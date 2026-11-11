"""Observability-first Studio surface; production Lua remains the only selector."""
from __future__ import annotations

from typing import Any, Callable
from pathlib import Path
import json

from ..inspection.response_candidate import preview_authored_variant
from ..inspection.response_source_lineage import inspect_codebuilder_lineage
from ..inspection.response_translation_coverage import translation_coverage
from .semantic_tree import filter_semantic_tree, build_semantic_tree


class SemanticObservatoryPane:
    """Read-only catalog/trace with explicit disposable-fixture test actions."""

    def __init__(
        self, parent: Any, tk: Any, ttk: Any, scrolled_text: Any,
        run_worker: Callable[[Callable, Callable], bool],
        *, repository: Path | None = None, filedialog: Any | None = None,
        review_parent: Any | None = None,
    ) -> None:
        self._tk, self._ttk = tk, ttk
        self._run_worker = run_worker
        self._repository = repository
        self._filedialog = filedialog
        self._review_parent = review_parent
        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.filter_var = tk.StringVar(value="")
        self.status_var = tk.StringVar(
            value="Production Lua catalog · waiting for worker readiness")
        self.selected_pool = ""
        self._page_offset = 0
        self._has_more = False
        self.loading = False
        self.catalog_ready = False
        self._pool_rows: dict[str, dict[str, Any]] = {}
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew")
        ttk.Label(toolbar, text="Response pools").pack(side="left")
        ttk.Entry(toolbar, textvariable=self.filter_var, width=24).pack(
            side="left", padx=6)
        ttk.Button(toolbar, text="Search", command=self.search).pack(side="left")
        self._previous = ttk.Button(
            toolbar, text="Previous", command=self.previous_page)
        self._previous.pack(side="left", padx=(8, 0))
        self._next = ttk.Button(toolbar, text="Next", command=self.next_page)
        self._next.pack(side="left", padx=4)
        self._previous.configure(state="disabled")
        self._next.configure(state="disabled")
        ttk.Label(toolbar, textvariable=self.status_var).pack(
            side="left", padx=12)

        content = ttk.Panedwindow(self.frame, orient="horizontal")
        content.grid(row=1, column=0, sticky="nsew")
        left = ttk.Frame(content)
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self.pools = ttk.Treeview(
            left, columns=("variants", "canonical"),
            show="tree headings", selectmode="browse")
        self.pools.heading("#0", text="Semantic branch / pool")
        self.pools.heading("variants", text="Count")
        self.pools.heading("canonical", text="Canonical ID")
        self.pools.column("#0", width=360)
        self.pools.column("variants", width=80, stretch=False)
        self.pools.column("canonical", width=300)
        self.pools.grid(row=0, column=0, sticky="nsew")
        scroll = ttk.Scrollbar(left, orient="vertical", command=self.pools.yview)
        scroll.grid(row=0, column=1, sticky="ns")
        self.pools.configure(yscrollcommand=scroll.set)
        self.pools.bind("<<TreeviewSelect>>", self._selected)
        content.add(left, weight=2)

        right = ttk.Frame(content)
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self.tabs = ttk.Notebook(right)
        self.tabs.grid(row=0, column=0, sticky="nsew")
        self.views: dict[str, Any] = {}
        response_panel = ttk.Frame(self.tabs, padding=6)
        response_panel.rowconfigure(1, weight=1)
        response_panel.columnconfigure(0, weight=1)
        self.tabs.add(response_panel, text="Registered responses")
        controls = ttk.Frame(response_panel)
        controls.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        ttk.Label(
            controls,
            text="Static production registry metadata · selection context lives in Simulation",
        ).pack(side="left")
        ttk.Button(
            controls, text="Locale coverage", command=self.verify_translation_manifest
        ).pack(side="right", padx=4)
        ttk.Button(
            controls, text="Verify source owner", command=self.verify_source_lineage
        ).pack(side="right", padx=4)
        viewer = scrolled_text(
            response_panel, wrap="word", state="disabled", height=14
        )
        viewer.grid(row=1, column=0, sticky="nsew")
        self.views["Catalog"] = viewer
        self.views["Explore"] = viewer

        self._review_report: dict[str, Any] | None = None
        self.review_decision_var = tk.StringVar(value="Decision: pending review")
        self._review_decision_status = None
        if review_parent is not None:
            self._build_review_surface(review_parent, ttk, scrolled_text)
        else:
            self.views["Review"] = scrolled_text(
                self.frame, wrap="word", state="disabled", height=14
            )
        content.add(right, weight=3)
        self._display(
            "Explore",
            "Registered responses are read-only production metadata.\n"
            "Use Simulation → Inspect for context-specific selection explanations.\n"
            "Use Studio → Review for isolated candidate before/after evidence.",
        )

    def _build_review_surface(self, parent: Any, ttk: Any, scrolled_text: Any) -> None:
        """Build the human-readable candidate review home."""

        parent.rowconfigure(0, weight=1)
        parent.columnconfigure(0, weight=1)
        self.review_frame = ttk.Frame(parent, padding=8)
        self.review_frame.grid(row=0, column=0, sticky="nsew")
        self.review_frame.rowconfigure(1, weight=1)
        self.review_frame.columnconfigure(0, weight=1)
        toolbar = ttk.Frame(self.review_frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        ttk.Label(
            toolbar,
            text="Candidate source review · isolated replay only",
        ).pack(side="left")
        ttk.Button(
            toolbar, text="Open proposal…", command=self.preview_proposal
        ).pack(side="right")
        self.review_decision_status = ttk.Label(
            toolbar, textvariable=self.review_decision_var
        )
        self.review_decision_status.pack(side="right", padx=(0, 12))
        self.review_view = scrolled_text(
            self.review_frame, wrap="word", state="disabled"
        )
        self.review_view.grid(row=1, column=0, sticky="nsew")
        actions = ttk.Frame(self.review_frame)
        actions.grid(row=2, column=0, sticky="ew", pady=(6, 0))
        self.approve_button = ttk.Button(
            actions, text="Approve decision", command=self.approve_candidate
        )
        self.approve_button.pack(side="left")
        self.reject_button = ttk.Button(
            actions, text="Reject decision", command=self.reject_candidate
        )
        self.reject_button.pack(side="left", padx=(6, 0))
        self.views["Review"] = self.review_view
        self._display(
            "Review",
            "Select a proposal to see exact source, current and proposed localized wording, "
            "preserved runtime metadata, isolated Lua results, and effect parity.\n"
            "No review action writes production files by itself.",
        )

    def _display(self, view: str, value: str) -> None:
        widget = self.views[view]
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)
        widget.configure(state="disabled")

    def _review_text(self) -> str:
        if "Review" not in self.views:
            return ""
        return self.views["Review"].get("1.0", "end").strip()

    def show_dialogue_content_review(self, report: dict[str, Any]) -> None:
        """Show a content-only before/after review in the shared Review home."""

        self._review_report = report
        self.review_decision_var.set("Decision: pending review")
        before = report.get("contentBefore") or {}
        after = report.get("contentAfter") or {}
        lines = [
            f"Dialogue Content review: {report.get('contentID', 'UNKNOWN')}",
            f"Content kind: {report.get('kind', before.get('kind', 'UNKNOWN'))}",
            f"Canonical semantic owner: {before.get('semanticTemplateID', 'player-facing')}",
            f"Canonical concept: {before.get('canonicalConcept', 'UNKNOWN')}",
            f"Source fingerprint: {report.get('sourceFingerprint', 'UNKNOWN')}",
            f"Proposed content fingerprint: {report.get('contentFingerprint', report.get('newContentFingerprint', 'UNKNOWN'))}",
            "Structural metadata: PRESERVED / LOCKED",
            "Production writes: 0 · review decision does not publish by itself",
            "",
        ]
        if before.get("kind") == "phraseFamily":
            before_styles = before.get("styles") or {}
            after_styles = after.get("styles") or {}
            for style in sorted(before_styles):
                before_phrases = [
                    item for item in before_styles.get(style, [])
                    if isinstance(item, dict)
                ]
                after_phrases = [
                    item for item in after_styles.get(style, [])
                    if isinstance(item, dict)
                ]
                for index, item in enumerate(before_phrases, 1):
                    old = item.get("translations") or {}
                    replacement = (
                        after_phrases[index - 1]
                        if index <= len(after_phrases)
                        else {}
                    )
                    new = replacement.get("translations") or {}
                    phrase_id = (
                        item.get("id")
                        or replacement.get("id")
                        or f"{before.get('id', 'phrase')}.{style}.{index:02d}"
                    )
                    lines.extend([
                        f"{style} · {phrase_id}",
                        f"  EN: {old.get('EN', '(missing)')} -> {new.get('EN', '(missing)')}",
                        f"  TL: {old.get('TL', '(missing)')} -> {new.get('TL', '(missing)')}",
                    ])
        else:
            for field in ("labelTranslations", "choiceTranslations"):
                old = before.get(field) or {}
                new = after.get(field) or {}
                lines.extend([
                    f"{field}",
                    f"  EN: {old.get('EN', '(missing)')} -> {new.get('EN', '(missing)')}",
                    f"  TL: {old.get('TL', '(missing)')} -> {new.get('TL', '(missing)')}",
                ])
        lines.extend([
            "",
            "Semantic/content invariants:",
            f"  semanticTemplateID: {before.get('semanticTemplateID', '(player-facing)')}",
            f"  contentOwner: {before.get('contentOwner', '(derived)')}",
            "",
            "Approve or reject this wording proposal, then use the explicit",
            "Dialogue Content source/compile actions when authorized.",
        ])
        self._display("Review", "\n".join(lines))

    def _set_review_decision(self, decision: str) -> None:
        if self._review_report is None:
            self.review_decision_var.set("Decision: preview a candidate first")
            return
        self.review_decision_var.set(f"Decision: {decision}")
        current = self._review_text()
        suffix = f"\n\nExplicit review decision: {decision}\n"
        if "Explicit review decision:" in current:
            current = current.split("\n\nExplicit review decision:", 1)[0]
        self._display("Review", current + suffix)

    def approve_candidate(self) -> None:
        """Record an explicit review decision without authoring a source."""

        self._set_review_decision("APPROVE")

    def reject_candidate(self) -> None:
        """Record an explicit rejection without changing canonical sources."""

        self._set_review_decision("REJECT")

    def _submit(self, operation: Callable, callback: Callable) -> bool:
        if self.loading:
            self.status_var.set("Loading catalog…")
            return False
        self.loading = True
        self.status_var.set("Loading catalog…")

        # Keep the loading state local to this read-only surface.  The worker
        # adapter still runs through the serialized session queue, but no
        # foreground Simulation status/control is changed by the request.
        def finish(result: Any) -> None:
            self.loading = False

            callback(result)

        if not self._run_worker(operation, finish):
            self.loading = False
            self.status_var.set("Worker busy or not initialized")
            return False
        return True

    def search(self) -> None:
        if self.loading:
            return
        self._page_offset = 0
        self.refresh()

    def previous_page(self) -> None:
        if self.loading:
            return
        self._page_offset = max(0, self._page_offset - 64)
        self.refresh()

    def next_page(self) -> None:
        if self._has_more and not self.loading:
            self._page_offset += 64
            self.refresh()

    def refresh(self) -> bool:
        query = self.filter_var.get().strip()

        def request(worker: Any) -> dict[str, Any]:
            try:
                return worker.response_pool_list(
                    filter=query, offset=self._page_offset, limit=64
                )
            except Exception as error:  # keep catalog failures out of Simulation
                return {
                    "ok": False,
                    "catalogError": str(error)[:400],
                }

        return self._submit(request, self._on_list)

    def _on_list(self, result: dict[str, Any]) -> None:
        if result.get("ok") is False or result.get("catalogError"):
            self.catalog_ready = False
            self._has_more = False
            self._previous.configure(state="disabled")
            self._next.configure(state="disabled")
            self.status_var.set(
                "Catalog unavailable: "
                f"{result.get('catalogError') or 'production query failed'}. "
                "Use Search to retry."
            )
            return
        self.catalog_ready = True
        self._has_more = bool(result.get("hasMore"))
        self._previous.configure(
            state="normal" if self._page_offset > 0 else "disabled")
        self._next.configure(state="normal" if self._has_more else "disabled")
        rows = [pool for pool in result.get("pools", []) if isinstance(pool, dict)]
        self._pool_rows = {str(pool.get("id")): pool for pool in rows}
        self._render_pool_tree(rows)
        self.status_var.set(
            f"{len(result.get('pools', []))}/{result.get('total', 0)} pools "
            f"(revision {result.get('registryRevision', '?')})"
            + (" · filtered/page-limited" if result.get("hasMore") else "")
        )

    def _render_pool_tree(self, rows: list[dict[str, Any]]) -> None:
        """Render the current bounded page through the shared ID projection."""

        query = self.filter_var.get().strip()
        tree = filter_semantic_tree(
            build_semantic_tree(rows, id_getter=lambda row: str(row.get("id", ""))),
            query,
        )
        self.pools.delete(*self.pools.get_children())

        def insert(node: dict[str, Any], parent: str = "") -> None:
            for key in sorted(node.get("children", {}), key=str.casefold):
                child = node["children"][key]
                iid = "branch:" + str(child["key"])
                self.pools.insert(
                    parent,
                    "end",
                    iid=iid,
                    text=f"{child['label']} ({child['count']})",
                    values=(child["count"], ""),
                    open=(not query or child["key"] in tree.get("expanded", set())),
                )
                for item in sorted(
                    child.get("items", []),
                    key=lambda value: str(value.get("id", "")).casefold(),
                ):
                    pool_id = str(item.get("id", ""))
                    self.pools.insert(
                        iid,
                        "end",
                        iid="pool:" + pool_id,
                        text=str(pool_id.rsplit(".", 1)[-1]),
                        values=(item.get("variantCount", 0), pool_id),
                    )
                insert(child, iid)

        insert(tree)

    def _selected(self, _event: Any = None) -> None:
        selection = self.pools.selection()
        if not selection:
            return
        iid = selection[0]
        if not iid.startswith("pool:"):
            self._show_branch(iid[len("branch:"):])
            return
        self.selected_pool = iid[len("pool:"):]
        self._submit(
            lambda worker: worker.response_pool_detail(
                self.selected_pool, limit=16),
            self._on_detail,
        )

    def _show_branch(self, key: str) -> None:
        """Keep branch selection useful without issuing a detail request."""

        label = key.rsplit(".", 1)[-1].replace("_", " ").title()
        descendants = [
            row for row_id, row in self._pool_rows.items()
            if row_id == key or row_id.startswith(key + ".")
        ]
        self._display(
            "Explore",
            f"Semantic branch: {label}\n"
            f"Canonical branch ID: {key}\n"
            f"Descendant pools on this bounded page: {len(descendants)}\n\n"
            "Select a leaf pool to load its bounded production detail.",
        )

    def _on_detail(self, result: dict[str, Any]) -> None:
        lines = [
            f"Pool: {result['poolID']}",
            f"Loaded variants: {result['variantCount']}",
            f"Registration revision: {result.get('registryRevision', '?')}",
            f"Registry content marker: {result.get('contentFingerprint', 'UNKNOWN')}",
            f"Registration source: {result.get('sourcePath', 'UNKNOWN')}",
            "",
        ]
        lineage = result.get("generatedActionLineage") or {}
        if lineage:
            lines.extend((
                f"Generated capability: {lineage.get('capabilityID', 'UNKNOWN')}",
                f"Canonical action descriptor: "
                f"{lineage.get('verifiedCanonicalActionPath', 'UNKNOWN')}",
                f"Verified descriptor owner: "
                f"{lineage.get('canonicalOwnerVerified', False)}",
                "",
            ))
        for variant in result.get("variants", []):
            checks = variant.get("when") or {}
            lines += [
                f"{variant['id']} · priority {variant.get('priority', 0)}",
                f"  Template: {variant.get('templateID', 'UNKNOWN')}",
                f"  Conditions: {checks if checks else 'none'}",
                f"  Fallback: {variant.get('fallback', '')}",
                f"  Plan: {variant.get('planSummary', {})}",
                "",
            ]
        self._display("Explore", "\n".join(lines))
        self._display(
            "Review",
            "Selected source context:\n"
            + "Source path: " + str(result.get("sourcePath", "UNKNOWN"))
            + "\nCanonical owner must be verified before any patch.\n"
            + "No edits or game commands are issued by inspection.",
        )

    def preview_proposal(self) -> None:
        if self._filedialog is None or self._repository is None:
            self.status_var.set("No source/review dialog configured")
            return
        selected = self._filedialog.askopenfilename(
            title="Select read-only localized candidate proposal",
            filetypes=[("JSON proposal", "*.json")],
        )
        if not selected:
            return
        path = Path(selected)
        if not path.is_file() or path.stat().st_size > 16 * 1024:
            self.status_var.set("Proposal missing or larger than 16 KiB")
            return
        try:
            proposal = json.loads(path.read_text(encoding="utf-8"))
        except (ValueError, UnicodeError, OSError) as error:
            self.status_var.set(f"Proposal unreadable: {error}")
            return
        if not isinstance(proposal, dict):
            self.status_var.set("Proposal must be a JSON object")
            return
        self._display("Review", "Running isolated production Lua replay; "
                      "production files remain untouched.")
        self._submit(
            lambda worker: preview_authored_variant(
                proposal, repository=self._repository,
            ),
            self._on_candidate_preview,
        )

    def _on_candidate_preview(self, report: dict[str, Any]) -> None:
        self._review_report = report
        self.review_decision_var.set("Decision: pending review")
        lines = [
            f"Isolated production Lua preview: {report['variantID']}",
            f"Response family: {report.get('poolID', 'UNKNOWN')}",
            f"Verified authored source: {report.get('sourcePath', 'UNKNOWN')}",
            f"Original source SHA-256: {report.get('sourceSHA256', 'UNKNOWN')}",
            f"Baseline fingerprint: {report.get('baselineFingerprint', 'UNKNOWN')}",
            f"Candidate fingerprint: {report.get('candidateFingerprint', 'UNKNOWN')}",
            "Approval: NOT GRANTED — record an explicit decision after review.",
            "Production writes: 0 · candidate overlay cleaned",
            "",
        ]
        contract = report.get("variantContract") or {}
        lines.extend([
            "Static contract invariants:",
            f"  Conditions: {contract.get('conditions', 'UNKNOWN')}",
            f"  Priority: {contract.get('priority', 'UNKNOWN')}",
            f"  Plan: {contract.get('plan', 'UNKNOWN')}",
            f"  Selection / authority route: "
            f"{contract.get('selectionSource', 'UNKNOWN')}",
            f"  Source status: {contract.get('sourceKind', 'UNKNOWN')} · "
            f"{contract.get('sourcePath', report.get('sourcePath', 'UNKNOWN'))}",
            "",
        ])
        for row in report["languageCases"]:
            original = row["baseline"]["messages"]
            updated = row["candidate"]["messages"]
            lines += [
                f"{row['language']} — {row['status']}",
                f"  Before: {original[0]['text'] if original else '(none)'}",
                f"  After:  {updated[0]['text'] if updated else '(none)'}",
                f"  Actions: {row['baseline']['actionCount']} -> "
                f"{row['candidate']['actionCount']}",
                f"  Transport: {row['baseline'].get('transportCount', 0)} -> "
                f"{row['candidate'].get('transportCount', 0)}",
                "",
            ]
        checks = report.get("checks") or {}
        lines.extend([
            "Preserved invariants / effect parity:",
            f"  Gameplay effects unchanged: {checks.get('unchangedGameplayEffects', 'UNKNOWN')}",
            f"  Selection metadata unchanged: {checks.get('unchangedSelectionMetadata', 'UNKNOWN')}",
            f"  Selected key / authority unchanged: {checks.get('sameSelectedKey', 'UNKNOWN')}",
            f"  Source SHA guard: {report.get('sourceSHA256GuardMatched', 'not supplied')}",
            f"  Translation source hashes: {report.get('translationSourceSHA256', 'UNKNOWN')}",
            "",
        ])
        lines += ["Lua source diff (preview only):", *report["sourceDiff"][:64]]
        self._display("Review", "\n".join(lines))

    def verify_translation_manifest(self) -> None:
        if not self.selected_pool:
            self.status_var.set("Select a registered pool first")
            return
        selected = self.selected_pool
        self._submit(
            lambda worker: translation_coverage(worker, selected),
            self._on_translation_coverage,
        )

    def _on_translation_coverage(self, report: dict[str, Any]) -> None:
        languages = report.get("languages") or []
        lines = [
            f"Canonical locale manifests: {report['poolID']}",
            "Static manifest membership, not runtime translation evidence.",
            "Not in manifest does not imply untranslated in actual dialogue.",
            "Locales: " + ", ".join(languages),
            "",
        ]
        for variant in report.get("variants", []):
            paths = variant.get("manifestAssets") or {}
            lines.extend((
                f"{variant['variantID']} · {variant['status']}",
                f"  Template: {variant['templateID']}",
            ))
            for language in languages:
                lines.append(
                    f"  {language}: "
                    + (", ".join(paths.get(language, [])) or "NOT MANIFESTED")
                )
            lines.append("")
        self._display("Explore", "\n".join(lines))
        self._display("Review", "\n".join(lines))


    def verify_source_lineage(self) -> None:
        if not self.selected_pool:
            self.status_var.set("Select a registered pool first")
            return
        selected = self.selected_pool
        self._submit(
            lambda worker: inspect_codebuilder_lineage(worker, selected),
            self._on_codebuilder_lineage,
        )

    def _on_codebuilder_lineage(self, report: dict[str, Any]) -> None:
        lines = [
            f"Verified CodeBuilder variant sources: {report['poolID']}",
            f"Canonical matches: {report.get('verifiedVariantCount', 0)}/"
            f"{report.get('variantCount', '?')}",
            "Only per-variant compiler+loaded-Lua matches are authoritative.",
            "Not verified does not prove missing or broken sources.",
            "No source files are written; explicit approval still required.",
            "",
        ]
        for owner in report.get("sourceOwners", []):
            source = owner.get("canonicalSource") or {}
            lines.extend((
                f"{owner['variantID']}: {owner['reason']}",
                f"  Source: {source.get('sourcePath', 'UNKNOWN')}",
                f"  Generator parity: "
                f"{source.get('generatedArtifactParity', 'UNKNOWN')}",
                "",
            ))
        self._display("Explore", "\n".join(lines))
        self._display("Review", "\n".join(lines))


__all__ = ["SemanticObservatoryPane"]
