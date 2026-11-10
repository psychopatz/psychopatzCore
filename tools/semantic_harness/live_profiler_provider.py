"""Optional, read-only projection of the PsychopatzCore profiler snapshot.

The game remains the owner of the live data.  This provider only reads the
Core snapshot/configuration files and returns bounded projections; it has no
command transport and deliberately exposes no mutation operation.
"""

from __future__ import annotations

from copy import deepcopy
import sys
from pathlib import Path
from typing import Any, Mapping

from .fixture_provider import ENGINE_FIXTURE_FIELDS
from semantic_harness.state import Provenance


DEFAULT_SNAPSHOT_NAME = "PsychopatzCore_Profiler_latest.json"
DEFAULT_CONFIG_NAME = "PsychopatzCore_Profiler.txt"
LIVE_PROVIDER_SCHEMA = "semantic.live_profiler_provider.v1"
LIVE_CATALOG_SCHEMA = "semantic.live_profiler_catalog.v1"

READ_ONLY_OPERATIONS = (
    "GET_SNAPSHOT",
    "GET_PLAYER",
    "GET_NPC",
    "GET_WORLD",
    "GET_FACTIONS",
)

# These names are part of the safety contract shown to the Lab.  They are
# never dispatched to Project Zomboid; the provider has no write transport.
FORBIDDEN_OPERATIONS = (
    "SET_RELATIONSHIP",
    "RECRUIT_NPC",
    "SET_BOND",
    "SET_WEATHER",
    "MUTATE_INVENTORY",
)


def _bounded_copy(value: Any, depth: int = 5, max_items: int = 32,
                  max_string: int = 240) -> Any:
    """Copy a snapshot value without returning an unbounded profiler tree."""

    if isinstance(value, str):
        return value if len(value) <= max_string else value[:max_string] + "…"
    if isinstance(value, Mapping):
        if depth <= 0:
            return {"_omittedEntries": len(value)}
        keys = sorted((str(key) for key in value), key=str.casefold)
        output = {
            key: _bounded_copy(value[key], depth - 1, max_items, max_string)
            for key in keys[:max_items]
        }
        if len(keys) > max_items:
            output["_omittedEntries"] = len(keys) - max_items
        return output
    if isinstance(value, (list, tuple)):
        if depth <= 0:
            return [{"_omittedItems": len(value)}]
        output = [
            _bounded_copy(item, depth - 1, max_items, max_string)
            for item in value[:max_items]
        ]
        if len(value) > max_items:
            output.append({"_omittedItems": len(value) - max_items})
        return output
    return deepcopy(value)


def _path_get(value: Any, path: str) -> Any:
    current = value
    for segment in path.split("."):
        if not isinstance(current, Mapping):
            return None
        current = current.get(segment)
    return deepcopy(current)


def _path_set(target: dict[str, Any], path: str, value: Any) -> bool:
    segments = path.split(".")
    current: dict[str, Any] = target
    for segment in segments[:-1]:
        child = current.get(segment)
        if not isinstance(child, dict):
            child = {}
            current[segment] = child
        current = child
    current[segments[-1]] = deepcopy(value)
    return True


def _flatten_paths(value: Any, prefix: str, output: dict[str, dict[str, Any]]) -> None:
    if isinstance(value, Mapping):
        for key in sorted(value, key=lambda item: str(item).casefold()):
            _flatten_paths(value[key], f"{prefix}.{key}", output)
        return
    output[prefix] = {
        "source": Provenance.LIVE.value,
        "provider": "live_profiler",
    }


def _core_profiler_tools(core_repository: Path) -> tuple[Any, Any, Any, Any]:
    """Load the existing Core snapshot/config helpers without duplicating them."""

    tools_path = Path(core_repository) / "tools" / "profiler"
    if not tools_path.is_dir():
        raise ImportError(f"Core profiler tools not found: {tools_path}")
    path_text = str(tools_path)
    if path_text not in sys.path:
        sys.path.insert(0, path_text)
    from profiler_cli import capture_manifest, read_snapshot, snapshot_npc_data
    from profiler_config import read_capture_config

    return capture_manifest, read_snapshot, snapshot_npc_data, read_capture_config


