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
from .repository_layout import RepositoryLayout, RepositoryLayoutError

__all__ = [
    "CORE_PROVIDER_ID",
    "ProfileDescriptor",
    "ProviderDescriptor",
    "ProviderRegistry",
    "RepositoryLayout",
    "RepositoryLayoutError",
    "ResolvedProfile",
]

__version__ = "0.1.0"
