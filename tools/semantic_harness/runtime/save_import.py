"""Project Hoomans save-backed Player/NPC selection and source projection."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .scenario import DEFAULT_SCENARIO, merge
from .save_catalog import SaveCatalog, SaveCatalogError, _load_core_reader
from tools.semantic_harness.core.item_catalog import item_type_registry_fixture
from .player_engine_state import OfflinePlayerEngineStateProvider


FULL_READ_MAX_DEPTH = 64
FULL_READ_MAX_ITEMS = 2_000_000
FULL_READ_MAX_NODES = 100_000
FULL_READ_MAX_STRING = 1_000_000


class SaveImportError(ValueError):
    """A selected saved actor cannot be imported safely."""


@dataclass(frozen=True)
class SavedSelection:
    scenario: dict[str, Any]
    metadata: dict[str, Any]
    provenance: dict[str, Any]
    provider_payloads: dict[str, Any]
    player_uuid: str
    player_entity_key: str
    npc_id: str


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _restore_reader_shape(value: Any) -> Any:
    """Restore Core reader table shape without interpreting mod semantics.

    The read-only Core ModData reader uses ``_entries`` when a table has
    sparse numeric keys, because JSON object keys cannot retain Lua numbers.
    Rebuilding those keys is transport normalization only; production Lua
    remains the owner of persistence, migration, and gameplay meaning.
    """

    if isinstance(value, list):
        return [_restore_reader_shape(item) for item in value]
    if not isinstance(value, dict):
        return value
    entries = value.get("_entries")
    if (
        isinstance(entries, list)
        and set(value) == {"_entries"}
        and all(
            isinstance(entry, dict)
            and "key" in entry
            and "value" in entry
            for entry in entries
        )
    ):
        return {
            _restore_reader_shape(entry["key"]): _restore_reader_shape(
                entry["value"]
            )
            for entry in entries
        }
    return {key: _restore_reader_shape(item) for key, item in value.items()}


def _first_name(identity: dict[str, Any]) -> tuple[str, str, str]:
    survivor = _as_dict(identity.get("survivor"))
    display = str(identity.get("displayName") or "Saved NPC")
    forename = str(survivor.get("forename") or "")
    surname = str(survivor.get("surname") or "")
    if not forename:
        parts = display.split(None, 1)
        forename = parts[0] if parts else display
        surname = parts[1] if len(parts) > 1 else ""
    return forename, surname, display


def _saved_relationship(
    npc_record: dict[str, Any], player_entity_key: str
) -> tuple[dict[str, Any], str]:
    social = _as_dict(npc_record.get("social"))
    relationships = _as_dict(social.get("relationships"))
    value = relationships.get(player_entity_key)
    if not isinstance(value, dict):
        return {}, "MISSING"
    return deepcopy(value), "SAVE"


def _empty_inventory() -> dict[str, Any]:
    """Represent an inventory that has no supported offline projection."""

    return {"revision": 0, "items": {}, "containers": []}


def _saved_inventory(record: dict[str, Any]) -> tuple[dict[str, Any], str]:
    value = record.get("inventory")
    if isinstance(value, dict) and isinstance(value.get("items"), (dict, list)):
        return deepcopy(value), "SAVE"
    # A compact production envelope is persisted state even though it is not
    # an offline runtime projection. Transport it as SAVE provenance and let
    # production Lua deserialize/hydrate it; Python must not decode its mode.
    if isinstance(value, list):
        return _empty_inventory(), "SAVE"
    return _empty_inventory(), "MISSING"


def _saved_actor_projection(
    npc_record: dict[str, Any], player_entity_key: str
) -> dict[str, Any]:
    """Project persisted actor capability facts without inventing gameplay state."""

    affiliation = _as_dict(npc_record.get("affiliation"))
    hostility = _as_dict(npc_record.get("hostility"))
    order = _as_dict(npc_record.get("orderSpec"))
    generation = _as_dict(npc_record.get("generation"))
    hostility_mode = str(hostility.get("mode") or "unknown")
    order_kind = str(order.get("kind") or "")
    follower = order_kind == "follow" or hostility_mode == "defend_owner"
    owner_key = str(
        affiliation.get("ownerPlayerKey")
        or npc_record.get("ownerPlayerKey")
        or ""
    )
    owned = follower or owner_key == player_entity_key
    hostile = bool(hostility.get("attackPlayers")) or hostility_mode in {
        "hostile",
        "aggressive",
        "attack",
    }
    source = str(generation.get("source") or "").lower()
    origin = str(affiliation.get("originArchetypeID") or "").lower()
    trader = source == "dynamic_trading" or origin == "trader"
    tactical_class = str(npc_record.get("tacticalClass") or "neutral")
    return {
        "tacticalClass": tactical_class,
        "factionID": affiliation.get("factionID"),
        "communityID": affiliation.get("communityID"),
        "factionRole": affiliation.get("role"),
        "role": "trader" if trader else None,
        "recruited": owned,
        "companion": owned,
        "ownedByPlayer": owned,
        "actorAuthority": {
            "eligible": owned,
            "companion": owned,
            "owned": owned,
            "status": "eligible" if owned else "not_owned",
        },
        "followState": {"mode": "following" if follower else "idle"},
        "orderSpec": deepcopy(order),
        "activeBehavior": (
            "following" if follower else "hostile" if hostile else "idle"
        ),
        "hostility": deepcopy(hostility),
        "isTrader": trader,
    }


class SaveBackedImporter:
    """Load selected persisted records through Core into a detached source."""

    def __init__(self, *, core_repository: Path) -> None:
        self.core_repository = Path(core_repository)
        self.catalog = SaveCatalog(
            core_repository=self.core_repository,
        )

    @staticmethod
    def _read_full(reader: Any, table_name: str) -> dict[str, Any]:
        try:
            report = reader.inspect(
                table=table_name,
                chunk_size=None,
                max_depth=FULL_READ_MAX_DEPTH,
                max_items=FULL_READ_MAX_ITEMS,
                max_nodes=FULL_READ_MAX_NODES,
                max_string=FULL_READ_MAX_STRING,
            )
        except Exception as error:
            raise SaveImportError(
                f"could not read saved table {table_name}: {error}"
            ) from error
        if report.get("truncated"):
            raise SaveImportError(
                f"saved table {table_name} exceeded bounded import limits"
            )
        value = report.get("data")
        if not isinstance(value, dict):
            raise SaveImportError(f"saved table {table_name} is not an object")
        return _restore_reader_shape(value)

    def load(
        self,
        save_path: Path,
        *,
        player_uuid: str | None = None,
        npc_id: str | None = None,
        engine_fixtures: dict[str, Any] | None = None,
    ) -> SavedSelection:
        save_path = Path(save_path).expanduser().resolve()
        try:
            catalog_entry = self.catalog.inspect(save_path)
        except SaveCatalogError as error:
            raise SaveImportError(str(error)) from error

        Reader, _reader_error = _load_core_reader(self.core_repository)
        player_table = "PNC_PlayerCharacters"
        try:
            with Reader(save_path) as reader:
                player_data = self._read_full(reader, player_table)
                by_uuid = _as_dict(player_data.get("byUUID"))
                if not by_uuid:
                    raise SaveImportError(
                        "PNC_PlayerCharacters contains no saved player records"
                    )
                selected_uuid = str(player_uuid or "")
                if selected_uuid and selected_uuid not in by_uuid:
                    raise SaveImportError(
                        f"saved player not found: {selected_uuid}"
                    )
                if not selected_uuid:
                    active = sorted(
                        key for key, value in by_uuid.items()
                        if _as_dict(value).get("status", "active") == "active"
                    )
                    selected_uuid = str((active or sorted(by_uuid))[0])
                player_record = _as_dict(by_uuid.get(selected_uuid))
                if not player_record:
                    raise SaveImportError(
                        f"saved player record is invalid: {selected_uuid}"
                    )

                account_key = str(
                    player_record.get("accountKey")
                    or player_record.get("accountIdentity")
                    or ""
                ).strip()
                if not account_key:
                    raise SaveImportError(
                        f"saved player has no account identity: {selected_uuid}"
                    )
                player_entity_key = (
                    f"player:{account_key}:{selected_uuid}"
                )

                selected_npc_id = str(npc_id or "")
                if selected_npc_id.startswith("PNC_"):
                    selected_npc_id = selected_npc_id[len("PNC_"):]
                if not selected_npc_id:
                    selected_npc_id = catalog_entry.npc_tables[0][len("PNC_"):]
                npc_table = f"PNC_{selected_npc_id}"
                if npc_table not in set(catalog_entry.npc_tables):
                    raise SaveImportError(f"saved NPC not found: {selected_npc_id}")
                npc_record = self._read_full(reader, npc_table)
                table_names = {
                    str(entry.get("name"))
                    for entry in catalog_entry.tables
                    if isinstance(entry, dict) and entry.get("name")
                }
                raw_registries: dict[str, dict[str, Any]] = {}
                # Keep the complete persisted player registry available to the
                # Lua worker.  This is transport only; production
                # PNC.PlayerCharacters.Load remains the owner of registry
                # normalization, migration, and identity binding.
                raw_registries["playerCharacters"] = deepcopy(player_data)
                for table_name, registry_name in (
                    ("PNC_Factions", "factions"),
                    ("PNC_Communities", "communities"),
                    ("PNC_NPCKnowledge", "npcKnowledge"),
                ):
                    if table_name in table_names:
                        raw_registries[registry_name] = self._read_full(
                            reader, table_name
                        )
        except SaveImportError:
            raise
        except Exception as error:
            raise SaveImportError(f"could not import save: {save_path}: {error}") from error

        identity = _as_dict(npc_record.get("identity"))
        forename, surname, display_name = _first_name(identity)
        player_display = str(
            player_record.get("displayName")
            or " ".join(
                part for part in (
                    player_record.get("forename"),
                    player_record.get("surname"),
                )
                if part
            )
            or selected_uuid
        )
        npc_relationship, relationship_source = _saved_relationship(
            npc_record, player_entity_key
        )
        native_player_state = OfflinePlayerEngineStateProvider().project(
            save_path,
            player_uuid=selected_uuid,
        )
        raw_inventory = npc_record.get("inventory")
        compact_inventory = (
            isinstance(raw_inventory, list)
            and len(raw_inventory) > 1
            and str(raw_inventory[1]) in {
                "SEED_ONLY",
                "BASELINE_DELTA",
                "FULL",
            }
        )
        if compact_inventory:
            native_player_state = deepcopy(native_player_state)
            native_player_state["itemTypeRegistry"] = (
                item_type_registry_fixture()
            )
        native_save_root = save_path if save_path.is_dir() else save_path.parent
        if native_player_state.get("available"):
            player_inventory = deepcopy(native_player_state["inventory"])
            player_inventory_source = "SAVE"
            player_inventory_provenance = deepcopy(
                native_player_state.get("provenance") or {}
            )
        elif (native_save_root / "players.db").is_file():
            # A native database exists but was not safely understood.  Do not
            # fall back to the Hoomans identity/social registry as physical
            # Player inventory authority.
            player_inventory = _empty_inventory()
            player_inventory_source = "MISSING"
            player_inventory_provenance = {
                "source": "MISSING",
                "table": "players.db.localPlayers",
                "recordKey": selected_uuid,
                "reason": native_player_state.get("reason")
                or "native_player_state_unavailable",
            }
        else:
            # Compatibility for synthetic/developer fixtures which contain no
            # native players.db.  Real save-backed imports take the branch
            # above whenever the native database is present.
            player_inventory, player_inventory_source = _saved_inventory(
                player_record
            )
            player_inventory_provenance = {
                "source": player_inventory_source,
                "table": player_table,
                "recordKey": selected_uuid,
            }
        npc_inventory, npc_inventory_source = _saved_inventory(npc_record)
        actor_projection = _saved_actor_projection(
            npc_record, player_entity_key
        )
        saved_personality = deepcopy(
            _as_dict(npc_record.get("social")).get("personality") or {}
        )
        saved_gender = (
            "female" if identity.get("isFemale") is True
            else "male" if identity.get("isFemale") is False
            else "unknown"
        )
        fixtures = deepcopy(engine_fixtures or {})
        player_num = None
        if account_key.startswith("sp_slot_"):
            try:
                player_num = int(account_key.rsplit("_", 1)[1])
            except (TypeError, ValueError):
                player_num = None
        if player_num is None:
            player_num = native_player_state.get("localPlayerID")
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "player": {
                    "characterUUID": selected_uuid,
                    "forename": player_record.get("forename") or player_display,
                    "surname": player_record.get("surname") or "",
                    "displayName": player_display,
                    "accountKey": account_key,
                    "accountIdentity": player_record.get("accountIdentity"),
                    "entityKey": player_entity_key,
                    "playerNum": player_num,
                    "gender": player_record.get("gender")
                    or fixtures.get("playerGender", "unknown"),
                    "traits": deepcopy(player_record.get("traits") or []),
                    "socialProfile": deepcopy(
                        player_record.get("socialProfile") or {}
                    ),
                    "inventory": player_inventory,
                },
                "npc": {
                    "npcID": selected_npc_id,
                    "forename": forename,
                    "surname": surname,
                    "displayName": display_name,
                    "identity": deepcopy(identity),
                    "identityState": "unknown",
                    "gender": saved_gender,
                    "identitySeed": identity.get("seed") or selected_npc_id,
                    "archetype": identity.get("archetypeID") or "General",
                    "archetypeID": identity.get("archetypeID") or "General",
                    "tacticalClass": actor_projection["tacticalClass"],
                    "factionID": actor_projection["factionID"],
                    "communityID": actor_projection["communityID"],
                    "factionRole": actor_projection["factionRole"],
                    "role": actor_projection["role"],
                    "recruited": actor_projection["recruited"],
                    "companion": actor_projection["companion"],
                    "ownedByPlayer": actor_projection["ownedByPlayer"],
                    "actorAuthority": actor_projection["actorAuthority"],
                    "followState": actor_projection["followState"],
                    "orderSpec": actor_projection["orderSpec"],
                    "activeBehavior": actor_projection["activeBehavior"],
                    "hostility": actor_projection["hostility"],
                    "traits": deepcopy(npc_record.get("npcTraits") or []),
                    "personality": deepcopy(
                        saved_personality
                    ),
                    "personalityOverride": bool(saved_personality),
                    "personalityMode": "saved" if saved_personality else "",
                    "social": deepcopy(_as_dict(npc_record.get("social"))),
                    "relationship": npc_relationship,
                    "inventory": npc_inventory,
                },
                "world": fixtures.get("world", {}),
                "runtime": {
                    "mode": "multiplayer"
                    if str(catalog_entry.mode or "").lower() == "multiplayer"
                    else "singleplayer",
                    "semanticLabSource": "SAVE",
                    "semanticLabSourceID": catalog_entry.source_id,
                    "availableMods": (
                        {"DTHoomans": True}
                        if actor_projection["isTrader"]
                        else {}
                    ),
                },
                "sourceSelection": {
                    "savePath": str(save_path),
                    "playerUUID": selected_uuid,
                    "playerEntityKey": player_entity_key,
                    "npcID": selected_npc_id,
                    "npcTable": npc_table,
                },
            },
        )
        for key, value in fixtures.items():
            if key not in {"playerGender", "world"}:
                scenario.setdefault("runtime", {}).setdefault(
                    "offlineFixtures", {}
                )[key] = value

        source_id = (
            f"{catalog_entry.source_id}#player={selected_uuid}"
            f"#npc={selected_npc_id}"
        )
        metadata = {
            "schemaVersion": 1,
            "sourceKind": "SAVE",
            "sourceID": source_id,
            "mode": "offline_save",
            "savePath": str(save_path),
            "worldVersion": catalog_entry.world_version,
            "playerUUID": selected_uuid,
            "playerEntityKey": player_entity_key,
            "npcID": selected_npc_id,
            "npcTable": npc_table,
        }
        provenance = {
            "schema": "semantic.provenance.v1",
            "defaultSource": "SAVE",
            "paths": {
                "player": {
                    "source": "SAVE",
                    "table": player_table,
                    "recordKey": selected_uuid,
                },
                "npc": {
                    "source": "SAVE",
                    "table": npc_table,
                    "recordKey": selected_npc_id,
                },
                "npc.relationship": {
                    "source": relationship_source,
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if relationship_source == "MISSING"
                        else None
                    ),
                    "table": npc_table,
                    "recordKey": player_entity_key,
                },
                "player.identity": {
                    "source": "SAVE",
                    "table": player_table,
                    "recordKey": selected_uuid,
                },
                "npc.identity": {
                    "source": "SAVE",
                    "table": npc_table,
                    "recordKey": selected_npc_id,
                },
                "player.needs": {"source": "FIXTURE"},
                "player.traits": {
                    "source": "SAVE"
                    if isinstance(player_record.get("traits"), (list, dict))
                    else "MISSING",
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if not isinstance(player_record.get("traits"), (list, dict))
                        else None
                    ),
                    "table": player_table,
                    "recordKey": selected_uuid,
                },
                "player.socialProfile": {
                    "source": "SAVE"
                    if isinstance(player_record.get("socialProfile"), dict)
                    else "MISSING",
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if not isinstance(player_record.get("socialProfile"), dict)
                        else None
                    ),
                    "table": player_table,
                    "recordKey": selected_uuid,
                },
                "player.registry": {
                    "source": "SAVE",
                    "owner": "PNC.PlayerCharacters.Load",
                    "table": player_table,
                    "recordKey": selected_uuid,
                },
                "npc.needs": {"source": "FIXTURE"},
                "npc.traits": {
                    "source": "SAVE"
                    if isinstance(npc_record.get("npcTraits"), (list, dict))
                    else "MISSING",
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if not isinstance(npc_record.get("npcTraits"), (list, dict))
                        else None
                    ),
                    "table": npc_table,
                    "recordKey": selected_npc_id,
                },
                "npc.personality": {
                    "source": "SAVE" if saved_personality else "DERIVED",
                    "table": npc_table,
                    "recordKey": selected_npc_id,
                },
                "npc.knowledge": {
                    "source": "SAVE" if "npcKnowledge" in raw_registries else "MISSING",
                    "owner": (
                        "PNC.NPCKnowledge.Load -> "
                        "PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer"
                        if "npcKnowledge" in raw_registries
                        else None
                    ),
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if "npcKnowledge" not in raw_registries
                        else None
                    ),
                    "table": "PNC_NPCKnowledge",
                    "recordKey": selected_uuid,
                },
                "npc.faction": {
                    "source": "SAVE" if "factions" in raw_registries else "MISSING",
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if "factions" not in raw_registries
                        else None
                    ),
                    "table": "PNC_Factions",
                    "recordKey": actor_projection["factionID"],
                },
                "npc.community": {
                    "source": "SAVE" if "communities" in raw_registries else "MISSING",
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if "communities" not in raw_registries
                        else None
                    ),
                    "table": "PNC_Communities",
                    "recordKey": actor_projection["communityID"],
                },
                "player.inventory": {
                    "source": player_inventory_source,
                    **player_inventory_provenance,
                },
                "npc.inventory": {
                    "source": npc_inventory_source,
                    "owner": (
                        "PNC.Persistence.DeserializeRecord"
                        " -> PNC.Inventory.EnsureRecordInventory"
                        if npc_inventory_source == "SAVE"
                        else None
                    ),
                    "missingClass": (
                        "LEGITIMATE_ABSENCE"
                        if npc_inventory_source == "MISSING"
                        else None
                    ),
                    "table": npc_table,
                    "recordKey": selected_npc_id,
                },
                "world": {"source": "FIXTURE"},
            },
        }
        provider_payloads = {
            "ProjectHoomans": {
                "PNC_PlayerCharacters": {selected_uuid: deepcopy(player_record)},
                "PNC_" + selected_npc_id: deepcopy(npc_record),
                # The Lua worker is the only owner of Hoomans runtime
                # deserialization. Keep the selected records explicit so the
                # production rehydration boundary never has to reconstruct a
                # record from the Python scenario projection.
                "rawRecords": {
                    "player": deepcopy(player_record),
                    "npc": deepcopy(npc_record),
                },
                # These are raw persisted registries.  The Lua worker passes
                # them to production faction/community owners; Python does
                # not normalize, reconcile, or derive diplomacy state.
                "rawRegistries": deepcopy(raw_registries),
                "selection": {
                    "playerTable": player_table,
                    "playerUUID": selected_uuid,
                    "npcTable": npc_table,
                    "npcID": selected_npc_id,
                },
            },
            "DynamicTrading": {
                "source": "SAVE" if actor_projection["isTrader"] else "MISSING",
                "selectedActor": (
                    {
                        "id": selected_npc_id,
                        "provider": "dynamictrading",
                    }
                    if actor_projection["isTrader"]
                    else None
                ),
            },
            "ProjectZomboid": native_player_state,
            "selection": {
                "playerEntityKey": player_entity_key,
                "relationshipKey": player_entity_key,
            },
        }
        return SavedSelection(
            scenario=scenario,
            metadata=metadata,
            provenance=provenance,
            provider_payloads=provider_payloads,
            player_uuid=selected_uuid,
            player_entity_key=player_entity_key,
            npc_id=selected_npc_id,
        )


__all__ = ["SaveBackedImporter", "SaveImportError", "SavedSelection"]
