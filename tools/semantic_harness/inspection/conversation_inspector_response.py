"""Visible response and dialogue-planning projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import bounded


def _visible_text(record: dict[str, Any], response: dict[str, Any]) -> dict[str, Any]:
    messages = record.get("messages", [])
    npc_message = next(
        (
            message
            for message in messages
            if isinstance(message, dict) and message.get("speaker") == "npc"
        ),
        {},
    )
    payload = npc_message.get("payload", {}) if isinstance(npc_message, dict) else {}
    payload = payload if isinstance(payload, dict) else {}
    translation = record.get("translation")
    return {
        "text": payload.get("text") or response.get("text") or response.get("fallback"),
        "fallback": payload.get("fallback") or response.get("fallback"),
        "translationKey": payload.get("translationKey") or response.get("templateID"),
        "language": translation.get("language")
        if isinstance(translation, dict)
        else None,
    }


def project(state: dict[str, Any]) -> dict[str, Any]:
    record = state["record"]
    response = state["response"]
    plan = state["plan"]
    flow = state["flow"]
    response_refs = state["response_refs"]
    visible_response = _visible_text(record, response)
    dialogue_planning = {
        "topic": (plan or {}).get("topic") or response.get("topic"),
        "dialogueAct": (plan or {}).get("dialogueAct")
        or response.get("dialogueAct"),
        "sourcePoolID": (plan or {}).get("sourcePoolID")
        or response.get("sourcePoolID"),
        "selectionSource": response.get("selectionSource"),
        "tone": (plan or {}).get("tone") or response.get("tone"),
        "uncertainty": (plan or {}).get("uncertainty")
        or response.get("uncertainty"),
        "groundedFactRefs": bounded(
            (plan or {}).get("groundedFactRefs") or response_refs
        ),
        "turns": bounded((plan or {}).get("turns", []), limit=8),
        "flow": bounded(flow, limit=24),
    }
    final_response = bounded(
        {
            **visible_response,
            "templateID": response.get("templateID"),
            "selectionSource": response.get("selectionSource"),
            "groundedFactRefs": response_refs,
        },
        limit=16,
    )
    return {
        "visible": visible_response,
        "planning": dialogue_planning,
        "final": final_response,
    }
