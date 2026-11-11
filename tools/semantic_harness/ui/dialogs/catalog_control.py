"""Reusable Tk field renderer for the worker-owned simulation control catalog."""

from __future__ import annotations

from typing import Any, Mapping

from tools.semantic_harness.inspection.rendering import pretty
from .inventory_editor import StructuredInventoryEditor


def control_option_rows(control: Mapping[str, Any]) -> list[tuple[Any, str]]:
    options = control.get("options")
    if not isinstance(options, list):
        return []
    rows: list[tuple[Any, str]] = []
    for option in options[:64]:
        if isinstance(option, Mapping):
            value = option.get("value", option.get("id"))
            label = option.get("label", value)
        else:
            value = option
            label = option
        if value is not None:
            rows.append((value, str(label if label is not None else value)))
    return rows


def control_options(control: Mapping[str, Any]) -> list[Any]:
    return [value for value, _label in control_option_rows(control)]


class CatalogControlField:
    """Render one typed field without owning or applying scenario state."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        host: Any,
        control: dict[str, Any],
        initial: Any,
        *,
        row: int,
        label_column: int = 0,
        value_column: int = 1,
        label_columnspan: int = 1,
        value_columnspan: int = 1,
        label_padx: tuple[int, int] = (0, 6),
        value_padx: tuple[int, int] = (0, 0),
        value_sticky: str = "ew",
        width: int = 30,
    ) -> None:
        self.control = control
        self.initial = initial
        self.tk = tk
        self.ttk = ttk
        self.host = host
        self.kind = str(control.get("control") or "text")
        self.variable: Any | None = None
        self.widget: Any | None = None
        self.value_widget: Any | None = None
        self.label_widget: Any | None = None
        self.slider_display: Any | None = None
        self._update_slider_display: Any | None = None
        self.option_map: dict[str, Any] = {}
        self.listbox_values: list[Any] = []
        self.editor: StructuredInventoryEditor | None = None
        self.width = width
        self.label_columnspan = max(1, int(label_columnspan))
        self.value_columnspan = max(1, int(value_columnspan))
        self.label_padx = label_padx
        self.value_padx = value_padx
        self.value_sticky = value_sticky
        self.dirty = False
        self.missing = False
        self._base_label = str(control.get("label") or control.get("id") or "")
        self._suppress_dirty = False
        self.derived = bool(control.get("derivedFrom"))

        rows = control_option_rows(control)
        if initial not in (None, "") and all(
            str(value) != str(initial) for value, _label in rows
        ):
            rows.append((initial, str(initial)))
        self._rows = rows
        self._label_by_value = {str(value): label for value, label in rows}

        if self.kind == "boolean":
            self.variable = tk.BooleanVar(value=bool(initial))
            self.widget = ttk.Checkbutton(
                parent,
                text=str(control.get("label") or control.get("id") or ""),
                variable=self.variable,
            )
            self.widget.grid(
                row=row,
                column=label_column,
                columnspan=self.label_columnspan + self.value_columnspan,
                sticky="w",
                padx=self.label_padx,
                pady=3,
            )
            return

        label = self._base_label
        if self.derived:
            label += " (derived)"
        self.label_widget = ttk.Label(
            parent,
            text=label,
        )
        self.label_widget.grid(
            row=row,
            column=label_column,
            columnspan=self.label_columnspan,
            sticky="w",
            padx=self.label_padx,
            pady=3,
        )

        if self.kind == "combobox":
            self.option_map = {label: value for value, label in rows}
            display = self._label_by_value.get(str(initial), rows[0][1] if rows else "")
            self.variable = tk.StringVar(value=display)
            self.widget = ttk.Combobox(
                parent,
                textvariable=self.variable,
                values=tuple(label for _value, label in rows),
                state="readonly",
                width=width,
            )
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
        elif self.kind == "slider":
            minimum = float(control.get("min", 0))
            maximum = float(control.get("max", 1))
            step = float(control.get("step", 0.05))
            try:
                numeric = float(initial)
            except (TypeError, ValueError):
                numeric = (minimum + maximum) / 2
            numeric = min(max(numeric, minimum), maximum)
            self.variable = tk.DoubleVar(value=numeric)
            holder = ttk.Frame(parent)
            holder.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=1,
            )
            holder.columnconfigure(0, weight=1)
            self.widget = tk.Scale(
                holder,
                from_=minimum,
                to=maximum,
                resolution=step,
                orient=tk.HORIZONTAL,
                showvalue=False,
                variable=self.variable,
                highlightthickness=0,
            )
            self.widget.grid(row=0, column=0, sticky="ew")
            display = ttk.Label(holder, width=7, anchor="e")
            display.grid(row=0, column=1, padx=(4, 0))

            def update_display(*_args: Any) -> None:
                if self.missing:
                    display.configure(text="MISSING")
                    return
                try:
                    number = float(self.variable.get())
                except (TypeError, ValueError):
                    number = 0.0
                formatter = control.get("format")
                if isinstance(formatter, str):
                    try:
                        display.configure(text=formatter % number)
                        return
                    except (TypeError, ValueError):
                        pass
                display.configure(text=str(number))

            self.variable.trace_add("write", update_display)
            update_display()
            self.slider_display = display
            self._update_slider_display = update_display
            self.value_widget = holder
        elif self.kind in {"integer", "spinbox"}:
            value_type = str(control.get("valueType") or "number")
            try:
                numeric = int(initial or 0) if value_type == "integer" else float(initial or 0)
            except (TypeError, ValueError):
                numeric = 0
            self.variable = (
                tk.IntVar(value=numeric)
                if value_type == "integer"
                else tk.DoubleVar(value=numeric)
            )
            self.widget = ttk.Spinbox(
                parent,
                textvariable=self.variable,
                from_=control.get("min", 0),
                to=control.get("max", 100),
                increment=control.get("step", 1),
                width=width,
            )
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
        elif self.kind == "multi_select":
            selected = {str(value) for value in initial} if isinstance(initial, list) else set()
            existing = {str(value) for value, _label in rows}
            rows.extend((value, value) for value in sorted(selected - existing))
            frame = ttk.Frame(parent)
            frame.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
            frame.columnconfigure(0, weight=1)
            listbox = tk.Listbox(
                frame,
                selectmode="multiple",
                height=min(max(len(rows), 4), 8),
                exportselection=False,
            )
            scrollbar = ttk.Scrollbar(frame, orient="vertical", command=listbox.yview)
            listbox.configure(yscrollcommand=scrollbar.set)
            listbox.grid(row=0, column=0, sticky="ew")
            scrollbar.grid(row=0, column=1, sticky="ns")
            self.listbox_values = [value for value, _label in rows]
            for index, (value, label) in enumerate(rows):
                listbox.insert("end", label)
                if str(value) in selected:
                    listbox.selection_set(index)
            self.variable = listbox
            self.widget = listbox
            self.value_widget = frame
        elif self.kind in {"text", "searchable_catalog"}:
            self.variable = tk.StringVar(value="" if initial is None else str(initial))
            self.widget = ttk.Entry(parent, textvariable=self.variable, width=width)
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
        elif (
            self.kind == "structured_collection"
            and control.get("collectionType") == "inventory"
        ):
            owner = str(control.get("id") or "player.inventory").split(".", 1)[0]
            self.editor = StructuredInventoryEditor(parent, host, owner, initial)
            self.widget = self.editor.frame
            self.value_widget = self.widget
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
        elif self.kind == "advanced_json":
            self.widget = scrolled_text(parent, height=10, width=58, wrap="none")
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky,
                padx=self.value_padx,
                pady=2,
            )
            self.widget.insert("1.0", pretty(initial if initial is not None else {}))
            self.variable = self.widget
        elif self.kind == "read_only":
            self.widget = ttk.Label(parent, text=str(initial or "unknown"))
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky if self.value_sticky else "w",
                padx=self.value_padx,
                pady=2,
            )
        else:
            self.widget = ttk.Label(parent, text=f"Unsupported worker control: {self.kind}")
            self.widget.grid(
                row=row,
                column=value_column,
                columnspan=self.value_columnspan,
                sticky=self.value_sticky if self.value_sticky else "w",
                padx=self.value_padx,
                pady=2,
            )
        self.value_widget = self.value_widget or self.widget
        if self.kind == "multi_select" and self.widget is not None:
            self.widget.bind("<<ListboxSelect>>", self._mark_dirty)
        elif self.kind == "advanced_json" and self.widget is not None:
            self.widget.bind("<KeyRelease>", self._mark_dirty)
        elif self.variable is not None and hasattr(self.variable, "trace_add"):
            self.variable.trace_add("write", self._mark_dirty)

    def _mark_dirty(self, *_args: Any) -> None:
        if not self._suppress_dirty:
            if self.missing:
                self.missing = False
                if self.label_widget is not None:
                    label = self._base_label
                    if self.derived:
                        label += " (derived)"
                    self.label_widget.configure(text=label)
                if callable(self._update_slider_display):
                    self._update_slider_display()
            self.dirty = True
            callback = getattr(self.host, "_on_workbench_field_dirty", None)
            if callable(callback):
                callback(self)

    def get_value(self) -> Any:
        if self.kind == "read_only":
            return None
        if self.kind == "structured_collection" and self.editor is not None:
            return self.editor.get_value()
        if self.variable is None:
            return None
        if self.kind == "multi_select":
            return [self.listbox_values[index] for index in self.variable.curselection()]
        if self.kind == "advanced_json":
            return self.variable.get("1.0", "end").strip()
        selected = self.variable.get()
        return self.option_map.get(str(selected), selected)

    def set_value(self, value: Any) -> None:
        self._suppress_dirty = True
        try:
            self._set_value(value)
        finally:
            self._suppress_dirty = False
        self.dirty = False

    def _set_value(self, value: Any) -> None:
        if self.kind == "read_only":
            if self.widget is not None:
                self.widget.configure(text=str(value or "unknown"))
            return
        if self.variable is None:
            return
        if self.kind == "boolean":
            self.variable.set(bool(value))
            return
        if self.kind == "multi_select":
            selected = {str(item) for item in value} if isinstance(value, list) else set()
            self.variable.selection_clear(0, "end")
            for index, item in enumerate(self.listbox_values):
                if str(item) in selected:
                    self.variable.selection_set(index)
            return
        if self.kind == "structured_collection" and self.editor is not None:
            return
        if self.kind == "advanced_json":
            self.variable.delete("1.0", "end")
            self.variable.insert("1.0", pretty(value if value is not None else {}))
            return
        if self.kind == "combobox":
            self.variable.set(self._label_by_value.get(str(value), str(value or "")))
            return
        if self.kind == "slider":
            minimum = float(self.control.get("min", 0))
            maximum = float(self.control.get("max", 1))
            try:
                numeric = float(value)
            except (TypeError, ValueError):
                numeric = (minimum + maximum) / 2
            self.variable.set(min(max(numeric, minimum), maximum))
            return
        if self.kind in {"integer", "spinbox"}:
            minimum = float(self.control.get("min", 0))
            maximum = float(self.control.get("max", 100))
            try:
                numeric = float(value)
            except (TypeError, ValueError):
                numeric = minimum
            numeric = min(max(numeric, minimum), maximum)
            if str(self.control.get("valueType") or "number") == "integer":
                numeric = int(numeric)
            self.variable.set(numeric)
            return
        self.variable.set(value if value is not None else "")

    def set_enabled(self, enabled: bool) -> None:
        if self.kind == "read_only" or self.widget is None:
            return
        if self.derived:
            enabled = False
        self._suppress_dirty = True
        try:
            if self.kind == "combobox":
                self.widget.configure(
                    state="readonly" if enabled else "disabled"
                )
                return
            state = "normal" if enabled else "disabled"
            self.widget.configure(state=state)
        except self.tk.TclError:
            pass
        finally:
            self._suppress_dirty = False

    def set_missing_state(self, missing: bool) -> None:
        """Mark a slider as an explicit runtime-only draft when SAVE data is absent."""

        if self.kind != "slider":
            return
        self._suppress_dirty = True
        try:
            self.missing = bool(missing)
            if self.label_widget is not None:
                label = self._base_label
                if self.missing:
                    label += " (runtime-only draft; source MISSING)"
                elif self.derived:
                    label += " (derived)"
                self.label_widget.configure(text=label)
            if self.missing and self.variable is not None:
                self.variable.set(0)
            if callable(self._update_slider_display):
                self._update_slider_display()
            self.dirty = False
        finally:
            self._suppress_dirty = False
