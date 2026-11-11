"""Provider-neutral serialized worker session lifecycle."""

from __future__ import annotations

from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass
from threading import Lock
from typing import Any, Callable, Generic, TypeVar

from ..transport.process import HarnessError


WorkerT = TypeVar("WorkerT")
ResultT = TypeVar("ResultT")


class SessionClosedError(HarnessError):
    """Raised when an operation reaches a session after shutdown began."""


@dataclass(frozen=True)
class WorkerReady:
    """Startup data captured on the serialized worker thread."""

    status: dict[str, Any]
    capabilities: dict[str, Any]


@dataclass(frozen=True)
class WorkerResult(Generic[ResultT]):
    """An operation result and status captured in the same queue turn."""

    value: ResultT
    status: dict[str, Any]


class WorkerSession(Generic[WorkerT]):
    """Own one worker and its single serialized execution queue."""

    def __init__(self, factory: Callable[[], WorkerT]) -> None:
        self._factory = factory
        self._executor = ThreadPoolExecutor(
            max_workers=1,
            thread_name_prefix="semantic-harness",
        )
        self._lock = Lock()
        self._closed = False
        self._worker: WorkerT | None = None
        self._start_future: Future[WorkerReady] | None = None

    @property
    def ready(self) -> bool:
        with self._lock:
            return self._worker is not None and not self._closed

    def start(self) -> Future[WorkerReady]:
        with self._lock:
            if self._closed:
                raise SessionClosedError("Lua worker session is closed")
            if self._start_future is None:
                self._start_future = self._executor.submit(self._start_worker)
            return self._start_future

    def _start_worker(self) -> WorkerReady:
        with self._lock:
            if self._closed:
                raise SessionClosedError("Lua worker session is closed")
        worker = self._factory()
        try:
            capabilities = worker.capabilities()
            status = worker.status()
        except BaseException:
            worker.close()
            raise

        with self._lock:
            closed = self._closed
            if not closed:
                self._worker = worker
        if closed:
            worker.close()
            raise SessionClosedError(
                "Lua worker session closed while the worker was starting"
            )
        return WorkerReady(status=status, capabilities=capabilities)

    def submit(
        self,
        operation: Callable[[WorkerT], ResultT],
    ) -> Future[WorkerResult[ResultT]]:
        with self._lock:
            if self._closed:
                raise SessionClosedError("Lua worker session is closed")
            if self._start_future is None:
                raise HarnessError("Lua worker session has not started")
            return self._executor.submit(self._run_operation, operation)

    def _run_operation(
        self,
        operation: Callable[[WorkerT], ResultT],
    ) -> WorkerResult[ResultT]:
        with self._lock:
            if self._closed:
                raise SessionClosedError("Lua worker session is closed")
            worker = self._worker
        if worker is None:
            raise HarnessError("Lua worker is not ready")
        value = operation(worker)
        return WorkerResult(value=value, status=worker.status())

    def close(self, *, wait: bool = False) -> None:
        """Queue cleanup behind in-flight work with an explicit wait policy."""

        with self._lock:
            if self._closed:
                executor = self._executor
            else:
                self._closed = True
                worker = self._worker
                if worker is not None:
                    self._executor.submit(worker.close)
                executor = self._executor
        if wait:
            executor.shutdown(wait=True, cancel_futures=False)
            return
        executor.shutdown(wait=False, cancel_futures=False)
