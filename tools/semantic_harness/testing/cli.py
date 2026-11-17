"""Command-line interface for running declarative semantic test fixtures."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, Sequence

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
        "--compact",
        action="store_true",
        help="print compact domain-level live progress (default unless --verbose)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="print detailed per-case lines, failure traces, and turn results",
    )
    return parser


def _case_group_key_and_label(index: int, case: SemanticCase) -> tuple[tuple[str, Any], str]:
    if case.domain:
        return (("domain", case.domain), f"domain={case.domain}")
    chunk_num = (index // 10) + 1
    return (("chunk", chunk_num), f"chunk={chunk_num}")


def _print_case_result(res: CaseResult) -> None:
    print(res.summary(), flush=True)
    if not res.passed:
        for f in res.failures:
            print(f"    FAILURE: {f.message}", flush=True)
        for conf in res.conflicts:
            print(f"    CONFLICT: {conf}", flush=True)
        if res.error:
            print(f"    ERROR: {res.error}", flush=True)


def _load_completed_batch_ids(state_file: Path | None) -> set[str]:
    if state_file is None or not state_file.is_file():
        return set()
    try:
        saved = json.loads(state_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return set()
    if isinstance(saved, dict) and isinstance(saved.get("completed"), dict):
        return {str(k) for k in saved["completed"]}
    return set()


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
    print(f"Running {len(filtered)} semantic test case(s)...", flush=True)
    total_start = time.monotonic()
    passed_count = 0
    failed_count = 0
    results: list[CaseResult] = []
    compact_mode = bool(args.compact) or not bool(args.verbose)

    worker_kwargs: dict[str, Path] = {}
    if args.repository is not None:
        worker_kwargs["repository"] = args.repository
    if args.core_repository is not None:
        worker_kwargs["core_repository"] = args.core_repository

    completed_batch_ids = (
        _load_completed_batch_ids(args.batch_state)
        if args.batch_state is not None
        else set()
    )
    progress_cases = (
        [c for c in filtered if c.case_id not in completed_batch_ids]
        if args.batch_state is not None
        else filtered
    )
    group_totals: dict[tuple[str, Any], int] = {}
    group_labels: dict[tuple[str, Any], str] = {}
    case_group_by_id: dict[int, tuple[str, Any]] = {}
    for idx, case in enumerate(progress_cases):
        gkey, glabel = _case_group_key_and_label(idx, case)
        group_totals[gkey] = group_totals.get(gkey, 0) + 1
        group_labels[gkey] = glabel
        case_group_by_id[id(case)] = gkey

    total_groups = len(group_totals)
    group_width = max(1, len(str(total_groups)))
    completed_groups = 0
    group_stats: dict[tuple[str, Any], dict[str, Any]] = {
        gkey: {"completed": 0, "passed": 0, "failed": 0, "duration": 0.0}
        for gkey in group_totals
    }

    def _on_progress(res: CaseResult, _idx: int, _total: int) -> None:
        nonlocal passed_count, failed_count, completed_groups
        if res.passed:
            passed_count += 1
        else:
            failed_count += 1
        if not compact_mode:
            _print_case_result(res)
            return
        if not res.passed:
            _print_case_result(res)
        gkey = case_group_by_id.get(id(res.case))
        if gkey is None:
            return
        stats = group_stats[gkey]
        stats["completed"] += 1
        if res.passed:
            stats["passed"] += 1
        else:
            stats["failed"] += 1
        stats["duration"] += res.duration
        if stats["completed"] >= group_totals[gkey]:
            completed_groups += 1
            status = "PASS" if stats["failed"] == 0 else "FAIL"
            label = group_labels[gkey]
            if stats["failed"] == 0:
                count_text = f"{stats['passed']}/{group_totals[gkey]} cases"
            else:
                count_text = (
                    f"{stats['passed']}/{group_totals[gkey]} passed, "
                    f"{stats['failed']} failed"
                )
            print(
                f"[{completed_groups:>{group_width}}/{total_groups}] {status} {label} "
                f"({count_text}, {stats['duration']:.2f}s)",
                flush=True,
            )

    if args.batch_state is not None:
        batch_res = execute_cases_batch(
            filtered,
            batch_size=args.batch_size,
            state_file=args.batch_state,
            fail_fast=args.fail_fast,
            progress_callback=_on_progress,
            **worker_kwargs,
        )
        results.extend(batch_res.results)
        passed_count = batch_res.passed_count
        failed_count = batch_res.failed_count
        if batch_res.skipped_ids:
            print(
                f"Resumed batch: skipped {len(batch_res.skipped_ids)} already-completed case(s).",
                flush=True,
            )
    else:
        if args.jobs > 1 and not args.fail_fast:
            results = execute_cases_parallel(
                filtered,
                jobs=args.jobs,
                fail_fast=args.fail_fast,
                progress_callback=_on_progress,
                **worker_kwargs,
            )
        else:
            results = execute_cases(
                filtered,
                fail_fast=args.fail_fast,
                progress_callback=_on_progress,
                **worker_kwargs,
            )

    total_time = time.monotonic() - total_start
    print(
        f"\nSEMANTIC TESTS: PASS {passed_count}, FAIL {failed_count}, TOTAL {len(results)} in {total_time:.2f}s",
        flush=True,
    )

    return 0 if failed_count == 0 else 1


if __name__ == "__main__":
    sys.exit(run_cli())
