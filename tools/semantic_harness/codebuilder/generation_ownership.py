"""Data-driven owner and target routing for generated semantic artifacts."""

from __future__ import annotations

import json
import os
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterator, Mapping

DEFAULT_TARGETS_PATH = Path(__file__).resolve().parent / "targets" / "pz_packages.json"
TARGET_REGISTRY_SCHEMA = "psychopatz.convo-engine.target-registry.v1"

# Compatibility constants for existing callers; routing itself is data-driven.
CORE_OWNER = "PsychopatzCore"
HOOMANS_OWNER = "ProjectHoomans"
DT_COMMON_OWNER = "DTCommon"


class OwnerConfigurationError(ValueError):
    """Raised when generated-artifact ownership or target routing cannot be resolved safely."""


@dataclass(frozen=True)
class PackageDescriptor:
    """Physical and logical targets for one semantic package owner."""

    owner: str
    aliases: tuple[str, ...]
    shared_lua_relative: Path
    conversation_prefix: str
    translation_relative: Path
    registry_module: str
    registry_namespace: str
    translation_manifest_relative: Path
    capability_ids: tuple[str, ...] = ()
    capability_globs: tuple[str, ...] = ()
    capability_fields: tuple[str, ...] = (
        "capabilityID",
        "capabilityRequired",
    )
    repository_environment: str | None = None
    repository_markers: tuple[str, ...] = ()
    source_root_relative: Path = Path("tools/semantic_harness/codebuilder/sources/conversation")
    backend: str = "pz-lua"
    localization_policy: str = "build42-json"
    capabilities: tuple[str, ...] = ("speech",)
    resolvers: tuple[str, ...] = ()
    is_core: bool = False
    is_default_project: bool = False
    social_policy_prefix: str | None = None
    social_policy_source_root_relative: Path | None = None
    autonomy_ad_prefix: str | None = None
    autonomy_ad_source_root_relative: Path | None = None
    reaction_policy_prefix: str | None = None
    reaction_policy_source_root_relative: Path | None = None
    work_scenario_prefix: str | None = None
    work_scenario_source_root_relative: Path | None = None


def _owner_key(value: Any) -> str:
    return (
        str(value or "")
        .strip()
        .lower()
        .replace(" ", "")
        .replace("_", "")
        .replace("-", "")
    )


def descriptor_from_mapping(owner: str, raw: Mapping[str, Any]) -> PackageDescriptor:
    """Construct a PackageDescriptor from a JSON target-registry entry."""
    if not isinstance(raw, Mapping):
        raise OwnerConfigurationError(f"Package descriptor for {owner!r} must be an object")
    required = ("sharedLuaRelative", "conversationPrefix", "translationRelative")
    for field in required:
        val = raw.get(field)
        if not isinstance(val, str) or not val.strip():
            raise OwnerConfigurationError(
                f"Package descriptor {owner!r} requires non-empty {field}"
            )
    prefix = str(raw["conversationPrefix"]).strip()
    registry_module = str(raw.get("registryModule") or f"{prefix}/Registry").strip()
    registry_ns = str(
        raw.get("registryNamespace") or f"{prefix.replace('/', '.')}.Registry"
    ).strip()
    return PackageDescriptor(
        owner=str(raw.get("owner") or owner).strip(),
        aliases=tuple(str(a) for a in (raw.get("aliases") or ())),
        shared_lua_relative=Path(str(raw["sharedLuaRelative"]).strip()),
        conversation_prefix=prefix,
        translation_relative=Path(str(raw["translationRelative"]).strip()),
        registry_module=registry_module,
        registry_namespace=registry_ns,
        translation_manifest_relative=Path(
            str(raw.get("translationManifestRelative") or "manifests/Conversation.json").strip()
        ),
        capability_ids=tuple(str(x) for x in (raw.get("capabilityIds") or ())),
        capability_globs=tuple(str(x) for x in (raw.get("capabilityGlobs") or ())),
        capability_fields=tuple(
            str(x)
            for x in (raw.get("capabilityFields") or ("capabilityID", "capabilityRequired"))
        ),
        repository_environment=(
            str(raw["repositoryEnvironment"]).strip()
            if raw.get("repositoryEnvironment")
            else None
        ),
        repository_markers=tuple(str(m) for m in (raw.get("repositoryMarkers") or ())),
        source_root_relative=Path(
            str(
                raw.get("sourceRootRelative")
                or "tools/semantic_harness/codebuilder/sources/conversation"
            ).strip()
        ),
        backend=str(raw.get("backend") or "pz-lua").strip(),
        localization_policy=str(raw.get("localizationPolicy") or "build42-json").strip(),
        capabilities=tuple(str(c) for c in (raw.get("capabilities") or ("speech",))),
        resolvers=tuple(str(r) for r in (raw.get("resolvers") or ())),
        is_core=bool(raw.get("isCore", False)),
        is_default_project=bool(raw.get("isDefaultProject", False)),
        social_policy_prefix=(
            str(raw["socialPolicyPrefix"]).strip()
            if raw.get("socialPolicyPrefix")
            else None
        ),
        social_policy_source_root_relative=(
            Path(str(raw["socialPolicySourceRootRelative"]).strip())
            if raw.get("socialPolicySourceRootRelative")
            else None
        ),
        autonomy_ad_prefix=(
            str(raw["autonomyAdPrefix"]).strip()
            if raw.get("autonomyAdPrefix")
            else None
        ),
        autonomy_ad_source_root_relative=(
            Path(str(raw["autonomyAdSourceRootRelative"]).strip())
            if raw.get("autonomyAdSourceRootRelative")
            else None
        ),
        reaction_policy_prefix=(
            str(raw["reactionPolicyPrefix"]).strip()
            if raw.get("reactionPolicyPrefix")
            else None
        ),
        reaction_policy_source_root_relative=(
            Path(str(raw["reactionPolicySourceRootRelative"]).strip())
            if raw.get("reactionPolicySourceRootRelative")
            else None
        ),
        work_scenario_prefix=(
            str(raw["workScenarioPrefix"]).strip()
            if raw.get("workScenarioPrefix")
            else None
        ),
        work_scenario_source_root_relative=(
            Path(str(raw["workScenarioSourceRootRelative"]).strip())
            if raw.get("workScenarioSourceRootRelative")
            else None
        ),
    )


