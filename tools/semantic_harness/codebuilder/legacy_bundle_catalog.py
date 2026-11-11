"""Migrate PNC's legacy flat conversation bundles into Core catalogs."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .catalog_contract import (
    TRANSLATION_SCHEMA,
    load_catalog_document,
)


LEGACY_BUNDLE_SCHEMA = "psychopatz.semantic.text-bundle.v1"
OWNER = "ProjectHoomans"
LOCALES = ("EN", "TL")


def _slug(value: str) -> str:
    result = re.sub(r"[^A-Za-z0-9]+", ".", value).strip(".")
    return result.lower() or "bundle"


def _load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"legacy bundle must be an object: {path}")
    return value


def _bundle_id(relative_path: str, namespace: str) -> str:
    return namespace + "." + _slug(relative_path.removesuffix(".json"))


def discover_legacy_bundles(
    legacy_root: str | Path,
    *,
    owner: str = OWNER,
    mod_id: str = OWNER,
    namespace: str = "conversation.legacy",
) -> tuple[list[dict[str, Any]], dict[str, dict[str, dict[str, Any]]]]:
    """Return deterministic bundle declarations and locale catalog entries."""

    root = Path(legacy_root).expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"legacy conversation root is missing: {root}")
    by_bundle: dict[str, dict[str, Any]] = {}
    locale_entries: dict[str, dict[str, dict[str, Any]]] = {language: {} for language in LOCALES}
    for path in sorted(root.rglob("*.json")):
        relative = path.relative_to(root).as_posix()
        pieces = relative.split("/")
        if len(pieces) < 4 or pieces[-2] not in LOCALES:
            raise ValueError(f"legacy bundle path must contain an EN/TL directory: {relative}")
        language = pieces[-2]
        bundle_relative = "/".join((*pieces[:-2], pieces[-1]))
        bundle_id = _bundle_id(bundle_relative, namespace)
        kind, audience = pieces[0], pieces[1]
        bundle = by_bundle.setdefault(bundle_id, {
            "bundleId": bundle_id,
            "owner": owner,
            "modID": mod_id,
            "domain": f"pnc.{_slug(kind)}.{_slug(audience)}.{_slug(path.stem)}",
            "kind": kind,
            "audience": audience,
            "bundle": path.stem,
            "runtimePath": f"Conversation/Legacy/{bundle_relative}",
            "sourceShard": f"conversation.content.legacy.{_slug(kind)}",
            "keys": [],
        })
        values = _load_object(path)
        for key, value in sorted(values.items()):
            if not isinstance(key, str) or not isinstance(value, str):
                raise ValueError(f"legacy bundle values must be string pairs: {path}:{key}")
            translation_key = f"{bundle_id}.{_slug(key)}"
            if not any(item["key"] == key for item in bundle["keys"]):
                bundle["keys"].append({
                    "key": key,
                    "translationKey": translation_key,
                })
            locale_entries[language][translation_key] = {
                "text": value,
                "context": f"legacy.{kind}.{audience}.{path.stem}",
                "sourceShard": bundle["sourceShard"],
                "owners": [OWNER],
            }
    for bundle in by_bundle.values():
        bundle["keys"] = sorted(bundle["keys"], key=lambda item: item["key"])
    return sorted(by_bundle.values(), key=lambda item: item["bundleId"]), locale_entries


def migrate_legacy_bundles(
    legacy_root: str | Path,
    manifest_path: str | Path,
    catalog_paths: Mapping[str, str | Path],
    *,
    owner: str = OWNER,
    mod_id: str = OWNER,
    namespace: str = "conversation.legacy",
    apply: bool = False,
) -> dict[str, Any]:
    """Prepare or apply the legacy bundle migration without runtime shims."""

    bundles, locale_entries = discover_legacy_bundles(
        legacy_root,
        owner=owner,
        mod_id=mod_id,
        namespace=namespace,
    )
    manifest = {
        "schema": LEGACY_BUNDLE_SCHEMA,
        "owner": OWNER,
        "bundles": bundles,
    }
    catalog_documents: dict[str, dict[str, Any]] = {}
    changed_paths: list[str] = []
    for language in LOCALES:
        path = Path(catalog_paths[language]).expanduser().resolve()
        document = _load_object(path)
        if document.get("schema") != TRANSLATION_SCHEMA or document.get("language") != language:
            raise ValueError(f"invalid Core catalog for {language}: {path}")
        entries = document.get("entries")
        if not isinstance(entries, dict):
            raise ValueError(f"Core catalog entries must be an object: {path}")
        merged = dict(entries)
        for key, entry in locale_entries[language].items():
            if key in merged and merged[key].get("text") != entry["text"]:
                raise ValueError(f"translation key collision: {key}")
            merged[key] = entry
        document["entries"] = {key: merged[key] for key in sorted(merged)}
        catalog_documents[language] = document
        if len(merged) != len(entries):
            changed_paths.append(str(path))
    manifest_file = Path(manifest_path).expanduser().resolve()
    if apply:
        manifest_file.parent.mkdir(parents=True, exist_ok=True)
        manifest_file.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        for language, document in catalog_documents.items():
            path = Path(catalog_paths[language]).expanduser().resolve()
            path.write_text(
                json.dumps(document, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    return {
        "schema": LEGACY_BUNDLE_SCHEMA,
        "bundleCount": len(bundles),
        "entryCounts": {language: len(locale_entries[language]) for language in LOCALES},
        "manifestPath": str(manifest_file),
        "changedCatalogPaths": changed_paths,
        "applied": apply,
    }


def append_legacy_bundles(
    legacy_root: str | Path,
    manifest_path: str | Path,
    catalog_paths: Mapping[str, str | Path],
    *,
    owner: str,
    mod_id: str,
    namespace: str,
    apply: bool = False,
) -> dict[str, Any]:
    """Append one provider's bundles to the shared manifest/catalog pair."""

    manifest_file = Path(manifest_path).expanduser().resolve()
    manifest = _load_object(manifest_file)
    if manifest.get("schema") != LEGACY_BUNDLE_SCHEMA:
        raise ValueError(f"invalid legacy bundle manifest: {manifest_file}")
    bundles, locale_entries = discover_legacy_bundles(
        legacy_root,
        owner=owner,
        mod_id=mod_id,
        namespace=namespace,
    )
    existing_bundles = manifest.get("bundles")
    if not isinstance(existing_bundles, list):
        raise ValueError("legacy bundle manifest requires bundles")
    existing_ids = {str(item.get("bundleId")) for item in existing_bundles if isinstance(item, dict)}
    collisions = sorted(existing_ids.intersection(item["bundleId"] for item in bundles))
    if collisions:
        raise ValueError("legacy bundle ID collisions: " + ", ".join(collisions))
    merged_catalogs: dict[str, dict[str, Any]] = {}
    for language in LOCALES:
        path = Path(catalog_paths[language]).expanduser().resolve()
        document = _load_object(path)
        entries = document.get("entries")
        if not isinstance(entries, dict):
            raise ValueError(f"catalog entries must be an object: {path}")
        merged = dict(entries)
        for key, entry in locale_entries[language].items():
            if key in merged and merged[key].get("text") != entry["text"]:
                raise ValueError(f"translation key collision: {key}")
            merged[key] = entry
        document["entries"] = {key: merged[key] for key in sorted(merged)}
        merged_catalogs[language] = document
    manifest["bundles"] = sorted(
        [*existing_bundles, *bundles],
        key=lambda item: str(item.get("bundleId")),
    )
    if apply:
        manifest_file.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        for language, document in merged_catalogs.items():
            path = Path(catalog_paths[language]).expanduser().resolve()
            path.write_text(
                json.dumps(document, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    return {
        "bundleCount": len(bundles),
        "entryCounts": {language: len(locale_entries[language]) for language in LOCALES},
        "manifestPath": str(manifest_file),
        "applied": apply,
    }


def write_legacy_runtime_catalogs(
    manifest_path: str | Path,
    authoring_catalog_root: str | Path,
    runtime_translation_root: str | Path,
    *,
    owner: str | None = None,
) -> list[Path]:
    """Materialize generated flat bundle JSON under the new runtime root."""

    manifest_file = Path(manifest_path).expanduser().resolve()
    manifest = _load_object(manifest_file)
    if manifest.get("schema") != LEGACY_BUNDLE_SCHEMA:
        raise ValueError(f"invalid legacy bundle manifest: {manifest_file}")
    bundles = manifest.get("bundles")
    if not isinstance(bundles, list):
        raise ValueError(f"legacy bundle manifest requires bundles: {manifest_file}")
    catalog_root = Path(authoring_catalog_root).expanduser().resolve()
    runtime_root = Path(runtime_translation_root).expanduser().resolve()
    loaded = {
        language: load_catalog_document(catalog_root / f"{language}.json")
        for language in LOCALES
    }
    rendered_paths: list[Path] = []
    for language in LOCALES:
        entries = loaded[language].get("entries")
        if not isinstance(entries, dict):
            raise ValueError(f"catalog entries must be an object: {language}")
        for bundle in bundles:
            if not isinstance(bundle, dict):
                raise ValueError("legacy bundle declaration must be an object")
            if owner is not None and bundle.get("owner") != owner:
                continue
            values: dict[str, str] = {}
            for item in bundle.get("keys", []):
                if not isinstance(item, dict):
                    raise ValueError("legacy bundle key declaration must be an object")
                key = item.get("key")
                translation_key = item.get("translationKey")
                entry = entries.get(translation_key)
                if not isinstance(key, str) or not isinstance(translation_key, str):
                    raise ValueError("legacy bundle key declarations require string IDs")
                if not isinstance(entry, dict) or not isinstance(entry.get("text"), str):
                    raise ValueError(f"missing catalog entry for {translation_key}")
                values[key] = entry["text"]
            relative = Path(language) / Path(*str(bundle["runtimePath"]).split("/"))
            path = runtime_root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(values, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            rendered_paths.append(path)
    return rendered_paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("legacy_root", type=Path)
    parser.add_argument("manifest_path", type=Path)
    parser.add_argument("--en", dest="en_catalog", required=True, type=Path)
    parser.add_argument("--tl", dest="tl_catalog", required=True, type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    report = migrate_legacy_bundles(
        args.legacy_root,
        args.manifest_path,
        {"EN": args.en_catalog, "TL": args.tl_catalog},
        apply=args.apply,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
