"""Compact, live-flushed unittest discovery runner for token-efficient CI and agent logs."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import contextlib
import io
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from typing import Any, Iterable, Sequence

_SHARD_EVENT_PREFIX = "__COMPACT_UNITTEST_EVENT__ "
_GUI_MARKERS = ("SemanticHarnessApp", "tkinter", "gui_test_support")


class _FlushingTextStream:
    """Wrap a text stream so every write flushes immediately for live logs."""

    def __init__(self, stream: object) -> None:
        self._stream = stream

    def write(self, text: str) -> int:
        written = self._stream.write(text)  # type: ignore[attr-defined]
        self._stream.flush()  # type: ignore[attr-defined]
        return written

    def writeln(self, text: str = "") -> None:
        self.write(f"{text}\n")

    def flush(self) -> None:
        self._stream.flush()  # type: ignore[attr-defined]


def _case_module_name(case: unittest.TestCase) -> str:
    module_name = getattr(case.__class__, "__module__", "")
    if module_name == "unittest.loader":
        method_name = getattr(case, "_testMethodName", "")
        if method_name:
            return str(method_name)
    return str(module_name or case.id())


def _iter_leaf_cases(suite: unittest.TestSuite) -> Iterable[unittest.TestCase]:
    for item in suite:
        if isinstance(item, unittest.TestSuite):
            yield from _iter_leaf_cases(item)
        else:
            yield item


def discover_module_suites(
    start_dir: str | Path,
    *,
    pattern: str = "test_*.py",
    top_level_dir: str | Path | None = None,
    filters: Sequence[str] = (),
    exact_modules: Sequence[str] = (),
) -> list[tuple[str, unittest.TestSuite]]:
    """Discover unittest suites grouped by module name and sorted deterministically."""
    resolved_start = str(Path(start_dir).expanduser().resolve())
    resolved_top = (
        str(Path(top_level_dir).expanduser().resolve())
        if top_level_dir is not None
        else None
    )
    loader = unittest.TestLoader()
    discovered = loader.discover(
        start_dir=resolved_start,
        pattern=pattern,
        top_level_dir=resolved_top,
    )
    grouped: dict[str, list[unittest.TestCase]] = {}
    for case in _iter_leaf_cases(discovered):
        mod_name = _case_module_name(case)
        grouped.setdefault(mod_name, []).append(case)

    ordered_names = sorted(grouped)
    if exact_modules:
        exact_set = set(exact_modules)
        ordered_names = [name for name in ordered_names if name in exact_set]
    lowered_filters = tuple(term.casefold() for term in filters if term)
    if lowered_filters:
        ordered_names = [
            name
            for name in ordered_names
            if any(term in name.casefold() for term in lowered_filters)
        ]
    return [(name, unittest.TestSuite(grouped[name])) for name in ordered_names]


def _format_failure_blocks(
    label: str,
    entries: Sequence[tuple[unittest.TestCase | str, str]],
) -> list[str]:
    lines: list[str] = []
    separator = "=" * 70
    divider = "-" * 70
    for test, err_text in entries:
        test_id = test if isinstance(test, str) else test.id()
        lines.append(separator)
        lines.append(f"{label}: {test_id}")
        lines.append(divider)
        lines.append(err_text.rstrip())
    return lines


def _cleanup_warm_workers() -> None:
    """Shut down process-shared warm Lua workers if PNC worker_reuse was imported."""
    worker_reuse_mod = sys.modules.get("tools.providers.pnc.tests.worker_reuse")
    close_all = (
        getattr(worker_reuse_mod, "close_all_warm_workers", None)
        if worker_reuse_mod is not None
        else None
    )
    if callable(close_all):
        try:
            close_all()
        except Exception:
            pass


def _package_import_root(start_path: Path, top_level_dir: str | Path | None) -> Path:
    if top_level_dir is not None:
        return Path(top_level_dir).expanduser().resolve()
    cur = start_path.expanduser().resolve()
    if cur.is_file():
        cur = cur.parent
    while (cur / "__init__.py").is_file():
        parent = cur.parent
        if parent == cur:
            break
        cur = parent
    return cur


def _is_gui_module(mod_name: str) -> bool:
    mod = sys.modules.get(mod_name)
    mod_file = getattr(mod, "__file__", None) if mod is not None else None
    if not mod_file:
        return False
    try:
        text = Path(mod_file).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    return any(marker in text for marker in _GUI_MARKERS)


def _partition_module_shards(
    module_names: Sequence[str],
    jobs: int,
) -> list[list[str]]:
    """Assign GUI modules to one serial shard and spread non-GUI modules across workers."""
    shard_count = min(max(1, jobs), len(module_names))
    if shard_count <= 1:
        return [list(module_names)]
    gui_mods: list[str] = []
    non_gui_mods: list[str] = []
    for mod_name in module_names:
        if _is_gui_module(mod_name):
            gui_mods.append(mod_name)
        else:
            non_gui_mods.append(mod_name)
    shards: list[list[str]] = [[] for _ in range(shard_count)]
    if gui_mods and non_gui_mods:
        shards[0].extend(gui_mods)
        worker_count = shard_count - 1
        for idx, mod_name in enumerate(non_gui_mods):
            shards[1 + (idx % worker_count)].append(mod_name)
    else:
        for idx, mod_name in enumerate(module_names):
            shards[idx % shard_count].append(mod_name)
    return [shard for shard in shards if shard]


def run_compact_unittest(
    *,
    start_dir: str | Path = ".",
    pattern: str = "test_*.py",
    top_level_dir: str | Path | None = None,
    progress_every: int = 10,
    slow_threshold: float = 2.0,
    fail_fast: bool = False,
    verbose: bool = False,
    list_only: bool = False,
    jobs: int = 1,
    filters: Sequence[str] = (),
    exact_modules: Sequence[str] = (),
    shard_jsonl: bool = False,
) -> int:
    """Discover and execute unittest modules with flushed compact live progress."""
    start_path = Path(start_dir).expanduser()
    if not start_path.exists():
        print(f"Error: start directory not found: {start_dir}", file=sys.stderr, flush=True)
        return 2

    if os.environ.get("XMODIFIERS", "") in {"", "@im=ibus"}:
        os.environ["XMODIFIERS"] = "@im=none"

    module_suites = discover_module_suites(
        start_path,
        pattern=pattern,
        top_level_dir=top_level_dir,
        filters=filters,
        exact_modules=exact_modules,
    )

    if list_only:
        for mod_name, suite in module_suites:
            print(f"{mod_name} ({suite.countTestCases()})", flush=True)
        return 0

    total_modules = len(module_suites)
    planned_tests = sum(suite.countTestCases() for _, suite in module_suites)
    display_dir = str(start_path.resolve())
    worker_jobs = max(1, int(jobs))

    if shard_jsonl:
        real_stdout = sys.stdout
        overall_ok = True
        try:
            for mod_name, suite in module_suites:
                mod_started = time.monotonic()
                result = unittest.TextTestResult(
                    io.StringIO(),
                    descriptions=True,
                    verbosity=0,
                )
                result.failfast = bool(fail_fast)
                result.startTestRun()
                try:
                    with contextlib.redirect_stdout(io.StringIO()):
                        suite(result)
                finally:
                    result.stopTestRun()
                mod_elapsed = time.monotonic() - mod_started
                mod_ok = (
                    not result.failures
                    and not result.errors
                    and not result.unexpectedSuccesses
                )
                if not mod_ok:
                    overall_ok = False
                payload = {
                    "module": mod_name,
                    "testsRun": result.testsRun,
                    "skipped": len(result.skipped),
                    "expectedFailures": len(result.expectedFailures),
                    "elapsed": mod_elapsed,
                    "failures": [[t.id(), err] for t, err in result.failures],
                    "errors": [[t.id(), err] for t, err in result.errors],
                    "unexpectedSuccesses": [t.id() for t in result.unexpectedSuccesses],
                }
                real_stdout.write(f"{_SHARD_EVENT_PREFIX}{json.dumps(payload)}\n")
                real_stdout.flush()
                if fail_fast and not mod_ok:
                    break
        finally:
            _cleanup_warm_workers()
        return 0 if overall_ok else 1

    print(
        f"Running {total_modules} unittest modules ({planned_tests} tests) from {display_dir}...",
        flush=True,
    )

    started = time.monotonic()
    width = max(1, len(str(total_modules)))
    interval = max(1, int(progress_every))

    passed_modules = 0
    failed_modules = 0
    total_tests_run = 0
    total_skipped = 0
    total_expected_failures = 0
    all_failures: list[tuple[unittest.TestCase | str, str]] = []
    all_errors: list[tuple[unittest.TestCase | str, str]] = []
    all_unexpected_successes: list[unittest.TestCase | str] = []
    slowest_name = ""
    slowest_elapsed = 0.0

    if worker_jobs > 1 and total_modules > 1 and not verbose:
        shards = _partition_module_shards([name for name, _ in module_suites], worker_jobs)
        core_root = str(Path(__file__).resolve().parents[3])
        pkg_root = str(_package_import_root(start_path, top_level_dir))
        env = os.environ.copy()
        env.setdefault("XMODIFIERS", "@im=none")
        py_parts = [p for p in env.get("PYTHONPATH", "").split(os.pathsep) if p]
        for required_path in (pkg_root, core_root, str(Path.cwd())):
            if required_path not in py_parts:
                py_parts.insert(0, required_path)
        env["PYTHONPATH"] = os.pathsep.join(py_parts)
        lock = threading.Lock()
        completed_count = 0
        stop_event = threading.Event()
        active_procs: list[subprocess.Popen[str]] = []

        def _record_module_event(ev: dict[str, Any]) -> None:
            nonlocal completed_count, passed_modules, failed_modules
            nonlocal total_tests_run, total_skipped, total_expected_failures
            nonlocal slowest_name, slowest_elapsed
            mod_name = str(ev["module"])
            tests_run = int(ev["testsRun"])
            mod_elapsed = float(ev["elapsed"])
            mod_failures = [(str(tid), str(err)) for tid, err in ev.get("failures", [])]
            mod_errors = [(str(tid), str(err)) for tid, err in ev.get("errors", [])]
            mod_unexpected = [str(tid) for tid in ev.get("unexpectedSuccesses", [])]
            with lock:
                completed_count += 1
                idx = completed_count
                total_tests_run += tests_run
                total_skipped += int(ev.get("skipped", 0))
                total_expected_failures += int(ev.get("expectedFailures", 0))
                all_failures.extend(mod_failures)
                all_errors.extend(mod_errors)
                all_unexpected_successes.extend(mod_unexpected)
                if mod_elapsed >= slowest_elapsed:
                    slowest_elapsed = mod_elapsed
                    slowest_name = mod_name
                mod_failed = bool(mod_failures or mod_errors or mod_unexpected)
                if mod_failed:
                    failed_modules += 1
                    print(
                        f"[FAIL] {mod_name} ({tests_run} tests, "
                        f"{len(mod_failures)} failures, {len(mod_errors)} errors, "
                        f"{mod_elapsed:.2f}s)",
                        flush=True,
                    )
                    if fail_fast:
                        stop_event.set()
                        for proc in list(active_procs):
                            if proc.poll() is None:
                                proc.terminate()
                else:
                    passed_modules += 1
                    if slow_threshold > 0 and mod_elapsed >= slow_threshold:
                        print(
                            f"[slow] {mod_name} ({tests_run} tests, {mod_elapsed:.2f}s)",
                            flush=True,
                        )
                if idx % interval == 0 or idx == total_modules:
                    total_elapsed = time.monotonic() - started
                    status = "PASS" if failed_modules == 0 else "FAIL"
                    slowest_part = (
                        f" | slowest: {slowest_name} ({slowest_elapsed:.2f}s)"
                        if slowest_name
                        else ""
                    )
                    print(
                        f"[{idx:>{width}}/{total_modules}] {status} "
                        f"{passed_modules}/{idx} modules ({total_tests_run} tests) | "
                        f"{total_elapsed:.1f}s elapsed{slowest_part}",
                        flush=True,
                    )

        def _run_shard(shard_idx: int, shard_modules: list[str], tmp_dir: Path) -> None:
            modules_file = tmp_dir / f"shard_{shard_idx}.json"
            modules_file.write_text(json.dumps(shard_modules), encoding="utf-8")
            cmd = [
                sys.executable,
                "-m",
                "tools.semantic_harness.testing.compact_unittest",
                "-s",
                str(start_path),
                "-p",
                pattern,
                "--exact-modules-file",
                str(modules_file),
                "--shard-jsonl",
            ]
            if top_level_dir is not None:
                cmd.extend(["-t", str(top_level_dir)])
            if fail_fast:
                cmd.append("--fail-fast")
            reported: set[str] = set()
            stderr_text = ""
            rc = 0
            with subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=env,
            ) as proc:
                with lock:
                    active_procs.append(proc)
                assert proc.stdout is not None
                for raw_line in proc.stdout:
                    if raw_line.startswith(_SHARD_EVENT_PREFIX):
                        ev = json.loads(raw_line[len(_SHARD_EVENT_PREFIX):])
                        reported.add(str(ev["module"]))
                        _record_module_event(ev)
                stderr_text = proc.stderr.read() if proc.stderr is not None else ""
                rc = proc.wait()
            if rc != 0 and not stop_event.is_set():
                missing = [m for m in shard_modules if m not in reported]
                if missing or (not reported):
                    detail = stderr_text.strip() or f"shard exited with status {rc}"
                    target_mod = missing[0] if missing else shard_modules[0]
                    _record_module_event(
                        {
                            "module": target_mod,
                            "testsRun": 0,
                            "skipped": 0,
                            "expectedFailures": 0,
                            "elapsed": 0.0,
                            "failures": [],
                            "errors": [[f"{target_mod}.<shard>", detail]],
                            "unexpectedSuccesses": [],
                        }
                    )

        with tempfile.TemporaryDirectory() as tmp_dir_str:
            tmp_dir = Path(tmp_dir_str)
            with ThreadPoolExecutor(max_workers=len(shards)) as pool:
                futures = [
                    pool.submit(_run_shard, shard_idx, shard_mods, tmp_dir)
                    for shard_idx, shard_mods in enumerate(shards)
                ]
                for future in as_completed(futures):
                    future.result()
    else:
        try:
            for idx, (mod_name, suite) in enumerate(module_suites, 1):
                mod_started = time.monotonic()
                if verbose:
                    stream: Any = _FlushingTextStream(sys.stdout)
                    verbosity = 2
                else:
                    stream = io.StringIO()
                    verbosity = 0
                result = unittest.TextTestResult(stream, descriptions=True, verbosity=verbosity)
                result.failfast = bool(fail_fast)
                result.startTestRun()
                try:
                    suite(result)
                finally:
                    result.stopTestRun()
                mod_elapsed = time.monotonic() - mod_started

                total_tests_run += result.testsRun
                total_skipped += len(result.skipped)
                total_expected_failures += len(result.expectedFailures)
                all_failures.extend(result.failures)
                all_errors.extend(result.errors)
                all_unexpected_successes.extend(result.unexpectedSuccesses)

                if mod_elapsed >= slowest_elapsed:
                    slowest_elapsed = mod_elapsed
                    slowest_name = mod_name

                mod_failed = (
                    len(result.failures) > 0
                    or len(result.errors) > 0
                    or len(result.unexpectedSuccesses) > 0
                )
                if mod_failed:
                    failed_modules += 1
                    print(
                        f"[FAIL] {mod_name} ({result.testsRun} tests, "
                        f"{len(result.failures)} failures, {len(result.errors)} errors, "
                        f"{mod_elapsed:.2f}s)",
                        flush=True,
                    )
                else:
                    passed_modules += 1
                    if not verbose and slow_threshold > 0 and mod_elapsed >= slow_threshold:
                        print(
                            f"[slow] {mod_name} ({result.testsRun} tests, {mod_elapsed:.2f}s)",
                            flush=True,
                        )

                if not verbose and (idx % interval == 0 or idx == total_modules):
                    total_elapsed = time.monotonic() - started
                    status = "PASS" if failed_modules == 0 else "FAIL"
                    slowest_part = (
                        f" | slowest: {slowest_name} ({slowest_elapsed:.2f}s)"
                        if slowest_name
                        else ""
                    )
                    print(
                        f"[{idx:>{width}}/{total_modules}] {status} "
                        f"{passed_modules}/{idx} modules ({total_tests_run} tests) | "
                        f"{total_elapsed:.1f}s elapsed{slowest_part}",
                        flush=True,
                    )

                if fail_fast and mod_failed:
                    break
        finally:
            _cleanup_warm_workers()

    total_elapsed = time.monotonic() - started

    if all_failures or all_errors or all_unexpected_successes:
        print("", flush=True)
        for line in _format_failure_blocks("ERROR", all_errors):
            print(line, flush=True)
        for line in _format_failure_blocks("FAIL", all_failures):
            print(line, flush=True)
        if all_unexpected_successes:
            print("=" * 70, flush=True)
            for test in all_unexpected_successes:
                test_id = test if isinstance(test, str) else test.id()
                print(f"UNEXPECTED SUCCESS: {test_id}", flush=True)

    print("-" * 70, flush=True)
    test_word = "test" if total_tests_run == 1 else "tests"
    print(f"Ran {total_tests_run} {test_word} in {total_elapsed:.3f}s\n", flush=True)

    infos: list[str] = []
    ok = (
        len(all_failures) == 0
        and len(all_errors) == 0
        and len(all_unexpected_successes) == 0
    )
    if not ok:
        if all_failures:
            infos.append(f"failures={len(all_failures)}")
        if all_errors:
            infos.append(f"errors={len(all_errors)}")
        if all_unexpected_successes:
            infos.append(f"unexpected successes={len(all_unexpected_successes)}")
    if total_skipped:
        infos.append(f"skipped={total_skipped}")
    if total_expected_failures:
        infos.append(f"expected failures={total_expected_failures}")

    suffix = f" ({', '.join(infos)})" if infos else ""
    print(f"{'OK' if ok else 'FAILED'}{suffix}", flush=True)
    return 0 if ok else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compact live-flushed unittest discovery runner.",
        prog="python -m tools.semantic_harness.testing.compact_unittest",
    )
    parser.add_argument(
        "-s",
        "--start-dir",
        default=".",
        help="directory to start discovery (default: '.')",
    )
    parser.add_argument(
        "-p",
        "--pattern",
        default="test_*.py",
        help="pattern to match test files (default: 'test_*.py')",
    )
    parser.add_argument(
        "-t",
        "--top-level-dir",
        default=None,
        help="top level directory of project (defaults to start directory)",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=10,
        help="emit flushed heartbeat summary every N modules (default: 10)",
    )
    parser.add_argument(
        "--slow-threshold",
        type=float,
        default=2.0,
        help="immediately log [slow] when a module meets/exceeds N seconds (default: 2.0)",
    )
    parser.add_argument(
        "--fail-fast",
        "-f",
        action="store_true",
        help="stop on first failure or error",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="stream per-test unittest output live",
    )
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=1,
        help="number of parallel shard processes (GUI modules stay serialized in one shard)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        dest="list_only",
        help="list discovered modules and test counts without running",
    )
    parser.add_argument(
        "--exact-modules-file",
        default=None,
        help=argparse.SUPPRESS,
    )
    parser.add_argument(
        "--shard-jsonl",
        action="store_true",
        help=argparse.SUPPRESS,
    )
    parser.add_argument(
        "filters",
        nargs="*",
        help="optional case-insensitive module name filters",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    exact_modules: tuple[str, ...] = ()
    if args.exact_modules_file:
        exact_modules = tuple(
            json.loads(Path(args.exact_modules_file).read_text(encoding="utf-8"))
        )
    return run_compact_unittest(
        start_dir=args.start_dir,
        pattern=args.pattern,
        top_level_dir=args.top_level_dir,
        progress_every=args.progress_every,
        slow_threshold=args.slow_threshold,
        fail_fast=args.fail_fast,
        verbose=args.verbose,
        list_only=args.list_only,
        jobs=args.jobs,
        filters=args.filters,
        exact_modules=exact_modules,
        shard_jsonl=args.shard_jsonl,
    )


if __name__ == "__main__":
    raise SystemExit(main())
