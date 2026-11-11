"""Compile reviewed dialogue response conditions, plans, and pools."""

from __future__ import annotations

import re
from typing import Any

from .lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder.translation_support import normalize_translations
from tools.semantic_harness.codebuilder.rule_contract import (
    validate_scalar_conditions,
    validate_typed_arguments,
)
from .dialogue_contract import (
    DIALOGUE_ID,
    DIALOGUE_TEMPLATE_ID,
    DIALOGUE_BACKSTORY_KINDS,
    DIALOGUE_BACKSTORY_EXTENSIONS,
    DIALOGUE_BACKSTORY_DISCLOSURES,
    DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS,
    DIALOGUE_PROMISE_SUBJECTS,
    DIALOGUE_PROMISE_EXTENSIONS,
    DIALOGUE_TRANSLATION_ARG_TYPES,
    DIALOGUE_PLAN_UNCERTAINTIES,
    DIALOGUE_RESPONSE_CONDITIONS,
    DIALOGUE_MAX_VARIANTS_PER_POOL,
    validate_branch_offers,
    _validate_source_refs,
)


def _variant_translations(
    variant: dict[str, Any],
    fallback: str,
    label: str,
) -> dict[str, str]:
    """Normalize an optional generic translation map."""
    raw = variant.get("translations")
    if raw is None:
        return {}
    return normalize_translations(raw, f"{label}.translations")

def _validate_response_condition(value: Any, pool_id: str, variant_id: str) -> dict[str, Any]:
    return validate_scalar_conditions(
        value,
        f"{pool_id}:{variant_id}",
        DIALOGUE_RESPONSE_CONDITIONS,
    )


def _validate_translation_args(value: Any, label: str) -> dict[str, str]:
    """Validate typed argument declarations without evaluating them."""
    return validate_typed_arguments(
        value,
        label,
        DIALOGUE_TRANSLATION_ARG_TYPES,
    )


def _validate_dialogue_plan(
    value: Any,
    pool_id: str,
    variant_id: str,
    template_id: str,
    fallback: str,
) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} must be an object")
    allowed = {
        "dialogueAct", "sourcePoolID", "topic", "groundedFactRefs",
        "uncertainty", "tone", "personalityStyle", "referenceTopic",
        "referenceSubject", "turns",
    }
    if set(value) - allowed:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has unsupported fields")
    dialogue_act = value.get("dialogueAct")
    if not isinstance(dialogue_act, str) or not dialogue_act.strip():
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} requires dialogueAct")
    source_pool = value.get("sourcePoolID", pool_id)
    if not isinstance(source_pool, str) or not DIALOGUE_TEMPLATE_ID.fullmatch(source_pool):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid sourcePoolID")
    topic = value.get("topic")
    if topic is not None and (not isinstance(topic, str) or not topic.strip()):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid topic")
    reference_topic = value.get("referenceTopic")
    reference_subject = value.get("referenceSubject")
    for field, item in (("referenceTopic", reference_topic),
                        ("referenceSubject", reference_subject)):
        if item is not None and (
            not isinstance(item, str) or not DIALOGUE_TEMPLATE_ID.fullmatch(item)
        ):
            raise CompileError(
                f"dialogue response plan for {pool_id}:{variant_id} has invalid {field}"
            )
    refs = value.get("groundedFactRefs", value.get("sourceFactRefs", []))
    if not isinstance(refs, list) or len(refs) > 8:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact refs")
    normalized_refs = []
    for ref in refs:
        if not isinstance(ref, str) or not ref or len(ref) > 128:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact ref")
        if not re.fullmatch(r"[A-Za-z0-9_.:-]+", ref):
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact ref")
        if ref not in normalized_refs:
            normalized_refs.append(ref)
    uncertainty = value.get("uncertainty")
    if uncertainty not in DIALOGUE_PLAN_UNCERTAINTIES:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid uncertainty")
    normalized = {
        "dialogueAct": dialogue_act.strip(),
        "sourcePoolID": source_pool,
        "topic": topic.strip() if isinstance(topic, str) else None,
        "referenceTopic": reference_topic,
        "referenceSubject": reference_subject,
        "groundedFactRefs": normalized_refs,
        "uncertainty": uncertainty,
        "tone": value.get("tone"),
        "personalityStyle": value.get("personalityStyle"),
        "turns": [],
    }
    for field in ("tone", "personalityStyle"):
        item = normalized[field]
        if item is not None and (not isinstance(item, str) or not item.strip()):
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid {field}")
        if isinstance(item, str):
            normalized[field] = item.strip()
    turns = value.get("turns")
    if not isinstance(turns, list) or not turns or len(turns) > 4:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} requires 1 to 4 turns")
    for turn in turns:
        if not isinstance(turn, dict) or set(turn) - {
            "id", "continuation", "segments", "offers"
        }:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid turn")
        segments = turn.get("segments")
        if not isinstance(segments, list) or not segments or len(segments) > 6:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid segments")
        normalized_segments = []
        for segment in segments:
            if not isinstance(segment, dict):
                raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid segment")
            kind = segment.get("kind")
            if kind == "translation":
                segment_template = segment.get("templateID", template_id)
                segment_fallback = segment.get("fallback", fallback)
                if (not isinstance(segment_template, str)
                        or not DIALOGUE_TEMPLATE_ID.fullmatch(segment_template)
                        or not isinstance(segment_fallback, str)
                        or not segment_fallback.strip()
                        or len(segment_fallback) > 256):
                    raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid translation segment")
                normalized_segments.append({
                    "kind": "translation",
                    "templateID": segment_template,
                    "fallback": segment_fallback.strip(),
                    "translationArgs": _validate_translation_args(
                        segment.get("translationArgs"),
                        f"dialogue response plan for {pool_id}:{variant_id} translationArgs",
                    ),
                })
            elif kind == "literal":
                segment_text = segment.get("text")
                if not isinstance(segment_text, str) or not segment_text.strip() or len(segment_text) > 256:
                    raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid literal segment")
                normalized_segments.append({"kind": "literal", "text": segment_text.strip()})
            else:
                raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has unsupported segment kind")
        normalized_offers = validate_branch_offers(
            turn.get("offers"),
            f"dialogue response plan for {pool_id}:{variant_id} turn offers",
        )
        normalized_turn = {
            "id": str(turn.get("id", len(normalized["turns"]) + 1)),
            "continuation": str(turn.get("continuation", "end")),
            "segments": normalized_segments,
        }
        if "offers" in turn:
            normalized_turn["offers"] = normalized_offers
        normalized["turns"].append(normalized_turn)
    return normalized


