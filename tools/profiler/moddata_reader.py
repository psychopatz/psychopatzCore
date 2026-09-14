"""Bounded reader for Project Zomboid's persisted global ModData file.

The reader follows the KahluaTableImpl serialization used by the 42.20 PZ
build: a big-endian global header, named table blocks, and typed values.  It
is intentionally a narrow inspection reader.  It never writes the save,
executes Lua, or materializes every table unless the caller explicitly asks
for a selected table.
"""

from __future__ import annotations

import math
import mmap
import struct
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Optional


MAX_FILE_BYTES = 512 * 1024 * 1024
MAX_TABLE_COUNT = 1_000_000
MAX_TABLE_ENTRIES = 2_000_000
MAX_DEPTH = 64
MAX_CHUNK_SIZE = 64
MAX_NODES = 100_000
MAX_STRING_LENGTH = 1_000_000
OMITTED_MARKER = "_profilerOmittedEntries"
REFERENCE_WORLD_VERSION = 249


class ModDataFormatError(ValueError):
    """The file is missing, corrupt, unsupported, or outside safe bounds."""


@dataclass(frozen=True)
class TableIndexEntry:
    name: str
    ordinal: int
    block_size: int
    data_offset: int
    end_offset: int
    entry_count: int


class _Cursor:
    def __init__(self, data: Any, start: int, end: int):
        self.data = data
        self.position = start
        self.end = end

    def require(self, size: int) -> None:
        if size < 0 or self.position + size > self.end:
            raise ModDataFormatError("truncated ModData value")

    def read(self, size: int) -> bytes:
        self.require(size)
        value = self.data[self.position:self.position + size]
        self.position += size
        return value

    def read_int32(self) -> int:
        return struct.unpack(">i", self.read(4))[0]

    def read_uint16(self) -> int:
        return struct.unpack(">H", self.read(2))[0]

    def read_string(self, *, max_length: int = MAX_STRING_LENGTH) -> str:
        # GameWindow.StringUTF stores the UTF-8 byte length as a signed short.
        length = struct.unpack(">h", self.read(2))[0]
        if length <= 0:
            return ""
        if length > MAX_STRING_LENGTH:
            raise ModDataFormatError("ModData string exceeds the safe format limit")
        raw = self.read(length)
        value = raw.decode("utf-8", errors="replace")
        if len(value) <= max_length:
            return value
        return value[:max_length] + "…"


def _json_number(value: float) -> Any:
    if not math.isfinite(value):
        return None
    if value.is_integer() and abs(value) <= 9_007_199_254_740_992:
        return int(value)
    return value


def _key_label(key: Any) -> str:
    if isinstance(key, float):
        return str(_json_number(key))
    return str(key)


def _key_matches(key: Any, wanted: str) -> bool:
    if isinstance(key, str):
        return key == wanted
    if isinstance(key, (int, float)):
        try:
            return float(wanted) == float(key)
        except ValueError:
            return False
    return False


