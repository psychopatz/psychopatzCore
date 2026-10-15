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

from asset_harness.simulator import RadioSimulator, get_device, list_devices
from asset_harness.simulator.catalog import normalize_variant
from asset_harness.simulator.render import compose_canvas, render_device


class RadioSimulatorApp(tk.Tk):
    """Thin view/controller around :class:`RadioSimulator`."""

    def __init__(self, *, device_id: str = "walkie_1", variant: str = "clean") -> None:
        super().__init__()
        self.title("Psychopatz Radio OS Simulator")
        self.geometry("1280x860")
        self.minsize(980, 680)

        self.simulator = RadioSimulator(device_id, variant=normalize_variant(variant))
        self.photo: tk.PhotoImage | None = None
        self.image_origin = (0, 0)
        self.image_scale = 1.0
        self.hitboxes: list[dict[str, Any]] = []
        self.lcd_rect: list[int] = [0, 0, 0, 0]
        self.source_offset = (0, 0)

        self.device_var = tk.StringVar(value=self.simulator.device.label)
        self.variant_var = tk.StringVar(value=self.simulator.state.variant)
        self.zoom_var = tk.DoubleVar(value=1.0)
        self.debug_var = tk.BooleanVar(value=False)
        self.command_var = tk.StringVar(value='{"event":"press","control":"power"}')
        self.status_var = tk.StringVar(value="Ready · press Power or send a JSON event")

        self._build_ui()
        self._bind_keys()
        self.after(0, self._redraw)

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
            values=[spec.label for spec in list_devices()],
            state="readonly",
            width=34,
        )
        self.device_combo.grid(row=0, column=1, sticky="w", padx=(0, 12))
        self.device_combo.bind("<<ComboboxSelected>>", self._device_changed)
        ttk.Label(toolbar, text="Variant").grid(row=0, column=2, padx=(0, 5))
        self.variant_combo = ttk.Combobox(toolbar, textvariable=self.variant_var, values=("clean", "worn"), state="readonly", width=9)
        self.variant_combo.grid(row=0, column=3, padx=(0, 12))
        self.variant_combo.bind("<<ComboboxSelected>>", self._variant_changed)
        ttk.Button(toolbar, text="Reset", command=self._reset).grid(row=0, column=4, padx=(0, 12))
        ttk.Label(toolbar, text="Zoom").grid(row=0, column=5, padx=(0, 5))
        ttk.Scale(toolbar, from_=0.5, to=1.6, variable=self.zoom_var, command=lambda _value: self._redraw()).grid(row=0, column=6, padx=(0, 12), sticky="ew")
        ttk.Checkbutton(toolbar, text="Show hitboxes", variable=self.debug_var, command=self._redraw).grid(row=0, column=7, padx=(0, 8))

        body = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        body.grid(row=1, column=0, sticky="nsew", padx=10, pady=(0, 10))

        preview_frame = ttk.Frame(body, padding=8)
        preview_frame.columnconfigure(0, weight=1)
        preview_frame.rowconfigure(0, weight=1)
        self.canvas = tk.Canvas(preview_frame, background="#20252b", highlightthickness=1, highlightbackground="#47515c")
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.canvas.bind("<Button-1>", self._canvas_click)
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

        actions = ttk.Frame(side)
        actions.grid(row=2, column=0, sticky="ew", pady=(0, 8))
        for column in range(4):
            actions.columnconfigure(column, weight=1)
        for column, (label, event) in enumerate(
            (
                ("Power", {"event": "press", "control": "power"}),
                ("Previous", {"event": "press", "control": "previous"}),
                ("Select", {"event": "press", "control": "center"}),
                ("Next", {"event": "press", "control": "next"}),
            )
        ):
            ttk.Button(actions, text=label, command=lambda value=event: self._dispatch(value)).grid(row=0, column=column, sticky="ew", padx=2)
        ttk.Button(actions, text="Signal", command=lambda: self._dispatch({"event": "press", "action": "signal_cycle"})).grid(row=1, column=0, sticky="ew", padx=2, pady=(4, 0))
        ttk.Button(actions, text="PTT", command=lambda: self._dispatch({"event": "press", "action": "transmit_toggle"})).grid(row=1, column=1, sticky="ew", padx=2, pady=(4, 0))
        ttk.Button(actions, text="Back", command=lambda: self._dispatch({"event": "press", "action": "back"})).grid(row=1, column=2, sticky="ew", padx=2, pady=(4, 0))

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

    def _bind_keys(self) -> None:
        self.bind("<F5>", lambda _event: self._reset())
        self.bind("<Left>", lambda _event: self._dispatch({"event": "press", "control": "previous"}))
        self.bind("<Right>", lambda _event: self._dispatch({"event": "press", "control": "next"}))
        self.bind("<Return>", lambda _event: self._dispatch({"event": "press", "control": "center"}))
        self.bind("<Escape>", lambda _event: self._dispatch({"event": "press", "action": "back"}))
        self.bind("<space>", lambda _event: self._dispatch({"event": "press", "control": "power"}))

    def _device_changed(self, _event: tk.Event) -> None:
        selected = self.device_var.get()
        spec = next(spec for spec in list_devices() if spec.label == selected)
        self.simulator.reset(device_id=spec.id, variant=self.variant_var.get())
        self._record_status(f"Selected {spec.label}")
        self._redraw()

    def _variant_changed(self, _event: tk.Event) -> None:
        self.simulator.reset(variant=self.variant_var.get())
        self._record_status(f"Selected {self.variant_var.get()} artwork")
        self._redraw()

    def _reset(self) -> None:
        self.simulator.reset()
        self._record_status("Reset simulator state")
        self._redraw()

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
        self._redraw()

    def _canvas_click(self, event: tk.Event) -> None:
        local_x = event.x - self.image_origin[0]
        local_y = event.y - self.image_origin[1]
        for control in self.hitboxes:
            left, top, width, height = control["rect"]
            if left <= local_x <= left + width and top <= local_y <= top + height:
                self._dispatch({"event": "press", "control": control["id"]})
                return
        lcd_left, lcd_top, lcd_width, lcd_height = self.lcd_rect
        if lcd_left <= local_x <= lcd_left + lcd_width and lcd_top <= local_y <= lcd_top + lcd_height:
            source_x = local_x / max(self.image_scale, 0.01) + self.source_offset[0]
            source_y = local_y / max(self.image_scale, 0.01) + self.source_offset[1]
            self._dispatch({"event": "screen_click", "x": source_x, "y": source_y})

    def _redraw(self) -> None:
        self.canvas.update_idletasks()
        canvas_width = max(240, self.canvas.winfo_width())
        canvas_height = max(300, self.canvas.winfo_height())
        try:
            base_image, base_metadata = render_device(self.simulator, zoom=1.0, debug=False)
            requested = max(0.2, float(self.zoom_var.get()))
            base_width, base_height = base_metadata["source_size"]
            fit = min((canvas_width - 32) / base_width, (canvas_height - 32) / base_height)
            actual = max(0.2, fit * requested)
            image, metadata = render_device(self.simulator, zoom=actual, debug=self.debug_var.get())
            frame = compose_canvas(image, (canvas_width, canvas_height))
        except (FileNotFoundError, OSError, ValueError) as error:
            self._render_missing_asset(canvas_width, canvas_height, error)
            self._update_state_panel()
            return

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
        self.canvas.create_text(14, 14, text=f"{self.simulator.device.full_type} · {self.simulator.state.variant} · click controls", fill="#d8dee9", anchor="nw")
        self._update_state_panel()

    def _render_missing_asset(self, width: int, height: int, error: Exception) -> None:
        self.canvas.delete("all")
        self.canvas.create_rectangle(0, 0, width, height, fill="#20252b", outline="")
        self.canvas.create_text(width // 2, height // 2, text=f"Device artwork unavailable\n{error}", fill="#f0b48a", justify="center")
        self.image_origin = (0, 0)
        self.hitboxes = []
        self.lcd_rect = [0, 0, 0, 0]
        self.source_offset = (0, 0)

    def _update_state_panel(self) -> None:
        snapshot = self.simulator.snapshot()
        state = snapshot["state"].copy()
        state["event_log"] = state["event_log"][-8:]
        rendered = json.dumps({"device": snapshot["state"]["device"], "state": state, "screen": snapshot["state"]["screen"]}, indent=2, sort_keys=True)
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
    parser.add_argument("--device", default="walkie_1")
    parser.add_argument("--variant", choices=("clean", "worn", "pristine", "damaged"), default="clean")
    args = parser.parse_args(argv)
    get_device(args.device)
    app = RadioSimulatorApp(device_id=args.device, variant=args.variant)
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
