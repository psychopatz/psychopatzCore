"""Unified multi-suite developer acceptance orchestration."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
    audit_convo_engine_workspace,
)
from tools.semantic_harness.kahlua_verifier.verify import (
    MAX_LUA_FILES,
    run_check as run_kahlua_check,
)
from tools.semantic_harness.runtime.config import discover_newest_runtime
from tools.semantic_harness.testing.python_runner import PythonAcceptanceRunner
from tools.semantic_harness.testing.suite import run_lua_suite

CORE_REPOSITORY = Path(__file__).resolve().parents[3]

REQUIRED_SUITES: tuple[str, ...] = (
    "core_python",
    "core_lua",
    "hoomans_lua",
    "hoomans_provider_python",
    "real_provider_worker",
    "tk_xvfb_gui",
    "dynamic_trading",
    "convo_audit",
    "kahlua_static",
)

CORE_LUA_PATTERNS: tuple[str, ...] = (
    "*convo*.lua",
    "*semantic*.lua",
    "*runtime_role*.lua",
    "*conversation*.lua",
)

UNRELATED_BASELINES_PATH = Path(__file__).with_name("unrelated_baselines.json")

ALLOWED_SKIP_REASONS: dict[str, tuple[str, ...]] = {
    "real_local_save_unavailable": (
        "real local save",
        "real operationalfixture save",
        "local dana save",
        "preexisting_local_save",
        "pre-existing local save",
        "no compatible real build 42.20 save",
        "no preferred real compact-inventory save",
    ),
}

DEFAULT_STEAM_GAME_ROOTS: tuple[Path, ...] = (
    Path.home() / ".steam/steam/steamapps/common/ProjectZomboid/projectzomboid",
    Path.home() / ".local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid",
)

_RAN_RE = re.compile(r"Ran\s+(\d+)\s+tests?\s+in\s+")
_SKIP_COUNT_RE = re.compile(r"skipped=(\d+)")
_FAIL_COUNT_RE = re.compile(r"failures=(\d+)")
_ERROR_COUNT_RE = re.compile(r"errors=(\d+)")
_GUI_IMPORT_RE = re.compile(
    r"\bSemanticHarnessApp\b|\bimport\s+tkinter\b|\bfrom\s+tkinter\b"
)
_CORE_GUI_IMPORT_RE = re.compile(
    r"\bimport\s+tkinter\b|\bfrom\s+tkinter\b"
)
_WORKER_IMPORT_RE = re.compile(
    r"\bLuaSemanticWorker\b|\bWarmWorkerTestMixin\b"
)
_RUNTIME_SKIP_RE = re.compile(r"\.\.\.\s+skipped\s+['\"]([^'\"]+)['\"]")
_CONVO_NAME_RE = re.compile(
    r"(?:convo|semantic|speech|response|identity|greeting|dialogue|discourse|pnc_s10)"
)


def resolve_repositories(
    core_repository: Path | None = None,
    hoomans_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
) -> dict[str, Path]:
    """Resolve Core and participant repository paths."""
    core = (core_repository or CORE_REPOSITORY).expanduser().resolve()
    parent = core.parent
    hoomans = (
        hoomans_repository.expanduser().resolve()
        if hoomans_repository is not None
        else (parent / "ProjectHoomans").resolve()
    )
    dt = (
        dynamic_trading_repository.expanduser().resolve()
        if dynamic_trading_repository is not None
        else (parent / "DynamicTrading").resolve()
    )
    return {
        "core": core,
        "hoomans": hoomans,
        "dynamic_trading": dt,
    }


def resolve_kahlua_game_root(explicit: Path | None = None) -> Path | None:
    """Find installed Project Zomboid directory containing projectzomboid.jar."""
    candidates: list[Path] = []
    if explicit is not None:
        candidates.append(explicit.expanduser())
    env_root = os.environ.get("PZ_KAHLUA_GAME_ROOT", "").strip()
    if env_root:
        candidates.append(Path(env_root).expanduser())
    candidates.extend(DEFAULT_STEAM_GAME_ROOTS)
    for candidate in candidates:
        resolved = candidate.resolve()
        if (resolved / "projectzomboid.jar").is_file():
            return resolved
    return None


def classify_pnc_provider_modules(
    tests_root: Path,
    prefix: str = "tools.providers.pnc.tests",
) -> dict[str, tuple[str, ...]]:
    """Disjointly partition PNC provider Python tests into worker, GUI, and unit suites."""
    gui: list[str] = []
    worker: list[str] = []
    unit: list[str] = []
    for path in sorted(tests_root.glob("test_*.py")):
        module = f"{prefix}.{path.stem}"
        source = path.read_text(encoding="utf-8", errors="replace")
        if _GUI_IMPORT_RE.search(source):
            gui.append(module)
        elif _WORKER_IMPORT_RE.search(source):
            worker.append(module)
        else:
            unit.append(module)
    return {
        "hoomans_provider_python": tuple(unit),
        "real_provider_worker": tuple(worker),
        "tk_xvfb_gui": tuple(gui),
    }


def classify_core_python_modules(
    tests_root: Path,
    prefix: str = "tools.semantic_harness.tests",
) -> dict[str, tuple[str, ...]]:
    """Partition Core Python tests into headless unit and Tk/Xvfb GUI suites."""
    gui: list[str] = []
    unit: list[str] = []
    for path in sorted(tests_root.glob("test_*.py")):
        module = f"{prefix}.{path.stem}"
        source = path.read_text(encoding="utf-8", errors="replace")
        if _CORE_GUI_IMPORT_RE.search(source):
            gui.append(module)
        else:
            unit.append(module)
    return {
        "core_python": tuple(unit),
        "tk_xvfb_gui": tuple(gui),
    }


def _suite_record(
    suite_id: str,
    *,
    ok: bool,
    total: int,
    passed: int,
    failed: int,
    skipped: int,
    allowed_skips: int,
    duration: float,
    failures: list[dict[str, Any]] | None = None,
    skips: list[dict[str, Any]] | None = None,
    details: dict[str, Any] | None = None,
) -> dict[str, Any]:
    unclassified_skips = max(0, skipped - allowed_skips)
    return {
        "suite": suite_id,
        "ok": bool(ok and unclassified_skips == 0),
        "status": "PASS" if (ok and unclassified_skips == 0) else "FAIL",
        "total": int(total),
        "passed": int(passed),
        "failed": int(failed),
        "skipped": int(skipped),
        "allowedSkips": int(allowed_skips),
        "unclassifiedSkips": int(unclassified_skips),
        "duration": round(float(duration), 3),
        "failures": list(failures or [])[:64],
        "skips": list(skips or [])[:64],
        "details": dict(details or {}),
    }


def _classify_runtime_skips(
    output: str,
    skip_count: int,
) -> tuple[int, list[dict[str, str]]]:
    """Classify runtime unittest skip reasons into (allowed_count, details)."""
    reasons = [match.group(1).strip() for match in _RUNTIME_SKIP_RE.finditer(output)]
    if skip_count <= 0 or not reasons:
        return 0, []
    allowed = 0
    details: list[dict[str, str]] = []
    for reason in reasons:
        lowered = reason.casefold()
        matched_cat = None
        for category, needles in ALLOWED_SKIP_REASONS.items():
            if any(needle in lowered for needle in needles):
                matched_cat = category
                break
        if matched_cat is not None:
            allowed += 1
        details.append({"reason": reason, "category": matched_cat or "unclassified"})
    if len(reasons) != skip_count:
        # Unrecognized discrepancy between unittest skip total and printed reasons.
        return min(allowed, len(reasons)), details
    return allowed, details


def _parse_unittest_counts(module_result: dict[str, Any]) -> tuple[int, int, int, int]:
    """Return (total, passed, failed, skipped) test case counts for one module."""
    output = str(module_result.get("output") or "")
    skip_count = int(module_result.get("skipCount") or 0)
    ran_matches = _RAN_RE.findall(output)
    ran = int(ran_matches[-1]) if ran_matches else 0
    fail_matches = _FAIL_COUNT_RE.findall(output)
    err_matches = _ERROR_COUNT_RE.findall(output)
    skip_matches = _SKIP_COUNT_RE.findall(output)
    skipped = int(skip_matches[-1]) if skip_matches else skip_count
    failed_cases = (int(fail_matches[-1]) if fail_matches else 0) + (
        int(err_matches[-1]) if err_matches else 0
    )
    status = str(module_result.get("status") or "FAIL")
    if status != "PASS" and status != "SKIP" and failed_cases == 0:
        failed_cases = 1
    total = max(ran, skipped + failed_cases)
    if total == 0 and status != "PASS":
        total = 1
    passed = max(0, total - failed_cases - skipped)
    return total, passed, failed_cases, skipped


def _run_python_suite(
    suite_id: str,
    *,
    root: Path,
    tests_root: Path,
    module_prefix: str,
    modules: Sequence[str] | None = None,
    environment: dict[str, str],
    jobs: int,
    timeout: float,
    headless: bool = False,
) -> dict[str, Any]:
    started = time.monotonic()
    runner = PythonAcceptanceRunner(
        root,
        python=sys.executable,
        jobs=jobs,
        timeout=timeout,
        tests_root=tests_root,
        module_prefix=module_prefix,
        modules=modules,
        environment=environment,
        headless=headless,
        unittest_verbose=True,
    )
    report = runner.run()
    duration = time.monotonic() - started
    total_cases = 0
    passed_cases = 0
    failed_cases = 0
    skipped_cases = 0
    allowed_skips = 0
    failures: list[dict[str, Any]] = []
    skips: list[dict[str, Any]] = []

    for mod in report.get("modules", []):
        c_total, c_passed, c_failed, c_skipped = _parse_unittest_counts(mod)
        total_cases += c_total
        passed_cases += c_passed
        failed_cases += c_failed
        skipped_cases += c_skipped
        mod_name = str(mod.get("module"))
        if mod.get("status") not in {"PASS", "SKIP"}:
            failures.append(
                {
                    "module": mod_name,
                    "status": mod.get("status"),
                    "tail": str(mod.get("output") or "")[-400:],
                }
            )
        if c_skipped > 0:
            allowed_count, skip_details = _classify_runtime_skips(
                str(mod.get("output") or ""), c_skipped
            )
            allowed_skips += allowed_count
            skips.append(
                {
                    "module": mod_name,
                    "skipped": c_skipped,
                    "allowed": allowed_count,
                    "reasons": skip_details,
                }
            )

    summary = report.get("summary", {})
    return _suite_record(
        suite_id,
        ok=bool(report.get("ok")) and failed_cases == 0,
        total=total_cases,
        passed=passed_cases,
        failed=failed_cases,
        skipped=skipped_cases,
        allowed_skips=allowed_skips,
        duration=duration,
        failures=failures,
        skips=skips,
        details={
            "modulesTotal": summary.get("total", 0),
            "modulesPassed": summary.get("PASS", 0),
            "modulesFailed": summary.get("FAIL", 0),
            "modulesSkipped": summary.get("SKIP", 0),
        },
    )


def run_core_python_suite(
    repos: dict[str, Path],
    *,
    jobs: int = 4,
    timeout: float = 300.0,
    environment: dict[str, str],
) -> dict[str, Any]:
    """Run headless Core Python Semantic Harness tests."""
    core = repos["core"]
    tests_root = core / "tools/semantic_harness/tests"
    buckets = classify_core_python_modules(tests_root)
    return _run_python_suite(
        "core_python",
        root=core,
        tests_root=tests_root,
        module_prefix="tools.semantic_harness.tests",
        modules=buckets["core_python"],
        environment=environment,
        jobs=jobs,
        timeout=timeout,
        headless=True,
    )


def run_tk_xvfb_gui_suite(
    repos: dict[str, Path],
    *,
    pnc_modules: Sequence[str],
    core_modules: Sequence[str],
    pnc_environment: dict[str, str],
    core_environment: dict[str, str],
    jobs: int = 2,
    timeout: float = 300.0,
) -> dict[str, Any]:
    """Run all Tk/Xvfb GUI tests (ProjectHoomans + Core) under one suite."""
    parts: list[dict[str, Any]] = []
    if pnc_modules:
        parts.append(
            _run_python_suite(
                "tk_xvfb_gui",
                root=repos["hoomans"],
                tests_root=repos["hoomans"] / "tools/providers/pnc/tests",
                module_prefix="tools.providers.pnc.tests",
                modules=pnc_modules,
                environment=pnc_environment,
                jobs=max(1, min(int(jobs), 2)),
                timeout=timeout,
            )
        )
    if core_modules:
        parts.append(
            _run_python_suite(
                "tk_xvfb_gui",
                root=repos["core"],
                tests_root=repos["core"] / "tools/semantic_harness/tests",
                module_prefix="tools.semantic_harness.tests",
                modules=core_modules,
                environment=core_environment,
                jobs=max(1, min(int(jobs), 2)),
                timeout=timeout,
            )
        )
    if not parts:
        return _suite_record(
            "tk_xvfb_gui",
            ok=True,
            total=0,
            passed=0,
            failed=0,
            skipped=0,
            allowed_skips=0,
            duration=0.0,
        )
    return _suite_record(
        "tk_xvfb_gui",
        ok=all(item["ok"] for item in parts),
        total=sum(int(item["total"]) for item in parts),
        passed=sum(int(item["passed"]) for item in parts),
        failed=sum(int(item["failed"]) for item in parts),
        skipped=sum(int(item["skipped"]) for item in parts),
        allowed_skips=sum(int(item["allowedSkips"]) for item in parts),
        duration=sum(float(item["duration"]) for item in parts),
        failures=[f for item in parts for f in item.get("failures", [])],
        skips=[s for item in parts for s in item.get("skips", [])],
        details={
            "modulesTotal": sum(
                int((item.get("details") or {}).get("modulesTotal", 0))
                for item in parts
            ),
            "modulesPassed": sum(
                int((item.get("details") or {}).get("modulesPassed", 0))
                for item in parts
            ),
            "modulesFailed": sum(
                int((item.get("details") or {}).get("modulesFailed", 0))
                for item in parts
            ),
            "modulesSkipped": sum(
                int((item.get("details") or {}).get("modulesSkipped", 0))
                for item in parts
            ),
        },
    )


def run_core_lua_suite(
    repos: dict[str, Path],
    *,
    jobs: int = 4,
    timeout: float = 30.0,
) -> dict[str, Any]:
    """Run Core ConvoEngine / Semantic Harness Lua tests."""
    core = repos["core"]
    runtime = discover_newest_runtime(core / "Contents/mods/PsychopatzCore")
    paths = sorted(
        {p for pattern in CORE_LUA_PATTERNS for p in (core / "tests").glob(pattern)}
    )
    env = os.environ.copy()
    env["PZ_TEST_REPOSITORY"] = str(core)
    env["PZ_TEST_CORE_REPOSITORY"] = str(core)
    env["LUA_PATH"] = (
        f"{core}/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
        f"{core}/Contents/mods/PsychopatzCore/{runtime}/media/lua/shared/?.lua;;"
    )
    started = time.monotonic()
    results, report = run_lua_suite(
        paths, root=core, environment=env, timeout=timeout, jobs=jobs
    )
    duration = time.monotonic() - started
    fails = [
        {
            "test": str(r.path.relative_to(core)),
            "returncode": r.returncode,
            "tail": r.output[-400:],
        }
        for r in results
        if r.returncode != 0
    ]
    return _suite_record(
        "core_lua",
        ok=bool(report.get("ok")) and not fails,
        total=len(results),
        passed=len(results) - len(fails),
        failed=len(fails),
        skipped=0,
        allowed_skips=0,
        duration=duration,
        failures=fails,
    )


def load_unrelated_baselines(
    path: Path | None = None,
) -> dict[tuple[str, str], dict[str, Any]]:
    """Load reviewed non-ConvoEngine failure baseline records with signature validation."""
    target = path or UNRELATED_BASELINES_PATH
    payload = json.loads(target.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or payload.get("schemaVersion") != 1:
        raise ValueError(f"invalid unrelated baselines schemaVersion at {target}")
    records = payload.get("baselines")
    if not isinstance(records, list):
        raise ValueError(f"invalid unrelated baselines list at {target}")
    indexed: dict[tuple[str, str], dict[str, Any]] = {}
    for entry in records:
        if not isinstance(entry, dict):
            raise ValueError(f"baseline record must be a JSON object in {target}")
        suite = str(entry.get("suite") or "").strip()
        test = str(entry.get("test") or "").strip()
        owner = str(entry.get("owner") or "").strip()
        provenance = str(entry.get("provenanceCommit") or "").strip()
        reason = str(entry.get("reason") or "").strip()
        patterns = entry.get("signaturePatterns")
        if not all((suite, test, owner, provenance, reason)):
            raise ValueError(
                f"baseline record missing required metadata (suite/test/owner/provenanceCommit/reason): {entry!r}"
            )
        if _is_convo_semantic_lua_test(test):
            raise ValueError(
                f"ConvoEngine/semantic test cannot be registered as an unrelated baseline: {test}"
            )
        if not isinstance(patterns, list) or not patterns or not all(
            isinstance(p, str) and p.strip() for p in patterns
        ):
            raise ValueError(
                f"baseline record {test!r} must declare non-empty signaturePatterns"
            )
        key = (suite, test)
        if key in indexed:
            raise ValueError(f"duplicate unrelated baseline record for {key!r}")
        indexed[key] = {
            "suite": suite,
            "test": test,
            "owner": owner,
            "provenanceCommit": provenance,
            "reason": reason,
            "signaturePatterns": tuple(patterns),
        }
    return indexed


def match_unrelated_baseline(
    suite: str,
    rel_path: str,
    failure_output: str,
    baselines: Mapping[tuple[str, str], dict[str, Any]] | None = None,
) -> dict[str, Any] | None:
    """Return reviewed baseline metadata only when test is non-Convo and failure signature matches."""
    if _is_convo_semantic_lua_test(rel_path):
        return None
    if not isinstance(failure_output, str) or not failure_output.strip():
        return None
    table = baselines if baselines is not None else load_unrelated_baselines()
    record = table.get((suite, rel_path))
    if record is None:
        return None
    if all(pattern in failure_output for pattern in record["signaturePatterns"]):
        return record
    return None


def classify_hoomans_lua_results(
    results: Sequence[Mapping[str, Any]],
    *,
    hoomans_root: Path,
    baselines: Mapping[tuple[str, str], dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Classify ProjectHoomans Lua results using signature-proven reviewed baselines."""
    table = baselines if baselines is not None else load_unrelated_baselines()
    convo_total = 0
    convo_failed = 0
    failures: list[dict[str, Any]] = []
    classified_baselines: list[str] = []
    baseline_records: list[dict[str, Any]] = []
    unexpected_failures: list[str] = []

    for item in results:
        path = Path(str(item.get("path", "")))
        rel = (
            path.relative_to(hoomans_root).as_posix()
            if path.is_relative_to(hoomans_root)
            else str(path)
        )
        convo_rel = _is_convo_semantic_lua_test(rel)
        if convo_rel:
            convo_total += 1
        if int(item.get("returncode") or 0) != 0:
            if convo_rel:
                convo_failed += 1
            timed_out = bool(item.get("timedOut"))
            failure_output = str(item.get("failureOutput") or "")
            matched = (
                None
                if (convo_rel or timed_out)
                else match_unrelated_baseline("hoomans_lua", rel, failure_output, table)
            )
            if matched is not None:
                classified_baselines.append(rel)
                baseline_records.append(
                    {
                        "test": rel,
                        "owner": matched["owner"],
                        "provenanceCommit": matched["provenanceCommit"],
                        "reason": matched["reason"],
                        "signatureMatched": True,
                    }
                )
                failures.append(
                    {
                        "test": rel,
                        "returncode": item.get("returncode"),
                        "classification": "known_unrelated_baseline",
                        "convoSemantic": convo_rel,
                        "owner": matched["owner"],
                        "provenanceCommit": matched["provenanceCommit"],
                    }
                )
            else:
                unexpected_failures.append(rel)
                entry: dict[str, Any] = {
                    "test": rel,
                    "returncode": item.get("returncode"),
                    "classification": "unexpected_failure",
                    "convoSemantic": convo_rel,
                }
                if timed_out:
                    entry["timedOut"] = True
                if failure_output.strip():
                    entry["failureTail"] = failure_output.strip()[-300:]
                failures.append(entry)

    return {
        "convoTotal": convo_total,
        "convoFailed": convo_failed,
        "failures": failures,
        "classifiedBaselines": classified_baselines,
        "baselineRecords": baseline_records,
        "unexpectedFailures": unexpected_failures,
    }


