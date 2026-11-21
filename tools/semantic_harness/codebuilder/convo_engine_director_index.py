"""Compact derived Conversation Director index emitter (S13D/S13E).

Derives one ID-based sparse lookup index directly from canonical ConvoEngine
``behavior`` and ``beat`` plans without duplicating semantic bodies
(``payload``, ``when``, ``entry``, ``maintain``, ``exit``, ``modifiers``,
``outputs``, ``translations``, or ``action`` trees).
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Any

from .conversation_contract import CONVERSATION_MAX_INDEX_BYTES
from .dialogue_content import _lua_value
from .errors import CompileError
from .generation_ownership import normalize_owner


DIRECTOR_INDEX_SCHEMA = "psychopatz.convo-engine.director-index.v1"

FORBIDDEN_DIRECTOR_INDEX_FIELDS = frozenset({
    "payload",
    "when",
    "entry",
    "maintain",
    "exit",
    "modifiers",
    "outputs",
    "translations",
    "action",
    "exchangeFamily",
})


def extract_required_facts(record: Mapping[str, Any]) -> list[str]:
    """Recursively collect referenced predicate fact paths from a behavior/beat record."""
    paths: set[str] = set()

    def visit(node: Any, depth: int) -> None:
        if depth > 12:
            return
        if isinstance(node, Mapping):
            path_val = node.get("path")
            if isinstance(path_val, str) and path_val.strip():
                paths.add(path_val.strip())
            for key, child in node.items():
                if key == "path":
                    continue
                visit(child, depth + 1)
        elif isinstance(node, list):
            for child in node[:64]:
                visit(child, depth + 1)

    if "when" in record:
        visit(record.get("when"), 0)
    payload = record.get("payload")
    if isinstance(payload, Mapping):
        for field in ("when", "entry", "maintain", "exit"):
            if field in payload:
                visit(payload.get(field), 0)
        modifiers = payload.get("modifiers")
        if isinstance(modifiers, list):
            for mod in modifiers[:32]:
                if isinstance(mod, Mapping) and "when" in mod:
                    visit(mod.get("when"), 0)
    return sorted(paths)


def summarize_role_spec(record: Mapping[str, Any]) -> dict[str, Any]:
    """Return compact role & target cardinality summary without semantic bodies."""
    participants = record.get("participants")
    roles: list[str] = []
    role_kinds: dict[str, list[str]] = {}
    if isinstance(participants, Mapping):
        for key in sorted(participants, key=str):
            role_key = str(key)
            roles.append(role_key)
            raw_kinds = participants[key]
            if isinstance(raw_kinds, list):
                role_kinds[role_key] = [str(item) for item in raw_kinds]
            else:
                role_kinds[role_key] = []
    target = record.get("target")
    target_summary = {
        "type": str(target.get("type") or "entity.any") if isinstance(target, Mapping) else "entity.any",
        "required": bool(target.get("required", False)) if isinstance(target, Mapping) else False,
        "multiple": bool(target.get("multiple", False)) if isinstance(target, Mapping) else False,
    }
    min_participants = max(1, len(roles))
    max_participants = 4 if target_summary["multiple"] else max(2, min_participants)
    return {
        "roles": roles,
        "roleKinds": role_kinds,
        "minParticipants": min_participants,
        "maxParticipants": max_participants,
        "target": target_summary,
    }


def _extract_hook_tokens(raw: Any, key_field: str = "id") -> list[str]:
    tokens: list[str] = []
    seen: set[str] = set()
    if not isinstance(raw, list):
        return tokens
    for item in raw:
        val: str | None = None
        if isinstance(item, str) and item.strip():
            val = item.strip()
        elif isinstance(item, Mapping):
            candidate = item.get(key_field) or item.get("id") or item.get("domain")
            if isinstance(candidate, str) and candidate.strip():
                val = candidate.strip()
        if val and val not in seen:
            seen.add(val)
            tokens.append(val)
    return sorted(tokens)


def build_director_index(
    model: Mapping[str, Any],
    reports: Iterable[Mapping[str, Any]],
    *,
    include_owners: Iterable[str] | None = None,
) -> dict[str, Any]:
    """Build compact ID-keyed Director entries + sparse inverted indexes."""
    owner_filter = (
        {normalize_owner(owner) for owner in include_owners}
        if include_owners is not None
        else None
    )

    module_by_id: dict[str, str] = {}
    for report in reports:
        if report.get("kind") in ("Index", "IndexRegistry"):
            continue
        mod = report.get("module")
        if not isinstance(mod, str) or not mod:
            continue
        for rec_id in report.get("recordIDs") or ():
            if isinstance(rec_id, str) and rec_id:
                module_by_id[rec_id] = mod

    entries: dict[str, dict[str, Any]] = {}
    by_stimulus: dict[str, set[str]] = {}
    by_domain: dict[str, set[str]] = {}
    by_topic: dict[str, set[str]] = {}
    by_activity: dict[str, set[str]] = {}
    by_event_type: dict[str, set[str]] = {}
    by_required_fact: dict[str, set[str]] = {}
    by_kind: dict[str, set[str]] = {}

    plans = list(model.get("convoRuntimePlans") or ())
    plans.sort(key=lambda item: str(item.get("id") or ""))

    for record in plans:
        kind = str(record.get("kind") or "").lower()
        if kind not in ("behavior", "beat"):
            continue
        record_id = str(record.get("id") or "")
        if not record_id:
            continue
        owner = normalize_owner(record.get("owner"))
        if owner_filter is not None and owner not in owner_filter:
            continue

        payload = record.get("payload") if isinstance(record.get("payload"), Mapping) else {}
        domain = str(record.get("domain") or "social")
        domain_path = str(record.get("domainPath") or domain)
        module = str(record.get("module") or module_by_id.get(record_id) or "")
        stimuli = sorted({str(s) for s in (payload.get("stimuli") or ()) if isinstance(s, str) and s})
        domains = sorted({
            domain,
            *_extract_hook_tokens(payload.get("domains"), "domain"),
        })
        topics = _extract_hook_tokens(payload.get("topics"), "id")
        events = _extract_hook_tokens(payload.get("events"), "id")
        activities = _extract_hook_tokens(payload.get("activities"), "id")
        memories = _extract_hook_tokens(payload.get("memories"), "id")
        required_facts = extract_required_facts(record)
        role_spec = summarize_role_spec(record)
        continuation = payload.get("continuation")
        continuation_mode = (
            str(continuation.get("mode"))
            if isinstance(continuation, Mapping) and continuation.get("mode")
            else None
        )

        entry: dict[str, Any] = {
            "id": record_id,
            "kind": kind,
            "owner": owner,
            "domain": domain,
            "domainPath": domain_path,
            "module": module,
            "stimuli": stimuli,
            "domains": domains,
            "topics": topics,
            "events": events,
            "activities": activities,
            "memories": memories,
            "requiredFacts": required_facts,
            "roleSpec": role_spec,
            "baseRelevance": float(payload.get("baseRelevance", 0.5)),
        }
        if kind == "behavior":
            entry["act"] = str(payload.get("act") or "")
            entry["mode"] = str(payload.get("mode") or "beat")
            if continuation_mode is not None:
                entry["continuationMode"] = continuation_mode
        else:
            if payload.get("group") is not None:
                entry["group"] = str(payload.get("group"))
            entry["cooldownTurns"] = int(payload.get("cooldownTurns", 0))
            entry["maxTurns"] = int(payload.get("maxTurns", 6))

        entries[record_id] = entry

        by_kind.setdefault(kind, set()).add(record_id)
        for s in stimuli:
            by_stimulus.setdefault(s, set()).add(record_id)
        for d in domains:
            by_domain.setdefault(d, set()).add(record_id)
        for t in topics:
            by_topic.setdefault(t, set()).add(record_id)
        for a in activities:
            by_activity.setdefault(a, set()).add(record_id)
        for e in events:
            by_event_type.setdefault(e, set()).add(record_id)
        for f in required_facts:
            by_required_fact.setdefault(f, set()).add(record_id)

    def freeze_index(raw_map: dict[str, set[str]]) -> dict[str, list[str]]:
        return {k: sorted(v) for k, v in sorted(raw_map.items())}

    return {
        "schema": DIRECTOR_INDEX_SCHEMA,
        "version": 1,
        "entries": entries,
        "byStimulus": freeze_index(by_stimulus),
        "byDomain": freeze_index(by_domain),
        "byTopic": freeze_index(by_topic),
        "byActivity": freeze_index(by_activity),
        "byEventType": freeze_index(by_event_type),
        "byRequiredFact": freeze_index(by_required_fact),
        "byKind": freeze_index(by_kind),
    }


def render_director_index_lua(index_payload: Mapping[str, Any]) -> tuple[str, int]:
    """Serialize compact Director index payload to deterministic Lua and enforce size budget."""
    entries = index_payload.get("entries")
    if isinstance(entries, Mapping):
        for entry_id, entry in entries.items():
            if isinstance(entry, Mapping):
                forbidden = FORBIDDEN_DIRECTOR_INDEX_FIELDS.intersection(entry.keys())
                if forbidden:
                    raise CompileError(
                        f"Director index entry {entry_id!r} illegally duplicates body fields: "
                        + ", ".join(sorted(forbidden))
                    )
    source = (
        "-- Generated Conversation Director index; do not edit by hand.\n"
        "return " + _lua_value(dict(index_payload), 0) + "\n"
    )
    size = len(source.encode("utf-8"))
    if size > CONVERSATION_MAX_INDEX_BYTES:
        raise CompileError(
            "Conversation Director index exceeds the hard index budget"
        )
    return source, size


__all__ = [
    "DIRECTOR_INDEX_SCHEMA",
    "FORBIDDEN_DIRECTOR_INDEX_FIELDS",
    "build_director_index",
    "extract_required_facts",
    "render_director_index_lua",
    "summarize_role_spec",
]
