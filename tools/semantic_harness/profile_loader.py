"""Provider-neutral profile composition for the Core semantic worker.

Core owns composition and validation.  Adopters supply optional registrar
callbacks; this module never imports an adopter by name and never decides
whether a provider materializes a physical body.
"""

from __future__ import annotations

from collections.abc import Callable, Iterable
from dataclasses import dataclass

from .provider_registry import (
    ProviderRegistry,
    ResolvedProfile,
    core_registry,
)


ProviderRegistrar = Callable[[ProviderRegistry], object]


@dataclass(frozen=True)
class ProfileSelection:
    """A validated profile plus the metadata needed by a generic worker."""

    resolved: ResolvedProfile

    @property
    def profile_id(self) -> str:
        return self.resolved.profile.profile_id

    @property
    def provider_ids(self) -> tuple[str, ...]:
        return self.resolved.provider_ids

    @property
    def materialization_mode(self) -> str:
        return self.resolved.profile.materialization_mode

    def launch_environment(self) -> dict[str, str]:
        """Return neutral environment metadata for the Core worker."""

        return {
            "SEMANTIC_HARNESS_PROFILE": self.profile_id,
            "SEMANTIC_HARNESS_PROVIDER_IDS": ",".join(self.provider_ids),
            "SEMANTIC_HARNESS_MATERIALIZATION_MODE": self.materialization_mode,
        }

    def to_dict(self) -> dict[str, object]:
        return {
            "schema": "semantic.harness.profile_selection.v1",
            "profile": self.resolved.to_dict(),
            "launchEnvironment": self.launch_environment(),
        }


def compose_profile(
    profile_id: str,
    *,
    registrars: Iterable[ProviderRegistrar] = (),
    available_provider_ids: Iterable[str] | None = None,
) -> ProfileSelection:
    """Compose and validate one profile from optional adopter registrars."""

    registry = core_registry()
    for registrar in registrars:
        result = registrar(registry)
        if result is not None and result is not registry:
            raise TypeError(
                "provider registrar must mutate and return the supplied "
                "ProviderRegistry or return None"
            )
    resolved = registry.resolve(
        profile_id,
        available_provider_ids=available_provider_ids,
    )
    return ProfileSelection(resolved=resolved)


__all__ = ["ProfileSelection", "ProviderRegistrar", "compose_profile"]
