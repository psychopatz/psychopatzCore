"""Provider-neutral Conversation model mechanics.

Core owns the mechanics that every Conversation source compiler needs:
canonical JSON fingerprints, defensive document copies, bounded provenance
merging, global record-location registration, and runtime-record projection.
Adopters retain their domain validators, merge policy, translation layout, and
generated registry/rendering rules.
"""

from __future__ import annotations

import copy
import hashlib
import json
from typing import Any, Iterable, Mapping

from .errors import CompileError


def canonical_json(value: Any) -> str:
    """Serialize JSON-compatible data deterministically."""
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def fingerprint(value: Any) -> str:
    """Return the stable SHA-256 fingerprint used by generated artifacts."""
    return hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def copy_json(value: Any) -> Any:
    """Copy JSON-compatible data before enriching a compiled model."""
    return copy.deepcopy(value)


def merge_source_metadata(
    documents: Iterable[Mapping[str, Any]],
    *,
    label: str = "Conversation",
) -> dict[str, Any]:
    """Merge source provenance while rejecting conflicting named references."""
    first: dict[str, Any] | None = None
    references: dict[str, dict[str, Any]] = {}
    for document in documents:
        source = document.get("source")
        if not isinstance(source, dict):
            raise CompileError(f"{label} shards require source metadata")
        if first is None:
            first = copy_json(source)
        for reference in source.get("references", []):
            if not isinstance(reference, dict) or not isinstance(
                reference.get("name"), str
            ):
                raise CompileError(
                    f"{label} source references require a name"
                )
            name = reference["name"]
            previous = references.get(name)
            if previous is not None and canonical_json(previous) != canonical_json(
                reference
            ):
                raise CompileError(
                    f"conflicting {label.lower()} source reference metadata: {name}"
                )
            references[name] = copy_json(reference)
    if first is None:
        raise CompileError(f"{label} manifest has no source metadata")
    if references:
        first["references"] = [references[name] for name in sorted(references)]
    return first


def register_global_id(
    locations: dict[str, dict[str, Any]],
    record_id: Any,
    *,
    kind: str,
    shard: Mapping[str, Any],
    path: str,
    owner: str | None = None,
) -> None:
    """Register one canonical record location and reject collisions."""
    if not isinstance(record_id, str) or not record_id:
        return
    previous = locations.get(record_id)
    if previous is not None:
        raise CompileError(
            f"duplicate global Conversation ID {record_id!r}: "
            f"{previous['sourceShard']} and {path}"
        )
    location = {
        "id": record_id,
        "kind": kind,
        "sourceShard": path,
        "domain": shard["domain"],
    }
    if owner is not None:
        location["owner"] = owner
    locations[record_id] = location


def runtime_records(
    records: Iterable[Mapping[str, Any]],
    *,
    excluded_fields: frozenset[str] = frozenset(("sourceShard", "conversationDomain")),
) -> list[dict[str, Any]]:
    """Project compiled records into bounded runtime payloads."""
    return [
        {
            key: copy_json(value)
            for key, value in record.items()
            if key not in excluded_fields
        }
        for record in records
    ]


__all__ = [
    "canonical_json",
    "copy_json",
    "fingerprint",
    "merge_source_metadata",
    "register_global_id",
    "runtime_records",
]
