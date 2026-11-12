"""Manifest-backed Conversation source compiler and generated artifact plan.

Conversation authoring is deliberately compiled through this module instead of
adding another source loader beside CodeBuilder.  The manifest is the only
filesystem discovery boundary; all runtime and authoring consumers receive the
same merged, validated model.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable, Mapping

from .dialogue_content import (
    _lua_value,
    render_dialogue_content_shard_plan,
)
from .errors import CompileError
from .conversation_manifest import (
    CONVERSATION_MANIFEST_SCHEMA,
    load_manifest as _load_manifest,
    read_json as _read_json,
    validate_id as _validate_id,
)
from .conversation_contract import (
    CONVERSATION_MANIFEST_RELATIVE,
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_MAX_INDEX_BYTES,
    CONVERSATION_MAX_SOURCE_BYTES,
    CONVERSATION_MODEL_SCHEMA,
    CONVERSATION_RUNTIME_RELATIVE,
    CONVERSATION_SHARD_SCHEMA,
    CONVERSATION_SOURCE_RELATIVE,
    CONVERSATION_UI_RUNTIME_RELATIVE,
)
from .conversation_validation import (
    CONVERSATION_MAX_RECORDS_PER_SHARD,
    _merge_director_sources,
    _merge_realization_sources,
    _validate_behavior_shard,
    _validate_beat_shard,
    _validate_director_predicate,
    _validate_realization_shard,
)
from .conversation_rendering import (
    CONVERSATION_MAX_SHARD_BYTES,
    _chunk_records,
    _render_pack_shard_plan,
    render_conversation_lua_records,
    render_conversation_ui_module,
)
from .conversation_discovery import (
    conversation_discovery_index,
    render_conversation_discovery_indexes,
)
from .conversation_health import (
    conversation_affected_closure,
    conversation_context_health,
)
from .conversation_registry import (
    render_conversation_manifest_lua,
    render_conversation_registry,
)
from .conversation_assembly import (
    _add_global_id,
    _compile_shard,
    _content_source,
    _conversation_record_ids,
    _hydrate_shard_provenance,
    _merge_dialogue_sources,
    _merge_semantic_sources,
    _ui_translations,
)
from tools.semantic_harness.codebuilder.conversation_model import (
    copy_json as _copy_json,
    fingerprint as _fingerprint,
    register_global_id as _register_global_id_core,
)
from tools.semantic_harness.codebuilder.conversation_assembler import assemble_shards
from tools.semantic_harness.codebuilder.translation_support import (
    DEFAULT_LANGUAGE,
    merge_language_sets,
    normalize_language,
)
from .generation_ownership import (
    HOOMANS_OWNER,
    conversation_prefix,
    normalize_owner,
    route_module_for_owner,
    resolve_core_repository,
    source_owner,
)
from .psdl_compiler import (
    compile_psdl_document,
    render_psdl_director_plan,
    render_psdl_semantic_pack_plan,
    render_psdl_runtime_plan,
    render_psdl_ui_plan,
)




def _registry_owner(model: dict[str, Any]) -> str:
    manifest = model.get("manifest")
    owner = manifest.get("registryOwner") if isinstance(manifest, dict) else None
    return normalize_owner(owner)


def _compiled_psdl_documents(
    loaded: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    compiled: list[tuple[dict[str, Any], dict[str, Any]]] = []
    for document, entry, _fingerprint_value in loaded:
        if entry.get("kind") != "psdl":
            continue
        compiled.append(
            (
                compile_psdl_document(document, source_path=entry["path"]),
                entry,
            )
        )
    return compiled








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
        _hydrate_shard_provenance(document, entry, manifest["sourceProfiles"])
        return _compile_shard(
            document,
            entry,
            runtime_root=runtime_root,
            default_owner=manifest["defaultOwner"],
            package_repositories=resolved_package_repositories,
        )

    def owner_for(_document: dict[str, Any], entry: dict[str, Any]) -> str:
        return normalize_owner(entry.get("owner"))

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
    psdl_documents = _compiled_psdl_documents(loaded)
    psdl_ui: list[dict[str, Any]] = []
    psdl_packs: list[dict[str, Any]] = []
    psdl_runtime_plans: list[dict[str, Any]] = []
    for compiled_psdl, entry in psdl_documents:
        for plan in render_psdl_runtime_plan(compiled_psdl):
            runtime_plan = _copy_json(plan)
            runtime_plan["owner"] = normalize_owner(entry.get("owner"))
            runtime_plan["domain"] = entry["domain"]
            runtime_plan["sourceShard"] = entry["path"]
            psdl_runtime_plans.append(runtime_plan)
        director_plan = render_psdl_director_plan(compiled_psdl)
        for record in director_plan["behaviors"]:
            record["sourceShard"] = entry["path"]
            record["domain"] = entry["domain"]
            behaviors["records"].append(record)
        for record in director_plan["beats"]:
            record["sourceShard"] = entry["path"]
            record["domain"] = entry["domain"]
            beats["records"].append(record)
        for row in render_psdl_ui_plan(compiled_psdl):
            row.pop("sourceRecordID", None)
            row.pop("owner", None)
            psdl_ui.append(row)
        for pack in render_psdl_semantic_pack_plan(compiled_psdl):
            record = _copy_json(pack)
            record["owner"] = normalize_owner(entry.get("owner"))
            record["domain"] = entry["domain"]
            record["sourceShard"] = entry["path"]
            psdl_packs.append(record)
    behaviors["records"].sort(key=lambda item: str(item.get("id", "")))
    beats["records"].sort(key=lambda item: str(item.get("id", "")))
    psdl_runtime_plans.sort(key=lambda item: str(item.get("id", "")))
    packs = [*psdl_packs]
    for document, entry, _fingerprint_value in loaded:
        if entry["kind"] != "packs":
            continue
        owner = normalize_owner(
            entry.get("owner"),
        )
        for pack in document.get("packs", []):
            record = _copy_json(pack)
            record["owner"] = owner
            record["domain"] = entry["domain"]
            record["sourceShard"] = entry["path"]
            packs.append(record)
    packs.sort(key=lambda item: str(item.get("id", "")))
    ui = sorted(
        [
            item
            for document, entry, _ in loaded
            if entry["kind"] == "ui"
            for item in document.get("suggestions", [])
        ] + psdl_ui,
        key=lambda item: (item.get("order", 0), item.get("id", "")),
    )
    ui_texts = sorted(
        [
            item
            for document, entry, _ in loaded
            if entry["kind"] == "ui"
            for item in document.get("texts", [])
        ],
        key=lambda item: item.get("id", ""),
    )

    locations: dict[str, dict[str, Any]] = {}
    for document, entry, _fingerprint_value in loaded:
        path = entry["path"]
        entry = {
            **entry,
            "owner": normalize_owner(entry.get("owner")),
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
        elif entry["kind"] == "psdl":
            for compiled_psdl, psdl_entry in psdl_documents:
                if psdl_entry["path"] != path:
                    continue
                for record in compiled_psdl["records"]:
                    _add_global_id(
                        locations,
                        record.get("id"),
                        kind=record.get("kind", "psdl"),
                        shard=entry,
                        path=path,
                    )
                for row in render_psdl_ui_plan(compiled_psdl):
                    _add_global_id(
                        locations,
                        row.get("id"),
                        kind="ui",
                        shard=entry,
                        path=path,
                    )
                for pack in render_psdl_semantic_pack_plan(compiled_psdl):
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
            for text in document.get("texts", []):
                _add_global_id(locations, text.get("id"), kind="uiText", shard=entry, path=path)

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
    available_patterns |= {
        str(pattern.get("id"))
        for pack in packs
        for pattern in pack.get("patterns", [])
        if isinstance(pattern, dict)
    }
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
        "psdlRuntimePlans": psdl_runtime_plans,
        "ui": ui,
        "uiTexts": ui_texts,
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
        "psdlRuntimePlans": psdl_runtime_plans,
        "ui": ui,
        "uiTexts": ui_texts,
        "uiTranslations": _ui_translations(ui, ui_texts),
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
        {
            language: {}
            for plan in model.get("psdlRuntimePlans", [])
            for language in _psdl_plan_languages(plan)
        },
    )
    if DEFAULT_LANGUAGE not in languages:
        raise CompileError(f"Conversation content requires {DEFAULT_LANGUAGE} fallback translations")
    return languages


def _psdl_plan_languages(plan: Mapping[str, Any]) -> tuple[str, ...]:
    """Return locales carried by one PSDL runtime plan's authored payload."""
    languages: set[str] = set()

    def visit(value: Any) -> None:
        if isinstance(value, Mapping):
            keys = list(value)
            if DEFAULT_LANGUAGE in value:
                for raw_language in keys:
                    if isinstance(raw_language, str):
                        languages.add(normalize_language(raw_language, "PSDL locale"))
            for child in value.values():
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(plan.get("payload"))
    return tuple(sorted(languages))


