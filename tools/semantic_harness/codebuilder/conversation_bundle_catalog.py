"""Render package-owned Conversation bundle translation artifacts."""

from __future__ import annotations

import json
from pathlib import Path, PurePosixPath
from typing import Any

CONVERSATION_BUNDLE_MANIFEST_SCHEMA = "psychopatz.semantic.text-bundle.manifest.v1"
CONVERSATION_BUNDLE_SHARD_SCHEMA = "psychopatz.semantic.text-bundle.shard.v1"
LOCALES = ("EN", "TL")


def _load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"conversation bundle document must be an object: {path}")
    return value


def _relative_path(value: Any, *, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"Conversation bundle {field} must be a non-empty path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        raise ValueError(f"Conversation bundle {field} must be a relative path: {value!r}")
    return path.as_posix()


def _load_bundles(manifest_path: Path) -> list[dict[str, Any]]:
    manifest = _load_object(manifest_path)
    if manifest.get("schema") != CONVERSATION_BUNDLE_MANIFEST_SCHEMA:
        raise ValueError(f"invalid Conversation bundle manifest: {manifest_path}")
    if manifest.get("bundleSchema") != CONVERSATION_BUNDLE_SHARD_SCHEMA:
        raise ValueError(f"invalid Conversation bundle shard contract: {manifest_path}")
    declarations = manifest.get("shards")
    if not isinstance(declarations, list) or not declarations:
        raise ValueError(
            f"Conversation bundle manifest requires non-empty shards: {manifest_path}"
        )

    bundles: list[dict[str, Any]] = []
    seen_paths: set[str] = set()
    seen_bundle_ids: set[str] = set()
    for index, declaration in enumerate(declarations):
        if not isinstance(declaration, dict):
            raise ValueError(f"Conversation bundle shard {index} must be an object")
        relative = _relative_path(declaration.get("path"), field=f"shards[{index}].path")
        if relative in seen_paths:
            raise ValueError(f"duplicate Conversation bundle shard path: {relative}")
        seen_paths.add(relative)
        shard_path = manifest_path.parent / Path(*PurePosixPath(relative).parts)
        if not shard_path.is_file():
            raise ValueError(f"Conversation bundle shard is missing: {relative}")
        shard = _load_object(shard_path)
        if shard.get("schema") != CONVERSATION_BUNDLE_SHARD_SCHEMA:
            raise ValueError(f"invalid Conversation bundle shard: {shard_path}")
        if shard.get("shardId") != declaration.get("shardId"):
            raise ValueError(f"Conversation bundle shard ID mismatch: {shard_path}")
        if shard.get("owner") != declaration.get("owner"):
            raise ValueError(f"Conversation bundle shard owner mismatch: {shard_path}")
        shard_bundles = shard.get("bundles")
        if not isinstance(shard_bundles, list) or not shard_bundles:
            raise ValueError(f"Conversation bundle shard requires bundles: {shard_path}")
        for bundle in shard_bundles:
            if not isinstance(bundle, dict):
                raise ValueError(f"Conversation bundle declarations must be objects: {shard_path}")
            bundle_id = bundle.get("bundleId")
            if not isinstance(bundle_id, str) or not bundle_id:
                raise ValueError(f"Conversation bundle requires bundleId: {shard_path}")
            if bundle_id in seen_bundle_ids:
                raise ValueError(f"duplicate Conversation bundle ID: {bundle_id}")
            seen_bundle_ids.add(bundle_id)
            if bundle.get("owner") != shard.get("owner"):
                raise ValueError(f"Conversation bundle owner mismatch: {bundle_id}")
            bundles.append(bundle)
    return bundles


def write_runtime_bundle_catalogs(
    manifest_path: str | Path,
    runtime_translation_root: str | Path,
    *,
    owner: str | None = None,
) -> list[Path]:
    """Render selected owner's flat bundle catalogs for the game runtime."""

    bundles = _load_bundles(Path(manifest_path).expanduser().resolve())
    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    rendered_paths: list[Path] = []
    for language in LOCALES:
        for bundle in bundles:
            if owner is not None and bundle.get("owner") != owner:
                continue
            values: dict[str, str] = {}
            keys = bundle.get("keys")
            if not isinstance(keys, list):
                raise ValueError(f"Conversation bundle requires keys: {bundle['bundleId']}")
            for item in keys:
                if not isinstance(item, dict):
                    raise ValueError("Conversation bundle key declarations must be objects")
                key = item.get("key")
                text = item.get("text")
                if not isinstance(key, str) or not key:
                    raise ValueError("Conversation bundle key requires a string ID")
                if key in values:
                    raise ValueError(f"duplicate Conversation bundle key: {key}")
                if not isinstance(text, dict):
                    raise ValueError(f"Conversation bundle key {key} requires inline locale text")
                localized = text.get(language)
                if not isinstance(localized, str) or not localized.strip():
                    raise ValueError(f"missing {language} text for Conversation bundle key: {key}")
                values[key] = localized
            runtime_path = bundle.get("runtimePath")
            if not isinstance(runtime_path, str) or not runtime_path.startswith(
                "Conversation/Bundles/"
            ):
                raise ValueError(
                    "Conversation bundle runtimePath must be under "
                    f"Conversation/Bundles/: {runtime_path!r}"
                )
            relative_runtime_path = _relative_path(runtime_path, field="runtimePath")
            path = runtime_root / language / Path(*PurePosixPath(relative_runtime_path).parts)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(values, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            rendered_paths.append(path)
    return rendered_paths
