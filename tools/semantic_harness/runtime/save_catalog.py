"""Read-only Project Zomboid save discovery backed by PsychopatzCore.

This module owns catalog policy only.  Binary decoding remains in Core's
``GlobalModDataReader`` so Semantic Lab cannot grow a second save parser.
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace
import importlib.util
import os
import re
from pathlib import Path
import sys
from typing import Any, Iterable


REPOSITORY = Path(__file__).resolve().parents[3]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
SAVE_FILENAME = "global_mod_data.bin"
CURRENT_WORLD_VERSION = 249
READABLE_WORLD_VERSIONS = frozenset({245, 247, 249, 251})
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

    def inspect_source(self, path: Path) -> "SaveCandidate":
        return self.catalog.inspect_source(path)


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
    mod_activation: dict[str, Any] = field(default_factory=dict)

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
            "formatCompatibility": (
                "verified_42.20"
                if self.world_version == CURRENT_WORLD_VERSION
                else "readable_unknown_world_version"
            ),
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
            "capabilities": {
                "globalModData": True,
                "projectHoomans": bool(
                    {"PNC_PlayerCharacters", "PNC_Core_Global"}
                    <= {str(table.get("name")) for table in self.tables}
                    and bool(self.npc_tables)
                ),
            },
            "modActivation": dict(self.mod_activation),
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


def _split_values(value: str) -> list[str]:
    """Split Project Zomboid list settings without preserving empty values."""

    return [item for item in (
        part.strip() for part in re.split(r"[;,]", str(value or ""))
    ) if item]


def _read_key_value_file(path: Path) -> dict[str, str]:
    """Read the simple key/value subset used by Project Zomboid server INI files."""

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line or line.startswith(("#", ";", "[")) or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key:
            values[key.casefold()] = value.strip()
    return values


def _quoted_section_values(text: str, section: str) -> list[str]:
    """Extract quoted values from a ``mods.txt`` section."""

    match = re.search(
        rf"(?ims)^\s*{re.escape(section)}\s*\{{(.*?)\}}",
        text,
    )
    if match is None:
        return []
    values: list[str] = []
    for double, single in re.findall(r'"([^"]+)"|\'([^\']+)\'', match.group(1)):
        value = (double or single).strip()
        if value and value not in values:
            values.append(value)
    return values


def _mods_txt_metadata(path: Path) -> dict[str, Any]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        return {
            "status": "invalid",
            "source": "SAVE",
            "sourceFiles": [str(path)],
            "modIDs": [],
            "maps": [],
            "workshopItems": [],
            "diagnostics": [str(error)],
        }
    return {
        "status": "ready",
        "source": "SAVE",
        "sourceFiles": [str(path)],
        "modIDs": _quoted_section_values(text, "mods"),
        "maps": _quoted_section_values(text, "maps"),
        "workshopItems": [],
        "diagnostics": [],
    }


def _server_profile_candidates(
    server_root: Path,
    save_name: str,
) -> tuple[list[Path], list[str]]:
    try:
        profiles = sorted(server_root.glob("*.ini"))
    except OSError as error:
        return [], [str(error)]
    exact = [
        path for path in profiles
        if path.stem.casefold() == save_name.casefold()
    ]
    if exact:
        return exact, []
    named: list[Path] = []
    diagnostics: list[str] = []
    for path in profiles:
        try:
            values = _read_key_value_file(path)
        except OSError as error:
            diagnostics.append(f"{path}: {error}")
            continue
        if values.get("savename", "").strip().casefold() == save_name.casefold():
            named.append(path)
    return named, diagnostics


def _server_ini_metadata(
    save_name: str,
    server_root: Path | None,
) -> dict[str, Any]:
    base = {
        "source": "SERVER_PROFILE",
        "sourceFiles": [],
        "modIDs": [],
        "maps": [],
        "workshopItems": [],
        "serverProfile": None,
        "diagnostics": [],
    }
    if server_root is None or not server_root.is_dir():
        base.update({
            "status": "missing",
            "diagnostics": [f"server profile directory not found: {server_root}"],
        })
        return base
    matches, diagnostics = _server_profile_candidates(server_root, save_name)
    if len(matches) > 1:
        base.update({
            "status": "ambiguous",
            "diagnostics": [
                "multiple server profiles match save " + save_name,
                *[str(path) for path in matches],
            ],
        })
        return base
    if not matches:
        base.update({
            "status": "missing",
            "diagnostics": [
                f"no server profile matches save {save_name}",
                *diagnostics,
            ],
        })
        return base
    path = matches[0]
    try:
        values = _read_key_value_file(path)
    except OSError as error:
        base.update({
            "status": "invalid",
            "sourceFiles": [str(path)],
            "serverProfile": str(path),
            "diagnostics": [str(error)],
        })
        return base
    base.update({
        "status": "ready",
        "sourceFiles": [str(path)],
        "serverProfile": str(path),
        "modIDs": _split_values(values.get("mods", "")),
        "workshopItems": _split_values(values.get("workshopitems", "")),
        "diagnostics": diagnostics,
    })
    return base


def _server_root_for_save(
    save_root: Path,
    *,
    explicit: Path | None = None,
) -> Path | None:
    if explicit is not None:
        return Path(explicit).expanduser().resolve()
    for variable in ("PZ_SERVER_ROOT", "ZOMBOID_SERVER_ROOT"):
        value = str(os.environ.get(variable, "")).strip()
        if value:
            return Path(value).expanduser().resolve()
    root = Path(save_root).expanduser()
    if root.name == SAVE_FILENAME:
        try:
            return root.parents[3] / "Server"
        except IndexError:
            return None
    return root.parent / "Server"


def _mod_activation_metadata(
    path: Path,
    *,
    mode: str | None,
    save_root: Path,
    server_root: Path | None = None,
) -> dict[str, Any]:
    save_name = path.parent.name
    if str(mode or "").casefold() == "multiplayer":
        metadata = _server_ini_metadata(
            save_name,
            _server_root_for_save(save_root, explicit=server_root),
        )
    else:
        mods_path = path.parent / "mods.txt"
        if mods_path.is_file():
            metadata = _mods_txt_metadata(mods_path)
        else:
            metadata = {
                "status": "missing",
                "source": "SAVE",
                "sourceFiles": [],
                "modIDs": [],
                "maps": [],
                "workshopItems": [],
                "diagnostics": [f"mods.txt not found: {mods_path}"],
            }
    metadata.update({
        "schema": "semantic.save_mod_activation.v1",
        "mode": mode,
        "saveName": save_name,
    })
    return metadata


class SaveCatalog:
    """Discover and validate persisted saves without opening Project Zomboid."""

    def __init__(
        self,
        roots: Iterable[Path] | None = None,
        *,
        core_repository: Path | None = None,
        server_root: Path | None = None,
    ) -> None:
        self.roots = tuple(roots) if roots is not None else default_save_roots()
        self.core_repository = Path(core_repository or CORE_REPOSITORY)
        self.server_root = (
            Path(server_root).expanduser().resolve()
            if server_root is not None else None
        )

    def inspect_source(self, path: Path) -> SaveCandidate:
        """Read any parseable save without requiring an adopter's tables."""

        path = Path(path).expanduser().resolve()
        Reader, ReaderError = _load_core_reader(self.core_repository)
        try:
            with Reader(path) as reader:
                entries = tuple(reader.index)
                names = {entry.name for entry in entries}
                npc_tables = tuple(
                    sorted(
                        name for name in names
                        if name.startswith("PNC_npc")
                        and len(name) > len("PNC_npc")
                    )
                )
                summary = reader.summary(prefix="", limit=500)
                tables = tuple(
                    {
                        "name": entry.name,
                        "bytes": entry.block_size,
                        "entries": entry.entry_count,
                    }
                    for entry in entries
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
        except (ReaderError, OSError, ValueError) as error:
            raise SaveCatalogError(f"invalid save: {path}: {error}") from error

    def mod_activation(self, path: Path) -> dict[str, Any]:
        """Read the mod activation metadata associated with one save path."""

        path = Path(path).expanduser().resolve()
        root = next(
            (
                Path(candidate).expanduser().resolve()
                for candidate in self.roots
                if Path(candidate).expanduser().resolve() != path
                and path.is_relative_to(Path(candidate).expanduser().resolve())
            ),
            None,
        )
        mode: str | None = None
        if root is None:
            mode = next(
                (
                    part for part in reversed(path.parts)
                    if part.casefold() in {"sandbox", "multiplayer"}
                ),
                None,
            )
            root = path.parents[2] if mode and len(path.parents) > 2 else path.parent
        if mode is None:
            mode, _save_name = _save_location(path, root)
        return _mod_activation_metadata(
            path,
            mode=mode,
            save_root=root,
            server_root=self.server_root,
        )

    def inspect(self, path: Path) -> SaveCandidate:
        candidate = self.inspect_source(path)
        try:
            if candidate.world_version not in READABLE_WORLD_VERSIONS:
                raise SaveCatalogError(
                    f"unsupported save world version: {candidate.world_version}"
                )
            names = {str(entry.get("name")) for entry in candidate.tables}
            missing = [name for name in REQUIRED_TABLES if name not in names]
            if not candidate.npc_tables:
                missing.append("PNC_npc<ID>")
            if missing:
                raise SaveCatalogError(
                    "missing required ModData tables: " + ", ".join(missing)
                )
            expected_schemas = {
                "PNC_PlayerCharacters": PLAYER_SCHEMA_VERSION,
                "PNC_Core_Global": CORE_SCHEMA_VERSION,
                **{table: NPC_SCHEMA_VERSION for table in candidate.npc_tables},
            }
            Reader, ReaderError = _load_core_reader(self.core_repository)
            with Reader(candidate.path) as reader:
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
            return replace(
                candidate,
                mod_activation=self.mod_activation(candidate.path),
            )
        except SaveCatalogError:
            raise
        except (ReaderError, OSError, ValueError) as error:
            raise SaveCatalogError(f"invalid save: {candidate.path}: {error}") from error

    def discover(self) -> dict[str, Any]:
        accepted: list[dict[str, Any]] = []
        rejected: list[dict[str, str]] = []
        for path, root in _candidate_files(self.roots):
            try:
                candidate = self.inspect_source(path)
                mode, _save_name = _save_location(path, root)
                value = candidate.to_dict()
                value["mode"] = mode
                value["modActivation"] = _mod_activation_metadata(
                    path,
                    mode=mode,
                    save_root=root,
                    server_root=self.server_root,
                )
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
            "readableWorldVersions": sorted(READABLE_WORLD_VERSIONS),
            "currentWorldVersion": CURRENT_WORLD_VERSION,
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
