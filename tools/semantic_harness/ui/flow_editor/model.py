"""Pure graph-model and coverage projections used by the Flow Editor."""

from __future__ import annotations

import copy
import json
from typing import Any

from tools.semantic_harness.codebuilder.blocks import TRANSITION_FIELDS

def graph_transform(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform model coordinates into canvas coordinates."""

    return point[0] * zoom + pan[0], point[1] * zoom + pan[1]


def graph_inverse(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform canvas coordinates into model coordinates."""

    return (point[0] - pan[0]) / zoom, (point[1] - pan[1]) / zoom


def graph_render_mode(zoom: float) -> str:
    """Return the amount of detail that remains readable at ``zoom``."""

    if zoom < 0.55:
        return "overview"
    if zoom < 0.8:
        return "compact"
    return "detail"


def flow_draft(flow: dict[str, Any]) -> dict[str, Any]:
    """Return an editable copy of one normalized production flow."""

    return copy.deepcopy(flow)


def _title_identifier(value: str) -> str:
    """Turn a bounded registry identifier segment into a UI label."""

    words = str(value).replace("_", " ").replace("-", " ").split()
    return " ".join(word[:1].upper() + word[1:] for word in words)


def flow_display_name(
    flow_id: str,
    flow: dict[str, Any] | None = None,
) -> str:
    """Return a compact label while preserving the canonical flow ID."""

    flow_id = str(flow_id)
    flow = flow if isinstance(flow, dict) else {}
    workflow_kind = str(flow.get("workflowKind") or "")
    capability_id = str(flow.get("capabilityID") or "")
    generated = workflow_kind != "" or flow_id.startswith("pnc.generated.")
    if not generated:
        return flow_id

    if not capability_id:
        generated_parts = flow_id.split(".")
        if len(generated_parts) >= 4:
            capability_id = ".".join(generated_parts[3:])
            if capability_id.startswith("pnc."):
                capability_id = "pnc:" + capability_id[4:]
    if capability_id.startswith("pnc:"):
        capability_id = capability_id[4:]
    segments = [
        _title_identifier(segment)
        for segment in capability_id.split(".")
        if segment
    ]
    if segments:
        return " / ".join(segments)
    return flow_id


def flow_graph_model(flow: dict[str, Any]) -> dict[str, Any]:
    """Build deterministic nodes/edges for the visual graph and tests."""

    if not isinstance(flow, dict):
        raise ValueError("flow must be an object")
    nodes = flow.get("nodes")
    if not isinstance(nodes, dict) or not nodes:
        raise ValueError("flow.nodes must be a non-empty object")

    node_rows: list[dict[str, Any]] = []
    edges: list[dict[str, Any]] = []
    for node_id in sorted(nodes):
        node = nodes[node_id]
        if not isinstance(node, dict):
            raise ValueError(f"flow node {node_id!r} must be an object")
        transitions = {
            field: node[field]
            for field in TRANSITION_FIELDS
            if node.get(field) not in (None, "")
        }
        action = node.get("action") if isinstance(node.get("action"), dict) else {}
        raw_result_transitions = node.get("resultTransitions")
        if not isinstance(raw_result_transitions, dict):
            raw_result_transitions = action.get("resultTransitions", {})
        result_transitions = {
            str(outcome): target
            for outcome, target in raw_result_transitions.items()
            if target not in (None, "")
        }
        node_rows.append({
            "id": node_id,
            "terminal": node.get("terminal") is True,
            "action": copy.deepcopy(action) if action else None,
            "responsePool": node.get("responsePool"),
            "responseTemplate": node.get("responseTemplate"),
            "accepts": copy.deepcopy(node.get("accepts", [])),
            "branchOffers": copy.deepcopy(node.get("branchOffers", [])),
            "slots": copy.deepcopy(node.get("slots", {})),
            "gate": copy.deepcopy(node.get("gate")),
            "transitions": transitions,
            "resultTransitions": result_transitions,
        })
        for field, target in transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": field,
                "toNodeID": target,
                "internal": target in nodes,
            })
        for outcome, target in result_transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": f"result:{outcome}",
                "toNodeID": target,
                "internal": target in nodes,
            })

    return {
        "schemaVersion": 1,
        "flowID": flow.get("id"),
        "owner": flow.get("owner"),
        "version": flow.get("version"),
        "workflowKind": flow.get("workflowKind"),
        "capabilityID": flow.get("capabilityID"),
        "generated": flow.get("workflowKind") is not None,
        "initial": flow.get("initial"),
        "triggers": copy.deepcopy(flow.get("triggers", [])),
        "nodes": node_rows,
        "edges": edges,
    }


