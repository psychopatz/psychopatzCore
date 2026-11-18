"""R9B/R9C: Primary Dialogue Completeness Workbench for Semantic Lab.

Renders the compiler-owned report from ``SemanticLabAuthoringService.analyze_convo_completeness()``
without duplicating any graph/completeness reasoning in Tk.
"""

from __future__ import annotations

import json
from typing import Any, Callable, Iterable

from tools.semantic_harness.codebuilder.completeness_scaffold import suggest_scaffold_kind


SEVERITY_ORDER: dict[str, int] = {
    "RED": 0,
    "ORANGE": 1,
    "YELLOW": 2,
    "BLUE": 3,
    "PURPLE": 4,
    "GREEN": 5,
}

SEMANTIC_STATUS_LABELS: dict[str, str] = {
    "RED": "! Broken / Must Fix",
    "ORANGE": "! Warning / Risky",
    "YELLOW": "? Pending / Review",
    "BLUE": "-> Continuation",
    "PURPLE": "* Domain Obligation",
    "GREEN": "OK Healthy",
}

SEMANTIC_TAG_STYLES: dict[str, dict[str, str]] = {
    "RED": {"background": "#fde2e1", "foreground": "#991b1b"},
    "ORANGE": {"background": "#ffedd5", "foreground": "#9a3412"},
    "YELLOW": {"background": "#fef9c3", "foreground": "#854d0e"},
    "BLUE": {"background": "#dbeafe", "foreground": "#1e40af"},
    "PURPLE": {"background": "#f3e8ff", "foreground": "#6b21a8"},
    "GREEN": {"background": "#dcfce7", "foreground": "#166534"},
}

ISSUE_FILTERS: tuple[str, ...] = (
    "needs_attention",
    "all",
    "errors_only",
    "warnings_only",
    "pending_review",
    "continuations",
    "healthy_only",
    "missing_coverage",
    "recently_changed_affected",
)

ADVANCED_ISSUE_FILTERS: tuple[str, ...] = (
    "none",
    "missing_closure",
    "unhandled_state_outcome",
    "unhandled_action_outcome",
    "pending_without_exit",
    "unbounded_cycle",
    "missing_repeat_policy",
    "typed_click_parity_gap",
)

TREE_COLUMNS: tuple[str, ...] = (
    "health",
    "family",
    "owner",
    "type",
    "branches",
    "issues",
    "closure",
    "tests",
)

TREE_HEADINGS: dict[str, str] = {
    "health": "Health",
    "family": "Family",
    "owner": "Owner",
    "type": "Type",
    "branches": "Branches / Coverage",
    "issues": "Issues",
    "closure": "Closure / Health",
    "tests": "Tests",
}


def _row_needs_attention(row: dict[str, Any]) -> bool:
    return (
        int(row.get("errorCount", 0)) > 0
        or int(row.get("warningCount", 0)) > 0
        or row.get("fixtureCoverage") == "uncovered"
        or row.get("closureHealth") == "invalid"
    )


def sort_completeness_rows(
    rows: list[dict[str, Any]],
    *,
    sort_by: str = "severity",
    descending: bool = False,
) -> list[dict[str, Any]]:
    """Sort completeness rows deterministically; default is severity-first then family ID."""
    def _key(row: dict[str, Any]) -> tuple[Any, ...]:
        fid = str(row.get("familyId") or "")
        sev = SEVERITY_ORDER.get(str(row.get("semanticStatus") or ""), 99)
        if sort_by == "family":
            return (fid,)
        if sort_by == "owner":
            return (str(row.get("owner") or ""), fid)
        if sort_by == "type":
            return (str(row.get("kind") or ""), fid)
        if sort_by == "branches":
            return (int(row.get("handledBranches", 0)), int(row.get("reachableBranches", 0)), fid)
        if sort_by == "issues":
            return (int(row.get("errorCount", 0)), int(row.get("warningCount", 0)), fid)
        if sort_by == "closure":
            return (str(row.get("closureHealth") or ""), fid)
        if sort_by == "tests":
            return (str(row.get("fixtureCoverage") or ""), fid)
        return (sev, fid)

    return sorted(rows, key=_key, reverse=descending)


