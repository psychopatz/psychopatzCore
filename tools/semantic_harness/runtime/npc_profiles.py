"""Provider-neutral profile selection hooks.

Concrete NPC profile policy belongs to provider packages. Core exposes one
stable neutral profile so shared authoring surfaces do not import an adopter.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any


PROFILE_IDS = ("core",)


def profile_id(scenario: dict[str, Any]) -> str:
    value = scenario.get("runtime", {}).get("semanticLabProfile")
    return str(value) if value in PROFILE_IDS else PROFILE_IDS[0]


def profile_label(value: str) -> str:
    return str(value).replace("_", " ").title()


def apply_npc_profile(scenario: dict[str, Any], selected: str) -> dict[str, Any]:
    if selected not in PROFILE_IDS:
        raise ValueError(f"unsupported Core profile: {selected}")
    result = deepcopy(scenario)
    result.setdefault("runtime", {})["semanticLabProfile"] = selected
    return result


__all__ = ["PROFILE_IDS", "apply_npc_profile", "profile_id", "profile_label"]
