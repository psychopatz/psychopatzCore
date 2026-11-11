"""Deterministic declarative codeblock round-trip for production flows."""

from __future__ import annotations

import copy
from typing import Any, Iterable

from .blocks import TRANSITION_FIELDS


SCHEMA = "semantic.codeblocks.v1"
SPECIAL_TARGETS = frozenset(("cancel", "resume", "suspend"))
BLOCK_TYPES = frozenset(
    ("flow_node", "condition_gate", "gameplay_action", "dialogue_response", "terminal", "nested_flow")
)


def _block_type(node: dict[str, Any]) -> str:
    if isinstance(node.get("action"), dict):
        return "gameplay_action"
    if isinstance(node.get("gate"), dict):
        return "condition_gate"
    if node.get("responsePool") or node.get("responseTemplate"):
        return "dialogue_response"
    if node.get("terminal") is True:
        return "terminal"
    return "flow_node"


def _connection_type(port: str) -> str:
    return "result" if port.startswith("result:") else "flow"


def _connections_for_node(node_id: str, node: dict[str, Any]) -> list[dict[str, str]]:
    connections: list[dict[str, str]] = []
    for port in TRANSITION_FIELDS:
        target = node.get(port)
        if target not in (None, ""):
            connections.append({
                "from": node_id,
                "port": port,
                "to": str(target),
                "type": "flow",
            })
    action = node.get("action") if isinstance(node.get("action"), dict) else {}
    result_transitions = action.get("resultTransitions")
    if isinstance(result_transitions, dict):
        for outcome in sorted(result_transitions):
            target = result_transitions[outcome]
            if target not in (None, ""):
                connections.append({
                    "from": node_id,
                    "port": f"result:{outcome}",
                    "to": str(target),
                    "type": "result",
                })
    return connections


