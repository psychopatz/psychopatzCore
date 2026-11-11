"""Manifest-backed Conversation source compiler and generated artifact plan.

Conversation authoring is deliberately compiled through this module instead of
adding another source loader beside CodeBuilder.  The manifest is the only
filesystem discovery boundary; all runtime and authoring consumers receive the
same merged, validated model.
"""

from __future__ import annotations

import json
import re
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Mapping

from tools.semantic_harness.codebuilder.catalog_naming import (
    ModuleNameRegistry,
    pascal_segment,
    source_owned_module,
)
from .dialogue_content import (
    _lua_value,
    _lua_string,
    compile_dialogue_content,
    render_dialogue_content_shard_plan,
)
from .dialogue_dataset import compile_dialogue_dataset
from .lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder.source_manifest import (
    SourceManifestError,
    load_external_shard_entries,
)
from tools.semantic_harness.codebuilder.conversation_model import (
    canonical_json as _canonical_json,
    copy_json as _copy_json,
    fingerprint as _fingerprint,
    merge_source_metadata as _source_metadata,
    register_global_id as _register_global_id_core,
    runtime_records as _runtime_records,
)
from tools.semantic_harness.codebuilder.conversation_assembler import assemble_shards
from tools.semantic_harness.codebuilder.translation_support import DEFAULT_LANGUAGE, merge_language_sets, normalize_language
from .semantic_definition_compiler import (
    compile_semantic_definitions,
    discover_registered_capability_ids,
)
from .semantic_pack_compiler import compile_semantic_pack_shard
from .generation_ownership import (
    HOOMANS_OWNER,
    OwnerConfigurationError,
    conversation_prefix,
    normalize_owner,
    package_descriptor,
    route_module_for_owner,
    resolve_core_repository,
    source_owner,
)


CONVERSATION_MANIFEST_SCHEMA = "pnc.conversation.manifest.v1"
CONVERSATION_SHARD_SCHEMA = "pnc.conversation.shard.v1"
CONVERSATION_MODEL_SCHEMA = "pnc.conversation.model.v1"
CONVERSATION_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/conversation"
)
CONVERSATION_MANIFEST_RELATIVE = CONVERSATION_SOURCE_RELATIVE / "manifest.json"
CONVERSATION_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/Conversation"
)
CONVERSATION_UI_RUNTIME_RELATIVE = CONVERSATION_RUNTIME_RELATIVE / "UI/StaticSuggestions.lua"
CONVERSATION_PREFERRED_SOURCE_BYTES = 64 * 1024
CONVERSATION_MAX_SOURCE_BYTES = 128 * 1024
CONVERSATION_PREFERRED_SHARD_BYTES = 64 * 1024
CONVERSATION_MAX_SHARD_BYTES = 192 * 1024
CONVERSATION_PREFERRED_RECORDS_PER_SHARD = 16
CONVERSATION_MAX_RECORDS_PER_SHARD = 32
CONVERSATION_MAX_INDEX_BYTES = 192 * 1024
_ID = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_SHARD_KINDS = frozenset((
    "content", "patterns", "responses", "flows", "beats", "behaviors",
    "realization", "ui", "packs",
))


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError(f"{label} must contain an object: {path}")
    return value


def _registry_owner(model: dict[str, Any]) -> str:
    manifest = model.get("manifest")
    owner = manifest.get("registryOwner") if isinstance(manifest, dict) else None
    return normalize_owner(owner)


def _validate_relative_json_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a relative JSON path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise CompileError(f"{label} must stay below the Conversation source root")
    normalized = path.as_posix()
    if normalized != value or path.suffix.lower() != ".json":
        raise CompileError(f"{label} must be a normalized .json path")
    if normalized == "manifest.json":
        raise CompileError("manifest.json cannot also be a Conversation shard")
    return normalized


def _validate_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _ID.fullmatch(value):
        raise CompileError(f"{label} must be a bounded canonical ID")
    return value


def _validate_relative_directory_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a relative source directory")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise CompileError(f"{label} must stay below the Conversation source root")
    normalized = path.as_posix().rstrip("/")
    if not normalized or normalized != value.rstrip("/"):
        raise CompileError(f"{label} must be a normalized relative directory")
    if PurePosixPath(normalized).suffix:
        raise CompileError(f"{label} must be a directory, not a file")
    return normalized


def _manifest_entry(raw, *, label, root, seen_paths):
    path_value = _validate_relative_json_path(raw.get("path"), f"{label}.path")
    if path_value in seen_paths:
        raise CompileError(f"duplicate Conversation shard path: {path_value}")
    kind = raw.get("kind")
    if kind not in _SHARD_KINDS:
        raise CompileError(f"unsupported Conversation shard kind: {kind!r}")
    domain = _validate_id(raw.get("domain"), f"{label}.domain")
    order = raw.get("order")
    if isinstance(order, bool) or not isinstance(order, int) or order < 0:
        raise CompileError(f"{label}.order must be a non-negative integer")
    path = root / Path(*PurePosixPath(path_value).parts)
    if not path.is_file():
        raise CompileError(f"Conversation manifest shard is missing: {path_value}")
    seen_paths.add(path_value)
    return {**_copy_json(raw), "path": path_value, "kind": kind, "domain": domain, "order": order}


def _source_root_entries(manifest, *, root, seen_paths):
    raw_roots = manifest.get("sourceRoots", [])
    if raw_roots is None:
        raw_roots = []
    if not isinstance(raw_roots, list):
        raise CompileError("Conversation manifest sourceRoots must be a list")
    roots = []
    seen_roots = set()
    for index, raw in enumerate(raw_roots):
        label = f"sourceRoots[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        root_path = _validate_relative_directory_path(raw.get("path"), f"{label}.path")
        if root_path in seen_roots:
            raise CompileError(f"duplicate Conversation source root: {root_path}")
        seen_roots.add(root_path)
        kind = raw.get("kind")
        if kind not in _SHARD_KINDS:
            raise CompileError(f"unsupported Conversation source-root kind: {kind!r}")
        domain = _validate_id(raw.get("domain"), f"{label}.domain")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int) or order < 0:
            raise CompileError(f"{label}.order must be a non-negative integer")
        directory = root / Path(*PurePosixPath(root_path).parts)
        if not directory.is_dir():
            raise CompileError(f"Conversation source root is missing: {root_path}")
        roots.append({"path": root_path, "kind": kind, "domain": domain, "order": order})
    if roots != sorted(roots, key=lambda item: (item["order"], item["path"])):
        raise CompileError("Conversation sourceRoots must use canonical order")
    entries = []
    for source_root in roots:
        directory = root / Path(*PurePosixPath(source_root["path"]).parts)
        files = sorted(path for path in directory.rglob("*.json") if path.is_file())
        if not files:
            raise CompileError(f"Conversation source root contains no JSON shards: {source_root['path']}")
        for file_path in files:
            relative = file_path.relative_to(root).as_posix()
            if relative in seen_paths:
                raise CompileError(f"Conversation source-root shard is already registered: {relative}")
            seen_paths.add(relative)
            entries.append({
                "path": relative,
                "kind": source_root["kind"],
                "domain": source_root["domain"],
                "order": source_root["order"],
                "discoveredFrom": source_root["path"],
            })
    return entries


def _load_manifest(
    repository: Path,
    manifest_path: Path,
    *,
    package_repositories: Mapping[str, Path] | None = None,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    resolved_package_repositories = dict(package_repositories or {})
    resolved_package_repositories.setdefault(HOOMANS_OWNER, repository)
    resolved_package_repositories.setdefault(
        "PsychopatzCore",
        resolve_core_repository(repository),
    )
    manifest = _read_json(manifest_path, "Conversation manifest")
    if manifest.get("schema") != CONVERSATION_MANIFEST_SCHEMA:
        raise CompileError(
            f"Conversation manifest requires schema {CONVERSATION_MANIFEST_SCHEMA}"
        )
    try:
        default_owner = normalize_owner(manifest.get("defaultOwner"))
        registry_owner = normalize_owner(
            manifest.get("registryOwner"),
            default=default_owner,
        )
    except OwnerConfigurationError as error:
        raise CompileError(f"invalid Conversation manifest ownership: {error}") from error
    manifest["defaultOwner"] = default_owner
    manifest["registryOwner"] = registry_owner
    shards = manifest.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError("Conversation manifest requires at least one shard")
    root = manifest_path.parent
    seen_paths = set()
    explicit_entries = []
    for index, raw in enumerate(shards):
        if not isinstance(raw, dict):
            raise CompileError(f"Conversation manifest shard {index} must be an object")
        explicit_entries.append(_manifest_entry(
            raw, label=f"shards[{index}]", root=root, seen_paths=seen_paths
        ))
    if explicit_entries != sorted(explicit_entries, key=lambda item: (item["order"], item["path"])):
        raise CompileError("Conversation manifest shards must use canonical order")

    discovered_entries = _source_root_entries(manifest, root=root, seen_paths=seen_paths)
    try:
        external_entries = load_external_shard_entries(
            manifest,
            seen_paths=seen_paths,
            package_repositories=resolved_package_repositories,
            valid_kinds=_SHARD_KINDS,
            validate_id=_validate_id,
        )
    except SourceManifestError as error:
        raise CompileError(str(error)) from error
    entries = sorted(
        [*explicit_entries, *discovered_entries, *external_entries],
        key=lambda item: (item["order"], item["path"]),
    )

    discovered = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*.json")
        if path.is_file() and path.name != "manifest.json"
    }
    unregistered = sorted(discovered - seen_paths)
    if unregistered:
        raise CompileError(
            "unregistered Conversation shards: " + ", ".join(unregistered)
        )
    return manifest, entries


def _validate_ui_shard(document: dict[str, Any], path: str) -> list[dict[str, Any]]:
    suggestions = document.get("suggestions")
    if not isinstance(suggestions, list):
        raise CompileError(f"UI shard {path} requires a suggestions list")
    seen: set[str] = set()
    result: list[dict[str, Any]] = []
    for index, suggestion in enumerate(suggestions):
        if not isinstance(suggestion, dict):
            raise CompileError(f"UI shard {path} suggestion {index} must be an object")
        suggestion_id = _validate_id(suggestion.get("id"), f"{path}.suggestions[{index}].id")
        if suggestion_id in seen:
            raise CompileError(f"duplicate UI suggestion id: {suggestion_id}")
        seen.add(suggestion_id)
        for field in ("topic", "patternID", "labelKey", "utteranceKey"):
            if not isinstance(suggestion.get(field), str) or not suggestion[field].strip():
                raise CompileError(f"{path}.{suggestion_id} requires {field}")
        order = suggestion.get("order")
        if isinstance(order, bool) or not isinstance(order, int):
            raise CompileError(f"{path}.{suggestion_id}.order must be an integer")
        result.append(_copy_json(suggestion))
    return result