def _psdl_plan_text_rows(
    plan: Mapping[str, Any],
) -> list[tuple[str, str, str, str]]:
    """Project explicitly requested PSDL text targets into flat catalogs.

    PSDL response text remains authored inline.  Only records that declare a
    ``metadata.textTarget`` opt into the native Conversation/Text compatibility
    boundary used by adopter runtimes; UI-only PSDL records continue through
    the normal generated UI catalog path.
    """
    payload = plan.get("payload")
    if not isinstance(payload, Mapping):
        return []
    metadata = payload.get("metadata")
    if not isinstance(metadata, Mapping):
        return []
    target = metadata.get("textTarget")
    if not isinstance(target, str) or not target.strip():
        return []
    target = target.strip().strip("/")
    domain = "Text/" + target
    rows: list[tuple[str, str, str, str]] = []

    def add(localized: Any, key: Any) -> None:
        if not isinstance(localized, Mapping) or not isinstance(key, str):
            return
        for raw_language, raw_values in localized.items():
            if not isinstance(raw_language, str):
                continue
            language = normalize_language(raw_language, "PSDL text locale")
            values = raw_values if isinstance(raw_values, list) else [raw_values]
            if values and isinstance(values[0], str):
                rows.append((language, domain, key, values[0]))

    def metadata_key(value: Any, field: str, fallback: str) -> str:
        if isinstance(value, Mapping):
            candidate = value.get(field)
            if isinstance(candidate, str) and candidate.strip():
                return candidate.strip()
        return fallback

    record_id = str(plan.get("id") or "record")
    response = payload.get("response")
    if isinstance(response, Mapping):
        response_text = response.get("text")
        if response_text is not None:
            add(response_text, metadata_key(metadata, "responseKey", "response"))
        variants = response.get("variants")
        if isinstance(variants, list):
            for index, variant in enumerate(variants):
                if not isinstance(variant, Mapping):
                    continue
                variant_metadata = variant.get("metadata")
                variant_id = str(variant.get("id") or f"variant_{index + 1}")
                add(
                    variant.get("text"),
                    metadata_key(variant_metadata, "textKey", variant_id),
                )
        turns = response.get("turns")
    else:
        turns = payload.get("turns")
    if turns is None:
        turns = payload.get("turns")
    if isinstance(turns, list):
        for index, turn in enumerate(turns):
            if not isinstance(turn, Mapping):
                continue
            turn_metadata = turn.get("metadata")
            turn_id = str(turn.get("id") or f"turn_{index + 1}")
            key = metadata_key(turn_metadata, "textKey", f"turn.{turn_id}")
            add(turn.get("text"), key)
            for offer in turn.get("offers", []):
                if not isinstance(offer, Mapping):
                    continue
                offer_id = str(offer.get("id") or "offer")
                offer_metadata = offer.get("metadata")
                choice_key = metadata_key(
                    offer_metadata,
                    "choiceKey",
                    f"offer.{offer_id}.label",
                )
                utterance_key = metadata_key(
                    offer_metadata,
                    "utteranceKey",
                    f"offer.{offer_id}.utterance",
                )
                add(offer.get("label"), choice_key)
                add(offer.get("utterance"), utterance_key)
                if isinstance(offer_metadata, Mapping):
                    add(offer_metadata.get("responseText"), metadata_key(
                        offer_metadata,
                        "responseKey",
                        f"offer.{offer_id}.response",
                    ))
    for field in ("text", "label", "utterance"):
        if field in payload:
            add(payload.get(field), metadata_key(metadata, f"{field}Key", field))
    if isinstance(payload.get("offers"), list):
        for offer in payload["offers"]:
            if not isinstance(offer, Mapping):
                continue
            offer_id = str(offer.get("id") or "offer")
            offer_metadata = offer.get("metadata")
            add(offer.get("label"), metadata_key(
                offer_metadata, "choiceKey", f"offer.{offer_id}.label"
            ))
            add(offer.get("utterance"), metadata_key(
                offer_metadata, "utteranceKey", f"offer.{offer_id}.utterance"
            ))
    text_rows = metadata.get("textRows")
    if isinstance(text_rows, list):
        for row in text_rows:
            if not isinstance(row, Mapping):
                continue
            add(row.get("text"), row.get("key"))
    return rows