def runtime_graph_model(graph: dict[str, Any]) -> dict[str, Any]:
    """Adapt semantic Flow and Hub projections to the shared canvas model."""

    if not isinstance(graph, dict):
        raise ValueError("runtime graph must be an object")
    raw_nodes = graph.get("nodes")
    if not isinstance(raw_nodes, list) or not raw_nodes:
        raise ValueError("runtime graph.nodes must be a non-empty list")
    known_nodes = {
        str(node.get("id"))
        for node in raw_nodes
        if isinstance(node, dict) and node.get("id")
    }
    nodes: list[dict[str, Any]] = []
    for raw in raw_nodes:
        if not isinstance(raw, dict) or not raw.get("id"):
            continue
        node_id = str(raw["id"])
        nodes.append(
            {
                "id": node_id,
                "title": raw.get("title") or node_id,
                "npcText": raw.get("npcText") or "",
                "state": raw.get("state") or "future",
                "current": raw.get("current") is True,
                "visited": raw.get("visited") is True,
                "choices": copy.deepcopy(raw.get("choices") or []),
                "terminal": raw.get("terminal") is True,
                "action": copy.deepcopy(raw.get("action")),
                "accepts": copy.deepcopy(raw.get("accepts") or []),
                "gate": copy.deepcopy(raw.get("gate")),
                "responsePool": raw.get("responsePool") or raw.get("npcText") or "",
                "source": copy.deepcopy(raw.get("source") or {}),
            }
        )
    edges: list[dict[str, Any]] = []
    for index, raw in enumerate(graph.get("edges") or []):
        if not isinstance(raw, dict) or not raw.get("fromNodeID"):
            continue
        target = str(raw.get("toNodeID") or "$root")
        edges.append(
            {
                "id": raw.get("id") or f"runtime.edge:{index}",
                "fromNodeID": str(raw["fromNodeID"]),
                "field": str(raw.get("field") or raw.get("label") or "transition"),
                "toNodeID": target,
                "internal": target in known_nodes,
                "label": raw.get("label") or raw.get("field") or "transition",
                "choiceID": raw.get("choiceID"),
                "state": raw.get("state") or "future",
                "clickable": raw.get("clickable") is True,
                "lockedReason": raw.get("lockedReason"),
                "outcomeIDs": copy.deepcopy(raw.get("outcomeIDs") or []),
                "frame": copy.deepcopy(raw.get("frame")),
                "source": copy.deepcopy(raw.get("source") or {}),
            }
        )
    graph_kind = str(graph.get("graphKind") or "semantic_flow")
    return {
        "schemaVersion": graph.get("schemaVersion", 1),
        "graphKind": graph_kind,
        "graphID": graph.get("graphID"),
        "title": graph.get("title") or graph.get("flowID") or graph_kind,
        "flowID": graph.get("flowID") or graph.get("graphID"),
        "workflowKind": graph.get("workflowKind"),
        "generated": graph.get("generated") is True,
        "triggers": copy.deepcopy(graph.get("triggers") or []),
        "initial": graph.get("initial"),
        "currentNodeID": graph.get("currentNodeID"),
        "visitedNodeIDs": copy.deepcopy(graph.get("visitedNodeIDs") or []),
        "revision": graph.get("revision"),
        "nodes": nodes,
        "edges": edges,
        "rootExits": copy.deepcopy(graph.get("rootExits") or []),
        "source": copy.deepcopy(graph.get("source") or {}),
    }


