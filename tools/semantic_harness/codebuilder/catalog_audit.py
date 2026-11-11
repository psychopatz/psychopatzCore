"""Read-only audit for the shared Conversation source catalog.

This module intentionally reports the current authoring shape without trying
to read it through a compatibility layer or rewriting any source. It is the
P0 inventory seam for the v2 shard and locale-catalog migration.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Iterable, Mapping


PREFERRED_SOURCE_BYTES = 64 * 1024
HARD_SOURCE_BYTES = 128 * 1024
LOCALE_CATALOG_DIRECTORY = "translations"


def _issue(
    code: str,
    message: str,
    *,
    path: str | None = None,
    severity: str = "warning",
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


def _walk(value: Any, path: str = "$") -> Iterable[tuple[str, Any]]:
    yield path, value
    if isinstance(value, Mapping):
        for key, child in value.items():
            yield from _walk(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from _walk(child, f"{path}[{index}]")


def _is_source_metadata(value: Any) -> bool:
    if not isinstance(value, Mapping):
        return False
    metadata_keys = {"name", "owner", "version", "license", "references"}
    return len(metadata_keys.intersection(value)) >= 2


def _manifest_entries(manifest: Mapping[str, Any]) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for field in ("shards", "externalShards"):
        raw_entries = manifest.get(field, [])
        if not isinstance(raw_entries, list):
            continue
        for index, raw in enumerate(raw_entries):
            if isinstance(raw, Mapping):
                entry = dict(raw)
                entry["_manifestField"] = field
                entry["_manifestIndex"] = index
                entries.append(entry)
    return entries


def _manifest_path_set(manifest: Mapping[str, Any]) -> set[str]:
    paths: set[str] = set()
    for entry in _manifest_entries(manifest):
        path = entry.get("path")
        if isinstance(path, str):
            paths.add(path)
    roots = manifest.get("sourceRoots", [])
    if isinstance(roots, list):
        for entry in roots:
            if isinstance(entry, Mapping) and isinstance(entry.get("path"), str):
                paths.add(f"{entry['path']}/**/*.json")
    return paths


def _relative_json_files(root: Path, manifest_path: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*.json")
        if path.is_file()
        and path.resolve() != manifest_path.resolve()
        and LOCALE_CATALOG_DIRECTORY not in path.relative_to(root).parts
    )


def audit_conversation_sources(
    root: str | Path,
    *,
    manifest_path: str | Path | None = None,
    preferred_source_bytes: int = PREFERRED_SOURCE_BYTES,
    hard_source_bytes: int = HARD_SOURCE_BYTES,
) -> dict[str, Any]:
    """Return a deterministic structural report without changing the tree."""

    source_root = Path(root).expanduser().resolve()
    manifest_file = Path(manifest_path or source_root / "manifest.json").resolve()
    issues: list[dict[str, Any]] = []
    if not source_root.is_dir():
        return {
            "schema": "psychopatz.semantic.catalog.audit.v1",
            "root": str(source_root),
            "files": [],
            "summary": {"sourceJsonCount": 0},
            "issues": [
                _issue(
                    "missing_root",
                    "Conversation source root does not exist",
                    path=str(source_root),
                    severity="error",
                )
            ],
        }
    if not manifest_file.is_file():
        issues.append(
            _issue(
                "missing_manifest",
                "Conversation source manifest does not exist",
                path=str(manifest_file),
                severity="error",
            )
        )
        manifest: dict[str, Any] = {}
    else:
        try:
            loaded = json.loads(manifest_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            loaded = {}
            issues.append(
                _issue(
                    "invalid_manifest",
                    f"Conversation source manifest cannot be read: {error}",
                    path=str(manifest_file),
                    severity="error",
                )
            )
        manifest = loaded if isinstance(loaded, dict) else {}

    if manifest.get("defaultOwner"):
        issues.append(
            _issue(
                "implicit_default_owner",
                "Manifest defaultOwner allows shards to omit package ownership",
                path="manifest.json",
                details={"defaultOwner": manifest["defaultOwner"]},
            )
        )
    for entry in _manifest_entries(manifest):
        if entry.get("_manifestField") == "shards" and not entry.get("owner"):
            issues.append(
                _issue(
                    "implicit_shard_owner",
                    "Manifest shard does not declare an explicit owner",
                    path=str(entry.get("path", "")),
                    details={"manifestIndex": entry.get("_manifestIndex")},
                )
            )
        if entry.get("kind") == "responses":
            path = str(entry.get("path", ""))
            if not path.startswith("responses/"):
                issues.append(
                    _issue(
                        "kind_path_mismatch",
                        "Response-kind shard is stored outside the responses path",
                        path=path,
                        details={"kind": entry.get("kind")},
                    )
                )

    files: list[dict[str, Any]] = []
    stem_paths: dict[str, list[str]] = {}
    inline_translation_files = 0
    repeated_metadata_files = 0
    preferred_oversize = 0
    hard_oversize = 0
    for path in _relative_json_files(source_root, manifest_file):
        relative = path.relative_to(source_root).as_posix()
        size = path.stat().st_size
        stem_paths.setdefault(path.stem, []).append(relative)
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(
                _issue(
                    "invalid_json",
                    f"Conversation source JSON cannot be read: {error}",
                    path=relative,
                    severity="error",
                )
            )
            files.append({"path": relative, "bytes": size, "validJson": False})
            continue

        translation_locations = [
            location for location, value in _walk(document)
            if location.rsplit(".", 1)[-1] == "translations"
            and isinstance(value, Mapping)
        ]
        metadata_locations = [
            location for location, value in _walk(document)
            if _is_source_metadata(value)
        ]
        if translation_locations:
            inline_translation_files += 1
            issues.append(
                _issue(
                    "inline_translations",
                    "Semantic shard embeds locale wording instead of referencing a locale catalog",
                    path=relative,
                    details={"locations": translation_locations},
                )
            )
        if metadata_locations:
            repeated_metadata_files += 1
            issues.append(
                _issue(
                    "repeated_source_metadata",
                    "Semantic shard repeats source metadata that belongs in the manifest/index",
                    path=relative,
                    details={"locations": metadata_locations},
                )
            )
        if size > hard_source_bytes:
            hard_oversize += 1
            issues.append(
                _issue(
                    "source_size_hard_limit",
                    "Semantic source shard exceeds the hard size limit",
                    path=relative,
                    severity="error",
                    details={"bytes": size, "limit": hard_source_bytes},
                )
            )
        elif size > preferred_source_bytes:
            preferred_oversize += 1
            issues.append(
                _issue(
                    "source_size_preferred_limit",
                    "Semantic source shard exceeds the preferred size limit",
                    path=relative,
                    details={"bytes": size, "limit": preferred_source_bytes},
                )
            )
        files.append(
            {
                "path": relative,
                "bytes": size,
                "validJson": True,
                "inlineTranslationLocations": translation_locations,
                "sourceMetadataLocations": metadata_locations,
            }
        )

    for stem, paths in sorted(stem_paths.items()):
        if len(paths) > 1:
            issues.append(
                _issue(
                    "duplicate_filename_stem",
                    "Multiple semantic shards share the same filename stem",
                    details={"stem": stem, "paths": paths},
                )
            )

    locale_root = source_root / LOCALE_CATALOG_DIRECTORY
    locale_files = (
        sorted(path.relative_to(source_root).as_posix() for path in locale_root.glob("*.json"))
        if locale_root.is_dir()
        else []
    )
    if not locale_files:
        issues.append(
            _issue(
                "missing_locale_catalogs",
                "CodeBuilder has no one-file-per-locale authoring catalog",
                path=f"{LOCALE_CATALOG_DIRECTORY}/",
            )
        )

    issues.sort(key=lambda item: (item.get("severity", ""), item["code"], item.get("path", "")))
    return {
        "schema": "psychopatz.semantic.catalog.audit.v1",
        "root": str(source_root),
        "manifest": str(manifest_file),
        "manifestPaths": sorted(_manifest_path_set(manifest)),
        "localeCatalogs": locale_files,
        "files": files,
        "summary": {
            "sourceJsonCount": len(files),
            "inlineTranslationFileCount": inline_translation_files,
            "repeatedMetadataFileCount": repeated_metadata_files,
            "preferredOversizeCount": preferred_oversize,
            "hardOversizeCount": hard_oversize,
            "issueCount": len(issues),
        },
        "issues": issues,
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--strict", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    options = _parser().parse_args(argv)
    report = audit_conversation_sources(options.root, manifest_path=options.manifest)
    print(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True))
    if options.strict and any(item["severity"] == "error" for item in report["issues"]):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
