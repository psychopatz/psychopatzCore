"""Pure layout policy for the semantic simulation workbench."""

from __future__ import annotations

from typing import Any

WORKBENCH_PANEL_NAMES = (
    "NPC Target",
    "Player",
    "Relationship",
    "World",
    "Faction / Community",
)
ACTOR_WORKBENCH_TABS = ("Overview", "Needs", "Personality & Traits", "Inventory")


def page_layout(panel_name: str, tab_name: str) -> str:
    if panel_name in {"NPC Target", "Player"}:
        if tab_name == "Needs":
            return "stacked"
        if tab_name == "Personality & Traits":
            return "personality"
        return "two_column"
    return "stacked"


def section_order(control: dict[str, Any]) -> tuple[int, str]:
    panel_name = str(control.get("workbenchPanel") or "World")
    tab_name = str(control.get("workbenchTab") or "Overview")
    section = str(control.get("workbenchSection") or "")
    if tab_name == "Personality & Traits":
        priority = {
            "Traits": 0,
            "Registered traits": 0,
            "Personality source": 1,
            "Derived social profile": 2,
            "Generated personality": 3,
        }
        return priority.get(section, 10), section
    return 0, section


__all__ = [
    "ACTOR_WORKBENCH_TABS",
    "WORKBENCH_PANEL_NAMES",
    "page_layout",
    "section_order",
]