def conversation_graph_model(graph: dict[str, Any]) -> dict[str, Any]:
    """Adapt a developer ConversationBlock projection to the shared canvas model."""

    if not isinstance(graph, dict):
        raise ValueError("conversation graph must be an object")
    if graph.get("graphKind") in {"semantic_flow", "semantic_hub"}:
        return runtime_graph_model(graph)
    raw_nodes = graph.get("nodes")
    if not isinstance(raw_nodes, list) or not raw_nodes:
        raise ValueError("conversation graph.nodes must be a non-empty list")

    node_rows: list[dict[str, Any]] = []
    known_nodes = {
        str(node.get("id"))
        for node in raw_nodes
        if isinstance(node, dict) and node.get("id")
    }
    for raw in raw_nodes:
        if not isinstance(raw, dict) or not raw.get("id"):
            continue
        node_id = str(raw["id"])
        node_rows.append(
            {
                "id": node_id,
                "title": raw.get("title") or node_id,
                "npcText": raw.get("npcText") or "",
                "state": raw.get("state") or "future",
                "current": raw.get("current") is True,
                "visited": raw.get("visited") is True,
                "choices": copy.deepcopy(raw.get("choices") or []),
                "terminal": False,
                "action": None,
                "accepts": [],
                "gate": None,
                "responsePool": raw.get("npcText") or "",
                "source": copy.deepcopy(raw.get("source") or {}),
            }
        )

    edges: list[dict[str, Any]] = []
    for raw in graph.get("edges") or []:
        if not isinstance(raw, dict) or not raw.get("fromNodeID"):
            continue
        target = str(raw.get("toNodeID") or "$root")
        edges.append(
            {
                "id": raw.get("id")
                or f"conversation.edge:{raw['fromNodeID']}:{target}",
                "fromNodeID": str(raw["fromNodeID"]),
                "field": str(raw.get("choiceID") or raw.get("label") or "choice"),
                "toNodeID": target,
                "internal": target in known_nodes,
                "label": raw.get("label") or raw.get("choiceID") or "choice",
                "choiceID": raw.get("choiceID"),
                "state": raw.get("state") or "future",
                "clickable": raw.get("clickable") is True,
                "lockedReason": raw.get("lockedReason"),
                "outcomeIDs": copy.deepcopy(raw.get("outcomeIDs") or []),
                "frame": copy.deepcopy(raw.get("frame")),
                "source": copy.deepcopy(raw.get("source") or {}),
            }
        )

    return {
        "schemaVersion": graph.get("schemaVersion", 1),
        "graphKind": "conversation_block",
        "graphID": graph.get("graphID"),
        "title": graph.get("title") or graph.get("categoryID") or graph.get("blockID"),
        "blockID": graph.get("blockID"),
        "categoryID": graph.get("categoryID"),
        "topic": graph.get("topic"),
        "initial": graph.get("entryNodeID"),
        "currentNodeID": graph.get("currentNodeID"),
        "source": copy.deepcopy(graph.get("source") or {}),
        "sourceIDs": copy.deepcopy(graph.get("sourceIDs") or {}),
        "nodes": node_rows,
        "edges": edges,
        "rootExits": copy.deepcopy(graph.get("rootExits") or []),
    }


