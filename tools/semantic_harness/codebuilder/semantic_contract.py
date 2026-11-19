"""Canonical S11 v1 semantic data-model and domain-schema contracts.

This module freezes the generic, participant-count-agnostic structural
vocabulary for ConvoEngine before compiler normalization, analyzer
construction, or production dialogue migration.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence

from tools.semantic_harness.codebuilder.errors import CompileError

S11_CONTRACT_VERSION = "psychopatz.convo-engine.s11-contract.v1"

# Generic semantic roles (participant-count agnostic; never actor1/actor2/speaker1/speaker2).
SEMANTIC_ROLES = frozenset(
    {
        "speaker",
        "addressee",
        "actor",
        "target",
        "subject",
        "beneficiary",
        "mediator",
        "supporter",
        "witness",
        "audience",
        "observer",
        "source",
        "initiator",
    }
)

FORBIDDEN_POSITIONAL_ROLES = frozenset(
    {"actor1", "actor2", "actor3", "speaker1", "speaker2", "speaker3", "npc1", "npc2"}
)

ROLE_CARDINALITIES = frozenset(
    {
        "ONE",
        "OPTIONAL_ONE",
        "ONE_OR_MORE",
        "ZERO_OR_MORE",
        "BOUNDED_MANY",
    }
)

PRE_ADMISSION_OUTCOMES = frozenset(
    {
        "actionable",
        "already_satisfied",
        "blocked",
        "unavailable",
        "requires_confirmation",
        "pending",
        "deferred",
    }
)

POST_DISPATCH_OUTCOMES = frozenset(
    {
        "queued",
        "accepted",
        "rejected",
        "failed",
        "completed",
        "pending",
    }
)

ALL_SEMANTIC_OUTCOMES = PRE_ADMISSION_OUTCOMES | POST_DISPATCH_OUTCOMES

ADMISSION_MODES = frozenset(
    {
        "dispatch",
        "no_op",
        "reject",
        "confirm",
        "defer",
        "none",
    }
)

INPUT_POLICIES = frozenset(
    {
        "typed_parity",
        "typed_confirmation",
        "presentation_only",
    }
)

REPEAT_POLICIES = frozenset(
    {
        "once",
        "cooldown",
        "max_uses",
        "state_retired",
        "repeatable",
        "idempotent",
    }
)

RETENTION_KINDS = frozenset(
    {
        "SESSION",
        "TIMED",
        "UNTIL",
        "PERMANENT",
    }
)

STACKING_MODES = frozenset(
    {
        "replace",
        "refresh",
        "extend",
        "stack",
        "accumulate",
        "ignore",
    }
)

CLOSURE_CLASSES = frozenset(
    {
        "none",
        "resolved_episode",
        "durable_fact_ref",
        "open_domain_obligation",
        "state_transition",
    }
)

_DURATION_RE = re.compile(r"^([1-9][0-9]*)(m|h|d|w)$")
_DURATION_MINUTES = {
    "m": 1,
    "h": 60,
    "d": 60 * 24,
    "w": 60 * 24 * 7,
}
_IDENTIFIER_RE = re.compile(r"^[a-z][a-z0-9_.-]*$")


def normalize_duration_minutes(value: Any, label: str = "duration") -> int:
    """Normalize a compact duration literal (30m, 6h, 1d, 7d, 2w) or positive int to game minutes."""
    if isinstance(value, int) and not isinstance(value, bool):
        if value <= 0:
            raise CompileError(f"{label} must be > 0 minutes, got {value!r}")
        return value
    if isinstance(value, str):
        match = _DURATION_RE.match(value.strip())
        if match:
            amount = int(match.group(1))
            unit = match.group(2)
            return amount * _DURATION_MINUTES[unit]
    raise CompileError(
        f"{label} must be a positive integer (minutes) or duration literal (e.g. 30m, 6h, 1d, 7d, 2w), got {value!r}"
    )


def _require_identifier(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _IDENTIFIER_RE.match(value.strip()):
        raise CompileError(f"{label} must be a non-empty lowercase identifier, got {value!r}")
    return value.strip()


@dataclass(frozen=True)
class EntityRef:
    id: str
    kind: str = "actor"
    role: str | None = None

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "entityRef") -> "EntityRef":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        eid = _require_identifier(raw.get("id"), f"{label}.id")
        kind = _require_identifier(raw.get("kind", "actor"), f"{label}.kind")
        role_raw = raw.get("role")
        role = None
        if role_raw is not None:
            role = validate_semantic_role(role_raw, f"{label}.role")
        return cls(id=eid, kind=kind, role=role)

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {"id": self.id, "kind": self.kind}
        if self.role is not None:
            out["role"] = self.role
        return out


@dataclass(frozen=True)
class ParticipantSet:
    participants: tuple[EntityRef, ...]
    max_size: int | None = None

    @classmethod
    def from_iterable(
        cls,
        raw: Sequence[Any],
        *,
        max_size: int | None = None,
        label: str = "participantSet",
    ) -> "ParticipantSet":
        if not isinstance(raw, (list, tuple)):
            raise CompileError(f"{label} must be a list of EntityRef objects")
        refs = tuple(EntityRef.from_mapping(item, f"{label}[{idx}]") for idx, item in enumerate(raw))
        if max_size is not None and len(refs) > max_size:
            raise CompileError(f"{label} exceeds max_size={max_size}: got {len(refs)}")
        return cls(participants=refs, max_size=max_size)

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {"participants": [p.to_dict() for p in self.participants]}
        if self.max_size is not None:
            out["maxSize"] = self.max_size
        return out


def validate_semantic_role(role: Any, label: str = "role") -> str:
    if not isinstance(role, str) or not role.strip():
        raise CompileError(f"{label} must be a non-empty string")
    cleaned = role.strip()
    if cleaned in FORBIDDEN_POSITIONAL_ROLES:
        raise CompileError(
            f"{label} uses forbidden positional role {cleaned!r}; use semantic roles in {sorted(SEMANTIC_ROLES)}"
        )
    if cleaned not in SEMANTIC_ROLES:
        raise CompileError(f"{label} unsupported role {cleaned!r}; expected one of {sorted(SEMANTIC_ROLES)}")
    return cleaned


@dataclass(frozen=True)
class RoleSpec:
    role: str
    cardinality: str = "ONE"
    entity_kinds: tuple[str, ...] = ("actor",)
    min_count: int | None = None
    max_count: int | None = None

    @classmethod
    def from_mapping(cls, role_name: str, raw: Any, label: str = "roleSpec") -> "RoleSpec":
        role = validate_semantic_role(role_name, f"{label}.role")
        if isinstance(raw, Mapping):
            card = str(raw.get("cardinality", "ONE")).strip()
            if card not in ROLE_CARDINALITIES:
                raise CompileError(f"{label}.cardinality unsupported: {card!r}")
            kinds_raw = raw.get("kinds") or raw.get("entityKinds") or ("actor",)
            if not isinstance(kinds_raw, (list, tuple)) or not kinds_raw:
                raise CompileError(f"{label}.kinds must be a non-empty list")
            kinds = tuple(_require_identifier(k, f"{label}.kinds") for k in kinds_raw)
            min_c = raw.get("min")
            max_c = raw.get("max")
            if card == "BOUNDED_MANY":
                if not isinstance(min_c, int) or not isinstance(max_c, int) or min_c < 0 or max_c < min_c:
                    raise CompileError(f"{label} BOUNDED_MANY requires integer 0 <= min <= max")
            return cls(role=role, cardinality=card, entity_kinds=kinds, min_count=min_c, max_count=max_c)
        raise CompileError(f"{label} must be an object")

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "role": self.role,
            "cardinality": self.cardinality,
            "kinds": list(self.entity_kinds),
        }
        if self.min_count is not None:
            out["min"] = self.min_count
        if self.max_count is not None:
            out["max"] = self.max_count
        return out


@dataclass(frozen=True)
class RoleBinding:
    role: str
    entities: tuple[EntityRef, ...]

    def validate_against(self, spec: RoleSpec, label: str = "roleBinding") -> None:
        if self.role != spec.role:
            raise CompileError(f"{label} role mismatch: {self.role!r} != {spec.role!r}")
        count = len(self.entities)
        card = spec.cardinality
        if card == "ONE" and count != 1:
            raise CompileError(f"{label} ({self.role}) requires ONE entity, got {count}")
        elif card == "OPTIONAL_ONE" and count > 1:
            raise CompileError(f"{label} ({self.role}) requires OPTIONAL_ONE entity, got {count}")
        elif card == "ONE_OR_MORE" and count < 1:
            raise CompileError(f"{label} ({self.role}) requires ONE_OR_MORE entities, got {count}")
        elif card == "BOUNDED_MANY":
            lo = spec.min_count or 0
            hi = spec.max_count if spec.max_count is not None else count
            if count < lo or count > hi:
                raise CompileError(f"{label} ({self.role}) requires {lo}..{hi} entities, got {count}")
        for ref in self.entities:
            if spec.entity_kinds and ref.kind not in spec.entity_kinds:
                raise CompileError(
                    f"{label} ({self.role}) entity {ref.id!r} kind {ref.kind!r} not in {spec.entity_kinds}"
                )

    def to_dict(self) -> dict[str, Any]:
        return {"role": self.role, "entities": [e.to_dict() for e in self.entities]}


@dataclass(frozen=True)
class TopicRef:
    id: str
    domain: str | None = None

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {"id": self.id}
        if self.domain:
            out["domain"] = self.domain
        return out


@dataclass(frozen=True)
class EventRef:
    id: str
    kind: str = "semantic_event"

    def to_dict(self) -> dict[str, Any]:
        return {"id": self.id, "kind": self.kind}


@dataclass(frozen=True)
class ActivityRef:
    id: str
    role: str = "actor"

    def to_dict(self) -> dict[str, Any]:
        return {"id": self.id, "role": self.role}


@dataclass(frozen=True)
class MemoryRef:
    id: str
    scope: str = "same_day"

    def to_dict(self) -> dict[str, Any]:
        return {"id": self.id, "scope": self.scope}


@dataclass(frozen=True)
class DomainRef:
    domain: str
    owner: str

    def to_dict(self) -> dict[str, Any]:
        return {"domain": self.domain, "owner": self.owner}


@dataclass(frozen=True)
class RetentionSpec:
    kind: str
    duration_minutes: int | None = None
    until_fact: str | None = None

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "retention") -> "RetentionSpec":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        kind = str(raw.get("kind", "SESSION")).strip()
        if kind not in RETENTION_KINDS:
            raise CompileError(f"{label}.kind unsupported: {kind!r}")
        duration_minutes = None
        until_fact = None
        if kind == "TIMED":
            duration_minutes = normalize_duration_minutes(raw.get("duration"), f"{label}.duration")
        elif kind == "UNTIL":
            uf = raw.get("untilFact") or raw.get("until")
            if not isinstance(uf, str) or not uf.strip():
                raise CompileError(f"{label}.untilFact is required when kind == 'UNTIL'")
            until_fact = uf.strip()
        return cls(kind=kind, duration_minutes=duration_minutes, until_fact=until_fact)

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {"kind": self.kind}
        if self.duration_minutes is not None:
            out["durationMinutes"] = self.duration_minutes
        if self.until_fact is not None:
            out["untilFact"] = self.until_fact
        return out


@dataclass(frozen=True)
class EffectSpec:
    type: str
    target_role: str = "addressee"
    params: Mapping[str, Any] = field(default_factory=dict)

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "effect") -> "EffectSpec":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        etype = _require_identifier(raw.get("type"), f"{label}.type")
        target_role = validate_semantic_role(raw.get("targetRole", "addressee"), f"{label}.targetRole")
        params = raw.get("params") or {}
        if not isinstance(params, Mapping):
            raise CompileError(f"{label}.params must be an object")
        return cls(type=etype, target_role=target_role, params=dict(params))

    def to_dict(self) -> dict[str, Any]:
        return {"type": self.type, "targetRole": self.target_role, "params": dict(self.params)}


@dataclass(frozen=True)
class ModifierSpec:
    id: str
    domain: str
    field: str
    delta: float | int
    retention: RetentionSpec
    stacking: str = "replace"
    target_role: str = "addressee"

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "modifier") -> "ModifierSpec":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        mid = _require_identifier(raw.get("id"), f"{label}.id")
        domain = _require_identifier(raw.get("domain"), f"{label}.domain")
        fld = _require_identifier(raw.get("field"), f"{label}.field")
        delta = raw.get("delta")
        if isinstance(delta, bool) or not isinstance(delta, (int, float)):
            raise CompileError(f"{label}.delta must be a number, got {delta!r}")
        retention = RetentionSpec.from_mapping(raw.get("retention", {}), f"{label}.retention")
        stacking = str(raw.get("stacking", "replace")).strip()
        if stacking not in STACKING_MODES:
            raise CompileError(f"{label}.stacking unsupported: {stacking!r}")
        target_role = validate_semantic_role(raw.get("targetRole", "addressee"), f"{label}.targetRole")
        return cls(
            id=mid,
            domain=domain,
            field=fld,
            delta=delta,
            retention=retention,
            stacking=stacking,
            target_role=target_role,
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "domain": self.domain,
            "field": self.field,
            "delta": self.delta,
            "retention": self.retention.to_dict(),
            "stacking": self.stacking,
            "targetRole": self.target_role,
        }


@dataclass(frozen=True)
class MemoryResidueSpec:
    closure_class: str
    episode_id: str | None = None
    retention: RetentionSpec | None = None
    obligation_ref: str | None = None

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "memoryResidue") -> "MemoryResidueSpec":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        cc = str(raw.get("closureClass", "none")).strip()
        if cc not in CLOSURE_CLASSES:
            raise CompileError(f"{label}.closureClass unsupported: {cc!r}")
        ep = raw.get("episodeId")
        if ep is not None:
            ep = _require_identifier(ep, f"{label}.episodeId")
        ret = None
        if raw.get("retention") is not None:
            ret = RetentionSpec.from_mapping(raw["retention"], f"{label}.retention")
        ob = raw.get("obligationRef")
        if ob is not None and (not isinstance(ob, str) or not ob.strip()):
            raise CompileError(f"{label}.obligationRef must be a non-empty string")
        return cls(closure_class=cc, episode_id=ep, retention=ret, obligation_ref=ob)

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {"closureClass": self.closure_class}
        if self.episode_id is not None:
            out["episodeId"] = self.episode_id
        if self.retention is not None:
            out["retention"] = self.retention.to_dict()
        if self.obligation_ref is not None:
            out["obligationRef"] = self.obligation_ref
        return out


@dataclass(frozen=True)
class StatePolicyRule:
    id: str
    outcome: str
    reason: str
    admission: str
    when: Any = None
    reply_outcome: str | None = None

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any], label: str = "statePolicyRule") -> "StatePolicyRule":
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        rid = _require_identifier(raw.get("id"), f"{label}.id")
        outcome = str(raw.get("outcome", "")).strip()
        if outcome not in PRE_ADMISSION_OUTCOMES:
            raise CompileError(f"{label}.outcome unsupported: {outcome!r}")
        reason = _require_identifier(raw.get("reason", outcome), f"{label}.reason")
        admission = str(raw.get("admission", "")).strip()
        if admission not in ADMISSION_MODES:
            raise CompileError(f"{label}.admission unsupported: {admission!r}")
        reply_outcome = raw.get("replyOutcome")
        if reply_outcome is not None:
            reply_outcome = _require_identifier(reply_outcome, f"{label}.replyOutcome")
        return cls(
            id=rid,
            outcome=outcome,
            reason=reason,
            admission=admission,
            when=raw.get("when"),
            reply_outcome=reply_outcome,
        )

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "id": self.id,
            "outcome": self.outcome,
            "reason": self.reason,
            "admission": self.admission,
        }
        if self.when is not None:
            out["when"] = self.when
        if self.reply_outcome is not None:
            out["replyOutcome"] = self.reply_outcome
        return out


@dataclass(frozen=True)
class SemanticOutcomeEnvelope:
    family_id: str
    matched_rule_id: str
    outcome: str
    reason: str
    admission: str
    state_changed: bool = False
    capability_id: str | None = None
    reply_outcome: str | None = None
    postconditions: tuple[str, ...] = ()

    def validate(self) -> None:
        if self.outcome not in ALL_SEMANTIC_OUTCOMES:
            raise CompileError(f"SemanticOutcome unsupported outcome: {self.outcome!r}")
        if self.admission not in ADMISSION_MODES:
            raise CompileError(f"SemanticOutcome unsupported admission: {self.admission!r}")

    def to_dict(self) -> dict[str, Any]:
        self.validate()
        out: dict[str, Any] = {
            "familyId": self.family_id,
            "matchedRuleId": self.matched_rule_id,
            "outcome": self.outcome,
            "reason": self.reason,
            "admission": self.admission,
            "stateChanged": self.state_changed,
        }
        if self.capability_id is not None:
            out["capabilityId"] = self.capability_id
        if self.reply_outcome is not None:
            out["replyOutcome"] = self.reply_outcome
        if self.postconditions:
            out["postconditions"] = list(self.postconditions)
        return out


@dataclass(frozen=True)
class SemanticBeatSpec:
    id: str
    archetype: str
    roles: Mapping[str, RoleSpec]
    topics: tuple[TopicRef, ...] = ()
    events: tuple[EventRef, ...] = ()
    activities: tuple[ActivityRef, ...] = ()
    memories: tuple[MemoryRef, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "archetype": self.archetype,
            "roles": {k: v.to_dict() for k, v in self.roles.items()},
            "topics": [t.to_dict() for t in self.topics],
            "events": [e.to_dict() for e in self.events],
            "activities": [a.to_dict() for a in self.activities],
            "memories": [m.to_dict() for m in self.memories],
        }


@dataclass(frozen=True)
class ConversationArchetypeSpec:
    id: str
    roles: Mapping[str, RoleSpec]
    input_policy: str = "typed_parity"
    repeat_policy: str = "repeatable"
    state_policy: tuple[StatePolicyRule, ...] = ()
    postconditions: tuple[str, ...] = ()
    continuation: str = "close"
    closure: MemoryResidueSpec = field(default_factory=lambda: MemoryResidueSpec(closure_class="none"))

    def validate(self) -> None:
        _require_identifier(self.id, "archetype.id")
        if self.input_policy not in INPUT_POLICIES:
            raise CompileError(f"archetype.inputPolicy unsupported: {self.input_policy!r}")
        if self.repeat_policy not in REPEAT_POLICIES:
            raise CompileError(f"archetype.repeatPolicy unsupported: {self.repeat_policy!r}")
        for role_name in self.roles:
            validate_semantic_role(role_name, "archetype.roles")

    def to_dict(self) -> dict[str, Any]:
        self.validate()
        return {
            "id": self.id,
            "roles": {k: v.to_dict() for k, v in self.roles.items()},
            "inputPolicy": self.input_policy,
            "repeatPolicy": self.repeat_policy,
            "statePolicy": [r.to_dict() for r in self.state_policy],
            "postconditions": list(self.postconditions),
            "continuation": self.continuation,
            "closure": self.closure.to_dict(),
        }


@dataclass(frozen=True)
class DomainSchema:
    """Adopter-owned domain schema contract (relationship, mood, inventory, etc.)."""

    domain: str
    owner: str
    allowed_facts: frozenset[str] = frozenset()
    allowed_effects: frozenset[str] = frozenset()
    allowed_modifier_fields: Mapping[str, tuple[float, float]] = field(default_factory=dict)
    allowed_actions: frozenset[str] = frozenset()

    def validate_modifier(self, modifier: ModifierSpec) -> None:
        if modifier.domain != self.domain:
            raise CompileError(f"Modifier {modifier.id!r} domain {modifier.domain!r} != {self.domain!r}")
        if modifier.field not in self.allowed_modifier_fields:
            raise CompileError(
                f"Modifier {modifier.id!r} field {modifier.field!r} not registered in domain {self.domain!r}"
            )
        lo, hi = self.allowed_modifier_fields[modifier.field]
        if modifier.delta < lo or modifier.delta > hi:
            raise CompileError(
                f"Modifier {modifier.id!r} delta {modifier.delta} outside [{lo}, {hi}] for {self.domain}.{modifier.field}"
            )


class DomainSchemaRegistry:
    """Registry for adopter-owned domain schemas; Core never hard-codes adopter schemas."""

    def __init__(self) -> None:
        self._schemas: dict[str, DomainSchema] = {}

    def register(self, schema: DomainSchema) -> None:
        _require_identifier(schema.domain, "domainSchema.domain")
        if not schema.owner:
            raise CompileError("domainSchema.owner must be non-empty")
        self._schemas[schema.domain] = schema

    def get(self, domain: str) -> DomainSchema | None:
        return self._schemas.get(domain)

    def require(self, domain: str) -> DomainSchema:
        schema = self._schemas.get(domain)
        if schema is None:
            raise CompileError(f"Unregistered domain schema: {domain!r}")
        return schema

    def validate_modifier(self, modifier: ModifierSpec) -> None:
        self.require(modifier.domain).validate_modifier(modifier)


__all__ = [
    "ADMISSION_MODES",
    "ALL_SEMANTIC_OUTCOMES",
    "ActivityRef",
    "CLOSURE_CLASSES",
    "ConversationArchetypeSpec",
    "DomainRef",
    "DomainSchema",
    "DomainSchemaRegistry",
    "EffectSpec",
    "EntityRef",
    "FORBIDDEN_POSITIONAL_ROLES",
    "INPUT_POLICIES",
    "MemoryRef",
    "MemoryResidueSpec",
    "ModifierSpec",
    "POST_DISPATCH_OUTCOMES",
    "PRE_ADMISSION_OUTCOMES",
    "ParticipantSet",
    "REPEAT_POLICIES",
    "RETENTION_KINDS",
    "ROLE_CARDINALITIES",
    "RetentionSpec",
    "RoleBinding",
    "RoleSpec",
    "S11_CONTRACT_VERSION",
    "SEMANTIC_ROLES",
    "STACKING_MODES",
    "SemanticBeatSpec",
    "SemanticOutcomeEnvelope",
    "StatePolicyRule",
    "TopicRef",
    "EventRef",
    "normalize_duration_minutes",
    "validate_semantic_role",
]
