"""S11A2 normalization helpers for canonical ConvoEngine source -> IR -> Portable Plan.

Normalizes the frozen S11A1 structural vocabulary (state/input/repeat policies,
postconditions, closure/memory residue, effects, timed domain modifiers, queries,
and emergent discovery references) without altering legacy behavior records.
"""

from __future__ import annotations

from collections.abc import Callable, Mapping
from typing import Any

from .errors import CompileError
from .semantic_contract import (
    ActivityRef,
    DomainRef,
    DomainSchemaRegistry,
    EffectSpec,
    EventRef,
    INPUT_POLICIES,
    MemoryRef,
    MemoryResidueSpec,
    ModifierSpec,
    REPEAT_POLICIES,
    StatePolicyRule,
    TopicRef,
)

MAX_STATE_POLICY_RULES = 32
MAX_POSTCONDITIONS = 32
MAX_EFFECTS = 16
MAX_MODIFIERS = 16
MAX_DISCOVERY_REFS = 32
MAX_QUERIES = 16


def normalize_input_policy(value: Any, label: str = "inputPolicy") -> str:
    if not isinstance(value, str) or value.strip() not in INPUT_POLICIES:
        raise CompileError(f"{label} must be one of {sorted(INPUT_POLICIES)}, got {value!r}")
    return value.strip()


def normalize_repeat_policy(value: Any, label: str = "repeatPolicy") -> str:
    if not isinstance(value, str) or value.strip() not in REPEAT_POLICIES:
        raise CompileError(f"{label} must be one of {sorted(REPEAT_POLICIES)}, got {value!r}")
    return value.strip()


def normalize_postconditions(value: Any, label: str = "postconditions") -> list[str]:
    if not isinstance(value, list) or len(value) > MAX_POSTCONDITIONS:
        raise CompileError(f"{label} must be a list of at most {MAX_POSTCONDITIONS} postcondition strings")
    out: list[str] = []
    for idx, item in enumerate(value):
        if not isinstance(item, str) or not item.strip():
            raise CompileError(f"{label}[{idx}] must be a non-empty postcondition identifier")
        cleaned = item.strip()
        if cleaned not in out:
            out.append(cleaned)
    return out


def normalize_state_policy(
    value: Any,
    label: str = "statePolicy",
    *,
    normalize_predicate: Callable[[Any, str], Any],
    validate_paths: Callable[[Any, str], None],
) -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_STATE_POLICY_RULES:
        raise CompileError(f"{label} must be a list of at most {MAX_STATE_POLICY_RULES} rules")
    normalized: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for idx, raw_rule in enumerate(value):
        rule_label = f"{label}[{idx}]"
        rule = StatePolicyRule.from_mapping(raw_rule, rule_label)
        if rule.id in seen_ids:
            raise CompileError(f"{label} contains duplicate rule id {rule.id!r}")
        seen_ids.add(rule.id)
        rule_dict = rule.to_dict()
        if rule.when is not None:
            pred = normalize_predicate(rule.when, f"{rule_label}.when")
            validate_paths(pred, f"{rule_label}.when")
            rule_dict["when"] = pred
        normalized.append(rule_dict)
    return normalized


def normalize_effects(value: Any, label: str = "effects") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_EFFECTS:
        raise CompileError(f"{label} must be a list of at most {MAX_EFFECTS} effects")
    return [EffectSpec.from_mapping(item, f"{label}[{idx}]").to_dict() for idx, item in enumerate(value)]


def normalize_domain_modifiers(
    value: Any,
    label: str = "modifiers",
    *,
    domain_schemas: DomainSchemaRegistry | None = None,
) -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_MODIFIERS:
        raise CompileError(f"{label} must be a list of at most {MAX_MODIFIERS} modifiers")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        spec = ModifierSpec.from_mapping(item, f"{label}[{idx}]")
        if domain_schemas is not None:
            domain_schemas.validate_modifier(spec)
        out.append(spec.to_dict())
    return out


