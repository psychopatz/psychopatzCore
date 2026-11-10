"""Core-owned contracts for the provider-neutral semantic harness.

The executable worker lifecycle and reusable engine projections live here.
Provider gameplay policy and authoring applications remain in adopters.
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
from .worker import SemanticWorker
from .fixture_provider import OfflineEngineFixtureProvider
from .health import normalize_npc_health, normalize_scenario, validate_npc_health
from .item_catalog import (
    item_type_registry_fixture,
    search_item_catalog,
)
from .live_profiler_provider import LiveProfilerProvider
from .player_engine_state import (
    OfflinePlayerEngineStateProvider,
    PLAYER_WORLD_VERSION,
    PlayerEngineStateError,
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
    "SemanticWorker",
    "OfflineEngineFixtureProvider",
    "normalize_npc_health",
    "normalize_scenario",
    "validate_npc_health",
    "item_type_registry_fixture",
    "search_item_catalog",
    "LiveProfilerProvider",
    "OfflinePlayerEngineStateProvider",
    "PLAYER_WORLD_VERSION",
    "PlayerEngineStateError",
]

__version__ = "0.1.0"
