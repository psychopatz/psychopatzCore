"""Shared deterministic translation-locale helpers for CodeBuilder."""

from __future__ import annotations

import json
import re
from typing import Any

from .errors import CompileError


DEFAULT_LANGUAGE = "EN"
_LANGUAGE = re.compile(r"^[A-Z][A-Z0-9_-]{1,15}$")


def normalize_language(value: Any, label: str = "language") -> str:
    if not isinstance(value, str):
        raise CompileError(f"{label} must be a string")
    language = value.strip().upper()
    if not _LANGUAGE.fullmatch(language):
        raise CompileError(f"{label} has invalid locale code: {value!r}")
    return language


def normalize_translations(
    value: Any,
    label: str,
    *,
    require_default: bool = True,
) -> dict[str, str]:
    if not isinstance(value, dict) or not value:
        raise CompileError(f"{label} requires a translation map")
    output: dict[str, str] = {}
    for raw_language, raw_text in value.items():
        language = normalize_language(raw_language, f"{label} language")
        if language in output:
            raise CompileError(f"{label} repeats locale {language}")
        if not isinstance(raw_text, str) or not raw_text.strip():
            raise CompileError(f"{label}.{language} requires non-empty text")
        if any(ord(ch) < 32 and ch not in "\t\n\r" for ch in raw_text):
            raise CompileError(f"{label}.{language} contains a control character")
        output[language] = raw_text.strip()
    if require_default and DEFAULT_LANGUAGE not in output:
        raise CompileError(f"{label} requires {DEFAULT_LANGUAGE} fallback text")
    return {language: output[language] for language in sorted(output)}


def merge_language_sets(*mappings: Any) -> tuple[str, ...]:
    languages: set[str] = set()
    for mapping in mappings:
        if isinstance(mapping, dict):
            for raw_language in mapping:
                try:
                    languages.add(normalize_language(raw_language))
                except CompileError:
                    continue
    if DEFAULT_LANGUAGE in languages:
        return (DEFAULT_LANGUAGE, *sorted(languages - {DEFAULT_LANGUAGE}))
    return tuple(sorted(languages))


def pretty_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ) + "\n"


__all__ = [
    "DEFAULT_LANGUAGE",
    "merge_language_sets",
    "normalize_language",
    "normalize_translations",
    "pretty_json",
]
