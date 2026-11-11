"""Read-only canonical/source discovery for Studio Explore.

Explore answers where semantic content comes from. It deliberately exposes
metadata only; wording editing remains in Dialogue Content and structural
editing remains behind Developer Tools.
"""

from __future__ import annotations

import json
from typing import Any


class CanonicalSourceExplorerPane:
    """Browse verified canonical dataset/source metadata without editing it."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        service: Any,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self.service = service
        self._rows: list[dict[str, Any]] = []
        self._query = tk.StringVar()
        self._status = tk.StringVar(value="Loading canonical sources…")

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Entry(toolbar, textvariable=self._query).grid(
            row=0, column=0, sticky="ew"
        )
        ttk.Button(toolbar, text="Search sources", command=self.search).grid(
            row=0, column=1, padx=(6, 0)
        )
        ttk.Button(toolbar, text="Refresh", command=self.refresh).grid(
            row=0, column=2, padx=(6, 0)
        )
        ttk.Label(toolbar, textvariable=self._status).grid(
            row=0, column=3, padx=(12, 0), sticky="e"
        )

        left = ttk.LabelFrame(self.frame, text="Canonical and generated sources")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._listbox = tk.Listbox(left, width=42, exportselection=False)
        self._listbox.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self._listbox.configure(yscrollcommand=scrollbar.set)
        self._listbox.bind("<<ListboxSelect>>", lambda _event: self.show_selected())

        right = ttk.LabelFrame(self.frame, text="Verified ownership and coverage")
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._detail = scrolled_text(right, wrap="none", state="disabled")
        self._detail.grid(row=0, column=0, sticky="nsew")
        self.refresh()

    def refresh(self) -> None:
        self._rows = [
            {
                "kind": "source",
                "sourceID": source.get("id"),
                "label": source.get("label") or source.get("id"),
                "sourceKind": source.get("kind", "UNKNOWN"),
                "path": source.get("path", "UNKNOWN"),
                "exists": source.get("exists", False),
                "editable": source.get("editable", False),
                "ownerStatus": "CANONICAL_SOURCE" if source.get("exists") else "MISSING",
            }
            for source in self.service.list_dataset_sources()
            if isinstance(source, dict)
        ]
        content_path = getattr(self.service, "dialogue_content_source_path", None)
        if content_path is not None and content_path.is_file():
            self._rows.append({
                "kind": "source",
                "sourceID": "dialogue_content_registry",
                "label": "Dialogue Content Registry",
                "sourceKind": "dialogue_content",
                "path": str(content_path),
                "exists": True,
                "editable": True,
                "ownerStatus": "CANONICAL_SOURCE",
                "editableIn": "Studio → Dialogue Content",
            })
        self._render_rows()
        self._status.set(f"{len(self._rows)} canonical sources")

    def search(self) -> None:
        query = self._query.get().strip()
        if not query:
            self.refresh()
            return
        self.refresh()
        needle = query.lower()
        self._rows = [
            row for row in self._rows
            if needle in json.dumps(row, ensure_ascii=False, sort_keys=True).lower()
        ]
        self._render_rows()
        self._status.set(f"{len(self._rows)} matches for {query!r}")

    def _render_rows(self) -> None:
        self._listbox.delete(0, "end")
        for row in self._rows:
            if row.get("kind") == "source":
                label = f"{row.get('label')} · {row.get('sourceKind')}"
            else:
                label = (
                    f"{row.get('sourceID', 'UNKNOWN')} · "
                    f"{row.get('kind', 'entry')} · {row.get('id', 'UNKNOWN')}"
                )
            self._listbox.insert("end", label)
        if self._rows:
            self._listbox.selection_set(0)
            self.show_selected()
        else:
            self._set_detail({"ok": True, "rows": [], "message": "No matching sources"})

    def show_selected(self) -> None:
        selection = self._listbox.curselection()
        if not selection or selection[0] >= len(self._rows):
            return
        row = self._rows[selection[0]]
        if row.get("kind") == "source":
            detail = {
                "sourceID": row.get("sourceID"),
                "sourceKind": row.get("sourceKind", "UNKNOWN"),
                "label": row.get("label"),
                "path": row.get("path", "UNKNOWN"),
                "exists": row.get("exists", False),
                "verifiedOwner": row.get("ownerStatus") == "CANONICAL_SOURCE",
                "editableIn": row.get(
                    "editableIn", "Studio → Developer Tools…"
                ),
                "execution": "Simulation",
            }
        else:
            detail = {
                "entry": row,
                "sourceOwner": row.get("sourceID", "UNKNOWN"),
                "sourcePath": row.get("path", "UNKNOWN"),
                "note": "Explore is read-only; context-specific selection belongs in Simulation.",
            }
        self._set_detail(detail)

    def _set_detail(self, value: Any) -> None:
        self._detail.configure(state="normal")
        self._detail.delete("1.0", "end")
        self._detail.insert(
            "1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
        )
        self._detail.configure(state="disabled")

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        self._listbox.configure(state=state)


__all__ = ["CanonicalSourceExplorerPane"]
