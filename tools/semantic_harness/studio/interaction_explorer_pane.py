"""Tk interaction explorer backed by the live production FlowEditor catalog."""

from __future__ import annotations

import json
from typing import Any, Callable

from tools.semantic_harness.codebuilder.interaction_explorer import search_interactions


class InteractionExplorerPane:
    """Search policy, Core, flow, capability, generated, and response rows."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        service: Any,
        *,
        on_open_flow: Callable[[str], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self.service = service
        self._on_open_flow = on_open_flow
        self._catalog: dict[str, Any] = {}
        self._rows: list[dict[str, Any]] = []
        self._query = tk.StringVar()
        self._kind = tk.StringVar(value="all")
        self._status = tk.StringVar(value="Waiting for the live Lua catalog…")

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Entry(toolbar, textvariable=self._query).grid(row=0, column=0, sticky="ew")
        self._kind_box = ttk.Combobox(
            toolbar,
            textvariable=self._kind,
            state="readonly",
            width=18,
            values=("all",),
        )
        self._kind_box.grid(row=0, column=1, padx=(6, 0))
        ttk.Button(toolbar, text="Search", command=self.search).grid(
            row=0, column=2, padx=(6, 0)
        )
        ttk.Button(toolbar, text="Refresh live", command=self.refresh).grid(
            row=0, column=3, padx=(6, 0)
        )
        ttk.Label(toolbar, textvariable=self._status).grid(
            row=0, column=4, padx=(12, 0), sticky="e"
        )

        left = ttk.LabelFrame(self.frame, text="Production interactions")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._listbox = tk.Listbox(left, width=46, exportselection=False)
        self._listbox.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self._listbox.configure(yscrollcommand=scrollbar.set)
        self._listbox.bind("<<ListboxSelect>>", lambda _event: self.show_selected())

        right = ttk.LabelFrame(self.frame, text="Actual execution route")
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._detail = scrolled_text(right, wrap="none", state="disabled")
        self._detail.grid(row=0, column=0, sticky="nsew")
        self._open_flow_button = ttk.Button(
            right, text="Open registered flow", command=self.open_flow
        )
        self._open_flow_button.grid(row=1, column=0, sticky="e", pady=(6, 0))
        self._open_flow_button.configure(state="disabled")

    def set_catalog(self, catalog: dict[str, Any] | None) -> None:
        self._catalog = catalog if isinstance(catalog, dict) else {}
        kinds = sorted({
            str(row.get("kind"))
            for row in self.service.list_interactions(self._catalog)
            if isinstance(row, dict) and row.get("kind")
        })
        self._kind_box.configure(values=("all", *kinds))
        if self._kind.get() not in {"all", *kinds}:
            self._kind.set("all")
        self.search()

    def refresh(self) -> None:
        self.search()

    def search(self) -> None:
        rows = search_interactions(self._catalog, self._query.get().strip(), limit=256)
        selected_kind = self._kind.get().strip()
        if selected_kind and selected_kind != "all":
            rows = [row for row in rows if row.get("kind") == selected_kind]
        self._rows = rows
        self._listbox.delete(0, "end")
        for row in rows:
            self._listbox.insert(
                "end",
                f"{row.get('kind', '?')} · {row.get('label', row.get('id', '?'))}",
            )
        self._status.set(f"{len(rows)} live interaction rows")
        if rows:
            self._listbox.selection_set(0)
            self.show_selected()
        else:
            self._set_detail({"ok": True, "rows": [], "message": "No matching interactions"})
            self._open_flow_button.configure(state="disabled")

    def show_selected(self) -> None:
        selection = self._listbox.curselection()
        if not selection or selection[0] >= len(self._rows):
            return
        row = self._rows[selection[0]]
        self._set_detail(row)
        flow_id = row.get("flowID") if isinstance(row, dict) else None
        self._open_flow_button.configure(
            state="normal" if flow_id and self._on_open_flow else "disabled"
        )

    def open_flow(self) -> None:
        selection = self._listbox.curselection()
        if not selection or selection[0] >= len(self._rows) or not self._on_open_flow:
            return
        flow_id = self._rows[selection[0]].get("flowID")
        if flow_id:
            self._on_open_flow(str(flow_id))

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
        self._open_flow_button.configure(state=state if self._rows else "disabled")
