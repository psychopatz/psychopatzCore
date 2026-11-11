"""Compose the top-level notebooks and delegate each surface to its builder."""

from __future__ import annotations

from typing import Any

from .quality_sweep_builder import build_quality_sweep_workbench
from .saved_world_browser_builder import build_saved_world_browser
from .simulation_conversation_builder import build_conversation_panel
from .simulation_pane_builder import build_simulation_panes
from .simulation_controls_builder import build_workbench_controls
from .selection_surface import build_selection_surface
from .studio_surface_builder import build_studio_editors
from .trace_conversation_builder import build_conversation_trace
from .trace_diagnostic_builder import build_diagnostic_trace


def build_ui(app: Any) -> None:
    ttk = app._ttk
    scrolled_text = app._ScrolledText
    app.main_tabs = ttk.Notebook(app.root)
    app.main_tabs.pack(fill="both", expand=True, padx=6, pady=6)

    studio_tab = ttk.Frame(app.main_tabs, padding=6)
    simulation_tab = ttk.Frame(app.main_tabs, padding=8)
    studio_tab.rowconfigure(0, weight=0)
    studio_tab.rowconfigure(1, weight=1)
    studio_tab.rowconfigure(2, weight=0)
    studio_tab.columnconfigure(0, weight=1)
    simulation_tab.rowconfigure(0, weight=0)
    simulation_tab.rowconfigure(1, weight=1)
    simulation_tab.columnconfigure(0, weight=1)
    studio_notebook = ttk.Notebook(studio_tab)
    app.studio_notebook = studio_notebook
    studio_toolbar = ttk.Frame(studio_tab, padding=(0, 0, 0, 6))
    studio_toolbar.grid(row=0, column=0, sticky="ew")
    studio_toolbar.columnconfigure(0, weight=1)
    studio_notebook.grid(row=1, column=0, sticky="nsew")
    explore_tab = ttk.Frame(studio_notebook, padding=8)
    dialogue_content_tab = ttk.Frame(studio_notebook, padding=8)
    review_tab = ttk.Frame(studio_notebook, padding=8)
    for panel in (explore_tab, dialogue_content_tab, review_tab):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    studio_notebook.add(explore_tab, text="Explore")
    studio_notebook.add(dialogue_content_tab, text="Dialogue Content")
    studio_notebook.add(review_tab, text="Review")
    developer_tools_host = ttk.Frame(studio_tab, padding=(0, 6, 0, 0))
    developer_tools_host.grid(row=2, column=0, sticky="nsew")
    developer_tools_host.grid_remove()
    developer_tools_host.rowconfigure(0, weight=1)
    developer_tools_host.columnconfigure(0, weight=1)
    app.developer_tools_host = developer_tools_host
    app.developer_tools_button = ttk.Button(
        studio_toolbar,
        text="Developer Tools…",
        command=lambda: developer_tools_host.grid()
        if not developer_tools_host.winfo_ismapped()
        else developer_tools_host.grid_remove(),
    )
    app.developer_tools_button.grid(row=0, column=1, sticky="e")
    log_tab = ttk.Frame(app.main_tabs, padding=8)
    log_tab.rowconfigure(1, weight=1)
    log_tab.columnconfigure(0, weight=1)
    app.activity_log_status = app._tk.StringVar(
        value="Shared GUI/CLI activity timeline"
    )
    log_toolbar = ttk.Frame(log_tab)
    log_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    ttk.Label(
        log_toolbar,
        textvariable=app.activity_log_status,
        anchor="w",
    ).pack(side="left", fill="x", expand=True)
    ttk.Button(
        log_toolbar,
        text="Clear view",
        command=app.clear_activity_log,
    ).pack(side="right")
    app.activity_log_widget = scrolled_text(log_tab, wrap="none", state="disabled")
    app.activity_log_widget.grid(row=1, column=0, sticky="nsew")

    quality_sweep_tab = ttk.Frame(app.main_tabs, padding=8)
    quality_sweep_tab.rowconfigure(0, weight=1)
    quality_sweep_tab.columnconfigure(0, weight=1)
    world_sources_tab = ttk.Frame(app.main_tabs, padding=10)
    world_sources_tab.rowconfigure(0, weight=1)
    world_sources_tab.columnconfigure(0, weight=1)
    world_sources_notebook = ttk.Notebook(world_sources_tab)
    world_sources_notebook.grid(row=0, column=0, sticky="nsew")
    saved_world_tab = ttk.Frame(world_sources_notebook, padding=4)
    active_mods_tab = ttk.Frame(world_sources_notebook, padding=8)
    world_sources_notebook.add(saved_world_tab, text="Saved Worlds")
    world_sources_notebook.add(active_mods_tab, text="Active Mods")
    app.main_tabs.add(world_sources_tab, text="World Sources")
    app.main_tabs.add(simulation_tab, text="Simulation")
    app.main_tabs.add(quality_sweep_tab, text="Quality Sweep")
    app.main_tabs.add(studio_tab, text="Studio")
    app.main_tabs.add(log_tab, text="Log")
    app.quality_sweep_tab = quality_sweep_tab
    app.world_sources_tab = world_sources_tab
    app.world_sources_notebook = world_sources_notebook
    app.saved_world_tab = saved_world_tab
    app.active_mods_tab = active_mods_tab
    build_quality_sweep_workbench(app, quality_sweep_tab)
    app.studio_tab = studio_tab
    app.explore_tab = explore_tab
    app.review_tab = review_tab
    # Compatibility attribute: structural tools are hidden behind the
    # Developer Tools… launcher rather than exposed as a Studio peer.
    app.advanced_tab = developer_tools_host
    app.log_tab = log_tab
    app.world_browser_tab = world_sources_tab
    build_selection_surface(app, active_mods_tab, ttk, scrolled_text)
    build_saved_world_browser(app, saved_world_tab)

    conversation_pane, workbench_pane = build_simulation_panes(
        app, simulation_tab, ttk
    )
    build_conversation_panel(app, conversation_pane, ttk, scrolled_text)
    build_workbench_controls(app, workbench_pane, ttk)
    right = ttk.LabelFrame(app.simulation_panes, text="Semantic trace")
    right.rowconfigure(0, weight=1)
    right.columnconfigure(0, weight=1)
    right.configure(width=420)
    app.trace_pane = right
    app.simulation_panes.add(right, weight=2)
    app.workflow_pane_split.add(conversation_pane, weight=3)
    app.workflow_pane_split.add(workbench_pane, weight=2)
    build_conversation_trace(app, right, ttk, scrolled_text)
    build_diagnostic_trace(app, ttk, scrolled_text)
    build_studio_editors(
        app,
        explore_tab=explore_tab,
        dialogue_content_tab=dialogue_content_tab,
        review_tab=review_tab,
        developer_tools_parent=developer_tools_host,
        ttk=ttk,
        scrolled_text=scrolled_text,
    )
    app.simulation_tab = simulation_tab
    app.main_tabs.bind(
        "<<NotebookTabChanged>>",
        lambda _event: app._on_main_tab_changed(),
    )
    app._restore_ui_state()
    app._schedule_activity_poll()
    app._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
    app._set_controls(False)
