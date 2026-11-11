"""Render package-owned Conversation bundle translation artifacts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .catalog_contract import load_catalog_document


CONVERSATION_BUNDLE_SCHEMA = "psychopatz.semantic.text-bundle.v1"
LOCALES = ("EN", "TL")


def _load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"conversation bundle document must be an object: {path}")
    return value


def write_runtime_bundle_catalogs(
    manifest_path: str | Path,
    authoring_catalog_root: str | Path,
    runtime_translation_root: str | Path,
    *,
    owner: str | None = None,
) -> list[Path]:
    """Render the selected owner's flat bundle catalogs for the game runtime."""

    manifest_file = Path(manifest_path).expanduser().resolve()
    manifest = _load_object(manifest_file)
    if manifest.get("schema") != CONVERSATION_BUNDLE_SCHEMA:
        raise ValueError(f"invalid Conversation bundle manifest: {manifest_file}")
    bundles = manifest.get("bundles")
    if not isinstance(bundles, list):
        raise ValueError(f"Conversation bundle manifest requires bundles: {manifest_file}")

    catalog_root = Path(authoring_catalog_root).expanduser().resolve()
    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    catalogs = {
        language: load_catalog_document(catalog_root / f"{language}.json")
        for language in LOCALES
    }
    rendered_paths: list[Path] = []

    for language in LOCALES:
        entries = catalogs[language].get("entries")
        if not isinstance(entries, dict):
            raise ValueError(f"catalog entries must be an object: {language}")
        for bundle in bundles:
            if not isinstance(bundle, dict):
                raise ValueError("Conversation bundle declarations must be objects")
            if owner is not None and bundle.get("owner") != owner:
                continue
            values: dict[str, str] = {}
            for item in bundle.get("keys", []):
                if not isinstance(item, dict):
                    raise ValueError("Conversation bundle key declarations must be objects")
                key = item.get("key")
                translation_key = item.get("translationKey")
                entry = entries.get(translation_key)
                if not isinstance(key, str) or not isinstance(translation_key, str):
                    raise ValueError("Conversation bundle keys require string IDs")
                if not isinstance(entry, dict) or not isinstance(entry.get("text"), str):
                    raise ValueError(f"missing catalog entry for {translation_key}")
                values[key] = entry["text"]

            runtime_path = bundle.get("runtimePath")
            if not isinstance(runtime_path, str) or not runtime_path.startswith(
                "Conversation/Bundles/"
            ):
                raise ValueError(
                    f"Conversation bundle runtimePath must be under "
                    f"Conversation/Bundles/: {runtime_path!r}"
                )
            path = runtime_root / language / Path(*runtime_path.split("/"))
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(values, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            rendered_paths.append(path)
    return rendered_paths
