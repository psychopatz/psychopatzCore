"""Manifest and filesystem boundary for Conversation source shards."""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path, PurePosixPath
from typing import Any, Mapping

from .errors import CompileError
from .generation_ownership import (
    HOOMANS_OWNER,
    OwnerConfigurationError,
    normalize_owner,
    resolve_core_repository,
)
from .source_manifest import SourceManifestError, load_external_shard_entries


CONVERSATION_MANIFEST_SCHEMA = "pnc.conversation.manifest.v1"
SHARD_KINDS = frozenset((
    "content", "patterns", "responses", "flows", "beats", "behaviors",
    "realization", "ui", "packs",
))
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")


def read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError(f"{label} must contain an object: {path}")
    return value


def validate_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not ID_PATTERN.fullmatch(value):
        raise CompileError(f"{label} must be a bounded canonical ID")
    return value


def _validate_relative_json_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a relative JSON path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise CompileError(f"{label} must stay below the Conversation source root")
    normalized = path.as_posix()
    if normalized != value or path.suffix.lower() != ".json":
        raise CompileError(f"{label} must be a normalized .json path")
    if normalized == "manifest.json":
        raise CompileError("manifest.json cannot also be a Conversation shard")
    return normalized


def _validate_relative_directory_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a relative source directory")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise CompileError(f"{label} must stay below the Conversation source root")
    normalized = path.as_posix().rstrip("/")
    if not normalized or normalized != value.rstrip("/"):
        raise CompileError(f"{label} must be a normalized relative directory")
    if PurePosixPath(normalized).suffix:
        raise CompileError(f"{label} must be a directory, not a file")
    return normalized


def _manifest_entry(raw: Mapping[str, Any], *, label: str, root: Path, seen_paths: set[str]) -> dict[str, Any]:
    path_value = _validate_relative_json_path(raw.get("path"), f"{label}.path")
    if path_value in seen_paths:
        raise CompileError(f"duplicate Conversation shard path: {path_value}")
    kind = raw.get("kind")
    if kind not in SHARD_KINDS:
        raise CompileError(f"unsupported Conversation shard kind: {kind!r}")
    domain = validate_id(raw.get("domain"), f"{label}.domain")
    order = raw.get("order")
    if isinstance(order, bool) or not isinstance(order, int) or order < 0:
        raise CompileError(f"{label}.order must be a non-negative integer")
    try:
        owner = normalize_owner(raw.get("owner"))
    except OwnerConfigurationError as error:
        raise CompileError(f"{label}.owner is required: {error}") from error
    shard_id = validate_id(raw.get("shardId"), f"{label}.shardId")
    source_profile = validate_id(raw.get("sourceProfile"), f"{label}.sourceProfile")
    path = root / Path(*PurePosixPath(path_value).parts)
    if not path.is_file():
        raise CompileError(f"Conversation manifest shard is missing: {path_value}")
    seen_paths.add(path_value)
    return {
        **deepcopy(dict(raw)),
        "path": path_value,
        "kind": kind,
        "domain": domain,
        "order": order,
        "owner": owner,
        "shardId": shard_id,
        "sourceProfile": source_profile,
    }


def _source_root_entries(
    manifest: Mapping[str, Any], *, root: Path, seen_paths: set[str]
) -> list[dict[str, Any]]:
    raw_roots = manifest.get("sourceRoots", [])
    if raw_roots is None:
        raw_roots = []
    if not isinstance(raw_roots, list):
        raise CompileError("Conversation manifest sourceRoots must be a list")
    roots = []
    seen_roots: set[str] = set()
    for index, raw in enumerate(raw_roots):
        label = f"sourceRoots[{index}]"
        if not isinstance(raw, dict):
            raise CompileError(f"{label} must be an object")
        root_path = _validate_relative_directory_path(raw.get("path"), f"{label}.path")
        if root_path in seen_roots:
            raise CompileError(f"duplicate Conversation source root: {root_path}")
        seen_roots.add(root_path)
        kind = raw.get("kind")
        if kind not in SHARD_KINDS:
            raise CompileError(f"unsupported source-root kind: {kind!r}")
        domain = validate_id(raw.get("domain"), f"{label}.domain")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int) or order < 0:
            raise CompileError(f"{label}.order must be a non-negative integer")
        try:
            owner = normalize_owner(raw.get("owner"))
        except OwnerConfigurationError as error:
            raise CompileError(f"{label}.owner is required: {error}") from error
        directory = root / Path(*PurePosixPath(root_path).parts)
        if not directory.is_dir():
            raise CompileError(f"Conversation source root is missing: {root_path}")
        roots.append({
            "path": root_path,
            "kind": kind,
            "domain": domain,
            "order": order,
            "owner": owner,
        })
    if roots != sorted(roots, key=lambda item: (item["order"], item["path"])):
        raise CompileError("Conversation sourceRoots must use canonical order")

    entries: list[dict[str, Any]] = []
    for source_root in roots:
        directory = root / Path(*PurePosixPath(source_root["path"]).parts)
        files = sorted(
            path for path in directory.rglob("*.json")
            if path.is_file() and "translations" not in path.relative_to(root).parts
        )
        if not files:
            raise CompileError(f"Conversation source root contains no JSON shards: {source_root['path']}")
        for file_path in files:
            relative = file_path.relative_to(root).as_posix()
            if relative in seen_paths:
                raise CompileError(f"Conversation source-root shard is already registered: {relative}")
            seen_paths.add(relative)
            entries.append({
                "path": relative,
                "kind": source_root["kind"],
                "domain": source_root["domain"],
                "order": source_root["order"],
                "owner": source_root["owner"],
                "discoveredFrom": source_root["path"],
            })
    return entries


