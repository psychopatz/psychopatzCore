"""Command-line interface for running declarative semantic test fixtures."""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import Sequence

from .executor import (
    CaseResult,
    execute_cases,
    execute_cases_batch,
    execute_cases_parallel,
)
from .loader import (
    SemanticCase,
    discover_cases,
    discover_domains,
    filter_cases,
    load_cases_from_file,
)
from .resolver import FixtureResolutionError, resolve_fixture_roots


def _parse_mods(values: Sequence[str] | None) -> tuple[str, ...] | None:
    if not values:
        return None
    parsed = tuple(
        item.strip()
        for value in values
        for item in str(value).split(",")
        if item.strip()
    )
    return parsed or None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Declarative, production-Lua-backed Semantic Test runner.",
        prog="python -m tools.semantic_harness.testing.cli",
    )
    parser.add_argument(
        "filters",
        nargs="*",
        help="case ID, suite, or tag filters (case-insensitive substring match)",
    )
    parser.add_argument(
        "--domain",
        help="filter by semantic domain (e.g. knowledge, beats, compiler)",
    )
    parser.add_argument(
        "--semantic-id",
        help="filter by semantic ID / source record ID",
    )
    parser.add_argument(
        "--suite",
        help="filter by exact suite name",
    )
    parser.add_argument(
        "--case",
        help="filter by exact case ID",
    )
    parser.add_argument(
        "--tag",
        action="append",
        dest="tags",
        help="filter by tag (repeatable)",
    )
    parser.add_argument(
        "--file",
        action="append",
        dest="files",
        help="specific fixture file path to execute (repeatable)",
    )
    parser.add_argument(
        "--fixtures-dir",
        type=Path,
        default=None,
        help="directory to scan for fixture JSON files (defaults to active provider fixture root)",
    )
    parser.add_argument(
        "--repository",
        type=Path,
        default=None,
        help="active provider repository path",
    )
    parser.add_argument(
        "--core-repository",
        type=Path,
        default=None,
        help="PsychopatzCore repository path",
    )
    parser.add_argument(
        "--provider-root",
        action="append",
        dest="provider_roots",
        help="additional provider manifest root directory (repeatable)",
    )
    parser.add_argument(
        "--preset",
        default=None,
        help="provider selection preset",
    )
    parser.add_argument(
        "--mods",
        action="append",
        default=None,
        help="explicit provider IDs to activate (comma-separated or repeatable)",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="stop immediately after the first failure",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="list matching cases without executing",
    )
    parser.add_argument(
        "--list-domains",
        action="store_true",
        help="list discovered domains and case counts without executing",
    )
    parser.add_argument(
        "--batch-state",
        type=Path,
        default=None,
        help="optional JSON batch state file for cancel/resume execution",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=32,
        help="batch chunk size when running with --batch-state",
    )
    parser.add_argument(
        "--jobs",
        "-j",
        type=int,
        default=1,
        help="number of parallel warm-worker shards to run",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="print detailed failure traces and turn results",
    )
    return parser


def run_cli(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    # 1. Discover cases
    cases: list[SemanticCase] = []
    if args.files:
        for f in args.files:
            p = Path(f).resolve()
            if not p.is_file():
                print(f"Error: Fixture file not found: {f}", file=sys.stderr)
                return 1
            cases.extend(load_cases_from_file(p))
    else:
        try:
            roots = resolve_fixture_roots(
                kind="semantic",
                explicit_dir=args.fixtures_dir,
                repository=args.repository,
                core_repository=args.core_repository,
                provider_roots=tuple(args.provider_roots or ()),
                mods=_parse_mods(args.mods),
                preset=args.preset,
            )
        except FixtureResolutionError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1
        cases.extend(discover_cases(roots))

    # 2. Filter cases
    filtered = filter_cases(
        cases,
        domain=args.domain,
        suite=args.suite,
        case_id=args.case,
        tags=args.tags,
        semantic_id=args.semantic_id,
        filters=args.filters,
    )

    if args.list_domains:
        domain_counts = discover_domains(filtered)
        print(f"Discovered {len(domain_counts)} domain(s) across {len(filtered)} case(s):")
        for dom, count in domain_counts.items():
            print(f"  - {dom}: {count}")
        return 0

    if not filtered:
        print("No semantic test cases matched the specified criteria.", file=sys.stderr)
        return 0

    if args.list:
        print(f"Discovered {len(filtered)} matching test case(s):")
        for c in filtered:
            dom_str = f", domain: {c.domain}" if c.domain else ""
            tags_str = f" [{', '.join(c.tags)}]" if c.tags else ""
            print(f"  - {c.case_id} (suite: {c.suite}{dom_str}){tags_str}")
        return 0

    # 3. Execute cases
    print(f"Running {len(filtered)} semantic test case(s)...")
    total_start = time.monotonic()
    passed_count = 0
    failed_count = 0
    results: list[CaseResult] = []

    worker_kwargs: dict[str, Path] = {}
    if args.repository is not None:
        worker_kwargs["repository"] = args.repository
    if args.core_repository is not None:
        worker_kwargs["core_repository"] = args.core_repository

    if args.batch_state is not None:
        batch_res = execute_cases_batch(
            filtered,
            batch_size=args.batch_size,
            state_file=args.batch_state,
            fail_fast=args.fail_fast,
            **worker_kwargs,
        )
        results.extend(batch_res.results)
        for res in results:
            print(res.summary())
            if not res.passed:
                for f in res.failures:
                    print(f"    FAILURE: {f.message}")
                for conf in res.conflicts:
                    print(f"    CONFLICT: {conf}")
                if res.error:
                    print(f"    ERROR: {res.error}")
        passed_count = batch_res.passed_count
        failed_count = batch_res.failed_count
        if batch_res.skipped_ids:
            print(f"Resumed batch: skipped {len(batch_res.skipped_ids)} already-completed case(s).")
    else:
        def _print_result(res: CaseResult) -> None:
            print(res.summary())
            if not res.passed:
                for f in res.failures:
                    print(f"    FAILURE: {f.message}")
                for conf in res.conflicts:
                    print(f"    CONFLICT: {conf}")
                if res.error:
                    print(f"    ERROR: {res.error}")

        if args.jobs > 1 and not args.fail_fast:
            results = execute_cases_parallel(
                filtered,
                jobs=args.jobs,
                fail_fast=args.fail_fast,
                **worker_kwargs,
            )
            for res in results:
                _print_result(res)
                if res.passed:
                    passed_count += 1
                else:
                    failed_count += 1
        else:
            def _on_progress(res: CaseResult, _idx: int, _total: int) -> None:
                nonlocal passed_count, failed_count
                _print_result(res)
                if res.passed:
                    passed_count += 1
                else:
                    failed_count += 1

            results = execute_cases(
                filtered,
                fail_fast=args.fail_fast,
                progress_callback=_on_progress,
                **worker_kwargs,
            )

    total_time = time.monotonic() - total_start
    print(f"\nSEMANTIC TESTS: PASS {passed_count}, FAIL {failed_count}, TOTAL {len(results)} in {total_time:.2f}s")

    return 0 if failed_count == 0 else 1


if __name__ == "__main__":
    sys.exit(run_cli())
