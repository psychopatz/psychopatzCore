"""Stable JSON response envelopes and bounded artifact descriptors."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any, Mapping, Sequence


SCHEMA_VERSION = 1


def canonical_json(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=True, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact_descriptor(path: Path, kind: str, **extra: Any) -> dict[str, Any]:
    result: dict[str, Any] = {"kind": kind, "path": str(path.resolve())}
    if path.exists() and path.is_file():
        result.update({"bytes": path.stat().st_size, "sha256": sha256_path(path)})
    result.update({key: value for key, value in extra.items() if value is not None})
    return result


def revision_for(value: Any) -> str:
    return sha256_bytes(canonical_json(value))


def _bounded(value: Any, budget: int, *, depth: int = 0) -> tuple[Any, bool]:
    if depth > 10:
        return "…", True
    if isinstance(value, str):
        if len(value) <= budget:
            return value, False
        return value[: max(1, budget - 1)] + "…", True
    if isinstance(value, (int, float, bool)) or value is None:
        return value, False
    if isinstance(value, list):
        output: list[Any] = []
        truncated = False
        for item in value:
            if len(canonical_json(output)) > budget:
                truncated = True
                break
            child, child_truncated = _bounded(item, budget, depth=depth + 1)
            output.append(child)
            truncated = truncated or child_truncated
        if len(output) < len(value):
            truncated = True
        return output, truncated
    if isinstance(value, Mapping):
        output: dict[str, Any] = {}
        truncated = False
        for key in sorted(value, key=str):
            if len(canonical_json(output)) > budget:
                truncated = True
                break
            child, child_truncated = _bounded(value[key], budget, depth=depth + 1)
            output[str(key)] = child
            truncated = truncated or child_truncated
        if len(output) < len(value):
            truncated = True
        return output, truncated
    return str(value), True


def bound_response(response: Mapping[str, Any], token_budget: int) -> dict[str, Any]:
    budget = max(256, int(token_budget)) * 4
    candidate = dict(response)
    encoded = canonical_json(candidate)
    if len(encoded) <= budget:
        return candidate
    bounded, truncated = _bounded(candidate, budget)
    if not isinstance(bounded, dict):
        bounded = {"value": bounded}
    # Envelope metadata must remain trustworthy even when a large audit data
    # payload is bounded.  In particular, dropping ``ok`` would make the text
    # CLI report a successful audit as failed merely because its evidence was
    # large.
    for key in ("schema_version", "ok", "command", "project_id", "revision", "summary"):
        if key in candidate:
            bounded[key] = candidate[key]
    bounded["truncated"] = True
    return bounded


def envelope(
    command: str,
    *,
    ok: bool,
    project_id: str | None = None,
    revision: str | None = None,
    summary: Mapping[str, Any] | None = None,
    diagnostics: Sequence[Mapping[str, Any]] = (),
    artifacts: Sequence[Mapping[str, Any]] = (),
    data: Mapping[str, Any] | None = None,
    truncated: bool = False,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "ok": bool(ok),
        "command": command,
        "project_id": project_id,
        "revision": revision,
        "summary": dict(summary or {}),
        "diagnostics": [dict(item) for item in diagnostics],
        "artifacts": [dict(item) for item in artifacts],
        "truncated": bool(truncated),
    }
    if data:
        result["data"] = dict(data)
    return result
