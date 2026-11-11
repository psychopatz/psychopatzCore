"""Production-Lua selector coverage over explicit hypothetical fixture contexts.

Only actual ResponseCatalog.ExplainSelection decides eligibility/ranking. This
service summarizes returned evidence; it never guesses conditions or asserts
global impossibility from a limited matrix.
"""
from __future__ import annotations

from typing import Any

from tools.semantic_harness.runtime.worker import LuaSemanticWorker

MAX_CONTEXTS = 16


def selection_coverage(
    worker: LuaSemanticWorker, request: dict[str, Any],
) -> dict[str, Any]:
    if not isinstance(request, dict) or set(request) - {"poolID", "cases"}:
        raise ValueError("coverage requires poolID and cases only")
    pool_id = request.get("poolID")
    if not isinstance(pool_id, str) or not 1 <= len(pool_id) <= 96:
        raise ValueError("coverage poolID must be a valid registry ID")
    cases = request.get("cases")
    if not isinstance(cases, list) or not 1 <= len(cases) <= MAX_CONTEXTS:
        raise ValueError("coverage requires 1 to 16 bounded contexts")
    detail = worker.response_pool_detail(pool_id, limit=16)
    by_id = {
        row["id"]: {
            "variantID": row["id"],
            "testedCases": len(cases),
            "eligibleCases": 0, "selectedCases": 0,
            "failedCases": 0, "lowerRankedCases": 0,
            "tieCases": 0,
        } for row in detail["variants"]
    }
    rows = []
    for index, case in enumerate(cases):
        if (not isinstance(case, dict) or set(case) - {"label", "context", "salt"}
                or not isinstance(case.get("context"), dict)):
            raise ValueError("coverage case requires an explicit Lua context object")
        label = str(case.get("label") or f"context-{index+1}")
        salt = str(case.get("salt") or "")
        if len(label) > 96 or len(salt) > 128:
            raise ValueError("coverage label/salt exceeds bounded limit")
        explanation = worker.explain_response_selection(
            pool_id, case["context"], salt,
        )
        selected = explanation.get("selectedID")
        evidence = []
        for candidate in explanation.get("candidates", []):
            row = by_id.get(candidate["id"])
            if row is None:
                raise ValueError("selector returned unregistered candidate")
            if candidate["eligible"]:
                row["eligibleCases"] += 1
                if candidate["id"] == selected:
                    row["selectedCases"] += 1
                elif candidate.get("reason") == "lower_score":
                    row["lowerRankedCases"] += 1
                else:
                    row["tieCases"] += 1
            else:
                row["failedCases"] += 1
            evidence.append({
                "variantID": candidate["id"],
                "eligible": candidate["eligible"],
                "score": candidate.get("score"),
                "reason": candidate.get("reason"),
                "failedFields": [
                    check["field"] for check in candidate.get("checks", [])
                    if not check["matched"]
                ][:16],
            })
        rows.append({
            "label": label, "selectedID": selected,
            "tieCount": explanation.get("tieCount", 0),
            "antiRepeatRotated": explanation.get("rotated", False),
            "candidateEvidence": evidence,
        })
    summary = []
    for vid in sorted(by_id):
        variant = by_id[vid]
        if variant["eligibleCases"] == 0:
            status = "NOT_ELIGIBLE_IN_TESTED_CONTEXTS"
        elif variant["selectedCases"] == 0:
            status = "ELIGIBLE_BUT_NOT_SELECTED_IN_TESTED_CONTEXTS"
        else:
            status = "SELECTED_IN_TESTED_CONTEXTS"
        variant["testedStatus"] = status
        summary.append(variant)
    return {
        "ok": True, "type": "response_selection_coverage",
        "schemaVersion": 1, "sourceKind": "FIXTURE",
        "contextKind": "EXPLICIT_HYPOTHETICAL_RESPONSE_CONTEXT",
        "workerKind": "production_lua",
        "poolID": pool_id, "variantCount": detail["variantCount"],
        "registryRevision": detail["registryRevision"],
        "contentFingerprint": detail["contentFingerprint"],
        "caseCount": len(cases), "truncated": False,
        "noRuntimeSelectionOrGameplayMutation": True,
        "neverClaimsGloballyUnreachable": True,
        "variants": summary, "cases": rows,
    }
