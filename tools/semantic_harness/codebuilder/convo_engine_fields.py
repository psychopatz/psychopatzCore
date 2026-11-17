"""Compiler-owned ConvoEngine schema field descriptors.

Studio and CLI inspect these descriptors instead of duplicating hardcoded field
tables in UI panes. Unknown future top-level fields are surfaced via
``describe_unknown_fields`` and preserved on editor round trips.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any, Mapping


ALL_FAMILY_KINDS: tuple[str, ...] = ("dialogue", "behavior", "beat", "realization")


@dataclass(frozen=True)
class FieldDescriptor:
    """Authoritative descriptor for a top-level ConvoEngine family field."""

    name: str
    label: str
    category: str
    editor_kind: str
    kinds: tuple[str, ...]
    summary: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


CONVO_ENGINE_FIELD_DESCRIPTORS: tuple[FieldDescriptor, ...] = (
    # Identity & ownership
    FieldDescriptor("schema", "Schema", "identity", "scalar", ALL_FAMILY_KINDS, "Canonical schema identifier (psychopatz.convo-engine.v1)."),
    FieldDescriptor("kind", "Kind", "identity", "scalar", ALL_FAMILY_KINDS, "Family kind: dialogue, behavior, beat, or realization."),
    FieldDescriptor("namespace", "Namespace", "identity", "scalar", ALL_FAMILY_KINDS, "Compact family namespace segment."),
    FieldDescriptor("id", "Local / Family ID", "identity", "scalar", ALL_FAMILY_KINDS, "Compact local family identifier."),
    FieldDescriptor("version", "Version", "identity", "scalar", ALL_FAMILY_KINDS, "Optional integer schema/content revision."),
    FieldDescriptor("owner", "Owner", "identity", "scalar", ALL_FAMILY_KINDS, "Owning mod package (manifest-routed)."),
    FieldDescriptor("_authoringSchema", "Authoring schema", "identity", "scalar", ALL_FAMILY_KINDS, "Normalized authoring-schema provenance tag."),
    # Participants, target, slots
    FieldDescriptor("participants", "Participants", "participants", "json", ("dialogue", "behavior", "beat"), "Speaker and addressee role filters."),
    FieldDescriptor("target", "Target", "participants", "json", ("dialogue", "behavior", "beat"), "Target entity contract and constraints."),
    FieldDescriptor("slots", "Slots", "participants", "json", ALL_FAMILY_KINDS, "Typed slot definitions bound into prompts, predicates, and speech."),
    # Primary exchange JSON editors (order preserved for ConvoEngine Studio structured pane)
    FieldDescriptor("when", "When predicate / collection constraints", "exchange", "json", ALL_FAMILY_KINDS, "Shared production predicate governing eligibility."),
    FieldDescriptor("invoke", "Semantic invoke intent / subject / target", "exchange", "json", ("dialogue",), "Structured semantic invoke contract (act, intent, subject, topic)."),
    FieldDescriptor("affordance", "Affordance (UI-only label, consumers, utility)", "exchange", "json", ("dialogue", "behavior"), "UI button label, player/NPC consumers, channels, utility dimensions."),
    FieldDescriptor("execute", "Registered execute action & typed inputs", "exchange", "json", ("dialogue", "behavior", "beat"), "Typed action contract reference and bound parameters."),
    FieldDescriptor("action", "Action", "dialogue", "json", ("dialogue", "behavior", "beat"), "Compact action binding shorthand compiled into execute."),
    FieldDescriptor("say", "Initiating say (string or stable numeric realization keys)", "exchange", "json", ("dialogue", "behavior", "realization"), "Actor speech template or keyed realization map."),
    FieldDescriptor("reply", "Named reply outcomes & independent realizations", "exchange", "json", ("dialogue",), "Outcome-keyed reply realizations and state bindings."),
    FieldDescriptor("after", "Chaining (recommend, recommendGroup, goto, end, resume)", "exchange", "json", ("dialogue", "behavior", "beat"), "Post-exchange transition, recommendation, and flow controls."),
    FieldDescriptor("metadata", "Functional runtime metadata", "exchange", "json", ALL_FAMILY_KINDS, "Extensible non-executable authoring and runtime metadata."),
    # Additional compiler-supported exchange / dialogue / realization fields
    FieldDescriptor("constraints", "Constraints (legacy alias of when)", "dialogue", "json", ALL_FAMILY_KINDS, "Legacy eligibility constraint expression."),
    FieldDescriptor("references", "Semantic references", "dialogue", "json", ALL_FAMILY_KINDS, "Explicit cross-family semantic reference declarations."),
    FieldDescriptor("on", "Stimulus triggers", "dialogue", "json", ("dialogue", "behavior", "beat"), "Trigger events and stimulus bindings."),
    FieldDescriptor("respond", "Respond strategy", "dialogue", "json", ("dialogue",), "Single-turn respond specification."),
    FieldDescriptor("response", "Response selection", "dialogue", "json", ("dialogue",), "Legacy response block specification."),
    FieldDescriptor("variants", "Realization variants", "realization", "json", ("dialogue", "realization"), "Keyed textual realization variants."),
    FieldDescriptor("turns", "Turn plan", "dialogue", "json", ("dialogue",), "Bounded multi-turn template sequence."),
    FieldDescriptor("offers", "Affordance offers", "dialogue", "json", ("dialogue",), "Offer projections exposed for UI selection."),
    FieldDescriptor("transitions", "Transitions", "dialogue", "json", ("dialogue", "behavior", "beat"), "Transition rules across turns or states."),
    FieldDescriptor("bindings", "Text bindings", "realization", "json", ALL_FAMILY_KINDS, "Role/slot text binding mappings."),
    FieldDescriptor("text", "Text payload", "realization", "json", ALL_FAMILY_KINDS, "Direct localized text mapping."),
    FieldDescriptor("label", "Display label", "realization", "json", ALL_FAMILY_KINDS, "Compact UI label template."),
    FieldDescriptor("utterance", "Utterance mapping", "realization", "json", ALL_FAMILY_KINDS, "Direct utterance specification."),
    FieldDescriptor("stimuli", "Stimuli", "director", "json", ("behavior", "beat"), "Stimulus inputs that activate the director item."),
    FieldDescriptor("act", "Dialogue act", "dialogue", "scalar", ("dialogue", "realization"), "Primary dialogue act identifier."),
    FieldDescriptor("mode", "Execution mode", "dialogue", "scalar", ("dialogue", "behavior", "beat"), "Interaction or execution mode."),
    FieldDescriptor("requiredCapabilities", "Required capabilities", "participants", "json", ALL_FAMILY_KINDS, "Capabilities required on participating actors/providers."),
    FieldDescriptor("outputs", "Outputs", "dialogue", "json", ("dialogue", "behavior", "beat"), "Declared semantic or action output keys."),
    FieldDescriptor("modifiers", "Utility modifiers", "director", "json", ("dialogue", "behavior", "beat"), "State-weighted preference/utility modifiers."),
    FieldDescriptor("continuation", "Continuation policy", "dialogue", "json", ("dialogue", "behavior", "beat"), "Bounded chaining continuation rule."),
    FieldDescriptor("baseRelevance", "Base relevance", "director", "scalar", ("dialogue", "behavior", "beat"), "Numeric base relevance weight."),
    FieldDescriptor("entry", "Entry condition", "director", "json", ("behavior", "beat"), "Director behavior/beat entry guard."),
    FieldDescriptor("maintain", "Maintain condition", "director", "json", ("behavior", "beat"), "Director behavior/beat maintenance predicate."),
    FieldDescriptor("exit", "Exit condition", "director", "json", ("behavior", "beat"), "Director behavior/beat termination guard."),
    FieldDescriptor("candidates", "Candidates", "director", "json", ("behavior", "beat"), "Bounded candidate member list."),
    FieldDescriptor("group", "Group", "director", "scalar", ALL_FAMILY_KINDS, "Optional semantic grouping tag."),
    FieldDescriptor("cooldownTurns", "Cooldown turns", "director", "scalar", ("dialogue", "behavior", "beat"), "Minimum turns before re-selection."),
    FieldDescriptor("maxTurns", "Max turns", "director", "scalar", ("dialogue", "behavior", "beat"), "Maximum active turns before expiry."),
    FieldDescriptor("effects", "Effects", "director", "json", ("dialogue", "behavior", "beat"), "State effects applied alongside execution."),
    FieldDescriptor("policy", "Policy", "director", "json", ("behavior", "beat"), "Arbiter/director scheduling policy."),
    FieldDescriptor("style", "Style", "realization", "json", ("dialogue", "realization"), "Register/style hints for realization."),
    FieldDescriptor("resolver", "Resolver", "realization", "json", ("dialogue", "realization"), "Slot/noun resolution hints."),
    FieldDescriptor("recognition", "NLU recognition cues", "dialogue", "json", ("dialogue", "realization"), "Surface cue/recognition configuration."),
    FieldDescriptor("type", "Family sub-type", "realization", "scalar", ("realization",), "Realization record sub-type."),
    FieldDescriptor("strategy", "Realization strategy", "realization", "scalar", ("realization",), "Selection/rendering strategy."),
    FieldDescriptor("dialogueAct", "Dialogue act", "realization", "scalar", ("dialogue", "realization"), "Dialogue act classification."),
    FieldDescriptor("concept", "Semantic concept", "realization", "scalar", ("realization",), "Concept anchor for realization."),
    FieldDescriptor("forms", "Linguistic forms", "realization", "json", ("realization",), "Inflected or register-specific realization forms."),
    FieldDescriptor("translations", "Inline translations", "realization", "json", ("realization",), "Explicit inline locale overrides."),
    FieldDescriptor("aliases", "Aliases", "realization", "json", ("realization",), "Alternative lexical surface forms."),
    FieldDescriptor("roles", "Role specifications", "participants", "json", ("dialogue", "beat"), "Participant-agnostic semantic role cardinality specs."),
    FieldDescriptor("participantSet", "Participant set", "participants", "json", ("dialogue", "beat"), "Bounded participant set constraints."),
    FieldDescriptor("statePolicy", "State policy", "dialogue", "json", ("dialogue",), "Pre-admission state policy rules and outcomes."),
    FieldDescriptor("inputPolicy", "Input policy", "dialogue", "scalar", ("dialogue",), "Typed vs click parity input policy."),
    FieldDescriptor("repeatPolicy", "Repeat policy", "dialogue", "scalar", ("dialogue",), "Idempotence, cooldown, and repeat retirement policy."),
    FieldDescriptor("postconditions", "Postconditions", "dialogue", "json", ("dialogue",), "Expected post-state assertions."),
    FieldDescriptor("closure", "Closure residue", "dialogue", "json", ("dialogue",), "Semantic episode closure and memory residue contract."),
    FieldDescriptor("archetype", "Conversation archetype", "dialogue", "scalar", ("dialogue", "beat"), "Archetype classification for discovery and analysis."),
    FieldDescriptor("topics", "Topics", "dialogue", "json", ("dialogue", "beat"), "Structured TopicRef discovery metadata."),
    FieldDescriptor("events", "Events", "dialogue", "json", ("dialogue", "beat"), "Structured EventRef discovery metadata."),
    FieldDescriptor("activities", "Activities", "dialogue", "json", ("dialogue", "beat"), "Structured ActivityRef discovery metadata."),
    FieldDescriptor("memories", "Memories", "dialogue", "json", ("dialogue", "beat"), "Structured MemoryRef discovery metadata."),
    FieldDescriptor("domains", "Domains", "dialogue", "json", ("dialogue", "beat"), "Structured DomainRef ownership metadata."),
    FieldDescriptor("queries", "Portable queries", "dialogue", "json", ("dialogue",), "Read-only portable domain fact queries."),
)

_KNOWN_FIELDS = frozenset(item.name for item in CONVO_ENGINE_FIELD_DESCRIPTORS)


def known_field_names() -> frozenset[str]:
    """Return the compiler-known set of ConvoEngine family top-level field names."""
    return _KNOWN_FIELDS


def list_field_descriptors(
    *,
    kind: str | None = None,
    category: str | None = None,
    editor_kind: str | None = None,
) -> list[dict[str, Any]]:
    """Return serializable compiler FieldDescriptor records matching optional filters."""
    results: list[dict[str, Any]] = []
    for descriptor in CONVO_ENGINE_FIELD_DESCRIPTORS:
        if kind is not None and kind not in descriptor.kinds:
            continue
        if category is not None and descriptor.category != category:
            continue
        if editor_kind is not None and descriptor.editor_kind != editor_kind:
            continue
        results.append(descriptor.to_dict())
    return results


def describe_unknown_fields(document: Mapping[str, Any] | None) -> dict[str, Any]:
    """Inspect top-level fields not declared in the compiler descriptor table."""
    if not isinstance(document, Mapping):
        return {}
    return {
        key: document[key]
        for key in sorted(str(k) for k in document.keys())
        if key not in _KNOWN_FIELDS
    }


__all__ = [
    "ALL_FAMILY_KINDS",
    "CONVO_ENGINE_FIELD_DESCRIPTORS",
    "FieldDescriptor",
    "describe_unknown_fields",
    "known_field_names",
    "list_field_descriptors",
]
