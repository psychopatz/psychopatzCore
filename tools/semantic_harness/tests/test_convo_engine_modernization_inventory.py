"""Tests for machine-readable ConvoEngine dataset modernization inventory and closure authority."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_engine_modernization_inventory import (
    CLOSURE_STATES,
    FORBIDDEN_RETENTION_REASONS,
    HOOK_STATES,
    MODERNIZATION_CLASSES,
    MODERNIZATION_INVENTORY_SCHEMA,
    _verify_retention_claim,
    build_modernization_inventory,
)

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"

_REQUIRED_RECORD_KEYS = {
    "canonicalID",
    "owner",
    "kind",
    "source",
    "classification",
    "classificationConfidence",
    "classificationReason",
    "semanticAct",
    "semanticIntent",
    "semanticSubject",
    "currentRoles",
    "candidateDynamicRoles",
    "currentSlots",
    "candidateSlots",
    "topicRefHooks",
    "eventRefHooks",
    "activityRefHooks",
    "memoryRefHooks",
    "domainRefHooks",
    "hookReadinessState",
    "stateful",
    "mutating",
    "executeContract",
    "repeatPolicy",
    "closurePolicy",
    "realizationCount",
    "testCoverageState",
    "possibleDuplicateSpecializationGroup",
    "recommendedModernizationAction",
    "closureState",
    "retentionEvidence",
}

_REQUIRED_SUMMARY_KEYS = {
    "catalogFamilyCount",
    "inventoryFamilyCount",
    "unknownOwnershipCount",
    "unclassifiedCount",
    "duplicateGroupCount",
    "splitAuthorityCount",
    "legacySplitAuthorityCount",
    "openActionableFamilyCount",
    "openActionableGroupCount",
    "intentionallyRetainedCount",
    "resolvedCount",
    "missingCompositionHookCount",
    "legacySchemaReaderCount",
}


class ConvoEngineModernizationInventoryTests(unittest.TestCase):
    def test_modernization_inventory_gate_all_maintained_families_classified(self) -> None:
        inv = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        self.assertTrue(inv["ok"], inv["summary"])
        self.assertEqual(inv["schema"], MODERNIZATION_INVENTORY_SCHEMA)
        summary = inv["summary"]
        self.assertTrue(_REQUIRED_SUMMARY_KEYS.issubset(summary.keys()))
        self.assertGreater(summary["catalogFamilyCount"], 0)
        self.assertEqual(summary["catalogFamilyCount"], summary["inventoryFamilyCount"])
        self.assertEqual(summary["unknownOwnershipCount"], 0)
        self.assertEqual(summary["unclassifiedCount"], 0)
        self.assertEqual(summary["splitAuthorityCount"], 0)

        for rec in inv["families"]:
            self.assertTrue(_REQUIRED_RECORD_KEYS.issubset(rec.keys()), rec.get("canonicalID"))
            self.assertTrue(rec["classification"], rec.get("canonicalID"))
            self.assertIn(rec["closureState"], CLOSURE_STATES)
            self.assertIn(rec["hookReadinessState"], HOOK_STATES)
            self.assertTrue(rec["classificationReason"], rec.get("canonicalID"))
            for cls in rec["classification"]:
                self.assertIn(cls, MODERNIZATION_CLASSES)

    def test_closure_mode_passes_when_all_findings_resolved_or_justified(self) -> None:
        inv = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            closure=True,
        )
        summary = inv["summary"]
        self.assertTrue(inv["closureOk"], summary)
        self.assertTrue(inv["ok"], summary)
        self.assertEqual(summary["openActionableFamilyCount"], 0)
        self.assertEqual(summary["openActionableGroupCount"], 0)
        self.assertEqual(summary["missingCompositionHookCount"], 0)
        self.assertEqual(summary["legacySchemaReaderCount"], 0)
        self.assertEqual(summary["activeCurrentPsdlIdentityCount"], 0)
        self.assertGreaterEqual(summary["historicalNegativeDetectionCount"], 1)

    def test_intentional_retention_requires_machine_checkable_evidence_and_does_not_hide_open_findings(self) -> None:
        baseline = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        # Pick a group with distinct predicates/selection semantics if present
        target_group = next(
            (g for g in baseline["groups"] if g["groupId"] == "slot_specialization:DTCommon:trade.conversation"),
            baseline["groups"][0],
        )
        gid = target_group["groupId"]

        # 1. Forbidden prose waiver must be rejected and keep group OPEN
        for bad_reason in sorted(FORBIDDEN_RETENTION_REASONS):
            inv_bad = build_modernization_inventory(
                CORE_ROOT,
                hoomans_repository=HOOMANS_ROOT,
                dynamic_trading_repository=DT_ROOT,
                retention_claims={
                    gid: {
                        "evidenceCode": "DISTINCT_SEMANTIC_ACT_OR_INTENT",
                        "reason": bad_reason,
                    }
                },
            )
            grp_bad = next(g for g in inv_bad["groups"] if g["groupId"] == gid)
            self.assertEqual(grp_bad["closureState"], "OPEN")
            self.assertFalse(grp_bad["retentionEvidence"]["valid"])

        # 2. Valid machine-checkable distinction on one group marks it INTENTIONALLY_RETAINED
        #    while leaving unrelated open groups OPEN and closureOk False.
        inv_retained = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            closure=True,
            retention_claims={
                gid: {
                    "evidenceCode": "SELECTION_SEMANTICS_LOSS",
                    "reason": "Distinct reply outcome / invoke / continuation contract verified in IR.",
                }
            },
        )
        grp_ret = next(g for g in inv_retained["groups"] if g["groupId"] == gid)
        if grp_ret["retentionEvidence"]["valid"]:
            self.assertEqual(grp_ret["closureState"], "INTENTIONALLY_RETAINED")
            self.assertGreater(inv_retained["summary"]["intentionallyRetainedCount"], 0)
            if inv_retained["summary"]["openActionableGroupCount"] > 0:
                self.assertFalse(inv_retained["closureOk"])

    def test_retention_proof_is_member_complete_and_rejects_parameterizable_predicates(self) -> None:
        # 1. 3-member group with only 2 semantic tuples must fail DISTINCT_SEMANTIC_ACT_OR_INTENT
        partial_recs = [
            {"semanticAct": None, "semanticIntent": "INFORM", "semanticSubject": "IDENTITY"},
            {"semanticAct": None, "semanticIntent": "INFORM", "semanticSubject": "IDENTITY"},
            {"semanticAct": None, "semanticIntent": "REFUSE", "semanticSubject": "IDENTITY"},
        ]
        partial_plans = [{"payload": {}}, {"payload": {}}, {"payload": {}}]
        ok_partial, ev_partial = _verify_retention_claim(
            {
                "evidenceCode": "DISTINCT_SEMANTIC_ACT_OR_INTENT",
                "reason": "Two tuples claimed for three members.",
            },
            partial_recs,
            partial_plans,
        )
        self.assertFalse(ok_partial)
        self.assertFalse(ev_partial["valid"])
        self.assertEqual(ev_partial["distinctActs"], 2)
        self.assertEqual(ev_partial["memberCount"], 3)

        # 2. 3-member group with 3 mechanically proven distinctions passes
        complete_recs = [
            {"semanticAct": "DISCLOSE_IDENTITY", "semanticIntent": "INFORM", "semanticSubject": "IDENTITY"},
            {"semanticAct": "DECEIVE_IDENTITY", "semanticIntent": "INFORM", "semanticSubject": "IDENTITY"},
            {"semanticAct": "REFUSE_IDENTITY", "semanticIntent": "REFUSE", "semanticSubject": "IDENTITY"},
        ]
        ok_complete, ev_complete = _verify_retention_claim(
            {
                "evidenceCode": "DISTINCT_SEMANTIC_ACT_OR_INTENT",
                "reason": "All three members own distinct canonical speechAct/intent/subject tuples.",
            },
            complete_recs,
            partial_plans,
        )
        self.assertTrue(ok_complete)
        self.assertTrue(ev_complete["valid"])
        self.assertEqual(ev_complete["distinctActs"], 3)

        # 3. Different predicates that are safely parameterizable (no structural blocker) must fail
        param_recs = [
            {"executeContract": None},
            {"executeContract": None},
            {"executeContract": None},
        ]
        param_plans = [
            {"when": {"path": "world.time.hour", "op": "lt", "value": 12}, "payload": {"metadata": {}}},
            {"when": {"path": "world.time.hour", "op": "gte", "value": 12}, "payload": {"metadata": {}}},
            {"when": {"path": "relationship.speakerToAddressee.state", "op": "eq", "value": "Friend"}, "payload": {"metadata": {}}},
        ]
        ok_param, ev_param = _verify_retention_claim(
            {
                "evidenceCode": "NON_PARAMETERIZABLE_PREDICATES",
                "reason": "Three different when predicates without structural blocker.",
            },
            param_recs,
            param_plans,
        )
        self.assertFalse(ok_param)
        self.assertFalse(ev_param["valid"])
        self.assertEqual(ev_param["distinctPredicates"], 3)

    def test_cli_modernization_closure_gate_passes_and_fails_closed(self) -> None:
        import io
        import json
        from contextlib import redirect_stdout
        from tempfile import TemporaryDirectory
        from tools.semantic_harness.codebuilder.convo_engine_cli import main as cli_main

        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = cli_main([
                "modernization-inventory",
                "--repository", str(CORE_ROOT),
                "--closure",
                "--summary",
            ])
        self.assertEqual(rc, 0)
        payload = json.loads(buf.getvalue())
        self.assertTrue(payload["ok"])
        self.assertTrue(payload["closureOk"])
        self.assertEqual(payload["operation"], "convo.modernization_closure")

        from unittest.mock import patch

        with patch(
            "tools.semantic_harness.codebuilder.convo_engine_modernization_inventory.build_modernization_inventory",
            return_value={
                "ok": False,
                "closureOk": False,
                "schema": MODERNIZATION_INVENTORY_SCHEMA,
                "summary": {"openActionableGroupCount": 1},
                "groups": [],
            },
        ):
            fail_buf = io.StringIO()
            with redirect_stdout(fail_buf):
                rc_fail = cli_main([
                    "modernization-inventory",
                    "--repository", str(CORE_ROOT),
                    "--closure",
                    "--summary",
                ])
            self.assertEqual(rc_fail, 2)
            fail_payload = json.loads(fail_buf.getvalue())
            self.assertFalse(fail_payload["ok"], fail_payload)
            self.assertFalse(fail_payload["closureOk"], fail_payload)


if __name__ == "__main__":
    unittest.main()
