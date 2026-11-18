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
from .psdl_compiler import (
    CONVO_ENGINE_SCHEMA,
    LEGACY_PSDL_SCHEMA,
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
        allow_legacy_schema=False,
    )
    return prepared, consumed_ids, compiled


def _uses_numeric_wording_id(record_id: str) -> bool:
    return any(not seg or seg.isdigit() for seg in record_id.split("."))


def canonical_family_spec_from_record(
    record: Mapping[str, Any],
    *,
    namespace: str | None = None,
    family_id: str | None = None,
    default_owner: str | None = None,
) -> dict[str, Any]:
    """Convert one legacy PSDL/dialogue record into a single-family ConvoEngine spec."""
    spec = copy.deepcopy(dict(record))
    spec.pop("schema", None)
    spec.setdefault("kind", "dialogue")
    if spec.get("owner") is None and default_owner is not None:
        spec["owner"] = default_owner
    if namespace is not None or family_id is not None:
        if namespace is not None:
            spec["namespace"] = namespace
        if family_id is not None:
            spec["id"] = family_id
        return spec
    raw_id = spec.get("id")
    if spec.get("namespace") is None and isinstance(raw_id, str) and "." in raw_id:
        candidate_ns, candidate_id = raw_id.rsplit(".", 1)
        try:
            resolve_family_identity(
                candidate_ns,
                candidate_id,
                strict_convo_engine=True,
                label="ConvoEngine family",
            )
            spec["namespace"] = candidate_ns
            spec["id"] = candidate_id
        except CompileError:
            pass
    return spec


def prepare_bucket_migration(
    source_document: Mapping[str, Any],
    plan: Sequence[Mapping[str, Any]],
    *,
    repository: Path,
    allowed_roots: Sequence[Path],
    default_owner: str | None = None,
    require_complete: bool = True,
) -> tuple[list[tuple[Path, dict[str, Any], list[str]]], list[str], dict[str, Any]]:
    """Accountably split a multi-record PSDL bucket into coherent ConvoEngine family files.

    Each plan entry must declare:
    - ``destPath`` (or ``dest_path``): destination relative/absolute ``.json`` path;
    - ``sourceRecordIds`` (or ``source_record_ids``): non-empty source record IDs;
    - either ``family`` (canonical ``psychopatz.convo-engine.v1`` spec), omitted for
      clean 1-record lossless conversion via ``canonical_family_spec_from_record``,
      or ``preNormalizationLegacy: true`` ONLY when grouping pre-S6M4 numeric-keyed
      records into one coherent family shard.
    """
    if not isinstance(plan, Sequence) or isinstance(plan, (str, bytes)) or not plan:
        raise CompileError("ConvoEngine migration plan must be a non-empty list of entries")

    source_records = _extract_source_records(source_document)
    if not source_records:
        raise CompileError("ConvoEngine migration source document contains no records")

    doc_owner = source_document.get("owner") if isinstance(source_document, Mapping) else None
    resolved_default_owner = default_owner or (str(doc_owner) if isinstance(doc_owner, str) else None)

    prepared: list[tuple[Path, dict[str, Any], list[str]]] = []
    seen_destinations: set[Path] = set()
    consumed_set: set[str] = set()
    consumed_ids: list[str] = []
    canonical_sources: dict[Path, dict[str, Any]] = {}
    legacy_sources: dict[Path, dict[str, Any]] = {}

    for index, raw_entry in enumerate(plan):
        if not isinstance(raw_entry, Mapping):
            raise CompileError(f"migration plan[{index}] must be an object")
        raw_dest = raw_entry.get("destPath", raw_entry.get("dest_path"))
        if not isinstance(raw_dest, (str, Path)) or not str(raw_dest).strip():
            raise CompileError(f"migration plan[{index}] requires destPath")
        dest_path = resolve_authorized_source_path(
            raw_dest,
            repository=repository,
            allowed_roots=allowed_roots,
        )
        if dest_path in seen_destinations:
            raise CompileError(f"migration plan repeats destination path: {dest_path}")
        seen_destinations.add(dest_path)

        raw_consumed = raw_entry.get("sourceRecordIds", raw_entry.get("source_record_ids"))
        if not isinstance(raw_consumed, list) or not raw_consumed or any(not isinstance(item, str) for item in raw_consumed):
            raise CompileError(f"migration plan[{index}].sourceRecordIds must be a non-empty list of strings")

        inherited_owner = resolved_default_owner
        selected_records: list[dict[str, Any]] = []
        for rec_id in raw_consumed:
            if rec_id not in source_records:
                raise CompileError(f"migration plan[{index}] references unknown source record {rec_id!r}")
            if rec_id in consumed_set:
                raise CompileError(f"migration plan consumes source record {rec_id!r} more than once")
            consumed_set.add(rec_id)
            consumed_ids.append(rec_id)
            record = copy.deepcopy(source_records[rec_id])
            selected_records.append(record)
            if inherited_owner is None and isinstance(record.get("owner"), str) and record["owner"].strip():
                inherited_owner = record["owner"]

        pre_norm_legacy = bool(raw_entry.get("preNormalizationLegacy"))
        if pre_norm_legacy:
            if not any(_uses_numeric_wording_id(rec_id) for rec_id in raw_consumed):
                raise CompileError(
                    f"migration plan[{index}] sets preNormalizationLegacy without numeric wording IDs"
                )
            for rec in selected_records:
                if rec.get("owner") is None and inherited_owner is not None:
                    rec["owner"] = inherited_owner
                rec.pop("schema", None)
            doc: dict[str, Any] = {
                "schema": LEGACY_PSDL_SCHEMA,
                **({"owner": inherited_owner} if inherited_owner is not None else {}),
                "records": selected_records,
            }
            legacy_sources[dest_path] = doc
            prepared.append((dest_path, doc, list(raw_consumed)))
            continue

        if bool(raw_entry.get("preFoldStyleGroup")):
            canonical_records = [
                canonical_family_spec_from_record(rec, default_owner=inherited_owner)
                for rec in selected_records
            ]
            bundle_doc: dict[str, Any] = {
                "schema": CONVO_ENGINE_SCHEMA,
                **({"owner": inherited_owner} if inherited_owner is not None else {}),
                "records": canonical_records,
            }
            canonical_sources[dest_path] = bundle_doc
            prepared.append((dest_path, bundle_doc, list(raw_consumed)))
            continue

        family_spec = raw_entry.get("family")
        if family_spec is None:
            if len(selected_records) != 1:
                raise CompileError(
                    f"migration plan[{index}] combines {len(selected_records)} records without a family spec"
                )
            family_spec = canonical_family_spec_from_record(
                selected_records[0],
                namespace=raw_entry.get("namespace"),
                family_id=raw_entry.get("id"),
                default_owner=inherited_owner,
            )
        elif not isinstance(family_spec, Mapping):
            raise CompileError(f"migration plan[{index}].family must be an object")

        family_doc = build_convo_engine_family_document(
            family_spec,
            default_owner=inherited_owner,
        )
        canonical_sources[dest_path] = family_doc
        prepared.append((dest_path, family_doc, list(raw_consumed)))

    if require_complete:
        unconsumed = sorted(set(source_records) - consumed_set)
        if unconsumed:
            raise CompileError(
                "migration plan leaves source records unconsumed: " + ", ".join(unconsumed)
            )

    fingerprints: list[str] = []
    if canonical_sources:
        compiled_canonical = compile_convo_engine_sources(
            canonical_sources,
            default_owner=resolved_default_owner,
            allow_legacy_schema=False,
            validate_cross_references=False,
        )
        fingerprints.append(str(compiled_canonical["fingerprint"]))
    if legacy_sources:
        compiled_legacy = compile_convo_engine_sources(
            legacy_sources,
            default_owner=resolved_default_owner,
            allow_legacy_schema=True,
            validate_cross_references=False,
        )
        fingerprints.append(str(compiled_legacy["fingerprint"]))

    return prepared, consumed_ids, {
        "fingerprint": fingerprint({"parts": fingerprints}),
        "canonicalCount": len(canonical_sources),
        "preNormalizationLegacyCount": len(legacy_sources),
    }


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


