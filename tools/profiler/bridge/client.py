"""Non-blocking bridge client reusable by Tk, CLI, and future tools."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
import time
from typing import Any, Optional

from .errors import BridgeProtocolError
from .models import BridgeRequest, BridgeResponse
from .transport import BridgeTransport

MAX_PENDING = 16
MAX_RESULTS = 64


@dataclass
class PendingRequest:
    request: BridgeRequest
    slot: int
    submitted_at: float
    timeout_seconds: float


class BridgeClient:
    def __init__(self, transport: BridgeTransport) -> None:
        self.transport = transport
        self.pending: dict[str, PendingRequest] = {}
        self.completed: dict[str, BridgeResponse] = {}
        self.failures: dict[str, str] = {}
        self.latencies_ms: deque[float] = deque(maxlen=30)
        self.runtime: Optional[dict[str, Any]] = None
        self.last_response_at: Optional[float] = None

    @staticmethod
    def _bounded_store(target: dict[str, Any], key: str, value: Any) -> None:
        while len(target) >= MAX_RESULTS:
            del target[next(iter(target))]
        target[key] = value

    def refresh_runtime(self) -> Optional[dict[str, Any]]:
        self.runtime = self.transport.read_runtime()
        return self.runtime

    def submit(self, namespace: str, command: str, arguments: Optional[dict[str, Any]] = None,
               *, target_current_runtime: bool = True, timeout_seconds: float = 5.0) -> str:
        if len(self.pending) >= MAX_PENDING:
            raise RuntimeError("bridge pending-request limit reached")
        runtime_id = (self.runtime or {}).get("runtime_id") if target_current_runtime else None
        request = BridgeRequest(namespace=namespace, command=command, arguments=arguments or {},
                                target_runtime_id=runtime_id)
        slot = self.transport.submit(request)
        self.pending[request.request_id] = PendingRequest(
            request=request, slot=slot, submitted_at=time.monotonic(),
            timeout_seconds=max(0.1, timeout_seconds))
        return request.request_id

    def poll(self) -> list[BridgeResponse]:
        now = time.monotonic()
        responses = []
        for request_id, pending in list(self.pending.items()):
            if now - pending.submitted_at >= pending.timeout_seconds:
                self._bounded_store(self.failures, request_id, "TIMEOUT")
                self.transport.release(pending.slot)
                del self.pending[request_id]
                continue
            try:
                response = self.transport.read_response(pending.slot, request_id)
            except (BridgeProtocolError, OSError) as error:
                self._bounded_store(self.failures, request_id, str(error))
                self.transport.release(pending.slot)
                del self.pending[request_id]
                continue
            if response is None:
                continue
            self.latencies_ms.append((now - pending.submitted_at) * 1000.0)
            self._bounded_store(self.completed, request_id, response)
            self.last_response_at = time.time()
            self.transport.release(pending.slot)
            del self.pending[request_id]
            responses.append(response)
        return responses

    def take(self, request_id: str) -> Optional[BridgeResponse]:
        return self.completed.pop(request_id, None)

    def close(self) -> None:
        for pending in list(self.pending.values()):
            self.transport.release(pending.slot)
        self.pending.clear()

    @property
    def average_latency_ms(self) -> Optional[float]:
        return sum(self.latencies_ms) / len(self.latencies_ms) if self.latencies_ms else None
