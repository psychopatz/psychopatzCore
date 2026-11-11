"""Persist non-scenario UI selections and geometry."""

from __future__ import annotations

from typing import Any

from .state import save as persist_ui_state


def remember_active_source(
    app: Any,
    kind: str,
    *,
    save_path: str | None = None,
    player_id: str | None = None,
    npc_id: str | None = None,
) -> None:
    """Record bounded active-source intent in the existing UI-state mapping."""

    source_kind = str(kind or "FIXTURE").upper()
    if source_kind != "SAVE":
        app._ui_state["active_source_kind"] = "FIXTURE"
        return
    app._ui_state["active_source_kind"] = "SAVE"
    for key, value in (
        ("saved_world_save_path", save_path),
        ("saved_world_player_id", player_id),
        ("saved_world_npc_id", npc_id),
    ):
        if value not in (None, ""):
            app._ui_state[key] = str(value)


def schedule_save(app: Any, delay_ms: int = 250) -> None:
    """Debounce geometry/state writes while the user drags or switches panes."""

    pending = getattr(app, "_ui_state_save_after", None)
    if pending is not None:
        try:
            app.root.after_cancel(pending)
        except app._tk.TclError:
            pass
    app._ui_state_save_after = app.root.after(
        delay_ms, lambda: _flush_scheduled_save(app)
    )


def _flush_scheduled_save(app: Any) -> None:
    app._ui_state_save_after = None
    app._save_ui_state()


def save_ui_state(app: Any) -> None:
    try:
        state = dict(app._ui_state)
        state["layout_state_version"] = 4
        state["geometry"] = app.root.geometry()
        state["window_state"] = app.root.state()
        state["main_tab"] = app.main_tabs.index(app.main_tabs.select())
        state["studio_tab"] = app.studio_notebook.index(
            app.studio_notebook.select()
        )
        state["trace_tab"] = app.trace_tabs.index(app.trace_tabs.select())
        for key, notebook in (
            ("studio_explore_tab", getattr(app, "studio_explore_notebook", None)),
            ("advanced_tab", getattr(app, "advanced_notebook", None)),
            ("inspect_tab", getattr(app, "inspect_tabs", None)),
            ("graph_tab", getattr(app, "graph_tabs", None)),
            ("graph_detail_tab", getattr(app, "graph_detail_tabs", None)),
            ("compare_tab", getattr(app, "compare_tabs", None)),
            ("debug_tab", getattr(app, "debug_tabs", None)),
        ):
            if notebook is not None and notebook.tabs():
                state[key] = notebook.index(notebook.select())
        state["trace_panel_visible"] = app.trace_panel_visible
        state["advanced_controls_visible"] = app.advanced_controls_visible
        state["developer_tools_visible"] = bool(
            getattr(app, "developer_tools_host", None)
            and app.developer_tools_host.winfo_ismapped()
        )
        state["workbench_expanded"] = app.workbench_expanded
        selected_talk = app.talk_target_ids_by_label.get(
            app.talk_target_var.get(), "current"
        )
        state["talk_target"] = selected_talk
        state["talk_utterance"] = app.talk_utterance_var.get()
        selected_save = app._selected_saved_world_entry()
        selected_save_path = (
            str(selected_save.get("path") or "")
            if isinstance(selected_save, dict)
            else ""
        )
        if isinstance(selected_save, dict):
            state["saved_world_save_path"] = selected_save_path
        selected_player = (
            getattr(app, "saved_world_player_labels", {}).get(
                app.saved_world_player_var.get(), {}
            )
            if hasattr(app, "saved_world_player_var")
            else {}
        )
        selected_player_id = str(
            selected_player.get("uuid")
            or selected_player.get("id")
            or ""
        )
        selected_npc_id = str(
            app.saved_world_npc_var.get()
            if hasattr(app, "saved_world_npc_var")
            else ""
        )
        state["saved_world_player_id"] = selected_player_id
        state["saved_world_npc_id"] = selected_npc_id
        source_snapshot = getattr(app, "source_snapshot_projection", {})
        metadata = (
            source_snapshot.get("metadata", {})
            if isinstance(source_snapshot, dict)
            else {}
        )
        if app.save_backed_mode is True:
            state["active_source_kind"] = "SAVE"
            state["saved_world_save_path"] = str(
                metadata.get("savePath")
                or selected_save_path
                or app._ui_state.get("saved_world_save_path")
                or ""
            )
            state["saved_world_player_id"] = str(
                metadata.get("playerUUID")
                or selected_player_id
                or app._ui_state.get("saved_world_player_id")
                or ""
            )
            state["saved_world_npc_id"] = str(
                metadata.get("npcID")
                or selected_npc_id
                or app._ui_state.get("saved_world_npc_id")
                or ""
            )
        else:
            state["active_source_kind"] = "FIXTURE"
        state["saved_world_view"] = str(
            app.saved_world_view_var.get()
            if hasattr(app, "saved_world_view_var")
            else "Relationship to Player"
        )
        state["saved_world_relationship_category"] = str(
            app.saved_world_relationship_category_var.get()
            if hasattr(app, "saved_world_relationship_category_var")
            else "All relationship categories"
        )
        state["saved_world_lens_revision"] = 2
        state["saved_world_search"] = str(
            app.saved_world_search_var.get()
            if hasattr(app, "saved_world_search_var")
            else ""
        )
        state["saved_world_open_groups"] = [
            str(group.get("id") or "")
            for item, group in app.saved_world_tree_group_nodes.items()
            if hasattr(app, "saved_world_tree")
            and app.saved_world_tree.item(item, "open")
            and isinstance(group, dict)
            and group.get("id")
        ] if hasattr(app, "saved_world_tree") else []
        if hasattr(app, "saved_world_tree"):
            root_iid = getattr(
                app, "saved_world_tree_root_iid", "world-root"
            )
            state["saved_world_root_open"] = bool(
                app.saved_world_tree.exists(root_iid)
                and app.saved_world_tree.item(root_iid, "open")
            )
        if app.trace_panel_visible and app.simulation_panes.winfo_width() > 10:
            state["simulation_sash"] = app.simulation_panes.sashpos(0)
        if (
            len(app.workflow_pane_split.panes()) > 1
            and app.workflow_pane_split.winfo_width() > 10
        ):
            state["workflow_sash"] = app.workflow_pane_split.sashpos(0)
        if app.workbench_notebook.tabs():
            state["workbench_panel"] = app.workbench_notebook.index(
                app.workbench_notebook.select()
            )
        state["workbench_tabs"] = {
            panel_name: notebook.index(notebook.select())
            for panel_name, notebook in app.workbench_panel_notebooks.items()
            if notebook.tabs()
        }
        app._ui_state.update(state)
        persist_ui_state(app.ui_state_path, state)
    except (OSError, app._tk.TclError, TypeError, ValueError):
        app.activity_log.record(
            "ui", "state_save_error", message="could not save window state"
        )
