"""Bounded, read-only projection of native Build 42 Player save state.

Build 42.20 stores native physical Player state in ``players.db`` (SQLite), in
``localPlayers.data``. This module reads only the proven prefix of the engine
serializer and fails closed when the format or its WorldDictionary cannot be
verified. Adopters may provide their own identity key without making the Core
decoder depend on an adopter's persistence schema.
"""

from __future__ import annotations

from dataclasses import dataclass
import re
import sqlite3
import struct
from pathlib import Path
from typing import Any


PLAYER_WORLD_VERSION = 249
MAX_BLOB_BYTES = 2 * 1024 * 1024
MAX_TABLE_ENTRIES = 10_000
MAX_TABLE_DEPTH = 16
MAX_INVENTORY_GROUPS = 4_096
MAX_STACK = 100_000
MAX_DICTIONARY_BYTES = 32 * 1024 * 1024


class PlayerEngineStateError(ValueError):
    """The native Player save cannot be interpreted safely."""


@dataclass
class _Reader:
    data: bytes
    position: int = 0

    def need(self, size: int) -> None:
        if size < 0 or self.position + size > len(self.data):
            raise PlayerEngineStateError(
                f"native Player blob ended at offset {self.position}"
            )

    def skip(self, size: int) -> None:
        self.need(size)
        self.position += size

    def u8(self) -> int:
        self.need(1)
        value = self.data[self.position]
        self.position += 1
        return value

    def i8(self) -> int:
        self.need(1)
        value = struct.unpack_from(">b", self.data, self.position)[0]
        self.position += 1
        return value

    def i16(self) -> int:
        self.need(2)
        value = struct.unpack_from(">h", self.data, self.position)[0]
        self.position += 2
        return value

    def i32(self) -> int:
        self.need(4)
        value = struct.unpack_from(">i", self.data, self.position)[0]
        self.position += 4
        return value

    def string(self) -> str:
        # GameWindow.StringUTF stores a signed-short byte length followed by
        # UTF-8 bytes.  The engine rejects lengths larger than 65536.
        length = self.i16()
        if length < 0 or length > 65_536:
            raise PlayerEngineStateError(
                f"invalid native Player string length {length}"
            )
        self.need(length)
        value = self.data[self.position : self.position + length].decode(
            "utf-8", errors="strict"
        )
        self.position += length
        return value


def _read_kahlua_value(reader: _Reader, depth: int = 0) -> Any:
    """Read the engine's KahluaTableImpl save tags used by IsoMovingObject."""

    if depth > MAX_TABLE_DEPTH:
        raise PlayerEngineStateError("native Player ModData table is too deep")
    value_type = reader.u8()
    if value_type == 0:  # String
        return reader.string()
    if value_type == 1:  # Double
        reader.skip(8)
        return None
    if value_type == 2:  # KahluaTableImpl
        return _read_kahlua_table(reader, depth + 1)
    if value_type == 3:  # Boolean
        return reader.u8() != 0
    raise PlayerEngineStateError(
        f"unsupported native Player Kahlua value tag {value_type}"
    )


def _read_kahlua_table(reader: _Reader, depth: int = 0) -> dict[str, Any]:
    count = reader.i32()
    if count < 0 or count > MAX_TABLE_ENTRIES:
        raise PlayerEngineStateError(
            f"invalid native Player Kahlua table count {count}"
        )
    result: dict[str, Any] = {}
    for _ in range(count):
        key = _read_kahlua_value(reader, depth)
        value = _read_kahlua_value(reader, depth)
        # Lua numeric keys are irrelevant to identity matching.  Preserve
        # string keys only, without inventing a Python representation for the
        # engine's numeric key space.
        if isinstance(key, str):
            result[key] = value
    return result


def _skip_survivor_descriptor(reader: _Reader, world_version: int) -> None:
    reader.i32()  # descriptor id
    reader.string()  # forename
    reader.string()  # surname
    reader.string()  # torso
    reader.i32()  # gender
    reader.string()  # profession
    extra = reader.i32()
    if extra not in (0, 1):
        raise PlayerEngineStateError("invalid native SurvivorDesc extra flag")
    if extra:
        count = reader.i32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise PlayerEngineStateError("invalid native SurvivorDesc extras")
        for _ in range(count):
            reader.string()
    count = reader.i32()  # XP boosts
    if count < 0 or count > MAX_TABLE_ENTRIES:
        raise PlayerEngineStateError("invalid native SurvivorDesc perk count")
    for _ in range(count):
        reader.string()
        reader.i32()
    if world_version >= 208:
        reader.string()  # voice prefix
        reader.skip(4)  # voice pitch
        reader.i32()  # voice type


