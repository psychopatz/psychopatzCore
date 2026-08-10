import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import psychopatz_profiler


class FakeRecorder:
    def __init__(self): self.stopped = False
    def stop(self): self.stopped = True


class FakeRoot:
    def __init__(self): self.destroyed = False
    def destroy(self): self.destroyed = True


class UiLifecycleTests(unittest.TestCase):
    def test_close_stops_recording_and_destroys_root(self):
        ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
        ui.root = FakeRoot()
        ui.model = type("Model", (), {"recorder": FakeRecorder()})()
        ui.closed = False
        ui.close()
        self.assertTrue(ui.closed)
        self.assertTrue(ui.root.destroyed)
        self.assertTrue(ui.model.recorder.stopped)

    def test_pid_argument(self):
        args = psychopatz_profiler.parse_args(["--pid", "123", "--interval", "2"])
        self.assertEqual(args.pid, 123)
        self.assertEqual(args.interval, 2.0)


if __name__ == "__main__":
    unittest.main()
