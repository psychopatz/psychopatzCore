"""R9D: Real Tk/Xvfb acceptance tests for DialogueCompletenessWorkbench & S11 controls."""

from __future__ import annotations

import os
import tempfile
import tkinter as tk
from tkinter import scrolledtext, ttk
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import (
    ConvoEngineAuthoringPane,
)
from tools.semantic_harness.tests.convo_engine_test_support import (
    _FakeMessageBox,
    _setup_three_repo_workspace,
)


class DialogueCompletenessWorkbenchTkTests(unittest.TestCase):
    def test_real_tk_workbench_tabs_filtering_and_semantic_controls_roundtrip(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")
        root = tk.Tk()
        root.withdraw()
        try:
            with tempfile.TemporaryDirectory() as tmp:
                repos = _setup_three_repo_workspace(Path(tmp))
                service = SemanticLabAuthoringService(
                    repos["core"],
                    runtime_root=repos["hoomans"],
                    core_repository=repos["core"],
                    hoomans_repository=repos["hoomans"],
                    dynamic_trading_repository=repos["dt"],
                )
                pane = ConvoEngineAuthoringPane(
                    root,
                    tk,
                    ttk,
                    scrolledtext.ScrolledText,
                    _FakeMessageBox(),
                    service,
                    auto_refresh=True,
                )
                tab_labels = [
                    pane._right_notebook.tab(tab_id, "text")
                    for tab_id in pane._right_notebook.tabs()
                ]
                self.assertIn("S11 Semantic Controls", tab_labels)
                self.assertIn("Dialogue Completeness", tab_labels)

                # Select Dialogue Completeness tab and verify canonical report loads
                pane._right_notebook.select(pane._completeness_tab)
                root.update_idletasks()
                report = pane.completeness_workbench.ensure_loaded()
                self.assertGreater(report["summary"]["families"], 0)
                self.assertIn("maintained", pane.completeness_workbench._summary_var.get())
                self.assertIn("Dialogues", pane.completeness_workbench._summary_var.get())

                # Verify S11 Semantic Controls round-trip into canonical document
                pane._s11_scalar_vars["inputPolicy"].set("typed_parity")
                pane._s11_scalar_vars["repeatPolicy"].set("state_retired")
                doc = pane._form_document()
                self.assertEqual(doc["inputPolicy"], "typed_parity")
                self.assertEqual(doc["repeatPolicy"], "state_retired")
                for field_name in (
                    "statePolicy",
                    "postconditions",
                    "closure",
                    "roles",
                    "participantSet",
                    "topics",
                    "events",
                    "activities",
                    "memories",
                    "domains",
                ):
                    self.assertIn(field_name, pane._editors)
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