def _skip_item_visual(reader: _Reader) -> None:
    flags = reader.u8()
    reader.string()  # full type
    reader.string()  # alternate model
    reader.string()  # clothing item
    if flags & 1:
        reader.skip(3)  # tint
    if flags & 2:
        reader.skip(1)  # base texture
    if flags & 4:
        reader.skip(1)  # texture choice
    if flags & 8:
        reader.skip(4)  # hue
    if flags & 16:
        reader.string()  # decal
    for _ in range(6):
        length = reader.i8()
        if length < 0:
            raise PlayerEngineStateError("invalid native ItemVisual byte array")
        reader.skip(length)


def _skip_human_visual(reader: _Reader, world_version: int) -> None:
    flags = reader.u8()
    for flag in (4, 2, 8):
        if flags & flag:
            reader.skip(3)
    reader.skip(3)  # body hair, skin texture, zombie rotation stage
    if flags & 64:
        reader.string()
    if flags & 16:
        reader.string()
    if flags & 32:
        reader.string()
    for _ in range(3):
        length = reader.i8()
        if length < 0:
            raise PlayerEngineStateError("invalid native HumanVisual byte array")
        reader.skip(length)
    count = reader.i8()
    if count < 0 or count > 127:
        raise PlayerEngineStateError("invalid native HumanVisual item count")
    for _ in range(count):
        _skip_item_visual(reader)
    reader.string()  # non-attached hair
    flags = reader.u8()
    if flags & 4:
        reader.skip(3)
    if flags & 2:
        reader.skip(3)


