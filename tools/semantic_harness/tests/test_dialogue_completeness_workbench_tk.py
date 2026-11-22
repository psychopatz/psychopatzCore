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
                self.assertIn("State & Flow", tab_labels)
                self.assertIn("Dialogue Completeness", tab_labels)
                self.assertNotIn("Simulation / trace", tab_labels)

                # Select Dialogue Completeness tab and verify canonical report loads
                pane._right_notebook.select(pane._completeness_tab)
                root.update_idletasks()
                report = pane.completeness_workbench.ensure_loaded()
                self.assertGreater(report["summary"]["families"], 0)
                self.assertIn("Package health:", pane.completeness_workbench._summary_var.get())
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
        from tools.semantic_harness.codebuilder.convo_engine_compiler import compile_convo_engine_document
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

            # 1. Needs attention is default and clean after CAMP single-family collapse; Package health scope is explicit
            self.assertEqual(wb._issue_filter_var.get(), "needs_attention")
            self.assertEqual(wb._family_tree.get_children(), ())
            self.assertIn("Package health:", wb._summary_var.get())

            # 2. Selecting command.camp while needs_attention is active reports explicit filter scope + GREEN health
            wb._issue_filter_var.set("all")
            wb._apply_filters()
            root.update_idletasks()
            camp_item = wb._family_tree.item("command.camp")
            self.assertIn("GREEN", camp_item["tags"])
            self.assertIn("Healthy", camp_item["values"][0])
            wb._issue_filter_var.set("needs_attention")
            wb._apply_filters()
            wb.select_family("command.camp", ensure_loaded=False)
            root.update_idletasks()
            self.assertEqual(pane._current_family_id, "command.camp")
            self.assertEqual(pane._current_entry["canonicalID"], "command.camp")
            health_text = wb._graph_text.get("1.0", "end")
            self.assertIn("Selected family: command.camp", health_text)
            self.assertIn("Tests:", health_text)
            self.assertIn("Current filter scope: needs_attention", health_text)
            self.assertIn("Selected family is outside current needs_attention filter.", health_text)

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

    def test_real_tk_primary_browser_progressive_disclosure_and_single_line_entries(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")
        root = tk.Tk()
        root.withdraw()
        try:
            preview_calls: list[str | None] = []
            service = SemanticLabAuthoringService()
            try:
                pane = ConvoEngineAuthoringPane(
                    root,
                    tk,
                    ttk,
                    scrolledtext.ScrolledText,
                    _FakeMessageBox(),
                    service,
                    auto_refresh=True,
                    on_preview_in_simulation=lambda fid, _doc: preview_calls.append(fid),
                )
                root.update_idletasks()

                # 1. Primary browser is compact (no [Owner] kind prefix) and health-colored
                all_children = pane._family_tree.get_children()
                self.assertGreaterEqual(len(all_children), 400)
                first_row = pane._family_tree.item(all_children[0])
                self.assertEqual(first_row["values"][1], all_children[0])
                self.assertNotIn("[ProjectHoomans]", str(first_row["values"][1]))
                self.assertIn("GREEN", pane._family_tree.item("command.camp")["tags"])
                for color in ("RED", "ORANGE", "YELLOW", "BLUE", "PURPLE", "GREEN"):
                    self.assertTrue(bool(pane._family_tree.tag_configure(color, "background")))

                # 2. Kind filters expose live counts and immediately surface Beats/Behaviors/Realizations
                expected_dialogues = len(all_children) - 30 - 3 - 35
                self.assertGreaterEqual(expected_dialogues, 402)
                self.assertIn(str(expected_dialogues), pane._kind_filter_vars["dialogue"].get())
                self.assertIn("30", pane._kind_filter_vars["behavior"].get())
                self.assertIn("3", pane._kind_filter_vars["beat"].get())
                self.assertIn("35", pane._kind_filter_vars["realization"].get())

                pane.select_family("command.camp")
                self.assertEqual(pane._current_family_id, "command.camp")

                pane.set_kind_filter("beat")
                beat_children = pane._family_tree.get_children()
                self.assertEqual(len(beat_children), 3)
                # Filtering out command.camp must preserve logical selection
                self.assertEqual(pane._current_family_id, "command.camp")

                pane.set_kind_filter("behavior")
                self.assertEqual(len(pane._family_tree.get_children()), 30)
                pane.set_kind_filter("realization")
                self.assertEqual(len(pane._family_tree.get_children()), 35)
                pane.set_kind_filter("all")

                # 3. Single-line Entry variables contain zero newline/carriage-return control chars
                for var in (pane._speaker_var, pane._addressee_var, pane._target_var, pane._slots_var):
                    val = var.get()
                    self.assertNotIn("\n", val)
                    self.assertNotIn("\r", val)

                # 4. Progressive disclosure: advanced panels collapsed by default, revealed on diagnostic focus
                self.assertFalse(pane._family_settings_visible)
                self.assertFalse(pane._participants_visible)
                self.assertFalse(pane._advanced_schema_visible)
                self.assertFalse(pane._advanced_s11_visible)
                pane.focus_field("roles", "role_unbound")
                self.assertTrue(pane._advanced_s11_visible)

                # 5. Surface consolidation: no Simulation / trace tab, Preview in Simulation routes out
                tab_labels = [
                    pane._right_notebook.tab(tab_id, "text")
                    for tab_id in pane._right_notebook.tabs()
                ]
                self.assertNotIn("Simulation / trace", tab_labels)
                self.assertIn("Dialogue", tab_labels)
                self.assertIn("State & Flow", tab_labels)
                pane.preview_in_simulation()
                self.assertEqual(preview_calls, ["command.camp"])
            finally:
                service.close()
        finally:
            root.destroy()

    def test_real_tk_full_usability_acceptance_journey(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")
        import copy
        from tkinter import filedialog
        from tools.semantic_harness.ui.interaction_modules.pane import InteractionModulesPane

        root = tk.Tk()
        root.withdraw()
        try:
            service = SemanticLabAuthoringService()
            try:
                sim_routed: list[str | None] = []
                im_frame = ttk.Frame(root)
                im_pane = InteractionModulesPane(
                    im_frame,
                    tk,
                    ttk,
                    scrolledtext.ScrolledText,
                    filedialog,
                    _FakeMessageBox(),
                    on_refresh=lambda: {"beats": [], "behaviors": []},
                    on_validate=lambda _d: {"ok": True},
                    on_preview=lambda _d, _u: {"ok": True},
                    on_register=lambda _d: {"ok": True},
                    on_validate_behavior=lambda _d: {"ok": True},
                    on_register_behavior=lambda _d: {"ok": True},
                    on_load_canonical=lambda _i: {},
                    on_preview_promotion=lambda _k, _d, _t: {"ok": True},
                    on_promote=lambda _k, _d, _t: {"ok": True},
                    on_open_content=lambda _c: None,
                )

                def _route_kind(kind: str, fid: str, fp: str | None, _dc: str | None) -> Any:
                    if kind == "behavior":
                        return im_pane.open_behavior(fid, fp)
                    if kind == "beat":
                        return im_pane.open_beat(fid, fp)
                    return None

                pane = ConvoEngineAuthoringPane(
                    root,
                    tk,
                    ttk,
                    scrolledtext.ScrolledText,
                    _FakeMessageBox(),
                    service,
                    auto_refresh=True,
                    on_preview_in_simulation=lambda fid, _d: sim_routed.append(fid),
                    on_open_kind_editor=_route_kind,
                )
                wb = pane.completeness_workbench
                wb.ensure_loaded()
                root.update_idletasks()

                # 1. Select command.camp -> GREEN in both primary browser and Workbench
                self.assertTrue(pane.select_family("command.camp"))
                self.assertIn("GREEN", pane._family_tree.item("command.camp")["tags"])
                self.assertEqual(wb._selected_family_id, "command.camp")

                # 2. Healthy family -> GREEN, no active structural repair
                self.assertTrue(pane.select_family("accept"))
                self.assertIn("GREEN", pane._family_tree.item("accept")["tags"])
                self.assertEqual(wb._repair_status_var.get(), "No structural repair needed")

                # 3. Known-owned family -> Run family tests executes real registered owner
                self.assertTrue(wb.select_family("offer.question.identity", notify=True))
                t_res = wb.run_family_tests()
                self.assertTrue(t_res["ok"] and t_res["ran"], t_res)
                self.assertEqual(t_res["coverageState"], "exact_owner")

                # 4. Missing Coverage filter is truthful (includes unknown/uncovered)
                wb._issue_filter_var.set("missing_coverage")
                wb._apply_filters()
                self.assertGreater(len(wb._family_tree.get_children()), 100)

                # 5. Behavior/beat routing to InteractionModulesPane + realization exact-field focus + no-op round trip
                beh_fid = next(i["canonicalID"] for i in pane._families if i["kind"] == "behavior")
                beat_fid = next(i["canonicalID"] for i in pane._families if i["kind"] == "beat")
                real_fid = next(i["canonicalID"] for i in pane._families if i["kind"] == "realization")

                self.assertTrue(pane.open_family_from_completeness(beh_fid, f"{beh_fid}.stimuli"))
                self.assertEqual(im_pane._highlighted_field, "behavior.stimuli")
                self.assertEqual(pane._form_document(), copy.deepcopy(pane._document))

                self.assertTrue(pane.open_family_from_completeness(beat_fid, f"{beat_fid}.entry"))
                self.assertEqual(im_pane._highlighted_field, "beat.entry")
                self.assertEqual(pane._form_document(), copy.deepcopy(pane._document))

                self.assertTrue(pane.open_family_from_completeness(real_fid, f"{real_fid}.translations"))
                self.assertEqual(pane._highlighted_field, "realization.translations")
                self.assertEqual(pane._form_document(), copy.deepcopy(pane._document))

                # 6. Legacy panes remain caller-zero
                core_root = Path(__file__).resolve().parents[3]
                for retired in ("dialogue_content_pane.py", "workflow.py", "interaction_spec_pane.py"):
                    self.assertFalse((core_root / "tools/semantic_harness/studio" / retired).exists())

                pane.preview_in_simulation()
                self.assertEqual(sim_routed, [real_fid])
            finally:
                service.close()
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