def load_manifest(
    repository: Path,
    manifest_path: Path,
    *,
    package_repositories: Mapping[str, Path] | None = None,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    """Load and validate the complete local/external Conversation graph."""

    resolved_package_repositories = dict(package_repositories or {})
    resolved_package_repositories.setdefault(HOOMANS_OWNER, repository)
    resolved_package_repositories.setdefault(
        "PsychopatzCore", resolve_core_repository(repository)
    )
    manifest = read_json(manifest_path, "Conversation manifest")
    if manifest.get("schema") != CONVERSATION_MANIFEST_SCHEMA:
        raise CompileError(
            f"Conversation manifest requires schema {CONVERSATION_MANIFEST_SCHEMA}"
        )
    try:
        default_owner = normalize_owner(manifest.get("defaultOwner"))
        registry_owner = normalize_owner(
            manifest.get("registryOwner"), default=default_owner
        )
    except OwnerConfigurationError as error:
        raise CompileError(f"invalid Conversation manifest ownership: {error}") from error
    manifest["defaultOwner"] = default_owner
    manifest["registryOwner"] = registry_owner
    source_profiles = manifest.get("sourceProfiles")
    if not isinstance(source_profiles, dict) or not source_profiles:
        raise CompileError("Conversation manifest requires non-empty sourceProfiles")
    for profile_id, profile in source_profiles.items():
        validate_id(profile_id, "Conversation manifest sourceProfiles key")
        if not isinstance(profile, dict):
            raise CompileError(f"Conversation source profile {profile_id} must be an object")

    shards = manifest.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError("Conversation manifest requires at least one shard")
    root = manifest_path.parent
    seen_paths: set[str] = set()
    explicit_entries = []
    for index, raw in enumerate(shards):
        if not isinstance(raw, dict):
            raise CompileError(f"Conversation manifest shard {index} must be an object")
        explicit_entries.append(_manifest_entry(
            raw, label=f"shards[{index}]", root=root, seen_paths=seen_paths
        ))
    if explicit_entries != sorted(explicit_entries, key=lambda item: (item["order"], item["path"])):
        raise CompileError("Conversation manifest shards must use canonical order")

    discovered_entries = _source_root_entries(manifest, root=root, seen_paths=seen_paths)
    try:
        external_entries = load_external_shard_entries(
            manifest,
            seen_paths=seen_paths,
            package_repositories=resolved_package_repositories,
            valid_kinds=SHARD_KINDS,
            validate_id=validate_id,
        )
    except SourceManifestError as error:
        raise CompileError(str(error)) from error
    for entry in external_entries:
        entry["shardId"] = validate_id(
            entry.get("shardId"), f"external shard {entry['path']}.shardId"
        )
        entry["sourceProfile"] = validate_id(
            entry.get("sourceProfile"), f"external shard {entry['path']}.sourceProfile"
        )
    entries = sorted(
        [*explicit_entries, *discovered_entries, *external_entries],
        key=lambda item: (item["order"], item["path"]),
    )

    discovered = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*.json")
        if (
            path.is_file()
            and path.name != "manifest.json"
            and "translations" not in path.relative_to(root).parts
        )
    }
    unregistered = sorted(discovered - seen_paths)
    if unregistered:
        raise CompileError(
            "unregistered Conversation shards: " + ", ".join(unregistered)
        )
    return manifest, entries


__all__ = [
    "CONVERSATION_MANIFEST_SCHEMA",
    "SHARD_KINDS",
    "load_manifest",
    "read_json",
    "validate_id",
]
