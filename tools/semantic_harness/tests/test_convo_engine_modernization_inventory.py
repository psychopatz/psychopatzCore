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

    def test_closure_mode_fails_while_open_groups_or_legacy_readers_exist(self) -> None:
        inv = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            closure=True,
        )
        summary = inv["summary"]
        if (
            summary["openActionableFamilyCount"] > 0
            or summary["openActionableGroupCount"] > 0
            or summary["missingCompositionHookCount"] > 0
            or summary["legacySchemaReaderCount"] > 0
        ):
            self.assertFalse(inv["closureOk"])
            self.assertFalse(inv["ok"])

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


if __name__ == "__main__":
    unittest.main()
