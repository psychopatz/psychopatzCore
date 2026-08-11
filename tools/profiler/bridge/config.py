"""Independent startup configuration for the Psychopatz bridge."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


BRIDGE_CONFIG_FILENAME = "PsychopatzCore_Bridge.txt"


def default_bridge_config_path() -> Path:
    return Path.home() / "Zomboid" / "Lua" / BRIDGE_CONFIG_FILENAME


@dataclass(frozen=True)
class BridgeConfig:
    enabled: bool = False
    transport: str = "file"
    poll_interval_ms: int = 250
    version: int = 1

    @property
    def fingerprint(self) -> str:
        return f"v{self.version}|{str(self.enabled).lower()}|{self.transport}|{self.poll_interval_ms}"

    def serialize(self) -> str:
        return (f"config_version={self.version}\n"
                f"bridge_enabled={str(self.enabled).lower()}\n"
                f"bridge_transport={self.transport}\n"
                f"bridge_poll_interval_ms={self.poll_interval_ms}\n")


def parse_bridge_config(text: str) -> BridgeConfig:
    values: dict[str, str] = {}
    for line in text.splitlines():
        content = line.split("#", 1)[0].split(";", 1)[0].strip()
        key, separator, value = content.partition("=")
        if separator:
            values[key.strip().lower()] = value.strip()
    enabled = values.get("bridge_enabled", "false").casefold() in {"1", "true", "yes", "on"}
    transport = values.get("bridge_transport", "file").casefold()
    if transport != "file":
        transport = "file"
    try:
        interval = int(values.get("bridge_poll_interval_ms", "250"))
    except ValueError:
        interval = 250
    return BridgeConfig(enabled=enabled, transport=transport,
                        poll_interval_ms=max(100, min(5000, interval)))


def read_bridge_config(path: Path | None = None) -> BridgeConfig:
    target = Path(path) if path else default_bridge_config_path()
    try:
        return parse_bridge_config(target.read_text(encoding="utf-8"))
    except (FileNotFoundError, PermissionError, OSError, UnicodeError):
        return BridgeConfig()


def write_bridge_config(config: BridgeConfig, path: Path | None = None) -> Path:
    target = Path(path) if path else default_bridge_config_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".tmp")
    temporary.write_text(config.serialize(), encoding="utf-8")
    temporary.replace(target)
    return target
