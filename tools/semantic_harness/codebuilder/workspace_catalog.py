"""Single workspace/provider/source discovery authority for ConvoEngine (Port A).

All GUI, CLI, audit, catalog, and build entrypoints consume ``WorkspaceCatalog``
rather than guessing sibling directories or mapping owners ad hoc.
"""

from __future__ import annotations

import json
import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Mapping

from ..providers.mod_manager import ModManagerError, ProviderManifest, ProviderSpec
from .conversation_model import fingerprint
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    PACKAGE_DESCRIPTORS,
    OwnerConfigurationError,
    normalize_owner,
    resolve_core_repository,
)


WORKSPACE_SNAPSHOT_SCHEMA = "semantic.workspace.v1"
CONVO_SUBDIRS = ("dialogue", "behavior", "beat", "realization")


class WorkspaceResolutionError(CompileError, OwnerConfigurationError):
    """Raised when workspace or required owner resolution fails closed."""


def _canonical_owner(raw: Any) -> str | None:
    if raw is None or not str(raw).strip():
        return None
    text = str(raw).strip()
    try:
        return normalize_owner(text)
    except OwnerConfigurationError:
        return text


def _has_convo_sources_dir(path: Path) -> bool:
    try:
        if not path.is_dir():
            return False
        if (path / "manifest.json").is_file():
            return True
        return any((path / subdir).is_dir() for subdir in CONVO_SUBDIRS)
    except OSError:
        return False


def _owner_mod_dir(owner: str) -> Path | None:
    desc = PACKAGE_DESCRIPTORS.get(owner)
    if desc is None or len(desc.shared_lua_relative.parts) < 3:
        return None
    return Path(*desc.shared_lua_relative.parts[:3])


def _read_json_mapping(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return None, f"unreadable JSON {path}: {error}"
    if not isinstance(payload, dict):
        return None, f"JSON root must be an object: {path}"
    return payload, None


def _manifest_files_in_repo(root: Path) -> list[Path]:
    paths: list[Path] = []
    if not root.is_dir():
        return paths
    try:
        paths.extend(sorted(root.glob("tools/providers/*/provider.json")))
        direct = root / "provider.json"
        if direct.is_file():
            paths.append(direct)
        core_desc = root / "tools/semantic_harness/provider.json"
        if core_desc.is_file():
            paths.append(core_desc)
    except OSError:
        return []
    seen: set[Path] = set()
    unique: list[Path] = []
    for path in paths:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique.append(resolved)
    return unique


@dataclass(frozen=True)
class SourceContribution:
    """One normalized conversation source root contributed by a workspace repo."""

    owner: str
    source_root: Path
    repository: Path
    manifest_path: Path | None = None
    provider_id: str | None = None
    origin: str = "provider_manifest"
    optional: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "owner": self.owner,
            "providerID": self.provider_id,
            "sourceRoot": str(self.source_root),
            "manifestPath": str(self.manifest_path) if self.manifest_path else None,
            "repository": str(self.repository),
            "origin": self.origin,
            "optional": self.optional,
        }


@dataclass(frozen=True)
class ProviderContribution:
    """Normalized provider summary surfaced inside ``WorkspaceSnapshot``."""

    provider_id: str
    display_name: str
    repository_kind: str
    repository_root: Path
    manifest_path: Path | None
    capabilities: tuple[str, ...] = ()
    materialization_modes: tuple[str, ...] = ("abstract",)
    runtime_modules: tuple[str, ...] = ()
    runtime_bootstraps: tuple[dict[str, Any], ...] = ()
    route_claims: Mapping[str, int] = field(default_factory=dict)
    requires: tuple[str, ...] = ()
    optional_requires: tuple[str, ...] = ()
    conflicts: tuple[str, ...] = ()
    optional: bool = True
    owners: tuple[str, ...] = ()
    conversation_sources: tuple[SourceContribution, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "providerID": self.provider_id,
            "displayName": self.display_name,
            "repositoryKind": self.repository_kind,
            "repository": str(self.repository_root),
            "manifestPath": str(self.manifest_path) if self.manifest_path else None,
            "capabilities": list(self.capabilities),
            "materializationModes": list(self.materialization_modes),
            "runtimeModules": list(self.runtime_modules),
            "runtimeBootstrap": list(self.runtime_bootstraps),
            "routeClaims": dict(self.route_claims),
            "requires": list(self.requires),
            "optionalRequires": list(self.optional_requires),
            "conflicts": list(self.conflicts),
            "optional": self.optional,
            "owners": list(self.owners),
            "conversationSources": [item.to_dict() for item in self.conversation_sources],
        }


