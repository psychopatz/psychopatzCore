"""Command-line interface for running declarative semantic test fixtures."""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import Sequence

from .executor import CaseResult, execute_case
from .loader import SemanticCase, discover_cases, load_cases_from_file
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
    filtered: list[SemanticCase] = []
    filter_terms = [f.casefold() for f in args.filters]

    for c in cases:
        if args.suite and c.suite != args.suite:
            continue
        if args.case and c.case_id != args.case:
            continue
        if args.tags:
            c_tags = set(c.tags)
            if not any(t in c_tags for t in args.tags):
                continue
        if filter_terms:
            matched = any(
                term in c.case_id.casefold()
                or term in c.suite.casefold()
                or any(term in t.casefold() for t in c.tags)
                for term in filter_terms
            )
            if not matched:
                continue
        filtered.append(c)

    if not filtered:
        print("No semantic test cases matched the specified criteria.", file=sys.stderr)
        return 0

    if args.list:
        print(f"Discovered {len(filtered)} matching test case(s):")
        for c in filtered:
            tags_str = f" [{', '.join(c.tags)}]" if c.tags else ""
            print(f"  - {c.case_id} (suite: {c.suite}){tags_str}")
        return 0

    # 3. Execute cases
    print(f"Running {len(filtered)} semantic test case(s)...")
    total_start = time.monotonic()
    passed_count = 0
    failed_count = 0
    results: list[CaseResult] = []

    for c in filtered:
        res = execute_case(c)
        results.append(res)
        print(res.summary())
        if res.passed:
            passed_count += 1
        else:
            failed_count += 1
            if args.verbose or True:
                for f in res.failures:
                    print(f"    FAILURE: {f.message}")
                for conf in res.conflicts:
                    print(f"    CONFLICT: {conf}")
                if res.error:
                    print(f"    ERROR: {res.error}")
            if args.fail_fast:
                break

    total_time = time.monotonic() - total_start
    print(f"\nSEMANTIC TESTS: PASS {passed_count}, FAIL {failed_count}, TOTAL {len(results)} in {total_time:.2f}s")

    return 0 if failed_count == 0 else 1


if __name__ == "__main__":
    sys.exit(run_cli())
