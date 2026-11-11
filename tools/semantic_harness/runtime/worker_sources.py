"""Source-provider operations for the semantic harness worker façade."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, Protocol

from tools.semantic_harness.fixture_provider import OfflineEngineFixtureProvider
from .live_profiler_provider import LiveProfilerProvider
from .save_browser import SavedWorldBrowser
from .save_catalog import SaveCatalog
from .save_import import SaveBackedImporter
from tools.semantic_harness.state import ImportedSourceSnapshot, Provenance


class _WorkerSourceHost(Protocol):
    source_snapshot: ImportedSourceSnapshot
    scenario: dict[str, Any]
    config: Any

    def import_source(
        self,
        scenario: dict[str, Any],
        *,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str = "fixture:synthetic-scenario",
        mode: str = "developer_test",
        metadata: dict[str, Any] | None = None,
        provenance: dict[str, Any] | None = None,
        provider_payloads: dict[str, Any] | None = None,
    ) -> dict[str, Any]: ...


class WorkerSourceOperations:
    """Coordinate optional source providers without owning worker state."""

    def __init__(self, host: _WorkerSourceHost) -> None:
        self._host = host

    def save_catalog(self, roots: list[Path] | None = None) -> dict[str, Any]:
        """Discover validated offline saves through PsychopatzCore's reader."""

        return SaveCatalog(
            roots,
            core_repository=self._host.config.core_repository,
        ).discover()

    def offline_fixture_catalog(self) -> dict[str, Any]:
        """Describe editable engine-only values and their fixture provenance."""

        return OfflineEngineFixtureProvider().catalog(self._host.scenario)

    def live_profiler_catalog(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Describe the optional read-only live snapshot provider."""

        return LiveProfilerProvider(
            core_repository=self._host.config.core_repository,
            snapshot_path=snapshot_path,
            config_path=config_path,
            enabled=enabled,
        ).catalog(npc_id=npc_id)

    def enrich_from_live_profiler(
        self,
        *,
        enabled: bool = False,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        player_id: str | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Copy eligible live engine values into the isolated source world."""

        provider = LiveProfilerProvider(
            core_repository=self._host.config.core_repository,
            snapshot_path=snapshot_path,
            config_path=config_path,
            enabled=enabled,
        )
        projection = provider.project(
            operation="GET_SNAPSHOT",
            player_id=player_id,
            npc_id=npc_id,
        )
        enrichment, live_paths = provider.fixture_enrichment(projection)
        if not enrichment:
            return {"ok": False, "liveProfiler": projection, "imported": False}

        def merge_overlay(target: dict[str, Any], overlay: dict[str, Any]) -> None:
            for key, value in overlay.items():
                if isinstance(value, dict) and isinstance(target.get(key), dict):
                    merge_overlay(target[key], value)
                else:
                    target[key] = deepcopy(value)

        source = self._host.source_snapshot.to_dict()
        enriched_data = deepcopy(source["data"])
        merge_overlay(enriched_data, enrichment)
        metadata = deepcopy(source["metadata"])
        metadata["liveProfiler"] = {
            "providerID": provider.provider_id,
            "snapshotPath": str(provider.snapshot_path),
            "configPath": str(provider.config_path),
            "snapshot": deepcopy(projection.get("snapshot")),
        }
        provenance = deepcopy(source["provenance"])
        provenance.setdefault("schema", "semantic.provenance.v1")
        provenance.setdefault("paths", {}).update(live_paths)
        provider_payloads = deepcopy(source["providerPayloads"])
        provider_payloads[provider.provider_id] = projection
        response = self._host.import_source(
            enriched_data,
            source=metadata.get("sourceKind", self._host.source_snapshot.source),
            source_id=str(metadata.get("sourceID") or "live-enriched-source"),
            mode=str(metadata.get("mode") or "offline_save"),
            metadata=metadata,
            provenance=provenance,
            provider_payloads=provider_payloads,
        )
        response["liveProfiler"] = projection
        response["imported"] = True
        response["enrichedPaths"] = sorted(live_paths)
        return response

    def save_browser(self, save_path: Path) -> dict[str, Any]:
        """Return a bounded read-only actor/world projection for one save."""

        return SavedWorldBrowser(
            core_repository=self._host.config.core_repository,
        ).browse(Path(save_path))

    def import_saved_selection(
        self,
        save_path: Path,
        *,
        player_uuid: str | None = None,
        npc_id: str | None = None,
        engine_fixtures: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Import one saved Player/NPC pair into the detached worker world."""

        selection = SaveBackedImporter(
            core_repository=self._host.config.core_repository,
        ).load(
            Path(save_path),
            player_uuid=player_uuid,
            npc_id=npc_id,
            engine_fixtures=engine_fixtures,
        )
        # The selected raw records are transported in the explicit
        # ProjectHoomans.rawRecords envelope. Do not send a second copy of
        # those same records through the legacy provider keys: large real-save
        # NPC records can otherwise exceed the Lua worker's bounded protocol
        # message size before production rehydration begins.
        provider_payloads = deepcopy(selection.provider_payloads)
        hoomans_payload = provider_payloads.get("ProjectHoomans")
        raw_records = (
            hoomans_payload.get("rawRecords")
            if isinstance(hoomans_payload, dict)
            else None
        )
        if isinstance(hoomans_payload, dict) and isinstance(raw_records, dict):
            npc_record = raw_records.get("npc")
            player_record = raw_records.get("player")
            if isinstance(npc_record, dict):
                npc_id_value = str(
                    npc_record.get("id")
                    or selection.scenario.get("npc", {}).get("npcID")
                    or ""
                )
                if npc_id_value:
                    hoomans_payload.pop("PNC_" + npc_id_value, None)
            if isinstance(player_record, dict):
                hoomans_payload.pop("PNC_PlayerCharacters", None)
        return self._host.import_source(
            selection.scenario,
            source=Provenance.SAVE,
            source_id=selection.metadata["sourceID"],
            mode="offline_save",
            metadata=selection.metadata,
            provenance=selection.provenance,
            provider_payloads=provider_payloads,
        )
