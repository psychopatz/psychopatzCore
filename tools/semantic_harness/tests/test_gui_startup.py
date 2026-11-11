from __future__ import annotations

import json
import os
import unittest
from types import SimpleNamespace

from tools.semantic_harness.core.worker_session import WorkerReady
from tools.semantic_harness.ui.layout_state_controller import restore_ui_state
from tools.semantic_harness.ui.lifecycle_controller import run_gui
from tools.semantic_harness.ui.worker_ready_controller import _capability_summary


class _AfterRoot:
    def __init__(self) -> None:
        self.calls: list[tuple[int, object]] = []

    def after(self, delay: int, callback: object) -> str:
        self.calls.append((delay, callback))
        return f"after-{len(self.calls)}"


class _LayoutApp:
    def __init__(self) -> None:
        self.root = _AfterRoot()
        self._ui_state = {}


class GuiStartupTests(unittest.TestCase):
    def test_layout_restore_waits_for_mapped_window_timer(self) -> None:
        app = _LayoutApp()

        restore_ui_state(app)

        self.assertEqual(len(app.root.calls), 1)
        self.assertEqual(app.root.calls[0][0], 50)
        self.assertNotEqual(getattr(app.root.calls[0][1], "__name__", ""), "idle")

    def test_capability_summary_does_not_copy_large_catalogs(self) -> None:
        result = WorkerReady(
            status={"pid": 123},
            capabilities={
                "profile": "pnc",
                "providers": ["PsychopatzCore", "ProjectHoomans"],
                "loadedModules": ["module"] * 100,
                "flowCatalog": {
                    "flowCount": 27,
                    "factCatalog": [{"id": str(i)} for i in range(5000)],
                    "eventCatalog": [{"id": str(i)} for i in range(5000)],
                    "commandCatalog": [{"id": str(i)} for i in range(5000)],
                },
                "beatCatalog": {"beatCount": 11, "behaviorCount": 8},
            },
        )

        summary = _capability_summary(result)

        self.assertEqual(summary["flows"], 27)
        self.assertEqual(summary["engineFacts"], 5000)
        self.assertNotIn("factCatalog", summary)
        self.assertLess(len(json.dumps(summary)), 2000)

    @unittest.skipUnless(os.environ.get("DISPLAY"), "requires a Tk display")
    def test_run_gui_maps_window_before_app_constructor(self) -> None:
        observed: dict[str, object] = {}

        class FakeApp:
            def __init__(self, root: object, _arguments: object) -> None:
                observed["viewable"] = root.winfo_viewable()
                observed["geometry"] = root.geometry()
                root.after(1, root.destroy)

        result = run_gui(FakeApp, SimpleNamespace())

        self.assertEqual(result, 0)
        self.assertEqual(observed["viewable"], 1)
        self.assertNotEqual(str(observed["geometry"]).split("x", 1)[0], "1")


if __name__ == "__main__":
    unittest.main()
