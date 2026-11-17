from __future__ import annotations

import gc
import json
import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from tools.semantic_harness.core.worker_session import WorkerReady
from tools.semantic_harness.ui.layout_state_controller import restore_ui_state
from tools.semantic_harness.ui.lifecycle_controller import run_gui
from tools.semantic_harness.ui.shell import SemanticHarnessApp
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


class _PaintBootstrap:
    def __init__(self, events: list[str]) -> None:
        self.events = events

    def destroy(self) -> None:
        self.events.append("destroy")


class _PaintRoot:
    def __init__(self) -> None:
        self.events: list[object] = []
        self._semantic_harness_bootstrap = _PaintBootstrap(self.events)

    def update_idletasks(self) -> None:
        self.events.append("idle")

    def update(self) -> None:
        self.events.append("update")

    def after(self, delay: int, callback: object) -> str:
        self.events.append(("after", delay, callback))
        return "studio-after"


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

    def test_base_shell_paints_before_deferred_studio_build(self) -> None:
        root = _PaintRoot()
        app = object.__new__(SemanticHarnessApp)
        app.root = root
        app._tk = SimpleNamespace(TclError=RuntimeError)
        app.closed = False
        app._initial_ui_ready_after = "base-after"
        app._studio_editor_build_after = None

        app._show_base_ui()

        self.assertIsNone(root._semantic_harness_bootstrap)
        self.assertEqual(root.events[:4], ["idle", "destroy", "idle", "update"])
        self.assertEqual(root.events[4][0:2], ("after", 50))

    @unittest.skipUnless(os.environ.get("DISPLAY"), "requires a Tk display")
    def test_saved_selection_mode_builds_world_controls_before_restore(self) -> None:
        import tkinter as tk
        from tkinter import ttk

        from tools.semantic_harness.entrypoints.cli import _parser

        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "selected-save-state.json"
            state_path.write_text(
                json.dumps(
                    {
                        "layout_state_version": 6,
                        "selection_source_mode": "Selected save",
                        "saved_world_view": "Relationship to Player",
                    }
                ),
                encoding="utf-8",
            )
            root = tk.Tk()
            root.geometry("980x620")
            bootstrap = ttk.Frame(root)
            bootstrap.pack(fill="both", expand=True)
            root._semantic_harness_bootstrap = bootstrap
            root.update_idletasks()
            root.update()
            app = None
            try:
                app = SemanticHarnessApp(
                    root,
                    _parser().parse_args(
                        ["--gui", "--ui-state", str(state_path)]
                    ),
                )
            finally:
                if app is not None:
                    app.close()
                    del app
                else:
                    root.destroy()
                del root
                gc.collect()

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
