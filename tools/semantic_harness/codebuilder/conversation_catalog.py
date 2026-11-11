"""Locale catalog hydration for Conversation semantic sources."""

from __future__ import annotations

from typing import Any, Mapping

from .dialogue_content import phrase_translation_key, player_translation_keys
from .errors import CompileError
from .translation_support import DEFAULT_LANGUAGE


def _catalog_values(
    catalogs: Mapping[str, Mapping[str, str]],
    key: Any,
) -> dict[str, str]:
    if not isinstance(key, str) or not key:
        return {}
    return {
        language: values[key]
        for language, values in sorted(catalogs.items())
        if key in values
    }

def _required_catalog_values(
    catalogs: Mapping[str, Mapping[str, str]],
    key: Any,
    label: str,
) -> dict[str, str]:
    values = _catalog_values(catalogs, key)
    if not values or DEFAULT_LANGUAGE not in values:
        raise CompileError(f"{label} requires a canonical EN catalog entry")
    return values

def _reject_inline_translations(document: Any, path: str) -> None:
    if isinstance(document, dict):
        for key, value in document.items():
            if key in {
                "translations", "labelTranslations", "choiceTranslations",
                "fallback", "labelFallback", "utteranceFallback",
            }:
                raise CompileError(
                    f"Conversation shard {path} contains inline locale field {key}; use translations/<LANG>.json"
                )
            _reject_inline_translations(value, path)
    elif isinstance(document, list):
        for value in document:
            _reject_inline_translations(value, path)

def _hydrate_catalog_translations(
    document: dict[str, Any],
    entry: Mapping[str, Any],
    catalogs: Mapping[str, Mapping[str, str]],
) -> None:
    """Hydrate typed compiler input from the canonical locale catalogs."""

    _reject_inline_translations(document, str(entry.get("path", "<shard>")))
    if not catalogs:
        return
    kind = entry.get("kind")
    if kind == "content":
        for family in document.get("phraseFamilies", []):
            if not isinstance(family, dict):
                continue
            semantic_id = family.get("semanticTemplateID")
            for style, phrases in (family.get("styles") or {}).items():
                if not isinstance(phrases, list):
                    continue
                for index, phrase in enumerate(phrases, 1):
                    if not isinstance(phrase, dict):
                        continue
                    key = phrase_translation_key(str(semantic_id), str(style), index)
                    phrase["translations"] = _required_catalog_values(
                        catalogs,
                        key,
                        f"{entry.get('path')}.{key}",
                    )
        for choice in document.get("playerChoices", []):
            if not isinstance(choice, dict) or not isinstance(choice.get("id"), str):
                continue
            label_key, choice_key = player_translation_keys(choice["id"])
            choice["labelTranslations"] = _required_catalog_values(
                catalogs,
                label_key,
                f"{entry.get('path')}.{label_key}",
            )
            choice["choiceTranslations"] = _required_catalog_values(
                catalogs,
                choice_key,
                f"{entry.get('path')}.{choice_key}",
            )
    if kind == "ui":
        for suggestion in document.get("suggestions", []):
            if not isinstance(suggestion, dict):
                continue
            localized_catalogs = {language: {} for language in sorted(catalogs)}
            for field, key in (
                ("label", suggestion.get("labelKey")),
                ("utterance", suggestion.get("utteranceKey")),
            ):
                values = _required_catalog_values(
                    catalogs,
                    key,
                    f"{entry.get('path')}.{key}",
                )
                for language, text in values.items():
                    localized_catalogs[language][field] = text
            suggestion["translations"] = localized_catalogs
            suggestion["labelFallback"] = localized_catalogs[DEFAULT_LANGUAGE]["label"]
            suggestion["utteranceFallback"] = localized_catalogs[DEFAULT_LANGUAGE]["utterance"]

    def walk(value: Any) -> None:
        if isinstance(value, dict):
            template_id = value.get("templateID")
            translation_id = template_id
            if translation_id is None:
                candidate = value.get("key")
                if isinstance(candidate, str) and candidate.startswith("UI_PNC_"):
                    translation_id = candidate
            values = _catalog_values(catalogs, translation_id)
            if values:
                value["translations"] = values
                value["fallback"] = values[DEFAULT_LANGUAGE]
            for child in value.values():
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)

    walk(document)

