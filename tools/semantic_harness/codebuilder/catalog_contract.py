"""Strict contracts for v2 semantic shards and locale catalogs.

The current Conversation sources are intentionally not accepted by these
validators. They are legacy inputs that P0 audits and P1 converts. Keeping the
new contract strict prevents the migration from reproducing the old inline
translation and implicit-ownership problems.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Mapping


SHARD_SCHEMA = "psychopatz.semantic.shard.v2"
TRANSLATION_SCHEMA = "psychopatz.semantic.translation.v1"
DEFAULT_LANGUAGE = "EN"
VALID_KINDS = frozenset({
    "content", "patterns", "responses", "flows", "behaviors", "beats",
    "realization", "packs", "ui",
})
PAYLOAD_FIELDS = {
    "content": ("phraseFamilies", "playerChoices"),
    "patterns": ("patterns",),
    "responses": ("responsePools",),
    "flows": ("definitions",),
    "behaviors": ("behaviors",),
    "beats": ("beats",),
    "realization": ("realizations",),
    "packs": ("packs",),
    "ui": ("suggestions",),
}
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
PACK_ID_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_.:-]{0,127}$")
LOCALE_PATTERN = re.compile(r"^[A-Z][A-Z0-9_-]{1,15}$")
TRANSLATION_KEY_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_.:-]{0,191}$")
PLACEHOLDER_PATTERN = re.compile(r"%(?:\d+|[sd])|\{[A-Za-z][A-Za-z0-9_.-]*\}")


class CatalogContractError(ValueError):
    """Raised when a catalog file cannot be parsed deterministically."""


def _issue(
    code: str,
    message: str,
    *,
    path: str | None = None,
    severity: str = "error",
    details: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "code": code,
        "message": message,
        "severity": severity,
    }
    if path is not None:
        result["path"] = path
    if details:
        result["details"] = dict(details)
    return result


def _duplicate_rejecting_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise CatalogContractError(f"duplicate JSON object key: {key}")
        result[key] = value
    return result


def load_catalog_document(path: str | Path) -> dict[str, Any]:
    """Load one catalog and reject duplicate JSON keys."""

    catalog_path = Path(path).expanduser().resolve()
    try:
        value = json.loads(
            catalog_path.read_text(encoding="utf-8"),
            object_pairs_hook=_duplicate_rejecting_object,
        )
    except (OSError, UnicodeError, json.JSONDecodeError, CatalogContractError) as error:
        raise CatalogContractError(f"cannot load catalog {catalog_path}: {error}") from error
    if not isinstance(value, dict):
        raise CatalogContractError(f"catalog {catalog_path} must contain a JSON object")
    return value


def load_locale_catalogs(
    root: str | Path,
    *,
    required: bool = False,
) -> dict[str, dict[str, str]]:
    """Load validated locale catalogs as language-to-key-to-text maps."""

    catalog_root = Path(root).expanduser().resolve()
    paths = sorted(catalog_root.glob("*.json")) if catalog_root.is_dir() else []
    if not paths:
        if required:
            raise CatalogContractError(f"no locale catalogs found under {catalog_root}")
        return {}
    documents = {path.stem: load_catalog_document(path) for path in paths}
    issues = validate_locale_set(documents)
    if issues:
        summary = "; ".join(
            f"{item['code']}:{item.get('path', '')}" for item in issues[:8]
        )
        raise CatalogContractError(f"invalid locale catalogs: {summary}")
    return {
        language: {
            str(key): str(entry["text"])
            for key, entry in document["entries"].items()
        }
        for language, document in sorted(documents.items())
    }


def _is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _walk(value: Any, path: str = "$") -> list[tuple[str, Any]]:
    found = [(path, value)]
    if isinstance(value, Mapping):
        for key, child in value.items():
            found.extend(_walk(child, f"{path}.{key}"))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(_walk(child, f"{path}[{index}]"))
    return found


def _validate_identity(
    value: Any,
    label: str,
    *,
    pattern: re.Pattern[str] = ID_PATTERN,
) -> bool:
    return isinstance(value, str) and bool(pattern.fullmatch(value))


def validate_shard(
    document: Mapping[str, Any],
    *,
    path: str = "<shard>",
    allowed_owners: set[str] | frozenset[str] | None = None,
) -> list[dict[str, Any]]:
    """Validate one strict v2 semantic shard and return ordered diagnostics."""

    issues: list[dict[str, Any]] = []
    if not isinstance(document, Mapping):
        return [_issue("shard_not_object", "Semantic shard must be an object", path=path)]
    if document.get("schema") != SHARD_SCHEMA:
        issues.append(_issue("shard_schema", f"Semantic shard schema must be {SHARD_SCHEMA}", path=path))
    shard_id = document.get("shardId")
    kind = document.get("kind")
    domain = document.get("domain")
    owner = document.get("owner")
    if not _validate_identity(shard_id, "shardId"):
        issues.append(_issue("shard_id", "shardId must be a bounded semantic ID", path=path))
    if not isinstance(kind, str) or kind not in VALID_KINDS:
        issues.append(_issue("shard_kind", "kind is not a supported semantic kind", path=path))
    if not _validate_identity(domain, "domain"):
        issues.append(_issue("shard_domain", "domain must be a bounded semantic ID", path=path))
    if _validate_identity(shard_id, "shardId") and isinstance(kind, str) and _validate_identity(domain, "domain"):
        expected_prefix = f"conversation.{kind}."
        if not shard_id.startswith(expected_prefix):
            issues.append(_issue(
                "shard_identity",
                "shardId must use the kind-qualified conversation namespace",
                path=path,
                details={"expectedPrefix": expected_prefix, "actual": shard_id},
            ))
    if not _is_non_empty_string(owner):
        issues.append(_issue("shard_owner", "owner is required and cannot be implicit", path=path))
    elif allowed_owners is not None and owner not in allowed_owners:
        issues.append(_issue(
            "shard_owner_unknown",
            "owner is not registered in the active composition",
            path=path,
            details={"owner": owner},
        ))
    source_profile = document.get("sourceProfile")
    if not _validate_identity(source_profile, "sourceProfile"):
        issues.append(_issue("shard_source_profile", "sourceProfile is required", path=path))
    payload_fields = PAYLOAD_FIELDS.get(kind, ()) if isinstance(kind, str) else ()
    if "records" in document:
        payload_fields = (*payload_fields, "records")
    present_payloads = [field for field in payload_fields if field in document]
    if not present_payloads:
        issues.append(_issue("shard_payload", "typed shard payload is missing", path=path))
    for payload_field in present_payloads:
        records = document.get(payload_field)
        if not isinstance(records, list):
            issues.append(_issue("shard_payload", f"{payload_field} must be a list", path=f"{path}.{payload_field}"))
            continue
        seen_ids: set[str] = set()
        for index, record in enumerate(records):
            record_path = f"{path}.{payload_field}[{index}]"
            if not isinstance(record, Mapping):
                issues.append(_issue("record_not_object", "record must be an object", path=record_path))
                continue
            record_id_key = (
                "semanticTemplateID"
                if kind == "content" and payload_field == "phraseFamilies"
                else "id"
            )
            record_id = record.get(record_id_key)
            record_pattern = PACK_ID_PATTERN if kind == "packs" else ID_PATTERN
            if not _validate_identity(record_id, record_id_key, pattern=record_pattern):
                issues.append(_issue("record_id", f"{record_id_key} must be a bounded semantic ID", path=record_path))
            elif record_id in seen_ids:
                issues.append(_issue("record_id_duplicate", "record.id is duplicated within the shard", path=record_path, details={"id": record_id}))
            else:
                seen_ids.add(record_id)
            translation_key = record.get("translationKey")
            if translation_key is not None and not _validate_identity(translation_key, "translationKey", pattern=TRANSLATION_KEY_PATTERN):
                issues.append(_issue("translation_key", "translationKey has an invalid format", path=record_path))

    for location, value in _walk(document):
        if location == "$.translations" or location.endswith(".translations"):
            issues.append(_issue(
                "inline_translations_forbidden",
                "v2 semantic shards must reference locale catalogs instead of embedding translations",
                path=f"{path}{location[1:]}",
            ))
        if location == "$.source" or location.endswith(".source"):
            if isinstance(value, Mapping):
                issues.append(_issue(
                    "inline_source_metadata_forbidden",
                    "generator/source metadata belongs in the manifest or provenance index",
                    path=f"{path}{location[1:]}",
                ))
    return sorted(issues, key=lambda item: (item.get("path", ""), item["code"]))


def validate_translation_catalog(
    document: Mapping[str, Any],
    *,
    path: str = "<translation-catalog>",
) -> list[dict[str, Any]]:
    """Validate one complete locale catalog."""

    issues: list[dict[str, Any]] = []
    if not isinstance(document, Mapping):
        return [_issue("translation_not_object", "Translation catalog must be an object", path=path)]
    if document.get("schema") != TRANSLATION_SCHEMA:
        issues.append(_issue("translation_schema", f"Translation catalog schema must be {TRANSLATION_SCHEMA}", path=path))
    language = document.get("language")
    if not isinstance(language, str) or not LOCALE_PATTERN.fullmatch(language):
        issues.append(_issue("translation_language", "language must be an uppercase locale code", path=path))
    if document.get("fallback") != DEFAULT_LANGUAGE:
        issues.append(_issue("translation_fallback", "fallback must be EN", path=path))
    entries = document.get("entries")
    if not isinstance(entries, Mapping):
        issues.append(_issue("translation_entries", "entries must be an object", path=path))
        return issues
    for key, entry in sorted(entries.items(), key=lambda item: str(item[0])):
        entry_path = f"{path}.entries.{key}"
        if not isinstance(key, str) or not TRANSLATION_KEY_PATTERN.fullmatch(key):
            issues.append(_issue("translation_key", "translation entry key has an invalid format", path=entry_path))
        if not isinstance(entry, Mapping):
            issues.append(_issue("translation_entry", "translation entry must be an object", path=entry_path))
            continue
        if not _is_non_empty_string(entry.get("text")):
            issues.append(_issue("translation_text", "translation entry text is required", path=entry_path))
        source_shard = entry.get("sourceShard")
        if not _is_non_empty_string(source_shard):
            issues.append(_issue("translation_source_shard", "translation entry sourceShard is required", path=entry_path))
        elif not _validate_identity(source_shard, "sourceShard"):
            issues.append(_issue("translation_source_shard", "translation entry sourceShard has an invalid format", path=entry_path))
    return sorted(issues, key=lambda item: (item.get("path", ""), item["code"]))


def _placeholders(text: str) -> tuple[str, ...]:
    # A translation may repeat an argument for natural phrasing. Validation
    # must ensure every argument remains available, not forbid repetition.
    return tuple(sorted(set(PLACEHOLDER_PATTERN.findall(text))))


def validate_locale_set(
    catalogs: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    """Validate locale files as a complete, comparable set."""

    issues: list[dict[str, Any]] = []
    for language, catalog in sorted(catalogs.items()):
        issues.extend(validate_translation_catalog(catalog, path=f"translations/{language}.json"))
    english = catalogs.get(DEFAULT_LANGUAGE)
    if english is None:
        issues.append(_issue("missing_english_catalog", "EN.json is mandatory", path="translations/EN.json"))
        return sorted(issues, key=lambda item: (item.get("path", ""), item["code"]))
    english_entries = english.get("entries", {}) if isinstance(english, Mapping) else {}
    if not isinstance(english_entries, Mapping):
        return sorted(issues, key=lambda item: (item.get("path", ""), item["code"]))
    english_keys = set(english_entries)
    english_placeholders = {
        key: _placeholders(str(value.get("text", "")))
        for key, value in english_entries.items()
        if isinstance(value, Mapping)
    }
    for language, catalog in sorted(catalogs.items()):
        if language == DEFAULT_LANGUAGE:
            continue
        entries = catalog.get("entries", {}) if isinstance(catalog, Mapping) else {}
        if not isinstance(entries, Mapping):
            continue
        keys = set(entries)
        missing = sorted(english_keys - keys)
        extra = sorted(keys - english_keys)
        if missing:
            issues.append(_issue("locale_missing_keys", "locale is missing EN translation keys", path=f"translations/{language}.json", details={"keys": missing}))
        if extra:
            issues.append(_issue("locale_extra_keys", "locale contains keys absent from EN", path=f"translations/{language}.json", details={"keys": extra}))
        for key in sorted(english_keys & keys):
            english_value = english_placeholders.get(key, ())
            localized_value = entries[key]
            if isinstance(localized_value, Mapping):
                localized_placeholders = _placeholders(str(localized_value.get("text", "")))
                if localized_placeholders != english_value:
                    issues.append(_issue(
                        "locale_placeholder_mismatch",
                        "locale placeholders must match EN",
                        path=f"translations/{language}.json.entries.{key}",
                        details={"EN": english_value, language: localized_placeholders},
                    ))
    return sorted(issues, key=lambda item: (item.get("path", ""), item["code"]))


__all__ = [
    "CatalogContractError",
    "DEFAULT_LANGUAGE",
    "SHARD_SCHEMA",
    "TRANSLATION_SCHEMA",
    "VALID_KINDS",
    "load_catalog_document",
    "load_locale_catalogs",
    "validate_locale_set",
    "validate_shard",
    "validate_translation_catalog",
]
