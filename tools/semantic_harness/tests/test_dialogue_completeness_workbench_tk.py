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

                # Verify Treeview + real semantic tags configured in real Tk
                wb = pane.completeness_workbench
                self.assertEqual(wb._issue_filter_var.get(), "needs_attention")
                self.assertIsInstance(wb._family_tree, ttk.Treeview)
                for color in ("RED", "ORANGE", "YELLOW", "BLUE", "PURPLE", "GREEN"):
                    bg = wb._family_tree.tag_configure(color, "background")
                    self.assertTrue(bool(bg))
        finally:
            root.destroy()

    def test_real_tk_usability_journey_and_all_semantic_color_classes(self) -> None:
        from tools.semantic_harness.codebuilder.completeness_analyzer import analyze_portable_plan
        from tools.semantic_harness.codebuilder.portable_runtime import compile_portable_plan
        from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
        from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA
        from tools.semantic_harness.studio.completeness_workbench import DialogueCompletenessWorkbench

        root = tk.Tk()
        root.withdraw()
        try:
            service = SemanticLabAuthoringService()
            pane = ConvoEngineAuthoringPane(
                root,
                tk,
                ttk,
                scrolledtext.ScrolledText,
                _FakeMessageBox(),
                service,
                auto_refresh=True,
            )
            pane._right_notebook.select(pane._completeness_tab)
            root.update_idletasks()
            wb = pane.completeness_workbench
            wb.ensure_loaded()

            # 1. Needs attention is default and command.camp is immediately visible & ORANGE
            self.assertEqual(wb._issue_filter_var.get(), "needs_attention")
            children = wb._family_tree.get_children()
            self.assertIn("command.camp", children)
            camp_item = wb._family_tree.item("command.camp")
            self.assertIn("ORANGE", camp_item["tags"])
            self.assertIn("Warning / Risky", camp_item["values"][0])

            # 2. Selecting command.camp in Workbench synchronizes main Conversations editor
            wb._family_tree.selection_set("command.camp")
            wb._on_family_select()
            root.update_idletasks()
            self.assertEqual(pane._current_family_id, "command.camp")
            self.assertEqual(pane._current_entry["canonicalID"], "command.camp")

            # 3. Diagnostic contextual repair is displayed and Open affected field focuses exact control
            self.assertIn("Suggested structural fix", wb._repair_status_var.get())
            self.assertEqual(str(wb._preview_btn.cget("state")), "normal")
            self.assertEqual(str(wb._apply_btn.cget("state")), "normal")
            wb.open_affected_field()
            root.update_idletasks()
            self.assertEqual(pane._highlighted_field, "statePolicy")

            # 4. Healthy family is GREEN and has no active repair controls
            wb._issue_filter_var.set("all")
            wb._apply_filters()
            root.update_idletasks()
            accept_item = wb._family_tree.item("accept")
            self.assertIn("GREEN", accept_item["tags"])
            wb._family_tree.selection_set("accept")
            wb._on_family_select()
            root.update_idletasks()
            self.assertEqual(wb._repair_status_var.get(), "No structural repair needed")
            self.assertEqual(str(wb._preview_btn.cget("state")), "disabled")
            self.assertEqual(str(wb._apply_btn.cget("state")), "disabled")

            # 5. Synthetic Tk fixture proves RED, YELLOW, BLUE, PURPLE tags and labels in real Tk
            records = [
                {
                    "kind": "dialogue",
                    "namespace": "tktest",
                    "id": "red_broken",
                    "say": "Broken.",
                    "after": {"goto": "tktest.missing"},
                },
                {
                    "kind": "dialogue",
                    "namespace": "tktest",
                    "id": "yellow_pending",
                    "statePolicy": [
                        {
                            "id": "wait",
                            "when": {"path": "addressee.state", "op": "==", "value": "waiting"},
                            "outcome": "pending",
                            "reason": "waiting",
                            "admission": "defer",
                            "replyOutcome": "waiting",
                        },
                        {
                            "id": "ready",
                            "outcome": "actionable",
                            "reason": "ready",
                            "admission": "dispatch",
                        },
                    ],
                    "say": "Wait.",
                    "reply": {"waiting": {"say": "Still waiting.", "after": {"end": True}}},
                },
                {
                    "kind": "dialogue",
                    "namespace": "tktest",
                    "id": "blue_cont",
                    "say": "Continue.",
                    "after": {"goto": "tktest.purple_obl"},
                },
                {
                    "kind": "dialogue",
                    "namespace": "tktest",
                    "id": "purple_obl",
                    "closure": {"closureClass": "open_domain_obligation", "obligationRef": "task.escort"},
                    "say": "Follow me.",
                },
            ]
            compiled = compile_convo_engine_document(
                {"schema": CONVO_ENGINE_SCHEMA, "owner": "PsychopatzCore", "records": records}
            )
            synth_plan = compile_portable_plan(compiled["records"], package="tktest")
            synth_report = analyze_portable_plan(synth_plan)

            class _SynthSvc:
                def analyze_convo_completeness(self, **_kwargs):
                    return synth_report

            wb_synth = DialogueCompletenessWorkbench(
                root, tk, ttk, scrolledtext.ScrolledText, _FakeMessageBox(), _SynthSvc(), auto_analyze=False
            )
            wb_synth._issue_filter_var.set("all")
            wb_synth.run_strict_analysis()
            root.update_idletasks()
            self.assertIn("RED", wb_synth._family_tree.item("tktest.red_broken")["tags"])
            self.assertIn("YELLOW", wb_synth._family_tree.item("tktest.yellow_pending")["tags"])
            self.assertIn("BLUE", wb_synth._family_tree.item("tktest.blue_cont")["tags"])
            self.assertIn("PURPLE", wb_synth._family_tree.item("tktest.purple_obl")["tags"])
            for color in ("RED", "ORANGE", "YELLOW", "BLUE", "PURPLE", "GREEN"):
                self.assertTrue(bool(wb_synth._family_tree.tag_configure(color, "background")))
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
