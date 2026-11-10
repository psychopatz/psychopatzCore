"""Bounded real-worker mutation matrix for coherent conversation regressions."""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
from typing import Any, Iterable

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


MAX_CASES = 32

DEFAULT_CASES: tuple[dict[str, Any], ...] = (
    {
        "id": "compact_hostility",
        "text": "fuckyou",
        "expect": {"intent": "INSULT", "branch": "HOSTILE_REMARK_RECEIVED"},
    },
    {
        "id": "elongated_compact_hostility",
        "text": "fuckyouuuu",
        "expect": {"intent": "INSULT", "branch": "HOSTILE_REMARK_RECEIVED"},
    },
    {
        "id": "punctuation_case_hostility",
        "text": "FUCK YOU!!!",
        "expect": {"intent": "INSULT", "branch": "HOSTILE_REMARK_RECEIVED"},
    },
    {
        "id": "compact_boundary",
        "text": "shutthefuckup",
        "expect": {"intent": "HOSTILE_REMARK", "branch": "HOSTILE_REMARK_RECEIVED"},
    },
    {
        "id": "safe_social_typo",
        "text": "yeah rigt",
        "expect": {"intent": "DISAGREE", "branch": "SOCIAL_ACKNOWLEDGED"},
    },
    {
        "id": "safe_fuzzy_movement",
        "text": "folow me",
        "expect": {"action": "FOLLOW", "branch": "COMMAND_ACCEPTED"},
    },
    {
        "id": "unsafe_item_typo",
        "text": "give me waterr",
        "expect": {"branch": "ASK_CLARIFICATION", "transportCount": 0},
    },
    {
        "id": "self_state_intensifier",
        "text": "i'm fucking starving",
        "expect": {"intent": "INFORM", "subject": "HUNGER"},
    },
    {
        "id": "punctuation_insult",
        "text": "YOU IDIOT!!!",
        "expect": {"intent": "INSULT", "branch": "HOSTILE_REMARK_RECEIVED"},
    },
)


def _row(case: dict[str, Any], turn: dict[str, Any]) -> dict[str, Any]:
    result = turn.get("result") if isinstance(turn.get("result"), dict) else {}
    ir = result.get("ir") if isinstance(result.get("ir"), dict) else {}
    decision = (
        result.get("decision")
        if isinstance(result.get("decision"), dict)
        else {}
    )
    diagnostics = (
        ir.get("diagnostics") if isinstance(ir.get("diagnostics"), dict) else {}
    )
    provenance = (
        ir.get("provenance") if isinstance(ir.get("provenance"), dict) else {}
    )
    risk = (
        decision.get("diagnostics", {}).get("riskAssessment")
        if isinstance(decision.get("diagnostics"), dict)
        else None
    )
    risk = risk if isinstance(risk, dict) else {}
    # Case transportCount historically means executable dispatch count.
    # The turn still retains every lifecycle fact in its raw transport.
    transport = turn.get("dispatchTransport", turn.get("transport"))
    transport_count = len(transport) if isinstance(transport, list) else 0

    actual = {
        "intent": ir.get("intent"),
        "speechAct": ir.get("speechAct"),
        "action": ir.get("action"),
        "subject": ir.get("subject"),
        "branch": decision.get("branch"),
        "pattern": provenance.get("pattern"),
        "candidatePass": provenance.get("candidatePass")
        or diagnostics.get("candidatePass"),
        "exact": diagnostics.get("exactMatch"),
        "fuzzy": diagnostics.get("fuzzyMatch"),
        "recovered": diagnostics.get("recoveredMatch"),
        "riskReason": risk.get("reason"),
        "transportCount": transport_count,
    }
    expected = case.get("expect") if isinstance(case.get("expect"), dict) else {}
    mismatches = {
        key: {"expected": expected_value, "actual": actual.get(key)}
        for key, expected_value in expected.items()
        if actual.get(key) != expected_value
    }
    return {
        "id": str(case.get("id") or ""),
        "input": str(case.get("text") or ""),
        "passed": not mismatches,
        "expected": expected,
        "actual": actual,
        "mismatches": mismatches,
    }


def run_mutation_matrix(
    cases: Iterable[dict[str, Any]] = DEFAULT_CASES,
    *,
    scenario: dict[str, Any] | None = None,
) -> dict[str, Any]:
    selected = list(cases)[:MAX_CASES]
    rows: list[dict[str, Any]] = []
    base = deepcopy(scenario or DEFAULT_SCENARIO)
    for case in selected:
        with LuaSemanticWorker(deepcopy(base)) as worker:
            turn = worker.input(str(case.get("text") or ""))
        rows.append(_row(case, turn))
    failed = [row["id"] for row in rows if row["passed"] is not True]
    return {
        "schema": "semantic.conversation.fuzz.v1",
        "caseCount": len(rows),
        "passedCount": len(rows) - len(failed),
        "failedCount": len(failed),
        "failedIDs": failed,
        "rows": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run bounded coherent-conversation mutation cases."
    )
    parser.add_argument(
        "--case",
        action="append",
        default=[],
        help="Run only the named case ID (repeatable).",
    )
    parser.add_argument("--jsonl", action="store_true")
    args = parser.parse_args()

    wanted = set(args.case)
    cases = [
        case for case in DEFAULT_CASES
        if not wanted or str(case.get("id")) in wanted
    ]
    report = run_mutation_matrix(cases)
    if args.jsonl:
        for row in report["rows"]:
            print(json.dumps(row, ensure_ascii=False, separators=(",", ":")))
    else:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    return 1 if report["failedCount"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
