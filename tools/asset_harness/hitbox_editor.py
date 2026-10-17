"""Interactive editor for canonical radio hitboxes.

The editor deliberately writes the same ``modular.components`` hitboxes that
the simulator and future Lua implementation consume.  It does not maintain a
second geometry file or a source-catalog representation.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import os
import tempfile
import tkinter as tk
from dataclasses import dataclass
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Any, Callable, Iterable, Mapping

from PIL import Image

try:  # Support both ``python -m asset_harness.hitbox_editor`` and direct use.
    from .simulator.model import RadioSimulator
    from .simulator.registry import list_project_refs, project_path_for_device
    from .simulator.render import render_modular
except ImportError:  # pragma: no cover - exercised only by direct script use.
    from asset_harness.simulator.model import RadioSimulator
    from asset_harness.simulator.registry import list_project_refs, project_path_for_device
    from asset_harness.simulator.render import render_modular


Rect = list[int]
RectMap = dict[str, Rect]
SavedCallback = Callable[[Path], None]


def _rect(value: Any) -> Rect:
    """Normalize a JSON hitbox into an editable integer rectangle."""

    if isinstance(value, Mapping):
        value = [value.get(key, 0) for key in ("x", "y", "w", "h")]
    if not isinstance(value, (list, tuple)) or len(value) != 4:
        raise ValueError(f"hitbox must be [x, y, width, height], got {value!r}")
    return [int(round(float(item))) for item in value]


def find_hitbox_overlaps(rects: Mapping[str, Iterable[int]]) -> tuple[tuple[str, str], ...]:
    """Return positive-area overlaps, allowing rectangles to share an edge."""

    normalized = {str(name): _rect(value) for name, value in rects.items()}
    names = tuple(normalized)
    overlaps: list[tuple[str, str]] = []
    for index, first_name in enumerate(names):
        first = normalized[first_name]
        first_right = first[0] + max(0, first[2])
        first_bottom = first[1] + max(0, first[3])
        for second_name in names[index + 1 :]:
            second = normalized[second_name]
            second_right = second[0] + max(0, second[2])
            second_bottom = second[1] + max(0, second[3])
            if (
                max(first[0], second[0]) < min(first_right, second_right)
                and max(first[1], second[1]) < min(first_bottom, second_bottom)
            ):
                overlaps.append((first_name, second_name))
    return tuple(overlaps)


def _components(project: Mapping[str, Any]) -> Mapping[str, Any]:
    modular = project.get("modular")
    if not isinstance(modular, Mapping):
        raise ValueError("pilot JSON has no modular section")
    components = modular.get("components")
    if not isinstance(components, Mapping):
        raise ValueError("pilot JSON has no modular.components section")
    return components


def load_project_hitboxes(
    project: Mapping[str, Any], control_ids: Iterable[str]
) -> RectMap:
    """Read editable controls from the canonical modular component map."""

    components = _components(project)
    result: RectMap = {}
    for control_id in control_ids:
        component = components.get(control_id)
        if not isinstance(component, Mapping):
            raise ValueError(f"missing modular component {control_id!r}")
        value = component.get("hitbox", component.get("rect"))
        if value is None:
            raise ValueError(f"component {control_id!r} has no hitbox")
        result[str(control_id)] = _rect(value)
    return result


def update_project_hitboxes(project: dict[str, Any], rects: Mapping[str, Iterable[int]]) -> None:
    """Update only canonical modular component hitboxes in ``project``."""

    components = _components(project)
    for control_id, value in rects.items():
        component = components.get(control_id)
        if not isinstance(component, dict):
            raise ValueError(f"missing modular component {control_id!r}")
        component["hitbox"] = _rect(value)


def save_project_json(path: Path, project: Mapping[str, Any]) -> None:
    """Atomically persist a pilot project without leaving a partial JSON file."""

    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            json.dump(project, stream, indent=2, ensure_ascii=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


@dataclass
class _Drag:
    control_id: str
    mode: str
    handle: str | None
    start_source: tuple[float, float]
    start_rect: Rect


class HitboxEditorFrame(ttk.Frame):
    """Canvas editor embedded in a standalone window or the simulator GUI."""

    HANDLE_RADIUS = 7
    MIN_SIZE = 1

    def __init__(
        self,
        master: tk.Misc,
        *,
        device_id: str = "walkie_5",
        variant: str = "pristine",
        project_path: Path | None = None,
        on_saved: SavedCallback | None = None,
    ) -> None:
        super().__init__(master)
        self.on_saved = on_saved
        self._refs = {ref.device_id: ref for ref in list_project_refs()}
        if device_id not in self._refs:
            device_id = next(iter(self._refs), device_id)
        self.device_var = tk.StringVar(value=device_id)
        self.variant_var = tk.StringVar(value=variant)
        self.status_var = tk.StringVar(value="Select a control, then drag its box or handles.")
        self.selection_var = tk.StringVar(value="No control selected")
        self.coordinates_var = tk.StringVar(value="x —  y —  w —  h —")
        self.dirty = False
        self.project_path = Path(project_path) if project_path else None
        self.loaded_device_id: str | None = device_id if project_path else None
        self.project: dict[str, Any] = {}
        self.simulator: RadioSimulator | None = None
        self.control_ids: tuple[str, ...] = ()
        self.rects: RectMap = {}
        self.original_rects: RectMap = {}
        self.source_image: Image.Image | None = None
        self.photo: tk.PhotoImage | None = None
        self.source_size = (1, 1)
        self.image_origin = (0.0, 0.0)
        self.image_scale = 1.0
        self.zoom = 1.0
        self.drag: _Drag | None = None
        self._handle_boxes: dict[str, tuple[float, float, float, float]] = {}
        self._pan_cursor_active = False
        self._syncing_tree_selection = False

        self._build_widgets()
        editor_window = self.winfo_toplevel()
        editor_window.bind("<Control-s>", self._on_save_shortcut, add="+")
        editor_window.bind("<Escape>", self._on_escape, add="+")
        self._load_device(device_id, variant, confirm=False)

    def _build_widgets(self) -> None:
        self.columnconfigure(1, weight=1)
        self.rowconfigure(1, weight=1)

        toolbar = ttk.Frame(self)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
        toolbar.columnconfigure(8, weight=1)

        ttk.Label(toolbar, text="Device").grid(row=0, column=0, padx=(0, 4))
        self.device_combo = ttk.Combobox(
            toolbar,
            textvariable=self.device_var,
            values=tuple(self._refs),
            state="readonly",
            width=22,
        )
        self.device_combo.grid(row=0, column=1, padx=(0, 10))
        self.device_combo.bind("<<ComboboxSelected>>", self._on_device_changed)

        ttk.Label(toolbar, text="Variant").grid(row=0, column=2, padx=(0, 4))
        self.variant_combo = ttk.Combobox(
            toolbar,
            textvariable=self.variant_var,
            values=("pristine", "worn"),
            state="readonly",
            width=10,
        )
        self.variant_combo.grid(row=0, column=3, padx=(0, 10))
        self.variant_combo.bind("<<ComboboxSelected>>", self._on_variant_changed)

        ttk.Button(toolbar, text="Zoom −", command=lambda: self._change_zoom(-0.1)).grid(
            row=0, column=4, padx=2
        )
        ttk.Button(toolbar, text="Zoom +", command=lambda: self._change_zoom(0.1)).grid(
            row=0, column=5, padx=2
        )
        self.save_button = ttk.Button(toolbar, text="Save JSON", command=self._save)
        self.save_button.grid(row=0, column=6, padx=(10, 2))
        ttk.Button(toolbar, text="Revert", command=self._revert).grid(row=0, column=7, padx=2)
        ttk.Label(toolbar, textvariable=self.status_var, anchor="w").grid(
            row=0, column=8, sticky="ew", padx=(12, 0)
        )

        side = ttk.Frame(self, padding=(6, 0, 6, 6))
        side.grid(row=1, column=0, sticky="nsw")
        side.rowconfigure(1, weight=1)
        ttk.Label(side, text="HITBOX EDITOR", font=("TkDefaultFont", 11, "bold")).grid(
            row=0, column=0, sticky="w"
        )
        self.tree = ttk.Treeview(
            side,
            columns=("x", "y", "w", "h"),
            show=("tree", "headings"),
            selectmode="browse",
            height=22,
        )
        for column, heading, width in (
            ("x", "X", 46),
            ("y", "Y", 46),
            ("w", "W", 46),
            ("h", "H", 46),
        ):
            self.tree.heading(column, text=heading)
            self.tree.column(column, width=width, anchor="e", stretch=False)
        self.tree.heading("#0", text="Control")
        self.tree.column("#0", width=92, stretch=False)
        self.tree.grid(row=1, column=0, sticky="ns")
        tree_scroll = ttk.Scrollbar(side, orient="vertical", command=self.tree.yview)
        tree_scroll.grid(row=1, column=1, sticky="ns")
        self.tree.configure(yscrollcommand=tree_scroll.set)
        self.tree.bind("<<TreeviewSelect>>", self._on_tree_select)

        ttk.Separator(side).grid(row=2, column=0, columnspan=2, sticky="ew", pady=8)
        ttk.Label(side, textvariable=self.selection_var).grid(row=3, column=0, columnspan=2, sticky="w")
        ttk.Label(side, textvariable=self.coordinates_var).grid(
            row=4, column=0, columnspan=2, sticky="w", pady=(2, 8)
        )
        ttk.Label(
            side,
            text=(
                "Drag inside a box to move it. Drag a corner or edge handle to resize.\n"
                "Mouse wheel scrolls vertically; Shift+wheel scrolls horizontally.\n"
                "Hold the middle mouse button to pan like Photoshop.\n"
                "Red boxes overlap another control. Save is disabled until overlaps are fixed.\n"
                "All coordinates are written to modular.components.*.hitbox."
            ),
            justify="left",
            wraplength=250,
        ).grid(row=5, column=0, columnspan=2, sticky="w")

        canvas_frame = ttk.Frame(self, padding=(0, 0, 6, 6))
        canvas_frame.grid(row=1, column=1, sticky="nsew")
        canvas_frame.rowconfigure(0, weight=1)
        canvas_frame.columnconfigure(0, weight=1)
        self.canvas = tk.Canvas(
            canvas_frame,
            width=900,
            height=780,
            background="#252c35",
            highlightthickness=0,
            cursor="crosshair",
            confine=True,
            xscrollincrement=1,
            yscrollincrement=1,
        )
        self.canvas.grid(row=0, column=0, sticky="nsew")
        x_scroll = ttk.Scrollbar(canvas_frame, orient="horizontal", command=self.canvas.xview)
        y_scroll = ttk.Scrollbar(canvas_frame, orient="vertical", command=self.canvas.yview)
        x_scroll.grid(row=1, column=0, sticky="ew")
        y_scroll.grid(row=0, column=1, sticky="ns")
        self.canvas.configure(xscrollcommand=x_scroll.set, yscrollcommand=y_scroll.set)
        self.canvas.bind("<ButtonPress-1>", self._on_pointer_down)
        self.canvas.bind("<B1-Motion>", self._on_pointer_move)
        self.canvas.bind("<ButtonRelease-1>", self._on_pointer_up)
        self.canvas.bind("<MouseWheel>", self._on_vertical_scroll)
        self.canvas.bind("<Shift-MouseWheel>", self._on_horizontal_scroll)
        self.canvas.bind("<Button-4>", lambda event: self._scroll_canvas(event, -1, horizontal=False))
        self.canvas.bind("<Button-5>", lambda event: self._scroll_canvas(event, 1, horizontal=False))
        self.canvas.bind("<Shift-Button-4>", lambda event: self._scroll_canvas(event, -1, horizontal=True))
        self.canvas.bind("<Shift-Button-5>", lambda event: self._scroll_canvas(event, 1, horizontal=True))
        self.canvas.bind("<ButtonPress-2>", self._on_pan_start)
        self.canvas.bind("<B2-Motion>", self._on_pan_move)
        self.canvas.bind("<ButtonRelease-2>", self._on_pan_end)
        self.canvas.bind("<Configure>", lambda _event: self._draw())

    def _interactive_control_ids(self) -> tuple[str, ...]:
        if self.simulator is None:
            return ()
        # This is the same canonical policy consumed by RadioSimulator.geometry.
        policy = self.simulator._project_simulator_policy()  # noqa: SLF001
        components = self.project.get("modular", {}).get("components", {})
        return tuple(
            str(item)
            for item in policy.get("interactive_controls") or ()
            if str(item) in components
        )

    def _path_for_device(self, device_id: str) -> Path:
        if (
            self.project_path is not None
            and self.loaded_device_id == device_id
            and self.project_path.exists()
        ):
            return self.project_path
        path = project_path_for_device(device_id)
        if path is None:
            raise FileNotFoundError(f"no canonical pilot project for {device_id}")
        return Path(path)

    def _load_device(self, device_id: str, variant: str, *, confirm: bool) -> bool:
        if confirm and self.dirty:
            decision = messagebox.askyesnocancel(
                "Unsaved hitboxes",
                "Save the current hitbox changes before switching devices?",
                parent=self.winfo_toplevel(),
            )
            if decision is None:
                return False
            if decision and not self._save():
                return False

        path = self._path_for_device(device_id)
        project = json.loads(path.read_text(encoding="utf-8"))
        self.device_var.set(device_id)
        self.variant_var.set(variant)
        self.project_path = path
        self.loaded_device_id = device_id
        self.project = project
        self.simulator = RadioSimulator(device_id, variant=variant, project_path=path)
        self.control_ids = self._interactive_control_ids()
        self.rects = load_project_hitboxes(project, self.control_ids)
        self.original_rects = {name: value[:] for name, value in self.rects.items()}
        self.dirty = False
        self.drag = None
        self._render()
        self._refresh_tree()
        self._select_control(self.control_ids[0] if self.control_ids else None)
        self.status_var.set(f"Loaded {path.name}; drag or resize a box, then save JSON.")
        return True

    def _render(self) -> None:
        if self.project_path is None or self.simulator is None:
            return
        image, _metadata = render_modular(
            self.project_path,
            self.project,
            variant=self.variant_var.get(),
            states=self.simulator.modular_state_selection(),
            hidden_components=self.simulator.modular_hidden_components(),
        )
        self.source_image = image.convert("RGBA")
        self.source_size = self.source_image.size
        self.after_idle(self._draw)

    def _draw(self) -> None:
        if self.source_image is None:
            return
        # Fit is calculated against the viewport, while the canvas itself
        # remains viewport-sized.  At zoom > 1 the image therefore grows into
        # the scrollregion instead of forcing the canvas to grow with it.
        canvas_width = max(1, self.canvas.winfo_width() - 20)
        canvas_height = max(1, self.canvas.winfo_height() - 20)
        fit = min(canvas_width / self.source_size[0], canvas_height / self.source_size[1])
        self.image_scale = max(0.05, fit * self.zoom)
        image_size = (
            max(1, round(self.source_size[0] * self.image_scale)),
            max(1, round(self.source_size[1] * self.image_scale)),
        )
        resized = self.source_image.resize(image_size, Image.Resampling.LANCZOS)
        png_buffer = io.BytesIO()
        resized.save(png_buffer, format="PNG")
        self.photo = tk.PhotoImage(data=base64.b64encode(png_buffer.getvalue()).decode("ascii"))
        self.image_origin = (10.0, 10.0)
        self.canvas.delete("all")
        self.canvas.create_image(*self.image_origin, image=self.photo, anchor="nw", tags=("art",))
        self.canvas.configure(
            scrollregion=(0, 0, image_size[0] + 20, image_size[1] + 20)
        )
        self._draw_hitboxes()

    def _source_to_canvas(self, x: float, y: float) -> tuple[float, float]:
        return (
            self.image_origin[0] + x * self.image_scale,
            self.image_origin[1] + y * self.image_scale,
        )

    def _canvas_to_source(self, x: float, y: float) -> tuple[float, float]:
        return (
            (self.canvas.canvasx(x) - self.image_origin[0]) / self.image_scale,
            (self.canvas.canvasy(y) - self.image_origin[1]) / self.image_scale,
        )

    def _draw_hitboxes(self) -> None:
        self._handle_boxes = {}
        overlaps = find_hitbox_overlaps(self.rects)
        colliding = {name for pair in overlaps for name in pair}
        for control_id in self.control_ids:
            x, y, width, height = self.rects[control_id]
            x1, y1 = self._source_to_canvas(x, y)
            x2, y2 = self._source_to_canvas(x + width, y + height)
            selected = control_id == self.selection_var.get()
            color = "#ff5858" if control_id in colliding else ("#ffd34d" if selected else "#56e0a1")
            line_width = 3 if selected else 2
            self.canvas.create_rectangle(
                x1,
                y1,
                x2,
                y2,
                outline=color,
                width=line_width,
                tags=("hitbox", control_id),
            )
            self.canvas.create_text(
                x1 + 4,
                y1 + 2,
                text=control_id,
                anchor="nw",
                fill=color,
                tags=("hitbox", control_id),
            )
            if selected:
                for handle, hx, hy in self._handle_points(x, y, width, height):
                    cx, cy = self._source_to_canvas(hx, hy)
                    radius = max(4.0, self.HANDLE_RADIUS)
                    self._handle_boxes[handle] = (
                        cx - radius,
                        cy - radius,
                        cx + radius,
                        cy + radius,
                    )
                    self.canvas.create_rectangle(
                        cx - radius,
                        cy - radius,
                        cx + radius,
                        cy + radius,
                        fill="#ffd34d",
                        outline="#1b1f24",
                        tags=("handle", control_id),
                    )
        self._update_status(overlaps)

    @staticmethod
    def _handle_points(x: int, y: int, width: int, height: int) -> tuple[tuple[str, int, int], ...]:
        right = x + width
        bottom = y + height
        return (
            ("nw", x, y),
            ("n", x + width // 2, y),
            ("ne", right, y),
            ("e", right, y + height // 2),
            ("se", right, bottom),
            ("s", x + width // 2, bottom),
            ("sw", x, bottom),
            ("w", x, y + height // 2),
        )

    def _refresh_tree(self) -> None:
        for child in self.tree.get_children():
            self.tree.delete(child)
        for control_id in self.control_ids:
            self.tree.insert("", "end", iid=control_id, text=control_id, values=tuple(self.rects[control_id]))
        self._draw()

    def _select_control(self, control_id: str | None) -> None:
        if control_id is None or control_id not in self.rects:
            self.selection_var.set("No control selected")
            self.coordinates_var.set("x —  y —  w —  h —")
            self._draw()
            return
        self.selection_var.set(control_id)
        # Treeview.selection_set emits ``<<TreeviewSelect>>``.  The callback
        # selects the same control through this method, so blindly calling it
        # here creates an endless event/redraw loop once Tk's mainloop starts.
        # Only synchronize the tree when its selection actually differs, and
        # suppress the corresponding callback while doing so.
        if tuple(self.tree.selection()) != (control_id,):
            self._syncing_tree_selection = True
            try:
                self.tree.selection_set(control_id)
            finally:
                self._syncing_tree_selection = False
        self.tree.see(control_id)
        self._update_coordinate_label()
        self._draw()

    def _on_tree_select(self, _event: tk.Event[tk.Misc]) -> None:
        if self._syncing_tree_selection:
            return
        selected = self.tree.selection()
        control_id = selected[0] if selected else None
        if control_id == self.selection_var.get():
            return
        self._select_control(control_id)

    def _on_device_changed(self, _event: tk.Event[tk.Misc]) -> None:
        self._load_device(self.device_var.get(), self.variant_var.get(), confirm=True)

    def _on_variant_changed(self, _event: tk.Event[tk.Misc]) -> None:
        self._render()
        self.status_var.set("Variant preview changed; hitboxes are shared by both variants.")

    def _change_zoom(self, delta: float) -> None:
        self.zoom = min(2.0, max(0.35, round(self.zoom + delta, 2)))
        self.status_var.set(f"Zoom {round(self.zoom * 100)}% · drag boxes; middle mouse pans")
        self._draw()

    def _on_vertical_scroll(self, event: tk.Event[tk.Misc]) -> str:
        raw_delta = getattr(event, "delta", 0)
        direction = -1 if raw_delta > 0 else 1
        return self._scroll_canvas(event, direction, horizontal=False)

    def _on_horizontal_scroll(self, event: tk.Event[tk.Misc]) -> str:
        raw_delta = getattr(event, "delta", 0)
        direction = -1 if raw_delta > 0 else 1
        return self._scroll_canvas(event, direction, horizontal=True)

    def _scroll_canvas(
        self,
        _event: tk.Event[tk.Misc],
        direction: int,
        *,
        horizontal: bool,
    ) -> str:
        command = self.canvas.xview_scroll if horizontal else self.canvas.yview_scroll
        command(direction, "units")
        return "break"

    def _on_pan_start(self, event: tk.Event[tk.Misc]) -> str:
        self.canvas.focus_set()
        self.canvas.scan_mark(event.x, event.y)
        self._pan_cursor_active = True
        self.canvas.configure(cursor="fleur")
        return "break"

    def _on_pan_move(self, event: tk.Event[tk.Misc]) -> str:
        if self._pan_cursor_active:
            self.canvas.scan_dragto(event.x, event.y, gain=1)
        return "break"

    def _on_pan_end(self, _event: tk.Event[tk.Misc]) -> str:
        self._pan_cursor_active = False
        self.canvas.configure(cursor="crosshair")
        return "break"

    def _on_save_shortcut(self, _event: tk.Event[tk.Misc]) -> str:
        self._save()
        return "break"

    def _on_escape(self, _event: tk.Event[tk.Misc]) -> str:
        self.drag = None
        self._select_control(None)
        return "break"

    def _event_source_point(self, event: tk.Event[tk.Misc]) -> tuple[float, float]:
        return self._canvas_to_source(event.x, event.y)

    def _handle_at(self, event: tk.Event[tk.Misc]) -> str | None:
        canvas_x = self.canvas.canvasx(event.x)
        canvas_y = self.canvas.canvasy(event.y)
        for handle, (x1, y1, x2, y2) in self._handle_boxes.items():
            if x1 <= canvas_x <= x2 and y1 <= canvas_y <= y2:
                return handle
        return None

    def _hit_controls(self, source_x: float, source_y: float) -> list[str]:
        return [
            control_id
            for control_id in self.control_ids
            if (
                self.rects[control_id][0] <= source_x < self.rects[control_id][0] + self.rects[control_id][2]
                and self.rects[control_id][1] <= source_y < self.rects[control_id][1] + self.rects[control_id][3]
            )
        ]

    def _on_pointer_down(self, event: tk.Event[tk.Misc]) -> None:
        self.canvas.focus_set()
        source_x, source_y = self._event_source_point(event)
        handle = self._handle_at(event)
        selected = self.selection_var.get()
        if selected not in self.rects:
            selected = ""
        candidates = self._hit_controls(source_x, source_y)
        if handle is not None and selected in self.rects:
            control_id = selected
            mode = "resize"
        elif candidates:
            control_id = selected if selected in candidates else candidates[-1]
            self._select_control(control_id)
            handle = self._handle_at(event)
            mode = "resize" if handle is not None else "move"
        else:
            self._select_control(None)
            return
        self.drag = _Drag(
            control_id=control_id,
            mode=mode,
            handle=handle,
            start_source=(source_x, source_y),
            start_rect=self.rects[control_id][:],
        )

    def _on_pointer_move(self, event: tk.Event[tk.Misc]) -> None:
        if self.drag is None:
            return
        source_x, source_y = self._event_source_point(event)
        control_id = self.drag.control_id
        start_x, start_y = self.drag.start_source
        start_rect = self.drag.start_rect
        if self.drag.mode == "move":
            dx = round(source_x - start_x)
            dy = round(source_y - start_y)
            self.rects[control_id] = self._clamp_rect(
                [start_rect[0] + dx, start_rect[1] + dy, start_rect[2], start_rect[3]]
            )
        else:
            self.rects[control_id] = self._resize_rect(start_rect, self.drag.handle or "se", source_x, source_y)
        self.dirty = any(
            self.rects[name] != self.original_rects.get(name)
            for name in self.control_ids
        )
        self._update_tree_row(control_id)
        self._update_coordinate_label()
        self._draw()

    def _on_pointer_up(self, _event: tk.Event[tk.Misc]) -> None:
        self.drag = None

    def _clamp_rect(self, value: Iterable[int]) -> Rect:
        x, y, width, height = _rect(value)
        canvas_width, canvas_height = self.source_size
        width = max(self.MIN_SIZE, min(width, canvas_width))
        height = max(self.MIN_SIZE, min(height, canvas_height))
        x = max(0, min(x, canvas_width - width))
        y = max(0, min(y, canvas_height - height))
        return [x, y, width, height]

    def _resize_rect(self, start: Rect, handle: str, source_x: float, source_y: float) -> Rect:
        left, top, width, height = start
        right, bottom = left + width, top + height
        x = int(round(source_x))
        y = int(round(source_y))
        if "w" in handle:
            left = min(x, right - self.MIN_SIZE)
        if "e" in handle:
            right = max(x, left + self.MIN_SIZE)
        if "n" in handle:
            top = min(y, bottom - self.MIN_SIZE)
        if "s" in handle:
            bottom = max(y, top + self.MIN_SIZE)
        return self._clamp_rect([left, top, right - left, bottom - top])

    def _update_tree_row(self, control_id: str) -> None:
        if self.tree.exists(control_id):
            self.tree.item(control_id, values=tuple(self.rects[control_id]))

    def _update_coordinate_label(self) -> None:
        control_id = self.selection_var.get()
        rect = self.rects.get(control_id)
        if rect is None:
            self.coordinates_var.set("x —  y —  w —  h —")
        else:
            self.coordinates_var.set(f"x {rect[0]}  y {rect[1]}  w {rect[2]}  h {rect[3]}")

    def _update_status(self, overlaps: tuple[tuple[str, str], ...] | None = None) -> None:
        if overlaps is None:
            overlaps = find_hitbox_overlaps(self.rects)
        self.save_button.configure(state="disabled" if overlaps else "normal")
        if overlaps:
            pairs = ", ".join(f"{first}/{second}" for first, second in overlaps[:3])
            suffix = " …" if len(overlaps) > 3 else ""
            self.status_var.set(f"Overlapping hitboxes: {pairs}{suffix}. Fix before saving.")
        elif self.dirty:
            self.status_var.set("Unsaved hitbox changes.")

    def _save(self) -> bool:
        if self.project_path is None:
            return False
        overlaps = find_hitbox_overlaps(self.rects)
        if overlaps:
            self._update_status(overlaps)
            messagebox.showwarning(
                "Overlapping hitboxes",
                "Fix the red overlapping rectangles before saving.\n\n"
                + "\n".join(f"{first} / {second}" for first, second in overlaps),
                parent=self.winfo_toplevel(),
            )
            return False
        update_project_hitboxes(self.project, self.rects)
        save_project_json(self.project_path, self.project)
        self.original_rects = {name: value[:] for name, value in self.rects.items()}
        self.dirty = False
        self.status_var.set(f"Saved canonical hitboxes to {self.project_path.name}.")
        if self.on_saved is not None:
            self.on_saved(self.project_path)
        return True

    def _revert(self) -> None:
        if self.project_path is None:
            return
        self._load_device(self.device_var.get(), self.variant_var.get(), confirm=False)


def open_hitbox_editor(
    parent: tk.Misc,
    *,
    device_id: str = "walkie_5",
    variant: str = "pristine",
    project_path: Path | None = None,
    on_saved: SavedCallback | None = None,
) -> tuple[tk.Toplevel, HitboxEditorFrame]:
    """Open the editor as a child window and return both window and frame."""

    window = tk.Toplevel(parent)
    window.title("Radio OS Hitbox Editor — canonical pilot JSON")
    window.geometry("1280x900")
    window.minsize(980, 680)
    frame = HitboxEditorFrame(
        window,
        device_id=device_id,
        variant=variant,
        project_path=project_path,
        on_saved=on_saved,
    )
    frame.pack(fill="both", expand=True)
    return window, frame


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", default="walkie_5")
    parser.add_argument("--variant", choices=("pristine", "worn"), default="pristine")
    args = parser.parse_args(argv)
    root = tk.Tk()
    root.title("Radio OS Hitbox Editor — canonical pilot JSON")
    root.geometry("1280x900")
    root.minsize(980, 680)
    frame = HitboxEditorFrame(root, device_id=args.device, variant=args.variant)
    frame.pack(fill="both", expand=True)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
