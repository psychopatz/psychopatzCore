#!/usr/bin/env python3
"""Deterministic verification tests for the V0 VANILLA_EVENT_COVERAGE.json manifest."""

import json
import subprocess
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
GENERATOR = REPO_ROOT / "tools" / "vanilla_event_coverage" / "generate_manifest.py"
MANIFEST_PATH = REPO_ROOT / "Docs" / "Jobs" / "UnifiedVanillaWorldEventSemantics" / "VANILLA_EVENT_COVERAGE.json"

sys.path.insert(0, str(GENERATOR.parent))
import generate_manifest  # noqa: E402


class VanillaEventCoverageManifestTests(unittest.TestCase):
    def test_check_cli_exits_cleanly_and_is_deterministic(self) -> None:
        proc = subprocess.run(
            [sys.executable, str(GENERATOR), "--check"],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, msg=proc.stdout + proc.stderr)
        self.assertIn("[OK] VANILLA_EVENT_COVERAGE.json verified", proc.stdout)

    def test_all_required_vanilla_families_and_counts_present(self) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        audit = manifest["installedBuildAudit"]
        self.assertEqual(audit["randomizedBuildingClasses"], 45)
        self.assertEqual(audit["randomizedDeadSurvivorClasses"], 33)
        self.assertEqual(audit["randomizedVehicleStoryClasses"], 26)
        self.assertEqual(audit["randomizedZoneStoryClasses"], 42)
        self.assertEqual(audit["randomizedRanchJavaClasses"], 2)
        self.assertGreaterEqual(audit["ranchZoneLuaDefinitions"], 21)

        by_id = {entry["id"]: entry for entry in manifest["entries"]}
        self.assertEqual(len(by_id), len(manifest["entries"]), "Entry IDs must be unique")

        # Mandatory exemplars & live hooks
        required_ids = [
            "utility.electricity_cutoff",
            "utility.water_cutoff",
            "world.helicopter_overflight",
            "ambient.MetaAssaultRifle1",
            "ambient.MetaPistol1",
            "ambient.MetaPistol2",
            "ambient.MetaPistol3",
            "ambient.MetaShotgun1",
            "ambient.MetaScream",
            "ambient.MetaDogBark",
            "ambient.MetaOwl",
            "ambient.MetaWolfHowl",
            "ambient.burglar2",
            "world.house_alarm_sp",
            "weather.period_start",
            "weather.thunder_event",
            "randomized_vehicle_story.RVSAmbulanceCrash",
            "randomized_vehicle_story.RVSBanditRoad",
            "randomized_vehicle_story.RVSPoliceBlockadeShooting",
            "randomized_vehicle_story.RVSCrashHorde",
            "randomized_zone_story.RZSMurderScene",
            "randomized_zone_story.RZSSurvivalistCamp",
            "randomized_building.RBGunstoreSiege",
            "randomized_building.RBSafehouse",
            "randomized_dead_survivor.RDSBanditRaid",
            "randomized_dead_survivor.RDSSuicidePact",
            "randomized_dead_survivor.RDSPoliceAtHouse",
            "randomized_ranch.RandomizedRanchBase",
        ]
        for req in required_ids:
            self.assertIn(req, by_id, f"Missing required manifest entry: {req}")
            self.assertIn(by_id[req]["classification"], generate_manifest.VALID_CLASSIFICATIONS)
            self.assertTrue(by_id[req]["evidenceNotes"])

        # Global scope restriction invariant on automatic vanilla events
        auto_global = [
            e["id"]
            for e in manifest["entries"]
            if e["defaultScope"] == "global" and e["classification"] != "intentionally_ephemeral"
        ]
        self.assertEqual(
            sorted(auto_global),
            ["utility.electricity_cutoff", "utility.water_cutoff"],
            "Automatic global scope must remain restricted to utilities",
        )


if __name__ == "__main__":
    unittest.main()
