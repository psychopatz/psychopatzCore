"""Manifest-driven provider discovery and harness composition.

The manager is deliberately unaware of Project Hoomans and Dynamic Trading
behaviour.  It knows only provider manifests, dependency contracts, route
claims, and runtime entrypoints.  Product names appear in data presets and
provider manifests, never in resolver branches.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

from ..discovery.runtime import ConfigurationError, discover_newest_runtime


CORE_PROVIDER_ID = "PsychopatzCore"
VALID_MATERIALIZATION_MODES = frozenset({"none", "abstract", "physical"})


MANIFEST_SCHEMA = "semantic.provider_manifest.v2"
ACTIVATION_SCHEMA = "semantic.harness.activation.v1"


class ModManagerError(ValueError):
    """Raised when provider discovery or composition cannot be completed."""


def _strings(value: Any, field: str) -> tuple[str, ...]:
    if value is None:
        return ()
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, (list, tuple)):
        raise ModManagerError(f"{field} must be a string list")
    result = tuple(str(item).strip() for item in value)
    if any(not item for item in result):
        raise ModManagerError(f"{field} must not contain empty values")
    if len(set(result)) != len(result):
        raise ModManagerError(f"{field} must not contain duplicates")
    return result


def _mapping(value: Any, field: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, Mapping):
        raise ModManagerError(f"{field} must be an object")
    return {str(key): item for key, item in value.items()}


def _route_claims(value: Any, field: str) -> dict[str, int]:
    if value is None:
        return {}
    if isinstance(value, (list, tuple)):
        return {str(item).strip(): 0 for item in value if str(item).strip()}
    mapping = _mapping(value, field)
    result: dict[str, int] = {}
    for capability, priority in mapping.items():
        name = str(capability).strip()
        if not name:
            raise ModManagerError(f"{field} contains an empty capability")
        try:
            result[name] = int(priority)
        except (TypeError, ValueError) as error:
            raise ModManagerError(
                f"{field}.{name} must be an integer priority"
            ) from error
    return result


def _expanded(value: str | None, repository: Path) -> Path | None:
    if not value:
        return None
    return Path(
        str(value)
        .replace("${repository}", str(repository))
        .replace("${repo}", str(repository))
    ).expanduser().resolve()


@dataclass(frozen=True)
class RuntimeBootstrapSpec:
    """One live shared-runtime entrypoint owned by a provider manifest."""

    bootstrap_id: str
    entrypoint: str
    module_paths: tuple[str, ...] = ()
    required: bool = True

    def __post_init__(self) -> None:
        bootstrap_id = str(self.bootstrap_id).strip()
        entrypoint = str(self.entrypoint).strip()
        if not bootstrap_id:
            raise ModManagerError("runtime bootstrap id is required")
        if not entrypoint:
            raise ModManagerError(f"{bootstrap_id}: runtime entrypoint is required")
        object.__setattr__(self, "bootstrap_id", bootstrap_id)
        object.__setattr__(self, "entrypoint", entrypoint)
        object.__setattr__(
            self,
            "module_paths",
            _strings(self.module_paths, f"{bootstrap_id}.modulePaths"),
        )
        object.__setattr__(self, "required", bool(self.required))

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.bootstrap_id,
            "entrypoint": self.entrypoint,
            "modulePaths": list(self.module_paths),
            "required": self.required,
        }


def _runtime_bootstraps(value: Any, field: str) -> tuple[RuntimeBootstrapSpec, ...]:
    if value is None:
        return ()
    if isinstance(value, Mapping):
        value = [value]
    if not isinstance(value, (list, tuple)):
        raise ModManagerError(f"{field} must be an object list")
    result: list[RuntimeBootstrapSpec] = []
    seen: set[str] = set()
    for raw in value:
        if isinstance(raw, RuntimeBootstrapSpec):
            bootstrap = raw
        else:
            if not isinstance(raw, Mapping):
                raise ModManagerError(f"{field} entries must be objects")
            bootstrap = RuntimeBootstrapSpec(
                bootstrap_id=str(raw.get("id", raw.get("bootstrapID", ""))),
                entrypoint=str(raw.get("entrypoint", "")),
                module_paths=raw.get("modulePaths", ()),
                required=raw.get("required", True),
            )
        if bootstrap.bootstrap_id in seen:
            raise ModManagerError(
                f"{field} contains duplicate bootstrap {bootstrap.bootstrap_id}"
            )
        seen.add(bootstrap.bootstrap_id)
        result.append(bootstrap)
    return tuple(result)


@dataclass(frozen=True)
class ProviderSpec:
    """One executable or declarative provider exposed by a manifest."""

    provider_id: str
    display_name: str
    repository_kind: str
    repository_root: Path
    manifest_path: Path
    requires: tuple[str, ...] = ()
    optional_requires: tuple[str, ...] = ()
    conflicts: tuple[str, ...] = ()
    capabilities: tuple[str, ...] = ()
    route_claims: Mapping[str, int] = ()
    materialization_modes: tuple[str, ...] = ("abstract",)
    optional: bool = True
    lua_module_paths: tuple[str, ...] = ()
    lua_module: str | None = None
    python_worker: str | None = None
    python_scenario: str | None = None
    worker_script: Path | None = None
    worker_profile: str | None = None
    worker_priority: int = 0
    runtime_modules: tuple[str, ...] = ()
    runtime_bootstraps: tuple[RuntimeBootstrapSpec, ...] = ()
    environment: Mapping[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        provider_id = str(self.provider_id).strip()
        if not provider_id:
            raise ModManagerError("providerID is required")
        if not str(self.display_name).strip():
            raise ModManagerError(f"{provider_id}: displayName is required")
        modes = _strings(self.materialization_modes, f"{provider_id}.materializationModes")
        invalid = set(modes) - set(VALID_MATERIALIZATION_MODES)
        if invalid:
            raise ModManagerError(
                f"{provider_id}: invalid materialization mode(s): "
                + ", ".join(sorted(invalid))
            )
        object.__setattr__(self, "provider_id", provider_id)
        object.__setattr__(self, "display_name", str(self.display_name).strip())
        object.__setattr__(self, "repository_kind", str(self.repository_kind).strip())
        object.__setattr__(self, "requires", _strings(self.requires, f"{provider_id}.requires"))
        object.__setattr__(self, "optional_requires", _strings(self.optional_requires, f"{provider_id}.optionalRequires"))
        object.__setattr__(self, "conflicts", _strings(self.conflicts, f"{provider_id}.conflicts"))
        object.__setattr__(self, "capabilities", _strings(self.capabilities, f"{provider_id}.capabilities"))
        object.__setattr__(self, "materialization_modes", modes)
        object.__setattr__(self, "lua_module_paths", _strings(self.lua_module_paths, f"{provider_id}.luaModulePaths"))
        object.__setattr__(self, "runtime_modules", _strings(self.runtime_modules, f"{provider_id}.runtimeModules"))
        object.__setattr__(
            self,
            "runtime_bootstraps",
            _runtime_bootstraps(
                self.runtime_bootstraps,
                f"{provider_id}.runtimeBootstrap",
            ),
        )
        object.__setattr__(
            self,
            "environment",
            {
                str(key): str(value)
                for key, value in _mapping(self.environment, f"{provider_id}.environment").items()
            },
        )
        object.__setattr__(self, "lua_module", str(self.lua_module).strip() if self.lua_module else None)
        if self.provider_id in self.requires:
            raise ModManagerError(f"{provider_id}: provider cannot require itself")

    def to_dict(self) -> dict[str, Any]:
        return {
            "providerID": self.provider_id,
            "displayName": self.display_name,
            "repositoryKind": self.repository_kind,
            "repository": str(self.repository_root),
            "requires": list(self.requires),
            "optionalRequires": list(self.optional_requires),
            "conflicts": list(self.conflicts),
            "capabilities": list(self.capabilities),
            "routeClaims": dict(self.route_claims),
            "materializationModes": list(self.materialization_modes),
            "optional": self.optional,
            "luaModule": self.lua_module,
            "pythonWorker": self.python_worker,
            "pythonScenario": self.python_scenario,
            "workerScript": str(self.worker_script) if self.worker_script else None,
            "runtimeModules": list(self.runtime_modules),
            "runtimeBootstrap": [
                bootstrap.to_dict() for bootstrap in self.runtime_bootstraps
            ],
            "environment": dict(self.environment),
        }


@dataclass(frozen=True)
class ProviderManifest:
    """A manifest file and all provider specs declared by it."""

    path: Path
    repository_root: Path
    document: Mapping[str, Any]
    providers: tuple[ProviderSpec, ...]

    @classmethod
    def load(cls, path: str | Path) -> "ProviderManifest":
        manifest_path = Path(path).expanduser().resolve()
        try:
            document = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ModManagerError(f"invalid provider manifest: {manifest_path}") from error
        if not isinstance(document, Mapping):
            raise ModManagerError(f"provider manifest must be an object: {manifest_path}")
        # Standard manifests live at <repository>/tools/providers/<name>/;
        # expansion packs may expose a direct <repository>/provider.json.
        if (
            manifest_path.parent.name == "semantic_harness"
            and manifest_path.parent.parent.name == "tools"
        ):
            repository_root = manifest_path.parents[2]
        elif (
            len(manifest_path.parents) >= 4
            and manifest_path.parents[1].name == "providers"
            and manifest_path.parents[2].name == "tools"
        ):
            repository_root = manifest_path.parents[3]
        else:
            repository_root = manifest_path.parent
        top_paths = tuple(
            str(value)
            for value in document.get("luaModulePaths", [])
            if str(value).strip()
        )
        top_worker = document.get("pythonWorker")
        top_scenario = document.get("pythonScenario")
        top_script = _expanded(document.get("workerScript"), repository_root)
        top_profile = document.get("workerProfile")
        top_priority = int(document.get("workerPriority", 0))
        top_bootstraps = _runtime_bootstraps(
            document.get("runtimeBootstrap"),
            "runtimeBootstrap",
        )

        raw_providers = document.get("providers")
        if raw_providers is None:
            raise ModManagerError(
                f"provider manifest requires a providers list: {manifest_path}"
            )
        if not isinstance(raw_providers, (list, tuple)):
            raise ModManagerError(f"providers must be a list: {manifest_path}")

        providers: list[ProviderSpec] = []
        for raw in raw_providers:
            if not isinstance(raw, Mapping):
                raise ModManagerError(f"provider entries must be objects: {manifest_path}")
            provider_id = str(raw.get("providerID", "")).strip()
            if not provider_id:
                raise ModManagerError(f"provider entry is missing providerID: {manifest_path}")
            requires = raw.get("requires")
            if requires is None and provider_id != CORE_PROVIDER_ID:
                requires = (CORE_PROVIDER_ID,)
            module = raw.get("luaModule")
            providers.append(
                ProviderSpec(
                    provider_id=provider_id,
                    display_name=str(raw.get("displayName", document.get("displayName", provider_id))),
                    repository_kind=str(raw.get("repositoryKind", document.get("repositoryKind", "external"))),
                    repository_root=repository_root,
                    manifest_path=manifest_path,
                    requires=_strings(requires, f"{provider_id}.requires"),
                    optional_requires=raw.get("optionalRequires", ()),
                    conflicts=raw.get("conflicts", ()),
                    capabilities=raw.get("capabilities", ()),
                    route_claims=_route_claims(raw.get("routeClaims", raw.get("routes")), f"{provider_id}.routeClaims"),
                    materialization_modes=raw.get("materializationModes", document.get("materializationModes", ("abstract",))),
                    optional=bool(raw.get("optional", provider_id != CORE_PROVIDER_ID)),
                    lua_module_paths=raw.get("luaModulePaths", top_paths),
                    lua_module=str(module) if module else None,
                    python_worker=raw.get("pythonWorker", top_worker),
                    python_scenario=raw.get("pythonScenario", top_scenario),
                    worker_script=_expanded(raw.get("workerScript", document.get("workerScript")), repository_root) or top_script,
                    worker_profile=raw.get("workerProfile", top_profile),
                    worker_priority=int(raw.get("workerPriority", top_priority)),
                    runtime_modules=raw.get("runtimeModules", ()),
                    runtime_bootstraps=raw.get(
                        "runtimeBootstrap",
                        top_bootstraps,
                    ),
                    environment=raw.get("environment", {}),
                )
            )
        return cls(
            path=manifest_path,
            repository_root=repository_root,
            document=document,
            providers=tuple(providers),
        )


@dataclass(frozen=True)
class ActivationPlan:
    """Deterministic composition consumed by Python and Lua workers."""

    selection_id: str
    enabled: tuple[ProviderSpec, ...]
    load_order: tuple[str, ...]
    materialization_mode: str
    routes: Mapping[str, str]
    module_paths: tuple[str, ...]
    modules: tuple[str, ...]
    primary_repository: Path
    repository_by_provider: Mapping[str, Path]
    runtime_bootstraps: tuple[Mapping[str, Any], ...] = ()
    python_worker: str | None = None
    python_scenario: str | None = None
    worker_script: Path | None = None
    worker_profile: str | None = None
    execution_provider_id: str | None = None
    environment: Mapping[str, str] = field(default_factory=dict)

    @property
    def provider_ids(self) -> tuple[str, ...]:
        return tuple(provider.provider_id for provider in self.enabled)

    def repository_for(self, provider_id: str) -> Path | None:
        return self.repository_by_provider.get(provider_id)

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": ACTIVATION_SCHEMA,
            "selectionID": self.selection_id,
            "enabled": list(self.provider_ids),
            "loadOrder": list(self.load_order),
            "materializationMode": self.materialization_mode,
            "routes": dict(self.routes),
            "modules": {
                "paths": list(self.module_paths),
                "names": list(self.modules),
            },
            "repositories": {
                provider_id: str(path)
                for provider_id, path in self.repository_by_provider.items()
            },
            "providers": [provider.to_dict() for provider in self.enabled],
            "runtimeBootstraps": [dict(item) for item in self.runtime_bootstraps],
            "executionProviderID": self.execution_provider_id,
            "environment": dict(self.environment),
        }


def _unique_paths(values: Iterable[str | Path]) -> tuple[str, ...]:
    result: list[str] = []
    for value in values:
        rendered = str(Path(value).expanduser().resolve())
        if rendered not in result:
            result.append(rendered)
    return tuple(result)


def _expand_environment_template(
    value: str,
    provider: ProviderSpec,
    repository_by_provider: Mapping[str, Path],
    core_repository: Path,
) -> str:
    expanded = str(value)
    expanded = expanded.replace("${repository}", str(provider.repository_root))
    expanded = expanded.replace("${repo}", str(provider.repository_root))
    expanded = expanded.replace("${coreRepository}", str(core_repository))
    for provider_id, repository in repository_by_provider.items():
        expanded = expanded.replace(
            "${repository:" + provider_id + "}", str(repository)
        )
        expanded = expanded.replace("${provider:" + provider_id + "}", str(repository))
    return expanded


def _runtime_values(providers: Sequence[ProviderSpec]) -> dict[str, str]:
    """Resolve manifest runtime tokens against the live repository roots."""

    values: dict[str, str] = {}
    for provider in providers:
        for module_id in provider.runtime_modules:
            mod_root = provider.repository_root / "Contents" / "mods" / module_id
            if not mod_root.is_dir():
                continue
            try:
                runtime = discover_newest_runtime(mod_root)
            except ConfigurationError:
                continue
            previous = values.get(module_id)
            if previous is not None and previous != runtime:
                raise ModManagerError(
                    f"runtime {module_id} resolves to conflicting versions: "
                    f"{previous}, {runtime}"
                )
            values[module_id] = runtime
    return values


def _expand_runtime_template(
    value: str,
    provider: ProviderSpec,
    repository_by_provider: Mapping[str, Path],
    core_repository: Path,
    runtimes: Mapping[str, str],
) -> str:
    expanded = _expand_environment_template(
        value,
        provider,
        repository_by_provider,
        core_repository,
    )
    for runtime_id, runtime in runtimes.items():
        expanded = expanded.replace("${runtime:" + runtime_id + "}", runtime)
    if "${runtime:" in expanded:
        raise ModManagerError(
            f"{provider.provider_id}: runtime template cannot be resolved: {value}"
        )
    return expanded


class ModManager:
    """Discover manifests and resolve arbitrary provider selections."""

    def __init__(
        self,
        core_repository: str | Path,
        providers: Iterable[ProviderSpec],
        *,
        presets: Mapping[str, Mapping[str, Any]] | None = None,
    ) -> None:
        self.core_repository = Path(core_repository).expanduser().resolve()
        self._providers: dict[str, ProviderSpec] = {
            provider.provider_id: provider for provider in providers
        }
        if CORE_PROVIDER_ID not in self._providers:
            descriptor = self.core_repository / "tools/semantic_harness/provider.json"
            if descriptor.is_file():
                core_manifest = ProviderManifest.load(descriptor)
                for provider in core_manifest.providers:
                    if provider.provider_id == CORE_PROVIDER_ID:
                        self._providers[CORE_PROVIDER_ID] = provider
                        break
            if CORE_PROVIDER_ID not in self._providers:
                self._providers[CORE_PROVIDER_ID] = ProviderSpec(
                    provider_id=CORE_PROVIDER_ID,
                    display_name="PsychopatzCore semantic runtime",
                    repository_kind="core",
                    repository_root=self.core_repository,
                    manifest_path=descriptor,
                    requires=(),
                    capabilities=("semantic.parse", "semantic.ir", "semantic.conversation"),
                    route_claims={"semantic.parse": 0, "semantic.ir": 0},
                    materialization_modes=("none", "abstract", "physical"),
                    optional=False,
                )
        if presets is None:
            presets = self._load_presets()
        self._presets = {str(name): dict(value) for name, value in presets.items()}

    @classmethod
    def discover(
        cls,
        *,
        core_repository: str | Path,
        repository_roots: Iterable[str | Path] = (),
        cwd: str | Path | None = None,
    ) -> "ModManager":
        core = Path(core_repository).expanduser().resolve()
        candidates: list[Path] = [core]
        candidates.extend(Path(root).expanduser().resolve() for root in repository_roots)
        current = Path(cwd or Path.cwd()).expanduser().resolve()
        candidates.extend((current, core.parent))
        if core.parent.is_dir():
            try:
                siblings = sorted(core.parent.iterdir())
            except OSError:
                siblings = []
            for child in siblings:
                try:
                    if child.is_dir():
                        candidates.append(child)
                except OSError:
                    continue
        manifests: list[ProviderManifest] = []
        seen_paths: set[Path] = set()
        for root in candidates:
            try:
                if not root.is_dir():
                    continue
                paths = sorted(root.glob("tools/providers/*/provider.json"))
                direct = root / "provider.json"
                if direct.is_file():
                    paths.append(direct)
                core_descriptor = root / "tools/semantic_harness/provider.json"
                if core_descriptor.is_file():
                    paths.append(core_descriptor)
            except OSError:
                continue
            for path in paths:
                resolved = path.resolve()
                if resolved in seen_paths:
                    continue
                seen_paths.add(resolved)
                manifests.append(ProviderManifest.load(resolved))
        providers: list[ProviderSpec] = []
        seen_ids: dict[str, Path] = {}
        for manifest in manifests:
            for provider in manifest.providers:
                previous = seen_ids.get(provider.provider_id)
                if previous is not None and previous != provider.manifest_path:
                    raise ModManagerError(
                        f"provider {provider.provider_id} is declared by both "
                        f"{previous} and {provider.manifest_path}"
                    )
                seen_ids[provider.provider_id] = provider.manifest_path
                providers.append(provider)
        return cls(core, providers)

    def _load_presets(self) -> Mapping[str, Mapping[str, Any]]:
        path = Path(__file__).resolve().parents[1] / "selection_presets.json"
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ModManagerError(f"invalid selection preset catalog: {path}") from error
        presets = document.get("presets") if isinstance(document, Mapping) else None
        if not isinstance(presets, Mapping):
            raise ModManagerError(f"selection preset catalog has no presets: {path}")
        return presets

    def provider(self, provider_id: str) -> ProviderSpec | None:
        return self._providers.get(str(provider_id).strip())

    def providers(self) -> tuple[ProviderSpec, ...]:
        return tuple(sorted(self._providers.values(), key=lambda item: item.provider_id))

    def presets(self) -> tuple[dict[str, Any], ...]:
        return tuple(
            {"presetID": name, **dict(value)}
            for name, value in sorted(self._presets.items())
        )

    def describe(self) -> dict[str, Any]:
        return {
            "schema": "semantic.harness.mod_manager.v1",
            "coreRepository": str(self.core_repository),
            "providers": [provider.to_dict() for provider in self.providers()],
            "presets": list(self.presets()),
        }

    def _requested(
        self,
        *,
        provider_ids: Sequence[str] | None,
        preset: str | None,
        alias: str | None,
    ) -> tuple[str, tuple[str, ...], Mapping[str, Any]]:
        if provider_ids:
            requested = _strings(provider_ids, "provider selection")
            if requested == (CORE_PROVIDER_ID,):
                raise ModManagerError(
                    "PsychopatzCore is infrastructure, not a standalone harness profile"
                )
            return "custom", requested, {}
        name = str(preset or alias or "").strip().lower()
        if not name:
            raise ModManagerError(
                "a product composition is required; PsychopatzCore is an "
                "infrastructure dependency, not a standalone harness profile"
            )
        if name == "core":
            raise ModManagerError(
                "PsychopatzCore is infrastructure, not a standalone harness profile"
            )
        if name not in self._presets:
            raise ModManagerError(f"unknown harness preset: {name}")
        document = self._presets[name]
        alias_of = document.get("aliasOf")
        if alias_of:
            alias_name = str(alias_of).strip().lower()
            if alias_name not in self._presets:
                raise ModManagerError(f"preset {name} aliases unknown preset {alias_name}")
            document = self._presets[alias_name]
        requested = _strings(document.get("providers"), f"preset {name}.providers")
        return name, requested, document

    def resolve(
        self,
        *,
        provider_ids: Sequence[str] | None = None,
        preset: str | None = None,
        alias: str | None = None,
    ) -> ActivationPlan:
        selection_id, requested, preset_document = self._requested(
            provider_ids=provider_ids,
            preset=preset,
            alias=alias,
        )
        selected: dict[str, ProviderSpec] = {}

        def add(provider_id: str, chain: tuple[str, ...] = ()) -> None:
            provider = self.provider(provider_id)
            if provider is None:
                raise ModManagerError(f"selection requires unavailable provider: {provider_id}")
            if provider_id in chain:
                cycle = " -> ".join(chain + (provider_id,))
                raise ModManagerError(f"provider dependency cycle: {cycle}")
            for dependency in provider.requires:
                add(dependency, chain + (provider_id,))
            selected[provider_id] = provider

        for provider_id in requested:
            add(provider_id)
        if CORE_PROVIDER_ID not in selected:
            add(CORE_PROVIDER_ID)

        selected_ids = set(selected)
        for provider in tuple(selected.values()):
            missing_optional = [dependency for dependency in provider.optional_requires if dependency not in self._providers]
            if missing_optional:
                continue
            for dependency in provider.optional_requires:
                if dependency in self._providers:
                    add(dependency)
                    selected_ids.add(dependency)
            conflicts = selected_ids.intersection(provider.conflicts)
            if conflicts:
                raise ModManagerError(
                    f"provider {provider.provider_id} conflicts with: "
                    + ", ".join(sorted(conflicts))
                )

        ordered: list[ProviderSpec] = []
        visiting: set[str] = set()
        visited: set[str] = set()

        def visit(provider: ProviderSpec) -> None:
            if provider.provider_id in visited:
                return
            if provider.provider_id in visiting:
                raise ModManagerError(f"provider dependency cycle at {provider.provider_id}")
            visiting.add(provider.provider_id)
            for dependency in provider.requires:
                visit(selected[dependency])
            visiting.remove(provider.provider_id)
            visited.add(provider.provider_id)
            ordered.append(provider)

        for provider in selected.values():
            visit(provider)

        requested_mode = preset_document.get("materializationMode")
        if requested_mode is None:
            levels = {"none": 0, "abstract": 1, "physical": 2}
            supported = set(VALID_MATERIALIZATION_MODES)
            for provider in ordered:
                supported.intersection_update(provider.materialization_modes)
            if not supported:
                raise ModManagerError(
                    "selected providers have no shared materialization mode"
                )
            requested_mode = max(supported, key=lambda mode: levels[mode])
        mode = str(requested_mode).lower()
        if mode not in VALID_MATERIALIZATION_MODES:
            raise ModManagerError(f"invalid selection materialization mode: {mode}")
        unsupported = [
            provider.provider_id
            for provider in ordered
            if provider.provider_id != CORE_PROVIDER_ID
            and mode not in provider.materialization_modes
        ]
        if unsupported:
            raise ModManagerError(
                f"selection materialization mode {mode} is unsupported by: "
                + ", ".join(unsupported)
            )

        explicit_routes = _mapping(preset_document.get("routes"), "preset routes")
        routes: dict[str, str] = {}
        for capability in sorted({
            capability
            for provider in ordered
            for capability in provider.route_claims
        } | set(explicit_routes)):
            override = explicit_routes.get(capability)
            if override is not None:
                owner = str(override)
                if owner not in selected_ids:
                    raise ModManagerError(
                        f"route {capability} selects unavailable provider {owner}"
                    )
                routes[capability] = owner
                continue
            claims = [
                (provider.route_claims[capability], provider.provider_id)
                for provider in ordered
                if capability in provider.route_claims
            ]
            if not claims:
                continue
            claims.sort(key=lambda item: (-item[0], item[1]))
            if len(claims) > 1 and claims[0][0] == claims[1][0]:
                raise ModManagerError(
                    f"route {capability} has competing owners: "
                    + ", ".join(provider_id for _, provider_id in claims)
                )
            routes[capability] = claims[0][1]

        module_paths: list[str] = []
        modules: list[str] = []
        repository_by_provider: dict[str, Path] = {}
        worker_candidates: list[ProviderSpec] = []
        for provider in ordered:
            repository_by_provider[provider.provider_id] = provider.repository_root
            module_paths.extend(
                str(value)
                .replace("${repository}", str(provider.repository_root))
                .replace("${repo}", str(provider.repository_root))
                for value in provider.lua_module_paths
            )
            if provider.lua_module:
                modules.append(provider.lua_module)
            if provider.python_worker:
                worker_candidates.append(provider)
        module_paths = list(_unique_paths(module_paths))
        modules = list(dict.fromkeys(modules))
        runtime_values = _runtime_values(ordered)
        runtime_bootstraps: list[dict[str, Any]] = []
        for provider in ordered:
            for bootstrap in provider.runtime_bootstraps:
                entrypoint = _expand_runtime_template(
                    bootstrap.entrypoint,
                    provider,
                    repository_by_provider,
                    self.core_repository,
                    runtime_values,
                )
                module_bootstrap_paths = tuple(
                    _expand_runtime_template(
                        module_path,
                        provider,
                        repository_by_provider,
                        self.core_repository,
                        runtime_values,
                    )
                    for module_path in bootstrap.module_paths
                )
                if bootstrap.required and not Path(entrypoint).is_file():
                    raise ModManagerError(
                        f"{provider.provider_id}: runtime bootstrap does not "
                        f"exist: {entrypoint}"
                    )
                runtime_bootstraps.append(
                    {
                        "id": bootstrap.bootstrap_id,
                        "providerID": provider.provider_id,
                        "entrypoint": entrypoint,
                        "modulePaths": list(module_bootstrap_paths),
                        "required": bootstrap.required,
                    }
                )
        worker_candidates.sort(key=lambda provider: (-provider.worker_priority, provider.provider_id))
        worker = worker_candidates[0] if worker_candidates else None
        primary = worker.repository_root if worker else ordered[-1].repository_root
        execution_provider_id = preset_document.get("executionProviderID")
        if execution_provider_id is not None:
            execution_provider_id = str(execution_provider_id)
            if execution_provider_id not in selected_ids:
                raise ModManagerError(
                    f"execution provider is not selected: {execution_provider_id}"
                )
        elif len([provider for provider in ordered if provider.lua_module]) == 1:
            execution_provider_id = next(
                provider.provider_id for provider in ordered if provider.lua_module
            )
        environment: dict[str, str] = {}
        for provider in ordered:
            for key, value in provider.environment.items():
                value = _expand_environment_template(
                    value,
                    provider,
                    repository_by_provider,
                    self.core_repository,
                )
                previous = environment.get(key)
                if previous is not None and previous != value:
                    raise ModManagerError(
                        f"environment key {key} has competing provider values"
                    )
                environment[key] = value
        return ActivationPlan(
            selection_id=selection_id,
            enabled=tuple(ordered),
            load_order=tuple(provider.provider_id for provider in ordered),
            materialization_mode=mode,
            routes=routes,
            module_paths=tuple(module_paths),
            modules=tuple(modules),
            primary_repository=primary,
            repository_by_provider=repository_by_provider,
            runtime_bootstraps=tuple(runtime_bootstraps),
            python_worker=worker.python_worker if worker else None,
            python_scenario=worker.python_scenario if worker else None,
            worker_script=worker.worker_script if worker else None,
            worker_profile=worker.worker_profile if worker else None,
            execution_provider_id=execution_provider_id,
            environment=environment,
        )


__all__ = [
    "ACTIVATION_SCHEMA",
    "MANIFEST_SCHEMA",
    "ActivationPlan",
    "ModManager",
    "ModManagerError",
    "ProviderManifest",
    "ProviderSpec",
    "RuntimeBootstrapSpec",
]
