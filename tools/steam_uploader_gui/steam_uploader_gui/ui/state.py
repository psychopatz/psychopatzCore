from __future__ import annotations

import json
from typing import Any

from ..persistence.database import SettingsDatabase


class UIStateStore:
    """Namespaced UI preferences stored through the existing SQLite settings table."""

    _PREFIX = "ui."

    def __init__(self, database: SettingsDatabase) -> None:
        self.database = database

    def get(self, key: str, default: str = "") -> str:
        return self.database.get_setting(f"{self._PREFIX}{key}", default)

    def set(self, key: str, value: str) -> None:
        self.database.set_setting(f"{self._PREFIX}{key}", value)

    def get_bool(self, key: str, default: bool = False) -> bool:
        value = self.get(key, "1" if default else "0").strip().lower()
        return value in {"1", "true", "yes", "on"}

    def set_bool(self, key: str, value: bool) -> None:
        self.set(key, "1" if value else "0")

    def get_json(self, key: str, default: Any) -> Any:
        raw = self.get(key)
        if not raw:
            return default
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return default

    def set_json(self, key: str, value: Any) -> None:
        self.set(key, json.dumps(value, ensure_ascii=False))

    @staticmethod
    def profile_scope(profile_key: str) -> str:
        return f"profile/{profile_key}"