PACKAGE_DESCRIPTORS: dict[str, PackageDescriptor] = {}
_OWNER_KEYS: dict[str, str] = {}


def _rebuild_owner_keys() -> None:
    _OWNER_KEYS.clear()
    for desc in PACKAGE_DESCRIPTORS.values():
        _OWNER_KEYS[_owner_key(desc.owner)] = desc.owner
        for alias in desc.aliases:
            _OWNER_KEYS[_owner_key(alias)] = desc.owner


def register_package_descriptor(descriptor: PackageDescriptor) -> None:
    """Register or update one data-driven package descriptor."""
    PACKAGE_DESCRIPTORS[descriptor.owner] = descriptor
    _rebuild_owner_keys()


def load_package_descriptors(path: Path = DEFAULT_TARGETS_PATH) -> dict[str, PackageDescriptor]:
    """Load package/target descriptors from a JSON registry file."""
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise OwnerConfigurationError(
            f"Target registry {path} must declare schema {TARGET_REGISTRY_SCHEMA!r} (got {type(raw).__name__!r})"
        )
    if raw.get("schema") != TARGET_REGISTRY_SCHEMA:
        raise OwnerConfigurationError(
            f"Target registry {path} must declare schema {TARGET_REGISTRY_SCHEMA!r} (got {raw.get('schema')!r})"
        )
    packages = raw.get("packages")
    if not isinstance(packages, Mapping) or not packages:
        raise OwnerConfigurationError(f"Target registry {path} must define non-empty packages")
    loaded: dict[str, PackageDescriptor] = {}
    for owner, entry in packages.items():
        desc = descriptor_from_mapping(str(owner), entry)
        loaded[desc.owner] = desc
    return loaded


def _initialize_builtin_descriptors() -> None:
    for desc in load_package_descriptors(DEFAULT_TARGETS_PATH).values():
        PACKAGE_DESCRIPTORS[desc.owner] = desc
    _rebuild_owner_keys()


_initialize_builtin_descriptors()


@contextmanager
def temporary_package_descriptors(
    extra: Mapping[str, Mapping[str, Any] | PackageDescriptor],
) -> Iterator[None]:
    """Temporarily register additional package descriptors (used by data-driven tests/plugins)."""
    snapshot = dict(PACKAGE_DESCRIPTORS)
    try:
        for owner, spec in extra.items():
            desc = (
                spec
                if isinstance(spec, PackageDescriptor)
                else descriptor_from_mapping(str(owner), spec)
            )
            PACKAGE_DESCRIPTORS[desc.owner] = desc
        _rebuild_owner_keys()
        yield
    finally:
        PACKAGE_DESCRIPTORS.clear()
        PACKAGE_DESCRIPTORS.update(snapshot)
        _rebuild_owner_keys()


def target_descriptor_for_owner(owner: Any) -> dict[str, Any]:
    """Return a capability_abi-compatible psychopatz.convo-engine.target.v1 descriptor for an owner."""
    desc = package_descriptor(owner)
    return {
        "schema": "psychopatz.convo-engine.target.v1",
        "target": desc.owner,
        "backend": desc.backend,
        "providedCapabilities": list(desc.capabilities),
        "providedResolvers": list(desc.resolvers),
        "outputRoots": {
            "lua": str(desc.shared_lua_relative),
            "translation": str(desc.translation_relative),
        },
        "localization": {"policy": desc.localization_policy},
    }


