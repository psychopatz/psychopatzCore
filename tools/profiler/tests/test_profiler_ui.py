import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import psychopatz_profiler
from profiler_core import ProcessCandidate


class FakeRecorder:
    def __init__(self): self.stopped = False
    def stop(self): self.stopped = True


class FakeRoot:
    def __init__(self):
        self.destroyed = False
        self.after_calls = []
    def destroy(self): self.destroyed = True
    def after(self, delay, callback): self.after_calls.append((delay, callback))


class FakeVar:
    def __init__(self, value=""): self.value = value
    def get(self): return self.value
    def set(self, value): self.value = value


class FakeCombo(dict):
    pass


class FakeBridgeTransport:
    def __init__(self): self.ensured = False
    def ensure_directories(self): self.ensured = True


class FakeBridgeClient:
    def __init__(self): self.submitted = None
    def submit(self, namespace, command, arguments):
        self.submitted = (namespace, command, arguments)
        return "request-1"


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

    def test_poll_reschedules_after_refresh_failure(self):
        ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
        ui.root = FakeRoot()
        ui.closed = False
        ui.interval = 1.25
        ui.status_var = FakeVar()
        ui.snapshot_var = FakeVar()
        ui.warning_var = FakeVar()
        ui._poll_once = lambda: (_ for _ in ()).throw(RuntimeError("render failed"))

        ui.poll()

        self.assertEqual(ui.status_var.get(), "UPDATE ERROR")
        self.assertIn("render failed", ui.snapshot_var.get())
        self.assertEqual(ui.root.after_calls, [(1250, ui.poll)])

    def test_refresh_candidates_displays_connected_process(self):
        old = ProcessCandidate(111, "ProjectZomboid64", "", "old", 125, "client")
        current = ProcessCandidate(222, "ProjectZomboid64", "", "current", 125, "client")
        monitor = type("Monitor", (), {
            "pid": 222,
            "process": object(),
            "discover": lambda self: [old, current],
        })()
        ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
        ui.monitor = monitor
        ui.process_combo = FakeCombo()
        ui.process_var = FakeVar(old.label)
        ui.app_settings = psychopatz_profiler.AppSettings()

        ui.refresh_candidates(auto_connect=False)

        self.assertEqual(ui.process_var.get(), current.label)

    def test_capture_pipeline_uses_restart_fallback_when_bridge_disabled(self):
        with tempfile.TemporaryDirectory() as directory:
            ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
            ui.game_config_path = Path(directory) / "profiler.txt"
            ui.bridge_config_path = Path(directory) / "bridge.txt"
            ui.bridge_transport = FakeBridgeTransport()
            ui.bridge_enabled_var = FakeVar(False)
            ui.bridge_status_var = FakeVar("DISCONNECTED")
            ui.bridge_response_var = FakeVar()
            ui.pending_live_config = None
            ui.refresh_game_mode = lambda: None
            config = psychopatz_profiler.CaptureConfig(
                mode="DETAILED", sections=("performance", "npc"), npc_ids=("npc-1",))

            with patch.object(psychopatz_profiler.messagebox, "showinfo") as showinfo:
                ui._apply_capture_config_pipeline(config)

            self.assertEqual(
                psychopatz_profiler.read_capture_config(ui.game_config_path), config)
            self.assertFalse(
                psychopatz_profiler.read_bridge_config(ui.bridge_config_path).enabled)
            self.assertIsNone(ui.pending_live_config)
            self.assertIn("restart", showinfo.call_args.args[1].lower())
            self.assertFalse(ui.bridge_transport.ensured)

    def test_capture_pipeline_waits_only_for_explicitly_enabled_bridge(self):
        with tempfile.TemporaryDirectory() as directory:
            ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
            ui.game_config_path = Path(directory) / "profiler.txt"
            ui.bridge_config_path = Path(directory) / "bridge.txt"
            psychopatz_profiler.write_bridge_config(
                psychopatz_profiler.BridgeConfig(enabled=True), ui.bridge_config_path)
            ui.bridge_status_var = FakeVar("ACTIVATING / WAITING")
            ui.bridge_response_var = FakeVar()
            ui.pending_live_config = None
            ui.refresh_game_mode = lambda: None
            config = psychopatz_profiler.CaptureConfig(
                mode="DETAILED", sections=("performance",))

            ui._apply_capture_config_pipeline(config)

            self.assertIs(ui.pending_live_config, config)
            self.assertIn("enabled local bridge", ui.bridge_response_var.get())

    def test_ping_sends_a_console_marker(self):
        ui = object.__new__(psychopatz_profiler.TkinterProfilerUI)
        ui.bridge_client = FakeBridgeClient()
        ui.bridge_request_actions = {}
        ui.bridge_response_var = FakeVar()

        ui.bridge_ping()

        namespace, command, arguments = ui.bridge_client.submitted
        self.assertEqual((namespace, command), ("psychopatzcore.bridge", "ping"))
        self.assertTrue(arguments["console_marker"].startswith("desktop-"))
        self.assertEqual(ui.bridge_request_actions["request-1"], "ping")


if __name__ == "__main__":
    unittest.main()
