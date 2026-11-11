"""Versioned provider-neutral source and working-world contracts."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from enum import Enum
from types import MappingProxyType
from typing import Any, Mapping


class Provenance(str, Enum):
    """Stable origin labels used by semantic harness state projections."""

    SAVE = "SAVE"
    FIXTURE = "FIXTURE"
    LIVE = "LIVE"
    DERIVED = "DERIVED"
    HARNESS_MUTATION = "HARNESS_MUTATION"
    MISSING = "MISSING"


SOURCE_SNAPSHOT_SCHEMA = "semantic.imported_source_snapshot.v1"
WORKING_WORLD_SCHEMA = "semantic.harness_working_world.v1"
PROVENANCE_SCHEMA = "semantic.provenance.v1"


def _freeze(value: Any) -> Any:
    if isinstance(value, Mapping):
        return MappingProxyType({str(key): _freeze(item) for key, item in value.items()})
    if isinstance(value, list):
        return tuple(_freeze(item) for item in value)
    if isinstance(value, tuple):
        return tuple(_freeze(item) for item in value)
    return value


def _thaw(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {key: _thaw(item) for key, item in value.items()}
    if isinstance(value, tuple):
        return [_thaw(item) for item in value]
    return deepcopy(value)


def _path_text(path: tuple[str, ...]) -> str:
    return ".".join(path)


def _diff(
    imported: Any,
    effective: Any,
    path: tuple[str, ...] = (),
    output: list[dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    """Return bounded, deterministic value patches between projections."""

    patches = output if output is not None else []
    if len(patches) >= 512:
        return patches
    if isinstance(imported, Mapping) and isinstance(effective, Mapping):
        keys = sorted(
            {str(key) for key in imported} | {str(key) for key in effective}
        )
        for key in keys:
            if len(patches) >= 512:
                break
            _diff(imported.get(key), effective.get(key), path + (key,), patches)
        return patches
    if imported == effective:
        return patches
    patches.append(
        {
            "path": _path_text(path),
            "imported": _thaw(imported),
            "effective": _thaw(effective),
            "source": Provenance.HARNESS_MUTATION.value,
        }
    )
    return patches


def _source_kind(value: Provenance | str | None) -> str:
    if isinstance(value, Provenance):
        return value.value
    normalized = str(value or Provenance.FIXTURE.value).upper()
    return normalized if normalized in {item.value for item in Provenance} else Provenance.MISSING.value


@dataclass(frozen=True)
class ImportedSourceSnapshot:
    """Immutable imported source data and its source-level metadata."""

    data: Mapping[str, Any]
    metadata: Mapping[str, Any]
    provenance: Mapping[str, Any]
    provider_payloads: Mapping[str, Any]
    schema: str = SOURCE_SNAPSHOT_SCHEMA
    schema_version: int = 1

    @classmethod
    def from_scenario(
        cls,
        scenario: Mapping[str, Any],
        *,
        source: Provenance | str = Provenance.FIXTURE,
        source_id: str = "fixture:synthetic-scenario",
        mode: str = "developer_test",
        metadata: Mapping[str, Any] | None = None,
        provenance: Mapping[str, Any] | None = None,
        provider_payloads: Mapping[str, Any] | None = None,
    ) -> "ImportedSourceSnapshot":
        source_kind = _source_kind(source)
        supplied_metadata = dict(metadata or {})
        supplied_metadata.update(
            {
                "sourceKind": source_kind,
                "sourceID": str(supplied_metadata.get("sourceID") or source_id),
                "mode": str(supplied_metadata.get("mode") or mode),
                "schemaVersion": 1,
                "immutable": True,
            }
        )
        supplied_provenance = dict(provenance or {})
        supplied_provenance.setdefault("schema", PROVENANCE_SCHEMA)
        supplied_provenance.setdefault("defaultSource", source_kind)
        supplied_provenance.setdefault("paths", {})
        return cls(
            data=_freeze(deepcopy(dict(scenario))),
            metadata=_freeze(supplied_metadata),
            provenance=_freeze(supplied_provenance),
            provider_payloads=_freeze(deepcopy(dict(provider_payloads or {}))),
        )

    @property
    def source(self) -> str:
        return str(self.metadata.get("sourceKind", Provenance.MISSING.value))

    def to_dict(self) -> dict[str, Any]:
        """Return a mutable transport copy without exposing mappings."""

        return {
            "schema": self.schema,
            "schemaVersion": self.schema_version,
            "data": _thaw(self.data),
            "metadata": _thaw(self.metadata),
            "provenance": _thaw(self.provenance),
            "providerPayloads": _thaw(self.provider_payloads),
        }


class HarnessWorkingWorld:
    """Mutable isolated world derived from one immutable source snapshot."""

    def __init__(self, source_snapshot: ImportedSourceSnapshot) -> None:
        self.source_snapshot = source_snapshot
        self._data: dict[str, Any] = source_snapshot.to_dict()["data"]
        self._baseline: dict[str, Any] = deepcopy(self._data)
        self._reset_count = 0
        self._patches: list[dict[str, Any]] = []

    @property
    def data(self) -> dict[str, Any]:
        return self._data

    @property
    def patches(self) -> list[dict[str, Any]]:
        self._patches = _diff(self._baseline, self._data)
        source_kind = self.source_snapshot.source
        for patch in self._patches:
            patch["baseSource"] = source_kind
        return deepcopy(self._patches)

    def replace(self, value: Mapping[str, Any]) -> dict[str, Any]:
        self._data = deepcopy(dict(value))
        return self.data

    def set_baseline(self, value: Mapping[str, Any]) -> dict[str, Any]:
        """Install a normalized effective baseline without changing source."""

        self._baseline = deepcopy(dict(value))
        self._data = deepcopy(self._baseline)
        return self.data

    def reset_turn(self) -> None:
        """Reset is represented by the worker's transient turn containers."""

    def reset_conversation(self) -> None:
        """Reset is represented by the worker's conversation containers."""

    def reset_selected_actor(self, actor: str) -> dict[str, Any]:
        source = self._baseline
        if actor in source:
            self._data[actor] = deepcopy(source[actor])
        return self.data

    def reset(self) -> dict[str, Any]:
        self._data = deepcopy(self._baseline)
        self._reset_count += 1
        return self.data

    def to_dict(self) -> dict[str, Any]:
        source = self.source_snapshot.to_dict()
        patches = self.patches
        return {
            "schema": WORKING_WORLD_SCHEMA,
            "schemaVersion": 1,
            "sourceSnapshotID": source["metadata"].get("sourceID"),
            "baseline": deepcopy(self._baseline),
            "effective": deepcopy(self._data),
            "patches": patches,
            "provenance": {
                "schema": PROVENANCE_SCHEMA,
                "defaultSource": source["metadata"].get(
                    "sourceKind", Provenance.MISSING.value
                ),
                "overrides": patches,
            },
            "resetCount": self._reset_count,
        }


__all__ = [
    "HarnessWorkingWorld",
    "ImportedSourceSnapshot",
    "PROVENANCE_SCHEMA",
    "Provenance",
    "SOURCE_SNAPSHOT_SCHEMA",
    "WORKING_WORLD_SCHEMA",
]