def combined_target_descriptor(owners: Any) -> dict[str, Any]:
    """Build a merged psychopatz.convo-engine.target.v1 descriptor across active package owners."""
    caps: set[str] = set()
    resolvers: set[str] = set()
    backends: set[str] = set()
    targets: list[str] = []
    for owner in owners:
        desc = package_descriptor(owner)
        targets.append(desc.owner)
        caps.update(desc.capabilities)
        resolvers.update(desc.resolvers)
        backends.add(desc.backend)
    if len(backends) > 1:
        raise OwnerConfigurationError(
            "cannot combine incompatible target backends in one build: "
            + ", ".join(sorted(backends))
        )
    backend = next(iter(backends)) if backends else "pz-lua"
    return {
        "schema": "psychopatz.convo-engine.target.v1",
        "target": "+".join(sorted(set(targets))) or "default",
        "backend": backend,
        "providedCapabilities": sorted(caps),
        "providedResolvers": sorted(resolvers),
    }


def package_descriptor(value: Any, *, default: Any = None) -> PackageDescriptor:
    """Resolve one explicit package owner or fail closed."""
    raw = value
    if raw is None or not str(raw).strip():
        raw = default
    key = _owner_key(raw)
    owner = _OWNER_KEYS.get(key)
    if owner is None:
        if key == "":
            raise OwnerConfigurationError(
                "semantic package owner is required; provide an explicit "
                "owner or manifest defaultOwner"
            )
        raise OwnerConfigurationError(
            "unknown semantic package owner: " + str(raw)
        )
    return PACKAGE_DESCRIPTORS[owner]


def normalize_owner(value: Any, *, default: Any = None) -> str:
    """Return a validated package owner used for artifact routing."""
    return package_descriptor(value, default=default).owner


def document_owner(
    document: dict[str, Any] | None,
    *,
    default_owner: Any = None,
) -> str:
    source = document.get("source") if isinstance(document, dict) else None
    owner = source.get("owner") if isinstance(source, dict) else None
    return normalize_owner(owner, default=default_owner)


def source_owner(model: dict[str, Any], source_shard: str | None) -> str:
    for report in model.get("shards") or []:
        if (
            isinstance(report, dict)
            and str(report.get("path") or "") == str(source_shard or "")
            and report.get("owner")
        ):
            return normalize_owner(report["owner"])
    documents = model.get("_source_documents") or {}
    document = documents.get(str(source_shard or ""))
    manifest = model.get("manifest")
    default_owner = (
        manifest.get("defaultOwner")
        if isinstance(manifest, dict)
        else None
    )
    return document_owner(
        document if isinstance(document, dict) else None,
        default_owner=default_owner,
    )


def conversation_prefix(owner: Any) -> str:
    return package_descriptor(owner).conversation_prefix


def route_module_for_owner(module: str, owner: Any) -> str:
    """Replace the generated Conversation package prefix for one owner."""
    target = conversation_prefix(owner)
    prefixes = sorted(
        (
            descriptor.conversation_prefix
            for descriptor in PACKAGE_DESCRIPTORS.values()
        ),
        key=len,
        reverse=True,
    )
    for prefix in prefixes:
        if module == prefix:
            return target
        if module.startswith(prefix + "/"):
            return target + module[len(prefix):]
    return module


def module_owner(module: str) -> str:
    matches = [
        descriptor
        for descriptor in PACKAGE_DESCRIPTORS.values()
        if module == descriptor.conversation_prefix
        or module.startswith(descriptor.conversation_prefix + "/")
    ]
    if not matches:
        raise OwnerConfigurationError(
            "cannot infer semantic package owner from module: " + str(module)
        )
    matches.sort(key=lambda descriptor: len(descriptor.conversation_prefix), reverse=True)
    return matches[0].owner


def _resolve_by_descriptor(
    project_repository: Path,
    descriptor: PackageDescriptor,
    *,
    explicit: Path | None = None,
    runtime_root: Path | None = None,
) -> Path | None:
    if explicit is not None:
        return explicit.expanduser().resolve()
    if descriptor.repository_environment:
        env = os.environ.get(descriptor.repository_environment)
        if env:
            return Path(env).expanduser().resolve()
    base = (runtime_root or project_repository).expanduser().resolve()
    if descriptor.repository_markers:
        if all((base / marker).exists() for marker in descriptor.repository_markers):
            return base
        for candidate in (base.parent / descriptor.owner, base.parent / descriptor.owner.lower()):
            if candidate.is_dir() and any((candidate / m).exists() for m in descriptor.repository_markers):
                return candidate.resolve()
        temp_roots = {Path(tempfile.gettempdir()).resolve(), Path("/tmp").resolve()}
        if base.parent.is_dir() and base.parent.resolve() not in temp_roots:
            try:
                children = sorted(base.parent.iterdir())
            except OSError:
                children = []
            for child in children:
                try:
                    if child.is_dir() and all((child / m).exists() for m in descriptor.repository_markers):
                        return child.resolve()
                except OSError:
                    continue
    return None


