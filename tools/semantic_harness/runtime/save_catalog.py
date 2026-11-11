"""Read-only Project Zomboid save discovery backed by PsychopatzCore.

This module owns catalog policy only.  Binary decoding remains in Core's
``GlobalModDataReader`` so Semantic Lab cannot grow a second save parser.
"""

from __future__ import annotations

from dataclasses import dataclass
import importlib.util
import os
import re
from pathlib import Path
import sys
from typing import Any, Iterable


REPOSITORY = Path(__file__).resolve().parents[3]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
SAVE_FILENAME = "global_mod_data.bin"
SUPPORTED_WORLD_VERSIONS = frozenset({249})
REQUIRED_TABLES = ("PNC_PlayerCharacters", "PNC_Core_Global")
CORE_SCHEMA_VERSION = 16
PLAYER_SCHEMA_VERSION = 6
NPC_SCHEMA_VERSION = 16
_SAVE_NAME_TIMESTAMP = re.compile(
    r"^(?P<stamp>\d{4}-\d{2}-\d{2}[_-]\d{2}-\d{2}-\d{2})"
)


class SaveCatalogError(ValueError):
    """A save cannot be safely cataloged or is outside the supported schema."""


class RawSaveInspector:
    """Read-only raw-save validation seam used by semantic state providers."""

    def __init__(self, *, core_repository: Path | None = None) -> None:
        self.catalog = SaveCatalog(core_repository=core_repository)

    def inspect(self, path: Path) -> "SaveCandidate":
        return self.catalog.inspect(path)


@dataclass(frozen=True)
class SaveCandidate:
    """A validated, read-only save catalog entry."""

    path: Path
    source_id: str
    mode: str | None
    save_name: str
    world_version: int
    file_bytes: int
    file_mtime_ms: int
    tables: tuple[dict[str, Any], ...]
    npc_tables: tuple[str, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": "semantic.save_catalog.entry.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "sourceID": self.source_id,
            "path": str(self.path),
            "mode": self.mode,
            "saveName": self.save_name,
            "worldVersion": self.world_version,
            "formatCompatibility": "verified_42.20",
            "fileBytes": self.file_bytes,
            "fileMtimeMs": self.file_mtime_ms,
            "requiredTables": list(REQUIRED_TABLES),
            "players": [{"table": "PNC_PlayerCharacters"}],
            "core": {"table": "PNC_Core_Global"},
            "npcs": [
                {
                    "table": table,
                    "id": table[len("PNC_"):],
                }
                for table in self.npc_tables
            ],
            "tables": [dict(table) for table in self.tables],
        }


def _load_core_reader(core_repository: Path):
    reader_path = (
        Path(core_repository) / "tools" / "profiler" / "moddata_reader.py"
    )
    if not reader_path.is_file():
        raise SaveCatalogError(
            f"PsychopatzCore reader not found: {reader_path}"
        )
    module_name = "_projecthoomans_core_moddata_reader"
    module = sys.modules.get(module_name)
    if module is None or Path(getattr(module, "__file__", "")) != reader_path:
        spec = importlib.util.spec_from_file_location(module_name, reader_path)
        if spec is None or spec.loader is None:
            raise SaveCatalogError(f"cannot load Core reader: {reader_path}")
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
    return module.GlobalModDataReader, module.ModDataFormatError


def default_save_roots() -> tuple[Path, ...]:
    """Return conventional offline save roots without requiring PZ to run."""

    roots: list[Path] = []
    for variable in ("PZ_SAVE_ROOT", "ZOMBOID_SAVE_ROOT"):
        value = str(os.environ.get(variable, "")).strip()
        if value:
            roots.append(Path(value).expanduser())
    roots.append(Path.home() / "Zomboid" / "Saves")
    unique: list[Path] = []
    seen: set[str] = set()
    for root in roots:
        key = str(root.resolve(strict=False))
        if key not in seen:
            seen.add(key)
            unique.append(root)
    return tuple(unique)


def _candidate_files(roots: Iterable[Path]) -> list[tuple[Path, Path]]:
    candidates: list[tuple[Path, Path]] = []
    seen: set[str] = set()
    for root in roots:
        root = Path(root).expanduser()
        if root.is_file():
            paths = [root] if root.name == SAVE_FILENAME else []
        elif root.is_dir():
            paths = sorted(root.rglob(SAVE_FILENAME))
        else:
            paths = []
        for path in paths:
            if not path.is_file() or path.is_symlink():
                continue
            resolved = path.resolve()
            key = str(resolved)
            if key not in seen:
                seen.add(key)
                candidates.append((resolved, root.resolve(strict=False)))
    return sorted(candidates, key=lambda item: str(item[0]))


def _save_location(path: Path, root: Path) -> tuple[str | None, str]:
    save_name = path.parent.name
    try:
        relative = path.relative_to(root)
        parts = relative.parts
        mode = parts[-3] if len(parts) >= 3 else None
    except ValueError:
        mode = None
    return mode, save_name


