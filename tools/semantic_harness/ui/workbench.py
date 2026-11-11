"""Reusable layout components for the Simulation workbench."""

from __future__ import annotations

from typing import Any

from .dialogs.catalog_control import CatalogControlField


class ActorInventoryView:
    """Shared read-only inventory presentation for Player and NPC actors."""

    def __init__(self, parent: Any, host: Any, actor_label: str) -> None:
        self.host = host
        self.ttk = host._ttk
        self.tk = host._tk
        self.actor_label = actor_label
        self.item_rows: dict[str, dict[str, Any]] = {}
        self.frame = self.ttk.Frame(parent, padding=6)
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(1, weight=1)
        self.source_var = self.tk.StringVar(value="Source: MISSING")
        self.ttk.Label(
            self.frame,
            textvariable=self.source_var,
            anchor="w",
            justify="left",
            wraplength=620,
        ).grid(row=0, column=0, sticky="ew", pady=(0, 6))
        table_frame = self.ttk.Frame(self.frame)
        table_frame.grid(row=1, column=0, sticky="nsew")
        table_frame.columnconfigure(0, weight=1)
        table_frame.rowconfigure(0, weight=1)
        self.tree = self.ttk.Treeview(
            table_frame,
            columns=("fullType", "quantity", "source"),
            show="headings",
            selectmode="browse",
            height=10,
        )
        for column, title, width in (
            ("fullType", "Item", 170),
            ("quantity", "Stack", 64),
            ("source", "Origin", 96),
        ):
            self.tree.heading(column, text=title)
            self.tree.column(column, width=width, stretch=column != "quantity")
        self.tree.grid(row=0, column=0, sticky="nsew")
        scrollbar = self.ttk.Scrollbar(
            table_frame, orient="vertical", command=self.tree.yview
        )
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.tree.configure(yscrollcommand=scrollbar.set)
        self.empty_var = self.tk.StringVar(value="")
        self.ttk.Label(
            self.frame,
            textvariable=self.empty_var,
            anchor="w",
        ).grid(row=2, column=0, sticky="ew", pady=(6, 0))

    def update(
        self,
        inventory: Any,
        provenance: Any,
    ) -> None:
        for item_id in self.tree.get_children(""):
            self.tree.delete(item_id)
        self.item_rows = {}
        inventory = inventory if isinstance(inventory, dict) else {}
        raw_items = inventory.get("items", [])
        if isinstance(raw_items, dict):
            items = list(raw_items.values())
        elif isinstance(raw_items, list):
            items = raw_items
        else:
            items = []
        provenance = provenance if isinstance(provenance, dict) else {}
        source = str(
            inventory.get("source")
            or provenance.get("source")
            or "MISSING"
        ).upper()
        reason = str(provenance.get("reason") or "").strip()
        table = str(provenance.get("table") or "").strip()
        details = [f"Source: {source}"]
        if table:
            details.append(f"authority: {table}")
        if reason:
            details.append(f"reason: {reason}")
        self.source_var.set(" · ".join(details))
        visible = 0
        for index, item in enumerate(items[:512]):
            if not isinstance(item, dict):
                continue
            full_type = str(
                item.get("displayName")
                or item.get("fullType")
                or item.get("type")
                or "Unstructured item"
            )
            quantity = item.get(
                "stack", item.get("quantity", item.get("count", 1))
            )
            item_source = str(item.get("source") or source).upper()
            row_id = f"{self.actor_label}-{index}"
            self.item_rows[row_id] = item
            self.tree.insert(
                "",
                "end",
                iid=row_id,
                values=(full_type, quantity, item_source),
            )
            visible += 1
        self.empty_var.set(
            ""
            if visible
            else f"{self.actor_label} inventory is unavailable or empty · source {source}"
        )


