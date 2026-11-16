"""Simulation-owned regression actions over shared Observatory services."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ..inspection.response_observatory import run_quality_matrix
from ..inspection.response_selection_coverage import selection_coverage
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.executor import execute_cases_batch
from tools.semantic_harness.testing.loader import (
    discover_cases,
    discover_domains,
    filter_cases,
)
from tools.semantic_harness.testing.resolver import (
    FixtureResolutionError,
    resolve_fixture_roots,
)


def _resolve_regression_fixture(app: Any, filename: str) -> Path:
    arguments = getattr(app, "arguments", None)
    selection_active = getattr(app, "selection_active", None)
    if not isinstance(selection_active, dict):
        selection_active = {}
    authoring_service = getattr(app, "authoring_service", None)
    repository = getattr(authoring_service, "repository", None)
    core_repository = getattr(authoring_service, "core_repository", None)
    if not isinstance(repository, Path):
        raw_repo = getattr(arguments, "repository", None)
        repository = Path(raw_repo) if raw_repo else None
    if not isinstance(core_repository, Path):
        raw_core = getattr(arguments, "core_repository", None)
        core_repository = Path(raw_core) if raw_core else None
    raw_dt = getattr(arguments, "dynamic_trading_repository", None)
    dt_repo = Path(raw_dt) if raw_dt else None
    mods = selection_active.get("mods") or getattr(arguments, "mods", None)
    preset = selection_active.get("preset") or getattr(arguments, "preset", None)
    profile = getattr(arguments, "profile", "pnc")
    provider_roots = tuple(getattr(arguments, "provider_root", None) or ())
    return resolve_fixture_file(
        filename,
        kind="regression",
        repository=repository,
        core_repository=core_repository,
        dynamic_trading_repository=dt_repo,
        provider_roots=provider_roots,
        mods=mods,
        preset=preset,
        profile=profile,
    )


def _fixture_cases(app: Any, filename: str) -> list[dict[str, Any]]:
    path = _resolve_regression_fixture(app, filename)
    document = json.loads(path.read_text(encoding="utf-8"))
    cases = document.get("cases") if isinstance(document, dict) else None
    if not isinstance(cases, list):
        raise ValueError(f"regression fixture has no cases: {filename}")
    return cases


def _select_regression_home(app: Any) -> None:
    app.trace_tabs.select(app.compare_frame)
    app.compare_tabs.select(app.regression_frame)


def _render_matrix(app: Any, result: dict[str, Any]) -> None:
    lines = [
        f"Production Lua matrix: {result['caseCount']} fixture cases",
        f"Assertions PASS={result['passed']} FAIL={result['failed']} "
        f"OBSERVED={result['observedOnly']}",
        "Not a native SP/MP test or global proof of reachability.",
        "",
    ]
    for row in result["cases"]:
        lines.extend(
            (
                f"{row['label']} · {row['status']} · {row['language']}",
                f"  Selected keys: {', '.join(row['responseKeys'])}",
                f"  Last NPC text: {row['responseTexts'][-1] if row['responseTexts'] else 'NONE'}",
                f"  Action count: {row['actions']}",
                f"  Authority: {row.get('commandDecisionKind', 'UNKNOWN')}",
                "",
            )
        )
    app._set_text(app.regression_output, "\n".join(lines))
    app.regression_status_var.set(
        f"PASS={result['passed']} · FAIL={result['failed']} · "
        f"OBSERVED={result['observedOnly']} · bounded fixture"
    )
    _select_regression_home(app)


def _run_matrix(app: Any, cases: list[dict[str, Any]], label: str) -> None:
    if not app.session.ready or app.busy:
        return

    def operation(worker: LuaSemanticWorker) -> dict[str, Any]:
        return run_quality_matrix(
            cases,
            worker_factory=lambda scenario: LuaSemanticWorker(
                scenario, config=worker.config
            ),
        )

    def finish(result: dict[str, Any]) -> None:
        _render_matrix(app, result)
        app._append("SYSTEM", f"Simulation regression complete: {label}.")

    app._start_operation(operation, finish)


def run_regression(app: Any) -> None:
    _run_matrix(
        app,
        [
            {
                "label": "Greeting EN",
                "language": "EN",
                "utterance": "hello",
                "expected": {"maxActions": 0},
            },
            {
                "label": "Greeting TL",
                "language": "TL",
                "utterance": "hello",
                "expected": {"maxActions": 0},
            },
            {
                "label": "Follow EN",
                "language": "EN",
                "utterance": "follow me",
                "expected": {"minActions": 1},
            },
            {
                "label": "Follow TL",
                "language": "TL",
                "utterance": "follow me",
                "expected": {"minActions": 1},
            },
        ],
        "greeting and companion",
    )


def run_regression_lifecycle(app: Any) -> None:
    run_semantic_fixtures(
        app,
        domain="realization",
        suite="pnc.realization.lifecycle_and_goodbye_wording",
    )


def run_regression_command_rejections(app: Any) -> None:
    run_semantic_fixtures(
        app,
        domain="realization",
        suite="pnc.realization.permission_rejection_wording",
    )


def run_regression_selection(app: Any) -> None:
    run_semantic_fixtures(
        app,
        domain="realization",
        suite="pnc.realization.response_pool_lookup_explain_and_sampling",
    )


def _resolve_semantic_fixture_cases(app: Any) -> list[Any]:
    arguments = getattr(app, "arguments", None)
    selection_active = getattr(app, "selection_active", None)
    if not isinstance(selection_active, dict):
        selection_active = {}
    authoring_service = getattr(app, "authoring_service", None)
    repository = getattr(authoring_service, "repository", None)
    core_repository = getattr(authoring_service, "core_repository", None)
    if not isinstance(repository, Path):
        raw_repo = getattr(arguments, "repository", None)
        repository = Path(raw_repo) if raw_repo else None
    if not isinstance(core_repository, Path):
        raw_core = getattr(arguments, "core_repository", None)
        core_repository = Path(raw_core) if raw_core else None
    raw_dt = getattr(arguments, "dynamic_trading_repository", None)
    dt_repo = Path(raw_dt) if raw_dt else None
    mods = selection_active.get("mods") or getattr(arguments, "mods", None)
    preset = selection_active.get("preset") or getattr(arguments, "preset", None)
    profile = getattr(arguments, "profile", "pnc")
    provider_roots = tuple(getattr(arguments, "provider_root", None) or ())
    roots = resolve_fixture_roots(
        kind="semantic",
        repository=repository,
        core_repository=core_repository,
        dynamic_trading_repository=dt_repo,
        provider_roots=provider_roots,
        mods=mods,
        preset=preset,
        profile=profile,
    )
    return discover_cases(roots)


def discover_semantic_fixture_domains(app: Any) -> dict[str, int]:
    try:
        cases = _resolve_semantic_fixture_cases(app)
    except (OSError, ValueError, FixtureResolutionError) as error:
        app.regression_status_var.set(f"Fixture discovery failed: {error}")
        return {}
    counts = discover_domains(cases)
    combo = getattr(app, "fixture_domain_combo", None)
    if combo is not None:
        combo["values"] = ("all", *counts.keys())
    lines = [
        f"Discovered {len(counts)} semantic fixture domain(s) across {len(cases)} case(s):",
        "",
        *[f"  - {dom}: {count} case(s)" for dom, count in counts.items()],
    ]
    app._set_text(app.regression_output, "\n".join(lines))
    app.regression_status_var.set(
        f"Domains={len(counts)} · Cases={len(cases)} · bounded fixture catalog"
    )
    _select_regression_home(app)
    return counts


def cancel_semantic_fixtures(app: Any) -> None:
    app._fixture_cancel_requested = True
    app.regression_status_var.set("Cancellation requested for semantic fixture batch...")


def run_semantic_fixtures(
    app: Any,
    *,
    domain: str | None = None,
    suite: str | None = None,
    semantic_id: str | None = None,
) -> None:
    if not app.session.ready or app.busy:
        return
    try:
        all_cases = _resolve_semantic_fixture_cases(app)
    except (OSError, ValueError, FixtureResolutionError) as error:
        app.regression_status_var.set(f"Fixture discovery failed: {error}")
        return

    raw_domain = domain if domain is not None else (
        app.fixture_domain_var.get().strip() if hasattr(app, "fixture_domain_var") else ""
    )
    effective_domain = None if not raw_domain or raw_domain == "all" else raw_domain
    raw_sid = semantic_id if semantic_id is not None else (
        app.fixture_semantic_id_var.get().strip() if hasattr(app, "fixture_semantic_id_var") else ""
    )
    effective_sid = raw_sid or None

    matched = filter_cases(
        all_cases,
        domain=effective_domain,
        suite=suite,
        semantic_id=effective_sid,
    )
    if not matched:
        app.regression_status_var.set("No semantic fixtures matched filter.")
        return

    app._fixture_cancel_requested = False

    def operation(worker: LuaSemanticWorker) -> dict[str, Any]:
        batch = execute_cases_batch(
            matched,
            batch_size=16,
            cancel_check=lambda: bool(getattr(app, "_fixture_cancel_requested", False)),
            worker_factory=lambda scenario: LuaSemanticWorker(
                scenario, config=worker.config
            ),
            config=worker.config,
        )
        return {
            "total": len(matched),
            "passed": batch.passed_count,
            "failed": batch.failed_count,
            "cancelled": batch.cancelled,
            "summaries": [r.summary() for r in batch.results],
        }

    def finish(report: dict[str, Any]) -> None:
        lines = [
            f"Semantic Fixtures: PASS={report['passed']} FAIL={report['failed']} "
            f"TOTAL={report['total']} CANCELLED={report['cancelled']}",
            "",
            *report["summaries"][:50],
        ]
        if len(report["summaries"]) > 50:
            lines.append(f"... ({len(report['summaries']) - 50} more)")
        app._set_text(app.regression_output, "\n".join(lines))
        app.regression_status_var.set(
            f"Fixtures PASS={report['passed']} · FAIL={report['failed']}"
        )
        _select_regression_home(app)

    app._start_operation(operation, finish)


__all__ = [
    "cancel_semantic_fixtures",
    "discover_semantic_fixture_domains",
    "run_regression",
    "run_regression_command_rejections",
    "run_regression_lifecycle",
    "run_regression_selection",
    "run_semantic_fixtures",
]
