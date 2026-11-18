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


if __name__ == "__main__":
    unittest.main()
