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


def _output_path_for_target(value: Any, *, catalog_id: str) -> str:
    """Validate a semantic target and map it to its runtime JSON path."""

    target = _relative_path(value, field="target")
    if target.endswith(".json"):
        raise ValueError(
            f"Conversation text target must omit the .json extension: {catalog_id}"
        )
    forbidden = {"basic", "default", "shared"}
    if any(part in forbidden for part in PurePosixPath(target).parts):
        raise ValueError(
            "Conversation text target contains a generic segment "
            f"({target!r}); use a semantic catalog name: {catalog_id}"
        )
    return f"Conversation/Text/{target}.json"


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
    clean: bool = True,
) -> list[Path]:
    """Render selected owners' focused text catalogs into flat runtime JSON.

    ``clean`` is disabled for secondary catalog manifests that share the
    package translation tree with the primary Conversation text manifest.
    Those manifests may add their own generated files without deleting the
    primary dialogue catalogs.
    """

    catalogs = _load_catalogs(Path(manifest_path).expanduser().resolve())
    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    grouped: dict[str, list[dict[str, Any]]] = {}
    keys_by_output: dict[str, set[str]] = {}
    for catalog in catalogs:
        if owner is not None and catalog.get("owner") != owner:
            continue
        entries = catalog.get("entries")
        if not isinstance(entries, list):
            raise ValueError(f"Conversation text requires entries: {catalog['catalogId']}")
        if "runtimePath" in catalog:
            raise ValueError(
                "Conversation text catalogs use semantic target, not runtimePath: "
                f"{catalog['catalogId']}"
            )
        relative_output_path = _output_path_for_target(
            catalog.get("target"), catalog_id=catalog["catalogId"]
        )
        grouped.setdefault(relative_output_path, []).append(catalog)
        seen_keys = keys_by_output.setdefault(relative_output_path, set())
        for item in entries:
            if not isinstance(item, dict):
                raise ValueError("Conversation text entries must be objects")
            key = item.get("key")
            text = item.get("text")
            if not isinstance(key, str) or not key:
                raise ValueError("Conversation text entry requires a string ID")
            if key in seen_keys:
                raise ValueError(
                    f"duplicate Conversation text key in {relative_output_path}: {key}"
                )
            if not isinstance(text, dict):
                raise ValueError(f"Conversation text entry {key} requires inline locale text")
            for language in LOCALES:
                localized = text.get(language)
                if not isinstance(localized, str) or not localized.strip():
                    raise ValueError(f"missing {language} text for Conversation text key: {key}")
            seen_keys.add(key)

    if clean:
        desired_outputs = set(grouped)
        for language in LOCALES:
            language_root = runtime_root / language
            text_root = language_root / "Conversation" / "Text"
            if not text_root.is_dir():
                continue
            for path in sorted(text_root.rglob("*.json")):
                relative = path.relative_to(language_root).as_posix()
                if relative not in desired_outputs:
                    path.unlink()
            for directory in sorted(text_root.rglob("*"), reverse=True):
                if directory.is_dir():
                    try:
                        directory.rmdir()
                    except OSError:
                        pass

    rendered_paths: list[Path] = []
    for language in LOCALES:
        for relative_output_path in sorted(grouped):
            values: dict[str, str] = {}
            for catalog in grouped[relative_output_path]:
                for item in catalog["entries"]:
                    key = item["key"]
                    localized = item["text"][language]
                    values[key] = localized
            path = runtime_root / language / Path(*PurePosixPath(relative_output_path).parts)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(values, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            rendered_paths.append(path)
    return rendered_paths
