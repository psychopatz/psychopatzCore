"""Semantic understanding, fact, graph, and social projections."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.conversation_inspector_support import (
    bounded,
    dossier_entries,
    fact_providers,
    reference,
)


def _graph_projection(selected: dict[str, Any]) -> dict[str, Any]:
    metadata = selected.get("metadata")
    metadata = metadata if isinstance(metadata, dict) else {}
    graph_metadata = metadata.get("semanticLabGraph")
    graph_metadata = graph_metadata if isinstance(graph_metadata, dict) else {}
    graph = graph_metadata.get("graph")
    graph = graph if isinstance(graph, dict) else {}
    blocks = graph.get("blocks", [])
    blocks = blocks if isinstance(blocks, list) else []
    connections = graph.get("connections", [])
    connections = connections if isinstance(connections, list) else []
    compact_blocks = [
        {"id": block.get("id"), "type": block.get("type")}
        for block in blocks
        if isinstance(block, dict)
    ]
    compact_connections = [
        {
            "from": connection.get("from"),
            "to": connection.get("to"),
            "type": connection.get("type"),
        }
        for connection in connections
        if isinstance(connection, dict)
    ]
    return {
        "available": bool(graph_metadata),
        "schema": graph_metadata.get("schema"),
        "fingerprint": graph_metadata.get("fingerprint"),
        "blocks": bounded(compact_blocks, limit=16),
        "connections": bounded(compact_connections, limit=24),
    }


def project(state: dict[str, Any]) -> dict[str, Any]:
    context = state["context"]
    observation = state["observation"]
    result = state["result"]
    ir = state["ir"]
    flow = state["flow"]
    selected = state["selected"]
    diagnostics = state["diagnostics"]
    facts = state["facts"]
    response_refs = state["response_refs"]
    plan_refs = state["plan_refs"]
    trace_data = state["trace_data"]
    understanding = {
        "classification": trace_data.get("classification"),
        "intent": ir.get("intent") or observation.get("ir", {}).get("intent"),
        "speechAct": ir.get("speechAct") or observation.get("ir", {}).get("speechAct"),
        "subject": ir.get("subject") or observation.get("ir", {}).get("subject"),
        "pattern": ir.get("provenance", {}).get("pattern")
        if isinstance(ir.get("provenance"), dict)
        else observation.get("ir", {}).get("pattern"),
        "confidence": ir.get("confidence")
        or observation.get("ir", {}).get("confidence"),
        "reference": reference(ir.get("target")),
    }
    facts_view = {
        "status": state["fact_status"],
        "providers": fact_providers(facts),
        "groundedFactRefs": bounded(response_refs),
        "entries": bounded(facts, limit=32),
        "planFactRefs": bounded(plan_refs),
    }
    graph_view = _graph_projection(selected)
    codeblock_view = {
        "patternID": selected.get("patternID"),
        "graphFingerprint": graph_view.get("fingerprint"),
        "blockIDs": [
            block.get("id")
            for block in graph_view.get("blocks", [])
            if isinstance(block, dict) and block.get("id")
        ],
        "blockTypes": [
            block.get("type")
            for block in graph_view.get("blocks", [])
            if isinstance(block, dict) and block.get("type")
        ],
    }
    knowledge_permission = {
        "status": state["fact_status"],
        "reason": diagnostics.get("factReason") or diagnostics.get("reason"),
        "provider": diagnostics.get("factProvider") or facts_view["providers"],
        "scope": "player_scoped_npc_knowledge",
        "dossierPresent": bool(dossier_entries(context)),
    }
    fact_provider = diagnostics.get("factProvider") or facts_view["providers"]
    if isinstance(fact_provider, str):
        fact_provider = [fact_provider]

    social_context = context.get("socialContext")
    if not isinstance(social_context, dict):
        actor_context = context.get("actorConversationContext")
        actor_context = actor_context if isinstance(actor_context, dict) else {}
        social_context = {
            "personalRelationship": actor_context.get(
                "personalRelationship", actor_context.get("relationship")
            ),
            "factionRelationship": actor_context.get("factionRelationship"),
            "tacticalHostility": actor_context.get("tacticalHostility"),
            "conversationAudience": actor_context.get("conversationAudience"),
            "durableBond": actor_context.get("bond"),
            "speechStyle": context.get("speechStyleContext"),
            "provenance": actor_context.get("provenance"),
        }
    return {
        "understanding": understanding,
        "facts": facts_view,
        "graph": graph_view,
        "codeblock": codeblock_view,
        "knowledge_permission": knowledge_permission,
        "fact_provider": fact_provider,
        "social_context": social_context,
    }