_DIRECTOR_PREDICATE_OPS = frozenset((
    "eq", "neq", "gt", "gte", "lt", "lte", "in", "not_in", "truthy", "falsy",
))


def _validate_director_predicate(value: Any, label: str, *, depth: int = 0) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError(f"{label} must be an object")
    if depth > 4:
        raise CompileError(f"{label} exceeds predicate depth")
    structural = [key for key in ("all", "any", "not") if key in value]
    if structural:
        if len(structural) != 1 or len(value) != 1:
            raise CompileError(f"{label} must contain exactly one structural predicate")
        key = structural[0]
        if key == "not":
            return {"not": _validate_director_predicate(value[key], f"{label}.not", depth=depth + 1)}
        items = value[key]
        if not isinstance(items, list) or not items or len(items) > 16:
            raise CompileError(f"{label}.{key} must contain 1-16 predicates")
        return {
            key: [
                _validate_director_predicate(item, f"{label}.{key}[{index}]", depth=depth + 1)
                for index, item in enumerate(items)
            ]
        }
    path = value.get("path")
    op = value.get("op")
    if not isinstance(path, str) or not path or len(path) > 128:
        raise CompileError(f"{label}.path must be a bounded field path")
    if op not in _DIRECTOR_PREDICATE_OPS:
        raise CompileError(f"{label}.op is unsupported: {op!r}")
    result: dict[str, Any] = {"path": path, "op": op}
    if op in ("truthy", "falsy"):
        return result
    if op in ("in", "not_in"):
        values = value.get("values")
        if not isinstance(values, list) or not values or len(values) > 16:
            raise CompileError(f"{label}.values must contain 1-16 values")
        result["values"] = _copy_json(values)
        return result
    if "value" not in value:
        raise CompileError(f"{label}.value is required")
    result["value"] = _copy_json(value["value"])
    return result


