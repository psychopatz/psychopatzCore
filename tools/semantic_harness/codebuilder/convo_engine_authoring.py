"""Headless CodeBuilder ConvoEngine authoring, sharding, and write operations.

Provides bounded, validated create / edit / move / shard / write workflows so
agents and Studio never manufacture raw unvalidated JSON shards or edit
generated Lua directly.
"""

from __future__ import annotations

import copy
import json
import re
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

from .convo_engine_exchange import resolve_family_identity
from .conversation_model import fingerprint
from .errors import CompileError
from .convo_engine_compiler import (
    CONVO_ENGINE_SCHEMA,
    compile_convo_engine_sources,
)


_FORBIDDEN_PATH_SEGMENTS = frozenset({
    "legacy",
    "compat",
    "old",
    "v1",
    "migrated",
})
_PART_SEGMENT_RE = re.compile(r"^part\d+$", re.IGNORECASE)
_STALE_MIGRATION_TOP_KEYS = frozenset({
    "sourceSurface",
    "migration",
    "sourceCatalog",
    "originalOwner",
})
_STALE_MIGRATION_METADATA_KEYS = frozenset({
    "sourceSurface",
    "migration",
    "sourceCatalog",
    "originalOwner",
    "sourcePath",
    "sourceProfile",
})


def strip_stale_migration_metadata(document: Mapping[str, Any]) -> dict[str, Any]:
    """Return a copy of a ConvoEngine document with stale migration metadata stripped."""
    cleaned = copy.deepcopy(dict(document))
    if cleaned.get("schema") != CONVO_ENGINE_SCHEMA:
        return cleaned
    for key in _STALE_MIGRATION_TOP_KEYS:
        cleaned.pop(key, None)
    meta = cleaned.get("metadata")
    if isinstance(meta, dict):
        for key in _STALE_MIGRATION_METADATA_KEYS:
            meta.pop(key, None)
        if not meta:
            cleaned.pop("metadata", None)
    records = cleaned.get("records")
    if isinstance(records, list):
        for record in records:
            if not isinstance(record, dict):
                continue
            for key in _STALE_MIGRATION_TOP_KEYS:
                record.pop(key, None)
            rec_meta = record.get("metadata")
            if isinstance(rec_meta, dict):
                for key in _STALE_MIGRATION_METADATA_KEYS:
                    rec_meta.pop(key, None)
                if not rec_meta:
                    record.pop("metadata", None)
    return cleaned


def resolve_authorized_source_path(
    raw_path: str | Path,
    *,
    repository: Path,
    allowed_roots: Sequence[Path],
    check_forbidden_segments: bool = True,
) -> Path:
    """Resolve a JSON source path and verify it stays inside authorized roots."""
    candidate = Path(raw_path)
    if not candidate.is_absolute():
        candidate = repository / candidate
    resolved = candidate.expanduser().resolve()
    resolved_roots = [root.expanduser().resolve() for root in allowed_roots]
    if not any(resolved == root or root in resolved.parents for root in resolved_roots):
        raise CompileError(
            "ConvoEngine source must remain inside the service or a manifest-routed package repository"
        )
    if resolved.suffix.lower() != ".json":
        raise CompileError("ConvoEngine source must be a .json file")
    if check_forbidden_segments:
        for part in resolved.parts:
            lowered = part.lower()
            if lowered in _FORBIDDEN_PATH_SEGMENTS or _PART_SEGMENT_RE.fullmatch(lowered):
                raise CompileError(
                    f"ConvoEngine destination path uses forbidden migration segment {part!r}: {resolved}"
                )
    return resolved


