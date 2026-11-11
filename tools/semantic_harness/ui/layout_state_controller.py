"""Restore and schedule the semantic harness window layout."""

from __future__ import annotations

from typing import Any


def restore_ui_state(app: Any) -> None:
    """Restore non-scenario UI state after the widget tree exists."""

    def restore() -> None:
        try:
            layout_version = int(app._ui_state.get("layout_state_version", 0))
            saved_window_state = app._ui_state.get("window_state")
            if saved_window_state in {"normal", "zoomed"}:
                app.root.state(saved_window_state)
            main_index = int(app._ui_state.get("main_tab", 0))
            tabs = app.main_tabs.tabs()
            if tabs:
                app.main_tabs.select(tabs[min(max(main_index, 0), len(tabs) - 1)])
            # Version 2 stored indices for the pre-consolidation Studio and
            # Simulation notebooks. Those indices could point at an unrelated
            # home after duplicate panes were removed, so old state starts at
            # the new first home and is migrated on save.
            studio_index = (
                int(app._ui_state.get("studio_tab", 0))
                if layout_version >= 4 else 0
            )
            studio_tabs = app.studio_notebook.tabs()
            if studio_tabs:
                app.studio_notebook.select(
                    studio_tabs[min(max(studio_index, 0), len(studio_tabs) - 1)]
                )
            trace_index = (
                int(app._ui_state.get("trace_tab", 0))
                if layout_version >= 3 else 0
            )
            trace_tabs = app.trace_tabs.tabs()
            if trace_tabs:
                app.trace_tabs.select(
                    trace_tabs[min(max(trace_index, 0), len(trace_tabs) - 1)]
                )
            nested_notebooks = (
                ("studio_explore_tab", getattr(app, "studio_explore_notebook", None)),
                ("advanced_tab", getattr(app, "advanced_notebook", None)),
                ("inspect_tab", getattr(app, "inspect_tabs", None)),
                ("graph_tab", getattr(app, "graph_tabs", None)),
                ("graph_detail_tab", getattr(app, "graph_detail_tabs", None)),
                ("compare_tab", getattr(app, "compare_tabs", None)),
                ("debug_tab", getattr(app, "debug_tabs", None)),
            )
            if layout_version >= 4:
                for key, notebook in nested_notebooks:
                    tabs = notebook.tabs() if notebook is not None else ()
                    if not tabs:
                        continue
                    try:
                        index = int(app._ui_state.get(key, 0))
                    except (TypeError, ValueError):
                        index = 0
                    notebook.select(tabs[min(max(index, 0), len(tabs) - 1)])
                if app._ui_state.get("developer_tools_visible"):
                    developer_tools = getattr(app, "developer_tools_host", None)
                    if developer_tools is not None:
                        developer_tools.grid()
            app._restore_splitters()
            workbench_tabs = app.workbench_notebook.tabs()
            if workbench_tabs:
                workbench_index = int(app._ui_state.get("workbench_panel", 0))
                app.workbench_notebook.select(
                    workbench_tabs[
                        min(max(workbench_index, 0), len(workbench_tabs) - 1)
                    ]
                )
            app._restore_workbench_tabs()
            app._restore_panel_state()
        except (app._tk.TclError, TypeError, ValueError):
            pass

    app._layout_restore_after = app.root.after_idle(restore)


def restore_panel_state(app: Any) -> None:
    """Restore visibility choices without restoring scenario contents."""

    saved_trace = app._ui_state.get("trace_panel_visible")
    if isinstance(saved_trace, bool) and saved_trace != app.trace_panel_visible:
        app._toggle_trace_panel()
    saved_advanced = app._ui_state.get("advanced_controls_visible")
    if (
        isinstance(saved_advanced, bool)
        and saved_advanced != app.advanced_controls_visible
    ):
        app._toggle_advanced_controls()
    saved_workbench = app._ui_state.get("workbench_expanded")
    if isinstance(saved_workbench, bool) and saved_workbench != app.workbench_expanded:
        app.toggle_simulation_workbench()