@dataclass(frozen=True)
class WorkspaceSnapshot:
    """Immutable bounded workspace discovery snapshot (Port A)."""

    schema: str
    workspace_fingerprint: str
    core_repository: Path
    repository: Path
    providers: tuple[ProviderContribution, ...]
    source_contributions: tuple[SourceContribution, ...]
    repository_by_owner: Mapping[str, Path]
    source_roots_by_owner: Mapping[str, Path]
    all_source_roots_by_owner: Mapping[str, tuple[Path, ...]]
    manifest_paths_by_owner: Mapping[str, Path]
    warnings: tuple[str, ...] = ()

    def repository_for(self, owner: str) -> Path | None:
        canonical = _canonical_owner(owner)
        if canonical is None:
            return None
        return self.repository_by_owner.get(canonical)

    def source_roots_for(self, owner: str | None = None) -> list[tuple[str, Path]]:
        if owner is not None:
            canonical = _canonical_owner(owner)
            if canonical is None:
                return []
            roots = self.all_source_roots_by_owner.get(canonical, ())
            return [(canonical, root) for root in roots]
        pairs: list[tuple[str, Path]] = []
        for owner_name in sorted(self.all_source_roots_by_owner):
            for root in self.all_source_roots_by_owner[owner_name]:
                pairs.append((owner_name, root))
        return pairs

    def describe(
        self,
        *,
        max_providers: int = 32,
        max_warnings: int = 16,
    ) -> dict[str, Any]:
        """Return a bounded, agent-safe summary of discovered workspace authorities."""
        all_caps = sorted({
            cap
            for provider in self.providers
            for cap in provider.capabilities
        })
        all_modes = sorted({
            mode
            for provider in self.providers
            for mode in provider.materialization_modes
        })
        all_runtime = sorted({
            mod
            for provider in self.providers
            for mod in provider.runtime_modules
        })
        limited_providers = self.providers[: max(1, max_providers)]
        limited_warnings = self.warnings[: max(0, max_warnings)]
        return {
            "schema": self.schema,
            "workspaceFingerprint": self.workspace_fingerprint,
            "coreRepository": str(self.core_repository),
            "repository": str(self.repository),
            "providerCount": len(self.providers),
            "providers": [provider.to_dict() for provider in limited_providers],
            "providersTruncated": len(self.providers) > len(limited_providers),
            "repositories": {
                owner: str(path)
                for owner, path in sorted(self.repository_by_owner.items())
            },
            "sourceRoots": {
                owner: [str(path) for path in roots]
                for owner, roots in sorted(self.all_source_roots_by_owner.items())
            },
            "capabilities": all_caps,
            "materializationModes": all_modes,
            "runtimeModules": all_runtime,
            "warnings": list(limited_warnings),
            "warningCount": len(self.warnings),
            "warningsTruncated": len(self.warnings) > len(limited_warnings),
        }


