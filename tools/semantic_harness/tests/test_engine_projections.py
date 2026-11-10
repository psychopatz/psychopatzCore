from __future__ import annotations

import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from semantic_harness.fixture_provider import OfflineEngineFixtureProvider
from semantic_harness.health import normalize_scenario
from semantic_harness.item_catalog import _parse_script_text
from semantic_harness.live_profiler_provider import LiveProfilerProvider
from semantic_harness.player_engine_state import OfflinePlayerEngineStateProvider


CORE_REPOSITORY = Path(__file__).resolve().parents[3]


class CoreEngineProjectionTests(unittest.TestCase):
    def test_engine_fixture_and_health_contracts_are_provider_neutral(self) -> None:
        scenario = {
            "player": {"needs": {"hunger": 0.2}},
            "npc": {"health": {"state": "normal", "current": 90}},
            "world": {"weather": "clear"},
        }
        fixture = OfflineEngineFixtureProvider().catalog(scenario)
        self.assertEqual(fixture["providerID"], "offline_engine_fixtures")
        normalized = normalize_scenario(scenario)
        self.assertEqual(normalized["npc"]["health"]["state"], "normal")

    def test_engine_fixture_fields_are_explicit_and_editable(self) -> None:
        scenario = {
            "player": {"needs": {"hunger": 0.2}},
            "npc": {"needs": {"thirst": 0.4}},
            "world": {"timeOfDay": 13.5, "weather": "clear"},
        }

        projection = OfflineEngineFixtureProvider().catalog(scenario)

        self.assertEqual(projection["source"], "FIXTURE")
        fields = {field["id"]: field for field in projection["fields"]}
        for field_id in (
            "player.needs",
            "npc.needs",
            "world.timeOfDay",
            "world.weather",
        ):
            self.assertEqual(fields[field_id]["source"], "FIXTURE")
            self.assertTrue(fields[field_id]["editable"])

    def test_item_catalog_parser_has_no_provider_policy(self) -> None:
        parsed = _parse_script_text(
            "module Base\n{\n item Bandage\n {\n DisplayName = Bandage,\n }\n}\n"
        )
        self.assertEqual(
            parsed,
            [{"fullType": "Base.Bandage", "displayName": "Bandage"}],
        )

    def test_live_projection_is_read_only_and_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            snapshot = root / "PsychopatzCore_Profiler_latest.json"
            config = root / "PsychopatzCore_Profiler.txt"
            snapshot.write_text(
                json.dumps(
                    {
                        "profilerVersion": 1,
                        "timestamp": 1,
                        "mode": "DETAILED",
                        "runtime": {"id": "core-test", "capture": {}},
                        "world": {"weather": "rain", "values": list(range(80))},
                    }
                ),
                encoding="utf-8",
            )
            config.write_text("config_version=2\nmode=DETAILED\n", encoding="utf-8")
            before = snapshot.read_bytes()
            projection = LiveProfilerProvider(
                core_repository=CORE_REPOSITORY,
                snapshot_path=snapshot,
                config_path=config,
                enabled=True,
            ).project(operation="GET_WORLD")
            self.assertTrue(projection["available"])
            self.assertEqual(projection["values"]["world"]["weather"], "rain")
            self.assertLessEqual(len(projection["values"]["world"]["values"]), 33)
            self.assertEqual(snapshot.read_bytes(), before)

    def test_native_player_projection_fails_closed_without_engine_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = OfflinePlayerEngineStateProvider().project(Path(directory))
        self.assertFalse(result["available"])
        self.assertEqual(result["source"], "MISSING")
        self.assertEqual(result["reason"], "players_db_missing")

    def test_native_player_projection_rejects_unsupported_world_version(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "WorldDictionaryReadable.lua").write_text(
                'items = {\n'
                '\t{\n'
                '\t\tregistryID = 1,\n'
                '\t\tfulltype = "Base.Apple",\n'
                '\t},\n'
                '}\n',
                encoding="utf-8",
            )
            database = root / "players.db"
            connection = sqlite3.connect(database)
            try:
                connection.execute(
                    "CREATE TABLE localPlayers ("
                    "id INTEGER PRIMARY KEY, name STRING, wx INTEGER, wy INTEGER, "
                    "x FLOAT, y FLOAT, z FLOAT, worldversion INTEGER, data BLOB, "
                    "isDead BOOLEAN)"
                )
                connection.execute(
                    "INSERT INTO localPlayers VALUES "
                    "(1, 'Saved Player', 0, 0, 0, 0, 0, 248, ?, 0)",
                    (b"unsupported",),
                )
                connection.commit()
            finally:
                connection.close()
            result = OfflinePlayerEngineStateProvider().project(root)
        self.assertFalse(result["available"])
        self.assertIn("unsupported native Player world version", result["reason"])


if __name__ == "__main__":
    unittest.main()