def filter_completeness_families(
    report: dict[str, Any],
    *,
    search_text: str = "",
    issue_filter: str = "needs_attention",
    owner_filter: str = "all",
    kind_filter: str = "all",
    namespace_filter: str = "all",
    advanced_filter: str = "none",
    affected_ids: Iterable[str] = (),
    sort_by: str = "severity",
    sort_descending: bool = False,
) -> list[dict[str, Any]]:
    """Filter and sort compiler-reported families using only canonical report fields."""
    families = report.get("families") or {}
    affected_set = set(affected_ids)
    needle = search_text.strip().lower()
    rows: list[dict[str, Any]] = []

    for fid in sorted(families):
        row = families[fid]
        if owner_filter != "all" and row.get("owner") != owner_filter:
            continue
        if kind_filter != "all" and row.get("kind") != kind_filter:
            continue
        if namespace_filter != "all" and row.get("namespace") != namespace_filter:
            continue
        if needle:
            haystack = " ".join(
                str(row.get(k) or "")
                for k in ("owner", "kind", "namespace", "familyId", "closureHealth", "semanticStatus")
            ).lower()
            if needle not in haystack:
                continue

        codes = set(row.get("diagnosticCodes") or ())
        status = str(row.get("semanticStatus") or "")
        if issue_filter == "needs_attention" and not _row_needs_attention(row):
            continue
        elif issue_filter == "errors_only" and int(row.get("errorCount", 0)) <= 0:
            continue
        elif issue_filter == "warnings_only" and int(row.get("warningCount", 0)) <= 0:
            continue
        elif issue_filter == "pending_review" and status != "YELLOW":
            continue
        elif issue_filter == "continuations" and status != "BLUE":
            continue
        elif issue_filter == "healthy_only" and status != "GREEN":
            continue
        elif issue_filter in ("missing_coverage", "missing_fixture_coverage") and row.get("fixtureCoverage") != "uncovered":
            continue
        elif issue_filter == "recently_changed_affected" and fid not in affected_set:
            continue

        # Backward-compatible support for passing advanced codes directly in issue_filter or advanced_filter
        adv = advanced_filter if advanced_filter != "none" else issue_filter
        if adv == "missing_closure" and row.get("hasClosure", False):
            continue
        elif adv == "unhandled_state_outcome" and "unhandled_state_outcome" not in codes:
            continue
        elif adv == "unhandled_action_outcome" and "unhandled_action_outcome" not in codes:
            continue
        elif adv == "pending_without_exit" and "pending_without_exit" not in codes:
            continue
        elif adv == "unbounded_cycle" and "unbounded_loop" not in codes:
            continue
        elif adv == "missing_repeat_policy" and "missing_repeat_policy" not in codes:
            continue
        elif adv == "typed_click_parity_gap" and row.get("typedClickParity") != "unspecified":
            continue

        rows.append(row)
    return sort_completeness_rows(rows, sort_by=sort_by, descending=sort_descending)