def _compile_dialogue_response_pool(
    value: Any,
    source_names: set[str],
) -> tuple[dict[str, Any], dict[str, dict[str, str]]]:
    if not isinstance(value, dict):
        raise CompileError("dialogue response pools must be objects")
    pool_id = value.get("id")
    variants = value.get("variants")
    if (not isinstance(pool_id, str)
        or not DIALOGUE_ID.fullmatch(pool_id)
        or not pool_id.startswith("semantic.")):
        raise CompileError(f"invalid dialogue response pool id: {pool_id!r}")
    if not isinstance(variants, list) or not variants:
        raise CompileError(f"dialogue response pool {pool_id} requires variants")
    if len(variants) > DIALOGUE_MAX_VARIANTS_PER_POOL:
        raise CompileError(
            f"dialogue response pool {pool_id} exceeds the supplemental variant limit")

    compiled_variants = []
    seen_ids: set[str] = set()
    for index, variant in enumerate(variants, 1):
        if not isinstance(variant, dict):
            raise CompileError(f"dialogue response {pool_id}:{index} must be an object")
        variant_id = variant.get("id")
        fallback = variant.get("fallback")
        if not isinstance(variant_id, str) or not DIALOGUE_ID.fullmatch(variant_id):
            raise CompileError(f"invalid dialogue response id in {pool_id}:{index}")
        if variant_id in seen_ids:
            raise CompileError(f"duplicate dialogue response id {variant_id}")
        seen_ids.add(variant_id)
        if (not isinstance(fallback, str) or not fallback.strip()
            or len(fallback) > 256
            or re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", fallback)):
            raise CompileError(f"invalid fallback text for {pool_id}:{variant_id}")
        template_id = variant.get("templateID", variant_id)
        if (not isinstance(template_id, str)
                or not DIALOGUE_TEMPLATE_ID.fullmatch(template_id)):
            raise CompileError(f"invalid template id for {pool_id}:{variant_id}")
        priority = variant.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, int) or not -10 <= priority <= 10:
            raise CompileError(
                f"response priority for {pool_id}:{variant_id} must be from -10 to 10")
        allowed_keys = {
            "id", "templateID", "fallback", "when", "priority",
            "translations", "plan", "reviewed", "sourceRefs", "translationArgs",
        }
        if set(variant) - allowed_keys:
            raise CompileError(
                f"unsupported fields for dialogue response {pool_id}:{variant_id}")
        if (not isinstance(template_id, str)
                or not DIALOGUE_TEMPLATE_ID.fullmatch(template_id)):
            raise CompileError(f"invalid template id for {pool_id}:{variant_id}")
        localized = _variant_translations(
            variant,
            fallback.strip(),
            f"dialogue response {pool_id}:{variant_id}",
        )
        reviewed = variant.get("reviewed", False)
        if not isinstance(reviewed, bool):
            raise CompileError(f"dialogue response {pool_id}:{variant_id} reviewed must be boolean")
        source_refs = []
        if "sourceRefs" in variant:
            source_refs = _validate_source_refs(
                variant["sourceRefs"], source_names,
                f"dialogue response {pool_id}:{variant_id} sourceRefs",
            )
        if "plan" in variant and (not reviewed or not source_refs):
            raise CompileError(
                f"dialogue response {pool_id}:{variant_id} plan requires reviewed source metadata")
        translation_args = _validate_translation_args(
            variant.get("translationArgs"),
            f"dialogue response {pool_id}:{variant_id} translationArgs",
        )
        compiled_variant = {
            "id": variant_id,
            "templateID": template_id,
            "fallback": fallback.strip(),
        }
        if translation_args:
            compiled_variant["translationArgs"] = translation_args
        condition = _validate_response_condition(variant.get("when"), pool_id, variant_id)
        if condition:
            compiled_variant["when"] = condition
        if priority != 0:
            compiled_variant["priority"] = priority
        if "plan" in variant:
            compiled_variant["plan"] = _validate_dialogue_plan(
                variant["plan"], pool_id, variant_id, template_id, fallback.strip()
            )
        if reviewed:
            compiled_variant["metadata"] = {
                "reviewed": True,
                "sourceRefs": source_refs,
            }
        if localized:
            compiled_variant.setdefault("metadata", {})["translationKey"] = template_id
        compiled_variants.append(compiled_variant)
    translations: dict[str, dict[str, str]] = {}
    for variant in variants:
        variant_id = variant["id"]
        compiled_variant = next(item for item in compiled_variants if item["id"] == variant_id)
        key = compiled_variant["templateID"]
        localized = _variant_translations(
            variant,
            compiled_variant["fallback"],
            f"dialogue response {pool_id}:{variant_id}",
        )
        for language, text in localized.items():
            bucket = translations.setdefault(language, {})
            if key in bucket:
                raise CompileError(f"duplicate dialogue translation key {key}")
            bucket[key] = text
    return {"id": pool_id, "variants": compiled_variants}, translations
