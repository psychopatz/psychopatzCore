"""Render package-owned Conversation bundle translation artifacts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

CONVERSATION_BUNDLE_SCHEMA = "psychopatz.semantic.text-bundle.v2"
LOCALES = ("EN", "TL")


def _load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"conversation bundle document must be an object: {path}")
    return value


def write_runtime_bundle_catalogs(
    manifest_path: str | Path,
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

    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    rendered_paths: list[Path] = []

    for language in LOCALES:
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
                text = item.get("text")
                if not isinstance(key, str) or not key:
                    raise ValueError("Conversation bundle keys require string IDs")
                if not isinstance(text, dict):
                    raise ValueError(f"Conversation bundle key {key} requires inline locale text")
                localized = text.get(language)
                if not isinstance(localized, str) or not localized.strip():
                    raise ValueError(f"missing inline {language} text for {key}")
                values[key] = localized

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
