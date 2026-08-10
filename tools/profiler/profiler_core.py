"""Platform-neutral data layer for the Psychopatz performance profiler."""

from __future__ import annotations

import csv
import json
import os
import time
from collections import deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping, Optional

try:
    import psutil as _psutil
except ImportError:  # The GUI turns this into a concise installation message.
    _psutil = None


SNAPSHOT_VERSION = 1
SNAPSHOT_FILENAME = "PsychopatzCore_Profiler_latest.json"
GAME_CONFIG_FILENAME = "PsychopatzCore_Profiler.txt"
LLM_REPORT_FILENAME = "PsychopatzCore_Profiler_LLM_latest.json"


def default_game_config_path() -> Path:
    return Path.home() / "Zomboid" / "Lua" / GAME_CONFIG_FILENAME


def read_game_profiler_mode(path: Optional[Path] = None) -> str:
    config = Path(path) if path else default_game_config_path()
    try:
        for line in config.read_text(encoding="utf-8").splitlines():
            key, separator, value = line.partition("=")
            if separator and key.strip().lower() == "mode":
                mode = value.split("#", 1)[0].split(";", 1)[0].strip().upper()
                return mode if mode in ("BASIC", "DETAILED") else "OFF"
    except (FileNotFoundError, PermissionError, OSError, UnicodeError):
        pass
    return "OFF"


def write_game_profiler_mode(mode: str, path: Optional[Path] = None) -> Path:
    normalized = str(mode).strip().upper()
    if normalized not in ("OFF", "BASIC", "DETAILED"):
        raise ValueError(f"unsupported profiler mode: {mode}")
    config = Path(path) if path else default_game_config_path()
    config.parent.mkdir(parents=True, exist_ok=True)
    config.write_text(f"mode={normalized}\n", encoding="utf-8")
    return config


def default_llm_report_path() -> Path:
    return Path.home() / "Zomboid" / "Lua" / LLM_REPORT_FILENAME


def build_llm_report(process: Mapping[str, Any], snapshot: Optional[Mapping[str, Any]]) -> dict[str, Any]:
    """Build a bounded, value-redacted report intended for automated analysis."""
    snapshot = snapshot or {}
    namespace = (snapshot.get("namespaces") or {}).get("ProjectHoomans") or {}
    timers = []
    for name, metric in (namespace.get("timers") or {}).items():
        if not isinstance(metric, Mapping):
            continue
        timers.append({
            "name": str(name),
            "msPerSec": metric.get("msPerSec", 0),
            "callsPerSec": metric.get("callsPerSec", 0),
            "movingAverageMs": metric.get("movingAverageMs", 0),
            "peakMs": metric.get("peakMs", 0),
        })
    timers.sort(key=lambda item: float(item.get("msPerSec") or 0), reverse=True)
    gauges = []
    for name, metric in (namespace.get("gauges") or {}).items():
        value = metric.get("value", 0) if isinstance(metric, Mapping) else metric
        gauges.append({"name": str(name), "value": value})
    gauges.sort(key=lambda item: item["name"])
    diagnostics = snapshot.get("diagnostics") or {}
    raw_mod_data = diagnostics.get("ProjectHoomans.modData") if isinstance(diagnostics, Mapping) else None
    mod_data = None
    if isinstance(raw_mod_data, Mapping):
        # Per-NPC contents are intentionally local-GUI-only; keep automated
        # reports compact and value-redacted.
        allowed = ("reportVersion", "capturedAtMs", "scanMs", "estimateMethod",
                   "valuesRedacted", "limits", "persisted", "runtimeRecords", "inventories")
        mod_data = {key: raw_mod_data.get(key) for key in allowed if key in raw_mod_data}
    return {
        "reportVersion": 1,
        "purpose": "compact ProjectHoomans performance and ModData analysis",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "snapshot": {
            "timestamp": snapshot.get("timestamp"),
            "mode": snapshot.get("mode"),
            "source": snapshot.get("source"),
        },
        "process": {key: process.get(key) for key in
                    ("connected", "pid", "name", "rss", "vms", "cpu_percent", "threads", "uptime")},
        "projectHoomans": {"topTimers": timers[:20], "gauges": gauges[:40]},
        "modData": mod_data,
        "warnings": list(snapshot.get("warnings") or [])[:30],
        "interpretation": [
            "Process RSS belongs to the whole Project Zomboid process, not one mod.",
            "ModData byte counts are bounded shape estimates, not exact JVM or save-file sizes.",
            "Persisted, runtimeRecords, and inventories overlap and must not be summed.",
            "Raw values and dynamic identifiers are intentionally excluded.",
        ],
    }


