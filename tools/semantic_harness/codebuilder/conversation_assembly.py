"""Shard compilation and semantic model assembly for Conversation sources."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Mapping

from .conversation_catalog import (
    _hydrate_catalog_translations,
    _reject_inline_translations,
)
from .conversation_contract import CONVERSATION_SHARD_SCHEMA
from .conversation_model import (
    canonical_json as _canonical_json,
    copy_json as _copy_json,
    merge_source_metadata as _source_metadata,
    register_global_id as _register_global_id_core,
)
from .conversation_validation import (
    _validate_beat_shard,
    _validate_behavior_shard,
    _validate_realization_shard,
    _validate_ui_shard,
)
from .dialogue_content import compile_dialogue_content
from .dialogue_dataset import compile_dialogue_dataset
from .errors import CompileError
from .generation_ownership import normalize_owner, source_owner
from .semantic_definition_compiler import (
    compile_semantic_definitions,
    discover_registered_capability_ids,
)
from .semantic_pack_compiler import compile_semantic_pack_shard
from .translation_support import DEFAULT_LANGUAGE, normalize_language


def _hydrate_shard_provenance(
    document: dict[str, Any],
    entry: Mapping[str, Any],
    source_profiles: Mapping[str, Any],
) -> None:
    """Reconstruct compiler-only provenance from the v2 manifest index."""

    path = str(entry.get("path", "<shard>"))
    if document.get("schema") != CONVERSATION_SHARD_SCHEMA:
        raise CompileError(f"Conversation shard {path} requires schema {CONVERSATION_SHARD_SCHEMA}")
    if entry.get("shardId") is not None and document.get("shardId") != entry.get("shardId"):
        raise CompileError(f"Conversation shard {path} does not match its manifest shardId")
    if document.get("owner") != entry.get("owner"):
        raise CompileError(f"Conversation shard {path} does not match its manifest owner")
    profile_id = document.get("sourceProfile")
    if entry.get("sourceProfile") is not None and profile_id != entry.get("sourceProfile"):
        raise CompileError(f"Conversation shard {path} does not match its manifest sourceProfile")
    profile = source_profiles.get(profile_id)
    if not isinstance(profile, dict):
        raise CompileError(f"Conversation shard {path} references unknown sourceProfile {profile_id!r}")
    # The compiler's domain validators still consume a normalized provenance
    # object. It is reconstructed in memory only; the authoring shard remains
    # free of the old inline source envelope.
    document["source"] = _copy_json(profile)
    document["source"].setdefault("owner", entry["owner"])
    document["version"] = document["source"].get("version", "1")

def _compile_shard(
    document: dict[str, Any],
    entry: dict[str, Any],
    *,
    runtime_root: Path,
    default_owner: str,
    catalogs: Mapping[str, Mapping[str, str]] | None = None,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    kind = entry["kind"]
    path = entry["path"]
    _reject_inline_translations(document, path)
    _hydrate_catalog_translations(document, entry, catalogs or {})
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

