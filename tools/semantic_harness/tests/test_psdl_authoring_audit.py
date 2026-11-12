"""Focused S0 tests for the Core-owned PSDL inventory/guard."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.psdl_authoring_audit import (
    guard_changed_paths,
)


class PSDLAuthoringGuardTests(unittest.TestCase):
    def test_rejects_changed_first_party_surfaces_in_all_adopters(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repositories = {
                "PsychopatzCore": root / "core",
                "ProjectHoomans": root / "hoomans",
                "DynamicTrading": root / "trading",
            }
            for repository in repositories.values():
                repository.mkdir()
            result = guard_changed_paths(
                repositories,
                changed_paths={
                    "PsychopatzCore": [
                        "tools/semantic_harness/codebuilder/sources/conversation/content/new.json",
                    ],
                    "ProjectHoomans": [
                        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Conversation/Definitions/New.lua",
                    ],
                    "DynamicTrading": [
                        "tools/providers/dt/codebuilder/sources/conversation/packs/new.json",
                    ],
                },
            )

        self.assertFalse(result["passed"])
        self.assertEqual(len(result["violations"]), 3)
        self.assertEqual(
            {violation["repository"] for violation in result["violations"]},
            {"PsychopatzCore", "ProjectHoomans", "DynamicTrading"},
        )

    def test_allows_psdl_records_generated_outputs_and_external_adapters(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repositories = {
                "PsychopatzCore": root / "core",
                "ProjectHoomans": root / "hoomans",
                "DynamicTrading": root / "trading",
            }
            for repository in repositories.values():
                repository.mkdir()
            psdl = repositories["DynamicTrading"] / "tools/providers/dt/psdl/trader.json"
            psdl.parent.mkdir(parents=True)
            psdl.write_text(
                json.dumps({
                    "schema": "psychopatz.semantic.dialogue-language.v1",
                    "kind": "dialogue",
                    "id": "trade.open",
                    "owner": "DTCommon",
                }),
                encoding="utf-8",
            )
            result = guard_changed_paths(
                repositories,
                changed_paths={
                    "PsychopatzCore": [
                        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/Conversation/Registry.lua",
                    ],
                    "ProjectHoomans": [
                        "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Compatibility/ExternalDialogue.lua",
                    ],
                    "DynamicTrading": ["tools/providers/dt/psdl/trader.json"],
                },
            )

        self.assertTrue(result["passed"])
        self.assertEqual(result["violations"], [])
        accepted = [item for repo in result["repositories"] for item in repo["accepted"]]
        self.assertIn("psdl_record", {item["reason"] for item in accepted})
        self.assertIn("generated_output_or_translation_boundary", {item["reason"] for item in accepted})


if __name__ == "__main__":
    unittest.main()
