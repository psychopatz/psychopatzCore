"""Bounded Dialogue Content Registry compiler and artifact renderer.

The response catalog remains the owner of semantic/context variants and
SpeechRealization remains the owner of style selection.  This module owns the
small post-style phrase layer and the player-facing, verified content records
that Studio is allowed to edit.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from typing import Any

from tools.semantic_harness.codebuilder.catalog_naming import ModuleNameRegistry, source_owned_module
from .lexicon_compiler import CompileError, _lua_string
from tools.semantic_harness.codebuilder.translation_support import DEFAULT_LANGUAGE, normalize_translations


CONTENT_SCHEMA = "pnc.semantic_dialogue_content.v2"
STYLES = ("neutral", "warm", "terse", "guarded", "bond_neutral", "bond_warm", "bond_terse", "bond_guarded")
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
TRANSLATION_KEY_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,127}$")
MAX_FAMILIES = 512
MAX_PHRASES_PER_STYLE = 16
MAX_PLAYER_CONTENT = 32
MAX_TEXT = 256
CONVERSATION_CONTENT_MAX_SHARD_BYTES = 192 * 1024
CONVERSATION_CONTENT_MAX_FAMILIES_PER_SHARD = 32


def _canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def content_fingerprint(document: dict[str, Any]) -> str:
    return hashlib.sha256(_canonical_json(document).encode("utf-8")).hexdigest()


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a non-empty string")
    value = value.strip()
    if len(value) > MAX_TEXT:
        raise CompileError(f"{label} exceeds the {MAX_TEXT}-character limit")
    if any(ord(char) < 32 for char in value):
        raise CompileError(f"{label} contains a control character")
    return value


def _id(value: Any, label: str) -> str:
    value = _text(value, label)
    if not ID_PATTERN.fullmatch(value):
        raise CompileError(f"{label} has an invalid bounded ID: {value!r}")
    return value


def _translation_key(value: Any, label: str) -> str:
    value = _text(value, label)
    if not TRANSLATION_KEY_PATTERN.fullmatch(value):
        raise CompileError(f"{label} has an invalid translation key: {value!r}")
    return value


def _translations(value: Any, label: str) -> dict[str, str]:
    """Validate one locale map; EN is the only required fallback locale."""
    return normalize_translations(value, label)


def _metadata(value: Any) -> dict[str, str]:
    if not isinstance(value, dict):
        raise CompileError("dialogue content source requires source metadata")
    return {
        "name": _text(value.get("name"), "source.name"),
        "version": _text(value.get("version"), "source.version"),
        "contentLicense": _text(value.get("contentLicense"), "source.contentLicense"),
    }


def derived_canonical_concept(semantic_id: str) -> str:
    pieces = [piece for piece in re.split(r"[^A-Za-z0-9]+", semantic_id) if piece]
    return "_".join(piece.upper() for piece in pieces)


def _derived_translation_prefix(semantic_id: str) -> str:
    pieces = [piece for piece in re.split(r"[^A-Za-z0-9]+", semantic_id) if piece]
    return "UI_PNC_Conversation_Content_" + "".join(
        piece[:1].upper() + piece[1:] for piece in pieces
    )


def _phrase_family(
    value: Any,
    groups: dict[str, Any],
    phrase_ids: set[str],
    translation_keys: set[str],
) -> tuple[dict[str, Any], dict[str, str]]:
    if not isinstance(value, dict):
        raise CompileError("phraseFamilies entries must be objects")
    semantic_id = _id(value.get("semanticTemplateID"), "semanticTemplateID")
    group = _id(value.get("group"), f"{semantic_id}.group")
    group_metadata = groups.get(group)
    if not isinstance(group_metadata, dict):
        raise CompileError(f"{semantic_id}.group is not declared: {group}")
    family_id = "phrase." + semantic_id
    concept = derived_canonical_concept(semantic_id)
    prefix = _derived_translation_prefix(semantic_id)
    styles = value.get("styles")
    if not isinstance(styles, dict) or not styles:
        raise CompileError(f"{family_id}.styles requires at least one style")
    unsupported_styles = set(styles) - set(STYLES)
    if unsupported_styles:
        raise CompileError(
            f"{family_id}.styles contains unsupported styles: "
            + ", ".join(sorted(unsupported_styles))
        )

    compiled_styles: dict[str, list[dict[str, str]]] = {}
    translations: dict[str, str] = {}
    for style in STYLES:
        raw_phrases = styles.get(style)
        if raw_phrases is None:
            continue
        if not isinstance(raw_phrases, list) or not raw_phrases:
            raise CompileError(f"{family_id}.styles.{style} requires 1..{MAX_PHRASES_PER_STYLE} phrases")
        if len(raw_phrases) > MAX_PHRASES_PER_STYLE:
            raise CompileError(f"{family_id}.styles.{style} exceeds the phrase bound")
        compiled_phrases: list[dict[str, str]] = []
        for index, raw_phrase in enumerate(raw_phrases, 1):
            if not isinstance(raw_phrase, dict):
                raise CompileError(f"{family_id}.styles.{style}[{index}] must be an object")
            phrase_id = f"{family_id}.{style}.{index:02d}"
            if phrase_id in phrase_ids:
                raise CompileError(f"duplicate phrase id: {phrase_id}")
            phrase_ids.add(phrase_id)
            style_suffix = "".join(
                piece[:1].upper() + piece[1:]
                for piece in style.split("_")
            )
            key = f"{prefix}{style_suffix}{index:02d}"
            if key in translation_keys:
                raise CompileError(f"duplicate generated translation key: {key}")
            translation_keys.add(key)
            values = _translations(
                raw_phrase.get("translations"), f"{phrase_id}.translations"
            )
            compiled_phrases.append({
                "id": phrase_id,
                "key": key,
                # Keep the authored English fallback beside the key so a
                # missing/late translation never exposes a key to players.
                "fallback": values[DEFAULT_LANGUAGE],
            })
            translations.update({f"{key}:{language}": text for language, text in values.items()})
        compiled_styles[style] = compiled_phrases

    if not compiled_styles:
        raise CompileError(f"{family_id} has no compiled style phrases")
    content_owner = _text(
        group_metadata.get("contentOwner"), f"groups.{group}.contentOwner"
    )
    return {
        "id": family_id,
        "semanticTemplateID": semantic_id,
        "canonicalConcept": concept,
        "group": group,
        "styles": compiled_styles,
        "contentOwner": content_owner,
    }, translations


def _player_content(
    value: Any,
    translation_keys: set[str],
) -> tuple[dict[str, Any], dict[str, str]]:
    if not isinstance(value, dict):
        raise CompileError("playerChoices entries must be objects")
    content_id = _id(value.get("id"), "player choice id")
    kind = _text(value.get("kind"), f"{content_id}.kind")
    label_key = "UI_PNC_Conversation_Content_" + "".join(
        piece[:1].upper() + piece[1:]
        for piece in re.split(r"[^A-Za-z0-9]+", content_id) if piece
    ) + "_Label"
    choice_key = label_key[:-6] + "Choice"
    if label_key == choice_key or label_key in translation_keys or choice_key in translation_keys:
        raise CompileError(f"duplicate player-content translation key: {content_id}")
    translation_keys.update((label_key, choice_key))
    label_values = _translations(value.get("labelTranslations"), f"{content_id}.labelTranslations")
    choice_values = _translations(value.get("choiceTranslations"), f"{content_id}.choiceTranslations")
    translations: dict[str, str] = {}
    for language in sorted(set(label_values) | set(choice_values)):
        if language in label_values:
            translations[f"{label_key}:{language}"] = label_values[language]
        if language in choice_values:
            translations[f"{choice_key}:{language}"] = choice_values[language]
    return {
        "id": content_id,
        "kind": kind,
        "labelKey": label_key,
        "choiceKey": choice_key,
        "route": _text(value.get("route"), f"{content_id}.route"),
        "hubID": _text(value.get("hubID"), f"{content_id}.hubID"),
        "canonicalConcept": derived_canonical_concept(content_id),
    }, translations


def compile_dialogue_content(document: dict[str, Any]) -> dict[str, Any]:
    """Validate and compile content without producing any files."""
    if not isinstance(document, dict):
        raise CompileError("dialogue content source root must be an object")
    if document.get("schemaVersion") != 2:
        raise CompileError("dialogue content source schemaVersion must be 2")
    source = _metadata(document.get("source"))
    groups = document.get("groups")
    if not isinstance(groups, dict) or not groups:
        raise CompileError("dialogue content source requires groups")
    raw_families = document.get("phraseFamilies")
    if not isinstance(raw_families, list) or not raw_families:
        raise CompileError("dialogue content source requires phraseFamilies")
    if len(raw_families) > MAX_FAMILIES:
        raise CompileError(f"dialogue content source exceeds {MAX_FAMILIES} phrase families")
    raw_player = document.get("playerChoices", [])
    if not isinstance(raw_player, list) or len(raw_player) > MAX_PLAYER_CONTENT:
        raise CompileError(f"playerChoices must contain at most {MAX_PLAYER_CONTENT} records")

    family_ids: set[str] = set()
    semantic_ids: set[str] = set()
    player_ids: set[str] = set()
    phrase_ids: set[str] = set()
    translation_keys: set[str] = set()
    compiled_families: list[dict[str, Any]] = []
    translations_by_language: dict[str, dict[str, str]] = {}
    for raw_family in raw_families:
        family, values = _phrase_family(
            raw_family, groups, phrase_ids, translation_keys
        )
        if family["id"] in family_ids:
            raise CompileError(f"duplicate phrase family id: {family['id']}")
        if family["semanticTemplateID"] in semantic_ids:
            raise CompileError(f"duplicate phrase semanticTemplateID: {family['semanticTemplateID']}")
        family_ids.add(family["id"])
        semantic_ids.add(family["semanticTemplateID"])
        compiled_families.append(family)
        for compound_key, text in values.items():
            key, language = compound_key.rsplit(":", 1)
            translations_by_language.setdefault(language, {})[key] = text

    compiled_player: list[dict[str, Any]] = []
    for raw_choice in raw_player:
        choice, values = _player_content(raw_choice, translation_keys)
        if choice["id"] in player_ids:
            raise CompileError(f"duplicate player choice id: {choice['id']}")
        player_ids.add(choice["id"])
        compiled_player.append(choice)
        for compound_key, text in values.items():
            key, language = compound_key.rsplit(":", 1)
            translations_by_language.setdefault(language, {})[key] = text

    # Translation output is deliberately a flat string map.  Arrays here
    # would turn equivalent wording into a different runtime contract.
    for language, values in translations_by_language.items():
        if any(not isinstance(value, str) for value in values.values()):
            raise CompileError(f"{language} content translations must be ordinary strings")

    compiled = {
        "schema": CONTENT_SCHEMA,
        "schemaVersion": 2,
        "source": source,
        "phraseFamilies": compiled_families,
        "playerChoices": compiled_player,
        "translations": translations_by_language,
    }
    compiled["contentFingerprint"] = content_fingerprint(document)
    return compiled


def _lua_value(value: Any, indent: int = 0) -> str:
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return _lua_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise CompileError("cannot render non-finite dialogue content number")
        return format(value, ".15g")
    if isinstance(value, list):
        lines = ["{"]
        for item in value:
            lines.append(" " * (indent + 4) + _lua_value(item, indent + 4) + ",")
        lines.append(" " * indent + "}")
        return "\n".join(lines)
    if isinstance(value, dict):
        lines = ["{"]
        for key in sorted(value):
            lines.append(
                " " * (indent + 4)
                + f"[{_lua_string(str(key))}] = "
                + _lua_value(value[key], indent + 4)
                + ","
            )
        lines.append(" " * indent + "}")
        return "\n".join(lines)
    raise CompileError(f"cannot render dialogue content value {type(value).__name__}")


def _runtime_family(family: dict[str, Any]) -> dict[str, Any]:
    """Strip compiler provenance before a family enters a runtime shard."""
    return {
        "id": family["id"],
        "semanticTemplateID": family["semanticTemplateID"],
        "canonicalConcept": family["canonicalConcept"],
        "contentOwner": family.get("contentOwner"),
        "styles": family["styles"],
    }


def _content_shard_source(families: list[dict[str, Any]]) -> str:
    payload = {
        family["semanticTemplateID"]: _runtime_family(family)
        for family in sorted(families, key=lambda item: item["semanticTemplateID"])
    }
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(payload, 0) + "\n"
    )


def render_dialogue_content_shard_plan(
    compiled: dict[str, Any],
    module_prefix: str,
    *,
    max_bytes: int = CONVERSATION_CONTENT_MAX_SHARD_BYTES,
    max_families: int = CONVERSATION_CONTENT_MAX_FAMILIES_PER_SHARD,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render one bounded generated content shard per canonical source owner."""
    grouped: dict[str, list[dict[str, Any]]] = {}
    for family in compiled.get("phraseFamilies", []):
        source_shard = str(
            family.get("sourceShard")
            or f"content/{family.get('conversationDomain') or family.get('group') or 'general'}.json"
        )
        grouped.setdefault(source_shard, []).append(family)

    modules: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    names = ModuleNameRegistry()
    for source_shard in sorted(grouped):
        families = sorted(
            grouped[source_shard],
            key=lambda item: item["semanticTemplateID"],
        )
        if len(families) > max_families:
            raise CompileError(
                "canonical Conversation content source exceeds the generated "
                f"{max_families}-family hard budget; split by semantic subdomain: "
                f"{source_shard}"
            )
        source = _content_shard_source(families)
        size = len(source.encode("utf-8"))
        if size > max_bytes:
            raise CompileError(
                "canonical Conversation content source renders above the "
                f"{max_bytes}-byte hard shard budget; split by semantic subdomain: "
                f"{source_shard}"
            )
        module = source_owned_module(
            f"{module_prefix}/Content",
            source_shard,
            names,
        )
        modules.append((module, source))
        reports.append({
            "module": module,
            "kind": "Content",
            "domain": str(
                families[0].get("conversationDomain")
                or families[0].get("group")
                or "general"
            ),
            "sourceShard": source_shard,
            "recordCount": len(families),
            "recordIDs": [
                "phrase." + family["semanticTemplateID"]
                for family in families
            ],
            "bytes": size,
        })

    choices = compiled.get("playerChoices", [])
    if choices:
        payload = {
            choice["id"]: {
                key: value for key, value in choice.items()
                if key not in ("conversationDomain", "sourceShard")
            }
            for choice in sorted(choices, key=lambda item: item["id"])
        }
        source = (
            "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
            "return " + _lua_value(payload, 0) + "\n"
        )
        size = len(source.encode("utf-8"))
        if size > max_bytes:
            raise CompileError(
                "generated Conversation player-choice shard exceeds its byte bound"
            )
        module = f"{module_prefix}/Content/PlayerChoices"
        modules.append((module, source))
        reports.append({
            "module": module,
            "kind": "ContentChoices",
            "domain": "greeting",
            "sourceShard": str(
                choices[0].get("sourceShard") or "content/greeting.json"
            ),
            "recordCount": len(choices),
            "recordIDs": [
                choice["id"]
                for choice in sorted(choices, key=lambda item: item["id"])
            ],
            "bytes": size,
        })
    return modules, reports
