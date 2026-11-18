"""R9D: Fake-widget & unit acceptance tests for DialogueCompletenessWorkbench."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools.semantic_harness.codebuilder.completeness_analyzer import (
    analyze_portable_plan,
)
from tools.semantic_harness.codebuilder.portable_runtime import compile_portable_plan
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.completeness_workbench import (
    DialogueCompletenessWorkbench,
    filter_completeness_families,
)
from tools.semantic_harness.studio.convo_engine_authoring_pane import (
    ConvoEngineAuthoringPane,
)
from tools.semantic_harness.tests.convo_engine_test_support import (
    _FakeMessageBox,
    _FakeTk,
    _FakeTtk,
    _FakeWidget,
    _setup_three_repo_workspace,
)


def _synthetic_plan() -> dict:
    records = [
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "valid_terminal",
            "inputPolicy": "typed_parity",
            "repeatPolicy": "state_retired",
            "closure": {"closureClass": "resolved_episode", "episodeId": "ep_term"},
            "say": "Done.",
            "reply": {"ok": {"say": "Okay."}},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "valid_continuation",
            "inputPolicy": "typed_parity",
            "repeatPolicy": "once",
            "say": "Next?",
            "after": {"goto": "test.valid_terminal"},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "valid_pending",
            "inputPolicy": "typed_parity",
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
            "namespace": "test",
            "id": "valid_obligation",
            "inputPolicy": "typed_parity",
            "closure": {"closureClass": "open_domain_obligation", "obligationRef": "task.escort"},
            "say": "Follow me.",
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "warn_stale",
            "inputPolicy": "typed_parity",
            "execute": {"use": "act.mutate"},
            "say": "Mutate.",
            "reply": {"ok": {"say": "Mutated."}},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_dead_end",
            "say": "Go nowhere.",
            "after": {"goto": "test.missing_target"},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_state_outcome",
            "statePolicy": [
                {
                    "id": "r1",
                    "outcome": "already_satisfied",
                    "reason": "done",
                    "admission": "no_op",
                    "replyOutcome": "missing_reply",
                }
            ],
            "say": "State?",
            "reply": {"ok": {"say": "Ok."}},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_action_outcome",
            "execute": {"use": "act.contract"},
            "postconditions": ["done"],
            "say": "Act.",
            "reply": {"ok": {"say": "Ok."}},
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_pending",
            "statePolicy": [
                {
                    "id": "stuck",
                    "outcome": "pending",
                    "reason": "waiting",
                    "admission": "defer",
                }
            ],
            "say": "Stuck.",
        },
        {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_cycle",
            "say": "Loop.",
            "after": {"goto": "test.bad_cycle"},
        },
    ]
    compiled = compile_convo_engine_document(
        {"schema": CONVO_ENGINE_SCHEMA, "owner": "PsychopatzCore", "records": records}
    )
    return compile_portable_plan(compiled["records"], package="test")


class DialogueCompletenessWorkbenchTests(unittest.TestCase):
    def test_synthetic_semantic_classes_and_filters(self) -> None:
        plan = _synthetic_plan()
        contracts = {
            "act.contract": {
                "id": "act.contract",
                "outcomeMap": {"ok": "ok", "failed": "failed"},
                "defaultOutcome": "ok",
            }
        }
        report = analyze_portable_plan(
            plan,
            action_contracts=contracts,
            covered_family_ids={"test.valid_terminal"},
        )
        families = report["families"]
        self.assertEqual(families["test.valid_terminal"]["semanticStatus"], "GREEN")
        self.assertEqual(families["test.valid_terminal"]["closureHealth"], "resolved_terminal")
        self.assertEqual(families["test.valid_continuation"]["semanticStatus"], "BLUE")
        self.assertEqual(families["test.valid_continuation"]["closureHealth"], "continuation")
        self.assertEqual(families["test.valid_pending"]["semanticStatus"], "YELLOW")
        self.assertEqual(families["test.valid_pending"]["closureHealth"], "bounded_pending")
        self.assertEqual(families["test.valid_obligation"]["semanticStatus"], "PURPLE")
        self.assertEqual(families["test.valid_obligation"]["closureHealth"], "domain_obligation")
        self.assertEqual(families["test.warn_stale"]["semanticStatus"], "ORANGE")
        self.assertEqual(families["test.warn_stale"]["closureHealth"], "warning")
        for bad_id in (
            "test.bad_dead_end",
            "test.bad_state_outcome",
            "test.bad_action_outcome",
            "test.bad_pending",
            "test.bad_cycle",
        ):
            self.assertEqual(families[bad_id]["semanticStatus"], "RED", bad_id)
            self.assertEqual(families[bad_id]["closureHealth"], "invalid", bad_id)

        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="errors_only")},
            {
                "test.bad_dead_end",
                "test.bad_state_outcome",
                "test.bad_action_outcome",
                "test.bad_pending",
                "test.bad_cycle",
            },
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="warnings_only")},
            {"test.warn_stale"},
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="unhandled_action_outcome")},
            {"test.bad_action_outcome"},
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="unhandled_state_outcome")},
            {"test.bad_state_outcome"},
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="pending_without_exit")},
            {"test.bad_pending"},
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="unbounded_cycle")},
            {"test.bad_cycle"},
        )
        self.assertEqual(
            {r["familyId"] for r in filter_completeness_families(report, issue_filter="missing_repeat_policy")},
            {"test.bad_cycle"},
        )

    def test_workbench_uses_canonical_service_navigation_affected_refresh_and_scaffolding(self) -> None:
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
                _FakeWidget(),
                _FakeTk,
                _FakeTtk,
                _FakeWidget,
                _FakeMessageBox(),
                service,
                auto_refresh=True,
            )
            wb: DialogueCompletenessWorkbench = pane.completeness_workbench

            with mock.patch.object(
                service,
                "analyze_convo_completeness",
                wraps=service.analyze_convo_completeness,
            ) as spy:
                report = wb.run_strict_analysis()
                spy.assert_called_once_with(strict_manifest=True)

            self.assertEqual(
                wb._report["summary"],
                report["summary"],
            )
            first_fid = next(iter(report["families"]))
            self.assertTrue(wb.select_family(first_fid))
            graph_dump = wb._graph_text.get("1.0", "end")
            self.assertIn(first_fid, graph_dump)
            self.assertIn("Ends cleanly", graph_dump)
            tech_dump = wb._tech_text.get("1.0", "end")
            self.assertIn(f"FAMILY: {first_fid}", tech_dump)

            # Navigation resolves to canonical source, never generated Lua
            wb.open_canonical_source()
            self.assertIsNotNone(pane._current_entry)
            self.assertEqual(pane._current_entry["canonicalID"], first_fid)
            self.assertTrue(str(pane._current_entry["sourcePath"]).endswith(".json"))

            # Affected-family refresh updates affected rows without dropping unrelated families
            before_count = len(wb._report["families"])
            partial = wb.run_affected_analysis([first_fid])
            self.assertIn(first_fid, partial["affectedFamilyIds"])
            self.assertEqual(len(wb._report["families"]), before_count)

            # Scaffold preview is effect-free
            src_path = Path(pane._current_entry["sourcePath"])
            before_bytes = src_path.read_bytes()
            wb._scaffold_kind_var.set("repeat_policy")
            preview = wb.preview_scaffold()
            self.assertTrue(preview["ok"])
            self.assertTrue(preview["effectFree"])
            self.assertTrue(preview["previewOnly"])
            self.assertEqual(src_path.read_bytes(), before_bytes)

            # Explicit scaffold apply updates only intended canonical source + normal CodeBuilder flow
            applied = wb.apply_scaffold()
            self.assertTrue(applied["ok"])
            self.assertFalse(applied["effectFree"])
            updated_doc = json.loads(src_path.read_text(encoding="utf-8"))
            self.assertEqual(updated_doc.get("repeatPolicy"), "state_retired")

    def test_real_package_workbench_matches_direct_strict_analyzer(self) -> None:
        service = SemanticLabAuthoringService()
        direct = service.analyze_convo_completeness(strict_manifest=True)
        wb = DialogueCompletenessWorkbench(
            _FakeWidget(),
            _FakeTk,
            _FakeTtk,
            _FakeWidget,
            _FakeMessageBox(),
            service,
            auto_analyze=False,
        )
        gui_report = wb.run_strict_analysis()
        self.assertEqual(gui_report["summary"], direct["summary"])
        self.assertEqual(gui_report["diagnostics"], direct["diagnostics"])
        self.assertEqual(direct["summary"]["families"], 588)
        self.assertEqual(direct["summary"]["analyzedFamilies"], 588)
        self.assertFalse(direct["summary"]["catalogMismatch"])
        by_kind = direct["summary"]["byKind"]
        self.assertEqual(by_kind["dialogue"]["total"], 520)
        self.assertEqual(by_kind["behavior"]["total"], 30)
        self.assertEqual(by_kind["beat"]["total"], 3)
        self.assertEqual(by_kind["realization"]["total"], 35)

    def test_selection_synchronization_prevents_action_trade_vs_accept_mismatch(self) -> None:
        service = SemanticLabAuthoringService()
        pane = ConvoEngineAuthoringPane(
            _FakeWidget(),
            _FakeTk,
            _FakeTtk,
            _FakeWidget,
            _FakeMessageBox(),
            service,
            auto_refresh=True,
        )
        # 1. Select action.trade in main editor -> Workbench must synchronize to action.trade
        self.assertTrue(pane.select_family("action.trade"))
        self.assertEqual(pane._current_family_id, "action.trade")
        pane.completeness_workbench.ensure_loaded()
        self.assertEqual(pane.completeness_workbench._selected_family_id, "action.trade")

        # 2. Select accept in Workbench -> main editor must synchronize to accept
        self.assertTrue(pane.completeness_workbench.select_family("accept", notify=True))
        self.assertEqual(pane._current_family_id, "accept")
        self.assertEqual(pane._current_entry["canonicalID"], "accept")

        # 3. Filtering Workbench to something else must not silently overwrite main editor selection
        pane.completeness_workbench._search_var.set("command.camp")
        pane.completeness_workbench._apply_filters()
        self.assertEqual(pane.completeness_workbench._selected_family_id, "accept")
        self.assertEqual(pane._current_family_id, "accept")

        # 4. Filtering main editor to something else must not silently overwrite Workbench selection
        pane._filter_var.set("command.camp")
        pane._apply_filter()
        self.assertEqual(pane._current_family_id, "accept")
        self.assertEqual(pane.completeness_workbench._selected_family_id, "accept")

    def test_problem_first_default_severity_ordering_and_real_command_camp_visibility(self) -> None:
        service = SemanticLabAuthoringService()
        wb = DialogueCompletenessWorkbench(
            _FakeWidget(),
            _FakeTk,
            _FakeTtk,
            _FakeWidget,
            _FakeMessageBox(),
            service,
            auto_analyze=False,
        )
        self.assertEqual(wb._issue_filter_var.get(), "needs_attention")
        wb.run_strict_analysis()
        children = wb._family_tree.get_children()
        self.assertIn("command.camp", children)
        self.assertEqual(children[0], "command.camp")
        item = wb._family_tree.item("command.camp")
        self.assertIn("ORANGE", item["tags"])
        self.assertIn("Warning / Risky", item["values"][0])

        # Verify all 6 semantic tags are configured and severity-first sorting is deterministic
        for color in ("RED", "ORANGE", "YELLOW", "BLUE", "PURPLE", "GREEN"):
            self.assertIn(color, wb._family_tree._tags)

        synth_report = analyze_portable_plan(_synthetic_plan(), action_contracts={"act.contract": {"id": "act.contract", "outcomeMap": {"ok": "ok", "failed": "failed"}}})
        all_rows = filter_completeness_families(synth_report, issue_filter="all")
        statuses = [r["semanticStatus"] for r in all_rows]
        self.assertEqual(
            statuses,
            sorted(statuses, key=lambda s: ("RED", "ORANGE", "YELLOW", "BLUE", "PURPLE", "GREEN").index(s)),
        )

    def test_exact_field_navigation_family_tests_contextual_repair_and_auto_reanalysis(self) -> None:
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
                _FakeWidget(),
                _FakeTk,
                _FakeTtk,
                _FakeWidget,
                _FakeMessageBox(),
                service,
                auto_refresh=True,
            )
            wb = pane.completeness_workbench
            self.assertIsNotNone(wb._on_run_family_tests)

            # Healthy family disables repair controls and says No structural repair needed
            wb.ensure_loaded()
            first_fid = next(iter(wb._report["families"]))
            wb.select_family(first_fid)
            self.assertEqual(wb._repair_status_var.get(), "No structural repair needed")
            self.assertEqual(wb._preview_btn._config.get("state"), "disabled")
            self.assertEqual(wb._apply_btn._config.get("state"), "disabled")

            # Run family tests returns explicit message when no owner is registered
            t_res = wb.run_family_tests()
            self.assertIsNotNone(t_res)
            self.assertFalse(t_res["ran"])
            self.assertEqual(t_res["message"], "No exact family-level runnable test is registered")

            # Exact-field navigation resolves diagnostic paths to exact controls
            for path, expected_field in (
                ("f.reply.failed", "reply"),
                ("f.statePolicy[0].replyOutcome", "statePolicy"),
                ("f.postconditions", "postconditions"),
                ("f.repeatPolicy", "repeatPolicy"),
                ("f.closure.episodeId", "closure"),
                ("f.after", "after"),
                ("f.roles.speaker", "roles"),
                ("f.participantSet", "participantSet"),
            ):
                self.assertEqual(pane.focus_field(path), expected_field)
                self.assertEqual(pane._highlighted_field, expected_field)

            # Contextual repair card populates on diagnostic and auto-reanalysis runs on save
            pane.open_family_from_completeness(first_fid, f"{first_fid}.repeatPolicy")
            self.assertEqual(pane._highlighted_field, "repeatPolicy")
            pane._s11_scalar_vars["repeatPolicy"].set("state_retired")
            wb._issue_filter_var.set("all")
            with mock.patch.object(
                wb,
                "run_affected_analysis",
                wraps=wb.run_affected_analysis,
            ) as spy_affected:
                written = pane.write_source()
                self.assertTrue(written["ok"])
                spy_affected.assert_called_once_with([first_fid])
            self.assertEqual(pane._current_family_id, first_fid)
            self.assertEqual(wb._selected_family_id, first_fid)
            self.assertEqual(wb._issue_filter_var.get(), "all")

    def test_truthful_coverage_states_and_exact_family_test_execution(self) -> None:
        from tools.semantic_harness.codebuilder.completeness_analyzer import (
            analyze_portable_plan,
            load_constrained_family_manifest,
        )

        # 1. Coverage states distinguish exact_owner, suite_covered, uncovered, unknown
        synth_plan = {
            "schema": "psychopatz.psdl.portable-plan.v1",
            "dialogues": {
                "a.owned": {"kind": "dialogue", "id": "owned", "say": "Hi."},
                "a.suite": {"kind": "dialogue", "id": "suite", "say": "Hi."},
                "a.uncovered": {"kind": "dialogue", "id": "uncovered", "say": "Hi."},
            }
        }
        manifest = {"entries": [{"canonicalFamilyId": "a.owned"}]}
        report_with_cov = analyze_portable_plan(
            synth_plan,
            covered_family_ids={"a.suite"},
            constrained_manifest=manifest,
        )
        self.assertEqual(report_with_cov["families"]["a.owned"]["fixtureCoverage"], "exact_owner")
        self.assertEqual(report_with_cov["families"]["a.suite"]["fixtureCoverage"], "suite_covered")
        self.assertEqual(report_with_cov["families"]["a.uncovered"]["fixtureCoverage"], "uncovered")
        self.assertEqual(report_with_cov["summary"]["byKind"]["dialogue"]["missingCoverage"], 1)

        report_no_cov = analyze_portable_plan(synth_plan, constrained_manifest=manifest)
        self.assertEqual(report_no_cov["families"]["a.owned"]["fixtureCoverage"], "exact_owner")
        self.assertEqual(report_no_cov["families"]["a.suite"]["fixtureCoverage"], "unknown")
        self.assertEqual(report_no_cov["summary"]["byKind"]["dialogue"]["missingCoverage"], 2)

        # Missing Coverage filter surfaces both uncovered and unknown
        missing_rows = filter_completeness_families(report_no_cov, issue_filter="missing_coverage")
        self.assertEqual({r["familyId"] for r in missing_rows}, {"a.suite", "a.uncovered"})

        # 2. Live service + real manifest-owned families execute their registered owners
        service = SemanticLabAuthoringService()
        try:
            live_report = service.analyze_convo_completeness(strict_manifest=False)
            real_manifest = load_constrained_family_manifest()
            manifest_ids = {
                str(e["canonicalFamilyId"])
                for e in (real_manifest.get("entries") or ())
                if isinstance(e, dict) and e.get("canonicalFamilyId")
            }
            for fid in ("offer.question.identity", "flow.needs.exchange", "departure.confirmed", "command.companion.camp"):
                self.assertIn(fid, manifest_ids)
                self.assertEqual(live_report["families"][fid]["fixtureCoverage"], "exact_owner")

            # Execute declarative_fixture, python_test, and lua_test owners
            decl_res = service.run_family_tests("offer.question.identity")
            self.assertTrue(decl_res["ok"], decl_res)
            self.assertTrue(decl_res["ran"], decl_res)
            self.assertEqual(decl_res["coverageState"], "exact_owner")
            self.assertEqual(decl_res["ownerKind"], "declarative_fixture")
            self.assertGreaterEqual(decl_res["passed"], 3)

            py_res = service.run_family_tests("departure.confirmed")
            self.assertTrue(py_res["ok"], py_res)
            self.assertTrue(py_res["ran"], py_res)
            self.assertEqual(py_res["ownerKind"], "python_test")
            self.assertEqual(py_res["passed"], 2)

            lua_res = service.run_family_tests("command.companion.camp")
            self.assertTrue(lua_res["ok"], lua_res)
            self.assertTrue(lua_res["ran"], lua_res)
            self.assertEqual(lua_res["ownerKind"], "lua_test")
            self.assertEqual(lua_res["passed"], 1)
        finally:
            service.close()


if __name__ == "__main__":
    unittest.main()
