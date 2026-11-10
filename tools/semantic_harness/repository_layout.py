"""Repository discovery for the provider-neutral semantic harness.

PsychopatzCore is required. Optional provider repositories are selected by
the requested profile.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


class RepositoryLayoutError(RuntimeError):
    """Raised when the requested harness repositories cannot be resolved."""


CORE_PROVIDER_ID = "PsychopatzCore"
HOOMANS_PROVIDER_ID = "ProjectHoomans"
DT_COMMON_PROVIDER_ID = "DTCommon"
DT_ABSTRACT_PROVIDER_ID = "DTAbstract"
DT_HOOMANS_PROVIDER_ID = "DTHoomans"

_MARKERS = {
    CORE_PROVIDER_ID: Path("Contents/mods/PsychopatzCore"),
    HOOMANS_PROVIDER_ID: Path("Contents/mods/ProjectHoomans"),
    DT_COMMON_PROVIDER_ID: Path("Contents/mods/DTCommon"),
    DT_ABSTRACT_PROVIDER_ID: Path("Contents/mods/DTAbstract"),
    DT_HOOMANS_PROVIDER_ID: Path("Contents/mods/DTHoomans"),
}

_ENVIRONMENTS = {
    "core": (
        "SEMANTIC_HARNESS_CORE_REPOSITORY",
    ),
    "hoomans": (
        "SEMANTIC_HARNESS_HOOMANS_REPOSITORY",
    ),
    "dynamic_trading": (
        "SEMANTIC_HARNESS_DYNAMIC_TRADING_REPOSITORY",
    ),
    "workshop_root": (
        "SEMANTIC_HARNESS_WORKSHOP_ROOT",
    ),
}


def _environment_value(name: str, environ: dict[str, str]) -> str | None:
    current = _ENVIRONMENTS[name]
    return environ.get(current)


def _candidate_path(value: str | Path) -> Path:
    return Path(value).expanduser().resolve()


def _has_marker(repository: Path, provider_id: str) -> bool:
    return (repository / _MARKERS[provider_id]).is_dir()


def _find_repository(
    *,
    provider_id: str,
    candidates: Iterable[str | Path],
    required: bool,
) -> Path | None:
    checked: list[str] = []
    for candidate in candidates:
        resolved = _candidate_path(candidate)
        rendered = str(resolved)
        if rendered in checked:
            continue
        checked.append(rendered)
        if _has_marker(resolved, provider_id):
            return resolved
    if required:
        marker = _MARKERS[provider_id]
        raise RepositoryLayoutError(
            f"could not locate {provider_id}; expected {marker} under: "
            + ", ".join(checked)
        )
    return None


@dataclass(frozen=True)
class RepositoryLayout:
    """Resolved repository roots used by a harness profile."""

    core_repository: Path
    hoomans_repository: Path | None = None
    dynamic_trading_repository: Path | None = None

    def __post_init__(self) -> None:
        core = _candidate_path(self.core_repository)
        if not _has_marker(core, CORE_PROVIDER_ID):
            raise RepositoryLayoutError(
                f"Core repository is invalid: {core}"
            )
        hoomans = (
            _candidate_path(self.hoomans_repository)
            if self.hoomans_repository is not None
            else None
        )
        if hoomans is not None and not _has_marker(hoomans, HOOMANS_PROVIDER_ID):
            raise RepositoryLayoutError(
                f"Project Hoomans repository is invalid: {hoomans}"
            )
        dynamic_trading = (
            _candidate_path(self.dynamic_trading_repository)
            if self.dynamic_trading_repository is not None
            else None
        )
        if dynamic_trading is not None and not _has_marker(
            dynamic_trading, DT_COMMON_PROVIDER_ID
        ):
            raise RepositoryLayoutError(
                f"Dynamic Trading repository is invalid: {dynamic_trading}"
            )
        object.__setattr__(self, "core_repository", core)
        object.__setattr__(self, "hoomans_repository", hoomans)
        object.__setattr__(self, "dynamic_trading_repository", dynamic_trading)

    def available_provider_ids(self) -> tuple[str, ...]:
        providers = [CORE_PROVIDER_ID]
        if self.hoomans_repository is not None:
            providers.append(HOOMANS_PROVIDER_ID)
        if self.dynamic_trading_repository is not None:
            providers.append(DT_COMMON_PROVIDER_ID)
            if _has_marker(self.dynamic_trading_repository, DT_ABSTRACT_PROVIDER_ID):
                providers.append(DT_ABSTRACT_PROVIDER_ID)
            if (
                self.hoomans_repository is not None
                and _has_marker(
                    self.dynamic_trading_repository, DT_HOOMANS_PROVIDER_ID
                )
            ):
                providers.append(DT_HOOMANS_PROVIDER_ID)
        return tuple(providers)

    def require_providers(self, provider_ids: Iterable[str]) -> None:
        available = set(self.available_provider_ids())
        missing = [provider_id for provider_id in provider_ids if provider_id not in available]
        if missing:
            raise RepositoryLayoutError(
                "requested profile requires unavailable provider(s): "
                + ", ".join(missing)
            )

    def to_dict(self) -> dict[str, object]:
        return {
            "schema": "semantic.harness.repository_layout.v1",
            "coreRepository": str(self.core_repository),
            "hoomansRepository": (
                str(self.hoomans_repository)
                if self.hoomans_repository is not None
                else None
            ),
            "dynamicTradingRepository": (
                str(self.dynamic_trading_repository)
                if self.dynamic_trading_repository is not None
                else None
            ),
            "availableProviders": list(self.available_provider_ids()),
        }


def discover_layout(
    *,
    core_repository: str | Path | None = None,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    cwd: str | Path | None = None,
    environ: dict[str, str] | None = None,
) -> RepositoryLayout:
    """Discover Core first and optional adopters independently."""

    env = dict(os.environ if environ is None else environ)
    current_directory = _candidate_path(cwd or Path.cwd())
    core_environment = _environment_value("core", env)
    core_candidates: list[str | Path] = []
    if core_repository is not None:
        core_candidates.append(core_repository)
    elif core_environment:
        core_candidates.append(core_environment)
    workshop_root = _environment_value("workshop_root", env)
    if workshop_root:
        core_candidates.append(_candidate_path(workshop_root) / "psychopatzCore")
    core_candidates.extend(
        (
            current_directory,
            current_directory / "psychopatzCore",
            current_directory.parent / "psychopatzCore",
        )
    )
    resolved_core = _find_repository(
        provider_id=CORE_PROVIDER_ID,
        candidates=core_candidates,
        required=True,
    )
    assert resolved_core is not None

    hoomans_environment = _environment_value("hoomans", env)
    hoomans_candidates: list[str | Path] = []
    if hoomans_repository is not None:
        hoomans_candidates.append(hoomans_repository)
    elif hoomans_environment:
        hoomans_candidates.append(hoomans_environment)
    hoomans_candidates.extend(
        (
            resolved_core.parent / "ProjectHoomans",
            current_directory / "ProjectHoomans",
        )
    )
    resolved_hoomans = _find_repository(
        provider_id=HOOMANS_PROVIDER_ID,
        candidates=hoomans_candidates,
        required=False,
    )

    dynamic_environment = _environment_value("dynamic_trading", env)
    dynamic_candidates: list[str | Path] = []
    if dynamic_trading_repository is not None:
        dynamic_candidates.append(dynamic_trading_repository)
    elif dynamic_environment:
        dynamic_candidates.append(dynamic_environment)
    dynamic_candidates.extend(
        (
            resolved_core.parent / "DynamicTrading",
            current_directory / "DynamicTrading",
        )
    )
    resolved_dynamic = _find_repository(
        provider_id=DT_COMMON_PROVIDER_ID,
        candidates=dynamic_candidates,
        required=False,
    )

    return RepositoryLayout(
        core_repository=resolved_core,
        hoomans_repository=resolved_hoomans,
        dynamic_trading_repository=resolved_dynamic,
    )
