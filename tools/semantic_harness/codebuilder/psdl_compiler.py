"""Core-owned PSDL parser, normalizer and deterministic runtime plan compiler.

PSDL records are authoring input only.  This module produces the canonical
Semantic Dialogue IR and a bounded plan for the already accepted response,
behavior, beat and realization authorities; it does not introduce a second
dialogue runtime.
"""

from __future__ import annotations

import copy
import json
import re
from collections import Counter
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .conversation_contract import CONVERSATION_SHARD_SCHEMA
from .conversation_model import fingerprint
from .conversation_validation import _validate_behavior_shard, _validate_beat_shard
from .conversation_ui_contract import validate_ui_shard
from .errors import CompileError
from .generation_ownership import (
    OwnerConfigurationError,
    conversation_prefix,
    normalize_owner,
    package_descriptor,
)
from .rule_contract import normalize_predicate
from .semantic_pack_compiler import compile_semantic_pack_shard
from .convo_engine_exchange import (
    EXCHANGE_FAMILY_FIELDS,
    collect_disallowed_realization_targets,
    collect_semantic_references,
    normalize_exchange_family_payload,
    project_exchange_family_runtime,
    resolve_family_identity,
    validate_semantic_reference,
)
from .portable_runtime import (
    PORTABLE_PLAN_SCHEMA,
    portable_plan_records,
)
from .psdl_compact import (
    COMPACT_PSDL_SCHEMA,
    expand_compact_psdl_document,
)
from .semantic_dialogue_ir import (
    CANONICAL_IR_SCHEMA,
    CONVO_ENGINE_SCHEMA,
    LEGACY_PSDL_SCHEMA,
    PSDL_SCHEMA,
    REFERENCE_TYPES,
    SLOT_TYPES,
    SUPPORTED_SOURCE_SCHEMAS,
    canonicalize_dialogue,
    validate_context_path,
)
from .translation_support import DEFAULT_LANGUAGE, normalize_language


PSDL_COMPILED_SCHEMA = "psychopatz.semantic.dialogue-compiled.v1"
CONVO_ENGINE_COMPILED_SCHEMA = PSDL_COMPILED_SCHEMA
PSDL_KINDS = frozenset({"dialogue", "behavior", "beat", "realization"})
PSDL_DOCUMENT_FIELDS = frozenset({"schema", "records", "owner", "metadata"})
PSDL_RECORD_FIELDS = frozenset({
    "schema", "_authoringSchema", "kind", "namespace", "id", "version", "owner", "participants", "target", "slots",
    "references", "when", "constraints", "on", "respond", "response",
    "variants", "turns", "offers", "transitions", "bindings", "text",
    "label", "utterance", "stimuli", "act", "action", "mode", "requiredCapabilities",
    "outputs", "modifiers", "continuation", "baseRelevance",
    "entry", "maintain", "exit", "candidates", "group", "cooldownTurns",
    "maxTurns", "effects", "policy", "metadata", "style", "resolver",
    "recognition",
    "type", "strategy", "dialogueAct", "concept", "forms", "translations", "aliases",
}) | (EXCHANGE_FAMILY_FIELDS - {"namespace"})
TRANSITION_KINDS = frozenset({
    "continue", "await_participant", "terminate", "resume_previous",
    "enter_flow", "exit_flow",
})
CONSUMERS = frozenset({"participant", "player", "npc"})
MAX_RECORDS = 512
MAX_TURNS = 4
MAX_VARIANTS = 32
MAX_OFFERS = 8
MAX_BINDINGS = 32
MAX_LOCALES = 32
MAX_TEXT_VARIANTS = 16
MAX_LIST_ITEMS = 32
MAX_RECOGNITION_RECORDS = 256
_ID = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_NAME = re.compile(r"^[a-z][a-z0-9_]{0,31}$")
_BINDING_NAME = re.compile(r"^[a-z][a-zA-Z0-9_.]*(?<!\.)$")
_RESOLVER = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_PLACEHOLDER = re.compile(r"\{([a-z][a-zA-Z0-9_.]*)\}")
_FORBIDDEN_ID_PARTS = frozenset({
    "generated", "legacy", "compat", "old", "v1", "automatic_flow",
    "parameterized_task", "part02", "part03", "part04", "part05",
})


def _copy(value: Any) -> Any:
    return copy.deepcopy(value)


def _id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _ID.fullmatch(value):
        raise CompileError(f"{label} must be a bounded lowercase semantic ID")
    parts = set(re.split(r"[.:_-]+", value))
    if parts & _FORBIDDEN_ID_PARTS:
        raise CompileError(
            f"{label} contains a forbidden migration/implementation identity: {value!r}"
        )
    return value


def _bounded_list(value: Any, label: str, maximum: int) -> list[Any]:
    if not isinstance(value, list) or len(value) > maximum:
        raise CompileError(f"{label} must contain at most {maximum} items")
    return value


def _normalize_locale_text(
    value: Any,
    label: str,
    *,
    bindings: Mapping[str, Any],
) -> dict[str, list[str]]:
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} requires a locale text map")
    if len(value) > MAX_LOCALES:
        raise CompileError(f"{label} contains too many locales")
    output: dict[str, list[str]] = {}
    placeholder_sets: dict[str, Counter[str]] = {}
    for raw_language, raw_values in value.items():
        language = normalize_language(raw_language, f"{label} locale")
        if language in output:
            raise CompileError(f"{label} repeats locale {language}")
        values = [raw_values] if isinstance(raw_values, str) else raw_values
        if not isinstance(values, list) or not values or len(values) > MAX_TEXT_VARIANTS:
            raise CompileError(
                f"{label}.{language} must contain 1..{MAX_TEXT_VARIANTS} strings"
            )
        normalized: list[str] = []
        placeholders: Counter[str] = Counter()
        for index, raw_text in enumerate(values):
            if not isinstance(raw_text, str) or not raw_text.strip():
                raise CompileError(f"{label}.{language}[{index}] must be non-empty text")
            text = raw_text.strip()
            if len(text) > 256 or any(ord(char) < 32 for char in text):
                raise CompileError(f"{label}.{language}[{index}] is unbounded or contains control text")
            matches = _PLACEHOLDER.findall(text)
            if text.count("{") != len(matches) or text.count("}") != len(matches):
                raise CompileError(f"{label}.{language}[{index}] contains malformed placeholders")
            placeholders.update(matches)
            normalized.append(text)
        output[language] = normalized
        placeholder_sets[language] = placeholders
    if DEFAULT_LANGUAGE not in output:
        raise CompileError(f"{label} requires {DEFAULT_LANGUAGE} fallback text")
    expected = placeholder_sets[DEFAULT_LANGUAGE]
    for language, placeholders in placeholder_sets.items():
        if placeholders != expected:
            raise CompileError(
                f"{label}.{language} placeholder set differs from {DEFAULT_LANGUAGE}"
            )
    for placeholder in sorted(expected):
        if placeholder in bindings:
            continue
        validate_context_path(placeholder, f"{label} placeholder")
    return {language: output[language] for language in sorted(output)}


def _normalize_bindings(value: Any, label: str = "bindings") -> dict[str, dict[str, Any]]:
    if value is None:
        return {}
    if not isinstance(value, Mapping) or len(value) > MAX_BINDINGS:
        raise CompileError(f"{label} must contain at most {MAX_BINDINGS} bindings")
    output: dict[str, dict[str, Any]] = {}
    for name in sorted(value, key=lambda item: str(item)):
        if (
            not isinstance(name, str)
            or len(name) > 64
            or ".." in name
            or not _BINDING_NAME.fullmatch(name)
        ):
            raise CompileError(f"{label} contains an invalid binding name {name!r}")
        for segment in name.split("."):
            if segment.lower() in {"private", "secret", "undiscovered", "lua", "callback", "java"}:
                raise CompileError(f"{label} contains forbidden binding segment in {name!r}")
        raw = value[name]
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label}.{name} must be a typed resolver object")
        if set(raw) - {"resolver", "from", "type", "public"}:
            raise CompileError(f"{label}.{name} contains unsupported resolver fields")
        resolver = raw.get("resolver")
        source = raw.get("from")
        if not isinstance(resolver, str) or not _RESOLVER.fullmatch(resolver):
            raise CompileError(f"{label}.{name}.resolver must be a registered resolver ID")
        validate_context_path(source, f"{label}.{name}.from")
        type_name = raw.get("type")
        if type_name is not None and type_name not in (SLOT_TYPES | REFERENCE_TYPES):
            raise CompileError(f"{label}.{name}.type is unsupported: {type_name!r}")
        if raw.get("public", True) is not True:
            raise CompileError(f"{label}.{name} cannot expose a private binding")
        output[name] = {
            "resolver": resolver,
            "from": source,
            **({"type": type_name} if type_name is not None else {}),
        }
    return output


