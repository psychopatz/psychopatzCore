"""Duplicate-case and fixture schema linter for declarative semantic tests."""

from __future__ import annotations

import argparse
import sys
from collections import defaultdict
from pathlib import Path
from typing import Sequence

from .loader import SemanticCase, discover_cases
from .resolver import FixtureResolutionError, resolve_fixture_roots
from .schema import validate_case, validate_fixture_document


def lint_fixtures(
    fixtures_dir: Path | Sequence[Path],
) -> dict[str, object]:
    """Lint all fixture documents under directory(s) for schema violations and duplicate cases."""
    results: dict[str, object] = {
        "ok": True,
        "files_checked": 0,
        "cases_checked": 0,
        "duplicate_ids": [],
        "duplicate_utterance_cases": [],
        "schema_errors": [],
    }

    dirs = [fixtures_dir] if isinstance(fixtures_dir, Path) else list(fixtures_dir)
    files: list[Path] = []
    seen_files: set[Path] = set()
    for root in dirs:
        for f in sorted(root.rglob("*.json")):
            resolved = f.resolve()
            if resolved not in seen_files:
                seen_files.add(resolved)
                files.append(f)
    results["files_checked"] = len(files)

    seen_ids: dict[str, Path] = {}
    utterance_map: dict[tuple[str, ...], list[str]] = defaultdict(list)

    all_cases: list[SemanticCase] = []

    for f in files:
        try:
            cases = discover_cases([f])
            for c in cases:
                results["cases_checked"] = int(results["cases_checked"]) + 1
                if c.case_id in seen_ids:
                    results["duplicate_ids"].append({
                        "case_id": c.case_id,
                        "file_1": str(seen_ids[c.case_id]),
                        "file_2": str(f),
                    })
                    results["ok"] = False
                seen_ids[c.case_id] = f

                # Check for identical multi-turn inputs across same suite
                inputs = tuple(
                    t.get("text") or t.get("rootChoice") or ""
                    for t in c.turns
                    if t.get("text") or t.get("rootChoice")
                )
                if inputs:
                    key = (c.suite, *inputs)
                    utterance_map[key].append(c.case_id)

        except Exception as exc:
            results["schema_errors"].append({
                "file": str(f),
                "error": str(exc),
            })
            results["ok"] = False

    # Check for duplicate utterance combinations in the same suite with identical scenario
    for (suite, *inputs), c_ids in utterance_map.items():
        if len(c_ids) > 1:
            # Only flag if not a matrix variant
            non_matrix_ids = [cid for cid in c_ids if "[" not in cid]
            if len(non_matrix_ids) > 1:
                results["duplicate_utterance_cases"].append({
                    "suite": suite,
                    "inputs": list(inputs),
                    "case_ids": non_matrix_ids,
                })

    return results


def run_linter_cli(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lint declarative semantic test fixtures.")
    parser.add_argument(
        "--fixtures-dir",
        type=Path,
        default=None,
        help="fixtures directory to lint (defaults to active provider semantic fixture root)",
    )
    parser.add_argument("--repository", type=Path, default=None)
    parser.add_argument("--core-repository", type=Path, default=None)
    parser.add_argument("--provider-root", action="append", dest="provider_roots")
    parser.add_argument("--preset", default=None)
    parser.add_argument("--mods", action="append", default=None)
    args = parser.parse_args(argv)

    mods = (
        tuple(
            item.strip()
            for value in (args.mods or ())
            for item in str(value).split(",")
            if item.strip()
        )
        or None
    )
    try:
        roots = resolve_fixture_roots(
            kind="semantic",
            explicit_dir=args.fixtures_dir,
            repository=args.repository,
            core_repository=args.core_repository,
            provider_roots=tuple(args.provider_roots or ()),
            mods=mods,
            preset=args.preset,
        )
    except FixtureResolutionError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    report = lint_fixtures(roots)
    print(f"Linted {report['files_checked']} files, {report['cases_checked']} cases.")

    if not report["ok"]:
        print("Lint FAILED with errors:", file=sys.stderr)
        for err in report["schema_errors"]:
            print(f"  Schema error in {err['file']}: {err['error']}", file=sys.stderr)
        for dup in report["duplicate_ids"]:
            print(f"  Duplicate case ID '{dup['case_id']}' in {dup['file_1']} and {dup['file_2']}", file=sys.stderr)
        for dup_ut in report["duplicate_utterance_cases"]:
            print(f"  Duplicate inputs {dup_ut['inputs']} in suite '{dup_ut['suite']}': {dup_ut['case_ids']}", file=sys.stderr)
        return 1

    print("All fixtures passed schema and duplicate-case linting cleanly.")
    return 0


if __name__ == "__main__":
    sys.exit(run_linter_cli())
