"""S11A4 tests: Dialogue Completeness Analyzer over canonical S11A1-A3 Portable Plan."""

from __future__ import annotations

import unittest

from pathlib import Path

from tools.semantic_harness.codebuilder.completeness_analyzer import (
    COMPLETENESS_REPORT_SCHEMA,
    analyze_portable_plan,
    load_constrained_family_manifest,
)
from tools.semantic_harness.codebuilder.conversation_compiler import compile_conversation_sources
from tools.semantic_harness.codebuilder.portable_runtime import compile_portable_plan
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA


def _plan(records: list[dict]) -> dict:
    compiled = compile_convo_engine_document(
        {"schema": CONVO_ENGINE_SCHEMA, "owner": "PsychopatzCore", "records": records}
    )
    return compile_portable_plan(compiled["records"], package="test")


class ConvoEngineCompletenessAnalyzerTests(unittest.TestCase):
    def test_clean_state_aware_family_passes(self) -> None:
        plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "clean_family",
                    "roles": {
                        "speaker": {"cardinality": "ONE", "kinds": ["actor"]},
                        "addressee": {"cardinality": "ONE", "kinds": ["actor"]},
                    },
                    "inputPolicy": "typed_parity",
                    "repeatPolicy": "state_retired",
                    "statePolicy": [
                        {
                            "id": "already_done",
                            "when": {"path": "addressee.state", "op": "==", "value": "done"},
                            "outcome": "already_satisfied",
                            "reason": "already_done",
                            "admission": "no_op",
                            "replyOutcome": "done",
                        },
                        {
                            "id": "ready",
                            "outcome": "actionable",
                            "reason": "ready",
                            "admission": "dispatch",
                        },
                    ],
                    "postconditions": ["addressee.done"],
                    "closure": {"closureClass": "resolved_episode", "episodeId": "ep_clean"},
                    "say": "Do it.",
                    "reply": {
                        "done": {"say": "Already done."},
                        "accepted": {"say": "Okay."},
                    },
                }
            ]
        )
        report = analyze_portable_plan(plan, covered_family_ids={"test.clean_family"})
        self.assertEqual(report["schema"], COMPLETENESS_REPORT_SCHEMA)
        self.assertTrue(report["ok"], report)
        self.assertEqual(report["summary"]["errors"], 0)

    def test_detects_unreachable_rule_pending_without_exit_and_closure_gaps(self) -> None:
        plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "broken_flow",
                    "statePolicy": [
                        {
                            "id": "always_pending",
                            "outcome": "pending",
                            "reason": "waiting",
                            "admission": "defer",
                            "replyOutcome": "missing_reply",
                        },
                        {
                            "id": "shadowed_rule",
                            "when": {"path": "addressee.state", "op": "==", "value": "x"},
                            "outcome": "actionable",
                            "reason": "ready",
                            "admission": "dispatch",
                        },
                    ],
                    "closure": {"closureClass": "open_domain_obligation"},
                    "say": "Status?",
                    "reply": {"ok": {"say": "Waiting."}},
                }
            ]
        )
        report = analyze_portable_plan(plan)
        self.assertFalse(report["ok"])
        codes = {d["code"] for d in report["diagnostics"]}
        self.assertIn("unreachable_branch", codes)
        self.assertIn("unhandled_state_outcome", codes)
        self.assertIn("pending_without_exit", codes)
        self.assertIn("lost_commitment", codes)

    def test_detects_unbounded_cycle_and_group_effect_hazards(self) -> None:
        plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "cycle_a",
                    "roles": {
                        "speaker": {"cardinality": "ONE", "kinds": ["actor"]},
                        "target": {"cardinality": "ONE_OR_MORE", "kinds": ["actor"]},
                    },
                    "effects": [{"type": "warn_group", "targetRole": "target", "params": {}}],
                    "say": "Listen.",
                    "after": {"goto": "test.cycle_b"},
                },
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "cycle_b",
                    "say": "Repeat.",
                    "after": {"goto": "test.cycle_a"},
                },
            ]
        )
        report = analyze_portable_plan(plan)
        self.assertFalse(report["ok"])
        codes = {d["code"] for d in report["diagnostics"]}
        self.assertIn("unbounded_loop", codes)
        self.assertIn("missing_repeat_policy", codes)
        self.assertIn("unbounded_group_reaction", codes)
        self.assertIn("ambiguous_group_effect", codes)

    def test_detects_unhandled_action_outcome_and_dead_end(self) -> None:
        plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "missing_action_branch",
                    "say": "Camp here.",
                    "reply": {"queued": {"say": "On it."}},
                    "after": {"goto": "test.nonexistent"},
                }
            ]
        )
        plan["dialogues"]["test.missing_action_branch"]["execute"] = {"use": "test.camp"}
        report = analyze_portable_plan(
            plan,
            action_contracts={
                "test.camp": {
                    "outcomeMap": {"ok": "queued", "fail": "rejected"},
                    "defaultOutcome": "failed",
                }
            },
        )
        self.assertFalse(report["ok"])
        codes = {d["code"] for d in report["diagnostics"]}
        self.assertIn("dead_end", codes)
        self.assertIn("unhandled_action_outcome", codes)

    def test_constrained_manifest_fails_when_required_stateful_family_is_missing_or_unmigrated(self) -> None:
        # 1. Missing required CANONICAL_STATEFUL family fails automatically
        other_plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "unrelated_family",
                    "say": "Hi.",
                }
            ]
        )
        manifest = {
            "schema": "psychopatz.convo-engine.constrained-family-manifest.v1",
            "entries": [
                {
                    "auditId": "audit.required.demo",
                    "canonicalFamilyId": "test.required_missing",
                    "classification": "CANONICAL_STATEFUL",
                    "migrationPhase": "accepted",
                    "requiredPolicy": ["statePolicy", "inputPolicy", "repeatPolicy", "closure"],
                    "acceptanceOwner": "tests/demo.json",
                }
            ],
        }
        report_missing = analyze_portable_plan(other_plan, constrained_manifest=manifest)
        self.assertFalse(report_missing["ok"])
        self.assertIn("missing_canonical_stateful_family", {d["code"] for d in report_missing["diagnostics"]})

        # 2. Present family without canonical S11 policy fields fails automatically
        unmigrated_plan = _plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "required_unmigrated",
                    "say": "Hello.",
                }
            ]
        )
        manifest_unmigrated = {
            "schema": "psychopatz.convo-engine.constrained-family-manifest.v1",
            "entries": [
                {
                    "auditId": "audit.required.unmigrated",
                    "canonicalFamilyId": "test.required_unmigrated",
                    "classification": "CANONICAL_STATEFUL",
                    "migrationPhase": "accepted",
                    "requiredPolicy": ["statePolicy", "inputPolicy", "repeatPolicy", "closure"],
                    "acceptanceOwner": "tests/demo.json",
                }
            ],
        }
        report_unmigrated = analyze_portable_plan(unmigrated_plan, constrained_manifest=manifest_unmigrated)
        self.assertFalse(report_unmigrated["ok"])
        self.assertIn("missing_required_state_policy", {d["code"] for d in report_unmigrated["diagnostics"]})

        # 3. Real 3-repo manifest passes under both normal and strict_manifest=True
        core_root = Path(__file__).resolve().parents[3]
        model = compile_conversation_sources(
            core_root,
            package_repositories={
                "PsychopatzCore": core_root,
                "ProjectHoomans": core_root.parent / "ProjectHoomans",
                "DTCommon": core_root.parent / "DynamicTrading",
            },
        )
        real_manifest = load_constrained_family_manifest()
        r0_report = analyze_portable_plan(model["portablePlan"], constrained_manifest=real_manifest, strict_manifest=False)
        self.assertTrue(r0_report["ok"], r0_report)
        strict_report = analyze_portable_plan(model["portablePlan"], constrained_manifest=real_manifest, strict_manifest=True)
        self.assertTrue(strict_report["ok"], strict_report)

    def test_closed_set_audit_inventory_and_verifiable_acceptance_negative_guards(self) -> None:
        from copy import deepcopy
        from tools.semantic_harness.codebuilder.completeness_analyzer import (
            load_branching_audit_inventory,
        )

        core_root = Path(__file__).resolve().parents[3]
        model = compile_conversation_sources(
            core_root,
            package_repositories={
                "PsychopatzCore": core_root,
                "ProjectHoomans": core_root.parent / "ProjectHoomans",
                "DTCommon": core_root.parent / "DynamicTrading",
            },
        )
        plan = model["portablePlan"]
        base_manifest = load_constrained_family_manifest()
        base_inventory = load_branching_audit_inventory()

        # 1. Omitted audit row fails closed-set check
        omitted_manifest = deepcopy(base_manifest)
        omitted_manifest["entries"] = [
            e for e in omitted_manifest["entries"] if e["auditId"] != "audit.event.response_window_expiry"
        ]
        rep_omitted = analyze_portable_plan(
            plan,
            constrained_manifest=omitted_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_omitted["ok"])
        self.assertIn("missing_audit_row_in_manifest", {d["code"] for d in rep_omitted["diagnostics"]})

        # 2. Extra manifest row with no audit ownership fails closed-set check
        extra_manifest = deepcopy(base_manifest)
        extra_manifest["entries"].append(
            {
                "auditId": "audit.invented.extra_row",
                "canonicalFamilyId": None,
                "classification": "REFERENCE_GOOD_REGRESSION",
                "reason": "Invented row.",
                "acceptance": {
                    "ownerKind": "python_test",
                    "source": "PsychopatzCore/tools/semantic_harness/tests/test_convo_engine_completeness_analyzer.py",
                    "testIds": ["test_detects_unbounded_cycle_and_group_effect_hazards"],
                    "requiredClaims": ["none"],
                },
            }
        )
        rep_extra = analyze_portable_plan(
            plan,
            constrained_manifest=extra_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_extra["ok"])
        self.assertIn("extra_manifest_row_without_audit", {d["code"] for d in rep_extra["diagnostics"]})

        # 3. Nonexistent acceptance source fails
        bad_source_manifest = deepcopy(base_manifest)
        bad_source_manifest["entries"][-1]["acceptance"]["source"] = "ProjectHoomans/tests/does_not_exist.py"
        rep_bad_source = analyze_portable_plan(
            plan,
            constrained_manifest=bad_source_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_bad_source["ok"])
        self.assertIn("missing_acceptance_source", {d["code"] for d in rep_bad_source["diagnostics"]})

        # 4. Nonexistent testId / caseId fails
        bad_tid_manifest = deepcopy(base_manifest)
        bad_tid_manifest["entries"][-1]["acceptance"]["testIds"] = ["test_nonexistent_method_id"]
        rep_bad_tid = analyze_portable_plan(
            plan,
            constrained_manifest=bad_tid_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_bad_tid["ok"])
        self.assertIn("missing_acceptance_test_id", {d["code"] for d in rep_bad_tid["diagnostics"]})

        # 5. Owner exists and testId exists with keyword in prose, but declares no auditClaims -> fails
        mismatch_manifest = deepcopy(base_manifest)
        for entry in mismatch_manifest["entries"]:
            if entry["auditId"] == "audit.root.disband":
                entry["acceptance"] = {
                    "ownerKind": "python_test",
                    "source": "ProjectHoomans/tools/providers/pnc/tests/test_automatic_flow_generation.py",
                    "testIds": ["test_live_coverage_generates_follow_and_stay_from_one_template"],
                    "requiredClaims": ["confirmation_modal_required", "no_unconfirmed_destructive_dispatch"],
                }
        rep_no_claims = analyze_portable_plan(
            plan,
            constrained_manifest=mismatch_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_no_claims["ok"])
        self.assertIn("missing_owner_audit_claims", {d["code"] for d in rep_no_claims["diagnostics"]})

        # 6. Owner declares wrong claim while manifest repeats requiredClaims -> fails with acceptance_claim_mismatch
        wrong_claim_manifest = deepcopy(base_manifest)
        for entry in wrong_claim_manifest["entries"]:
            if entry["auditId"] == "audit.root.disband":
                entry["acceptance"] = {
                    "ownerKind": "python_test",
                    "source": "ProjectHoomans/tools/providers/pnc/tests/test_automatic_flow_generation.py",
                    "testIds": ["test_all_dispatchable_registered_capabilities_use_existing_handlers"],
                    "requiredClaims": ["confirmation_modal_required", "no_unconfirmed_destructive_dispatch"],
                }
        rep_wrong_claim = analyze_portable_plan(
            plan,
            constrained_manifest=wrong_claim_manifest,
            strict_manifest=True,
            audit_inventory=base_inventory,
        )
        self.assertFalse(rep_wrong_claim["ok"])
        self.assertIn("acceptance_claim_mismatch", {d["code"] for d in rep_wrong_claim["diagnostics"]})

        # 7. Lua file contains keyword & claim on OTHER testId, but selected testId lacks claim -> fails
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_root = Path(tmpdir)
            lua_file = tmp_root / "lua_smoke.lua"
            lua_file.write_text(
                '-- @auditClaims other_test: ["settlement_admission_post_success_refresh", "ambient_visit_post_success_refresh"]\n'
                '-- settlement keyword appears here\n'
                'local function selected_test() return true end\n',
                encoding="utf-8",
            )
            lua_manifest = deepcopy(base_manifest)
            for entry in lua_manifest["entries"]:
                if entry["auditId"] == "audit.root.settlement_admission":
                    entry["acceptance"] = {
                        "ownerKind": "lua_test",
                        "source": "TmpRepo/lua_smoke.lua",
                        "testIds": ["selected_test"],
                        "requiredClaims": [
                            "settlement_admission_post_success_refresh",
                            "ambient_visit_post_success_refresh",
                        ],
                    }
            rep_lua_scope = analyze_portable_plan(
                plan,
                constrained_manifest=lua_manifest,
                strict_manifest=True,
                audit_inventory=base_inventory,
                workspace_roots={
                    "PsychopatzCore": core_root,
                    "ProjectHoomans": core_root.parent / "ProjectHoomans",
                    "DTCommon": core_root.parent / "DynamicTrading",
                    "TmpRepo": tmp_root,
                },
            )
            self.assertFalse(rep_lua_scope["ok"])
            self.assertIn("missing_owner_audit_claims", {d["code"] for d in rep_lua_scope["diagnostics"]})

    def test_all_kind_authoring_health_and_catalog_mismatch_detection(self) -> None:
        plan = {
            "schema": "psychopatz.psdl.portable-plan.v1",
            "dialogues": {
                "dlg.ok": {"id": "dlg.ok", "kind": "dialogue", "after": {"end": True}},
            },
            "behaviors": {
                "behavior.ok": {
                    "id": "behavior.ok",
                    "kind": "behavior",
                    "stimuli": ["HUMAN_UTTERANCE"],
                    "outputs": {"speech": {"dialogueAct": "GREET"}},
                },
                "behavior.bad": {
                    "id": "behavior.bad",
                    "kind": "behavior",
                    "stimuli": [],
                    "outputs": {},
                },
            },
            "beats": {
                "beat.bad": {
                    "id": "beat.bad",
                    "kind": "beat",
                    "candidates": [{"behavior": "behavior.missing"}],
                },
            },
            "realizations": {
                "real.bad": {
                    "id": "real.bad",
                    "kind": "realization",
                    "translations": {},
                },
            },
        }
        report = analyze_portable_plan(
            plan,
            catalog_family_ids={"dlg.ok", "behavior.ok", "behavior.bad", "beat.bad", "real.bad", "catalog.only"},
        )
        self.assertFalse(report["ok"])
        self.assertTrue(report["summary"]["catalogMismatch"])
        self.assertEqual(report["summary"]["families"], 5)
        self.assertEqual(report["summary"]["byKind"]["dialogue"]["total"], 1)
        self.assertEqual(report["summary"]["byKind"]["behavior"]["total"], 2)
        self.assertEqual(report["summary"]["byKind"]["beat"]["total"], 1)
        self.assertEqual(report["summary"]["byKind"]["realization"]["total"], 1)
        codes = {d["code"] for d in report["diagnostics"]}
        self.assertIn("missing_behavior_stimuli", codes)
        self.assertIn("missing_behavior_outputs", codes)
        self.assertIn("missing_beat_entry", codes)
        self.assertIn("unresolved_beat_candidate", codes)
        self.assertIn("missing_en_realization", codes)
        self.assertIn("catalog_report_mismatch", codes)
        self.assertEqual(report["families"]["behavior.ok"]["semanticStatus"], "GREEN")
        self.assertEqual(report["families"]["behavior.bad"]["semanticStatus"], "RED")
        self.assertEqual(report["families"]["beat.bad"]["semanticStatus"], "RED")
        self.assertEqual(report["families"]["real.bad"]["semanticStatus"], "RED")


if __name__ == "__main__":
    unittest.main()
