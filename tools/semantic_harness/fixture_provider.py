"""Explicit offline engine-derived fixture provider."""

from __future__ import annotations

from copy import deepcopy
from typing import Any


ENGINE_FIXTURE_FIELDS: tuple[tuple[str, str], ...] = (
    ("player.needs", "player.needs"),
    ("npc.needs", "npc.needs"),
    ("world.timeOfDay", "world.timeOfDay"),
    ("world.worldAgeHours", "world.worldAgeHours"),
    ("world.weather", "world.weather"),
    ("world.weatherTransition", "world.weatherTransition"),
    ("world.temperature", "world.temperature"),
    ("world.season", "world.season"),
    ("world.activity", "world.activity"),
    ("world.position", "world.position"),
    ("world.nearbyZombieDensity", "world.nearbyZombieDensity"),
    ("world.zombieKills", "world.zombieKills"),
)


def _path_value(scenario: dict[str, Any], path: str) -> Any:
    value: Any = scenario
    for segment in path.split("."):
        if not isinstance(value, dict):
            return None
        value = value.get(segment)
    return deepcopy(value)


class OfflineEngineFixtureProvider:
    """Declare engine-only values as editable offline fixtures."""

    provider_id = "offline_engine_fixtures"
    source = "FIXTURE"

    def project(self, scenario: dict[str, Any]) -> dict[str, Any]:
        values: dict[str, Any] = {}
        paths: dict[str, dict[str, Any]] = {}
        for field_id, path in ENGINE_FIXTURE_FIELDS:
            value = _path_value(scenario, path)
            values[field_id] = value
            paths[field_id] = {
                "source": self.source if value is not None else "MISSING",
                "editable": True,
                "authority": "offline_fixture",
            }
        return {
            "schema": "semantic.offline_engine_fixtures.v1",
            "schemaVersion": 1,
            "providerID": self.provider_id,
            "source": self.source,
            "values": values,
            "paths": paths,
        }

    def catalog(self, scenario: dict[str, Any]) -> dict[str, Any]:
        projection = self.project(scenario)
        return {
            "schema": "semantic.offline_engine_fixture_catalog.v1",
            "schemaVersion": 1,
            "source": self.source,
            "providerID": self.provider_id,
            "editable": True,
            "fields": [
                {
                    "id": field_id,
                    "path": path,
                    "source": projection["paths"][field_id]["source"],
                    "value": projection["values"][field_id],
                    "editable": True,
                }
                for field_id, path in ENGINE_FIXTURE_FIELDS
            ],
        }

    def provenance_paths(self, scenario: dict[str, Any]) -> dict[str, dict[str, Any]]:
        return {
            field_id: {
                "source": self.project(scenario)["paths"][field_id]["source"],
                "provider": self.provider_id,
            }
            for field_id, _path in ENGINE_FIXTURE_FIELDS
        }


__all__ = ["ENGINE_FIXTURE_FIELDS", "OfflineEngineFixtureProvider"]
