"""Core-owned PSDL parser, normalizer and deterministic runtime plan compiler.

PSDL records are authoring input only.  This module produces the canonical
Semantic Dialogue IR and a bounded plan for the already accepted response,
behavior, beat and realization authorities; it does not introduce a second
dialogue runtime.
"""

from __future__ import annotations

import copy
import re
from collections import Counter
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .conversation_model import fingerprint
from .errors import CompileError
from .generation_ownership import (
    OwnerConfigurationError,
    conversation_prefix,
    normalize_owner,
    package_descriptor,
)
from .rule_contract import normalize_predicate
from .semantic_dialogue_ir import (
    CANONICAL_IR_SCHEMA,
    PSDL_SCHEMA,
    REFERENCE_TYPES,
    SLOT_TYPES,
    canonicalize_dialogue,
    validate_context_path,
)
from .translation_support import DEFAULT_LANGUAGE, normalize_language


PSDL_COMPILED_SCHEMA = "psychopatz.semantic.dialogue-compiled.v1"
PSDL_KINDS = frozenset({"dialogue", "behavior", "beat", "realization"})
PSDL_DOCUMENT_FIELDS = frozenset({"schema", "records", "owner", "metadata"})
PSDL_RECORD_FIELDS = frozenset({
    "schema", "kind", "id", "owner", "participants", "target", "slots",
    "references", "when", "constraints", "on", "respond", "response",
    "variants", "turns", "offers", "transitions", "bindings", "text",
    "label", "utterance", "stimuli", "act", "respondWith", "baseRelevance",
    "entry", "maintain", "exit", "candidates", "group", "cooldownTurns",
    "maxTurns", "effects", "policy", "metadata", "style", "resolver",
})
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
_ID = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_NAME = re.compile(r"^[a-z][a-z0-9_]{0,31}$")
_RESOLVER = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_PLACEHOLDER = re.compile(r"\{([a-z][a-z0-9_.]*)\}")
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
        if not isinstance(name, str) or not _NAME.fullmatch(name):
            raise CompileError(f"{label} contains an invalid binding name {name!r}")
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


def _normalize_module_payload(
    kind: str,
    payload: dict[str, Any],
    *,
    label: str,
) -> dict[str, Any]:
    bindings = _normalize_bindings(payload.get("bindings"), f"{label}.bindings")
    if bindings:
        payload["bindings"] = bindings
    else:
        payload.pop("bindings", None)

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
    if kind == "dialogue" and not any(
        field in payload for field in ("respond", "response", "variants", "turns", "text", "offers")
    ):
        raise CompileError(f"{label} requires a response, turns, variants, offers or text")
    if kind == "behavior" and not any(
        field in payload for field in ("act", "respondWith")
    ):
        raise CompileError(f"{label} requires act or respondWith")
    if kind == "realization" and not any(
        field in payload for field in ("text", "variants")
    ):
        raise CompileError(f"{label} requires text or variants")
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


def _normalize_record(
    raw: Mapping[str, Any],
    *,
    source_path: str | None,
    default_owner: Any = None,
) -> dict[str, Any]:
    if not isinstance(raw, Mapping):
        raise CompileError("PSDL record must be an object")
    unsupported = set(raw) - PSDL_RECORD_FIELDS
    if unsupported:
        raise CompileError(
            "PSDL record contains unsupported fields: "
            + ", ".join(sorted((str(item) for item in unsupported)))
        )
    record = _copy(dict(raw))
    if "schema" not in record:
        record["schema"] = PSDL_SCHEMA
    if "owner" not in record and default_owner is not None:
        record["owner"] = default_owner
    record_id = _id(record.get("id"), "PSDL record.id")
    try:
        record["owner"] = normalize_owner(record.get("owner"))
        package_descriptor(record["owner"])
    except OwnerConfigurationError as error:
        raise CompileError(str(error)) from error
    if "when" in record and "constraints" in record:
        raise CompileError(f"{record_id} cannot define both when and constraints")
    canonical = canonicalize_dialogue(record, source_path=source_path)
    canonical["payload"] = _normalize_module_payload(
        canonical["kind"], canonical["payload"], label=record_id
    )
    canonical["owner"] = record["owner"]
    canonical["lineage"]["sourceId"] = record_id
    return canonical


