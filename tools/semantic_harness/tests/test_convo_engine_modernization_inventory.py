"""Tests for S12B machine-readable dataset modernization inventory."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_engine_modernization_inventory import (
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
    "stateful",
    "mutating",
    "executeContract",
    "repeatPolicy",
    "closurePolicy",
    "realizationCount",
    "testCoverageState",
    "possibleDuplicateSpecializationGroup",
    "recommendedModernizationAction",
}


class ConvoEngineModernizationInventoryTests(unittest.TestCase):
    def test_s12b_gate_all_maintained_families_classified(self) -> None:
        inv = build_modernization_inventory(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        self.assertTrue(inv["ok"], inv["summary"])
        self.assertEqual(inv["schema"], MODERNIZATION_INVENTORY_SCHEMA)
        summary = inv["summary"]
        self.assertGreater(summary["catalogFamilyCount"], 0)
        self.assertEqual(summary["catalogFamilyCount"], summary["inventoryFamilyCount"])
        self.assertEqual(summary["unknownOwnershipCount"], 0)
        self.assertEqual(summary["unclassifiedCount"], 0)
        self.assertEqual(summary["splitAuthorityCount"], 0)
        self.assertGreater(summary["duplicateGroupCount"], 0)

        for rec in inv["families"]:
            self.assertTrue(_REQUIRED_RECORD_KEYS.issubset(rec.keys()), rec.get("canonicalID"))
            self.assertTrue(rec["classification"], rec.get("canonicalID"))
            for cls in rec["classification"]:
                self.assertIn(cls, MODERNIZATION_CLASSES)


if __name__ == "__main__":
    unittest.main()
