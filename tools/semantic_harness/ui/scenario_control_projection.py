"""Resolve projected UI control values from scenario and worker state."""

from __future__ import annotations

from typing import Any


def scenario_control_value(
    app: Any, control: dict[str, Any], scenario: dict[str, Any]
) -> Any:
    """Resolve one workbench control from authoritative projections."""

    control_id = str(control.get("id") or "")
    if control_id == "relationship.state":
        projected_relationship = app.simulation_projection.get("relationship", {})
        if isinstance(projected_relationship, dict) and projected_relationship.get("standing"):
            return projected_relationship.get("standing")
        response = app.last_response if isinstance(app.last_response, dict) else {}
        context = response.get("contextAfter") or response.get("context") or {}
        actor = context.get("actorConversationContext", {}) if isinstance(context, dict) else {}
        relationship = actor.get("relationship", {}) if isinstance(actor, dict) else {}
        return relationship.get("state", "unknown")
    if control_id == "relationship.bond":
        relationship_projection = app.simulation_projection.get("relationship", {})
        if isinstance(relationship_projection, dict):
            projected_bond = relationship_projection.get("bond")
            if isinstance(projected_bond, dict):
                return projected_bond.get("kind") or projected_bond.get("class") or "none"
        bond = app.simulation_projection.get("npc", {}).get("bond", {})
        if isinstance(bond, dict):
            return bond.get("kind") or bond.get("class") or "none"
        return control.get("currentValue", "none")
    if control_id == "relationship.friendBondProgress":
        relationship = app.simulation_projection.get("relationship", {})
        if not isinstance(relationship, dict):
            relationship = {}
        thresholds = relationship.get("friendBondThresholds") or {
            "approval": 80,
            "respect": 50,
            "familiarity": 60,
        }
        return (
            f"Approval {relationship.get('approval', 0)} / {thresholds.get('approval', 80)} · "
            f"Respect {relationship.get('respect', 0)} / {thresholds.get('respect', 50)} · "
            f"Familiarity {relationship.get('familiarity', 0)} / {thresholds.get('familiarity', 60)}"
        )
    if control_id in {
        "relationship.romanceCompatibility",
        "relationship.proposalThreshold",
        "relationship.proposalCooldown",
        "relationship.proposalAvailable",
    }:
        proposal = app.simulation_projection.get("relationship", {})
        if not isinstance(proposal, dict):
            proposal = {}
        if control_id == "relationship.romanceCompatibility":
            return "compatible" if proposal.get("compatible") is True else "incompatible"
        if control_id == "relationship.proposalThreshold":
            thresholds = proposal.get("thresholds") or {}
            return (
                f"Approval {thresholds.get('approval', 85)} · "
                f"Respect {thresholds.get('respect', 60)} · "
                f"Familiarity {thresholds.get('familiarity', 80)}"
            )
        if control_id == "relationship.proposalCooldown":
            return f"{float(proposal.get('cooldownRemaining') or 0):.1f}h"
        return "yes" if proposal.get("eligible") is True else "no"
    if control_id == "npc.personalityMode":
        response = app.last_response if isinstance(app.last_response, dict) else {}
        context = response.get("contextAfter") or response.get("context") or {}
        if isinstance(context, dict) and context.get("npcPersonalityMode"):
            return context.get("npcPersonalityMode")
        return control.get("currentValue", "generated")
    if control_id.startswith("player.socialProfile."):
        key = control_id.rsplit(".", 1)[-1]
        if app.player_social_profile_preview:
            return app.player_social_profile_preview.get(
                key, control.get("currentValue", "unknown")
            )
        projection = app.simulation_projection.get("player", {})
        profile = projection.get("socialProfile") or app.persona_catalog.get("playerSocialProfile", {})
        response = app.last_response if isinstance(app.last_response, dict) else {}
        context = response.get("contextAfter") or response.get("context") or {}
        if isinstance(context, dict):
            profile = context.get("playerSocialProfile") or profile
        return profile.get(key, control.get("currentValue", "unknown"))
    if control_id == "persona.socialStyle" or control_id.startswith("persona.personality."):
        key = "socialStyle" if control_id == "persona.socialStyle" else control_id.rsplit(".", 1)[-1]
        projection = app.simulation_projection.get("npc", {})
        profile = projection.get("personality") or app.persona_catalog.get("npcPersonality", {})
        response = app.last_response if isinstance(app.last_response, dict) else {}
        context = response.get("contextAfter") or response.get("context") or {}
        if isinstance(context, dict):
            profile = context.get("npcPersonality") or profile
        if key in profile:
            return profile[key]
    if control.get("path") is None:
        return control.get("currentValue")
    value: Any = scenario
    path = control.get("path")
    if isinstance(path, str):
        for segment in path.split("."):
            if not isinstance(value, dict):
                value = None
                break
            value = value.get(segment)
    if control_id in {"persona.bondKind", "npc.role"}:
        return value or "none"
    return value
