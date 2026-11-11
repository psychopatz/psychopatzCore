"""Project worker simulation state into the semantic harness UI."""

from __future__ import annotations

from copy import deepcopy
from typing import Any


def update_simulation_projection(app: Any, response: dict[str, Any]) -> None:
    """Merge worker projections and refresh dependent UI controls."""

    if isinstance(response, dict):
        dossier = response.get("npcDossier")
        if isinstance(dossier, dict):
            app.npc_dossier_projection = deepcopy(dossier)
        history = response.get("relationshipHistory")
        if isinstance(history, dict):
            app.relationship_history_projection = deepcopy(history)
    social = app._social_context_from_response(response)
    if social:
        app.social_context_projection = social
    overrides = response.get("runtimeRelationshipOverrides") if isinstance(response, dict) else None
    if isinstance(overrides, dict):
        app.runtime_relationship_override_projection = deepcopy(overrides)
    elif isinstance(overrides, list):
        app.runtime_relationship_override_projection = {}
    app._update_source_provenance(response)
    projection = response.get("simulationProjection") if isinstance(response, dict) else None
    if isinstance(projection, dict):
        app.simulation_projection = projection
        npc_projection = projection.get("npc", {})
        bond = npc_projection.get("bond") if isinstance(npc_projection, dict) else None
        if isinstance(bond, dict):
            app.scenario.setdefault("npc", {}).setdefault("relationship", {})[
                "bond"
            ] = deepcopy(bond)
        relationship_projection = projection.get("relationship")
        relationship_projection = (
            relationship_projection
            if isinstance(relationship_projection, dict)
            else {}
        )
        relationship_record = relationship_projection.get("record")
        relationship_record = (
            relationship_record
            if isinstance(relationship_record, dict)
            else relationship_projection
        )
        for control_id in (
            "relationship.approval",
            "relationship.respect",
            "relationship.familiarity",
            "relationship.state",
            "relationship.bond",
            "relationship.friendBondProgress",
            "relationship.romanceCompatibility",
            "relationship.proposalThreshold",
            "relationship.proposalCooldown",
            "relationship.proposalAvailable",
        ):
            field = app.workbench_control_fields.get(control_id)
            control = next(
                (item for item in app.workbench_controls if item.get("id") == control_id),
                None,
            )
            if field is not None and control is not None:
                if control_id.startswith("relationship.") and control_id.split(".")[-1] in {
                    "approval",
                    "respect",
                    "familiarity",
                }:
                    relationship_key = control_id.split(".")[-1]
                    if relationship_key in relationship_record:
                        field.set_value(relationship_record[relationship_key])
                        continue
                field.set_value(
                    app._scenario_control_value(control, app.scenario)
                )
        app._set_relationship_preview_from_projection()
        app._update_generated_personality_controls()
    app._refresh_social_context_summary()
    app._refresh_relationship_missing_state()
