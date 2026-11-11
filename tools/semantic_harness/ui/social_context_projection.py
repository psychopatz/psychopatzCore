"""Pure social-context normalization and readable-line projection."""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Callable

def social_context_from_response(response: Any) -> dict[str, Any]:
    if not isinstance(response, dict):
        return {}
    candidates = [
        response.get("contextAfter"),
        response.get("context"),
        response.get("socialContext"),
    ]
    observation = response.get("observation")
    if isinstance(observation, dict):
        candidates.extend(
            [observation.get("contextAfter"), observation.get("context")]
        )
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        social = candidate.get("socialContext")
        if isinstance(social, dict):
            return deepcopy(social)
        if {
            "personalRelationship",
            "factionRelationship",
            "tacticalHostility",
        }.intersection(candidate):
            return deepcopy(candidate)
    return {}


def social_context_lines(
    social: dict[str, Any],
    format_number: Callable[[Any], str],
) -> list[str]:
    personal = social.get("personalRelationship") or {}
    faction = social.get("factionRelationship") or {}
    effective = faction.get("effective") or faction
    tactical = social.get("tacticalHostility") or {}
    audience = social.get("conversationAudience") or {}
    bond = social.get("durableBond") or {}
    speech = social.get("speechStyle") or {}
    lines = [
        "Personal relationship",
        f"  {personal.get('state') or 'unknown'} · "
        f"source {personal.get('source') or 'MISSING'} · "
        f"reason {personal.get('reason') or 'MISSING'}",
        "  current: "
        f"Approval {format_number(personal.get('approval'))} · "
        f"Respect {format_number(personal.get('respect'))} · "
        f"Familiarity {format_number(personal.get('familiarity'))}",
        "Faction relationship",
        f"  {effective.get('state') or 'unknown'} · "
        f"standing {effective.get('standing', 'MISSING')} · "
        f"source {effective.get('source') or 'MISSING'}",
        "Tactical hostility",
        f"  {tactical.get('mode') or 'unknown'} · "
        f"attackPlayers={tactical.get('attackPlayers', 'MISSING')} · "
        f"source {tactical.get('source') or 'MISSING'}",
        "Conversation audience",
        f"  {audience.get('audience') or 'unknown'} · "
        f"reason {audience.get('reason') or 'MISSING'} · "
        f"source {audience.get('source') or 'MISSING'}",
        "Durable bond",
        f"  {bond.get('class') or 'none'} · "
        f"source {bond.get('source') or 'MISSING'}",
        "Speech style",
        f"  {speech.get('variant') or 'unknown'} · "
        f"reason {speech.get('reason') or 'MISSING'}",
    ]
    if personal.get("baselineApproval") is not None \
            or personal.get("baselineRespect") is not None:
        lines.insert(
            3,
            "  saved baseline: "
            f"Approval {format_number(personal.get('baselineApproval'))} · "
            f"Respect {format_number(personal.get('baselineRespect'))}",
        )
    return lines


__all__ = ["social_context_from_response", "social_context_lines"]
