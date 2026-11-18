"""R9B/R9C: Primary Dialogue Completeness Workbench for Semantic Lab.

Renders the compiler-owned report from ``SemanticLabAuthoringService.analyze_convo_completeness()``
without duplicating any graph/completeness reasoning in Tk.
"""

from __future__ import annotations

import json
from typing import Any, Callable, Iterable

from tools.semantic_harness.codebuilder.completeness_scaffold import suggest_scaffold_kind


ISSUE_FILTERS: tuple[str, ...] = (
    "all",
    "errors_only",
    "warnings_only",
    "missing_closure",
    "unhandled_state_outcome",
    "unhandled_action_outcome",
    "pending_without_exit",
    "unbounded_cycle",
    "missing_repeat_policy",
    "missing_fixture_coverage",
    "typed_click_parity_gap",
    "recently_changed_affected",
)


def filter_completeness_families(
    report: dict[str, Any],
    *,
    search_text: str = "",
    issue_filter: str = "all",
    owner_filter: str = "all",
    kind_filter: str = "all",
    affected_ids: Iterable[str] = (),
) -> list[dict[str, Any]]:
    """Filter compiler-reported families using only canonical report fields."""
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
        if needle:
            haystack = " ".join(
                str(row.get(k) or "")
                for k in ("owner", "kind", "namespace", "familyId", "closureHealth")
            ).lower()
            if needle not in haystack:
                continue

        codes = set(row.get("diagnosticCodes") or ())
        if issue_filter == "errors_only" and int(row.get("errorCount", 0)) <= 0:
            continue
        elif issue_filter == "warnings_only" and int(row.get("warningCount", 0)) <= 0:
            continue
        elif issue_filter == "missing_closure" and row.get("hasClosure", False):
            continue
        elif issue_filter == "unhandled_state_outcome" and "unhandled_state_outcome" not in codes:
            continue
        elif issue_filter == "unhandled_action_outcome" and "unhandled_action_outcome" not in codes:
            continue
        elif issue_filter == "pending_without_exit" and "pending_without_exit" not in codes:
            continue
        elif issue_filter == "unbounded_cycle" and "unbounded_loop" not in codes:
            continue
        elif issue_filter == "missing_repeat_policy" and "missing_repeat_policy" not in codes:
            continue
        elif issue_filter == "missing_fixture_coverage" and row.get("fixtureCoverage") != "uncovered":
            continue
        elif issue_filter == "typed_click_parity_gap" and row.get("typedClickParity") != "unspecified":
            continue
        elif issue_filter == "recently_changed_affected" and fid not in affected_set:
            continue

        rows.append(row)
    return rows


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
        on_run_family_tests: Callable[[str], None] | None = None,
        auto_analyze: bool = False,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self._on_open_family = on_open_family
        self._on_run_family_tests = on_run_family_tests

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
        self._issue_filter_var = tk.StringVar(value="all")
        self._owner_filter_var = tk.StringVar(value="all")
        self._kind_filter_var = tk.StringVar(value="all")
        self._scaffold_kind_var = tk.StringVar(value="closure")
        self._scaffold_outcome_var = tk.StringVar(value="accepted")

        self._build_ui()
        if auto_analyze:
            self.run_strict_analysis()

    def _build_ui(self) -> None:
        ttk = self._ttk
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

        filters = ttk.Frame(self.frame)
        filters.grid(row=1, column=0, sticky="ew", pady=(0, 4))
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
            width=24,
        )
        self._issue_box.grid(row=0, column=3, padx=(4, 6))
        self._issue_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Owner").grid(row=0, column=4, sticky="w")
        self._owner_box = ttk.Combobox(
            filters,
            textvariable=self._owner_filter_var,
            state="readonly",
            values=("all", "PsychopatzCore", "ProjectHoomans", "DTCommon"),
            width=16,
        )
        self._owner_box.grid(row=0, column=5, padx=(4, 6))
        self._owner_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        ttk.Label(filters, text="Kind").grid(row=0, column=6, sticky="w")
        self._kind_box = ttk.Combobox(
            filters,
            textvariable=self._kind_filter_var,
            state="readonly",
            values=("all", "dialogue", "behavior", "beat", "realization"),
            width=12,
        )
        self._kind_box.grid(row=0, column=7, padx=(4, 0))
        self._kind_box.bind("<<ComboboxSelected>>", lambda _e: self._apply_filters())

        paned = ttk.PanedWindow(self.frame, orient="horizontal")
        paned.grid(row=2, column=0, sticky="nsew")

        left = ttk.LabelFrame(paned, text="Package Families (compiler report)")
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._family_list = self._tk.Listbox(left, width=52, exportselection=False)
        self._family_list.grid(row=0, column=0, sticky="nsew")
        self._family_list.bind("<<ListboxSelect>>", lambda _e: self._on_family_select())
        lscroll = ttk.Scrollbar(left, orient="vertical", command=self._family_list.yview)
        lscroll.grid(row=0, column=1, sticky="ns")
        self._family_list.configure(yscrollcommand=lscroll.set)
        paned.add(left, weight=2)

        right = ttk.Frame(paned)
        right.rowconfigure(0, weight=2)
        right.rowconfigure(1, weight=1)
        right.rowconfigure(2, weight=2)
        right.columnconfigure(0, weight=1)
        paned.add(right, weight=3)

        graph_box = ttk.LabelFrame(right, text="Compiler-Derived Semantic Graph")
        graph_box.grid(row=0, column=0, sticky="nsew", pady=(0, 4))
        graph_box.rowconfigure(0, weight=1)
        graph_box.columnconfigure(0, weight=1)
        self._graph_text = self._ScrolledText(graph_box, height=10, wrap="none", state="disabled")
        self._graph_text.grid(row=0, column=0, sticky="nsew")

        diag_box = ttk.LabelFrame(right, text="Diagnostics")
        diag_box.grid(row=1, column=0, sticky="nsew", pady=(0, 4))
        diag_box.rowconfigure(0, weight=1)
        diag_box.columnconfigure(0, weight=1)
        self._diag_list = self._tk.Listbox(diag_box, height=5, exportselection=False)
        self._diag_list.grid(row=0, column=0, sticky="nsew")
        self._diag_list.bind("<<ListboxSelect>>", lambda _e: self._on_diag_select())

        detail_box = ttk.LabelFrame(right, text="Diagnostic Detail, Navigation & Safe Scaffolding")
        detail_box.grid(row=2, column=0, sticky="nsew")
        detail_box.rowconfigure(2, weight=1)
        detail_box.columnconfigure(0, weight=1)

        nav_bar = ttk.Frame(detail_box)
        nav_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        ttk.Button(nav_bar, text="Open canonical source", command=self.open_canonical_source).pack(side="left")
        ttk.Button(nav_bar, text="Open affected field", command=self.open_affected_field).pack(side="left", padx=4)
        ttk.Button(nav_bar, text="Open continuation target", command=self.open_continuation_target).pack(side="left")
        if self._on_run_family_tests is not None:
            ttk.Button(nav_bar, text="Run family tests", command=self.run_family_tests).pack(side="left", padx=4)

        scaf_bar = ttk.Frame(detail_box)
        scaf_bar.grid(row=1, column=0, sticky="ew", pady=(0, 4))
        ttk.Label(scaf_bar, text="Scaffold").pack(side="left")
        self._scaffold_box = ttk.Combobox(
            scaf_bar,
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
        ttk.Entry(scaf_bar, textvariable=self._scaffold_outcome_var, width=14).pack(side="left", padx=(0, 4))
        ttk.Button(scaf_bar, text="Preview scaffold", command=self.preview_scaffold).pack(side="left")
        ttk.Button(scaf_bar, text="Apply scaffold", command=self.apply_scaffold).pack(side="left", padx=4)

        self._detail_text = self._ScrolledText(detail_box, height=8, wrap="none", state="disabled")
        self._detail_text.grid(row=2, column=0, sticky="nsew")

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

    def _update_summary_banner(self) -> None:
        summary = self._report.get("summary") or {}
        health = summary.get("byClosureHealth") or {}
        self._summary_var.set(
            f"families={summary.get('families', 0)} | "
            f"errors={summary.get('errors', 0)} | "
            f"warnings={summary.get('warnings', 0)} | "
            f"sccs={summary.get('sccs', 0)} | "
            f"resolved={health.get('resolved_terminal', 0)} "
            f"cont={health.get('continuation', 0)} "
            f"pending={health.get('bounded_pending', 0)} "
            f"invalid={health.get('invalid', 0)}"
        )

    def _refresh_filter_choices(self) -> None:
        families = (self._report.get("families") or {}).values()
        owners = ["all", *sorted({str(f.get("owner") or "") for f in families if f.get("owner")})]
        kinds = ["all", *sorted({str(f.get("kind") or "") for f in families if f.get("kind")})]
        self._owner_box.configure(values=tuple(owners))
        self._kind_box.configure(values=tuple(kinds))

    def _apply_filters(self) -> None:
        rows = filter_completeness_families(
            self._report,
            search_text=self._search_var.get(),
            issue_filter=self._issue_filter_var.get(),
            owner_filter=self._owner_filter_var.get(),
            kind_filter=self._kind_filter_var.get(),
            affected_ids=self._affected_ids,
        )
        self._filtered_rows = rows
        self._family_list.delete(0, "end")
        selected_idx = 0 if rows else None
        for idx, row in enumerate(rows):
            fid = str(row["familyId"])
            mark = " *affected" if fid in self._affected_ids else ""
            label = (
                f"[{row.get('semanticStatus')}] {fid} | "
                f"{row.get('owner')}/{row.get('kind')} | "
                f"branches {row.get('handledBranches')}/{row.get('reachableBranches')} | "
                f"E:{row.get('errorCount')} W:{row.get('warningCount')} | "
                f"{row.get('closureHealth')}{mark}"
            )
            self._family_list.insert("end", label)
            if fid == self._selected_family_id:
                selected_idx = idx
        if selected_idx is not None and rows:
            self._family_list.selection_set(selected_idx)
            self._on_family_select()
        else:
            self._selected_family_id = None
            self._render_family_graph(None)

    def select_family(self, family_id: str) -> bool:
        self.ensure_loaded()
        for idx, row in enumerate(self._filtered_rows):
            if row.get("familyId") == family_id:
                self._family_list.selection_set(idx)
                self._on_family_select()
                return True
        return False

    def _on_family_select(self) -> None:
        sel = self._family_list.curselection()
        if not sel:
            return
        idx = int(sel[0])
        if idx < 0 or idx >= len(self._filtered_rows):
            return
        row = self._filtered_rows[idx]
        self._selected_family_id = str(row["familyId"])
        self._render_family_graph(row)

    def _render_family_graph(self, row: dict[str, Any] | None) -> None:
        if row is None:
            self._set_text(self._graph_text, "(no family selected)")
            self._diag_list.delete(0, "end")
            self._family_diagnostics = []
            self._selected_diagnostic = None
            self._set_text(self._detail_text, "")
            return

        fid = str(row["familyId"])
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
        self._set_text(self._graph_text, "\n".join(lines))

        self._family_diagnostics = [
            d for d in (self._report.get("diagnostics") or ())
            if d.get("familyId") == fid
        ]
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
            self._set_text(self._detail_text, "No diagnostics for this family.")

    def _on_diag_select(self) -> None:
        sel = self._diag_list.curselection()
        if not sel:
            return
        idx = int(sel[0])
        if idx < 0 or idx >= len(self._family_diagnostics):
            return
        diag = self._family_diagnostics[idx]
        self._selected_diagnostic = diag
        self._scaffold_kind_var.set(suggest_scaffold_kind(str(diag.get("code") or "")))
        self._set_text(self._detail_text, json.dumps(diag, indent=2, ensure_ascii=False))

    def open_canonical_source(self) -> None:
        if self._selected_family_id and self._on_open_family is not None:
            path = (
                self._selected_diagnostic.get("path")
                if self._selected_diagnostic
                else None
            )
            self._on_open_family(self._selected_family_id, path)

    def open_affected_field(self) -> None:
        self.open_canonical_source()

    def open_continuation_target(self) -> None:
        if not self._selected_family_id:
            return
        row = (self._report.get("families") or {}).get(self._selected_family_id) or {}
        deps = row.get("dependencies") or ()
        if deps:
            target = str(deps[0])
            if not self.select_family(target) and self._on_open_family is not None:
                self._on_open_family(target, None)

    def run_family_tests(self) -> None:
        if self._selected_family_id and self._on_run_family_tests is not None:
            self._on_run_family_tests(self._selected_family_id)

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