def _read_inventory(
    reader: _Reader,
    registry: dict[int, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    container_type = reader.string()
    reader.u8()  # explored
    group_count = reader.i16()
    if group_count < 0 or group_count > MAX_INVENTORY_GROUPS:
        raise PlayerEngineStateError(
            f"invalid native inventory group count {group_count}"
        )

    items: list[dict[str, Any]] = []
    for group_index in range(group_count):
        stack = reader.i32()
        if stack <= 0 or stack > MAX_STACK:
            raise PlayerEngineStateError(
                f"invalid native inventory stack {stack}"
            )
        data_length = reader.i32()
        if data_length < 3:
            raise PlayerEngineStateError("invalid native inventory item length")
        item_start = reader.position
        registry_id = reader.i16()
        reader.u8()  # save type
        reader.skip(data_length - 3)
        full_type = registry.get(registry_id)
        if not full_type:
            raise PlayerEngineStateError(
                f"unknown native inventory registry id {registry_id}"
            )
        for _ in range(stack - 1):
            reader.i32()  # ids of compressed identical items
        items.append(
            {
                "itemID": f"native:{group_index}:{registry_id}",
                "fullType": full_type,
                "displayName": full_type.rsplit(".", 1)[-1],
                "stack": stack,
                "registryID": registry_id,
                "source": "SAVE",
            }
        )

    reader.u8()  # hasBeenLooted
    capacity = reader.i32()
    if capacity < 0 or capacity > 1_000_000:
        raise PlayerEngineStateError("invalid native inventory capacity")
    return (
        {
            "revision": 0,
            "items": items,
            "containers": [],
            "containerType": container_type,
            "capacity": capacity,
            "source": "SAVE",
        },
        {
            "inventoryOffset": item_start if items else reader.position,
            "groupCount": group_count,
            "containerType": container_type,
        },
    )


def _read_world_dictionary(path: Path) -> dict[int, str]:
    try:
        if path.stat().st_size > MAX_DICTIONARY_BYTES:
            raise PlayerEngineStateError("WorldDictionaryReadable.lua is too large")
        text = path.read_text(encoding="utf-8", errors="strict")
    except (OSError, UnicodeError) as error:
        raise PlayerEngineStateError(f"cannot read WorldDictionaryReadable.lua: {error}") from error
    rows = re.findall(
        r'registryID\s*=\s*(-?\d+)\s*,\s*\n\s*fulltype\s*=\s*"((?:\\.|[^"\\])*)"',
        text,
    )
    if not rows:
        raise PlayerEngineStateError("WorldDictionaryReadable.lua has no item registry")
    registry: dict[int, str] = {}
    for raw_id, full_type in rows:
        registry[int(raw_id)] = full_type
    return registry


def _read_native_blob(
    blob: bytes,
    *,
    world_version: int,
    registry: dict[int, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    if world_version != PLAYER_WORLD_VERSION:
        raise PlayerEngineStateError(
            f"unsupported native Player world version {world_version}"
        )
    if not blob or len(blob) > MAX_BLOB_BYTES:
        raise PlayerEngineStateError("native Player blob is missing or too large")
    reader = _Reader(blob)
    reader.u8()  # IsoPlayer serialise flag
    reader.u8()  # IsoObject class id
    reader.skip(20)  # IsoMovingObject offsets and position
    reader.skip(4)  # forward direction
    if reader.u8():
        identity_data = _read_kahlua_table(reader)
    else:
        identity_data = {}
    if reader.u8():
        _skip_survivor_descriptor(reader, world_version)
    _skip_human_visual(reader, world_version)
    inventory, details = _read_inventory(reader, registry)
    details["blobBytes"] = len(blob)
    details["parsedThroughOffset"] = reader.position
    return identity_data, {"inventory": inventory, "details": details}


def _missing(reason: str, *, save_path: Path, player_uuid: str | None = None) -> dict[str, Any]:
    if reason in {"players_db_missing", "world_dictionary_missing"}:
        missing_class = "ENGINE_ONLY"
    elif reason.startswith("unsupported"):
        missing_class = "UNSUPPORTED_FORMAT"
    elif reason in {"player_identity_not_found", "player_identity_ambiguous"}:
        missing_class = "PROVIDER_OMISSION"
    else:
        missing_class = "PROVIDER_OMISSION"
    return {
        "schema": "semantic.player_engine_state.v1",
        "schemaVersion": 1,
        "available": False,
        "source": "MISSING",
        "reason": reason,
        "missingClass": missing_class,
        "savePath": str(save_path),
        "playerUUID": player_uuid,
        "inventory": {
            "revision": 0,
            "items": [],
            "containers": [],
            "source": "MISSING",
        },
        "worn": {
            "source": "MISSING",
            "reason": "native_tail_not_projected",
            "missingClass": "ENGINE_ONLY",
        },
        "equipped": {
            "source": "MISSING",
            "reason": "native_tail_not_projected",
            "missingClass": "ENGINE_ONLY",
        },
        "provenance": {
            "source": "MISSING",
            "reason": reason,
            "missingClass": missing_class,
            "path": "players.db.localPlayers",
        },
    }


class OfflinePlayerEngineStateProvider:
    """Read native local Player inventory without mutating the save."""

    provider_id = "pz_native_player"
    owner = "Project Zomboid"

    def __init__(
        self,
        *,
        identity_key: str | None = None,
        identity_metadata_keys: tuple[str, ...] = (),
    ) -> None:
        self.identity_key = identity_key
        self.identity_metadata_keys = tuple(identity_metadata_keys)

    def _matches_identity(
        self,
        row: tuple[Any, ...],
        identity_data: dict[str, Any],
        player_uuid: str | None,
    ) -> bool:
        if not player_uuid:
            return True
        if self.identity_key:
            return str(identity_data.get(self.identity_key)) == str(player_uuid)
        return str(row[0]) == str(player_uuid)

    def project(
        self,
        save_path: Path,
        *,
        player_uuid: str | None = None,
    ) -> dict[str, Any]:
        save_path = Path(save_path).expanduser().resolve()
        save_root = save_path if save_path.is_dir() else save_path.parent
        players_db = save_root / "players.db"
        dictionary_path = save_root / "WorldDictionaryReadable.lua"
        if not players_db.is_file():
            return _missing("players_db_missing", save_path=save_path, player_uuid=player_uuid)
        if not dictionary_path.is_file():
            return _missing("world_dictionary_missing", save_path=save_path, player_uuid=player_uuid)

        try:
            before = self._signatures(players_db, dictionary_path)
        except OSError as error:
            return _missing(
                f"source_unavailable:{error}",
                save_path=save_path,
                player_uuid=player_uuid,
            )
        try:
            registry = _read_world_dictionary(dictionary_path)
            connection = sqlite3.connect(
                f"file:{players_db}?mode=ro", uri=True, timeout=2.0
            )
            try:
                table = connection.execute(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name='localPlayers'"
                ).fetchone()
                if table is None:
                    return _missing("local_players_table_missing", save_path=save_path, player_uuid=player_uuid)
                rows = connection.execute(
                    "SELECT id, name, worldversion, data, isDead FROM localPlayers "
                    "ORDER BY id LIMIT 5"
                ).fetchall()
            finally:
                connection.close()
        except sqlite3.DatabaseError:
            return _missing("players_db_corrupt", save_path=save_path, player_uuid=player_uuid)
        except (OSError, PlayerEngineStateError) as error:
            return _missing(str(error), save_path=save_path, player_uuid=player_uuid)

        try:
            after = self._signatures(players_db, dictionary_path)
        except OSError as error:
            return _missing(
                f"source_unavailable_after_read:{error}",
                save_path=save_path,
                player_uuid=player_uuid,
            )
        if before != after:
            return _missing("source_changed_during_read", save_path=save_path, player_uuid=player_uuid)
        if len(rows) > 4:
            return _missing("too_many_local_players", save_path=save_path, player_uuid=player_uuid)
        if not rows:
            return _missing("local_player_missing", save_path=save_path, player_uuid=player_uuid)

        parsed: list[tuple[tuple[Any, ...], dict[str, Any], dict[str, Any]]] = []
        for row in rows:
            row_id, name, world_version, blob, is_dead = row
            if not isinstance(blob, (bytes, bytearray, memoryview)):
                return _missing("local_player_blob_missing", save_path=save_path, player_uuid=player_uuid)
            try:
                identity_data, projection = _read_native_blob(
                    bytes(blob), world_version=int(world_version), registry=registry
                )
            except (PlayerEngineStateError, TypeError, ValueError, UnicodeError, struct.error) as error:
                return _missing(
                    f"native_player_format:{error}",
                    save_path=save_path,
                    player_uuid=player_uuid,
                )
            parsed.append(((row_id, name, world_version, is_dead), identity_data, projection))

        matches = [
            item
            for item in parsed
            if self._matches_identity(item[0], item[1], player_uuid)
        ]
        if not matches:
            return _missing("player_identity_not_found", save_path=save_path, player_uuid=player_uuid)
        if len(matches) > 1:
            return _missing("player_identity_ambiguous", save_path=save_path, player_uuid=player_uuid)

        (row_id, name, world_version, is_dead), identity_data, projection = matches[0]
        inventory = projection["inventory"]
        return {
            "schema": "semantic.player_engine_state.v1",
            "schemaVersion": 1,
            "available": True,
            "source": "SAVE",
            "providerID": self.provider_id,
            "owner": self.owner,
            "savePath": str(save_path),
            "playerUUID": (
                identity_data.get(self.identity_key)
                if self.identity_key
                else (player_uuid or str(row_id))
            ),
            "playerName": str(name or ""),
            "localPlayerID": int(row_id),
            "worldVersion": int(world_version),
            "isDead": bool(is_dead),
            "inventory": inventory,
            "worn": {
                "source": "MISSING",
                "reason": "native_tail_not_projected",
                "missingClass": "ENGINE_ONLY",
            },
            "equipped": {
                "source": "MISSING",
                "reason": "native_tail_not_projected",
                "missingClass": "ENGINE_ONLY",
            },
            "provenance": {
                "source": "SAVE",
                "table": "players.db.localPlayers",
                "recordKey": str(row_id),
                "baseSource": "SAVE",
            },
            "identityMetadata": {
                key: identity_data.get(key)
                for key in self.identity_metadata_keys
                if key in identity_data
            },
            "details": projection["details"],
        }

    @staticmethod
    def _signatures(*paths: Path) -> tuple[tuple[str, int, int], ...]:
        result = []
        for path in paths:
            stat = path.stat()
            result.append((str(path), int(stat.st_size), int(stat.st_mtime_ns)))
        return tuple(result)


__all__ = [
    "OfflinePlayerEngineStateProvider",
    "PLAYER_WORLD_VERSION",
    "PlayerEngineStateError",
]
