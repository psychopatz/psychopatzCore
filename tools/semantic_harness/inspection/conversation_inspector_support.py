"""Shared bounded-input and persistence helpers for the conversation inspector."""

from __future__ import annotations

from typing import Any


MAX_ITEMS = 8
MAX_TRACE_ITEMS = 16
MAX_DEPTH = 5
MAX_TEXT = 512


def bounded(value: Any, depth: int = 0, limit: int = MAX_ITEMS) -> Any:
    if depth >= MAX_DEPTH:
        return "<depth limit>"
    if isinstance(value, str):
        return value if len(value) <= MAX_TEXT else value[:MAX_TEXT] + "…"
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    if isinstance(value, list):
        result = [bounded(item, depth + 1, limit) for item in value[:limit]]
        if len(value) > limit:
            result.append(f"<{len(value) - limit} more>")
        return result
    if isinstance(value, dict):
        keys = sorted(value, key=str)
        result = {
            str(key): bounded(value[key], depth + 1, limit)
            for key in keys[:limit]
        }
        if len(keys) > limit:
            result["_truncatedKeys"] = len(keys) - limit
        return result
    return str(value)


def context(record: dict[str, Any]) -> dict[str, Any]:
    value = record.get("contextAfter") or record.get("context") or {}
    return value if isinstance(value, dict) else {}


def dialogue(context_value: dict[str, Any]) -> dict[str, Any]:
    value = context_value.get("dialogue", {})
    return value if isinstance(value, dict) else {}


def observation(record: dict[str, Any]) -> dict[str, Any]:
    value = record.get("observation", {})
    return value if isinstance(value, dict) else {}


def response(record: dict[str, Any], observation_value: dict[str, Any]) -> dict[str, Any]:
    value = observation_value.get("response")
    if isinstance(value, dict):
        return value
    result = record.get("result", {})
    if isinstance(result, dict):
        decision = result.get("decision", {})
        if isinstance(decision, dict) and isinstance(decision.get("response"), dict):
            return decision["response"]
    return {}


def plan(response_value: dict[str, Any]) -> dict[str, Any] | None:
    value = response_value.get("plan")
    return value if isinstance(value, dict) else None


def trace_data(record: dict[str, Any]) -> dict[str, Any]:
    trace = record.get("trace", [])
    if not isinstance(trace, list):
        return {}
    for event in trace:
        if not isinstance(event, dict):
            continue
        data = event.get("data")
        if isinstance(data, dict):
            return data
    return {}


def reference(target: Any) -> dict[str, Any] | None:
    if not isinstance(target, dict):
        return None
    return bounded(
        {
            "surface": target.get("text") or target.get("reference"),
            "reference": target.get("reference"),
            "resolvedReference": target.get("resolvedReference"),
            "unresolved": target.get("unresolved"),
            "concept": target.get("concept"),
            "value": target.get("value"),
            "entityType": target.get("entityType"),
            "resolution": target.get("resolution"),
        },
        limit=16,
    )


def fact_providers(facts: dict[str, Any]) -> list[str]:
    providers = {
        str(fact.get("provider"))
        for fact in facts.values()
        if isinstance(fact, dict) and fact.get("provider")
    }
    return sorted(providers)


def dossier_entries(snapshot: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(snapshot, dict):
        return {}
    knowledge = snapshot.get("knowledge") or snapshot.get("dossier")
    if not isinstance(knowledge, dict):
        return {}
    entries: dict[str, dict[str, Any]] = {}
    categories = knowledge.get("categories", [])
    if not isinstance(categories, list):
        return entries
    for category in categories:
        if not isinstance(category, dict):
            continue
        descriptors = category.get("descriptors", [])
        if not isinstance(descriptors, list):
            continue
        for descriptor in descriptors:
            if not isinstance(descriptor, dict):
                continue
            descriptor_id = str(descriptor.get("descriptorID") or "")
            if descriptor_id:
                entries[descriptor_id] = {
                    "status": descriptor.get("status"),
                    "value": descriptor.get("value"),
                    "evidenceCount": descriptor.get("evidenceCount"),
                    "category": descriptor.get("category") or category.get("id"),
                }
    return entries


def dossier_changes(before: Any, after: Any) -> dict[str, Any]:
    before_entries = dossier_entries(before)
    after_entries = dossier_entries(after)
    added = sorted(set(after_entries) - set(before_entries))
    removed = sorted(set(before_entries) - set(after_entries))
    changed = sorted(
        key
        for key in set(before_entries) & set(after_entries)
        if before_entries[key] != after_entries[key]
    )
    after_knowledge = after.get("knowledge") if isinstance(after, dict) else None
    return {
        "scope": "player_scoped_npc_dossier",
        "beforeCount": len(before_entries),
        "afterCount": len(after_entries),
        "addedDescriptorIDs": added,
        "removedDescriptorIDs": removed,
        "changedDescriptorIDs": changed,
        "afterRevision": (
            after_knowledge.get("revision")
            if isinstance(after_knowledge, dict)
            else None
        ),
    }
