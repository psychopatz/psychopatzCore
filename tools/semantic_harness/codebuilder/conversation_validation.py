"""Validation and merge rules for Conversation source shards.

This module owns shard-local contracts. The compiler orchestrates discovery and
assembly but does not duplicate validation policy.
"""

from __future__ import annotations

import re
from typing import Any

from .conversation_manifest import validate_id as _validate_id
from .conversation_model import copy_json as _copy_json
from .conversation_contract import CONVERSATION_MAX_RECORDS_PER_SHARD
from .conversation_ui_contract import validate_ui_shard
from .errors import CompileError
from .generation_ownership import normalize_owner
from .rule_contract import normalize_predicate


def _validate_director_predicate(value: Any, label: str, *, depth: int = 0) -> dict[str, Any]:
    normalized = normalize_predicate(
        value,
        label,
        depth,
        max_depth=4,
        max_items=16,
    )
    if not isinstance(normalized, dict):
        raise CompileError(f"{label} must be an object")
    return normalized

def _validate_behavior_shard(
    document: dict[str, Any],
    path: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    values = document.get("behaviors")
    if not isinstance(values, list):
        raise CompileError(f"Behavior shard {path} requires a behaviors list")
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    token = re.compile(r"^[A-Z][A-Z0-9_]{0,63}$")
    for index, raw in enumerate(values):
        label = f"{path}.behaviors[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        if not record_id.startswith("behavior."):
            raise CompileError(f"{label}.id must start with behavior.")
        if record_id in seen:
            raise CompileError(f"duplicate behavior id: {record_id}")
        seen.add(record_id)

        act = raw.get("act")
        if not isinstance(act, str) or not token.fullmatch(act):
            raise CompileError(f"{label}.act must be a bounded semantic token")

        mode = raw.get("mode", "beat")
        if mode not in ("beat", "one_shot"):
            raise CompileError(f"{label}.mode must be beat or one_shot")

        raw_stimuli = raw.get("stimuli")
        if not isinstance(raw_stimuli, list) or not raw_stimuli or len(raw_stimuli) > 16:
            raise CompileError(f"{label}.stimuli must contain 1-16 stimulus tokens")
        stimuli: list[str] = []
        stimulus_seen: set[str] = set()
        for stimulus_index, value in enumerate(raw_stimuli):
            if not isinstance(value, str) or not token.fullmatch(value):
                raise CompileError(
                    f"{label}.stimuli[{stimulus_index}] must be a bounded semantic token"
                )
            if value in stimulus_seen:
                raise CompileError(f"{label}.stimuli contains duplicate {value}")
            stimulus_seen.add(value)
            stimuli.append(value)

        raw_capabilities = raw.get("requiredCapabilities", [])
        if not isinstance(raw_capabilities, list) or len(raw_capabilities) > 8:
            raise CompileError(
                f"{label}.requiredCapabilities must contain at most 8 capabilities"
            )
        required_capabilities: list[str] = []
        capability_seen: set[str] = set()
        for capability_index, value in enumerate(raw_capabilities):
            capability = _validate_id(
                value, f"{label}.requiredCapabilities[{capability_index}]"
            )
            if capability in capability_seen:
                raise CompileError(
                    f"{label}.requiredCapabilities contains duplicate {capability}"
                )
            capability_seen.add(capability)
            required_capabilities.append(capability)

        raw_outputs = raw.get("outputs", {})
        if not isinstance(raw_outputs, dict):
            raise CompileError(f"{label}.outputs must be an object")
        outputs: dict[str, Any] = {}
        speech = raw_outputs.get("speech")
        if speech is not None:
            if not isinstance(speech, dict):
                raise CompileError(f"{label}.outputs.speech must be an object")
            dialogue_act = speech.get("dialogueAct")
            if not isinstance(dialogue_act, str) or not token.fullmatch(dialogue_act):
                raise CompileError(
                    f"{label}.outputs.speech.dialogueAct must be a bounded semantic token"
                )
            outputs["speech"] = {
                "dialogueAct": dialogue_act,
                "contentTemplateID": _validate_id(
                    speech.get("contentTemplateID"),
                    f"{label}.outputs.speech.contentTemplateID",
                ),
            }
        emote = raw_outputs.get("emote")
        if emote is not None:
            if not isinstance(emote, dict):
                raise CompileError(f"{label}.outputs.emote must be an object")
            emote_id = _validate_id(emote.get("id"), f"{label}.outputs.emote.id")
            outputs["emote"] = {"id": emote_id}
        flavor = raw_outputs.get("flavor")
        if flavor is not None:
            if not isinstance(flavor, dict):
                raise CompileError(f"{label}.outputs.flavor must be an object")
            presentation_act = flavor.get("presentationAct", "AMBIENT_FLAVOR")
            if (
                not isinstance(presentation_act, str)
                or not token.fullmatch(presentation_act)
            ):
                raise CompileError(
                    f"{label}.outputs.flavor.presentationAct must be a bounded semantic token"
                )
            outputs["flavor"] = {
                "presentationAct": presentation_act,
                "contentTemplateID": _validate_id(
                    flavor.get("contentTemplateID"),
                    f"{label}.outputs.flavor.contentTemplateID",
                ),
            }
        gameplay = raw_outputs.get("gameplayIntent")
        if gameplay is not None:
            if not isinstance(gameplay, dict):
                raise CompileError(f"{label}.outputs.gameplayIntent must be an object")
            intent_id = _validate_id(
                gameplay.get("id"), f"{label}.outputs.gameplayIntent.id"
            )
            outputs["gameplayIntent"] = {"id": intent_id}
        unsupported_outputs = sorted(
            set(raw_outputs) - {"speech", "emote", "flavor", "gameplayIntent"}
        )
        if unsupported_outputs:
            raise CompileError(
                f"{label}.outputs contains unsupported keys: "
                + ", ".join(unsupported_outputs)
            )

        continuation = raw.get("continuation")
        normalized_continuation: dict[str, Any] | None = None
        if continuation is not None:
            if not isinstance(continuation, dict):
                raise CompileError(f"{label}.continuation must be an object")
            continuation_mode = str(continuation.get("mode") or "")
            if continuation_mode not in ("emit", "wait", "terminate"):
                raise CompileError(
                    f"{label}.continuation.mode must be emit, wait, or terminate"
                )
            continuation_target = str(
                continuation.get("target") or (
                    "none" if continuation_mode == "terminate" else "source"
                )
            )
            if continuation_target not in ("source", "other", "none"):
                raise CompileError(
                    f"{label}.continuation.target must be source, other, or none"
                )
            if continuation_mode == "emit" and continuation_target == "none":
                raise CompileError(
                    f"{label}.continuation emit requires a target"
                )
            continuation_intent = continuation.get("intent")
            if continuation_intent is not None and (
                not isinstance(continuation_intent, str)
                or not token.fullmatch(continuation_intent)
            ):
                raise CompileError(
                    f"{label}.continuation.intent must be a bounded semantic token"
                )
            continuation_speech_act = continuation.get("speechAct")
            if continuation_speech_act is not None and (
                not isinstance(continuation_speech_act, str)
                or not token.fullmatch(continuation_speech_act)
            ):
                raise CompileError(
                    f"{label}.continuation.speechAct must be a bounded semantic token"
                )
            expected_response = continuation.get("expectedResponse")
            if expected_response is not None and (
                not isinstance(expected_response, str)
                or not token.fullmatch(expected_response)
            ):
                raise CompileError(
                    f"{label}.continuation.expectedResponse must be a bounded semantic token"
                )
            normalized_continuation = {
                "mode": continuation_mode,
                "target": continuation_target,
                "inheritFactRefs": continuation.get("inheritFactRefs", True) is not False,
                "inheritEventRefs": continuation.get("inheritEventRefs", True) is not False,
            }
            if continuation_intent is not None:
                normalized_continuation["intent"] = continuation_intent
            if continuation_speech_act is not None:
                normalized_continuation["speechAct"] = continuation_speech_act
            if expected_response is not None:
                normalized_continuation["expectedResponse"] = expected_response

        when = raw.get("when")
        if when is not None:
            when = _validate_director_predicate(when, f"{label}.when")
        relevance = raw.get("baseRelevance", 0.5)
        if (
            isinstance(relevance, bool)
            or not isinstance(relevance, (int, float))
            or not 0 <= relevance <= 1
        ):
            raise CompileError(f"{label}.baseRelevance must be between 0 and 1")
        modifiers = raw.get("modifiers", [])
        if not isinstance(modifiers, list) or len(modifiers) > 16:
            raise CompileError(
                f"{label}.modifiers must be a list of at most 16 entries"
            )
        normalized_modifiers: list[dict[str, Any]] = []
        for modifier_index, modifier in enumerate(modifiers):
            modifier_label = f"{label}.modifiers[{modifier_index}]"
            if not isinstance(modifier, dict):
                raise CompileError(f"{modifier_label} must be an object")
            delta = modifier.get("delta")
            if (
                isinstance(delta, bool)
                or not isinstance(delta, (int, float))
                or not -1 <= delta <= 1
            ):
                raise CompileError(
                    f"{modifier_label}.delta must be between -1 and 1"
                )
            normalized_modifiers.append(
                {
                    "when": _validate_director_predicate(
                        modifier.get("when"), f"{modifier_label}.when"
                    ),
                    "delta": delta,
                    "reason": str(modifier.get("reason") or "")[:96],
                }
            )
        normalize_owner(raw.get("owner"), default=default_owner)
        record = {
            "id": record_id,
            "version": int(raw.get("version", 1)),
            "owner": default_owner,
            "act": act,
            "mode": mode,
            "stimuli": stimuli,
            "requiredCapabilities": required_capabilities,
            "outputs": outputs,
            "when": when,
            "baseRelevance": float(relevance),
            "modifiers": normalized_modifiers,
        }
        if normalized_continuation is not None:
            record["continuation"] = normalized_continuation
        records.append(record)
    return {"records": records}

def _validate_beat_shard(
    document: dict[str, Any],
    path: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    values = document.get("beats")
    if not isinstance(values, list):
        raise CompileError(f"Beat shard {path} requires a beats list")
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    token = re.compile(r"^[A-Z][A-Z0-9_]{0,63}$")
    for index, raw in enumerate(values):
        label = f"{path}.beats[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        if not record_id.startswith("beat."):
            raise CompileError(f"{label}.id must start with beat.")
        if record_id in seen:
            raise CompileError(f"duplicate beat id: {record_id}")
        seen.add(record_id)
        raw_stimuli = raw.get("stimuli")
        if (
            not isinstance(raw_stimuli, list)
            or not raw_stimuli
            or len(raw_stimuli) > 16
        ):
            raise CompileError(
                f"{label}.stimuli must contain 1-16 stimulus tokens"
            )
        stimuli: list[str] = []
        stimulus_seen: set[str] = set()
        for stimulus_index, value in enumerate(raw_stimuli):
            if not isinstance(value, str) or not token.fullmatch(value):
                raise CompileError(
                    f"{label}.stimuli[{stimulus_index}] must be a bounded semantic token"
                )
            if value in stimulus_seen:
                raise CompileError(
                    f"{label}.stimuli contains duplicate {value}"
                )
            stimulus_seen.add(value)
            stimuli.append(value)
        candidates = raw.get("candidates")
        if not isinstance(candidates, list) or not candidates or len(candidates) > 16:
            raise CompileError(f"{label}.candidates must contain 1-16 behaviors")
        normalized_candidates: list[dict[str, Any]] = []
        for candidate_index, candidate in enumerate(candidates):
            candidate_label = f"{label}.candidates[{candidate_index}]"
            if not isinstance(candidate, dict):
                raise CompileError(f"{candidate_label} must be an object")
            behavior = _validate_id(candidate.get("behavior"), f"{candidate_label}.behavior")
            relevance = candidate.get("relevance", 0.5)
            if isinstance(relevance, bool) or not isinstance(relevance, (int, float)) or not 0 <= relevance <= 1:
                raise CompileError(f"{candidate_label}.relevance must be between 0 and 1")
            normalized_candidates.append({"behavior": behavior, "relevance": float(relevance)})
        relevance = raw.get("baseRelevance", 0.5)
        if isinstance(relevance, bool) or not isinstance(relevance, (int, float)) or not 0 <= relevance <= 1:
            raise CompileError(f"{label}.baseRelevance must be between 0 and 1")
        cooldown = raw.get("cooldownTurns", 0)
        max_turns = raw.get("maxTurns", 6)
        for field, value, maximum in (("cooldownTurns", cooldown, 64), ("maxTurns", max_turns, 64)):
            if isinstance(value, bool) or not isinstance(value, int) or value < 0 or value > maximum:
                raise CompileError(f"{label}.{field} must be an integer from 0 to {maximum}")
        normalize_owner(raw.get("owner"), default=default_owner)
        record = {
            "id": record_id,
            "version": int(raw.get("version", 1)),
            "owner": default_owner,
            "stimuli": stimuli,
            "entry": _validate_director_predicate(raw.get("entry"), f"{label}.entry"),
            "maintain": _validate_director_predicate(raw.get("maintain"), f"{label}.maintain"),
            "exit": _validate_director_predicate(raw.get("exit"), f"{label}.exit"),
            "candidates": normalized_candidates,
            "baseRelevance": float(relevance),
            "cooldownTurns": cooldown,
            "maxTurns": max_turns,
        }
        group = raw.get("group")
        if group is not None:
            record["group"] = _validate_id(group, f"{label}.group")
        records.append(record)
    return {"records": records}

def _validate_realization_shard(
    document: dict[str, Any],
    path: str,
) -> dict[str, Any]:
    values = document.get("realizations")
    if not isinstance(values, list):
        raise CompileError(f"Realization shard {path} requires a realizations list")
    records: list[dict[str, Any]] = []

    def validate_tokens(raw_tokens: Any, label: str) -> list[dict[str, Any]]:
        if not isinstance(raw_tokens, list) or not raw_tokens or len(raw_tokens) > 12:
            raise CompileError(f"{label}.tokens must contain 1-12 token objects")
        tokens: list[dict[str, Any]] = []
        for token_index, token in enumerate(raw_tokens):
            token_label = f"{label}.tokens[{token_index}]"
            if not isinstance(token, dict):
                raise CompileError(f"{token_label} must be an object")
            token_kind = str(token.get("kind") or "")
            if token_kind not in {"literal", "lexeme", "slot"}:
                raise CompileError(f"{token_label}.kind is not supported")
            if token_kind == "literal":
                value = token.get("value")
                if not isinstance(value, str) or len(value) > 128:
                    raise CompileError(f"{token_label}.value must be bounded text")
            else:
                slot = token.get("slot")
                if not isinstance(slot, str) or not slot or len(slot) > 64:
                    raise CompileError(f"{token_label}.slot is required")
            tokens.append(_copy_json(token))
        return tokens

    def runtime_construction_id(base_id: str, locale: str, label: str) -> str:
        parts = base_id.split(".")
        if len(parts) < 3 or parts[0] != "construction":
            raise CompileError(
                f"{label}.id must be construction.<domain>.<name> without a locale segment"
            )
        if parts[1].lower() in {"en", "tl"}:
            raise CompileError(f"{label}.id must not contain a locale segment")
        return ".".join((parts[0], locale.lower(), *parts[1:]))

    for index, raw in enumerate(values):
        label = f"{path}.realizations[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        record_id = _validate_id(raw.get("id"), f"{label}.id")
        realization_type = str(raw.get("type") or "")
        if realization_type not in {"lexeme", "construction"}:
            raise CompileError(
                f"{label}.type must be lexeme or construction"
            )
        if realization_type == "lexeme":
            record = _copy_json(raw)
            record["id"] = record_id
            record["type"] = realization_type
            concept = str(raw.get("concept") or "")
            if not concept or len(concept) > 96:
                raise CompileError(f"{label}.concept is required")
            forms = raw.get("forms")
            if not isinstance(forms, dict) or not forms:
                raise CompileError(f"{label}.forms must be a non-empty object")
            if len(forms) > 8:
                raise CompileError(f"{label}.forms exceeds 8 locales")
            for locale, value in forms.items():
                if not isinstance(locale, str) or not locale or len(locale) > 12:
                    raise CompileError(f"{label}.forms locale is invalid")
                if not isinstance(value, str) or not value or len(value) > 96:
                    raise CompileError(
                        f"{label}.forms[{locale}] must be bounded text"
                    )
            records.append(record)
        else:
            strategy = str(raw.get("strategy") or "")
            if not strategy or len(strategy) > 64:
                raise CompileError(f"{label}.strategy is required")
            if "locale" in raw or "tokens" in raw:
                raise CompileError(
                    f"{label} must use one translations map instead of locale/tokens"
                )
            translations = raw.get("translations")
            if not isinstance(translations, dict) or not translations:
                raise CompileError(f"{label}.translations must be a non-empty locale map")
            if len(translations) > 8:
                raise CompileError(f"{label}.translations exceeds 8 locales")
            locales = {str(locale).upper(): tokens for locale, tokens in translations.items()}
            if "EN" not in locales:
                raise CompileError(f"{label}.translations requires EN fallback")
            for locale, raw_tokens in sorted(locales.items()):
                if not re.fullmatch(r"[A-Z][A-Z0-9_-]{0,11}", locale):
                    raise CompileError(f"{label}.translations locale is invalid: {locale}")
                tokens = validate_tokens(raw_tokens, f"{label}.translations[{locale}]")
                record = _copy_json(raw)
                record.pop("translations", None)
                record["id"] = runtime_construction_id(record_id, locale, label)
                record["locale"] = locale
                record["tokens"] = tokens
                record["type"] = realization_type
                records.append(record)
    if len(records) > CONVERSATION_MAX_RECORDS_PER_SHARD:
        raise CompileError(
            f"Realization shard {path} expands above the "
            f"{CONVERSATION_MAX_RECORDS_PER_SHARD}-record hard budget"
        )
    return {"records": records}

def _merge_realization_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for document, entry, _ in shards:
        if entry["kind"] != "realization":
            continue
        for record in document.get("realizations", []):
            records.append({**record, "domain": entry["domain"]})
    records.sort(key=lambda item: item["id"])
    return {"records": records}

def _merge_director_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
    kind: str,
    *,
    default_owner: str,
) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for document, entry, _ in shards:
        if entry["kind"] != kind:
            continue
        source = document.get("source")
        owner = normalize_owner(
            source.get("owner") if isinstance(source, dict) else None,
            default=default_owner,
        )
        compiled = (
            _validate_behavior_shard(
                document,
                entry["path"],
                default_owner=owner,
            )
            if kind == "behaviors"
            else _validate_beat_shard(
                document,
                entry["path"],
                default_owner=owner,
            )
        )
        for record in compiled["records"]:
            records.append({**record, "domain": entry["domain"]})
    records.sort(key=lambda item: item["id"])
    return {"records": records}

