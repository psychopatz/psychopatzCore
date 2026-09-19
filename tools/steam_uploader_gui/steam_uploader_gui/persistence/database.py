from __future__ import annotations

import json
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from ..core.models import ModProfile


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class SettingsDatabase:
    """Small SQLite store for settings, mod profiles, and searchable audit events."""

    def __init__(self, path: Path):
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._connection = sqlite3.connect(self.path, check_same_thread=False)
        self._connection.row_factory = sqlite3.Row
        self._connection.execute("PRAGMA journal_mode=WAL")
        self._create_schema()

    def _create_schema(self) -> None:
        with self._lock, self._connection:
            self._connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS profiles (
                    key TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    mod_root TEXT NOT NULL,
                    appid INTEGER NOT NULL,
                    workshopid INTEGER,
                    content_path TEXT,
                    preview_path TEXT,
                    title TEXT NOT NULL,
                    description TEXT NOT NULL,
                    visibility INTEGER NOT NULL,
                    tags_json TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    created_at TEXT NOT NULL,
                    level TEXT NOT NULL,
                    operation TEXT NOT NULL,
                    message TEXT NOT NULL,
                    details_json TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS workshop_sync (
                    profile_key TEXT PRIMARY KEY,
                    steam_json TEXT NOT NULL,
                    local_json TEXT NOT NULL,
                    synced_at TEXT NOT NULL
                );
                """
            )

    def get_setting(self, key: str, default: str = "") -> str:
        with self._lock:
            row = self._connection.execute("SELECT value FROM settings WHERE key = ?", (key,)).fetchone()
        return str(row["value"]) if row else default

    def set_setting(self, key: str, value: str) -> None:
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO settings(key, value) VALUES(?, ?) "
                "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                (key, value),
            )

    def save_profile(self, profile: ModProfile) -> None:
        values = profile.as_dict()
        with self._lock, self._connection:
            self._connection.execute(
                """
                INSERT INTO profiles(
                    key, name, mod_root, appid, workshopid, content_path, preview_path,
                    title, description, visibility, tags_json, updated_at
                ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    name=excluded.name, mod_root=excluded.mod_root, appid=excluded.appid,
                    workshopid=excluded.workshopid, content_path=excluded.content_path,
                    preview_path=excluded.preview_path, title=excluded.title,
                    description=excluded.description, visibility=excluded.visibility,
                    tags_json=excluded.tags_json, updated_at=excluded.updated_at
                """,
                (
                    values["key"], values["name"], values["mod_root"], values["appid"],
                    values["workshopid"], values["content_path"], values["preview_path"],
                    values["title"], values["description"], values["visibility"],
                    json.dumps(values["tags"], ensure_ascii=False), _now(),
                ),
            )

    def load_profile(self, key: str) -> ModProfile | None:
        with self._lock:
            row = self._connection.execute("SELECT * FROM profiles WHERE key = ?", (key,)).fetchone()
        if not row:
            return None
        return self._profile_from_row(row)

    def load_profiles(self) -> dict[str, ModProfile]:
        """Load cached profiles for identity recovery during a fresh disk scan."""

        with self._lock:
            rows = self._connection.execute("SELECT * FROM profiles").fetchall()
        return {str(row["key"]): self._profile_from_row(row) for row in rows}

    @staticmethod
    def _profile_from_row(row: sqlite3.Row) -> ModProfile:
        return ModProfile(
            key=row["key"], name=row["name"], mod_root=Path(row["mod_root"]), appid=row["appid"],
            workshopid=row["workshopid"], content_path=Path(row["content_path"]) if row["content_path"] else None,
            preview_path=Path(row["preview_path"]) if row["preview_path"] else None,
            title=row["title"], description=row["description"], visibility=row["visibility"],
            tags=json.loads(row["tags_json"] or "[]"),
        )

    def record_event(self, level: str, operation: str, message: str, details: dict[str, Any] | None = None) -> None:
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO events(created_at, level, operation, message, details_json) VALUES(?, ?, ?, ?, ?)",
                (_now(), level, operation, message, json.dumps(details or {}, ensure_ascii=False, default=str)),
            )

    def load_workshop_sync(self, profile_key: str) -> dict[str, Any] | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT steam_json, local_json, synced_at FROM workshop_sync WHERE profile_key = ?",
                (profile_key,),
            ).fetchone()
        if not row:
            return None
        return {
            "steam": json.loads(row["steam_json"] or "{}"),
            "local": json.loads(row["local_json"] or "{}"),
            "synced_at": row["synced_at"],
        }

    def save_workshop_sync(
        self,
        profile_key: str,
        steam: dict[str, Any],
        local: dict[str, Any],
    ) -> None:
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO workshop_sync(profile_key, steam_json, local_json, synced_at) "
                "VALUES(?, ?, ?, ?) "
                "ON CONFLICT(profile_key) DO UPDATE SET "
                "steam_json = excluded.steam_json, local_json = excluded.local_json, "
                "synced_at = excluded.synced_at",
                (
                    profile_key,
                    json.dumps(steam, ensure_ascii=False),
                    json.dumps(local, ensure_ascii=False),
                    _now(),
                ),
            )

    def close(self) -> None:
        with self._lock:
            self._connection.close()