def flow_to_codeblocks(
    flow: dict[str, Any],
    *,
    nested_flows: Iterable[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Project one normalized flow into a stable editor document."""

    if not isinstance(flow, dict) or not isinstance(flow.get("nodes"), dict):
        raise ValueError("flow must contain an object-valued nodes field")
    blocks = []
    connections = []
    for node_id in sorted(flow["nodes"]):
        node = flow["nodes"][node_id]
        if not isinstance(node, dict):
            raise ValueError(f"flow node {node_id!r} must be an object")
        blocks.append({
            "id": str(node_id),
            "type": _block_type(node),
            "reusable": True,
            "definition": copy.deepcopy(node),
        })
        connections.extend(_connections_for_node(str(node_id), node))
    return {
        "schema": SCHEMA,
        "flowID": flow.get("id"),
        "version": flow.get("version", 1),
        "owner": flow.get("owner"),
        "initial": flow.get("initial"),
        "triggers": copy.deepcopy(flow.get("triggers", [])),
        "blocks": blocks,
        "connections": connections,
        "nestedFlows": copy.deepcopy(list(nested_flows or [])),
    }


def validate_codeblock_document(
    document: dict[str, Any],
    *,
    known_flow_ids: Iterable[str] | None = None,
) -> dict[str, Any]:
    """Validate editor structure and typed edges without evaluating it."""

    diagnostics: list[dict[str, str]] = []
    if not isinstance(document, dict) or document.get("schema") != SCHEMA:
        return {
            "ok": False,
            "type": "codeblock_validation",
            "valid": False,
            "diagnostics": [{"severity": "error", "message": f"document requires schema {SCHEMA}"}],
            "effectFree": True,
            "writes": [],
        }
    flow_id = document.get("flowID")
    owner = document.get("owner")
    initial = document.get("initial")
    blocks = document.get("blocks")
    connections = document.get("connections")
    if not isinstance(flow_id, str) or not flow_id.strip():
        diagnostics.append({"severity": "error", "message": "flowID is required"})
    if not isinstance(owner, str) or not owner.strip():
        diagnostics.append({"severity": "error", "message": "owner is required"})
    if not isinstance(blocks, list) or not blocks or len(blocks) > 32:
        diagnostics.append({"severity": "error", "message": "blocks must contain 1..32 entries"})
        blocks = []
    if not isinstance(connections, list) or len(connections) > 128:
        diagnostics.append({"severity": "error", "message": "connections must contain at most 128 entries"})
        connections = []
    block_ids: set[str] = set()
    definitions: dict[str, dict[str, Any]] = {}
    for block in blocks:
        if not isinstance(block, dict):
            diagnostics.append({"severity": "error", "message": "each block must be an object"})
            continue
        block_id = block.get("id")
        block_type = block.get("type")
        definition = block.get("definition")
        if not isinstance(block_id, str) or not block_id.strip():
            diagnostics.append({"severity": "error", "message": "block id is required"})
            continue
        if block_id in block_ids:
            diagnostics.append({"severity": "error", "blockID": block_id, "message": "duplicate block id"})
            continue
        block_ids.add(block_id)
        if block_type not in BLOCK_TYPES:
            diagnostics.append({"severity": "error", "blockID": block_id, "message": "unknown block type"})
        if not isinstance(definition, dict):
            diagnostics.append({"severity": "error", "blockID": block_id, "message": "block definition must be an object"})
        else:
            definitions[block_id] = definition
    if initial not in block_ids:
        diagnostics.append({"severity": "error", "message": "initial must reference a block"})
    edge_keys: set[tuple[str, str]] = set()
    adjacency: dict[str, list[str]] = {block_id: [] for block_id in block_ids}
    for connection in connections:
        if not isinstance(connection, dict):
            diagnostics.append({"severity": "error", "message": "each connection must be an object"})
            continue
        source = connection.get("from")
        port = connection.get("port")
        target = connection.get("to")
        expected_type = _connection_type(str(port)) if isinstance(port, str) else "flow"
        key = (str(source), str(port))
        if key in edge_keys:
            diagnostics.append({"severity": "error", "message": f"duplicate connection port {source}.{port}"})
        edge_keys.add(key)
        if source not in block_ids:
            diagnostics.append({"severity": "error", "message": f"unknown connection source {source}"})
            continue
        if not isinstance(port, str) or not port:
            diagnostics.append({"severity": "error", "message": "connection port is required"})
            continue
        if not isinstance(target, str) or not target:
            diagnostics.append({"severity": "error", "message": f"connection target is required for {source}.{port}"})
            continue
        if connection.get("type") != expected_type:
            diagnostics.append({"severity": "error", "message": f"connection type mismatch for {source}.{port}"})
        if target not in block_ids and target not in SPECIAL_TARGETS:
            diagnostics.append({"severity": "error", "message": f"unknown connection target {target}"})
        elif expected_type == "result" and not isinstance(definitions.get(source, {}).get("action"), dict):
            diagnostics.append({"severity": "error", "message": f"result connection requires an action block: {source}"})
        elif target in block_ids:
            adjacency[source].append(target)
    nested = document.get("nestedFlows", [])
    if not isinstance(nested, list) or len(nested) > 8:
        diagnostics.append({"severity": "error", "message": "nestedFlows must contain at most 8 entries"})
        nested = []
    known = {str(value) for value in known_flow_ids or ()}
    nested_seen: set[str] = set()
    for reference in nested:
        if not isinstance(reference, dict) or not isinstance(reference.get("flowID"), str):
            diagnostics.append({"severity": "error", "message": "nested flow references require flowID"})
            continue
        nested_id = reference["flowID"]
        if nested_id in nested_seen:
            diagnostics.append({"severity": "error", "message": f"duplicate nested flow reference {nested_id}"})
        nested_seen.add(nested_id)
        if nested_id == flow_id:
            diagnostics.append({"severity": "error", "message": "flow cannot nest itself"})
        if known and nested_id not in known:
            diagnostics.append({"severity": "error", "message": f"unknown nested flow {nested_id}"})
    if initial in adjacency:
        reachable = {initial}
        pending = [initial]
        while pending:
            current = pending.pop(0)
            for target in adjacency[current]:
                if target not in reachable:
                    reachable.add(target)
                    pending.append(target)
        for block_id in sorted(block_ids - reachable):
            diagnostics.append({"severity": "error", "blockID": block_id, "message": "unreachable block"})
    return {
        "ok": not diagnostics,
        "type": "codeblock_validation",
        "schema": SCHEMA,
        "valid": not diagnostics,
        "diagnostics": diagnostics,
        "blockIDs": sorted(block_ids),
        "nestedFlows": copy.deepcopy(nested),
        "effectFree": True,
        "writes": [],
    }


def codeblocks_to_flow(
    document: dict[str, Any],
    *,
    base_flow: dict[str, Any] | None = None,
    known_flow_ids: Iterable[str] | None = None,
) -> dict[str, Any]:
    """Apply a validated codeblock document to a flow draft."""

    validation = validate_codeblock_document(document, known_flow_ids=known_flow_ids)
    if not validation["valid"]:
        return {**validation, "flow": None}
    flow = copy.deepcopy(base_flow) if isinstance(base_flow, dict) else {}
    for key in ("id", "version", "owner", "initial", "triggers"):
        source_key = "flowID" if key == "id" else key
        if source_key in document:
            flow[key] = copy.deepcopy(document[source_key])
    nodes: dict[str, dict[str, Any]] = {}
    for block in document["blocks"]:
        node = copy.deepcopy(block["definition"])
        for port in TRANSITION_FIELDS:
            node.pop(port, None)
        action = node.get("action") if isinstance(node.get("action"), dict) else None
        if action is not None:
            action.pop("resultTransitions", None)
        nodes[str(block["id"])] = node
    for connection in document["connections"]:
        node = nodes[connection["from"]]
        port = connection["port"]
        if port.startswith("result:"):
            action = node.setdefault("action", {})
            action.setdefault("resultTransitions", {})[port[7:]] = connection["to"]
        else:
            node[port] = connection["to"]
    flow["nodes"] = nodes
    return {
        **validation,
        "valid": True,
        "flow": flow,
        "nestedFlows": copy.deepcopy(document.get("nestedFlows", [])),
    }