def _extract_provider_sources(
    manifest: ProviderManifest,
    spec: ProviderSpec,
    warnings: list[str],
    external_root_hints: list[dict[str, Any]],
) -> tuple[list[SourceContribution], tuple[str, ...]]:
    """Extract conversation source roots and owners from one ``provider.json`` entry."""
    doc = manifest.document
    repo = manifest.repository_root.resolve()
    raw_specs: list[Any] = []
    if isinstance(doc.get("conversationSources"), list):
        raw_specs.extend(doc["conversationSources"])
    if isinstance(doc.get("conversationManifest"), str):
        raw_specs.append(doc["conversationManifest"])

    raw_providers = doc.get("providers")
    if isinstance(raw_providers, list):
        for raw_entry in raw_providers:
            if (
                isinstance(raw_entry, Mapping)
                and str(raw_entry.get("providerID", "")).strip() == spec.provider_id
                and isinstance(raw_entry.get("conversationSources"), list)
            ):
                raw_specs.extend(raw_entry["conversationSources"])

    primary_owner = _canonical_owner(doc.get("owner") or spec.provider_id)
    if spec.provider_id != CORE_OWNER and _canonical_owner(doc.get("providerID")):
        primary_owner = _canonical_owner(doc.get("providerID")) or primary_owner

    contributions: list[SourceContribution] = []
    seen_roots: set[tuple[str, Path]] = set()
    owners: list[str] = []
    if primary_owner and primary_owner in PACKAGE_DESCRIPTORS:
        owners.append(primary_owner)
    elif _canonical_owner(spec.provider_id) in PACKAGE_DESCRIPTORS:
        owners.append(str(_canonical_owner(spec.provider_id)))
    elif str(doc.get("providerID") or "").strip() == spec.provider_id and primary_owner:
        owners.append(primary_owner)

    for entry in raw_specs:
        if isinstance(entry, Mapping):
            raw_path = entry.get("path") or entry.get("manifest") or entry.get("sourceRoot")
            explicit_owner = _canonical_owner(entry.get("owner"))
            optional = bool(entry.get("optional", False))
        else:
            raw_path = entry
            explicit_owner = None
            optional = False
        if not isinstance(raw_path, str) or not raw_path.strip():
            continue
        candidate = (repo / raw_path.strip()).resolve()
        if candidate != repo and repo not in candidate.parents:
            warnings.append(
                f"{manifest.path}: ignoring conversation source outside repo: {raw_path}"
            )
            continue
        if candidate.is_file() and candidate.suffix.lower() == ".json":
            manifest_doc, err = _read_json_mapping(candidate)
            if manifest_doc is not None:
                for ext in manifest_doc.get("externalSourceRoots", []) or []:
                    if isinstance(ext, Mapping):
                        external_root_hints.append(dict(ext))
            src_owner = (
                explicit_owner
                or primary_owner
                or _canonical_owner(manifest_doc.get("defaultOwner") if manifest_doc else None)
            )
            src_root = candidate.parent.resolve()
            if err:
                warnings.append(f"{spec.provider_id}: {err}")
            if src_owner and (src_owner, src_root) not in seen_roots and _has_convo_sources_dir(src_root):
                seen_roots.add((src_owner, src_root))
                contributions.append(
                    SourceContribution(
                        owner=src_owner,
                        source_root=src_root,
                        repository=repo,
                        manifest_path=candidate,
                        provider_id=spec.provider_id,
                        origin="provider_manifest",
                        optional=optional,
                    )
                )
                if src_owner not in owners:
                    owners.append(src_owner)
        elif _has_convo_sources_dir(candidate):
            src_owner = explicit_owner or primary_owner
            if src_owner and (src_owner, candidate) not in seen_roots:
                seen_roots.add((src_owner, candidate))
                m_path = candidate / "manifest.json"
                contributions.append(
                    SourceContribution(
                        owner=src_owner,
                        source_root=candidate,
                        repository=repo,
                        manifest_path=m_path if m_path.is_file() else None,
                        provider_id=spec.provider_id,
                        origin="provider_manifest",
                        optional=optional,
                    )
                )
                if src_owner not in owners:
                    owners.append(src_owner)

    # Convention fallback relative to manifest location when no local root matched.
    if not contributions:
        convention_roots = [
            manifest.path.parent / "codebuilder/sources/conversation",
            repo / "tools/semantic_harness/codebuilder/sources/conversation",
        ]
        for conv_root in convention_roots:
            resolved_root = conv_root.resolve()
            if not _has_convo_sources_dir(resolved_root):
                continue
            manifest_file = resolved_root / "manifest.json"
            manifest_doc = None
            if manifest_file.is_file():
                manifest_doc, _ = _read_json_mapping(manifest_file)
                if manifest_doc is not None:
                    for ext in manifest_doc.get("externalSourceRoots", []) or []:
                        if isinstance(ext, Mapping):
                            external_root_hints.append(dict(ext))
            src_owner = (
                primary_owner
                or _canonical_owner(manifest_doc.get("defaultOwner") if manifest_doc else None)
            )
            if src_owner and (src_owner, resolved_root) not in seen_roots:
                seen_roots.add((src_owner, resolved_root))
                contributions.append(
                    SourceContribution(
                        owner=src_owner,
                        source_root=resolved_root,
                        repository=repo,
                        manifest_path=manifest_file if manifest_file.is_file() else None,
                        provider_id=spec.provider_id,
                        origin="layout_convention",
                    )
                )
                if src_owner not in owners:
                    owners.append(src_owner)
            break

    return contributions, tuple(owners)


