"""Readable, bounded rendering for production tool/action calls."""

from __future__ import annotations

from typing import Any


_HIDDEN_FIELDS = {
    "conversationToken",
    "eventID",
    "leaseToken",
    "memoryID",
    "requestID",
    "snapshot",
    "presentation",
    "relationship",
    "relationshipBefore",
    "relationshipAfter",
}
_PREFERRED_FIELDS = (
    "kind",
    "npcID",
    "claimedName",
    "action",
    "itemID",
    "itemType",
    "quantity",
    "amount",
    "topicID",
    "origin",
    "reason",
)


def _display_value(value: Any) -> str:
    if isinstance(value, bool):
        return "yes" if value else "no"
    return str(value).replace("\n", " ")


def _field_pairs(
    values: dict[str, Any],
    *,
    hidden: set[str] | None = None,
    limit: int = 6,
) -> list[str]:
    hidden = hidden or set()
    keys = [key for key in _PREFERRED_FIELDS if key in values]
    keys.extend(
        sorted(
            key
            for key in values
            if key not in keys and key not in _HIDDEN_FIELDS and key not in hidden
        )
    )
    pairs: list[str] = []
    for key in keys:
        value = values.get(key)
        if value is None or isinstance(value, (dict, list, tuple)):
            continue
        pairs.append(f"{key}={_display_value(value)}")
        if len(pairs) >= limit:
            break
    return pairs


def _delta_pairs(delta: Any) -> list[str]:
    if not isinstance(delta, dict):
        return []
    pairs: list[str] = []
    for key in ("approval", "respect", "familiarity", "trust"):
        value = delta.get(key)
        if value is None:
            continue
        if isinstance(value, (int, float)) and value > 0:
            rendered = f"+{value}"
        else:
            rendered = _display_value(value)
        pairs.append(f"{key} {rendered}")
    return pairs


def format_tool_call(call: dict[str, Any]) -> str:
    """Render one call as a compact multi-line transcript entry."""

    call = call if isinstance(call, dict) else {}
    label = str(call.get("label") or call.get("name") or "Unknown action")
    contract = str(call.get("name") or "untyped")
    status = call.get("status") or call.get("reason")
    if not status and call.get("accepted") is not None:
        status = "accepted" if call.get("accepted") is True else "rejected"
    status = str(status or "observed").upper()

    lines = [label, f"  Contract: {contract}", f"  Status: {status}"]
    route = []
    for key in ("authority", "source"):
        value = call.get(key)
        if value:
            route.append(f"{key}={_display_value(value)}")
    if route:
        lines.append(f"  Route: {' · '.join(route)}")

    arguments = call.get("arguments")
    if isinstance(arguments, dict):
        input_pairs = _field_pairs(arguments)
        if input_pairs:
            lines.append(f"  Input: {' · '.join(input_pairs)}")

        response_text = arguments.get("responseText")
        if response_text:
            lines.append(f"  Response: {_display_value(response_text)}")

        delta_pairs = _delta_pairs(arguments.get("relationshipDelta"))
        if delta_pairs:
            lines.append(f"  Change: {' · '.join(delta_pairs)}")

        after = arguments.get("relationshipAfter")
        if isinstance(after, dict):
            state_pairs = _field_pairs(
                after,
                hidden={"approval", "respect", "familiarity"},
                limit=4,
            )
            if state_pairs:
                lines.append(f"  State: {' · '.join(state_pairs)}")

    if call.get("accepted") is not None:
        result = "accepted" if call.get("accepted") is True else "rejected"
        lines.append(f"  Result: {result}")

    return "\n".join(lines)
