"""Pure presentation helpers for the Interaction Modules workbench."""

from __future__ import annotations

import json
from typing import Any

def _pretty(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)


def _behavior_content_refs(value: dict[str, Any] | None) -> dict[str, str]:
    """Return presentation content references without exposing wording here."""

    value = value if isinstance(value, dict) else {}
    outputs = value.get("outputs")
    outputs = outputs if isinstance(outputs, dict) else {}
    refs: dict[str, str] = {}
    for kind in ("speech", "flavor"):
        spec = outputs.get(kind)
        if isinstance(spec, dict):
            content_id = str(spec.get("contentTemplateID") or "").strip()
            if content_id:
                refs[kind] = content_id
    return refs


def _flatten_predicate(
    value: Any, *, prefix: str = "root", depth: int = 0
) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    if not isinstance(value, dict) or depth > 8:
        return [(prefix, "invalid", repr(value))]
    for structural in ("all", "any"):
        children = value.get(structural)
        if isinstance(children, list):
            rows.append((prefix, structural.upper(), f"{len(children)} children"))
            for index, child in enumerate(children, start=1):
                rows.extend(
                    _flatten_predicate(
                        child,
                        prefix=f"{prefix}.{structural}[{index}]",
                        depth=depth + 1,
                    )
                )
            return rows
    if isinstance(value.get("not"), dict):
        rows.append((prefix, "NOT", ""))
        rows.extend(
            _flatten_predicate(
                value["not"],
                prefix=f"{prefix}.not",
                depth=depth + 1,
            )
        )
        return rows
    expected = value.get("values") if "values" in value else value.get("value")
    rows.append(
        (
            prefix,
            f"{value.get('path', '?')} {value.get('op', '?')}",
            _pretty(expected) if isinstance(expected, (dict, list)) else str(expected),
        )
    )
    return rows
