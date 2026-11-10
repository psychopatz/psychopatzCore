"""Production-shaped NPC health fixtures for the semantic harness.

The game owns health as ``health.state/current/max/body``.  The semantic
layer derives conversational states such as ``injured`` from that snapshot.
This module keeps authored harness scenarios on the same boundary and only
adapts older fixture fields while they are being migrated.
"""

from __future__ import annotations

from copy import deepcopy
import math
from typing import Any, Mapping


PRODUCTION_HEALTH_STATES = frozenset(
    {"normal", "incapacitated", "dead", "corpse"}
)
LEGACY_HEALTH_FIELDS = frozenset(
    {"healthState", "hpCurrent", "hpMax", "bodyHealth"}
)
LEGACY_SEMANTIC_STATES = frozenset(
    {"healthy", "injured", "wounded", "critical", "unknown"}
)


def _number(value: Any, field: str) -> int | float | None:
    if value is None:
        return None
    if isinstance(value, bool):
        raise ValueError(f"npc.health.{field} must be numeric")
    try:
        number = float(value)
    except (TypeError, ValueError) as error:
        raise ValueError(f"npc.health.{field} must be numeric") from error
    if not math.isfinite(number):
        raise ValueError(f"npc.health.{field} must be finite")
    return int(number) if number.is_integer() else number


def _legacy_body(state: str | None) -> dict[str, Any] | None:
    if state not in {"injured", "wounded", "critical"}:
        return None
    # Compatibility only: old fixtures expressed an injury without a body
    # snapshot. Make that meaning explicit in the production-shaped record.
    return {
        "bleedingRate": 0,
        "openWoundCount": 1,
        "bandagedWoundCount": 0,
        "infected": False,
        "wholeBodyAilments": {},
        "wounds": {"legacy": {"type": "legacy_fixture_injury"}},
        "overallPercent": 98 if state != "critical" else 50,
    }


def normalize_npc_health(npc: Mapping[str, Any]) -> dict[str, Any] | None:
    """Return one production-shaped health record or ``None`` when unknown.

    ``health`` is authoritative for new scenarios. Top-level legacy fields
    are accepted only as a migration adapter and are folded into that record;
    callers never need to transport both representations to Lua.
    """

    raw_health = npc.get("health")
    if raw_health is not None and not isinstance(raw_health, Mapping):
        raise ValueError("npc.health must be an object or null")

    legacy_present = any(field in npc for field in LEGACY_HEALTH_FIELDS)
    if raw_health is None and "health" in npc and not legacy_present:
        return None
    if raw_health is None and not legacy_present:
        return None

    health: dict[str, Any] = deepcopy(dict(raw_health or {}))
    if "healthState" in npc:
        health["state"] = npc.get("healthState")
    if "hpCurrent" in npc:
        health["current"] = npc.get("hpCurrent")
    if "hpMax" in npc:
        health["max"] = npc.get("hpMax")
    if "bodyHealth" in npc:
        body = npc.get("bodyHealth")
        health["body"] = deepcopy(body) if isinstance(body, Mapping) else None

    state_value = health.get("state")
    if state_value is None or str(state_value).strip() == "":
        state = None
    else:
        state = str(state_value).strip().lower()
    if state in LEGACY_SEMANTIC_STATES:
        if not legacy_present:
            raise ValueError(
                "npc.health.state must use a production health state; "
                "semantic-only states belong in the legacy adapter"
            )
        if state == "unknown":
            return None
        legacy_state = state
        state = "normal"
        if "bodyHealth" not in npc:
            health["body"] = _legacy_body(legacy_state)
    elif state is not None and state not in PRODUCTION_HEALTH_STATES:
        raise ValueError(
            "npc.health.state must be one of: "
            + ", ".join(sorted(PRODUCTION_HEALTH_STATES))
        )

    health["state"] = state
    for key in ("current", "max"):
        value = _number(health.get(key), key)
        if value is None:
            health.pop(key, None)
        else:
            health[key] = value

    body = health.get("body")
    if body is not None and not isinstance(body, Mapping):
        raise ValueError("npc.health.body must be an object or null")
    if isinstance(body, Mapping):
        health["body"] = deepcopy(dict(body))
    else:
        health.pop("body", None)

    # A production record normally has these values. Defaults are only
    # applied when a legacy state supplied no raw HP; explicit raw snapshots
    # remain untouched so missing facts still exercise the semantic unknown
    # path.
    if legacy_present and state in {"normal", "incapacitated"}:
        health.setdefault("max", 100)
        health.setdefault("current", 100 if state == "normal" else 0)
    return health


def normalize_scenario(scenario: Mapping[str, Any]) -> dict[str, Any]:
    """Deep-copy a scenario and fold legacy NPC health fields into ``health``."""

    output = deepcopy(dict(scenario))
    npc = output.get("npc")
    if isinstance(npc, dict):
        health = normalize_npc_health(npc)
        npc["health"] = health
        for field in LEGACY_HEALTH_FIELDS:
            npc.pop(field, None)
    return output


def validate_npc_health(npc: Mapping[str, Any]) -> None:
    """Validate both canonical health and transitional legacy fixture input."""

    health = normalize_npc_health(npc)
    if health is None:
        return
    current = health.get("current")
    maximum = health.get("max")
    if current is not None and current < 0:
        raise ValueError("npc.health.current must be at least 0")
    if maximum is not None and maximum < 0:
        raise ValueError("npc.health.max must be at least 0")
    if current is not None and maximum is not None and current > maximum:
        raise ValueError("npc.health.current must not exceed npc.health.max")
