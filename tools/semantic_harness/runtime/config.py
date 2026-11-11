"""Provider-neutral configuration backed by the Core mod manager."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Sequence

from ..providers.mod_manager import ModManager, ModManagerError
from ..transport.process import WorkerLaunchSpec
from ..transport.protocol import DEFAULT_MAX_MESSAGE_BYTES
from ..discovery.runtime import (
    ConfigurationError,
    discover_lua,
    discover_newest_runtime,
    discover_shared_runtime,
)


def _preset_names() -> tuple[str, ...]:
    path = Path(__file__).resolve().parents[1] / "selection_presets.json"
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
        presets = document.get("presets", {})
        if isinstance(presets, dict):
            return tuple(sorted(str(name) for name in presets))
    except (OSError, json.JSONDecodeError):
        pass
    return ("core",)


# Compatibility aliases remain data-defined. Core does not branch on adopter
# names; the manager resolves the selected preset/provider manifests.
PROFILE_ALIASES = {name: name for name in _preset_names()}


def _repository_marker(repository: Path, marker: str) -> bool:
    return (repository / "Contents/mods" / marker).is_dir()


def _looks_like_core(repository: Path) -> bool:
    return _repository_marker(repository, "PsychopatzCore") or (
        repository / "tools/semantic_harness/lua/worker.lua"
    ).is_file()


def discover_core_repository(
    explicit: str | Path | None = None,
    *,
    cwd: Path | None = None,
) -> Path:
    candidates: list[Path] = []
    if explicit is not None:
        candidates.append(Path(explicit))
    environment = os.environ.get("SEMANTIC_HARNESS_CORE_REPOSITORY")
    if environment:
        candidates.append(Path(environment))
    workshop_root = os.environ.get("SEMANTIC_HARNESS_WORKSHOP_ROOT")
    if workshop_root:
        candidates.append(Path(workshop_root) / "psychopatzCore")
    current = (cwd or Path.cwd()).resolve()
    candidates.extend((current, current.parent / "psychopatzCore"))
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if _looks_like_core(resolved):
            return resolved
    raise ConfigurationError(
        "could not locate PsychopatzCore repository; checked: "
        + ", ".join(str(item.expanduser()) for item in candidates)
    )


def _runtime_if_present(repository: Path | None, mod_id: str) -> str | None:
    if repository is None:
        return None
    mod_root = repository / "Contents/mods" / mod_id
    if not mod_root.is_dir():
        return None
    return discover_newest_runtime(mod_root)


def _provider_environment(config: "HarnessConfig") -> dict[str, str]:
    """Resolve provider-declared environment templates without provider branches."""

    plan = config.activation_plan or {}
    templates = plan.get("environment", {})
    repositories = plan.get("repositories", {})
    providers = plan.get("providers", [])
    if not isinstance(templates, dict) or not isinstance(repositories, dict):
        return {}

    runtimes: dict[str, str] = {}
    for provider in providers if isinstance(providers, list) else []:
        if not isinstance(provider, dict):
            continue
        provider_id = str(provider.get("providerID", ""))
        repository_value = repositories.get(provider_id)
        if not provider_id or not repository_value:
            continue
        repository = Path(str(repository_value)).expanduser().resolve()
        module_ids = tuple(
            str(value)
            for value in provider.get("runtimeModules", [])
            if str(value).strip()
        )
        if provider_id == "PsychopatzCore":
            runtime = _runtime_if_present(repository, "PsychopatzCore")
        elif module_ids:
            runtime = discover_shared_runtime(repository, module_ids)
        else:
            runtime = None
        if runtime is None:
            continue
        runtimes[provider_id] = runtime
        for module_id in module_ids:
            runtimes[module_id] = runtime

    resolved: dict[str, str] = {}
    for key, raw_value in templates.items():
        value = str(raw_value)
        for runtime_key, runtime in runtimes.items():
            value = value.replace(
                "${runtime:" + runtime_key + "}",
                runtime,
            )
        if "${runtime:" in value:
            raise ConfigurationError(
                f"provider environment {key} references an unavailable runtime"
            )
        resolved[str(key)] = value
    return resolved


@dataclass(frozen=True)
class HarnessConfig:
    """Resolved Core launch configuration and immutable activation plan."""

    repository: Path
    core_repository: Path
    lua_bin: Path
    worker_script: Path
    profile: str = "core"
    provider_ids: tuple[str, ...] = ("PsychopatzCore",)
    materialization_mode: str = "none"
    provider_module_paths: tuple[str, ...] = ()
    provider_modules: tuple[str, ...] = ()
    execution_provider_id: str | None = None
    provider_python_worker: str | None = None
    provider_python_scenario: str | None = None
    provider_worker_script: Path | None = None
    provider_worker_profile: str | None = None
    activation_plan: dict[str, Any] | None = None
    route_table: dict[str, str] | None = None
    candidate_overlay_root: Path | None = None
    candidate_overlay_module: str | None = None
    startup_timeout: float = 8.0
    request_timeout: float = 5.0
    shutdown_timeout: float = 1.0
    max_message_bytes: int = DEFAULT_MAX_MESSAGE_BYTES

    @classmethod
    def discover(
        cls,
        *,
        repository: str | Path | None = None,
        core_repository: str | Path | None = None,
        dynamic_trading_repository: str | Path | None = None,
        provider_roots: Sequence[str | Path] = (),
        mods: Sequence[str] | None = None,
        preset: str | None = None,
        lua_bin: str | Path | None = None,
        worker_script: str | Path | None = None,
        profile: str | None = "core",
        startup_timeout: float = 8.0,
        request_timeout: float = 5.0,
        shutdown_timeout: float = 1.0,
    ) -> "HarnessConfig":
        sibling_hint = repository or dynamic_trading_repository
        core_hint = core_repository
        if core_hint is None and sibling_hint is not None:
            core_hint = Path(sibling_hint).expanduser().resolve().parent / "psychopatzCore"
        core = discover_core_repository(
            core_hint,
            cwd=Path(sibling_hint).expanduser().resolve() if sibling_hint is not None else None,
        )
        roots: list[str | Path] = list(provider_roots)
        if repository is not None:
            roots.append(repository)
        if dynamic_trading_repository is not None:
            roots.append(dynamic_trading_repository)
        try:
            manager = ModManager.discover(
                core_repository=core,
                repository_roots=roots,
                cwd=sibling_hint or Path.cwd(),
            )
            selected = tuple(mods) if mods else None
            plan = manager.resolve(
                provider_ids=selected,
                preset=preset,
                alias=None if selected or preset else (profile or "core"),
            )
        except ModManagerError as error:
            raise ConfigurationError(str(error)) from error

        lua = discover_lua(lua_bin)
        core_worker = Path(worker_script) if worker_script else core / "tools/semantic_harness/lua/worker.lua"
        core_worker = core_worker.expanduser().resolve()
        if not core_worker.is_file():
            raise ConfigurationError(f"Core worker script does not exist: {core_worker}")

        config = cls(
            repository=plan.primary_repository,
            core_repository=core,
            lua_bin=lua,
            worker_script=core_worker,
            profile=plan.selection_id,
            provider_ids=plan.provider_ids,
            materialization_mode=plan.materialization_mode,
            provider_module_paths=plan.module_paths,
            provider_modules=plan.modules,
            execution_provider_id=plan.execution_provider_id,
            provider_python_worker=plan.python_worker,
            provider_python_scenario=plan.python_scenario,
            provider_worker_script=plan.worker_script,
            provider_worker_profile=plan.worker_profile,
            activation_plan=plan.to_dict(),
            route_table=dict(plan.routes),
            startup_timeout=float(startup_timeout),
            request_timeout=float(request_timeout),
            shutdown_timeout=float(shutdown_timeout),
        )
        activation_plan = dict(config.activation_plan or {})
        activation_plan["environment"] = _provider_environment(config)
        return replace(config, activation_plan=activation_plan)


def build_worker_launch_spec(config: HarnessConfig) -> WorkerLaunchSpec:
    """Create the neutral process spec shared by every selection."""

    environment: dict[str, str] = {
        "SEMANTIC_HARNESS_REPOSITORY": str(config.repository),
        "SEMANTIC_HARNESS_CORE_REPOSITORY": str(config.core_repository),
        "SEMANTIC_HARNESS_ACTIVATION_PLAN": json.dumps(
            config.activation_plan or {}, ensure_ascii=False, separators=(",", ":")
        ),
        "SEMANTIC_HARNESS_ROUTE_TABLE": ";".join(
            f"{capability}={provider}"
            for capability, provider in sorted((config.route_table or {}).items())
        ),
    }
    environment.update(_provider_environment(config))

    return WorkerLaunchSpec(
        lua_bin=config.lua_bin,
        worker_script=config.worker_script,
        core_repository=config.core_repository,
        working_directory=config.repository,
        profile=config.profile,
        provider_ids=config.provider_ids,
        materialization_mode=config.materialization_mode,
        provider_module_paths=config.provider_module_paths,
        provider_modules=config.provider_modules,
        execution_provider_id=config.execution_provider_id,
        environment=environment,
        startup_timeout=config.startup_timeout,
        request_timeout=config.request_timeout,
        shutdown_timeout=config.shutdown_timeout,
        max_message_bytes=config.max_message_bytes,
    )


__all__ = [
    "ConfigurationError",
    "HarnessConfig",
    "PROFILE_ALIASES",
    "build_worker_launch_spec",
    "discover_core_repository",
]
