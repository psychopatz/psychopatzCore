"""Shared profiler capture configuration used by the GUI and headless tools."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import time
from typing import Iterable, Optional


VALID_MODES = ("OFF", "BASIC", "DETAILED")
VALID_SECTIONS = ("performance", "moddata", "npc")


def _csv(values: Iterable[str]) -> str:
    return ",".join(value for value in VALID_SECTIONS if value in set(values))


@dataclass(frozen=True)
class CaptureConfig:
    mode: str = "OFF"
    sections: tuple[str, ...] = ("performance",)
    performance_interval_ms: int = 1000
    moddata_interval_ms: int = 60000
    npc_interval_ms: int = 5000
    npc_scope: str = "selected"
    npc_ids: tuple[str, ...] = ()
    version: int = 2

    def enabled(self, section: str) -> bool:
        return self.mode != "OFF" and section in self.sections

    @property
    def fingerprint(self) -> str:
        ids = ",".join(sorted(set(self.npc_ids)))
        return "|".join((
            f"v{self.version}", self.mode, _csv(self.sections),
            str(self.performance_interval_ms), str(self.moddata_interval_ms),
            str(self.npc_interval_ms), self.npc_scope, ids,
        ))

    def serialize(self) -> str:
        return "\n".join((
            f"config_version={self.version}",
            f"mode={self.mode}",
            f"capture={_csv(self.sections)}",
            f"performance_interval_ms={self.performance_interval_ms}",
            f"moddata_interval_ms={self.moddata_interval_ms}",
            f"npc_interval_ms={self.npc_interval_ms}",
            f"npc_scope={self.npc_scope}",
            f"npc_ids={','.join(self.npc_ids)}",
            "",
        ))


def _bounded_int(value: object, default: int, minimum: int, maximum: int) -> int:
    try:
        return max(minimum, min(maximum, int(str(value))))
    except (TypeError, ValueError):
        return default


def parse_capture_config(text: str) -> CaptureConfig:
    values: dict[str, str] = {}
    for line in text.splitlines():
        content = line.split("#", 1)[0].split(";", 1)[0].strip()
        key, separator, value = content.partition("=")
        if separator:
            values[key.strip().lower()] = value.strip()
    mode = values.get("mode", "OFF").upper()
    if mode not in VALID_MODES:
        mode = "OFF"
    raw_sections = values.get("capture", "performance")
    requested = {item.strip().lower() for item in raw_sections.split(",")}
    sections = tuple(item for item in VALID_SECTIONS if item in requested)
    if mode != "OFF" and not sections:
        sections = ("performance",)
    scope = values.get("npc_scope", "selected").strip().lower()
    if scope not in ("selected", "all_bounded"):
        scope = "selected"
    npc_ids = tuple(dict.fromkeys(
        item.strip() for item in values.get("npc_ids", "").split(",") if item.strip()))
    return CaptureConfig(
        mode=mode,
        sections=sections,
        performance_interval_ms=_bounded_int(values.get("performance_interval_ms"), 1000, 250, 60000),
        moddata_interval_ms=_bounded_int(values.get("moddata_interval_ms"), 60000, 5000, 3600000),
        npc_interval_ms=_bounded_int(values.get("npc_interval_ms"), 5000, 1000, 300000),
        npc_scope=scope,
        npc_ids=npc_ids,
        version=_bounded_int(values.get("config_version"), 2, 2, 2),
    )


def read_capture_config(path: Path) -> CaptureConfig:
    try:
        return parse_capture_config(Path(path).read_text(encoding="utf-8"))
    except (FileNotFoundError, PermissionError, OSError, UnicodeError):
        return CaptureConfig()


def write_capture_config(config: CaptureConfig, path: Path) -> Path:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".tmp")
    temporary.write_text(config.serialize(), encoding="utf-8")
    temporary.replace(target)
    return target


def runtime_application_state(config: CaptureConfig, snapshot: Optional[dict], *,
                              config_path: Optional[Path] = None,
                              process: Optional[dict] = None) -> tuple[str, str]:
    """Return a stable state and concise GUI/CLI explanation."""
    if config.mode == "OFF":
        uptime = (process or {}).get("uptime")
        if config_path is not None and (process or {}).get("connected") and uptime is not None:
            try:
                configured_at = Path(config_path).stat().st_mtime
                process_started_at = time.time() - float(uptime)
                if process_started_at >= configured_at - 2.0:
                    return "applied_off", "APPLIED OFF — this game process started after profiling was disabled"
                return "restart_required", "RESTART REQUIRED — the running game predates the OFF configuration"
            except (OSError, TypeError, ValueError):
                pass
        return "configured_off", "Configured OFF — start or restart PZ for strict zero-overhead mode"
    runtime = (snapshot or {}).get("runtime") or {}
    runtime_id = str(runtime.get("id") or "")
    applied = str(runtime.get("configFingerprint") or "")
    if not runtime_id:
        return "unknown", "Waiting for a version-2 runtime snapshot"
    if applied != config.fingerprint:
        return "restart_required", f"RESTART REQUIRED — running {runtime_id[:16]} uses different capture settings"
    sections = ", ".join(config.sections) if config.mode != "OFF" else "none"
    return "applied", f"APPLIED by runtime {runtime_id[:16]} — capturing: {sections}"
