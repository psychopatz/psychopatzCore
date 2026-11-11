"""Render the selected saved-world context above the simulation workbench."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def refresh_simulation_context(app: Any) -> None:
    """Render the readable save-backed target context above the workbench."""

    if not hasattr(app, "simulation_context_var"):
        return
    source_snapshot = app.source_snapshot_projection
    metadata = (
        source_snapshot.get("metadata", {})
        if isinstance(source_snapshot, dict)
        else {}
    )
    source = str(
        metadata.get("sourceKind")
        or ("SAVE" if app.save_backed_mode else "FIXTURE")
    ).upper()
    save_name = str(app.saved_world_browser.get("saveName") or "").strip()
    if not save_name and source == "SAVE":
        save_path = str(metadata.get("savePath") or "").strip()
        if save_path:
            save_name = Path(save_path).parent.name
    player = app.scenario.get("player", {})
    npc = app.scenario.get("npc", {})
    player = player if isinstance(player, dict) else {}
    npc = npc if isinstance(npc, dict) else {}
    selected_actor = app.saved_world_selected_actor
    if not isinstance(selected_actor, dict):
        selected_actor = {}
    if selected_actor.get("id") and selected_actor.get("id") != npc.get("npcID"):
        selected_actor = {}
    target = str(
        npc.get("displayName")
        or selected_actor.get("label")
        or "No NPC target"
    )
    player_label = str(
        player.get("displayName")
        or player.get("characterUUID")
        or "No Player"
    )
    faction = str(
        selected_actor.get("factionLabel")
        or npc.get("factionLabel")
        or "MISSING"
    )
    community = str(
        selected_actor.get("communityLabel")
        or npc.get("communityLabel")
        or "MISSING"
    )
    parts = [f"Source {source}"]
    if save_name:
        parts.append(f"Save: {save_name}")
    parts.extend(
        [
            f"Player: {player_label}",
            f"Target: {target}",
            f"Faction: {faction}",
            f"Community: {community}",
        ]
    )
    app.simulation_context_var.set(" · ".join(parts))
