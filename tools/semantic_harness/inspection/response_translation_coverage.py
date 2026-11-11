"""Bounded manifest provenance for *loaded Lua* response keys.

This is static source readiness, not an independent translator and not proof
that any untranslated/unobserved variant was selected in a runtime turn.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.codebuilder.translation_support import DEFAULT_LANGUAGE, normalize_language

MAX_MANIFEST_ASSETS = 64
MAX_TRANSLATION_ASSET_BYTES = 256 * 1024
MAX_CONVERSATION_MANIFEST_BYTES = 64 * 1024


def translation_coverage(
    worker: LuaSemanticWorker,
    pool_id: str,
    *,
    repository: Path | None = None,
) -> dict[str, Any]:
    root = (repository or worker.config.repository).resolve(strict=True)
    detail = worker.response_pool_detail(pool_id, limit=16)
    if detail.get("hasMore"):
        raise ValueError("translation coverage requires fully bounded pool")
    media = root / "Contents/mods/ProjectHoomans/common/media/translation"
    manifest_path = media / "manifests/Conversation.json"
    if manifest_path.stat().st_size > MAX_CONVERSATION_MANIFEST_BYTES:
        raise ValueError("oversized production Conversation manifest")
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes.decode("utf-8"))
    raw_languages = manifest.get("languages") if isinstance(manifest, dict) else None
    if not isinstance(raw_languages, dict) or not raw_languages:
        raise ValueError("invalid production Conversation manifest")

    normalized_languages: dict[str, list[str]] = {}
    for raw_language, paths in raw_languages.items():
        language = normalize_language(raw_language, "Conversation manifest language")
        if language in normalized_languages:
            raise ValueError("duplicate normalized Conversation manifest language")
        if not isinstance(paths, list) or len(paths) > MAX_MANIFEST_ASSETS:
            raise ValueError("missing or unbounded translation manifest language")
        normalized_languages[language] = paths
    if DEFAULT_LANGUAGE not in normalized_languages:
        raise ValueError(
            f"Conversation manifest requires {DEFAULT_LANGUAGE} fallback language"
        )
    languages = (
        DEFAULT_LANGUAGE,
        *sorted(set(normalized_languages) - {DEFAULT_LANGUAGE}),
    )

    index: dict[str, dict[str, list[str]]] = {
        language: {} for language in languages
    }
    for language in languages:
        for name in normalized_languages[language]:
            if (not isinstance(name, str)
                    or not name.startswith(language + "/")
                    or not name.endswith(".json")
                    or ".." in name):
                raise ValueError("invalid translation manifest path")
            asset_path = (media / name).resolve(strict=True)
            if not asset_path.is_relative_to(media.resolve()):
                raise ValueError("translation manifest escapes media owner")
            if asset_path.stat().st_size > MAX_TRANSLATION_ASSET_BYTES:
                raise ValueError("oversized manifest-backed translation catalog")
            contents = json.loads(asset_path.read_text(encoding="utf-8"))
            if not isinstance(contents, dict):
                raise ValueError("invalid manifest-backed translation catalog")
            for key, text in contents.items():
                if not isinstance(key, str) or not isinstance(text, str):
                    raise ValueError("translation catalog contains non-text entry")
                index[language].setdefault(key, []).append(name)

    rows = []
    counts = {
        "ALL_MANIFESTED": 0,
        "PARTIAL_MANIFESTED": 0,
        "NOT_IN_CONVERSATION_MANIFEST": 0,
        "DUPLICATE_MANIFEST_KEY": 0,
    }
    for variant in detail["variants"]:
        key = variant.get("templateID")
        paths = {
            language: index[language].get(key, []) if isinstance(key, str) else []
            for language in languages
        }
        if any(len(paths[language]) > 1 for language in languages):
            status = "DUPLICATE_MANIFEST_KEY"
        elif all(paths[language] for language in languages):
            status = "ALL_MANIFESTED"
        elif any(paths[language] for language in languages):
            status = "PARTIAL_MANIFESTED"
        else:
            status = "NOT_IN_CONVERSATION_MANIFEST"
        counts[status] += 1
        rows.append({
            "variantID": variant["id"],
            "templateID": key,
            "sourceKind": variant.get("sourceKind", "UNKNOWN"),
            "status": status,
            "manifestAssets": paths,
            "missingLocales": [
                language for language in languages if not paths[language]
            ],
            "actualRuntimeLookupObserved": False,
            "fallbackEvidence": "UNTESTED",
        })
    return {
        "ok": True,
        "type": "response_translation_manifest_coverage",
        "schemaVersion": 2,
        "poolID": pool_id,
        "sourceKind": "CANONICAL_MANIFEST_STATIC",
        "languages": list(languages),
        "manifestSHA256": hashlib.sha256(manifest_bytes).hexdigest(),
        "contentFingerprint": detail["contentFingerprint"],
        "registryRevision": detail["registryRevision"],
        "variantCount": len(rows),
        "summary": counts,
        "variants": rows,
        "limitations": [
            "Manifest membership is not a runtime translation lookup",
            "A templateID may intentionally use fallback or nonmanifested keys",
            "Runtime localized text and fallback must be established by Lua replay",
        ],
        "writes": 0,
    }
