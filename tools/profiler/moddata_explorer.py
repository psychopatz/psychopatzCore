"""Read-only saved ModData explorer used by the desktop profiler."""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any, Optional

try:
    import tkinter as tk
    from tkinter import filedialog, ttk
except ImportError:
    tk = None  # type: ignore[assignment]

from moddata_reader import GlobalModDataReader, ModDataFormatError
from moddata_formatters import FormatInfo, detect_format, formatted_value


def discover_saved_moddata() -> tuple[Path, ...]:
    """Return save files newest-first without reading any save contents."""
    root = Path.home() / "Zomboid" / "Saves"
    if not root.is_dir():
        return ()
    paths = [path for path in root.glob("*/*/global_mod_data.bin") if path.is_file()]
    return tuple(sorted(paths, key=lambda path: path.stat().st_mtime_ns, reverse=True))


class ModDataExplorer:
    """A bounded tree view with formatted and serializer-faithful views."""

    def __init__(self, parent: Any, initial_path: Optional[Path] = None):
        self.parent = parent
        self.reader: Optional[GlobalModDataReader] = None
        self.path_var = tk.StringVar(value=str(initial_path) if initial_path else "")
        self.status_var = tk.StringVar(value="Choose a saved global_mod_data.bin")
        self.table_var = tk.StringVar(value="")
        self.format_var = tk.StringVar(value="Detected format: —")
        self.table_names: tuple[str, ...] = ()
        self.table_by_iid: dict[str, str] = {}
        self.open_state: dict[str, dict[str, bool]] = {"formatted": {}, "raw": {}}
        self._build()
        candidates = discover_saved_moddata()
        selected = initial_path or (candidates[0] if candidates else None)
        if selected:
            self.load_path(selected)

    def _build(self) -> None:
        source = ttk.LabelFrame(self.parent, text="SAVED MODDATA SOURCE", padding=6)
        source.pack(fill="x")
        ttk.Label(source, text="global_mod_data.bin:").grid(row=0, column=0, sticky="w")
        ttk.Entry(source, textvariable=self.path_var).grid(row=0, column=1, sticky="ew", padx=6)
        ttk.Button(source, text="Browse", command=self.choose_path).grid(row=0, column=2)
        ttk.Button(source, text="Refresh", command=self.refresh).grid(row=0, column=3, padx=(6, 0))
        source.columnconfigure(1, weight=1)
        ttk.Label(source, textvariable=self.status_var).grid(
            row=1, column=0, columnspan=4, sticky="w", pady=(5, 0))

        selector = ttk.Frame(self.parent)
        selector.pack(fill="x", pady=(6, 4))
        ttk.Label(selector, text="Table:").pack(side="left")
        self.table_combo = ttk.Combobox(
            selector, textvariable=self.table_var, state="readonly", width=52)
        self.table_combo.pack(side="left", fill="x", expand=True, padx=6)
        self.table_combo.bind("<<ComboboxSelected>>", lambda _event: self.render_selected())
        ttk.Button(selector, text="Expand all", command=lambda: self.set_all_open(True)).pack(side="left")
        ttk.Button(selector, text="Collapse all", command=lambda: self.set_all_open(False)).pack(
            side="left", padx=(6, 0))
        ttk.Label(selector, textvariable=self.format_var).pack(side="left", padx=(10, 0))

        workspace = ttk.Panedwindow(self.parent, orient="horizontal")
        workspace.pack(fill="both", expand=True)
        catalog_frame = ttk.LabelFrame(workspace, text="ALL SAVED MODDATA TABLES", padding=4)
        value_frame = ttk.Frame(workspace)
        workspace.add(catalog_frame, weight=1)
        workspace.add(value_frame, weight=4)
        self.table_catalog = ttk.Treeview(
            catalog_frame, columns=("bytes", "entries", "format"), show="tree headings")
        self.table_catalog.heading("#0", text="Table")
        self.table_catalog.heading("bytes", text="Bytes")
        self.table_catalog.heading("entries", text="Entries")
        self.table_catalog.heading("format", text="Formatter")
        self.table_catalog.column("#0", width=230, minwidth=150)
        self.table_catalog.column("bytes", width=85, anchor="e")
        self.table_catalog.column("entries", width=65, anchor="e")
        self.table_catalog.column("format", width=180)
        catalog_scroll = ttk.Scrollbar(catalog_frame, command=self.table_catalog.yview)
        self.table_catalog.configure(yscrollcommand=catalog_scroll.set)
        self.table_catalog.pack(side="left", fill="both", expand=True)
        catalog_scroll.pack(side="right", fill="y")
        self.table_catalog.bind("<<TreeviewSelect>>", self.on_catalog_selected)

        self.notebook = ttk.Notebook(value_frame)
        self.notebook.pack(fill="both", expand=True)
        formatted_tab = ttk.Frame(self.notebook, padding=4)
        raw_tab = ttk.Frame(self.notebook, padding=4)
        self.notebook.add(formatted_tab, text="Formatted")
        self.notebook.add(raw_tab, text="Raw Value")
        self.notebook.bind("<<NotebookTabChanged>>", lambda _event: self._update_controls())

        self.formatted_tree = self._make_tree(
            formatted_tab,
            ("value", "type", "bytes", "offset"),
            ("Field / index", "Value", "Type", "Bytes", "Offset"),
        )
        self.raw_tree = self._make_tree(
            raw_tab,
            ("value", "type", "bytes", "offset"),
            ("Entry / key", "Saved value", "Wire type", "Bytes", "Offset"),
        )
        self._bind_open_state(self.formatted_tree, "formatted")
        self._bind_open_state(self.raw_tree, "raw")
        self._update_controls()

    @staticmethod
    def _make_tree(parent: Any, columns: tuple[str, ...], headings: tuple[str, ...]) -> Any:
        tree = ttk.Treeview(parent, columns=columns, show="tree headings")
        for column, heading in zip(("#0",) + columns, headings):
            tree.heading(column, text=heading)
        tree.column("#0", width=300, minwidth=180)
        tree.column("value", width=360, minwidth=160)
        tree.column("type", width=150, minwidth=100)
        tree.column("bytes", width=80, anchor="e")
        tree.column("offset", width=100, anchor="e")
        scrollbar = ttk.Scrollbar(parent, command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        tree.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        return tree

    def _bind_open_state(self, tree: Any, view: str) -> None:
        tree.bind("<<TreeviewOpen>>", lambda _event: self._remember_open(tree, view, True), add="+")
        tree.bind("<<TreeviewClose>>", lambda _event: self._remember_open(tree, view, False), add="+")

    def _remember_open(self, tree: Any, view: str, opened: bool) -> None:
        iid = tree.focus()
        if iid:
            self.open_state[view][iid] = opened

    def _active_tree(self) -> tuple[Any, str]:
        try:
            selected = self.notebook.tab(self.notebook.select(), "text")
        except (AttributeError, tk.TclError):
            selected = "Formatted"
        return (self.raw_tree, "raw") if selected == "Raw Value" else (self.formatted_tree, "formatted")

    def _update_controls(self) -> None:
        enabled = bool(self.reader and self.table_var.get())
        state = "normal" if enabled else "disabled"
        # The buttons are discovered by their labels to keep this component self-contained.
        for child in self.parent.winfo_children():
            if isinstance(child, ttk.Frame):
                for button in child.winfo_children():
                    if isinstance(button, ttk.Button) and button.cget("text") in ("Expand all", "Collapse all"):
                        button.configure(state=state)

    def on_catalog_selected(self, _event: Any = None) -> None:
        selection = self.table_catalog.selection()
        if not selection:
            return
        table_name = self.table_by_iid.get(selection[0])
        if table_name:
            self.table_var.set(table_name)
            self.table_combo.set(table_name)
            self.render_selected()

    def choose_path(self) -> None:
        selected = filedialog.askopenfilename(
            title="Select saved global_mod_data.bin",
            filetypes=(("Project Zomboid ModData", "global_mod_data.bin"), ("All files", "*")),
        )
        if selected:
            self.load_path(Path(selected))

    def refresh(self) -> None:
        path = Path(self.path_var.get().strip()) if self.path_var.get().strip() else None
        if path:
            self.load_path(path)
            return
        candidates = discover_saved_moddata()
        if candidates:
            self.load_path(candidates[0])

    def load_path(self, path: Path) -> None:
        old_reader = self.reader
        self.reader = None
        if old_reader is not None:
            old_reader.close()
        try:
            reader = GlobalModDataReader(path)
            self.reader = reader
            self.path_var.set(str(path))
            self.table_names = tuple(entry.name for entry in reader.index)
            self.table_combo.configure(values=self.table_names)
            self._populate_catalog()
            preferred = self.table_names[0] if self.table_names else ""
            self.table_var.set(preferred)
            self.table_combo.set(preferred)
            if preferred:
                self.table_catalog.selection_set(self._table_iid(preferred))
            self.status_var.set(
                f"Saved read-only snapshot: {path.name} — {reader.table_count} tables, "
                f"{reader.file_bytes:,} bytes")
            self.render_selected()
        except (ModDataFormatError, OSError) as error:
            self.status_var.set(f"Unable to read saved ModData: {error}")
            self.table_names = ()
            self.table_by_iid = {}
            self.table_combo.configure(values=())
            self.table_var.set("")
            self.table_combo.set("")
            self.format_var.set("Detected format: —")
            self.table_catalog.delete(*self.table_catalog.get_children())
            self._clear()

    @staticmethod
    def _table_iid(table_name: str) -> str:
        return "table|" + hashlib.sha1(table_name.encode("utf-8", "replace")).hexdigest()

    def _populate_catalog(self) -> None:
        self.table_catalog.delete(*self.table_catalog.get_children())
        self.table_by_iid = {}
        if self.reader is None:
            return
        for entry in self.reader.index:
            iid = self._table_iid(entry.name)
            self.table_by_iid[iid] = entry.name
            info = detect_format(entry.name)
            self.table_catalog.insert(
                "", "end", iid=iid, text=entry.name,
                values=(f"{entry.block_size:,}", f"{entry.entry_count:,}", info.label),
            )

    def render_selected(self) -> None:
        if self.reader is None or not self.table_var.get():
            self._clear()
            self._update_controls()
            return
        try:
            formatted = self.reader.inspect(
                table=self.table_var.get(), chunk_size=None, max_depth=10,
                max_items=128, max_nodes=20_000, max_string=4_096)
            raw = self.reader.inspect_raw(
                table=self.table_var.get(), max_depth=10, max_items=128,
                max_nodes=20_000, max_string=4_096)
            info = detect_format(self.table_var.get(), formatted.get("data"))
            formatted["data"] = formatted_value(self.table_var.get(), formatted.get("data"))
            self.format_var.set(self._format_label(info))
            self._render_formatted(formatted, info)
            self._render_raw(raw)
            suffix = " — bounded" if formatted.get("truncated") or raw.get("truncated") else ""
            self.status_var.set(f"{self.path_var.get()} — {self.table_var.get()}{suffix}")
        except (ModDataFormatError, OSError) as error:
            self.status_var.set(f"Unable to decode {self.table_var.get()}: {error}")
            self._clear()
        self._update_controls()

    @staticmethod
    def _format_label(info: FormatInfo) -> str:
        suffix = f" schema {info.schema_version}" if info.schema_version is not None else ""
        return f"Detected format: {info.label}{suffix}"

    def _clear(self) -> None:
        for tree in (getattr(self, "formatted_tree", None), getattr(self, "raw_tree", None)):
            if tree is not None:
                tree.delete(*tree.get_children())

    @staticmethod
    def _iid(view: str, path: str) -> str:
        return f"{view}|{hashlib.sha1(path.encode('utf-8', 'replace')).hexdigest()}"

    @staticmethod
    def _display(value: Any) -> str:
        if isinstance(value, str):
            return value
        return repr(value)

    def _render_formatted(self, report: dict[str, Any], info: Optional[FormatInfo] = None) -> None:
        tree = self.formatted_tree
        tree.delete(*tree.get_children())
        table = report.get("table") or {}
        info = info or detect_format(str(table.get("name") or ""), report.get("data"))
        root = tree.insert(
            "", "end", iid="formatted|root", text=str(table.get("name") or "table"),
            values=("", info.label, table.get("bytes", ""), table.get("dataOffset", "")),
            open=self.open_state["formatted"].get("formatted|root", True),
        )
        self._insert_formatted(root, report.get("data"), "root", 0)

    def _insert_formatted(self, parent: str, value: Any, path: str, depth: int) -> None:
        if depth > 10:
            return
        if isinstance(value, dict):
            items = value.items()
        elif isinstance(value, list):
            items = enumerate(value)
        else:
            self.formatted_tree.insert(
                parent, "end", iid=self._iid("formatted", path), text="value",
                values=(self._display(value), type(value).__name__, "", ""))
            return
        for key, child in items:
            child_path = f"{path}.{key}"
            iid = self._iid("formatted", child_path)
            if isinstance(child, (dict, list)):
                node = self.formatted_tree.insert(
                    parent, "end", iid=iid, text=f"[{key}]" if isinstance(value, list) else str(key),
                    values=(f"{len(child)} entries", type(child).__name__, "", ""),
                    open=self.open_state["formatted"].get(iid, False))
                self._insert_formatted(node, child, child_path, depth + 1)
            else:
                self.formatted_tree.insert(
                    parent, "end", iid=iid,
                    text=f"[{key}]" if isinstance(value, list) else str(key),
                    values=(self._display(child), type(child).__name__, "", ""))

    def _render_raw(self, report: dict[str, Any]) -> None:
        tree = self.raw_tree
        tree.delete(*tree.get_children())
        table = report.get("table") or {}
        raw = report.get("raw") or {}
        root = tree.insert(
            "", "end", iid="raw|root", text=str(table.get("name") or "table"),
            values=(f"{raw.get('entryCount', 0)} entries", "table", raw.get("bytes", ""), raw.get("offset", "")),
            open=self.open_state["raw"].get("raw|root", True),
        )
        self._insert_raw(root, raw, "root")

    def _insert_raw(self, parent: str, table: dict[str, Any], path: str) -> None:
        for entry in table.get("entries") or []:
            key = entry.get("key") or {}
            value = entry.get("value") or {}
            key_value = self._display(key.get("value"))
            key_label = f"[{entry.get('index')}] {key_value} ({key.get('type', 'unknown')})"
            value_type = str(value.get("type") or "unknown")
            value_text = (f"{value.get('entryCount', 0)} entries" if value_type == "table"
                          else self._display(value.get("value")))
            iid = self._iid("raw", f"{path}.{entry.get('index')}")
            node = self.raw_tree.insert(
                parent, "end", iid=iid, text=key_label,
                values=(value_text, value_type, entry.get("bytes", ""), entry.get("offset", "")),
                open=self.open_state["raw"].get(iid, False))
            if value_type == "table":
                self._insert_raw(node, value, f"{path}.{entry.get('index')}")
        omitted = table.get("_profilerOmittedEntries")
        if omitted:
            self.raw_tree.insert(
                parent, "end", iid=self._iid("raw", f"{path}.omitted"),
                text="[omitted]", values=(f"{omitted} entries", "bounded", "", ""))

    def set_all_open(self, opened: bool) -> None:
        tree, view = self._active_tree()
        def visit(parent: str) -> None:
            for iid in tree.get_children(parent):
                tree.item(iid, open=opened)
                self.open_state[view][iid] = opened
                visit(iid)
        visit("")

    def close(self) -> None:
        if self.reader is not None:
            self.reader.close()
            self.reader = None
