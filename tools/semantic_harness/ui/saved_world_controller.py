"""Coordinate read-only saved-world discovery and target import."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from .ui_state_persistence import remember_active_source
from .selection_surface import save_source_selected


def discover_saved_worlds(app: Any) -> None:
    """Discover validated offline saves without starting Project Zomboid."""

    def finish(result: dict[str, Any]) -> None:
        app.saved_catalog = result if isinstance(result, dict) else {}
        entries = app.saved_catalog.get("saves") or []
        app.saved_world_entries = [
            entry for entry in entries if isinstance(entry, dict)
        ]
        app.saved_world_save_labels = {}
        labels: list[str] = []
        for entry in app.saved_world_entries:
            base_label = (
                f"{entry.get('saveName') or 'save'} · "
                f"{entry.get('mode') or 'unknown mode'}"
            )
            label = base_label
            suffix = 2
            while label in app.saved_world_save_labels:
                label = f"{base_label} ({suffix})"
                suffix += 1
            labels.append(label)
            app.saved_world_save_labels[label] = entry
        app.saved_world_save_box.configure(values=tuple(labels))
        app.saved_world_browser = {}
        app.saved_world_player_box.configure(values=())
        app.saved_world_player_var.set("")
        app.saved_world_target_var.set("No saved Player/NPC pair loaded")
        app._render_saved_world_tree()
        if labels:
            preferred_path = str(
                app._ui_state.get("saved_world_save_path") or ""
            )
            preferred_label = next(
                (
                    label
                    for label, entry in app.saved_world_save_labels.items()
                    if str(entry.get("path") or "") == preferred_path
                ),
                labels[0],
            )
            app.saved_world_save_var.set(preferred_label)
            _set_save_activation_status(
                app,
                app.saved_world_save_labels.get(preferred_label),
            )
            save_source_selected(
                app,
                app.saved_world_save_labels.get(preferred_label),
            )
            app.saved_world_status_var.set(
                f"{len(labels)} validated save(s); choose a save to browse its world."
            )
            app._set_controls(True)
            app._inspect_saved_world()
        else:
            rejected = len(app.saved_catalog.get("rejected") or [])
            app.saved_world_save_var.set("")
            app.saved_world_status_var.set(
                f"No readable save sources found ({rejected} rejected)."
            )
            app.saved_world_activation_var.set(
                "No readable save sources were found."
            )
            app._set_controls(True)

    app._start_operation(lambda worker: worker.save_catalog(), finish)


def selected_saved_world_entry(app: Any) -> dict[str, Any] | None:
    return app.saved_world_save_labels.get(app.saved_world_save_var.get())


def _set_save_activation_status(
    app: Any,
    entry: dict[str, Any] | None,
) -> None:
    activation = entry.get("modActivation") if isinstance(entry, dict) else None
    if not isinstance(activation, dict):
        app.saved_world_activation_var.set(
            "Active mods: metadata unavailable for this save"
        )
        return
    mod_ids = activation.get("modIDs") or []
    source = activation.get("serverProfile") or (
        (activation.get("sourceFiles") or ["save metadata"])[0]
    )
    status = str(activation.get("status") or "unknown")
    app.saved_world_activation_var.set(
        f"Active mods · {status} · {len(mod_ids)} detected · source {source}"
    )


def inspect_saved_world(app: Any) -> None:
    entry = app._selected_saved_world_entry()
    _set_save_activation_status(app, entry)
    if entry is None:
        app.saved_world_status_var.set("Discover and select a readable save first.")
        return
    save_path = str(entry.get("path") or "")
    if not save_path:
        app.saved_world_status_var.set("Selected save has no readable path.")
        return

    def finish(result: dict[str, Any]) -> None:
        app.saved_world_browser = result if isinstance(result, dict) else {}
        players = app.saved_world_browser.get("players") or []
        player_labels = [
            str(row.get("label") or row.get("id"))
            for row in players
            if isinstance(row, dict)
        ]
        app.saved_world_player_labels = {
            str(row.get("label") or row.get("id")): row
            for row in players
            if isinstance(row, dict)
        }
        app.saved_world_player_box.configure(values=tuple(player_labels))
        if player_labels:
            preferred_player = str(
                app._ui_state.get("saved_world_player_id") or ""
            )
            preferred_label = next(
                (
                    label
                    for label, row in app.saved_world_player_labels.items()
                    if str(row.get("uuid") or row.get("id") or "")
                    == preferred_player
                ),
                player_labels[0],
            )
            app.saved_world_player_var.set(preferred_label)
        app.saved_world_search_var.set(
            str(app._ui_state.get("saved_world_search") or "")
        )
        if app.saved_world_view_var.get() not in {
            "Relationship to Player",
            "Saved affiliations",
        }:
            app.saved_world_view_var.set(
                str(
                    app._ui_state.get("saved_world_view")
                    or "Relationship to Player"
                )
            )
        app.saved_world_npc_var.set("")
        app.saved_world_selected_actor = {}
        app.saved_world_selected_group = {}
        app._render_saved_world_tree()
        app._restore_saved_world_tree_selection()
        counts = app.saved_world_browser.get("counts") or {}
        app.saved_world_status_var.set(
            "Browsed save: "
            f"{counts.get('players', 0)} player(s), "
            f"{counts.get('npcs', 0)} NPC(s), "
            f"{counts.get('factions', 0)} faction(s), "
            f"{counts.get('communities', 0)} community reference(s)."
        )
        app.saved_world_target_var.set(
            "Choose a Player, expand a group, then double-click an NPC or use Load selected NPC."
        )
        app._set_controls(True)

    app._start_operation(
        lambda worker: worker.save_browser(Path(save_path)), finish
    )


def import_saved_world_target(app: Any) -> None:
    entry = app._selected_saved_world_entry()
    player = getattr(app, "saved_world_player_labels", {}).get(
        app.saved_world_player_var.get()
    )
    selection = app.saved_world_tree.selection()
    npc = app.saved_world_tree_actor_rows.get(selection[0]) if selection else None
    if entry is None or not player or not npc:
        app.saved_world_status_var.set(
            "Choose a save, Player, and NPC from the World hierarchy first."
        )
        return

    def finish(result: dict[str, Any]) -> None:
        scenario = result.get("scenario") if isinstance(result, dict) else None
        if isinstance(scenario, dict):
            app.scenario = scenario
            app._sync_workbench_from_scenario(scenario)
        app._update_simulation_projection(result)
        app._set_save_backed_mode(True)
        remember_active_source(
            app,
            "SAVE",
            save_path=str(entry.get("path") or ""),
            player_id=str(player.get("uuid") or player.get("id") or ""),
            npc_id=str(npc.get("id") or ""),
        )
        app._refresh_npc_dossier_if_selected()
        app.saved_world_target_var.set(
            f"Loaded Player {player.get('label')} → NPC {npc.get('label')}"
        )
        source = (result.get("sourceSnapshot") or {}).get("metadata", {})
        app.saved_world_status_var.set(
            "Imported saved target: "
            f"{player.get('label')} → {npc.get('label')} · "
            f"source {source.get('sourceKind', 'SAVE')}"
        )
        app._set_text(app.trace, pretty(result))
        app._append(
            "SYSTEM",
            f"Imported saved target {npc.get('label')} from read-only source save.",
        )
        app._append(
            "SYSTEM",
            "Saved target loaded; click Open conversation to start the native "
            "Conversation session. Preview is optional and does not send input.",
        )
        app._save_ui_state()
        app.main_tabs.select(app.simulation_tab)

    app._start_operation(
        lambda worker: worker.import_saved_selection(
            Path(str(entry.get("path"))),
            player_uuid=str(player.get("uuid") or player.get("id")),
            npc_id=str(npc.get("id")),
        ),
        finish,
    )
