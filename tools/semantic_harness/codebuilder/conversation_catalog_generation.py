"""Materialize one self-contained authoring catalog per Conversation locale."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .catalog_contract import TRANSLATION_SCHEMA


def _source_shard_id(
    value: Any,
    fallback: str,
    shard_ids: Mapping[str, str] | None = None,
) -> str:
    raw = str(value or fallback).replace("\\", "/")
    if shard_ids and raw in shard_ids:
        return shard_ids[raw]
    if raw.startswith("conversation."):
        return raw
    raw = re.sub(r"\.json$", "", raw)
    pieces = [piece for piece in re.split(r"[^A-Za-z0-9]+", raw) if piece]
    return "conversation." + ".".join(piece.lower() for piece in pieces)


def _record_location(model: Mapping[str, Any], record_id: Any) -> Mapping[str, Any]:
    locations = model.get("locations", {})
    location = locations.get(str(record_id)) if isinstance(locations, Mapping) else None
    return location if isinstance(location, Mapping) else {}


def _translation_sources(model: Mapping[str, Any]) -> dict[str, dict[str, str]]:
    """Map generated translation keys to stable source and context metadata."""

    sources: dict[str, dict[str, str]] = {}
    shard_ids: dict[str, str] = {}
    reports = model.get("shards")
    if isinstance(reports, list):
        for report in reports:
            if not isinstance(report, Mapping):
                continue
            path = report.get("path")
            shard_id = report.get("shardId")
            if isinstance(path, str) and isinstance(shard_id, str):
                shard_ids[path] = shard_id
    source_documents = model.get("_source_documents")
    if isinstance(source_documents, Mapping):
        for path, document in source_documents.items():
            if not isinstance(path, str) or not isinstance(document, Mapping):
                continue
            shard_id = document.get("shardId")
            if isinstance(shard_id, str):
                shard_ids[path] = shard_id

    def add(key: Any, source: Any, domain: Any) -> None:
        if not isinstance(key, str) or not key:
            return
        sources.setdefault(key, {
            "sourceShard": _source_shard_id(source, "conversation.merged", shard_ids),
            "context": str(domain or "general"),
        })

    content = model.get("content", {})
    for family in content.get("phraseFamilies", []) if isinstance(content, Mapping) else []:
        if not isinstance(family, Mapping):
            continue
        source = family.get("sourceShard")
        domain = family.get("conversationDomain") or family.get("group")
        for phrases in (family.get("styles") or {}).values():
            if isinstance(phrases, list):
                for phrase in phrases:
                    if isinstance(phrase, Mapping):
                        add(phrase.get("key"), source, domain)
    if isinstance(content, Mapping):
        for choice in content.get("playerChoices", []):
            if not isinstance(choice, Mapping):
                continue
            location = _record_location(model, choice.get("id"))
            source = choice.get("sourceShard") or location.get("sourceShard")
            domain = choice.get("conversationDomain") or "greeting"
            add(choice.get("labelKey"), source, domain)
            add(choice.get("choiceKey"), source, domain)

    for suggestion in model.get("ui", []):
        if not isinstance(suggestion, Mapping):
            continue
        location = _record_location(model, suggestion.get("id"))
        source = suggestion.get("sourceShard") or location.get("sourceShard") or "ui/static_suggestions.json"
        add(suggestion.get("labelKey"), source, "UI")
        add(suggestion.get("utteranceKey"), source, "UI")

    for section, fallback in (("dialogue", "dialogue/merged.json"), ("semantic", "flows/merged.json")):
        values = model.get(section, {})
        if not isinstance(values, Mapping):
            continue
        response_pools = values.get("responsePools", [])
        if isinstance(response_pools, list):
            for pool in response_pools:
                if not isinstance(pool, Mapping):
                    continue
                location = _record_location(model, pool.get("id"))
                source = location.get("sourceShard") or fallback
                for variant in pool.get("variants", []):
                    if isinstance(variant, Mapping):
                        add(variant.get("templateID"), source, section)
        for language_values in (values.get("translations", {}) or {}).values():
            if isinstance(language_values, Mapping):
                for key in language_values:
                    add(key, fallback, section)
    return sources


def catalogs_from_model(model: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    """Return deterministic EN/TL-style catalogs from the current model."""

    from .conversation_compiler import conversation_translation_bundles_by_owner

    bundles = conversation_translation_bundles_by_owner(model)
    sources = _translation_sources(model)
    catalogs: dict[str, dict[str, Any]] = {}
    for owner, language_bundles in sorted(bundles.items()):
        for language, domain_bundles in sorted(language_bundles.items()):
            catalog = catalogs.setdefault(language, {
                "schema": TRANSLATION_SCHEMA,
                "language": language,
                "fallback": "EN",
                "entries": {},
            })
            entries = catalog["entries"]
            for domain, values in sorted(domain_bundles.items()):
                for key, text in sorted(values.items()):
                    if not isinstance(text, str) or not text.strip():
                        continue
                    metadata = sources.get(key, {
                        "sourceShard": _source_shard_id(
                            f"generated/{domain}.json", "conversation.generated"
                        ),
                        "context": str(domain),
                    })
                    existing = entries.get(key)
                    if existing is not None and existing.get("text") != text:
                        raise ValueError(f"conflicting translation text for key {key}")
                    if existing is None:
                        entries[key] = {
                            "text": text,
                            "context": metadata["context"],
                            "sourceShard": metadata["sourceShard"],
                            "owners": [owner],
                        }
                    elif owner not in existing["owners"]:
                        existing["owners"].append(owner)

    fallback_entries: list[tuple[str, str, str, str, str]] = []
    for section in ("dialogue", "semantic"):
        section_model = model.get(section, {})
        if not isinstance(section_model, Mapping):
            continue
        for pool in section_model.get("responsePools", []):
            if not isinstance(pool, Mapping):
                continue
            location = _record_location(model, pool.get("id"))
            source = location.get("sourceShard") or f"{section}/merged.json"
            owner = str(location.get("owner") or "ProjectHoomans")
            for variant in pool.get("variants", []):
                if not isinstance(variant, Mapping):
                    continue
                key = variant.get("templateID")
                fallback = variant.get("fallback")
                if isinstance(key, str) and isinstance(fallback, str) and fallback.strip():
                    fallback_entries.append((
                        key,
                        fallback,
                        _source_shard_id(source, f"{section}.merged"),
                        section,
                        owner,
                    ))
    for suggestion in model.get("ui", []):
        if not isinstance(suggestion, Mapping):
            continue
        location = _record_location(model, suggestion.get("id"))
        source = location.get("sourceShard") or "ui/static_suggestions.json"
        owner = str(location.get("owner") or "ProjectHoomans")
        for key_name, fallback_name in (
            ("labelKey", "labelFallback"),
            ("utteranceKey", "utteranceFallback"),
        ):
            key = suggestion.get(key_name)
            fallback = suggestion.get(fallback_name)
            if isinstance(key, str) and isinstance(fallback, str) and fallback.strip():
                fallback_entries.append((
                    key,
                    fallback,
                    _source_shard_id(source, "ui.static_suggestions"),
                    "UI",
                    owner,
                ))

    english = catalogs.setdefault("EN", {
        "schema": TRANSLATION_SCHEMA,
        "language": "EN",
        "fallback": "EN",
        "entries": {},
    })
    for key, text, source_shard, context, owner in fallback_entries:
        if key in english["entries"]:
            continue
        english["entries"][key] = {
            "text": text,
            "context": context,
            "sourceShard": source_shard,
            "owners": [owner],
        }
    for language, catalog in catalogs.items():
        if language == "EN":
            continue
        for key, text, source_shard, context, owner in fallback_entries:
            if key in catalog["entries"]:
                continue
            catalog["entries"][key] = {
                "text": text,
                "context": context,
                "sourceShard": source_shard,
                "owners": [owner],
                "status": "fallback",
            }
    for catalog in catalogs.values():
        for entry in catalog["entries"].values():
            entry["owners"] = sorted(entry["owners"])
        catalog["entries"] = {
            key: catalog["entries"][key]
            for key in sorted(catalog["entries"])
        }
    existing_documents = model.get("_catalog_documents")
    if isinstance(existing_documents, Mapping):
        for language, document in existing_documents.items():
            catalog = catalogs.get(language)
            entries = document.get("entries") if isinstance(document, Mapping) else None
            if not isinstance(catalog, dict) or not isinstance(entries, Mapping):
                continue
            for key, existing in entries.items():
                if (
                    isinstance(existing, Mapping)
                    and existing.get("status") == "fallback"
                    and key in catalog["entries"]
                ):
                    catalog["entries"][key]["status"] = "fallback"
    return {language: catalogs[language] for language in sorted(catalogs)}


def write_catalogs(catalogs: Mapping[str, Mapping[str, Any]], output_root: str | Path) -> list[Path]:
    """Write locale catalogs as deterministic authoring files."""

    destination = Path(output_root).expanduser().resolve()
    destination.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    for language, catalog in sorted(catalogs.items()):
        path = destination / f"{language}.json"
        path.write_text(
            json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        paths.append(path)
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-repository", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--dynamic-trading-repository", type=Path)
    parser.add_argument("--output-root", type=Path, required=True)
    options = parser.parse_args(argv)

    from .conversation_compiler import compile_conversation_sources

    package_repositories = {}
    if options.dynamic_trading_repository:
        package_repositories["DTCommon"] = options.dynamic_trading_repository
    model = compile_conversation_sources(
        options.project_repository,
        manifest_path=options.manifest,
        runtime_root=options.project_repository,
        package_repositories=package_repositories,
    )
    paths = write_catalogs(catalogs_from_model(model), options.output_root)
    print(json.dumps({"languages": [path.stem for path in paths], "paths": [str(path) for path in paths]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