class LiveProfilerProvider:
    """Read-only optional provider backed by one Core profiler snapshot."""

    provider_id = "live_profiler"
    source = Provenance.LIVE.value

    def __init__(
        self,
        *,
        core_repository: Path,
        snapshot_path: Path | None = None,
        config_path: Path | None = None,
        enabled: bool = False,
        section_aliases: Mapping[str, tuple[str, ...]] | None = None,
    ) -> None:
        self.core_repository = Path(core_repository)
        lua_root = Path.home() / "Zomboid" / "Lua"
        self.snapshot_path = Path(snapshot_path or lua_root / DEFAULT_SNAPSHOT_NAME)
        self.config_path = Path(config_path or lua_root / DEFAULT_CONFIG_NAME)
        self.enabled = bool(enabled)
        self.section_aliases = {
            str(section): tuple(str(alias) for alias in aliases)
            for section, aliases in (section_aliases or {}).items()
        }

    def _section_keys(self, section: str) -> tuple[str, ...]:
        return self.section_aliases.get(section, (section,))

    def _unavailable(self, reason: str, detail: str | None = None) -> dict[str, Any]:
        result: dict[str, Any] = {
            "schema": LIVE_PROVIDER_SCHEMA,
            "schemaVersion": 1,
            "providerID": self.provider_id,
            "source": Provenance.MISSING.value,
            "enabled": self.enabled,
            "available": False,
            "readOnly": True,
            "reason": reason,
            "snapshotPath": str(self.snapshot_path),
            "configPath": str(self.config_path),
            "allowedOperations": list(READ_ONLY_OPERATIONS),
            "forbiddenOperations": list(FORBIDDEN_OPERATIONS),
            "values": {},
            "paths": {},
        }
        if detail:
            result["detail"] = detail
        return result

    def _load(self) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
        if not self.enabled:
            return None, self._unavailable("disabled_by_default")
        try:
            capture_manifest, read_snapshot, snapshot_npc_data, read_capture_config = (
                _core_profiler_tools(self.core_repository)
            )
            config = read_capture_config(self.config_path)
            if config.mode == "OFF":
                return None, self._unavailable("configured_off")
            snapshot = read_snapshot(self.snapshot_path)
        except (ImportError, OSError, ValueError) as error:
            return None, self._unavailable("snapshot_unavailable", str(error))
        if not isinstance(snapshot, dict):
            return None, self._unavailable("snapshot_invalid")
        return snapshot, {
            "capture_manifest": capture_manifest,
            "snapshot_npc_data": snapshot_npc_data,
            "config": config,
        }

    @staticmethod
    def _selected_npc(data: Mapping[str, Any], npc_id: str | None) -> Any:
        if not npc_id:
            return None
        for collection_name in ("records", "roster"):
            for item in data.get(collection_name) or []:
                if isinstance(item, Mapping) and str(item.get("id")) == str(npc_id):
                    return dict(item)
        return None

    @staticmethod
    def _first_mapping(snapshot: Mapping[str, Any], keys: tuple[str, ...]) -> Any:
        diagnostics = snapshot.get("diagnostics")
        sources = (snapshot, diagnostics if isinstance(diagnostics, Mapping) else {})
        for source in sources:
            for key in keys:
                value = source.get(key) if isinstance(source, Mapping) else None
                if isinstance(value, Mapping):
                    return value
        return None

    def project(
        self,
        *,
        operation: str = "GET_SNAPSHOT",
        player_id: str | None = None,
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Return one bounded read-only projection for an allowed operation."""

        operation = str(operation or "GET_SNAPSHOT").upper()
        if operation not in READ_ONLY_OPERATIONS:
            return self._unavailable("forbidden_operation", operation)
        snapshot, loaded = self._load()
        if snapshot is None:
            return loaded or self._unavailable("snapshot_unavailable")

        capture_manifest = loaded["capture_manifest"]
        snapshot_npc_data = loaded["snapshot_npc_data"]
        npc_data = snapshot_npc_data(snapshot)
        values: dict[str, Any] = {}
        if operation in ("GET_SNAPSHOT", "GET_WORLD"):
            world = self._first_mapping(
                snapshot, self._section_keys("world")
            )
            if world is not None:
                values["world"] = _bounded_copy(world)
        if operation in ("GET_SNAPSHOT", "GET_PLAYER"):
            player = self._first_mapping(
                snapshot, self._section_keys("player")
            )
            if player is not None:
                values["player"] = _bounded_copy(player)
        if operation in ("GET_SNAPSHOT", "GET_NPC"):
            if capture_manifest(snapshot).get("npc") is True:
                selected = self._selected_npc(npc_data, npc_id)
                if selected is not None:
                    values["npc"] = _bounded_copy(selected)
                elif operation == "GET_NPC" and npc_id:
                    values["npc"] = {
                        "id": str(npc_id),
                        "status": "not_present_in_bounded_snapshot",
                    }
        if operation in ("GET_SNAPSHOT", "GET_FACTIONS"):
            factions = self._first_mapping(
                snapshot, self._section_keys("factions")
            )
            if factions is not None:
                values["factions"] = _bounded_copy(factions)

        paths: dict[str, dict[str, Any]] = {}
        for section, value in values.items():
            _flatten_paths(value, section, paths)
        runtime = snapshot.get("runtime")
        runtime = runtime if isinstance(runtime, Mapping) else {}
        capture = runtime.get("capture")
        capture = capture if isinstance(capture, Mapping) else capture_manifest(snapshot)
        result: dict[str, Any] = {
            "schema": LIVE_PROVIDER_SCHEMA,
            "schemaVersion": 1,
            "providerID": self.provider_id,
            "source": self.source,
            "enabled": True,
            "available": True,
            "readOnly": True,
            "operation": operation,
            "snapshotPath": str(self.snapshot_path),
            "configPath": str(self.config_path),
            "snapshot": {
                "profilerVersion": snapshot.get("profilerVersion"),
                "timestamp": snapshot.get("timestamp"),
                "mode": snapshot.get("mode"),
                "source": snapshot.get("source"),
                "runtimeID": runtime.get("id"),
                "configFingerprint": runtime.get("configFingerprint"),
                "capture": dict(capture),
            },
            "allowedOperations": list(READ_ONLY_OPERATIONS),
            "forbiddenOperations": list(FORBIDDEN_OPERATIONS),
            "values": values,
            "paths": paths,
        }
        if player_id is not None:
            result["playerID"] = str(player_id)
        if npc_id is not None:
            result["npcID"] = str(npc_id)
        return result

    def catalog(self, *, npc_id: str | None = None) -> dict[str, Any]:
        projection = self.project(npc_id=npc_id)
        return {
            "schema": LIVE_CATALOG_SCHEMA,
            "schemaVersion": 1,
            "providerID": self.provider_id,
            "source": projection.get("source", Provenance.MISSING.value),
            "enabled": projection.get("enabled", False),
            "available": projection.get("available", False),
            "readOnly": True,
            "reason": projection.get("reason"),
            "snapshot": projection.get("snapshot"),
            "allowedOperations": list(READ_ONLY_OPERATIONS),
            "forbiddenOperations": list(FORBIDDEN_OPERATIONS),
            "paths": projection.get("paths", {}),
        }

    def fixture_enrichment(
        self, projection: Mapping[str, Any]
    ) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
        """Extract only engine-fixture-shaped values for an explicit import."""

        values = projection.get("values")
        if not isinstance(values, Mapping):
            return {}, {}
        enrichment: dict[str, Any] = {}
        provenance: dict[str, dict[str, Any]] = {}
        for _field_id, path in ENGINE_FIXTURE_FIELDS:
            value = _path_get(values, path)
            if value is None:
                continue
            _path_set(enrichment, path, value)
            provenance[path] = {
                "source": Provenance.LIVE.value,
                "provider": self.provider_id,
            }
        return enrichment, provenance


__all__ = [
    "DEFAULT_CONFIG_NAME",
    "DEFAULT_SNAPSHOT_NAME",
    "FORBIDDEN_OPERATIONS",
    "LIVE_CATALOG_SCHEMA",
    "LIVE_PROVIDER_SCHEMA",
    "LiveProfilerProvider",
    "READ_ONLY_OPERATIONS",
]