def resolve_core_repository(
    project_repository: Path,
    *,
    explicit: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Resolve the Core checkout without coupling generated paths to Hoomans."""
    if explicit is not None:
        return explicit.expanduser().resolve()
    core_desc = next((d for d in PACKAGE_DESCRIPTORS.values() if d.is_core), None)
    if core_desc is not None:
        resolved = _resolve_by_descriptor(
            project_repository, core_desc, explicit=explicit, runtime_root=runtime_root
        )
        if resolved is not None:
            return resolved
    base = (runtime_root or project_repository).expanduser().resolve()
    return (base.parent / "psychopatzCore").resolve()


def resolve_hoomans_repository(
    project_repository: Path,
    *,
    explicit: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Resolve the default project checkout when invoked from Core or ProjectHoomans."""
    if explicit is not None:
        return explicit.expanduser().resolve()
    proj_desc = next((d for d in PACKAGE_DESCRIPTORS.values() if d.is_default_project), None)
    if proj_desc is not None:
        resolved = _resolve_by_descriptor(
            project_repository, proj_desc, explicit=explicit, runtime_root=runtime_root
        )
        if resolved is not None:
            return resolved
    return project_repository.expanduser().resolve()


def owner_repository(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
    explicit_repositories: Mapping[str, Path] | None = None,
) -> Path:
    """Resolve the physical repository for *owner* purely from its PackageDescriptor."""
    descriptor = package_descriptor(owner)
    if explicit_repositories and descriptor.owner in explicit_repositories:
        return Path(explicit_repositories[descriptor.owner]).expanduser().resolve()
    if descriptor.is_core and core_repository is not None:
        return core_repository.expanduser().resolve()
    if descriptor.owner == DT_COMMON_OWNER and dynamic_trading_repository is not None:
        return dynamic_trading_repository.expanduser().resolve()
    if descriptor.repository_environment:
        configured = os.environ.get(descriptor.repository_environment)
        if configured:
            return Path(configured).expanduser().resolve()
    if descriptor.is_default_project:
        return project_repository.expanduser().resolve()
    if descriptor.is_core:
        return resolve_core_repository(
            project_repository,
            explicit=core_repository,
            runtime_root=runtime_root,
        )
    if descriptor.repository_markers:
        base = (runtime_root or project_repository).expanduser().resolve()
        if all((base / marker).exists() for marker in descriptor.repository_markers):
            return base
    raise OwnerConfigurationError(
        "no repository resolver configured for owner: " + descriptor.owner
    )


def shared_lua_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )
    return repository / package_descriptor(owner).shared_lua_relative


def translation_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )
    return repository / package_descriptor(owner).translation_relative


def generated_conversation_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Return the owning repository's generated Conversation directory."""
    return shared_lua_root(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    ) / package_descriptor(owner).conversation_prefix


def _generated_optional_domain_root(
    project_repository: Path,
    owner: Any,
    prefix: str | None,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path | None:
    if not prefix:
        return None
    return shared_lua_root(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    ) / prefix


def generated_social_policy_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Return the owning repository's generated SocialPolicy directory."""
    desc = package_descriptor(owner)
    prefix = desc.social_policy_prefix or f"{desc.owner}/SocialPolicy"
    return shared_lua_root(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    ) / prefix


def generated_autonomy_ad_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path | None:
    """Return the owning repository's generated AutonomyAd directory when configured."""
    return _generated_optional_domain_root(
        project_repository,
        owner,
        package_descriptor(owner).autonomy_ad_prefix,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )


def generated_reaction_policy_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path | None:
    """Return the owning repository's generated ReactionPolicy directory when configured."""
    return _generated_optional_domain_root(
        project_repository,
        owner,
        package_descriptor(owner).reaction_policy_prefix,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )


def generated_work_scenario_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path | None:
    """Return the owning repository's generated WorkScenario directory when configured."""
    return _generated_optional_domain_root(
        project_repository,
        owner,
        package_descriptor(owner).work_scenario_prefix,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )


def module_target(
    project_repository: Path,
    module: str,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> tuple[Path, Path]:
    owner = module_owner(module)
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )
    root = shared_lua_root(
        project_repository,
        owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=runtime_root,
    )
    return repository, root / (module + ".lua")
