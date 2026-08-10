import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import psychopatz_profiler


class TkHierarchyTests(unittest.TestCase):
    def setUp(self):
        if psychopatz_profiler.tk is None:
            self.skipTest("Tkinter unavailable")
        try:
            self.root = psychopatz_profiler.tk.Tk()
        except psychopatz_profiler.tk.TclError as error:
            self.skipTest(f"display unavailable: {error}")
        self.root.withdraw()
        self.ui = psychopatz_profiler.TkinterProfilerUI(self.root, None, None, 1.0)

    def tearDown(self):
        if hasattr(self, "ui") and not self.ui.closed:
            self.ui.close()

    def test_metric_hierarchy_and_collapse_survive_refresh(self):
        snapshot = {
            "namespaces": {
                "ProjectHoomans": {
                    "displayName": "Project Hoomans",
                    "timers": {
                        "Server.Update": {"msPerSec": 300},
                        "Server.Update.PlayerCharacters": {"msPerSec": 70},
                        "Server.Update.NPC.Health": {"msPerSec": 20},
                        "Network.BroadcastRecord": {"msPerSec": 100},
                        "Network.BroadcastRecord.BuildPayload": {"msPerSec": 80},
                    },
                },
            },
        }
        self.ui._render_metrics(snapshot)
        server = "metric|ProjectHoomans|Server.Update"
        network = "metric|ProjectHoomans|Network.BroadcastRecord"
        self.assertTrue(self.ui.metrics.exists(server))
        self.assertTrue(self.ui.metrics.exists(network))
        self.assertTrue(self.ui.metrics.exists("metric|ProjectHoomans|Server.Update.PlayerCharacters"))
        self.ui.metrics.focus(server)
        self.ui.metrics.event_generate("<<TreeviewClose>>", when="now")
        self.ui.metrics.item(server, open=False)
        self.ui._render_metrics(snapshot)
        self.assertFalse(bool(self.ui.metrics.item(server, "open")))

    def test_pause_skips_collection_until_resumed(self):
        self.ui.toggle_pause()
        self.assertTrue(self.ui.paused)
        self.assertEqual(self.ui.pause_button.cget("text"), "Resume Updates")
        self.ui.monitor.sample = lambda: self.fail("paused poll sampled process")
        self.ui.poll()
        self.ui.toggle_pause()
        self.assertFalse(self.ui.paused)
        self.assertEqual(self.ui.pause_button.cget("text"), "Pause Updates")


if __name__ == "__main__":
    unittest.main()
