"""Human-facing Dialogue Content Registry editor.

This pane is intentionally narrower than the Advanced authoring tools.  It
can edit only ordinary EN/TL wording and always shows the structural fields
that remain owned by ResponseCatalog, navigation, and authority services.
"""

from __future__ import annotations

import json
from typing import Any, Callable

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from .semantic_tree import build_semantic_tree, filter_semantic_tree


class DialogueContentPane:
    """Browse and safely edit compiled phrase/player-facing content."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: SemanticLabAuthoringService,
        *,
        on_preview_simulation: Callable[[dict[str, Any]], Any] | None = None,
        on_send_review: Callable[[dict[str, Any]], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self.service = service
        self.on_preview_simulation = on_preview_simulation
        self.on_send_review = on_send_review
        self.frame = ttk.Frame(parent)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)
        self._status_var = tk.StringVar(
            value="Click Refresh to load verified dialogue content"
        )
        self._items: list[dict[str, Any]] = []
        self._tree_rows: dict[str, dict[str, Any]] = {}
        self._selected: dict[str, Any] | None = None
        self._source_fingerprint: str | None = None
        self._filter_var = tk.StringVar(value="")

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Label(
            toolbar,
            text="Phrase wording and verified player-facing labels only; routes, plans, and authority are locked.",
        ).grid(row=0, column=0, sticky="w")
        ttk.Button(toolbar, text="Refresh", command=self.refresh).grid(
            row=0, column=1, padx=(8, 0)
        )
        ttk.Label(toolbar, text="Filter").grid(row=0, column=2, padx=(12, 4))
        ttk.Entry(toolbar, textvariable=self._filter_var, width=24).grid(
            row=0, column=3, sticky="ew"
        )
        ttk.Button(toolbar, text="Search", command=self._render_tree).grid(
            row=0, column=4, padx=(4, 0)
        )
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=0, column=5, padx=(12, 0), sticky="e"
        )
        toolbar.columnconfigure(3, weight=1)

        left = ttk.LabelFrame(self.frame, text="Verified content families")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._tree = ttk.Treeview(
            left,
            columns=("count", "canonical"),
            show="tree headings",
            selectmode="browse",
        )
        self._tree.heading("#0", text="Semantic branch / family")
        self._tree.heading("count", text="Count")
        self._tree.heading("canonical", text="Canonical ID")
        self._tree.column("#0", width=270)
        self._tree.column("count", width=60, stretch=False)
        self._tree.column("canonical", width=280)
        self._tree.grid(row=0, column=0, sticky="nsew")
        self._tree.bind("<<TreeviewSelect>>", lambda _event: self.load_selected())
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._tree.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        scrollbar.configure(command=self._tree.yview)
        self._tree.configure(yscrollcommand=scrollbar.set)

        right = ttk.Frame(self.frame)
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(1, weight=1)
        right.columnconfigure(0, weight=1)
        locked = ttk.LabelFrame(right, text="Locked semantic / gameplay invariants")
        locked.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        locked.columnconfigure(0, weight=1)
        self._locked_text = scrolled_text(locked, height=8, wrap="word")
        self._locked_text.grid(row=0, column=0, sticky="ew")
        self._locked_text.configure(state="disabled")

        editable = ttk.LabelFrame(right, text="Editable EN/TL content draft")
        editable.grid(row=1, column=0, sticky="nsew")
        editable.rowconfigure(0, weight=1)
        editable.columnconfigure(0, weight=1)
        self._editor = scrolled_text(editable, wrap="none")
        self._editor.grid(row=0, column=0, sticky="nsew")
        buttons = ttk.Frame(editable)
        buttons.grid(row=1, column=0, sticky="ew", pady=(6, 0))
        ttk.Button(buttons, text="Validate content", command=self.validate_draft).pack(side="left")
        ttk.Button(buttons, text="Preview in Simulation", command=self.preview_in_simulation).pack(
            side="left", padx=6
        )
        ttk.Button(buttons, text="Send to Review", command=self.send_to_review).pack(side="left")
        ttk.Button(buttons, text="Write source…", command=self.write_content).pack(
            side="left", padx=6
        )
        ttk.Button(
            buttons,
            text="Compile artifacts",
            command=self.compile_artifacts,
        ).pack(side="left")

    @staticmethod
    def _display_label(item: dict[str, Any]) -> str:
        kind = "phrase family" if item.get("kind") == "phraseFamily" else "player choice"
        return f"{kind} · {item.get('id', '<missing>')}"

    def refresh(self) -> None:
        try:
            self._items = self.service.list_dialogue_content()
        except (OSError, ValueError, KeyError) as error:
            self._items = []
            self._tree_rows = {}
            self._status_var.set(f"Content load failed: {error}")
            return
        self._render_tree()
        self._status_var.set(
            f"{len(self._items)} verified content records · select a row to inspect"
        )

    def select_content(self, content_ref: str) -> bool:
        """Select a canonical content record by ID or semantic template ID."""

        content_ref = str(content_ref or "").strip()
        if not content_ref:
            return False
        if not self._items:
            self.refresh()
        match = next(
            (
                item
                for item in self._items
                if str(item.get("id") or "") == content_ref
                or str(item.get("semanticTemplateID") or "") == content_ref
            ),
            None,
        )
        if not isinstance(match, dict):
            self._status_var.set(f"Dialogue Content not found: {content_ref}")
            return False

        # Clear a filter that may hide the requested canonical record.
        if self._filter_var.get().strip():
            self._filter_var.set("")
            self._render_tree()

        match_id = str(match.get("id") or "")
        target_iid = next(
            (
                iid
                for iid, item in self._tree_rows.items()
                if str(item.get("id") or "") == match_id
            ),
            None,
        )
        if target_iid is None:
            self._render_tree()
            target_iid = next(
                (
                    iid
                    for iid, item in self._tree_rows.items()
                    if str(item.get("id") or "") == match_id
                ),
                None,
            )
        if target_iid is None:
            self._status_var.set(f"Dialogue Content row unavailable: {content_ref}")
            return False

        self._tree.selection_set(target_iid)
        self._tree.focus(target_iid)
        self._tree.see(target_iid)
        self.load_selected()
        return True

    def _render_tree(self) -> None:
        tree = filter_semantic_tree(
            build_semantic_tree(
                self._items,
                id_getter=lambda item: str(
                    item.get("semanticTemplateID") or item.get("id") or ""
                ),
            ),
            self._filter_var.get(),
        )
        self._tree_rows = {}
        self._tree.delete(*self._tree.get_children())

        def insert(node: dict[str, Any], parent: str = "") -> None:
            for key in sorted(node.get("children", {}), key=str.casefold):
                child = node["children"][key]
                iid = "branch:" + str(child["key"])
                self._tree.insert(
                    parent,
                    "end",
                    iid=iid,
                    text=f"{child['label']} ({child['count']})",
                    values=(child["count"], ""),
                    open=(
                        not self._filter_var.get().strip()
                        or child["key"] in tree.get("expanded", set())
                    ),
                )
                for index, item in enumerate(
                    sorted(
                        child.get("items", []),
                        key=lambda value: str(
                            value.get("semanticTemplateID")
                            or value.get("id") or ""
                        ).casefold(),
                    )
                ):
                    content_id = str(item.get("id") or f"item-{index}")
                    iid = "content:" + content_id
                    self._tree_rows[iid] = item
                    self._tree.insert(
                        "branch:" + str(child["key"]),
                        "end",
                        iid=iid,
                        text=self._display_label(item),
                        values=(1, str(item.get("semanticTemplateID") or content_id)),
                    )
                insert(child, "branch:" + str(child["key"]))

        insert(tree)

    def _set_text(self, widget: Any, value: str, *, disabled: bool = False) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)
        if disabled:
            widget.configure(state="disabled")

    def _selected_id(self) -> str | None:
        selection = self._tree.selection()
        if not selection:
            return None
        item = self._tree_rows.get(selection[0])
        return str(item.get("id")) if item else None

    def load_selected(self) -> None:
        content_id = self._selected_id()
        if not content_id:
            return
        try:
            item = self.service.load_dialogue_content(content_id)
        except (OSError, ValueError, KeyError) as error:
            self._status_var.set(f"Content load failed: {error}")
            return
        self._selected = item
        self._source_fingerprint = item.get("sourceFingerprint")
        locked = {
            key: value
            for key, value in item.items()
            if key in {
                "id", "kind", "semanticTemplateID", "canonicalConcept", "group",
                "contentOwner", "route", "hubID", "labelKey", "choiceKey",
                "verifiedOwner",
            }
        }
        self._set_text(
            self._locked_text,
            json.dumps(locked, ensure_ascii=False, indent=2) + "\n",
            disabled=True,
        )
        self._set_text(
            self._editor,
            json.dumps(item, ensure_ascii=False, indent=2) + "\n",
        )
        self._status_var.set(
            f"Editing {content_id}; structural fields locked; source fingerprint guarded"
        )

    def _draft(self) -> dict[str, Any] | None:
        try:
            value = json.loads(self._editor.get("1.0", "end"))
        except json.JSONDecodeError as error:
            self._status_var.set(f"Invalid JSON draft: {error}")
            return None
        if not isinstance(value, dict):
            self._status_var.set("Content draft must be an object")
            return None
        return value

    def validate_draft(self) -> dict[str, Any] | None:
        content_id = self._selected_id()
        draft = self._draft()
        if not content_id or draft is None:
            return None
        report = self.service.preview_dialogue_content_edit(
            content_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        if report.get("ok") is True:
            self._status_var.set("Content valid; no files written; stale guard passed")
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else report.get("reason", "invalid content")
            self._status_var.set(f"Content rejected: {message}")
        return report

    def preview_in_simulation(self) -> dict[str, Any] | None:
        report = self.validate_draft()
        if report and report.get("ok") is True:
            self._status_var.set("Preview delegated to Simulation; no Studio runner is owned here")
            if self.on_preview_simulation:
                self.on_preview_simulation(report)
        return report

    def send_to_review(self) -> dict[str, Any] | None:
        report = self.validate_draft()
        if report and report.get("ok") is True:
            self._status_var.set("Validated content proposal sent to Review")
            if self.on_send_review:
                self.on_send_review(report)
        return report

    def write_content(self) -> dict[str, Any] | None:
        content_id = self._selected_id()
        draft = self._draft()
        if not content_id or draft is None:
            return None
        report = self.validate_draft()
        if not report or report.get("ok") is not True:
            return report
        if not self._messagebox.askyesno(
            "Write dialogue content source",
            "Write only the validated EN/TL wording to the canonical content source?",
        ):
            self._status_var.set("Write cancelled; draft remains in the editor")
            return report
        written = self.service.write_dialogue_content_edit(
            content_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        if written.get("ok") is True:
            self._status_var.set(
                "Canonical content source written; review it, then compile artifacts explicitly"
            )
            self.refresh()
        return written

    def compile_artifacts(self) -> dict[str, Any]:
        """Compile the reviewed canonical source through the shared CodeBuilder."""

        if not self._messagebox.askyesno(
            "Compile dialogue content",
            "Compile the current canonical EN/TL content source into runtime artifacts?",
        ):
            self._status_var.set("Compile cancelled; canonical source unchanged")
            return {"ok": False, "cancelled": True, "writes": []}
        report = self.service.generate_dialogue_content_source()
        if report.get("ok") is True:
            self._status_var.set(
                f"Compiled {len(report.get('writes', []))} Dialogue Content artifacts"
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "compile failed"
            self._status_var.set(f"Content compile rejected: {message}")
        return report
