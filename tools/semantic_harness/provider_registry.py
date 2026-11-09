"""Provider and profile contracts for the Core semantic harness.

Core owns the registry mechanism, not adopter policy. Project Hoomans and
Dynamic Trading register descriptors from their own adapters; the Core worker
only consumes the resulting profile and never imports an adopter module by
name.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Mapping


CORE_PROVIDER_ID = "PsychopatzCore"
VALID_MATERIALIZATION_MODES = frozenset({"none", "abstract", "physical"})


class ProviderContractError(ValueError):
    """Raised when a provider or profile violates the harness contract."""


def _unique_strings(values: Iterable[str], field: str) -> tuple[str, ...]:
    normalized = tuple(str(value).strip() for value in values)
    if any(not value for value in normalized):
        raise ProviderContractError(f"{field} must not contain empty values")
    if len(set(normalized)) != len(normalized):
        raise ProviderContractError(f"{field} must not contain duplicates")
    return normalized


@dataclass(frozen=True)
class ProviderDescriptor:
    """A provider's declarative boundary, without executable imports."""

    provider_id: str
    display_name: str
    repository_kind: str = "external"
    requires: tuple[str, ...] = ()
    capabilities: tuple[str, ...] = ()
    materialization_modes: tuple[str, ...] = ("abstract",)
    optional: bool = True

    def __post_init__(self) -> None:
        provider_id = str(self.provider_id).strip()
        display_name = str(self.display_name).strip()
        repository_kind = str(self.repository_kind).strip()
        if not provider_id:
            raise ProviderContractError("provider_id is required")
        if not display_name:
            raise ProviderContractError(
                f"{provider_id}: display_name is required"
            )
        if not repository_kind:
            raise ProviderContractError(
                f"{provider_id}: repository_kind is required"
            )
        requires = _unique_strings(self.requires, f"{provider_id}.requires")
        capabilities = _unique_strings(
            self.capabilities, f"{provider_id}.capabilities"
        )
        modes = _unique_strings(
            self.materialization_modes,
            f"{provider_id}.materialization_modes",
        )
        unknown_modes = set(modes) - VALID_MATERIALIZATION_MODES
        if unknown_modes:
            raise ProviderContractError(
                f"{provider_id}: unknown materialization mode(s): "
                + ", ".join(sorted(unknown_modes))
            )
        if provider_id in requires:
            raise ProviderContractError(
                f"{provider_id}: provider cannot require itself"
            )
        object.__setattr__(self, "provider_id", provider_id)
        object.__setattr__(self, "display_name", display_name)
        object.__setattr__(self, "repository_kind", repository_kind)
        object.__setattr__(self, "requires", requires)
        object.__setattr__(self, "capabilities", capabilities)
        object.__setattr__(self, "materialization_modes", modes)

    def to_dict(self) -> dict[str, object]:
        return {
            "providerID": self.provider_id,
            "displayName": self.display_name,
            "repositoryKind": self.repository_kind,
            "requires": list(self.requires),
            "capabilities": list(self.capabilities),
            "materializationModes": list(self.materialization_modes),
            "optional": self.optional,
        }


@dataclass(frozen=True)
class ProfileDescriptor:
    """A deterministic composition of provider IDs for one harness mode."""

    profile_id: str
    display_name: str
    provider_ids: tuple[str, ...]
    materialization_mode: str = "none"

    def __post_init__(self) -> None:
        profile_id = str(self.profile_id).strip()
        display_name = str(self.display_name).strip()
        if not profile_id:
            raise ProviderContractError("profile_id is required")
        if not display_name:
            raise ProviderContractError(
                f"{profile_id}: display_name is required"
            )
        provider_ids = _unique_strings(
            self.provider_ids, f"{profile_id}.provider_ids"
        )
        if not provider_ids:
            raise ProviderContractError(
                f"{profile_id}: at least one provider is required"
            )
        if self.materialization_mode not in VALID_MATERIALIZATION_MODES:
            raise ProviderContractError(
                f"{profile_id}: invalid materialization mode "
                f"{self.materialization_mode!r}"
            )
        object.__setattr__(self, "profile_id", profile_id)
        object.__setattr__(self, "display_name", display_name)
        object.__setattr__(self, "provider_ids", provider_ids)

    def to_dict(self) -> dict[str, object]:
        return {
            "profileID": self.profile_id,
            "displayName": self.display_name,
            "providerIDs": list(self.provider_ids),
            "materializationMode": self.materialization_mode,
        }


@dataclass(frozen=True)
class ResolvedProfile:
    """A validated profile with providers in declared composition order."""

    profile: ProfileDescriptor
    providers: tuple[ProviderDescriptor, ...]

    @property
    def provider_ids(self) -> tuple[str, ...]:
        return tuple(provider.provider_id for provider in self.providers)

    def to_dict(self) -> dict[str, object]:
        return {
            "profile": self.profile.to_dict(),
            "providers": [provider.to_dict() for provider in self.providers],
        }


