#!/usr/bin/env python3
"""Interactive human/LLM client for the offline radio simulator."""

from __future__ import annotations

import json
import base64
import io
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import tkinter as tk
from tkinter import ttk

from asset_harness.simulator import RadioSimulator
from asset_harness.simulator.catalog import normalize_variant
from asset_harness.simulator.registry import list_project_refs, project_path_for_device
from asset_harness.simulator.render import compose_canvas, render_device


class RadioSimulatorApp(tk.Tk):
    """Thin view/controller around :class:`RadioSimulator`."""

    def __init__(
        self,
        *,
        device_id: str = "walkie_5",
        variant: str = "pristine",
        project_path: Path | None = None,
        mode: str = "auto",
    ) -> None:
        super().__init__()
        self.title("Psychopatz Radio OS Simulator")
        self.geometry("1280x860")
        self.minsize(980, 680)

        self.render_mode = self._resolve_mode(mode, project_path, device_id)
        self.project_path = self._resolve_project(project_path, device_id)
        if self.project_path is None:
            raise FileNotFoundError(
                f"no canonical radio pilot project exists for device {device_id!r}; "
                "the GUI only loads authored pilot projects"
            )
        self.simulator = self._new_simulator(variant=variant)
        self.photo: tk.PhotoImage | None = None
        self.image_origin = (0, 0)
        self.image_scale = 1.0
        self.hitboxes: list[dict[str, Any]] = []
        self.lcd_rect: list[int] = [0, 0, 0, 0]
        self.source_offset = (0, 0)
        self.captured_control: str | None = None
        self.drag_last_source: tuple[float, float] | None = None
        self.drag_remainder = 0.0
        self._redraw_after_id: str | None = None
        self._last_render_key: tuple[Any, ...] | None = None
        self._source_size_cache: dict[tuple[str, str, str, str], tuple[int, int]] = {}

        self.device_var = tk.StringVar(value=self.simulator.device.label)
        self.variant_var = tk.StringVar(value="pristine" if normalize_variant(variant) == "clean" else "worn")
        self.pilot_var = tk.StringVar(value=self._mode_label())
        self.zoom_var = tk.DoubleVar(value=1.0)
        self.debug_var = tk.BooleanVar(value=False)
        self.command_var = tk.StringVar(value='{"event":"press","control":"power"}')
        self.status_var = tk.StringVar(value="Ready · press Power or send a JSON event")

        self._build_ui()
        self._install_hitbox_editor_button()
        self._bind_keys()
        self.after(0, self._redraw)

    @staticmethod
    def _resolve_mode(mode: str, project_path: Path | None, device_id: str) -> str:
        normalized = str(mode or "auto").strip().lower()
        if normalized not in {"auto", "modular"}:
            raise ValueError("mode must be auto or modular; only canonical pilots are supported")
        return "modular"

    @staticmethod
    def _discover_project(device_id: str) -> Path | None:
        canonical = project_path_for_device(device_id)
        return canonical.resolve() if canonical is not None and canonical.is_file() else None

    @classmethod
    def _resolve_project(cls, project_path: Path | None, device_id: str) -> Path | None:
        target = project_path.expanduser() if project_path is not None else cls._discover_project(device_id)
        return target.resolve() if target is not None else None

    def _new_simulator(self, *, variant: str | None = None) -> RadioSimulator:
        selected_variant = variant or self.variant_var.get() if hasattr(self, "variant_var") else variant or "pristine"
        if self.project_path is None:
            raise RuntimeError("a canonical pilot project is required to create the simulator")
        return RadioSimulator(project_path=self.project_path, variant=selected_variant)

    def _mode_label(self) -> str:
        if self.project_path is None:
            return "Canonical pilot"
        project_id = self.project_path.stem.removesuffix("_pilot")
        return f"Canonical pilot · {project_id}"

    def _device_labels(self) -> list[str]:
        return [project.label for project in list_project_refs()]

    def _sync_mode_controls(self) -> None:
        self.device_combo.configure(values=self._device_labels(), state="readonly")

    def _build_ui(self) -> None:
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        toolbar = ttk.Frame(self, padding=(10, 8))
        toolbar.grid(row=0, column=0, sticky="ew")
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Device").grid(row=0, column=0, padx=(0, 5))
        self.device_combo = ttk.Combobox(
            toolbar,
            textvariable=self.device_var,
            values=self._device_labels(),
            state="readonly",
            width=34,
        )
        self.device_combo.grid(row=0, column=1, sticky="w", padx=(0, 12))
        self.device_combo.bind("<<ComboboxSelected>>", self._device_changed)
        ttk.Label(toolbar, text="Pilot").grid(row=0, column=2, padx=(0, 5))
        ttk.Label(toolbar, textvariable=self.pilot_var, width=27, anchor="w").grid(row=0, column=3, padx=(0, 12))
        ttk.Label(toolbar, text="Variant").grid(row=0, column=4, padx=(0, 5))
        self.variant_combo = ttk.Combobox(toolbar, textvariable=self.variant_var, values=("pristine", "worn"), state="readonly", width=9)
        self.variant_combo.grid(row=0, column=5, padx=(0, 12))
        self.variant_combo.bind("<<ComboboxSelected>>", self._variant_changed)
        # Keep the authoring entry point in the main toolbar.  It must not live
        # in ``action_frame``: that frame contains simulated device presses,
        # and putting an editor command there made it easy to miss or confuse
        # with a physical control.
        ttk.Button(toolbar, text="Edit hitboxes", command=self._open_hitbox_editor).grid(
            row=0, column=6, padx=(0, 8)
        )
        ttk.Button(toolbar, text="Reset", command=self._reset).grid(row=0, column=7, padx=(0, 12))
        ttk.Label(toolbar, text="Zoom").grid(row=0, column=8, padx=(0, 5))
        ttk.Scale(toolbar, from_=0.5, to=1.6, variable=self.zoom_var, command=lambda _value: self._request_redraw()).grid(row=0, column=9, padx=(0, 12), sticky="ew")
        ttk.Checkbutton(toolbar, text="Show hitboxes", variable=self.debug_var, command=self._request_redraw).grid(row=0, column=10, padx=(0, 8))

        body = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        body.grid(row=1, column=0, sticky="nsew", padx=10, pady=(0, 10))

        preview_frame = ttk.Frame(body, padding=8)
        preview_frame.columnconfigure(0, weight=1)
        preview_frame.rowconfigure(0, weight=1)
        self.canvas = tk.Canvas(preview_frame, background="#20252b", highlightthickness=1, highlightbackground="#47515c")
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.canvas.bind("<Button-1>", self._canvas_button_down)
        self.canvas.bind("<ButtonRelease-1>", self._canvas_button_up)
        self.canvas.bind("<B1-Motion>", self._canvas_motion)
        self.canvas.bind("<MouseWheel>", self._canvas_wheel)
        self.canvas.bind("<Button-4>", lambda event: self._canvas_wheel(event, direction=1))
        self.canvas.bind("<Button-5>", lambda event: self._canvas_wheel(event, direction=-1))
        self.canvas.bind("<FocusOut>", self._cancel_pointer)
        body.add(preview_frame, weight=3)

        side = ttk.Frame(body, padding=(8, 8, 0, 8))
        body.add(side, weight=2)
        side.columnconfigure(0, weight=1)
        side.rowconfigure(1, weight=1)
        side.rowconfigure(6, weight=2)
        ttk.Label(side, text="Simulation state", font=("TkDefaultFont", 11, "bold")).grid(row=0, column=0, sticky="w", pady=(0, 4))
        self.state_text = tk.Text(side, height=11, width=48, wrap="none", background="#171a1f", foreground="#e6edf3", insertbackground="#e6edf3", relief="flat")
        self.state_text.grid(row=1, column=0, sticky="nsew", pady=(0, 8))
        self.state_text.configure(state="disabled")

        self.action_frame = ttk.Frame(side)
        self.action_frame.grid(row=2, column=0, sticky="ew", pady=(0, 8))
        self._refresh_action_buttons()

        ttk.Label(side, text="LLM event (same command path as buttons)").grid(row=3, column=0, sticky="nw", pady=(0, 4))
        command_frame = ttk.Frame(side)
        command_frame.grid(row=4, column=0, sticky="ew", pady=(0, 8))
        command_frame.columnconfigure(0, weight=1)
        ttk.Entry(command_frame, textvariable=self.command_var).grid(row=0, column=0, sticky="ew", padx=(0, 5))
        ttk.Button(command_frame, text="Send", command=self._send_command).grid(row=0, column=1)

        ttk.Label(side, text="Event log", font=("TkDefaultFont", 11, "bold")).grid(row=5, column=0, sticky="nw", pady=(0, 4))
        self.log_text = tk.Text(side, width=48, wrap="word", background="#171a1f", foreground="#9fb3c8", insertbackground="#e6edf3", relief="flat")
        self.log_text.grid(row=6, column=0, sticky="nsew")
        self.log_text.configure(state="disabled")

        ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", padding=(8, 4)).grid(row=2, column=0, sticky="ew")
        self._sync_mode_controls()

    def _refresh_action_buttons(self) -> None:
        """Expose exactly the active project's physical controls as commands."""

        for child in self.action_frame.winfo_children():
            child.destroy()
        controls = list(self.simulator.geometry.controls)
        preferred = {name: index for index, name in enumerate(("power", "up", "down", "left", "ok", "right", "back", "home"))}
        controls.sort(key=lambda control: (preferred.get(control.id, len(preferred)), control.id))
        for column in range(4):
            self.action_frame.columnconfigure(column, weight=1)
        for index, control in enumerate(controls):
            row, column = divmod(index, 4)
            self.action_frame.rowconfigure(row, weight=1)
            label = control.label if control.label != control.id else control.id.replace("_", " ").title()
            ttk.Button(
                self.action_frame,
                text=label,
                command=lambda control_id=control.id: self._dispatch({"event": "press", "control": control_id}),
            ).grid(row=row, column=column, sticky="ew", padx=2, pady=(0 if row == 0 else 4, 0))

    def _bind_keys(self) -> None:
        self.bind("<F5>", lambda _event: self._reset())
        self.bind("<Left>", lambda _event: self._dispatch({"event": "press", "control": "previous"}))
        self.bind("<Right>", lambda _event: self._dispatch({"event": "press", "control": "next"}))
        self.bind("<Return>", lambda _event: self._dispatch({"event": "press", "control": "center"}))
        self.bind("<Escape>", lambda _event: self._dispatch({"event": "press", "action": "back"}))
        self.bind("<space>", lambda _event: self._dispatch({"event": "press", "control": "power"}))

    def _device_changed(self, _event: tk.Event) -> None:
        selected = self.device_var.get()
        project = next((item for item in list_project_refs() if item.label == selected), None)
        if project is None:
            self._record_status(f"No canonical pilot project was found for {selected}")
            return
        self.project_path = project.path
        self.captured_control = None
        self.simulator = self._new_simulator()
        self.pilot_var.set(self._mode_label())
        self._refresh_action_buttons()
        self._record_status(f"Selected {project.label} pilot")
        self._request_redraw()

    def _variant_changed(self, _event: tk.Event) -> None:
        self.simulator.reset(variant=self.variant_var.get())
        self._record_status(f"Selected {self.variant_var.get()} artwork")
        self._request_redraw()

    def _reset(self) -> None:
        self.simulator.reset()
        self.captured_control = None
        self._record_status("Reset simulator state")
        self._request_redraw()

    def _send_command(self) -> None:
        try:
            event = json.loads(self.command_var.get())
        except json.JSONDecodeError as error:
            self._record_status(f"Invalid JSON: {error.msg}")
            return
        self._dispatch(event)

    def _dispatch(self, event: dict[str, Any]) -> None:
        try:
            self.simulator.dispatch(event)
        except (TypeError, ValueError, OSError) as error:
            self._record_status(f"Rejected event: {error}")
            self._append_log({"rejected": event, "error": str(error)})
            return
        self._record_status(f"Applied {event.get('event', event.get('type', 'command'))}")
        self._request_redraw()

    def _image_point(self, event: tk.Event) -> tuple[float, float]:
        return (event.x - self.image_origin[0], event.y - self.image_origin[1])

    def _source_point(self, event: tk.Event) -> tuple[float, float]:
        local_x, local_y = self._image_point(event)
        scale = max(self.image_scale, 0.01)
        return (local_x / scale + self.source_offset[0], local_y / scale + self.source_offset[1])

    def _hit_control(self, local_x: float, local_y: float) -> dict[str, Any] | None:
        for control in self.hitboxes:
            left, top, width, height = control["rect"]
            if left <= local_x < left + width and top <= local_y < top + height:
                return control
        return None

    def _in_lcd(self, local_x: float, local_y: float) -> bool:
        left, top, width, height = self.lcd_rect
        return left <= local_x < left + width and top <= local_y < top + height

    def _canvas_button_down(self, event: tk.Event) -> str:
        local_x, local_y = self._image_point(event)
        control = self._hit_control(local_x, local_y)
        if control is not None:
            self.captured_control = str(control["id"])
            self.drag_last_source = self._source_point(event)
            self.drag_remainder = 0.0
            self.canvas.focus_set()
            self.canvas.grab_set()
            self._dispatch({"event": "pointer_down", "control": self.captured_control})
            return "break"
        if self._in_lcd(local_x, local_y):
            source_x, source_y = self._source_point(event)
            self._dispatch({"event": "screen_click", "x": source_x, "y": source_y})
        return "break"

    def _canvas_button_up(self, _event: tk.Event) -> str:
        if self.captured_control is not None:
            control = self.captured_control
            self.captured_control = None
            self.drag_last_source = None
            self.drag_remainder = 0.0
            try:
                self._dispatch({"event": "pointer_up", "control": control})
            finally:
                try:
                    self.canvas.grab_release()
                except tk.TclError:
                    pass
        return "break"

    def _cancel_pointer(self, _event: tk.Event | None = None) -> str:
        if self.captured_control is not None:
            self._dispatch({"event": "pointer_cancel", "reason": "focus_loss"})
            self.captured_control = None
            self.drag_last_source = None
            self.drag_remainder = 0.0
            try:
                self.canvas.grab_release()
            except tk.TclError:
                pass
        return "break"

    def _canvas_motion(self, event: tk.Event) -> str:
        if self.captured_control is None or self.drag_last_source is None:
            return "break"
        control = next((item for item in self.hitboxes if item["id"] == self.captured_control), None)
        current = self._source_point(event)
        previous = self.drag_last_source
        self.drag_last_source = current
        if control is None or control.get("kind") not in {"rotary", "knob"}:
            return "break"
        delta_pixels = previous[1] - current[1]
        if abs(delta_pixels) < abs(previous[0] - current[0]):
            delta_pixels = current[0] - previous[0]
        self.drag_remainder += delta_pixels
        steps = int(self.drag_remainder / 12)
        if steps:
            self.drag_remainder -= steps * 12
            self._dispatch({"event": "pointer_move", "control": self.captured_control, "delta": max(-16, min(16, steps))})
        return "break"

    def _canvas_wheel(self, event: tk.Event, direction: int | None = None) -> str:
        local_x, local_y = self._image_point(event)
        control = self._hit_control(local_x, local_y)
        control_id = control["id"] if control is not None else self.captured_control
        if control_id is None:
            return "break"
        if direction is None:
            raw_delta = getattr(event, "delta", 0)
            direction = 1 if raw_delta > 0 else -1 if raw_delta < 0 else 0
        if direction:
            self._dispatch({"event": "wheel", "control": control_id, "delta": direction})
        return "break"

    def _request_redraw(self) -> None:
        """Coalesce pointer and slider events into one bounded refresh."""

        if self._redraw_after_id is None:
            self._redraw_after_id = self.after(16, self._scheduled_redraw)

    def _scheduled_redraw(self) -> None:
        self._redraw_after_id = None
        self._redraw()

    def _open_hitbox_editor(self) -> None:
        """Open the editor backed by this simulator's canonical pilot JSON."""

        try:
            from .hitbox_editor import open_hitbox_editor
        except ImportError:  # pragma: no cover - direct script fallback.
            from asset_harness.hitbox_editor import open_hitbox_editor

        existing = getattr(self, "_hitbox_editor_window", None)
        if existing is not None and existing.winfo_exists():
            existing.deiconify()
            existing.lift()
            return

        def on_saved(_path: Path) -> None:
            self.simulator = self._new_simulator(variant=self.variant_var.get())
            self._redraw()
            self.status_var.set("Reloaded saved hitboxes from the canonical pilot JSON")

        window, _editor = open_hitbox_editor(
            self,
            device_id=self.simulator.device.id,
            variant=self.variant_var.get(),
            project_path=self.project_path,
            on_saved=on_saved,
        )
        self._hitbox_editor_window = window

    def _install_hitbox_editor_button(self) -> None:
        """Retain a stable widget reference for smoke tests and integrations.

        The actual button is created with the rest of the top toolbar in
        ``_build_ui``.  Older code appended it to the simulation action grid;
        that made the authoring control invisible on narrower windows and
        incorrectly grouped it with physical button presses.
        """

        toolbar = self.device_combo.master
        self._hitbox_editor_button = next(
            (
                child
                for child in toolbar.winfo_children()
                if isinstance(child, ttk.Button)
                and str(child.cget("text")) == "Edit hitboxes"
            ),
            None,
        )

    def _redraw(self) -> None:
        self.canvas.update_idletasks()
        canvas_width = max(240, self.canvas.winfo_width())
        canvas_height = max(300, self.canvas.winfo_height())
        try:
            source_key = (
                self.render_mode,
                str(self.project_path) if self.project_path else "",
                self.simulator.state.device_id,
                normalize_variant(self.simulator.state.variant),
            )
            if source_key not in self._source_size_cache:
                _, base_metadata = render_device(self.simulator, zoom=1.0, debug=False)
                self._source_size_cache[source_key] = tuple(base_metadata["source_size"])
            requested = max(0.2, float(self.zoom_var.get()))
            base_width, base_height = self._source_size_cache[source_key]
            fit = min((canvas_width - 32) / base_width, (canvas_height - 32) / base_height)
            actual = max(0.2, fit * requested)
            render_key = (
                source_key,
                repr(self.simulator.state),
                round(actual, 6),
                bool(self.debug_var.get()),
                canvas_width,
                canvas_height,
            )
            if render_key == self._last_render_key and self.photo is not None:
                self._update_state_panel()
                return
            image, metadata = render_device(self.simulator, zoom=actual, debug=self.debug_var.get())
            frame = compose_canvas(image, (canvas_width, canvas_height))
        except (FileNotFoundError, OSError, ValueError) as error:
            self._render_missing_asset(canvas_width, canvas_height, error)
            self._update_state_panel()
            return

        self._last_render_key = render_key
        self.image_scale = actual
        self.image_origin = ((canvas_width - image.width) // 2, (canvas_height - image.height) // 2)
        self.hitboxes = metadata["controls"]
        self.lcd_rect = metadata["lcd_rect"]
        self.source_offset = tuple(metadata["source_offset"])
        encoded = io.BytesIO()
        frame.save(encoded, format="PNG", optimize=False)
        self.photo = tk.PhotoImage(data=base64.b64encode(encoded.getvalue()).decode("ascii"))
        self.canvas.delete("all")
        self.canvas.create_image(0, 0, image=self.photo, anchor="nw")
        variant_label = "pristine" if self.simulator.state.variant == "clean" else "worn"
        self.canvas.create_text(
            14,
            14,
            text=f"{self.simulator.device.full_type} · {self._mode_label()} · {variant_label} · click controls · hold to preview press",
            fill="#d8dee9",
            anchor="nw",
        )
        self._update_state_panel()

    def _render_missing_asset(self, width: int, height: int, error: Exception) -> None:
        self.canvas.delete("all")
        self.canvas.create_rectangle(0, 0, width, height, fill="#20252b", outline="")
        self.canvas.create_text(width // 2, height // 2, text=f"Device artwork unavailable\n{error}", fill="#f0b48a", justify="center")
        self.image_origin = (0, 0)
        self.hitboxes = []
        self.lcd_rect = [0, 0, 0, 0]
        self.source_offset = (0, 0)
        self.captured_control = None
        self.drag_last_source = None

    def _update_state_panel(self) -> None:
        snapshot = self.simulator.snapshot()
        state = snapshot["state"].copy()
        state["event_log"] = state["event_log"][-8:]
        rendered = json.dumps(
            {
                "render_mode": self._mode_label(),
                "project": str(self.project_path) if self.project_path else None,
                "device": snapshot["state"]["device"],
                "state": state,
                "screen": snapshot["state"]["screen"],
            },
            indent=2,
            sort_keys=True,
        )
        self._replace_text(self.state_text, rendered)
        log = "\n".join(json.dumps(item, sort_keys=True) for item in self.simulator.state.event_log[-12:])
        self._replace_text(self.log_text, log or "No events yet. Click a physical control or send JSON.")

    @staticmethod
    def _replace_text(widget: tk.Text, value: str) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", tk.END)
        widget.insert("1.0", value)
        widget.configure(state="disabled")

    def _append_log(self, value: dict[str, Any]) -> None:
        current = self.log_text.get("1.0", tk.END).strip()
        self._replace_text(self.log_text, f"{current}\n{json.dumps(value, sort_keys=True)}")

    def _record_status(self, message: str) -> None:
        self.status_var.set(message)


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Open the Psychopatz Radio OS simulator")
    parser.add_argument("--device", default="walkie_5")
    parser.add_argument("--variant", choices=("clean", "worn", "pristine", "damaged"), default="pristine")
    parser.add_argument("--project", type=Path, default=None, help="load a modular project JSON")
    parser.add_argument("--mode", choices=("auto", "modular"), default="auto", help="load the canonical authored pilot project")
    args = parser.parse_args(argv)
    app = RadioSimulatorApp(device_id=args.device, variant=args.variant, project_path=args.project, mode=args.mode)
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
