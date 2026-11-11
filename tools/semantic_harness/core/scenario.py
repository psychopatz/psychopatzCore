"""Provider-neutral scenario document utilities.

This module owns document mechanics only. Adopters supply defaults,
normalizers, and domain validation in their own packages.
"""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path
from typing import Any, Iterable, Mapping


def derive_display_name(forename: Any, surname: Any) -> str:
    """Build a display name from bounded actor name fields."""

    return " ".join(
        part.strip()
        for part in (str(forename or ""), str(surname or ""))
        if part.strip()
    )


def derive_actor_identifier(prefix: str, forename: Any, surname: Any) -> str:
    """Build a stable readable identifier without owning actor state."""

    name = derive_display_name(forename, surname).lower()
    slug = re.sub(r"[^a-z0-9]+", "_", name).strip("_")
    return f"{prefix}_{slug or 'actor'}"


def deep_merge(
    base: Mapping[str, Any],
    override: Mapping[str, Any],
    *,
    replace_empty_objects: Iterable[str] = (),
) -> dict[str, Any]:
    """Recursively merge a document without mutating either input.

    ``replace_empty_objects`` is an adopter policy hook for fields where an
    authored empty object intentionally clears the default object. Core does
    not prescribe domain field names.
    """

    output: dict[str, Any] = deepcopy(dict(base))
    replace_empty = set(replace_empty_objects)
    for key, value in override.items():
        if (
            isinstance(value, Mapping)
            and key not in replace_empty
            and isinstance(output.get(key), dict)
        ):
            output[key] = deep_merge(
                output[key],
                value,
                replace_empty_objects=replace_empty,
            )
        else:
            output[key] = deepcopy(value)
    return output


def load_json_document(path: str | Path) -> dict[str, Any]:
    """Read one bounded JSON object document."""

    document_path = Path(path)
    with document_path.open("r", encoding="utf-8") as handle:
        document = json.load(handle)
    if not isinstance(document, dict):
        raise ValueError("document root must be a JSON object")
    return document


def save_json_document(path: str | Path, document: Mapping[str, Any]) -> Path:
    """Atomically persist one JSON object document."""

    if not isinstance(document, Mapping):
        raise ValueError("document must be a mapping")
    document_path = Path(path)
    document_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = document_path.with_name(document_path.name + ".tmp")
    try:
        with temporary.open("w", encoding="utf-8") as handle:
            json.dump(
                dict(document),
                handle,
                indent=2,
                ensure_ascii=False,
                sort_keys=True,
            )
            handle.write("\n")
        temporary.replace(document_path)
    finally:
        if temporary.exists():
            temporary.unlink()
    return document_path
