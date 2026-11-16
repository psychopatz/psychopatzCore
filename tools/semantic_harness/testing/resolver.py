"""Provider-aware fixture root and file resolution for the Semantic Test subsystem."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Mapping, Sequence

from ..discovery.runtime import ConfigurationError
from ..providers.mod_manager import ActivationPlan, ModManagerError
from ..runtime.config import discover_mod_manager


class FixtureResolutionError(ValueError):
    """Raised when provider fixture roots or files cannot be resolved."""


def _ordered_roots_from_mapping(
    plan: Mapping[str, Any],
    kind: str,
) -> tuple[tuple[str, Path], ...]:
    raw_providers = plan.get("providers")
    if not isinstance(raw_providers, list):
        return ()
    by_id: dict[str, Mapping[str, Any]] = {}
    ordered_ids: list[str] = []
    for entry in raw_providers:
        if not isinstance(entry, Mapping):
            continue
        provider_id = str(entry.get("providerID", "")).strip()
        if not provider_id:
            continue
        by_id[provider_id] = entry
        ordered_ids.append(provider_id)

    prioritized: list[str] = []
    exec_id = plan.get("executionProviderID")
    if isinstance(exec_id, str) and exec_id in by_id:
        prioritized.append(exec_id)
    for pid in reversed(ordered_ids):
        if pid not in prioritized:
            prioritized.append(pid)

    roots: list[tuple[str, Path]] = []
    seen: set[Path] = set()
    for pid in prioritized:
        fixture_roots = by_id[pid].get("fixtureRoots")
        if not isinstance(fixture_roots, Mapping):
            continue
        raw_path = fixture_roots.get(kind)
        if not raw_path:
            continue
        resolved = Path(str(raw_path)).expanduser().resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        roots.append((pid, resolved))
    return tuple(roots)


def _active_provider_ids(plan: ActivationPlan | Mapping[str, Any]) -> tuple[str, ...]:
    if isinstance(plan, ActivationPlan):
        return plan.provider_ids
    raw_enabled = plan.get("enabled")
    if isinstance(raw_enabled, list):
        return tuple(str(item) for item in raw_enabled if str(item).strip())
    return ()


def resolve_fixture_roots(
    *,
    kind: str = "semantic",
    explicit_dir: str | Path | None = None,
    activation_plan: ActivationPlan | Mapping[str, Any] | None = None,
    repository: str | Path | None = None,
    core_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    provider_roots: Sequence[str | Path] = (),
    mods: Sequence[str] | None = None,
    preset: str | None = None,
    profile: str | None = None,
    cwd: str | Path | None = None,
) -> tuple[Path, ...]:
    """Resolve fixture root directories from an explicit path or active providers."""
    if explicit_dir is not None:
        resolved = Path(explicit_dir).expanduser().resolve()
        if not resolved.is_dir():
            raise FixtureResolutionError(f"Fixtures directory not found: {resolved}")
        return (resolved,)

    plan: ActivationPlan | Mapping[str, Any]
    if activation_plan is not None:
        plan = activation_plan
    else:
        try:
            manager = discover_mod_manager(
                repository=repository,
                core_repository=core_repository,
                dynamic_trading_repository=dynamic_trading_repository,
                provider_roots=provider_roots,
                cwd=cwd,
            )
            selected = tuple(mods) if mods else None
            plan = manager.resolve(
                provider_ids=selected,
                preset=preset,
                alias=None if selected or preset else (profile or "pnc"),
            )
        except (ConfigurationError, ModManagerError) as error:
            raise FixtureResolutionError(
                f"Could not resolve active providers for {kind!r} fixtures: {error}"
            ) from error

    if isinstance(plan, ActivationPlan):
        declared = plan.fixture_roots_for(kind)
    else:
        declared = _ordered_roots_from_mapping(plan, kind)

    if not declared:
        active = ", ".join(_active_provider_ids(plan)) or "none"
        raise FixtureResolutionError(
            f"No active provider declares fixtureRoots.{kind} (active providers: {active})"
        )

    verified: list[Path] = []
    for provider_id, path in declared:
        if not path.is_dir():
            raise FixtureResolutionError(
                f"Provider {provider_id} declared fixtureRoots.{kind} at missing directory: {path}"
            )
        verified.append(path)
    return tuple(verified)


def resolve_fixture_file(
    filename: str | Path,
    *,
    kind: str = "regression",
    explicit_dir: str | Path | None = None,
    activation_plan: ActivationPlan | Mapping[str, Any] | None = None,
    repository: str | Path | None = None,
    core_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    provider_roots: Sequence[str | Path] = (),
    mods: Sequence[str] | None = None,
    preset: str | None = None,
    profile: str | None = None,
    cwd: str | Path | None = None,
) -> Path:
    """Resolve a named fixture file from the active provider's fixture roots."""
    roots = resolve_fixture_roots(
        kind=kind,
        explicit_dir=explicit_dir,
        activation_plan=activation_plan,
        repository=repository,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        provider_roots=provider_roots,
        mods=mods,
        preset=preset,
        profile=profile,
        cwd=cwd,
    )
    rel = Path(filename)
    for root in roots:
        candidate = (root / rel).resolve()
        if candidate.is_file():
            return candidate
    raise FixtureResolutionError(
        f"Fixture file '{filename}' not found in {kind!r} fixture roots: "
        + ", ".join(str(root) for root in roots)
    )


__all__ = [
    "FixtureResolutionError",
    "resolve_fixture_file",
    "resolve_fixture_roots",
]
