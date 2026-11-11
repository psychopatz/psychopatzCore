"""One-shot migration of Conversation shards to the explicit v2 envelope."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .catalog_contract import SHARD_SCHEMA


def _slug(value: Any) -> str:
    pieces = [piece.lower() for piece in re.split(r"[^A-Za-z0-9]+", str(value)) if piece]
    return ".".join(pieces) or "source"


def _source_profile_id(source: Mapping[str, Any], version: Any) -> str:
    payload = json.dumps(
        {"source": source, "version": version},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()[:10]
    label = source.get("name") or source.get("owner") or "conversation"
    return f"conversation.source.{_slug(label)}.{digest}"


def shard_id_for(path: str, kind: str) -> str:
    relative = re.sub(r"\.json$", "", path.replace("\\", "/"))
    parts = relative.split("/")
    if parts and parts[0] == kind:
        relative = "/".join(parts[1:])
    elif parts and kind == "responses" and parts[0] == "flows":
        relative = "/".join(parts[1:])
    return f"conversation.{kind}.{_slug(relative)}"


def normalize_shard_document(
    document: Mapping[str, Any],
    *,
    path: str,
    owner: str,
    profiles: dict[str, dict[str, Any]],
) -> tuple[dict[str, Any], str, str]:
    source = document.get("source")
    if not isinstance(source, Mapping):
        source = {
            "name": "Conversation Authoring",
            "version": str(document.get("version") or "1"),
            "contentLicense": "Package-owned Conversation content",
        }
    version = document.get("version") or source.get("version") or "1"
    profile_id = _source_profile_id(source, version)
    profile = copy.deepcopy(dict(source))
    profile.setdefault("version", str(version))
    profiles.setdefault(profile_id, profile)
    kind = str(document["kind"])
    domain = str(document["domain"])
    normalized: dict[str, Any] = {
        "schema": SHARD_SCHEMA,
        "shardId": shard_id_for(path, kind),
        "kind": kind,
        "domain": domain,
        "owner": owner,
        "sourceProfile": profile_id,
    }
    for key, value in document.items():
        if key in {"schema", "shardId", "kind", "domain", "owner", "source", "sourceProfile", "version"}:
            continue
        normalized[key] = copy.deepcopy(value)
    return normalized, normalized["shardId"], profile_id


def migrate_standalone_shard(
    source_path: str | Path,
    *,
    manifest_path: str | Path,
    logical_path: str,
    owner: str,
    apply: bool = False,
) -> dict[str, Any]:
    """Migrate one external shard and register its profile in a manifest."""

    source_file = Path(source_path).expanduser().resolve()
    manifest_file = Path(manifest_path).expanduser().resolve()
    document = json.loads(source_file.read_text(encoding="utf-8"))
    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    profiles: dict[str, dict[str, Any]] = copy.deepcopy(manifest.get("sourceProfiles") or {})
    if document.get("schema") == SHARD_SCHEMA:
        normalized = copy.deepcopy(document)
        shard_id = str(normalized.get("shardId") or shard_id_for(logical_path, str(normalized.get("kind", "content"))))
        profile_id = str(normalized.get("sourceProfile") or "")
        if not profile_id:
            raise ValueError(f"migrated shard {source_file} is missing sourceProfile")
        if profile_id not in profiles:
            raise ValueError(f"manifest is missing source profile {profile_id}")
    else:
        normalized, shard_id, profile_id = normalize_shard_document(
            document,
            path=logical_path,
            owner=owner,
            profiles=profiles,
        )
    updated_manifest = copy.deepcopy(manifest)
    updated_manifest["sourceProfiles"] = {
        key: profiles[key] for key in sorted(profiles)
    }
    matching = [
        entry for entry in updated_manifest.get("externalShards", [])
        if isinstance(entry, dict) and entry.get("path") == logical_path
    ]
    if len(matching) != 1:
        raise ValueError(f"manifest must contain exactly one external shard at {logical_path}")
    entry = matching[0]
    if str(entry.get("owner")) != owner:
        raise ValueError(f"external shard owner mismatch for {logical_path}")
    entry["shardId"] = shard_id
    entry["sourceProfile"] = profile_id
    if apply:
        source_file.write_text(
            json.dumps(normalized, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest_file.write_text(
            json.dumps(updated_manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return {
        "sourcePath": str(source_file),
        "manifestPath": str(manifest_file),
        "logicalPath": logical_path,
        "owner": owner,
        "shardId": shard_id,
        "sourceProfile": profile_id,
        "apply": apply,
    }


def migrate_manifest_and_tree(
    source_root: str | Path,
    *,
    manifest_path: str | Path | None = None,
    apply: bool = False,
) -> dict[str, Any]:
    """Audit or migrate one manifest-backed Conversation source tree."""

    root = Path(source_root).expanduser().resolve()
    manifest_file = Path(manifest_path or root / "manifest.json").expanduser().resolve()
    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    profiles: dict[str, dict[str, Any]] = copy.deepcopy(manifest.get("sourceProfiles") or {})
    changed: list[dict[str, Any]] = []
    path_metadata: dict[str, tuple[str, str, str]] = {}

    for path in sorted(root.rglob("*.json")):
        relative = path.relative_to(root)
        if path.name == "manifest.json" or "translations" in relative.parts:
            continue
        document = json.loads(path.read_text(encoding="utf-8"))
        if document.get("schema") == SHARD_SCHEMA:
            owner = document.get("owner")
            shard_id = document.get("shardId")
            profile_id = document.get("sourceProfile")
            if all(isinstance(value, str) and value for value in (owner, shard_id, profile_id)):
                path_metadata[relative.as_posix()] = (owner, shard_id, profile_id)
            continue
        source = document.get("source") if isinstance(document.get("source"), Mapping) else {}
        owner = str(source.get("owner") or manifest.get("defaultOwner") or "ProjectHoomans")
        normalized, shard_id, profile_id = normalize_shard_document(
            document,
            path=relative.as_posix(),
            owner=owner,
            profiles=profiles,
        )
        path_metadata[relative.as_posix()] = (owner, shard_id, profile_id)
        if apply:
            path.write_text(
                json.dumps(normalized, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        changed.append({
            "path": relative.as_posix(),
            "owner": owner,
            "shardId": shard_id,
            "sourceProfile": profile_id,
        })

    updated_manifest = copy.deepcopy(manifest)
    updated_manifest["sourceProfiles"] = {
        key: profiles[key] for key in sorted(profiles)
    }
    for field in ("shards", "sourceRoots"):
        entries = updated_manifest.get(field, [])
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            if field == "shards":
                metadata = path_metadata.get(entry.get("path"))
                if metadata:
                    entry["owner"], entry["shardId"], entry["sourceProfile"] = metadata
            else:
                matching = [
                    metadata for path, metadata in path_metadata.items()
                    if path.startswith(str(entry.get("path", "")).rstrip("/") + "/")
                ]
                owners = sorted({metadata[0] for metadata in matching})
                if len(owners) == 1:
                    entry["owner"] = owners[0]
    for entry in updated_manifest.get("externalShards", []):
        if not isinstance(entry, dict):
            continue
        source_path = entry.get("sourcePath")
        if not isinstance(source_path, str):
            continue
        local_metadata = next(
            (
                metadata for relative, metadata in path_metadata.items()
                if source_path.replace("\\", "/").endswith("/" + relative)
            ),
            None,
        )
        if local_metadata:
            entry["owner"], entry["shardId"], entry["sourceProfile"] = local_metadata
        elif entry.get("shardId") is None:
            # External profiles are supplied by the owning repository's
            # migration. Keep a deterministic ID until that profile arrives.
            entry["shardId"] = shard_id_for(
                str(entry.get("path", "")), str(entry.get("kind", "content"))
            )
    if apply:
        manifest_file.write_text(
            json.dumps(updated_manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return {
        "root": str(root),
        "manifestPath": str(manifest_file),
        "apply": apply,
        "changedFileCount": len(changed),
        "sourceProfileCount": len(profiles),
        "changed": changed,
        "updatedManifest": updated_manifest,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--apply", action="store_true")
    options = parser.parse_args(argv)
    report = migrate_manifest_and_tree(
        options.root,
        manifest_path=options.manifest,
        apply=options.apply,
    )
    print(json.dumps({
        "root": report["root"],
        "manifest": report["manifestPath"],
        "apply": report["apply"],
        "changedFileCount": report["changedFileCount"],
        "sourceProfileCount": report["sourceProfileCount"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
