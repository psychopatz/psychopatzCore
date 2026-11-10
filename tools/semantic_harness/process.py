"""Bounded, correlated JSON-lines client for a semantic worker process."""

from __future__ import annotations

import os
import queue
import signal
import subprocess
import threading
import time
import weakref
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Mapping

from .protocol import (
    DEFAULT_MAX_MESSAGE_BYTES,
    ProtocolError,
    decode_message,
    encode_request,
)


@dataclass(frozen=True)
class WorkerLaunchSpec:
    """Generic worker launch data supplied by a profile adapter."""

    lua_bin: Path
    worker_script: Path
    core_repository: Path
    working_directory: Path | None = None
    profile: str = "core"
    provider_ids: tuple[str, ...] = ()
    materialization_mode: str = "none"
    provider_module_paths: tuple[str, ...] = ()
    provider_modules: tuple[str, ...] = ()
    execution_provider_id: str | None = None
    worker_arguments: tuple[str, ...] = ()
    environment: Mapping[str, str] = field(default_factory=dict)
    startup_timeout: float = 8.0
    request_timeout: float = 5.0
    shutdown_timeout: float = 1.0
    max_message_bytes: int = DEFAULT_MAX_MESSAGE_BYTES

    @classmethod
    def from_profile_selection(
        cls,
        selection: Any,
        **values: Any,
    ) -> "WorkerLaunchSpec":
        """Create a launch spec from Core's validated profile metadata.

        Adopters may supply repository paths, worker arguments, and their
        private environment aliases, but profile identity and materialization
        metadata always come from the validated Core selection.
        """

        values = dict(values)
        values.update(
            {
                "profile": selection.profile_id,
                "provider_ids": tuple(selection.provider_ids),
                "materialization_mode": selection.materialization_mode,
            }
        )
        return cls(**values)

    def neutral_environment(self) -> dict[str, str]:
        """Return only provider-neutral metadata for the worker process."""

        environment = {
            "SEMANTIC_HARNESS_PROFILE": self.profile,
            "SEMANTIC_HARNESS_PROVIDER_IDS": ",".join(self.provider_ids),
            "SEMANTIC_HARNESS_MATERIALIZATION_MODE": self.materialization_mode,
        }
        if self.provider_module_paths:
            environment["SEMANTIC_HARNESS_PROVIDER_MODULE_PATHS"] = ";".join(
                self.provider_module_paths
            )
        if self.provider_modules:
            environment["SEMANTIC_HARNESS_PROVIDER_MODULES"] = ",".join(
                self.provider_modules
            )
        if self.execution_provider_id:
            environment["SEMANTIC_HARNESS_EXECUTION_PROVIDER_ID"] = (
                self.execution_provider_id
            )
        return environment

    def __post_init__(self) -> None:
        profile = str(self.profile).strip()
        if not profile:
            raise ValueError("worker profile must be non-empty")
        provider_ids = tuple(str(value).strip() for value in self.provider_ids)
        if any(not value for value in provider_ids):
            raise ValueError("provider IDs must be non-empty")
        if len(set(provider_ids)) != len(provider_ids):
            raise ValueError("provider IDs must be unique")
        materialization_mode = str(self.materialization_mode).strip().lower()
        if materialization_mode not in {"none", "abstract", "physical"}:
            raise ValueError("invalid materialization mode")
        if self.startup_timeout <= 0:
            raise ValueError("startup timeout must be positive")
        if self.request_timeout <= 0:
            raise ValueError("request timeout must be positive")
        if self.shutdown_timeout <= 0:
            raise ValueError("shutdown timeout must be positive")
        if self.max_message_bytes <= 0:
            raise ValueError("message limit must be positive")
        object.__setattr__(self, "profile", profile)
        object.__setattr__(self, "provider_ids", provider_ids)
        object.__setattr__(self, "materialization_mode", materialization_mode)
        provider_module_paths = tuple(
            str(value).strip() for value in self.provider_module_paths
        )
        provider_modules = tuple(
            str(value).strip() for value in self.provider_modules
        )
        if any(not value for value in provider_module_paths):
            raise ValueError("provider module paths must be non-empty")
        if any(not value for value in provider_modules):
            raise ValueError("provider modules must be non-empty")
        if len(set(provider_modules)) != len(provider_modules):
            raise ValueError("provider modules must be unique")
        execution_provider_id = self.execution_provider_id
        if execution_provider_id is not None:
            execution_provider_id = str(execution_provider_id).strip()
            if not execution_provider_id:
                raise ValueError("execution provider ID must be non-empty")
        object.__setattr__(self, "provider_module_paths", provider_module_paths)
        object.__setattr__(self, "provider_modules", provider_modules)
        object.__setattr__(self, "execution_provider_id", execution_provider_id)
        object.__setattr__(self, "lua_bin", Path(self.lua_bin).expanduser().resolve())
        object.__setattr__(
            self,
            "worker_script",
            Path(self.worker_script).expanduser().resolve(),
        )
        object.__setattr__(
            self,
            "core_repository",
            Path(self.core_repository).expanduser().resolve(),
        )
        working_directory = (
            Path(self.working_directory).expanduser().resolve()
            if self.working_directory is not None
            else Path(self.core_repository).expanduser().resolve()
        )
        object.__setattr__(self, "working_directory", working_directory)
        object.__setattr__(
            self,
            "worker_arguments",
            tuple(str(value) for value in self.worker_arguments),
        )
        object.__setattr__(self, "environment", dict(self.environment))


