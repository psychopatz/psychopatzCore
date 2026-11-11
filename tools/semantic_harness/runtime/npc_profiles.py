"""Semantic Lab NPC profile presets over the existing scenario projection.

The presets deliberately do not introduce a second NPC state store.  They only
write the scenario fields that the production worker already projects into
authority, behavior, hostility, and optional-mod compatibility checks.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any


PROFILE_IDS = ("companion", "neutral", "enemy", "trader", "custom")
PROFILE_LABELS = {
    "companion": "Companion (owned)",
    "neutral": "Neutral NPC",
    "enemy": "Enemy",
    "trader": "Trader (Dynamic Trading)",
    "custom": "Custom scenario",
}


def profile_id(scenario: dict[str, Any]) -> str:
    """Return the persisted profile marker, defaulting to the safe companion."""

    value = scenario.get("runtime", {}).get("semanticLabProfile", "companion")
    value = str(value or "companion").strip().lower()
    return value if value in PROFILE_IDS else "custom"


def profile_label(value: str) -> str:
    return PROFILE_LABELS.get(str(value), PROFILE_LABELS["custom"])


def apply_npc_profile(scenario: dict[str, Any], selected: str) -> dict[str, Any]:
    """Apply one Semantic Lab preset through the canonical scenario fields."""

    selected = str(selected or "custom").strip().lower()
    if selected not in PROFILE_IDS:
        raise ValueError(f"unknown Semantic Lab NPC profile: {selected}")

    updated = deepcopy(scenario)
    runtime = updated.setdefault("runtime", {})
    npc = updated.setdefault("npc", {})
    runtime["semanticLabProfile"] = selected

    if selected == "custom":
        return updated

    runtime["availableMods"] = {}
    # A profile switch must not retain a capability-specific role from the
    # previous preset.  Custom scenarios remain untouched above.
    npc.pop("role", None)
    npc.pop("ownerUsername", None)
    npc.pop("colonyOwned", None)
    # Keep the canonical record facts aligned with the production recruitment
    # service. actorAuthority drives UI capability projection; the service
    # itself reads the persisted recruited fact when rejecting a second invite.
    npc["recruited"] = selected == "companion"
    npc["followState"] = {"mode": "idle"}
    npc["hostility"] = {"attackPlayers": False}
    # Owned/recruited colonists have already been identified by the player.
    # Keep this canonical fact aligned with the native actor path.
    npc["identityState"] = "known" if selected == "companion" else "unknown"

    if selected == "companion":
        npc["activeBehavior"] = "idle"
        npc["actorAuthority"] = {
            "companion": True,
            "owned": True,
            "eligible": True,
            "status": "eligible",
        }
    elif selected == "neutral":
        npc["activeBehavior"] = "idle"
        npc["actorAuthority"] = {
            "companion": False,
            "owned": False,
            "eligible": False,
            "status": "not_companion",
        }
    elif selected == "enemy":
        npc["activeBehavior"] = "hostile"
        npc["hostility"] = {"attackPlayers": True}
        npc["actorAuthority"] = {
            "companion": False,
            "owned": False,
            "eligible": False,
            "status": "hostile",
        }
    elif selected == "trader":
        npc["activeBehavior"] = "idle"
        npc["role"] = "trader"
        npc["actorAuthority"] = {
            "companion": False,
            "owned": False,
            "eligible": False,
            "status": "not_companion",
        }
        runtime["availableMods"] = {"DTHoomans": True}

    return updated
