"""Compose the top-level notebooks and delegate each surface to its builder."""

from __future__ import annotations

from typing import Any

from .convo_flows_tab_builder import build_convo_flows_tab
from .quality_sweep_builder import build_quality_sweep_workbench
from .saved_world_browser_builder import build_saved_world_browser
from .simulation_conversation_builder import build_conversation_panel
from .simulation_pane_builder import build_simulation_panes
from .simulation_controls_builder import build_workbench_controls
from .selection_surface import build_selection_surface
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
    conversations_tab = ttk.Frame(studio_notebook, padding=8)
    convo_flows_tab = ttk.Frame(studio_notebook, padding=8)
    source_impact_tab = ttk.Frame(studio_notebook, padding=8)
    review_tab = ttk.Frame(studio_notebook, padding=8)
    for panel in (
        conversations_tab,
        convo_flows_tab,
        source_impact_tab,
        review_tab,
    ):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    studio_notebook.add(conversations_tab, text="Conversations")
    studio_notebook.add(convo_flows_tab, text="Convo Flows")
    studio_notebook.add(source_impact_tab, text="Source / Impact")
    studio_notebook.add(review_tab, text="Review")
    app.convo_engine_tab = conversations_tab
    app.convo_flows_tab = convo_flows_tab
    app.source_impact_tab = source_impact_tab
    build_convo_flows_tab(app, convo_flows_tab)

    from ..studio.surface_registry import SurfaceRegistry

    app.surface_registry = SurfaceRegistry()
    app.visible_studio_surfaces = lambda: app.surface_registry.list_surfaces(
        include_legacy=False,
        dataset_sources=(
            app.authoring_service.list_dataset_sources()
            if hasattr(app, "authoring_service")
            and hasattr(app.authoring_service, "list_dataset_sources")
            else ()
        ),
    )
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
    world_sources_notebook.add(active_mods_tab, text="Mod Composition")
    app.main_tabs.add(world_sources_tab, text="World & Mods")
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
    app.review_tab = review_tab
    # Compatibility attribute: structural tools are hidden behind the
    # Developer Tools… launcher rather than exposed as a Studio peer.
    app.advanced_tab = developer_tools_host
    app.log_tab = log_tab
    app.world_browser_tab = world_sources_tab
    build_saved_world_browser(app, saved_world_tab)
    # Selection initialization can restore the "Selected save" mode and
    # immediately resolve the active saved-world entry. Build the saved-world
    # variables and controls before that callback is allowed to run.
    build_selection_surface(app, active_mods_tab, ttk, scrolled_text)

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
    app.simulation_tab = simulation_tab
    app.main_tabs.bind(
        "<<NotebookTabChanged>>",
        lambda _event: app._on_main_tab_changed(),
    )
    app._restore_ui_state()
    app._schedule_activity_poll()
    app._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
    # Studio owns the heaviest Tk construction (editor canvases, source
    # browsers, and authoring panes). Build it in the mapped window's next
    # event-loop turn so the core Simulation/World surfaces become usable
    # immediately. Worker startup is chained after this deferred phase.
    app._studio_editor_kwargs = {
        "conversations_tab": conversations_tab,
        "source_impact_tab": source_impact_tab,
        "review_tab": review_tab,
        "developer_tools_parent": developer_tools_host,
        "ttk": ttk,
        "scrolled_text": scrolled_text,
    }
    app._studio_editors_ready = False
