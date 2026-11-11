"""Bounded activity events shared by the GUI and command-line harness."""

from __future__ import annotations

from collections import deque
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
from threading import Lock
from typing import Any
import uuid

try:
    import fcntl
except ImportError:  # pragma: no cover - Windows has no fcntl.
    fcntl = None


MAX_SHARED_BYTES = 2_000_000


def default_activity_path(
    repository: Path,
    explicit: str | Path | None = None,
) -> Path:
    """Return the shared per-repository activity stream location."""

    if explicit:
        return Path(explicit).expanduser().resolve()
    state_root = Path(
        os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")
    )
    identity = str(repository.expanduser().resolve())
    digest = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:16]
    return state_root / "project-hoomans" / f"semantic-lab-{digest}.activity.jsonl"


class ActivityLog:
    """Thread-safe bounded history with an optional cross-process stream."""

    def __init__(
        self,
        capacity: int = 500,
        path: str | Path | None = None,
        client: str = "harness",
    ) -> None:
        self.capacity = max(32, int(capacity))
        self.path = Path(path).expanduser().resolve() if path else None
        self.client = str(client or "harness")
        self.session_id = uuid.uuid4().hex[:12]
        self._events: deque[dict[str, Any]] = deque(maxlen=self.capacity)
        self._sequence = 0
        self._lock = Lock()
        self._shared_read_lock = Lock()
        self._shared_read_offset: int | None = None
        self._shared_file_identity: tuple[int, int] | None = None
        self._shared_file_head: str | None = None

    def record(self, source: str, event: str, **details: Any) -> dict[str, Any]:
        with self._lock:
            self._sequence += 1
            record = {
                "sequence": self._sequence,
                "eventID": f"{self.session_id}-{self._sequence:06d}",
                "sessionID": self.session_id,
                "client": self.client,
                "timestamp": datetime.now().astimezone().isoformat(
                    timespec="milliseconds"
                ),
                "source": str(source),
                "event": str(event),
                "details": details,
            }
            self._events.append(record)
            self._append_shared(record)
            return dict(record)

    def snapshot(self, since: int = 0) -> list[dict[str, Any]]:
        with self._lock:
            return [
                dict(record)
                for record in self._events
                if int(record.get("sequence", 0)) > int(since)
            ]

    def shared_snapshot(self) -> list[dict[str, Any]]:
        """Read the bounded shared timeline, including other processes."""

        if self.path is None:
            return self.snapshot()
        try:
            records, _offset, _identity, _head = self._read_shared_records()
        except OSError:
            return self.snapshot()
        return records

    def new_shared_events(self, seen_event_ids: set[str]) -> list[dict[str, Any]]:
        """Return shared events without rescanning old records every poll."""

        if self.path is None:
            records = self.snapshot()
            return [
                record
                for record in records
                if str(record.get("eventID") or "") not in seen_event_ids
            ]

        with self._shared_read_lock:
            try:
                stat = self.path.stat()
                identity = (int(stat.st_dev), int(stat.st_ino))
                offset = self._shared_read_offset
                reset = (
                    offset is None
                    or identity != self._shared_file_identity
                    or int(stat.st_size) < offset
                )
                records, next_offset, next_identity, next_head = self._read_shared_records(
                    start_offset=None if reset else offset
                )
                self._shared_read_offset = next_offset
                self._shared_file_identity = next_identity
                self._shared_file_head = next_head
            except OSError:
                records = self.snapshot()

        return [
            record
            for record in records
            if str(record.get("eventID") or "") not in seen_event_ids
        ]

    def _read_shared_records(
        self, start_offset: int | None = None
    ) -> tuple[list[dict[str, Any]], int, tuple[int, int], str]:
        """Read bounded records and return the byte position for the next poll."""

        records: deque[dict[str, Any]] = deque(maxlen=self.capacity)
        with self.path.open("r", encoding="utf-8") as stream:  # type: ignore[union-attr]
            if fcntl is not None:
                fcntl.flock(stream.fileno(), fcntl.LOCK_SH)
            try:
                stat = os.fstat(stream.fileno())
                stream.seek(0)
                head = stream.readline()
                effective_offset = start_offset
                if effective_offset is not None and (
                    effective_offset > int(stat.st_size)
                    or (
                        self._shared_file_head is not None
                        and head != self._shared_file_head
                    )
                ):
                    effective_offset = None
                stream.seek(effective_offset if effective_offset is not None else 0)
                for line in stream:
                    try:
                        value = json.loads(line)
                    except (TypeError, ValueError):
                        continue
                    if isinstance(value, dict) and value.get("eventID"):
                        records.append(value)
                return (
                    [dict(record) for record in records],
                    stream.tell(),
                    (int(stat.st_dev), int(stat.st_ino)),
                    head,
                )
            finally:
                if fcntl is not None:
                    fcntl.flock(stream.fileno(), fcntl.LOCK_UN)

    @property
    def latest_sequence(self) -> int:
        with self._lock:
            return self._sequence

    def clear(self) -> None:
        with self._lock:
            self._events.clear()

    def _append_shared(self, record: dict[str, Any]) -> None:
        """Append one compact event without making logging a hard dependency."""

        if self.path is None:
            return
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            with self.path.open("a+", encoding="utf-8") as stream:
                if fcntl is not None:
                    fcntl.flock(stream.fileno(), fcntl.LOCK_EX)
                try:
                    stream.write(json.dumps(record, separators=(",", ":")) + "\n")
                    stream.flush()
                    if stream.tell() > MAX_SHARED_BYTES:
                        stream.seek(0)
                        retained = deque(
                            stream,
                            maxlen=max(self.capacity * 4, self.capacity),
                        )
                        stream.seek(0)
                        stream.truncate()
                        stream.writelines(retained)
                        stream.flush()
                finally:
                    if fcntl is not None:
                        fcntl.flock(stream.fileno(), fcntl.LOCK_UN)
        except (OSError, TypeError, ValueError):
            # Activity tracing must never break the worker or the UI.
            return


def format_activity_event(record: dict[str, Any]) -> str:
    """Render one event without dumping large request or scenario payloads."""

    timestamp = str(record.get("timestamp") or "")
    if "T" in timestamp:
        timestamp = timestamp.split("T", 1)[1]
    timestamp = timestamp.rsplit("+", 1)[0].rsplit("-", 1)[0]
    source = str(record.get("source") or "event").upper()
    event = str(record.get("event") or "activity")
    client = str(record.get("client") or "")
    session_id = str(record.get("sessionID") or "")
    details = record.get("details") or {}
    if not isinstance(details, dict):
        details = {"detail": details}
    parts: list[str] = []
    for key in (
        "operation",
        "command",
        "requestID",
        "controlID",
        "label",
        "speaker",
        "value",
        "replay",
        "durationMs",
        "pid",
        "message",
    ):
        value = details.get(key)
        if value is not None and value != "":
            rendered = str(value).replace("\n", " ")
            if len(rendered) > 180:
                rendered = rendered[:177] + "..."
            parts.append(f"{key}={rendered}")
    if client:
        parts.insert(0, f"client={client}")
    if session_id:
        parts.insert(1, f"session={session_id}")
    suffix = " · ".join(parts)
    return f"{timestamp}  {source:<8} {event:<16}" + (f" · {suffix}" if suffix else "")
