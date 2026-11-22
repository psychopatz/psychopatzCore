"""Turn, dialogue-context, lane ownership, disposition, grounding, and role projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import (
    bounded,
    fact_providers,
)


def _dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _non_empty_str(value: Any) -> str | None:
    if isinstance(value, str):
        text = value.strip()
        return text if text else None
    return None


def _first_str(*values: Any) -> str | None:
    for value in values:
        text = _non_empty_str(value)
        if text is not None:
            return text
    return None


def _lane_ownership(state: dict[str, Any]) -> dict[str, Any]:
    context = _dict(state.get("context"))
    dialogue = _dict(state.get("dialogue"))
    observation = _dict(state.get("observation"))
    interaction = _dict(observation.get("interactionPlan"))
    flow = _dict(state.get("flow"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))
    ir = _dict(state.get("ir"))
    ir_ext = _dict(ir.get("extensions"))

    raw_lane = _first_str(
        interaction.get("lane"),
        flow.get("lane"),
        plan.get("lane"),
        response.get("lane"),
        dialogue.get("lane"),
        context.get("lane"),
        ir_ext.get("lane"),
    )
    lane = raw_lane.lower() if raw_lane and raw_lane.lower() in {"scene", "beat"} else None

    scene_id = _first_str(
        interaction.get("sceneID"),
        flow.get("sceneID"),
        plan.get("sceneID"),
        response.get("sceneID"),
        dialogue.get("sceneID"),
        context.get("sceneID"),
        ir_ext.get("sceneID"),
    )
    thread_id = _first_str(
        interaction.get("threadID"),
        flow.get("threadID"),
        plan.get("threadID"),
        response.get("threadID"),
        dialogue.get("threadID"),
        context.get("threadID"),
        ir_ext.get("threadID"),
    )

    if lane is None:
        if scene_id is not None and thread_id is None:
            lane = "scene"
        elif thread_id is not None or _first_str(interaction.get("beatID"), flow.get("beatID")):
            lane = "beat"

    warning: str | None = None
    if scene_id is not None and thread_id is not None:
        warning = (
            f"sceneID ({scene_id!r}) and threadID ({thread_id!r}) both set inconsistently"
        )
    elif lane == "scene" and thread_id is not None:
        warning = f"lane='scene' conflicts with threadID={thread_id!r}"
    elif lane == "beat" and scene_id is not None:
        warning = f"lane='beat' conflicts with sceneID={scene_id!r}"

    return {
        "lane": lane,
        "sceneID": scene_id,
        "threadID": thread_id,
        "sceneThreadCollision": warning is not None,
        "collisionWarning": warning,
    }


def _disposition_contribution(state: dict[str, Any]) -> dict[str, Any]:
    context = _dict(state.get("context"))
    actor_ctx = _dict(context.get("actorConversationContext"))
    social_ctx = _dict(context.get("socialContext"))
    speech_style = _dict(context.get("speechStyleContext"))
    observation = _dict(state.get("observation"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))

    contrib: dict[str, Any] = {}
    for candidate in (
        actor_ctx.get("dispositionContribution"),
        social_ctx.get("dispositionContribution"),
        context.get("dispositionContribution"),
        observation.get("dispositionContribution"),
        plan.get("dispositionContribution"),
        response.get("dispositionContribution"),
    ):
        if isinstance(candidate, dict):
            contrib = candidate
            break

    base = contrib.get("baseDisposition")
    if base is None:
        base = actor_ctx.get("baseDisposition")
    demeanor = contrib.get("temporaryDemeanor")
    if demeanor is None:
        demeanor = actor_ctx.get("temporaryDemeanor")
    effective = contrib.get("effectiveDisposition")
    if effective is None:
        effective = actor_ctx.get("effectiveDisposition")
    style_profile = contrib.get("styleProfile")
    if style_profile is None:
        style_profile = (
            speech_style.get("styleProfile")
            or speech_style.get("profile")
            or speech_style.get("tone")
        )

    return bounded(
        {
            "baseDisposition": base,
            "temporaryDemeanor": demeanor,
            "effectiveDisposition": effective,
            "styleProfile": style_profile,
        },
        limit=16,
    )


def _constraint_reasons(state: dict[str, Any]) -> list[Any]:
    observation = _dict(state.get("observation"))
    diagnostics = _dict(state.get("diagnostics"))
    decision = _dict(state.get("decision"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))
    selection = _dict(diagnostics.get("candidateSelection"))

    reasons: list[Any] = []
    seen: set[str] = set()
    for source in (
        response.get("constraintReasons"),
        plan.get("constraintReasons"),
        diagnostics.get("constraintReasons"),
        decision.get("constraintReasons"),
        observation.get("constraintReasons"),
        selection.get("constraintReasons"),
    ):
        if not isinstance(source, list):
            continue
        for item in source:
            marker = repr(item)
            if marker not in seen:
                seen.add(marker)
                reasons.append(item)
    return bounded(reasons, limit=16)


def _normalize_epistemic_status(
    state: dict[str, Any], grounding_refs: list[Any]
) -> str:
    diagnostics = _dict(state.get("diagnostics"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))
    raw = _first_str(
        response.get("epistemicStatus"),
        plan.get("epistemicStatus"),
        diagnostics.get("epistemicStatus"),
    )
    if raw and raw.lower() in {"known", "uncertain", "unknown"}:
        return raw.lower()

    fact_status = state.get("fact_status")
    if isinstance(fact_status, str):
        low = fact_status.strip().lower()
        if low in {"known", "grounded", "verified", "certain"}:
            return "known"
        if low in {"uncertain", "partial", "unverified"}:
            return "uncertain"
        if low in {"unknown", "missing", "none"}:
            return "unknown"
    if fact_status is True:
        return "uncertain"
    if grounding_refs:
        return "known"
    return "unknown"


def _grounding_and_epistemic(state: dict[str, Any]) -> dict[str, Any]:
    context = _dict(state.get("context"))
    dialogue = _dict(state.get("dialogue"))
    diagnostics = _dict(state.get("diagnostics"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))
    action_result = _dict(state.get("action_result"))
    facts = _dict(state.get("facts"))

    refs: list[Any] = []
    seen: set[str] = set()
    for source in (
        response.get("groundingRefs"),
        plan.get("groundingRefs"),
        diagnostics.get("groundingRefs"),
        state.get("response_refs"),
        state.get("plan_refs"),
    ):
        if not isinstance(source, list):
            continue
        for ref in source:
            marker = repr(ref)
            if marker not in seen:
                seen.add(marker)
                refs.append(ref)

    knowledge_provenance = (
        response.get("knowledgeProvenance")
        or plan.get("knowledgeProvenance")
        or diagnostics.get("knowledgeProvenance")
        or context.get("knowledgeProvenance")
    )
    if knowledge_provenance is None:
        providers = fact_providers(facts)
        if providers or diagnostics.get("factProvider"):
            knowledge_provenance = {
                "providers": providers,
                "factProvider": diagnostics.get("factProvider"),
                "scope": "player_scoped_npc_knowledge",
            }

    memory_salience = response.get("memorySalience")
    if memory_salience is None:
        memory_salience = plan.get("memorySalience")
    if memory_salience is None:
        memory_salience = diagnostics.get("memorySalience")
    if memory_salience is None:
        memory_salience = dialogue.get("memorySalience")
    if memory_salience is None:
        memory_salience = context.get("memorySalience")
    if memory_salience is None:
        memory_salience = action_result.get("memorySalience")

    epistemic_status = _normalize_epistemic_status(state, refs)
    return {
        "groundingRefs": bounded(refs, limit=16),
        "knowledgeProvenance": bounded(knowledge_provenance, limit=16),
        "epistemicStatus": epistemic_status,
        "memorySalience": bounded(memory_salience, limit=16),
    }


def _actor_roles(state: dict[str, Any]) -> dict[str, Any]:
    context = _dict(state.get("context"))
    actor_ctx = _dict(context.get("actorConversationContext"))
    dialogue = _dict(state.get("dialogue"))
    observation = _dict(state.get("observation"))
    interaction = _dict(observation.get("interactionPlan"))
    plan = _dict(state.get("plan"))
    response = _dict(state.get("response"))
    ir = _dict(state.get("ir"))
    ir_ext = _dict(ir.get("extensions"))
    discourse_frame = _dict(ir_ext.get("discourseFrame"))

    roles: dict[str, Any] = {}
    for candidate in (
        response.get("actorRoles"),
        plan.get("actorRoles"),
        interaction.get("actorRoles"),
        observation.get("actorRoles"),
        ir.get("actorRoles"),
        ir_ext.get("actorRoles"),
        discourse_frame.get("actorRoles"),
        dialogue.get("actorRoles"),
        actor_ctx.get("actorRoles"),
        context.get("actorRoles"),
    ):
        if isinstance(candidate, dict) and candidate:
            roles = dict(candidate)
            break

    if not roles:
        if dialogue.get("lastSpeaker") is not None:
            roles["speaker"] = dialogue.get("lastSpeaker")
        if actor_ctx.get("conversationAudience") is not None:
            roles["audience"] = actor_ctx.get("conversationAudience")

    return bounded(roles, limit=16)


def project(state: dict[str, Any]) -> dict[str, Any]:
    record = state["record"]
    context = state["context"]
    dialogue = state["dialogue"]
    plan = state["plan"]
    response = state["response"]
    grounding = _grounding_and_epistemic(state)
    return {
        "turn": {
            "type": record.get("type"),
            "accepted": record.get("accepted") is True,
            "sequence": dialogue.get("sequence"),
            "lastIntent": dialogue.get("lastIntent"),
            "lastSpeaker": dialogue.get("lastSpeaker"),
            "llmCalls": record.get("llmCalls", 0),
        },
        "laneOwnership": _lane_ownership(state),
        "dispositionContribution": _disposition_contribution(state),
        "constraintReasons": _constraint_reasons(state),
        "actorRoles": _actor_roles(state),
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
            "groundingRefs": grounding["groundingRefs"],
            "knowledgeProvenance": grounding["knowledgeProvenance"],
            "epistemicStatus": grounding["epistemicStatus"],
            "memorySalience": grounding["memorySalience"],
        },
    }
