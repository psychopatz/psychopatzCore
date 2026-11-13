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
    return doc


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