def _record_values(document: Mapping[str, Any]) -> tuple[list[Mapping[str, Any]], Any]:
    if not isinstance(document, Mapping) or document.get("schema") != PSDL_SCHEMA:
        raise CompileError(f"PSDL document.schema must be {PSDL_SCHEMA}")
    if "records" in document:
        unsupported = set(document) - PSDL_DOCUMENT_FIELDS
        if unsupported:
            raise CompileError(
                "PSDL document contains unsupported fields: "
                + ", ".join(sorted((str(item) for item in unsupported)))
            )
        records = document.get("records")
        if not isinstance(records, list) or not records or len(records) > MAX_RECORDS:
            raise CompileError(f"PSDL document.records must contain 1..{MAX_RECORDS} records")
        return records, document.get("owner")
    return [document], None


def _validate_cross_references(records: list[dict[str, Any]]) -> None:
    behavior_ids = {record["id"] for record in records if record["kind"] == "behavior"}
    record_ids = {record["id"] for record in records}
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


def compile_psdl_document(
    document: Mapping[str, Any],
    *,
    source_path: str | Path | None = None,
) -> dict[str, Any]:
    """Compile one PSDL record or a bounded PSDL record catalog."""
    raw_records, default_owner = _record_values(document)
    display_path = str(source_path) if source_path is not None else None
    records = [
        _normalize_record(
            raw,
            source_path=(
                f"{display_path}#records[{index}]"
                if display_path is not None and len(raw_records) > 1
                else display_path
            ),
            default_owner=default_owner,
        )
        for index, raw in enumerate(raw_records)
    ]
    records.sort(key=lambda item: item["id"])
    ids = [record["id"] for record in records]
    if len(set(ids)) != len(ids):
        duplicates = sorted({item for item in ids if ids.count(item) > 1})
        raise CompileError("PSDL document repeats IDs: " + ", ".join(duplicates))
    _validate_cross_references(records)
    payload = {
        "schema": PSDL_COMPILED_SCHEMA,
        "version": 1,
        "canonicalIRSchema": CANONICAL_IR_SCHEMA,
        "records": records,
    }
    payload["fingerprint"] = fingerprint(payload)
    return payload


def compile_psdl_sources(
    sources: Mapping[str | Path, Mapping[str, Any]],
) -> dict[str, Any]:
    """Compile multiple source documents with deterministic path/ID routing."""
    if not isinstance(sources, Mapping) or not sources:
        raise CompileError("PSDL sources must contain at least one document")
    records: list[dict[str, Any]] = []
    reports: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for raw_path in sorted(sources, key=lambda item: str(item)):
        path = str(raw_path)
        compiled = compile_psdl_document(sources[raw_path], source_path=path)
        ids = [record["id"] for record in compiled["records"]]
        duplicates = sorted(set(ids) & seen_ids)
        if duplicates:
            raise CompileError(
                f"PSDL source {path} repeats IDs from another source: {', '.join(duplicates)}"
            )
        seen_ids.update(ids)
        records.extend(compiled["records"])
        reports.append({"path": path, "recordIDs": ids, "fingerprint": compiled["fingerprint"]})
    records.sort(key=lambda item: item["id"])
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
        "labelKey": f"psdl.{record_id}.offer.{offer_id}.label",
        "labelFallback": label[DEFAULT_LANGUAGE][0],
        "utteranceKey": f"psdl.{record_id}.offer.{offer_id}.utterance",
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
            "segments": [_translation_segment(text, f"psdl.{record['id']}.{turn_id}")],
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


def render_psdl_runtime_plan(compiled: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Render bounded Core-owned plans consumed by existing runtime authorities."""
    if compiled.get("schema") != PSDL_COMPILED_SCHEMA:
        raise CompileError("compiled PSDL payload has an invalid schema")
    plans: list[dict[str, Any]] = []
    for record in compiled.get("records", []):
        owner = normalize_owner(record.get("owner"))
        module_path = (
            conversation_prefix(owner)
            + "/PSDL/"
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
        response_plan = _response_plan_projection(record)
        if response_plan is not None:
            plan["responsePlan"] = response_plan
        plans.append(plan)
    return plans


__all__ = [
    "PSDL_COMPILED_SCHEMA",
    "PSDL_KINDS",
    "PSDL_SCHEMA",
    "compile_psdl_document",
    "compile_psdl_sources",
    "render_psdl_runtime_plan",
]