def normalize_closure(value: Any, label: str = "closure") -> dict[str, Any]:
    return MemoryResidueSpec.from_mapping(value, label).to_dict()


def normalize_topic_refs(value: Any, label: str = "topics") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_DISCOVERY_REFS:
        raise CompileError(f"{label} must be a list of at most {MAX_DISCOVERY_REFS} topic refs")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        if isinstance(item, str) and item.strip():
            out.append(TopicRef(id=item.strip()).to_dict())
        elif isinstance(item, Mapping) and isinstance(item.get("id"), str) and item["id"].strip():
            domain = item.get("domain")
            out.append(TopicRef(id=item["id"].strip(), domain=str(domain).strip() if domain else None).to_dict())
        else:
            raise CompileError(f"{label}[{idx}] must be a topic id or TopicRef object")
    return out


def normalize_event_refs(value: Any, label: str = "events") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_DISCOVERY_REFS:
        raise CompileError(f"{label} must be a list of at most {MAX_DISCOVERY_REFS} event refs")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        if isinstance(item, str) and item.strip():
            out.append(EventRef(id=item.strip()).to_dict())
        elif isinstance(item, Mapping) and isinstance(item.get("id"), str) and item["id"].strip():
            kind = str(item.get("kind") or "semantic_event").strip()
            out.append(EventRef(id=item["id"].strip(), kind=kind).to_dict())
        else:
            raise CompileError(f"{label}[{idx}] must be an event id or EventRef object")
    return out


def normalize_activity_refs(value: Any, label: str = "activities") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_DISCOVERY_REFS:
        raise CompileError(f"{label} must be a list of at most {MAX_DISCOVERY_REFS} activity refs")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        if isinstance(item, str) and item.strip():
            out.append(ActivityRef(id=item.strip()).to_dict())
        elif isinstance(item, Mapping) and isinstance(item.get("id"), str) and item["id"].strip():
            role = str(item.get("role") or "actor").strip()
            out.append(ActivityRef(id=item["id"].strip(), role=role).to_dict())
        else:
            raise CompileError(f"{label}[{idx}] must be an activity id or ActivityRef object")
    return out


def normalize_memory_refs(value: Any, label: str = "memories") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_DISCOVERY_REFS:
        raise CompileError(f"{label} must be a list of at most {MAX_DISCOVERY_REFS} memory refs")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        if isinstance(item, str) and item.strip():
            out.append(MemoryRef(id=item.strip()).to_dict())
        elif isinstance(item, Mapping) and isinstance(item.get("id"), str) and item["id"].strip():
            scope = str(item.get("scope") or "same_day").strip()
            out.append(MemoryRef(id=item["id"].strip(), scope=scope).to_dict())
        else:
            raise CompileError(f"{label}[{idx}] must be a memory id or MemoryRef object")
    return out


def normalize_domain_refs(value: Any, label: str = "domains") -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_DISCOVERY_REFS:
        raise CompileError(f"{label} must be a list of at most {MAX_DISCOVERY_REFS} domain refs")
    out: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        if not isinstance(item, Mapping):
            raise CompileError(f"{label}[{idx}] must be a DomainRef object")
        domain = item.get("domain")
        owner = item.get("owner")
        if not isinstance(domain, str) or not domain.strip() or not isinstance(owner, str) or not owner.strip():
            raise CompileError(f"{label}[{idx}] requires non-empty domain and owner")
        out.append(DomainRef(domain=domain.strip(), owner=owner.strip()).to_dict())
    return out


