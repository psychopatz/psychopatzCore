import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from profiler_core import (CsvRecorder, HistoryStore, ProcessMonitor, ProfilerModel,
                           SnapshotReader, build_llm_report, read_game_profiler_mode,
                           score_process, write_game_profiler_mode, write_llm_report)


class NoSuchProcess(Exception):
    pass


class AccessDenied(Exception):
    pass


class ZombieProcess(Exception):
    pass


class Memory:
    rss = 1024
    vms = 2048


class FakeProcess:
    def __init__(self, info, alive=True):
        self.info = info
        self.pid = info["pid"]
        self.alive = alive

    def _check(self):
        if not self.alive:
            raise NoSuchProcess()

    def cpu_percent(self, _interval): self._check(); return 12.5
    def memory_info(self): self._check(); return Memory()
    def create_time(self): self._check(); return 1.0
    def name(self): self._check(); return self.info["name"]
    def num_threads(self): self._check(); return 7


class FakePsutil:
    NoSuchProcess = NoSuchProcess
    AccessDenied = AccessDenied
    ZombieProcess = ZombieProcess

    def __init__(self, processes=()):
        self.processes = {process.pid: process for process in processes}

    def process_iter(self, _attrs):
        return list(self.processes.values())

    def Process(self, pid):
        if pid not in self.processes:
            raise NoSuchProcess()
        return self.processes[pid]


class ProcessTests(unittest.TestCase):
    def test_score_never_matches_generic_java(self):
        self.assertEqual(score_process({"name": "java", "cmdline": ["java", "idea"]})[0], 0)
        self.assertGreater(score_process({"name": "java", "cmdline": ["java", "zomboid.gameStates.MainScreenState"]})[0], 0)

    def test_file_manager_browsing_zomboid_path_is_not_a_candidate(self):
        info = {
            "name": "nemo",
            "exe": "/usr/bin/nemo",
            "cmdline": ["/usr/bin/nemo", "/home/user/Zomboid/Workshop/psychopatzCore"],
        }
        self.assertEqual(score_process(info)[0], 0)

    def test_no_one_and_multiple_candidates(self):
        monitor = ProcessMonitor(FakePsutil())
        self.assertEqual(monitor.discover(), [])
        one = FakeProcess({"pid": 1, "name": "ProjectZomboid64", "exe": "", "cmdline": []})
        two = FakeProcess({"pid": 2, "name": "java", "exe": "", "cmdline": ["java", "zomboid", "dedicated"]})
        monitor = ProcessMonitor(FakePsutil((one, two)))
        candidates = monitor.discover()
        self.assertEqual(len(candidates), 2)
        self.assertEqual(candidates[1].kind, "dedicated server")

    def test_selected_process_exit_and_restart(self):
        first = FakeProcess({"pid": 10, "name": "ProjectZomboid64", "exe": "", "cmdline": []})
        fake = FakePsutil((first,))
        monitor = ProcessMonitor(fake)
        self.assertTrue(monitor.select(10))
        self.assertTrue(monitor.sample()["connected"])
        first.alive = False
        self.assertFalse(monitor.sample()["connected"])
        second = FakeProcess({"pid": 11, "name": "ProjectZomboid64", "exe": "", "cmdline": []})
        fake.processes[11] = second
        self.assertTrue(monitor.select(11))
        self.assertTrue(monitor.sample()["connected"])


class SnapshotTests(unittest.TestCase):
    def test_missing_invalid_valid_and_version(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "latest.json"
            reader = SnapshotReader(path)
            self.assertIsNone(reader.read())
            path.write_text("{broken", encoding="utf-8")
            self.assertIsNone(reader.read())
            valid = {"profilerVersion": 1, "namespaces": {}}
            path.write_text(json.dumps(valid), encoding="utf-8")
            self.assertEqual(reader.read(), valid)
            path.write_text(json.dumps({"profilerVersion": 99}), encoding="utf-8")
            self.assertEqual(reader.read(), valid)
            self.assertIn("unsupported", reader.status)

    def test_game_profiler_config_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Lua" / "PsychopatzCore_Profiler.txt"
            self.assertEqual(read_game_profiler_mode(path), "OFF")
            self.assertEqual(write_game_profiler_mode("detailed", path), path)
            self.assertEqual(read_game_profiler_mode(path), "DETAILED")
            write_game_profiler_mode("OFF", path)
            self.assertEqual(read_game_profiler_mode(path), "OFF")

    def test_game_profiler_config_rejects_unknown_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                write_game_profiler_mode("turbo", Path(directory) / "config.txt")


class BoundedAndRecordingTests(unittest.TestCase):
    def test_history_is_bounded(self):
        history = HistoryStore(3)
        for index in range(10):
            history.add("rss", index, index)
        self.assertEqual(len(history.series["rss"]), 3)

    def test_recording_marker_stop_and_rotation(self):
        with tempfile.TemporaryDirectory() as directory:
            recorder = CsvRecorder(max_bytes=1024)
            first = recorder.start(Path(directory))
            rows = ({"timestamp": index, "row_type": "metric", "metric": "x" * 300, "value": index}
                    for index in range(12))
            recorder.write_rows(rows)
            recorder.marker(13, 42, "Spawned test NPCs")
            final = recorder.path
            recorder.stop()
            self.assertTrue(first.exists())
            self.assertNotEqual(first, final)
            self.assertFalse(recorder.active)
            with final.open(newline="", encoding="utf-8") as handle:
                parsed = list(csv.DictReader(handle))
            self.assertTrue(any(row["row_type"] == "marker" for row in parsed))

    def test_model_marker_is_bounded_and_recordable(self):
        model = ProfilerModel(3)
        for index in range(8):
            model.update({"connected": True, "pid": 1, "rss": index, "cpu_percent": 1, "threads": 2}, None)
        model.add_marker("battle")
        self.assertLessEqual(len(model.history.series["process.rss"]), 3)
        self.assertEqual(model.history.markers[-1][1], "battle")

    def test_llm_report_is_bounded_and_contains_moddata_diagnostic(self):
        timers = {f"Timer{index}": {"msPerSec": index, "peakMs": index * 2}
                  for index in range(50)}
        diagnostic = {"valuesRedacted": True, "persisted": {"estimatedBytes": 1234}}
        snapshot = {
            "timestamp": 42,
            "mode": "DETAILED",
            "namespaces": {"ProjectHoomans": {"timers": timers, "gauges": {}}},
            "diagnostics": {"ProjectHoomans.modData": diagnostic},
        }
        report = build_llm_report({"pid": 7, "rss": 99}, snapshot)
        self.assertEqual(report["modData"], diagnostic)
        self.assertEqual(len(report["projectHoomans"]["topTimers"]), 20)
        self.assertEqual(report["projectHoomans"]["topTimers"][0]["name"], "Timer49")
        with tempfile.TemporaryDirectory() as directory:
            path = write_llm_report(report, Path(directory) / "report.json")
            self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["reportVersion"], 1)


if __name__ == "__main__":
    unittest.main()