class _Decoder:
    def __init__(self, data: Any, world_version: int, *, max_depth: int,
                 max_items: int, max_nodes: int, max_string: int):
        self.data = data
        self.world_version = world_version
        self.max_depth = max_depth
        self.max_items = max_items
        self.max_nodes = max_nodes
        self.max_string = max_string
        self.nodes = 0
        self.truncated = False

    def _typed_key(self, cursor: _Cursor) -> Any:
        if self.world_version < 25:
            return cursor.read_string(max_length=self.max_string)
        kind = cursor.read(1)[0]
        if kind == 0:
            return cursor.read_string(max_length=self.max_string)
        if kind == 1:
            return _json_number(struct.unpack(">d", cursor.read(8))[0])
        raise ModDataFormatError(f"unsupported ModData key type: {kind}")

    def _value_type(self, cursor: _Cursor) -> int:
        kind = cursor.read(1)[0]
        if kind not in (0, 1, 2, 3):
            raise ModDataFormatError(f"unsupported ModData value type: {kind}")
        return kind

    def _read_value(self, cursor: _Cursor, kind: int, depth: int) -> Any:
        if kind == 0:
            return cursor.read_string(max_length=self.max_string)
        if kind == 1:
            return _json_number(struct.unpack(">d", cursor.read(8))[0])
        if kind == 2:
            return self._read_table(cursor, depth + 1)
        if kind == 3:
            return cursor.read(1)[0] != 0
        raise ModDataFormatError(f"unsupported ModData value type: {kind}")

    def _skip_value(self, cursor: _Cursor, kind: int, depth: int) -> None:
        if kind == 0:
            cursor.read_string()
            return
        if kind == 1:
            cursor.read(8)
            return
        if kind == 2:
            self._skip_table(cursor, depth + 1)
            return
        if kind == 3:
            cursor.read(1)
            return
        raise ModDataFormatError(f"unsupported ModData value type: {kind}")

    def _read_table(self, cursor: _Cursor, depth: int,
                    projection: Optional[tuple[str, ...]] = None) -> Any:
        count = cursor.read_int32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise ModDataFormatError(f"invalid ModData table entry count: {count}")

        entries: list[tuple[Any, Any]] = []
        omitted = 0
        for index in range(count):
            key = self._typed_key(cursor)
            kind = self._value_type(cursor)
            wanted = projection is None or (projection and _key_matches(key, projection[0]))
            within_limits = depth <= self.max_depth and self.nodes < self.max_nodes
            within_items = len(entries) < self.max_items
            if wanted and within_limits and within_items:
                self.nodes += 1
                remaining = projection[1:] if projection else None
                if remaining and kind != 2:
                    # A scalar cannot contain the rest of a requested path.
                    self._skip_value(cursor, kind, depth + 1)
                    continue
                if remaining:
                    value = self._read_table(cursor, depth + 1, remaining)
                else:
                    value = self._read_value(cursor, kind, depth)
                entries.append((key, value))
            else:
                self._skip_value(cursor, kind, depth)
                if wanted:
                    omitted += 1
                    self.truncated = True

        if projection is not None and not entries:
            return {}
        return _table_to_json(entries, omitted)

    def _skip_table(self, cursor: _Cursor, depth: int) -> None:
        count = cursor.read_int32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise ModDataFormatError(f"invalid ModData table entry count: {count}")
        for _ in range(count):
            self._typed_key(cursor)
            self._skip_value(cursor, self._value_type(cursor), depth)

    def read_root(self, data_offset: int, end_offset: int, *,
                  chunk_index: int = 0, chunk_size: Optional[int] = None,
                  projection: Optional[tuple[str, ...]] = None) -> tuple[Any, int]:
        cursor = _Cursor(self.data, data_offset, end_offset)
        count = cursor.read_int32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise ModDataFormatError(f"invalid ModData table entry count: {count}")

        start = chunk_index * chunk_size if chunk_size is not None else 0
        stop = start + chunk_size if chunk_size is not None else count
        entries: list[tuple[Any, Any]] = []
        omitted = 0
        for index in range(count):
            key = self._typed_key(cursor)
            kind = self._value_type(cursor)
            in_chunk = chunk_size is None or start <= index < stop
            wanted = projection is None or (projection and _key_matches(key, projection[0]))
            within_limits = self.max_depth >= 0 and self.nodes < self.max_nodes
            # A root chunk is itself the caller's item bound. max-items is the
            # bound for nested tables and must not silently shorten a page.
            item_limit = chunk_size if chunk_size is not None else self.max_items
            within_items = len(entries) < item_limit
            if in_chunk and wanted and within_limits and within_items:
                self.nodes += 1
                remaining = projection[1:] if projection else None
                if remaining and kind != 2:
                    self._skip_value(cursor, kind, 0)
                    continue
                value = (self._read_table(cursor, 1, remaining)
                         if remaining else self._read_value(cursor, kind, 0))
                entries.append((key, value))
            else:
                self._skip_value(cursor, kind, 0)
                if in_chunk and wanted:
                    omitted += 1
                    self.truncated = True
        if cursor.position != end_offset:
            raise ModDataFormatError(
                f"table block boundary mismatch: consumed {cursor.position}, expected {end_offset}")
        return _table_to_json(entries, omitted), count