def _save_discovery_sort_key(value: dict[str, Any]) -> tuple[int, str, int, str]:
    """Return a deterministic newest-first key for a catalog entry.

    Project Zomboid normally names save directories with a sortable timestamp
    (``YYYY-MM-DD_HH-MM-SS``). Prefer that save identity over file mtime,
    which can change when a save is copied. Non-timestamped saves fall back
    to their validated file mtime.
    """
    save_name = str(value.get("saveName") or "")
    match = _SAVE_NAME_TIMESTAMP.match(save_name)
    stamp = match.group("stamp") if match else ""
    try:
        file_mtime_ms = int(value.get("fileMtimeMs") or 0)
    except (TypeError, ValueError):
        file_mtime_ms = 0
    return (
        1 if stamp else 0,
        stamp,
        file_mtime_ms,
        str(value.get("path") or ""),
    )


class SaveCatalog:
    """Discover and validate persisted saves without opening Project Zomboid."""

    def __init__(
        self,
        roots: Iterable[Path] | None = None,
        *,
        core_repository: Path | None = None,
    ) -> None:
        self.roots = tuple(roots) if roots is not None else default_save_roots()
        self.core_repository = Path(core_repository or CORE_REPOSITORY)

    def inspect(self, path: Path) -> SaveCandidate:
        path = Path(path).expanduser().resolve()
        Reader, ReaderError = _load_core_reader(self.core_repository)
        try:
            with Reader(path) as reader:
                if reader.world_version not in SUPPORTED_WORLD_VERSIONS:
                    raise SaveCatalogError(
                        f"unsupported save world version: {reader.world_version}"
                    )
                entries = tuple(reader.index)
                names = {entry.name for entry in entries}
                missing = [name for name in REQUIRED_TABLES if name not in names]
                npc_tables = tuple(
                    sorted(name for name in names if name.startswith("PNC_npc")
                           and len(name) > len("PNC_npc"))
                )
                if not npc_tables:
                    missing.append("PNC_npc<ID>")
                if missing:
                    raise SaveCatalogError(
                        "missing required ModData tables: " + ", ".join(missing)
                    )
                expected_schemas = {
                    "PNC_PlayerCharacters": PLAYER_SCHEMA_VERSION,
                    "PNC_Core_Global": CORE_SCHEMA_VERSION,
                }
                for table_name in npc_tables:
                    expected_schemas[table_name] = NPC_SCHEMA_VERSION
                for table_name, expected in expected_schemas.items():
                    schema_report = reader.inspect(
                        table=table_name,
                        path="schemaVersion",
                        max_depth=1,
                        max_items=8,
                        max_nodes=16,
                    )
                    schema_data = schema_report.get("data")
                    actual = (
                        schema_data.get("schemaVersion")
                        if isinstance(schema_data, dict)
                        else None
                    )
                    if isinstance(actual, bool) or not isinstance(actual, (int, float)):
                        raise SaveCatalogError(
                            f"invalid schema for {table_name}: schemaVersion is missing"
                        )
                    if int(actual) != expected or float(actual) != float(expected):
                        raise SaveCatalogError(
                            f"unsupported schema for {table_name}: {actual} "
                            f"(expected {expected})"
                        )
                # summary performs Core's stable-file check after indexing.
                summary = reader.summary(prefix="PNC_", limit=500)
                tables = tuple(
                    {
                        "name": entry.name,
                        "bytes": entry.block_size,
                        "entries": entry.entry_count,
                    }
                    for entry in entries
                    if entry.name.startswith("PNC_")
                )
                return SaveCandidate(
                    path=path,
                    source_id=f"save:{path}",
                    mode=None,
                    save_name=path.parent.name,
                    world_version=reader.world_version,
                    file_bytes=int(summary["fileBytes"]),
                    file_mtime_ms=int(summary["fileMtimeMs"]),
                    tables=tables,
                    npc_tables=npc_tables,
                )
        except SaveCatalogError:
            raise
        except (ReaderError, OSError, ValueError) as error:
            raise SaveCatalogError(f"invalid save: {path}: {error}") from error

    def discover(self) -> dict[str, Any]:
        accepted: list[dict[str, Any]] = []
        rejected: list[dict[str, str]] = []
        for path, root in _candidate_files(self.roots):
            try:
                candidate = self.inspect(path)
                mode, _save_name = _save_location(path, root)
                value = candidate.to_dict()
                value["mode"] = mode
                accepted.append(value)
            except SaveCatalogError as error:
                rejected.append({
                    "path": str(path),
                    "status": "rejected",
                    "reason": str(error),
                })
        accepted.sort(key=_save_discovery_sort_key, reverse=True)
        return {
            "schema": "semantic.save_catalog.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "roots": [str(Path(root).expanduser()) for root in self.roots],
            "supportedWorldVersions": sorted(SUPPORTED_WORLD_VERSIONS),
            "saves": accepted,
            "rejected": rejected,
        }


__all__ = [
    "RawSaveInspector",
    "SaveCandidate",
    "SaveCatalog",
    "SaveCatalogError",
    "default_save_roots",
]
