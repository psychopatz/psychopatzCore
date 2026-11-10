"""Provider-neutral source-manifest boundary helpers.

This module owns only filesystem and manifest-shape rules. Adopters provide
their own owner vocabulary, shard-kind policy, and generated-artifact policy;
Core never names an adopter here.
"""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path, PurePosixPath
from typing import Any, Callable, Collection, Mapping


class SourceManifestError(ValueError):
    """Raised when an external source declaration is unsafe or incomplete."""


def validate_relative_json_path(value: Any, label: str) -> str:
    """Return a normalized logical shard path below a manifest root."""
    if not isinstance(value, str) or not value.strip():
        raise SourceManifestError(f"{label} must be a relative JSON path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise SourceManifestError(f"{label} must stay below its manifest root")
    normalized = path.as_posix()
    if normalized != value or path.suffix.lower() != ".json":
        raise SourceManifestError(f"{label} must be a normalized .json path")
    if normalized == "manifest.json":
        raise SourceManifestError("manifest.json cannot also be a source shard")
    return normalized


def validate_relative_repository_path(value: Any, label: str) -> str:
    """Return a normalized JSON path relative to an owning repository."""
    if not isinstance(value, str) or not value.strip():
        raise SourceManifestError(f"{label} must be a relative JSON path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise SourceManifestError(f"{label} must stay below its repository root")
    normalized = path.as_posix()
    if normalized != value or path.suffix.lower() != ".json":
        raise SourceManifestError(f"{label} must be a normalized .json path")
    return normalized


def load_external_shard_entries(
    manifest: Mapping[str, Any],
    *,
    seen_paths: set[str],
    package_repositories: Mapping[str, Path],
    valid_kinds: Collection[str],
    validate_id: Callable[[Any, str], str],
) -> list[dict[str, Any]]:
    """Validate and resolve manifest-owned external shard declarations.

    The returned entries keep the logical ``path`` used by the adopting
    compiler while carrying the physical repository and source path needed to
    read the shard. The function performs no writes and has no adopter policy.
    """
    raw_shards = manifest.get("externalShards", [])
    if raw_shards is None:
        raw_shards = []
    if not isinstance(raw_shards, list):
        raise SourceManifestError(
            "Conversation manifest externalShards must be a list"
        )

    entries: list[dict[str, Any]] = []
    for index, raw in enumerate(raw_shards):
        label = f"externalShards[{index}]"
        if not isinstance(raw, dict):
            raise SourceManifestError(f"{label} must be an object")
        logical_path = validate_relative_json_path(
            raw.get("path"), f"{label}.path"
        )
        if logical_path in seen_paths:
            raise SourceManifestError(
                f"duplicate Conversation shard path: {logical_path}"
            )

        owner_value = raw.get("owner")
        if not isinstance(owner_value, str) or not owner_value.strip():
            raise SourceManifestError(f"{label}.owner is required")
        owner = owner_value.strip()
        source_path = validate_relative_repository_path(
            raw.get("sourcePath"), f"{label}.sourcePath"
        )
        kind = raw.get("kind")
        if kind not in valid_kinds:
            raise SourceManifestError(
                f"unsupported Conversation shard kind: {kind!r}"
            )
        domain = validate_id(raw.get("domain"), f"{label}.domain")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int) or order < 0:
            raise SourceManifestError(
                f"{label}.order must be a non-negative integer"
            )

        source_repository = package_repositories.get(owner)
        if source_repository is None and raw.get("optional") is True:
            continue
        if source_repository is None:
            raise SourceManifestError(
                f"no repository configured for external Conversation owner {owner}"
            )
        source_repository = Path(source_repository).expanduser().resolve()
        source_file = source_repository / Path(
            *PurePosixPath(source_path).parts
        )
        if not source_file.is_file():
            raise SourceManifestError(
                f"external Conversation shard is missing: {owner}:{source_path}"
            )

        seen_paths.add(logical_path)
        entries.append({
            **deepcopy(raw),
            "path": logical_path,
            "kind": kind,
            "domain": domain,
            "order": order,
            "sourceOwner": owner,
            "sourceRepository": str(source_repository),
            "sourcePath": source_path,
        })

    if entries != sorted(
        entries, key=lambda item: (item["order"], item["path"])
    ):
        raise SourceManifestError(
            "Conversation manifest externalShards must use canonical order"
        )
    return entries


__all__ = [
    "SourceManifestError",
    "load_external_shard_entries",
    "validate_relative_json_path",
    "validate_relative_repository_path",
]
