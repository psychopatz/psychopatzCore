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


def validate_relative_directory_path(value: Any, label: str) -> str:
    """Return a normalized directory path relative to its root."""
    if not isinstance(value, str) or not value.strip():
        raise SourceManifestError(f"{label} must be a relative source directory")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise SourceManifestError(f"{label} must stay below its root")
    normalized = path.as_posix().rstrip("/")
    if not normalized or normalized != value.rstrip("/"):
        raise SourceManifestError(f"{label} must be a normalized relative directory")
    if PurePosixPath(normalized).suffix:
        raise SourceManifestError(f"{label} must be a directory, not a file")
    return normalized


def derive_subdir_domain(
    relative_to_root: Path,
    *,
    fallback_domain: str,
    validate_id: Callable[[Any, str], str],
) -> str:
    """Derive a clean domain from a discovered file's first subdirectory (or stem)."""
    parts = relative_to_root.parts
    candidate = parts[0] if len(parts) >= 2 else relative_to_root.stem
    normalized = candidate.strip().lower().replace("-", "_")
    if normalized:
        return validate_id(normalized, "derived shard domain")
    return fallback_domain


def load_external_source_root_entries(
    manifest: Mapping[str, Any],
    *,
    seen_paths: set[str],
    package_repositories: Mapping[str, Path],
    valid_kinds: Collection[str],
    validate_id: Callable[[Any, str], str],
) -> list[dict[str, Any]]:
    """Discover sorted JSON shards from manifest-declared external source roots."""
    raw_roots = manifest.get("externalSourceRoots", [])
    if raw_roots is None:
        raw_roots = []
    if not isinstance(raw_roots, list):
        raise SourceManifestError(
            "Conversation manifest externalSourceRoots must be a list"
        )

    roots: list[dict[str, Any]] = []
    seen_logical_roots: set[str] = set()
    for index, raw in enumerate(raw_roots):
        label = f"externalSourceRoots[{index}]"
        if not isinstance(raw, dict):
            raise SourceManifestError(f"{label} must be an object")
        logical_prefix = validate_relative_directory_path(raw.get("path"), f"{label}.path")
        if logical_prefix in seen_logical_roots:
            raise SourceManifestError(
                f"duplicate Conversation external source root: {logical_prefix}"
            )
        seen_logical_roots.add(logical_prefix)

        owner_value = raw.get("owner")
        if not isinstance(owner_value, str) or not owner_value.strip():
            raise SourceManifestError(f"{label}.owner is required")
        owner = owner_value.strip()
        source_dir = validate_relative_directory_path(
            raw.get("sourcePath"), f"{label}.sourcePath"
        )
        kind = raw.get("kind")
        if kind not in valid_kinds:
            raise SourceManifestError(
                f"unsupported external source-root kind: {kind!r}"
            )
        domain = validate_id(raw.get("domain"), f"{label}.domain")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int) or order < 0:
            raise SourceManifestError(
                f"{label}.order must be a non-negative integer"
            )
        domain_from_subdir = bool(raw.get("domainFromSubdir", False))
        source_profile = raw.get("sourceProfile")
        if source_profile is not None:
            source_profile = validate_id(source_profile, f"{label}.sourceProfile")

        source_repository = package_repositories.get(owner)
        if source_repository is None and raw.get("optional") is True:
            continue
        if source_repository is None:
            raise SourceManifestError(
                f"no repository configured for external Conversation owner {owner}"
            )
        source_repository = Path(source_repository).expanduser().resolve()
        directory = source_repository / Path(*PurePosixPath(source_dir).parts)
        if not directory.is_dir():
            if raw.get("optional") is True:
                continue
            raise SourceManifestError(
                f"external Conversation source root is missing: {owner}:{source_dir}"
            )
        roots.append({
            "raw": deepcopy(raw),
            "logicalPrefix": logical_prefix,
            "sourceDir": source_dir,
            "directory": directory,
            "owner": owner,
            "sourceRepository": source_repository,
            "kind": kind,
            "domain": domain,
            "domainFromSubdir": domain_from_subdir,
            "sourceProfile": source_profile,
            "order": order,
        })

    if roots != sorted(roots, key=lambda item: (item["order"], item["logicalPrefix"])):
        raise SourceManifestError(
            "Conversation manifest externalSourceRoots must use canonical order"
        )

    entries: list[dict[str, Any]] = []
    for root_spec in roots:
        directory = root_spec["directory"]
        files = sorted(
            path
            for path in directory.rglob("*.json")
            if path.is_file() and "translations" not in path.relative_to(directory).parts
        )
        if not files:
            raise SourceManifestError(
                f"external Conversation source root contains no JSON shards: {root_spec['owner']}:{root_spec['sourceDir']}"
            )
        for file_path in files:
            rel = file_path.relative_to(directory)
            rel_posix = rel.as_posix()
            logical_path = f"{root_spec['logicalPrefix']}/{rel_posix}"
            if logical_path in seen_paths:
                raise SourceManifestError(
                    f"duplicate Conversation shard path: {logical_path}"
                )
            seen_paths.add(logical_path)
            entry_domain = (
                derive_subdir_domain(
                    rel,
                    fallback_domain=root_spec["domain"],
                    validate_id=validate_id,
                )
                if root_spec["domainFromSubdir"]
                else root_spec["domain"]
            )
            entry = {
                "path": logical_path,
                "kind": root_spec["kind"],
                "domain": entry_domain,
                "order": root_spec["order"],
                "owner": root_spec["owner"],
                "sourceOwner": root_spec["owner"],
                "sourceRepository": str(root_spec["sourceRepository"]),
                "sourcePath": f"{root_spec['sourceDir']}/{rel_posix}",
                "discoveredFrom": root_spec["logicalPrefix"],
            }
            if root_spec["sourceProfile"] is not None:
                entry["sourceProfile"] = root_spec["sourceProfile"]
            entries.append(entry)
    return entries


__all__ = [
    "SourceManifestError",
    "derive_subdir_domain",
    "load_external_shard_entries",
    "load_external_source_root_entries",
    "validate_relative_directory_path",
    "validate_relative_json_path",
    "validate_relative_repository_path",
]
