"""Provider-neutral high-level semantic worker façade.

This module owns the lifecycle and source/working-world mechanics shared by
all semantic-harness adopters.  An adopter supplies scenario normalization,
validation, and (when needed) a bounded source-payload adapter; it does not
need to reimplement process ownership, source snapshots, reset behavior, or
restart handling.
"""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, Callable, Mapping

from .activity import ActivityLog, default_activity_path
from ..transport.process import LuaProcess, WorkerLaunchSpec
from .scenario import load_json_document
from .state import HarnessWorkingWorld, ImportedSourceSnapshot, Provenance


ScenarioNormalizer = Callable[[Mapping[str, Any]], dict[str, Any]]
ScenarioValidator = Callable[[Mapping[str, Any]], None]
RuntimeFactory = Callable[[WorkerLaunchSpec, ActivityLog], Any]


def _copy_scenario(scenario: Mapping[str, Any]) -> dict[str, Any]:
    if not isinstance(scenario, Mapping):
        raise ValueError("scenario must be an object")
    return deepcopy(dict(scenario))


def _validate_mapping(scenario: Mapping[str, Any]) -> None:
    if not isinstance(scenario, Mapping):
        raise ValueError("scenario must be an object")


class SemanticWorker:
    """Own one isolated worker and its provider-neutral world lifecycle.

    Adopters can override the ``_normalize_scenario``, ``_validate_scenario``,
    ``_build_source_payload``, ``_after_source_import``, and
    ``_load_scenario`` hooks to adapt provider data.  Those hooks are the
    provider boundary; process/session and working-world mechanics remain in
    Core.
    """

    def __init__(
        self,
        scenario: Mapping[str, Any],
        launch_spec: WorkerLaunchSpec,
        *,
        activity_log: ActivityLog | None = None,
        import_source_on_start: bool = False,
        runtime_factory: RuntimeFactory | None = None,
    ) -> None:
        normalized = self._prepare_scenario(scenario)
        self.source_snapshot = ImportedSourceSnapshot.from_scenario(
            normalized,
            source=Provenance.FIXTURE,
            source_id="fixture:synthetic-scenario",
            mode="developer_test",
        )
        self.working_world = HarnessWorkingWorld(self.source_snapshot)
        self.scenario = self.working_world.data
        self._import_source_on_start = bool(import_source_on_start)
        self.activity_log = activity_log or ActivityLog(
            path=default_activity_path(launch_spec.working_directory),
            client="api",
        )
        factory = runtime_factory or (
            lambda spec, log: LuaProcess(spec, activity_log=log)
        )
        self.runtime = factory(launch_spec, self.activity_log)
        try:
            self.runtime.start()
            if self._import_source_on_start:
                self.import_source(normalized)
        except Exception:
            self.runtime.close()
            raise

    def _normalize_scenario(
        self, scenario: Mapping[str, Any]
    ) -> dict[str, Any]:
        return _copy_scenario(scenario)

    def _validate_scenario(self, scenario: Mapping[str, Any]) -> None:
        _validate_mapping(scenario)

    def _prepare_scenario(
        self, scenario: Mapping[str, Any]
    ) -> dict[str, Any]:
        normalized = self._normalize_scenario(scenario)
        self._validate_scenario(normalized)
        return normalized

    def _build_source_payload(
        self, snapshot_data: dict[str, Any]
    ) -> dict[str, Any]:
        """Build the bounded import request for an adopter worker."""

        return {
            "scenario": deepcopy(snapshot_data["data"]),
            "metadata": deepcopy(snapshot_data["metadata"]),
            "provenance": deepcopy(snapshot_data["provenance"]),
            "providerPayloads": deepcopy(snapshot_data["providerPayloads"]),
        }

    def _after_source_import(
        self,
        snapshot: ImportedSourceSnapshot,
        response: dict[str, Any],
    ) -> dict[str, Any]:
        return response

    def _load_scenario(self, path: Path) -> dict[str, Any]:
        return load_json_document(path)

    @property
    def process(self) -> Any:
        """Compatibility access for diagnostics; prefer :meth:`status`."""

        return self.runtime.process

    def status(self) -> dict[str, Any]:
        return self.runtime.status()

    def _request(self, command: str, value: Any = None) -> dict[str, Any]:
        return self.runtime.request(command, value)

    def configure(self, scenario: Mapping[str, Any]) -> dict[str, Any]:
        """Apply a working-world draft without replacing its source."""

        normalized = self._prepare_scenario(scenario)
        response = self._request("CONFIG", normalized)
        self.working_world.replace(normalized)
        self.scenario = self.working_world.data
        return response

    def import_source(
        self,
        scenario: Mapping[str, Any],
        *,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str = "fixture:synthetic-scenario",
        mode: str = "developer_test",
        metadata: Mapping[str, Any] | None = None,
        provenance: Mapping[str, Any] | None = None,
        provider_payloads: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Install one immutable source and derive a fresh working world."""

        normalized = self._prepare_scenario(scenario)
        effective_provenance = deepcopy(dict(provenance or {}))
        default_source = (
            source.value
            if isinstance(source, Provenance)
            else str(source).upper()
        )
        valid_sources = {item.value for item in Provenance}
        if default_source not in valid_sources:
            default_source = Provenance.MISSING.value
        effective_provenance.setdefault("schema", "semantic.provenance.v1")
        effective_provenance.setdefault("defaultSource", default_source)
        effective_provenance.setdefault("paths", {})
        snapshot = ImportedSourceSnapshot.from_scenario(
            normalized,
            source=source,
            source_id=source_id,
            mode=mode,
            metadata=metadata,
            provenance=effective_provenance,
            provider_payloads=provider_payloads,
        )
        snapshot_data = snapshot.to_dict()
        response = self._request(
            "IMPORT_SOURCE",
            self._build_source_payload(snapshot_data),
        )
        self.source_snapshot = snapshot
        self.working_world = HarnessWorkingWorld(snapshot)
        self._sync_effective_scenario(response, establish_baseline=True)
        return self._after_source_import(snapshot, response)

    def reload_source(
        self,
        scenario: Mapping[str, Any] | None = None,
        *,
        path: Path | None = None,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str | None = None,
        mode: str = "developer_test",
    ) -> dict[str, Any]:
        """Explicitly reread/reinstall a source; reset never rereads it."""

        if path is not None:
            scenario = self._load_scenario(Path(path))
            source_id = source_id or f"fixture:file:{Path(path).resolve()}"
        if scenario is None:
            scenario = self.source_snapshot.to_dict()["data"]
        return self.import_source(
            scenario,
            source=source,
            source_id=source_id or "fixture:synthetic-scenario",
            mode=mode,
        )

    def _sync_effective_scenario(
        self, response: Mapping[str, Any], *, establish_baseline: bool = False
    ) -> None:
        scenario = response.get("scenario") if isinstance(response, Mapping) else None
        if isinstance(scenario, dict):
            if establish_baseline:
                self.working_world.set_baseline(scenario)
            else:
                self.working_world.replace(scenario)
            self.scenario = self.working_world.data

    def reset(self) -> dict[str, Any]:
        response = self._request("RESET")
        self._sync_effective_scenario(response)
        return response

    def reset_turn(self) -> dict[str, Any]:
        return self._request("RESET_TURN")

    def reset_conversation(self) -> dict[str, Any]:
        response = self._request("RESET_CONVERSATION")
        self._sync_effective_scenario(response)
        return response

    def reset_selected_actor(self, actor: str = "npc") -> dict[str, Any]:
        response = self._request("RESET_ACTOR_MUTATIONS", {"actor": str(actor)})
        self._sync_effective_scenario(response)
        return response

    def reset_working_world(self) -> dict[str, Any]:
        response = self._request("RESET_WORLD")
        self.working_world.reset()
        self._sync_effective_scenario(response)
        return response

    def capabilities(self) -> dict[str, Any]:
        return self._request("CAPABILITIES")

    def restart(self) -> dict[str, Any]:
        """Restart the worker and optionally rehydrate its immutable source."""

        self.runtime.close()
        self.runtime.start()
        if not self._import_source_on_start:
            return self.capabilities()
        source = self.source_snapshot.to_dict()
        return self.import_source(
            source["data"],
            source=source["metadata"].get(
                "sourceKind", Provenance.FIXTURE.value
            ),
            source_id=source["metadata"].get(
                "sourceID", "fixture:synthetic-scenario"
            ),
            mode=source["metadata"].get("mode", "developer_test"),
            metadata=source["metadata"],
            provenance=source["provenance"],
            provider_payloads=source["providerPayloads"],
        )

    def close(self) -> None:
        self.runtime.close()

    def __enter__(self) -> "SemanticWorker":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()


__all__ = ["SemanticWorker"]
