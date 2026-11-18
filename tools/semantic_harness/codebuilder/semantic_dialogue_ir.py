"""Core-owned actor-neutral Semantic Dialogue IR contracts.

This module is the shared normalization boundary for PSDL.  It deliberately
does not select a gameplay authority or render a player/NPC UI projection.
Those remain downstream consumers of the canonical IR.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from typing import Any

from .convo_engine_exchange import resolve_family_identity
from .conversation_model import canonical_json, copy_json, fingerprint
from .errors import CompileError
from .rule_contract import normalize_predicate
from .semantic_contract import (
    FORBIDDEN_POSITIONAL_ROLES,
    ParticipantSet,
    RoleSpec,
    SEMANTIC_ROLES,
    validate_semantic_role,
)


CANONICAL_IR_SCHEMA = "psychopatz.semantic.dialogue-ir.v1"
CANONICAL_IR_VERSION = 1
CONVO_ENGINE_SCHEMA = "psychopatz.convo-engine.v1"
COMPACT_PSDL_SCHEMA = "psychopatz.psdl.v2"
LEGACY_PSDL_SCHEMA = "psychopatz.semantic.dialogue-language.v1"
PSDL_SCHEMA = LEGACY_PSDL_SCHEMA
SUPPORTED_SOURCE_SCHEMAS = frozenset({COMPACT_PSDL_SCHEMA, CONVO_ENGINE_SCHEMA, LEGACY_PSDL_SCHEMA})
MAX_PARTICIPANTS = 8
MAX_SLOTS = 16
MAX_REFERENCES = 16
MAX_SLOT_SUGGEST_LIMIT = 8
MAX_CONTEXT_PATH_LENGTH = 128
MAX_CONTEXT_SEGMENTS = 8

PARTICIPANT_ROLES = SEMANTIC_ROLES
PARTICIPANT_KINDS = frozenset({"participant", "actor", "player", "npc"})
SLOT_TYPES = frozenset({
    "entity.any", "entity.person", "entity.item", "entity.location",
    "entity.faction", "entity.settlement", "entity.building", "entity.vehicle",
    "entity.task", "entity.threat", "fact", "event", "topic",
})
REFERENCE_TYPES = SLOT_TYPES | frozenset({"entity.event", "entity.fact"})
TARGET_TYPES = REFERENCE_TYPES
CONTEXT_ROOTS = frozenset({
    "speaker", "addressee", "initiator", "observer", "participants", "target",
    "actor", "subject", "beneficiary", "mediator", "supporter", "witness",
    "audience", "source", "beat",
    "relationship", "scene", "world", "slot", "reference", "conversation",
    "pragmatic", "stimulus", "history", "capability", "knowledge", "interaction",
    "flow", "social", "task", "action", "decision", "result",
    "inventory", "mood", "memory", "modifier", "event", "activity", "topic", "domain",
    "roles", "npcState", "followState", "situation",
})
PRIVATE_SEGMENTS = frozenset({"private", "secret", "undiscovered", "java", "lua", "callback"})
_NAME = re.compile(r"^[a-z][a-z0-9_]{0,31}$")


def validate_context_path(path: Any, label: str = "context path") -> str:
    if not isinstance(path, str) or not path.strip() or len(path) > MAX_CONTEXT_PATH_LENGTH:
        raise CompileError(f"{label} must be a bounded public context path")
    normalized = path.strip()
    parts = normalized.split(".")
    if len(parts) > MAX_CONTEXT_SEGMENTS or any(not part for part in parts):
        raise CompileError(f"{label} has invalid path segments")
    if parts[0] not in CONTEXT_ROOTS:
        raise CompileError(f"{label} is not a public context path: {normalized!r}")
    if any(
        part.lower() in PRIVATE_SEGMENTS
        or any(marker in part.lower() for marker in ("private", "secret", "undiscovered"))
        for part in parts
    ):
        raise CompileError(f"{label} reaches private context: {normalized!r}")
    if parts[0] in {"slot", "reference"} and len(parts) < 2:
        raise CompileError(f"{label} requires a named {parts[0]} entry")
    return normalized


def _normalize_participant_kinds(value: Any, label: str) -> list[str]:
    values = [value] if isinstance(value, str) else value
    if not isinstance(values, list) or not values or len(values) > MAX_PARTICIPANTS:
        raise CompileError(f"{label} must contain 1..{MAX_PARTICIPANTS} participant kinds")
    output: list[str] = []
    for item in values:
        if not isinstance(item, str) or item not in PARTICIPANT_KINDS:
            raise CompileError(f"{label} contains an invalid participant kind {item!r}")
        if item not in output:
            output.append(item)
    return output


def normalize_participants(value: Any, label: str = "participants") -> dict[str, list[str]]:
    if value is None:
        return {"speaker": ["participant"], "addressee": ["participant"]}
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be an object keyed by participant role")
    for role in value:
        validate_semantic_role(role, label)
    output: dict[str, list[str]] = {}
    for role in sorted(value):
        output[role] = _normalize_participant_kinds(value[role], f"{label}.{role}")
    if "speaker" not in output or "addressee" not in output:
        raise CompileError(f"{label} requires speaker and addressee roles")
    return output


def normalize_roles(value: Any, label: str = "roles") -> dict[str, dict[str, Any]] | None:
    if value is None:
        return None
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} must be a non-empty object keyed by semantic role")
    output: dict[str, dict[str, Any]] = {}
    for role_name in sorted(value, key=lambda item: str(item)):
        spec = RoleSpec.from_mapping(str(role_name), value[role_name], f"{label}.{role_name}")
        output[spec.role] = spec.to_dict()
    return output


def normalize_participant_set(value: Any, label: str = "participantSet") -> dict[str, Any] | None:
    if value is None:
        return None
    if isinstance(value, list):
        return ParticipantSet.from_iterable(value, max_size=MAX_PARTICIPANTS, label=label).to_dict()
    if isinstance(value, Mapping):
        max_size = value.get("maxSize")
        if max_size is not None and (isinstance(max_size, bool) or not isinstance(max_size, int) or max_size < 1 or max_size > MAX_PARTICIPANTS):
            raise CompileError(f"{label}.maxSize must be an integer 1..{MAX_PARTICIPANTS}")
        raw_parts = value.get("participants", [])
        return ParticipantSet.from_iterable(
            raw_parts,
            max_size=max_size if max_size is not None else MAX_PARTICIPANTS,
            label=f"{label}.participants",
        ).to_dict()
    raise CompileError(f"{label} must be a list of EntityRef or an object with participants/maxSize")


def _normalize_typed_map(
    value: Any,
    label: str,
    allowed_types: frozenset[str],
    maximum: int,
    *,
    allow_suggest: bool = False,
) -> dict[str, dict[str, Any]]:
    if value is None:
        return {}
    if not isinstance(value, Mapping) or len(value) > maximum:
        raise CompileError(f"{label} must contain at most {maximum} typed entries")
    allowed_keys = {"type", "required", "multiple", "public"}
    if allow_suggest:
        allowed_keys = allowed_keys | {"suggest", "limit"}
    output: dict[str, dict[str, Any]] = {}
    for name in sorted(value, key=lambda item: str(item)):
        if not isinstance(name, str) or not _NAME.fullmatch(name):
            raise CompileError(f"{label} contains an invalid entry name {name!r}")
        raw = value[name]
        definition = {"type": raw} if isinstance(raw, str) else raw
        if not isinstance(definition, Mapping):
            raise CompileError(f"{label}.{name} must be a type or metadata object")
        if set(definition) - allowed_keys:
            raise CompileError(f"{label}.{name} contains unsupported metadata")
        type_name = definition.get("type")
        if type_name not in allowed_types:
            raise CompileError(f"{label}.{name}.type is unsupported: {type_name!r}")
        normalized: dict[str, Any] = {
            "type": type_name,
            "required": definition.get("required", False) is True,
            "multiple": definition.get("multiple", False) is True,
            "public": definition.get("public", True) is not False,
        }
        if allow_suggest:
            if "suggest" in definition:
                suggest = definition["suggest"]
                if not isinstance(suggest, str) or not suggest.strip():
                    raise CompileError(f"{label}.{name}.suggest must be a registered provider ID")
                normalized["suggest"] = suggest.strip()
            if "limit" in definition:
                limit = definition["limit"]
                if (
                    isinstance(limit, bool)
                    or not isinstance(limit, int)
                    or limit < 1
                    or limit > MAX_SLOT_SUGGEST_LIMIT
                ):
                    raise CompileError(
                        f"{label}.{name}.limit must be an integer 1..{MAX_SLOT_SUGGEST_LIMIT}"
                    )
                normalized["limit"] = limit
        output[name] = normalized
    return output


def normalize_slots(value: Any, label: str = "slots") -> dict[str, dict[str, Any]]:
    return _normalize_typed_map(value, label, SLOT_TYPES, MAX_SLOTS, allow_suggest=True)


def normalize_references(value: Any, label: str = "references") -> dict[str, dict[str, Any]]:
    return _normalize_typed_map(value, label, REFERENCE_TYPES, MAX_REFERENCES)


def normalize_target(value: Any, label: str = "target") -> dict[str, Any]:
    if value is None:
        return {"type": "entity.any", "required": False, "multiple": False}
    raw = {"type": value} if isinstance(value, str) else value
    if not isinstance(raw, Mapping) or set(raw) - {"type", "required", "multiple"}:
        raise CompileError(f"{label} must be a typed entity reference")
    type_name = raw.get("type")
    if type_name not in TARGET_TYPES:
        raise CompileError(f"{label}.type is unsupported: {type_name!r}")
    return {
        "type": type_name,
        "required": raw.get("required", False) is True,
        "multiple": raw.get("multiple", False) is True,
    }


def _validate_predicate_paths(value: Any, label: str = "predicate") -> None:
    if value is None:
        return
    if "all" in value or "any" in value:
        key = "all" if "all" in value else "any"
        for index, child in enumerate(value[key]):
            _validate_predicate_paths(child, f"{label}.{key}[{index}]")
        return
    if "not" in value:
        _validate_predicate_paths(value["not"], f"{label}.not")
        return
    validate_context_path(value.get("path", value.get("field")), f"{label}.path")


def canonicalize_dialogue(source: Mapping[str, Any], *, source_path: str | None = None) -> dict[str, Any]:
    """Normalize one ConvoEngine/PSDL envelope into the Core Canonical Semantic Dialogue IR."""
    if not isinstance(source, Mapping):
        raise CompileError("ConvoEngine source must be an object")
    source_schema = source.get("schema")
    if source_schema not in SUPPORTED_SOURCE_SCHEMAS:
        raise CompileError(
            f"source.schema must be {CONVO_ENGINE_SCHEMA} (or migration {LEGACY_PSDL_SCHEMA})"
        )
    kind = source.get("kind")
    if kind not in {"dialogue", "behavior", "beat", "realization"}:
        raise CompileError(f"source.kind is unsupported: {kind!r}")
    record_id, namespace, local_id = resolve_family_identity(
        source.get("namespace"),
        source.get("id"),
        strict_convo_engine=(source_schema == CONVO_ENGINE_SCHEMA),
        label="source",
    )
    owner = source.get("owner")
    if not isinstance(owner, str) or not owner.strip():
        raise CompileError("source.owner must name the adopter/package owner")

    raw_when = source.get("when")
    if raw_when is None and "constraints" in source:
        raw_when = source.get("constraints")
    normalized_when = normalize_predicate(raw_when, f"{record_id}.when")
    _validate_predicate_paths(normalized_when, f"{record_id}.when")

    payload = {
        key: copy_json(source[key])
        for key in sorted(source)
        if key not in {
            "schema", "_authoringSchema", "kind", "namespace", "id", "owner",
            "participants", "roles", "participantSet", "target", "slots",
            "references", "when", "constraints",
        }
    }
    normalized_roles = normalize_roles(source.get("roles"), f"{record_id}.roles")
    normalized_participant_set = normalize_participant_set(
        source.get("participantSet"), f"{record_id}.participantSet"
    )
    authoring_schema = str(source.get("_authoringSchema") or source_schema)
    lineage: dict[str, Any] = {
        "sourceId": record_id,
        "authoringSchema": authoring_schema,
        "canonicalSchema": CONVO_ENGINE_SCHEMA,
        "sourceSchema": authoring_schema,
    }
    if namespace is not None:
        lineage["localId"] = local_id
    if source_schema == LEGACY_PSDL_SCHEMA:
        lineage["migrationReadOnly"] = True
    if source_path is not None:
        lineage["sourcePath"] = source_path
    ir: dict[str, Any] = {
        "schema": CANONICAL_IR_SCHEMA,
        "version": CANONICAL_IR_VERSION,
        "kind": kind,
        "id": record_id,
        "owner": owner,
        "participants": normalize_participants(source.get("participants")),
        "target": normalize_target(source.get("target")),
        "slots": normalize_slots(source.get("slots")),
        "references": normalize_references(source.get("references")),
        "when": normalized_when,
        "payload": payload,
        "lineage": lineage,
    }
    if namespace is not None:
        ir["namespace"] = namespace
    if normalized_roles is not None:
        ir["roles"] = normalized_roles
    if normalized_participant_set is not None:
        ir["participantSet"] = normalized_participant_set
    return ir


def canonical_ir_fingerprint(ir: Mapping[str, Any]) -> str:
    """Fingerprint semantic content without physical source-path provenance."""
    value = copy_json(ir)
    if isinstance(value.get("lineage"), dict):
        value["lineage"].pop("sourcePath", None)
    return fingerprint(value)


def validate_canonical_ir(ir: Any) -> bool:
    if not isinstance(ir, Mapping) or ir.get("schema") != CANONICAL_IR_SCHEMA:
        return False
    if ir.get("version") != CANONICAL_IR_VERSION:
        return False
    if not isinstance(ir.get("id"), str) or not isinstance(ir.get("owner"), str):
        return False
    try:
        normalize_participants(ir.get("participants"))
        if ir.get("roles") is not None:
            normalize_roles(ir.get("roles"))
        if ir.get("participantSet") is not None:
            normalize_participant_set(ir.get("participantSet"))
        normalize_target(ir.get("target"))
        normalize_slots(ir.get("slots"))
        normalize_references(ir.get("references"))
        predicate = ir.get("when")
        if predicate is not None:
            _validate_predicate_paths(normalize_predicate(predicate), "ir.when")
    except CompileError:
        return False
    return True


__all__ = [
    "CANONICAL_IR_SCHEMA",
    "CANONICAL_IR_VERSION",
    "CONVO_ENGINE_SCHEMA",
    "CONTEXT_ROOTS",
    "LEGACY_PSDL_SCHEMA",
    "PARTICIPANT_KINDS",
    "PARTICIPANT_ROLES",
    "PSDL_SCHEMA",
    "REFERENCE_TYPES",
    "SLOT_TYPES",
    "SUPPORTED_SOURCE_SCHEMAS",
    "TARGET_TYPES",
    "canonical_ir_fingerprint",
    "canonicalize_dialogue",
    "normalize_participants",
    "normalize_references",
    "normalize_slots",
    "normalize_target",
    "validate_canonical_ir",
    "validate_context_path",
]
