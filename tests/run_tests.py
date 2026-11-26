#!/usr/bin/env python3
"""Parallel, failure-focused runner for isolated PsychopatzCore Lua smoke tests."""

from __future__ import annotations

import argparse
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"
sys.path.insert(0, str(ROOT))

from tools.semantic_harness.runtime.config import discover_newest_runtime
from tools.semantic_harness.testing.suite import (
    BoundedLuaTestRunner,
    install_suite_shutdown_handler,
)


@dataclass(frozen=True)
class Result:
    path: Path
    returncode: int
    output: str
    elapsed: float


def test_environment(verbose: bool) -> dict[str, str]:
    environment = os.environ.copy()
    environment.update({
        "PZ_TEST_CORE_REPOSITORY": str(ROOT),
        "PZ_TEST_CORE_RUNTIME": discover_newest_runtime(
            ROOT / "Contents/mods/PsychopatzCore"
        ),
        "PZ_TEST_VERBOSE": "1" if verbose else "0",
    })
    return environment


def discover(filters: list[str]) -> list[Path]:
    tests = sorted(TESTS.glob("*_smoke.lua"))
    if filters:
        lowered = [value.casefold() for value in filters]
        tests = [
            path
            for path in tests
            if any(value in path.stem.casefold() for value in lowered)
        ]
    return tests


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filters", nargs="*", help="Substring filters on test stems")
    parser.add_argument("--jobs", type=int, default=min(8, os.cpu_count() or 4))
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    tests = discover(args.filters)
    if not tests:
        print("No matching PsychopatzCore Lua smoke tests found.")
        return 1

    env = test_environment(args.verbose)
    runner = BoundedLuaTestRunner(ROOT)
    install_suite_shutdown_handler()

    started = time.monotonic()
    failures: list[Result] = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        futures = {
            pool.submit(runner.run_one, path, env, args.timeout): path
            for path in tests
        }
        for future in as_completed(futures):
            path = futures[future]
            bounded = future.result()
            res = Result(path, bounded.returncode, bounded.output, bounded.elapsed)
            if res.returncode != 0:
                failures.append(res)
            elif args.verbose:
                print(f"PASS {path.name} ({res.elapsed:.2f}s)")

    elapsed = time.monotonic() - started
    passed = len(tests) - len(failures)
    print(
        f"PsychopatzCore Lua tests: {passed}/{len(tests)} passed "
        f"({len(failures)} failed) in {elapsed:.2f}s"
    )
    for fail in sorted(failures, key=lambda item: item.path.name):
        print(f"\n--- FAIL {fail.path.name} (rc={fail.returncode}) ---")
        print(fail.output.strip()[-1500:])
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
