"""Bounded end-to-end conversation-chain projection for Semantic Lab.

This module intentionally emits small diagnostic rows, not a second worker
snapshot. Canonical storage details stay behind the C5 discovery service and
are referenced here only by stable IDs.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    conversation_context_health,
    conversation_discovery_index,
    render_conversation_runtime_plan,
)

from tools.semantic_harness.inspection.conversation_inspector_support import bounded


MAX_CANDIDATES = 8
MAX_REJECTIONS = 6
MAX_AFFORDANCES = 8
MAX_STORAGE_POINTERS = 12
REPOSITORY = Path(__file__).resolve().parents[3]


@lru_cache(maxsize=1)
def _storage_projection() -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
    """Compile the lightweight C5 routing index once per inspector process."""

    try:
        model = compile_conversation_sources(REPOSITORY)
        _modules, reports = render_conversation_runtime_plan(model)
        index = conversation_discovery_index(model, reports)
        health = conversation_context_health(model, reports)
        return index, health
    except (OSError, ValueError, TypeError):
        return {}, {"status": "unavailable", "errors": ["compiler_unavailable"]}


def _dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _message_payload(record: dict[str, Any]) -> dict[str, Any]:
    for message in _list(record.get("messages")):
        if not isinstance(message, dict) or message.get("speaker") != "npc":
            continue
        payload = message.get("payload")
        if isinstance(payload, dict):
            return payload
    return {}


def _compact_candidate(row: Any) -> dict[str, Any] | None:
    if not isinstance(row, dict):
        return None
    return {
        key: row.get(key)
        for key in (
            "patternID",
            "intent",
            "speechAct",
            "action",
            "baseConfidence",
            "contextualSupport",
            "contextualScore",
            "evidence",
        )
        if row.get(key) is not None
    }


def surface_and_candidates(state: dict[str, Any]) -> dict[str, Any]:
    ir = state["ir"]
    diagnostics = state["diagnostics"]
    provenance = _dict(ir.get("provenance"))
    recovery = diagnostics.get("surfaceRecovery")
    if not isinstance(recovery, dict):
        recovery = provenance.get("surfaceRecovery")
    recovery = recovery if isinstance(recovery, dict) else None
    selection = _dict(diagnostics.get("candidateSelection"))

    rows = [
        compact
        for row in _list(selection.get("rows"))[:MAX_CANDIDATES]
        if (compact := _compact_candidate(row)) is not None
    ]
    rejections = []
    for row in _list(selection.get("rejections"))[:MAX_REJECTIONS]:
        if not isinstance(row, dict):
            continue
        rejections.append(
            {
                key: row.get(key)
                for key in ("patternID", "pass", "score", "reason", "details")
                if row.get(key) is not None
            }
        )

    return {
        "surface": {
            "raw": ir.get("rawText") or state["record"].get("input"),
            "normalized": ir.get("normalizedText"),
            "candidatePass": diagnostics.get("candidatePass")
            or provenance.get("candidatePass"),
            "exact": diagnostics.get("exactMatch"),
            "fuzzy": diagnostics.get("fuzzyMatch"),
            "recovered": diagnostics.get("recoveredMatch"),
            "recovery": bounded(recovery, limit=16) if recovery else None,
            "correctedTokens": bounded(
                diagnostics.get("correctedTokens", []), limit=8
            ),
            "unmatchedTokens": bounded(
                diagnostics.get("unmatchedTokens", []), limit=8
            ),
        },
        "candidateSelection": {
            "reason": selection.get("reason"),
            "selectedPattern": selection.get("selectedPattern"),
            "selectedPass": selection.get("selectedPass"),
            "selectedConfidence": selection.get("selectedConfidence"),
            "selectedContextualSupport": selection.get(
                "selectedContextualSupport"
            ),
            "selectedContextualScore": selection.get(
                "selectedContextualScore"
            ),
            "margin": selection.get("margin"),
            "candidateCount": selection.get("candidateCount"),
            "eligibleCount": selection.get("eligibleCount"),
            "rejectedCount": selection.get("rejectedCount"),
            "rows": bounded(rows, limit=MAX_CANDIDATES),
            "rejections": bounded(rejections, limit=MAX_REJECTIONS),
        },
    }


def discourse(state: dict[str, Any]) -> dict[str, Any]:
    ir = state["ir"]
    extensions = _dict(ir.get("extensions"))
    frame = _dict(extensions.get("discourseFrame"))
    return {
        "frame": bounded(frame, limit=24),
        "socialFeatures": bounded(
            _dict(extensions.get("socialFeatures")), limit=24
        ),
    }


def affordances(state: dict[str, Any]) -> dict[str, Any]:
    observation = state["observation"]
    suggestions = _dict(observation.get("suggestions"))
    candidates = _list(suggestions.get("candidates"))
    generated: list[dict[str, Any]] = []
    authored_count = 0
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        if candidate.get("providerID") != "projecthoomans.generated_affordances":
            authored_count += 1
            continue
        if len(generated) >= MAX_AFFORDANCES:
            continue
        frame = _dict(candidate.get("frame"))
        extensions = _dict(frame.get("extensions"))
        dynamic = _dict(extensions.get("dynamicAffordance"))
        generated.append(
            {
                "id": candidate.get("id"),
                "origin": candidate.get("origin") or dynamic.get("origin"),
                "stance": candidate.get("stance") or dynamic.get("stance"),
                "strategy": candidate.get("strategy") or dynamic.get("strategy"),
                "topic": candidate.get("topic") or frame.get("topic"),
                "rank": candidate.get("rank"),
                "groupID": candidate.get("groupID"),
                "contextReason": candidate.get("contextReason"),
                "source": bounded(candidate.get("source"), limit=8),
                "evidence": bounded(dynamic.get("evidence"), limit=12),
                "semanticFrame": bounded(
                    {
                        "intent": frame.get("intent"),
                        "speechAct": frame.get("speechAct"),
                        "action": frame.get("action"),
                        "subject": frame.get("subject"),
                        "topic": frame.get("topic"),
                        "target": frame.get("target"),
                        "discourseFrame": extensions.get("discourseFrame"),
                    },
                    limit=16,
                ),
                "display": bounded(candidate.get("display"), limit=8),
            }
        )

    ir = state["ir"]
    provenance = _dict(ir.get("provenance"))
    ir_extensions = _dict(ir.get("extensions"))
    selected_frame: dict[str, Any] | None = None
    if provenance.get("parser") == "semantic_click_frame":
        selected_frame = {
            "candidateID": provenance.get("candidateID"),
            "providerID": provenance.get("providerID")
            or provenance.get("provider"),
            "intent": ir.get("intent"),
            "speechAct": ir.get("speechAct"),
            "action": ir.get("action"),
            "subject": ir.get("subject"),
            "topic": ir_extensions.get("topic"),
            "dynamicAffordance": bounded(
                ir_extensions.get("dynamicAffordance"), limit=16
            ),
            "discourseFrame": bounded(
                ir_extensions.get("discourseFrame"), limit=20
            ),
            "realizedPlayerUtterance": ir.get("rawText"),
        }

    return {
        "totalCandidateCount": len(candidates),
        "authoredOrExistingCount": authored_count,
        "generatedCount": len(generated),
        "generated": generated,
        "selectedSemanticFrame": bounded(selected_frame, limit=24)
        if selected_frame
        else None,
    }


def realization(state: dict[str, Any]) -> dict[str, Any]:
    response = state["response"]
    payload = _message_payload(state["record"])
    plan = payload.get("utterancePlan")
    realized = payload.get("utteranceRealization")
    return {
        "canonical": {
            "templateID": response.get("templateID"),
            "fallback": response.get("fallback"),
            "selectionID": response.get("selectionID"),
            "sourcePoolID": response.get("sourcePoolID"),
        },
        "presentation": {
            "text": payload.get("text"),
            "semanticTemplateID": payload.get("semanticTemplateID"),
            "realizationFamily": payload.get("realizationFamily"),
            "realizationVariant": payload.get("realizationVariant"),
            "speechStyleVariant": payload.get("speechStyleVariant"),
            "phraseFamilyID": payload.get("phraseFamilyID"),
            "phraseID": payload.get("phraseID"),
            "utterancePlanFallbackReason": payload.get(
                "utterancePlanFallbackReason"
            ),
        },
        "utterancePlan": bounded(plan, limit=24)
        if isinstance(plan, dict)
        else None,
        "utteranceRealization": bounded(realized, limit=16)
        if isinstance(realized, dict)
        else None,
    }


def storage_pointers(state: dict[str, Any]) -> dict[str, Any]:
    ir = state["ir"]
    response = state["response"]
    observation = state["observation"]
    interaction = _dict(observation.get("interactionPlan"))
    provenance = _dict(ir.get("provenance"))
    payload = _message_payload(state["record"])
    realized = _dict(payload.get("utteranceRealization"))
    index, health = _storage_projection()

    pointers: list[dict[str, Any]] = []
    seen: set[str] = set()

    def add(kind: str, canonical_id: Any) -> None:
        value = str(canonical_id or "")
        if not value or value in seen or len(pointers) >= MAX_STORAGE_POINTERS:
            return
        seen.add(value)
        resolved = index.get(value)
        row: dict[str, Any] = {
            "kind": kind,
            "id": value,
            "resolved": isinstance(resolved, dict),
        }
        if isinstance(resolved, dict):
            row.update(
                {
                    "ownerKind": resolved.get("kind"),
                    "domain": resolved.get("domain"),
                    "source": resolved.get("source"),
                    "generated": bounded(
                        resolved.get("generated", []), limit=6
                    ),
                    "related": bounded(
                        resolved.get("related", []), limit=8
                    ),
                    "dependents": bounded(
                        resolved.get("dependents", []), limit=8
                    ),
                }
            )
        pointers.append(row)

    add("pattern", provenance.get("pattern"))
    if response.get("templateID"):
        add("content", "phrase." + str(response["templateID"]))
    add("responsePool", response.get("sourcePoolID"))
    add("beat", interaction.get("beatID"))
    add("behavior", interaction.get("behaviorID"))
    add("realization", realized.get("constructionID"))
    for lexeme_id in _list(realized.get("lexemeIDs"))[:6]:
        add("realization", lexeme_id)

    return {
        "records": pointers,
        "contextHealth": {
            "status": health.get("status"),
            "errorCount": len(_list(health.get("errors"))),
            "numericShardViolationCount": len(
                _list(health.get("numericShardViolations"))
            ),
            "opaqueShardViolationCount": len(
                _list(health.get("opaqueShardViolations"))
            ),
            "missingOwnershipCount": len(
                _list(health.get("missingOwnership"))
            ),
        },
        "lookup": "SemanticLabAuthoringService.conversation_discovery_record(id)",
        "closure": "SemanticLabAuthoringService.conversation_affected_closure(id)",
    }


def social_effect(state: dict[str, Any]) -> dict[str, Any]:
    action = state["action_result"]
    observation = state["observation"]
    decision = state["decision"]
    ir = state["ir"]
    interaction = _dict(observation.get("interactionPlan"))
    conduct_outcome = _dict(action.get("conductEvidenceOutcome"))

    relevant = bool(
        action.get("eventType")
        or action.get("conductPersistence")
        or action.get("relationshipDelta")
    )
    return {
        "present": relevant,
        "interaction": {
            "intent": ir.get("intent"),
            "speechAct": ir.get("speechAct"),
            "branch": decision.get("branch"),
            "understood": bool(ir.get("intent") or ir.get("speechAct")),
        },
        "reaction": {
            "beatID": interaction.get("beatID"),
            "behaviorID": interaction.get("behaviorID"),
            "dialogueAct": interaction.get("dialogueAct"),
            "responseTemplate": state["response"].get("templateID"),
        },
        "relationshipEffect": {
            "accepted": action.get("accepted"),
            "status": action.get("status"),
            "reason": action.get("reason"),
            "eventType": action.get("eventType"),
            "memoryRecorded": action.get("memoryRecorded"),
            "visibleRelationshipChange": action.get(
                "visibleRelationshipChange"
            ),
            "delta": bounded(action.get("relationshipDelta"), limit=8),
        },
        "conductMemory": {
            "created": action.get("conductEvidenceCreated"),
            "status": conduct_outcome.get("status"),
            "persisted": conduct_outcome.get("persisted"),
            "pruned": conduct_outcome.get("pruned"),
            "dropped": conduct_outcome.get("dropped"),
            "total": conduct_outcome.get("total"),
            "attempts": bounded(
                action.get("conductPersistence", []), limit=8
            ),
        },
    }


def project(state: dict[str, Any]) -> dict[str, Any]:
    surface = surface_and_candidates(state)
    return {
        **surface,
        "discourse": discourse(state),
        "affordances": affordances(state),
        "realization": realization(state),
        "storagePointers": storage_pointers(state),
        "socialEffect": social_effect(state),
    }


__all__ = ["project"]