def conversation_translation_catalogs(model: dict[str, Any]) -> dict[str, dict[str, dict[str, str]]]:
    """Partition generated translations by Conversation domain, not history."""
    languages = conversation_languages(model)
    catalogs = {language: {} for language in languages}

    def add(language: str, domain: str, key: str, value: Any) -> None:
        if language not in catalogs or not isinstance(key, str) or not isinstance(value, str):
            return
        catalogs[language].setdefault(domain, {})[key] = value

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
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            add(language, "UI", key, value)
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(language, "Flows", key, value)
    for plan in model.get("psdlRuntimePlans", []):
        for language, domain, key, value in _psdl_plan_text_rows(plan):
            add(language, domain, key, value)
    for language in languages:
        catalogs[language] = {
            domain: {key: values[key] for key in sorted(values)}
            for domain, values in sorted(catalogs[language].items())
            if values
        }
    return catalogs


def conversation_translation_catalogs_by_owner(
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
    catalogs: dict[str, dict[str, dict[str, dict[str, str]]]] = {}

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
        owner_catalogs = catalogs.setdefault(canonical_owner, {})
        language_catalogs = owner_catalogs.setdefault(language, {})
        language_catalogs.setdefault(domain, {})[key] = value

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
    for text in model.get("uiTexts", []):
        key = text.get("key")
        if isinstance(key, str):
            ui_key_owners[key] = record_owner(str(text.get("id") or ""))
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            owner = ui_key_owners.get(key, registry_owner)
            add(owner, language, "UI", key, value)
            # The adopter registry is a runtime composition boundary.  Its
            # package-owned UI catalog must include Core UI text because the
            # composed PNC surface loads one package catalog in lightweight
            # harnesses and in installations that do not merge translation
            # manifests across dependencies.
            if owner != registry_owner:
                add(registry_owner, language, "UI", key, value)

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

    for plan in model.get("psdlRuntimePlans", []):
        owner = normalize_owner(plan.get("owner"), default=default_owner)
        for language, domain, key, value in _psdl_plan_text_rows(plan):
            add(owner, language, domain, key, value)

    return {
        owner: {
            language: {
                domain: {key: values[key] for key in sorted(values)}
                for domain, values in sorted(domains.items())
                if values
            }
            for language, domains in sorted(languages_by_owner.items())
        }
        for owner, languages_by_owner in sorted(catalogs.items())
    }




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
        source_shard = item.get("sourceShard") or (
            owner.get("sourceShard") if isinstance(owner, dict) else None
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
    psdl_modules: list[tuple[str, str]] = []
    psdl_reports: list[dict[str, Any]] = []
    for plan in model.get("psdlRuntimePlans", []):
        module = str(plan.get("module") or "")
        record_id = str(plan.get("id") or "")
        if not module or not record_id:
            raise CompileError("PSDL runtime plan requires module and id")
        source = render_conversation_lua_records([plan])
        size = len(source.encode("utf-8"))
        if size > CONVERSATION_MAX_SHARD_BYTES:
            raise CompileError(
                "PSDL runtime plan renders above the generated shard budget: "
                + record_id
            )
        psdl_modules.append((module, source))
        psdl_reports.append({
            "module": module,
            "kind": "PSDL",
            "domain": str(plan.get("domain") or "general"),
            "sourceShard": str(plan.get("sourceShard") or ""),
            "recordCount": 1,
            "recordIDs": [record_id],
            "bytes": size,
        })
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
        *psdl_modules,
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
        *psdl_reports,
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