def write_llm_report(report: Mapping[str, Any], path: Optional[Path] = None) -> Path:
    target = Path(path) if path else default_llm_report_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".tmp")
    temporary.write_text(json.dumps(report, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")
    temporary.replace(target)
    return target


@dataclass(frozen=True)
class ProcessCandidate:
    pid: int
    name: str
    executable: str
    command: str
    score: int
    kind: str

    @property
    def label(self) -> str:
        summary = self.command.replace("\n", " ").strip()
        suffix = f" — {summary[:90]}" if summary else ""
        return f"{self.pid} — {self.name} ({self.kind}){suffix}"


def _safe_text(value: Any) -> str:
    return str(value or "")


def score_process(info: Mapping[str, Any]) -> tuple[int, str]:
    """Score PZ clients/servers without ever matching generic Java alone."""
    name = _safe_text(info.get("name")).lower()
    executable = _safe_text(info.get("exe")).lower()
    command_parts = info.get("cmdline") or []
    command = " ".join(_safe_text(part) for part in command_parts).lower()
    combined = " ".join((name, executable, command))
    score = 0
    strong_names = ("projectzomboid", "projectzomboid64", "project zomboid")
    if any(token in name or token in executable for token in strong_names):
        score += 80
    # Match runtime entry points, not arbitrary paths containing "Zomboid".
    # Otherwise a file manager browsing ~/Zomboid/Workshop is a false positive.
    runtime_signals = (
        "projectzomboid64", "projectzomboid32", "projectzomboid.sh",
        "zombie.gamewindow", "zombie.gamestates.", "zombie.network.gameserver",
        "zomboid.gamewindow", "zomboid.gamestates.", "zomboid.network.gameserver",
    )
    has_runtime_signal = any(token in command for token in runtime_signals) \
        or any(_safe_text(part).lower() == "zomboid" for part in command_parts)
    if has_runtime_signal:
        score += 45
    dedicated = any(token in combined for token in ("dedicated", "pzserver", "server64"))
    if dedicated:
        score += 10
    # A Java process is only eligible if a separate PZ signal was found.
    if name in ("java", "java.exe", "javaw.exe") \
            and not has_runtime_signal:
        return 0, "unknown"
    return score, "dedicated server" if dedicated else "client"


class ProcessMonitor:
    def __init__(self, psutil_module: Any = None) -> None:
        self.psutil = psutil_module or _psutil
        self.process: Any = None
        self.pid: Optional[int] = None

    def discover(self) -> list[ProcessCandidate]:
        if self.psutil is None:
            return []
        candidates: list[ProcessCandidate] = []
        attrs = ["pid", "name", "exe", "cmdline"]
        for process in self.psutil.process_iter(attrs):
            try:
                info = process.info
                score, kind = score_process(info)
                if score < 45:
                    continue
                command = " ".join(_safe_text(value) for value in info.get("cmdline") or [])
                candidates.append(ProcessCandidate(
                    pid=int(info["pid"]),
                    name=_safe_text(info.get("name")) or "Unknown",
                    executable=_safe_text(info.get("exe")),
                    command=command[:240],
                    score=score,
                    kind=kind,
                ))
            except self._process_exceptions():
                continue
        candidates.sort(key=lambda item: (-item.score, item.pid))
        return candidates

    def _process_exceptions(self) -> tuple[type[BaseException], ...]:
        if self.psutil is None:
            return (Exception,)
        return tuple(filter(None, (
            getattr(self.psutil, "NoSuchProcess", None),
            getattr(self.psutil, "AccessDenied", None),
            getattr(self.psutil, "ZombieProcess", None),
        ))) or (Exception,)

    def select(self, pid: int) -> bool:
        if self.psutil is None:
            return False
        try:
            process = self.psutil.Process(int(pid))
            process.cpu_percent(None)
            self.process, self.pid = process, int(pid)
            return True
        except (ValueError,) + self._process_exceptions():
            self.disconnect()
            return False

    def disconnect(self) -> None:
        self.process, self.pid = None, None

    def sample(self) -> dict[str, Any]:
        if self.process is None:
            return {"connected": False, "pid": self.pid}
        try:
            memory = self.process.memory_info()
            created = float(self.process.create_time())
            return {
                "connected": True,
                "pid": self.process.pid,
                "name": self.process.name(),
                "rss": getattr(memory, "rss", None),
                "vms": getattr(memory, "vms", None),
                "cpu_percent": self.process.cpu_percent(None),
                "threads": self.process.num_threads(),
                "uptime": max(0.0, time.time() - created),
            }
        except self._process_exceptions():
            old_pid = self.pid
            self.disconnect()
            return {"connected": False, "pid": old_pid}

    def system_sample(self) -> dict[str, Any]:
        if self.psutil is None:
            return {}
        try:
            memory = self.psutil.virtual_memory()
            return {
                "system_total_ram": getattr(memory, "total", None),
                "system_available_ram": getattr(memory, "available", None),
                "system_cpu_percent": self.psutil.cpu_percent(None),
            }
        except Exception:
            return {}


def default_snapshot_paths() -> list[Path]:
    home = Path.home()
    roots = [Path.cwd(), home / "Zomboid" / "Lua", home / "Zomboid"]
    for variable in ("APPDATA", "LOCALAPPDATA"):
        raw = os.environ.get(variable)
        if raw:
            roots.extend((Path(raw) / "Zomboid" / "Lua", Path(raw) / "Zomboid"))
    roots.append(home / "Library" / "Zomboid" / "Lua")
    seen: set[Path] = set()
    paths: list[Path] = []
    for root in roots:
        path = root / SNAPSHOT_FILENAME
        if path not in seen:
            seen.add(path)
            paths.append(path)
    return paths


class SnapshotReader:
    def __init__(self, path: Optional[Path] = None, stale_after: float = 5.0) -> None:
        self.path = Path(path).expanduser() if path else None
        self.stale_after = stale_after
        self.last_valid: Optional[dict[str, Any]] = None
        self.status = "snapshot not found"
        self.last_mtime: Optional[float] = None

    def resolve_path(self) -> Optional[Path]:
        if self.path:
            return self.path
        for candidate in default_snapshot_paths():
            if candidate.is_file():
                self.path = candidate
                return candidate
        return None

    def read(self) -> Optional[dict[str, Any]]:
        path = self.resolve_path()
        if path is None:
            self.status = "snapshot not found"
            return self.last_valid
        try:
            stat = path.stat()
            raw = path.read_text(encoding="utf-8")
            parsed = json.loads(raw)
            if not isinstance(parsed, dict):
                raise ValueError("snapshot root is not an object")
            if parsed.get("profilerVersion") != SNAPSHOT_VERSION:
                self.status = f"unsupported snapshot version: {parsed.get('profilerVersion')}"
                return self.last_valid
            self.last_valid = parsed
            self.last_mtime = stat.st_mtime
            age = max(0.0, time.time() - stat.st_mtime)
            self.status = "stale snapshot" if age > self.stale_after else "snapshot connected"
        except FileNotFoundError:
            self.status = "snapshot missing"
        except PermissionError:
            self.status = "snapshot permission denied"
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError):
            self.status = "snapshot temporarily invalid; showing last valid data"
        return self.last_valid


class HistoryStore:
    def __init__(self, capacity: int = 300) -> None:
        self.capacity = max(2, int(capacity))
        self.series: dict[str, deque[tuple[float, float]]] = {}
        self.markers: deque[tuple[float, str]] = deque(maxlen=self.capacity)

    def add(self, name: str, timestamp: float, value: Any) -> None:
        try:
            numeric = float(value)
        except (TypeError, ValueError):
            return
        self.series.setdefault(name, deque(maxlen=self.capacity)).append((timestamp, numeric))

    def add_marker(self, timestamp: float, text: str) -> None:
        self.markers.append((timestamp, str(text).strip()[:240]))


class CsvRecorder:
    FIELDS = ("timestamp", "row_type", "pid", "namespace", "metric", "kind", "value", "marker")

    def __init__(self, max_bytes: int = 100 * 1024 * 1024) -> None:
        self.max_bytes = max(1024, int(max_bytes))
        self.active = False
        self.directory: Optional[Path] = None
        self.stem = ""
        self.index = 0
        self.path: Optional[Path] = None
        self._file: Any = None
        self._writer: Any = None

    def start(self, directory: Path) -> Path:
        self.stop()
        self.directory = Path(directory).expanduser()
        self.directory.mkdir(parents=True, exist_ok=True)
        self.stem = "psychopatz-profiler-" + datetime.now().strftime("%Y%m%d-%H%M%S")
        self.index = 0
        self.active = True
        self._open_next()
        return self.path  # type: ignore[return-value]

    def _open_next(self) -> None:
        if self._file:
            self._file.close()
        suffix = "" if self.index == 0 else f"-{self.index:03d}"
        self.path = self.directory / f"{self.stem}{suffix}.profiler.csv"  # type: ignore[operator]
        self._file = self.path.open("w", encoding="utf-8", newline="")
        self._writer = csv.DictWriter(self._file, fieldnames=self.FIELDS)
        self._writer.writeheader()
        self._file.flush()

    def _rotate_if_needed(self) -> None:
        if self._file and self._file.tell() >= self.max_bytes:
            self.index += 1
            self._open_next()

    def write_rows(self, rows: Iterable[Mapping[str, Any]]) -> None:
        if not self.active or not self._writer:
            return
        for row in rows:
            self._writer.writerow({field: row.get(field, "") for field in self.FIELDS})
        self._file.flush()
        self._rotate_if_needed()

    def marker(self, timestamp: float, pid: Any, text: str) -> None:
        self.write_rows(({"timestamp": timestamp, "row_type": "marker", "pid": pid or "", "marker": text},))

    def stop(self) -> None:
        if self._file:
            self._file.close()
        self._file, self._writer = None, None
        self.active = False


def iter_snapshot_metrics(snapshot: Optional[Mapping[str, Any]]) -> Iterable[tuple[str, str, str, float]]:
    if not snapshot:
        return
    for namespace, data in (snapshot.get("namespaces") or {}).items():
        for kind in ("timers", "counters", "gauges", "rates"):
            for name, metric in (data.get(kind) or {}).items():
                if isinstance(metric, Mapping):
                    key = "msPerSec" if kind == "timers" else "perSec" if kind == "rates" else "value"
                    value = metric.get(key, 0)
                else:
                    value = metric
                try:
                    yield str(namespace), str(name), kind[:-1], float(value)
                except (TypeError, ValueError):
                    continue


class ProfilerModel:
    def __init__(self, history_capacity: int = 300) -> None:
        self.history = HistoryStore(history_capacity)
        self.recorder = CsvRecorder()
        self.warnings: deque[str] = deque(maxlen=100)
        self.last_process: dict[str, Any] = {"connected": False}
        self.last_snapshot: Optional[dict[str, Any]] = None

    def update(self, process: Mapping[str, Any], snapshot: Optional[dict[str, Any]]) -> None:
        now = time.time()
        self.last_process = dict(process)
        self.last_snapshot = snapshot
        for key in ("rss", "cpu_percent", "threads"):
            self.history.add(f"process.{key}", now, process.get(key))
        rows: list[dict[str, Any]] = []
        pid = process.get("pid", "")
        for key in ("rss", "cpu_percent", "threads"):
            value = process.get(key)
            if value is not None:
                rows.append({"timestamp": now, "row_type": "metric", "pid": pid,
                             "namespace": "PROJECT ZOMBOID PROCESS", "metric": key,
                             "kind": "process", "value": value})
        for namespace, metric, kind, value in iter_snapshot_metrics(snapshot):
            self.history.add(f"{namespace}.{metric}", now, value)
            rows.append({"timestamp": now, "row_type": "metric", "pid": pid,
                         "namespace": namespace, "metric": metric, "kind": kind, "value": value})
        self.recorder.write_rows(rows)
        self._update_warnings()

    def _update_warnings(self) -> None:
        rss = self.history.series.get("process.rss")
        if rss and len(rss) >= min(60, self.history.capacity):
            values = [value for _, value in rss]
            rises = sum(1 for left, right in zip(values, values[1:]) if right >= left)
            if rises >= int((len(values) - 1) * 0.9) and values[-1] - values[0] > 256 * 1024 * 1024:
                self._warn("Possible continuous process memory growth")
        threads = self.history.series.get("process.threads")
        if threads and len(threads) >= 30 and threads[-1][1] - threads[0][1] >= 10:
            self._warn("Possible thread growth")

    def _warn(self, message: str) -> None:
        if not self.warnings or self.warnings[-1] != message:
            self.warnings.append(message)

    def add_marker(self, text: str) -> None:
        now = time.time()
        cleaned = str(text).strip()
        if not cleaned:
            return
        self.history.add_marker(now, cleaned)
        self.recorder.marker(now, self.last_process.get("pid"), cleaned)