class _RawDecoder:
    """Decode the wire shape while retaining entry order and byte spans."""

    def __init__(self, data: Any, world_version: int, *, max_depth: int,
                 max_items: int, max_nodes: int, max_string: int):
        self.data = data
        self.world_version = world_version
        self.max_depth = max_depth
        self.max_items = max_items
        self.max_nodes = max_nodes
        self.max_string = max_string
        self.nodes = 0
        self.truncated = False

    def _read_string(self, cursor: _Cursor) -> tuple[str, bool]:
        length = struct.unpack(">h", cursor.read(2))[0]
        if length <= 0:
            return "", False
        if length > MAX_STRING_LENGTH:
            raise ModDataFormatError("ModData string exceeds the safe format limit")
        raw = cursor.read(length)
        value = raw.decode("utf-8", errors="replace")
        if len(value) <= self.max_string:
            return value, False
        self.truncated = True
        return value[:self.max_string] + "…", True

    def _read_key(self, cursor: _Cursor) -> dict[str, Any]:
        offset = cursor.position
        if self.world_version < 25:
            value, truncated = self._read_string(cursor)
            key_type = "string"
        else:
            kind = cursor.read(1)[0]
            if kind == 0:
                value, truncated = self._read_string(cursor)
                key_type = "string"
            elif kind == 1:
                raw_number = struct.unpack(">d", cursor.read(8))[0]
                value = _json_number(raw_number)
                truncated = False
                key_type = "number"
            else:
                raise ModDataFormatError(f"unsupported ModData key type: {kind}")
        return {
            "type": key_type,
            "value": value,
            "offset": offset,
            "bytes": cursor.position - offset,
            "truncated": truncated,
        }

    def _read_scalar(self, cursor: _Cursor, kind: int) -> dict[str, Any]:
        offset = cursor.position - 1
        if kind == 0:
            value, truncated = self._read_string(cursor)
            return {"type": "string", "wireType": kind, "value": value,
                    "offset": offset, "bytes": cursor.position - offset,
                    "truncated": truncated}
        if kind == 1:
            value = _json_number(struct.unpack(">d", cursor.read(8))[0])
            return {"type": "number", "wireType": kind, "value": value,
                    "offset": offset, "bytes": cursor.position - offset}
        if kind == 3:
            value = cursor.read(1)[0] != 0
            return {"type": "boolean", "wireType": kind, "value": value,
                    "offset": offset, "bytes": cursor.position - offset}
        raise ModDataFormatError(f"unsupported ModData value type: {kind}")

    def _read_value(self, cursor: _Cursor, kind: int, depth: int,
                    type_offset: int) -> dict[str, Any]:
        if kind == 2:
            value = self._read_table(cursor, depth + 1)
            value["offset"] = type_offset
            value["bytes"] = cursor.position - type_offset
            value["wireType"] = kind
            return value
        value = self._read_scalar(cursor, kind)
        value["offset"] = type_offset
        value["bytes"] = cursor.position - type_offset
        return value

    def _skip_value(self, cursor: _Cursor, kind: int, depth: int) -> None:
        if kind == 0:
            cursor.read_string()
            return
        if kind == 1:
            cursor.read(8)
            return
        if kind == 2:
            self._skip_table(cursor, depth + 1)
            return
        if kind == 3:
            cursor.read(1)
            return
        raise ModDataFormatError(f"unsupported ModData value type: {kind}")

    def _skip_table(self, cursor: _Cursor, depth: int) -> int:
        count = cursor.read_int32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise ModDataFormatError(f"invalid ModData table entry count: {count}")
        for _ in range(count):
            self._read_key(cursor)
            self._skip_value(cursor, cursor.read(1)[0], depth)
        return count

    def _read_table(self, cursor: _Cursor, depth: int) -> dict[str, Any]:
        table_offset = cursor.position
        count = cursor.read_int32()
        if count < 0 or count > MAX_TABLE_ENTRIES:
            raise ModDataFormatError(f"invalid ModData table entry count: {count}")

        entries: list[dict[str, Any]] = []
        omitted = 0
        for index in range(count):
            entry_offset = cursor.position
            key = self._read_key(cursor)
            kind = cursor.read(1)[0]
            within_limits = depth <= self.max_depth and self.nodes < self.max_nodes
            within_items = len(entries) < self.max_items
            if within_limits and within_items:
                self.nodes += 1
                value = self._read_value(cursor, kind, depth, cursor.position - 1)
                entries.append({
                    "index": index,
                    "key": key,
                    "value": value,
                    "offset": entry_offset,
                    "bytes": cursor.position - entry_offset,
                })
            else:
                self._skip_value(cursor, kind, depth)
                omitted += 1
                self.truncated = True

        result: dict[str, Any] = {
            "type": "table",
            "entryCount": count,
            "entries": entries,
            "offset": table_offset,
            "bytes": cursor.position - table_offset,
        }
        if omitted:
            result[OMITTED_MARKER] = omitted
        return result

    def read_root(self, data_offset: int, end_offset: int) -> tuple[dict[str, Any], int]:
        cursor = _Cursor(self.data, data_offset, end_offset)
        value = self._read_table(cursor, 0)
        if cursor.position != end_offset:
            raise ModDataFormatError(
                f"table block boundary mismatch: consumed {cursor.position}, expected {end_offset}")
        return value, value["entryCount"]


