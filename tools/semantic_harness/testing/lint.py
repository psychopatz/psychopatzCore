"""Duplicate-case, naming, and fixture schema linter for declarative semantic tests."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Sequence

from .loader import SemanticCase, discover_cases
from .resolver import FixtureResolutionError, resolve_fixture_roots

FORBIDDEN_HISTORY_TOKEN_RE = re.compile(
    r"(?:^|[._/\-])("
    r"[cbhrsg]\d+(?:[a-z]+\d*)*|"
    r"[el]\d+|"
    r"a[12](?:[a-z]+\d*)*|a\d+r\d+[a-z0-9]*|"
    r"(?:phase|batch|part)\d+[a-z0-9]*|"
    r"pilot|legacy|compat|old"
    r")(?=$|[._/\-])",
    re.IGNORECASE,
)


def _find_history_tokens(value: str) -> list[str]:
    return sorted({m.group(1).lower() for m in FORBIDDEN_HISTORY_TOKEN_RE.finditer(value)})


def _normalized_stimulus(case: SemanticCase) -> str:
    turns_norm = [
        {
            "text": t.get("text"),
            "action": t.get("action"),
            "payload": t.get("payload"),
            "rootChoice": t.get("rootChoice"),
            "suggestionClick": t.get("suggestionClick"),
            "language": t.get("language"),
        }
        for t in case.turns
    ]
    return json.dumps(
        {"scenario": case.scenario, "turns": turns_norm},
        sort_keys=True,
        ensure_ascii=False,
    )


def _normalized_case_signature(case: SemanticCase) -> str:
    turns_norm = [
        {
            "text": t.get("text"),
            "action": t.get("action"),
            "payload": t.get("payload"),
            "rootChoice": t.get("rootChoice"),
            "suggestionClick": t.get("suggestionClick"),
            "language": t.get("language"),
            "expect": t.get("expect"),
        }
        for t in case.turns
    ]
    return json.dumps(
        {"scenario": case.scenario, "turns": turns_norm},
        sort_keys=True,
        ensure_ascii=False,
    )


def lint_fixtures(
    fixtures_dir: Path | Sequence[Path],
    *,
    enforce_naming: bool = True,
) -> dict[str, Any]:
    """Lint fixture documents for schema errors, duplicates, overlaps, and naming."""
    results: dict[str, Any] = {
        "ok": True,
        "files_checked": 0,
        "cases_checked": 0,
        "duplicate_ids": [],
        "duplicate_utterance_cases": [],
        "exact_duplicates": [],
        "stimulus_overlaps": [],
        "naming_violations": [],
        "domain_path_mismatches": [],
        "schema_errors": [],
    }

    dirs = [fixtures_dir] if isinstance(fixtures_dir, Path) else list(fixtures_dir)
    files: list[tuple[Path, Path]] = []
    seen_files: set[Path] = set()
    for root in dirs:
        resolved_root = root.resolve()
        for f in sorted(resolved_root.rglob("*.json")):
            resolved = f.resolve()
            if resolved not in seen_files:
                seen_files.add(resolved)
                files.append((resolved_root, f))
    results["files_checked"] = len(files)

    seen_ids: dict[str, Path] = {}
    utterance_map: dict[tuple[str, ...], list[str]] = defaultdict(list)
    exact_sig_map: dict[str, list[dict[str, str]]] = defaultdict(list)
    stimulus_map: dict[str, list[dict[str, str]]] = defaultdict(list)

    for root, f in files:
        rel_path = f.relative_to(root).as_posix()
        top_dir = f.relative_to(root).parts[0] if len(f.relative_to(root).parts) > 1 else None
        if enforce_naming:
            path_tokens = _find_history_tokens(rel_path)
            if path_tokens:
                results["naming_violations"].append({
                    "kind": "path",
                    "target": rel_path,
                    "tokens": path_tokens,
                })
                results["ok"] = False

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

                if enforce_naming:
                    for kind, val in (("suite", c.suite), ("case_id", c.case_id)):
                        tokens = _find_history_tokens(val)
                        if tokens:
                            results["naming_violations"].append({
                                "kind": kind,
                                "target": val,
                                "file": rel_path,
                                "tokens": tokens,
                            })
                            results["ok"] = False
                    if top_dir and c.domain and top_dir != c.domain:
                        results["domain_path_mismatches"].append({
                            "file": rel_path,
                            "top_dir": top_dir,
                            "domain": c.domain,
                            "case_id": c.case_id,
                        })
                        results["ok"] = False

                # Global exact-duplicate and stimulus-overlap tracking
                sig = _normalized_case_signature(c)
                exact_sig_map[sig].append({
                    "case_id": c.case_id,
                    "suite": c.suite,
                    "domain": c.domain or "",
                    "file": rel_path,
                })
                stim = _normalized_stimulus(c)
                stimulus_map[stim].append({
                    "case_id": c.case_id,
                    "suite": c.suite,
                    "domain": c.domain or "",
                    "file": rel_path,
                })

                # Same-suite utterance check
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

    for (suite, *inputs), c_ids in utterance_map.items():
        if len(c_ids) > 1:
            non_matrix_ids = [cid for cid in c_ids if "[" not in cid]
            if len(non_matrix_ids) > 1:
                results["duplicate_utterance_cases"].append({
                    "suite": suite,
                    "inputs": list(inputs),
                    "case_ids": non_matrix_ids,
                })

    for entries in exact_sig_map.values():
        if len(entries) > 1:
            results["exact_duplicates"].append(entries)
            results["ok"] = False

    for entries in stimulus_map.values():
        if len(entries) > 1:
            results["stimulus_overlaps"].append(entries[:8])

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
    parser.add_argument("--show-overlaps", action="store_true", help="print cross-case stimulus overlaps")
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
    print(
        f"Linted {report['files_checked']} files, {report['cases_checked']} cases "
        f"({len(report['stimulus_overlaps'])} stimulus overlap group(s))."
    )

    if args.show_overlaps and report["stimulus_overlaps"]:
        print("Stimulus overlap groups (informational):")
        for group in report["stimulus_overlaps"][:20]:
            summary = ", ".join(f"{item['case_id']} ({item['domain'] or item['suite']})" for item in group)
            print(f"  - {summary}")

    if not report["ok"]:
        print("Lint FAILED with errors:", file=sys.stderr)
        for err in report["schema_errors"]:
            print(f"  Schema error in {err['file']}: {err['error']}", file=sys.stderr)
        for dup in report["duplicate_ids"]:
            print(f"  Duplicate case ID '{dup['case_id']}' in {dup['file_1']} and {dup['file_2']}", file=sys.stderr)
        for dup_group in report["exact_duplicates"]:
            ids = ", ".join(f"{e['case_id']} ({e['file']})" for e in dup_group)
            print(f"  Global exact duplicate case(s): {ids}", file=sys.stderr)
        for nv in report["naming_violations"][:20]:
            print(f"  History/milestone naming violation ({nv['kind']}): {nv['target']} {nv['tokens']}", file=sys.stderr)
        for dm in report["domain_path_mismatches"][:20]:
            print(f"  Domain/path mismatch in {dm['file']}: dir '{dm['top_dir']}' != domain '{dm['domain']}'", file=sys.stderr)
        return 1

    print("All fixtures passed schema, naming, and duplicate-case linting cleanly.")
    return 0


if __name__ == "__main__":
    sys.exit(run_linter_cli())