def _normalize_predicate(value: Any, label: str) -> Any:
    normalized = normalize_predicate(value, label, max_depth=6, max_items=16)
    if normalized is None:
        return None

    def visit(node: Any, node_label: str) -> None:
        if "all" in node or "any" in node:
            key = "all" if "all" in node else "any"
            for index, child in enumerate(node[key]):
                visit(child, f"{node_label}.{key}[{index}]")
            return
        if "not" in node:
            visit(node["not"], f"{node_label}.not")
            return
        validate_context_path(node.get("path", node.get("field")), f"{node_label}.path")

    visit(normalized, label)
    return normalized


def _normalize_transition(value: Any, label: str) -> Any:
    values = [value] if isinstance(value, str) else value
    if not isinstance(values, list) or not values or len(values) > MAX_LIST_ITEMS:
        raise CompileError(f"{label} must contain 1..{MAX_LIST_ITEMS} transitions")
    output = []
    for item in values:
        if isinstance(item, str):
            transition = item
        elif isinstance(item, Mapping) and isinstance(item.get("type"), str):
            transition = item.get("type")
        else:
            raise CompileError(f"{label} contains an invalid transition")
        if transition not in TRANSITION_KINDS:
            raise CompileError(f"{label} contains unsupported transition {transition!r}")
        output.append(transition)
    return output[0] if isinstance(value, str) else output


def _normalize_offer(
    value: Any,
    label: str,
    *,
    bindings: Mapping[str, Any],
) -> dict[str, Any]:
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be an offer object")
    allowed = {"id", "when", "label", "utterance", "frame", "consumers", "transition", "metadata"}
    if set(value) - allowed:
        raise CompileError(f"{label} contains unsupported offer fields")
    offer_id = _id(value.get("id"), f"{label}.id")
    if not isinstance(value.get("frame"), Mapping):
        raise CompileError(f"{label}.frame is required and must be a semantic frame")
    consumers = value.get("consumers", ["participant"])
    if not isinstance(consumers, list) or not consumers or len(consumers) > 3:
        raise CompileError(f"{label}.consumers must contain 1..3 consumers")
    if any(item not in CONSUMERS for item in consumers) or len(set(consumers)) != len(consumers):
        raise CompileError(f"{label}.consumers contains an unsupported or duplicate consumer")
    output: dict[str, Any] = {
        "id": offer_id,
        "frame": _copy(value["frame"]),
        "consumers": list(consumers),
    }
    if "when" in value:
        output["when"] = _normalize_predicate(value["when"], f"{label}.when")
    for field in ("label", "utterance"):
        if field in value:
            output[field] = _normalize_locale_text(
                value[field], f"{label}.{field}", bindings=bindings
            )
    if "transition" in value:
        output["transition"] = _normalize_transition(value["transition"], f"{label}.transition")
    if "metadata" in value:
        if not isinstance(value["metadata"], Mapping):
            raise CompileError(f"{label}.metadata must be an object")
        output["metadata"] = _copy(value["metadata"])
    return output


def _normalize_turn(
    value: Any,
    label: str,
    *,
    bindings: Mapping[str, Any],
) -> dict[str, Any]:
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be a turn object")
    allowed = {"id", "when", "text", "offers", "transition", "metadata"}
    if set(value) - allowed:
        raise CompileError(f"{label} contains unsupported turn fields")
    output = {"id": _id(value.get("id"), f"{label}.id")}
    if "when" in value:
        output["when"] = _normalize_predicate(value["when"], f"{label}.when")
    if "text" not in value:
        raise CompileError(f"{label}.text is required")
    output["text"] = _normalize_locale_text(value["text"], f"{label}.text", bindings=bindings)
    if "offers" in value:
        offers = _bounded_list(value["offers"], f"{label}.offers", MAX_OFFERS)
        output["offers"] = [
            _normalize_offer(item, f"{label}.offers[{index}]", bindings=bindings)
            for index, item in enumerate(offers)
        ]
    if "transition" in value:
        output["transition"] = _normalize_transition(value["transition"], f"{label}.transition")
    if "metadata" in value:
        if not isinstance(value["metadata"], Mapping):
            raise CompileError(f"{label}.metadata must be an object")
        output["metadata"] = _copy(value["metadata"])
    return output


def _normalize_variants(
    value: Any,
    label: str,
    *,
    bindings: Mapping[str, Any],
) -> list[dict[str, Any]]:
    variants = _bounded_list(value, label, MAX_VARIANTS)
    output = []
    seen: set[str] = set()
    for index, raw in enumerate(variants):
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label}[{index}] must be an object")
        variant_id = _id(raw.get("id"), f"{label}[{index}].id")
        if variant_id in seen:
            raise CompileError(f"{label} repeats variant {variant_id}")
        seen.add(variant_id)
        allowed = {"id", "when", "text", "turns", "offers", "transition", "metadata"}
        if set(raw) - allowed:
            raise CompileError(f"{label}[{index}] contains unsupported fields")
        item: dict[str, Any] = {"id": variant_id}
        if "when" in raw:
            item["when"] = _normalize_predicate(raw["when"], f"{label}[{index}].when")
        if "text" in raw:
            item["text"] = _normalize_locale_text(raw["text"], f"{label}[{index}].text", bindings=bindings)
        if "turns" in raw:
            turns = _bounded_list(raw["turns"], f"{label}[{index}].turns", MAX_TURNS)
            item["turns"] = [
                _normalize_turn(turn, f"{label}[{index}].turns[{turn_index}]", bindings=bindings)
                for turn_index, turn in enumerate(turns)
            ]
        if "offers" in raw:
            offers = _bounded_list(raw["offers"], f"{label}[{index}].offers", MAX_OFFERS)
            item["offers"] = [
                _normalize_offer(offer, f"{label}[{index}].offers[{offer_index}]", bindings=bindings)
                for offer_index, offer in enumerate(offers)
            ]
        if not any(key in item for key in ("text", "turns", "offers")):
            raise CompileError(f"{label}[{index}] requires text, turns or offers")
        if "transition" in raw:
            item["transition"] = _normalize_transition(raw["transition"], f"{label}[{index}].transition")
        if "metadata" in raw:
            if not isinstance(raw["metadata"], Mapping):
                raise CompileError(f"{label}[{index}].metadata must be an object")
            item["metadata"] = _copy(raw["metadata"])
        output.append(item)
    return output


def _normalize_response(value: Any, label: str, *, bindings: Mapping[str, Any]) -> dict[str, Any]:
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be a response object")
    allowed = {"act", "text", "turns", "variants", "offers", "transition", "metadata"}
    if set(value) - allowed:
        raise CompileError(f"{label} contains unsupported response fields")
    output: dict[str, Any] = {}
    if "act" in value:
        if not isinstance(value["act"], str) or not value["act"].strip():
            raise CompileError(f"{label}.act must be a semantic act")
        output["act"] = value["act"].strip()
    if "text" in value:
        output["text"] = _normalize_locale_text(value["text"], f"{label}.text", bindings=bindings)
    if "turns" in value:
        turns = _bounded_list(value["turns"], f"{label}.turns", MAX_TURNS)
        output["turns"] = [
            _normalize_turn(turn, f"{label}.turns[{index}]", bindings=bindings)
            for index, turn in enumerate(turns)
        ]
    if "variants" in value:
        output["variants"] = _normalize_variants(value["variants"], f"{label}.variants", bindings=bindings)
    if "offers" in value:
        offers = _bounded_list(value["offers"], f"{label}.offers", MAX_OFFERS)
        output["offers"] = [
            _normalize_offer(offer, f"{label}.offers[{index}]", bindings=bindings)
            for index, offer in enumerate(offers)
        ]
    if "transition" in value:
        output["transition"] = _normalize_transition(value["transition"], f"{label}.transition")
    if "metadata" in value:
        if not isinstance(value["metadata"], Mapping):
            raise CompileError(f"{label}.metadata must be an object")
        output["metadata"] = _copy(value["metadata"])
    if not any(key in output for key in ("text", "turns", "variants", "offers")):
        raise CompileError(f"{label} requires text, turns, variants or offers")
    return output


