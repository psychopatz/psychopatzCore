"""Render package-owned Conversation text catalog artifacts."""

from __future__ import annotations

import json
from pathlib import Path, PurePosixPath
from typing import Any

CONVERSATION_TEXT_MANIFEST_SCHEMA = "psychopatz.semantic.text-source.manifest.v1"
CONVERSATION_TEXT_SOURCE_SCHEMA = "psychopatz.semantic.text-source.v1"
LOCALES = ("EN", "TL")


def _load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"conversation text document must be an object: {path}")
    return value


def _relative_path(value: Any, *, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"Conversation text {field} must be a non-empty path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        raise ValueError(f"Conversation text {field} must be a relative path: {value!r}")
    return path.as_posix()


def _load_catalogs(manifest_path: Path) -> list[dict[str, Any]]:
    manifest = _load_object(manifest_path)
    if manifest.get("schema") != CONVERSATION_TEXT_MANIFEST_SCHEMA:
        raise ValueError(f"invalid Conversation text manifest: {manifest_path}")
    if manifest.get("sourceSchema") != CONVERSATION_TEXT_SOURCE_SCHEMA:
        raise ValueError(f"invalid Conversation text source contract: {manifest_path}")
    declarations = manifest.get("sources")
    if not isinstance(declarations, list) or not declarations:
        raise ValueError(
            f"Conversation text manifest requires non-empty sources: {manifest_path}"
        )

    catalogs: list[dict[str, Any]] = []
    seen_paths: set[str] = set()
    seen_catalog_ids: set[str] = set()
    for index, declaration in enumerate(declarations):
        if not isinstance(declaration, dict):
            raise ValueError(f"Conversation text source {index} must be an object")
        relative = _relative_path(declaration.get("path"), field=f"sources[{index}].path")
        if relative in seen_paths:
            raise ValueError(f"duplicate Conversation text source path: {relative}")
        seen_paths.add(relative)
        source_path = manifest_path.parent / Path(*PurePosixPath(relative).parts)
        if not source_path.is_file():
            raise ValueError(f"Conversation text source is missing: {relative}")
        source = _load_object(source_path)
        if source.get("schema") != CONVERSATION_TEXT_SOURCE_SCHEMA:
            raise ValueError(f"invalid Conversation text source: {source_path}")
        if source.get("sourceId") != declaration.get("sourceId"):
            raise ValueError(f"Conversation text source ID mismatch: {source_path}")
        if source.get("owner") != declaration.get("owner"):
            raise ValueError(f"Conversation text source owner mismatch: {source_path}")
        source_catalogs = source.get("catalogs")
        if not isinstance(source_catalogs, list) or not source_catalogs:
            raise ValueError(f"Conversation text source requires catalogs: {source_path}")
        for catalog in source_catalogs:
            if not isinstance(catalog, dict):
                raise ValueError(f"Conversation text catalogs must be objects: {source_path}")
            catalog_id = catalog.get("catalogId")
            if not isinstance(catalog_id, str) or not catalog_id:
                raise ValueError(f"Conversation text requires catalogId: {source_path}")
            if catalog_id in seen_catalog_ids:
                raise ValueError(f"duplicate Conversation text catalog ID: {catalog_id}")
            seen_catalog_ids.add(catalog_id)
            if catalog.get("owner") != source.get("owner"):
                raise ValueError(f"Conversation text catalog owner mismatch: {catalog_id}")
            catalogs.append(catalog)
    return catalogs


def write_runtime_text_catalogs(
    manifest_path: str | Path,
    runtime_translation_root: str | Path,
    *,
    owner: str | None = None,
) -> list[Path]:
    """Render selected owners' focused text catalogs into flat runtime JSON."""

    catalogs = _load_catalogs(Path(manifest_path).expanduser().resolve())
    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    grouped: dict[str, list[dict[str, Any]]] = {}
    keys_by_runtime: dict[str, set[str]] = {}
    for catalog in catalogs:
        if owner is not None and catalog.get("owner") != owner:
            continue
        entries = catalog.get("entries")
        if not isinstance(entries, list):
            raise ValueError(f"Conversation text requires entries: {catalog['catalogId']}")
        runtime_path = catalog.get("runtimePath")
        if not isinstance(runtime_path, str) or not runtime_path.startswith(
            "Conversation/Text/"
        ):
            raise ValueError(
                "Conversation text runtimePath must be under "
                f"Conversation/Text/: {runtime_path!r}"
            )
        relative_runtime_path = _relative_path(runtime_path, field="runtimePath")
        grouped.setdefault(relative_runtime_path, []).append(catalog)
        seen_keys = keys_by_runtime.setdefault(relative_runtime_path, set())
        for item in entries:
            if not isinstance(item, dict):
                raise ValueError("Conversation text entries must be objects")
            key = item.get("key")
            text = item.get("text")
            if not isinstance(key, str) or not key:
                raise ValueError("Conversation text entry requires a string ID")
            if key in seen_keys:
                raise ValueError(
                    f"duplicate Conversation text key in {relative_runtime_path}: {key}"
                )
            if not isinstance(text, dict):
                raise ValueError(f"Conversation text entry {key} requires inline locale text")
            for language in LOCALES:
                localized = text.get(language)
                if not isinstance(localized, str) or not localized.strip():
                    raise ValueError(f"missing {language} text for Conversation text key: {key}")
            seen_keys.add(key)

    rendered_paths: list[Path] = []
    for language in LOCALES:
        for relative_runtime_path in sorted(grouped):
            values: dict[str, str] = {}
            for catalog in grouped[relative_runtime_path]:
                for item in catalog["entries"]:
                    key = item["key"]
                    localized = item["text"][language]
                    values[key] = localized
            path = runtime_root / language / Path(*PurePosixPath(relative_runtime_path).parts)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(values, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            rendered_paths.append(path)
    return rendered_paths
