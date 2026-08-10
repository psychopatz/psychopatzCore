#!/usr/bin/env python3
"""Lightweight cross-platform Tk monitor for PsychopatzCore snapshots."""

from __future__ import annotations

import argparse
import hashlib
import sys
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
                           read_game_profiler_mode, write_game_profiler_mode,
                           write_llm_report)


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
        self.llm_report_path = default_llm_report_path()
        self.llm_status_var = tk.StringVar(value="LLM report waiting for ModData diagnostics")
        self.last_llm_snapshot_timestamp = None
        self.metric_sort = ("value", True)
        self.moddata_sort = ("estimated", True)
        self.npc_sort = ("name", False)
        self.metric_open_state = {}
        self.moddata_open_state = {}
        self.content_open_state = {}
        self.paused = False
        self.selected_npc_id = None
        self.npc_by_iid = {}
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
        self.root.geometry("1080x860")
        self.root.minsize(820, 680)
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

        notebook = ttk.Notebook(outer)
        notebook.pack(fill="both", expand=True, pady=8)
        performance_tab = ttk.Frame(notebook, padding=6)
        moddata_tab = ttk.Frame(notebook, padding=6)
        npc_tab = ttk.Frame(notebook, padding=6)
        notebook.add(performance_tab, text="Performance")
        notebook.add(moddata_tab, text="ModData Summary")
        notebook.add(npc_tab, text="NPC Data Inspector")

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
        moddata_scroll.pack(side="left", fill="y")
        self._bind_open_state(self.moddata_tree, "moddata_open_state")
        moddata_actions = ttk.Frame(moddata)
        moddata_actions.pack(side="right", fill="y", padx=(8, 0))
        ttk.Button(moddata_actions, text="Export LLM Report", command=self.export_llm_report).pack(fill="x")
        ttk.Label(moddata_actions, textvariable=self.llm_status_var, wraplength=220).pack(fill="x", pady=(8, 0))

        npc_pane = ttk.Panedwindow(npc_tab, orient="horizontal")
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
        self.npc_content_tree = ttk.Treeview(
            npc_content_frame, columns=("value", "type"), show="tree headings",
        )
        self.npc_content_tree.heading("#0", text="Field")
        self.npc_content_tree.heading("value", text="Value")
        self.npc_content_tree.heading("type", text="Type")
        self.npc_content_tree.column("#0", width=260)
        self.npc_content_tree.column("value", width=300)
        self.npc_content_tree.column("type", width=80)
        content_scroll = ttk.Scrollbar(npc_content_frame, command=self.npc_content_tree.yview)
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
        if self.paused:
            self.root.after(int(self.interval * 1000), self.poll)
            return
        process = self.monitor.sample()
        if not process.get("connected") and self.monitor.process is None:
            self.refresh_candidates()
            if len(self.candidates) == 1:
                self.monitor.select(self.candidates[0].pid)
        snapshot = self.reader.read()
        self.model.update(process, snapshot)
        self._update_llm_report(process, snapshot)
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
        diagnostic = ((snapshot or {}).get("diagnostics") or {}).get("ProjectHoomans.modData")
        if not isinstance(diagnostic, dict):
            self.moddata_tree.insert("", "end", text="No ModData diagnostic yet",
                                     values=("N/A", "DETAILED mode; wait up to 10 seconds"))
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
        self._restore_tree_state(self.moddata_tree, tree_state)

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
        diagnostic = ((snapshot or {}).get("diagnostics") or {}).get("ProjectHoomans.modData") or {}
        npc_data = diagnostic.get("npcRecords") or {}
        records = list(npc_data.get("records") or [])
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

    def _show_npc_content(self, record: dict[str, Any]) -> None:
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
        diagnostic = ((snapshot or {}).get("diagnostics") or {}).get("ProjectHoomans.modData")
        timestamp = (snapshot or {}).get("timestamp")
        if not diagnostic or timestamp == self.last_llm_snapshot_timestamp:
            return
        try:
            write_llm_report(build_llm_report(process, snapshot), self.llm_report_path)
            self.last_llm_snapshot_timestamp = timestamp
            self.llm_status_var.set(f"Auto LLM report:\n{self.llm_report_path}")
        except OSError as error:
            self.llm_status_var.set(f"LLM report write failed: {error}")

    def export_llm_report(self) -> None:
        if not self.model.last_snapshot:
            messagebox.showinfo("No report available", "Wait for a connected profiler snapshot first.")
            return
        selected = filedialog.asksaveasfilename(
            title="Export compact LLM report",
            defaultextension=".json",
            initialfile="PsychopatzCore_Profiler_LLM.json",
            filetypes=(("JSON reports", "*.json"), ("All files", "*")),
        )
        if not selected:
            return
        try:
            path = write_llm_report(build_llm_report(self.model.last_process, self.model.last_snapshot), Path(selected))
            messagebox.showinfo("LLM report exported", f"Saved compact, value-redacted report to:\n{path}")
        except OSError as error:
            messagebox.showerror("Export failed", str(error))

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
