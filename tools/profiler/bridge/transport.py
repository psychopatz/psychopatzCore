"""Transport abstraction and bounded cross-platform filesystem transport."""

from __future__ import annotations

from abc import ABC, abstractmethod
import json
import os
from pathlib import Path
import time
from typing import Any, Optional

from .errors import BridgeBusyError, BridgeProtocolError
from .models import BridgeRequest, BridgeResponse

MAX_REQUEST_BYTES = 32 * 1024
MAX_RESPONSE_BYTES = 64 * 1024
SLOT_COUNT = 16
RETENTION_SECONDS = 15 * 60


class BridgeTransport(ABC):
    @abstractmethod
    def submit(self, request: BridgeRequest) -> int: ...

    @abstractmethod
    def read_response(self, slot: int, request_id: str) -> Optional[BridgeResponse]: ...

    @abstractmethod
    def read_runtime(self) -> Optional[dict[str, Any]]: ...

    @abstractmethod
    def release(self, slot: int) -> None: ...


class FileBridgeTransport(BridgeTransport):
    """Fixed slots prevent unbounded directory growth and scanning."""

    def __init__(self, root: Path | None = None) -> None:
        self.root = Path(root) if root else Path.home() / "Zomboid" / "Lua" / "PsychopatzBridge"
        self.requests = self.root / "requests"
        self.responses = self.root / "responses"
        self.state = self.root / "state"

    def ensure_directories(self) -> None:
        for directory in (self.requests, self.responses, self.state):
            directory.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _slot_name(slot: int) -> str:
        if slot < 0 or slot >= SLOT_COUNT:
            raise ValueError("bridge slot out of range")
        return f"slot-{slot:02d}"

    @staticmethod
    def _atomic_json(path: Path, value: Any, maximum: int) -> None:
        encoded = json.dumps(value, ensure_ascii=True, separators=(",", ":")).encode("utf-8")
        if len(encoded) > maximum:
            raise BridgeProtocolError(f"payload exceeds {maximum} bytes")
        temporary = path.with_name(path.name + f".{os.getpid()}.tmp")
        with temporary.open("wb") as handle:
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        temporary.replace(path)

    @staticmethod
    def _acquire_slot(path: Path, request_id: str) -> bool:
        try:
            descriptor = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            return False
        try:
            os.write(descriptor, request_id.encode("ascii", "strict"))
        finally:
            os.close(descriptor)
        return True

    def submit(self, request: BridgeRequest) -> int:
        self.ensure_directories()
        payload = request.to_dict()
        self.cleanup(max_files=4)
        for slot in range(SLOT_COUNT):
            name = self._slot_name(slot)
            request_path = self.requests / f"{name}.json"
            lock_path = self.requests / f"{name}.lock"
            ready_path = self.responses / f"{name}.ready.txt"
            response_path = self.responses / f"{name}.json"
            if request_path.exists() or ready_path.exists() or response_path.exists():
                continue
            if not self._acquire_slot(lock_path, request.request_id):
                continue
            try:
                if request_path.exists() or ready_path.exists() or response_path.exists():
                    lock_path.unlink(missing_ok=True)
                    continue
                self._atomic_json(request_path, payload, MAX_REQUEST_BYTES)
                return slot
            except Exception:
                lock_path.unlink(missing_ok=True)
                raise
        raise BridgeBusyError("bridge queue is full")

    def read_response(self, slot: int, request_id: str) -> Optional[BridgeResponse]:
        name = self._slot_name(slot)
        marker = self.responses / f"{name}.ready.txt"
        if not marker.exists():
            return None
        path = self.responses / f"{name}.json"
        try:
            if path.stat().st_size > MAX_RESPONSE_BYTES:
                raise BridgeProtocolError("response exceeds size limit")
            response = BridgeResponse.from_dict(json.loads(path.read_text(encoding="utf-8")))
        except (FileNotFoundError, OSError, UnicodeError, json.JSONDecodeError) as error:
            raise BridgeProtocolError(f"malformed or partial response: {error}") from error
        if response.request_id != request_id:
            raise BridgeProtocolError("stale response request ID")
        return response

    def read_runtime(self) -> Optional[dict[str, Any]]:
        marker = self.state / "runtime.ready.txt"
        path = self.state / "runtime.json"
        if not marker.exists():
            return None
        try:
            marker_runtime = marker.read_text(encoding="utf-8").strip()
            if path.stat().st_size > MAX_RESPONSE_BYTES:
                return None
            value = json.loads(path.read_text(encoding="utf-8"))
            marker_after = marker.read_text(encoding="utf-8").strip()
            valid = (isinstance(value, dict) and value.get("protocol_version") == 1
                     and marker_runtime == marker_after == str(value.get("runtime_id") or ""))
            return value if valid else None
        except (FileNotFoundError, PermissionError, OSError, UnicodeError, json.JSONDecodeError):
            return None

    def release(self, slot: int) -> None:
        name = self._slot_name(slot)
        for path in (self.requests / f"{name}.json", self.responses / f"{name}.json",
                     self.responses / f"{name}.ready.txt", self.responses / f"{name}.ready",
                     self.requests / f"{name}.lock"):
            try:
                path.unlink()
            except (FileNotFoundError, PermissionError, OSError):
                pass

    def cleanup(self, max_files: int = 4) -> int:
        """Delete only old validated slot files, with a bounded per-call budget."""
        cutoff = time.time() - RETENTION_SECONDS
        removed = 0
        for slot in range(SLOT_COUNT):
            name = self._slot_name(slot)
            paths = (self.requests / f"{name}.json", self.responses / f"{name}.json",
                     self.responses / f"{name}.ready.txt", self.responses / f"{name}.ready",
                     self.requests / f"{name}.lock")
            try:
                existing = [path for path in paths if path.exists()]
                expired = existing and max(path.stat().st_mtime for path in existing) < cutoff
            except (FileNotFoundError, PermissionError, OSError):
                continue
            if expired:
                for path in existing:
                    try:
                        path.unlink()
                    except (FileNotFoundError, PermissionError, OSError):
                        pass
                removed += 1
                if removed >= max_files:
                    break
        return removed
