"""Small shared settings store for GUI and headless profiler clients."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import json
import os
from pathlib import Path
from typing import Any, Iterable, Optional


APP_SETTINGS_FILENAME = "PsychopatzCore_ProfilerApp.json"
VALID_INTERVALS = (0.5, 1.0, 2.0, 5.0)


def default_app_settings_path() -> Path:
    return Path.home() / "Zomboid" / "Lua" / APP_SETTINGS_FILENAME


def _bounded(value: Any, maximum: int) -> str:
    return str(value or "").strip()[:maximum]


@dataclass(frozen=True)
class AppSettings:
    preferred_process_name: str = ""
    preferred_executable_name: str = ""
    preferred_process_kind: str = ""
    auto_connect: bool = True
    poll_interval: float = 1.0
    selected_tab: str = "Performance"
    version: int = 1

    @property
    def has_preferred_process(self) -> bool:
        return bool(self.preferred_process_name)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def parse_app_settings(value: Any) -> AppSettings:
    if not isinstance(value, dict):
        return AppSettings()
    try:
        interval = float(value.get("poll_interval", 1.0))
    except (TypeError, ValueError):
        interval = 1.0
    interval = min(VALID_INTERVALS, key=lambda candidate: abs(candidate - interval))
    return AppSettings(
        preferred_process_name=_bounded(value.get("preferred_process_name"), 128),
        preferred_executable_name=_bounded(value.get("preferred_executable_name"), 128),
        preferred_process_kind=_bounded(value.get("preferred_process_kind"), 32),
        auto_connect=value.get("auto_connect", True) is not False,
        poll_interval=interval,
        selected_tab=_bounded(value.get("selected_tab") or "Performance", 64),
    )


def read_app_settings(path: Path | None = None) -> AppSettings:
    target = Path(path) if path else default_app_settings_path()
    try:
        return parse_app_settings(json.loads(target.read_text(encoding="utf-8")))
    except (FileNotFoundError, PermissionError, OSError, UnicodeError, json.JSONDecodeError):
        return AppSettings()


def write_app_settings(settings: AppSettings, path: Path | None = None) -> Path:
    target = Path(path) if path else default_app_settings_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(f"{target.name}.{os.getpid()}.tmp")
    temporary.write_text(json.dumps(settings.to_dict(), ensure_ascii=True,
                                    separators=(",", ":")), encoding="utf-8")
    temporary.replace(target)
    return target


def settings_for_candidate(candidate: Any, current: AppSettings) -> AppSettings:
    executable = Path(str(getattr(candidate, "executable", "") or "")).name
    return AppSettings(
        preferred_process_name=_bounded(getattr(candidate, "name", ""), 128),
        preferred_executable_name=_bounded(executable, 128),
        preferred_process_kind=_bounded(getattr(candidate, "kind", ""), 32),
        auto_connect=current.auto_connect, poll_interval=current.poll_interval,
        selected_tab=current.selected_tab,
    )


def _normalized(value: str) -> str:
    return "".join(character for character in value.casefold() if character.isalnum())


def select_preferred_candidate(candidates: Iterable[Any], settings: AppSettings) -> Optional[Any]:
    """Match a stable saved identity; never persist or compare a PID."""
    if not settings.has_preferred_process:
        return None
    preferred_name = settings.preferred_process_name.casefold()
    preferred_normalized = _normalized(settings.preferred_process_name)
    ranked = []
    for candidate in candidates:
        name = str(getattr(candidate, "name", ""))
        executable = Path(str(getattr(candidate, "executable", "") or "")).name
        score = 0
        if name.casefold() == preferred_name:
            score += 100
        elif _normalized(name) == preferred_normalized:
            score += 70
        else:
            continue
        if settings.preferred_executable_name and \
                executable.casefold() == settings.preferred_executable_name.casefold():
            score += 30
        if settings.preferred_process_kind and \
                str(getattr(candidate, "kind", "")).casefold() == settings.preferred_process_kind.casefold():
            score += 10
        score += min(20, int(getattr(candidate, "score", 0) or 0) // 10)
        # PID is only a final live tie-breaker (newer instances usually have a
        # higher PID); it is never written to settings.
        ranked.append((score, int(getattr(candidate, "pid", 0) or 0), candidate))
    return max(ranked, key=lambda item: (item[0], item[1]))[2] if ranked else None