_ACTIVE_PROCESSES: weakref.WeakSet["LuaProcess"] = weakref.WeakSet()
_SHUTDOWN_HANDLER_INSTALLED = False


def install_shutdown_handler() -> None:
    """Ensure external termination closes every active worker first."""

    global _SHUTDOWN_HANDLER_INSTALLED
    if (
        _SHUTDOWN_HANDLER_INSTALLED
        or threading.current_thread() is not threading.main_thread()
    ):
        return

    def handle_signal(signum: int, _frame: Any) -> None:
        for runtime in list(_ACTIVE_PROCESSES):
            runtime.close()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    _SHUTDOWN_HANDLER_INSTALLED = True


class HarnessError(RuntimeError):
    """A bounded worker lifecycle or protocol failure."""


class LuaProcess:
    """Own one worker process and serialize all requests through it."""

    def __init__(
        self,
        config: WorkerLaunchSpec,
        activity_log: Any | None = None,
    ) -> None:
        self.config = config
        self.activity_log = activity_log
        self.process: subprocess.Popen[bytes] | None = None
        self._state = "STOPPED"
        self._state_lock = threading.RLock()
        self._request_lock = threading.Lock()
        self._pending_lock = threading.Lock()
        self._pending: dict[str, queue.Queue[dict[str, Any]]] = {}
        self._hello: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=1)
        self._stderr: deque[str] = deque(maxlen=32)
        self._failure: str | None = None
        self._request_sequence = 0
        self._reader_thread: threading.Thread | None = None
        self._stderr_thread: threading.Thread | None = None

    @property
    def state(self) -> str:
        with self._state_lock:
            return self._state

    def status(self) -> dict[str, Any]:
        process = self.process
        return {
            "state": self.state,
            "pid": process.pid if process is not None else None,
            "returncode": process.poll() if process is not None else None,
            "failure": self._failure,
            "stderr": list(self._stderr),
            "profile": self.config.profile,
        }

    def start(self) -> dict[str, Any]:
        with self._state_lock:
            if self._state not in {"STOPPED", "FAILED"}:
                raise HarnessError(f"worker is already {self._state.lower()}")
            self._state = "STARTING"
            self._failure = None

        environment = os.environ.copy()
        environment.update(
            {
                "SEMANTIC_HARNESS_CORE_REPOSITORY": str(
                    self.config.core_repository
                ),
                **self.config.neutral_environment(),
            }
        )
        environment.update(self.config.environment)
        command = [
            str(self.config.lua_bin),
            str(self.config.worker_script),
            *self.config.worker_arguments,
        ]
        try:
            self.process = subprocess.Popen(
                command,
                cwd=self.config.working_directory,
                env=environment,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0,
            )
            _ACTIVE_PROCESSES.add(self)
            self._record_activity(
                "start",
                coreRepository=str(self.config.core_repository),
                profile=self.config.profile,
                pid=self.process.pid,
            )
        except OSError as error:
            self._set_failure(f"could not start Lua worker: {error}")
            raise HarnessError(self._failure or str(error)) from error

        self._reader_thread = threading.Thread(
            target=self._read_stdout,
            name="semantic-harness-worker-reader",
            daemon=True,
        )
        self._stderr_thread = threading.Thread(
            target=self._read_stderr,
            name="semantic-harness-worker-stderr",
            daemon=True,
        )
        self._reader_thread.start()
        self._stderr_thread.start()
        try:
            hello = self._hello.get(timeout=self.config.startup_timeout)
        except queue.Empty as error:
            detail = self._failure or self._diagnostic("worker did not send READY")
            self.close()
            raise HarnessError(detail) from error
        if hello.get("ok") is not True or hello.get("type") != "hello":
            detail = hello.get("error", "worker handshake failed")
            self.close()
            raise HarnessError(str(detail))
        advertised_profile = hello.get("profile")
        if advertised_profile is not None and advertised_profile != self.config.profile:
            detail = (
                "worker profile mismatch: expected "
                f"{self.config.profile}, received {advertised_profile}"
            )
            self.close()
            raise HarnessError(detail)
        with self._state_lock:
            self._state = "READY"
        self._record_activity("ready", pid=self.process.pid if self.process else None)
        return hello

    def request(
        self,
        command: str,
        payload: Any = None,
        *,
        timeout: float | None = None,
    ) -> dict[str, Any]:
        with self._request_lock:
            if self.state != "READY":
                raise HarnessError(self._failure or f"worker is {self.state.lower()}")
            process = self.process
            if process is None or process.stdin is None:
                raise HarnessError("worker pipes are unavailable")
            self._request_sequence += 1
            request_id = f"harness-{self._request_sequence}"
            started_at = time.perf_counter()
            self._record_activity(
                "request",
                command=command,
                requestID=request_id,
                pid=process.pid,
            )
            try:
                encoded = encode_request(
                    request_id,
                    command,
                    payload,
                    max_bytes=self.config.max_message_bytes,
                )
            except ProtocolError as error:
                raise HarnessError(str(error)) from error
            response_queue: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=1)
            with self._pending_lock:
                self._pending[request_id] = response_queue
            try:
                process.stdin.write(encoded)
                process.stdin.flush()
            except (BrokenPipeError, OSError) as error:
                self._set_failure(f"could not write Lua request: {error}")
                raise HarnessError(self._diagnostic("worker write failed")) from error
            try:
                response = response_queue.get(
                    timeout=timeout or self.config.request_timeout
                )
            except queue.Empty as error:
                self._set_failure(f"request timeout: {command}")
                self._record_activity(
                    "timeout",
                    command=command,
                    requestID=request_id,
                    durationMs=round((time.perf_counter() - started_at) * 1000, 1),
                )
                raise HarnessError(
                    self._diagnostic(f"worker timed out on {command}")
                ) from error
            finally:
                with self._pending_lock:
                    self._pending.pop(request_id, None)
            if response.get("ok") is False:
                self._record_activity(
                    "response_error",
                    command=command,
                    requestID=request_id,
                    durationMs=round((time.perf_counter() - started_at) * 1000, 1),
                    message=str(response.get("error", "worker request failed")),
                )
                raise HarnessError(str(response.get("error", "worker request failed")))
            self._record_activity(
                "response",
                command=command,
                requestID=request_id,
                durationMs=round((time.perf_counter() - started_at) * 1000, 1),
                ok=True,
            )
            return response

    def _record_activity(self, event: str, **details: Any) -> None:
        if self.activity_log is not None:
            self.activity_log.record("worker", event, **details)

    def _read_stdout(self) -> None:
        process = self.process
        if process is None or process.stdout is None:
            return
        while True:
            line = process.stdout.readline()
            if not line:
                if self.state not in {"STOPPING", "STOPPED"}:
                    self._set_failure(
                        self._diagnostic("worker exited without a response")
                    )
                return
            if len(line) > self.config.max_message_bytes:
                self._set_failure("worker response exceeds the message limit")
                return
            try:
                message = decode_message(
                    line,
                    max_bytes=self.config.max_message_bytes,
                )
            except ProtocolError as error:
                self._set_failure(str(error))
                return
            if message.get("type") == "hello":
                try:
                    self._hello.put_nowait(message)
                except queue.Full:
                    self._set_failure("duplicate worker handshake")
                continue
            request_id = message.get("id")
            if not isinstance(request_id, str):
                self._set_failure("worker response has no request id")
                return
            with self._pending_lock:
                response_queue = self._pending.get(request_id)
            if response_queue is None:
                self._set_failure(f"worker returned unknown request id: {request_id}")
                return
            try:
                response_queue.put_nowait(message)
            except queue.Full:
                self._set_failure(f"duplicate worker response: {request_id}")
                return

    def _read_stderr(self) -> None:
        process = self.process
        if process is None or process.stderr is None:
            return
        for raw_line in iter(process.stderr.readline, b""):
            line = raw_line.decode("utf-8", errors="replace").rstrip()
            if line:
                self._stderr.append(line[:4096])

    def _set_failure(self, reason: str) -> None:
        with self._state_lock:
            if self._state in {"STOPPED", "STOPPING"}:
                return
            self._state = "FAILED"
            self._failure = reason
        failure = {"ok": False, "error": reason}
        with self._pending_lock:
            pending = list(self._pending.values())
        for response_queue in pending:
            try:
                response_queue.put_nowait(failure)
            except queue.Full:
                pass
        process = self.process
        if process is not None and process.poll() is None:
            try:
                process.terminate()
            except OSError:
                pass

    def _diagnostic(self, prefix: str) -> str:
        process = self.process
        returncode = process.poll() if process is not None else None
        stderr = "; ".join(self._stderr)
        suffix = f"; stderr: {stderr}" if stderr else ""
        return f"{prefix} (state={self.state}, returncode={returncode}){suffix}"

    def close(self) -> None:
        process = self.process
        if process is None:
            with self._state_lock:
                self._state = "STOPPED"
            return
        with self._state_lock:
            if self._state != "STOPPED":
                self._state = "STOPPING"
        if process.poll() is None:
            try:
                process.terminate()
                process.wait(timeout=self.config.shutdown_timeout)
            except (OSError, subprocess.TimeoutExpired):
                try:
                    process.kill()
                    process.wait(timeout=self.config.shutdown_timeout)
                except (OSError, subprocess.TimeoutExpired):
                    pass
        for stream in (process.stdin, process.stdout, process.stderr):
            if stream is not None and not stream.closed:
                stream.close()
        for thread in (self._reader_thread, self._stderr_thread):
            if thread is not None and thread is not threading.current_thread():
                thread.join(timeout=0.2)
        with self._state_lock:
            self._state = "STOPPED"
        _ACTIVE_PROCESSES.discard(self)
        self._record_activity("closed")

    def __enter__(self) -> "LuaProcess":
        self.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