class InventoryGiftWorkbench:
    """Side-by-side read-only inventories with a production gift action."""

    def __init__(self, parent: Any, host: Any) -> None:
        self.host = host
        self.ttk = host._ttk
        self.tk = host._tk
        self.frame = self.ttk.LabelFrame(
            parent,
            text="Inventory / Gift verification · isolated working world",
            padding=6,
        )
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, minsize=20)
        self.frame.columnconfigure(2, weight=1)
        self.frame.rowconfigure(1, weight=1)
        self.frame.rowconfigure(2, weight=1)
        self.player_view = ActorInventoryView(self.frame, host, "gift-player")
        self.npc_view = ActorInventoryView(self.frame, host, "gift-npc")
        # The Relationship page lives in the narrow context dock. Stack the
        # two read-only inventories so they do not impose a side-by-side
        # 900px minimum on the conversation surface.
        self.player_view.frame.grid(row=1, column=0, columnspan=3, sticky="nsew")
        self.npc_view.frame.grid(row=2, column=0, columnspan=3, sticky="nsew")
        self.ttk.Label(self.frame, text="Player → NPC").grid(
            row=0, column=0, columnspan=3, sticky="w", pady=(0, 4)
        )
        self.player_view.tree.bind(
            "<<TreeviewSelect>>", lambda _event: self._on_player_select()
        )
        action = self.ttk.Frame(self.frame)
        action.grid(row=3, column=0, columnspan=3, sticky="ew", pady=(6, 2))
        action.columnconfigure(1, weight=1)
        self.selected_var = self.tk.StringVar(value="Selected: none")
        self.ttk.Label(action, textvariable=self.selected_var, anchor="w").grid(
            row=0, column=0, sticky="w", padx=(0, 8)
        )
        self.quantity_var = self.tk.StringVar(value="1")
        self.ttk.Label(action, text="Count").grid(row=0, column=1, sticky="e")
        self.quantity_box = self.ttk.Spinbox(
            action,
            from_=1,
            to=999,
            width=5,
            textvariable=self.quantity_var,
        )
        self.quantity_box.grid(row=0, column=2, sticky="w", padx=(4, 8))
        self.give_button = self.ttk.Button(
            action,
            text="Give selected →",
            command=self._give_selected,
        )
        self.give_button.grid(row=0, column=3, sticky="e")
        self.reset_button = self.ttk.Button(
            action,
            text="Reset Working World",
            command=host.reset_working_world,
        )
        self.reset_button.grid(row=0, column=4, sticky="e", padx=(6, 0))
        self.status_var = self.tk.StringVar(
            value="Select a Player item to route it through production gift semantics."
        )
        self.ttk.Label(
            self.frame,
            textvariable=self.status_var,
            anchor="w",
            justify="left",
            wraplength=760,
        ).grid(row=4, column=0, columnspan=3, sticky="ew", pady=(2, 4))
        self.result = host._ScrolledText(
            self.frame,
            width=40,
            wrap="word",
            height=8,
            state="disabled",
        )
        self.result.grid(row=5, column=0, columnspan=3, sticky="ew")
        self.selected_item: dict[str, Any] | None = None

    def _on_player_select(self) -> None:
        selection = self.player_view.tree.selection()
        self.selected_item = (
            self.player_view.item_rows.get(selection[0]) if selection else None
        )
        if not self.selected_item:
            self.selected_var.set("Selected: none")
            self._set_action_state(False)
            return
        display = str(
            self.selected_item.get("displayName")
            or self.selected_item.get("fullType")
            or self.selected_item.get("type")
            or "item"
        )
        stack = self.selected_item.get(
            "stack", self.selected_item.get("quantity", 1)
        )
        self.selected_var.set(f"Selected: {display} × {stack}")
        self.quantity_var.set("1")
        self.status_var.set(
            "Selected item will use the production semantic GIFT route; "
            "the UI does not mutate inventory tables."
        )
        self._set_action_state(True)

    def _set_action_state(self, selected: bool) -> None:
        self.give_button.configure(
            state=("normal" if selected and not self.host.busy else "disabled")
        )

    def set_busy(self, busy: bool) -> None:
        self._set_action_state(self.selected_item is not None and not busy)
        self.reset_button.configure(state="disabled" if busy else "normal")

    def _give_selected(self) -> None:
        if self.selected_item is not None:
            self.host.gift_selected_inventory_item(
                self.selected_item,
                self.quantity_var.get(),
            )

    def update(self, player: Any, npc: Any, player_provenance: Any, npc_provenance: Any) -> None:
        self.player_view.update(player, player_provenance)
        self.npc_view.update(npc, npc_provenance)
        self.selected_item = None
        self.selected_var.set("Selected: none")
        self._set_action_state(False)

    def show_result(self, text: str) -> None:
        self._set_action_state(False)
        self.host._set_text(self.result, text)