def _normalize_recognition(value: Any, label: str) -> dict[str, Any]:
    """Normalize semantic recognition data before projecting the Core pack contract."""
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be a semantic recognition object")
    allowed = {
        "packID", "ownerModID", "version", "concepts", "speechActs",
        "patterns", "actionProviders", "dialogueBlocks",
    }
    unsupported = set(value) - allowed
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported fields: "
            + ", ".join(sorted(str(item) for item in unsupported))
        )
    pack_id = value.get("packID")
    if not isinstance(pack_id, str) or not pack_id.strip():
        raise CompileError(f"{label}.packID must be a semantic-pack ID")
    version = value.get("version", 1)
    if isinstance(version, bool) or not isinstance(version, int) or version < 1:
        raise CompileError(f"{label}.version must be a positive integer")
    output: dict[str, Any] = {"packID": pack_id.strip(), "version": version}
    if "ownerModID" in value:
        owner_mod_id = value["ownerModID"]
        if not isinstance(owner_mod_id, str) or not owner_mod_id.strip():
            raise CompileError(f"{label}.ownerModID must be a non-empty string")
        output["ownerModID"] = owner_mod_id.strip()
    for field in ("concepts", "speechActs", "patterns", "actionProviders", "dialogueBlocks"):
        if field not in value:
            continue
        item = value[field]
        if not isinstance(item, (list, dict)):
            raise CompileError(f"{label}.{field} must be a list or object")
        if isinstance(item, list) and len(item) > MAX_RECOGNITION_RECORDS:
            raise CompileError(
                f"{label}.{field} must contain at most {MAX_RECOGNITION_RECORDS} items"
            )
        output[field] = _copy(item)
    for field in ("concepts", "speechActs", "patterns"):
        output.setdefault(field, [])
    return output