def _validate_behavior_shard(
    document: dict[str, Any],
    path: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    values = document.get("behaviors")
    if not isinstance(values, list):
        raise CompileError(f"Behavior shard {path} requires a behaviors list")
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    token = re.compile(r"^[A-Z][A-Z0-9_]{0,63}$")
    for index, raw in enumerate(values):
        label = f"{path}.behaviors[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        if not record_id.startswith("behavior."):
            raise CompileError(f"{label}.id must start with behavior.")
        if record_id in seen:
            raise CompileError(f"duplicate behavior id: {record_id}")
        seen.add(record_id)

        act = raw.get("act")
        if not isinstance(act, str) or not token.fullmatch(act):
            raise CompileError(f"{label}.act must be a bounded semantic token")

        mode = raw.get("mode", "beat")
        if mode not in ("beat", "one_shot"):
            raise CompileError(f"{label}.mode must be beat or one_shot")

        raw_stimuli = raw.get("stimuli")
        if not isinstance(raw_stimuli, list) or not raw_stimuli or len(raw_stimuli) > 16:
            raise CompileError(f"{label}.stimuli must contain 1-16 stimulus tokens")
        stimuli: list[str] = []
        stimulus_seen: set[str] = set()
        for stimulus_index, value in enumerate(raw_stimuli):
            if not isinstance(value, str) or not token.fullmatch(value):
                raise CompileError(
                    f"{label}.stimuli[{stimulus_index}] must be a bounded semantic token"
                )
            if value in stimulus_seen:
                raise CompileError(f"{label}.stimuli contains duplicate {value}")
            stimulus_seen.add(value)
            stimuli.append(value)

        raw_capabilities = raw.get("requiredCapabilities", [])
        if not isinstance(raw_capabilities, list) or len(raw_capabilities) > 8:
            raise CompileError(
                f"{label}.requiredCapabilities must contain at most 8 capabilities"
            )
        required_capabilities: list[str] = []
        capability_seen: set[str] = set()
        for capability_index, value in enumerate(raw_capabilities):
            capability = _validate_id(
                value, f"{label}.requiredCapabilities[{capability_index}]"
            )
            if capability in capability_seen:
                raise CompileError(
                    f"{label}.requiredCapabilities contains duplicate {capability}"
                )
            capability_seen.add(capability)
            required_capabilities.append(capability)

        raw_outputs = raw.get("outputs", {})
        if not isinstance(raw_outputs, dict):
            raise CompileError(f"{label}.outputs must be an object")
        outputs: dict[str, Any] = {}
        speech = raw_outputs.get("speech")
        if speech is not None:
            if not isinstance(speech, dict):
                raise CompileError(f"{label}.outputs.speech must be an object")
            dialogue_act = speech.get("dialogueAct")
            if not isinstance(dialogue_act, str) or not token.fullmatch(dialogue_act):
                raise CompileError(
                    f"{label}.outputs.speech.dialogueAct must be a bounded semantic token"
                )
            outputs["speech"] = {
                "dialogueAct": dialogue_act,
                "contentTemplateID": _validate_id(
                    speech.get("contentTemplateID"),
                    f"{label}.outputs.speech.contentTemplateID",
                ),
            }
        emote = raw_outputs.get("emote")
        if emote is not None:
            if not isinstance(emote, dict):
                raise CompileError(f"{label}.outputs.emote must be an object")
            emote_id = _validate_id(emote.get("id"), f"{label}.outputs.emote.id")
            outputs["emote"] = {"id": emote_id}
        flavor = raw_outputs.get("flavor")
        if flavor is not None:
            if not isinstance(flavor, dict):
                raise CompileError(f"{label}.outputs.flavor must be an object")
            presentation_act = flavor.get("presentationAct", "AMBIENT_FLAVOR")
            if (
                not isinstance(presentation_act, str)
                or not token.fullmatch(presentation_act)
            ):
                raise CompileError(
                    f"{label}.outputs.flavor.presentationAct must be a bounded semantic token"
                )
            outputs["flavor"] = {
                "presentationAct": presentation_act,
                "contentTemplateID": _validate_id(
                    flavor.get("contentTemplateID"),
                    f"{label}.outputs.flavor.contentTemplateID",
                ),
            }
        gameplay = raw_outputs.get("gameplayIntent")
        if gameplay is not None:
            if not isinstance(gameplay, dict):
                raise CompileError(f"{label}.outputs.gameplayIntent must be an object")
            intent_id = _validate_id(
                gameplay.get("id"), f"{label}.outputs.gameplayIntent.id"
            )
            outputs["gameplayIntent"] = {"id": intent_id}
        unsupported_outputs = sorted(
            set(raw_outputs) - {"speech", "emote", "flavor", "gameplayIntent"}
        )
        if unsupported_outputs:
            raise CompileError(
                f"{label}.outputs contains unsupported keys: "
                + ", ".join(unsupported_outputs)
            )

        continuation = raw.get("continuation")
        normalized_continuation: dict[str, Any] | None = None
        if continuation is not None:
            if not isinstance(continuation, dict):
                raise CompileError(f"{label}.continuation must be an object")
            continuation_mode = str(continuation.get("mode") or "")
            if continuation_mode not in ("emit", "wait", "terminate"):
                raise CompileError(
                    f"{label}.continuation.mode must be emit, wait, or terminate"
                )
            continuation_target = str(
                continuation.get("target") or (
                    "none" if continuation_mode == "terminate" else "source"
                )
            )
            if continuation_target not in ("source", "other", "none"):
                raise CompileError(
                    f"{label}.continuation.target must be source, other, or none"
                )
            if continuation_mode == "emit" and continuation_target == "none":
                raise CompileError(
                    f"{label}.continuation emit requires a target"
                )
            continuation_intent = continuation.get("intent")
            if continuation_intent is not None and (
                not isinstance(continuation_intent, str)
                or not token.fullmatch(continuation_intent)
            ):
                raise CompileError(
                    f"{label}.continuation.intent must be a bounded semantic token"
                )
            continuation_speech_act = continuation.get("speechAct")
            if continuation_speech_act is not None and (
                not isinstance(continuation_speech_act, str)
                or not token.fullmatch(continuation_speech_act)
            ):
                raise CompileError(
                    f"{label}.continuation.speechAct must be a bounded semantic token"
                )
            expected_response = continuation.get("expectedResponse")
            if expected_response is not None and (
                not isinstance(expected_response, str)
                or not token.fullmatch(expected_response)
            ):
                raise CompileError(
                    f"{label}.continuation.expectedResponse must be a bounded semantic token"
                )
            normalized_continuation = {
                "mode": continuation_mode,
                "target": continuation_target,
                "inheritFactRefs": continuation.get("inheritFactRefs", True) is not False,
                "inheritEventRefs": continuation.get("inheritEventRefs", True) is not False,
            }
            if continuation_intent is not None:
                normalized_continuation["intent"] = continuation_intent
            if continuation_speech_act is not None:
                normalized_continuation["speechAct"] = continuation_speech_act
            if expected_response is not None:
                normalized_continuation["expectedResponse"] = expected_response

        when = raw.get("when")
        if when is not None:
            when = _validate_director_predicate(when, f"{label}.when")
        relevance = raw.get("baseRelevance", 0.5)
        if (
            isinstance(relevance, bool)
            or not isinstance(relevance, (int, float))
            or not 0 <= relevance <= 1
        ):
            raise CompileError(f"{label}.baseRelevance must be between 0 and 1")
        modifiers = raw.get("modifiers", [])
        if not isinstance(modifiers, list) or len(modifiers) > 16:
            raise CompileError(
                f"{label}.modifiers must be a list of at most 16 entries"
            )
        normalized_modifiers: list[dict[str, Any]] = []
        for modifier_index, modifier in enumerate(modifiers):
            modifier_label = f"{label}.modifiers[{modifier_index}]"
            if not isinstance(modifier, dict):
                raise CompileError(f"{modifier_label} must be an object")
            delta = modifier.get("delta")
            if (
                isinstance(delta, bool)
                or not isinstance(delta, (int, float))
                or not -1 <= delta <= 1
            ):
                raise CompileError(
                    f"{modifier_label}.delta must be between -1 and 1"
                )
            normalized_modifiers.append(
                {
                    "when": _validate_director_predicate(
                        modifier.get("when"), f"{modifier_label}.when"
                    ),
                    "delta": delta,
                    "reason": str(modifier.get("reason") or "")[:96],
                }
            )
        normalize_owner(raw.get("owner"), default=default_owner)
        record = {
            "id": record_id,
            "version": int(raw.get("version", 1)),
            "owner": default_owner,
            "act": act,
            "mode": mode,
            "stimuli": stimuli,
            "requiredCapabilities": required_capabilities,
            "outputs": outputs,
            "when": when,
            "baseRelevance": float(relevance),
            "modifiers": normalized_modifiers,
        }
        if normalized_continuation is not None:
            record["continuation"] = normalized_continuation
        records.append(record)
    return {"records": records}


def _validate_beat_shard(
    document: dict[str, Any],
    path: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    values = document.get("beats")
    if not isinstance(values, list):
        raise CompileError(f"Beat shard {path} requires a beats list")
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    token = re.compile(r"^[A-Z][A-Z0-9_]{0,63}$")
    for index, raw in enumerate(values):
        label = f"{path}.beats[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        if not record_id.startswith("beat."):
            raise CompileError(f"{label}.id must start with beat.")
        if record_id in seen:
            raise CompileError(f"duplicate beat id: {record_id}")
        seen.add(record_id)
        raw_stimuli = raw.get("stimuli")
        if (
            not isinstance(raw_stimuli, list)
            or not raw_stimuli
            or len(raw_stimuli) > 16
        ):
            raise CompileError(
                f"{label}.stimuli must contain 1-16 stimulus tokens"
            )
        stimuli: list[str] = []
        stimulus_seen: set[str] = set()
        for stimulus_index, value in enumerate(raw_stimuli):
            if not isinstance(value, str) or not token.fullmatch(value):
                raise CompileError(
                    f"{label}.stimuli[{stimulus_index}] must be a bounded semantic token"
                )
            if value in stimulus_seen:
                raise CompileError(
                    f"{label}.stimuli contains duplicate {value}"
                )
            stimulus_seen.add(value)
            stimuli.append(value)
        candidates = raw.get("candidates")
        if not isinstance(candidates, list) or not candidates or len(candidates) > 16:
            raise CompileError(f"{label}.candidates must contain 1-16 behaviors")
        normalized_candidates: list[dict[str, Any]] = []
        for candidate_index, candidate in enumerate(candidates):
            candidate_label = f"{label}.candidates[{candidate_index}]"
            if not isinstance(candidate, dict):
                raise CompileError(f"{candidate_label} must be an object")
            behavior = _validate_id(candidate.get("behavior"), f"{candidate_label}.behavior")
            relevance = candidate.get("relevance", 0.5)
            if isinstance(relevance, bool) or not isinstance(relevance, (int, float)) or not 0 <= relevance <= 1:
                raise CompileError(f"{candidate_label}.relevance must be between 0 and 1")
            normalized_candidates.append({"behavior": behavior, "relevance": float(relevance)})
        relevance = raw.get("baseRelevance", 0.5)
        if isinstance(relevance, bool) or not isinstance(relevance, (int, float)) or not 0 <= relevance <= 1:
            raise CompileError(f"{label}.baseRelevance must be between 0 and 1")
        cooldown = raw.get("cooldownTurns", 0)
        max_turns = raw.get("maxTurns", 6)
        for field, value, maximum in (("cooldownTurns", cooldown, 64), ("maxTurns", max_turns, 64)):
            if isinstance(value, bool) or not isinstance(value, int) or value < 0 or value > maximum:
                raise CompileError(f"{label}.{field} must be an integer from 0 to {maximum}")
        normalize_owner(raw.get("owner"), default=default_owner)
        record = {
            "id": record_id,
            "version": int(raw.get("version", 1)),
            "owner": default_owner,
            "stimuli": stimuli,
            "entry": _validate_director_predicate(raw.get("entry"), f"{label}.entry"),
            "maintain": _validate_director_predicate(raw.get("maintain"), f"{label}.maintain"),
            "exit": _validate_director_predicate(raw.get("exit"), f"{label}.exit"),
            "candidates": normalized_candidates,
            "baseRelevance": float(relevance),
            "cooldownTurns": cooldown,
            "maxTurns": max_turns,
        }
        group = raw.get("group")
        if group is not None:
            record["group"] = _validate_id(group, f"{label}.group")
        records.append(record)
    return {"records": records}


def _validate_realization_shard(
    document: dict[str, Any],
    path: str,
) -> dict[str, Any]:
    values = document.get("realizations")
    if not isinstance(values, list):
        raise CompileError(f"Realization shard {path} requires a realizations list")
    if len(values) > CONVERSATION_MAX_RECORDS_PER_SHARD:
        raise CompileError(
            f"Realization shard {path} exceeds the "
            f"{CONVERSATION_MAX_RECORDS_PER_SHARD}-record hard budget"
        )
    records: list[dict[str, Any]] = []
    for index, raw in enumerate(values):
        label = f"{path}.realizations[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        realization_type = str(raw.get("type") or "")
        if realization_type not in {"lexeme", "construction"}:
            raise CompileError(
                f"{label}.type must be lexeme or construction"
            )
        record = _copy_json(raw)
        record["id"] = record_id
        record["type"] = realization_type
        if realization_type == "lexeme":
            concept = str(raw.get("concept") or "")
            if not concept or len(concept) > 96:
                raise CompileError(f"{label}.concept is required")
            forms = raw.get("forms")
            if not isinstance(forms, dict) or not forms:
                raise CompileError(f"{label}.forms must be a non-empty object")
            if len(forms) > 8:
                raise CompileError(f"{label}.forms exceeds 8 locales")
            for locale, value in forms.items():
                if not isinstance(locale, str) or not locale or len(locale) > 12:
                    raise CompileError(f"{label}.forms locale is invalid")
                if not isinstance(value, str) or not value or len(value) > 96:
                    raise CompileError(
                        f"{label}.forms[{locale}] must be bounded text"
                    )
        else:
            locale = str(raw.get("locale") or "")
            strategy = str(raw.get("strategy") or "")
            if not locale or len(locale) > 12:
                raise CompileError(f"{label}.locale is required")
            if not strategy or len(strategy) > 64:
                raise CompileError(f"{label}.strategy is required")
            tokens = raw.get("tokens")
            if not isinstance(tokens, list) or not tokens or len(tokens) > 12:
                raise CompileError(
                    f"{label}.tokens must contain 1-12 token objects"
                )
            for token_index, token in enumerate(tokens):
                token_label = f"{label}.tokens[{token_index}]"
                if not isinstance(token, dict):
                    raise CompileError(f"{token_label} must be an object")
                token_kind = str(token.get("kind") or "")
                if token_kind not in {"literal", "lexeme", "slot"}:
                    raise CompileError(
                        f"{token_label}.kind is not supported"
                    )
                if token_kind == "literal":
                    value = token.get("value")
                    if not isinstance(value, str) or len(value) > 128:
                        raise CompileError(
                            f"{token_label}.value must be bounded text"
                        )
                else:
                    slot = token.get("slot")
                    if not isinstance(slot, str) or not slot or len(slot) > 64:
                        raise CompileError(
                            f"{token_label}.slot is required"
                        )
        records.append(record)
    return {"records": records}


def _merge_realization_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for document, entry, _ in shards:
        if entry["kind"] != "realization":
            continue
        compiled = _validate_realization_shard(document, entry["path"])
        for record in compiled["records"]:
            records.append({**record, "domain": entry["domain"]})
    records.sort(key=lambda item: item["id"])
    return {"records": records}


def _merge_director_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
    kind: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for document, entry, _ in shards:
        if entry["kind"] != kind:
            continue
        source = document.get("source")
        owner = normalize_owner(
            source.get("owner") if isinstance(source, dict) else None,
            default=default_owner,
        )
        compiled = (
            _validate_behavior_shard(
                document,
                entry["path"],
                default_owner=owner,
            )
            if kind == "behaviors"
            else _validate_beat_shard(
                document,
                entry["path"],
                default_owner=owner,
            )
        )
        for record in compiled["records"]:
            records.append({**record, "domain": entry["domain"]})
    records.sort(key=lambda item: item["id"])
    return {"records": records}


def _compile_shard(
    document: dict[str, Any],
    entry: dict[str, Any],
    *,
    runtime_root: Path,
    default_owner: str,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    kind = entry["kind"]
    path = entry["path"]
    if document.get("schema") != CONVERSATION_SHARD_SCHEMA:
        raise CompileError(f"Conversation shard {path} requires schema {CONVERSATION_SHARD_SCHEMA}")
    if document.get("kind") != kind or document.get("domain") != entry["domain"]:
        raise CompileError(f"Conversation shard {path} does not match its manifest entry")
    source = document.get("source")
    if not isinstance(source, dict):
        raise CompileError(f"Conversation shard {path} requires source metadata")
    if kind == "content":
        compiled = compile_dialogue_content({
            "schemaVersion": 2,
            "source": source,
            "groups": document.get("groups"),
            "phraseFamilies": document.get("phraseFamilies"),
            "playerChoices": document.get("playerChoices", []),
        })
    elif kind in ("patterns", "responses"):
        compiled = compile_dialogue_dataset({
            "schemaVersion": 1,
            "source": source,
            "patterns": document.get("patterns", []) if kind == "patterns" else [],
            "responsePools": document.get("responsePools", []) if kind == "responses" else [],
        })
    elif kind == "flows":
        compiled = compile_semantic_definitions(
            {
                "schema": "pnc.semantic_authoring.v1",
                "source": source,
                "definitions": document.get("definitions"),
            },
            registered_capability_ids=discover_registered_capability_ids(
                runtime_root,
                package_repositories=package_repositories,
            ),
        )
    elif kind == "behaviors":
        compiled = _validate_behavior_shard(
            document,
            path,
            default_owner=normalize_owner(
                source.get("owner"),
                default=default_owner,
            ),
        )
    elif kind == "beats":
        compiled = _validate_beat_shard(
            document,
            path,
            default_owner=normalize_owner(
                source.get("owner"),
                default=default_owner,
            ),
        )
    elif kind == "realization":
        compiled = _validate_realization_shard(document, path)
    elif kind == "packs":
        compiled = compile_semantic_pack_shard(document, path)
    else:
        compiled = {"suggestions": _validate_ui_shard(document, path)}
    return compiled


def _merge_dialogue_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    pattern_documents = [document for document, entry, _ in shards if entry["kind"] == "patterns"]
    response_documents = [document for document, entry, _ in shards if entry["kind"] == "responses"]
    all_documents = pattern_documents + response_documents
    if not all_documents:
        return {
            "source": {"name": "Project Hoomans Conversation", "version": "1", "references": []},
            "patterns": [],
            "responsePools": [],
        }, {}
    source = _source_metadata(all_documents)
    patterns = [item for document in pattern_documents for item in document.get("patterns", [])]
    pools = [item for document in response_documents for item in document.get("responsePools", [])]
    patterns.sort(key=lambda item: str(item.get("id", "")))
    pools.sort(key=lambda item: str(item.get("id", "")))
    compiled = compile_dialogue_dataset({
        "schemaVersion": 1,
        "source": source,
        "patterns": patterns,
        "responsePools": pools,
    })
    return compiled, compiled["translations"]


def _merge_semantic_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
    runtime_root: Path,
    default_owner: str,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    documents = [document for document, entry, _ in shards if entry["kind"] == "flows"]
    if not documents:
        return {"patterns": [], "flows": [], "responsePools": [], "translations": {}}
    source = _source_metadata(documents)
    source_owner = normalize_owner(source.get("owner"), default=default_owner)
    source_version = source.get("version") or "1"
    definitions = [item for document in documents for item in document.get("definitions", [])]
    definitions.sort(key=lambda item: str(item.get("id", "")))
    return compile_semantic_definitions(
        {
            "schema": "pnc.semantic_authoring.v1",
            "source": {"owner": source_owner, "version": source_version},
            "definitions": definitions,
        },
        registered_capability_ids=discover_registered_capability_ids(
            runtime_root,
            package_repositories=package_repositories,
        ),
    )


def _content_source(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> tuple[dict[str, Any], dict[str, str]]:
    documents = [document for document, entry, _ in shards if entry["kind"] == "content"]
    if not documents:
        raise CompileError("Conversation manifest requires at least one content shard")
    groups: dict[str, Any] = {}
    families: list[dict[str, Any]] = []
    choices: list[dict[str, Any]] = []
    for document in documents:
        for group, metadata in (document.get("groups") or {}).items():
            existing = groups.get(group)
            if existing is not None and _canonical_json(existing) != _canonical_json(metadata):
                raise CompileError(f"conflicting content group metadata: {group}")
            groups[group] = _copy_json(metadata)
        families.extend(_copy_json(document.get("phraseFamilies", [])))
        choices.extend(_copy_json(document.get("playerChoices", [])))
    families.sort(key=lambda item: str(item.get("semanticTemplateID", "")))
    choices.sort(key=lambda item: str(item.get("id", "")))
    source = _source_metadata(documents)
    compiled = compile_dialogue_content({
        "schemaVersion": 2,
        "source": source,
        "groups": {key: groups[key] for key in sorted(groups)},
        "phraseFamilies": families,
        "playerChoices": choices,
    })
    return compiled, source


def _add_global_id(
    locations: dict[str, dict[str, Any]],
    record_id: Any,
    *,
    kind: str,
    shard: dict[str, Any],
    path: str,
) -> None:
    _register_global_id_core(
        locations,
        record_id,
        kind=kind,
        shard=shard,
        path=path,
        owner=normalize_owner(shard.get("owner")),
    )


def _ui_translations(ui: list[dict[str, Any]]) -> dict[str, dict[str, str]]:
    languages: set[str] = {DEFAULT_LANGUAGE}
    for suggestion in ui:
        raw = suggestion.get("translations")
        if isinstance(raw, dict):
            for raw_language in raw:
                languages.add(normalize_language(raw_language, "UI translation language"))
    translations = {language: {} for language in sorted(languages)}
    for suggestion in ui:
        raw = suggestion.get("translations")
        for language in sorted(languages):
            values = raw.get(language, {}) if isinstance(raw, dict) else {}
            for field, key in (
                ("label", suggestion.get("labelKey")),
                ("utterance", suggestion.get("utteranceKey")),
            ):
                value = values.get(field) if isinstance(values, dict) else None
                if not isinstance(value, str) or not value.strip():
                    if language == DEFAULT_LANGUAGE:
                        value = suggestion.get(
                            "labelFallback" if field == "label" else "utteranceFallback"
                        )
                    else:
                        continue
                if isinstance(key, str) and isinstance(value, str):
                    translations[language][key] = value
    return {
        language: {key: values[key] for key in sorted(values)}
        for language, values in sorted(translations.items())
        if values
    }


def _conversation_record_ids(
    document: dict[str, Any],
    entry: dict[str, Any],
) -> list[str]:
    kind = entry["kind"]
    fields = {
        "content": ("phraseFamilies", "playerChoices"),
        "patterns": ("patterns",),
        "responses": ("responsePools",),
        "flows": ("definitions",),
        "behaviors": ("behaviors",),
        "beats": ("beats",),
        "realization": ("realizations",),
        "packs": ("packs",),
        "ui": ("suggestions",),
    }.get(kind)
    if fields is None:
        return []
    record_ids: list[str] = []
    for field in fields:
        key = (
            "semanticTemplateID"
            if kind == "content" and field == "phraseFamilies"
            else "id"
        )
        record_ids.extend(str(item[key]) for item in document.get(field, []))
    return record_ids


def compile_conversation_sources(
    repository: Path,
    *,
    manifest_path: Path | None = None,
    runtime_root: Path | None = None,
    source_overrides: dict[str, dict[str, Any]] | None = None,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    """Load, validate, merge, sort, fingerprint, and index Conversation shards.

    source_overrides is an effect-free preview hook keyed by manifest-relative
    shard path. It never writes to disk and is used by the shared authoring
    service to validate edits against the complete Conversation model.
    """
    repository = repository.expanduser().resolve()
    resolved_package_repositories = {
        HOOMANS_OWNER: repository,
        "PsychopatzCore": resolve_core_repository(
            repository,
            runtime_root=runtime_root,
        ),
        **{
            normalize_owner(owner): Path(path).expanduser().resolve()
            for owner, path in (package_repositories or {}).items()
        },
    }
    if manifest_path is None:
        manifest_path = repository / CONVERSATION_MANIFEST_RELATIVE
        if not manifest_path.is_file():
            manifest_path = (
                resolved_package_repositories["PsychopatzCore"]
                / CONVERSATION_MANIFEST_RELATIVE
            )
    manifest_path = manifest_path.expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()
    manifest, entries = _load_manifest(
        repository,
        manifest_path,
        package_repositories=resolved_package_repositories,
    )
    def compile_shard(document: dict[str, Any], entry: dict[str, Any]) -> Any:
        return _compile_shard(
            document,
            entry,
            runtime_root=runtime_root,
            default_owner=manifest["defaultOwner"],
            package_repositories=resolved_package_repositories,
        )

    def owner_for(document: dict[str, Any], _entry: dict[str, Any]) -> str:
        source_meta = document.get("source")
        return normalize_owner(
            source_meta.get("owner") if isinstance(source_meta, dict) else None,
            default=manifest["defaultOwner"],
        )

    loaded, shard_reports, source_documents = assemble_shards(
        entries,
        source_root=manifest_path.parent,
        source_overrides=source_overrides,
        read_document=_read_json,
        compile_shard=compile_shard,
        record_ids_for=_conversation_record_ids,
        owner_for=owner_for,
    )

    content, content_source = _content_source(loaded)
    dialogue, _dialogue_translations = _merge_dialogue_sources(loaded)
    semantic = _merge_semantic_sources(
        loaded,
        runtime_root,
        manifest["defaultOwner"],
        package_repositories,
    )
    behaviors = _merge_director_sources(
        loaded,
        "behaviors",
        default_owner=manifest["defaultOwner"],
    )
    beats = _merge_director_sources(
        loaded,
        "beats",
        default_owner=manifest["defaultOwner"],
    )
    realization = _merge_realization_sources(loaded)
    packs = []
    for document, entry, _fingerprint_value in loaded:
        if entry["kind"] != "packs":
            continue
        source_meta = document.get("source") if isinstance(document, dict) else None
        owner = normalize_owner(
            source_meta.get("owner") if isinstance(source_meta, dict) else None,
            default=manifest["defaultOwner"],
        )
        for pack in document.get("packs", []):
            record = _copy_json(pack)
            record["owner"] = owner
            record["domain"] = entry["domain"]
            record["sourceShard"] = entry["path"]
            packs.append(record)
    packs.sort(key=lambda item: str(item.get("id", "")))
    ui = sorted(
        [item for document, entry, _ in loaded if entry["kind"] == "ui" for item in document.get("suggestions", [])],
        key=lambda item: (item.get("order", 0), item.get("id", "")),
    )

    locations: dict[str, dict[str, Any]] = {}
    for document, entry, _fingerprint_value in loaded:
        path = entry["path"]
        source_meta = document.get("source") if isinstance(document, dict) else None
        entry = {
            **entry,
            "owner": normalize_owner(
                source_meta.get("owner") if isinstance(source_meta, dict) else None,
                default=manifest["defaultOwner"],
            ),
        }
        if entry["kind"] == "content":
            for family in document.get("phraseFamilies", []):
                _add_global_id(
                    locations,
                    "phrase." + str(family.get("semanticTemplateID")),
                    kind="content",
                    shard=entry,
                    path=path,
                )
            for choice in document.get("playerChoices", []):
                _add_global_id(locations, choice.get("id"), kind="content", shard=entry, path=path)
        elif entry["kind"] == "patterns":
            for pattern in document.get("patterns", []):
                _add_global_id(locations, pattern.get("id"), kind="pattern", shard=entry, path=path)
        elif entry["kind"] == "responses":
            for pool in document.get("responsePools", []):
                _add_global_id(locations, pool.get("id"), kind="responsePool", shard=entry, path=path)
        elif entry["kind"] == "flows":
            for definition in document.get("definitions", []):
                _add_global_id(locations, definition.get("id"), kind="flowDefinition", shard=entry, path=path)
                flow = definition.get("flow") if isinstance(definition, dict) else None
                if isinstance(flow, dict):
                    _add_global_id(locations, flow.get("id"), kind="flow", shard=entry, path=path)
                responses = definition.get("responses") if isinstance(definition, dict) else None
                if isinstance(responses, dict):
                    _add_global_id(locations, responses.get("poolID"), kind="responsePool", shard=entry, path=path)
        elif entry["kind"] == "behaviors":
            for behavior in document.get("behaviors", []):
                _add_global_id(locations, behavior.get("id"), kind="behavior", shard=entry, path=path)
        elif entry["kind"] == "beats":
            for beat in document.get("beats", []):
                _add_global_id(locations, beat.get("id"), kind="beat", shard=entry, path=path)
        elif entry["kind"] == "realization":
            for realization_record in document.get("realizations", []):
                _add_global_id(
                    locations,
                    realization_record.get("id"),
                    kind="realization",
                    shard=entry,
                    path=path,
                )
        elif entry["kind"] == "packs":
            for pack in document.get("packs", []):
                _add_global_id(
                    locations,
                    pack.get("id"),
                    kind="pack",
                    shard=entry,
                    path=path,
                )
        else:
            for suggestion in document.get("suggestions", []):
                _add_global_id(locations, suggestion.get("id"), kind="ui", shard=entry, path=path)

    behavior_ids = {record["id"] for record in behaviors["records"]}
    available_content_templates = {
        str(item.get("semanticTemplateID"))
        for item in content.get("phraseFamilies", [])
        if isinstance(item, dict)
    }
    behavior_by_id = {
        record["id"]: record for record in behaviors["records"]
    }
    for behavior in behaviors["records"]:
        outputs = behavior.get("outputs", {})
        for output_name in ("speech", "flavor"):
            output = outputs.get(output_name)
            if isinstance(output, dict):
                content_template_id = output.get("contentTemplateID")
                if content_template_id not in available_content_templates:
                    raise CompileError(
                        f"behavior {behavior.get('id')} {output_name} output references "
                        f"unknown Dialogue Content template {content_template_id}"
                    )
    for beat in beats["records"]:
        for candidate in beat.get("candidates", []):
            behavior_id = candidate.get("behavior")
            if behavior_id not in behavior_ids:
                raise CompileError(
                    f"beat {beat.get('id')} references unknown behavior {behavior_id}"
                )
            if behavior_by_id[behavior_id].get("mode") != "beat":
                raise CompileError(
                    f"beat {beat.get('id')} references non-beat behavior {behavior_id}"
                )

    available_patterns = {
        str(item.get("id")) for item in dialogue.get("patterns", [])
    } | {str(item.get("id")) for item in semantic.get("patterns", [])}
    external_pattern_ids = set(
        (manifest.get("externalReferences") or {}).get("patternIDs", [])
    )
    for suggestion in ui:
        pattern_id = suggestion.get("patternID")
        if pattern_id not in available_patterns and pattern_id not in external_pattern_ids:
            raise CompileError(
                f"UI suggestion {suggestion.get('id')} references unregistered pattern {pattern_id}"
            )

    for family in content["phraseFamilies"]:
        owner = locations.get("phrase." + str(family["semanticTemplateID"]))
        if owner is not None:
            family["conversationDomain"] = owner["domain"]
            family["sourceShard"] = owner["sourceShard"]
    for choice in content["playerChoices"]:
        owner = locations.get(choice["id"])
        if owner is not None:
            choice["conversationDomain"] = owner["domain"]
            choice["sourceShard"] = owner["sourceShard"]

    # Semantic-authoring patterns are generated from the flow definitions but
    # are still canonical runtime IDs. Register them globally so a later
    # shard cannot accidentally mint an ID already used by a data pattern.
    for pattern in semantic.get("patterns", []):
        pattern_id = pattern.get("id")
        if not isinstance(pattern_id, str):
            continue
        definition_id = ".".join(pattern_id.split(".")[:3])
        owner = locations.get(definition_id)
        if owner is not None:
            _add_global_id(
                locations,
                pattern_id,
                kind="pattern",
                shard={
                    "domain": owner["domain"],
                    "owner": owner.get("owner"),
                },
                path=owner["sourceShard"],
            )

    identity_content = _copy_json(content)
    for family in identity_content.get("phraseFamilies", []):
        family.pop("conversationDomain", None)
        family.pop("sourceShard", None)
    for choice in identity_content.get("playerChoices", []):
        choice.pop("conversationDomain", None)
        choice.pop("sourceShard", None)
    semantic_payload = {
        "content": {
            key: value for key, value in identity_content.items()
            if key not in ("contentFingerprint",)
        },
        "dialogue": dialogue,
        "semantic": semantic,
        "behaviors": behaviors["records"],
        "beats": beats["records"],
        "realization": realization["records"],
        "packs": packs,
        "ui": ui,
    }
    whole_fingerprint = _fingerprint(semantic_payload)
    locations = {key: locations[key] for key in sorted(locations)}
    try:
        manifest_display_path = manifest_path.relative_to(repository)
    except ValueError:
        core_repository = resolved_package_repositories.get("PsychopatzCore")
        try:
            manifest_display_path = manifest_path.relative_to(core_repository)
        except (TypeError, ValueError):
            manifest_display_path = manifest_path
    model = {
        "schema": CONVERSATION_MODEL_SCHEMA,
        "manifestPath": str(manifest_display_path),
        "manifest": manifest,
        "source": content_source,
        "content": content,
        "dialogue": dialogue,
        "semantic": semantic,
        "behaviors": behaviors["records"],
        "beats": beats["records"],
        "realization": realization["records"],
        "packs": packs,
        "ui": ui,
        "uiTranslations": _ui_translations(ui),
        "shards": shard_reports,
        "locations": locations,
        "wholeModelFingerprint": whole_fingerprint,
        # Private build-time provenance used for shard-targeted authoring.
        # Private fields are never written into generated runtime artifacts.
        "_repository": repository,
        "_package_repositories": {
            normalize_owner(owner): Path(path).expanduser().resolve()
            for owner, path in (package_repositories or {}).items()
        },
        "_source_documents": source_documents,
    }
    return model


def conversation_record(model: dict[str, Any], canonical_id: str) -> dict[str, Any] | None:
    location = (model.get("locations") or {}).get(str(canonical_id))
    if not isinstance(location, dict):
        return None
    return _copy_json(location)


def conversation_languages(model: dict[str, Any]) -> tuple[str, ...]:
    """Return locale codes present in the merged canonical Conversation model."""
    languages = merge_language_sets(
        model.get("content", {}).get("translations", {}),
        model.get("uiTranslations", {}),
        model.get("dialogue", {}).get("translations", {}),
        model.get("semantic", {}).get("translations", {}),
    )
    if DEFAULT_LANGUAGE not in languages:
        raise CompileError(f"Conversation content requires {DEFAULT_LANGUAGE} fallback translations")
    return languages


def conversation_translation_bundles(model: dict[str, Any]) -> dict[str, dict[str, dict[str, str]]]:
    """Partition generated translations by Conversation domain, not history."""
    languages = conversation_languages(model)
    bundles = {language: {} for language in languages}

    def add(language: str, domain: str, key: str, value: Any) -> None:
        if language not in bundles or not isinstance(key, str) or not isinstance(value, str):
            return
        bundles[language].setdefault(domain, {})[key] = value

    for family in model["content"].get("phraseFamilies", []):
        domain = str(family.get("conversationDomain") or family.get("group") or "general").title()
        keys = [
            phrase["key"]
            for phrases in family.get("styles", {}).values()
            for phrase in phrases
            if isinstance(phrase, dict) and isinstance(phrase.get("key"), str)
        ]
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            for key in keys:
                add(language, domain, key, values.get(key))
    for choice in model["content"].get("playerChoices", []):
        domain = str(choice.get("conversationDomain") or "greeting").title()
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            add(language, domain, choice.get("labelKey"), values.get(choice.get("labelKey")))
            add(language, domain, choice.get("choiceKey"), values.get(choice.get("choiceKey")))
    repository = model.get("_repository")
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            add(language, "UI", key, value)
        if isinstance(repository, Path):
            suggestions_path = (
                repository
                / "Contents/mods/ProjectHoomans/common/media/translation"
                / language
                / "Conversation/Semantic/Suggestions.json"
            )
            if suggestions_path.is_file():
                try:
                    suggestions = json.loads(
                        suggestions_path.read_text(encoding="utf-8")
                    )
                except (OSError, UnicodeError, json.JSONDecodeError):
                    suggestions = {}
                if isinstance(suggestions, dict):
                    for key, value in suggestions.items():
                        add(language, "UI", key, value)
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(language, "Flows", key, value)
        bundles[language] = {
            domain: {key: values[key] for key in sorted(values)}
            for domain, values in sorted(bundles[language].items())
            if values
        }
    return bundles


def conversation_translation_bundles_by_owner(
    model: dict[str, Any],
    *,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, dict[str, dict[str, dict[str, str]]]]:
    """Partition Conversation translations by canonical package owner."""
    languages = conversation_languages(model)
    manifest = model.get("manifest") or {}
    default_owner = normalize_owner(manifest.get("defaultOwner"))
    registry_owner = normalize_owner(
        manifest.get("registryOwner"),
        default=default_owner,
    )
    bundles: dict[str, dict[str, dict[str, dict[str, str]]]] = {}

    def add(
        owner: Any,
        language: str,
        domain: str,
        key: Any,
        value: Any,
    ) -> None:
        if (
            language not in languages
            or not isinstance(key, str)
            or not isinstance(value, str)
        ):
            return
        canonical_owner = normalize_owner(owner, default=registry_owner)
        owner_bundles = bundles.setdefault(canonical_owner, {})
        language_bundles = owner_bundles.setdefault(language, {})
        language_bundles.setdefault(domain, {})[key] = value

    def record_owner(canonical_id: str) -> str:
        record = conversation_record(model, canonical_id) or {}
        return normalize_owner(record.get("owner"), default=default_owner)

    for family in model["content"].get("phraseFamilies", []):
        owner = record_owner("phrase." + str(family.get("semanticTemplateID")))
        domain = str(
            family.get("conversationDomain")
            or family.get("group")
            or "general"
        ).title()
        keys = [
            phrase["key"]
            for phrases in family.get("styles", {}).values()
            for phrase in phrases
            if isinstance(phrase, dict) and isinstance(phrase.get("key"), str)
        ]
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            for key in keys:
                add(owner, language, domain, key, values.get(key))

    for choice in model["content"].get("playerChoices", []):
        owner = record_owner(str(choice.get("id") or ""))
        domain = str(choice.get("conversationDomain") or "greeting").title()
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            add(owner, language, domain, choice.get("labelKey"), values.get(choice.get("labelKey")))
            add(owner, language, domain, choice.get("choiceKey"), values.get(choice.get("choiceKey")))

    ui_key_owners: dict[str, str] = {}
    for suggestion in model.get("ui", []):
        owner = record_owner(str(suggestion.get("id") or ""))
        for key in (suggestion.get("labelKey"), suggestion.get("utteranceKey")):
            if isinstance(key, str):
                ui_key_owners[key] = owner
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            add(ui_key_owners.get(key, registry_owner), language, "UI", key, value)

    repositories = {
        normalize_owner(owner): Path(path).expanduser().resolve()
        for owner, path in (
            model.get("_package_repositories") or {}
        ).items()
    }
    repository = model.get("_repository")
    if isinstance(repository, Path):
        repositories.setdefault(HOOMANS_OWNER, repository)
    for raw_owner, path in (package_repositories or {}).items():
        repositories[normalize_owner(raw_owner)] = Path(path).expanduser().resolve()
    for owner, repository_path in sorted(repositories.items()):
        descriptor = package_descriptor(owner)
        for language in languages:
            suggestions_path = (
                repository_path
                / descriptor.translation_relative
                / language
                / "Conversation/Semantic/Suggestions.json"
            )
            if not suggestions_path.is_file():
                continue
            try:
                suggestions = json.loads(
                    suggestions_path.read_text(encoding="utf-8")
                )
            except (OSError, UnicodeError, json.JSONDecodeError):
                suggestions = {}
            if isinstance(suggestions, dict):
                for key, value in suggestions.items():
                    add(owner, language, "UI", key, value)

    semantic_owner = normalize_owner(
        (model.get("semantic") or {}).get("source", {}).get("owner")
        if isinstance((model.get("semantic") or {}).get("source"), dict)
        else None,
        default=registry_owner,
    )
    for language in languages:
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(registry_owner, language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(semantic_owner, language, "Flows", key, value)

    return {
        owner: {
            language: {
                domain: {key: values[key] for key in sorted(values)}
                for domain, values in sorted(domains.items())
                if values
            }
            for language, domains in sorted(languages_by_owner.items())
        }
        for owner, languages_by_owner in sorted(bundles.items())
    }


def render_conversation_ui_module(model: dict[str, Any]) -> str:
    """Render the canonical generated static Conversation UI list."""
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(model["ui"], 0) + "\n"
    )



def render_conversation_lua_records(records: list[dict[str, Any]]) -> str:
    return "-- Generated; do not edit by hand.\nreturn " + _lua_value(records, 0) + "\n"


def _chunk_records(
    records: list[dict[str, Any]],
    *,
    kind: str,
    module_prefix: str,
    max_bytes: int = CONVERSATION_MAX_SHARD_BYTES,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render one bounded generated shard per canonical source owner.

    Numeric overflow parts are intentionally forbidden. If a canonical source
    owns too much generated runtime data, the canonical source must be split by
    semantic subdomain instead.
    """
    modules: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in records:
        source_shard = str(
            record.get("sourceShard")
            or f"{kind.lower()}/{record.get('domain') or 'general'}.json"
        )
        grouped.setdefault(source_shard, []).append(record)

    names = ModuleNameRegistry()
    for source_shard in sorted(grouped):
        items = sorted(
            grouped[source_shard],
            key=lambda item: str(item.get("id", "")),
        )
        if len(items) > CONVERSATION_MAX_RECORDS_PER_SHARD:
            raise CompileError(
                "canonical Conversation source exceeds the generated "
                f"{CONVERSATION_MAX_RECORDS_PER_SHARD}-definition hard budget; "
                f"split by semantic subdomain: {source_shard}"
            )
        runtime_items = _runtime_records(items)
        source = render_conversation_lua_records(runtime_items)
        size = len(source.encode("utf-8"))
        if size > max_bytes:
            raise CompileError(
                "canonical Conversation source renders above the "
                f"{max_bytes}-byte hard shard budget; split by semantic subdomain: "
                f"{source_shard}"
            )
        module = source_owned_module(
            f"{module_prefix}/{kind}",
            source_shard,
            names,
        )
        modules.append((module, source))
        reports.append({
            "module": module,
            "kind": kind,
            "domain": str(
                items[0].get("conversationDomain")
                or items[0].get("domain")
                or "general"
            ),
            "sourceShard": source_shard,
            "recordCount": len(items),
            "recordIDs": [
                str(item.get("id"))
                for item in items
                if isinstance(item.get("id"), str)
            ],
            "bytes": size,
        })
    return modules, reports


def _render_pack_shard_plan(
    records: list[dict[str, Any]],
    *,
    module_prefix: str,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render static pack data separately from runtime callback adapters."""
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in records:
        source_shard = str(record.get("sourceShard") or "packs/general.json")
        grouped.setdefault(source_shard, []).append(record)
    modules: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    names = ModuleNameRegistry()
    for source_shard in sorted(grouped):
        items = sorted(grouped[source_shard], key=lambda item: str(item.get("id", "")))
        runtime_items = []
        for item in items:
            runtime_item = _copy_json(item)
            for key in ("owner", "domain", "sourceShard"):
                runtime_item.pop(key, None)
            runtime_items.append(runtime_item)
        source = render_conversation_lua_records(runtime_items)
        size = len(source.encode("utf-8"))
        if size > CONVERSATION_MAX_SHARD_BYTES:
            raise CompileError(
                "canonical semantic-pack source renders above the hard shard budget: "
                + source_shard
            )
        module = source_owned_module(
            f"{module_prefix}/Packs",
            source_shard,
            names,
        )
        modules.append((module, source))
        reports.append({
            "module": module,
            "kind": "Packs",
            "domain": str(items[0].get("domain") or "general"),
            "sourceShard": source_shard,
            "recordCount": len(items),
            "recordIDs": [
                str(item.get("id"))
                for item in items
                if isinstance(item.get("id"), str)
            ],
            "bytes": size,
        })
    return modules, reports


def render_conversation_runtime_plan(
    model: dict[str, Any],
    *,
    registry_owner: str | None = None,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render bounded runtime modules using canonical source ownership."""
    registry_owner = normalize_owner(registry_owner or _registry_owner(model))
    prefix = conversation_prefix(registry_owner)
    content_modules, content_reports = render_dialogue_content_shard_plan(
        model["content"], prefix, max_bytes=CONVERSATION_MAX_SHARD_BYTES
    )
    locations = model.get("locations") or {}

    def owned(item: dict[str, Any], *, domain: str) -> dict[str, Any]:
        record_id = str(item.get("id") or "")
        owner = locations.get(record_id) if record_id else None
        source_shard = (
            owner.get("sourceShard")
            if isinstance(owner, dict)
            else None
        )
        return {
            **item,
            "domain": domain,
            "sourceShard": source_shard
            or f"{domain}/{record_id or 'general'}.json",
        }

    patterns = [
        *model["dialogue"].get("patterns", []),
        *model["semantic"].get("patterns", []),
    ]
    patterns = [
        owned(
            item,
            domain=(
                str(item.get("id", "general")).split(".")[2]
                if len(str(item.get("id", "")).split(".")) > 2
                else "general"
            ),
        )
        for item in patterns
    ]

    response_pools = [
        *model["dialogue"].get("responsePools", []),
        *model["semantic"].get("responsePools", []),
    ]
    response_pools = [
        owned(
            item,
            domain=(
                str(item.get("id", "general")).split(".")[1]
                if len(str(item.get("id", "")).split(".")) > 1
                else "general"
            ),
        )
        for item in response_pools
    ]

    flow_records = [
        owned(item, domain="semantic")
        for item in model["semantic"].get("flows", [])
    ]
    behavior_records = [
        owned(item, domain="social")
        for item in model.get("behaviors", [])
    ]
    beat_records = [
        owned(item, domain="social")
        for item in model.get("beats", [])
    ]
    realization_records = [
        owned(item, domain=str(item.get("domain") or "general"))
        for item in model.get("realization", [])
    ]
    pack_records = [
        owned(item, domain=str(item.get("domain") or "general"))
        for item in model.get("packs", [])
    ]
    ui_records = [
        owned(item, domain=str(item.get("topic") or "general"))
        for item in model["ui"]
    ]

    pattern_modules, pattern_reports = _chunk_records(
        patterns, kind="Patterns", module_prefix=prefix
    )
    response_modules, response_reports = _chunk_records(
        response_pools, kind="Responses", module_prefix=prefix
    )
    flow_modules, flow_reports = _chunk_records(
        flow_records, kind="Flows", module_prefix=prefix
    )
    behavior_modules, behavior_reports = _chunk_records(
        behavior_records, kind="Behaviors", module_prefix=prefix
    )
    beat_modules, beat_reports = _chunk_records(
        beat_records, kind="Beats", module_prefix=prefix
    )
    realization_modules, realization_reports = _chunk_records(
        realization_records, kind="Realization", module_prefix=prefix
    )
    pack_modules, pack_reports = _render_pack_shard_plan(
        pack_records,
        module_prefix=prefix,
    )
    ui_modules, ui_reports = _chunk_records(
        ui_records, kind="UI", module_prefix=prefix
    )
    modules = [
        *content_modules,
        *pattern_modules,
        *response_modules,
        *flow_modules,
        *behavior_modules,
        *beat_modules,
        *realization_modules,
        *pack_modules,
        *ui_modules,
    ]
    reports = [
        *content_reports,
        *pattern_reports,
        *response_reports,
        *flow_reports,
        *behavior_reports,
        *beat_reports,
        *realization_reports,
        *pack_reports,
        *ui_reports,
    ]

    # Canonical source ownership controls physical package ownership.  The
    # combined Hoomans registry may reference Core modules, but CodeBuilder
    # writes those modules into PsychopatzCore instead of duplicating them
    # under the PNC package.
    source_reports = {
        str(item.get("path")): item
        for item in model.get("shards", [])
        if isinstance(item, dict) and item.get("path")
    }
    routed_modules: list[tuple[str, str]] = []
    for (module, source), report in zip(modules, reports):
        owner = source_owner(model, report.get("sourceShard"))
        routed_module = route_module_for_owner(module, owner)
        source_report = source_reports.get(str(report.get("sourceShard")))
        if source_report is not None:
            for key in ("sourceOwner", "sourceRepository", "sourcePath"):
                if key in source_report:
                    report[key] = source_report[key]
        report["shardOwner"] = owner
        report["owner"] = owner
        report["registryOwner"] = registry_owner
        report["module"] = routed_module
        routed_modules.append((routed_module, source))
    modules = routed_modules

    index_modules, index_reports, _ = render_conversation_discovery_indexes(
        model,
        reports,
        module_prefix=prefix,
    )
    for report in index_reports:
        report["shardOwner"] = registry_owner
        report["owner"] = registry_owner
        report["registryOwner"] = registry_owner
    modules.extend(index_modules)
    reports.extend(index_reports)
    return modules, reports



def _runtime_record_index(model: dict[str, Any]) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}

    def add(values: Iterable[dict[str, Any]]) -> None:
        for record in values:
            if not isinstance(record, dict):
                continue
            record_id = record.get("id")
            if isinstance(record_id, str) and record_id:
                records[record_id] = record

    add(model.get("content", {}).get("phraseFamilies", []))
    add(model.get("content", {}).get("playerChoices", []))
    add(model.get("dialogue", {}).get("patterns", []))
    add(model.get("dialogue", {}).get("responsePools", []))
    add(model.get("semantic", {}).get("patterns", []))
    add(model.get("semantic", {}).get("responsePools", []))
    add(model.get("semantic", {}).get("flows", []))
    add(model.get("behaviors", []))
    add(model.get("beats", []))
    add(model.get("realization", []))
    add(model.get("packs", []))
    add(model.get("ui", []))
    return records


def _collect_known_ids(
    value: Any,
    known_ids: set[str],
    output: set[str],
    *,
    depth: int = 0,
) -> None:
    if depth > 8:
        return
    if isinstance(value, str):
        if value in known_ids:
            output.add(value)
        return
    if isinstance(value, list):
        for item in value[:64]:
            _collect_known_ids(
                item,
                known_ids,
                output,
                depth=depth + 1,
            )
        return
    if isinstance(value, dict):
        for key in sorted(value, key=str)[:64]:
            _collect_known_ids(
                value[key],
                known_ids,
                output,
                depth=depth + 1,
            )


def conversation_discovery_index(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    relation_limit: int = 8,
    generated_limit: int = 6,
) -> dict[str, dict[str, Any]]:
    """Build a bounded ID->source->generated routing index."""
    locations = model.get("locations") or {}
    known_ids = set(locations)
    generated_by_id: dict[str, str] = {}
    generated_by_source: dict[str, list[str]] = {}
    for report in reports:
        if report.get("kind") in ("Index", "IndexRegistry"):
            continue
        module = report.get("module")
        source_shard = report.get("sourceShard")
        if isinstance(module, str) and isinstance(source_shard, str):
            modules = generated_by_source.setdefault(source_shard, [])
            if module not in modules:
                modules.append(module)
        for record_id in report.get("recordIDs", []):
            if isinstance(record_id, str) and isinstance(module, str):
                generated_by_id[record_id] = module

    runtime_records = _runtime_record_index(model)
    related: dict[str, list[str]] = {}
    dependents: dict[str, set[str]] = {}
    for record_id, record in sorted(runtime_records.items()):
        refs: set[str] = set()
        _collect_known_ids(record, known_ids, refs)
        refs.discard(record_id)
        selected = sorted(refs)[:relation_limit]
        if selected:
            related[record_id] = selected
        for target in selected:
            dependents.setdefault(target, set()).add(record_id)

    index: dict[str, dict[str, Any]] = {}
    for record_id in sorted(locations):
        location = locations[record_id]
        source_shard = str(location.get("sourceShard") or "")
        direct = generated_by_id.get(record_id)
        generated = (
            [direct]
            if direct
            else sorted(generated_by_source.get(source_shard, []))[
                :generated_limit
            ]
        )
        entry = {
            "id": record_id,
            "kind": str(location.get("kind") or "unknown"),
            "domain": str(location.get("domain") or "general"),
            "source": source_shard,
            "generated": generated,
        }
        if related.get(record_id):
            entry["related"] = related[record_id]
        reverse = sorted(dependents.get(record_id, set()))[:relation_limit]
        if reverse:
            entry["dependents"] = reverse
        index[record_id] = entry
    return index


def render_conversation_discovery_indexes(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    module_prefix: str | None = None,
) -> tuple[
    list[tuple[str, str]],
    list[dict[str, Any]],
    dict[str, dict[str, Any]],
]:
    """Render small source-routing indexes without aggregating definitions."""
    if module_prefix is None:
        module_prefix = conversation_prefix(_registry_owner(model))
    index = conversation_discovery_index(model, reports)
    grouped: dict[tuple[str, str], dict[str, dict[str, Any]]] = {}
    for record_id, entry in index.items():
        key = (entry["kind"], entry["domain"])
        grouped.setdefault(key, {})[record_id] = entry

    modules: list[tuple[str, str]] = []
    index_reports: list[dict[str, Any]] = []
    manifest_rows: list[dict[str, Any]] = []
    for (kind, domain) in sorted(grouped):
        payload = grouped[(kind, domain)]
        source = (
            "-- Generated Conversation discovery index; do not edit by hand.\n"
            "return " + _lua_value(payload, 0) + "\n"
        )
        size = len(source.encode("utf-8"))
        if size > CONVERSATION_MAX_INDEX_BYTES:
            raise CompileError(
                "Conversation discovery index exceeds the hard index budget; "
                f"split the ownership domain: {kind}/{domain}"
            )
        module = (
            f"{module_prefix}/Index/"
            f"{pascal_segment(kind)}/{pascal_segment(domain)}"
        )
        modules.append((module, source))
        ids = sorted(payload)
        index_reports.append({
            "module": module,
            "kind": "Index",
            "domain": domain,
            "indexKind": kind,
            "sourceShard": f"@index/{kind}/{domain}",
            "recordCount": len(ids),
            "recordIDs": ids,
            "bytes": size,
        })
        manifest_rows.append({
            "kind": kind,
            "domain": domain,
            "module": module,
            "recordCount": len(ids),
        })

    registry_module = f"{module_prefix}/Index/Registry"
    registry_source = (
        "-- Generated Conversation discovery index registry; do not edit by hand.\n"
        "return " + _lua_value(manifest_rows, 0) + "\n"
    )
    registry_size = len(registry_source.encode("utf-8"))
    if registry_size > CONVERSATION_MAX_INDEX_BYTES:
        raise CompileError(
            "Conversation discovery index registry exceeds the hard index budget"
        )
    modules.append((registry_module, registry_source))
    index_reports.append({
        "module": registry_module,
        "kind": "IndexRegistry",
        "domain": "index",
        "sourceShard": "@index/registry",
        "recordCount": len(manifest_rows),
        "recordIDs": [],
        "bytes": registry_size,
    })
    return modules, index_reports, index


def conversation_affected_closure(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    canonical_id: str,
    *,
    limit: int = 24,
) -> dict[str, Any] | None:
    """Return a bounded one-hop dependency/source/generated closure."""
    index = conversation_discovery_index(model, reports)
    root = index.get(str(canonical_id))
    if root is None:
        return None
    ids = [str(canonical_id)]
    for field in ("related", "dependents"):
        for value in root.get(field, []):
            if value not in ids and len(ids) < limit:
                ids.append(value)
    entries = [index[value] for value in ids if value in index]
    generated = sorted({
        module
        for entry in entries
        for module in entry.get("generated", [])
    })
    sources = sorted({
        entry["source"]
        for entry in entries
        if entry.get("source")
    })
    return {
        "id": str(canonical_id),
        "entry": root,
        "closureIDs": ids,
        "sources": sources,
        "generated": generated,
        "entries": entries,
        "truncated": len(ids) >= limit,
    }


def conversation_context_health(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
) -> dict[str, Any]:
    """Return configurable context-budget evidence for canonical/generated data."""
    repository = model.get("_repository")
    source_root = (
        repository / CONVERSATION_SOURCE_RELATIVE
        if isinstance(repository, Path)
        else None
    )
    sources: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    for report in model.get("shards", []):
        path = str(report.get("path") or "")
        size = 0
        external_repository = report.get("sourceRepository")
        external_path = report.get("sourcePath")
        if external_repository and external_path:
            source_path = Path(external_repository) / Path(
                *PurePosixPath(str(external_path)).parts
            )
        elif source_root is not None:
            source_path = source_root / path
        else:
            source_path = None
        if source_path is not None and source_path.is_file():
            size = source_path.stat().st_size
        record_count = len(report.get("recordIDs", []))
        row = {
            "path": path,
            "kind": report.get("kind"),
            "domain": report.get("domain"),
            "bytes": size,
            "recordCount": record_count,
        }
        sources.append(row)
        if size > CONVERSATION_MAX_SOURCE_BYTES:
            errors.append({
                "type": "source_bytes_hard",
                "path": path,
                "value": size,
                "limit": CONVERSATION_MAX_SOURCE_BYTES,
            })
        elif size > CONVERSATION_PREFERRED_SOURCE_BYTES:
            warnings.append({
                "type": "source_bytes_preferred",
                "path": path,
                "value": size,
                "limit": CONVERSATION_PREFERRED_SOURCE_BYTES,
            })

    generated: list[dict[str, Any]] = []
    numeric: list[str] = []
    opaque: list[str] = []
    missing_ownership: list[str] = []
    forbidden_opaque = {"Massive", "Sgd"}
    for report in reports:
        row = {
            key: _copy_json(report.get(key))
            for key in (
                "module",
                "kind",
                "domain",
                "sourceShard",
                "recordCount",
                "bytes",
            )
        }
        generated.append(row)
        module = str(report.get("module") or "")
        final = module.rsplit("/", 1)[-1]
        if re.search(r"Part\d+$", final):
            numeric.append(module)
        if final in forbidden_opaque:
            opaque.append(module)
        if report.get("kind") not in ("Index", "IndexRegistry") and not report.get(
            "sourceShard"
        ):
            missing_ownership.append(module)
        size = int(report.get("bytes") or 0)
        count = int(report.get("recordCount") or 0)
        limit = (
            CONVERSATION_MAX_INDEX_BYTES
            if report.get("kind") in ("Index", "IndexRegistry")
            else CONVERSATION_MAX_SHARD_BYTES
        )
        if size > limit:
            errors.append({
                "type": "generated_bytes_hard",
                "module": module,
                "value": size,
                "limit": limit,
            })
        elif (
            report.get("kind") not in ("Index", "IndexRegistry")
            and size > CONVERSATION_PREFERRED_SHARD_BYTES
        ):
            warnings.append({
                "type": "generated_bytes_preferred",
                "module": module,
                "value": size,
                "limit": CONVERSATION_PREFERRED_SHARD_BYTES,
            })
        if report.get("kind") not in ("Index", "IndexRegistry"):
            if count > CONVERSATION_MAX_RECORDS_PER_SHARD:
                errors.append({
                    "type": "generated_records_hard",
                    "module": module,
                    "value": count,
                    "limit": CONVERSATION_MAX_RECORDS_PER_SHARD,
                })
            elif count > CONVERSATION_PREFERRED_RECORDS_PER_SHARD:
                warnings.append({
                    "type": "generated_records_preferred",
                    "module": module,
                    "value": count,
                    "limit": CONVERSATION_PREFERRED_RECORDS_PER_SHARD,
                })

    for module in numeric:
        errors.append({"type": "numeric_shard_name", "module": module})
    for module in opaque:
        errors.append({"type": "opaque_shard_name", "module": module})
    for module in missing_ownership:
        errors.append({"type": "generated_owner_missing", "module": module})

    largest_sources = sorted(
        sources,
        key=lambda item: (-int(item["bytes"]), item["path"]),
    )[:12]
    largest_generated = sorted(
        generated,
        key=lambda item: (-int(item["bytes"] or 0), str(item["module"])),
    )[:12]

    return {
        "schema": "pnc.conversation.context-health.v1",
        "status": "pass" if not errors else "fail",
        "policy": {
            "preferredSourceBytes": CONVERSATION_PREFERRED_SOURCE_BYTES,
            "maxSourceBytes": CONVERSATION_MAX_SOURCE_BYTES,
            "preferredGeneratedBytes": CONVERSATION_PREFERRED_SHARD_BYTES,
            "maxGeneratedBytes": CONVERSATION_MAX_SHARD_BYTES,
            "preferredDefinitionsPerShard":
                CONVERSATION_PREFERRED_RECORDS_PER_SHARD,
            "maxDefinitionsPerShard": CONVERSATION_MAX_RECORDS_PER_SHARD,
            "maxIndexBytes": CONVERSATION_MAX_INDEX_BYTES,
        },
        "sourceCount": len(sources),
        "generatedCount": len(generated),
        "largestSources": largest_sources,
        "largestGenerated": largest_generated,
        "numericShardViolations": numeric,
        "opaqueShardViolations": opaque,
        "missingOwnership": missing_ownership,
        "warnings": warnings,
        "errors": errors,
        # Cross-reference/collision/orphan checks are compile-time fatal in
        # compile_conversation_sources; reaching this report means they passed.
        "referenceFailures": [],
        "collisionFailures": {},
        "orphanFailures": [],
    }


def _lua_namespace_prelude(namespace: str) -> list[str]:
    parts = [part for part in str(namespace).split(".") if part]
    if len(parts) < 2:
        raise CompileError(f"Conversation registry namespace is invalid: {namespace}")
    lines = [f"{parts[0]} = {parts[0]} or {{}}"]
    current = parts[0]
    for part in parts[1:-1]:
        current += "." + part
        lines.append(f"{current} = {current} or {{}}")
    full = ".".join(parts)
    lines.extend([
        f"local Registry = {full} or {{}}",
        f"{full} = Registry",
    ])
    return lines


def render_conversation_registry(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    registry_owner: str | None = None,
    include_owner: str | None = None,
    include_owners: tuple[str, ...] | None = None,
    registry_module: str | None = None,
) -> str:
    registry_owner = normalize_owner(registry_owner or _registry_owner(model))
    descriptor = package_descriptor(registry_owner)
    include_owner = (
        normalize_owner(include_owner) if include_owner is not None else None
    )
    normalized_include_owners = None
    if include_owners is not None:
        normalized_include_owners = {
            normalize_owner(owner) for owner in include_owners
        }
    registry_module = registry_module or descriptor.registry_module
    lines = [
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.",
        *_lua_namespace_prelude(descriptor.registry_namespace),
        f"Registry.OWNER = {_lua_string(registry_owner)}",
        f"Registry.REGISTRY_NAMESPACE = {_lua_string(descriptor.registry_namespace)}",
        f"Registry.REGISTRY_MODULE = {_lua_string(registry_module)}",
        f"Registry.SCHEMA = {_lua_string(CONVERSATION_MODEL_SCHEMA)}",
        "Registry.VERSION = 1",
        f"Registry.CONTENT_FINGERPRINT = {_lua_string(model['content']['contentFingerprint'])}",
        f"Registry.WHOLE_MODEL_FINGERPRINT = {_lua_string(model['wholeModelFingerprint'])}",
        "Registry.PHRASE_FAMILIES = {}",
        "Registry.PLAYER_CHOICES = {}",
        "Registry.PATTERNS = {}",
        "Registry.RESPONSE_POOLS = {}",
        "Registry.FLOWS = {}",
        "Registry.BEHAVIORS = {}",
        "Registry.BEATS = {}",
          "Registry.PACKS = {}",
        "Registry.UI = {}",
    ]
    lines.extend([
        "local function appendContent(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PHRASE_FAMILIES[key] = value end",
        "end",
        "local function appendContentChoices(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PLAYER_CHOICES[key] = value end",
        "end",
        "local function appendPatterns(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.PATTERNS[#Registry.PATTERNS + 1] = value end",
        "end",
        "local function appendResponses(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.RESPONSE_POOLS[#Registry.RESPONSE_POOLS + 1] = value end",
        "end",
        "local function appendFlows(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.FLOWS[#Registry.FLOWS + 1] = value end",
        "end",
        "local function appendBehaviors(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.BEHAVIORS[#Registry.BEHAVIORS + 1] = value end",
        "end",
        "local function appendBeats(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.BEATS[#Registry.BEATS + 1] = value end",
        "end",
          "local function appendPacks(loaded)",
          "    if type(loaded) ~= \"table\" then return end",
          "    for _, value in ipairs(loaded) do Registry.PACKS[#Registry.PACKS + 1] = value end",
          "end",
        "local function appendUI(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.UI[#Registry.UI + 1] = value end",
        "end",
    ])
    loaded_index = 0
    for report in reports:
        if report.get("kind") in ("Index", "IndexRegistry"):
            continue
        if include_owner is not None and report.get("owner") != include_owner:
            continue
        if normalized_include_owners is not None and report.get("owner") not in normalized_include_owners:
            continue
        name = report["module"]
        loaded_index += 1
        loaded_name = f"loaded{loaded_index:02d}"
        lines.append(f"local {loaded_name} = require {_lua_string(name)}")
        if report["kind"] == "Content":
            lines.append(f"appendContent({loaded_name})")
        elif report["kind"] == "ContentChoices":
            lines.append(f"appendContentChoices({loaded_name})")
        elif report["kind"] == "Patterns":
            lines.append(f"appendPatterns({loaded_name})")
        elif report["kind"] == "Responses":
            lines.append(f"appendResponses({loaded_name})")
        elif report["kind"] == "Flows":
            lines.append(f"appendFlows({loaded_name})")
        elif report["kind"] == "Behaviors":
            lines.append(f"appendBehaviors({loaded_name})")
        elif report["kind"] == "Beats":
            lines.append(f"appendBeats({loaded_name})")
        elif report["kind"] == "Packs":
            lines.append(f"appendPacks({loaded_name})")
        elif report["kind"] == "UI":
            lines.append(f"appendUI({loaded_name})")
    lines.extend([
        "for key, family in pairs(Registry.PHRASE_FAMILIES) do",
        "    if type(family) == \"table\" and family.id then Registry.PHRASE_FAMILIES[key] = family end",
        "end",
        "function Registry.FamilyFor(templateID, style)",
        "    local family = Registry.PHRASE_FAMILIES[tostring(templateID or \"\")]",
        "    if type(family) ~= \"table\" then return nil end",
        "    local selectedStyle = tostring(style or \"neutral\")",
        "    local phrases = family.styles and family.styles[selectedStyle]",
        "    if type(phrases) ~= \"table\" then",
        "        selectedStyle = \"neutral\"",
        "        phrases = family.styles and family.styles[selectedStyle]",
        "    end",
        "    return family, type(phrases) == \"table\" and phrases or nil, selectedStyle",
        "end",
        "function Registry.PlayerChoice(contentID)",
        "    return Registry.PLAYER_CHOICES[tostring(contentID or \"\")]",
        "end",
        "return Registry",
        "",
    ])
    return "\n".join(lines)


def render_conversation_manifest_lua(
    model: dict[str, Any],
    reports: list[dict[str, Any]],
    *,
    registry_owner: str | None = None,
) -> str:
    registry_owner = normalize_owner(registry_owner or _registry_owner(model))
    descriptor = package_descriptor(registry_owner)
    payload = {
        "schema": "pnc.conversation.runtime-manifest.v1",
        "registryOwner": registry_owner,
        "registryNamespace": descriptor.registry_namespace,
        "registryModule": descriptor.registry_module,
        "wholeModelFingerprint": model["wholeModelFingerprint"],
        "shards": reports,
    }
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(payload, 0) + "\n"
    )
