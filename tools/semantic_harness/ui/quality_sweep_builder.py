"""Build the user-facing dialogue sentence review workbench."""

from __future__ import annotations

from typing import Any

from .quality_sweep_controller import (
    init_quality_sweep_state,
    on_qs_apply_filter,
    on_qs_cancel,
    on_qs_clear_filter,
    on_qs_copy_evidence,
    on_qs_evidence_select,
    on_qs_export_bundle,
    on_qs_generate_sentences,
    on_qs_open_full_inspector,
    on_qs_reachability_scan,
    on_qs_refresh,
    on_qs_toggle_advanced,
)


def build_quality_sweep_workbench(app: Any, parent: Any) -> None:
    """Build a sentence-first Quality Sweep workspace.

    Coverage mechanics remain available under Advanced, but the primary task is
    deliberately simple: generate dialogue examples, scan the rendered
    sentences, filter suspicious lines, and inspect the context that produced
    them.
    """
    ttk = app._ttk
    scrolled_text = app._ScrolledText

    init_quality_sweep_state(app)

    parent.rowconfigure(2, weight=1)
    parent.columnconfigure(0, weight=1)

    intro = ttk.LabelFrame(parent, text="Dialogue Sentence Review", padding=8)
    intro.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    intro.columnconfigure(5, weight=1)

    ttk.Label(
        intro,
        text=(
            "Generate real NPC dialogue across different triggers and contexts, "
            "then scan the sentences below for awkward, robotic, repetitive, or incorrect lines."
        ),
        anchor="w",
    ).grid(row=0, column=0, columnspan=8, sticky="ew", pady=(0, 6))

    app.qs_generate_button = ttk.Button(
        intro,
        text="Generate Sentences",
        command=lambda: on_qs_generate_sentences(app),
    )
    app.qs_generate_button.grid(row=1, column=0, sticky="w", padx=(0, 6))

    app.qs_cancel_button = ttk.Button(
        intro,
        text="Stop",
        command=lambda: on_qs_cancel(app),
        state="disabled",
    )
    app.qs_cancel_button.grid(row=1, column=1, sticky="w", padx=(0, 10))

    ttk.Label(intro, text="Languages:").grid(row=1, column=2, sticky="w")
    ttk.Entry(
        intro,
        textvariable=app.quality_sweep_languages_var,
        width=8,
    ).grid(row=1, column=3, sticky="w", padx=(4, 10))

    ttk.Label(intro, text="Max examples:").grid(row=1, column=4, sticky="w")
    ttk.Entry(
        intro,
        textvariable=app.quality_sweep_max_cases_var,
        width=6,
    ).grid(row=1, column=5, sticky="w", padx=(4, 10))

    ttk.Button(
        intro,
        text="Reload Results",
        command=lambda: on_qs_refresh(app),
    ).grid(row=1, column=6, sticky="e", padx=(0, 6))

    ttk.Button(
        intro,
        text="Advanced…",
        command=lambda: on_qs_toggle_advanced(app),
    ).grid(row=1, column=7, sticky="e")

    ttk.Label(
        intro,
        textvariable=app.quality_sweep_status_var,
        anchor="w",
    ).grid(row=2, column=0, columnspan=8, sticky="ew", pady=(6, 2))

    app.qs_progressbar = ttk.Progressbar(
        intro,
        variable=app.quality_sweep_progress_var,
        maximum=100.0,
        mode="determinate",
    )
    app.qs_progressbar.grid(row=3, column=0, columnspan=8, sticky="ew")

    filters = ttk.LabelFrame(parent, text="Find awkward dialogue", padding=6)
    filters.grid(row=1, column=0, sticky="ew", pady=(0, 6))
    filters.columnconfigure(7, weight=1)

    ttk.Label(filters, text="Search:").grid(row=0, column=0, sticky="w")
    ttk.Entry(
        filters,
        textvariable=app.qs_filter_text_var,
        width=28,
    ).grid(row=0, column=1, sticky="w", padx=(4, 10))

    ttk.Checkbutton(
        filters,
        text="Only suspicious / flagged lines",
        variable=app.qs_filter_flagged_only_var,
        command=lambda: on_qs_apply_filter(app),
    ).grid(row=0, column=2, sticky="w", padx=(0, 10))

    ttk.Checkbutton(
        filters,
        text="Only duplicates / repeated lines",
        variable=app.qs_filter_duplicate_only_var,
        command=lambda: on_qs_apply_filter(app),
    ).grid(row=0, column=3, sticky="w", padx=(0, 10))

    ttk.Label(filters, text="Language:").grid(row=0, column=4, sticky="w")
    ttk.Combobox(
        filters,
        textvariable=app.qs_filter_lang_var,
        values=["ALL", "EN", "TL"],
        state="readonly",
        width=6,
    ).grid(row=0, column=5, sticky="w", padx=(4, 10))

    ttk.Button(
        filters,
        text="Apply",
        command=lambda: on_qs_apply_filter(app),
    ).grid(row=0, column=6, sticky="w", padx=(0, 4))

    ttk.Button(
        filters,
        text="Clear",
        command=lambda: on_qs_clear_filter(app),
    ).grid(row=0, column=7, sticky="w")

    ttk.Label(
        filters,
        textvariable=app.qs_filter_count_var,
        anchor="e",
    ).grid(row=0, column=8, sticky="e")

    panes = ttk.PanedWindow(parent, orient="horizontal")
    panes.grid(row=2, column=0, sticky="nsew")

    list_frame = ttk.LabelFrame(panes, text="Generated NPC Sentences", padding=4)
    list_frame.rowconfigure(0, weight=1)
    list_frame.columnconfigure(0, weight=1)

    detail_frame = ttk.LabelFrame(panes, text="Why this sentence happened", padding=6)
    detail_frame.rowconfigure(1, weight=1)
    detail_frame.columnconfigure(0, weight=1)

    panes.add(list_frame, weight=4)
    panes.add(detail_frame, weight=2)

    cols = ("sentence", "trigger", "context", "lang", "problem", "source")
    app.qs_evidence_tree = ttk.Treeview(
        list_frame,
        columns=cols,
        show="headings",
        height=24,
    )
    headings = {
        "sentence": "NPC Sentence",
        "trigger": "Trigger",
        "context": "Context",
        "lang": "Lang",
        "problem": "Quality / Problem",
        "source": "Source",
    }
    widths = {
        "sentence": 360,
        "trigger": 180,
        "context": 260,
        "lang": 48,
        "problem": 190,
        "source": 160,
    }
    for key in cols:
        app.qs_evidence_tree.heading(key, text=headings[key])
        app.qs_evidence_tree.column(key, width=widths[key], anchor="w")
    app.qs_evidence_tree.column("lang", anchor="center")

    yscroll = ttk.Scrollbar(
        list_frame,
        orient="vertical",
        command=app.qs_evidence_tree.yview,
    )
    xscroll = ttk.Scrollbar(
        list_frame,
        orient="horizontal",
        command=app.qs_evidence_tree.xview,
    )
    app.qs_evidence_tree.configure(
        yscrollcommand=yscroll.set,
        xscrollcommand=xscroll.set,
    )
    app.qs_evidence_tree.grid(row=0, column=0, sticky="nsew")
    yscroll.grid(row=0, column=1, sticky="ns")
    xscroll.grid(row=1, column=0, sticky="ew")
    app.qs_evidence_tree.bind(
        "<<TreeviewSelect>>",
        lambda _e: on_qs_evidence_select(app),
    )

    actions = ttk.Frame(detail_frame)
    actions.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    ttk.Button(
        actions,
        text="Open Full Inspector",
        command=lambda: on_qs_open_full_inspector(app),
    ).pack(side="left", padx=(0, 4))
    ttk.Button(
        actions,
        text="Copy Evidence",
        command=lambda: on_qs_copy_evidence(app),
    ).pack(side="left")

    app.qs_inspector_text = scrolled_text(
        detail_frame,
        wrap="word",
        state="disabled",
        height=24,
    )
    app.qs_inspector_text.grid(row=1, column=0, sticky="nsew")

    # Developer/testing internals are intentionally hidden by default.
    app.qs_advanced_frame = ttk.LabelFrame(
        parent,
        text="Advanced coverage / debugging",
        padding=6,
    )
    app.qs_advanced_frame.columnconfigure(9, weight=1)

    ttk.Label(app.qs_advanced_frame, text="Coverage mode:").grid(
        row=0, column=0, sticky="w"
    )
    ttk.Combobox(
        app.qs_advanced_frame,
        textvariable=app.quality_sweep_strategy_var,
        values=["review", "smoke", "boundary", "pairwise", "persona", "full"],
        state="readonly",
        width=10,
    ).grid(row=0, column=1, sticky="w", padx=(4, 10))

    ttk.Label(app.qs_advanced_frame, text="Sweep ID:").grid(
        row=0, column=2, sticky="w"
    )
    ttk.Entry(
        app.qs_advanced_frame,
        textvariable=app.quality_sweep_id_var,
        width=22,
    ).grid(row=0, column=3, sticky="w", padx=(4, 10))

    ttk.Label(app.qs_advanced_frame, text="Batch size:").grid(
        row=0, column=4, sticky="w"
    )
    ttk.Entry(
        app.qs_advanced_frame,
        textvariable=app.quality_sweep_batch_size_var,
        width=5,
    ).grid(row=0, column=5, sticky="w", padx=(4, 10))

    ttk.Button(
        app.qs_advanced_frame,
        text="Analyze Variant Reachability",
        command=lambda: on_qs_reachability_scan(app),
    ).grid(row=0, column=6, sticky="w", padx=(0, 6))

    ttk.Button(
        app.qs_advanced_frame,
        text="Export Review Bundle",
        command=lambda: on_qs_export_bundle(app),
    ).grid(row=0, column=7, sticky="w")

    app.qs_advanced_summary_var = app._tk.StringVar(
        value="Advanced data is optional; sentence generation does not require it."
    )
    ttk.Label(
        app.qs_advanced_frame,
        textvariable=app.qs_advanced_summary_var,
        anchor="w",
    ).grid(row=1, column=0, columnspan=10, sticky="ew", pady=(6, 0))
