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
)
from .codebuilder import CatalogNameError, CompileError
from .process import HarnessError, LuaProcess, WorkerLaunchSpec
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
    "save_json_document",
    "WorkerLaunchSpec",
]

__version__ = "0.1.0"