def _table_to_json(entries: Iterable[tuple[Any, Any]], omitted: int = 0) -> Any:
    pairs = list(entries)
    if not pairs:
        return {}
    if all(isinstance(key, str) for key, _ in pairs):
        keys = [key for key, _ in pairs]
        if len(set(keys)) == len(keys):
            result = {key: value for key, value in pairs}
            if omitted:
                result[OMITTED_MARKER] = omitted
            return result

    numeric_keys = [key for key, _ in pairs]
    if not omitted and all(isinstance(key, (int, float)) for key in numeric_keys):
        expected = list(range(1, len(pairs) + 1))
        if [_json_number(float(key)) for key in numeric_keys] == expected:
            return [value for _, value in pairs]

    result: dict[str, Any] = {
        "_entries": [{"key": key, "value": value} for key, value in pairs]
    }
    if omitted:
        result[OMITTED_MARKER] = omitted
    return result


class GlobalModDataReader:
    """Read and inspect one persisted ``global_mod_data.bin`` file."""

    def __init__(self, path: Path):
        self.path = Path(path)
        try:
            file_stat = self.path.stat()
            size = file_stat.st_size
        except (FileNotFoundError, OSError) as error:
            raise ModDataFormatError(f"ModData file not found: {self.path}") from error
        if size < 8 or size > MAX_FILE_BYTES:
            raise ModDataFormatError(f"ModData file size is outside safe bounds: {size}")
        self._file = None
        try:
            self._file = self.path.open("rb")
            self.data = mmap.mmap(self._file.fileno(), 0, access=mmap.ACCESS_READ)
        except (OSError, PermissionError) as error:
            if self._file is not None:
                self._file.close()
            raise ModDataFormatError(f"ModData file is unreadable: {self.path}") from error
        if len(self.data) != size:
            self.close()
            raise ModDataFormatError("ModData file changed while it was being read")
        self._file_size = size
        self._file_mtime_ns = file_stat.st_mtime_ns
        self.file_mtime_ms = int(file_stat.st_mtime * 1000)
        self.world_version = struct.unpack_from(">i", self.data, 0)[0]
        self.table_count = struct.unpack_from(">i", self.data, 4)[0]
        if self.table_count < 0 or self.table_count > MAX_TABLE_COUNT:
            raise ModDataFormatError(f"invalid ModData table count: {self.table_count}")
        try:
            self._index = self._build_index()
        except Exception:
            self.close()
            raise

    def close(self) -> None:
        mapping = getattr(self, "data", None)
        if mapping is not None and hasattr(mapping, "close"):
            mapping.close()
        handle = getattr(self, "_file", None)
        if handle is not None:
            handle.close()
        self._file = None

    def __enter__(self) -> "GlobalModDataReader":
        return self

    def __exit__(self, _exc_type, _exc_value, _traceback) -> None:
        self.close()

    def __del__(self):
        # The CLI uses the context manager; keep ad-hoc interactive use from
        # leaking a file descriptor if a caller forgets to close the reader.
        try:
            self.close()
        except (OSError, BufferError):
            pass

    def _build_index(self) -> tuple[TableIndexEntry, ...]:
        cursor = _Cursor(self.data, 8, len(self.data))
        entries: list[TableIndexEntry] = []
        for ordinal in range(self.table_count):
            block_start = cursor.position
            block_size = cursor.read_int32()
            if block_size < 0:
                raise ModDataFormatError("negative ModData table block size")
            name = cursor.read_string()
            data_offset = cursor.position
            end_offset = block_start + 4 + block_size
            if end_offset < data_offset or end_offset > len(self.data):
                raise ModDataFormatError(f"invalid block boundary for ModData table {name}")
            if end_offset == data_offset:
                entry_count = 0
            elif data_offset + 4 <= end_offset:
                entry_count = struct.unpack_from(">i", self.data, data_offset)[0]
                if entry_count < 0 or entry_count > MAX_TABLE_ENTRIES:
                    raise ModDataFormatError(f"invalid entry count for ModData table {name}")
            else:
                raise ModDataFormatError(f"missing entry count for ModData table {name}")
            entries.append(TableIndexEntry(name, ordinal, block_size, data_offset,
                                            end_offset, entry_count))
            cursor.position = end_offset
        if cursor.position != len(self.data):
            raise ModDataFormatError("trailing bytes after global ModData tables")
        return tuple(entries)

    def _assert_stable(self) -> None:
        try:
            file_stat = self.path.stat()
        except OSError as error:
            raise ModDataFormatError("ModData file disappeared while it was being read") from error
        if (file_stat.st_size != self._file_size
                or file_stat.st_mtime_ns != self._file_mtime_ns):
            raise ModDataFormatError("ModData file changed while it was being read")

    @property
    def index(self) -> tuple[TableIndexEntry, ...]:
        return self._index

    @property
    def file_bytes(self) -> int:
        return self._file_size

    def find_table(self, name: str) -> TableIndexEntry:
        for entry in self._index:
            if entry.name == name:
                return entry
        raise ModDataFormatError(f"ModData table not found: {name}")

    def find_npc_table(self, npc_id: str) -> TableIndexEntry:
        if npc_id.startswith("PNC_npc"):
            table_name = npc_id
        elif npc_id.startswith("npc"):
            table_name = f"PNC_{npc_id}"
        else:
            table_name = f"PNC_npc{npc_id}"
        return self.find_table(table_name)

    def summary(self, *, prefix: Optional[str] = None, limit: int = 40) -> dict[str, Any]:
        if limit < 1 or limit > 500:
            raise ModDataFormatError("summary limit must be between 1 and 500")
        self._assert_stable()
        selected = [entry for entry in self._index
                    if not prefix or entry.name.startswith(prefix)]
        groups: dict[str, dict[str, int]] = defaultdict(lambda: {"count": 0, "bytes": 0})
        for entry in self._index:
            group = "PNC_npc" if entry.name.startswith("PNC_npc") else entry.name.split("_", 1)[0]
            groups[group]["count"] += 1
            groups[group]["bytes"] += entry.block_size
        npc_ids = [entry.name.removeprefix("PNC_") for entry in selected
                   if entry.name.startswith("PNC_npc")]
        tables = [{"name": entry.name, "bytes": entry.block_size,
                   "entries": entry.entry_count} for entry in selected[:limit]]
        result: dict[str, Any] = {
            "reportVersion": 1,
            "source": "persisted_global_mod_data",
            "format": "PZ GlobalModData/KahluaTable",
            "file": str(self.path),
            "fileBytes": len(self.data),
            "fileMtimeMs": self.file_mtime_ms,
            "worldVersion": self.world_version,
            "formatCompatibility": ("verified_42.20"
                                     if self.world_version == REFERENCE_WORLD_VERSION
                                     else "unverified_world_version"),
            "tableCount": self.table_count,
            "tableGroups": dict(sorted(groups.items())),
            "tables": tables,
        }
        if prefix and prefix.startswith("PNC_npc"):
            result["npcIds"] = npc_ids[:limit]
            if len(npc_ids) > limit:
                result[OMITTED_MARKER] = len(npc_ids) - limit
        if len(selected) > limit:
            result["tablesOmitted"] = len(selected) - limit
        return result

    def inspect(self, *, table: Optional[str] = None, npc: Optional[str] = None,
                path: Optional[str] = None, chunk_index: int = 0,
                chunk_size: Optional[int] = 8, max_depth: int = 6,
                max_items: int = 32, max_nodes: int = 5_000,
                max_string: int = 160) -> dict[str, Any]:
        if table and npc:
            raise ModDataFormatError("choose --table or --npc, not both")
        if chunk_index < 0:
            raise ModDataFormatError("chunk must be zero or greater")
        if chunk_size is not None and (chunk_size < 1 or chunk_size > MAX_CHUNK_SIZE):
            raise ModDataFormatError(f"chunk-size must be between 1 and {MAX_CHUNK_SIZE}")
        if max_depth < 0 or max_depth > MAX_DEPTH:
            raise ModDataFormatError(f"depth must be between 0 and {MAX_DEPTH}")
        if max_items < 1 or max_items > MAX_TABLE_ENTRIES:
            raise ModDataFormatError("max-items is outside safe bounds")
        if max_nodes < 1 or max_nodes > MAX_NODES:
            raise ModDataFormatError("max-nodes is outside safe bounds")
        if max_string < 1 or max_string > MAX_STRING_LENGTH:
            raise ModDataFormatError("max-string is outside safe bounds")
        self._assert_stable()

        target = self.find_npc_table(npc) if npc else self.find_table(table) if table else None
        if target is None:
            return self.summary()
        projection = tuple(part for part in (path or "").split(".") if part)
        decoder = _Decoder(self.data, self.world_version, max_depth=max_depth,
                           max_items=max_items, max_nodes=max_nodes,
                           max_string=max_string)
        if projection:
            data, root_count = decoder.read_root(target.data_offset, target.end_offset,
                                                 projection=projection)
            chunk_count = 1
        else:
            chunk_count = (1 if chunk_size is None
                           else max(1, math.ceil(target.entry_count / chunk_size)))
            if chunk_index >= chunk_count:
                raise ModDataFormatError(
                    f"chunk {chunk_index} is outside {chunk_count} available chunks")
            data, root_count = decoder.read_root(
                target.data_offset, target.end_offset,
                chunk_index=chunk_index, chunk_size=chunk_size)
        self._assert_stable()
        result = {
            "reportVersion": 1,
            "source": "persisted_global_mod_data",
            "format": "PZ GlobalModData/KahluaTable",
            "file": str(self.path),
            "fileBytes": len(self.data),
            "fileMtimeMs": self.file_mtime_ms,
            "worldVersion": self.world_version,
            "formatCompatibility": ("verified_42.20"
                                     if self.world_version == REFERENCE_WORLD_VERSION
                                     else "unverified_world_version"),
            "table": {"name": target.name, "bytes": target.block_size,
                      "entries": root_count},
            "chunk": {"index": 0 if projection else chunk_index,
                      "count": chunk_count,
                      "size": None if projection else chunk_size},
            "path": ".".join(projection) if projection else None,
            "limits": {"depth": max_depth, "itemsPerTable": max_items,
                       "nodes": max_nodes, "string": max_string},
            "truncated": decoder.truncated,
            "data": data,
        }
        return result

    def inspect_raw(self, *, table: Optional[str] = None, npc: Optional[str] = None,
                    max_depth: int = 10, max_items: int = 128,
                    max_nodes: int = 20_000, max_string: int = 4_096) -> dict[str, Any]:
        """Inspect one table without normalizing arrays or discarding wire metadata."""
        if table and npc:
            raise ModDataFormatError("choose --table or --npc, not both")
        if max_depth < 0 or max_depth > MAX_DEPTH:
            raise ModDataFormatError(f"depth must be between 0 and {MAX_DEPTH}")
        if max_items < 1 or max_items > MAX_TABLE_ENTRIES:
            raise ModDataFormatError("max-items is outside safe bounds")
        if max_nodes < 1 or max_nodes > MAX_NODES:
            raise ModDataFormatError("max-nodes is outside safe bounds")
        if max_string < 1 or max_string > MAX_STRING_LENGTH:
            raise ModDataFormatError("max-string is outside safe bounds")
        self._assert_stable()
        target = self.find_npc_table(npc) if npc else self.find_table(table) if table else None
        if target is None:
            return self.summary()
        decoder = _RawDecoder(self.data, self.world_version, max_depth=max_depth,
                               max_items=max_items, max_nodes=max_nodes,
                               max_string=max_string)
        raw, root_count = decoder.read_root(target.data_offset, target.end_offset)
        self._assert_stable()
        return {
            "reportVersion": 1,
            "source": "persisted_global_mod_data",
            "format": "PZ GlobalModData/KahluaTable",
            "file": str(self.path),
            "fileBytes": len(self.data),
            "fileMtimeMs": self.file_mtime_ms,
            "worldVersion": self.world_version,
            "formatCompatibility": ("verified_42.20"
                                     if self.world_version == REFERENCE_WORLD_VERSION
                                     else "unverified_world_version"),
            "table": {"name": target.name, "bytes": target.block_size,
                      "entries": root_count, "dataOffset": target.data_offset},
            "limits": {"depth": max_depth, "itemsPerTable": max_items,
                       "nodes": max_nodes, "string": max_string},
            "truncated": decoder.truncated,
            "raw": raw,
        }