def normalize_queries(
    value: Any,
    label: str = "queries",
    *,
    validate_path: Callable[[Any, str], str],
) -> list[dict[str, Any]]:
    if not isinstance(value, list) or len(value) > MAX_QUERIES:
        raise CompileError(f"{label} must be a list of at most {MAX_QUERIES} portable queries")
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for idx, item in enumerate(value):
        qlabel = f"{label}[{idx}]"
        if not isinstance(item, Mapping):
            raise CompileError(f"{qlabel} must be an object")
        qid = item.get("id")
        if not isinstance(qid, str) or not qid.strip():
            raise CompileError(f"{qlabel}.id must be a non-empty identifier")
        qid = qid.strip()
        if qid in seen:
            raise CompileError(f"{label} contains duplicate query id {qid!r}")
        seen.add(qid)
        path = validate_path(item.get("path"), f"{qlabel}.path")
        entry: dict[str, Any] = {"id": qid, "path": path}
        if "op" in item and item["op"] is not None:
            entry["op"] = str(item["op"]).strip()
        if "value" in item:
            entry["value"] = item["value"]
        if "default" in item:
            entry["default"] = item["default"]
        out.append(entry)
    return out


def normalize_s11_dialogue_fields(
    payload: dict[str, Any],
    *,
    label: str,
    normalize_predicate: Callable[[Any, str], Any],
    validate_paths: Callable[[Any, str], None],
    validate_path: Callable[[Any, str], str],
    domain_schemas: DomainSchemaRegistry | None = None,
) -> dict[str, Any]:
    """Normalize S11A1/A2 dialogue-level fields in place on a dialogue payload."""
    if "statePolicy" in payload:
        payload["statePolicy"] = normalize_state_policy(
            payload["statePolicy"],
            f"{label}.statePolicy",
            normalize_predicate=normalize_predicate,
            validate_paths=validate_paths,
        )
    if "inputPolicy" in payload:
        payload["inputPolicy"] = normalize_input_policy(payload["inputPolicy"], f"{label}.inputPolicy")
    if "repeatPolicy" in payload:
        payload["repeatPolicy"] = normalize_repeat_policy(payload["repeatPolicy"], f"{label}.repeatPolicy")
    if "postconditions" in payload:
        payload["postconditions"] = normalize_postconditions(payload["postconditions"], f"{label}.postconditions")
    if "closure" in payload:
        payload["closure"] = normalize_closure(payload["closure"], f"{label}.closure")
    if "effects" in payload:
        payload["effects"] = normalize_effects(payload["effects"], f"{label}.effects")
    if "modifiers" in payload:
        payload["modifiers"] = normalize_domain_modifiers(
            payload["modifiers"],
            f"{label}.modifiers",
            domain_schemas=domain_schemas,
        )
    if "archetype" in payload:
        arch = payload["archetype"]
        if not isinstance(arch, str) or not arch.strip():
            raise CompileError(f"{label}.archetype must be a non-empty identifier")
        payload["archetype"] = arch.strip()
    if "topics" in payload:
        payload["topics"] = normalize_topic_refs(payload["topics"], f"{label}.topics")
    if "events" in payload:
        payload["events"] = normalize_event_refs(payload["events"], f"{label}.events")
    if "activities" in payload:
        payload["activities"] = normalize_activity_refs(payload["activities"], f"{label}.activities")
    if "memories" in payload:
        payload["memories"] = normalize_memory_refs(payload["memories"], f"{label}.memories")
    if "domains" in payload:
        payload["domains"] = normalize_domain_refs(payload["domains"], f"{label}.domains")
    if "queries" in payload:
        payload["queries"] = normalize_queries(
            payload["queries"],
            f"{label}.queries",
            validate_path=validate_path,
        )
    return payload


__all__ = [
    "normalize_activity_refs",
    "normalize_closure",
    "normalize_domain_modifiers",
    "normalize_domain_refs",
    "normalize_effects",
    "normalize_event_refs",
    "normalize_input_policy",
    "normalize_memory_refs",
    "normalize_postconditions",
    "normalize_queries",
    "normalize_repeat_policy",
    "normalize_s11_dialogue_fields",
    "normalize_state_policy",
    "normalize_topic_refs",
]
