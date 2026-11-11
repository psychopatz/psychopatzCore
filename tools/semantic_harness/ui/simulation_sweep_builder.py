"""Build the Simulation Quality Sweep workbench panel."""

from __future__ import annotations

from typing import Any

from .simulation_sweep_controller import (
    on_sweep_cancel,
    on_sweep_cluster_select,
    on_sweep_plan,
    on_sweep_refresh,
    on_sweep_replay,
    on_sweep_run,
)


def build_simulation_sweep_panel(app: Any, ttk: Any, scrolled_text: Any) -> None:
    """Build the Quality Sweep tab inside Simulation's trace_tabs."""
    app.sweep_frame = ttk.Frame(app.trace_tabs, padding=4)
    app.sweep_frame.rowconfigure(2, weight=1)
    app.sweep_frame.rowconfigure(4, weight=1)
    app.sweep_frame.columnconfigure(0, weight=1)

    # State variables
    app.sweep_strategy_var = app._tk.StringVar(value="smoke")
    app.sweep_id_var = app._tk.StringVar(value="dialogue_sweep_v1")
    app.sweep_status_var = app._tk.StringVar(value="Status: Ready")
    app.sweep_estimate_var = app._tk.StringVar(value="Plan: No plan generated yet")
    app.sweep_report_summary_var = app._tk.StringVar(value="Clusters: None loaded")
    app.sweep_progress_var = app._tk.DoubleVar(value=0.0)
    app.sweep_cancel_requested = False
    app.current_sweep_plan = None
    app.current_sweep_manifest = None
    app.current_cluster_report = None
    app.selected_sweep_cluster = None

    def refresh_feedback(msg: str) -> None:
        if hasattr(app, "activity_log") and app.activity_log:
            app.activity_log.record("sweep_ui", "status", message=msg)

    app._refresh_sweep_feedback = refresh_feedback

    # Top Control Frame: Strategy, ID, Plan & Run buttons
    top_frame = ttk.LabelFrame(app.sweep_frame, text="Sweep Configuration & Control", padding=6)
    top_frame.grid(row=0, column=0, sticky="ew", pady=(0, 4))
    top_frame.columnconfigure(5, weight=1)

    ttk.Label(top_frame, text="Strategy:").grid(row=0, column=0, sticky="w", padx=(0, 4))
    strategy_combo = ttk.Combobox(
        top_frame,
        textvariable=app.sweep_strategy_var,
        values=["smoke", "boundary", "pairwise", "persona", "full"],
        width=10,
        state="readonly",
    )
    strategy_combo.grid(row=0, column=1, sticky="w", padx=(0, 8))

    ttk.Label(top_frame, text="Sweep ID:").grid(row=0, column=2, sticky="w", padx=(0, 4))
    id_entry = ttk.Entry(top_frame, textvariable=app.sweep_id_var, width=16)
    id_entry.grid(row=0, column=3, sticky="w", padx=(0, 8))

    app.sweep_plan_button = ttk.Button(
        top_frame, text="Plan", command=lambda: on_sweep_plan(app)
    )
    app.sweep_plan_button.grid(row=0, column=4, sticky="w", padx=(0, 4))

    app.sweep_run_button = ttk.Button(
        top_frame, text="Run / Resume", command=lambda: on_sweep_run(app)
    )
    app.sweep_run_button.grid(row=0, column=5, sticky="w", padx=(0, 4))

    app.sweep_cancel_button = ttk.Button(
        top_frame, text="Cancel", command=lambda: on_sweep_cancel(app)
    )
    app.sweep_cancel_button.grid(row=0, column=6, sticky="w", padx=(0, 4))

    app.sweep_open_workbench_button = ttk.Button(
        top_frame,
        text="Open Quality Sweep Workbench…",
        command=lambda: app.main_tabs.select(app.quality_sweep_tab) if hasattr(app, "quality_sweep_tab") else None,
    )
    app.sweep_open_workbench_button.grid(row=0, column=7, sticky="e", padx=(8, 0))

    # Status & Progress Frame
    status_frame = ttk.Frame(app.sweep_frame, padding=(2, 2))
    status_frame.grid(row=1, column=0, sticky="ew", pady=(0, 4))
    status_frame.columnconfigure(0, weight=1)

    ttk.Label(status_frame, textvariable=app.sweep_estimate_var, anchor="w").grid(
        row=0, column=0, sticky="w"
    )
    ttk.Label(status_frame, textvariable=app.sweep_status_var, anchor="w").grid(
        row=1, column=0, sticky="w"
    )
    app.sweep_progressbar = ttk.Progressbar(
        status_frame,
        variable=app.sweep_progress_var,
        maximum=100.0,
        mode="determinate",
    )
    app.sweep_progressbar.grid(row=2, column=0, sticky="ew", pady=(2, 0))

    # Middle Frame: Cluster Treeview
    clusters_frame = ttk.LabelFrame(app.sweep_frame, text="Defect Clusters", padding=4)
    clusters_frame.grid(row=2, column=0, sticky="nsew", pady=(0, 4))
    clusters_frame.rowconfigure(1, weight=1)
    clusters_frame.columnconfigure(0, weight=1)

    cluster_bar = ttk.Frame(clusters_frame)
    cluster_bar.grid(row=0, column=0, sticky="ew", pady=(0, 2))
    cluster_bar.columnconfigure(0, weight=1)

    ttk.Label(cluster_bar, textvariable=app.sweep_report_summary_var, anchor="w").grid(
        row=0, column=0, sticky="w"
    )
    ttk.Button(
        cluster_bar, text="Refresh", command=lambda: on_sweep_refresh(app)
    ).grid(row=0, column=1, sticky="e", padx=(4, 0))
    ttk.Button(
        cluster_bar, text="Replay Cluster", command=lambda: on_sweep_replay(app)
    ).grid(row=0, column=2, sticky="e", padx=(4, 0))

    tree_cols = ("severity", "flag", "count", "source", "cluster_id")
    app.sweep_cluster_tree = ttk.Treeview(
        clusters_frame, columns=tree_cols, show="headings", height=6
    )
    app.sweep_cluster_tree.heading("severity", text="Severity")
    app.sweep_cluster_tree.heading("flag", text="Flag")
    app.sweep_cluster_tree.heading("count", text="Count")
    app.sweep_cluster_tree.heading("source", text="Canonical Source")
    app.sweep_cluster_tree.heading("cluster_id", text="Cluster ID")

    app.sweep_cluster_tree.column("severity", width=80, anchor="center")
    app.sweep_cluster_tree.column("flag", width=220)
    app.sweep_cluster_tree.column("count", width=60, anchor="center")
    app.sweep_cluster_tree.column("source", width=160)
    app.sweep_cluster_tree.column("cluster_id", width=180)

    app.sweep_cluster_tree.grid(row=1, column=0, sticky="nsew")
    app.sweep_cluster_tree.bind(
        "<<TreeviewSelect>>", lambda _e: on_sweep_cluster_select(app)
    )

    # Bottom Frame: Cluster Details and Representative Examples
    details_frame = ttk.LabelFrame(app.sweep_frame, text="Evidence & Review Details", padding=4)
    details_frame.grid(row=3, column=0, sticky="nsew")
    details_frame.rowconfigure(0, weight=1)
    details_frame.columnconfigure(0, weight=1)

    app.sweep_details_text = scrolled_text(
        details_frame, wrap="word", state="disabled", height=8
    )
    app.sweep_details_text.grid(row=0, column=0, sticky="nsew")

    # Add to Simulation's trace_tabs
    app.trace_tabs.add(app.sweep_frame, text="Quality Sweep")
