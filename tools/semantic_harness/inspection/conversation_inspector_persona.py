"""Persona and choice projection for the conversation inspector."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import bounded


def project(state: dict[str, Any]) -> dict[str, Any]:
    record = state["record"]
    context = state["context"]
    observation = state["observation"]
    suggestions = observation.get("suggestions")
    suggestions = suggestions if isinstance(suggestions, dict) else {}
    rows = []
    for source in (
        suggestions.get("candidates") or [],
        suggestions.get("permittedCapabilities") or [],
    ):
        for candidate in source[:24]:
            if not isinstance(candidate, dict):
                continue
            display = candidate.get("display")
            display = display if isinstance(display, dict) else {}
            rows.append(
                {
                    "id": candidate.get("id"),
                    "action": candidate.get("action"),
                    "providerID": candidate.get("providerID"),
                    "source": candidate.get("source"),
                    "sources": candidate.get("sources"),
                    "eligibility": candidate.get("eligibility"),
                    "visibility": candidate.get("visibility"),
                    "ranking": candidate.get("ranking"),
                    "labelKey": display.get("labelKey"),
                    "label": display.get("label"),
                    "utteranceKey": display.get("utteranceKey"),
                    "utterance": display.get("utterance"),
                    "frame": candidate.get("frame"),
                }
            )
    response = observation.get("response")
    response = response if isinstance(response, dict) else {}
    queued = (response.get("queued") or [response])[0]
    queued = queued if isinstance(queued, dict) else response
    args = queued.get("args") if isinstance(queued.get("args"), dict) else {}
    actor_context = context.get("actorConversationContext", {})
    actor_context = actor_context if isinstance(actor_context, dict) else {}
    persona = {
        "actorConversationContext": bounded(
            context.get("actorConversationContext", {}), limit=32
        ),
        "speechStyleContext": bounded(
            context.get("speechStyleContext", {}), limit=24
        ),
        "choiceRegistry": bounded(suggestions.get("choiceRegistry", {}), limit=24),
        "candidates": bounded(rows, limit=32),
        "ranking": bounded(suggestions.get("ranking", {}), limit=24),
        "privacy": bounded(suggestions.get("privacy", {}), limit=16),
        "realization": bounded(response.get("realization", {}), limit=24),
        "realizationFamily": response.get("realizationFamily"),
        "realizationVariant": response.get("realizationVariant"),
        "realizationFallbackReason": response.get("realizationFallbackReason"),
        "responseTrace": {
            "semanticTemplateID": response.get("templateID"),
            "renderTemplateID": response.get("renderTemplateID"),
            "realizationFamily": queued.get("realizationFamily")
            or response.get("realizationFamily"),
            "realizationVariant": queued.get("realizationVariant")
            or response.get("realizationVariant"),
            "fallbackReason": queued.get("realizationFallbackReason")
            or response.get("realizationFallbackReason"),
            "translationKey": queued.get("translationKey")
            or response.get("translationKey"),
            "familyAddress": args.get("familyAddress"),
            "bond": bounded(actor_context.get("bond", {}), limit=16),
            "semanticFrame": bounded(
                state["result"].get("ir")
                or response.get("plan")
                or response.get("args")
                or {},
                limit=24,
            ),
        },
        "receipt": {
            "accepted": record.get("accepted") is True,
            "reason": record.get("reason") or state["result"].get("reason"),
            "requestRevision": state["result"].get("sequence"),
            "replaySafe": record.get("reason") in {
                "duplicate_suggestion",
                "stale_suggestion",
            },
        },
        "dialogueResult": bounded(state["result"], limit=24),
        "gameplayAction": bounded(
            state["observation"].get("actionResult")
            or state["result"].get("actionResult")
            or {},
            limit=24,
        ),
    }
    catalog = record.get("personaCatalog")
    if isinstance(catalog, dict):
        persona["speechRealizationCoverage"] = bounded(
            catalog.get("speechRealization", {}), limit=32
        )
    return persona
