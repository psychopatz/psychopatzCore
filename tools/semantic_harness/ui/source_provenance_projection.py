"""Project imported save provenance and working-world authority for the UI."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty


def update_source_provenance(app: Any, response: dict[str, Any]) -> None:
    """Merge compact worker provenance into bounded UI projections."""

    if not isinstance(response, dict):
        return
    source = response.get("sourceSnapshot")
    working = response.get("workingWorld")
    if isinstance(source, dict):
        previous_source = app.source_snapshot_projection
        merged_source = deepcopy(previous_source)
        merged_source.update(deepcopy(source))
        # Compact worker snapshots deliberately omit the duplicated raw
        # save/provider payloads. Keep the already-imported diagnostic
        # copy available to the UI when a later mutation is rendered.
        for key in ("data", "providerPayloads"):
            if key not in source and key in previous_source:
                merged_source[key] = deepcopy(previous_source[key])
        app.source_snapshot_projection = merged_source
    if isinstance(working, dict):
        previous_working = app.working_world_projection
        merged_working = deepcopy(previous_working)
        merged_working.update(deepcopy(working))
        # The working-world baseline is immutable for this import and is
        # intentionally omitted by the compact transport boundary.
        if "baseline" not in working and "baseline" in previous_working:
            merged_working["baseline"] = deepcopy(previous_working["baseline"])
        app.working_world_projection = merged_working
    source = app.source_snapshot_projection
    working = app.working_world_projection
    if not isinstance(source, dict) or not isinstance(working, dict):
        return
    source_data = source.get("data") if isinstance(source.get("data"), dict) else {}
    effective = response.get("scenario")
    if not isinstance(effective, dict):
        effective = working.get("effective")
    if not isinstance(effective, dict):
        effective = {}
    metadata = source.get("metadata") if isinstance(source.get("metadata"), dict) else {}
    provenance = source.get("provenance") if isinstance(source.get("provenance"), dict) else {}
    path_sources = provenance.get("paths") if isinstance(provenance.get("paths"), dict) else {}
    patches = working.get("patches") if isinstance(working.get("patches"), list) else []
    patch_sources = {
        str(patch.get("path")): patch
        for patch in patches
        if isinstance(patch, dict) and patch.get("path")
    }
    important_paths = (
        "npc.relationship.baselineApproval",
        "npc.relationship.baselineRespect",
        "npc.relationship.approval",
        "npc.relationship.respect",
        "npc.relationship.familiarity",
        "npc.relationship.state",
        "npc.relationship.previousState",
        "npc.relationship.bond",
        "npc.relationship.memories",
        "npc.relationship.cooldowns",
        "npc.relationship.interactionJournal",
        "npc.relationship.interactionRevision",
        "npc.relationship.revision",
        "world.weather",
        "world.timeOfDay",
        "world.temperature",
        "world.season",
        "player.needs",
        "npc.needs",
        "player.inventory.revision",
        "npc.inventory.revision",
    )
    fields: dict[str, Any] = {}
    for path in important_paths:
        imported = app._value_at_path(source_data, path)
        current = app._value_at_path(effective, path)
        patch = patch_sources.get(path)
        source_info = path_sources.get(path)
        source_info = source_info if isinstance(source_info, dict) else {}
        origin = (
            str(patch.get("source"))
            if patch is not None
            else str(source_info.get("source") or metadata.get("sourceKind") or "MISSING")
        )
        fields[path] = {
            "imported": app._provenance_value(imported),
            "effective": app._provenance_value(current),
            "source": origin,
            "baseSource": str(
                patch.get("baseSource")
                if patch is not None
                else source_info.get("source")
                or metadata.get("sourceKind")
                or "MISSING"
            ),
            "provider": source_info.get("provider"),
        }
    app.provenance_projection = {
        "schema": "semantic.ui.provenance_projection.v1",
        "source": {
            "kind": metadata.get("sourceKind", "MISSING"),
            "id": metadata.get("sourceID"),
            "mode": metadata.get("mode"),
            "immutable": source.get("immutable") is True
            or metadata.get("immutable") is True,
        },
        "workingWorld": {
            "schema": working.get("schema"),
            "sourceSnapshotID": working.get("sourceSnapshotID"),
            "resetCount": working.get("resetCount", 0),
            "patchCount": len(patches),
        },
        "fields": fields,
        "runtimeRelationshipOverrides": app._provenance_value(
            response.get("runtimeRelationshipOverrides")
        ),
    }
    simulation = response.get("simulationProjection")
    projected_relationship = (
        simulation.get("relationship")
        if isinstance(simulation, dict)
        else None
    )
    if isinstance(projected_relationship, dict):
        app.provenance_projection["relationshipAuthority"] = {
            "authority": "PNC.RelationshipGraph + PNC.RelationshipPresentation",
            "record": app._provenance_value(
                projected_relationship.get("record")
            ),
            "graph": app._provenance_value(
                projected_relationship.get("productionGraph")
            ),
            "presentation": app._provenance_value(
                projected_relationship.get("productionPresentation")
            ),
        }
    if getattr(app, "provenance_status_var", None) is not None:
        runtime_overrides = response.get("runtimeRelationshipOverrides")
        runtime_override_count = (
            len(runtime_overrides)
            if isinstance(runtime_overrides, dict)
            else 0
        )
        app.provenance_status_var.set(
            f"Source: {metadata.get('sourceKind', 'MISSING')} · "
            f"working overrides: {len(patches)} · "
            f"runtime relationship overrides: {runtime_override_count} · "
            "immutable source snapshot"
        )
    if hasattr(app, "provenance_inspector"):
        app._set_text(app.provenance_inspector, pretty(app.provenance_projection))
    app._refresh_actor_inspectors()
