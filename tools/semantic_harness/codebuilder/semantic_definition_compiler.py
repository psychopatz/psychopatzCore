"""Compile typed Semantic Lab definitions into deterministic data-only assets.

This module owns the canonical pnc.semantic_authoring.v1 pipeline. The public
compiler facade re-exports its names for established callers and adapters.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Iterable, Mapping

from .dialogue_contract import (
    DIALOGUE_ID,
    DIALOGUE_LUA_CHUNK_MAX_CHARS,
    _normalize_dialogue_utterance,
)
from .dialogue_rendering import _lua_value
from .lexicon_compiler import CompileError, _lua_string
from .dialogue_contract import validate_branch_offers
from tools.semantic_harness.codebuilder.catalog_naming import ModuleNameRegistry, module_path, pascal_segment
from .generation_ownership import (
    HOOMANS_OWNER,
    PACKAGE_DESCRIPTORS,
    normalize_owner,
)
from tools.semantic_harness.codebuilder.translation_support import DEFAULT_LANGUAGE, normalize_translations

SEMANTIC_SCHEMA = "pnc.semantic_authoring.v1"


def _semantic_metadata(value: Any, label: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise CompileError(f"{label} must be an object")
    try:
        encoded = json.dumps(value, ensure_ascii=False, sort_keys=True)
    except (TypeError, ValueError) as error:
        raise CompileError(f"{label} must be JSON-serializable") from error
    if len(encoded) > 16_384:
        raise CompileError(f"{label} exceeds the metadata size bound")
    return json.loads(encoded)
SEMANTIC_FRAME_FIELDS = frozenset({
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
})
DEFAULT_REGISTERED_CAPABILITY_IDS = frozenset({
    "pnc:companion.follow", "pnc:companion.stop", "pnc:companion.stay",
    "pnc:companion.return_home", "pnc:companion.camp", "pnc:task.wait_at",
    "pnc:gift.offer",
})
DEFAULT_RESERVED_UTTERANCES = frozenset({
    "follow", "follow me", "stop", "wait", "wait here",
})


def load_semantic_source(path: Path) -> dict[str, Any]:
    """Load one reviewed declarative semantic-authoring source document."""
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read semantic source {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError("semantic source root must be an object")
    return document


def discover_registered_capability_ids(
    runtime_root: Path,
    *,
    package_repositories: Mapping[str, Path] | None = None,
    owners: Iterable[Any] | None = None,
) -> set[str]:
    """Read capability IDs from descriptor-owned semantic catalogs.

    The Hoomans runtime root remains the compatibility default. Optional
    package repositories are explicit inputs; missing optional repositories
    contribute only their descriptor-declared IDs and do not break discovery.
    """
    repositories: dict[str, Path] = {HOOMANS_OWNER: runtime_root}
    for raw_owner, repository in (package_repositories or {}).items():
        repositories[normalize_owner(raw_owner)] = Path(repository).expanduser().resolve()

    selected = (
        [normalize_owner(owner) for owner in owners]
        if owners is not None
        else list(PACKAGE_DESCRIPTORS)
    )
    capabilities: set[str] = set()
    for owner in selected:
        descriptor = PACKAGE_DESCRIPTORS[owner]
        capabilities.update(descriptor.capability_ids)
        repository = repositories.get(owner)
        if repository is None:
            continue
        for glob in descriptor.capability_globs:
            for path in sorted(repository.glob(glob)):
                try:
                    text = path.read_text(encoding="utf-8")
                except OSError:
                    continue
                for field in descriptor.capability_fields:
                    pattern = re.compile(
                        rf'{re.escape(field)}\s*=\s*["\']([^"\']+)["\']'
                    )
                    capabilities.update(pattern.findall(text))
    return capabilities


def _semantic_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not DIALOGUE_ID.fullmatch(value):
        raise CompileError(f"{label} must be a lowercase dotted identifier")
    return value


def _semantic_text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip() or len(value) > 256:
        raise CompileError(f"{label} must be a non-empty bounded string")
    return value.strip()


def _semantic_frame(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or not value:
        raise CompileError(f"{label} must be a non-empty object")
    output: dict[str, Any] = {}
    for key, item in value.items():
        if key not in SEMANTIC_FRAME_FIELDS:
            raise CompileError(f"{label} contains unsupported field {key!r}")
        if not isinstance(item, (str, int, float, bool)):
            raise CompileError(f"{label}.{key} must be scalar")
        output[key] = item
    return output


def _semantic_match(utterance: str) -> list[dict[str, str]]:
    _normalized, tokens = _normalize_dialogue_utterance(utterance)
    return [{"kind": "literal", "value": token} for token in tokens]


def _semantic_slug(utterance: str) -> str:
    normalized, _tokens = _normalize_dialogue_utterance(utterance)
    slug = re.sub(r"[^a-z0-9]+", "_", normalized).strip("_")
    return slug or "utterance"


def _semantic_flow(
    value: Any,
    definition_id: str,
    response_pool_ids: set[str],
    pattern_ids: set[str],
) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError(f"semantic definition {definition_id} requires a flow")
    flow_id = _semantic_id(value.get("id"), f"flow for {definition_id}")
    version = value.get("version", 1)
    if isinstance(version, bool) or not isinstance(version, int) or version < 1:
        raise CompileError(f"flow {flow_id} requires a positive integer version")
    triggers = value.get("triggers")
    if not isinstance(triggers, list) or not triggers or len(triggers) > 8:
        raise CompileError(f"flow {flow_id} requires 1..8 triggers")
    normalized_triggers = [
        _semantic_frame(trigger, f"flow {flow_id} trigger")
        for trigger in triggers
    ]
    for trigger in normalized_triggers:
        if "pattern" in trigger and trigger["pattern"] not in pattern_ids:
            raise CompileError(
                f"flow {flow_id} trigger references unknown authored pattern "
                f"{trigger['pattern']}"
            )
    nodes = value.get("nodes")
    if not isinstance(nodes, dict) or not nodes or len(nodes) > 32:
        raise CompileError(f"flow {flow_id} requires 1..32 nodes")
    initial = value.get("initial")
    if not isinstance(initial, str) or initial not in nodes:
        raise CompileError(f"flow {flow_id} initial node is missing")

    normalized_nodes: dict[str, dict[str, Any]] = {}
    transition_fields = (
        "next", "onMatch", "onUnrelated", "onRefuse", "onPass", "onFail",
        "onUnknown",
    )
    special_targets = {"cancel", "resume", "suspend"}
    for node_id in sorted(nodes):
        if not isinstance(node_id, str) or not node_id:
            raise CompileError(f"flow {flow_id} contains an invalid node id")
        node = nodes[node_id]
        if not isinstance(node, dict):
            raise CompileError(f"flow {flow_id} node {node_id} must be an object")
        allowed = {
            "terminal", "responsePool", "responseTemplate", "gate", "slots",
            "accepts", "branchOffers", *transition_fields,
        }
        unsupported = set(node) - allowed
        if unsupported:
            raise CompileError(
                f"flow {flow_id} node {node_id} contains unsupported fields: "
                + ", ".join(sorted(unsupported))
            )
        normalized: dict[str, Any] = {"id": node_id, "terminal": node.get("terminal", False) is True}
        for field in ("responsePool", "responseTemplate"):
            if field in node:
                if not isinstance(node[field], str) or not node[field]:
                    raise CompileError(f"flow {flow_id} node {node_id} has invalid {field}")
                if field == "responsePool" and node[field] not in response_pool_ids:
                    raise CompileError(
                        f"flow {flow_id} node {node_id} references missing response pool "
                        f"{node[field]}"
                    )
                normalized[field] = node[field]
        if "gate" in node:
            if not isinstance(node["gate"], dict) or not node["gate"].get("type"):
                raise CompileError(f"flow {flow_id} node {node_id} has invalid gate")
            normalized["gate"] = node["gate"]
        if "slots" in node:
            if not isinstance(node["slots"], dict):
                raise CompileError(f"flow {flow_id} node {node_id} slots must be an object")
            normalized["slots"] = node["slots"]
        accepts = node.get("accepts", [])
        if not isinstance(accepts, list) or len(accepts) > 16:
            raise CompileError(f"flow {flow_id} node {node_id} accepts must be bounded")
        normalized["accepts"] = [
            _semantic_frame(frame, f"flow {flow_id} node {node_id} accept")
            for frame in accepts
        ]
        if "branchOffers" in node:
            normalized["branchOffers"] = validate_branch_offers(
                node.get("branchOffers"),
                f"flow {flow_id} node {node_id} branchOffers",
            )
        for field in transition_fields:
            if field not in node:
                continue
            target = node[field]
            if not isinstance(target, str) or not target:
                raise CompileError(f"flow {flow_id} node {node_id} has invalid {field}")
            if target not in special_targets and target not in nodes:
                raise CompileError(
                    f"flow {flow_id} node {node_id} references unknown node {target}"
                )
            normalized[field] = target
        if not normalized["terminal"] and not normalized["accepts"]:
            raise CompileError(f"flow {flow_id} node {node_id} requires accepts")
        if not normalized["terminal"] and not any(
            field in normalized for field in transition_fields
        ):
            raise CompileError(f"flow {flow_id} node {node_id} requires a transition")
        normalized_nodes[node_id] = normalized

    seen: set[str] = set()
    pending = [initial]
    while pending:
        node_id = pending.pop(0)
        if node_id in seen or node_id in special_targets:
            continue
        seen.add(node_id)
        node = normalized_nodes[node_id]
        for field in transition_fields:
            target = node.get(field)
            if target and target not in seen and target not in special_targets:
                pending.append(target)
    unreachable = sorted(set(normalized_nodes) - seen)
    if unreachable:
        raise CompileError(
            f"flow {flow_id} contains unreachable nodes: {', '.join(unreachable)}"
        )
    return {
        "id": flow_id,
        "version": version,
        "owner": _semantic_text(value.get("owner", "ProjectHoomans"), f"flow {flow_id} owner"),
        "initial": initial,
        "triggers": normalized_triggers,
        "nodes": normalized_nodes,
    }


def _semantic_responses(
    value: Any,
    definition_id: str,
) -> tuple[dict[str, Any], dict[str, dict[str, str]]]:
    if not isinstance(value, dict):
        raise CompileError(f"semantic definition {definition_id} requires responses")
    pool_id = _semantic_id(value.get("poolID"), f"responses for {definition_id}")
    if not pool_id.startswith("semantic."):
        raise CompileError(f"response pool {pool_id} must use semantic.* namespace")
    variants = value.get("variants")
    if not isinstance(variants, list) or not variants or len(variants) > 16:
        raise CompileError(f"response pool {pool_id} requires 1..16 variants")
    compiled: list[dict[str, Any]] = []
    translations: dict[str, dict[str, str]] = {}
    seen_ids: set[str] = set()
    for variant in variants:
        if not isinstance(variant, dict):
            raise CompileError(f"response variant in {pool_id} must be an object")
        variant_id = _semantic_id(variant.get("id"), f"response variant in {pool_id}")
        if variant_id in seen_ids:
            raise CompileError(f"duplicate response variant {pool_id}:{variant_id}")
        seen_ids.add(variant_id)
        key = variant.get("key")
        if not isinstance(key, str) or not key.startswith("UI_PNC_"):
            raise CompileError(f"response variant {pool_id}:{variant_id} requires UI_PNC key")

        localized = normalize_translations(
            variant.get("translations"),
            f"response {key}.translations",
        )

        for language, text in localized.items():
            bucket = translations.setdefault(language, {})
            if key in bucket:
                raise CompileError(f"duplicate translation key {key}")
            bucket[key] = text

        compiled_variant: dict[str, Any] = {
            "id": variant_id,
            "templateID": key,
            "fallback": localized[DEFAULT_LANGUAGE],
        }
        if "when" in variant:
            compiled_variant["when"] = _validate_response_condition(
                variant["when"], pool_id, variant_id
            )
        priority = variant.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, int) or not -10 <= priority <= 10:
            raise CompileError(f"response priority {pool_id}:{variant_id} must be -10..10")
        if priority:
            compiled_variant["priority"] = priority
        compiled.append(compiled_variant)
    return {"id": pool_id, "variants": compiled}, {
        language: {key: values[key] for key in sorted(values)}
        for language, values in sorted(translations.items())
    }


def compile_semantic_definitions(
    document: dict[str, Any],
    registered_capability_ids: set[str] | frozenset[str] | None = None,
    reserved_utterances: set[str] | frozenset[str] | None = None,
) -> dict[str, Any]:
    """Compile one canonical semantic-authoring document into data-only artifacts."""
    if not isinstance(document, dict) or document.get("schema") != SEMANTIC_SCHEMA:
        raise CompileError(f"semantic source requires schema {SEMANTIC_SCHEMA}")
    source = document.get("source")
    if not isinstance(source, dict):
        raise CompileError("semantic source requires source metadata")
    source_owner = _semantic_text(source.get("owner"), "semantic source owner")
    source_version = _semantic_text(source.get("version"), "semantic source version")
    definitions = document.get("definitions")
    if not isinstance(definitions, list) or not definitions or len(definitions) > 32:
        raise CompileError("semantic source requires 1..32 definitions")
    capabilities = set(DEFAULT_REGISTERED_CAPABILITY_IDS)
    capabilities.update(registered_capability_ids or ())
    reserved = {
        _normalize_dialogue_utterance(item)[0]
        for item in (reserved_utterances or DEFAULT_RESERVED_UTTERANCES)
    }
    patterns: list[dict[str, Any]] = []
    flows: list[dict[str, Any]] = []
    response_pools: list[dict[str, Any]] = []
    translations: dict[str, dict[str, str]] = {}
    seen_definition_ids: set[str] = set()
    seen_flow_ids: set[str] = set()
    seen_pool_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    for definition in definitions:
        if not isinstance(definition, dict):
            raise CompileError("semantic definitions must be objects")
        definition_id = _semantic_id(definition.get("id"), "semantic definition id")
        if definition_id in seen_definition_ids:
            raise CompileError(f"duplicate semantic definition id {definition_id}")
        seen_definition_ids.add(definition_id)
        capability = definition.get("capability")
        if not isinstance(capability, str) or capability not in capabilities:
            raise CompileError(
                f"semantic definition {definition_id} references unregistered capability "
                f"{capability!r}"
            )
        metadata = _semantic_metadata(
            definition.get("metadata"),
            f"semantic definition {definition_id} metadata",
        )
        emit = definition.get("emit")
        if not isinstance(emit, dict):
            raise CompileError(f"semantic definition {definition_id} requires emit")
        normalized_emit = _semantic_frame(emit, f"semantic definition {definition_id} emit")
        if normalized_emit.get("intent") != "REQUEST" or normalized_emit.get("speechAct") != "REQUEST":
            raise CompileError(f"semantic definition {definition_id} must emit REQUEST/REQUEST")
        action = normalized_emit.get("action")
        if not isinstance(action, str) or not action:
            raise CompileError(f"semantic definition {definition_id} requires an action")
        if capability.endswith(".follow") and action != "FOLLOW":
            raise CompileError(f"semantic definition {definition_id} action does not match FOLLOW capability")
        utterances = definition.get("utterances")
        if not isinstance(utterances, dict):
            raise CompileError(f"semantic definition {definition_id} requires utterances")
        positives = utterances.get("positives")
        negatives = utterances.get("negatives")
        if not isinstance(positives, list) or not positives or not isinstance(negatives, list) or not negatives:
            raise CompileError(f"semantic definition {definition_id} requires positive and negative examples")
        normalized_negatives = {
            _normalize_dialogue_utterance(item)[0] for item in negatives
        }
        for negative in normalized_negatives:
            if negative in reserved:
                continue
        definition_pattern_ids: set[str] = set()
        for utterance in positives:
            normalized, _tokens = _normalize_dialogue_utterance(utterance)
            if normalized in normalized_negatives:
                raise CompileError(
                    f"semantic definition {definition_id} has positive/negative collision: {normalized}"
                )
            if normalized in reserved:
                raise CompileError(
                    f"semantic definition {definition_id} collides with registered utterance: {normalized}"
                )
            if normalized in seen_utterances:
                raise CompileError(
                    f"semantic utterance collision {normalized} between "
                    f"{seen_utterances[normalized]} and {definition_id}"
                )
            if re.match(r"^(don't|do not|are you|is you|did you|i )\b", normalized):
                raise CompileError(
                    f"semantic positive example is not an executable imperative: {normalized}"
                )
            seen_utterances[normalized] = definition_id
            pattern_id = f"{definition_id}.{_semantic_slug(normalized)}"
            definition_pattern_ids.add(pattern_id)
            pattern = {
                "id": pattern_id,
                "match": _semantic_match(normalized),
                "emit": normalized_emit,
                "confidence": definition.get("confidence", 0.99),
                "priority": definition.get("priority", 160),
            }
            if metadata:
                pattern["metadata"] = json.loads(
                    json.dumps(metadata, ensure_ascii=False)
                )
            patterns.append(pattern)
        response_pool, definition_translations = _semantic_responses(
            definition.get("responses"), definition_id
        )
        if metadata:
            response_pool["metadata"] = json.loads(
                json.dumps(metadata, ensure_ascii=False)
            )
        if response_pool["id"] in seen_pool_ids:
            raise CompileError(f"duplicate semantic response pool {response_pool['id']}")
        seen_pool_ids.add(response_pool["id"])
        for language, localized in sorted(definition_translations.items()):
            bucket = translations.setdefault(language, {})
            for key, text in localized.items():
                if key in bucket:
                    raise CompileError(f"duplicate semantic translation key {key}")
                bucket[key] = text
        flow = _semantic_flow(
            definition.get("flow"),
            definition_id,
            seen_pool_ids | {response_pool["id"]},
            definition_pattern_ids,
        )
        if metadata:
            flow["metadata"] = json.loads(
                json.dumps(metadata, ensure_ascii=False)
            )
        if flow["id"] in seen_flow_ids:
            raise CompileError(f"duplicate semantic flow id {flow['id']}")
        seen_flow_ids.add(flow["id"])
        for trigger in flow["triggers"]:
            if trigger.get("action") != action:
                raise CompileError(
                    f"flow {flow['id']} trigger action must match {definition_id} action"
                )
        response_pools.append(response_pool)
        flows.append(flow)
    patterns.sort(key=lambda item: item["id"])
    flows.sort(key=lambda item: item["id"])
    response_pools.sort(key=lambda item: item["id"])
    return {
        "schema": SEMANTIC_SCHEMA,
        "source": {"owner": source_owner, "version": source_version},
        "patterns": patterns,
        "flows": flows,
        "responsePools": response_pools,
        "translations": {
            language: {key: values[key] for key in sorted(values)}
            for language, values in sorted(translations.items())
        },
    }


def _render_semantic_chunk(kind: str, label: str, records: list[dict[str, Any]]) -> str:
    lines = [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        f"-- Semantic {label} catalog; keep file data-only.",
        "return {",
    ]
    for record in records:
        rendered = _lua_value(record, 4)
        lines.append("    " + rendered.replace("\n", "\n    ") + ",")
    lines.extend(["}", ""])
    return "\n".join(lines)


def _split_semantic_records(
    kind: str,
    label: str,
    records: list[dict[str, Any]],
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[str]:
    shards: list[str] = []
    current: list[dict[str, Any]] = []
    for record in records:
        candidate = current + [record]
        rendered = _render_semantic_chunk(kind, label, candidate)
        if current and len(rendered) > max_chars:
            shards.append(_render_semantic_chunk(kind, label, current))
            current = [record]
        else:
            current = candidate
    if current or not shards:
        shards.append(_render_semantic_chunk(kind, label, current))
    if any(len(shard) > max_chars for shard in shards):
        raise CompileError(f"semantic {kind} shard exceeds the {max_chars}-character output budget")
    return shards


def _semantic_group(kind: str, record: dict[str, Any]) -> tuple[str, list[str]]:
    """Return a stable definition group and readable path segments."""
    identifier = str(record.get("id", "catalog.unknown"))
    parts = identifier.split(".")
    if kind == "patterns" and len(parts) >= 3:
        return ".".join(parts[:3]), parts[1:3]
    if kind == "flows" and len(parts) >= 3:
        base = parts[:-1] if parts[-1] == "flow" else parts
        return ".".join(base), parts[1:-1] or parts[1:]
    response_parts = parts[1:] if parts and parts[0] == "semantic" else parts
    if len(response_parts) > 1:
        response_parts = [response_parts[0], "_".join(response_parts[1:])]
    return identifier, response_parts or ["Catalog"]


def render_semantic_lua_plan(
    compiled: dict[str, Any],
    module_prefix: str,
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> tuple[list[tuple[str, str]], dict[str, list[dict[str, Any]]]]:
    """Plan readable semantic-definition modules and their logical index."""
    rendered: list[tuple[str, str]] = []
    manifest: dict[str, list[dict[str, Any]]] = {
        "patterns": [],
        "flows": [],
        "responsePools": [],
    }
    registry = ModuleNameRegistry()
    for kind, key in (("patterns", "patterns"), ("flows", "flows"), ("responses", "responsePools")):
        groups: dict[str, tuple[list[str], list[dict[str, Any]]]] = {}
        for record in compiled[key]:
            canonical_id, segments = _semantic_group(kind, record)
            if canonical_id not in groups:
                groups[canonical_id] = (segments, [])
            groups[canonical_id][1].append(record)
        parent = module_prefix + "/" + pascal_segment(kind)
        manifest_key = "responsePools" if kind == "responses" else kind
        for canonical_id, (segments, records) in groups.items():
            label = "/".join(pascal_segment(segment) for segment in segments)
            shards = _split_semantic_records(kind, label, records, max_chars)
            modules: list[str] = []
            for index, shard in enumerate(shards, 1):
                shard_segments = list(segments)
                if len(shards) > 1:
                    shard_segments[-1] = f"{shard_segments[-1]}_Part{index:02d}"
                module = module_path(parent, shard_segments, f"{canonical_id}:{index}", registry)
                rendered.append((module, shard))
                modules.append(module)
            manifest[manifest_key].append({
                "id": canonical_id,
                "modules": modules,
                "recordCount": len(records),
            })
    return rendered, manifest


def render_semantic_lua_shards(
    compiled: dict[str, Any],
    module_prefix: str,
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[tuple[str, str]]:
    return render_semantic_lua_plan(compiled, module_prefix, max_chars)[0]


def render_semantic_manifest(
    compiled: dict[str, Any],
    pattern_modules: list[str],
    flow_modules: list[str],
    response_modules: list[str],
    translation_paths: dict[str, list[str]],
    module_manifest: dict[str, list[dict[str, Any]]] | None = None,
) -> str:
    lines = [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        "-- Explicit manifest for one deterministic semantic-authoring build.",
        "local result = {",
        "    [\"schema\"] = " + _lua_string(compiled["schema"]) + ",",
        "    [\"source\"] = " + _lua_value(compiled["source"], 4) + ",",
        "    [\"catalogVersion\"] = 2,",
        "    [\"patterns\"] = {},",
        "    [\"flows\"] = {},",
        "    [\"responsePools\"] = {},",
        "    [\"translationPaths\"] = " + _lua_value(translation_paths, 4) + ",",
        "}",
        "local function append(target, shard)",
        "    for index = 1, #shard do target[#target + 1] = shard[index] end",
        "end",
    ]
    if module_manifest is not None:
        lines.insert(8, "    [\"modules\"] = " + _lua_value(module_manifest, 4) + ",")
    for module in pattern_modules:
        lines.append(f'append(result["patterns"], require "{module}")')
    for module in flow_modules:
        lines.append(f'append(result["flows"], require "{module}")')
    for module in response_modules:
        lines.append(f'append(result["responsePools"], require "{module}")')
    lines.extend(["return result", ""])
    return "\n".join(lines)
