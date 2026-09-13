from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from ..persistence.database import SettingsDatabase


class EventLogger:
    """Writes the same structured event to a file, SQLite, and an optional UI callback."""

    def __init__(self, database: SettingsDatabase, log_dir: Path, callback: Callable[[dict[str, Any]], None] | None = None):
        self.database = database
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.callback = callback
        self._lock = threading.Lock()

    def emit(self, level: str, operation: str, message: str, **details: Any) -> dict[str, Any]:
        event = {
            "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "level": level.upper(),
            "operation": operation,
            "message": message,
            "details": details,
        }
        day_log = self.log_dir / f"steam-uploader-{datetime.now().strftime('%Y-%m-%d')}.jsonl"
        line = json.dumps(event, ensure_ascii=False, default=str)
        with self._lock:
            with day_log.open("a", encoding="utf-8") as stream:
                stream.write(line + "\n")
            self.database.record_event(event["level"], operation, message, details)
        if self.callback:
            self.callback(event)
        return event
