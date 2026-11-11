"""Normalize the worker record consumed by inspector projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import (
    context,
    dialogue,
    observation,
    plan,
    response,
    trace_data,
)


def normalize(record: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(record, dict):
        record = {}
    context_value = context(record)
    observation_value = observation(record)
    response_value = response(record, observation_value)
    result = record.get("result", {})
    result = result if isinstance(result, dict) else {}
    ir = result.get("ir", {})
    ir = ir if isinstance(ir, dict) else {}
    flow = observation_value.get("flow", {})
    flow = flow if isinstance(flow, dict) else {}
    selected = observation_value.get("selectedCandidate", {})
    selected = selected if isinstance(selected, dict) else {}
    if not selected:
        selected = observation_value.get("candidates", {})
        selected = selected if isinstance(selected, dict) else {}
    extensions = ir.get("extensions", {})
    extensions = extensions if isinstance(extensions, dict) else {}
    facts = extensions.get("facts", {})
    facts = facts if isinstance(facts, dict) else {}
    plan_value = plan(response_value)
    plan_refs = plan_value.get("groundedFactRefs", []) if plan_value else []
    response_refs = response_value.get("groundedFactRefs", [])
    if not isinstance(plan_refs, list):
        plan_refs = []
    if not isinstance(response_refs, list):
        response_refs = []
    action_result = observation_value.get("actionResult")
    if not isinstance(action_result, dict):
        action_result = result.get("actionResult")
    if not isinstance(action_result, dict):
        action_result = {}
    decision = result.get("decision", {})
    decision = decision if isinstance(decision, dict) else {}
    diagnostics = ir.get("diagnostics", {})
    diagnostics = diagnostics if isinstance(diagnostics, dict) else {}
    fact_status = diagnostics.get("factStatus")
    if fact_status is None:
        fact_status = response_value.get("uncertainty")
    return {
        "record": record,
        "context": context_value,
        "dialogue": dialogue(context_value),
        "observation": observation_value,
        "response": response_value,
        "plan": plan_value,
        "result": result,
        "ir": ir,
        "flow": flow,
        "selected": selected,
        "facts": facts,
        "plan_refs": plan_refs,
        "response_refs": response_refs,
        "action_result": action_result,
        "decision": decision,
        "diagnostics": diagnostics,
        "fact_status": fact_status,
        "trace_data": trace_data(record),
    }
