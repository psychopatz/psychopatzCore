"""Bounded C7F held-out scoring over real-worker observations.

The fixture contains Project Hoomans-authored evaluation paraphrases and
metadata-only source references. It never loads or packages an external
corpus. The production Lua worker remains the authority for recognition,
response selection, and gameplay effects.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable


HOLDOUT_PATH = Path(__file__).with_name("c7f_heldout_conversations.json")
ALLOWED_SOURCE_REFS = frozenset({"WordNet 3.0", "MASSIVE", "SGD"})
MAX_CASES = 32
MAX_UTTERANCE = 256


def load_c7f_holdout(path: Path = HOLDOUT_PATH) -> dict[str, Any]:
    """Load and validate the bounded, evaluation-only holdout manifest."""

    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read C7F holdout {path}: {error}") from error
    if not isinstance(document, dict) or document.get("schemaVersion") != 1:
        raise ValueError("C7F holdout requires schemaVersion 1")
    if document.get("rawCorpusPackaged") is not False:
        raise ValueError("C7F holdout must not package raw corpus data")
    cases = document.get("cases")
    if not isinstance(cases, list) or not cases or len(cases) > MAX_CASES:
        raise ValueError(f"C7F holdout requires 1..{MAX_CASES} cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("C7F holdout cases must be objects")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            raise ValueError("C7F holdout case IDs must be unique non-empty strings")
        seen.add(case_id)
        setup = case.get("setup", [])
        if not isinstance(setup, list) or not all(
            isinstance(value, str) and 0 < len(value) <= MAX_UTTERANCE
            for value in setup
        ):
            raise ValueError(f"C7F holdout setup is invalid for {case_id}")
        utterance = case.get("utterance")
        if not isinstance(utterance, str) or not 0 < len(utterance) <= MAX_UTTERANCE:
            raise ValueError(f"C7F holdout utterance is invalid for {case_id}")
        source_refs = case.get("sourceRefs", [])
        if not isinstance(source_refs, list) or any(
            ref not in ALLOWED_SOURCE_REFS for ref in source_refs
        ):
            raise ValueError(f"C7F holdout sourceRefs are invalid for {case_id}")
        expected = case.get("expected")
        if not isinstance(expected, dict) or not isinstance(
            expected.get("recognized"), bool
        ):
            raise ValueError(f"C7F holdout expected result is invalid for {case_id}")
    return document


def _record_is_recognized(turn: dict[str, Any]) -> bool:
    result = turn.get("result") if isinstance(turn, dict) else None
    ir = result.get("ir", {}) if isinstance(result, dict) else {}
    diagnostics = ir.get("diagnostics", {}) if isinstance(ir, dict) else {}
    return bool(
        isinstance(ir, dict)
        and diagnostics.get("noMatch") is not True
        and ir.get("intent") is not None
    )


def _semantic_match(expected: dict[str, Any], turn: dict[str, Any]) -> bool:
    result = turn.get("result", {})
    ir = result.get("ir", {}) if isinstance(result, dict) else {}
    if not isinstance(ir, dict):
        return False
    if _record_is_recognized(turn) is not expected.get("recognized"):
        return False
    for field in ("intent", "subject", "action"):
        if field in expected and ir.get(field) != expected[field]:
            return False
    pattern = expected.get("pattern")
    if pattern is not None and ir.get("provenance", {}).get("pattern") != pattern:
        return False
    return True


def _has_gameplay_effects(turn: dict[str, Any]) -> bool:
    result = turn.get("result", {})
    action_result = result.get("actionResult") if isinstance(result, dict) else None
    return bool(
        turn.get("dispatchTransport", turn.get("transport"))
        or turn.get("toolCalls")
        or action_result is not None
    )


def score_c7f_holdout(
    cases: Iterable[dict[str, Any]],
    turns: Iterable[dict[str, Any]],
) -> dict[str, Any]:
    """Score semantic recognition and protected-effect behavior."""

    rows: list[dict[str, Any]] = []
    true_positive = false_positive = false_negative = 0
    protected_count = false_dispatch = 0
    for case, turn in zip(cases, turns):
        expected = case["expected"]
        semantic_match = _semantic_match(expected, turn)
        if expected["recognized"]:
            if semantic_match:
                true_positive += 1
            else:
                false_negative += 1
        elif _record_is_recognized(turn):
            false_positive += 1
        if expected.get("noGameplayEffects") is True:
            protected_count += 1
            if _has_gameplay_effects(turn):
                false_dispatch += 1
        rows.append({
            "id": case["id"],
            "semanticMatch": semantic_match,
            "recognized": _record_is_recognized(turn),
            "pattern": turn.get("result", {})
            .get("ir", {})
            .get("provenance", {})
            .get("pattern"),
            "effects": _has_gameplay_effects(turn),
        })
    denominator = true_positive + false_positive
    return {
        "caseCount": len(rows),
        "truePositive": true_positive,
        "falsePositive": false_positive,
        "falseNegative": false_negative,
        "precision": true_positive / denominator if denominator else 1.0,
        "recall": true_positive / (true_positive + false_negative)
        if true_positive + false_negative else 1.0,
        "protectedCaseCount": protected_count,
        "falseExecutableDispatch": false_dispatch,
        "falseExecutableDispatchRate": false_dispatch / protected_count
        if protected_count else 0.0,
        "cases": rows,
    }


__all__ = ["HOLDOUT_PATH", "load_c7f_holdout", "score_c7f_holdout"]
