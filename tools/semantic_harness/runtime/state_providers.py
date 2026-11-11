"""Adopter-owned projections over the shared Core save reader."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Protocol

from .save_catalog import (
    SaveCandidate,
    SaveCatalogError,
    RawSaveInspector,
    _load_core_reader,
)
from .save_import import _as_dict, _first_name


class StateProviderError(ValueError):
    """A provider cannot safely interpret its persisted schema."""


@dataclass(frozen=True)
class ProviderContext:
    reader: Any
    candidate: SaveCandidate
    table_names: frozenset[str]

    def read_path(self, table: str, path: str) -> Any:
        try:
            report = self.reader.inspect(
                table=table,
                path=path,
                chunk_size=None,
                max_depth=24,
                max_items=100_000,
                max_nodes=100_000,
                max_string=16_384,
            )
        except Exception as error:
            raise StateProviderError(
                f"could not read {table}.{path}: {error}"
            ) from error
        if report.get("truncated"):
            raise StateProviderError(
                f"projection {table}.{path} exceeded bounded limits"
            )
        value = report.get("data")
        if isinstance(value, dict):
            path_key = path.rsplit(".", 1)[-1]
            if path_key in value and len(value) == 1:
                return value[path_key]
        return value


class SaveStateProvider(Protocol):
    provider_id: str
    owner: str

    def project(self, context: ProviderContext) -> dict[str, Any]:
        """Return a bounded semantic projection owned by this adopter."""


class CoreStateProvider:
    provider_id = "psychopatzCore"
    owner = "PsychopatzCore"

    def project(self, context: ProviderContext) -> dict[str, Any]:
        table = "PNC_Core_Global"
        if table not in context.table_names:
            return {
                "available": False,
                "reason": "table_missing",
                "source": "MISSING",
                "tables": [],
            }
        return {
            "available": True,
            "source": "SAVE",
            "tables": [table],
            "schemaVersion": context.read_path(table, "schemaVersion"),
        }


class ProjectHoomansStateProvider:
    provider_id = "projecthoomans"
    owner = "ProjectHoomans"

    @staticmethod
    def _player_rows(value: Any) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for uuid, raw in sorted(_as_dict(value).items()):
            record = _as_dict(raw)
            account_key = str(
                record.get("accountKey")
                or record.get("accountIdentity")
                or ""
            ).strip()
            label = str(
                record.get("displayName")
                or " ".join(
                    part
                    for part in (record.get("forename"), record.get("surname"))
                    if part
                )
                or uuid
            )
            rows.append(
                {
                    "id": str(uuid),
                    "uuid": str(record.get("uuid") or uuid),
                    "label": label,
                    "status": str(record.get("status") or "unknown"),
                    "accountKey": account_key,
                    "entityKey": (
                        f"player:{account_key}:{uuid}" if account_key else None
                    ),
                    "source": "SAVE",
                }
            )
        return rows

    @staticmethod
    def _actor(context: ProviderContext, table: str) -> dict[str, Any]:
        identity = _as_dict(context.read_path(table, "identity"))
        affiliation = _as_dict(context.read_path(table, "affiliation"))
        hostility = _as_dict(context.read_path(table, "hostility"))
        order_spec = _as_dict(context.read_path(table, "orderSpec"))
        generation = _as_dict(context.read_path(table, "generation"))
        actor_id = table[len("PNC_"):] if table.startswith("PNC_") else table
        forename, surname, display_name = _first_name(identity)
        hostility_mode = str(hostility.get("mode") or "unknown")
        order_kind = str(order_spec.get("kind") or "")
        follower = order_kind == "follow" or hostility_mode == "defend_owner"
        hostile = bool(hostility.get("attackPlayers")) or hostility_mode in {
            "hostile",
            "aggressive",
            "attack",
        }
        return {
            "id": actor_id,
            "table": table,
            "label": display_name,
            "forename": forename,
            "surname": surname,
            "identity": deepcopy(identity),
            "affiliation": deepcopy(affiliation),
            "hostility": deepcopy(hostility),
            "order": deepcopy(order_spec),
            "generation": deepcopy(generation),
            "factionID": affiliation.get("factionID"),
            "communityID": affiliation.get("communityID"),
            "role": affiliation.get("role"),
            "hostilityMode": hostility_mode,
            "orderKind": order_kind,
            "isFollower": follower,
            "isHostile": hostile,
            "source": "SAVE",
        }

    @staticmethod
    def _rows_by_id(value: Any, *, name_key: str = "name") -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for row_id, raw in sorted(_as_dict(value).items()):
            record = _as_dict(raw)
            row = {
                    "id": str(record.get("id") or row_id),
                    "label": str(record.get(name_key) or row_id),
                    "status": str(record.get("status") or "unknown"),
                    "factionID": record.get("factionID"),
                    "archetypeID": record.get("archetypeID"),
                    "ownerPlayerKey": record.get("ownerPlayerKey"),
                    "leaderNPCID": record.get("leaderNPCID"),
                    "memberIDs": sorted(
                        str(member) for member in _as_dict(record.get("memberIDs"))
                    ),
                    "source": "SAVE",
                }
            for key in (
                "roles",
                "memberRoles",
                "roleByMemberID",
                "owner",
                "standing",
                "diplomacy",
                "provider",
                "providerID",
                "providerOverlay",
            ):
                if key in record:
                    row[key] = deepcopy(record.get(key))
            rows.append(row)
        return rows

    def project(self, context: ProviderContext) -> dict[str, Any]:
        player_table = "PNC_PlayerCharacters"
        if player_table not in context.table_names:
            return {
                "available": False,
                "reason": "player_table_missing",
                "source": "MISSING",
                "tables": [],
                "players": [],
                "actors": [],
                "factions": [],
                "communities": [],
            }
        players = self._player_rows(
            context.read_path(player_table, "byUUID")
        )
        actors = [
            self._actor(context, table) for table in context.candidate.npc_tables
        ]
        factions = []
        if "PNC_Factions" in context.table_names:
            factions = self._rows_by_id(
                context.read_path("PNC_Factions", "byID")
            )
        communities = []
        if "PNC_Communities" in context.table_names:
            communities = self._rows_by_id(
                context.read_path("PNC_Communities", "byID")
            )
        tables = [player_table, *context.candidate.npc_tables]
        tables.extend(
            table for table in ("PNC_Factions", "PNC_Communities")
            if table in context.table_names
        )
        return {
            "available": True,
            "source": "SAVE",
            "tables": tables,
            "players": players,
            "actors": actors,
            "factions": factions,
            "communities": communities,
        }


class DynamicTradingStateProvider:
    provider_id = "dynamictrading"
    owner = "DynamicTrading"

    def project(self, context: ProviderContext) -> dict[str, Any]:
        actors: list[dict[str, Any]] = []
        for table in context.candidate.npc_tables:
            generation = _as_dict(context.read_path(table, "generation"))
            affiliation = _as_dict(context.read_path(table, "affiliation"))
            source = str(generation.get("source") or "").lower()
            origin = str(affiliation.get("originArchetypeID") or "").lower()
            if source != "dynamic_trading" and origin != "trader":
                continue
            identity = _as_dict(context.read_path(table, "identity"))
            _, _, label = _first_name(identity)
            actor_id = table[len("PNC_"):] if table.startswith("PNC_") else table
            actors.append(
                {
                    "id": actor_id,
                    "table": table,
                    "label": label,
                    "provider": self.provider_id,
                    "source": "SAVE",
                }
            )
        persisted = sorted(
            table
            for table in context.table_names
            if table.startswith("DT_") or table.startswith("DTHoomans_")
        )
        return {
            "available": bool(actors or persisted),
            "reason": None if actors or persisted else "tables_missing",
            "source": "SAVE" if actors or persisted else "MISSING",
            "tables": persisted,
            "knownActors": actors,
        }


class SemanticStateCatalog:
    """Collect adopter projections over one raw, validated save."""

    def __init__(self, *, core_repository: Path) -> None:
        self.core_repository = Path(core_repository)
        self.raw_inspector = RawSaveInspector(core_repository=self.core_repository)
        self.providers: tuple[SaveStateProvider, ...] = (
            CoreStateProvider(),
            ProjectHoomansStateProvider(),
            DynamicTradingStateProvider(),
        )

    def load(self, save_path: Path) -> dict[str, Any]:
        try:
            candidate = self.raw_inspector.inspect(Path(save_path))
        except SaveCatalogError as error:
            raise StateProviderError(str(error)) from error
        Reader, _reader_error = _load_core_reader(self.core_repository)
        try:
            with Reader(candidate.path) as reader:
                context = ProviderContext(
                    reader=reader,
                    candidate=candidate,
                    table_names=frozenset(item["name"] for item in candidate.tables),
                )
                projections = {}
                for provider in self.providers:
                    projections[provider.provider_id] = {
                        "providerID": provider.provider_id,
                        "owner": provider.owner,
                        "projection": provider.project(context),
                    }
        except StateProviderError:
            raise
        except Exception as error:
            raise StateProviderError(
                f"could not build semantic state catalog: {error}"
            ) from error
        return {
            "schema": "semantic.state_catalog.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "sourceID": candidate.source_id,
            "raw": candidate.to_dict(),
            "providers": projections,
        }


__all__ = [
    "CoreStateProvider",
    "DynamicTradingStateProvider",
    "ProjectHoomansStateProvider",
    "ProviderContext",
    "SaveStateProvider",
    "SemanticStateCatalog",
    "StateProviderError",
]
