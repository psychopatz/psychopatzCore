"""Tests for the Semantic Harness `.convo` flow & variant inspector."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_flow_inspector import (
    collect_repo_convo_flows,
    format_flow_report,
)

HOOMANS_ROOT = Path("/home/psychopatz/Zomboid/Workshop/ProjectHoomans")


class ConvoFlowInspectorTests(unittest.TestCase):
    def test_discovers_world_gossip_and_banter_flows_offers_and_variants(self) -> None:
        if not HOOMANS_ROOT.is_dir():
            self.skipTest("ProjectHoomans checkout not present")
        flows = collect_repo_convo_flows(HOOMANS_ROOT)
        by_id = {f["poolId"]: f for f in flows}
        self.assertIn("semantic.gossip.world.opening", by_id)
        self.assertIn("semantic.gossip.world.followup", by_id)
        self.assertIn("semantic.banter.mundane", by_id)
        self.assertIn("semantic.social.npc_exchange.intro", by_id)

        opening = by_id["semantic.gossip.world.opening"]
        self.assertEqual(len(opening["offers"]), 3)
        self.assertGreaterEqual(len(opening["variants"]), 10)
        self.assertEqual(opening["variants"][0]["variant"], "threat_chopper_linked")

        followup = by_id["semantic.gossip.world.followup"]
        self.assertTrue(all(v["hasClosure"] for v in followup["variants"]))

        report = format_flow_report(opening)
        self.assertIn("DYNAMIC SUGGESTION BUTTONS (OFFERS)", report)
        self.assertIn("Where was that?", report)
        self.assertIn("BRANCHES & VARIANTS (PRIORITY ORDER)", report)
        self.assertIn("medical_wreck", report)


if __name__ == "__main__":
    unittest.main()
