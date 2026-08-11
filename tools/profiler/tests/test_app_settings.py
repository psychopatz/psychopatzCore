import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app_settings import (AppSettings, read_app_settings, select_preferred_candidate,
                          settings_for_candidate, write_app_settings)
import profiler_cli


class AppSettingsTests(unittest.TestCase):
    def test_atomic_round_trip_contains_no_pid_or_command_line(self):
        candidate = SimpleNamespace(pid=9876, name="ProjectZomboid64",
                                    executable="/game/ProjectZomboid64",
                                    command="--password secret", kind="client", score=125)
        settings = settings_for_candidate(candidate, AppSettings(poll_interval=2.0))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            write_app_settings(settings, path)
            encoded = path.read_text(encoding="utf-8")
            self.assertNotIn("9876", encoded)
            self.assertNotIn("password", encoded)
            self.assertEqual(read_app_settings(path), settings)

    def test_corrupt_settings_fail_safe_and_interval_is_bounded(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            path.write_text("{", encoding="utf-8")
            self.assertEqual(read_app_settings(path), AppSettings())
            path.write_text(json.dumps({"poll_interval": 99}), encoding="utf-8")
            self.assertEqual(read_app_settings(path).poll_interval, 5.0)

    def test_saved_name_matches_new_pid_and_disambiguates_kind(self):
        settings = AppSettings(preferred_process_name="ProjectZomboid64",
                               preferred_process_kind="client")
        server = SimpleNamespace(pid=10, name="ProjectZomboid64", executable="",
                                 kind="dedicated server", score=130)
        client = SimpleNamespace(pid=77, name="ProjectZomboid64", executable="",
                                 kind="client", score=125)
        self.assertIs(select_preferred_candidate((server, client), settings), client)
        replacement = SimpleNamespace(pid=101, name="ProjectZomboid64", executable="",
                                      kind="client", score=125)
        self.assertIs(select_preferred_candidate((replacement,), settings), replacement)

    def test_cli_samples_saved_identity_without_process_name_argument(self):
        candidate = SimpleNamespace(pid=55, name="ProjectZomboid64", executable="/game/pz",
                                    command="secret args", kind="client", score=120)
        monitor = SimpleNamespace(
            discover=lambda: [candidate], select=lambda pid: pid == 55,
            sample=lambda: {"connected": True, "pid": 55, "name": "ProjectZomboid64"})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.json"
            write_app_settings(AppSettings(
                preferred_process_name="ProjectZomboid64", preferred_process_kind="client"), path)
            with patch.object(profiler_cli, "ProcessMonitor", return_value=monitor):
                result = profiler_cli.sample_saved_process(path)
        self.assertTrue(result["connected"])
        self.assertEqual(result["pid"], 55)
        self.assertNotIn("command", result)


if __name__ == "__main__":
    unittest.main()