class ProviderRegistry:
    """Registry for provider descriptors and explicit profile compositions."""

    def __init__(self) -> None:
        self._providers: dict[str, ProviderDescriptor] = {}
        self._profiles: dict[str, ProfileDescriptor] = {}

    def register_provider(self, provider: ProviderDescriptor) -> ProviderDescriptor:
        existing = self._providers.get(provider.provider_id)
        if existing is not None and existing != provider:
            raise ProviderContractError(
                f"provider already registered with a different contract: "
                f"{provider.provider_id}"
            )
        self._providers[provider.provider_id] = provider
        return provider

    def register_profile(self, profile: ProfileDescriptor) -> ProfileDescriptor:
        existing = self._profiles.get(profile.profile_id)
        if existing is not None and existing != profile:
            raise ProviderContractError(
                f"profile already registered with a different contract: "
                f"{profile.profile_id}"
            )
        self._profiles[profile.profile_id] = profile
        return profile

    def provider(self, provider_id: str) -> ProviderDescriptor | None:
        return self._providers.get(provider_id)

    def profile(self, profile_id: str) -> ProfileDescriptor | None:
        return self._profiles.get(profile_id)

    def providers(self) -> tuple[ProviderDescriptor, ...]:
        return tuple(self._providers.values())

    def profiles(self) -> tuple[ProfileDescriptor, ...]:
        return tuple(self._profiles.values())

    def resolve(
        self,
        profile_id: str,
        *,
        available_provider_ids: Iterable[str] | None = None,
    ) -> ResolvedProfile:
        profile = self.profile(profile_id)
        if profile is None:
            raise ProviderContractError(f"unknown harness profile: {profile_id}")

        available = (
            set(self._providers)
            if available_provider_ids is None
            else set(available_provider_ids)
        )
        missing = [
            provider_id
            for provider_id in profile.provider_ids
            if provider_id not in self._providers or provider_id not in available
        ]
        if missing:
            raise ProviderContractError(
                f"profile {profile_id} is unavailable; missing provider(s): "
                + ", ".join(missing)
            )

        resolved: list[ProviderDescriptor] = []
        for provider_id in profile.provider_ids:
            provider = self._providers[provider_id]
            missing_dependencies = [
                dependency
                for dependency in provider.requires
                if dependency not in profile.provider_ids
            ]
            if missing_dependencies:
                raise ProviderContractError(
                    f"profile {profile_id} omits dependency(s) for "
                    f"{provider_id}: {', '.join(missing_dependencies)}"
                )
            if (
                profile.materialization_mode
                not in provider.materialization_modes
                and provider.provider_id != CORE_PROVIDER_ID
            ):
                raise ProviderContractError(
                    f"profile {profile_id} requests unsupported materialization "
                    f"mode {profile.materialization_mode!r} for {provider_id}"
                )
            resolved.append(provider)
        return ResolvedProfile(profile=profile, providers=tuple(resolved))

    def describe(self) -> dict[str, object]:
        return {
            "schema": "semantic.harness.provider_registry.v1",
            "providers": [
                provider.to_dict()
                for provider in sorted(
                    self._providers.values(), key=lambda item: item.provider_id
                )
            ],
            "profiles": [
                profile.to_dict()
                for profile in sorted(
                    self._profiles.values(), key=lambda item: item.profile_id
                )
            ],
        }


def core_registry() -> ProviderRegistry:
    """Return the minimal Core-only registry.

    Adopter packages extend this registry explicitly. Keeping this constructor
    Core-only is what allows the standalone Core and DTAbstract profiles to
    boot without Project Hoomans.
    """

    registry = ProviderRegistry()
    registry.register_provider(
        ProviderDescriptor(
            provider_id=CORE_PROVIDER_ID,
            display_name="PsychopatzCore semantic runtime",
            repository_kind="core",
            capabilities=(
                "semantic.parse",
                "semantic.ir",
                "semantic.conversation",
            ),
            materialization_modes=("none", "abstract", "physical"),
            optional=False,
        )
    )
    registry.register_profile(
        ProfileDescriptor(
            profile_id="core",
            display_name="Core-only semantic harness",
            provider_ids=(CORE_PROVIDER_ID,),
            materialization_mode="none",
        )
    )
    return registry


def register_provider_profile(
    registry: ProviderRegistry,
    *,
    provider: ProviderDescriptor,
    profile_id: str,
    profile_name: str,
    provider_ids: Iterable[str],
    materialization_mode: str,
) -> ResolvedProfile:
    """Register one adapter and its profile, returning its validation result."""

    registry.register_provider(provider)
    registry.register_profile(
        ProfileDescriptor(
            profile_id=profile_id,
            display_name=profile_name,
            provider_ids=tuple(provider_ids),
            materialization_mode=materialization_mode,
        )
    )
    return registry.resolve(profile_id)


def profile_capabilities(
    resolved: ResolvedProfile,
) -> Mapping[str, tuple[str, ...]]:
    """Return provider-owned capabilities without merging ownership."""

    return {
        provider.provider_id: provider.capabilities
        for provider in resolved.providers
    }