def _infer_layout_owners(candidate: Path) -> list[tuple[str, Path | None, Path | None]]:
    """Fallback detector for minimal test repositories lacking ``provider.json``.

    Returns ``[(owner, source_root, manifest_path)]`` only when *candidate* has
    both owner mod/runtime markers or canonical manifest markers and no provider
    manifest already claimed it.
    """
    found: list[tuple[str, Path | None, Path | None]] = []
    try:
        if not candidate.is_dir():
            return found

        core_src = candidate / "tools/semantic_harness/codebuilder/sources/conversation"
        if (core_src / "manifest.json").is_file():
            found.append((CORE_OWNER, core_src.resolve(), (core_src / "manifest.json").resolve()))

        for owner, desc in PACKAGE_DESCRIPTORS.items():
            if owner == CORE_OWNER:
                continue
            mod_rel = _owner_mod_dir(owner)
            has_mod = mod_rel is not None and (candidate / mod_rel).is_dir()
            provider_roots = sorted(candidate.glob("tools/providers/*/codebuilder/sources/conversation"))
            matching_root = provider_roots[0].resolve() if provider_roots else None
            if has_mod and matching_root is not None:
                manifest_file = matching_root / "manifest.json"
                if manifest_file.is_file():
                    doc, _ = _read_json_mapping(manifest_file)
                    declared_owner = _canonical_owner(doc.get("defaultOwner") if doc else None)
                    if declared_owner is not None and declared_owner != owner:
                        continue
                # Confirm provider dir aligns with this owner when no manifest declares defaultOwner.
                provider_dir_name = matching_root.parents[2].name.lower()
                if provider_dir_name != owner.lower() and provider_dir_name not in desc.aliases:
                    continue
                found.append(
                    (
                        owner,
                        matching_root,
                        manifest_file.resolve() if manifest_file.is_file() else None,
                    )
                )
    except OSError:
        return found
    return found