def restore_splitters(app: Any) -> None:
    if app.closed or app.main_tabs.select() != str(app.simulation_tab):
        return
    # Ignore absolute sash values written by the pre-dock topology. They can
    # otherwise shrink the conversation pane on the first launch after the
    # layout migration; the corrected defaults are persisted on the next save.
    sashes_compatible = app._ui_state.get("layout_state_version") in {2, 3, 4}
    if not app.trace_panel_visible:
        workflow_width = max(1, app.workflow_pane_split.winfo_width())
        if workflow_width <= 10:
            app._schedule_splitter_restore(100)
            return
    else:
        simulation_width = max(1, app.simulation_panes.winfo_width())
        if simulation_width <= 10:
            app._schedule_splitter_restore(100)
            return
        simulation_value = (
            app._ui_state.get("simulation_sash") if sashes_compatible else None
        )
        if simulation_value is None:
            simulation_value = min(
                max(620, int(simulation_width * 0.60)),
                max(420, simulation_width - 420),
            )
        else:
            simulation_value = min(
                max(620, int(simulation_value)),
                max(620, simulation_width - 420),
            )
        try:
            app.simulation_panes.sashpos(0, int(simulation_value))
            # The outer sash changes the width available to the conversation
            # split. Let Tk settle that geometry before restoring the inner
            # conversation/context sash, otherwise the outer resize can
            # proportionally overwrite the user's inner position.
            app.root.update_idletasks()
        except (app._tk.TclError, TypeError, ValueError):
            pass

        workflow_width = max(1, app.workflow_pane_split.winfo_width())
        if workflow_width <= 10:
            app._schedule_splitter_restore(100)
            return
    # Preserve user-saved sash values across the topology migration. The
    # default proportion gives Conversation the large pane; a user may still
    # intentionally choose a narrower context dock.
    # Keep enough width for the conversation pane even when a sash saved on a
    # larger desktop is restored at the 1080px acceptance-test floor. The
    # context dock remains usable at 180px and its notebook pages can scroll.
    context_minimum = 180 if workflow_width < 900 else 320
    if not app.trace_panel_visible and app.save_backed_mode:
        # Keep the primary Conversation/Response Channel readable at the
        # supported 1080px window floor even when an older persisted sash is
        # narrower. Larger windows still retain the user's proportional sash.
        workflow_minimum = min(740, max(420, workflow_width - context_minimum))
    else:
        # Diagnostics/fixture layouts retain the established minimum so saved
        # splitter parity remains stable across the two-pane topology.
        workflow_minimum = min(420, max(280, workflow_width - 180))
    workflow_maximum = max(
        workflow_minimum,
        workflow_width - context_minimum,
    )
    workflow_value = (
        app._ui_state.get("workflow_sash") if sashes_compatible else None
    )
    if workflow_value is None:
        workflow_value = min(
            max(workflow_minimum, int(workflow_width * 0.68)),
            workflow_maximum,
        )
    else:
        workflow_value = min(
            max(workflow_minimum, int(workflow_value)),
            workflow_maximum,
        )
    try:
        app.workflow_pane_split.sashpos(0, int(workflow_value))
    except (app._tk.TclError, TypeError, ValueError):
        pass


def schedule_splitter_restore(app: Any, delay_ms: int = 250) -> None:
    if app.closed:
        return
    if app._splitter_restore_after is not None:
        try:
            app.root.after_cancel(app._splitter_restore_after)
        except app._tk.TclError:
            pass
    app._splitter_restore_after = app.root.after(
        delay_ms, app._restore_splitters
    )


def on_main_tab_changed(app: Any) -> None:
    if app.closed or app.main_tabs.select() != str(app.simulation_tab):
        return
    app._schedule_splitter_restore()


def restore_workbench_tabs(app: Any) -> None:
    selections = app._ui_state.get("workbench_tabs") or {}
    if not isinstance(selections, dict):
        return
    for panel_name, notebook in app.workbench_panel_notebooks.items():
        selected = selections.get(panel_name)
        tabs = notebook.tabs()
        if selected is None or not tabs:
            continue
        try:
            notebook.select(tabs[min(max(int(selected), 0), len(tabs) - 1)])
        except (TypeError, ValueError, app._tk.TclError):
            continue


