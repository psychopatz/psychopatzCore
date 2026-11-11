"""Tk Dataset Library over the shared Semantic Lab authoring service."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


_INTEGRATION_STATUS_FIELDS = (
    "imported",
    "mapped",
    "approved",
    "compiled",
    "workerVerified",
)


def _integration_status(document: dict[str, Any]) -> dict[str, int]:
    source = document.get("source") if isinstance(document.get("source"), dict) else {}
    references = source.get("references") if isinstance(source.get("references"), list) else []
    totals = {field: 0 for field in _INTEGRATION_STATUS_FIELDS}
    for reference in references:
        if not isinstance(reference, dict):
            continue
        status = reference.get("importStatus")
        if not isinstance(status, dict):
            continue
        for field in _INTEGRATION_STATUS_FIELDS:
            value = status.get(field)
            if isinstance(value, int) and not isinstance(value, bool) and value >= 0:
                totals[field] += value
    return totals


def _status_text(source_id: str, document: dict[str, Any]) -> str:
    status = _integration_status(document)
    if not any(status.values()):
        return f"Editing {source_id}; write requires explicit approval"
    return (
        f"Editing {source_id} · imported {status['imported']} · "
        f"mapped {status['mapped']} · approved {status['approved']} · "
        f"compiled {status['compiled']} · worker verified {status['workerVerified']}"
    )


class DatasetLibraryPane:
    """Browse, search, validate, and explicitly edit canonical JSON sources."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: SemanticLabAuthoringService,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self.service = service
        self.frame = ttk.Frame(parent)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)
        self._search_var = tk.StringVar()
        self._status_var = tk.StringVar(value="Loading canonical dataset catalog…")
        self._items: list[dict[str, Any]] = []

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Entry(toolbar, textvariable=self._search_var).grid(
            row=0, column=0, sticky="ew",
        )
        ttk.Button(toolbar, text="Search", command=self.search).grid(
            row=0, column=1, padx=(6, 0),
        )
        ttk.Button(toolbar, text="Refresh", command=self.refresh).grid(
            row=0, column=2, padx=(6, 0),
        )
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=0, column=3, padx=(12, 0), sticky="e",
        )

        left = ttk.LabelFrame(self.frame, text="Canonical sources and entries")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._listbox = tk.Listbox(left, width=42, exportselection=False)
        self._listbox.grid(row=0, column=0, sticky="nsew")
        self._listbox.bind("<<ListboxSelect>>", lambda _event: self.load_selected())
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self._listbox.configure(yscrollcommand=scrollbar.set)

        right = ttk.LabelFrame(self.frame, text="Definition editor · JSON draft")
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._editor = scrolled_text(right, wrap="none")
        self._editor.grid(row=0, column=0, sticky="nsew")
        buttons = ttk.Frame(right)
        buttons.grid(row=1, column=0, sticky="ew", pady=(6, 0))
        ttk.Button(buttons, text="Load selected", command=self.load_selected).pack(side="left")
        ttk.Button(buttons, text="Validate draft", command=self.validate_draft).pack(
            side="left", padx=6,
        )
        ttk.Button(buttons, text="Write canonical…", command=self.write_canonical).pack(
            side="left",
        )
        self.refresh()

    def _set_editor(self, value: Any) -> None:
        self._editor.configure(state="normal")
        self._editor.delete("1.0", "end")
        self._editor.insert("1.0", json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def _selected_item(self) -> dict[str, Any] | None:
        selection = self._listbox.curselection()
        if not selection:
            return None
        return self._items[selection[0]]

    def _selected_source_id(self) -> str | None:
        item = self._selected_item()
        return str(item["sourceID"]) if item else None

    def refresh(self) -> None:
        self._items = [
            {
                "sourceID": source["id"],
                "kind": "source",
                "label": f"{source['label']} · {source['kind']}",
                "path": source["path"],
            }
            for source in self.service.list_dataset_sources()
        ]
        self._render_items()
        self._status_var.set(f"{len(self._items)} canonical sources")

    def search(self) -> None:
        query = self._search_var.get().strip()
        if not query:
            self.refresh()
            return
        self._items = self.service.search_dataset(query, limit=64)
        self._render_items()
        self._status_var.set(f"{len(self._items)} matches for {query!r}")

    def _render_items(self) -> None:
        self._listbox.delete(0, "end")
        for item in self._items:
            if item.get("kind") == "source":
                label = item["label"]
            else:
                label = f"{item['sourceID']} · {item['kind']} · {item['id']}"
            self._listbox.insert("end", label)
        if self._items:
            self._listbox.selection_set(0)
            self.load_selected()

    def load_selected(self) -> None:
        source_id = self._selected_source_id()
        if not source_id:
            return
        try:
            document = self.service.load_dataset_document(source_id)
        except (OSError, ValueError) as error:
            self._status_var.set(f"Load failed: {error}")
            return
        self._set_editor(document)
        self._status_var.set(_status_text(source_id, document))

    def _draft_document(self) -> dict[str, Any] | None:
        try:
            document = json.loads(self._editor.get("1.0", "end"))
        except json.JSONDecodeError as error:
            self._status_var.set(f"Invalid JSON: {error}")
            return None
        if not isinstance(document, dict):
            self._status_var.set("Dataset root must be a JSON object")
            return None
        return document

    def validate_draft(self) -> dict[str, Any] | None:
        source_id = self._selected_source_id()
        document = self._draft_document()
        if not source_id or document is None:
            return None
        report = self.service.preview_dataset_edit(source_id, document)
        if report.get("ok") is True:
            self._status_var.set(f"{source_id} valid; no files written")
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
            self._status_var.set(f"{source_id} rejected: {message}")
        return report

    def write_canonical(self) -> dict[str, Any] | None:
        source_id = self._selected_source_id()
        document = self._draft_document()
        if not source_id or document is None:
            return None
        report = self.service.preview_dataset_edit(source_id, document)
        if report.get("ok") is not True:
            self.validate_draft()
            return report
        if not self._messagebox.askyesno(
            "Write canonical dataset",
            f"Write the validated {source_id} definition to its canonical JSON source?",
        ):
            self._status_var.set("Write cancelled; draft remains in the editor")
            return report
        written = self.service.write_dataset_document(source_id, document)
        if written.get("ok") is True:
            self._status_var.set(f"Wrote {source_id}; regenerate artifacts explicitly")
        return written
