"""Bounded helpers for source provenance inspection."""

from __future__ import annotations

from copy import deepcopy
from typing import Any


def provenance_value(value: Any, depth: int = 2) -> Any:
    """Keep the provenance inspector readable for large saved records."""

    if isinstance(value, dict):
        if depth <= 0:
            return {"keys": len(value)}
        keys = sorted(value, key=lambda item: str(item).casefold())
        output = {
            str(key): provenance_value(value[key], depth - 1)
            for key in keys[:12]
        }
        if len(keys) > 12:
            output["_omittedKeys"] = len(keys) - 12
        return output
    if isinstance(value, list):
        if depth <= 0:
            return {"count": len(value)}
        return {
            "count": len(value),
            "sample": [provenance_value(item, depth - 1) for item in value[:3]],
        }
    return deepcopy(value)


def value_at_path(value: Any, path: str) -> Any:
    current = value
    for segment in path.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(segment)
    return current
