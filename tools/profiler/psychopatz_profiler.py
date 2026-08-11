#!/usr/bin/env python3
"""Lightweight cross-platform Tk monitor for PsychopatzCore snapshots."""

from __future__ import annotations

import argparse
import hashlib
import sys
import time
from dataclasses import replace
from pathlib import Path
from typing import Any, Optional

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, simpledialog, ttk
except ImportError:
    tk = None  # type: ignore[assignment]

from profiler_core import (ProcessMonitor, ProfilerModel, SnapshotReader, _psutil,
                           build_llm_report, default_game_config_path,
                           default_llm_report_path, iter_snapshot_metrics,
                           snapshot_npc_data, write_llm_report)
from profiler_config import (CaptureConfig, read_capture_config,
                             runtime_application_state, write_capture_config)
from bridge import (BridgeClient, BridgeConfig, FileBridgeTransport,
                    default_bridge_config_path, read_bridge_config,
                    write_bridge_config)
from app_settings import (AppSettings, default_app_settings_path, read_app_settings,
                          select_preferred_candidate, settings_for_candidate,
                          write_app_settings)


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
    def __init__(self, root: Any, pid: Optional[int], snapshot: Optional[Path],
                 interval: Optional[float]) -> None:
        self.root = root
        self.app_settings_path = default_app_settings_path()
        self.app_settings = read_app_settings(self.app_settings_path)
        self.interval = float(interval if interval is not None else self.app_settings.poll_interval)
        self.monitor = ProcessMonitor()
        self.reader = SnapshotReader(snapshot)
        self.model = ProfilerModel(300)
        self.candidates = []
        self.closed = False
        self.status_var = tk.StringVar(value="DISCONNECTED")
        self.snapshot_var = tk.StringVar(value="snapshot not found")
        self.process_var = tk.StringVar(value="")
        self.preferred_process_var = tk.StringVar(value="No saved process identity")
        self.game_mode_var = tk.StringVar(value="Checking configuration...")
        self.game_config_path = default_game_config_path()
        self.bridge_config_path = default_bridge_config_path()
        self.bridge_transport = FileBridgeTransport()
        self.bridge_client = BridgeClient(self.bridge_transport)
        self.bridge_enabled_var = tk.BooleanVar(value=False)
        self.bridge_status_var = tk.StringVar(value="DISABLED")
        self.bridge_runtime_var = tk.StringVar(value="N/A")
        self.bridge_protocol_var = tk.StringVar(value="N/A")
        self.bridge_response_var = tk.StringVar(value="No bridge response yet")
        self.bridge_latency_var = tk.StringVar(value="N/A")
        self.bridge_pending_var = tk.StringVar(value="0")
        self.bridge_request_actions = {}
        self.live_profiler_fingerprint = None
        self.live_profiler_runtime_id = None
        self.profiler_runtime_active = False
        self.capture_performance_var = tk.BooleanVar(value=True)
        self.capture_moddata_var = tk.BooleanVar(value=False)
        self.capture_npc_var = tk.BooleanVar(value=False)
        self.capture_npc_ids_var = tk.StringVar(value="")
        self.llm_report_path = default_llm_report_path()
        self.llm_status_var = tk.StringVar(value="LLM report waiting for ModData diagnostics")
        self.last_llm_snapshot_timestamp = None
        self.metric_sort = ("value", True)
        self.moddata_sort = ("estimated", True)
        self.npc_sort = ("name", False)
        self.metric_open_state = {}
        self.moddata_open_state = {}
        self.content_open_state = {}
        self.inventory_open_state = {}
        self.paused = False
        self.selected_npc_id = None
        self.npc_by_iid = {}
        self.moddata_npc_by_iid = {}
        self.process_values = {key: tk.StringVar(value="N/A") for key in ("pid", "rss", "cpu", "threads", "uptime")}
        self._build()
        self._restore_selected_tab()
        self.refresh_game_mode()
        self.refresh_candidates(auto_connect=pid is None)
        if pid is not None:
            self.monitor.select(pid)
            selected = next((candidate for candidate in self.candidates if candidate.pid == pid), None)
            if selected:
                self._remember_candidate(selected)
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self.root.after(50, self.poll)

    def _build(self) -> None:
        self.root.title("Psychopatz Performance Profiler")
        self.root.geometry("1080x860")
        self.root.minsize(820, 680)
        outer = ttk.Frame(self.root, padding=10)
        outer.pack(fill="both", expand=True)

        picker = ttk.LabelFrame(outer, text="Project Zomboid process", padding=8)
        picker.pack(fill="x")
        self.process_combo = ttk.Combobox(picker, textvariable=self.process_var, state="readonly")
        self.process_combo.grid(row=0, column=0, sticky="ew")
        ttk.Button(picker, text="Connect", command=self.connect_selected).grid(
            row=0, column=1, padx=6)
        ttk.Button(picker, text="Rescan", command=self.refresh_candidates).grid(row=0, column=2)
        ttk.Label(picker, textvariable=self.status_var, width=15).grid(
            row=0, column=3, padx=8)
        ttk.Label(picker, textvariable=self.preferred_process_var).grid(
            row=1, column=0, columnspan=4, sticky="w", pady=(5, 0))
        picker.columnconfigure(0, weight=1)

        setup = ttk.LabelFrame(outer, text="PROJECT HOOMANS PROFILING SETUP", padding=8)
        setup.pack(fill="x", pady=(8, 0))
        ttk.Label(setup, textvariable=self.game_mode_var).grid(
            row=0, column=0, columnspan=7, sticky="ew", pady=(0, 5))
        ttk.Checkbutton(setup, text="Performance", variable=self.capture_performance_var).grid(
            row=1, column=0, sticky="w")
        ttk.Checkbutton(setup, text="ModData Summary", variable=self.capture_moddata_var).grid(
            row=1, column=1, sticky="w", padx=(10, 0))
        ttk.Checkbutton(setup, text="NPC Data", variable=self.capture_npc_var).grid(
            row=1, column=2, sticky="w", padx=(10, 0))
        ttk.Label(setup, text="NPC IDs:").grid(row=1, column=3, sticky="e", padx=(14, 4))
        ttk.Entry(setup, textvariable=self.capture_npc_ids_var, width=24).grid(
            row=1, column=4, sticky="ew")
        ttk.Button(setup, text="Apply Settings", command=self.apply_capture_setup).grid(
            row=1, column=5, padx=6)
        self.profiler_toggle_button = ttk.Button(
            setup, text="Enable Profiling", command=self.toggle_profiler_enabled)
        self.profiler_toggle_button.grid(row=1, column=6)
        setup.columnconfigure(4, weight=1)

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

        self.notebook = ttk.Notebook(outer)
        self.notebook.pack(fill="both", expand=True, pady=8)
        performance_tab = ttk.Frame(self.notebook, padding=6)
        moddata_tab = ttk.Frame(self.notebook, padding=6)
        self.npc_tab = ttk.Frame(self.notebook, padding=6)
        self.notebook.add(performance_tab, text="Performance")
        self.notebook.add(moddata_tab, text="ModData Summary")
        self.notebook.add(self.npc_tab, text="NPC Data Inspector")
        self.bridge_tab = ttk.Frame(self.notebook, padding=6)
        self.notebook.add(self.bridge_tab, text="External Control")

        bridge_setup = ttk.LabelFrame(self.bridge_tab, text="LOCAL PSYCHOPATZ BRIDGE", padding=10)
        bridge_setup.pack(fill="x")
        ttk.Checkbutton(bridge_setup, text="Enable bridge at next PZ startup",
                        variable=self.bridge_enabled_var).grid(row=0, column=0, sticky="w")
        ttk.Button(bridge_setup, text="Save Bridge Setting",
                   command=self.save_bridge_setting).grid(row=0, column=1, padx=8)
        ttk.Label(bridge_setup, text="Independent from Performance, ModData, and NPC capture.").grid(
            row=1, column=0, columnspan=2, sticky="w", pady=(5, 0))

        bridge_state = ttk.LabelFrame(self.bridge_tab, text="RUNTIME", padding=10)
        bridge_state.pack(fill="x", pady=(8, 0))
        for row, (label, variable) in enumerate((
                ("Status", self.bridge_status_var), ("Runtime ID", self.bridge_runtime_var),
                ("Protocol", self.bridge_protocol_var), ("Pending", self.bridge_pending_var),
                ("Average RTT", self.bridge_latency_var),
                ("Last response", self.bridge_response_var))):
            ttk.Label(bridge_state, text=label + ":", width=15).grid(row=row, column=0, sticky="nw")
            ttk.Label(bridge_state, textvariable=variable).grid(row=row, column=1, sticky="nw")
        bridge_actions = ttk.Frame(self.bridge_tab)
        bridge_actions.pack(fill="x", pady=8)
        ttk.Button(bridge_actions, text="Ping Runtime", command=self.bridge_ping).pack(side="left")
        ttk.Button(bridge_actions, text="Refresh Capabilities",
                   command=self.bridge_refresh_capabilities).pack(side="left", padx=6)
        self.bridge_apply_button = ttk.Button(
            bridge_actions, text="Apply Profiler Settings Live", command=self.apply_capture_setup_live)
        self.bridge_apply_button.pack(side="left")
        capabilities = ttk.LabelFrame(self.bridge_tab, text="REGISTERED CAPABILITIES", padding=6)
        capabilities.pack(fill="both", expand=True)
        self.bridge_capabilities = ttk.Treeview(
            capabilities, columns=("category", "access"), show="tree headings")
        self.bridge_capabilities.heading("#0", text="Namespace / command")
        self.bridge_capabilities.heading("category", text="Category")
        self.bridge_capabilities.heading("access", text="Access")
        self.bridge_capabilities.column("#0", width=440)
        self.bridge_capabilities.column("category", width=100)
        self.bridge_capabilities.column("access", width=100)
        self.bridge_capabilities.pack(fill="both", expand=True)

        pane = ttk.Panedwindow(performance_tab, orient="horizontal")
        pane.pack(fill="both", expand=True)
        metrics_frame = ttk.LabelFrame(pane, text="MOD NAMESPACES", padding=6)
        history_frame = ttk.LabelFrame(pane, text="PROCESS RAM HISTORY", padding=6)
        pane.add(metrics_frame, weight=3)
        pane.add(history_frame, weight=2)
        self.metrics = ttk.Treeview(metrics_frame, columns=("value", "kind"), show="tree headings")
        self.metrics.heading("#0", text="Namespace / metric", command=lambda: self.set_metric_sort("name"))
        self.metrics.heading("value", text="Value ▼", command=lambda: self.set_metric_sort("value"))
        self.metrics.heading("kind", text="Kind", command=lambda: self.set_metric_sort("kind"))
        self.metrics.column("#0", width=300)
        self.metrics.column("value", width=110, anchor="e")
        self.metrics.column("kind", width=80)
        scroll = ttk.Scrollbar(metrics_frame, command=self.metrics.yview)
        self.metrics.configure(yscrollcommand=scroll.set)
        self.metrics.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")
        self._bind_open_state(self.metrics, "metric_open_state")
        self.graph = tk.Canvas(history_frame, background="#161a20", highlightthickness=0)
        self.graph.pack(fill="both", expand=True)

        moddata = ttk.LabelFrame(moddata_tab, text="PROJECT HOOMANS MODDATA BLOAT ANALYSIS", padding=6)
        moddata.pack(fill="both", expand=True)
        self.moddata_tree = ttk.Treeview(moddata, columns=("estimated", "details"), show="tree headings", height=7)
        self.moddata_tree.heading("#0", text="Section / largest path", command=lambda: self.set_moddata_sort("name"))
        self.moddata_tree.heading("estimated", text="Estimated shape ▼", command=lambda: self.set_moddata_sort("estimated"))
        self.moddata_tree.heading("details", text="Counts / status", command=lambda: self.set_moddata_sort("details"))
        self.moddata_tree.column("#0", width=390)
        self.moddata_tree.column("estimated", width=120, anchor="e")
        self.moddata_tree.column("details", width=390)
        moddata_scroll = ttk.Scrollbar(moddata, command=self.moddata_tree.yview)
        self.moddata_tree.configure(yscrollcommand=moddata_scroll.set)
        self.moddata_tree.pack(side="left", fill="both", expand=True)
        moddata_scroll.pack(side="right", fill="y")
        self._bind_open_state(self.moddata_tree, "moddata_open_state")
        self.moddata_tree.bind("<Double-1>", self.on_moddata_activate)

        npc_pane = ttk.Panedwindow(self.npc_tab, orient="horizontal")
        npc_pane.pack(fill="both", expand=True)
        npc_list_frame = ttk.LabelFrame(npc_pane, text="NPCS", padding=6)
        npc_content_frame = ttk.LabelFrame(npc_pane, text="BOUNDED RUNTIME / PERSISTED CONTENT", padding=6)
        npc_pane.add(npc_list_frame, weight=2)
        npc_pane.add(npc_content_frame, weight=3)
        self.npc_tree = ttk.Treeview(
            npc_list_frame,
            columns=("faction", "presence", "runtime", "persisted", "items"),
            show="tree headings",
        )
        self.npc_tree.heading("#0", text="NPC name", command=lambda: self.set_npc_sort("name"))
        for column, label in (("faction", "Faction"), ("presence", "Presence"),
                              ("runtime", "Runtime"), ("persisted", "Persisted"),
                              ("items", "Items")):
            self.npc_tree.heading(column, text=label, command=lambda value=column: self.set_npc_sort(value))
        self.npc_tree.column("#0", width=190)
        self.npc_tree.column("faction", width=75)
        self.npc_tree.column("presence", width=75)
        self.npc_tree.column("runtime", width=85, anchor="e")
        self.npc_tree.column("persisted", width=85, anchor="e")
        self.npc_tree.column("items", width=50, anchor="e")
        npc_scroll = ttk.Scrollbar(npc_list_frame, command=self.npc_tree.yview)
        self.npc_tree.configure(yscrollcommand=npc_scroll.set)
        self.npc_tree.pack(side="left", fill="both", expand=True)
        npc_scroll.pack(side="right", fill="y")
        self.npc_tree.bind("<<TreeviewSelect>>", self.on_npc_selected)
        self.npc_detail_notebook = ttk.Notebook(npc_content_frame)
        self.npc_detail_notebook.pack(fill="both", expand=True)
        inventory_tab = ttk.Frame(self.npc_detail_notebook, padding=4)
        raw_tab = ttk.Frame(self.npc_detail_notebook, padding=4)
        self.npc_detail_notebook.add(inventory_tab, text="Inventory & Clothing")
        self.npc_detail_notebook.add(raw_tab, text="Raw State")
        self.npc_inventory_tree = ttk.Treeview(
            inventory_tab, columns=("location", "details"), show="tree headings",
        )
        self.npc_inventory_tree.heading("#0", text="NPC / item")
        self.npc_inventory_tree.heading("location", text="Slot / container")
        self.npc_inventory_tree.heading("details", text="State")
        self.npc_inventory_tree.column("#0", width=270)
        self.npc_inventory_tree.column("location", width=130)
        self.npc_inventory_tree.column("details", width=260)
        inventory_scroll = ttk.Scrollbar(inventory_tab, command=self.npc_inventory_tree.yview)
        self.npc_inventory_tree.configure(yscrollcommand=inventory_scroll.set)
        self.npc_inventory_tree.pack(side="left", fill="both", expand=True)
        inventory_scroll.pack(side="right", fill="y")
        self._bind_open_state(self.npc_inventory_tree, "inventory_open_state")
        self.npc_content_tree = ttk.Treeview(
            raw_tab, columns=("value", "type"), show="tree headings",
        )
        self.npc_content_tree.heading("#0", text="Field")
        self.npc_content_tree.heading("value", text="Value")
        self.npc_content_tree.heading("type", text="Type")
        self.npc_content_tree.column("#0", width=260)
        self.npc_content_tree.column("value", width=300)
        self.npc_content_tree.column("type", width=80)
        content_scroll = ttk.Scrollbar(raw_tab, command=self.npc_content_tree.yview)
        self.npc_content_tree.configure(yscrollcommand=content_scroll.set)
        self.npc_content_tree.pack(side="left", fill="both", expand=True)
        content_scroll.pack(side="right", fill="y")
        self._bind_open_state(self.npc_content_tree, "content_open_state")

        warnings = ttk.LabelFrame(outer, text="WARNINGS", padding=6)
        warnings.pack(fill="x")
        self.warning_var = tk.StringVar(value="No warnings")
        ttk.Label(warnings, textvariable=self.warning_var).pack(anchor="w")

        controls = ttk.Frame(outer)
        controls.pack(fill="x", pady=(8, 0))
        self.record_button = ttk.Button(controls, text="Start Recording", command=self.toggle_recording)
        self.record_button.pack(side="left")
        ttk.Button(controls, text="Add Marker", command=self.add_marker).pack(side="left", padx=6)
        self.pause_button = ttk.Button(controls, text="Pause Updates", command=self.toggle_pause)
        self.pause_button.pack(side="left", padx=(0, 6))
        self.export_button = ttk.Button(controls, text="Export LLM...", command=self.open_llm_export_dialog)
        self.export_button.pack(side="left", padx=(0, 6))
        ttk.Button(controls, text="Capture Selected NPC", command=self.capture_selected_npc).pack(
            side="left", padx=(0, 6))
        self.interval_var = tk.StringVar(value=f"{self.interval:g}")
        ttk.Label(controls, text="Poll seconds:").pack(side="left", padx=(20, 4))
        interval = ttk.Combobox(controls, textvariable=self.interval_var, values=("0.5", "1", "2", "5"), width=5, state="readonly")
        interval.pack(side="left")
        interval.bind("<<ComboboxSelected>>", lambda _event: self._set_interval())
        self.notebook.bind("<<NotebookTabChanged>>", lambda _event: self._save_ui_preferences())

    def refresh_game_mode(self) -> None:
        config = read_capture_config(self.game_config_path)
        self.capture_performance_var.set("performance" in config.sections)
        self.capture_moddata_var.set("moddata" in config.sections)
        self.capture_npc_var.set("npc" in config.sections)
        self.capture_npc_ids_var.set(",".join(config.npc_ids))
        sections = ", ".join(config.sections) if config.mode != "OFF" else "none"
        self.game_mode_var.set(f"Configured: {config.mode} — capture: {sections}")
        self._update_profiler_toggle(config.mode != "OFF")
        self.bridge_enabled_var.set(read_bridge_config(self.bridge_config_path).enabled)
        self._update_preferred_process_text()

    def _capture_config_from_controls(self, mode: str = "DETAILED") -> CaptureConfig:
        current = read_capture_config(self.game_config_path)
        sections = tuple(name for name, selected in (
            ("performance", self.capture_performance_var.get()),
            ("moddata", self.capture_moddata_var.get()),
            ("npc", self.capture_npc_var.get()),
        ) if selected)
        npc_ids = tuple(dict.fromkeys(
            value.strip() for value in self.capture_npc_ids_var.get().split(",") if value.strip()))
        return CaptureConfig(
            mode=mode, sections=sections,
            performance_interval_ms=current.performance_interval_ms,
            moddata_interval_ms=current.moddata_interval_ms,
            npc_interval_ms=current.npc_interval_ms,
            npc_scope="selected", npc_ids=npc_ids,
        )

    def apply_capture_setup(self) -> None:
        config = self._capture_config_from_controls()
        if not config.sections:
            messagebox.showwarning("Nothing selected", "Select at least one capture section or use Disable (OFF).")
            return
        if config.enabled("npc") and not config.npc_ids:
            if not messagebox.askyesno(
                    "No NPC selected",
                    "NPC Data will expose only the lightweight NPC roster until IDs are entered. Continue?"):
                return
        if self.bridge_status_var.get() == "CONNECTED":
            self._submit_live_capture_config(config)
        else:
            self._write_capture_config(config)

    @staticmethod
    def _bridge_capture_arguments(config: CaptureConfig) -> dict[str, Any]:
        return {"mode": config.mode, "capture": list(config.sections),
                "performance_interval_ms": config.performance_interval_ms,
                "moddata_interval_ms": config.moddata_interval_ms,
                "npc_interval_ms": config.npc_interval_ms,
                "npc_scope": config.npc_scope, "npc_ids": list(config.npc_ids)}

    def apply_capture_setup_live(self) -> None:
        config = self._capture_config_from_controls()
        if not config.sections:
            messagebox.showwarning("Nothing selected", "Select at least one capture section.")
            return
        self._submit_live_capture_config(config)

    def _submit_live_capture_config(self, config: CaptureConfig) -> None:
        try:
            write_capture_config(config, self.game_config_path)
            request_id = self.bridge_client.submit(
                "psychopatzcore.profiler", "configure", self._bridge_capture_arguments(config))
            self.bridge_request_actions[request_id] = "configure"
            self.bridge_response_var.set("Profiler configuration submitted")
        except (OSError, RuntimeError, ValueError) as error:
            messagebox.showerror("Live configuration failed", str(error))

    def save_bridge_setting(self) -> None:
        current = read_bridge_config(self.bridge_config_path)
        config = BridgeConfig(enabled=self.bridge_enabled_var.get(),
                              poll_interval_ms=current.poll_interval_ms)
        try:
            write_bridge_config(config, self.bridge_config_path)
            if config.enabled:
                self.bridge_transport.ensure_directories()
        except OSError as error:
            messagebox.showerror("Bridge configuration failed", str(error))
            return
        messagebox.showinfo(
            "Bridge restart required",
            "Restart Project Zomboid to apply the bridge startup setting.\n\n"
            "Once active, profiler capture settings can be changed live.")

    def bridge_ping(self) -> None:
        self._submit_bridge_action("ping")

    def bridge_refresh_capabilities(self) -> None:
        self._submit_bridge_action("capabilities")

    def _submit_bridge_action(self, command: str) -> None:
        try:
            request_id = self.bridge_client.submit("psychopatzcore.bridge", command)
            self.bridge_request_actions[request_id] = command
            self.bridge_response_var.set(f"{command} submitted")
        except (OSError, RuntimeError, ValueError) as error:
            self.bridge_response_var.set(f"Request failed: {error}")

    def set_game_mode(self, mode: str) -> None:
        config = self._capture_config_from_controls(mode)
        if mode == "OFF":
            config = CaptureConfig(mode="OFF", sections=config.sections,
                                   performance_interval_ms=config.performance_interval_ms,
                                   moddata_interval_ms=config.moddata_interval_ms,
                                   npc_interval_ms=config.npc_interval_ms,
                                   npc_scope=config.npc_scope, npc_ids=config.npc_ids)
        if self.bridge_status_var.get() == "CONNECTED":
            self._submit_live_capture_config(config)
        else:
            self._write_capture_config(config)

    def toggle_profiler_enabled(self) -> None:
        config = read_capture_config(self.game_config_path)
        if self.profiler_runtime_active or config.mode != "OFF":
            self.set_game_mode("OFF")
            return
        if not any((self.capture_performance_var.get(), self.capture_moddata_var.get(),
                    self.capture_npc_var.get())):
            self.capture_performance_var.set(True)
        self.apply_capture_setup()

    def _update_profiler_toggle(self, active: bool) -> None:
        self.profiler_runtime_active = bool(active)
        self.profiler_toggle_button.configure(
            text="Disable Profiling" if self.profiler_runtime_active else "Enable Profiling")

    def _write_capture_config(self, config: CaptureConfig) -> None:
        try:
            path = write_capture_config(config, self.game_config_path)
        except (OSError, PermissionError, ValueError) as error:
            messagebox.showerror("Could not update profiler", f"Failed to write the game configuration:\n{error}")
            return
        self.refresh_game_mode()
        if config.mode == "DETAILED":
            message = (
                f"Capture configured for: {', '.join(config.sections)}.\n\n"
                "Fully close and restart Project Zomboid, then load your save. "
                "This status changes to APPLIED only when a new runtime reports the same configuration."
            )
        else:
            message = (
                "Profiling is configured OFF.\n\n"
                "Fully close and restart Project Zomboid to return to strict zero-overhead mode."
            )
        messagebox.showinfo("Game restart required", f"{message}\n\nConfiguration: {path}")

    def refresh_candidates(self, auto_connect: bool = True) -> None:
        self.candidates = self.monitor.discover()
        self.process_combo["values"] = [candidate.label for candidate in self.candidates]
        preferred = select_preferred_candidate(self.candidates, self.app_settings)
        displayed = preferred or (self.candidates[0] if self.candidates else None)
        if displayed and (not self.process_var.get() or preferred):
            self.process_var.set(displayed.label)
        if auto_connect and self.monitor.process is None:
            target = preferred if self.app_settings.auto_connect else None
            if target is None and not self.app_settings.has_preferred_process and len(self.candidates) == 1:
                target = self.candidates[0]
            if target and self.monitor.select(target.pid):
                self.process_var.set(target.label)
                if not self.app_settings.has_preferred_process:
                    self._remember_candidate(target)

    def connect_selected(self) -> None:
        selected = self.process_var.get()
        for candidate in self.candidates:
            if candidate.label == selected:
                if self.monitor.select(candidate.pid):
                    self._remember_candidate(candidate)
                return

    def _remember_candidate(self, candidate: Any) -> None:
        current = replace(self.app_settings, poll_interval=self.interval,
                          selected_tab=self._selected_tab_name())
        self.app_settings = settings_for_candidate(candidate, current)
        self._save_ui_preferences()
        self._update_preferred_process_text()

    def _update_preferred_process_text(self) -> None:
        if self.app_settings.has_preferred_process:
            kind = f" ({self.app_settings.preferred_process_kind})" \
                if self.app_settings.preferred_process_kind else ""
            self.preferred_process_var.set(
                f"Saved auto-connect process: {self.app_settings.preferred_process_name}{kind} — PID is discovered")
        else:
            self.preferred_process_var.set("No saved process identity — Connect once to remember this process name")

    def _selected_tab_name(self) -> str:
        try:
            return str(self.notebook.tab(self.notebook.select(), "text") or "Performance")
        except (AttributeError, tk.TclError):
            return self.app_settings.selected_tab

    def _restore_selected_tab(self) -> None:
        for tab in self.notebook.tabs():
            if self.notebook.tab(tab, "text") == self.app_settings.selected_tab:
                self.notebook.select(tab)
                return

    def _save_ui_preferences(self) -> None:
        self.app_settings = replace(self.app_settings, poll_interval=self.interval,
                                    selected_tab=self._selected_tab_name())
        try:
            write_app_settings(self.app_settings, self.app_settings_path)
        except OSError:
            pass

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
        self._save_ui_preferences()

    def poll(self) -> None:
        if self.closed:
            return
        if self.paused:
            self._poll_bridge(self.model.last_process)
            self.root.after(int(self.interval * 1000), self.poll)
            return
        process = self.monitor.sample()
        if not process.get("connected") and self.monitor.process is None:
            self.refresh_candidates()
        snapshot = self.reader.read()
        self.model.update(process, snapshot)
        self._poll_bridge(process)
        self._update_llm_report(process, snapshot)
        self._render(process, snapshot)
        self.root.after(int(self.interval * 1000), self.poll)

    def _poll_bridge(self, process: dict[str, Any]) -> None:
        config = read_bridge_config(self.bridge_config_path)
        runtime = self.bridge_client.refresh_runtime()
        fresh = False
        if runtime and process.get("connected") and process.get("uptime") is not None:
            try:
                runtime_mtime = (self.bridge_transport.state / "runtime.json").stat().st_mtime
                fresh = runtime_mtime >= time.time() - float(process["uptime"]) - 2.0
            except (OSError, TypeError, ValueError):
                fresh = False
        if not fresh:
            self.bridge_client.runtime = None
            runtime = None
        if not config.enabled:
            self.bridge_status_var.set("RESTART REQUIRED TO DISABLE" if fresh else "DISABLED")
        elif not process.get("connected"):
            self.bridge_status_var.set("DISCONNECTED")
        elif not runtime:
            self.bridge_status_var.set("RESTART REQUIRED / WAITING")
        elif runtime.get("config_fingerprint") != config.fingerprint:
            self.bridge_status_var.set("RESTART REQUIRED")
        else:
            self.bridge_status_var.set("CONNECTED")
        self.bridge_runtime_var.set(str((runtime or {}).get("runtime_id") or "N/A"))
        self.bridge_protocol_var.set(str((runtime or {}).get("protocol_version") or "N/A"))
        if self.live_profiler_runtime_id and (runtime or {}).get("runtime_id") != self.live_profiler_runtime_id:
            self.live_profiler_fingerprint = None
            self.live_profiler_runtime_id = None
        responses = self.bridge_client.poll()
        self.bridge_pending_var.set(str(len(self.bridge_client.pending)))
        average = self.bridge_client.average_latency_ms
        self.bridge_latency_var.set(f"{average:.1f} ms" if average is not None else "N/A")
        for response in responses:
            action = self.bridge_request_actions.pop(response.request_id, "request")
            if response.status == "ok":
                self.bridge_response_var.set(f"{action}: OK from {response.runtime_id}")
                if action == "capabilities":
                    self._render_bridge_capabilities((response.result or {}).get("namespaces") or {})
                elif action == "configure":
                    result = response.result or {}
                    suffix = "restart required" if result.get("restart_required") else "applied live"
                    self.bridge_response_var.set(f"Profiler settings {suffix} by {response.runtime_id}")
                    if result.get("applied") and not result.get("restart_required"):
                        self.live_profiler_fingerprint = result.get("config_fingerprint")
                        self.live_profiler_runtime_id = response.runtime_id
            else:
                error = response.error or {}
                self.bridge_response_var.set(f"{action}: {error.get('code')} — {error.get('message')}")
        if self.bridge_client.failures:
            request_id = next(reversed(self.bridge_client.failures))
            if request_id in self.bridge_request_actions:
                action = self.bridge_request_actions.pop(request_id)
                self.bridge_response_var.set(f"{action}: {self.bridge_client.failures[request_id]}")

    def _render_bridge_capabilities(self, namespaces: dict[str, Any]) -> None:
        self.bridge_capabilities.delete(*self.bridge_capabilities.get_children())
        for namespace in sorted(namespaces):
            parent = self.bridge_capabilities.insert("", "end", text=namespace, open=True)
            commands = namespaces.get(namespace, {}).get("commands", [])
            for command in commands[:64]:
                if isinstance(command, str):
                    name, category, access = command, "READ", "read-only"
                else:
                    name = str(command.get("name") or "unknown")
                    category = str(command.get("category") or "READ")
                    access = "read-only" if command.get("read_only") else "mutating"
                self.bridge_capabilities.insert(parent, "end", text=name,
                                                values=(category, access))

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
        config = read_capture_config(self.game_config_path)
        _runtime_state, runtime_text = runtime_application_state(
            config, snapshot, config_path=self.game_config_path, process=process)
        if (self.live_profiler_fingerprint == config.fingerprint
                and self.live_profiler_runtime_id == (self.bridge_client.runtime or {}).get("runtime_id")):
            runtime_text = (f"APPLIED LIVE by bridge runtime {str(self.live_profiler_runtime_id)[:16]} — "
                            f"capturing: {', '.join(config.sections) if config.mode != 'OFF' else 'none'}")
            profiler_active = config.mode != "OFF"
        else:
            current_snapshot = (connected and self.reader.status == "snapshot connected"
                                and bool(((snapshot or {}).get("runtime") or {}).get("id")))
            profiler_active = ((snapshot or {}).get("mode") != "OFF") if current_snapshot \
                else config.mode != "OFF"
        self.game_mode_var.set(runtime_text)
        self._update_profiler_toggle(profiler_active)
        self._render_metrics(snapshot)
        self._render_moddata(snapshot)
        self._render_npcs(snapshot)
        self._render_graph()
        warnings = list(self.model.warnings)
        if snapshot:
            warnings.extend(str(item.get("message")) for item in snapshot.get("warnings") or [] if item.get("message"))
        self.warning_var.set(" • ".join(warnings[-3:]) if warnings else "No warnings")

    def _render_metrics(self, snapshot: Optional[dict[str, Any]]) -> None:
        tree_state = self._capture_tree_state(self.metrics)
        self.metrics.delete(*self.metrics.get_children())
        if not snapshot:
            self.metrics.insert(
                "", "end",
                text="No profiler snapshot",
                values=("Enable DETAILED mode, then restart Project Zomboid", "status"),
            )
            return
        display_names = {name: data.get("displayName", name) for name, data in (snapshot or {}).get("namespaces", {}).items()}
        values = list(iter_snapshot_metrics(snapshot))
        column, reverse = self.metric_sort
        self._update_sort_headings(self.metrics, column, reverse,
                                   {"name": "Namespace / metric", "value": "Value", "kind": "Kind"})
        namespace_trees = {}
        namespace_totals = {}
        for namespace, name, kind, value in values:
            root = namespace_trees.setdefault(namespace, {"children": {}, "metric": None})
            node = root
            for segment in name.split("."):
                node = node["children"].setdefault(segment, {"children": {}, "metric": None})
            node["metric"] = (kind, value)
        for namespace, root in namespace_trees.items():
            namespace_totals[namespace] = self._node_timer_total(root)
        namespaces = list(namespace_trees)
        namespaces.sort(key=lambda name: namespace_totals.get(name, 0)
                        if column == "value" else name.casefold(), reverse=reverse)
        for namespace in namespaces:
            label = display_names.get(namespace, namespace)
            iid = f"metric|{namespace}"
            namespace_node = self.metrics.insert(
                "", "end", iid=iid, text=label,
                values=(f"{namespace_totals.get(namespace, 0):.2f} ms/s", "namespace"),
                open=self.metric_open_state.get(iid, True),
            )
            self._insert_metric_children(namespace_node, namespace, "", namespace_trees[namespace], tree_state)
        self._restore_tree_state(self.metrics, tree_state)

    def _node_timer_total(self, node: dict[str, Any]) -> float:
        metric = node.get("metric")
        if metric and metric[0] == "timer":
            return float(metric[1])
        return sum(self._node_timer_total(child) for child in node.get("children", {}).values())

    def _metric_node_value(self, node: dict[str, Any]) -> tuple[str, float]:
        metric = node.get("metric")
        if metric:
            return str(metric[0]), float(metric[1])
        return "group", self._node_timer_total(node)

    def _insert_metric_children(self, parent: str, namespace: str, prefix: str,
                                root: dict[str, Any], tree_state: dict[str, Any]) -> None:
        rows = []
        for segment, original in root.get("children", {}).items():
            label_parts = [segment]
            path_parts = [segment]
            node = original
            while node.get("metric") is None and len(node.get("children", {})) == 1:
                next_segment, next_node = next(iter(node["children"].items()))
                label_parts.append(next_segment)
                path_parts.append(next_segment)
                node = next_node
            path = ".".join(filter(None, (prefix, ".".join(path_parts))))
            kind, value = self._metric_node_value(node)
            rows.append((".".join(label_parts), path, node, kind, value))
        column, reverse = self.metric_sort
        if column == "value":
            rows.sort(key=lambda item: item[4], reverse=reverse)
        elif column == "kind":
            rows.sort(key=lambda item: item[3].casefold(), reverse=reverse)
        else:
            rows.sort(key=lambda item: item[0].casefold(), reverse=reverse)
        for label, path, node, kind, value in rows:
            suffix = " ms/s" if kind in ("timer", "group") else " /s" if kind == "rate" else ""
            iid = f"metric|{namespace}|{path}"
            inserted = self.metrics.insert(
                parent, "end", iid=iid, text=label,
                values=(f"{value:.2f}{suffix}", kind),
                open=self.metric_open_state.get(iid, True),
            )
            self._insert_metric_children(inserted, namespace, path, node, tree_state)

    @staticmethod
    def _capture_tree_state(tree: Any) -> dict[str, Any]:
        opened = {}
        def visit(parent: str) -> None:
            for iid in tree.get_children(parent):
                opened[iid] = bool(tree.item(iid, "open"))
                visit(iid)
        visit("")
        yview = tree.yview()
        return {"open": opened, "selection": tuple(tree.selection()),
                "focus": tree.focus(), "y": yview[0] if yview else 0.0}

    @staticmethod
    def _restore_tree_state(tree: Any, state: dict[str, Any]) -> None:
        selection = [iid for iid in state.get("selection", ()) if tree.exists(iid)]
        if selection:
            tree.selection_set(selection)
        focus = state.get("focus")
        if focus and tree.exists(focus):
            tree.focus(focus)
        tree.yview_moveto(state.get("y", 0.0))

    def _bind_open_state(self, tree: Any, attribute: str) -> None:
        tree.bind("<<TreeviewOpen>>",
                  lambda _event: self._remember_open_state(tree, attribute, True), add="+")
        tree.bind("<<TreeviewClose>>",
                  lambda _event: self._remember_open_state(tree, attribute, False), add="+")

    def _remember_open_state(self, tree: Any, attribute: str, opened: bool) -> None:
        iid = tree.focus()
        if iid:
            getattr(self, attribute)[iid] = opened

    def _render_moddata(self, snapshot: Optional[dict[str, Any]]) -> None:
        tree_state = self._capture_tree_state(self.moddata_tree)
        self.moddata_tree.delete(*self.moddata_tree.get_children())
        self.moddata_npc_by_iid = {}
        diagnostic = ((snapshot or {}).get("diagnostics") or {}).get("ProjectHoomans.modData")
        if not isinstance(diagnostic, dict):
            capture = (((snapshot or {}).get("runtime") or {}).get("capture") or {})
            reason = "Capture disabled in the running game" if capture.get("moddata") is False \
                else "Waiting for the next bounded ModData scan"
            self.moddata_tree.insert("", "end", text="No ModData diagnostic yet",
                                     values=("N/A", reason))
            return
        sections = (
            ("Persisted PNC ModData", "persisted"),
            ("Runtime NPC records", "runtimeRecords"),
            ("Inventory state", "inventories"),
        )
        column, reverse = self.moddata_sort
        self._update_sort_headings(self.moddata_tree, column, reverse,
                                   {"name": "Section / largest path", "estimated": "Estimated shape",
                                    "details": "Counts / status"})
        section_rows = []
        for label, key in sections:
            data = diagnostic.get(key) or {}
            section_rows.append((label, key, data))
        if column == "estimated":
            section_rows.sort(key=lambda item: float(item[2].get("estimatedBytes") or 0), reverse=reverse)
        else:
            section_rows.sort(key=lambda item: item[0].casefold(), reverse=reverse)
        for label, key, data in section_rows:
            detail_parts = [f"nodes={data.get('nodes', 0)}", f"tables={data.get('tables', 0)}",
                            f"entries={data.get('entries', 0)}"]
            if key == "persisted":
                detail_parts.append(f"stores={data.get('modDataTables', 0)}")
            if key == "runtimeRecords":
                detail_parts.append(f"records={data.get('recordCount', 0)}")
            if key == "inventories":
                detail_parts.extend((f"records={data.get('recordCount', 0)}",
                                     f"items={data.get('itemCount', 0)}",
                                     f"oplog={data.get('operationLogEntries', 0)}"))
            if data.get("truncated"):
                detail_parts.append("TRUNCATED")
            parent = self.moddata_tree.insert("", "end", text=label,
                                              iid=f"moddata|{key}",
                                              values=(human_bytes(data.get("estimatedBytes")),
                                                      "  ".join(detail_parts)),
                                              open=self.moddata_open_state.get(f"moddata|{key}", True))
            paths = list((data.get("topPaths") or [])[:30])
            if column == "estimated":
                paths.sort(key=lambda item: float(item.get("estimatedBytes") or 0), reverse=reverse)
            else:
                paths.sort(key=lambda item: str(item.get("path", "")).casefold(), reverse=reverse)
            for item in paths[:15]:
                path = str(item.get("path", ""))
                self.moddata_tree.insert(parent, "end", iid=f"moddata|{key}|{path}", text=path,
                                         values=(human_bytes(item.get("estimatedBytes")), "top retained path"))
        records = list(snapshot_npc_data(snapshot).get("records") or [])
        npc_parent_iid = "moddata|npcs"
        npc_total = sum(float(item.get("runtimeEstimatedBytes") or 0) for item in records)
        npc_parent = self.moddata_tree.insert(
            "", "end", iid=npc_parent_iid, text="Per-NPC data (double-click to inspect)",
            values=(human_bytes(npc_total), f"{len(records)} bounded NPC records"),
            open=self.moddata_open_state.get(npc_parent_iid, True),
        )
        if column == "estimated":
            records.sort(key=lambda item: float(item.get("runtimeEstimatedBytes") or 0), reverse=reverse)
        else:
            records.sort(key=lambda item: str(item.get("name") or "").casefold(), reverse=reverse)
        for record in records:
            npc_id = str(record.get("id") or "unknown")
            iid = "moddata|npc|" + hashlib.sha1(npc_id.encode("utf-8", "replace")).hexdigest()
            self.moddata_npc_by_iid[iid] = record
            runtime = record.get("runtimeContent") or {}
            inventory = runtime.get("inventory") or {} if isinstance(runtime, dict) else {}
            details = (
                f"items={record.get('inventoryItems', len(inventory.get('items') or {}))}  "
                f"worn={record.get('wornItems', len(inventory.get('worn') or {}))}  "
                f"equipped={record.get('equippedItems', len(inventory.get('equipped') or {}))}  "
                f"persisted={human_bytes(record.get('persistedEstimatedBytes'))}  "
                f"{record.get('faction', 'unknown')} / {record.get('presence', 'unknown')}"
            )
            self.moddata_tree.insert(
                npc_parent, "end", iid=iid, text=str(record.get("name") or "Unknown NPC"),
                values=(human_bytes(record.get("runtimeEstimatedBytes")), details),
            )
        self._restore_tree_state(self.moddata_tree, tree_state)

    def on_moddata_activate(self, _event: Any = None) -> None:
        selection = self.moddata_tree.selection()
        if not selection:
            return
        record = self.moddata_npc_by_iid.get(selection[0])
        if not record:
            return
        self.selected_npc_id = record.get("id")
        self._render_npcs(self.model.last_snapshot)
        self.notebook.select(self.npc_tab)

    @staticmethod
    def _update_sort_headings(tree: Any, column: str, reverse: bool, labels: dict[str, str]) -> None:
        arrow = " ▼" if reverse else " ▲"
        tree.heading("#0", text=labels["name"] + (arrow if column == "name" else ""))
        for key, label in labels.items():
            if key != "name":
                tree.heading(key, text=label + (arrow if column == key else ""))

    def _toggle_sort(self, attribute: str, column: str) -> None:
        current_column, current_reverse = getattr(self, attribute)
        setattr(self, attribute, (column, not current_reverse if current_column == column else column in
                                  ("value", "estimated", "runtime", "persisted", "items")))
        self._render(self.model.last_process, self.model.last_snapshot)

    def set_metric_sort(self, column: str) -> None:
        self._toggle_sort("metric_sort", column)

    def set_moddata_sort(self, column: str) -> None:
        self._toggle_sort("moddata_sort", column)

    def set_npc_sort(self, column: str) -> None:
        self._toggle_sort("npc_sort", column)

    def _render_npcs(self, snapshot: Optional[dict[str, Any]]) -> None:
        tree_state = self._capture_tree_state(self.npc_tree)
        selected_id = self.selected_npc_id
        self.npc_tree.delete(*self.npc_tree.get_children())
        self.npc_by_iid = {}
        npc_data = snapshot_npc_data(snapshot)
        records = list(npc_data.get("records") or [])
        roster = list(npc_data.get("roster") or [])
        records_by_id = {str(item.get("id")): item for item in records}
        for item in roster:
            records_by_id.setdefault(str(item.get("id")), item)
        records = list(records_by_id.values())
        column, reverse = self.npc_sort
        numeric = {"runtime": "runtimeEstimatedBytes", "persisted": "persistedEstimatedBytes", "items": "inventoryItems"}
        if column in numeric:
            records.sort(key=lambda item: float(item.get(numeric[column]) or 0), reverse=reverse)
        else:
            records.sort(key=lambda item: str(item.get(column, "")).casefold(), reverse=reverse)
        self._update_sort_headings(self.npc_tree, column, reverse, {
            "name": "NPC name", "faction": "Faction", "presence": "Presence",
            "runtime": "Runtime", "persisted": "Persisted", "items": "Items",
        })
        selected_iid = None
        selected_record = None
        for record in records:
            iid = f"npc|{record.get('id')}"
            self.npc_by_iid[iid] = record
            self.npc_tree.insert("", "end", iid=iid, text=str(record.get("name") or "Unknown NPC"), values=(
                record.get("faction", "unknown"), record.get("presence", "unknown"),
                human_bytes(record.get("runtimeEstimatedBytes")),
                human_bytes(record.get("persistedEstimatedBytes")), record.get("inventoryItems", 0),
            ))
            if str(record.get("id")) == str(selected_id):
                selected_iid = iid
                selected_record = record
        if selected_iid:
            self.npc_tree.selection_set(selected_iid)
            self.npc_tree.focus(selected_iid)
            self._show_npc_content(selected_record)
        elif records:
            first = f"npc|{records[0].get('id')}"
            self.npc_tree.selection_set(first)
            self.npc_tree.focus(first)
            self.selected_npc_id = records[0].get("id")
            self._show_npc_content(records[0])
        else:
            self.npc_inventory_tree.delete(*self.npc_inventory_tree.get_children())
            self.npc_inventory_tree.insert("", "end", text="No NPC diagnostic yet", values=("", "status"))
            self.npc_content_tree.delete(*self.npc_content_tree.get_children())
            self.npc_content_tree.insert("", "end", text="No NPC diagnostic yet", values=("", "status"))
        self._restore_tree_state(self.npc_tree, tree_state)

    def on_npc_selected(self, _event: Any = None) -> None:
        selection = self.npc_tree.selection()
        if not selection:
            return
        record = self.npc_by_iid.get(selection[0])
        if record:
            self.selected_npc_id = record.get("id")
            self._show_npc_content(record)

    def capture_selected_npc(self) -> None:
        if not self.selected_npc_id:
            messagebox.showinfo("No NPC selected", "Select an NPC in the NPC Data Inspector first.")
            return
        self.capture_npc_var.set(True)
        self.capture_npc_ids_var.set(str(self.selected_npc_id))
        self.apply_capture_setup()

    def _show_npc_content(self, record: dict[str, Any]) -> None:
        self._show_npc_inventory(record)
        tree_state = self._capture_tree_state(self.npc_content_tree)
        self.npc_content_tree.delete(*self.npc_content_tree.get_children())
        title_iid = "content|npc"
        title = self.npc_content_tree.insert(
            "", "end", iid=title_iid, text=str(record.get("name") or "Unknown NPC"),
            values=(record.get("id", ""), "NPC"), open=self.content_open_state.get(title_iid, True))
        for label, key, estimated, truncated in (
            ("Runtime record", "runtimeContent", "runtimeEstimatedBytes", "runtimeTruncated"),
            ("Persisted ModData", "persistedContent", "persistedEstimatedBytes", "persistedTruncated"),
        ):
            root_iid = f"content|{key}"
            node = self.npc_content_tree.insert(
                title, "end", iid=root_iid, text=label,
                values=(human_bytes(record.get(estimated)), "truncated" if record.get(truncated) else "table"),
                open=self.content_open_state.get(root_iid, True),
            )
            self._insert_content(node, record.get(key), 0, key)
        self._restore_tree_state(self.npc_content_tree, tree_state)

    @staticmethod
    def _inventory_item_name(item_id: Any, item: Any) -> str:
        if isinstance(item, dict):
            return str(item.get("customName") or item.get("displayName") or
                       item.get("fullType") or item.get("type") or item_id)
        return str(item or item_id)

    @staticmethod
    def _inventory_item_state(item: Any) -> str:
        if not isinstance(item, dict):
            return ""
        parts = []
        for label, key in (("qty", "stack"), ("condition", "cond"), ("uses", "uses"),
                           ("ammo", "ammoCount"), ("template", "templateKey")):
            if item.get(key) is not None:
                parts.append(f"{label}={item[key]}")
        state = item.get("itemState")
        if isinstance(state, dict) and state:
            parts.append("state=" + ",".join(sorted(str(key) for key in state)[:8]))
        return "  ".join(parts)

    def _show_npc_inventory(self, record: dict[str, Any]) -> None:
        tree_state = self._capture_tree_state(self.npc_inventory_tree)
        self.npc_inventory_tree.delete(*self.npc_inventory_tree.get_children())
        runtime = record.get("runtimeContent") or {}
        inventory = runtime.get("inventory") or {} if isinstance(runtime, dict) else {}
        if not isinstance(inventory, dict):
            inventory = {}
        items = inventory.get("items") or {}
        if not isinstance(items, dict):
            items = {str(index): item for index, item in enumerate(items)} if isinstance(items, list) else {}
        name = str(record.get("name") or "Unknown NPC")
        root_iid = "inventory|npc"
        root = self.npc_inventory_tree.insert(
            "", "end", iid=root_iid, text=name,
            values=(record.get("id", ""), f"{len(items)} item records"),
            open=self.inventory_open_state.get(root_iid, True),
        )
        for label, key in (("Equipped", "equipped"), ("Worn clothing", "worn"),
                           ("Attached", "attached")):
            values = inventory.get(key) or {}
            if not isinstance(values, dict):
                continue
            category_iid = f"inventory|{key}"
            category = self.npc_inventory_tree.insert(
                root, "end", iid=category_iid, text=label, values=("", f"{len(values)} slots"),
                open=self.inventory_open_state.get(category_iid, True),
            )
            for slot, item_id in sorted(values.items(), key=lambda pair: str(pair[0]).casefold()):
                item = items.get(str(item_id), items.get(item_id))
                self.npc_inventory_tree.insert(
                    category, "end", iid=self._inventory_iid(f"{key}.{slot}"),
                    text=self._inventory_item_name(item_id, item), values=(str(slot), str(item_id)),
                )
        item_root_iid = "inventory|items"
        item_root = self.npc_inventory_tree.insert(
            root, "end", iid=item_root_iid, text="All items", values=("", f"{len(items)} records"),
            open=self.inventory_open_state.get(item_root_iid, True),
        )
        for item_id, item in sorted(items.items(), key=lambda pair: self._inventory_item_name(*pair).casefold()):
            location = ""
            if isinstance(item, dict):
                location = str(item.get("containerId") or item.get("container") or item.get("location") or "")
            self.npc_inventory_tree.insert(
                item_root, "end", iid=self._inventory_iid(f"items.{item_id}"),
                text=self._inventory_item_name(item_id, item),
                values=(location, self._inventory_item_state(item)),
            )
        containers = inventory.get("containers") or {}
        if isinstance(containers, dict):
            container_iid = "inventory|containers"
            container_root = self.npc_inventory_tree.insert(
                root, "end", iid=container_iid, text="Containers", values=("", f"{len(containers)} records"),
                open=self.inventory_open_state.get(container_iid, False),
            )
            for container_id, container in sorted(containers.items(), key=lambda pair: str(pair[0]).casefold()):
                contained = container.get("items") or [] if isinstance(container, dict) else []
                state = f"items={len(contained)}"
                if isinstance(container, dict) and container.get("maxWeight") is not None:
                    state += f"  maxWeight={container['maxWeight']}"
                self.npc_inventory_tree.insert(
                    container_root, "end", iid=self._inventory_iid(f"containers.{container_id}"),
                    text=str(container_id), values=("container", state),
                )
        self._restore_tree_state(self.npc_inventory_tree, tree_state)

    @staticmethod
    def _inventory_iid(path: str) -> str:
        return "inventory|" + hashlib.sha1(path.encode("utf-8", "replace")).hexdigest()

    @staticmethod
    def _content_iid(path: str) -> str:
        return "content|" + hashlib.sha1(path.encode("utf-8", "replace")).hexdigest()

    def _insert_content(self, parent: str, value: Any, depth: int, path: str) -> None:
        if depth > 10:
            return
        if isinstance(value, dict):
            for key in sorted(value, key=lambda item: str(item).casefold()):
                child = value[key]
                child_path = f"{path}.{key}"
                if isinstance(child, (dict, list)):
                    iid = self._content_iid(child_path)
                    node = self.npc_content_tree.insert(
                        parent, "end", iid=iid, text=str(key),
                        values=(f"{len(child)} entries", type(child).__name__),
                        open=self.content_open_state.get(iid, False))
                    self._insert_content(node, child, depth + 1, child_path)
                else:
                    self.npc_content_tree.insert(parent, "end", iid=self._content_iid(child_path), text=str(key),
                                                 values=(str(child), type(child).__name__))
        elif isinstance(value, list):
            for index, child in enumerate(value):
                child_path = f"{path}[{index}]"
                iid = self._content_iid(child_path)
                node = self.npc_content_tree.insert(
                    parent, "end", iid=iid, text=f"[{index}]",
                    values=("" if isinstance(child, (dict, list)) else str(child), type(child).__name__),
                    open=self.content_open_state.get(iid, False))
                if isinstance(child, (dict, list)):
                    self._insert_content(node, child, depth + 1, child_path)
        elif value is not None:
            self.npc_content_tree.insert(parent, "end", iid=self._content_iid(f"{path}.value"),
                                         text="value", values=(str(value), type(value).__name__))

    def _update_llm_report(self, process: dict[str, Any], snapshot: Optional[dict[str, Any]]) -> None:
        timestamp = (snapshot or {}).get("timestamp")
        if not snapshot or timestamp == self.last_llm_snapshot_timestamp:
            return
        try:
            write_llm_report(build_llm_report(process, snapshot), self.llm_report_path)
            self.last_llm_snapshot_timestamp = timestamp
            self.llm_status_var.set(f"Auto LLM report:\n{self.llm_report_path}")
        except OSError as error:
            self.llm_status_var.set(f"LLM report write failed: {error}")

    def open_llm_export_dialog(self) -> None:
        if not self.model.last_snapshot:
            messagebox.showinfo("No report available", "Wait for a connected profiler snapshot first.")
            return
        existing = getattr(self, "llm_export_dialog", None)
        if existing is not None and existing.winfo_exists():
            existing.lift()
            return
        dialog = tk.Toplevel(self.root)
        self.llm_export_dialog = dialog
        dialog.title("Build LLM Debug Report")
        dialog.transient(self.root)
        dialog.resizable(False, False)
        body = ttk.Frame(dialog, padding=14)
        body.pack(fill="both", expand=True)
        ttk.Label(body, text="Choose only the profiler data needed for this debugging report.").pack(
            anchor="w", pady=(0, 10))
        performance_var = tk.BooleanVar(value=True)
        moddata_var = tk.BooleanVar(value=True)
        npc_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(
            body, text="Performance — process usage, timers, gauges, and warnings",
            variable=performance_var,
        ).pack(anchor="w", pady=2)
        ttk.Checkbutton(
            body, text="ModData size — bounded aggregate size and retained paths",
            variable=moddata_var,
        ).pack(anchor="w", pady=2)
        npc_check = ttk.Checkbutton(
            body, text="NPC Data Inspector — selected NPC state, animation, inventory, and clothing",
            variable=npc_var,
        )
        npc_check.pack(anchor="w", pady=2)
        npc_row = ttk.Frame(body)
        npc_row.pack(fill="x", padx=(24, 0), pady=(4, 10))
        ttk.Label(npc_row, text="NPC:").pack(side="left", padx=(0, 6))
        npc_data = snapshot_npc_data(self.model.last_snapshot)
        records = list(npc_data.get("records") or [])
        records_by_id = {str(item.get("id")): item for item in records}
        for item in npc_data.get("roster") or []:
            records_by_id.setdefault(str(item.get("id")), item)
        records = list(records_by_id.values())
        npc_choices = {}
        selected_label = ""
        for record in records:
            label = f"{record.get('name') or 'Unknown NPC'} — {record.get('id') or 'unknown'}"
            npc_choices[label] = str(record.get("id") or "")
            if str(record.get("id")) == str(self.selected_npc_id):
                selected_label = label
        if not selected_label and npc_choices:
            selected_label = next(iter(npc_choices))
        npc_choice_var = tk.StringVar(value=selected_label)
        npc_combo = ttk.Combobox(
            npc_row, textvariable=npc_choice_var, values=tuple(npc_choices), state="readonly", width=54)
        npc_combo.pack(side="left", fill="x", expand=True)
        if not npc_choices:
            npc_check.configure(state="disabled")
            npc_combo.configure(state="disabled")
            ttk.Label(body, text="No bounded NPC records are present in this snapshot.").pack(anchor="w", padx=(24, 0))
        buttons = ttk.Frame(body)
        buttons.pack(fill="x", pady=(8, 0))
        ttk.Button(buttons, text="Cancel", command=dialog.destroy).pack(side="right")
        ttk.Button(
            buttons, text="Choose File & Export",
            command=lambda: self._perform_llm_export(
                dialog, performance_var.get(), moddata_var.get(),
                npc_choices.get(npc_choice_var.get()) if npc_var.get() else None,
                npc_var.get()),
        ).pack(side="right", padx=(0, 6))
        dialog.protocol("WM_DELETE_WINDOW", dialog.destroy)
        dialog.grab_set()

    def _perform_llm_export(self, dialog: Any, include_performance: bool,
                            include_moddata: bool, npc_id: Optional[str],
                            include_npc: bool) -> None:
        if not include_performance and not include_moddata and not include_npc:
            messagebox.showwarning("Nothing selected", "Select at least one report section.", parent=dialog)
            return
        if include_npc and not npc_id:
            messagebox.showwarning("NPC required", "Choose an NPC for the NPC Data Inspector section.", parent=dialog)
            return
        selected = filedialog.asksaveasfilename(
            title="Export selected LLM debug report",
            defaultextension=".json",
            initialfile="PsychopatzCore_Profiler_LLM.json",
            filetypes=(("JSON reports", "*.json"), ("All files", "*")),
            parent=dialog,
        )
        if not selected:
            return
        try:
            report = build_llm_report(
                self.model.last_process, self.model.last_snapshot,
                include_performance=include_performance,
                include_moddata=include_moddata,
                npc_id=npc_id if include_npc else None,
            )
            path = write_llm_report(report, Path(selected))
            dialog.destroy()
            messagebox.showinfo("LLM report exported", f"Saved the selected profiler sections to:\n{path}")
        except OSError as error:
            messagebox.showerror("Export failed", str(error), parent=dialog)

    def export_llm_report(self) -> None:
        """Compatibility entry point for older callers."""
        self.open_llm_export_dialog()

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

    def toggle_pause(self) -> None:
        self.paused = not self.paused
        self.pause_button.configure(text="Resume Updates" if self.paused else "Pause Updates")
        if self.paused:
            self.status_var.set("PAUSED")
        else:
            connected = self.model.last_process.get("connected") is True
            self.status_var.set("CONNECTED" if connected else "DISCONNECTED")

    def add_marker(self) -> None:
        text = simpledialog.askstring("Add marker", "What happened at this point?")
        if text:
            self.model.add_marker(text)

    def close(self) -> None:
        self.closed = True
        self.model.recorder.stop()
        if hasattr(self, "app_settings"):
            self._save_ui_preferences()
        if hasattr(self, "bridge_client"):
            self.bridge_client.close()
        self.root.destroy()


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="PsychopatzCore cross-platform performance profiler")
    parser.add_argument("--pid", type=int, help="connect directly to a Project Zomboid client/server PID")
    parser.add_argument("--snapshot", type=Path, help="path to PsychopatzCore_Profiler_latest.json")
    parser.add_argument("--interval", type=float, choices=(0.5, 1.0, 2.0, 5.0),
                        help="override the saved GUI polling interval")
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
