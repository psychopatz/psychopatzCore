"""Format detection and schema-aware projections for saved ModData tables."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class FormatInfo:
    key: str
    label: str
    schema_version: Any = None
    specialized: bool = False


def detect_format(table_name: str, value: Any = None) -> FormatInfo:
    """Identify known table namespaces without rejecting unknown mod data."""
    if table_name == "PNC_Core_Global":
        schema = value.get("schemaVersion") if isinstance(value, dict) else None
        return FormatInfo("project_hoomans.directory", "Project Hoomans registry", schema, True)
    if table_name.startswith("PNC_npc"):
        schema = value.get("schemaVersion") if isinstance(value, dict) else None
        return FormatInfo("project_hoomans.npc", "Project Hoomans NPC record", schema, True)
    if table_name.startswith("PNC_"):
        schema = value.get("schemaVersion") if isinstance(value, dict) else None
        return FormatInfo("project_hoomans.namespace", "Project Hoomans namespace", schema, True)
    return FormatInfo("generic", "Generic PZ ModData", specialized=False)


def _format_npc_inventory(value: Any) -> Any:
    if not isinstance(value, list) or len(value) < 2:
        return value
    schema = value[0]
    mode = value[1]
    if not isinstance(schema, (int, float)) or mode not in ("SEED_ONLY", "BASELINE_DELTA", "FULL"):
        return value
    if mode == "FULL":
        return {
            "_format": "Project Hoomans inventory persistence",
            "schema": schema,
            "mode": mode,
            "payload": value[2] if len(value) > 2 else None,
        }
    return {
        "_format": "Project Hoomans inventory persistence",
        "schema": schema,
        "mode": mode,
        "revision": value[2] if len(value) > 2 else None,
        "baseline": value[3] if len(value) > 3 else None,
        "delta": value[4] if len(value) > 4 else None,
    }


def formatted_value(table_name: str, value: Any) -> Any:
    """Return a display projection; the raw decoded value is never modified."""
    info = detect_format(table_name, value)
    if info.key != "project_hoomans.npc" or not isinstance(value, dict):
        return value
    output = dict(value)
    if "inventory" in output:
        output["inventory"] = _format_npc_inventory(output["inventory"])
    return output
