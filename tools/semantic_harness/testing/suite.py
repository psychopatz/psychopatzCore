"""Bounded subprocess runner for provider Lua smoke suites."""

from __future__ import annotations

import json
import os
import signal
import subprocess
import threading
import time
import weakref
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


DEFAULT_MAX_OUTPUT_BYTES = 256 * 1024
_ACTIVE_RUNNERS: weakref.WeakSet["BoundedLuaTestRunner"] = weakref.WeakSet()
_SUITE_SHUTDOWN_HANDLER_INSTALLED = False


def install_suite_shutdown_handler() -> None:
    """Close active smoke-test process groups on external termination."""

    global _SUITE_SHUTDOWN_HANDLER_INSTALLED
    if _SUITE_SHUTDOWN_HANDLER_INSTALLED or threading.current_thread() is not threading.main_thread():
        return

    def handle_signal(signum: int, _frame: Any) -> None:
        for runner in list(_ACTIVE_RUNNERS):
            runner.terminate_all()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    _SUITE_SHUTDOWN_HANDLER_INSTALLED = True


@dataclass(frozen=True)
class LuaTestResult:
    run_id: str
    path: Path
    returncode: int
    output: str
    elapsed: float
    status: str
    pid: int | None
    timed_out: bool = False
    output_truncated: bool = False