class WorkbenchPage:
    """Place catalog fields with predictable spacing and page-specific density."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        host: Any,
        *,
        layout: str = "two_column",
    ) -> None:
        self.tk = tk
        self.ttk = ttk
        self.scrolled_text = scrolled_text
        self.host = host
        self.layout = layout
        self.frame = ttk.Frame(parent)
        self.frame.rowconfigure(0, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.canvas = tk.Canvas(
            self.frame,
            borderwidth=0,
            highlightthickness=0,
        )
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.scrollbar = ttk.Scrollbar(
            self.frame,
            orient="vertical",
            command=self.canvas.yview,
        )
        self.scrollbar.grid(row=0, column=1, sticky="ns")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.content = ttk.Frame(self.canvas, padding=(6, 4))
        self.content.columnconfigure(0, minsize=90)
        self.content.columnconfigure(1, weight=1, minsize=80)
        self.content.columnconfigure(2, minsize=90)
        self.content.columnconfigure(3, weight=1, minsize=80)
        self._canvas_window = self.canvas.create_window(
            (0, 0),
            window=self.content,
            anchor="nw",
        )
        self.content.bind("<Configure>", self._update_scroll_region)
        self.canvas.bind("<Configure>", self._resize_content)
        self._row = 0
        self._pair_column = 0
        self._section: str | None = None

    def _update_scroll_region(self, _event: Any | None = None) -> None:
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _resize_content(self, event: Any) -> None:
        self.canvas.itemconfigure(
            self._canvas_window,
            width=max(1, int(event.width)),
        )
        self._update_scroll_region()

    def _finish_pair(self) -> None:
        if self._pair_column:
            self._row += 1
            self._pair_column = 0

    def add_section(self, title: str | None) -> None:
        value = str(title or "").strip()
        if not value or value == self._section:
            return
        self._finish_pair()
        if self._section is not None:
            self.ttk.Separator(self.content, orient=self.tk.HORIZONTAL).grid(
                row=self._row,
                column=0,
                columnspan=4,
                sticky="ew",
                pady=(5, 3),
            )
            self._row += 1
        self.ttk.Label(
            self.content,
            text=value,
            font=("TkDefaultFont", 9, "bold"),
        ).grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="w",
            pady=(2, 2),
        )
        self._row += 1
        self._section = value

    def add_control(self, control: dict[str, Any], initial: Any) -> CatalogControlField:
        kind = str(control.get("control") or "text")
        full_width = self.layout == "stacked" or (
            self.layout == "personality"
            and kind in {"boolean", "multi_select", "structured_collection", "advanced_json"}
        )
        if full_width:
            self._finish_pair()
            field = CatalogControlField(
                self.content,
                self.tk,
                self.ttk,
                self.scrolled_text,
                self.host,
                control,
                initial,
                row=self._row,
                label_column=0,
                value_column=1,
                value_columnspan=3,
                label_padx=(0, 8),
                value_padx=(0, 0),
                width=24,
            )
            self._row += 1
            return field

        if self._pair_column == 0:
            label_column = 0
            value_column = 1
            label_padx = (0, 8)
            value_padx = (0, 14)
        else:
            label_column = 2
            value_column = 3
            label_padx = (16, 8)
            value_padx = (0, 0)
        field = CatalogControlField(
            self.content,
            self.tk,
            self.ttk,
            self.scrolled_text,
            self.host,
            control,
            initial,
            row=self._row,
            label_column=label_column,
            value_column=value_column,
            label_padx=label_padx,
            value_padx=value_padx,
            width=18,
        )
        self._pair_column = 2 if self._pair_column == 0 else 0
        if self._pair_column == 0:
            self._row += 1
        return field

    def add_summary(
        self,
        title: str,
        *,
        height: int = 4,
        width: int = 36,
    ) -> Any:
        """Add a bounded read-only summary below the current field row."""

        self._finish_pair()
        self.ttk.Label(
            self.content,
            text=title,
            anchor="w",
        ).grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="w",
            pady=(2, 1),
        )
        self._row += 1
        widget = self.scrolled_text(
            self.content,
            height=height,
            width=width,
            wrap="word",
            state="disabled",
        )
        widget.grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="ew",
            pady=(0, 5),
        )
        self._row += 1
        return widget

    def add_widget(
        self,
        widget: Any,
        *,
        column: int = 0,
        columnspan: int = 4,
        sticky: str = "ew",
        pady: tuple[int, int] = (2, 4),
    ) -> Any:
        """Place a host-owned widget after the current field row."""

        self._finish_pair()
        widget.grid(
            row=self._row,
            column=column,
            columnspan=columnspan,
            sticky=sticky,
            pady=pady,
        )
        self._row += 1
        return widget

    def finish(self) -> None:
        self._finish_pair()
        self.content.rowconfigure(self._row, weight=1)
        self._update_scroll_region()
