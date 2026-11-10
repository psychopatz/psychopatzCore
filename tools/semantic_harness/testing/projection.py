"""Bounded canonical path resolution for semantic test observations.

Resolves dot-separated accessors against actual turn outputs produced by
LuaSemanticWorker and its production Lua observation projections.
"""

from __future__ import annotations

from typing import Any

# Sentinel value representing a path that does not exist in the record.
class _Absent:
    def __repr__(self) -> str:
        return "<ABSENT>"

ABSENT = _Absent()


def _resolve_raw_path(source: Any, parts: list[str]) -> Any:
    """Recursively resolve dot-separated parts against nested dicts/lists."""
    current = source
    for part in parts:
        if current is None or current is ABSENT:
            return ABSENT
        if isinstance(current, dict):
            if part in current:
                current = current[part]
            else:
                return ABSENT
        elif isinstance(current, (list, tuple)):
            try:
                index = int(part)
                if 0 <= index < len(current):
                    current = current[index]
                else:
                    return ABSENT
            except ValueError:
                if part == "count" or part == "length":
                    current = len(current)
                else:
                    return ABSENT
        else:
            return ABSENT
    return current


def resolve_observation_path(turn: dict[str, Any], path: str) -> Any:
    """Resolve a path against a turn dictionary.

    Checks observation paths first, then raw turn results, then root fields.
    Returns ABSENT if the path could not be resolved.
    """
    if not isinstance(turn, dict) or not path:
        return ABSENT

    parts = path.split(".")
    first = parts[0]
    tail = parts[1:]

    observation = turn.get("observation")
    if isinstance(observation, dict):
        # 1. Direct match in observation
        if first in observation:
            if not tail:
                return observation[first]
            val = _resolve_raw_path(observation[first], tail)
            if val is not ABSENT:
                return val

        # 2. Domain-specific aliases within observation
        if first == "response":
            resp = observation.get("response")
            if isinstance(resp, dict):
                if tail:
                    val = _resolve_raw_path(resp, tail)
                    if val is not ABSENT:
                        return val
                    # Alias: response.exists
                    if tail == ["exists"]:
                        return resp.get("templateID") is not None or resp.get("fallback") is not None
                else:
                    return resp
        elif first == "ir":
            ir_obs = observation.get("ir")
            if isinstance(ir_obs, dict) and tail:
                val = _resolve_raw_path(ir_obs, tail)
                if val is not ABSENT:
                    return val
        elif first == "flow":
            flow_obs = observation.get("flow")
            if isinstance(flow_obs, dict) and tail:
                val = _resolve_raw_path(flow_obs, tail)
                if val is not ABSENT:
                    return val

    # 3. Check turn["result"]
    result = turn.get("result")
    if isinstance(result, dict):
        if first == "ir" and "ir" in result:
            val = _resolve_raw_path(result["ir"], tail)
            if val is not ABSENT:
                return val
        elif first == "decision" and "decision" in result:
            val = _resolve_raw_path(result["decision"], tail)
            if val is not ABSENT:
                return val
        elif first == "response" and "decision" in result:
            decision = result["decision"]
            if isinstance(decision, dict) and "response" in decision:
                val = _resolve_raw_path(decision["response"], tail)
                if val is not ABSENT:
                    return val
        elif first == "flow" and "flow" in result:
            val = _resolve_raw_path(result["flow"], tail)
            if val is not ABSENT:
                return val
        elif first in result:
            val = _resolve_raw_path(result[first], tail)
            if val is not ABSENT:
                return val

    # 4. Check root turn fields (e.g., messages, transport, toolCalls, contextAfter, relationshipAfter)
    if first in turn:
        val = _resolve_raw_path(turn[first], tail)
        if val is not ABSENT:
            return val

    # 5. Convenience aliases:
    # "response.text": check first NPC message in turn["messages"]
    if path in {"response.text", "response.fallback"}:
        messages = turn.get("messages")
        if isinstance(messages, (list, tuple)) and messages:
            for msg in messages:
                if isinstance(msg, dict) and msg.get("speaker") == "npc":
                    payload = msg.get("payload", {})
                    if isinstance(payload, dict):
                        text = payload.get("text") or payload.get("fallback")
                        if text is not None:
                            return text
            # Fallback to first message payload text
            payload = messages[0].get("payload", {}) if isinstance(messages[0], dict) else {}
            if isinstance(payload, dict):
                return payload.get("text") or payload.get("fallback", ABSENT)

    # "response.templateID": check messages payload semanticTemplateID or templateID
    if path in {"response.templateID", "response.key"}:
        messages = turn.get("messages")
        if isinstance(messages, (list, tuple)) and messages:
            for msg in messages:
                if isinstance(msg, dict):
                    payload = msg.get("payload", {})
                    if isinstance(payload, dict):
                        tid = payload.get("semanticTemplateID") or payload.get("templateID")
                        if tid is not None:
                            return tid

    # Observatory lifecycle & translation aliases
    if path == "conversationClosed":
        lifecycle = (turn.get("conversationPresentation") or {}).get("lifecycle") or {}
        return lifecycle.get("closed") is True

    if path == "fallbackLookups":
        lookups = (turn.get("translation") or {}).get("lookups") or []
        return sum(
            1 for item in lookups if isinstance(item, dict) and item.get("fallbackUsed") is True
        )

    if path in {"lastKey", "firstKey", "firstSemanticKey", "lastSemanticKey"}:
        messages = [
            msg.get("payload", {}) for msg in turn.get("messages", [])
            if isinstance(msg, dict) and msg.get("speaker") == "npc" and isinstance(msg.get("payload"), dict)
        ]
        if not messages:
            messages = [
                msg.get("payload", {}) for msg in turn.get("messages", [])
                if isinstance(msg, dict) and isinstance(msg.get("payload"), dict)
            ]
        if not messages:
            return ABSENT
        if path == "firstKey":
            return messages[0].get("key") or messages[0].get("templateID", ABSENT)
        elif path == "lastKey":
            return messages[-1].get("key") or messages[-1].get("templateID", ABSENT)
        elif path == "firstSemanticKey":
            return messages[0].get("semanticTemplateID") or messages[0].get("key", ABSENT)
        elif path == "lastSemanticKey":
            return messages[-1].get("semanticTemplateID") or messages[-1].get("key", ABSENT)

    if path == "companionCommandTransportCount":
        transports = turn.get("transport") or []
        return sum(
            1 for evt in transports
            if isinstance(evt, dict) and evt.get("command") == "CompanionCommand"
        )

    # Fallback direct path navigation on turn
    return _resolve_raw_path(turn, parts)
