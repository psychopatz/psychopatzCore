"""Build the consolidated Inspect, World, and Debug Simulation homes."""

from __future__ import annotations

from typing import Any


def build_diagnostic_trace(app: Any, ttk: Any, scrolled_text: Any) -> None:
    """Nest existing projections under the five stable diagnostic homes."""

    # Inspect owns current-turn semantic understanding, command authority,
    # predicates, and provenance.  These are details of one inspection job,
    # not separate execution surfaces.
    inspect_frame = app.inspect_frame
    inspect_frame.rowconfigure(0, weight=1)
    inspect_frame.rowconfigure(1, weight=0)
    inspect_frame.columnconfigure(0, weight=1)
    app.inspect_tabs = ttk.Notebook(inspect_frame)
    app.inspect_tabs.grid(row=0, column=0, sticky="nsew")

    conversation_frame = ttk.Frame(app.inspect_tabs)
    conversation_frame.rowconfigure(0, weight=1)
    conversation_frame.columnconfigure(0, weight=1)
    app.inspector = scrolled_text(
        conversation_frame, wrap="word", state="disabled"
    )
    app.inspector.grid(row=0, column=0, sticky="nsew")
    app.inspect_tabs.add(conversation_frame, text="Understanding")
    app.conversation_inspection_frame = conversation_frame

    authority_frame = ttk.Frame(app.inspect_tabs)
    authority_frame.rowconfigure(0, weight=1)
    authority_frame.columnconfigure(0, weight=1)
    app.authority = scrolled_text(authority_frame, wrap="word", state="disabled")
    app.authority.grid(row=0, column=0, sticky="nsew")
    app.inspect_tabs.add(authority_frame, text="Authority / effects")
    app.authority_frame = authority_frame

    suggestion_trace_frame = ttk.Frame(app.inspect_tabs)
    suggestion_trace_frame.rowconfigure(0, weight=1)
    suggestion_trace_frame.columnconfigure(0, weight=1)
    app.suggestion_inspector = scrolled_text(
        suggestion_trace_frame, wrap="none", state="disabled"
    )
    app.suggestion_inspector.grid(row=0, column=0, sticky="nsew")
    app.inspect_tabs.add(suggestion_trace_frame, text="Predicates")
    app.suggestion_trace_frame = suggestion_trace_frame

    provenance_frame = ttk.Frame(app.inspect_tabs)
    provenance_frame.rowconfigure(0, weight=1)
    provenance_frame.columnconfigure(0, weight=1)
    app.provenance_inspector = scrolled_text(
        provenance_frame, wrap="none", state="disabled"
    )
    app.provenance_inspector.grid(row=0, column=0, sticky="nsew")
    app.inspect_tabs.add(provenance_frame, text="Provenance")
    app.provenance_frame = provenance_frame

    inspect_toolbar = ttk.Frame(inspect_frame)
    inspect_toolbar.grid(row=1, column=0, sticky="ew", pady=(6, 0))
    app.selection_explain_button = ttk.Button(
        inspect_toolbar,
        text="Why did this win?",
        command=app.explain_current_selection,
    )
    app.selection_explain_button.pack(side="left")
    app.selection_explain_status_var = app._tk.StringVar(
        value="Uses the production selector for the active Simulation turn."
    )
    ttk.Label(
        inspect_toolbar, textvariable=app.selection_explain_status_var
    ).pack(side="left", padx=(8, 0))

    # World is the single runtime world-knowledge inspection home.  Saved
    # target discovery remains in World Browser; this frame only reflects the
    # active Simulation context.
    world_knowledge_frame = ttk.Frame(app.trace_tabs)
    world_knowledge_frame.rowconfigure(1, weight=1)
    world_knowledge_frame.columnconfigure(0, weight=1)
    world_knowledge_toolbar = ttk.Frame(world_knowledge_frame)
    world_knowledge_toolbar.grid(
        row=0, column=0, sticky="ew", padx=6, pady=(6, 0)
    )
    app.world_knowledge_button = ttk.Button(
        world_knowledge_toolbar,
        text="Refresh world knowledge",
        command=app.inspect_world_knowledge,
    )
    app.world_knowledge_button.pack(side="left")
    app.world_knowledge_inspector = scrolled_text(
        world_knowledge_frame, wrap="none", state="disabled"
    )
    app.world_knowledge_inspector.grid(
        row=1, column=0, sticky="nsew", padx=6, pady=6
    )
    app.world_knowledge_frame = world_knowledge_frame
    app.trace_tabs.add(world_knowledge_frame, text="World")

    # Debug contains worker lifecycle and raw records.  It is deliberately
    # separate from Inspect so raw maintenance data cannot look like a second
    # semantic explanation implementation.
    debug_frame = ttk.Frame(app.trace_tabs, padding=4)
    debug_frame.rowconfigure(0, weight=1)
    debug_frame.columnconfigure(0, weight=1)
    app.debug_tabs = ttk.Notebook(debug_frame)
    app.debug_tabs.grid(row=0, column=0, sticky="nsew")
    diagnostics_frame = ttk.Frame(app.debug_tabs, padding=6)
    diagnostics_frame.columnconfigure(0, weight=1)
    ttk.Label(
        diagnostics_frame,
        text="Worker and maintenance diagnostics",
        font=("TkDefaultFont", 10, "bold"),
    ).grid(row=0, column=0, sticky="w")
    diagnostics_actions = ttk.Frame(diagnostics_frame)
    diagnostics_actions.grid(row=1, column=0, sticky="w", pady=(6, 6))
    app.snapshot_button = ttk.Button(
        diagnostics_actions, text="Snapshot", command=app.show_snapshot
    )
    app.snapshot_button.pack(side="left")
    app.restart_button = ttk.Button(
        diagnostics_actions, text="Restart worker", command=app.restart
    )
    app.restart_button.pack(side="left", padx=(6, 0))
    ttk.Label(
        diagnostics_frame,
        text="Raw worker records remain available in the Debug raw-record tab.",
    ).grid(row=2, column=0, sticky="w")
    app.debug_tabs.add(diagnostics_frame, text="Worker")
    app.diagnostics_frame = diagnostics_frame

    raw_frame = ttk.Frame(app.debug_tabs)
    raw_frame.rowconfigure(0, weight=1)
    raw_frame.columnconfigure(0, weight=1)
    app.trace = scrolled_text(raw_frame, wrap="none", state="disabled")
    app.trace.grid(row=0, column=0, sticky="nsew")
    app.debug_tabs.add(raw_frame, text="Raw worker record")
    app.raw_worker_frame = raw_frame
    app.debug_frame = debug_frame
    app.trace_tabs.add(debug_frame, text="Debug")


__all__ = ["build_diagnostic_trace"]
