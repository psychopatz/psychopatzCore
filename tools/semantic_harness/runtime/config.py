"""Provider-neutral configuration for the Core-owned semantic harness."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ..process import WorkerLaunchSpec
from ..protocol import DEFAULT_MAX_MESSAGE_BYTES
from ..runtime_discovery import ConfigurationError, discover_lua, discover_newest_runtime


PROFILE_ALIASES = {
    "pnc": "pnc",
    "core": "core",
    "dtabstract": "dtabstract",
    "dthoomans": "dthoomans",
    "combined": "combined",
}


def _repository_marker(repository: Path, marker: str) -> bool:
    return (repository / "Contents/mods" / marker).is_dir()


def discover_core_repository(explicit: str | Path | None = None, *, cwd: Path | None = None) -> Path:
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
        if _repository_marker(resolved, "PsychopatzCore"):
            return resolved
    raise ConfigurationError(
        "could not locate PsychopatzCore repository; checked: "
        + ", ".join(str(item.expanduser()) for item in candidates)
    )


def discover_repository(explicit: str | Path | None, *, marker: str, environment_name: str, core_repository: Path) -> Path:
    candidates: list[Path] = []
    if explicit is not None:
        candidates.append(Path(explicit))
    environment = os.environ.get(environment_name)
    if environment:
        candidates.append(Path(environment))
    candidates.extend(
        child
        for child in sorted(core_repository.parent.iterdir())
        if child.is_dir() and child != core_repository
    )
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if _repository_marker(resolved, marker):
            return resolved
    raise ConfigurationError(
        f"could not locate {marker} repository; checked: "
        + ", ".join(str(item.expanduser()) for item in candidates)
    )


def _provider_manifest(repository: Path, provider_id: str) -> dict[str, Any]:
    root = repository / "tools" / "providers"
    for path in sorted(root.glob("*/provider.json")) if root.is_dir() else []:
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ConfigurationError(f"invalid provider manifest: {path}") from error
        identifiers = set(document.get("providerIDs", []))
        if document.get("providerID"):
            identifiers.add(document["providerID"])
        if provider_id in identifiers:
            return document
    raise ConfigurationError(f"provider manifest for {provider_id} was not found under {repository}")


def _manifest_repository(
    explicit: str | Path | None,
    *,
    profile: str,
    environment_name: str,
    core_repository: Path,
) -> Path:
    """Find a provider repository by its declared Core profile membership."""

    candidates: list[Path] = []
    if explicit is not None:
        candidates.append(Path(explicit))
    environment = os.environ.get(environment_name)
    if environment:
        candidates.append(Path(environment))
    candidates.extend(
        child
        for child in sorted(core_repository.parent.iterdir())
        if child.is_dir() and child != core_repository
    )
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        manifests = sorted((resolved / "tools/providers").glob("*/provider.json"))
        for path in manifests:
            try:
                document = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as error:
                raise ConfigurationError(f"invalid provider manifest: {path}") from error
            if profile in document.get("profiles", []):
                return resolved
    raise ConfigurationError(
        f"no provider repository declares profile {profile!r}; checked: "
        + ", ".join(str(item.expanduser()) for item in candidates)
    )


def _manifest_for_profile(repository: Path, profile: str) -> dict[str, Any]:
    manifests = sorted((repository / "tools/providers").glob("*/provider.json"))
    for path in manifests:
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ConfigurationError(f"invalid provider manifest: {path}") from error
        if profile in document.get("profiles", []):
            return document
    raise ConfigurationError(
        f"provider repository {repository} has no manifest for profile {profile}"
    )


def _expand_paths(values: list[str], repository: Path) -> tuple[str, ...]:
    return tuple(
        value.replace("${repository}", str(repository)).replace("${repo}", str(repository))
        for value in values
    )


@dataclass(frozen=True)
class HarnessConfig:
    """Resolved Core launch configuration plus explicit provider metadata."""

    repository: Path
    core_repository: Path
    lua_bin: Path
    worker_script: Path
    dynamic_trading_repository: Path | None = None
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
    startup_timeout: float = 8.0
    request_timeout: float = 5.0
    shutdown_timeout: float = 1.0
    max_message_bytes: int = DEFAULT_MAX_MESSAGE_BYTES

    @classmethod
    def discover(cls, *, repository: str | Path | None = None, core_repository: str | Path | None = None, dynamic_trading_repository: str | Path | None = None, lua_bin: str | Path | None = None, worker_script: str | Path | None = None, profile: str = "core", startup_timeout: float = 8.0, request_timeout: float = 5.0, shutdown_timeout: float = 1.0) -> "HarnessConfig":
        normalized = PROFILE_ALIASES.get(str(profile or "core").strip().lower())
        if normalized is None:
            raise ConfigurationError(f"unsupported semantic harness profile: {profile}")
        core_hint = core_repository
        sibling_hint = repository or dynamic_trading_repository
        if core_hint is None and sibling_hint is not None:
            core_hint = Path(sibling_hint).expanduser().resolve().parent / "psychopatzCore"
        core = discover_core_repository(core_hint, cwd=Path(sibling_hint).expanduser().resolve() if sibling_hint is not None else None)
        repo = core
        dt_repository = None
        provider_ids = ["PsychopatzCore"]
        module_paths: list[str] = []
        modules: list[str] = []
        execution_provider_id = None
        python_worker = None
        python_scenario = None
        provider_worker_script = None
        provider_worker_profile = None
        materialization = "none"
        if normalized == "pnc":
            repo = _manifest_repository(
                repository,
                profile=normalized,
                environment_name="SEMANTIC_HARNESS_PNC_REPOSITORY",
                core_repository=core,
            )
            manifest = _manifest_for_profile(repo, normalized)
            provider_ids.extend(
                manifest.get("providerIDsByProfile", {}).get(
                    normalized,
                    manifest.get("providerIDs", [manifest["providerID"]]),
                )
            )
            module_paths.extend(_expand_paths(manifest.get("luaModulePaths", []), repo))
            modules.extend(manifest.get("luaModules", []))
            python_worker = manifest.get("pythonWorker")
            python_scenario = manifest.get("pythonScenario")
            worker_value = manifest.get("workerScript")
            if isinstance(worker_value, str) and worker_value:
                provider_worker_script = Path(
                    _expand_paths([worker_value], repo)[0]
                ).expanduser().resolve()
            provider_worker_profile = manifest.get("workerProfile")
            materialization = manifest.get("materializationByProfile", {}).get(
                normalized, "physical"
            )
        elif normalized in {"dtabstract", "dthoomans"}:
            repo = _manifest_repository(
                dynamic_trading_repository,
                profile=normalized,
                environment_name="SEMANTIC_HARNESS_DT_REPOSITORY",
                core_repository=core,
            )
            manifest = _manifest_for_profile(repo, normalized)
            dt_repository = repo
            provider_ids.extend(
                manifest.get("providerIDsByProfile", {}).get(
                    normalized,
                    manifest.get("providerIDs", [manifest["providerID"]]),
                )
            )
            module_paths.extend(_expand_paths(manifest.get("luaModulePaths", []), repo))
            selected = manifest.get("executionProviderByProfile", {}).get(normalized)
            if selected is None:
                selected = (manifest.get("providerIDs", []) or [manifest["providerID"]])[-1]
            selected_module = manifest.get("luaModulesByProvider", {}).get(selected)
            modules.append(selected_module or manifest.get("luaModules", [])[0])
            execution_provider_id = selected
            materialization = manifest.get("materializationByProfile", {}).get(
                normalized, "physical"
            )
        elif normalized == "combined":
            pnc = _manifest_repository(
                repository,
                profile=normalized,
                environment_name="SEMANTIC_HARNESS_PNC_REPOSITORY",
                core_repository=core,
            )
            dt = _manifest_repository(
                dynamic_trading_repository,
                profile=normalized,
                environment_name="SEMANTIC_HARNESS_DT_REPOSITORY",
                core_repository=core,
            )
            pnc_manifest = _manifest_for_profile(pnc, normalized)
            dt_manifest = _manifest_for_profile(dt, normalized)
            dt_repository = dt
            provider_ids.extend(
                pnc_manifest.get("providerIDsByProfile", {}).get(
                    normalized,
                    pnc_manifest.get("providerIDs", [pnc_manifest["providerID"]]),
                )
            )
            provider_ids.extend(
                item for item in dt_manifest.get("providerIDsByProfile", {}).get(
                    normalized,
                    dt_manifest.get("providerIDs", [dt_manifest["providerID"]]),
                )
                if item not in provider_ids
            )
            module_paths.extend(_expand_paths(pnc_manifest.get("luaModulePaths", []), pnc))
            module_paths.extend(_expand_paths(dt_manifest.get("luaModulePaths", []), dt))
            modules.extend(pnc_manifest.get("luaModules", []))
            dt_provider = dt_manifest.get("executionProviderByProfile", {}).get(
                normalized, dt_manifest.get("providerID")
            )
            dt_module = dt_manifest.get("luaModulesByProvider", {}).get(dt_provider)
            if dt_module is None:
                dt_module = (dt_manifest.get("luaModules", []) or [None])[0]
            if dt_module:
                modules.append(dt_module)
            python_worker = pnc_manifest.get("pythonWorker")
            python_scenario = pnc_manifest.get("pythonScenario")
            worker_value = pnc_manifest.get("workerScript")
            if isinstance(worker_value, str) and worker_value:
                provider_worker_script = Path(
                    _expand_paths([worker_value], pnc)[0]
                ).expanduser().resolve()
            provider_worker_profile = pnc_manifest.get("workerProfile")
            materialization = pnc_manifest.get("materializationByProfile", {}).get(
                normalized,
                dt_manifest.get("materializationByProfile", {}).get(normalized, "physical"),
            )
            repo = pnc
        lua = discover_lua(lua_bin)
        worker = Path(worker_script) if worker_script else core / "tools/semantic_harness/lua/worker.lua"
        worker = worker.expanduser().resolve()
        if not worker.is_file():
            raise ConfigurationError(f"Core worker script does not exist: {worker}")
        return cls(repository=repo, core_repository=core, dynamic_trading_repository=dt_repository, lua_bin=lua, worker_script=worker, profile=normalized, provider_ids=tuple(provider_ids), materialization_mode=materialization, provider_module_paths=tuple(module_paths), provider_modules=tuple(modules), execution_provider_id=execution_provider_id, provider_python_worker=python_worker, provider_python_scenario=python_scenario, provider_worker_script=provider_worker_script, provider_worker_profile=provider_worker_profile, startup_timeout=float(startup_timeout), request_timeout=float(request_timeout), shutdown_timeout=float(shutdown_timeout))


def build_worker_launch_spec(config: HarnessConfig) -> WorkerLaunchSpec:
    environment = {
        "SEMANTIC_HARNESS_REPOSITORY": str(config.repository),
        "SEMANTIC_HARNESS_CORE_REPOSITORY": str(config.core_repository),
    }
    if config.dynamic_trading_repository is not None:
        environment["SEMANTIC_HARNESS_DT_REPOSITORY"] = str(
            config.dynamic_trading_repository
        )
    core_mod = config.core_repository / "Contents/mods/PsychopatzCore"
    if core_mod.is_dir():
        environment["PZ_TEST_CORE_RUNTIME"] = discover_newest_runtime(core_mod)
    pnc_mod = config.repository / "Contents/mods/ProjectHoomans"
    if pnc_mod.is_dir():
        environment["PZ_TEST_HOOMANS_RUNTIME"] = discover_newest_runtime(pnc_mod)
    dt_root = config.dynamic_trading_repository or config.repository
    dt_mod = dt_root / "Contents/mods/DTCommon"
    if dt_mod.is_dir():
        environment["PZ_TEST_DYNAMIC_TRADING_RUNTIME"] = discover_newest_runtime(dt_mod)
    return WorkerLaunchSpec(lua_bin=config.lua_bin, worker_script=config.worker_script, core_repository=config.core_repository, working_directory=config.repository, profile=config.profile, provider_ids=config.provider_ids, materialization_mode=config.materialization_mode, provider_module_paths=config.provider_module_paths, provider_modules=config.provider_modules, execution_provider_id=config.execution_provider_id, environment=environment, startup_timeout=config.startup_timeout, request_timeout=config.request_timeout, shutdown_timeout=config.shutdown_timeout, max_message_bytes=config.max_message_bytes)


__all__ = ["ConfigurationError", "HarnessConfig", "build_worker_launch_spec", "discover_core_repository", "discover_newest_runtime"]
