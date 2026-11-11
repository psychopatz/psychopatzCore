"""Simulation-owned regression actions over shared Observatory services."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ..inspection.response_observatory import run_quality_matrix
from ..inspection.response_selection_coverage import selection_coverage
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def _repository(app: Any) -> Path | None:
    repository = getattr(app.authoring_service, "repository", None)
    return repository if isinstance(repository, Path) else None


def _fixture_cases(app: Any, filename: str) -> list[dict[str, Any]]:
    repository = _repository(app)
    if repository is None:
        raise ValueError("repository unavailable for regression fixture")
    core_repository = getattr(app.authoring_service, "core_repository", repository)
    path = core_repository / "tools/semantic_harness/fixtures" / filename
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
    try:
        cases = _fixture_cases(app, "observatory_lifecycle_en_tl.json")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        app.regression_status_var.set(f"Lifecycle fixture unavailable: {error}")
        return
    _run_matrix(app, cases, "farewell lifecycle")


def run_regression_command_rejections(app: Any) -> None:
    try:
        cases = _fixture_cases(app, "observatory_permission_rejections_en_tl.json")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        app.regression_status_var.set(f"Rejection fixture unavailable: {error}")
        return
    _run_matrix(app, cases, "authority rejection")


def run_regression_selection(app: Any) -> None:
    if not app.session.ready or app.busy:
        return
    repository = _repository(app)
    if repository is None:
        app.regression_status_var.set("Selection fixture unavailable")
        return
    core_repository = getattr(app.authoring_service, "core_repository", repository)
    path = (
        core_repository
        / "tools/semantic_harness/fixtures"
        / "observatory_greeting_selection.json"
    )
    try:
        scenario = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, json.JSONDecodeError) as error:
        app.regression_status_var.set(f"Selection fixture unavailable: {error}")
        return

    def finish(report: dict[str, Any]) -> None:
        lines = [
            f"Production Lua selector coverage: {report['poolID']}",
            f"Contexts tested: {report['caseCount']}",
            f"Revision: {report['registryRevision']}",
            "These outcomes apply ONLY to tested hypothetical contexts.",
            "Not selected does NOT mean globally unreachable.",
            "",
        ]
        for variant in report["variants"]:
            lines.extend(
                (
                    f"{variant['variantID']} · {variant['testedStatus']}",
                    f"  eligible={variant['eligibleCases']} "
                    f"selected={variant['selectedCases']} "
                    f"lower-score={variant['lowerRankedCases']} "
                    f"ties-not-selected={variant['tieCases']}",
                    "",
                )
            )
        for case in report["cases"]:
            lines.append(f"{case['label']}: selected {case['selectedID']}")
            for row in case["candidateEvidence"]:
                if row["failedFields"]:
                    lines.append(
                        f"  {row['variantID']}: not eligible "
                        f"({', '.join(row['failedFields'])})"
                    )
        app._set_text(app.regression_output, "\n".join(lines))
        app.regression_status_var.set(
            f"Selection contexts={report['caseCount']} · production matcher"
        )
        _select_regression_home(app)

    app._start_operation(
        lambda worker: selection_coverage(worker, scenario),
        finish,
    )


__all__ = [
    "run_regression",
    "run_regression_command_rejections",
    "run_regression_lifecycle",
    "run_regression_selection",
]
