"""Resource-aware process runner for the Python Semantic Harness suite.

Each discovered unittest module runs in its own Python process.  The process
owns its Lua worker(s), so worker access remains serial inside a test process
while independent modules can use separate CPU/process resources.  Modules
that exercise source/generation authoring are deliberately kept in a serial
exclusive lane for the shared checkout.
"""

from __future__ import annotations

import argparse
from concurrent.futures import CancelledError, Future, ThreadPoolExecutor, as_completed
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading
import time
import weakref
from typing import Iterable, Sequence


HARNESS_ROOT = Path(__file__).resolve().parents[1]
_VENV_PYTHON_CANDIDATES = (
    HARNESS_ROOT / ".venv/bin/python",
    HARNESS_ROOT / ".venv/Scripts/python.exe",
)
DEFAULT_PYTHON = str(
    next(
        (candidate for candidate in _VENV_PYTHON_CANDIDATES if candidate.is_file()),
        Path(sys.executable),
    )
)
DEFAULT_JOBS = min(4, os.cpu_count() or 1)
DEFAULT_TIMEOUT_SECONDS = 300.0
DEFAULT_MAX_OUTPUT_BYTES = 256 * 1024
DEFAULT_SLOWEST_COUNT = 12

# These modules exercise approved source/generation authoring paths.  They use
# temporary repositories in their normal tests, but remain exclusive so future
# cases cannot accidentally write generated artifacts beside a read-only test.
CANONICAL_SOURCE_MODULES = frozenset({
    "test_codebuilder_consolidation",
    "test_interaction_spec",
    "test_semantic_authoring_compiler",
    "test_v1_visual_authoring",
})

# This module has a real wall-clock IPC budget.  It is read-only, but running
# it alongside several worker-startup-heavy modules makes that product budget
# scheduler-dependent.  Keep the assertion meaningful by giving it the same
# serial resource lane as canonical-source tests; this is not worker reuse.
RESOURCE_SENSITIVE_MODULES = frozenset({
    "test_conversational_competence_c7g",
    "test_contextual_scale_isolation",
    # These real-worker contextual modules passed in an isolated serial
    # rerun but produced scheduler-sensitive precision/context failures when
    # competing with other worker-heavy modules.  Keep the tests unchanged;
    # route only the resource-sensitive processes through the existing
    # exclusive lane.
    "test_c7f_dataset_precision",
    "test_coherent_conversation_c8",
    "test_contextual_acceptance_c6b",
    "test_contextual_conversation_c4a",
    "test_contextual_conversation_c4b",
    "test_contextual_conversation_c4c",
    "test_contextual_conversation_c4d",
    "test_contextual_provider_parity_c6c",
    "test_contextual_speech_behavior",
    "test_contextual_suggestions_whats_up",
})

# These modules are still safe to run in the bounded parallel lane, but their
# measured wall time is dominated by real production-Lua worker/fixture work.
# Keep the topology visible in --list and reports so a fast/default run is not
# confused with the deliberately expensive acceptance estate.  This label does
# not share workers or weaken per-module isolation.
SLOW_ACCEPTANCE_MODULES = frozenset({
    "test_response_observatory_matrix",
    "test_sweep_acceptance",
    "test_observatory_fixture_parity",
    "test_harness",
    "test_contextual_talk_parity",
    "test_behavior_fixture_parity",
    "test_contextual_social_reactions",
    "test_contextual_speech_behavior",
    "test_automatic_flow_generation",
    "test_pilot_parity",
    "test_contextual_suggestions_s4",
    "test_contextual_bonds",
})

EXCLUSIVE_MODULES = CANONICAL_SOURCE_MODULES | RESOURCE_SENSITIVE_MODULES

_SKIPPED_RE = re.compile(r"\bskipped=(\d+)\b")
_RAN_RE = re.compile(r"\bRan (\d+) test")
_ACTIVE_RUNNERS: weakref.WeakSet["PythonAcceptanceRunner"] = weakref.WeakSet()
_SHUTDOWN_HANDLER_INSTALLED = False


@dataclass(frozen=True)
class PythonModule:
    name: str
    classification: str

    @property
    def exclusive(self) -> bool:
        return self.classification == "exclusive"


