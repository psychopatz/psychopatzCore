from __future__ import annotations

import os
import sys
from pathlib import Path


APP_NAME = "SteamUploaderGUI"
DEFAULT_APPID = 108600
SETTING_WORKSHOP_ROOT = "workshop_root"
SETTING_UPLOADER_PATH = "uploader_path"
SETTING_IDENTIFIER_EDITING = "identifier_editing"
SETTING_DARK_MODE = "dark_mode"


def default_workshop_root() -> Path:
    """Return the conventional Project Zomboid Workshop folder for this OS."""

    return Path.home() / "Zomboid" / "Workshop"


def config_dir() -> Path:
    if sys.platform == "win32":
        return Path(os.environ.get("APPDATA", Path.home())) / APP_NAME
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / APP_NAME
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / APP_NAME


def data_dir() -> Path:
    if sys.platform == "win32":
        return Path(os.environ.get("LOCALAPPDATA", Path.home())) / APP_NAME
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / APP_NAME
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / APP_NAME


def default_database_path() -> Path:
    return data_dir() / "settings.sqlite3"


def default_log_dir() -> Path:
    return data_dir() / "logs"


def uploader_candidates() -> list[Path]:
    names = ["SteamUploader.exe", "SteamUploader"] if sys.platform == "win32" else ["SteamUploader"]
    roots = [
        Path.home() / "Desktop" / "Projects" / "SteamUploader",
        Path.home() / "Projects" / "SteamUploader",
        Path.home() / "SteamUploader",
    ]
    return [root / name for root in roots for name in names]


def first_existing_uploader() -> Path | None:
    return next((candidate for candidate in uploader_candidates() if candidate.is_file()), None)
