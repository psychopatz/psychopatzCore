"""Handle the production gift action and its bounded evidence view."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from .suggestion_projection import npc_message_text


def inventory_item_map(inventory: Any) -> dict[str, dict[str, Any]]:
    inventory = inventory if isinstance(inventory, dict) else {}
    raw_items = inventory.get("items", [])
    items = list(raw_items.values()) if isinstance(raw_items, dict) else raw_items
    if not isinstance(items, list):
        return {}
    output: dict[str, dict[str, Any]] = {}
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        item_id = str(item.get("itemID") or item.get("id") or f"item-{index}")
        output[item_id] = {
            "name": str(
                item.get("displayName")
                or item.get("fullType")
                or item.get("type")
                or item_id
            ),
            "stack": item.get("stack", item.get("quantity", item.get("count", 1))),
        }
    return output


def inventory_delta(before: Any, after: Any) -> str:
    before_items = inventory_item_map(before)
    after_items = inventory_item_map(after)
    lines: list[str] = []
    for item_id in sorted(set(before_items) | set(after_items)):
        left = before_items.get(item_id, {"name": item_id, "stack": 0})
        right = after_items.get(item_id, {"name": left["name"], "stack": 0})
        if left.get("stack") != right.get("stack"):
            lines.append(
                f"{right.get('name') or left.get('name')}: "
                f"{left.get('stack', 0)} → {right.get('stack', 0)}"
            )
    return "\n".join(lines[:24]) or "no inventory delta"


def format_number(value: Any) -> str:
    if isinstance(value, bool):
        return str(value)
    try:
        return f"{float(value):.2f}"
    except (TypeError, ValueError):
        return "MISSING"


def format_signed(value: Any) -> str:
    rendered = format_number(value)
    if rendered == "MISSING":
        return rendered
    return f"{float(rendered):+0.2f}"


def relationship_evidence(value: Any) -> str:
    relationship = value if isinstance(value, dict) else {}
    return " · ".join(
        [
            f"Approval {format_number(relationship.get('approval'))}",
            f"Respect {format_number(relationship.get('respect'))}",
            f"Familiarity {format_number(relationship.get('familiarity'))}",
            f"State {relationship.get('state') or 'unknown'}",
            f"Revision {format_number(relationship.get('revision'))}",
        ]
    )


def gift_result_text(
    app: Any,
    response: dict[str, Any],
    before: dict[str, Any],
    after: dict[str, Any],
    selected_item: dict[str, Any],
    quantity: int,
) -> str:
    result = response.get("result") if isinstance(response, dict) else {}
    result = result if isinstance(result, dict) else {}
    action = result.get("actionResult")
    action = action if isinstance(action, dict) else {}
    decision = result.get("decision")
    decision = decision if isinstance(decision, dict) else {}
    display = str(
        selected_item.get("displayName")
        or selected_item.get("fullType")
        or selected_item.get("type")
        or "item"
    )
    messages = [
        npc_message_text(message)
        for message in response.get("messages", [])
        if isinstance(message, dict) and message.get("speaker") == "npc"
    ]
    relationship_before = before.get("npc", {}).get("relationship")
    relationship_after = after.get("npc", {}).get("relationship")
    source_kind = (
        app.source_snapshot_projection.get("metadata", {}).get("sourceKind")
        if isinstance(app.source_snapshot_projection, dict)
        else "MISSING"
    )
    return "\n".join(
        [
            "Gift: Player → NPC",
            f"item/count: {display} × {quantity}",
            f"production status: {action.get('status') or decision.get('branch') or 'unknown'}",
            "",
            "Player inventory before → after:",
            inventory_delta(
                before.get("player", {}).get("inventory"),
                after.get("player", {}).get("inventory"),
            ),
            "NPC inventory before → after:",
            inventory_delta(
                before.get("npc", {}).get("inventory"),
                after.get("npc", {}).get("inventory"),
            ),
            "",
            f"NPC response: {messages[0] if messages else 'no production response'}",
            "Relationship before: " + relationship_evidence(relationship_before),
            "Relationship after: " + relationship_evidence(relationship_after),
            "",
            "Source save: UNCHANGED · source "
            f"{str(source_kind or 'MISSING').upper()} · detached working world only",
        ]
    )


def gift_selected_inventory_item(
    app: Any, item: dict[str, Any], raw_quantity: Any
) -> None:
    if app.closed or not app.session.ready or app.busy:
        return
    try:
        quantity = max(1, min(999, int(str(raw_quantity or "1"))))
    except (TypeError, ValueError):
        quantity = 1
    display = str(
        item.get("displayName")
        or item.get("fullType")
        or item.get("type")
        or "item"
    )
    quantity_text = str(quantity)
    utterance = f"here's {quantity_text} {display} for you"
    before = deepcopy(app.scenario)

    def operation(worker: LuaSemanticWorker) -> dict[str, Any]:
        response = worker.input(utterance)
        return {"response": response, "actorState": worker.inspect_actor_state()}

    def finish(payload: dict[str, Any]) -> None:
        response = payload.get("response") if isinstance(payload, dict) else {}
        actor_state = payload.get("actorState") if isinstance(payload, dict) else {}
        response = response if isinstance(response, dict) else {}
        actor_state = actor_state if isinstance(actor_state, dict) else {}
        state_scenario = actor_state.get("scenario")
        state_scenario = state_scenario if isinstance(state_scenario, dict) else {}
        after = deepcopy(app.scenario)
        for actor_key in ("player", "npc"):
            state_actor = state_scenario.get(actor_key)
            if not isinstance(state_actor, dict):
                continue
            actor = after.setdefault(actor_key, {})
            if isinstance(actor, dict) and isinstance(state_actor.get("inventory"), dict):
                actor["inventory"] = state_actor["inventory"]
            if actor_key == "npc" and isinstance(actor, dict):
                relationship = state_actor.get("relationship")
                if isinstance(relationship, dict):
                    actor["relationship"] = relationship
        app.scenario = after
        app._show_response(response)
        app.scenario = after
        app._refresh_actor_inspectors()
        if response.get("accepted") is True:
            app._record_replay_step({"kind": "input", "text": utterance})
        if app.inventory_gift_workbench is not None:
                app.inventory_gift_workbench.show_result(
                    gift_result_text(
                        app, response, before, after, item, quantity
                    )
                )

    app._start_operation(operation, finish)