@dataclass(frozen=True)
class PythonModuleResult:
    module: str
    classification: str
    status: str
    returncode: int | None
    elapsed: float
    timed_out: bool
    skip_count: int
    pid: int | None
    output: str
    termination_reason: str | None = None

    def as_dict(self) -> dict[str, object]:
        return {
            "module": self.module,
            "classification": self.classification,
            "status": self.status,
            "returncode": self.returncode,
            "elapsed": self.elapsed,
            "timedOut": self.timed_out,
            "skipCount": self.skip_count,
            "pid": self.pid,
            "output": self.output,
            "terminationReason": self.termination_reason,
        }


def install_shutdown_handler() -> None:
    """Terminate active child process groups when the runner is interrupted."""

    global _SHUTDOWN_HANDLER_INSTALLED
    if (_SHUTDOWN_HANDLER_INSTALLED
            or threading.current_thread() is not threading.main_thread()):
        return

    def handle_signal(signum: int, _frame: object) -> None:
        for runner in list(_ACTIVE_RUNNERS):
            runner.terminate_all()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    _SHUTDOWN_HANDLER_INSTALLED = True


class PythonAcceptanceRunner:
    """Run unittest modules in isolated subprocesses with bounded resources."""

    def __init__(
        self,
        root: Path,
        *,
        python: str = DEFAULT_PYTHON,
        jobs: int = DEFAULT_JOBS,
        timeout: float = DEFAULT_TIMEOUT_SECONDS,
        max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
        tests_root: Path | None = None,
        module_prefix: str = "tools.semantic_harness.tests",
        modules: Sequence[str] | None = None,
        exclusive_modules: Iterable[str] = EXCLUSIVE_MODULES,
        environment: dict[str, str] | None = None,
        headless: bool = True,
    ) -> None:
        if jobs <= 0:
            raise ValueError("jobs must be positive")
        if timeout <= 0:
            raise ValueError("timeout must be positive")
        if max_output_bytes <= 0:
            raise ValueError("max_output_bytes must be positive")
        self.root = root.resolve()
        self.python = python
        self.jobs = jobs
        self.timeout = timeout
        self.max_output_bytes = max_output_bytes
        self.tests_root = (tests_root or self.root / "tools/semantic_harness/tests").resolve()
        self.module_prefix = module_prefix
        self._requested_modules = tuple(modules) if modules is not None else None
        self.exclusive_modules = frozenset(exclusive_modules)
        self.environment = dict(environment or {})
        self.headless = headless
        self._lock = threading.Lock()
        self._active: dict[str, subprocess.Popen[bytes]] = {}
        self._events: list[dict[str, object]] = []
        self._max_active = 0
        self._stop_requested = False
        _ACTIVE_RUNNERS.add(self)

    @property
    def max_active_processes(self) -> int:
        with self._lock:
            return self._max_active

    @property
    def events(self) -> list[dict[str, object]]:
        with self._lock:
            return list(self._events)

    def _record_event(self, event: dict[str, object]) -> None:
        with self._lock:
            if len(self._events) < 4096:
                self._events.append(event)

    def classify(self, module: str) -> PythonModule:
        short_name = module.rsplit(".", 1)[-1]
        classification = (
            "exclusive" if short_name in self.exclusive_modules
            else "acceptance_slow" if short_name in SLOW_ACCEPTANCE_MODULES
            else "parallel"
        )
        return PythonModule(name=module, classification=classification)

    def discover(self, filters: Sequence[str] = ()) -> list[PythonModule]:
        if self._requested_modules is not None:
            modules = list(self._requested_modules)
        else:
            modules = []
            for path in sorted(self.tests_root.glob("test_*.py")):
                relative = path.relative_to(self.root).with_suffix("")
                modules.append(".".join(relative.parts))
        if filters:
            lowered = tuple(value.casefold() for value in filters)
            modules = [
                module for module in modules
                if any(value in module.casefold() for value in lowered)
            ]
        return [self.classify(module) for module in sorted(set(modules))]

    def _environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(self.environment)
        environment["PYTHONUNBUFFERED"] = "1"
        if self.headless:
            environment.pop("DISPLAY", None)
        return environment

    @staticmethod
    def _terminate(process: subprocess.Popen[bytes]) -> None:
        if process.poll() is not None:
            return
        try:
            if os.name == "posix":
                os.killpg(process.pid, signal.SIGTERM)
            else:
                process.terminate()
            process.wait(timeout=1.0)
        except (OSError, subprocess.TimeoutExpired):
            try:
                if os.name == "posix":
                    os.killpg(process.pid, signal.SIGKILL)
                else:
                    process.kill()
                process.wait(timeout=1.0)
            except (OSError, subprocess.TimeoutExpired):
                pass

    def terminate_all(self) -> None:
        with self._lock:
            self._stop_requested = True
            processes = list(self._active.values())
        for process in processes:
            self._terminate(process)

    def _limited_output(self, output: bytes | str | None) -> str:
        if output is None:
            return ""
        if isinstance(output, str):
            rendered = output
        else:
            rendered = output.decode("utf-8", errors="replace")
        encoded = rendered.encode("utf-8", errors="replace")
        if len(encoded) <= self.max_output_bytes:
            return rendered
        marker = b"\n... output truncated by Python acceptance runner ...\n"
        bounded = encoded[:max(0, self.max_output_bytes - len(marker))] + marker
        return bounded.decode("utf-8", errors="replace")

    @staticmethod
    def _skip_count(output: str) -> int:
        match = _SKIPPED_RE.search(output)
        return int(match.group(1)) if match else 0

    @staticmethod
    def _ran_count(output: str) -> int | None:
        match = _RAN_RE.search(output)
        return int(match.group(1)) if match else None

    def _run_one(self, module: PythonModule) -> PythonModuleResult:
        started = time.monotonic()
        process: subprocess.Popen[bytes] | None = None
        output: bytes | str | None = None
        returncode: int | None = None
        timed_out = False
        termination_reason: str | None = None
        try:
            process = subprocess.Popen(
                [self.python, "-m", "unittest", module.name, "-q"],
                cwd=self.root,
                env=self._environment(),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                start_new_session=(os.name == "posix"),
            )
            with self._lock:
                self._active[module.name] = process
                self._max_active = max(self._max_active, len(self._active))
            self._record_event({
                "event": "module.started",
                "module": module.name,
                "classification": module.classification,
                "pid": process.pid,
                "time": time.time(),
            })
            try:
                output, _ = process.communicate(timeout=self.timeout)
            except subprocess.TimeoutExpired as error:
                timed_out = True
                termination_reason = "timeout"
                self._terminate(process)
                tail, _ = process.communicate(timeout=1.0)
                output = (error.output or b"") + (tail or b"")
                returncode = 124
            else:
                returncode = process.returncode
                with self._lock:
                    stop_requested = self._stop_requested
                if returncode != 0 and stop_requested:
                    termination_reason = "fail_fast"
        except OSError as error:
            output = str(error)
            returncode = 127
            termination_reason = "spawn_error"
        finally:
            if process is not None and process.poll() is None:
                self._terminate(process)
            if process is not None:
                with self._lock:
                    self._active.pop(module.name, None)

        rendered_output = self._limited_output(output)
        elapsed = time.monotonic() - started
        if timed_out:
            status = "FAIL"
        elif returncode == 0:
            ran_count = self._ran_count(rendered_output)
            skip_count = self._skip_count(rendered_output)
            status = (
                "SKIP"
                if ran_count is not None and ran_count <= skip_count
                else "PASS"
            )
        else:
            status = "FAIL"
        result = PythonModuleResult(
            module=module.name,
            classification=module.classification,
            status=status,
            returncode=returncode,
            elapsed=elapsed,
            timed_out=timed_out,
            skip_count=self._skip_count(rendered_output),
            pid=process.pid if process is not None else None,
            output=rendered_output,
            termination_reason=termination_reason,
        )
        self._record_event({
            "event": "module.finished",
            "module": module.name,
            "classification": module.classification,
            "status": result.status,
            "returncode": result.returncode,
            "elapsed": result.elapsed,
            "time": time.time(),
        })
        return result

    @staticmethod
    def _cancelled(module: PythonModule) -> PythonModuleResult:
        return PythonModuleResult(
            module=module.name,
            classification=module.classification,
            status="SKIP",
            returncode=None,
            elapsed=0.0,
            timed_out=False,
            skip_count=0,
            pid=None,
            output="",
            termination_reason="fail_fast",
        )

    def _run_parallel(
        self,
        modules: Sequence[PythonModule],
        *,
        fail_fast: bool,
    ) -> list[PythonModuleResult]:
        if not modules:
            return []
        results: list[PythonModuleResult] = []
        worker_count = min(self.jobs, len(modules))
        with ThreadPoolExecutor(
            max_workers=worker_count,
            thread_name_prefix="python-acceptance",
        ) as executor:
            futures: dict[Future[PythonModuleResult], PythonModule] = {
                executor.submit(self._run_one, module): module
                for module in modules
            }
            stopped = False
            for future in as_completed(futures):
                module = futures[future]
                try:
                    result = future.result()
                except CancelledError:
                    result = self._cancelled(module)
                results.append(result)
                if fail_fast and result.status == "FAIL" and not stopped:
                    stopped = True
                    self.terminate_all()
                    for pending, pending_module in futures.items():
                        if pending.cancel():
                            results.append(self._cancelled(pending_module))
        return results

    def run(
        self,
        filters: Sequence[str] = (),
        *,
        fail_fast: bool = False,
    ) -> dict[str, object]:
        started = time.monotonic()
        with self._lock:
            self._stop_requested = False
        modules = self.discover(filters)
        parallel = [module for module in modules if not module.exclusive]
        exclusive = [module for module in modules if module.exclusive]
        results = self._run_parallel(parallel, fail_fast=fail_fast)
        failed = any(result.status == "FAIL" for result in results)

        if fail_fast and failed:
            results.extend(self._cancelled(module) for module in exclusive)
        else:
            for index, module in enumerate(exclusive):
                result = self._run_one(module)
                results.append(result)
                if fail_fast and result.status == "FAIL":
                    results.extend(
                        self._cancelled(remaining)
                        for remaining in exclusive[index + 1:]
                    )
                    break

        ordered = sorted(results, key=lambda result: result.module)
        summary = {
            "PASS": sum(result.status == "PASS" for result in ordered),
            "FAIL": sum(result.status == "FAIL" for result in ordered),
            "SKIP": sum(result.status == "SKIP" for result in ordered),
            "total": len(ordered),
        }
        slowest = sorted(ordered, key=lambda result: result.elapsed, reverse=True)
        report = {
            "type": "python_semantic_harness_acceptance",
            "root": str(self.root),
            "python": self.python,
            "jobs": self.jobs,
            "timeout": self.timeout,
            "headless": self.headless,
            "exclusiveModules": sorted(self.exclusive_modules),
            "slowAcceptanceModules": sorted(SLOW_ACCEPTANCE_MODULES),
            "modules": [result.as_dict() for result in ordered],
            "slowest": [result.as_dict() for result in slowest[:DEFAULT_SLOWEST_COUNT]],
            "events": self.events,
            "maxActiveProcesses": self.max_active_processes,
            "elapsed": time.monotonic() - started,
            "summary": summary,
            "ok": summary["FAIL"] == 0 and summary["total"] == len(modules),
        }
        return report