def reset_ui_state(app: Any) -> None:
    """Reset layout preferences without changing the working scenario."""

    app._ui_state = {}
    try:
        app.root.state("normal")
        screen_width = app.root.winfo_screenwidth()
        screen_height = app.root.winfo_screenheight()
        width = min(1320, max(1080, screen_width - 48))
        height = min(860, max(700, screen_height - 96))
        app.root.geometry(f"{width}x{height}")
        app.main_tabs.select(app.simulation_tab)
        app.studio_notebook.select(app.studio_notebook.tabs()[0])
        app.trace_tabs.select(app.trace_tabs.tabs()[0])
        for notebook in (
            getattr(app, "studio_explore_notebook", None),
            getattr(app, "advanced_notebook", None),
            getattr(app, "inspect_tabs", None),
            getattr(app, "graph_tabs", None),
            getattr(app, "graph_detail_tabs", None),
            getattr(app, "compare_tabs", None),
            getattr(app, "debug_tabs", None),
        ):
            if notebook is not None and notebook.tabs():
                notebook.select(notebook.tabs()[0])
        if app.workbench_notebook.tabs():
            app.workbench_notebook.select(app.workbench_notebook.tabs()[0])
        for notebook in app.workbench_panel_notebooks.values():
            if notebook.tabs():
                notebook.select(notebook.tabs()[0])
        if not app.trace_panel_visible:
            app._toggle_trace_panel()
        if not app.advanced_controls_visible:
            app._toggle_advanced_controls()
        if not app.workbench_expanded:
            app.toggle_simulation_workbench()
        # Resetting the persisted state must also reset the live sashes before
        # saving again. Otherwise save_ui_state immediately captures the
        # user's broken splitter positions and makes Reset appear ineffective
        # on the next startup.
        app.root.update_idletasks()
        app._restore_splitters()
        app.root.update_idletasks()
        app.talk_utterance_var.set("hello")
        if "current" in app.talk_target_ids_by_label.values():
            app.talk_target_var.set(
                next(
                    label
                    for label, target_id in app.talk_target_ids_by_label.items()
                    if target_id == "current"
                )
            )
        if hasattr(app, "saved_world_search_var"):
            app.saved_world_search_var.set("")
        app._save_ui_state()
        app._set_status("Ready · UI layout reset")
        app._append(
            "SYSTEM",
            "UI layout reset. Working scenario and imported save were unchanged.",
        )
    except (app._tk.TclError, TypeError, ValueError, IndexError):
        app.activity_log.record(
            "ui", "state_reset_error", message="could not reset window state"
        )


def toggle_simulation_workbench(app: Any) -> None:
    app.workbench_expanded = not app.workbench_expanded
    if app.workbench_expanded:
        panes = app.workflow_pane_split.panes()
        if str(app.context_dock_pane) not in panes:
            app.workflow_pane_split.add(app.context_dock_pane, weight=2)
        app.workbench_content.grid()
        app.workbench_toggle_button.configure(text="Hide controls")
    else:
        if str(app.context_dock_pane) in app.workflow_pane_split.panes():
            app.workflow_pane_split.forget(app.context_dock_pane)
        app.workbench_content.grid_remove()
        app.workbench_toggle_button.configure(text="Show controls")
    app._schedule_splitter_restore(0)


def toggle_trace_panel(app: Any) -> None:
    """Show diagnostics on demand so the normal conversation gets the width."""

    # The outer topology changes when diagnostics is added/removed. Absolute
    # sash positions captured in the other topology are not reusable and can
    # collapse the conversation pane after a reset or restart.
    app._ui_state.pop("simulation_sash", None)
    app._ui_state.pop("workflow_sash", None)
    if app.trace_panel_visible:
        app.simulation_panes.forget(app.trace_pane)
        app.simulation_panes.pane(app.simulation_workflow_pane, weight=1)
        app.trace_panel_visible = False
        app.diagnostics_toggle_button.configure(text="Show diagnostics")
    else:
        app.simulation_panes.add(app.trace_pane, weight=2)
        app.simulation_panes.pane(app.simulation_workflow_pane, weight=3)
        app.trace_panel_visible = True
        app.diagnostics_toggle_button.configure(text="Hide diagnostics")
        app._schedule_splitter_restore()


def toggle_advanced_controls(app: Any) -> None:
    """Collapse low-frequency reset/fixture/replay controls."""

    if app.advanced_controls_visible:
        app.advanced_controls.grid_remove()
        app.workbench_footer.grid_remove()
        app.advanced_controls_visible = False
        app.advanced_toggle_button.configure(text="Show advanced")
    else:
        app.advanced_controls.grid()
        app.workbench_footer.grid()
        app.advanced_controls_visible = True
        app.advanced_toggle_button.configure(text="Hide advanced")