class DialogueCompletenessWorkbench:
    """Primary Semantic Lab workbench rendering the canonical completeness report."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: Any,
        *,
        on_open_family: Callable[[str, str | None], None] | None = None,
        on_select_family: Callable[[str], None] | None = None,
        on_run_family_tests: Callable[[str], None] | None = None,
        auto_analyze: bool = False,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self._on_open_family = on_open_family
        self._on_select_family = on_select_family
        self._on_run_family_tests = on_run_family_tests
        self._syncing_selection = False

        self.frame = ttk.Frame(parent, padding=4)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)

        self._report: dict[str, Any] = {}
        self._filtered_rows: list[dict[str, Any]] = []
        self._selected_family_id: str | None = None
        self._family_diagnostics: list[dict[str, Any]] = []
        self._selected_diagnostic: dict[str, Any] | None = None
        self._affected_ids: set[str] = set()
        self._last_scaffold_preview: dict[str, Any] | None = None

        self._summary_var = tk.StringVar(
            value="Click 'Run Strict Completeness' to load compiler completeness report."
        )
        self._search_var = tk.StringVar()
        self._issue_filter_var = tk.StringVar(value="needs_attention")
        self._owner_filter_var = tk.StringVar(value="all")
        self._kind_filter_var = tk.StringVar(value="all")
        self._namespace_filter_var = tk.StringVar(value="all")
        self._advanced_filter_var = tk.StringVar(value="none")
        self._sort_by = "severity"
        self._sort_descending = False
        self._tech_visible = False
        self._counter_vars: dict[str, Any] = {
            "needs_fixing": tk.StringVar(value="Needs fixing (0)"),
            "warnings": tk.StringVar(value="Warnings (0)"),
            "pending": tk.StringVar(value="Pending review (0)"),
            "continuations": tk.StringVar(value="Continuations (0)"),
            "healthy": tk.StringVar(value="Healthy (0)"),
            "all": tk.StringVar(value="All (0)"),
        }
        self._scaffold_kind_var = tk.StringVar(value="closure")
        self._scaffold_outcome_var = tk.StringVar(value="accepted")
        self._repair_status_var = tk.StringVar(value="No structural repair needed")
        self._adv_repair_visible = False

        self._build_ui()
        if auto_analyze:
            self.run_strict_analysis()

    def _build_ui(self) -> None:
        ttk = self._ttk
        self.frame.rowconfigure(3, weight=1)
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        toolbar.columnconfigure(4, weight=1)

        ttk.Button(
            toolbar,
            text="Run Strict Completeness",
            command=self.run_strict_analysis,
        ).grid(row=0, column=0, padx=(0, 4))
        ttk.Button(
            toolbar,
            text="Run Affected Analysis",
            command=self.run_affected_analysis,
        ).grid(row=0, column=1, padx=(0, 4))
        ttk.Label(toolbar, textvariable=self._summary_var).grid(
            row=0, column=2, columnspan=3, sticky="w", padx=(6, 0)
        )

        counters = ttk.Frame(self.frame)
        counters.grid(row=1, column=0, sticky="ew", pady=(0, 4))
        counter_specs = (
            ("needs_fixing", "errors_only"),
            ("warnings", "warnings_only"),
            ("pending", "pending_review"),
            ("continuations", "continuations"),
            ("healthy", "healthy_only"),
            ("all", "all"),
        )
        for col_idx, (key, filter_val) in enumerate(counter_specs):
            ttk.Button(
                counters,
                textvariable=self._counter_vars[key],
                command=lambda fv=filter_val: self._set_quick_filter(fv),
            ).grid(row=0, column=col_idx, padx=(0, 4))

        filters = ttk.Frame(self.frame)
        filters.grid(row=2, column=0, sticky="ew", pady=(0, 4))
        filters.columnconfigure(1, weight=1)
        ttk.Label(filters, text="Search").grid(row=0, column=0, sticky="w")
        search_entry = ttk.Entry(filters, textvariable=self._search_var)
        search_entry.grid(row=0, column=1, sticky="ew", padx=(4, 6))
        search_entry.bind("<KeyRelease>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Filter").grid(row=0, column=2, sticky="w")
        self._issue_box = ttk.Combobox(
            filters,
            textvariable=self._issue_filter_var,
            state="readonly",
            values=ISSUE_FILTERS,
            width=22,
        )
        self._issue_box.grid(row=0, column=3, padx=(4, 6))
        self._issue_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Owner").grid(row=0, column=4, sticky="w")
        self._owner_box = ttk.Combobox(
            filters,
            textvariable=self._owner_filter_var,
            state="readonly",
            values=("all", "PsychopatzCore", "ProjectHoomans", "DTCommon"),
            width=14,
        )
        self._owner_box.grid(row=0, column=5, padx=(4, 6))
        self._owner_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Type").grid(row=0, column=6, sticky="w")
        self._kind_box = ttk.Combobox(
            filters,
            textvariable=self._kind_filter_var,
            state="readonly",
            values=("all", "dialogue", "behavior", "beat", "realization"),
            width=11,
        )
        self._kind_box.grid(row=0, column=7, padx=(4, 6))
        self._kind_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Namespace").grid(row=0, column=8, sticky="w")
        self._namespace_box = ttk.Combobox(
            filters,
            textvariable=self._namespace_filter_var,
            state="readonly",
            values=("all",),
            width=14,
        )
        self._namespace_box.grid(row=0, column=9, padx=(4, 6))
        self._namespace_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Advanced").grid(row=0, column=10, sticky="w")
        self._advanced_box = ttk.Combobox(
            filters,
            textvariable=self._advanced_filter_var,
            state="readonly",
            values=ADVANCED_ISSUE_FILTERS,
            width=20,
        )
        self._advanced_box.grid(row=0, column=11, padx=(4, 0))
        self._advanced_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        paned = ttk.PanedWindow(self.frame, orient="horizontal")
        paned.grid(row=3, column=0, sticky="nsew")

        left = ttk.LabelFrame(paned, text="Package Families (compiler report)")
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._family_tree = ttk.Treeview(
            left,
            columns=TREE_COLUMNS,
            show="headings",
            selectmode="browse",
        )
        for col in TREE_COLUMNS:
            self._family_tree.heading(
                col,
                text=TREE_HEADINGS[col],
                command=lambda c=col: self._sort_by_column(c),
            )
            width = 160 if col == "family" else (130 if col == "health" else 95)
            self._family_tree.column(col, width=width, stretch=(col == "family"))
        for status_key, style_cfg in SEMANTIC_TAG_STYLES.items():
            self._family_tree.tag_configure(status_key, **style_cfg)
        self._family_tree.grid(row=0, column=0, sticky="nsew")
        self._family_tree.bind("<<TreeviewSelect>>", lambda _e: self._on_family_select())
        lscroll = ttk.Scrollbar(left, orient="vertical", command=self._family_tree.yview)
        lscroll.grid(row=0, column=1, sticky="ns")
        self._family_tree.configure(yscrollcommand=lscroll.set)
        paned.add(left, weight=3)

        right = ttk.Frame(paned)
        right.rowconfigure(0, weight=2)
        right.rowconfigure(1, weight=1)
        right.rowconfigure(2, weight=2)
        right.columnconfigure(0, weight=1)
        paned.add(right, weight=3)

        graph_box = ttk.LabelFrame(right, text="Family Authoring Health")
        graph_box.grid(row=0, column=0, sticky="nsew", pady=(0, 4))
        graph_box.rowconfigure(0, weight=1)
        graph_box.columnconfigure(0, weight=1)
        self._graph_text = self._ScrolledText(graph_box, height=8, wrap="word", state="disabled")
        self._graph_text.grid(row=0, column=0, sticky="nsew")
        self._tech_toggle_btn = ttk.Button(
            graph_box,
            text="Show technical details",
            command=self._toggle_technical_details,
        )
        self._tech_toggle_btn.grid(row=1, column=0, sticky="w", pady=(2, 0))
        self._tech_text = self._ScrolledText(graph_box, height=7, wrap="none", state="disabled")

        diag_box = ttk.LabelFrame(right, text="Diagnostics")
        diag_box.grid(row=1, column=0, sticky="nsew", pady=(0, 4))
        diag_box.rowconfigure(0, weight=1)
        diag_box.columnconfigure(0, weight=1)
        self._diag_list = self._tk.Listbox(diag_box, height=5, exportselection=False)
        self._diag_list.grid(row=0, column=0, sticky="nsew")
        self._diag_list.bind("<<ListboxSelect>>", lambda _e: self._on_diag_select())

        detail_box = ttk.LabelFrame(right, text="Contextual Repair, Navigation & Verification")
        detail_box.grid(row=2, column=0, sticky="nsew")
        detail_box.rowconfigure(3, weight=1)
        detail_box.columnconfigure(0, weight=1)

        nav_bar = ttk.Frame(detail_box)
        nav_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        ttk.Button(nav_bar, text="Open canonical source", command=self.open_canonical_source).pack(side="left")
        ttk.Button(nav_bar, text="Open affected field", command=self.open_affected_field).pack(side="left", padx=4)
        ttk.Button(nav_bar, text="Open continuation target", command=self.open_continuation_target).pack(side="left")
        if self._on_run_family_tests is not None:
            ttk.Button(nav_bar, text="Run family tests", command=self.run_family_tests).pack(side="left", padx=4)

        repair_card = ttk.Frame(detail_box)
        repair_card.grid(row=1, column=0, sticky="ew", pady=(0, 4))
        repair_card.columnconfigure(0, weight=1)
        ttk.Label(repair_card, textvariable=self._repair_status_var).grid(row=0, column=0, sticky="w")
        repair_btns = ttk.Frame(repair_card)
        repair_btns.grid(row=0, column=1, sticky="e")
        self._preview_btn = ttk.Button(repair_btns, text="Preview", command=self.preview_scaffold)
        self._preview_btn.pack(side="left")
        self._apply_btn = ttk.Button(repair_btns, text="Apply", command=self.apply_scaffold)
        self._apply_btn.pack(side="left", padx=4)
        self._adv_repair_btn = ttk.Button(
            repair_btns,
            text="Advanced repair tools",
            command=self._toggle_advanced_repair,
        )
        self._adv_repair_btn.pack(side="left")

        self._adv_repair_frame = ttk.Frame(detail_box)
        ttk.Label(self._adv_repair_frame, text="Scaffold").pack(side="left")
        self._scaffold_box = ttk.Combobox(
            self._adv_repair_frame,
            textvariable=self._scaffold_kind_var,
            state="readonly",
            values=(
                "reply_outcome",
                "closure",
                "pending_exit",
                "repeat_policy",
                "poststate_guard",
                "closure_residue",
                "fixture_stub",
            ),
            width=16,
        )
        self._scaffold_box.pack(side="left", padx=4)
        ttk.Entry(self._adv_repair_frame, textvariable=self._scaffold_outcome_var, width=14).pack(side="left", padx=(0, 4))

        self._detail_text = self._ScrolledText(detail_box, height=7, wrap="word", state="disabled")
        self._detail_text.grid(row=3, column=0, sticky="nsew")
        self._set_repair_controls_enabled(False)

    def ensure_loaded(self) -> dict[str, Any]:
        if not self._report:
            return self.run_strict_analysis()
        return self._report

    def run_strict_analysis(self) -> dict[str, Any]:
        report = self.service.analyze_convo_completeness(strict_manifest=True)
        self._report = report
        self._affected_ids = set()
        self._refresh_filter_choices()
        self._apply_filters()
        self._update_summary_banner()
        return report

    def run_affected_analysis(self, family_ids: Iterable[str] | None = None) -> dict[str, Any]:
        seeds = list(family_ids) if family_ids is not None else (
            [self._selected_family_id] if self._selected_family_id else []
        )
        if not seeds:
            return self.run_strict_analysis()
        partial = self.service.analyze_convo_completeness(
            strict_manifest=True,
            family_ids=seeds,
        )
        if not self._report:
            self._report = partial
        else:
            existing_families = dict(self._report.get("families") or {})
            for fid, fdata in (partial.get("families") or {}).items():
                existing_families[fid] = fdata
            self._report["families"] = existing_families

            affected = set(partial.get("affectedFamilyIds") or ())
            kept_diags = [
                d for d in (self._report.get("diagnostics") or ())
                if d.get("familyId") not in affected
            ]
            kept_diags.extend(partial.get("diagnostics") or ())
            self._report["diagnostics"] = kept_diags
            errors = sum(1 for d in kept_diags if d.get("severity") == "error")
            warnings = sum(1 for d in kept_diags if d.get("severity") == "warning")
            infos = sum(1 for d in kept_diags if d.get("severity") == "info")
            summary = dict(self._report.get("summary") or {})
            summary["errors"] = errors
            summary["warnings"] = warnings
            summary["info"] = infos
            self._report["summary"] = summary
            self._report["ok"] = errors == 0

        self._affected_ids = set(partial.get("affectedFamilyIds") or ())
        self._apply_filters()
        self._update_summary_banner()
        return partial

    def _set_quick_filter(self, filter_val: str) -> None:
        self._issue_filter_var.set(filter_val)
        self._apply_filters()

    def _sort_by_column(self, col: str) -> None:
        if self._sort_by == col:
            self._sort_descending = not self._sort_descending
        else:
            self._sort_by = col
            self._sort_descending = False
        self._apply_filters()

    def _toggle_technical_details(self) -> None:
        self._tech_visible = not self._tech_visible
        if self._tech_visible:
            self._tech_text.grid(row=2, column=0, sticky="nsew", pady=(2, 0))
            self._tech_toggle_btn.configure(text="Hide technical details")
        else:
            try:
                self._tech_text.grid_remove()
            except Exception:
                pass
            self._tech_toggle_btn.configure(text="Show technical details")

    def _update_summary_banner(self) -> None:
        summary = self._report.get("summary") or {}
        health = summary.get("byClosureHealth") or {}
        by_kind = summary.get("byKind") or {}
        d_total = (by_kind.get("dialogue") or {}).get("total", 0)
        b_total = (by_kind.get("behavior") or {}).get("total", 0)
        bt_total = (by_kind.get("beat") or {}).get("total", 0)
        r_total = (by_kind.get("realization") or {}).get("total", 0)
        self._summary_var.set(
            f"{summary.get('families', 0)} maintained "
            f"({d_total} Dialogues, {b_total} Behaviors, {bt_total} Beats, {r_total} Realizations) | "
            f"errors={summary.get('errors', 0)} | warnings={summary.get('warnings', 0)}"
        )
        all_families = (self._report.get("families") or {}).values()
        needs_fixing = sum(1 for r in all_families if int(r.get("errorCount", 0)) > 0)
        warnings_cnt = sum(
            1 for r in all_families
            if int(r.get("errorCount", 0)) == 0 and int(r.get("warningCount", 0)) > 0
        )
        pending_cnt = health.get("bounded_pending", 0)
        cont_cnt = health.get("continuation", 0)
        healthy_cnt = health.get("resolved_terminal", 0)
        self._counter_vars["needs_fixing"].set(f"Needs fixing ({needs_fixing})")
        self._counter_vars["warnings"].set(f"Warnings ({warnings_cnt})")
        self._counter_vars["pending"].set(f"Pending review ({pending_cnt})")
        self._counter_vars["continuations"].set(f"Continuations ({cont_cnt})")
        self._counter_vars["healthy"].set(f"Healthy ({healthy_cnt})")
        self._counter_vars["all"].set(f"All ({summary.get('families', 0)})")

    def _refresh_filter_choices(self) -> None:
        families = (self._report.get("families") or {}).values()
        owners = ["all", *sorted({str(f.get("owner") or "") for f in families if f.get("owner")})]
        kinds = ["all", *sorted({str(f.get("kind") or "") for f in families if f.get("kind")})]
        namespaces = ["all", *sorted({str(f.get("namespace") or "") for f in families if f.get("namespace")})]
        self._owner_box.configure(values=tuple(owners))
        self._kind_box.configure(values=tuple(kinds))
        self._namespace_box.configure(values=tuple(namespaces))

    def _apply_filters(self) -> None:
        rows = filter_completeness_families(
            self._report,
            search_text=self._search_var.get(),
            issue_filter=self._issue_filter_var.get(),
            owner_filter=self._owner_filter_var.get(),
            kind_filter=self._kind_filter_var.get(),
            namespace_filter=self._namespace_filter_var.get(),
            advanced_filter=self._advanced_filter_var.get(),
            affected_ids=self._affected_ids,
            sort_by=self._sort_by,
            sort_descending=self._sort_descending,
        )
        self._filtered_rows = rows
        existing_children = self._family_tree.get_children()
        if existing_children:
            self._family_tree.delete(*existing_children)
        selected_fid: str | None = None
        for row in rows:
            fid = str(row["familyId"])
            status = str(row.get("semanticStatus") or "GREEN")
            status_label = SEMANTIC_STATUS_LABELS.get(status, status)
            mark = " *affected" if fid in self._affected_ids else ""
            err_n = int(row.get("errorCount", 0))
            warn_n = int(row.get("warningCount", 0))
            issues_str = f"E:{err_n} W:{warn_n}" if (err_n or warn_n) else "None"
            branches_str = f"{row.get('handledBranches')}/{row.get('reachableBranches')} ({row.get('fixtureCoverage')})"
            tests_str = str(row.get("fixtureCoverage") or "unknown")
            self._family_tree.insert(
                "",
                "end",
                iid=fid,
                values=(
                    status_label,
                    f"{fid}{mark}",
                    str(row.get("owner") or ""),
                    str(row.get("kind") or ""),
                    branches_str,
                    issues_str,
                    str(row.get("closureHealth") or ""),
                    tests_str,
                ),
                tags=(status,),
            )
            if fid == self._selected_family_id:
                selected_fid = fid
        all_families = self._report.get("families") or {}
        if selected_fid is not None and rows:
            self._set_tree_selection(selected_fid)
            self._render_family_graph(all_families[selected_fid])
        elif self._selected_family_id and self._selected_family_id in all_families:
            self._render_family_graph(all_families[self._selected_family_id])
        elif self._selected_family_id is None and rows:
            first_fid = str(rows[0]["familyId"])
            self._set_tree_selection(first_fid)
            self._selected_family_id = first_fid
            self._render_family_graph(rows[0])
        else:
            self._render_family_graph(None)

    def _set_tree_selection(self, family_id: str) -> None:
        try:
            self._family_tree.selection_set(family_id)
            self._family_tree.see(family_id)
        except Exception:
            pass

    def select_family(
        self,
        family_id: str,
        *,
        ensure_loaded: bool = True,
        notify: bool = True,
    ) -> bool:
        self._selected_family_id = str(family_id) if family_id else None
        if ensure_loaded:
            self.ensure_loaded()
        if not self._report:
            return False
        all_families = self._report.get("families") or {}
        found_row = all_families.get(family_id)
        in_filtered = any(r.get("familyId") == family_id for r in self._filtered_rows)
        if in_filtered:
            self._set_tree_selection(family_id)
        else:
            try:
                cur = self._family_tree.selection()
                if cur:
                    self._family_tree.selection_remove(*cur)
            except Exception:
                pass
        if found_row is not None:
            self._render_family_graph(found_row)
            if notify and self._on_select_family is not None and not self._syncing_selection:
                self._syncing_selection = True
                try:
                    self._on_select_family(family_id)
                finally:
                    self._syncing_selection = False
            return True
        return False

    def _on_family_select(self) -> None:
        if self._syncing_selection:
            return
        sel = self._family_tree.selection()
        if not sel:
            return
        fid = str(sel[0])
        all_families = self._report.get("families") or {}
        row = all_families.get(fid)
        if row is None:
            return
        self._selected_family_id = fid
        self._render_family_graph(row)
        if self._on_select_family is not None:
            self._syncing_selection = True
            try:
                self._on_select_family(fid)
            finally:
                self._syncing_selection = False

    @staticmethod
    def _format_human_health_summary(
        row: dict[str, Any],
        family_diags: list[dict[str, Any]],
    ) -> str:
        fid = str(row.get("familyId") or "")
        kind = str(row.get("kind") or "dialogue")
        status = str(row.get("semanticStatus") or "GREEN")
        status_label = SEMANTIC_STATUS_LABELS.get(status, status)
        handled = int(row.get("handledBranches", 0))
        reachable = int(row.get("reachableBranches", 1))
        repeat_pol = str(row.get("repeatPolicy") or "unspecified")
        deps = row.get("dependencies") or ()
        detail = row.get("kindDetail") or {}

        lines: list[str] = []
        if family_diags:
            lines.append(f"Needs attention — {fid} [{status_label}]")
            lines.append("")
            for d in family_diags:
                lines.append(f"• {d.get('message')}")
                if d.get("repairHint"):
                    lines.append(f"  Suggested fix: {d.get('repairHint')}")
            lines.append("")
        elif status == "BLUE":
            lines.append(f"Continues to another family — {fid} [{status_label}]")
            lines.append("")
            lines.append(f"Next: {', '.join(deps) or '(emits semantic continuation)'}")
        elif status == "YELLOW":
            lines.append(f"Bounded pending / review state — {fid} [{status_label}]")
            lines.append("")
            lines.append("Waiting/deferred state has a reachable exit or resolution.")
        elif status == "PURPLE":
            lines.append(f"Domain obligation survives conversation — {fid} [{status_label}]")
            lines.append("")
            lines.append(f"Closure: {row.get('closureClass')}")
        else:
            if kind == "behavior":
                lines.append(f"Behavior ready — {fid} [{status_label}]")
                lines.append("")
                lines.append(f"Stimuli: {', '.join(detail.get('stimuli') or ()) or 'none'}")
                lines.append(f"Outputs: {', '.join(detail.get('outputChannels') or ()) or detail.get('act') or 'none'}")
            elif kind == "beat":
                lines.append(f"Beat bounded — {fid} [{status_label}]")
                lines.append("")
                lines.append(f"Candidates: {detail.get('candidateCount', 0)} | maxTurns: {detail.get('maxTurns')}")
            elif kind == "realization":
                lines.append(f"Realization complete — {fid} [{status_label}]")
                lines.append("")
                lines.append(f"Locales: {', '.join(detail.get('locales') or ()) or 'forms'} | Act: {detail.get('dialogueAct') or detail.get('concept') or 'n/a'}")
            else:
                lines.append(f"Ends cleanly — {fid} [{status_label}]")
                lines.append("")
                lines.append(f"{reachable} reachable branch(es) · {handled} handled")
                lines.append(f"No warnings · Repeat policy: {repeat_pol}")
        return "\n".join(lines)

    def _render_family_graph(self, row: dict[str, Any] | None) -> None:
        if row is None:
            self._set_text(self._graph_text, "(no family selected)")
            self._set_text(self._tech_text, "")
            self._diag_list.delete(0, "end")
            self._family_diagnostics = []
            self._selected_diagnostic = None
            self._set_text(self._detail_text, "")
            return

        fid = str(row["familyId"])
        self._family_diagnostics = [
            d for d in (self._report.get("diagnostics") or ())
            if d.get("familyId") == fid
        ]
        self._set_text(
            self._graph_text,
            self._format_human_health_summary(row, self._family_diagnostics),
        )

        graph = row.get("graph") or {}
        lines = [
            f"FAMILY: {fid}  [{row.get('semanticStatus')} / {row.get('closureHealth')}]",
            f"Source: {row.get('sourcePath') or row.get('sourceShard')}",
            f"Closure: {row.get('closureClass')} | Repeat: {row.get('repeatPolicy')} | Input: {row.get('typedClickParity')} | Coverage: {row.get('fixtureCoverage')}",
            f"SCC: {', '.join(row.get('sccMembers') or ())}",
            f"Outgoing: {', '.join(row.get('dependencies') or ()) or '(none)'} | Incoming: {', '.join(row.get('dependents') or ()) or '(none)'}",
            "",
            "NODES:",
        ]
        for node in graph.get("nodes") or ():
            lines.append(
                f"  [{node.get('colorClass')}:{node.get('status')}] ({node.get('kind')}) {node.get('label')}  @{node.get('path')}"
            )
        lines.append("")
        lines.append("EDGES:")
        for edge in graph.get("edges") or ():
            lines.append(
                f"  [{edge.get('colorClass')}] {edge.get('from')} --({edge.get('label')})--> {edge.get('to')}"
            )
        if row.get("stateOutcomeMatrix"):
            lines.append("")
            lines.append("STATE OUTCOME MATRIX:")
            for item in row["stateOutcomeMatrix"]:
                lines.append(
                    f"  rule={item.get('ruleId')} outcome={item.get('outcome')} admission={item.get('admission')} reply={item.get('replyOutcome')} handled={item.get('handled')}"
                )
        if row.get("actionOutcomeMatrix"):
            lines.append("")
            lines.append("ACTION OUTCOME MATRIX:")
            for item in row["actionOutcomeMatrix"]:
                lines.append(
                    f"  contract={item.get('contractId')} outcome={item.get('outcome')} handled={item.get('handled')}"
                )
        self._set_text(self._tech_text, "\n".join(lines))

        self._diag_list.delete(0, "end")
        for d in self._family_diagnostics:
            self._diag_list.insert(
                "end",
                f"[{d.get('severity', '').upper()}] {d.get('code')} @ {d.get('path')}: {d.get('message')}",
            )
        if self._family_diagnostics:
            self._diag_list.selection_set(0)
            self._on_diag_select()
        else:
            self._selected_diagnostic = None
            self._repair_status_var.set("No structural repair needed")
            self._set_repair_controls_enabled(False)
            self._set_text(
                self._detail_text,
                "No structural repair needed.\n\nThis family has no active authoring-health diagnostics.",
            )

    def _toggle_advanced_repair(self) -> None:
        self._adv_repair_visible = not self._adv_repair_visible
        if self._adv_repair_visible:
            self._adv_repair_frame.grid(row=2, column=0, sticky="ew", pady=(0, 4))
        else:
            try:
                self._adv_repair_frame.grid_remove()
            except Exception:
                pass

    def _set_repair_controls_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        combo_state = "readonly" if enabled else "disabled"
        for btn in (self._preview_btn, self._apply_btn):
            try:
                btn.configure(state=state)
            except Exception:
                pass
        try:
            self._scaffold_box.configure(state=combo_state)
        except Exception:
            pass

    def _on_diag_select(self) -> None:
        sel = self._diag_list.curselection()
        if not sel:
            return
        idx = int(sel[0])
        if idx < 0 or idx >= len(self._family_diagnostics):
            return
        diag = self._family_diagnostics[idx]
        self._selected_diagnostic = diag
        suggested = suggest_scaffold_kind(str(diag.get("code") or ""))
        self._scaffold_kind_var.set(suggested)
        self._repair_status_var.set(f"Suggested structural fix: {suggested}")
        self._set_repair_controls_enabled(True)
        why = diag.get("missingOwnership") or "Authoring-health policy requires explicit declaration."
        card_text = "\n".join(
            [
                f"Problem: {diag.get('message')}",
                f"Why it matters: {why} ({diag.get('code')})",
                f"Suggested structural fix: {diag.get('repairHint')} [scaffold: {suggested}]",
                "",
                json.dumps(diag, indent=2, ensure_ascii=False),
            ]
        )
        self._set_text(self._detail_text, card_text)

    def open_canonical_source(self) -> None:
        if self._selected_family_id and self._on_open_family is not None:
            path = (
                self._selected_diagnostic.get("path")
                if self._selected_diagnostic
                else None
            )
            self._on_open_family(self._selected_family_id, path)

    def open_affected_field(self) -> None:
        if not self._selected_family_id or self._on_open_family is None:
            return
        path = (
            self._selected_diagnostic.get("path")
            if self._selected_diagnostic
            else None
        )
        code = (
            self._selected_diagnostic.get("code")
            if self._selected_diagnostic
            else None
        )
        try:
            self._on_open_family(self._selected_family_id, path, code)
        except TypeError:
            self._on_open_family(self._selected_family_id, path)

    def open_continuation_target(self) -> None:
        if not self._selected_family_id:
            return
        row = (self._report.get("families") or {}).get(self._selected_family_id) or {}
        deps = row.get("dependencies") or ()
        if deps:
            target = str(deps[0])
            if not self.select_family(target) and self._on_open_family is not None:
                self._on_open_family(target, None)

    def run_family_tests(self) -> dict[str, Any] | None:
        if self._selected_family_id and self._on_run_family_tests is not None:
            result = self._on_run_family_tests(self._selected_family_id)
            if isinstance(result, dict):
                self._set_text(self._detail_text, json.dumps(result, indent=2, ensure_ascii=False))
                return result
        return None

    def preview_scaffold(self) -> dict[str, Any] | None:
        if not self._selected_family_id:
            return None
        preview = self.service.preview_completeness_scaffold(
            self._selected_family_id,
            self._scaffold_kind_var.get(),
            outcome_name=self._scaffold_outcome_var.get(),
        )
        self._last_scaffold_preview = preview
        self._set_text(self._detail_text, json.dumps(preview, indent=2, ensure_ascii=False))
        return preview

    def apply_scaffold(self) -> dict[str, Any] | None:
        if not self._selected_family_id:
            return None
        if not self._messagebox.askyesno(
            "Apply Structural Scaffold",
            f"Apply '{self._scaffold_kind_var.get()}' structural scaffold to {self._selected_family_id}?",
        ):
            return None
        applied = self.service.apply_completeness_scaffold(
            self._selected_family_id,
            self._scaffold_kind_var.get(),
            outcome_name=self._scaffold_outcome_var.get(),
        )
        self._set_text(self._detail_text, json.dumps(applied, indent=2, ensure_ascii=False))
        self.run_affected_analysis([self._selected_family_id])
        return applied

    @staticmethod
    def _set_text(widget: Any, text: str) -> None:
        try:
            widget.configure(state="normal")
        except Exception:
            pass
        widget.delete("1.0", "end")
        widget.insert("1.0", text)
        try:
            widget.configure(state="disabled")
        except Exception:
            pass
