"""Materialize one self-contained authoring catalog per Conversation locale."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .catalog_contract import TRANSLATION_SCHEMA


def _source_shard_id(value: Any, fallback: str) -> str:
    raw = str(value or fallback).replace("\\", "/")
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

    def add(key: Any, source: Any, domain: Any) -> None:
        if not isinstance(key, str) or not key:
            return
        sources.setdefault(key, {
            "sourceShard": _source_shard_id(source, "conversation.merged"),
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
    for catalog in catalogs.values():
        for entry in catalog["entries"].values():
            entry["owners"] = sorted(entry["owners"])
        catalog["entries"] = {
            key: catalog["entries"][key]
            for key in sorted(catalog["entries"])
        }
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
