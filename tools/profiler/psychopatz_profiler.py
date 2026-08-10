#!/usr/bin/env python3
"""Lightweight cross-platform Tk monitor for PsychopatzCore snapshots."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Optional

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, simpledialog, ttk
except ImportError:
    tk = None  # type: ignore[assignment]

from profiler_core import (ProcessMonitor, ProfilerModel, SnapshotReader, _psutil,
                           default_game_config_path, iter_snapshot_metrics,
                           read_game_profiler_mode, write_game_profiler_mode)


def human_bytes(value: Any) -> str:
    if value is None:
        return "N/A"
    amount = float(value)
    for suffix in ("B", "KB", "MB", "GB", "TB"):
        if abs(amount) < 1024 or suffix == "TB":
            return f"{amount:.2f} {suffix}"
        amount /= 1024
    return "N/A"


def duration(value: Any) -> str:
    if value is None:
        return "N/A"
    seconds = max(0, int(value))
    hours, remainder = divmod(seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


class TkinterProfilerUI:
    def __init__(self, root: Any, pid: Optional[int], snapshot: Optional[Path], interval: float) -> None:
        self.root = root
        self.interval = interval
        self.monitor = ProcessMonitor()
        self.reader = SnapshotReader(snapshot)
        self.model = ProfilerModel(300)
        self.candidates = []
        self.closed = False
        self.status_var = tk.StringVar(value="DISCONNECTED")
        self.snapshot_var = tk.StringVar(value="snapshot not found")
        self.process_var = tk.StringVar(value="")
        self.game_mode_var = tk.StringVar(value="Checking configuration...")
        self.game_config_path = default_game_config_path()
        self.process_values = {key: tk.StringVar(value="N/A") for key in ("pid", "rss", "cpu", "threads", "uptime")}
        self._build()
        self.refresh_game_mode()
        self.refresh_candidates()
        if pid is not None:
            self.monitor.select(pid)
        elif len(self.candidates) == 1:
            self.monitor.select(self.candidates[0].pid)
            self.process_var.set(self.candidates[0].label)
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self.root.after(50, self.poll)

    def _build(self) -> None:
        self.root.title("Psychopatz Performance Profiler")
        self.root.geometry("980x720")
        self.root.minsize(760, 540)
        outer = ttk.Frame(self.root, padding=10)
        outer.pack(fill="both", expand=True)

        picker = ttk.LabelFrame(outer, text="Project Zomboid process", padding=8)
        picker.pack(fill="x")
        self.process_combo = ttk.Combobox(picker, textvariable=self.process_var, state="readonly")
        self.process_combo.pack(side="left", fill="x", expand=True)
        ttk.Button(picker, text="Connect", command=self.connect_selected).pack(side="left", padx=6)
        ttk.Button(picker, text="Rescan", command=self.refresh_candidates).pack(side="left")
        ttk.Label(picker, textvariable=self.status_var, width=15).pack(side="right", padx=8)

        setup = ttk.LabelFrame(outer, text="PROJECT HOOMANS PROFILING SETUP", padding=8)
        setup.pack(fill="x", pady=(8, 0))
        ttk.Label(setup, textvariable=self.game_mode_var).pack(side="left", fill="x", expand=True)
        ttk.Button(
            setup,
            text="Enable DETAILED",
            command=lambda: self.set_game_mode("DETAILED"),
        ).pack(side="left", padx=6)
        ttk.Button(
            setup,
            text="Disable (OFF)",
            command=lambda: self.set_game_mode("OFF"),
        ).pack(side="left")

        process = ttk.LabelFrame(outer, text="PROJECT ZOMBOID PROCESS", padding=8)
        process.pack(fill="x", pady=(8, 0))
        labels = (("PID", "pid"), ("RSS", "rss"), ("CPU", "cpu"), ("Threads", "threads"), ("Uptime", "uptime"))
        for column, (label, key) in enumerate(labels):
            ttk.Label(process, text=label).grid(row=0, column=column, padx=12, sticky="w")
            ttk.Label(process, textvariable=self.process_values[key]).grid(row=1, column=column, padx=12, sticky="w")

        snapshot_bar = ttk.Frame(outer)
        snapshot_bar.pack(fill="x", pady=(8, 0))
        ttk.Label(snapshot_bar, textvariable=self.snapshot_var).pack(side="left")
        ttk.Button(snapshot_bar, text="Select snapshot", command=self.select_snapshot).pack(side="right")

        pane = ttk.Panedwindow(outer, orient="horizontal")
        pane.pack(fill="both", expand=True, pady=8)
        metrics_frame = ttk.LabelFrame(pane, text="MOD NAMESPACES", padding=6)
        history_frame = ttk.LabelFrame(pane, text="PROCESS RAM HISTORY", padding=6)
        pane.add(metrics_frame, weight=3)
        pane.add(history_frame, weight=2)
        self.metrics = ttk.Treeview(metrics_frame, columns=("value", "kind"), show="tree headings")
        self.metrics.heading("#0", text="Namespace / metric")
        self.metrics.heading("value", text="Value")
        self.metrics.heading("kind", text="Kind")
        self.metrics.column("#0", width=300)
        self.metrics.column("value", width=110, anchor="e")
        self.metrics.column("kind", width=80)
        scroll = ttk.Scrollbar(metrics_frame, command=self.metrics.yview)
        self.metrics.configure(yscrollcommand=scroll.set)
        self.metrics.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")
        self.graph = tk.Canvas(history_frame, background="#161a20", highlightthickness=0)
        self.graph.pack(fill="both", expand=True)

        warnings = ttk.LabelFrame(outer, text="WARNINGS", padding=6)
        warnings.pack(fill="x")
        self.warning_var = tk.StringVar(value="No warnings")
        ttk.Label(warnings, textvariable=self.warning_var).pack(anchor="w")

        controls = ttk.Frame(outer)
        controls.pack(fill="x", pady=(8, 0))
        self.record_button = ttk.Button(controls, text="Start Recording", command=self.toggle_recording)
        self.record_button.pack(side="left")
        ttk.Button(controls, text="Add Marker", command=self.add_marker).pack(side="left", padx=6)
        self.interval_var = tk.StringVar(value=str(self.interval))
        ttk.Label(controls, text="Poll seconds:").pack(side="left", padx=(20, 4))
        interval = ttk.Combobox(controls, textvariable=self.interval_var, values=("0.5", "1", "2", "5"), width=5, state="readonly")
        interval.pack(side="left")
        interval.bind("<<ComboboxSelected>>", lambda _event: self._set_interval())

    def refresh_game_mode(self) -> None:
        mode = read_game_profiler_mode(self.game_config_path)
        self.game_mode_var.set(f"Game instrumentation: {mode} — restart PZ after changing")

    def set_game_mode(self, mode: str) -> None:
        try:
            path = write_game_profiler_mode(mode, self.game_config_path)
        except (OSError, PermissionError, ValueError) as error:
            messagebox.showerror("Could not update profiler", f"Failed to write the game configuration:\n{error}")
            return
        self.refresh_game_mode()
        if mode == "DETAILED":
            message = (
                "ProjectHoomans DETAILED profiling is enabled.\n\n"
                "Fully close and restart Project Zomboid, then load your save. "
                "The Project Hoomans namespace will appear after the snapshot is created."
            )
        else:
            message = (
                "Profiling is configured OFF.\n\n"
                "Fully close and restart Project Zomboid to return to strict zero-overhead mode."
            )
        messagebox.showinfo("Game restart required", f"{message}\n\nConfiguration: {path}")

    def refresh_candidates(self) -> None:
        self.candidates = self.monitor.discover()
        self.process_combo["values"] = [candidate.label for candidate in self.candidates]
        if self.candidates and not self.process_var.get():
            self.process_var.set(self.candidates[0].label)

    def connect_selected(self) -> None:
        selected = self.process_var.get()
        for candidate in self.candidates:
            if candidate.label == selected:
                self.monitor.select(candidate.pid)
                return

    def select_snapshot(self) -> None:
        selected = filedialog.askopenfilename(
            title="Select PsychopatzCore snapshot",
            filetypes=(("JSON snapshots", "*.json"), ("All files", "*")),
        )
        if selected:
            self.reader = SnapshotReader(Path(selected))

    def _set_interval(self) -> None:
        try:
            self.interval = max(0.5, float(self.interval_var.get()))
        except ValueError:
            self.interval = 1.0

    def poll(self) -> None:
        if self.closed:
            return
        process = self.monitor.sample()
        if not process.get("connected") and self.monitor.process is None:
            self.refresh_candidates()
            if len(self.candidates) == 1:
                self.monitor.select(self.candidates[0].pid)
        snapshot = self.reader.read()
        self.model.update(process, snapshot)
        self._render(process, snapshot)
        self.root.after(int(self.interval * 1000), self.poll)

    def _render(self, process: dict[str, Any], snapshot: Optional[dict[str, Any]]) -> None:
        connected = process.get("connected") is True
        self.status_var.set("CONNECTED" if connected else "DISCONNECTED")
        self.snapshot_var.set(self.reader.status + (f" — {self.reader.path}" if self.reader.path else ""))
        self.process_values["pid"].set(str(process.get("pid") or "N/A"))
        self.process_values["rss"].set(human_bytes(process.get("rss")))
        cpu = process.get("cpu_percent")
        self.process_values["cpu"].set(f"{cpu:.1f} %" if cpu is not None else "N/A")
        self.process_values["threads"].set(str(process.get("threads") or "N/A"))
        self.process_values["uptime"].set(duration(process.get("uptime")))
        self._render_metrics(snapshot)
        self._render_graph()
        warnings = list(self.model.warnings)
        if snapshot:
            warnings.extend(str(item.get("message")) for item in snapshot.get("warnings") or [] if item.get("message"))
        self.warning_var.set(" • ".join(warnings[-3:]) if warnings else "No warnings")

    def _render_metrics(self, snapshot: Optional[dict[str, Any]]) -> None:
        self.metrics.delete(*self.metrics.get_children())
        if not snapshot:
            self.metrics.insert(
                "", "end",
                text="No profiler snapshot",
                values=("Enable DETAILED mode, then restart Project Zomboid", "status"),
            )
            return
        namespace_nodes: dict[str, str] = {}
        display_names = {name: data.get("displayName", name) for name, data in (snapshot or {}).get("namespaces", {}).items()}
        totals: dict[str, float] = {}
        values = list(iter_snapshot_metrics(snapshot))
        for namespace, _name, kind, value in values:
            if kind == "timer":
                totals[namespace] = totals.get(namespace, 0.0) + value
        for namespace in sorted({item[0] for item in values}):
            label = display_names.get(namespace, namespace)
            namespace_nodes[namespace] = self.metrics.insert("", "end", text=label,
                values=(f"{totals.get(namespace, 0):.2f} ms/s", "namespace"), open=True)
        for namespace, name, kind, value in sorted(values):
            suffix = " ms/s" if kind == "timer" else " /s" if kind == "rate" else ""
            self.metrics.insert(namespace_nodes[namespace], "end", text=name,
                                values=(f"{value:.2f}{suffix}", kind))

    def _render_graph(self) -> None:
        self.graph.delete("all")
        width, height = max(2, self.graph.winfo_width()), max(2, self.graph.winfo_height())
        points = list(self.model.history.series.get("process.rss", ()))
        if len(points) < 2:
            self.graph.create_text(width / 2, height / 2, fill="#b9c1cc", text="Waiting for RSS samples")
            return
        values = [value for _, value in points]
        low, high = min(values), max(values)
        span = max(1.0, high - low)
        coords = []
        for index, value in enumerate(values):
            coords.extend((index * (width - 12) / (len(values) - 1) + 6,
                           height - 8 - (value - low) * (height - 20) / span))
        self.graph.create_line(*coords, fill="#62b0ff", width=2)
        self.graph.create_text(8, 8, anchor="nw", fill="#b9c1cc", text=f"{human_bytes(values[-1])} process RSS")
        if points:
            start, end = points[0][0], points[-1][0]
            for timestamp, text in self.model.history.markers:
                if start <= timestamp <= end and end > start:
                    x = 6 + (timestamp - start) * (width - 12) / (end - start)
                    self.graph.create_line(x, 0, x, height, fill="#ffb347", dash=(3, 3))

    def toggle_recording(self) -> None:
        if self.model.recorder.active:
            path = self.model.recorder.path
            self.model.recorder.stop()
            self.record_button.configure(text="Start Recording")
            messagebox.showinfo("Recording stopped", f"Saved recording to:\n{path}")
            return
        selected = filedialog.askdirectory(title="Choose recording directory")
        if selected:
            path = self.model.recorder.start(Path(selected))
            self.record_button.configure(text="Stop Recording")
            messagebox.showinfo("Recording started", f"Writing normalized metric rows to:\n{path}")

    def add_marker(self) -> None:
        text = simpledialog.askstring("Add marker", "What happened at this point?")
        if text:
            self.model.add_marker(text)

    def close(self) -> None:
        self.closed = True
        self.model.recorder.stop()
        self.root.destroy()


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="PsychopatzCore cross-platform performance profiler")
    parser.add_argument("--pid", type=int, help="connect directly to a Project Zomboid client/server PID")
    parser.add_argument("--snapshot", type=Path, help="path to PsychopatzCore_Profiler_latest.json")
    parser.add_argument("--interval", type=float, choices=(0.5, 1.0, 2.0, 5.0), default=1.0)
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    if tk is None:
        print("Tkinter is not available in this Python installation.\n"
              "Install your operating system's Python Tk package, then run this program again.\n"
              "The profiler does not install or modify system packages automatically.", file=sys.stderr)
        return 2
    if _psutil is None:
        print("The 'psutil' package is required. Install the profiler requirements with:\n"
              "  python -m pip install -r requirements.txt", file=sys.stderr)
        return 2
    try:
        root = tk.Tk()
    except tk.TclError as error:
        print("Tkinter is installed, but no graphical display is available.\n"
              f"Run the GUI in a desktop session. Details: {error}", file=sys.stderr)
        return 2
    TkinterProfilerUI(root, args.pid, args.snapshot, args.interval)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
