"""Owner-aware CodeBuilder output routing for generated semantic artifacts."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

CORE_OWNER = "PsychopatzCore"
HOOMANS_OWNER = "ProjectHoomans"
DT_COMMON_OWNER = "DTCommon"

CORE_CONVERSATION_PREFIX = "PsychopatzCore/Semantics/Generated/Conversation"
HOOMANS_CONVERSATION_PREFIX = "PNC/Semantics/Generated/Conversation"
DT_COMMON_CONVERSATION_PREFIX = "DTCommon/Semantics/Generated/Conversation"

CORE_SHARED_RELATIVE = Path(
    "Contents/mods/PsychopatzCore/common/media/lua/shared"
)
HOOMANS_SHARED_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared"
)

CORE_TRANSLATION_RELATIVE = Path(
    "Contents/mods/PsychopatzCore/common/media/translation"
)
HOOMANS_TRANSLATION_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)
DT_COMMON_SHARED_RELATIVE = Path(
    "Contents/mods/DTCommon/common/media/lua/shared"
)
DT_COMMON_TRANSLATION_RELATIVE = Path(
    "Contents/mods/DTCommon/common/media/translation"
)


class OwnerConfigurationError(ValueError):
    """Raised when generated-artifact ownership cannot be resolved safely."""


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


PACKAGE_DESCRIPTORS = {
    CORE_OWNER: PackageDescriptor(
        owner=CORE_OWNER,
        aliases=("core", "psychopatzcore"),
        shared_lua_relative=CORE_SHARED_RELATIVE,
        conversation_prefix=CORE_CONVERSATION_PREFIX,
        translation_relative=CORE_TRANSLATION_RELATIVE,
        registry_module=CORE_CONVERSATION_PREFIX + "/Registry",
        registry_namespace="PsychopatzCore.Semantics.ConversationRegistry",
        translation_manifest_relative=Path("manifests/Conversation.json"),
        repository_environment="PZ_TEST_CORE_REPOSITORY",
    ),
    HOOMANS_OWNER: PackageDescriptor(
        owner=HOOMANS_OWNER,
        aliases=("hoomans", "projecthoomans", "pnc"),
        shared_lua_relative=HOOMANS_SHARED_RELATIVE,
        conversation_prefix=HOOMANS_CONVERSATION_PREFIX,
        translation_relative=HOOMANS_TRANSLATION_RELATIVE,
        registry_module=HOOMANS_CONVERSATION_PREFIX + "/Registry",
        registry_namespace="PNC.Semantics.ConversationRegistry",
        translation_manifest_relative=Path("manifests/Conversation.json"),
        capability_globs=(
            "Contents/mods/ProjectHoomans/*/media/lua/**/PNC_Semantic*.lua",
        ),
        repository_environment="PZ_TEST_HOOMANS_REPOSITORY",
    ),
    DT_COMMON_OWNER: PackageDescriptor(
        owner=DT_COMMON_OWNER,
        aliases=(
            "dt",
            "dtcommon",
            "dynamictrading",
            "dynamic_trading",
            "dynamic-trading",
        ),
        shared_lua_relative=DT_COMMON_SHARED_RELATIVE,
        conversation_prefix=DT_COMMON_CONVERSATION_PREFIX,
        translation_relative=DT_COMMON_TRANSLATION_RELATIVE,
        registry_module=DT_COMMON_CONVERSATION_PREFIX + "/Registry",
        registry_namespace="DTCommon.Semantics.ConversationRegistry",
        translation_manifest_relative=Path("manifests/Conversation.json"),
        capability_ids=("DT.trade",),
        capability_globs=(
            "Contents/mods/DTCommon/*/media/lua/**/DTCommon_Semantic*.lua",
        ),
        repository_environment="PZ_TEST_DYNAMIC_TRADING_REPOSITORY",
    ),
}


def _owner_key(value: Any) -> str:
    return (
        str(value or "")
        .strip()
        .lower()
        .replace(" ", "")
        .replace("_", "")
        .replace("-", "")
    )


_OWNER_KEYS = {
    _owner_key(descriptor.owner): descriptor.owner
    for descriptor in PACKAGE_DESCRIPTORS.values()
}
for _descriptor in PACKAGE_DESCRIPTORS.values():
    for _alias in _descriptor.aliases:
        _OWNER_KEYS[_owner_key(_alias)] = _descriptor.owner


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


def resolve_core_repository(
    project_repository: Path,
    *,
    explicit: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Resolve the Core checkout without coupling generated paths to Hoomans."""
    if explicit is not None:
        return explicit.expanduser().resolve()
    env = os.environ.get("PZ_TEST_CORE_REPOSITORY")
    if env:
        return Path(env).expanduser().resolve()
    base = (runtime_root or project_repository).expanduser().resolve()
    return (base.parent / "psychopatzCore").resolve()


def owner_repository(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    descriptor = package_descriptor(owner)
    if descriptor.owner == HOOMANS_OWNER:
        return project_repository.expanduser().resolve()
    if descriptor.owner == CORE_OWNER:
        return resolve_core_repository(
            project_repository,
            explicit=core_repository,
            runtime_root=runtime_root,
        )
    if descriptor.owner == DT_COMMON_OWNER:
        if dynamic_trading_repository is not None:
            return dynamic_trading_repository.expanduser().resolve()
        environment = descriptor.repository_environment
        configured = os.environ.get(environment) if environment else None
        if configured:
            return Path(configured).expanduser().resolve()
        raise OwnerConfigurationError(
            "DTCommon generation requires an explicit DynamicTrading "
            "repository or PZ_TEST_DYNAMIC_TRADING_REPOSITORY"
        )
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
