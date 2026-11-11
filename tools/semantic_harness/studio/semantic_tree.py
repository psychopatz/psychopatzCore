"""Derived hierarchy for semantic catalog and Dialogue Content projections.

The tree is deliberately derived from canonical IDs on every bounded page.
It is not a second registry: leaf records remain the response/content rows
provided by the existing production query or CodeBuilder service.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Callable, Iterable


_LABELS = {
    "compat": "Compatibility",
    "compatibility": "Compatibility",
    "companion_dogs": "Companion Dogs",
    "projectalife": "Project ALife",
    "tool_reply": "Tool Replies",
    "tool_replies": "Tool Replies",
    "events": "Events",
    "commands_emotes": "Commands & Emotes",
    "medical": "Medical",
    "distress": "Distress",
    "call": "Call",
    "update": "Update",
    "repeat": "Repeat",
    "generated": "Generated",
    "multi_stage_gift": "Multi-stage Gift",
    "flow": "Flow",
    "greeting": "Greeting",
    "followup": "Follow-up",
    "opening": "Opening",
    "question": "Questions",
    "wellbeing": "Wellbeing",
    "identity": "Identity",
    "activity": "Activity",
    "social": "Social",
    "corpse": "Corpse",
    "combat": "Combat",
    "leader_loss": "Leader Loss",
    "companion": "Companion",
}


def _humanize(part: str) -> str:
    value = str(part or "").replace("-", "_")
    if value in _LABELS:
        return _LABELS[value]
    words = [piece for piece in value.split("_") if piece]
    return " ".join(word[:1].upper() + word[1:] for word in words) or "Unknown"


def canonical_id(item: dict[str, Any], id_getter: Callable[[dict[str, Any]], str] | None = None) -> str:
    """Return the semantic join ID without changing the leaf record."""

    value = id_getter(item) if id_getter else (
        item.get("semanticTemplateID") or item.get("id") or ""
    )
    value = str(value)
    if value.startswith("phrase."):
        value = value[len("phrase."):]
    return value


def _new_node(key: str, label: str) -> dict[str, Any]:
    return {"key": key, "label": label, "count": 0, "children": {}, "items": []}


def build_semantic_tree(
    items: Iterable[dict[str, Any]],
    *,
    id_getter: Callable[[dict[str, Any]], str] | None = None,
) -> dict[str, Any]:
    """Build a bounded tree whose leaves retain the exact source records."""

    root = _new_node("semantic", "Semantic")
    for item in items:
        if not isinstance(item, dict):
            continue
        value = canonical_id(item, id_getter)
        pieces = [piece for piece in value.split(".") if piece]
        if not pieces:
            pieces = ["unknown"]
        if pieces[0] == "semantic":
            pieces = pieces[1:] or ["unknown"]
        node = root
        node["count"] += 1
        path = ["semantic"]
        for piece in pieces:
            path.append(piece)
            child = node["children"].get(piece)
            if child is None:
                child = _new_node(".".join(path), _humanize(piece))
                node["children"][piece] = child
            child["count"] += 1
            node = child
        node["items"].append(item)
    return root


def filter_semantic_tree(tree: dict[str, Any], query: str = "") -> dict[str, Any]:
    """Return a filtered copy and mark matching ancestor paths expanded."""

    query = str(query or "").strip().casefold()
    expanded: set[str] = set()

    def mark_descendants(node: dict[str, Any]) -> None:
        key = node.get("key")
        if key:
            expanded.add(str(key))
        for child in node.get("children", {}).values():
            mark_descendants(child)

    def visit(node: dict[str, Any]) -> dict[str, Any] | None:
        own_match = not query or query in str(node.get("label", "")).casefold()
        if query and own_match:
            output = deepcopy(node)
            mark_descendants(output)
            return output
        kept_items = []
        for item in node.get("items", []):
            item_id = canonical_id(item).casefold()
            if not query or query in item_id or query in str(item.get("id", "")).casefold():
                kept_items.append(item)
        children: dict[str, dict[str, Any]] = {}
        child_match = False
        for key, child in node.get("children", {}).items():
            filtered = visit(child)
            if filtered is not None:
                children[key] = filtered
                child_match = True
        if query and (child_match or kept_items) and node.get("key"):
            expanded.add(str(node["key"]))
        if query and not own_match and not child_match and not kept_items:
            return None
        output = deepcopy(node)
        output["children"] = children
        output["items"] = kept_items if query else list(node.get("items", []))
        output["count"] = sum(
            child.get("count", 0) for child in children.values()
        ) + len(output["items"])
        return output

    filtered = visit(tree) or _new_node("semantic", "Semantic")
    filtered["expanded"] = expanded
    return filtered


def iter_tree_nodes(tree: dict[str, Any]) -> Iterable[tuple[dict[str, Any], dict[str, Any]]]:
    """Yield ``(node, item)`` pairs for deterministic UI insertion."""

    for item in tree.get("items", []):
        yield tree, item
    for key in sorted(tree.get("children", {}), key=str.casefold):
        yield from iter_tree_nodes(tree["children"][key])


__all__ = [
    "build_semantic_tree",
    "canonical_id",
    "filter_semantic_tree",
    "iter_tree_nodes",
]
