"""Execution, side-effect, authority, and acceptance-chain projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import bounded, dossier_changes


def project(
    state: dict[str, Any],
    semantics: dict[str, Any],
    response_projection: dict[str, Any],
) -> dict[str, Any]:
    record = state["record"]
    observation = state["observation"]
    result = state["result"]
    ir = state["ir"]
    flow = state["flow"]
    decision = state["decision"]
    response = state["response"]
    action_result = state["action_result"]
    selected = state["selected"]
    visible_response = response_projection["visible"]
    flow_owner = "flow" if flow.get("matched") is True else "policy"
    execution = {
        "route": decision.get("route"),
        "branch": decision.get("branch"),
        "owner": flow_owner,
        "status": action_result.get("status"),
        "accepted": action_result.get("accepted"),
        "requestID": action_result.get("requestID"),
        "npcID": action_result.get("npcID"),
        "speechAct": action_result.get("speechAct") or ir.get("speechAct"),
        "authority": action_result.get("authority"),
        "result": bounded(action_result, limit=24),
        "rejectionReason": action_result.get("reason"),
        "finalText": visible_response.get("text"),
        "responseTemplate": response.get("templateID"),
        "responsePool": response.get("sourcePoolID"),
    }
    selected_binding = selected.get("binding")
    if not isinstance(selected_binding, dict):
        selected_binding = action_result.get("binding")
    # This is a fixed evidence contract, not an arbitrary map. Bound each
    # value independently so adding fact/dispatch counts cannot hide the
    # original wire count behind the generic eight-key dictionary limit.
    raw_effects = observation.get("sideEffects", {})
    side_effects = {
        name: bounded(raw_effects[name])
        for name in (
            "none", "actionCount", "transportCount", "actionsTruncated",
            "transportTruncated", "actions", "transport", "noGameplayEffects",
            "factTransportCount", "dispatchTransportCount", "dispatchTransport",
            "factTransport",
        )
        if isinstance(raw_effects, dict) and name in raw_effects
    }
    dispatches = record.get("dispatchTransport", record.get("transport", []))
    facts = record.get("factTransport", [])
    effects = {
        "dispatchTransportCount": len(dispatches) if isinstance(dispatches, list) else 0,
        "factTransportCount": len(facts) if isinstance(facts, list) else 0,
        "transportCount": len(record.get("transport", []))
        if isinstance(record.get("transport", []), list)
        else 0,
        "toolCallCount": len(record.get("toolCalls", []))
        if isinstance(record.get("toolCalls", []), list)
        else 0,
        "sideEffects": side_effects,
    }
    is_gameplay_action = bool(
        ir.get("action") or action_result or selected_binding
    )
    command_authority = {
        "isGameplayAction": is_gameplay_action,
        "action": ir.get("action"),
        "route": decision.get("route"),
        "branch": decision.get("branch"),
        "accepted": action_result.get("accepted"),
        "status": action_result.get("status"),
        "authority": action_result.get("authority"),
        "capabilityID": action_result.get("capabilityID")
        or selected.get("capabilityID"),
        "binding": bounded(selected_binding, limit=24),
        "effects": effects,
        "result": bounded(action_result, limit=24),
    }
    translation = record.get("translation", {})
    translation = translation if isinstance(translation, dict) else {}
    acceptance_chain = {
        "utterance": record.get("input"),
        "selectedCodeBlock": bounded(semantics["codeblock"], limit=16),
        "selectedGraph": bounded(semantics["graph"], limit=24),
        "coreMeaning": bounded(semantics["understanding"], limit=16),
        "factProvider": semantics["fact_provider"],
        "knowledgePermission": bounded(
            semantics["knowledge_permission"], limit=16
        ),
        "translation": bounded(translation, limit=24),
        "actualNPCResponse": bounded(visible_response, limit=16),
        "gameplayEffects": bounded(effects, limit=24),
        "dossierChanges": bounded(
            dossier_changes(record.get("contextBefore"), state["context"]),
            limit=24,
        ),
    }
    return {
        "execution": execution,
        "effects": effects,
        "effects_output": {
            "transport": bounded(record.get("transport", [])),
            "toolCalls": bounded(record.get("toolCalls", [])),
            "sideEffects": side_effects,
        },
        "command_authority": command_authority,
        "acceptance_chain": acceptance_chain,
    }
