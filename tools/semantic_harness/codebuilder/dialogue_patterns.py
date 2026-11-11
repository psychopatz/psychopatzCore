"""Compile one reviewed dialogue pattern into canonical match data."""

from __future__ import annotations

import json
import math
import re
from typing import Any

from .lexicon_compiler import CompileError
from .dialogue_contract import (
    DIALOGUE_ID,
    DIALOGUE_PATTERN_SUBJECTS,
    DIALOGUE_BACKSTORY_KINDS,
    DIALOGUE_BACKSTORY_EXTENSIONS,
    DIALOGUE_BACKSTORY_DISCLOSURES,
    DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS,
    DIALOGUE_CONVERSATION_TOPIC_EXTENSIONS,
    DIALOGUE_PROMISE_SUBJECTS,
    DIALOGUE_PROMISE_EXTENSIONS,
    DIALOGUE_MAPPING_FIELDS,
    DIALOGUE_MAPPING_CONCEPTS,
    DIALOGUE_MAPPING_STATES,
    _normalize_dialogue_utterance,
    _validate_source_refs,
    _compile_dialogue_match,
 )

def _compile_dialogue_pattern(
    value: Any,
    source_names: set[str],
) -> tuple[dict[str, Any], list[str]]:
    if not isinstance(value, dict):
        raise CompileError("dialogue patterns must be objects")
    allowed_fields = {
        "id", "utterance", "emit", "confidence", "priority", "negatives",
        "reviewed", "sourceRefs", "mapping", "match", "semanticLabGraph",
    }
    if set(value) - allowed_fields:
        raise CompileError("dialogue pattern contains unsupported fields")
    pattern_id = value.get("id")
    if not isinstance(pattern_id, str) or not DIALOGUE_ID.fullmatch(pattern_id):
        raise CompileError(f"invalid dialogue pattern id: {pattern_id!r}")
    _normalized, tokens = _normalize_dialogue_utterance(value.get("utterance"))
    compiled_match = _compile_dialogue_match(
        value["match"], pattern_id
    ) if "match" in value else [
        {"kind": "literal", "value": token} for token in tokens
    ]

    emit = value.get("emit")
    if not isinstance(emit, dict):
        raise CompileError(f"dialogue pattern {pattern_id} requires an emit object")
    intent = emit.get("intent")
    speech_act = emit.get("speechAct")
    if intent == "QUESTION":
        subject = emit.get("subject")
        if (speech_act != "QUESTION" or not isinstance(subject, str)):
            raise CompileError(
                f"dialogue pattern {pattern_id} must target an existing safe question subject")
        if subject in {"ACTIVITY", "IDENTITY", "WELLBEING", "WEATHER"}:
            if set(emit) != {"intent", "speechAct", "subject"}:
                raise CompileError(
                    f"dialogue question pattern {pattern_id} contains unsupported semantic fields")
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": subject,
            }
        elif subject in {
            "IDENTITY_NICKNAME", "IDENTITY_SURNAME", "IDENTITY_FACTION",
        }:
            social_context = emit.get("socialContext")
            expected_facet = {
                "IDENTITY_NICKNAME": "nickname",
                "IDENTITY_SURNAME": "surname",
                "IDENTITY_FACTION": "faction",
            }[subject]
            if (
                speech_act != "QUESTION"
                or set(emit) != {"intent", "speechAct", "subject", "socialContext"}
                or not isinstance(social_context, dict)
                or social_context.get("directed") is not True
                or social_context.get("identityFacet") != expected_facet
            ):
                raise CompileError(
                    f"dialogue identity facet pattern {pattern_id} requires directed facet metadata")
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": subject,
                "socialContext": {
                    "directed": True,
                    "identityFacet": expected_facet,
                },
            }
        elif subject == "NPC_BACKSTORY":
            slots = emit.get("slots")
            extensions = emit.get("extensions")
            if (set(emit) != {
                    "intent", "speechAct", "subject", "slots", "extensions",
                }
                    or not isinstance(slots, dict)
                    or set(slots) != {"backstoryKind"}
                    or slots.get("backstoryKind") not in DIALOGUE_BACKSTORY_KINDS
                    or not isinstance(extensions, dict)
                    or set(extensions) - DIALOGUE_BACKSTORY_EXTENSIONS
                    or extensions.get("factProvider") != "npc_backstory"
                    or extensions.get("topicID") != (
                        "backstory." + str(slots.get("backstoryKind"))
                    )
                    or extensions.get("disclosure")
                    not in DIALOGUE_BACKSTORY_DISCLOSURES):
                raise CompileError(
                    f"dialogue backstory pattern {pattern_id} requires a typed fact provider, kind, topic, and disclosure"
                )
            if ("dialogueFollowUp" in extensions
                    and extensions["dialogueFollowUp"] != "CONTEXT_REFERENCE"):
                raise CompileError(
                    f"dialogue backstory pattern {pattern_id} has an unsupported follow-up contract"
                )
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "NPC_BACKSTORY",
                "slots": {"backstoryKind": slots["backstoryKind"]},
                "extensions": {
                    key: extensions[key] for key in sorted(extensions)
                },
            }
        elif subject == "CONTEXT_REFERENCE":
            extensions = emit.get("extensions")
            if (set(emit) - {
                    "intent", "speechAct", "subject", "target", "extensions",
                }
                    or not isinstance(extensions, dict)
                    or set(extensions) != DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS
                    or extensions.get("dialogueFollowUp") != "CONTEXT_REFERENCE"
                    or not isinstance(emit.get("target"), str)
                    or not emit["target"].startswith("$capture.")):
                raise CompileError(
                    f"dialogue context-reference pattern {pattern_id} requires a capture target and follow-up metadata"
                )
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "CONTEXT_REFERENCE",
                "target": emit["target"],
                "extensions": {
                    key: extensions[key] for key in sorted(extensions)
                },
            }
        elif subject == "CONVERSATION_TOPIC":
            extensions = emit.get("extensions")
            if (set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                    or not isinstance(extensions, dict)
                    or set(extensions) != DIALOGUE_CONVERSATION_TOPIC_EXTENSIONS
                    or extensions.get("topic") != "whats_up"
                    or extensions.get("hubID") != "whats_up"
                    or extensions.get("route") != "semantic_hub"):
                raise CompileError(
                    f"dialogue conversation-topic pattern {pattern_id} requires the reviewed whats_up semantic-hub route"
                )
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "CONVERSATION_TOPIC",
                "extensions": {
                    key: extensions[key]
                    for key in sorted(extensions)
                },
            }
        elif subject == "QUANTITY":
            extensions = emit.get("extensions")
            if (set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                    or not isinstance(extensions, dict)
                    or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                    or extensions.get("topic") != "NEEDS"
                    or extensions.get("dialogueFollowUp") != "NEEDS_QUANTITY"):
                raise CompileError(
                    f"dialogue quantity clarification pattern {pattern_id} must target the existing needs flow")
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "QUANTITY",
                "extensions": {
                    "topic": "NEEDS",
                    "dialogueFollowUp": "NEEDS_QUANTITY",
                },
            }
        else:
            raise CompileError(
                f"dialogue pattern {pattern_id} must target an existing safe question subject")
    elif intent == "GREET":
        if speech_act != "GREET" or set(emit) != {"intent", "speechAct"}:
            raise CompileError(
                f"dialogue greeting pattern {pattern_id} has an unsupported emit")
        normalized_emit = {"intent": "GREET", "speechAct": "GREET"}
    elif intent == "CLARIFY":
        extensions = emit.get("extensions")
        if (speech_act != "CLARIFY"
                or emit.get("subject") != "NEEDS"
                or set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                or not isinstance(extensions, dict)
                or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                or extensions.get("topic") != "NEEDS"
                or extensions.get("dialogueFollowUp") != "NEEDS_QUANTITY"):
            raise CompileError(
                f"dialogue clarification pattern {pattern_id} must target the existing needs flow")
        normalized_emit = {
            "intent": "CLARIFY",
            "speechAct": "CLARIFY",
            "subject": "NEEDS",
            "extensions": {
                "topic": "NEEDS",
                "dialogueFollowUp": "NEEDS_QUANTITY",
            },
        }
    elif intent == "PROMISE":
        extensions = emit.get("extensions")
        if (speech_act != "PROMISE"
                or emit.get("subject") not in DIALOGUE_PROMISE_SUBJECTS
                or set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                or not isinstance(extensions, dict)
                or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                or extensions.get("topic") != "NEEDS"
                or extensions.get("dialogueFollowUp") != "NEEDS_PROPOSAL"):
            raise CompileError(
                f"dialogue promise pattern {pattern_id} must target the existing needs proposal flow")
        normalized_emit = {
            "intent": "PROMISE",
            "speechAct": "PROMISE",
            "subject": "NEEDS",
            "extensions": {
                "topic": "NEEDS",
                "dialogueFollowUp": "NEEDS_PROPOSAL",
            },
        }
    else:
        raise CompileError(
            f"dialogue pattern {pattern_id} targets an unsupported interaction")

    reviewed = value.get("reviewed", False)
    if not isinstance(reviewed, bool):
        raise CompileError(f"dialogue pattern {pattern_id} reviewed must be boolean")
    source_refs = []
    if "sourceRefs" in value:
        source_refs = _validate_source_refs(
            value["sourceRefs"], source_names,
            f"dialogue pattern {pattern_id} sourceRefs",
        )
    mapping = value.get("mapping")
    normalized_mapping = None
    if mapping is not None:
        if not isinstance(mapping, dict) or set(mapping) - DIALOGUE_MAPPING_FIELDS:
            raise CompileError(f"dialogue pattern {pattern_id} has invalid mapping")
        concept = mapping.get("canonicalConcept")
        state = mapping.get("dialogueState")
        mapping_refs = _validate_source_refs(
            mapping.get("sourceRefs"), source_names,
            f"dialogue pattern {pattern_id} mapping sourceRefs",
        )
        if concept not in DIALOGUE_MAPPING_CONCEPTS:
            raise CompileError(
                f"dialogue pattern {pattern_id} maps to an unsupported canonical concept")
        if state not in DIALOGUE_MAPPING_STATES:
            raise CompileError(
                f"dialogue pattern {pattern_id} maps to an unsupported dialogue state")
        if source_refs and mapping_refs != source_refs:
            raise CompileError(
                f"dialogue pattern {pattern_id} mapping/sourceRefs disagree")
        source_refs = mapping_refs
        normalized_mapping = {
            "canonicalConcept": concept,
            "dialogueState": state,
            "sourceRefs": mapping_refs,
        }
    if ((intent in {"PROMISE", "CLARIFY"} or normalized_mapping is not None)
            and (not reviewed or not source_refs or not normalized_mapping)):
        raise CompileError(
            f"dialogue promise pattern {pattern_id} requires reviewed canonical mapping metadata")

    negatives = value.get("negatives", [])
    if not isinstance(negatives, list) or len(negatives) > 8:
        raise CompileError(f"dialogue pattern {pattern_id} negatives must be bounded")
    normalized_negatives = []
    for negative in negatives:
        normalized_negative, _negative_tokens = _normalize_dialogue_utterance(negative)
        if normalized_negative == _normalized:
            raise CompileError(
                f"dialogue pattern {pattern_id} has a positive/negative collision")
        if normalized_negative not in normalized_negatives:
            normalized_negatives.append(normalized_negative)

    confidence = value.get("confidence", 0.98)
    if (isinstance(confidence, bool)
        or not isinstance(confidence, (int, float))
        or not math.isfinite(confidence)
        or confidence < 0.95 or confidence > 1.0):
        raise CompileError(
            f"dialogue pattern {pattern_id} requires confidence between 0.95 and 1.0")
    priority = value.get("priority", 100)
    if isinstance(priority, bool) or not isinstance(priority, int) or not 0 <= priority <= 255:
        raise CompileError(
            f"dialogue pattern {pattern_id} priority must be an integer from 0 to 255")

    compiled = {
        "id": pattern_id,
        "match": compiled_match,
        "emit": normalized_emit,
        "confidence": float(confidence),
        "priority": priority,
    }
    if reviewed:
        compiled["metadata"] = {
            "reviewed": True,
            "sourceRefs": source_refs,
        }
    if normalized_mapping is not None:
        compiled.setdefault("metadata", {})["mapping"] = normalized_mapping
    graph_metadata = value.get("semanticLabGraph")
    if graph_metadata is not None:
        if not isinstance(graph_metadata, dict):
            raise CompileError(
                f"dialogue pattern {pattern_id} semanticLabGraph must be an object"
            )
        try:
            encoded_graph = json.dumps(
                graph_metadata,
                ensure_ascii=False,
                sort_keys=True,
            )
        except (TypeError, ValueError) as error:
            raise CompileError(
                f"dialogue pattern {pattern_id} semanticLabGraph must be JSON-serializable"
            ) from error
        if len(encoded_graph) > 16_384:
            raise CompileError(
                f"dialogue pattern {pattern_id} semanticLabGraph exceeds the metadata size bound"
            )
        compiled.setdefault("metadata", {})["semanticLabGraph"] = json.loads(
            encoded_graph
        )
    return compiled, normalized_negatives