class BoundedLuaTestRunner:
    """Run isolated Lua tests with bounded output and lifecycle telemetry."""

    def __init__(
        self,
        root: Path,
        *,
        executable: str = "lua",
        max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
    ) -> None:
        if max_output_bytes <= 0:
            raise ValueError("max_output_bytes must be positive")
        self.root = root.resolve()
        self.executable = executable
        self.max_output_bytes = max_output_bytes
        self._lock = threading.Lock()
        self._sequence = 0
        self._active: dict[Path, str] = {}
        self._processes: dict[str, subprocess.Popen[bytes]] = {}
        self._events: list[dict[str, Any]] = []
        self._conflicts: list[dict[str, Any]] = []
        self._results: list[LuaTestResult] = []
        _ACTIVE_RUNNERS.add(self)

    def _next_run_id(self) -> str:
        with self._lock:
            self._sequence += 1
            return f"lua-test-{self._sequence}"

    def _record(self, event: dict[str, Any]) -> None:
        with self._lock:
            if len(self._events) < 4096:
                self._events.append(event)

    def run_one(self, path: Path, environment: dict[str, str], timeout: float) -> LuaTestResult:
        if timeout <= 0:
            raise ValueError("timeout must be positive")
        resolved_path = path.resolve()
        run_id = self._next_run_id()
        started = time.monotonic()
        started_at = time.time()
        with self._lock:
            active_run = self._active.get(resolved_path)
            if active_run is not None:
                self._conflicts.append(
                    {
                        "kind": "concurrent_duplicate_test",
                        "path": str(resolved_path),
                        "firstRunID": active_run,
                        "secondRunID": run_id,
                    }
                )
            self._active[resolved_path] = run_id
        self._record(
            {
                "event": "test.started",
                "runID": run_id,
                "path": str(resolved_path),
                "startedAt": started_at,
            }
        )

        process: subprocess.Popen[bytes] | None = None
        output = bytearray()
        output_truncated = False
        reader_done = threading.Event()

        def read_output(stream: Any) -> None:
            nonlocal output_truncated
            try:
                while True:
                    chunk = stream.read(8192)
                    if not chunk:
                        return
                    remaining = self.max_output_bytes - len(output)
                    if remaining > 0:
                        output.extend(chunk[:remaining])
                    if len(chunk) > max(remaining, 0):
                        output_truncated = True
            finally:
                reader_done.set()

        status = "failed"
        timed_out = False
        returncode = 1
        pid: int | None = None
        try:
            environment_copy = dict(environment)
            process = subprocess.Popen(
                [self.executable, str(resolved_path)],
                cwd=self.root,
                env=environment_copy,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                start_new_session=(os.name == "posix"),
            )
            pid = process.pid
            with self._lock:
                self._processes[run_id] = process
            self._record(
                {
                    "event": "test.process_started",
                    "runID": run_id,
                    "pid": pid,
                }
            )
            reader = threading.Thread(
                target=read_output,
                args=(process.stdout,),
                name=f"lua-test-output-{run_id}",
                daemon=True,
            )
            reader.start()
            try:
                returncode = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                status = "timeout"
                self._terminate(process)
                returncode = 124
            reader_done.wait(timeout=1.0)
            reader.join(timeout=0.2)
            if not timed_out:
                status = "passed" if returncode == 0 else "failed"
        except OSError as error:
            output.extend(str(error).encode("utf-8", errors="replace")[: self.max_output_bytes])
            status = "spawn_error"
            returncode = 127
        finally:
            if process is not None and process.poll() is None:
                self._terminate(process)
            if process is not None and process.stdout is not None and not process.stdout.closed:
                process.stdout.close()
            with self._lock:
                self._active.pop(resolved_path, None)
                self._processes.pop(run_id, None)

        elapsed = time.monotonic() - started
        rendered_output = bytes(output)
        if output_truncated:
            marker = b"\n... output truncated by harness ...\n"
            rendered_output = rendered_output[: max(0, self.max_output_bytes - len(marker))] + marker
        result = LuaTestResult(
            run_id=run_id,
            path=resolved_path,
            returncode=returncode,
            output=rendered_output.decode("utf-8", errors="replace"),
            elapsed=elapsed,
            status=status,
            pid=pid,
            timed_out=timed_out,
            output_truncated=output_truncated,
        )
        self._record(
            {
                "event": "test.finished",
                "runID": run_id,
                "pid": pid,
                "path": str(resolved_path),
                "status": status,
                "returncode": returncode,
                "elapsed": elapsed,
                "timedOut": timed_out,
                "outputTruncated": output_truncated,
            }
        )
        with self._lock:
            self._results.append(result)
        return result

    @staticmethod
    def _terminate(process: subprocess.Popen[bytes]) -> None:
        if process.poll() is not None:
            return
        try:
            if os.name == "posix":
                os.killpg(process.pid, signal.SIGTERM)
            else:
                process.terminate()
            process.wait(timeout=0.5)
        except (OSError, subprocess.TimeoutExpired):
            try:
                if os.name == "posix":
                    os.killpg(process.pid, signal.SIGKILL)
                else:
                    process.kill()
                process.wait(timeout=0.5)
            except (OSError, subprocess.TimeoutExpired):
                pass

    def terminate_all(self) -> None:
        with self._lock:
            processes = list(self._processes.values())
        for process in processes:
            self._terminate(process)

    def report(self, results: Iterable[LuaTestResult] | None = None) -> dict[str, Any]:
        source = self._results if results is None else results
        ordered = sorted(source, key=lambda item: str(item.path))
        return {
            "type": "lua_test_suite",
            "root": str(self.root),
            "executable": self.executable,
            "results": [
                {
                    "runID": result.run_id,
                    "path": str(result.path),
                    "status": result.status,
                    "returncode": result.returncode,
                    "elapsed": result.elapsed,
                    "pid": result.pid,
                    "timedOut": result.timed_out,
                    "outputTruncated": result.output_truncated,
                }
                for result in ordered
            ],
            "events": list(self._events),
            "conflicts": list(self._conflicts),
            "ok": not self._conflicts and all(result.returncode == 0 for result in ordered),
        }


def run_lua_suite(
    paths: Iterable[Path],
    *,
    root: Path,
    environment: dict[str, str],
    executable: str = "lua",
    timeout: float = 30.0,
    jobs: int = 1,
    fail_fast: bool = False,
    max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
) -> tuple[list[LuaTestResult], dict[str, Any]]:
    path_list = list(paths)
    if jobs <= 0:
        raise ValueError("jobs must be positive")
    runner = BoundedLuaTestRunner(
        root,
        executable=executable,
        max_output_bytes=max_output_bytes,
    )
    results: list[LuaTestResult] = []
    worker_count = max(1, min(jobs, len(path_list))) if path_list else 1
    with ThreadPoolExecutor(max_workers=worker_count) as executor:
        futures: dict[Future[LuaTestResult], Path] = {
            executor.submit(runner.run_one, path, environment, timeout): path
            for path in path_list
        }
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            if fail_fast and result.returncode != 0:
                for pending in futures:
                    pending.cancel()
                runner.terminate_all()
                break
    return results, runner.report(results)


def write_report(report: dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