def _is_convo_semantic_lua_test(rel_path: str) -> bool:
    return bool(_CONVO_NAME_RE.search(Path(rel_path).stem.casefold()))


def run_hoomans_lua_suite(
    repos: dict[str, Path],
    *,
    jobs: int = 4,
    timeout: float = 60.0,
    allow_unrelated_baselines: bool = True,
) -> dict[str, Any]:
    """Run ProjectHoomans root Lua smoke suite via its bounded runner."""
    hoomans = repos["hoomans"]
    core = repos["core"]
    started = time.monotonic()
    with tempfile.NamedTemporaryFile(
        prefix="hoomans-lua-acceptance-", suffix=".json", delete=False
    ) as handle:
        report_path = Path(handle.name)
    try:
        env = os.environ.copy()
        env["PZ_TEST_CORE_REPOSITORY"] = str(core)
        cmd = [
            sys.executable,
            str(hoomans / "tests/run_tests.py"),
            "--jobs",
            str(max(1, jobs)),
            "--timeout",
            str(timeout),
            "--harness-report",
            str(report_path),
        ]
        proc = subprocess.run(
            cmd,
            cwd=hoomans,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        duration = time.monotonic() - started
        payload = (
            json.loads(report_path.read_text(encoding="utf-8"))
            if report_path.is_file()
            else {"results": [], "ok": False}
        )
    finally:
        report_path.unlink(missing_ok=True)

    results = payload.get("results", [])
    classified = classify_hoomans_lua_results(results, hoomans_root=hoomans)
    convo_total = classified["convoTotal"]
    convo_failed = classified["convoFailed"]
    failures = classified["failures"]
    classified_baselines = classified["classifiedBaselines"]
    unexpected_failures = classified["unexpectedFailures"]

    total = len(results)
    failed = len(failures)
    passed = total - failed
    ok = (
        proc.returncode == 0
        and failed == 0
        and not payload.get("conflicts")
    ) or (
        allow_unrelated_baselines
        and convo_failed == 0
        and len(unexpected_failures) == 0
        and total > 0
        and not payload.get("conflicts")
    )
    return _suite_record(
        "hoomans_lua",
        ok=ok,
        total=total,
        passed=passed,
        failed=failed,
        skipped=0,
        allowed_skips=0,
        duration=duration,
        failures=failures,
        details={
            "convoSemanticTotal": convo_total,
            "convoSemanticPassed": convo_total - convo_failed,
            "convoSemanticFailed": convo_failed,
            "classifiedBaselines": classified_baselines,
            "baselineRecords": classified["baselineRecords"],
            "unexpectedFailures": unexpected_failures,
            "rawReturncode": proc.returncode,
            "stdoutTail": proc.stdout[-400:] if proc.returncode != 0 else "",
        },
    )


def run_dynamic_trading_suite(
    repos: dict[str, Path],
    *,
    jobs: int = 2,
    timeout: float = 30.0,
) -> dict[str, Any]:
    """Run DynamicTrading Lua smoke tests via BoundedLuaTestRunner."""
    dt_repo = repos["dynamic_trading"]
    paths = sorted((dt_repo / "tests").glob("*_smoke.lua"))
    env = os.environ.copy()
    env["PZ_TEST_REPOSITORY"] = str(dt_repo)
    started = time.monotonic()
    results, report = run_lua_suite(
        paths, root=dt_repo, environment=env, timeout=timeout, jobs=jobs
    )
    duration = time.monotonic() - started
    fails = [
        {
            "test": str(r.path.relative_to(dt_repo)),
            "returncode": r.returncode,
            "tail": r.output[-400:],
        }
        for r in results
        if r.returncode != 0
    ]
    return _suite_record(
        "dynamic_trading",
        ok=bool(report.get("ok")) and not fails and len(results) > 0,
        total=len(results),
        passed=len(results) - len(fails),
        failed=len(fails),
        skipped=0,
        allowed_skips=0,
        duration=duration,
        failures=fails,
    )


def run_convo_audit_suite(repos: dict[str, Path]) -> dict[str, Any]:
    """Run unified three-repository ConvoEngine architectural and determinism audit."""
    started = time.monotonic()
    audit = audit_convo_engine_workspace(
        repos["core"],
        hoomans_repository=repos["hoomans"],
        dynamic_trading_repository=repos["dynamic_trading"],
        check_determinism=True,
        require_all_owners=True,
    )
    duration = time.monotonic() - started
    violations = audit.get("violations", [])
    ok = bool(audit.get("ok")) and not violations
    return _suite_record(
        "convo_audit",
        ok=ok,
        total=1,
        passed=1 if ok else 0,
        failed=0 if ok else 1,
        skipped=0,
        allowed_skips=0,
        duration=duration,
        failures=[{"violations": violations[:16]}] if not ok else [],
        details={
            "stats": audit.get("stats", {}),
            "compiled": audit.get("compiled", {}),
            "determinism": audit.get("determinism", {}),
            "violationCount": audit.get("violationCount", len(violations)),
        },
    )


def _collect_repo_kahlua_files(repo: Path, rel_roots: tuple[str, ...]) -> list[Path]:
    files: list[Path] = []
    for rel in rel_roots:
        root = repo / rel
        if root.is_dir():
            files.extend(root.rglob("*.lua"))
    return sorted(set(files))


def run_kahlua_static_suite(
    repos: dict[str, Path],
    *,
    game_root: Path | None = None,
) -> dict[str, Any]:
    """Verify Core, ProjectHoomans, and DynamicTrading Lua files against Kahlua compiler."""
    started = time.monotonic()
    resolved_game_root = resolve_kahlua_game_root(game_root)
    if resolved_game_root is None:
        return _suite_record(
            "kahlua_static",
            ok=False,
            total=1,
            passed=0,
            failed=1,
            skipped=0,
            allowed_skips=0,
            duration=time.monotonic() - started,
            failures=[{"reason": "PZ_KAHLUA_GAME_ROOT / projectzomboid.jar not found"}],
        )

    targets: tuple[tuple[str, Path, tuple[str, ...]], ...] = (
        (
            "PsychopatzCore",
            repos["core"],
            (
                "tools/semantic_harness/lua",
                "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine",
            ),
        ),
        (
            "ProjectHoomans",
            repos["hoomans"],
            (
                "tools/providers/pnc/lua",
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine",
            ),
        ),
        (
            "DynamicTrading",
            repos["dynamic_trading"],
            (
                "tools/providers/dt/lua",
                "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine",
            ),
        ),
    )

    total_files = 0
    passed_targets = 0
    failures: list[dict[str, Any]] = []
    per_repo: dict[str, Any] = {}
    for label, repo, rel_roots in targets:
        files = _collect_repo_kahlua_files(repo, rel_roots)
        if not files:
            continue
        for index in range(0, len(files), MAX_LUA_FILES):
            chunk = files[index : index + MAX_LUA_FILES]
            res = run_kahlua_check(resolved_game_root, chunk, repository=repo)
            total_files += int(res.get("filesChecked") or 0)
            per_repo[label] = res
            if res.get("passed"):
                passed_targets += 1
            else:
                failures.append({"repository": label, "failure": res.get("failure")})

    total_checks = passed_targets + len(failures)
    return _suite_record(
        "kahlua_static",
        ok=len(failures) == 0 and total_files > 0,
        total=total_checks,
        passed=passed_targets,
        failed=len(failures),
        skipped=0,
        allowed_skips=0,
        duration=time.monotonic() - started,
        failures=failures,
        details={
            "gameRoot": str(resolved_game_root),
            "filesChecked": total_files,
            "repositories": per_repo,
        },
    )


def run_acceptance_suites(
    *,
    core_repository: Path | None = None,
    hoomans_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    suites: Sequence[str] | None = None,
    jobs: int = 2,
    timeout: float = 300.0,
    kahlua_game_root: Path | None = None,
    allow_unrelated_baselines: bool = True,
) -> dict[str, Any]:
    """Execute the multi-suite developer acceptance matrix."""
    started = time.monotonic()
    repos = resolve_repositories(
        core_repository, hoomans_repository, dynamic_trading_repository
    )
    selected = tuple(suites) if suites else REQUIRED_SUITES
    unknown = [name for name in selected if name not in REQUIRED_SUITES]
    if unknown:
        raise ValueError(f"unknown acceptance suite(s): {', '.join(unknown)}")

    resolved_game_root = resolve_kahlua_game_root(kahlua_game_root)
    pnc_env = {
        "PYTHONPATH": f"{repos['hoomans']}{os.pathsep}{repos['core']}",
    }
    core_env = {
        "PYTHONPATH": str(repos["core"]),
    }
    if resolved_game_root is not None:
        pnc_env["PZ_KAHLUA_GAME_ROOT"] = str(resolved_game_root)
        core_env["PZ_KAHLUA_GAME_ROOT"] = str(resolved_game_root)

    pnc_root = repos["hoomans"] / "tools/providers/pnc/tests"
    pnc_buckets = classify_pnc_provider_modules(pnc_root)
    core_buckets = classify_core_python_modules(
        repos["core"] / "tools/semantic_harness/tests"
    )

    runners: dict[str, Callable[[], dict[str, Any]]] = {
        "core_python": lambda: run_core_python_suite(
            repos, jobs=max(1, jobs), timeout=timeout, environment=core_env
        ),
        "core_lua": lambda: run_core_lua_suite(repos, jobs=max(1, jobs)),
        "hoomans_lua": lambda: run_hoomans_lua_suite(
            repos,
            jobs=max(1, jobs),
            allow_unrelated_baselines=allow_unrelated_baselines,
        ),
        "hoomans_provider_python": lambda: _run_python_suite(
            "hoomans_provider_python",
            root=repos["hoomans"],
            tests_root=pnc_root,
            module_prefix="tools.providers.pnc.tests",
            modules=pnc_buckets["hoomans_provider_python"],
            environment=pnc_env,
            jobs=jobs,
            timeout=timeout,
        ),
        "real_provider_worker": lambda: _run_python_suite(
            "real_provider_worker",
            root=repos["hoomans"],
            tests_root=pnc_root,
            module_prefix="tools.providers.pnc.tests",
            modules=pnc_buckets["real_provider_worker"],
            environment=pnc_env,
            jobs=jobs,
            timeout=timeout,
        ),
        "tk_xvfb_gui": lambda: run_tk_xvfb_gui_suite(
            repos,
            pnc_modules=pnc_buckets["tk_xvfb_gui"],
            core_modules=core_buckets["tk_xvfb_gui"],
            pnc_environment=pnc_env,
            core_environment=core_env,
            jobs=jobs,
            timeout=timeout,
        ),
        "dynamic_trading": lambda: run_dynamic_trading_suite(repos, jobs=jobs),
        "convo_audit": lambda: run_convo_audit_suite(repos),
        "kahlua_static": lambda: run_kahlua_static_suite(
            repos, game_root=resolved_game_root
        ),
    }

    suite_reports: dict[str, dict[str, Any]] = {}
    for suite_id in selected:
        suite_reports[suite_id] = runners[suite_id]()

    suites_passed = sum(1 for item in suite_reports.values() if item["ok"])
    convo_scope_ok = all(
        item["ok"]
        if sid != "hoomans_lua"
        else int(item["details"].get("convoSemanticFailed", 0)) == 0
        for sid, item in suite_reports.items()
    )
    return {
        "schemaVersion": 1,
        "type": "semantic_harness_acceptance",
        "ok": suites_passed == len(selected),
        "convoScopeOk": convo_scope_ok,
        "suiteOrder": list(selected),
        "suites": suite_reports,
        "summary": {
            "suitesTotal": len(selected),
            "suitesPassed": suites_passed,
            "suitesFailed": len(selected) - suites_passed,
            "total": sum(item["total"] for item in suite_reports.values()),
            "passed": sum(item["passed"] for item in suite_reports.values()),
            "failed": sum(item["failed"] for item in suite_reports.values()),
            "skipped": sum(item["skipped"] for item in suite_reports.values()),
            "allowedSkips": sum(item["allowedSkips"] for item in suite_reports.values()),
            "unclassifiedSkips": sum(
                item["unclassifiedSkips"] for item in suite_reports.values()
            ),
            "duration": round(time.monotonic() - started, 3),
        },
        "repositories": {k: str(v) for k, v in repos.items()},
    }


def print_acceptance_report(report: dict[str, Any]) -> None:
    """Print a compact summary table for every executed acceptance suite."""
    for suite_id in report.get("suiteOrder", []):
        item = report["suites"][suite_id]
        print(
            f"{item['status']:4s} {suite_id:24s} "
            f"total={item['total']} pass={item['passed']} fail={item['failed']} "
            f"skip={item['skipped']} (allowed={item['allowedSkips']}) "
            f"duration={item['duration']:.2f}s"
        )
        for fail in item.get("failures", ())[:5]:
            print(f"  fail: {json.dumps(fail, ensure_ascii=False)}")
    summary = report["summary"]
    print(
        f"ACCEPTANCE: suites={summary['suitesPassed']}/{summary['suitesTotal']} "
        f"cases={summary['passed']}/{summary['total']} failed={summary['failed']} "
        f"skipped={summary['skipped']} allowedSkips={summary['allowedSkips']} "
        f"convoScopeOk={report['convoScopeOk']} in {summary['duration']:.2f}s"
    )


def write_acceptance_report(report: dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def ensure_xvfb_for_suites(selected: Sequence[str]) -> None:
    needs_display = any(suite == "tk_xvfb_gui" for suite in selected)
    if (
        needs_display
        and not os.environ.get("DISPLAY")
        and not os.environ.get("_SEMANTIC_ACCEPTANCE_XVFB")
        and shutil.which("xvfb-run")
    ):
        env = os.environ.copy()
        env["_SEMANTIC_ACCEPTANCE_XVFB"] = "1"
        os.execvpe(
            "xvfb-run",
            ["xvfb-run", "-a", sys.executable, *sys.argv],
            env,
        )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--suite",
        action="append",
        dest="suites",
        choices=REQUIRED_SUITES,
        help="Run specific suite(s); defaults to all developer acceptance suites",
    )
    parser.add_argument("--core-repository", type=Path)
    parser.add_argument("--hoomans-repository", type=Path)
    parser.add_argument("--dynamic-trading-repository", type=Path)
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--timeout", type=float, default=300.0)
    parser.add_argument("--kahlua-game-root", type=Path)
    parser.add_argument("--allow-unrelated-baselines", action="store_true")
    parser.add_argument("--strict-baselines", action="store_true")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--jsonl", action="store_true")
    options = parser.parse_args(argv)
    selected = tuple(options.suites) if options.suites else REQUIRED_SUITES
    ensure_xvfb_for_suites(selected)
    report = run_acceptance_suites(
        core_repository=options.core_repository,
        hoomans_repository=options.hoomans_repository,
        dynamic_trading_repository=options.dynamic_trading_repository,
        suites=selected,
        jobs=options.jobs,
        timeout=options.timeout,
        kahlua_game_root=options.kahlua_game_root,
        allow_unrelated_baselines=not bool(options.strict_baselines),
    )
    if options.report is not None:
        write_acceptance_report(report, options.report.expanduser())
    if options.jsonl:
        print(json.dumps(report, ensure_ascii=False))
    else:
        print_acceptance_report(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
