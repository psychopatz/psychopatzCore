import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from profiler_config import (CaptureConfig, parse_capture_config,
                             runtime_application_state, write_capture_config)


class CaptureConfigTests(unittest.TestCase):
    def test_round_trip_and_runtime_fingerprint(self):
        config = CaptureConfig(mode="DETAILED", sections=("performance", "npc"),
                               npc_ids=("npc_2", "npc_1"))
        parsed = parse_capture_config(config.serialize())
        self.assertEqual(parsed, config)
        state, _ = runtime_application_state(config, {
            "runtime": {"id": "boot-123", "configFingerprint": config.fingerprint},
        })
        self.assertEqual(state, "applied")
        state, _ = runtime_application_state(config, {
            "runtime": {"id": "boot-old", "configFingerprint": "different"},
        })
        self.assertEqual(state, "restart_required")

    def test_default_capture_is_performance_only(self):
        config = parse_capture_config("mode=DETAILED\n")
        self.assertEqual(config.sections, ("performance",))
        self.assertFalse(config.enabled("moddata"))
        self.assertFalse(config.enabled("npc"))


class ProfilerCliTests(unittest.TestCase):
    def test_status_and_bounded_targeted_npc_report(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = CaptureConfig(mode="DETAILED", sections=("performance", "npc"),
                                   npc_ids=("npc_1",))
            config_path = write_capture_config(config, root / "config.txt")
            snapshot = {
                "profilerVersion": 1, "timestamp": 42, "mode": "DETAILED",
                "runtime": {"id": "boot-42", "configFingerprint": config.fingerprint,
                            "capture": {"performance": True, "moddata": False, "npc": True}},
                "namespaces": {"ProjectHoomans": {"timers": {
                    "Server.Update": {"msPerSec": 20},
                    "Tiny": {"msPerSec": 0.1},
                }, "gauges": {}}},
                "diagnostics": {"ProjectHoomans.npcData": {
                    "roster": [{"id": "npc_1", "name": "Alex"}],
                    "records": [{"id": "npc_1", "name": "Alex",
                                 "runtimeContent": {"animation": {"state": "walk"},
                                                    "inventory": {"items": list(range(100))}},
                                 "persistedContent": {}}],
                }},
            }
            snapshot_path = root / "snapshot.json"
            snapshot_path.write_text(json.dumps(snapshot), encoding="utf-8")
            status = subprocess.run([
                sys.executable, str(ROOT / "profiler_cli.py"),
                "--snapshot", str(snapshot_path), "--config", str(config_path),
                "--process-report", str(root / "missing.json"), "status",
            ], check=True, text=True, capture_output=True)
            self.assertEqual(json.loads(status.stdout)["state"], "applied")
            report = subprocess.run([
                sys.executable, str(ROOT / "profiler_cli.py"),
                "--snapshot", str(snapshot_path), "--config", str(config_path),
                "--process-report", str(root / "missing.json"), "summarize",
                "--sections", "performance,npc", "--npc", "Alex",
                "--npc-view", "animation", "--min-ms", "0.5", "--token-budget", "1000",
            ], check=True, text=True, capture_output=True)
            parsed = json.loads(report.stdout)
            self.assertEqual(parsed["npcData"]["runtimeContent"]["animation"]["state"], "walk")
            self.assertNotIn("inventory", parsed["npcData"]["runtimeContent"])
            self.assertEqual(len(parsed["projectHoomans"]["topTimers"]), 1)
            self.assertLessEqual(len(report.stdout), 5000)


if __name__ == "__main__":
    unittest.main()
