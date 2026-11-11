"""Context health and bounded affected closures for Conversation data."""

from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from typing import Any

from .conversation_contract import (
    CONVERSATION_MAX_INDEX_BYTES,
    CONVERSATION_MAX_RECORDS_PER_SHARD,
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_MAX_SOURCE_BYTES,
    CONVERSATION_PREFERRED_RECORDS_PER_SHARD,
    CONVERSATION_PREFERRED_SHARD_BYTES,
    CONVERSATION_PREFERRED_SOURCE_BYTES,
    CONVERSATION_SOURCE_RELATIVE,
)
from .conversation_discovery import conversation_discovery_index
from .conversation_model import copy_json as _copy_json


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

