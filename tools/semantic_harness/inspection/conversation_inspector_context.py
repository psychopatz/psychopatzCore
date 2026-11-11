"""Turn, dialogue-context, and memory provenance projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import bounded


def project(state: dict[str, Any]) -> dict[str, Any]:
    record = state["record"]
    context = state["context"]
    dialogue = state["dialogue"]
    plan = state["plan"]
    response = state["response"]
    return {
        "turn": {
            "type": record.get("type"),
            "accepted": record.get("accepted") is True,
            "sequence": dialogue.get("sequence"),
            "lastIntent": dialogue.get("lastIntent"),
            "lastSpeaker": dialogue.get("lastSpeaker"),
            "llmCalls": record.get("llmCalls", 0),
        },
        "context": {
            "currentTopic": dialogue.get("currentTopic"),
            "previousTopic": dialogue.get("previousTopic"),
            "priorTopics": bounded(dialogue.get("priorTopics", []), limit=16),
            "focus": bounded(dialogue.get("focus", []), limit=16),
            "mentions": bounded(dialogue.get("mentions", []), limit=16),
            "pendingObligation": bounded(
                dialogue.get("pendingFollowUp"), limit=32
            ),
            "agenda": bounded(dialogue.get("agenda", []), limit=16),
            "flowSessions": bounded(dialogue.get("flowSessions", []), limit=16),
            "engineFacts": bounded(context.get("engineFacts", {}), limit=32),
            "engineEvents": bounded(context.get("engineEvents", []), limit=16),
        },
        "memoryProvenance": {
            "planFactRefs": bounded(state["plan_refs"]),
            "responseFactRefs": bounded(state["response_refs"]),
            "irFacts": bounded(state["facts"]),
            "uncertainty": plan.get("uncertainty")
            if plan
            else response.get("uncertainty"),
        },
    }
