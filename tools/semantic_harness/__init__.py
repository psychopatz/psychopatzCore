"""Core-owned contracts for the provider-neutral semantic harness.

The executable worker and authoring application will move here incrementally.
This package intentionally contains no Project Hoomans or Dynamic Trading
imports. Adopters register providers through :mod:`provider_registry`.
"""

from .provider_registry import (
    CORE_PROVIDER_ID,
    ProfileDescriptor,
    ProviderDescriptor,
    ProviderRegistry,
    ResolvedProfile,
    SEMANTIC_EXECUTION_CALLBACKS,
    SEMANTIC_EXECUTION_SCHEMA,
)
from .codebuilder import CatalogNameError, CompileError
from .process import HarnessError, LuaProcess, WorkerLaunchSpec
from .profile_loader import ProfileSelection, ProviderRegistrar, compose_profile
from .runtime_discovery import (
    ConfigurationError,
    discover_lua,
    discover_newest_runtime,
    probe_lua,
)
from .repository_layout import RepositoryLayout, RepositoryLayoutError
from .scenario import (
    deep_merge,
    derive_actor_identifier,
    derive_display_name,
    load_json_document,
    save_json_document,
)
from .worker_session import (
    SessionClosedError,
    WorkerReady,
    WorkerResult,
    WorkerSession,
)

__all__ = [
    "CORE_PROVIDER_ID",
    "CatalogNameError",
    "CompileError",
    "ProfileDescriptor",
    "ProviderDescriptor",
    "ProviderRegistry",
    "ProfileSelection",
    "ProviderRegistrar",
    "compose_profile",
    "ConfigurationError",
    "discover_lua",
    "discover_newest_runtime",
    "probe_lua",
    "HarnessError",
    "LuaProcess",
    "SessionClosedError",
    "WorkerReady",
    "WorkerResult",
    "WorkerSession",
    "deep_merge",
    "derive_actor_identifier",
    "derive_display_name",
    "load_json_document",
    "RepositoryLayout",
    "RepositoryLayoutError",
    "ResolvedProfile",
    "SEMANTIC_EXECUTION_CALLBACKS",
    "SEMANTIC_EXECUTION_SCHEMA",
    "save_json_document",
    "WorkerLaunchSpec",
]

__version__ = "0.1.0"