def print_report(report: dict[str, object], *, verbose: bool = True) -> None:
    modules = report.get("modules", [])
    if verbose and isinstance(modules, list):
        for item in modules:
            print(
                f"{item['status']:4} {item['module']} "
                f"{float(item['elapsed']):8.2f}s "
                f"rc={item['returncode']} timeout={item['timedOut']}"
            )
    summary = report["summary"]
    print(
        "PYTHON ACCEPTANCE: "
        f"PASS {summary['PASS']}, FAIL {summary['FAIL']}, "
        f"SKIP {summary['SKIP']}, TOTAL {summary['total']} "
        f"in {float(report['elapsed']):.2f}s "
        f"({report['jobs']} jobs; max-active={report['maxActiveProcesses']})"
    )
    print("SLOWEST MODULES")
    print("status  seconds  returncode  module")
    for item in report.get("slowest", []):
        print(
            f"{item['status']:6} {float(item['elapsed']):8.2f} "
            f"{str(item['returncode']):10} {item['module']}"
        )


def write_report(report: dict[str, object], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def parse_args(arguments: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filters", nargs="*", help="case-insensitive module filters")
    parser.add_argument("--jobs", type=int, default=DEFAULT_JOBS)
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT_SECONDS)
    parser.add_argument("--python", default=DEFAULT_PYTHON)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--fail-fast", action="store_true")
    parser.add_argument("--keep-display", action="store_true")
    parser.add_argument("--quiet-modules", action="store_true")
    parser.add_argument("--list", action="store_true")
    return parser.parse_args(arguments)


def main(arguments: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    options = parse_args(arguments)
    root = Path(__file__).resolve().parents[3]
    runner = PythonAcceptanceRunner(
        root,
        python=options.python,
        jobs=options.jobs,
        timeout=options.timeout,
        headless=not options.keep_display,
    )
    modules = runner.discover(options.filters)
    if options.list:
        for module in modules:
            print(f"{module.classification}\t{module.name}")
        return 0
    if not modules:
        print("No matching Python test modules.", file=sys.stderr)
        return 2
    report = runner.run(options.filters, fail_fast=options.fail_fast)
    print_report(report, verbose=not options.quiet_modules)
    if options.report:
        write_report(report, options.report.expanduser())
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