def load_json_document(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise CompileError(f"ConvoEngine source is missing: {path}")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise CompileError(f"Invalid JSON in {path}: {error}") from error
    if not isinstance(payload, dict):
        raise CompileError(f"ConvoEngine source must be a JSON object: {path}")
    return payload


def write_json_document(path: Path, document: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(document, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def build_convo_engine_family_document(
    family_spec: Mapping[str, Any],
    *,
    default_owner: str | None = None,
) -> dict[str, Any]:
    """Normalize a family spec into a canonical ``psychopatz.convo-engine.v1`` document."""
    if not isinstance(family_spec, Mapping):
        raise CompileError("ConvoEngine family spec must be an object")
    doc = copy.deepcopy(dict(family_spec))
    existing_schema = doc.get("schema")
    if existing_schema is not None and existing_schema != CONVO_ENGINE_SCHEMA:
        raise CompileError(
            f"New ConvoEngine family writes must use schema {CONVO_ENGINE_SCHEMA}, got {existing_schema!r}"
        )
    doc["schema"] = CONVO_ENGINE_SCHEMA
    doc.setdefault("kind", "dialogue")
    if doc.get("owner") is None and default_owner is not None:
        doc["owner"] = default_owner
    resolve_family_identity(
        doc.get("namespace"),
        doc.get("id"),
        strict_convo_engine=True,
        label="ConvoEngine family",
    )
    return strip_stale_migration_metadata(doc)


def apply_family_patch(
    document: Mapping[str, Any],
    patch: Mapping[str, Any],
) -> dict[str, Any]:
    """Apply a bounded update to a single-family or records ConvoEngine document."""
    if not isinstance(document, Mapping):
        raise CompileError("ConvoEngine source document must be an object")
    if not isinstance(patch, Mapping) or not patch:
        raise CompileError("ConvoEngine patch must be a non-empty object")
    candidate = copy.deepcopy(dict(document))
    if candidate.get("schema") != CONVO_ENGINE_SCHEMA:
        raise CompileError(
            f"Editing requires canonical schema {CONVO_ENGINE_SCHEMA}; migrate legacy sources first"
        )
    if "records" in candidate:
        raise CompileError(
            "apply_family_patch operates on single-family documents; shard multi-record documents first"
        )
    if "schema" in patch and patch["schema"] != CONVO_ENGINE_SCHEMA:
        raise CompileError(f"ConvoEngine edits cannot change schema away from {CONVO_ENGINE_SCHEMA}")
    for key in ("id", "namespace", "kind"):
        if key in patch and patch[key] != candidate.get(key):
            raise CompileError(
                f"ConvoEngine edits cannot mutate {key!r}; use move_convo_engine_source to rename/re-namespace"
            )
    for key, value in patch.items():
        if value is None:
            candidate.pop(key, None)
        else:
            candidate[key] = copy.deepcopy(value)
    return candidate


def _extract_source_records(source_document: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    records = source_document.get("records")
    if isinstance(records, list):
        by_id: dict[str, dict[str, Any]] = {}
        for item in records:
            if isinstance(item, Mapping) and isinstance(item.get("id"), str):
                by_id[item["id"]] = copy.deepcopy(dict(item))
        return by_id
    if isinstance(source_document.get("id"), str):
        return {source_document["id"]: copy.deepcopy(dict(source_document))}
    return {}


def prepare_shard_documents(
    source_document: Mapping[str, Any],
    plan: Sequence[Mapping[str, Any]],
    *,
    repository: Path,
    allowed_roots: Sequence[Path],
    default_owner: str | None = None,
) -> tuple[list[tuple[Path, dict[str, Any], list[str]]], list[str], dict[str, Any]]:
    """Build and cross-validate sharded canonical ConvoEngine documents from a plan.

    Each plan entry must declare:
    - ``destPath`` (or ``dest_path``): destination relative/absolute ``.json`` path;
    - ``family``: canonical ``psychopatz.convo-engine.v1`` family spec;
    - optional ``sourceRecordIds`` (or ``source_record_ids``): legacy record IDs
      consumed by this shard.
    """
    if not isinstance(plan, Sequence) or isinstance(plan, (str, bytes)) or not plan:
        raise CompileError("ConvoEngine shard plan must be a non-empty list of shard specs")

    source_records = _extract_source_records(source_document)
    doc_owner = source_document.get("owner") if isinstance(source_document, Mapping) else None
    resolved_default_owner = default_owner or (str(doc_owner) if isinstance(doc_owner, str) else None)

    prepared: list[tuple[Path, dict[str, Any], list[str]]] = []
    seen_destinations: set[Path] = set()
    consumed_ids: list[str] = []
    sources_for_compile: dict[Path, dict[str, Any]] = {}

    for index, raw_entry in enumerate(plan):
        if not isinstance(raw_entry, Mapping):
            raise CompileError(f"shard plan[{index}] must be an object")
        raw_dest = raw_entry.get("destPath", raw_entry.get("dest_path"))
        if not isinstance(raw_dest, (str, Path)) or not str(raw_dest).strip():
            raise CompileError(f"shard plan[{index}] requires destPath")
        dest_path = resolve_authorized_source_path(
            raw_dest,
            repository=repository,
            allowed_roots=allowed_roots,
        )
        if dest_path in seen_destinations:
            raise CompileError(f"shard plan repeats destination path: {dest_path}")
        seen_destinations.add(dest_path)

        family_spec = raw_entry.get("family")
        if not isinstance(family_spec, Mapping):
            raise CompileError(f"shard plan[{index}] requires a family object")

        raw_consumed = raw_entry.get("sourceRecordIds", raw_entry.get("source_record_ids", []))
        if raw_consumed is None:
            raw_consumed = []
        if not isinstance(raw_consumed, list) or any(not isinstance(item, str) for item in raw_consumed):
            raise CompileError(f"shard plan[{index}].sourceRecordIds must be a list of strings")

        inherited_owner = resolved_default_owner
        for rec_id in raw_consumed:
            if source_records and rec_id not in source_records:
                raise CompileError(
                    f"shard plan[{index}] references unknown source record {rec_id!r}"
                )
            if inherited_owner is None and rec_id in source_records:
                rec_owner = source_records[rec_id].get("owner")
                if isinstance(rec_owner, str) and rec_owner.strip():
                    inherited_owner = rec_owner
            if rec_id not in consumed_ids:
                consumed_ids.append(rec_id)

        family_doc = build_convo_engine_family_document(
            family_spec,
            default_owner=inherited_owner,
        )
        prepared.append((dest_path, family_doc, list(raw_consumed)))
        sources_for_compile[dest_path] = family_doc

    compiled = compile_convo_engine_sources(
        sources_for_compile,
        default_owner=resolved_default_owner,
    )
    return prepared, consumed_ids, compiled


from .convo_engine_fields import (
    CONVO_ENGINE_FIELD_DESCRIPTORS,
    FieldDescriptor,
    describe_unknown_fields,
    list_field_descriptors,
)


def source_fingerprint_mismatch(
    target: Path,
    expected_source_fingerprint: str | None,
) -> dict[str, Any] | None:
    if not expected_source_fingerprint or not target.is_file():
        return None
    current = load_json_document(target)
    actual = fingerprint(current)
    if actual != expected_source_fingerprint:
        return {
            "ok": False,
            "stale": True,
            "reason": "source_fingerprint_mismatch",
            "expectedSourceFingerprint": expected_source_fingerprint,
            "sourceFingerprint": actual,
            "writes": [],
        }
    return None


def collapse_convo_engine_families(
    source_paths: list[Path],
    dest_path: Path,
    *,
    target_id: str,
    default_owner: str | None = None,
    extra_slots: Mapping[str, Any] | None = None,
    extra_roles: Mapping[str, Any] | None = None,
    variant_ids: Mapping[str, str] | None = None,
    drop_when: bool = False,
    write: bool = False,
    prune_sources: bool = False,
) -> dict[str, Any]:
    """Deterministically collapse redundant contextual/variant ConvoEngine families into one family."""
    from .convo_engine_compiler import compile_convo_engine_document

    resolved_sources = [Path(p).expanduser().resolve() for p in source_paths]
    if not resolved_sources:
        raise CompileError("collapse_convo_engine_families requires at least one source path")
    resolved_dest = Path(dest_path).expanduser().resolve()

    loaded_docs = [(p, load_json_document(p)) for p in resolved_sources]
    first_doc = loaded_docs[0][1]
    owner = str(first_doc.get("owner") or default_owner or "").strip()
    if not owner:
        raise CompileError("collapse_convo_engine_families could not resolve owner")

    merged_roles: dict[str, Any] = {}
    merged_slots: dict[str, Any] = {}
    merged_domains: list[dict[str, Any]] = []
    merged_topics: list[dict[str, Any]] = []
    merged_events: list[dict[str, Any]] = []
    merged_activities: list[dict[str, Any]] = []
    merged_memories: list[dict[str, Any]] = []
    seen_domains: set[str] = set()
    seen_topics: set[str] = set()
    seen_events: set[str] = set()
    seen_activities: set[str] = set()
    seen_memories: set[str] = set()

    merged_variants: list[dict[str, Any]] = []
    merged_text_rows: list[dict[str, Any]] = []
    seen_text_keys: set[str] = set()

    def _add_unique(dst: list[dict[str, Any]], seen: set[str], items: Any, key_field: str) -> None:
        if not isinstance(items, list):
            return
        for item in items:
            if isinstance(item, Mapping):
                k = str(item.get(key_field) or json.dumps(item, sort_keys=True))
                if k not in seen:
                    seen.add(k)
                    dst.append(copy.deepcopy(dict(item)))

    for src_path, doc in loaded_docs:
        src_id = str(doc.get("id") or "")
        sidecar_texts: dict[str, dict[str, Any]] = {}
        if isinstance(doc.get("textSidecars"), Mapping):
            for lang, rel_sidecar in doc["textSidecars"].items():
                sc_path = (src_path.parent / str(rel_sidecar)).resolve()
                if sc_path.is_file():
                    sidecar_texts[str(lang)] = load_json_document(sc_path)
        if variant_ids and src_id in variant_ids:
            var_id = str(variant_ids[src_id])
        elif src_id.startswith(f"{target_id}."):
            var_id = src_id[len(target_id) + 1:]
        elif src_id == target_id:
            var_id = "default"
        else:
            var_id = src_id.split(".")[-1] if "." in src_id else src_id

        if isinstance(doc.get("roles"), Mapping):
            for k, v in doc["roles"].items():
                merged_roles.setdefault(str(k), copy.deepcopy(v))
        if isinstance(doc.get("slots"), Mapping):
            for k, v in doc["slots"].items():
                merged_slots.setdefault(str(k), copy.deepcopy(v))
        _add_unique(merged_domains, seen_domains, doc.get("domains"), "domain")
        _add_unique(merged_topics, seen_topics, doc.get("topics"), "id")
        _add_unique(merged_events, seen_events, doc.get("events"), "id")
        _add_unique(merged_activities, seen_activities, doc.get("activities"), "id")
        _add_unique(merged_memories, seen_memories, doc.get("memories"), "id")

        meta = doc.get("metadata") if isinstance(doc.get("metadata"), Mapping) else {}
        if isinstance(meta.get("textRows"), list):
            for row in meta["textRows"]:
                if isinstance(row, Mapping):
                    tk = str(row.get("key") or "")
                    if tk and tk not in seen_text_keys:
                        seen_text_keys.add(tk)
                        merged_text_rows.append(copy.deepcopy(dict(row)))
        elif isinstance(meta.get("textKey"), str) and meta["textKey"].strip():
            tk = meta["textKey"].strip()
            if tk not in seen_text_keys:
                say_node = doc.get("say") if isinstance(doc.get("say"), Mapping) else {}
                variants = say_node.get("variants") if isinstance(say_node.get("variants"), list) else []
                first_text = variants[0].get("text") if variants and isinstance(variants[0], Mapping) else {}
                if isinstance(first_text, Mapping):
                    row_text: dict[str, Any] = {}
                    for lang, val in first_text.items():
                        row_text[str(lang)] = val[0] if isinstance(val, list) and val else val
                    seen_text_keys.add(tk)
                    merged_text_rows.append({"key": tk, "text": row_text})

        say_node = doc.get("say")
        if isinstance(say_node, Mapping) and isinstance(say_node.get("variants"), list):
            for idx, v in enumerate(say_node["variants"]):
                if not isinstance(v, Mapping):
                    continue
                vc = copy.deepcopy(dict(v))
                orig_vid = str(vc.get("id") or "neutral")
                if "text" not in vc and sidecar_texts:
                    inlined_text: dict[str, Any] = {}
                    for lang, sc_map in sidecar_texts.items():
                        val = sc_map.get(orig_vid)
                        if val is None and isinstance(sc_map.get("variants"), Mapping):
                            val = sc_map["variants"].get(orig_vid)
                        if val is None and isinstance(sc_map.get("say"), Mapping):
                            val = sc_map["say"].get(orig_vid)
                        if val is not None:
                            inlined_text[lang] = val if isinstance(val, list) else [val]
                    if inlined_text:
                        vc["text"] = inlined_text
                if orig_vid in {"neutral", "default"}:
                    vc["id"] = var_id
                else:
                    vc["id"] = f"{var_id}.{orig_vid}" if len(say_node["variants"]) > 1 else var_id
                merged_variants.append(vc)
        elif isinstance(say_node, Mapping):
            # Multi-key say (e.g. "1": {"variants": [...]})
            for rkey in sorted(say_node.keys()):
                rnode = say_node[rkey]
                if isinstance(rnode, Mapping) and isinstance(rnode.get("variants"), list):
                    for v in rnode["variants"]:
                        if isinstance(v, Mapping):
                            vc = copy.deepcopy(dict(v))
                            vc["id"] = f"{var_id}.say.{rkey}" if len(say_node) > 1 else var_id
                            merged_variants.append(vc)

    if extra_roles:
        for k, v in extra_roles.items():
            merged_roles[str(k)] = copy.deepcopy(v)
    if extra_slots:
        for k, v in extra_slots.items():
            merged_slots[str(k)] = copy.deepcopy(v)

    base_meta = copy.deepcopy(dict(first_doc.get("metadata") or {}))
    base_meta.pop("textKey", None)
    if merged_text_rows:
        base_meta["textRows"] = merged_text_rows

    collapsed: dict[str, Any] = {
        "schema": CONVO_ENGINE_SCHEMA,
        "id": target_id,
        "owner": owner,
    }
    if not drop_when and first_doc.get("when") is not None:
        collapsed["when"] = copy.deepcopy(first_doc["when"])
    if base_meta:
        collapsed["metadata"] = base_meta
    if merged_variants:
        collapsed["say"] = {"variants": merged_variants}
    elif "say" in first_doc:
        collapsed["say"] = copy.deepcopy(first_doc["say"])
    if merged_roles:
        collapsed["roles"] = merged_roles
    if merged_slots:
        collapsed["slots"] = merged_slots
    if merged_domains:
        collapsed["domains"] = merged_domains
    if merged_topics:
        collapsed["topics"] = merged_topics
    if merged_events:
        collapsed["events"] = merged_events
    if merged_activities:
        collapsed["activities"] = merged_activities
    if merged_memories:
        collapsed["memories"] = merged_memories

    compile_convo_engine_document(
        collapsed,
        source_path=resolved_dest,
        default_owner=owner,
        validate_cross_references=False,
    )

    writes: list[str] = []
    removed: list[str] = []
    if write:
        resolved_dest.parent.mkdir(parents=True, exist_ok=True)
        resolved_dest.write_text(
            json.dumps(collapsed, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        writes.append(str(resolved_dest))
        if prune_sources:
            for sp in resolved_sources:
                if sp != resolved_dest and sp.is_file():
                    sp.unlink()
                    removed.append(str(sp))

    return {
        "ok": True,
        "previewOnly": not write,
        "effectFree": not write,
        "targetId": target_id,
        "destPath": str(resolved_dest),
        "sourceCount": len(resolved_sources),
        "variantCount": len(merged_variants),
        "textRowCount": len(merged_text_rows),
        "writes": writes,
        "removedSources": removed,
        "document": collapsed,
    }
    current = load_json_document(target)
    actual = fingerprint(current)
    if actual != expected_source_fingerprint:
        return {
            "ok": False,
            "stale": True,
            "reason": "source_fingerprint_mismatch",
            "expectedSourceFingerprint": expected_source_fingerprint,
            "sourceFingerprint": actual,
            "writes": [],
        }
    return None


def collapse_convo_engine_families(
    source_paths: list[Path],
    dest_path: Path,
    *,
    target_id: str,
    default_owner: str | None = None,
    extra_slots: Mapping[str, Any] | None = None,
    extra_roles: Mapping[str, Any] | None = None,
    variant_ids: Mapping[str, str] | None = None,
    drop_when: bool = False,
    write: bool = False,
    prune_sources: bool = False,
) -> dict[str, Any]:
    """Deterministically collapse redundant contextual/variant ConvoEngine families into one family."""
    from .convo_engine_compiler import compile_convo_engine_document

    resolved_sources = [Path(p).expanduser().resolve() for p in source_paths]
    if not resolved_sources:
        raise CompileError("collapse_convo_engine_families requires at least one source path")
    resolved_dest = Path(dest_path).expanduser().resolve()

    loaded_docs = [(p, load_json_document(p)) for p in resolved_sources]
    first_doc = loaded_docs[0][1]
    owner = str(first_doc.get("owner") or default_owner or "").strip()
    if not owner:
        raise CompileError("collapse_convo_engine_families could not resolve owner")

    merged_roles: dict[str, Any] = {}
    merged_slots: dict[str, Any] = {}
    merged_domains: list[dict[str, Any]] = []
    merged_topics: list[dict[str, Any]] = []
    merged_events: list[dict[str, Any]] = []
    merged_activities: list[dict[str, Any]] = []
    merged_memories: list[dict[str, Any]] = []
    seen_domains: set[str] = set()
    seen_topics: set[str] = set()
    seen_events: set[str] = set()
    seen_activities: set[str] = set()
    seen_memories: set[str] = set()

    merged_variants: list[dict[str, Any]] = []
    merged_text_rows: list[dict[str, Any]] = []
    seen_text_keys: set[str] = set()

    def _add_unique(dst: list[dict[str, Any]], seen: set[str], items: Any, key_field: str) -> None:
        if not isinstance(items, list):
            return
        for item in items:
            if isinstance(item, Mapping):
                k = str(item.get(key_field) or json.dumps(item, sort_keys=True))
                if k not in seen:
                    seen.add(k)
                    dst.append(copy.deepcopy(dict(item)))

    for src_path, doc in loaded_docs:
        src_id = str(doc.get("id") or "")
        sidecar_texts: dict[str, dict[str, Any]] = {}
        if isinstance(doc.get("textSidecars"), Mapping):
            for lang, rel_sidecar in doc["textSidecars"].items():
                sc_path = (src_path.parent / str(rel_sidecar)).resolve()
                if sc_path.is_file():
                    sidecar_texts[str(lang)] = load_json_document(sc_path)
        if variant_ids and src_id in variant_ids:
            var_id = str(variant_ids[src_id])
        elif src_id.startswith(f"{target_id}."):
            var_id = src_id[len(target_id) + 1:]
        elif src_id == target_id:
            var_id = "default"
        else:
            var_id = src_id.split(".")[-1] if "." in src_id else src_id

        if isinstance(doc.get("roles"), Mapping):
            for k, v in doc["roles"].items():
                merged_roles.setdefault(str(k), copy.deepcopy(v))
        if isinstance(doc.get("slots"), Mapping):
            for k, v in doc["slots"].items():
                merged_slots.setdefault(str(k), copy.deepcopy(v))
        _add_unique(merged_domains, seen_domains, doc.get("domains"), "domain")
        _add_unique(merged_topics, seen_topics, doc.get("topics"), "id")
        _add_unique(merged_events, seen_events, doc.get("events"), "id")
        _add_unique(merged_activities, seen_activities, doc.get("activities"), "id")
        _add_unique(merged_memories, seen_memories, doc.get("memories"), "id")

        meta = doc.get("metadata") if isinstance(doc.get("metadata"), Mapping) else {}
        if isinstance(meta.get("textRows"), list):
            for row in meta["textRows"]:
                if isinstance(row, Mapping):
                    tk = str(row.get("key") or "")
                    if tk and tk not in seen_text_keys:
                        seen_text_keys.add(tk)
                        merged_text_rows.append(copy.deepcopy(dict(row)))
        elif isinstance(meta.get("textKey"), str) and meta["textKey"].strip():
            tk = meta["textKey"].strip()
            if tk not in seen_text_keys:
                say_node = doc.get("say") if isinstance(doc.get("say"), Mapping) else {}
                variants = say_node.get("variants") if isinstance(say_node.get("variants"), list) else []
                first_text = variants[0].get("text") if variants and isinstance(variants[0], Mapping) else {}
                if isinstance(first_text, Mapping):
                    row_text: dict[str, Any] = {}
                    for lang, val in first_text.items():
                        row_text[str(lang)] = val[0] if isinstance(val, list) and val else val
                    seen_text_keys.add(tk)
                    merged_text_rows.append({"key": tk, "text": row_text})

        say_node = doc.get("say")
        if isinstance(say_node, Mapping) and isinstance(say_node.get("variants"), list):
            for idx, v in enumerate(say_node["variants"]):
                if not isinstance(v, Mapping):
                    continue
                vc = copy.deepcopy(dict(v))
                orig_vid = str(vc.get("id") or "neutral")
                if "text" not in vc and sidecar_texts:
                    inlined_text: dict[str, Any] = {}
                    for lang, sc_map in sidecar_texts.items():
                        val = sc_map.get(orig_vid)
                        if val is None and isinstance(sc_map.get("variants"), Mapping):
                            val = sc_map["variants"].get(orig_vid)
                        if val is None and isinstance(sc_map.get("say"), Mapping):
                            val = sc_map["say"].get(orig_vid)
                        if val is not None:
                            inlined_text[lang] = val if isinstance(val, list) else [val]
                    if inlined_text:
                        vc["text"] = inlined_text
                if orig_vid in {"neutral", "default"}:
                    vc["id"] = var_id
                else:
                    vc["id"] = f"{var_id}.{orig_vid}" if len(say_node["variants"]) > 1 else var_id
                merged_variants.append(vc)
        elif isinstance(say_node, Mapping):
            # Multi-key say (e.g. "1": {"variants": [...]})
            for rkey in sorted(say_node.keys()):
                rnode = say_node[rkey]
                if isinstance(rnode, Mapping) and isinstance(rnode.get("variants"), list):
                    for v in rnode["variants"]:
                        if isinstance(v, Mapping):
                            vc = copy.deepcopy(dict(v))
                            vc["id"] = f"{var_id}.say.{rkey}" if len(say_node) > 1 else var_id
                            merged_variants.append(vc)

    if extra_roles:
        for k, v in extra_roles.items():
            merged_roles[str(k)] = copy.deepcopy(v)
    if extra_slots:
        for k, v in extra_slots.items():
            merged_slots[str(k)] = copy.deepcopy(v)

    base_meta = copy.deepcopy(dict(first_doc.get("metadata") or {}))
    base_meta.pop("textKey", None)
    if merged_text_rows:
        base_meta["textRows"] = merged_text_rows

    collapsed: dict[str, Any] = {
        "schema": CONVO_ENGINE_SCHEMA,
        "id": target_id,
        "owner": owner,
    }
    if not drop_when and first_doc.get("when") is not None:
        collapsed["when"] = copy.deepcopy(first_doc["when"])
    if base_meta:
        collapsed["metadata"] = base_meta
    if merged_variants:
        collapsed["say"] = {"variants": merged_variants}
    elif "say" in first_doc:
        collapsed["say"] = copy.deepcopy(first_doc["say"])
    if merged_roles:
        collapsed["roles"] = merged_roles
    if merged_slots:
        collapsed["slots"] = merged_slots
    if merged_domains:
        collapsed["domains"] = merged_domains
    if merged_topics:
        collapsed["topics"] = merged_topics
    if merged_events:
        collapsed["events"] = merged_events
    if merged_activities:
        collapsed["activities"] = merged_activities
    if merged_memories:
        collapsed["memories"] = merged_memories

    compile_convo_engine_document(
        collapsed,
        source_path=resolved_dest,
        default_owner=owner,
        validate_cross_references=False,
    )

    writes: list[str] = []
    removed: list[str] = []
    if write:
        resolved_dest.parent.mkdir(parents=True, exist_ok=True)
        resolved_dest.write_text(
            json.dumps(collapsed, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        writes.append(str(resolved_dest))
        if prune_sources:
            for sp in resolved_sources:
                if sp != resolved_dest and sp.is_file():
                    sp.unlink()
                    removed.append(str(sp))

    return {
        "ok": True,
        "previewOnly": not write,
        "effectFree": not write,
        "targetId": target_id,
        "destPath": str(resolved_dest),
        "sourceCount": len(resolved_sources),
        "variantCount": len(merged_variants),
        "textRowCount": len(merged_text_rows),
        "writes": writes,
        "removedSources": removed,
        "document": collapsed,
    }
