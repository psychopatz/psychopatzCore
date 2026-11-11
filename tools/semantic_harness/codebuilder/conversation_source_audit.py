"""Read-only audit for the shared self-contained Conversation source.

This module reports the authoring shape without rewriting source. Locale text
is expected to live beside its recipe records; generated runtime catalogs are
owned by package build outputs and are outside this source audit.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Iterable, Mapping


PREFERRED_SOURCE_BYTES = 64 * 1024
HARD_SOURCE_BYTES = 128 * 1024
AUTHORING_LOCALE_DIRECTORY = "translations"
LEGACY_SOURCE_FIELDS = frozenset({
    "phraseID", "translationKey", "labelTranslations", "choiceTranslations",
    "labelKey", "utteranceKey",
})
LOCALE_SPLIT_STEM = re.compile(r"(?:_|\.)(?:en|tl)$", re.IGNORECASE)


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
    # Record-level owner/version fields are valid runtime metadata for
    # behaviors, beats, and semantic flows. Source provenance has a stronger
    # signature: a name/license/reference/content-license field that would be
    # better represented by manifest.sourceProfiles.
    source_signature_keys = {
        "name", "license", "references", "contentLicense",
        "sourceVersion", "sourceSha256",
    }
    return bool(source_signature_keys.intersection(value))


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
        and AUTHORING_LOCALE_DIRECTORY not in path.relative_to(root).parts
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

    manifest_entries = _manifest_entries(manifest)
    source_roots = manifest.get("sourceRoots", [])
    if isinstance(source_roots, list):
        manifest_entries.extend(
            dict(entry)
            for entry in source_roots
            if isinstance(entry, Mapping)
        )
    if manifest.get("defaultOwner") and any(not entry.get("owner") for entry in manifest_entries):
        issues.append(
            _issue(
                "implicit_default_owner",
                "Manifest defaultOwner allows shards to omit package ownership",
                path="manifest.json",
                details={"defaultOwner": manifest["defaultOwner"]},
            )
        )
    for entry in manifest_entries:
        if not entry.get("owner"):
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
    inline_locale_field_files = 0
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
        locale_field_locations = [
            location for location, value in _walk(document)
            if location.rsplit(".", 1)[-1] in {"translations", "display", "label", "choice"}
            and isinstance(value, Mapping)
        ]
        legacy_field_locations = [
            location for location, _value in _walk(document)
            if location.rsplit(".", 1)[-1] in LEGACY_SOURCE_FIELDS
        ]
        metadata_locations = [
            location for location, value in _walk(document)
            if _is_source_metadata(value)
        ]
        if locale_field_locations:
            inline_locale_field_files += 1
        if legacy_field_locations:
            inline_translation_files += 1
            issues.append(
                _issue(
                    "legacy_source_fields",
                    "Semantic shard contains removed identity/catalog fields",
                    path=relative,
                    severity="error",
                    details={"locations": legacy_field_locations},
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
                "inlineLocaleFieldLocations": locale_field_locations,
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
        if LOCALE_SPLIT_STEM.search(stem):
            issues.append(
                _issue(
                    "locale_split_filename",
                    "Locale-suffixed source shards must be combined into one self-contained recipe",
                    details={"stem": stem, "paths": paths},
                    severity="error",
                )
            )

    locale_root = source_root / AUTHORING_LOCALE_DIRECTORY
    locale_files = (
        sorted(path.relative_to(source_root).as_posix() for path in locale_root.glob("*.json"))
        if locale_root.is_dir()
        else []
    )
    if locale_files:
        issues.append(
            _issue(
                "authoring_locale_catalogs_present",
                "Authoring locale catalogs are not part of the self-contained source contract",
                path=f"{AUTHORING_LOCALE_DIRECTORY}/",
                severity="error",
                details={"files": locale_files},
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
            "inlineLocaleFieldFileCount": inline_locale_field_files,
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
