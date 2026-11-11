"""Authoring and generated-key contract for Conversation UI shards.

UI recipes keep their localized display text beside the semantic record.  The
compiler owns the runtime localization keys so authors never have to maintain
parallel key catalogs or copy generated identifiers into source JSON.
"""

from __future__ import annotations

import re
from typing import Any, Mapping

from .catalog_naming import pascal_segment
from .conversation_manifest import validate_id
from .conversation_model import copy_json
from .errors import CompileError
from .translation_support import DEFAULT_LANGUAGE, normalize_language


UI_NAMESPACE_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_]{0,95}$")


def _require_namespace(value: Any, label: str) -> str:
    if not isinstance(value, str) or not UI_NAMESPACE_PATTERN.fullmatch(value):
        raise CompileError(
            f"{label} must be a bounded runtime UI namespace"
        )
    return value


def _pascal_id_parts(value: str) -> str:
    return "_".join(pascal_segment(part) for part in value.split("."))


def suggestion_text_keys(
    namespace: str,
    suggestion_id: str,
) -> tuple[str, str]:
    """Derive label and utterance keys from a suggestion identity.

    The first ID segment is the authored suggestion category (for example,
    ``question`` or ``gossip``), so it is intentionally omitted from the
    generated display suffix.  This keeps the source ID concise while
    preserving the established runtime key shape.
    """

    parts = suggestion_id.split(".")
    suffix = "".join(pascal_segment(part) for part in (parts[1:] or parts))
    return (
        f"{namespace}_{suffix}_Label",
        f"{namespace}_{suffix}_Utterance",
    )


def text_key(namespace: str, text_id: str) -> str:
    """Derive one runtime localization key for a UI text recipe."""

    return f"{namespace}_{_pascal_id_parts(text_id)}"


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a non-empty string")
    value = value.strip()
    if len(value) > 256:
        raise CompileError(f"{label} exceeds the 256-character limit")
    if any(ord(character) < 32 for character in value):
        raise CompileError(f"{label} contains a control character")
    return value


def _display_map(value: Any, label: str, *, fields: tuple[str, ...]) -> dict[str, dict[str, str]]:
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} requires a locale display map")
    normalized: dict[str, dict[str, str]] = {}
    for raw_language, raw_values in value.items():
        language = normalize_language(raw_language, f"{label} locale")
        if not isinstance(raw_values, Mapping):
            raise CompileError(f"{label}.{language} must be an object")
        values: dict[str, str] = {}
        for field in fields:
            if field not in raw_values:
                raise CompileError(f"{label}.{language} requires {field}")
            values[field] = _text(raw_values[field], f"{label}.{language}.{field}")
        normalized[language] = values
    if DEFAULT_LANGUAGE not in normalized:
        raise CompileError(f"{label} requires {DEFAULT_LANGUAGE} fallback text")
    return {
        language: normalized[language]
        for language in sorted(normalized)
    }


def _text_map(value: Any, label: str) -> dict[str, str]:
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} requires a locale text map")
    normalized: dict[str, str] = {}
    for raw_language, raw_text in value.items():
        language = normalize_language(raw_language, f"{label} locale")
        normalized[language] = _text(raw_text, f"{label}.{language}")
    if DEFAULT_LANGUAGE not in normalized:
        raise CompileError(f"{label} requires {DEFAULT_LANGUAGE} fallback text")
    return {language: normalized[language] for language in sorted(normalized)}


def validate_ui_shard(document: Mapping[str, Any], path: str) -> dict[str, list[dict[str, Any]]]:
    """Validate and compile authoring-only UI records into runtime-shaped rows."""

    namespace = _require_namespace(
        document.get("textNamespace"),
        f"UI shard {path}.textNamespace",
    )
    suggestions = document.get("suggestions", [])
    texts = document.get("texts", [])
    if not isinstance(suggestions, list):
        raise CompileError(f"UI shard {path} suggestions must be a list")
    if not isinstance(texts, list):
        raise CompileError(f"UI shard {path} texts must be a list")
    if len(suggestions) + len(texts) > 32:
        raise CompileError(f"UI shard {path} exceeds the 32-record hard budget")

    seen: set[str] = set()
    compiled_suggestions: list[dict[str, Any]] = []
    for index, raw in enumerate(suggestions):
        label = f"{path}.suggestions[{index}]"
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        suggestion_id = validate_id(raw.get("id"), f"{label}.id")
        if suggestion_id in seen:
            raise CompileError(f"duplicate UI record id: {suggestion_id}")
        seen.add(suggestion_id)
        for field in ("topic", "patternID"):
            if not isinstance(raw.get(field), str) or not raw[field].strip():
                raise CompileError(f"{label} requires {field}")
        forbidden = {"labelKey", "utteranceKey", "labelFallback", "utteranceFallback", "translations"}
        present_forbidden = forbidden.intersection(raw)
        if present_forbidden:
            raise CompileError(
                f"{label} uses generated or legacy fields: "
                + ", ".join(sorted(present_forbidden))
            )
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int):
            raise CompileError(f"{label}.order must be an integer")
        display = _display_map(raw.get("display"), f"{label}.display", fields=("label", "utterance"))
        label_key, utterance_key = suggestion_text_keys(namespace, suggestion_id)
        compiled = copy_json(dict(raw))
        compiled.pop("translations", None)
        compiled["display"] = display
        compiled["labelKey"] = label_key
        compiled["utteranceKey"] = utterance_key
        compiled["labelFallback"] = display[DEFAULT_LANGUAGE]["label"]
        compiled["utteranceFallback"] = display[DEFAULT_LANGUAGE]["utterance"]
        compiled_suggestions.append(compiled)

    compiled_texts: list[dict[str, Any]] = []
    for index, raw in enumerate(texts):
        label = f"{path}.texts[{index}]"
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label} must be an object")
        text_id = validate_id(raw.get("id"), f"{label}.id")
        if text_id in seen:
            raise CompileError(f"duplicate UI record id: {text_id}")
        seen.add(text_id)
        forbidden = {"key", "fallback", "translations"}.intersection(raw)
        if forbidden:
            raise CompileError(
                f"{label} uses generated or legacy fields: "
                + ", ".join(sorted(forbidden))
            )
        display = _text_map(raw.get("display"), f"{label}.display")
        compiled = copy_json(dict(raw))
        compiled.pop("translations", None)
        compiled["display"] = display
        compiled["key"] = text_key(namespace, text_id)
        compiled["fallback"] = display[DEFAULT_LANGUAGE]
        compiled_texts.append(compiled)

    return {"suggestions": compiled_suggestions, "texts": compiled_texts}


__all__ = [
    "suggestion_text_keys",
    "text_key",
    "validate_ui_shard",
]