def _normalize_module_payload(
    kind: str,
    payload: dict[str, Any],
    *,
    label: str,
    slots: Mapping[str, Any] | None = None,
    source_schema: str = LEGACY_PSDL_SCHEMA,
    has_namespace: bool = False,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    bindings = _normalize_bindings(payload.get("bindings"), f"{label}.bindings")
    if bindings:
        payload["bindings"] = bindings
    else:
        payload.pop("bindings", None)
    if "recognition" in payload:
        payload["recognition"] = _normalize_recognition(
            payload["recognition"], f"{label}.recognition"
        )

    exchange_keys = EXCHANGE_FAMILY_FIELDS - {"namespace"}
    uses_exchange_syntax = has_namespace or any(key in payload for key in exchange_keys)
    if uses_exchange_syntax and source_schema != CONVO_ENGINE_SCHEMA:
        raise CompileError(
            f"{label} uses compact exchange-family syntax and must declare schema {CONVO_ENGINE_SCHEMA}"
        )
    if kind != "dialogue" and any(key in payload for key in exchange_keys):
        raise CompileError(
            f"{label} compact exchange-family fields are supported only for kind 'dialogue'"
        )

    if "on" in payload:
        if not isinstance(payload["on"], Mapping):
            raise CompileError(f"{label}.on must be a semantic trigger object")
        allowed_on = {"intent", "speechAct", "subject", "action", "recognition", "confidence"}
        if set(payload["on"]) - allowed_on:
            raise CompileError(f"{label}.on contains unsupported trigger fields")
        for field, value in payload["on"].items():
            if field != "confidence" and (not isinstance(value, str) or not value.strip()):
                raise CompileError(f"{label}.on.{field} must be a semantic token")
        if "confidence" in payload["on"]:
            confidence = payload["on"]["confidence"]
            if not isinstance(confidence, (int, float)) or not 0 <= confidence <= 1:
                raise CompileError(f"{label}.on.confidence must be between 0 and 1")

    for field in ("entry", "maintain", "exit"):
        if field in payload:
            payload[field] = _normalize_predicate(payload[field], f"{label}.{field}")
    if "transitions" in payload:
        payload["transitions"] = _normalize_transition(payload["transitions"], f"{label}.transitions")
    if "respond" in payload:
        payload["respond"] = _normalize_locale_text(payload["respond"], f"{label}.respond", bindings=bindings)
    if "response" in payload:
        payload["response"] = _normalize_response(payload["response"], f"{label}.response", bindings=bindings)
    if "variants" in payload:
        payload["variants"] = _normalize_variants(payload["variants"], f"{label}.variants", bindings=bindings)
    if "turns" in payload:
        turns = _bounded_list(payload["turns"], f"{label}.turns", MAX_TURNS)
        payload["turns"] = [
            _normalize_turn(turn, f"{label}.turns[{index}]", bindings=bindings)
            for index, turn in enumerate(turns)
        ]
    if "offers" in payload:
        offers = _bounded_list(payload["offers"], f"{label}.offers", MAX_OFFERS)
        payload["offers"] = [
            _normalize_offer(offer, f"{label}.offers[{index}]", bindings=bindings)
            for index, offer in enumerate(offers)
        ]
    for field in ("text", "label", "utterance"):
        if field in payload:
            payload[field] = _normalize_locale_text(payload[field], f"{label}.{field}", bindings=bindings)
    if kind == "beat":
        if any(field in payload for field in ("text", "label", "utterance", "respond", "response")):
            raise CompileError(f"{label} beats reference behaviors and do not own wording")
        candidates = payload.get("candidates")
        if candidates is None:
            raise CompileError(f"{label}.candidates is required for a beat")
        if candidates is not None:
            candidates = _bounded_list(candidates, f"{label}.candidates", MAX_LIST_ITEMS)
            normalized_candidates = []
            for index, candidate in enumerate(candidates):
                if not isinstance(candidate, Mapping) or not isinstance(candidate.get("behavior"), str):
                    raise CompileError(f"{label}.candidates[{index}] requires a behavior reference")
                item = {"behavior": candidate["behavior"]}
                if "relevance" in candidate:
                    relevance = candidate["relevance"]
                    if not isinstance(relevance, (int, float)) or not 0 <= relevance <= 1:
                        raise CompileError(f"{label}.candidates[{index}].relevance must be between 0 and 1")
                    item["relevance"] = relevance
                normalized_candidates.append(item)
            payload["candidates"] = normalized_candidates
            if not normalized_candidates:
                raise CompileError(f"{label}.candidates must contain at least one behavior")
    if kind == "dialogue":
        if any(key in payload for key in ("invoke", "affordance", "execute", "say", "reply", "after")):
            normalize_exchange_family_payload(
                payload,
                label=label,
                slots=slots or {},
                bindings=bindings,
                normalize_locale_text=_normalize_locale_text,
                normalize_predicate=_normalize_predicate,
                normalize_transition=_normalize_transition,
                normalize_turn=_normalize_turn,
                consumers=CONSUMERS,
                action_contracts=action_contracts,
            )
    if kind == "dialogue" and not any(
        field in payload for field in ("respond", "response", "variants", "turns", "text", "offers", "say", "reply", "recognition")
    ):
        raise CompileError(f"{label} requires a say, reply, response, turns, variants, offers, recognition or text")
    if kind == "behavior" and not any(
        field in payload for field in ("act",)
    ):
        raise CompileError(f"{label}.act is required for a behavior")
    if kind == "realization":
        realization_type = payload.get("type")
        if realization_type is None:
            if not any(field in payload for field in ("text", "variants")):
                raise CompileError(f"{label} requires text or variants")
        elif realization_type == "lexeme":
            concept = payload.get("concept")
            forms = payload.get("forms")
            if not isinstance(concept, str) or not concept.strip():
                raise CompileError(f"{label}.concept is required for a lexeme")
            if not isinstance(forms, Mapping) or not forms:
                raise CompileError(f"{label}.forms is required for a lexeme")
            if len(forms) > 8:
                raise CompileError(f"{label}.forms contains too many locales")
            if any(
                not isinstance(locale, str)
                or not locale.strip()
                or not isinstance(value, str)
                or not value.strip()
                for locale, value in forms.items()
            ):
                raise CompileError(f"{label}.forms must map locales to bounded text")
            aliases = payload.get("aliases")
            if aliases is not None:
                if not isinstance(aliases, list) or len(aliases) > MAX_LIST_ITEMS:
                    raise CompileError(f"{label}.aliases must be a bounded list")
                if any(not isinstance(item, str) or not item.strip() for item in aliases):
                    raise CompileError(f"{label}.aliases must contain text strings")
        elif realization_type == "construction":
            strategy = payload.get("strategy")
            translations = payload.get("translations")
            if not isinstance(strategy, str) or not strategy.strip():
                raise CompileError(f"{label}.strategy is required for a construction")
            if not isinstance(translations, Mapping) or not translations:
                raise CompileError(f"{label}.translations is required for a construction")
            if "EN" not in {str(locale).upper() for locale in translations}:
                raise CompileError(f"{label}.translations requires EN fallback")
            for locale, tokens in translations.items():
                if not isinstance(locale, str) or not locale.strip():
                    raise CompileError(f"{label}.translations has an invalid locale")
                if not isinstance(tokens, list) or not tokens or len(tokens) > 12:
                    raise CompileError(f"{label}.translations[{locale}] requires 1-12 tokens")
                for index, token in enumerate(tokens):
                    if not isinstance(token, Mapping):
                        raise CompileError(f"{label}.translations[{locale}][{index}] must be an object")
                    token_kind = token.get("kind")
                    if token_kind not in {"literal", "lexeme", "slot"}:
                        raise CompileError(f"{label}.translations[{locale}][{index}].kind is unsupported")
                    if token_kind == "literal":
                        if not isinstance(token.get("value"), str) or len(token["value"]) > 128:
                            raise CompileError(f"{label}.translations[{locale}][{index}].value is invalid")
                    elif not isinstance(token.get("slot"), str) or not token["slot"].strip():
                        raise CompileError(f"{label}.translations[{locale}][{index}].slot is required")
        else:
            raise CompileError(f"{label}.type must be lexeme or construction")
    for field in ("stimuli",):
        if field in payload:
            values = _bounded_list(payload[field], f"{label}.{field}", MAX_LIST_ITEMS)
            if any(not isinstance(item, str) or not item.strip() for item in values):
                raise CompileError(f"{label}.{field} must contain semantic token strings")
            payload[field] = list(values)
    if "respondWith" in payload and not isinstance(payload["respondWith"], str):
        raise CompileError(f"{label}.respondWith must be a behavior/response identity")
    for field in ("cooldownTurns", "maxTurns"):
        if field in payload:
            value = payload[field]
            if not isinstance(value, int) or isinstance(value, bool) or value < 0 or value > 256:
                raise CompileError(f"{label}.{field} must be a bounded non-negative integer")
    if "baseRelevance" in payload:
        value = payload["baseRelevance"]
        if not isinstance(value, (int, float)) or not 0 <= value <= 1:
            raise CompileError(f"{label}.baseRelevance must be between 0 and 1")
    return payload


def _director_record_projection(record: Mapping[str, Any]) -> dict[str, Any]:
    """Validate and normalize one record for the existing director registry."""
    kind = str(record.get("kind") or "")
    if kind not in {"behavior", "beat"}:
        raise CompileError(f"{record.get('id', 'record')} is not a director record")
    payload = _copy(record.get("payload") or {})
    if not isinstance(payload, dict):
        raise CompileError(f"{record['id']}.payload must be an object")
    payload["id"] = record["id"]
    payload["owner"] = record["owner"]
    payload.setdefault("version", 1)
    if record.get("when") is not None:
        payload["when"] = _copy(record["when"])

    if kind == "behavior":
        unsupported = set(payload) - {
            "id", "version", "owner", "act", "mode", "stimuli",
            "requiredCapabilities", "outputs", "continuation", "when",
            "baseRelevance", "modifiers",
        }
        if unsupported:
            raise CompileError(
                f"{record['id']} contains fields outside the Interaction Director behavior contract: "
                + ", ".join(sorted(unsupported))
            )
        return _validate_behavior_shard(
            {"behaviors": [payload]},
            f"PSDL {record['id']}",
            default_owner=record["owner"],
        )["records"][0]

    unsupported = set(payload) - {
        "id", "version", "owner", "group", "baseRelevance", "entry",
        "maintain", "exit", "candidates", "cooldownTurns", "maxTurns",
        "stimuli",
    }
    if unsupported:
        raise CompileError(
            f"{record['id']} contains fields outside the Interaction Director beat contract: "
            + ", ".join(sorted(unsupported))
        )
    return _validate_beat_shard(
        {"beats": [payload]},
        f"PSDL {record['id']}",
        default_owner=record["owner"],
    )["records"][0]


def _normalize_record(
    raw: Mapping[str, Any],
    *,
    source_path: str | None,
    default_owner: Any = None,
    document_schema: str = LEGACY_PSDL_SCHEMA,
    allow_legacy_schema: bool = True,
    allow_custom_owner: bool = False,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    if not isinstance(raw, Mapping):
        raise CompileError("ConvoEngine record must be an object")
    unsupported = set(raw) - PSDL_RECORD_FIELDS
    if unsupported:
        raise CompileError(
            "ConvoEngine record contains unsupported fields: "
            + ", ".join(sorted((str(item) for item in unsupported)))
        )
    record = _copy(dict(raw))
    if "schema" not in record:
        record["schema"] = document_schema
    record_schema = record["schema"]
    if record_schema not in SUPPORTED_SOURCE_SCHEMAS:
        raise CompileError(
            f"ConvoEngine record.schema must be {CONVO_ENGINE_SCHEMA} (or migration {LEGACY_PSDL_SCHEMA})"
        )
    if not allow_legacy_schema and record_schema == LEGACY_PSDL_SCHEMA:
        raise CompileError(
            f"Legacy schema {LEGACY_PSDL_SCHEMA} is read-only migration compatibility; use {CONVO_ENGINE_SCHEMA}"
        )
    if "owner" not in record and default_owner is not None:
        record["owner"] = default_owner
    record_id, namespace, _local_id = resolve_family_identity(
        record.get("namespace"),
        record.get("id"),
        strict_convo_engine=(record_schema == CONVO_ENGINE_SCHEMA),
        label="ConvoEngine record",
    )
    try:
        record["owner"] = normalize_owner(record.get("owner"))
        package_descriptor(record["owner"])
    except OwnerConfigurationError as error:
        raw_owner = record.get("owner")
        if allow_custom_owner and isinstance(raw_owner, str) and raw_owner.strip():
            record["owner"] = raw_owner.strip()
        else:
            raise CompileError(str(error)) from error
    if "when" in record and "constraints" in record:
        raise CompileError(f"{record_id} cannot define both when and constraints")
    canonical = canonicalize_dialogue(record, source_path=source_path)
    canonical["payload"] = _normalize_module_payload(
        canonical["kind"],
        canonical["payload"],
        label=record_id,
        slots=canonical["slots"],
        source_schema=record_schema,
        has_namespace=(namespace is not None),
        action_contracts=action_contracts,
    )
    canonical["owner"] = record["owner"]
    if canonical["kind"] in {"behavior", "beat"}:
        director_record = _director_record_projection(canonical)
        canonical["payload"] = {
            key: _copy(value)
            for key, value in director_record.items()
            if key not in {"id", "owner"}
        }
    canonical["lineage"]["sourceId"] = record_id
    return canonical


def _record_values(
    document: Mapping[str, Any],
    *,
    allow_legacy_schema: bool = True,
    package: Mapping[str, Any] | None = None,
    text_loader: Any = None,
) -> tuple[list[Mapping[str, Any]], Any, str]:
    if not isinstance(document, Mapping):
        raise CompileError("ConvoEngine document must be an object")
    schema = document.get("schema")
    if schema == COMPACT_PSDL_SCHEMA or (
        schema is None and package is not None
    ) or "profile" in document or "textSidecars" in document:
        expanded = expand_compact_psdl_document(
            document,
            package=package,
            text_loader=text_loader,
        )
        return [expanded], None, str(schema or COMPACT_PSDL_SCHEMA)
    if schema not in SUPPORTED_SOURCE_SCHEMAS:
        raise CompileError(
            f"ConvoEngine document.schema must be {CONVO_ENGINE_SCHEMA} (or migration {LEGACY_PSDL_SCHEMA})"
        )
    if not allow_legacy_schema and schema == LEGACY_PSDL_SCHEMA:
        raise CompileError(
            f"Legacy schema {LEGACY_PSDL_SCHEMA} is read-only migration compatibility; use {CONVO_ENGINE_SCHEMA}"
        )
    if "records" in document:
        unsupported = set(document) - PSDL_DOCUMENT_FIELDS
        if unsupported:
            raise CompileError(
                "ConvoEngine document contains unsupported fields: "
                + ", ".join(sorted((str(item) for item in unsupported)))
            )
        records = document.get("records")
        if not isinstance(records, list) or not records or len(records) > MAX_RECORDS:
            raise CompileError(f"ConvoEngine document.records must contain 1..{MAX_RECORDS} records")
        return records, document.get("owner"), schema
    return [document], None, schema


def _validate_cross_references(records: list[dict[str, Any]]) -> None:
    behavior_ids = {record["id"] for record in records if record["kind"] == "behavior"}
    record_ids = {record["id"] for record in records}
    disallowed_realization_targets: set[str] = set()
    for record in records:
        disallowed_realization_targets.update(collect_disallowed_realization_targets(record))
    for record in records:
        payload = record["payload"]
        if record["kind"] == "beat":
            for candidate in payload.get("candidates", []):
                if candidate["behavior"] not in behavior_ids:
                    raise CompileError(
                        f"beat {record['id']} references unknown behavior {candidate['behavior']}"
                    )
        for field in ("respondWith",):
            reference = payload.get(field)
            if isinstance(reference, str) and reference.startswith("behavior.") and reference not in record_ids:
                raise CompileError(
                    f"{record['id']} references unknown module {reference}"
                )
        for field_label, reference in collect_semantic_references(record):
            validate_semantic_reference(reference, field_label)
            if reference in disallowed_realization_targets:
                raise CompileError(
                    f"{field_label} cannot target wording realization key {reference!r}"
                )


def _default_sidecar_loader(source_path: str | Path) -> Any:
    resolved = Path(source_path).expanduser().resolve()
    shard_dir = resolved.parent
    base_root = shard_dir
    for parent in resolved.parents:
        if (
            (parent / "manifest.json").is_file()
            or (parent / "package.json").is_file()
            or (parent / "provider.json").is_file()
        ):
            base_root = parent
            break

    def load_sidecar(rel_path: str) -> dict[str, Any]:
        candidate = (shard_dir / rel_path).resolve()
        if not candidate.is_file():
            candidate = (base_root / rel_path).resolve()
        if base_root not in candidate.parents and candidate != base_root and shard_dir not in candidate.parents:
            raise CompileError(f"textSidecars path escapes source root: {rel_path!r}")
        if not candidate.is_file():
            raise CompileError(f"Missing textSidecars file {rel_path!r} for {source_path}")
        try:
            data = json.loads(candidate.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise CompileError(f"Invalid textSidecars JSON {rel_path!r}: {error}") from error
        if not isinstance(data, dict):
            raise CompileError(f"textSidecars {rel_path!r} must be a JSON object")
        return data

    return load_sidecar


def compile_convo_engine_document(
    document: Mapping[str, Any],
    *,
    source_path: str | Path | None = None,
    default_owner: Any = None,
    allow_legacy_schema: bool = True,
    validate_cross_references: bool = True,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
    package: Mapping[str, Any] | None = None,
    text_loader: Any = None,
) -> dict[str, Any]:
    """Compile one ConvoEngine/PSDL record or a bounded record catalog."""
    is_compact = (
        document.get("schema") == COMPACT_PSDL_SCHEMA
        or "profile" in document
        or "textSidecars" in document
        or package is not None
    )
    resolved_text_loader = text_loader
    if resolved_text_loader is None and source_path is not None:
        src_parent = Path(source_path).expanduser().parent
        if src_parent.is_dir():
            resolved_text_loader = _default_sidecar_loader(source_path)
    raw_records, doc_owner, doc_schema = _record_values(
        document,
        allow_legacy_schema=allow_legacy_schema,
        package=package,
        text_loader=resolved_text_loader,
    )
    resolved_default_owner = doc_owner if doc_owner is not None else default_owner
    display_path = str(source_path) if source_path is not None else None
    records = [
        _normalize_record(
            raw,
            source_path=(
                f"{display_path}#records[{index}]"
                if display_path is not None and len(raw_records) > 1
                else display_path
            ),
            default_owner=resolved_default_owner,
            document_schema=doc_schema,
            allow_legacy_schema=allow_legacy_schema,
            allow_custom_owner=is_compact,
            action_contracts=action_contracts,
        )
        for index, raw in enumerate(raw_records)
    ]
    records.sort(key=lambda item: item["id"])
    ids = [record["id"] for record in records]
    if len(set(ids)) != len(ids):
        duplicates = sorted({item for item in ids if ids.count(item) > 1})
        raise CompileError("ConvoEngine document repeats IDs: " + ", ".join(duplicates))
    if validate_cross_references:
        _validate_cross_references(records)
    payload = {
        "schema": PSDL_COMPILED_SCHEMA,
        "version": 1,
        "canonicalIRSchema": CANONICAL_IR_SCHEMA,
        "canonicalSchema": CONVO_ENGINE_SCHEMA,
        "authoringSchema": doc_schema,
        "sourceSchema": doc_schema,
        "records": records,
    }
    payload["fingerprint"] = fingerprint(payload)
    return payload


def compile_psdl_document(
    document: Mapping[str, Any],
    *,
    source_path: str | Path | None = None,
    default_owner: Any = None,
    validate_cross_references: bool = True,
) -> dict[str, Any]:
    """Compatibility alias for ``compile_convo_engine_document``."""
    return compile_convo_engine_document(
        document,
        source_path=source_path,
        default_owner=default_owner,
        allow_legacy_schema=True,
        validate_cross_references=validate_cross_references,
    )


def compile_convo_engine_sources(
    sources: Mapping[str | Path, Mapping[str, Any]],
    *,
    default_owner: Any = None,
    allow_legacy_schema: bool = True,
    validate_cross_references: bool = True,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Compile multiple source documents with deterministic path/ID routing."""
    if not isinstance(sources, Mapping) or not sources:
        raise CompileError("ConvoEngine sources must contain at least one document")
    records: list[dict[str, Any]] = []
    reports: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for raw_path in sorted(sources, key=lambda item: str(item)):
        path = str(raw_path)
        compiled = compile_convo_engine_document(
            sources[raw_path],
            source_path=path,
            default_owner=default_owner,
            allow_legacy_schema=allow_legacy_schema,
            validate_cross_references=False,
            action_contracts=action_contracts,
        )
        ids = [record["id"] for record in compiled["records"]]
        duplicates = sorted(set(ids) & seen_ids)
        if duplicates:
            raise CompileError(
                f"ConvoEngine source {path} repeats IDs from another source: {', '.join(duplicates)}"
            )
        seen_ids.update(ids)
        records.extend(compiled["records"])
        reports.append({"path": path, "recordIDs": ids, "fingerprint": compiled["fingerprint"]})
    records.sort(key=lambda item: item["id"])
    if validate_cross_references:
        _validate_cross_references(records)
    output = {
        "schema": PSDL_COMPILED_SCHEMA,
        "version": 1,
        "canonicalIRSchema": CANONICAL_IR_SCHEMA,
        "sources": reports,
        "records": records,
    }
    output["fingerprint"] = fingerprint(output)
    return output


def compile_psdl_sources(
    sources: Mapping[str | Path, Mapping[str, Any]],
) -> dict[str, Any]:
    """Compatibility alias for ``compile_convo_engine_sources``."""
    return compile_convo_engine_sources(sources, allow_legacy_schema=True)


def _translation_segment(
    text: Mapping[str, list[str]],
    template_id: str,
) -> dict[str, Any]:
    return {
        "kind": "translation",
        "templateID": template_id,
        "fallback": text[DEFAULT_LANGUAGE][0],
        "args": {},
    }


def _offer_runtime_projection(
    offer: Mapping[str, Any],
    record_id: str,
) -> dict[str, Any]:
    offer_id = str(offer["id"])
    label = offer.get("label") or {DEFAULT_LANGUAGE: [offer_id]}
    utterance = offer.get("utterance") or label
    output: dict[str, Any] = {
        "id": offer_id,
        "labelKey": f"convo.{record_id}.offer.{offer_id}.label",
        "labelFallback": label[DEFAULT_LANGUAGE][0],
        "utteranceKey": f"convo.{record_id}.offer.{offer_id}.utterance",
        "utteranceFallback": utterance[DEFAULT_LANGUAGE][0],
        "frame": _copy(offer["frame"]),
        "consumers": list(offer.get("consumers", ["participant"])),
    }
    if "when" in offer:
        output["constraints"] = _copy(offer["when"])
    if "transition" in offer:
        output["transition"] = offer["transition"]
    return output


def _response_plan_projection(record: Mapping[str, Any]) -> dict[str, Any] | None:
    payload = record.get("payload") or {}
    response = payload.get("response")
    if isinstance(response, Mapping):
        source = response
    elif "respond" in payload:
        source = {"text": payload["respond"]}
    elif "text" in payload:
        source = {"text": payload["text"]}
    elif "turns" in payload:
        source = {"turns": payload["turns"]}
    elif isinstance(payload.get("say"), Mapping):
        say = payload["say"]
        metadata = payload.get("metadata") or {}
        realizations = say.get("realizations") if isinstance(say.get("realizations"), Mapping) else {}
        key_order = say.get("keyOrder") if isinstance(say.get("keyOrder"), list) else sorted(realizations)
        turns_from_say: list[dict[str, Any]] = []
        for rkey in key_order:
            real = realizations.get(rkey)
            if not isinstance(real, Mapping):
                continue
            variants = real.get("variants")
            if not isinstance(variants, list) or not variants:
                continue
            first_text = variants[0].get("text") if isinstance(variants[0], Mapping) else None
            if isinstance(first_text, Mapping) and first_text.get(DEFAULT_LANGUAGE):
                turns_from_say.append({"id": f"say_{rkey}", "text": first_text})
                break
        if not turns_from_say:
            return None
        source = {
            "act": metadata.get("responseAct") if isinstance(metadata, Mapping) else None,
            "turns": turns_from_say,
        }
    else:
        return None
    source_turns = source.get("turns")
    if source_turns is None and isinstance(source.get("text"), Mapping):
        source_turns = [{"id": "response", "text": source["text"]}]
    if not isinstance(source_turns, list):
        return None
    turns: list[dict[str, Any]] = []
    for index, turn in enumerate(source_turns):
        if not isinstance(turn, Mapping):
            continue
        text = turn.get("text")
        if not isinstance(text, Mapping):
            continue
        turn_id = str(turn.get("id") or f"turn_{index + 1}")
        normalized_turn: dict[str, Any] = {
            "id": turn_id,
            "continuation": "end" if index == len(source_turns) - 1 else "continue",
            "segments": [_translation_segment(text, f"convo.{record['id']}.{turn_id}")],
            "offers": [
                _offer_runtime_projection(offer, str(record["id"]))
                for offer in turn.get("offers", [])
                if isinstance(offer, Mapping)
            ],
        }
        if "transition" in turn:
            transition = turn["transition"]
            normalized_turn["continuation"] = (
                "end" if transition == "terminate" else transition
            )
        turns.append(normalized_turn)
    if not turns:
        return None
    return {
        "schemaVersion": 1,
        "kind": "dialogue_act_plan",
        "responsePlanID": record["id"],
        "dialogueAct": source.get("act"),
        "turns": turns,
    }


def render_convo_engine_runtime_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Render bounded Core-owned plans consumed by existing runtime authorities."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled ConvoEngine payload has an invalid schema")
    plans: list[dict[str, Any]] = []
    for record in compiled.get("records", []):
        owner = normalize_owner(record.get("owner"))
        module_path = (
            conversation_prefix(owner)
            + "/"
            + record["kind"].title()
            + "/"
            + record["id"].replace(".", "_").replace(":", "_")
        )
        plan: dict[str, Any] = {
            "id": record["id"],
            "owner": owner,
            "kind": record["kind"],
            "module": module_path,
            "participants": _copy(record["participants"]),
            "target": _copy(record["target"]),
            "slots": _copy(record["slots"]),
            "references": _copy(record["references"]),
            "when": _copy(record["when"]),
            "lineage": _copy(record["lineage"]),
            "payload": _copy(record["payload"]),
        }
        if "namespace" in record:
            plan["namespace"] = record["namespace"]
        exchange_family = project_exchange_family_runtime(record)
        if exchange_family is not None:
            plan["exchangeFamily"] = exchange_family
            plan["textRoles"] = exchange_family["textRoles"]
        response_plan = _response_plan_projection(record)
        if response_plan is not None:
            plan["responsePlan"] = response_plan
        plans.append(plan)
    return plans


def render_psdl_runtime_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Compatibility alias for ``render_convo_engine_runtime_plan``."""
    return render_convo_engine_runtime_plan(compiled)


def render_psdl_director_plan(compiled: Mapping[str, Any]) -> dict[str, list[dict[str, Any]]]:
    """Project PSDL behaviors and beats into the existing director registries."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    plan: dict[str, list[dict[str, Any]]] = {"behaviors": [], "beats": []}
    for record in compiled.get("records", []):
        kind = record.get("kind")
        if kind == "behavior":
            plan["behaviors"].append(_director_record_projection(record))
        elif kind == "beat":
            plan["beats"].append(_director_record_projection(record))
    plan["behaviors"].sort(key=lambda item: item["id"])
    plan["beats"].sort(key=lambda item: item["id"])
    return plan


def _legacy_condition_projection(predicate: Any) -> Any:
    """Project a public PSDL predicate for the existing bounded selector seam.

    The selector remains a runtime consumer; the semantic condition is authored
    and validated in PSDL.  Flat ``conversation.*`` leaves are projected to the
    selector's historical context keys so adopters do not need a second
    predicate language during the migration.
    """
    if predicate is None:
        return None
    if not isinstance(predicate, Mapping):
        return _copy(predicate)
    if "all" in predicate:
        projected = [_legacy_condition_projection(item) for item in predicate["all"]]
        if all(isinstance(item, Mapping) and len(item) == 1 for item in projected):
            output: dict[str, Any] = {}
            for item in projected:
                output.update(item)
            return output
        return {"all": projected}
    if "any" in predicate:
        return {"any": [_legacy_condition_projection(item) for item in predicate["any"]]}
    if "not" in predicate:
        return {"not": _legacy_condition_projection(predicate["not"])}
    path = str(predicate.get("path", predicate.get("field", "")))
    if path.startswith("conversation.") and path.count(".") == 1:
        field = path.split(".", 1)[1]
        op = predicate.get("op", "eq")
        value = predicate.get("values", predicate.get("value"))
        if op == "in":
            return {field: _copy(value)}
        if op == "eq":
            return {field: _copy(value)}
    return _copy(predicate)


def render_psdl_response_pool_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Project PSDL response variants into the existing ResponsePlan catalog."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    pools: list[dict[str, Any]] = []
    for record in compiled.get("records", []):
        if record.get("kind") != "dialogue":
            continue
        payload = record.get("payload") or {}
        metadata = payload.get("metadata") or {}
        pool_id = metadata.get("responsePoolID") if isinstance(metadata, Mapping) else None
        if not isinstance(pool_id, str) or not pool_id.strip():
            continue
        response = payload.get("response")
        variants: list[Any] | None = None
        act: Any = metadata.get("responseAct") if isinstance(metadata, Mapping) else None
        if isinstance(response, Mapping):
            variants = response.get("variants") if isinstance(response.get("variants"), list) else None
            if response.get("act") is not None:
                act = response.get("act")
        elif isinstance(payload.get("say"), Mapping):
            say = payload["say"]
            realizations = say.get("realizations") if isinstance(say.get("realizations"), Mapping) else {}
            key_order = say.get("keyOrder") if isinstance(say.get("keyOrder"), list) else sorted(realizations)
            collected: list[Any] = []
            for rkey in key_order:
                real = realizations.get(rkey)
                if isinstance(real, Mapping) and isinstance(real.get("variants"), list):
                    collected.extend(real["variants"])
            variants = collected or None
        if not isinstance(variants, list):
            continue
        output_variants: list[dict[str, Any]] = []
        for variant in variants:
            if not isinstance(variant, Mapping):
                continue
            variant_metadata = variant.get("metadata") or {}
            if not isinstance(variant_metadata, Mapping):
                variant_metadata = {}
            text = variant.get("text") or {}
            if not isinstance(text, Mapping) or not text.get(DEFAULT_LANGUAGE):
                continue
            item: dict[str, Any] = {
                "id": variant["id"],
                "templateID": variant_metadata.get("templateID", variant["id"]),
                "translations": _copy(text),
                "fallback": variant_metadata.get(
                    "fallback", text[DEFAULT_LANGUAGE][0]
                ),
            }
            if variant.get("when") is not None:
                item["when"] = _legacy_condition_projection(variant["when"])
            for field in (
                "priority", "translationArgs", "plan", "dialogueAct",
                "topic", "groundedFactRefs", "uncertainty", "tone",
                "personalityStyle", "contentOwner", "reviewed", "sourceRefs",
            ):
                if field in variant_metadata:
                    item[field] = _copy(variant_metadata[field])
            if "dialogueAct" not in item and act is not None:
                item["dialogueAct"] = act
            output_variants.append(item)
        if output_variants:
            pools.append({"id": pool_id, "variants": output_variants})
    pools.sort(key=lambda item: str(item["id"]))
    return pools


def render_psdl_flow_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Project PSDL authored triggers into the accepted flow registry shape."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    flows: list[dict[str, Any]] = []
    for record in compiled.get("records", []):
        if record.get("kind") != "dialogue":
            continue
        payload = record.get("payload") or {}
        metadata = payload.get("metadata") or {}
        if not isinstance(metadata, Mapping):
            continue
        flow_spec = metadata.get("flow")
        if not isinstance(flow_spec, Mapping):
            continue
        flow_id = flow_spec.get("id", f"{record['id']}.flow")
        flows.append({
            "id": flow_id,
            "version": flow_spec.get("version", 1),
            "owner": flow_spec.get(
                "owner",
                metadata.get("originalOwner", record["owner"]),
            ),
            "initial": flow_spec.get("initial", "accepted"),
            "nodes": _copy(flow_spec.get("nodes") or {}),
            "triggers": _copy(metadata.get("triggers") or []),
        })
    flows.sort(key=lambda item: str(item["id"]))
    return flows


def render_psdl_realization_plan(
    compiled: Mapping[str, Any],
    *,
    source_path: str = "realization/realization.json",
) -> list[dict[str, Any]]:
    """Project structured PSDL realization records into SpeechRealization input."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    output: list[dict[str, Any]] = []
    for record in compiled.get("records", []):
        if record.get("kind") != "realization":
            continue
        payload = _copy(record.get("payload") or {})
        realization_type = payload.get("type")
        payload["id"] = record["id"]
        payload["owner"] = record["owner"]
        payload["sourceShard"] = source_path
        if realization_type == "lexeme":
            output.append(payload)
            continue
        translations = payload.pop("translations", {})
        for raw_locale, tokens in sorted(translations.items(), key=lambda item: str(item[0])):
            locale = str(raw_locale).upper()
            base_parts = record["id"].split(".")
            if len(base_parts) < 3 or base_parts[0] != "construction":
                raise CompileError(
                    f"{record['id']} must be construction.<domain>.<name>"
                )
            item = _copy(payload)
            item["id"] = ".".join(("construction", locale.lower(), *base_parts[1:]))
            item["locale"] = locale
            item["tokens"] = _copy(tokens)
            output.append(item)
    output.sort(key=lambda item: str(item.get("id", "")))
    return output


def render_psdl_ui_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Project top-level PSDL offers into the existing UI suggestion rows."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    rows_by_namespace: dict[str, list[dict[str, Any]]] = {}
    for record in compiled.get("records", []):
        if record.get("kind") != "dialogue":
            continue
        payload = record.get("payload") or {}
        metadata = payload.get("metadata") or {}
        if not isinstance(metadata, Mapping):
            raise CompileError(f"{record['id']}.metadata must be an object")
        namespace = metadata.get("textNamespace", "UI_Conversation_Suggestion")
        if not isinstance(namespace, str) or not namespace.strip():
            raise CompileError(f"{record['id']}.metadata.textNamespace must be a namespace")
        for offer in payload.get("offers", []):
            frame = offer.get("frame") or {}
            offer_metadata = offer.get("metadata") or {}
            if not isinstance(frame, Mapping) or not isinstance(offer_metadata, Mapping):
                raise CompileError(f"{record['id']} offer metadata must be objects")
            pattern_id = frame.get("patternID") or offer_metadata.get("patternID")
            if not isinstance(pattern_id, str) or not pattern_id.strip():
                raise CompileError(
                    f"{record['id']}.{offer['id']} requires frame.patternID for UI projection"
                )
            order = offer_metadata.get("order")
            if isinstance(order, bool) or not isinstance(order, int):
                raise CompileError(
                    f"{record['id']}.{offer['id']}.metadata.order must be an integer"
                )
            label = offer.get("label")
            utterance = offer.get("utterance")
            if not isinstance(label, Mapping) or not isinstance(utterance, Mapping):
                raise CompileError(
                    f"{record['id']}.{offer['id']} requires localized label and utterance"
                )
            languages = sorted(set(label) | set(utterance))
            display: dict[str, dict[str, str]] = {}
            for language in languages:
                label_values = label.get(language) or label.get(DEFAULT_LANGUAGE)
                utterance_values = utterance.get(language) or utterance.get(DEFAULT_LANGUAGE)
                if not isinstance(label_values, list) or not label_values:
                    raise CompileError(
                        f"{record['id']}.{offer['id']}.label lacks {language} fallback text"
                    )
                if not isinstance(utterance_values, list) or not utterance_values:
                    raise CompileError(
                        f"{record['id']}.{offer['id']}.utterance lacks {language} fallback text"
                    )
                display[language] = {
                    "label": label_values[0],
                    "utterance": utterance_values[0],
                }
            row: dict[str, Any] = {
                "id": offer["id"],
                "order": order,
                "patternID": pattern_id,
                "display": display,
                "sourceRecordID": record["id"],
                "owner": record["owner"],
            }
            for field in ("intent", "speechAct", "subject", "topic"):
                if field in frame:
                    row[field] = frame[field]
            for field, value in frame.items():
                if field not in row and field != "patternID":
                    row[field] = _copy(value)
            if "domain" in offer_metadata:
                row["domain"] = offer_metadata["domain"]
            rows_by_namespace.setdefault(namespace, []).append(row)
        affordance = payload.get("affordance")
        aff_meta = affordance.get("metadata") if isinstance(affordance, Mapping) else None
        ui_meta = metadata.get("ui")
        if not isinstance(ui_meta, Mapping) and isinstance(aff_meta, Mapping):
            ui_meta = aff_meta.get("ui")
        if isinstance(affordance, Mapping) and isinstance(ui_meta, Mapping):
            say = payload.get("say")
            if not isinstance(say, Mapping) or not isinstance(say.get("realizations"), Mapping):
                raise CompileError(f"{record['id']} requires say realizations for UI projection")
            realizations = say["realizations"]
            key_order = say.get("keyOrder") if isinstance(say.get("keyOrder"), list) and say["keyOrder"] else sorted(realizations)
            first_real = realizations.get(key_order[0]) if key_order else None
            first_variants = first_real.get("variants") if isinstance(first_real, Mapping) else None
            utterance = first_variants[0].get("text") if isinstance(first_variants, list) and first_variants else None
            invoke = payload.get("invoke") if isinstance(payload.get("invoke"), Mapping) else {}
            pattern_id = invoke.get("patternID") or ui_meta.get("patternID")
            ui_id = ui_meta.get("id") or record["id"]
            if not isinstance(pattern_id, str) or not pattern_id.strip():
                raise CompileError(f"{record['id']} requires invoke.patternID or metadata.ui.patternID for UI projection")
            order = ui_meta.get("order")
            if isinstance(order, bool) or not isinstance(order, int):
                raise CompileError(f"{record['id']}.metadata.ui.order must be an integer")
            label = affordance.get("label")
            if not isinstance(label, Mapping) or not isinstance(utterance, Mapping):
                raise CompileError(f"{record['id']} requires localized affordance.label and say utterance for UI projection")
            languages = sorted(set(label) | set(utterance))
            display = {}
            for language in languages:
                label_values = label.get(language) or label.get(DEFAULT_LANGUAGE)
                utterance_values = utterance.get(language) or utterance.get(DEFAULT_LANGUAGE)
                if not isinstance(label_values, list) or not label_values:
                    raise CompileError(f"{record['id']}.affordance.label lacks {language} fallback text")
                if not isinstance(utterance_values, list) or not utterance_values:
                    raise CompileError(f"{record['id']}.say lacks {language} fallback text")
                display[language] = {
                    "label": label_values[0],
                    "utterance": utterance_values[0],
                }
            row = {
                "id": ui_id,
                "order": order,
                "patternID": pattern_id,
                "display": display,
                "sourceRecordID": record["id"],
                "owner": record["owner"],
            }
            for field, value in ui_meta.items():
                if field not in ("id", "order", "patternID") and field not in row:
                    row[field] = _copy(value)
            for field in ("topic", "intent", "speechAct", "subject"):
                if field not in row and field in invoke:
                    row[field] = _copy(invoke[field])
            if "slots" not in row and record.get("slots"):
                row["slots"] = _copy(record["slots"])
            if "target" not in row and record.get("target"):
                row["target"] = _copy(record["target"])
            rows_by_namespace.setdefault(namespace, []).append(row)
    rows: list[dict[str, Any]] = []
    for namespace in sorted(rows_by_namespace):
        rows.extend(
            validate_ui_shard(
                {
                    "textNamespace": namespace,
                    "suggestions": rows_by_namespace[namespace],
                },
                f"PSDL UI projection {namespace}",
            )["suggestions"]
        )
    rows.sort(key=lambda item: (item["order"], item["id"]))
    return rows


def render_psdl_semantic_pack_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Project PSDL recognition declarations into the existing semantic-pack authority."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    packs: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in compiled.get("records", []):
        recognition = (record.get("payload") or {}).get("recognition")
        if recognition is None:
            continue
        pack = {
            "id": recognition["packID"],
            "version": recognition["version"],
            "concepts": _copy(recognition.get("concepts", [])),
            "speechActs": _copy(recognition.get("speechActs", [])),
            "patterns": _copy(recognition.get("patterns", [])),
        }
        for field in ("ownerModID", "actionProviders", "dialogueBlocks"):
            if field in recognition:
                pack[field] = _copy(recognition[field])
        if pack["id"] in seen:
            raise CompileError(
                f"PSDL document repeats semantic-pack ID: {pack['id']}"
            )
        seen.add(pack["id"])
        validated = compile_semantic_pack_shard(
            {
                "schema": CONVERSATION_SHARD_SCHEMA,
                "kind": "packs",
                "source": {"owner": record["owner"], "version": "1"},
                "packs": [pack],
            },
            f"PSDL {record['id']}.recognition",
        )
        packs.extend(validated["packs"])
    return sorted(packs, key=lambda item: str(item.get("id", "")))


def render_pz_backend_from_portable_plan(
    portable_plan: Mapping[str, Any],
    *,
    entry_by_record_id: Mapping[str, Mapping[str, Any]] | None = None,
    default_owner: Any = None,
) -> dict[str, Any]:
    """G8R2: Project PZ runtime plans/registries exclusively from a Portable Dialogue Plan."""
    if not isinstance(portable_plan, Mapping) or portable_plan.get("schema") != PORTABLE_PLAN_SCHEMA:
        raise CompileError(
            f"PZ backend requires a validated Portable Dialogue Plan ({PORTABLE_PLAN_SCHEMA})"
        )
    records = portable_plan_records(portable_plan)
    compiled_envelope = {
        "schema": PSDL_COMPILED_SCHEMA,
        "version": 1,
        "records": records,
    }
    entry_map = entry_by_record_id or {}

    runtime_plans: list[dict[str, Any]] = []
    for plan in render_psdl_runtime_plan(compiled_envelope):
        row = _copy(plan)
        entry = entry_map.get(str(row.get("id") or "")) or {}
        row["owner"] = normalize_owner(entry.get("owner") or row.get("owner"), default=default_owner)
        if "domain" in entry:
            row["domain"] = entry["domain"]
        if "domainPath" in entry or "domain" in entry:
            row["domainPath"] = entry.get("domainPath") or entry["domain"]
        if "path" in entry:
            row["sourceShard"] = entry["path"]
        runtime_plans.append(row)

    director_plan = render_psdl_director_plan(compiled_envelope)
    behaviors: list[dict[str, Any]] = []
    for record in director_plan["behaviors"]:
        entry = entry_map.get(str(record.get("id") or "")) or {}
        if "path" in entry:
            record["sourceShard"] = entry["path"]
        if "domain" in entry:
            record["domain"] = entry["domain"]
        if "domainPath" in entry or "domain" in entry:
            record["domainPath"] = entry.get("domainPath") or entry["domain"]
        behaviors.append(record)
    beats: list[dict[str, Any]] = []
    for record in director_plan["beats"]:
        entry = entry_map.get(str(record.get("id") or "")) or {}
        if "path" in entry:
            record["sourceShard"] = entry["path"]
        if "domain" in entry:
            record["domain"] = entry["domain"]
        if "domainPath" in entry or "domain" in entry:
            record["domainPath"] = entry.get("domainPath") or entry["domain"]
        beats.append(record)

    ui_rows: list[dict[str, Any]] = []
    for row in render_psdl_ui_plan(compiled_envelope):
        row.pop("sourceRecordID", None)
        row.pop("owner", None)
        ui_rows.append(row)

    semantic_packs: list[dict[str, Any]] = []
    for record in records:
        entry = entry_map.get(str(record.get("id") or "")) or {}
        for pack in render_psdl_semantic_pack_plan({
            "schema": PSDL_COMPILED_SCHEMA,
            "version": 1,
            "records": [record],
        }):
            pack_row = _copy(pack)
            pack_row["owner"] = normalize_owner(
                entry.get("owner") or pack_row.get("owner"),
                default=default_owner,
            )
            if "domain" in entry:
                pack_row["domain"] = entry["domain"]
            if "path" in entry:
                pack_row["sourceShard"] = entry["path"]
            semantic_packs.append(pack_row)

    response_pools: list[dict[str, Any]] = []
    response_pool_owners: dict[str, str] = {}
    for record in records:
        entry = entry_map.get(str(record.get("id") or "")) or {}
        rec_owner = normalize_owner(
            entry.get("owner") or record.get("owner"),
            default=default_owner,
        )
        for pool in render_psdl_response_pool_plan({
            "schema": PSDL_COMPILED_SCHEMA,
            "version": 1,
            "records": [record],
        }):
            response_pools.append(pool)
            pool_id = str(pool.get("id") or "")
            if pool_id:
                response_pool_owners[pool_id] = rec_owner

    flows = render_psdl_flow_plan(compiled_envelope)
    realizations: list[dict[str, Any]] = []
    for record in records:
        if record.get("kind") != "realization":
            continue
        entry = entry_map.get(str(record.get("id") or "")) or {}
        realizations.extend(
            render_psdl_realization_plan(
                {
                    "schema": PSDL_COMPILED_SCHEMA,
                    "version": 1,
                    "records": [record],
                },
                source_path=entry.get("path"),
            )
        )

    return {
        "portablePlanSchema": portable_plan["schema"],
        "runtimePlans": runtime_plans,
        "behaviors": behaviors,
        "beats": beats,
        "ui": ui_rows,
        "semanticPacks": semantic_packs,
        "responsePools": response_pools,
        "responsePoolOwners": response_pool_owners,
        "flows": flows,
        "realizations": realizations,
    }


__all__ = [
    "CONVO_ENGINE_COMPILED_SCHEMA",
    "CONVO_ENGINE_SCHEMA",
    "LEGACY_PSDL_SCHEMA",
    "PSDL_COMPILED_SCHEMA",
    "PSDL_KINDS",
    "PSDL_SCHEMA",
    "SUPPORTED_SOURCE_SCHEMAS",
    "compile_convo_engine_document",
    "compile_convo_engine_sources",
    "compile_psdl_document",
    "compile_psdl_sources",
    "render_convo_engine_runtime_plan",
    "render_psdl_director_plan",
    "render_psdl_ui_plan",
    "render_psdl_semantic_pack_plan",
    "render_psdl_runtime_plan",
]
