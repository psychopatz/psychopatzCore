#!/usr/bin/env python3
"""Token-bounded, read-only CLI over the same profiler model used by the GUI."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, Mapping, Optional

from profiler_config import read_capture_config, runtime_application_state
from profiler_core import (SNAPSHOT_FILENAME, ProcessMonitor, build_llm_report,
                           default_game_config_path, default_llm_report_path,
                           snapshot_npc_data)
from bridge import BridgeClient, FileBridgeTransport, read_bridge_config
from app_settings import (default_app_settings_path, read_app_settings,
                          select_preferred_candidate)


NPC_VIEW_TERMS = {
    "identity": ("identity", "name", "faction", "presence"),
    "ai": ("ai", "behavior", "decision", "target", "needs"),
    "animation": ("anim", "visual", "action", "bump"),
    "combat": ("combat", "attack", "weapon", "target", "retreat"),
    "pathing": ("path", "goal", "move", "locomotion", "position"),
    "inventory": ("inventory", "equipment", "worn", "attached", "item"),
    "health": ("health", "wound", "stamina", "body"),
}


def default_snapshot_path() -> Path:
    return Path.home() / "Zomboid" / "Lua" / SNAPSHOT_FILENAME


def read_snapshot(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(f"snapshot not found: {path}") from error
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"snapshot is unreadable or incomplete: {error}") from error
    if not isinstance(value, dict) or int(value.get("profilerVersion") or 0) != 1:
        raise ValueError("unsupported profiler snapshot")
    return value


def read_process_report(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return dict(value.get("process") or {}) if isinstance(value, dict) else {}
    except (FileNotFoundError, PermissionError, OSError, UnicodeError, json.JSONDecodeError):
        return {}


def capture_manifest(snapshot: Mapping[str, Any]) -> dict[str, bool]:
    capture = ((snapshot.get("runtime") or {}).get("capture") or {})
    if capture:
        return {name: capture.get(name) is True for name in ("performance", "moddata", "npc")}
    diagnostics = snapshot.get("diagnostics") or {}
    return {
        "performance": bool((snapshot.get("namespaces") or {}).get("ProjectHoomans")),
        "moddata": "ProjectHoomans.modData" in diagnostics,
        "npc": bool(snapshot_npc_data(snapshot)),
    }


def npc_rows(snapshot: Mapping[str, Any]) -> list[dict[str, Any]]:
    data = snapshot_npc_data(snapshot)
    rows: dict[str, dict[str, Any]] = {}
    for item in data.get("roster") or []:
        if isinstance(item, dict):
            rows[str(item.get("id"))] = dict(item)
    for item in data.get("records") or []:
        if isinstance(item, dict):
            rows[str(item.get("id"))] = dict(item)
    return sorted(rows.values(), key=lambda item: (str(item.get("name", "")).casefold(), str(item.get("id", ""))))


def resolve_npc(snapshot: Mapping[str, Any], query: str) -> str:
    rows = npc_rows(snapshot)
    exact_id = [row for row in rows if str(row.get("id")) == query]
    if exact_id:
        return str(exact_id[0].get("id"))
    exact_name = [row for row in rows if str(row.get("name", "")).casefold() == query.casefold()]
    if len(exact_name) == 1:
        return str(exact_name[0].get("id"))
    partial = [row for row in rows if query.casefold() in str(row.get("name", "")).casefold()]
    if len(partial) == 1:
        return str(partial[0].get("id"))
    candidates = exact_name or partial
    if candidates:
        labels = ", ".join(f"{row.get('name')} ({row.get('id')})" for row in candidates[:8])
        raise ValueError(f"NPC is ambiguous; use an exact ID. Candidates: {labels}")
    raise ValueError(f"NPC not found in captured roster: {query}")


def _filter_npc_value(value: Any, terms: tuple[str, ...]) -> Any:
    if isinstance(value, dict):
        output = {}
        for key, child in value.items():
            filtered = _filter_npc_value(child, terms)
            matches = any(term in str(key).casefold() for term in terms)
            if matches:
                output[key] = child
            elif filtered not in ({}, [], None):
                output[key] = filtered
        return output
    if isinstance(value, list):
        kept = [_filter_npc_value(item, terms) for item in value]
        return [item for item in kept if item not in ({}, [], None)]
    return None


def filter_npc_views(report: dict[str, Any], views: tuple[str, ...]) -> None:
    npc = report.get("npcData")
    if not isinstance(npc, dict) or not views:
        return
    terms = tuple(dict.fromkeys(term for view in views for term in NPC_VIEW_TERMS.get(view, ())))
    if not terms:
        return
    for key in ("runtimeContent", "persistedContent"):
        if key in npc:
            npc[key] = _filter_npc_value(npc[key], terms)
    npc["selectedViews"] = list(views)


def compact_value(value: Any, depth: int, max_items: int, max_string: int) -> Any:
    if isinstance(value, str):
        return value if len(value) <= max_string else value[:max_string] + "…"
    if isinstance(value, dict):
        if depth <= 0:
            return {"_omittedEntries": len(value)}
        keys = list(value)
        output = {key: compact_value(value[key], depth - 1, max_items, max_string)
                  for key in keys[:max_items]}
        if len(keys) > max_items:
            output["_omittedEntries"] = len(keys) - max_items
        return output
    if isinstance(value, list):
        if depth <= 0:
            return [{"_omittedItems": len(value)}]
        output = [compact_value(item, depth - 1, max_items, max_string)
                  for item in value[:max_items]]
        if len(value) > max_items:
            output.append({"_omittedItems": len(value) - max_items})
        return output
    return value


def enforce_budget(report: dict[str, Any], token_budget: int) -> dict[str, Any]:
    char_budget = max(1000, token_budget * 4)
    for depth, items, string_size in ((7, 30, 240), (6, 20, 180), (5, 12, 140), (4, 8, 100), (3, 5, 80)):
        compact = compact_value(report, depth, items, string_size)
        encoded = json.dumps(compact, ensure_ascii=True, separators=(",", ":"))
        if len(encoded) <= char_budget:
            if compact != report:
                compact["reportCompacted"] = True
            return compact
    return {
        "reportVersion": report.get("reportVersion"),
        "snapshot": report.get("snapshot"),
        "runtime": report.get("runtime"),
        "includedSections": report.get("includedSections"),
        "reportCompacted": True,
        "message": "Requested report exceeded the token budget; narrow sections, NPC views, or top count.",
    }


def build_summary(process: Mapping[str, Any], snapshot: dict[str, Any],
                  sections: tuple[str, ...], npc: Optional[str],
                  views: tuple[str, ...], top: int, minimum_ms: float,
                  token_budget: int) -> dict[str, Any]:
    manifest = capture_manifest(snapshot)
    disabled = [section for section in sections if not manifest.get(section)]
    if disabled:
        raise ValueError("requested sections were not captured by this runtime: "
                         + ", ".join(disabled)
                         + ". Enable them in the profiler GUI and restart Project Zomboid.")
    include_performance = "performance" in sections
    include_moddata = "moddata" in sections
    npc_id = resolve_npc(snapshot, npc) if "npc" in sections and npc else None
    if "npc" in sections and not npc_id:
        raise ValueError("--npc NAME_OR_ID is required when the npc section is selected")
    report = build_llm_report(process, snapshot, include_performance=include_performance,
                              include_moddata=include_moddata, npc_id=npc_id)
    report["capture"] = manifest
    performance = report.get("projectHoomans") or {}
    timers = [item for item in performance.get("topTimers") or []
              if float(item.get("selfMsPerSec", item.get("msPerSec")) or 0) >= minimum_ms]
    performance["topTimers"] = timers[:max(1, top)]
    performance["gauges"] = (performance.get("gauges") or [])[:max(1, top * 2)]
    filter_npc_views(report, views)
    return enforce_budget(report, token_budget)


def render_text(report: Mapping[str, Any]) -> str:
    lines = ["Psychopatz profiler report"]
    runtime = report.get("runtime") or {}
    lines.append(f"runtime={runtime.get('id', 'unknown')} sections={','.join(report.get('includedSections') or [])}")
    process = report.get("process") or {}
    if process:
        lines.append(f"process rss={process.get('rss')} cpu={process.get('cpu_percent')} threads={process.get('threads')}")
    timers = ((report.get("projectHoomans") or {}).get("topTimers") or [])
    if timers:
        lines.append("top timers:")
        lines.extend(f"- {item.get('name')}: {item.get('selfMsPerSec')} self ms/s "
                     f"({item.get('msPerSec')} inclusive), {item.get('callsPerSec')} calls/s"
                     for item in timers)
    moddata = report.get("modData")
    if isinstance(moddata, Mapping):
        lines.append("ModData:")
        for name in ("persisted", "runtimeRecords", "inventories"):
            section = moddata.get(name) or {}
            lines.append(f"- {name}: {section.get('estimatedBytes')} estimated bytes")
    npc = report.get("npcData")
    if isinstance(npc, Mapping):
        lines.append(f"NPC: {npc.get('name', 'unknown')} ({npc.get('id', 'unknown')})")
        lines.append(json.dumps(npc, ensure_ascii=True, separators=(",", ":")))
    if report.get("reportCompacted"):
        lines.append("report compacted to token budget")
    return "\n".join(lines)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="Bounded LLM interface for Psychopatz profiler snapshots")
    result.add_argument("--snapshot", type=Path, default=default_snapshot_path())
    result.add_argument("--config", type=Path, default=default_game_config_path())
    result.add_argument("--process-report", type=Path, default=default_llm_report_path(),
                        help="optional GUI-generated report used for the latest process sample")
    result.add_argument("--bridge-root", type=Path,
                        default=Path.home() / "Zomboid" / "Lua" / "PsychopatzBridge")
    result.add_argument("--app-settings", type=Path, default=default_app_settings_path())
    sub = result.add_subparsers(dest="command", required=True)
    sub.add_parser("status")
    sub.add_parser("list-sections")
    sub.add_parser("list-npcs")
    summary = sub.add_parser("summarize")
    summary.add_argument("--sections", default="performance",
                         help="comma-separated performance,moddata,npc")
    summary.add_argument("--npc")
    summary.add_argument("--npc-view", default="",
                         help="comma-separated identity,ai,animation,combat,pathing,inventory,health")
    summary.add_argument("--top", type=int, default=15)
    summary.add_argument("--min-ms", type=float, default=0.5)
    summary.add_argument("--token-budget", type=int, default=3000)
    summary.add_argument("--format", choices=("json", "text"), default="json")
    summary.add_argument("--output", type=Path)
    bridge = sub.add_parser("bridge", help="safe Psychopatz bridge infrastructure commands")
    bridge.add_argument("bridge_command", choices=("status", "ping", "capabilities"))
    bridge.add_argument("--timeout", type=float, default=5.0)
    process = sub.add_parser("process", help="inspect the GUI-saved process identity")
    process.add_argument("process_command", choices=("status",))
    return result


def run_bridge_command(args: argparse.Namespace) -> dict[str, Any]:
    client = BridgeClient(FileBridgeTransport(args.bridge_root))
    runtime = client.refresh_runtime()
    config = read_bridge_config()
    if args.bridge_command == "status":
        return {"configured": config.enabled, "config_fingerprint": config.fingerprint,
                "state": "available" if runtime else "disconnected", "runtime": runtime}
    if not runtime:
        raise ValueError("bridge runtime is unavailable; enable the bridge and restart Project Zomboid")
    request_id = client.submit("psychopatzcore.bridge", args.bridge_command,
                               timeout_seconds=max(0.1, args.timeout))
    deadline = time.monotonic() + max(0.1, args.timeout)
    while time.monotonic() < deadline:
        client.poll()
        response = client.take(request_id)
        if response:
            if response.status == "error":
                error = response.error or {}
                raise ValueError(f"{error.get('code')}: {error.get('message')}")
            return {"runtime_id": response.runtime_id, "result": response.result,
                    "round_trip_ms": client.latencies_ms[-1] if client.latencies_ms else None}
        if request_id in client.failures:
            raise ValueError(client.failures[request_id])
        time.sleep(0.05)
    raise ValueError("bridge request timed out")


def sample_saved_process(settings_path: Path) -> dict[str, Any]:
    settings = read_app_settings(settings_path)
    monitor = ProcessMonitor()
    candidates = monitor.discover()
    selected = select_preferred_candidate(candidates, settings)
    identity = {
        "configured": settings.has_preferred_process,
        "name": settings.preferred_process_name or None,
        "executable": settings.preferred_executable_name or None,
        "kind": settings.preferred_process_kind or None,
        "autoConnect": settings.auto_connect,
    }
    if selected is None:
        return {"preferredProcess": identity, "connected": False,
                "detectedCandidates": len(candidates)}
    if not monitor.select(selected.pid):
        return {"preferredProcess": identity, "connected": False,
                "detectedCandidates": len(candidates)}
    sample = monitor.sample()
    sample["matchedBySavedIdentity"] = True
    return {"preferredProcess": identity, **sample}


def main(argv: Optional[list[str]] = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "bridge":
            print(json.dumps(run_bridge_command(args), ensure_ascii=True, indent=2))
            return 0
        saved_process = sample_saved_process(args.app_settings)
        if args.command == "process":
            print(json.dumps(saved_process, ensure_ascii=True, indent=2))
            return 0
        snapshot = read_snapshot(args.snapshot)
        process = saved_process if (saved_process.get("connected")
                                    or (saved_process.get("preferredProcess") or {}).get("configured")) \
            else read_process_report(args.process_report)
        config = read_capture_config(args.config)
        if args.command == "status":
            state, message = runtime_application_state(
                config, snapshot, config_path=args.config, process=process)
            output: Any = {"state": state, "message": message,
                           "runtime": snapshot.get("runtime"),
                           "capture": capture_manifest(snapshot), "snapshot": str(args.snapshot),
                           "preferredProcess": saved_process.get("preferredProcess"),
                           "process": process}
        elif args.command == "list-sections":
            output = capture_manifest(snapshot)
        elif args.command == "list-npcs":
            output = {"npcs": [{key: row.get(key) for key in
                                ("id", "name", "faction", "presence", "inventoryItems")}
                               for row in npc_rows(snapshot)]}
        else:
            sections = tuple(dict.fromkeys(item.strip().lower()
                                           for item in args.sections.split(",") if item.strip()))
            unknown = set(sections) - {"performance", "moddata", "npc"}
            if unknown:
                raise ValueError("unknown sections: " + ", ".join(sorted(unknown)))
            views = tuple(item.strip().lower() for item in args.npc_view.split(",") if item.strip())
            output = build_summary(process, snapshot, sections, args.npc, views, args.top,
                                   args.min_ms, args.token_budget)
        encoded = render_text(output) if args.command == "summarize" and args.format == "text" \
            else json.dumps(output, ensure_ascii=True, indent=2)
        if getattr(args, "output", None):
            args.output.write_text(encoded + "\n", encoding="utf-8")
        else:
            print(encoded)
        return 0
    except ValueError as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
