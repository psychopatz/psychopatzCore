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
    owner_repository,
    package_descriptor,
    resolve_core_repository,
    resolve_hoomans_repository,
)
from .psdl_compact import (
    PACKAGE_DESCRIPTOR_SCHEMA,
    PROVENANCE_LOCK_SCHEMA,
    validate_package_descriptor,
)
from .source_manifest import (
    SourceManifestError,
    derive_subdir_domain,
    derive_subdir_domain_path,
    load_external_shard_entries,
    load_external_source_root_entries,
)


CONVERSATION_MANIFEST_SCHEMA = "pnc.conversation.manifest.v1"
SHARD_KINDS = frozenset((
    "content", "patterns", "responses", "flows", "beats", "behaviors",
    "realization", "ui", "packs", "psdl", "convo_engine",
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
            "domainFromSubdir": bool(raw.get("domainFromSubdir", False)),
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
            if source_root["domainFromSubdir"]:
                entry_domain, entry_domain_path = derive_subdir_domain_path(
                    file_path.relative_to(directory),
                    fallback_domain=source_root["domain"],
                    validate_id=validate_id,
                )
            else:
                entry_domain = source_root["domain"]
                entry_domain_path = source_root["domain"]
            entries.append({
                "path": relative,
                "kind": source_root["kind"],
                "domain": entry_domain,
                "domainPath": entry_domain_path,
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
    visited_packages: set[str] | None = None,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    """Load and validate the complete local/external Conversation graph."""
    active_visited = set() if visited_packages is None else visited_packages

    resolved_package_repositories = dict(package_repositories or {})
    resolved_package_repositories.setdefault(
        HOOMANS_OWNER, resolve_hoomans_repository(repository)
    )
    resolved_package_repositories.setdefault(
        "PsychopatzCore", resolve_core_repository(repository)
    )
    root = manifest_path.parent
    package_path = manifest_path if manifest_path.name == "package.json" else (root / "package.json")
    provenance_path = root / "provenance.lock"
    package_doc: dict[str, Any] | None = None
    if package_path.is_file():
        package_doc = validate_package_descriptor(
            read_json(package_path, "PSDL package descriptor")
        )
    if manifest_path.name == "package.json":
        manifest = dict(package_doc or {})
        manifest.setdefault("shards", [])
    else:
        manifest = read_json(manifest_path, "Conversation manifest")
        if manifest.get("schema") not in {CONVERSATION_MANIFEST_SCHEMA, PACKAGE_DESCRIPTOR_SCHEMA}:
            raise CompileError(
                f"Conversation manifest requires schema {CONVERSATION_MANIFEST_SCHEMA}"
            )
    if package_doc is not None:
        manifest["_packageDescriptor"] = package_doc
        for key in (
            "defaultOwner",
            "registryOwner",
            "sourceRoots",
            "externalSourceRoots",
            "auxiliaryRoots",
            "externalReferences",
            "shards",
            "externalShards",
            "requiredCapabilities",
            "imports",
            "defaults",
            "profiles",
        ):
            if key in package_doc and key not in manifest:
                manifest[key] = deepcopy(package_doc[key])
    if provenance_path.is_file():
        prov_doc = read_json(provenance_path, "PSDL provenance lock")
        if prov_doc.get("schema") != PROVENANCE_LOCK_SCHEMA:
            raise CompileError(
                f"PSDL provenance lock requires schema {PROVENANCE_LOCK_SCHEMA}"
            )
        if isinstance(prov_doc.get("sourceProfiles"), dict):
            manifest.setdefault("sourceProfiles", {}).update(
                deepcopy(prov_doc["sourceProfiles"])
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
    if not isinstance(shards, list):
        raise CompileError("Conversation manifest shards must be a list")
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
        external_root_entries = load_external_source_root_entries(
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
        [*explicit_entries, *discovered_entries, *external_entries, *external_root_entries],
        key=lambda item: (item["order"], item["path"]),
    )
    pkg_identity = str(manifest.get("package") or default_owner)
    active_visited.add(pkg_identity)

    raw_imports = manifest.get("imports") or []
    if not isinstance(raw_imports, list):
        raise CompileError("PSDL package imports must be a list")
    imported_entries: list[dict[str, Any]] = []
    for imp in raw_imports:
        if not isinstance(imp, str) or not imp.strip():
            raise CompileError("PSDL package import entry must be a non-empty string")
        try:
            imp_desc = package_descriptor(imp.strip())
        except OwnerConfigurationError as error:
            raise CompileError(f"Unknown imported PSDL package {imp!r}: {error}") from error
        if imp_desc.owner in active_visited:
            continue
        imp_repo = resolved_package_repositories.get(imp_desc.owner)
        if imp_repo is None:
            try:
                imp_repo = owner_repository(repository, imp_desc.owner)
            except OwnerConfigurationError as error:
                raise CompileError(
                    f"Missing repository for imported PSDL package {imp!r}: {error}"
                ) from error
        imp_root = imp_repo / imp_desc.source_root_relative
        imp_manifest_path = imp_root / "package.json"
        if not imp_manifest_path.is_file():
            imp_manifest_path = imp_root / "manifest.json"
        if not imp_manifest_path.is_file():
            raise CompileError(
                f"Imported PSDL package {imp!r} is missing package.json/manifest.json under {imp_root}"
            )
        imp_manifest, imp_loaded_entries = load_manifest(
            imp_repo,
            imp_manifest_path,
            package_repositories=resolved_package_repositories,
            visited_packages=active_visited,
        )
        manifest["sourceProfiles"].update(deepcopy(imp_manifest.get("sourceProfiles") or {}))
        imp_ext_refs = (imp_manifest.get("externalReferences") or {}).get("patternIDs") or []
        if imp_ext_refs:
            ext_refs = manifest.setdefault("externalReferences", {})
            pat_ids = ext_refs.setdefault("patternIDs", [])
            for pid in imp_ext_refs:
                if pid not in pat_ids:
                    pat_ids.append(pid)
        for imp_entry in imp_loaded_entries:
            cloned = deepcopy(imp_entry)
            if not cloned.get("sourceRepository"):
                cloned["sourceRepository"] = str(imp_repo.expanduser().resolve())
            if not cloned.get("sourcePath"):
                cloned["sourcePath"] = (
                    imp_root.relative_to(imp_repo).as_posix() + "/" + cloned["path"]
                )
            cloned.setdefault("importedFrom", imp_desc.owner)
            cloned.setdefault("sourceOwner", str(cloned.get("owner") or imp_desc.owner))
            logical = cloned["path"]
            if logical in seen_paths:
                logical = f"imports/{imp_desc.owner}/{logical}"
                cloned["path"] = logical
            seen_paths.add(logical)
            imported_entries.append(cloned)

    entries = sorted(
        [*entries, *imported_entries],
        key=lambda item: (item["order"], item["path"]),
    )
    if not entries:
        raise CompileError("Conversation manifest requires at least one shard")

    discovered = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*.json")
        if (
            path.is_file()
            and path.name not in {"manifest.json", "package.json"}
            and "translations" not in path.relative_to(root).parts
        )
    }
    raw_auxiliary = manifest.get("auxiliaryFiles", [])
    if raw_auxiliary is None:
        raw_auxiliary = []
    if not isinstance(raw_auxiliary, list):
        raise CompileError("Conversation manifest auxiliaryFiles must be a list")
    auxiliary_paths: set[str] = set()
    for index, raw_path in enumerate(raw_auxiliary):
        auxiliary_path = _validate_relative_json_path(
            raw_path,
            f"auxiliaryFiles[{index}]",
        )
        if auxiliary_path in seen_paths:
            raise CompileError(f"Conversation auxiliary file is also a shard: {auxiliary_path}")
        if not (root / Path(*PurePosixPath(auxiliary_path).parts)).is_file():
            raise CompileError(f"Conversation auxiliary file is missing: {auxiliary_path}")
        auxiliary_paths.add(auxiliary_path)
    raw_auxiliary_roots = manifest.get("auxiliaryRoots", [])
    if raw_auxiliary_roots is None:
        raw_auxiliary_roots = []
    if not isinstance(raw_auxiliary_roots, list):
        raise CompileError("Conversation manifest auxiliaryRoots must be a list")
    seen_auxiliary_roots: set[str] = set()
    for index, raw_path in enumerate(raw_auxiliary_roots):
        auxiliary_root = _validate_relative_directory_path(
            raw_path,
            f"auxiliaryRoots[{index}]",
        )
        if auxiliary_root in seen_auxiliary_roots:
            raise CompileError(
                f"duplicate Conversation auxiliary root: {auxiliary_root}"
            )
        seen_auxiliary_roots.add(auxiliary_root)
        directory = root / Path(*PurePosixPath(auxiliary_root).parts)
        if not directory.is_dir():
            raise CompileError(
                f"Conversation auxiliary root is missing: {auxiliary_root}"
            )
        files = sorted(path for path in directory.rglob("*.json") if path.is_file())
        if not files:
            raise CompileError(
                f"Conversation auxiliary root contains no JSON files: {auxiliary_root}"
            )
        for file_path in files:
            relative = file_path.relative_to(root).as_posix()
            if relative in seen_paths:
                raise CompileError(
                    f"Conversation auxiliary file is also a shard: {relative}"
                )
            auxiliary_paths.add(relative)
    unregistered = sorted(discovered - seen_paths - auxiliary_paths)
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