class WorkspaceCatalog:
    """Single data-driven repository/provider/source discovery port (Port A)."""

    @classmethod
    def discover(
        cls,
        anchor: str | Path | None = None,
        *,
        repository: str | Path | None = None,
        core_repository: str | Path | None = None,
        hoomans_repository: str | Path | None = None,
        dynamic_trading_repository: str | Path | None = None,
        explicit_repositories: Iterable[str | Path] = (),
        owner_repositories: Mapping[str, str | Path] | None = None,
        required_owners: Iterable[str] = (),
        allow_sibling_discovery: bool = True,
        runtime_root: str | Path | None = None,
    ) -> WorkspaceSnapshot:
        """Resolve workspace providers, owners, and conversation source roots.

        Precedence guarantees explicit repository/owner overrides always beat
        environment variables, anchor/primary guesses, and sibling directories.
        Required unresolved owners fail closed.
        """
        warnings: list[str] = []
        anchor_path = Path(anchor).expanduser().resolve() if anchor is not None else None
        repo_path = Path(repository).expanduser().resolve() if repository is not None else None
        runtime_path = (
            Path(runtime_root).expanduser().resolve()
            if runtime_root is not None
            else (repo_path or anchor_path)
        )

        # Tier 1: explicit owner overrides.
        explicit_owner_repos: dict[str, Path] = {}
        if core_repository is not None:
            explicit_owner_repos[CORE_OWNER] = Path(core_repository).expanduser().resolve()
        if hoomans_repository is not None:
            explicit_owner_repos["ProjectHoomans"] = Path(hoomans_repository).expanduser().resolve()
        if dynamic_trading_repository is not None:
            explicit_owner_repos["DTCommon"] = Path(dynamic_trading_repository).expanduser().resolve()
        for raw_owner, raw_path in (owner_repositories or {}).items():
            canonical = _canonical_owner(raw_owner)
            if canonical:
                explicit_owner_repos[canonical] = Path(raw_path).expanduser().resolve()

        # Tier 2: environment variable overrides (only for owners not set explicitly).
        env_owner_repos: dict[str, Path] = {}
        for owner, desc in PACKAGE_DESCRIPTORS.items():
            if owner in explicit_owner_repos:
                continue
            env_name = desc.repository_environment
            if env_name:
                val = os.environ.get(env_name)
                if val:
                    env_owner_repos[owner] = Path(val).expanduser().resolve()

        # Organize candidate directories into ordered precedence tiers.
        tier1_paths: list[Path] = []
        for path in [*explicit_owner_repos.values(), *(Path(p).expanduser().resolve() for p in explicit_repositories)]:
            if path not in tier1_paths:
                tier1_paths.append(path)

        tier2_paths: list[Path] = []
        for path in env_owner_repos.values():
            if path not in tier1_paths and path not in tier2_paths:
                tier2_paths.append(path)

        tier3_paths: list[Path] = []
        for path in (repo_path, anchor_path):
            if path is not None and path not in tier1_paths and path not in tier2_paths and path not in tier3_paths:
                tier3_paths.append(path)

        tier4_paths: list[Path] = []
        temp_roots = {Path(tempfile.gettempdir()).resolve(), Path("/tmp").resolve()}
        if allow_sibling_discovery:
            parents: list[Path] = []
            for base in (*tier1_paths, *tier2_paths, *tier3_paths):
                parent = base.parent
                if parent not in parents and parent not in temp_roots:
                    parents.append(parent)
            for parent in parents:
                if not parent.is_dir():
                    continue
                try:
                    children = sorted(parent.iterdir())
                except OSError:
                    continue
                for child in children:
                    try:
                        if not child.is_dir():
                            continue
                    except OSError:
                        continue
                    resolved = child.resolve()
                    if (
                        resolved not in tier1_paths
                        and resolved not in tier2_paths
                        and resolved not in tier3_paths
                        and resolved not in tier4_paths
                    ):
                        tier4_paths.append(resolved)

        tiers = (
            ("explicit", tier1_paths),
            ("environment", tier2_paths),
            ("primary", tier3_paths),
            ("sibling", tier4_paths),
        )

        # Resolve candidate repositories tier by tier.
        # Seed explicit owner mappings first so lower-tier siblings never override or conflict.
        repository_by_owner: dict[str, Path] = dict(explicit_owner_repos)
        for owner, path in env_owner_repos.items():
            repository_by_owner.setdefault(owner, path)

        owner_tier: dict[str, str] = {
            owner: "explicit" for owner in explicit_owner_repos
        }
        for owner in env_owner_repos:
            owner_tier.setdefault(owner, "environment")

        providers_by_id: dict[str, ProviderContribution] = {}
        provider_tier_by_id: dict[str, str] = {}
        all_sources: list[SourceContribution] = []
        external_root_hints: list[dict[str, Any]] = []
        seen_manifests: set[Path] = set()

        def _claim_owner(owner: str, repo: Path, tier_name: str, *, same_tier_check: bool) -> bool:
            existing = repository_by_owner.get(owner)
            existing_tier = owner_tier.get(owner)
            if existing is not None:
                if existing == repo:
                    return True
                if existing_tier != tier_name:
                    # Higher-priority tier already pinned this owner.
                    return False
                if same_tier_check:
                    env_hint = (
                        PACKAGE_DESCRIPTORS[owner].repository_environment
                        if owner in PACKAGE_DESCRIPTORS
                        else ""
                    )
                    hint = f"pass explicit override or set {env_hint}" if env_hint else "pass explicit repository override"
                    raise WorkspaceResolutionError(
                        f"Ambiguous {owner} repository discovery ({existing}, {repo}); {hint}"
                    )
                return False
            repository_by_owner[owner] = repo
            owner_tier[owner] = tier_name
            return True

        for tier_name, paths in tiers:
            for candidate in paths:
                if not candidate.is_dir():
                    continue
                manifest_files = _manifest_files_in_repo(candidate)
                if manifest_files:
                    for m_file in manifest_files:
                        if m_file in seen_manifests:
                            continue
                        seen_manifests.add(m_file)
                        try:
                            manifest = ProviderManifest.load(m_file)
                        except ModManagerError as error:
                            warnings.append(str(error))
                            continue
                        # Check whether this manifest belongs to an owner pinned elsewhere.
                        for spec in manifest.providers:
                            sources, spec_owners = _extract_provider_sources(
                                manifest,
                                spec,
                                warnings,
                                external_root_hints,
                            )
                            existing_provider = providers_by_id.get(spec.provider_id)
                            if existing_provider is not None:
                                if existing_provider.repository_root == manifest.repository_root:
                                    continue
                                if provider_tier_by_id.get(spec.provider_id) != tier_name:
                                    # Higher priority tier already owns this provider.
                                    continue
                                if tier_name == "sibling":
                                    raise WorkspaceResolutionError(
                                        f"Ambiguous {spec.provider_id} repository discovery "
                                        f"({existing_provider.repository_root}, {manifest.repository_root})"
                                    )
                                continue

                            # Claim any owners declared by this spec/manifest.
                            accepted = True
                            owned_claimed: list[str] = []
                            for own in spec_owners:
                                if _claim_owner(
                                    own,
                                    manifest.repository_root.resolve(),
                                    tier_name,
                                    same_tier_check=(tier_name == "sibling"),
                                ):
                                    owned_claimed.append(own)
                                else:
                                    # If a sibling tries to claim an owner explicitly pinned elsewhere, skip.
                                    if own == _canonical_owner(spec.provider_id):
                                        accepted = False
                            if not accepted:
                                continue
                            # Filter sources to those whose owner points to this repository.
                            filtered_sources = [
                                src
                                for src in sources
                                if repository_by_owner.get(src.owner, src.repository) == src.repository
                            ]
                            contrib = ProviderContribution(
                                provider_id=spec.provider_id,
                                display_name=spec.display_name,
                                repository_kind=spec.repository_kind,
                                repository_root=manifest.repository_root.resolve(),
                                manifest_path=manifest.path.resolve(),
                                capabilities=spec.capabilities,
                                materialization_modes=spec.materialization_modes,
                                runtime_modules=spec.runtime_modules,
                                runtime_bootstraps=tuple(
                                    bootstrap.to_dict() for bootstrap in spec.runtime_bootstraps
                                ),
                                route_claims=dict(spec.route_claims),
                                requires=spec.requires,
                                optional_requires=spec.optional_requires,
                                conflicts=spec.conflicts,
                                optional=spec.optional,
                                owners=tuple(owned_claimed),
                                conversation_sources=tuple(filtered_sources),
                            )
                            providers_by_id[spec.provider_id] = contrib
                            provider_tier_by_id[spec.provider_id] = tier_name
                            all_sources.extend(filtered_sources)
                else:
                    # Fallback layout inspection only when candidate lacks provider.json.
                    for owner, src_root, m_path in _infer_layout_owners(candidate):
                        if not _claim_owner(
                            owner,
                            candidate.resolve(),
                            tier_name,
                            same_tier_check=(tier_name == "sibling"),
                        ):
                            continue
                        if src_root is not None:
                            all_sources.append(
                                SourceContribution(
                                    owner=owner,
                                    source_root=src_root,
                                    repository=candidate.resolve(),
                                    manifest_path=m_path,
                                    provider_id=None,
                                    origin="layout_convention",
                                )
                            )
                            warnings.append(
                                f"{owner}: discovered via layout convention without provider.json at {candidate}"
                            )

        # Ensure Core repository falls back cleanly to resolve_core_repository if not claimed via manifest/layout.
        resolved_core = repository_by_owner.get(CORE_OWNER)
        if resolved_core is None:
            resolved_core = resolve_core_repository(
                repo_path or anchor_path or Path.cwd(),
                explicit=explicit_owner_repos.get(CORE_OWNER),
                runtime_root=runtime_path,
            )
            repository_by_owner[CORE_OWNER] = resolved_core
            core_conv = resolved_core / "tools/semantic_harness/codebuilder/sources/conversation"
            if _has_convo_sources_dir(core_conv):
                m_path = core_conv / "manifest.json"
                all_sources.append(
                    SourceContribution(
                        owner=CORE_OWNER,
                        source_root=core_conv.resolve(),
                        repository=resolved_core,
                        manifest_path=m_path.resolve() if m_path.is_file() else None,
                        provider_id=CORE_OWNER,
                        origin="layout_convention",
                    )
                )

        # Resolve manifest externalSourceRoots hints across all resolved owner repositories.
        seen_source_pairs = {(src.owner, src.source_root) for src in all_sources}
        for hint in external_root_hints:
            ext_owner = _canonical_owner(hint.get("owner"))
            ext_path = hint.get("sourcePath")
            if not ext_owner or not isinstance(ext_path, str) or not ext_path.strip():
                continue
            owner_repo = repository_by_owner.get(ext_owner)
            if owner_repo is None:
                continue
            target = (owner_repo / ext_path.strip()).resolve()
            # externalSourceRoots typically point to a subdir such as .../conversation/dialogue;
            # derive the parent conversation root if target is a CONVO_SUBDIRS directory.
            conv_root = target.parent if target.name in CONVO_SUBDIRS else target
            if not _has_convo_sources_dir(conv_root):
                continue
            if (ext_owner, conv_root) not in seen_source_pairs:
                seen_source_pairs.add((ext_owner, conv_root))
                m_path = conv_root / "manifest.json"
                all_sources.append(
                    SourceContribution(
                        owner=ext_owner,
                        source_root=conv_root,
                        repository=owner_repo,
                        manifest_path=m_path.resolve() if m_path.is_file() else None,
                        provider_id=ext_owner,
                        origin="external_source_root",
                        optional=bool(hint.get("optional", False)),
                    )
                )

        # Also check any explicitly pinned owner repos that lack provider.json/external hints for convention root.
        for owner, owner_repo in list(repository_by_owner.items()):
            if any(src.owner == owner for src in all_sources):
                continue
            if not owner_repo.is_dir():
                continue
            candidates = [
                owner_repo / "tools/semantic_harness/codebuilder/sources/conversation",
                *sorted(owner_repo.glob("tools/providers/*/codebuilder/sources/conversation")),
            ]
            for cand in candidates:
                resolved = cand.resolve()
                if _has_convo_sources_dir(resolved) and (owner, resolved) not in seen_source_pairs:
                    seen_source_pairs.add((owner, resolved))
                    m_path = resolved / "manifest.json"
                    all_sources.append(
                        SourceContribution(
                            owner=owner,
                            source_root=resolved,
                            repository=owner_repo,
                            manifest_path=m_path.resolve() if m_path.is_file() else None,
                            provider_id=owner,
                            origin="layout_convention",
                        )
                    )
                    break

        # Validate required_owners (fail closed).
        for req in required_owners:
            canonical = _canonical_owner(req)
            if not canonical:
                continue
            repo_for_req = repository_by_owner.get(canonical)
            if repo_for_req is None or not repo_for_req.is_dir():
                raise WorkspaceResolutionError(
                    f"Required owner repository is unresolved or missing: {canonical}"
                )

        all_roots_by_owner_mut: dict[str, list[Path]] = {}
        primary_root_by_owner: dict[str, Path] = {}
        manifest_paths_by_owner: dict[str, Path] = {}
        for src in sorted(all_sources, key=lambda item: (item.owner, str(item.source_root))):
            bucket = all_roots_by_owner_mut.setdefault(src.owner, [])
            if src.source_root not in bucket:
                bucket.append(src.source_root)
            primary_root_by_owner.setdefault(src.owner, src.source_root)
            if src.manifest_path is not None:
                manifest_paths_by_owner.setdefault(src.owner, src.manifest_path)

        all_roots_by_owner = {
            owner: tuple(roots) for owner, roots in sorted(all_roots_by_owner_mut.items())
        }
        providers = tuple(
            providers_by_id[pid] for pid in sorted(providers_by_id)
        )
        ordered_repos = {
            owner: path for owner, path in sorted(repository_by_owner.items())
        }
        primary_repo = repo_path or resolved_core

        fp_payload = {
            "coreRepository": str(resolved_core),
            "repositories": {owner: str(path) for owner, path in ordered_repos.items()},
            "sourceRoots": {
                owner: [str(path) for path in roots]
                for owner, roots in all_roots_by_owner.items()
            },
            "providers": [provider.to_dict() for provider in providers],
        }
        return WorkspaceSnapshot(
            schema=WORKSPACE_SNAPSHOT_SCHEMA,
            workspace_fingerprint=fingerprint(fp_payload),
            core_repository=resolved_core,
            repository=primary_repo,
            providers=providers,
            source_contributions=tuple(
                sorted(all_sources, key=lambda item: (item.owner, str(item.source_root)))
            ),
            repository_by_owner=ordered_repos,
            source_roots_by_owner={k: primary_root_by_owner[k] for k in sorted(primary_root_by_owner)},
            all_source_roots_by_owner=all_roots_by_owner,
            manifest_paths_by_owner={
                k: manifest_paths_by_owner[k] for k in sorted(manifest_paths_by_owner)
            },
            warnings=tuple(warnings),
        )


__all__ = [
    "CONVO_SUBDIRS",
    "ProviderContribution",
    "SourceContribution",
    "WORKSPACE_SNAPSHOT_SCHEMA",
    "WorkspaceCatalog",
    "WorkspaceResolutionError",
    "WorkspaceSnapshot",
]
