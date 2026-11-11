"""Tk browser for the reusable Semantic Lab block registry."""

from __future__ import annotations

import json
from typing import Any, Callable

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


class SemanticBlockRegistryPane:
    """Browse live reusable blocks without evaluating or dispatching them."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        service: SemanticLabAuthoringService,
        on_refresh: Callable[[], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self.service = service
        self._on_refresh = on_refresh
        self.frame = ttk.Frame(parent)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)
        self._catalog: dict[str, Any] = service.list_semantic_blocks()
        self._blocks: list[dict[str, Any]] = []
        self._production_catalog: dict[str, Any] | None = None
        self._query = tk.StringVar()
        self._category = tk.StringVar(value="all")
        self._status = tk.StringVar(value="Loading reusable block registry…")

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Entry(toolbar, textvariable=self._query).grid(row=0, column=0, sticky="ew")
        categories = ["all"] + [item["id"] for item in self._catalog.get("categories", [])]
        ttk.Combobox(
            toolbar,
            textvariable=self._category,
            values=categories,
            state="readonly",
            width=22,
        ).grid(row=0, column=1, padx=(6, 0))
        ttk.Button(toolbar, text="Search", command=self.search).grid(row=0, column=2, padx=(6, 0))
        ttk.Button(toolbar, text="Refresh live", command=self.request_refresh).grid(row=0, column=3, padx=(6, 0))
        ttk.Label(toolbar, textvariable=self._status).grid(row=0, column=4, padx=(12, 0), sticky="e")

        left = ttk.LabelFrame(self.frame, text="Reusable blocks")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._listbox = tk.Listbox(left, width=42, exportselection=False)
        self._listbox.grid(row=0, column=0, sticky="nsew")
        self._listbox.bind("<<ListboxSelect>>", lambda _event: self.show_selected())
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self._listbox.configure(yscrollcommand=scrollbar.set)

        right = ttk.LabelFrame(self.frame, text="Block contract")
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._detail = scrolled_text(right, wrap="none", state="disabled")
        self._detail.grid(row=0, column=0, sticky="nsew")
        self._render()

    def set_catalog(self, production_catalog: dict[str, Any] | None = None) -> None:
        self._production_catalog = production_catalog if isinstance(production_catalog, dict) else None
        self._catalog = self.service.list_semantic_blocks(self._production_catalog)
        self._render()

    def refresh(self) -> None:
        self.set_catalog(self._production_catalog)
        self._status.set(
            f"{self._catalog.get('blockCount', 0)} blocks · "
            + ("live production catalog" if self._catalog.get("productionCatalogLoaded") else "static contracts")
        )

    def request_refresh(self) -> None:
        if self._on_refresh is not None:
            self._on_refresh()
            return
        self.refresh()

    def search(self) -> None:
        category = self._category.get().strip()
        self._blocks = self.service.search_semantic_blocks(
            self._query.get().strip(),
            category=None if category in ("", "all") else category,
            production_catalog=self._production_catalog,
            limit=128,
        )
        self._render_items()
        self._status.set(f"{len(self._blocks)} matching blocks")

    def _render(self) -> None:
        self._blocks = list(self._catalog.get("blocks", []))
        self._render_items()
        self._status.set(
            f"{len(self._blocks)} blocks · "
            + ("live production catalog" if self._catalog.get("productionCatalogLoaded") else "static contracts")
        )

    def _render_items(self) -> None:
        self._listbox.delete(0, "end")
        for block in self._blocks:
            self._listbox.insert(
                "end",
                f"{block.get('category', '?')} · {block.get('label', block.get('id', '?'))}",
            )
        if self._blocks:
            self._listbox.selection_set(0)
            self.show_selected()
        else:
            self._set_detail({"ok": True, "blocks": [], "message": "No matching blocks"})

    def show_selected(self) -> None:
        selection = self._listbox.curselection()
        if not selection or selection[0] >= len(self._blocks):
            return
        self._set_detail(self._blocks[selection[0]])

    def _set_detail(self, value: Any) -> None:
        self._detail.configure(state="normal")
        self._detail.delete("1.0", "end")
        self._detail.insert("1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        self._detail.configure(state="disabled")