def conversation_graph_diagnostics(graph: dict[str, Any]) -> dict[str, Any]:
    """Build a bounded authoring/source view without rewriting authored text."""

    graph = graph if isinstance(graph, dict) else {}
    source = copy.deepcopy(graph.get("source") or {})
    nodes: list[dict[str, Any]] = []
    choices: list[dict[str, Any]] = []
    suspicious: list[dict[str, Any]] = []
    english_markers = {"the", "and", "you", "what", "there", "around", "today"}
    tagalog_markers = {"ang", "mga", "ng", "sa", "ko", "mo", "may"}

    def inspect_text(
        text: Any,
        text_key: Any,
        kind: str,
        identifier: Any,
        source_ids: dict[str, Any],
    ) -> None:
        resolved = str(text or "")
        tokens = {
            token.strip(".,!?;:'\"()[]").lower()
            for token in resolved.split()
        }
        reasons: list[str] = []
        if not resolved.strip():
            reasons.append("unresolved_text")
        if text_key and resolved.strip() == str(text_key).strip():
            reasons.append("translation_key_rendered_as_text")
        if english_markers & tokens and tagalog_markers & tokens:
            reasons.append("mixed_language_markers")
        if reasons and len(suspicious) < 32:
            suspicious.append(
                {
                    "kind": kind,
                    "id": identifier,
                    "textKey": text_key,
                    "resolvedText": resolved,
                    "reasons": reasons,
                    "source": copy.deepcopy(source_ids),
                }
            )

    for node in graph.get("nodes") or []:
        if not isinstance(node, dict):
            continue
        node_id = node.get("id")
        source_ids = copy.deepcopy(node.get("source") or {})
        row = {
            "nodeID": node_id,
            "translationKey": node.get("textKey"),
            "resolvedText": node.get("npcText") or "",
            "state": node.get("state"),
            "source": source_ids,
        }
        nodes.append(row)
        inspect_text(
            row["resolvedText"], row["translationKey"], "node", node_id, source_ids
        )
        for choice in node.get("choices") or []:
            if not isinstance(choice, dict):
                continue
            choice_source = copy.deepcopy(choice.get("source") or source_ids)
            choice_row = {
                "nodeID": node_id,
                "choiceID": choice.get("id"),
                "translationKey": choice.get("textKey"),
                "resolvedText": choice.get("text") or "",
                "enabled": choice.get("enabled") is True,
                "lockedReason": choice.get("lockedReason"),
                "outcomeIDs": copy.deepcopy(choice.get("outcomeIDs") or []),
                "nextNodeTargets": copy.deepcopy(choice.get("nextNodeTargets") or []),
                "source": choice_source,
            }
            choices.append(choice_row)
            inspect_text(
                choice_row["resolvedText"],
                choice_row["translationKey"],
                "choice",
                f"{node_id}:{choice_row['choiceID']}",
                choice_source,
            )

    return {
        "schema": "semantic_lab.graph_diagnostics.v1",
        "graphID": graph.get("graphID"),
        "blockID": graph.get("blockID"),
        "categoryID": graph.get("categoryID"),
        "topic": graph.get("topic"),
        "source": source,
        "sourceIDs": copy.deepcopy(graph.get("sourceIDs") or {}),
        "nodes": nodes,
        "choices": choices,
        "suspicious": suspicious,
        "note": "Diagnostics report authored content; no translation is rewritten.",
    }


def coverage_summary(coverage: list[dict[str, Any]]) -> dict[str, int]:
    """Count live capability classifications shown by Semantic Lab."""

    summary: dict[str, int] = {}
    for row in coverage:
        if not isinstance(row, dict):
            continue
        classification = str(row.get("classification") or "unknown")
        summary[classification] = summary.get(classification, 0) + 1
    return summary


def coverage_lines(coverage: list[dict[str, Any]]) -> list[str]:
    """Render exact bounded coverage reasons for the visual coverage view."""

    lines: list[str] = []
    for row in sorted(
        (item for item in coverage if isinstance(item, dict)),
        key=lambda item: str(item.get("id") or ""),
    ):
        capability = str(row.get("id") or "<unknown>")
        classification = str(row.get("classification") or "unknown")
        reason = str(row.get("reason") or "unspecified")
        flow_id = row.get("flowID")
        suffix = f" -> {flow_id}" if flow_id else ""
        lines.append(f"{capability}: {classification} ({reason}){suffix}")
    return lines


def _json_text(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)
