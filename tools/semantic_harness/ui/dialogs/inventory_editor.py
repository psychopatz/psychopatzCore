"""Structured inventory view backed by the installed PZ item definitions."""

from __future__ import annotations

from copy import deepcopy
import json
from typing import Any, Mapping

from tools.semantic_harness.inspection.rendering import pretty


class StructuredInventoryEditor:
    """One inventory draft projected as both structured controls and JSON."""

    def __init__(
        self,
        parent: Any,
        host: Any,
        owner: str,
        inventory: Any,
    ) -> None:
        self.host = host
        self.owner = owner
        self.tk = host._tk
        self.ttk = host._ttk
        self.ScrolledText = host._ScrolledText
        self.inventory = deepcopy(inventory) if isinstance(inventory, dict) else {}
        raw_items = self.inventory.get("items", [])
        self.items_are_mapping = isinstance(raw_items, dict)
        if isinstance(raw_items, dict):
            source = list(raw_items.items())
        elif isinstance(raw_items, list):
            source = [(None, item) for item in raw_items]
        else:
            source = []
        self.rows: list[dict[str, Any]] = []
        for index, (storage_key, item) in enumerate(source):
            self.rows.append(
                {
                    "rowID": f"{owner}-row-{index}",
                    "storageKey": storage_key,
                    "item": deepcopy(item),
                }
            )
        self.next_row = len(self.rows)
        self.selected_row_id: str | None = None
        self._loading_details = False
        self._active_tab = 0
        self._result_by_label: dict[str, dict[str, Any]] = {}

        self.frame = self.ttk.Frame(parent)
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(0, weight=1)
        self.notebook = self.ttk.Notebook(self.frame)
        self.notebook.grid(row=0, column=0, sticky="nsew")
        self.structured_tab = self.ttk.Frame(self.notebook, padding=8)
        self.structured_tab.columnconfigure(0, weight=1)
        self.structured_tab.rowconfigure(2, weight=1)
        self.json_tab = self.ttk.Frame(self.notebook, padding=8)
        self.json_tab.columnconfigure(0, weight=1)
        self.json_tab.rowconfigure(0, weight=1)
        self.notebook.add(self.structured_tab, text="Structured")
        self.notebook.add(self.json_tab, text="Advanced JSON")
        self.notebook.bind("<<NotebookTabChanged>>", self._on_tab_changed)

        self._build_search()
        self._build_tree()
        self._build_details()
        self._build_json()
        self._refresh_tree()

    def _build_search(self) -> None:
        ttk = self.ttk
        search = ttk.LabelFrame(
            self.structured_tab,
            text="Search Project Zomboid items",
            padding=8,
        )
        search.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        search.columnconfigure(0, weight=1)
        self.search_var = self.tk.StringVar(value="")
        self.search_entry = ttk.Entry(search, textvariable=self.search_var)
        self.search_entry.grid(row=0, column=0, sticky="ew", padx=(0, 6))
        self.search_button = ttk.Button(search, text="Search", command=self.search)
        self.search_button.grid(row=0, column=1, padx=(0, 6))
        self.results_var = self.tk.StringVar(value="")
        self.results_box = ttk.Combobox(
            search,
            textvariable=self.results_var,
            values=(),
            state="readonly",
            width=48,
        )
        self.results_box.grid(row=0, column=2, sticky="ew", padx=(0, 6))
        search.columnconfigure(2, weight=1)
        self.add_button = ttk.Button(
            search,
            text="Add item",
            command=self.add_selected_item,
            state="disabled",
        )
        self.add_button.grid(row=0, column=3)
        self.status_var = self.tk.StringVar(value="Search the installed item definitions.")
        ttk.Label(search, textvariable=self.status_var).grid(
            row=1, column=0, columnspan=4, sticky="w", pady=(5, 0)
        )

    def _build_tree(self) -> None:
        ttk = self.ttk
        items_frame = ttk.LabelFrame(
            self.structured_tab, text="Inventory items", padding=8
        )
        items_frame.grid(row=1, column=0, sticky="nsew", pady=(0, 8))
        items_frame.columnconfigure(0, weight=1)
        items_frame.rowconfigure(0, weight=1)
        self.tree = ttk.Treeview(
            items_frame,
            columns=("fullType", "quantity", "condition", "container"),
            show="headings",
            height=6,
            selectmode="browse",
        )
        for column, title, width in (
            ("fullType", "Full type", 190),
            ("quantity", "Stack / quantity", 95),
            ("condition", "Condition", 90),
            ("container", "Container / location", 160),
        ):
            self.tree.heading(column, text=title)
            self.tree.column(column, width=width, stretch=column != "quantity")
        self.tree.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(
            items_frame, orient="vertical", command=self.tree.yview
        )
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.tree.configure(yscrollcommand=scrollbar.set)
        self.tree.bind("<<TreeviewSelect>>", self._on_tree_select)
        self.remove_button = ttk.Button(
            items_frame, text="Remove selected", command=self.remove_selected
        )
        self.remove_button.grid(row=1, column=0, sticky="w", pady=(6, 0))

    def _build_details(self) -> None:
        ttk = self.ttk
        details = ttk.LabelFrame(
            self.structured_tab, text="Selected item", padding=8
        )
        details.grid(row=2, column=0, sticky="ew")
        details.columnconfigure(1, weight=1)
        self.detail_title = ttk.Label(details, text="Select an item to edit its stack and state.")
        self.detail_title.grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 5))

        self.quantity_var = self.tk.StringVar(value="1")
        ttk.Label(details, text="Stack / quantity").grid(
            row=1, column=0, sticky="w", padx=(0, 8), pady=2
        )
        self.quantity_box = ttk.Spinbox(
            details,
            textvariable=self.quantity_var,
            from_=1,
            to=1_000_000,
            increment=1,
            width=14,
        )
        self.quantity_box.grid(row=1, column=1, sticky="w", pady=2)

        self.condition_var = self.tk.StringVar(value="normal")
        ttk.Label(details, text="Condition").grid(
            row=2, column=0, sticky="w", padx=(0, 8), pady=2
        )
        self.condition_box = ttk.Combobox(
            details,
            textvariable=self.condition_var,
            values=("normal", "worn", "damaged", "broken"),
            state="readonly",
            width=25,
        )
        self.condition_box.grid(row=2, column=1, sticky="ew", pady=2)

        self.container_var = self.tk.StringVar(value="")
        ttk.Label(details, text="Container").grid(
            row=3, column=0, sticky="w", padx=(0, 8), pady=2
        )
        self.container_entry = ttk.Entry(details, textvariable=self.container_var)
        self.container_entry.grid(row=3, column=1, sticky="ew", pady=2)

        self.location_var = self.tk.StringVar(value="")
        ttk.Label(details, text="Location").grid(
            row=4, column=0, sticky="w", padx=(0, 8), pady=2
        )
        self.location_entry = ttk.Entry(details, textvariable=self.location_var)
        self.location_entry.grid(row=4, column=1, sticky="ew", pady=2)

        flags = ttk.Frame(details)
        flags.grid(row=5, column=0, columnspan=2, sticky="ew", pady=3)
        self.equipped_var = self.tk.BooleanVar(value=False)
        self.favorite_var = self.tk.BooleanVar(value=False)
        ttk.Checkbutton(flags, text="Equipped", variable=self.equipped_var).grid(
            row=0, column=0, sticky="w", padx=(0, 12)
        )
        ttk.Checkbutton(flags, text="Favorite", variable=self.favorite_var).grid(
            row=0, column=1, sticky="w"
        )

        self.equip_slot_var = self.tk.StringVar(value="")
        ttk.Label(details, text="Equipment slot").grid(
            row=6, column=0, sticky="w", padx=(0, 8), pady=2
        )
        self.equip_slot_entry = ttk.Entry(details, textvariable=self.equip_slot_var)
        self.equip_slot_entry.grid(row=6, column=1, sticky="ew", pady=2)

        self.market_sense_var = self.tk.StringVar(value="No MarketSense metadata on this item.")
        ttk.Label(details, text="MarketSense · read-only").grid(
            row=7, column=0, sticky="nw", padx=(0, 8), pady=2
        )
        self.market_sense_label = ttk.Label(
            details,
            textvariable=self.market_sense_var,
            wraplength=520,
            justify="left",
        )
        self.market_sense_label.grid(row=7, column=1, sticky="w", pady=2)
        self.commit_button = ttk.Button(
            details,
            text="Apply item changes",
            command=self.commit_selected,
        )
        self.commit_button.grid(row=8, column=1, sticky="e", pady=(5, 0))

    def _build_json(self) -> None:
        ttk = self.ttk
        ttk.Label(
            self.json_tab,
            text=(
                "Advanced JSON edits the same inventory draft as the Structured tab. "
                "Switch back to validate and refresh the item list."
            ),
            wraplength=680,
        ).grid(row=1, column=0, sticky="w", pady=(6, 0))
        self.json_editor = self.ScrolledText(
            self.json_tab, height=24, width=80, wrap="none"
        )
        self.json_editor.grid(row=0, column=0, sticky="nsew")

    def _inventory_value(self) -> dict[str, Any]:
        value = deepcopy(self.inventory)
        if self.items_are_mapping:
            items: dict[Any, Any] = {}
            for row in self.rows:
                key = row.get("storageKey")
                item = row.get("item")
                if key is None and isinstance(item, dict):
                    key = item.get("itemID") or item.get("id") or row["rowID"]
                if key is not None:
                    items[key] = deepcopy(item)
            value["items"] = items
        else:
            value["items"] = [deepcopy(row.get("item")) for row in self.rows]
        return value

    def _row_for(self, row_id: str | None) -> dict[str, Any] | None:
        if not row_id:
            return None
        return next((row for row in self.rows if row["rowID"] == row_id), None)

    def _refresh_tree(self) -> None:
        for row_id in self.tree.get_children(""):
            self.tree.delete(row_id)
        for row in self.rows:
            item = row.get("item")
            if not isinstance(item, dict):
                self.tree.insert(
                    "", "end", iid=row["rowID"],
                    values=("Unstructured entry · preserve in Advanced JSON", "", "", ""),
                )
                continue
            full_type = str(item.get("fullType") or item.get("type") or "")
            quantity = item.get("stack", item.get("quantity", item.get("count", 1)))
            condition = item.get("condition", item.get("cond", "—"))
            container = item.get("container", item.get("location", "—"))
            name = str(item.get("displayName") or item.get("customName") or full_type)
            self.tree.insert(
                "", "end", iid=row["rowID"], text=name,
                values=(full_type, quantity, condition, container),
            )

    def _on_tree_select(self, _event: Any = None) -> None:
        selected = self.tree.selection()
        next_id = selected[0] if selected else None
        if next_id == self.selected_row_id:
            return
        if self.selected_row_id:
            try:
                self.commit_selected(show_error=False)
            except ValueError:
                if self.selected_row_id in self.tree.get_children(""):
                    self.tree.selection_set(self.selected_row_id)
                return
        self.selected_row_id = next_id
        self._load_selected()

    def _load_selected(self) -> None:
        row = self._row_for(self.selected_row_id)
        item = row.get("item") if row else None
        self._loading_details = True
        if not isinstance(item, dict):
            self.detail_title.configure(text="Select a structured item to edit its fields.")
            self.quantity_var.set("1")
            self.condition_var.set("normal")
            self.container_var.set("")
            self.location_var.set("")
            self.equipped_var.set(False)
            self.favorite_var.set(False)
            self.equip_slot_var.set("")
            self.market_sense_var.set("Metadata unavailable for this unstructured entry.")
            self._loaded_values = None
            self._loading_details = False
            return

        full_type = str(item.get("fullType") or item.get("type") or "unknown item")
        self.detail_title.configure(
            text=f"{item.get('displayName') or item.get('customName') or full_type} · {full_type}"
        )
        self.quantity_var.set(
            str(item.get("stack", item.get("quantity", item.get("count", 1))))
        )
        condition = item.get("condition", item.get("cond", "normal"))
        condition = str(condition)
        values = list(self.condition_box.cget("values"))
        if condition not in values:
            values.append(condition)
            self.condition_box.configure(values=tuple(values))
        self.condition_var.set(condition)
        self.container_var.set(str(item.get("container") or ""))
        self.location_var.set(str(item.get("location") or ""))
        self.equipped_var.set(item.get("equipped") is True or bool(item.get("equipSlot")))
        self.favorite_var.set(item.get("favorite") is True or item.get("fav") is True)
        self.equip_slot_var.set(str(item.get("equipSlot") or ""))
        metadata = item.get("marketSense") or item.get("classification")
        self.market_sense_var.set(
            pretty(metadata) if isinstance(metadata, Mapping)
            else "No MarketSense metadata on this item."
        )
        self._loaded_values = {
            "stack": self.quantity_var.get(),
            "condition": self.condition_var.get(),
            "container": self.container_var.get(),
            "location": self.location_var.get(),
            "equipped": self.equipped_var.get(),
            "favorite": self.favorite_var.get(),
            "equipSlot": self.equip_slot_var.get(),
        }
        self._loading_details = False

    def _detail_values(self) -> dict[str, Any]:
        return {
            "stack": self.quantity_var.get(),
            "condition": self.condition_var.get(),
            "container": self.container_var.get().strip(),
            "location": self.location_var.get().strip(),
            "equipped": self.equipped_var.get(),
            "favorite": self.favorite_var.get(),
            "equipSlot": self.equip_slot_var.get().strip(),
        }

    def commit_selected(self, show_error: bool = True) -> None:
        row = self._row_for(self.selected_row_id)
        item = row.get("item") if row else None
        loaded = getattr(self, "_loaded_values", None)
        if not isinstance(item, dict) or not isinstance(loaded, dict):
            return
        values = self._detail_values()
        try:
            quantity = int(str(values["stack"]))
        except (TypeError, ValueError) as error:
            raise ValueError("Stack / quantity must be a whole number") from error
        if quantity < 1 or quantity > 1_000_000:
            raise ValueError("Stack / quantity must be between 1 and 1000000")
        if str(quantity) != str(loaded["stack"]):
            item["stack"] = quantity
        if values["condition"] != loaded["condition"]:
            item["condition"] = values["condition"]
        for key in ("container", "location", "equipSlot"):
            if values[key] != loaded[key]:
                if values[key]:
                    item[key] = values[key]
                else:
                    item.pop(key, None)
        if values["equipped"]:
            item["equipped"] = True
        elif loaded["equipped"] or "equipped" in item or "equipSlot" in item:
            item["equipped"] = False
            item.pop("equipSlot", None)
            self.equip_slot_var.set("")
            values["equipSlot"] = ""
        if values["favorite"] != loaded["favorite"] or "favorite" in item:
            item["favorite"] = values["favorite"]
        self._loaded_values = values
        self._refresh_tree()
        if show_error:
            self.status_var.set("Item changes are in the scenario draft.")

    def search(self) -> None:
        query = self.search_var.get().strip()
        self.status_var.set("Searching installed item definitions…")

        def finished(result: dict[str, Any]) -> None:
            self._result_by_label = {}
            labels = []
            for item in result.get("results", []):
                if not isinstance(item, dict) or not item.get("fullType"):
                    continue
                label = f"{item.get('displayName') or item['fullType']} · {item['fullType']}"
                self._result_by_label[label] = item
                labels.append(label)
            self.results_box.configure(values=tuple(labels))
            self.results_var.set(labels[0] if labels else "")
            self.add_button.configure(state="normal" if labels else "disabled")
            if labels:
                self.status_var.set(
                    f"{len(labels)} shown · {result.get('totalMatches', len(labels))} matches"
                )
            elif result.get("sourceAvailable"):
                self.status_var.set("No matching item definitions.")
            else:
                self.status_var.set(
                    "PZ item scripts were not found; set PZ_GAME_DIR to the installed game folder."
                )

        if not self.host._start_operation(
            lambda worker: worker.item_catalog(query, limit=100), finished
        ):
            self.status_var.set("The Lua worker is busy; try searching again shortly.")

    def add_selected_item(self) -> None:
        selected = self._result_by_label.get(self.results_var.get())
        if not isinstance(selected, dict):
            return
        try:
            self.commit_selected(show_error=False)
        except ValueError as error:
            self.host._messagebox.showerror("Inventory item", str(error), parent=self.frame)
            return
        full_type = str(selected["fullType"])
        used_ids: set[str] = set()
        for row in self.rows:
            if row.get("storageKey") is not None:
                used_ids.add(str(row["storageKey"]))
            item = row.get("item")
            if isinstance(item, dict):
                for value in (item.get("itemID"), item.get("id")):
                    if value is not None:
                        used_ids.add(str(value))
        base = f"semantic-lab-{self.owner}-item"
        suffix = 1
        item_id = f"{base}-{suffix}"
        while item_id in used_ids:
            suffix += 1
            item_id = f"{base}-{suffix}"
        item = {
            "id": item_id,
            "itemID": item_id,
            "type": full_type,
            "fullType": full_type,
            "displayName": str(selected.get("displayName") or full_type),
            "stack": 1,
            "condition": "normal",
            "container": "root",
            "equipped": False,
            "favorite": False,
        }
        row_id = f"{self.owner}-row-{self.next_row}"
        self.next_row += 1
        self.rows.append(
            {
                "rowID": row_id,
                "storageKey": item_id if self.items_are_mapping else None,
                "item": item,
            }
        )
        self._refresh_tree()
        self.tree.selection_set(row_id)
        self.tree.see(row_id)
        self.selected_row_id = row_id
        self._load_selected()
        self.status_var.set(f"Added {full_type} to the scenario draft.")

    def remove_selected(self) -> None:
        selected = self.tree.selection()
        if not selected:
            return
        self.rows = [row for row in self.rows if row["rowID"] != selected[0]]
        self.selected_row_id = None
        self._refresh_tree()
        self._load_selected()
        self.status_var.set("Removed the selected item from the scenario draft.")

    def _sync_json_from_structured(self) -> None:
        try:
            self.commit_selected(show_error=False)
        except ValueError as error:
            self.host._messagebox.showerror("Inventory item", str(error), parent=self.frame)
            self.notebook.select(self.structured_tab)
            return
        self.json_editor.delete("1.0", "end")
        self.json_editor.insert("1.0", pretty(self._inventory_value()))

    def _sync_structured_from_json(self) -> None:
        try:
            value = json.loads(self.json_editor.get("1.0", "end").strip())
        except json.JSONDecodeError as error:
            self.host._messagebox.showerror(
                "Advanced inventory JSON",
                f"Invalid JSON: {error.msg}",
                parent=self.frame,
            )
            self.notebook.select(self.json_tab)
            return
        if not isinstance(value, dict):
            self.host._messagebox.showerror(
                "Advanced inventory JSON",
                "Inventory JSON must be an object.",
                parent=self.frame,
            )
            self.notebook.select(self.json_tab)
            return
        self.inventory = value
        raw_items = value.get("items", [])
        self.items_are_mapping = isinstance(raw_items, dict)
        if isinstance(raw_items, dict):
            source = list(raw_items.items())
        elif isinstance(raw_items, list):
            source = [(None, item) for item in raw_items]
        else:
            source = []
        self.rows = [
            {
                "rowID": f"{self.owner}-row-{index}",
                "storageKey": storage_key,
                "item": deepcopy(item),
            }
            for index, (storage_key, item) in enumerate(source)
        ]
        self.next_row = len(self.rows)
        self.selected_row_id = None
        self._refresh_tree()
        self._load_selected()
        self.status_var.set("Advanced JSON was loaded into the Structured view.")

    def _on_tab_changed(self, _event: Any = None) -> None:
        selected = self.notebook.index(self.notebook.select())
        if selected == self._active_tab:
            return
        if selected == 1:
            self._sync_json_from_structured()
        else:
            self._sync_structured_from_json()
        self._active_tab = self.notebook.index(self.notebook.select())

    def get_value(self) -> Any:
        if self.notebook.index(self.notebook.select()) == 1:
            return self.json_editor.get("1.0", "end").strip()
        self.commit_selected(show_error=False)
        return self._inventory_value()
