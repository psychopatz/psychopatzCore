"""Deterministic record and translation-key inventory for Conversation data."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Mapping


def inventory_from_model(model: Mapping[str, Any]) -> dict[str, Any]:
    """Build a compact freeze report from an already compiled model."""

    from .conversation_compiler import (
        conversation_languages,
        conversation_translation_catalogs_by_owner,
    )

    shards = []
    for shard in model.get("shards", []):
        if not isinstance(shard, Mapping):
            continue
        shards.append({
            "path": shard.get("path"),
            "kind": shard.get("kind"),
            "domain": shard.get("domain"),
            "owner": shard.get("owner"),
            "recordIDs": sorted(str(value) for value in shard.get("recordIDs", [])),
            "fingerprint": shard.get("fingerprint"),
        })

    catalogs = conversation_translation_catalogs_by_owner(model)
    translations: dict[str, Any] = {}
    for owner, language_catalogs in sorted(catalogs.items()):
        translations[owner] = {}
        for language, domain_catalogs in sorted(language_catalogs.items()):
            translations[owner][language] = {}
            for domain, values in sorted(domain_catalogs.items()):
                translations[owner][language][domain] = {
                    "keyCount": len(values),
                    "keys": sorted(str(key) for key in values),
                }

    return {
        "schema": "psychopatz.semantic.conversation.inventory.v1",
        "modelFingerprint": model.get("wholeModelFingerprint"),
        "languages": list(conversation_languages(model)),
        "shards": sorted(shards, key=lambda item: str(item.get("path", ""))),
        "translations": translations,
        "summary": {
            "shardCount": len(shards),
            "recordCount": sum(len(item["recordIDs"]) for item in shards),
            "ownerCount": len(translations),
            "translationKeyCount": sum(
                item["keyCount"]
                for owner in translations.values()
                for language in owner.values()
                for item in language.values()
            ),
        },
    }


def compile_inventory(
    project_repository: str | Path,
    *,
    manifest_path: str | Path | None = None,
    core_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Compile the existing source model and return its freeze inventory."""

    from .conversation_compiler import compile_conversation_sources

    project = Path(project_repository).expanduser().resolve()
    package_repositories: dict[str, Path] = {}
    if dynamic_trading_repository is not None:
        package_repositories["DTCommon"] = Path(dynamic_trading_repository).expanduser().resolve()
    model = compile_conversation_sources(
        project,
        manifest_path=Path(manifest_path).expanduser().resolve() if manifest_path else None,
        runtime_root=project,
        package_repositories=package_repositories,
    )
    report = inventory_from_model(model)
    report["repositories"] = {
        "projectHoomans": str(project),
        "core": str(Path(core_repository).expanduser().resolve()) if core_repository else None,
        "dynamicTrading": str(Path(dynamic_trading_repository).expanduser().resolve()) if dynamic_trading_repository else None,
    }
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-repository", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--core-repository", type=Path)
    parser.add_argument("--dynamic-trading-repository", type=Path)
    options = parser.parse_args(argv)
    report = compile_inventory(
        options.project_repository,
        manifest_path=options.manifest,
        core_repository=options.core_repository,
        dynamic_trading_repository=options.dynamic_trading_repository,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