def migrate_convo_engine_schema(
    source_roots: Mapping[str, Path],
    *,
    owner: str | None = None,
    write: bool = False,
) -> dict[str, Any]:
    """Deterministically migrate ``psychopatz.psdl.*`` source/package schemas to ConvoEngine v1."""
    from .psdl_compact import validate_package_descriptor
    from .psdl_compiler import compile_convo_engine_document
    from .semantic_dialogue_ir import CONVO_ENGINE_PACKAGE_SCHEMA

    planned_writes: list[dict[str, Any]] = []
    pending_files: list[tuple[Path, dict[str, Any]]] = []

    for pkg_owner, root in sorted(source_roots.items()):
        if owner is not None and pkg_owner != owner:
            continue
        conv_root = Path(root).expanduser().resolve()
        if not conv_root.is_dir():
            continue

        package_path = conv_root / "package.json"
        pkg_doc: dict[str, Any] | None = None
        if package_path.is_file():
            raw_pkg = load_json_document(package_path)
            if raw_pkg.get("schema") == "psychopatz.psdl.package.v2":
                updated_pkg = copy.deepcopy(raw_pkg)
                updated_pkg["schema"] = CONVO_ENGINE_PACKAGE_SCHEMA
                pkg_doc = validate_package_descriptor(updated_pkg)
                planned_writes.append({
                    "owner": pkg_owner,
                    "path": str(package_path),
                    "kind": "package",
                    "fromSchema": "psychopatz.psdl.package.v2",
                    "toSchema": CONVO_ENGINE_PACKAGE_SCHEMA,
                    "fingerprint": fingerprint(updated_pkg),
                })
                pending_files.append((package_path, updated_pkg))
            else:
                pkg_doc = validate_package_descriptor(raw_pkg)

        for json_path in sorted(conv_root.rglob("*.json")):
            if json_path.name in {"package.json", "manifest.json", "provenance.lock"}:
                continue
            if "translations" in json_path.relative_to(conv_root).parts:
                continue
            raw_doc = load_json_document(json_path)
            if raw_doc.get("schema") != "psychopatz.psdl.v2":
                continue
            updated_doc = copy.deepcopy(raw_doc)
            updated_doc["schema"] = CONVO_ENGINE_SCHEMA
            compile_convo_engine_document(
                updated_doc,
                source_path=json_path,
                default_owner=pkg_owner,
                allow_legacy_schema=False,
                validate_cross_references=False,
                package=pkg_doc,
            )
            planned_writes.append({
                "owner": pkg_owner,
                "path": str(json_path),
                "kind": "source",
                "fromSchema": "psychopatz.psdl.v2",
                "toSchema": CONVO_ENGINE_SCHEMA,
                "fingerprint": fingerprint(updated_doc),
            })
            pending_files.append((json_path, updated_doc))

    writes: list[str] = []
    if write:
        for path, payload in pending_files:
            path.write_text(
                json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            writes.append(str(path))

    return {
        "ok": True,
        "previewOnly": not write,
        "effectFree": not write,
        "owner": owner,
        "plannedCount": len(planned_writes),
        "migratedCount": len(writes),
        "plannedWrites": planned_writes,
        "writes": writes,
    }
