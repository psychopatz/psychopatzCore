"""Bounded Conversation State Inspector projection for Semantic Lab.

The inspector is a read-only view over a real worker turn or snapshot. It
does not retain a transcript or create a second context store.
"""

from __future__ import annotations

from typing import Any

from .conversation_inspector_authority import project as project_authority
from .conversation_inspector_chain import project as project_chain
from .conversation_inspector_context import project as project_context
from .conversation_inspector_persona import project as project_persona
from .conversation_inspector_response import project as project_response
from .conversation_inspector_semantics import project as project_semantics
from .conversation_inspector_state import normalize
from tools.semantic_harness.inspection.conversation_inspector_support import MAX_TRACE_ITEMS, bounded


def build_conversation_inspector(record: dict[str, Any]) -> dict[str, Any]:
    """Return a bounded, read-only state/plan/trace view for the Lab UI."""

    state = normalize(record)
    context_projection = project_context(state)
    persona_choices = project_persona(state)
    semantic_projection = project_semantics(state)
    response_projection = project_response(state)
    chain_projection = project_chain(state)
    authority_projection = project_authority(
        state, semantic_projection, response_projection
    )
    return {
        "schemaVersion": 1,
        "source": "real_lua_worker",
        "input": state["record"].get("input"),
        "turn": context_projection["turn"],
        "context": context_projection["context"],
        "memoryProvenance": context_projection["memoryProvenance"],
        "understanding": bounded(
            semantic_projection["understanding"], limit=16
        ),
        "surface": chain_projection["surface"],
        "candidateSelection": chain_projection["candidateSelection"],
        "discourse": chain_projection["discourse"],
        "affordances": chain_projection["affordances"],
        "realization": chain_projection["realization"],
        "storagePointers": chain_projection["storagePointers"],
        "socialEffect": chain_projection["socialEffect"],
        "facts": bounded(semantic_projection["facts"], limit=32),
        "socialContext": bounded(
            semantic_projection["social_context"], limit=48
        ),
        "acceptanceChain": authority_projection["acceptance_chain"],
        "dialoguePlanning": bounded(
            response_projection["planning"], limit=24
        ),
        "finalResponse": response_projection["final"],
        "commandAuthority": bounded(
            authority_projection["command_authority"], limit=24
        ),
        "personaChoices": persona_choices,
        "semantic": {
            "intent": state["ir"].get("intent")
            or state["observation"].get("ir", {}).get("intent"),
            "speechAct": state["ir"].get("speechAct")
            or state["observation"].get("ir", {}).get("speechAct"),
            "subject": state["ir"].get("subject")
            or state["observation"].get("ir", {}).get("subject"),
            "pattern": state["ir"].get("provenance", {}).get("pattern")
            if isinstance(state["ir"].get("provenance"), dict)
            else state["observation"].get("ir", {}).get("pattern"),
            "confidence": state["ir"].get("confidence")
            or state["observation"].get("ir", {}).get("confidence"),
            "selectedCandidate": bounded(state["selected"]),
        },
        "dialoguePlan": bounded(state["plan"], limit=32),
        "selectedFlow": bounded(state["flow"], limit=32),
        "dialogueDirector": bounded(
            state["observation"].get("director", {}), limit=64
        ),
        "interactionPlan": bounded(
            state["observation"].get("interactionPlan", {}), limit=32
        ),
        "visibleResponse": bounded(response_projection["visible"]),
        "execution": bounded(
            authority_projection["execution"], limit=24
        ),
        "workerTrace": bounded(
            state["record"].get("trace", []), limit=MAX_TRACE_ITEMS
        ),
        "effects": authority_projection["effects_output"],
    }


__all__ = ["build_conversation_inspector"]
