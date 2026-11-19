"""Tests for ConvoEngine vs generic Semantics ownership inventory."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.codebuilder import (
    OWNERSHIP_INVENTORY_SCHEMA,
    build_ownership_inventory,
    map_generated_convo_engine_module,
)

CORE_REPO = Path(__file__).resolve().parents[3]
HOOMANS_REPO = CORE_REPO.parent / "ProjectHoomans"
DT_REPO = CORE_REPO.parent / "DynamicTrading"


class ConvoEngineOwnershipInventoryTests(unittest.TestCase):
    def test_generated_module_mapping_removes_redundant_wrappers_and_catalog_leaves(self) -> None:
        self.assertEqual(
            map_generated_convo_engine_module(
                "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/CoreCheckIn/Catalog"
            ),
            "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        )
        self.assertEqual(
            map_generated_convo_engine_module(
                "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/TaskLifecycle/Catalog__ecb92fd8"
            ),
            "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        )
        self.assertEqual(
            map_generated_convo_engine_module(
                "DTCommon/Semantics/Generated/Conversation/Packs/Psdl/Dialogue/Trading"
            ),
            "DTCommon/ConvoEngine/Packs/Dialogue/Trading",
        )
        self.assertEqual(
            map_generated_convo_engine_module(
                "PsychopatzCore/Semantics/Generated/Conversation/FoundationRegistry"
            ),
            "PsychopatzCore/ConvoEngine/FoundationRegistry",
        )

    def test_three_repo_ownership_inventory_classifies_modules_and_verifies_collision_safety(self) -> None:
        if not (HOOMANS_REPO.is_dir() and DT_REPO.is_dir()):
            self.skipTest("Sibling participant repositories are not available")

        report = build_ownership_inventory(
            {
                "PsychopatzCore": CORE_REPO,
                "ProjectHoomans": HOOMANS_REPO,
                "DynamicTrading": DT_REPO,
            },
            generated_at="2026-11-13T00:00:00Z",
        )
        self.assertEqual(report["schema"], OWNERSHIP_INVENTORY_SCHEMA)
        self.assertEqual(report["scope"], "ownership-inventory")
        self.assertTrue(report["collisionCheck"]["collisionSafe"])
        self.assertEqual(report["collisionCheck"]["targetPathCollisions"], {})

        by_key = {(item["repository"], item["module"]): item for item in report["modules"]}

        # Core ConvoEngine-owned modules (canonical post-S6M2B namespace)
        for core_convo in (
            "PsychopatzCore/ConvoEngine/DialogueState",
            "PsychopatzCore/ConvoEngine/DialogueRouter",
            "PsychopatzCore/ConvoEngine/DialogueFlow",
            "PsychopatzCore/ConvoEngine/DialogueTurn",
            "PsychopatzCore/ConvoEngine/Offer",
            "PsychopatzCore/ConvoEngine/Foundation",
            "PsychopatzCore/ConvoEngine/FoundationRegistry",
        ):
            entry = by_key[("PsychopatzCore", core_convo)]
            self.assertEqual(entry["classification"], "convo_engine")
            self.assertEqual(entry["proposedModule"], core_convo)

        # Generic Core Semantic infrastructure stays under PsychopatzCore/Semantics/
        for core_generic in (
            "PsychopatzCore/Semantics/PsychopatzSemantic",
            "PsychopatzCore/Semantics/PsychopatzSemanticIR",
            "PsychopatzCore/Semantics/PsychopatzSemanticParser",
            "PsychopatzCore/Semantics/PsychopatzSemanticPredicate",
            "PsychopatzCore/Semantics/PsychopatzSemanticFuzzyMatcher",
            "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher",
            "PsychopatzCore/Semantics/PsychopatzSemanticPackRegistry",
            "PsychopatzCore/Semantics/Generated/Lexicon/Catalog",
        ):
            entry = by_key[("PsychopatzCore", core_generic)]
            self.assertEqual(entry["classification"], "generic_semantic_infrastructure")
            self.assertTrue(entry["proposedModule"].startswith("PsychopatzCore/Semantics/"))

        # ProjectHoomans ConvoEngine vs non-ConvoEngine domain subsystems
        convo_adapter = by_key[("ProjectHoomans", "PNC/ConvoEngine/DialogueBlocks")]
        self.assertEqual(convo_adapter["classification"], "convo_engine")
        self.assertEqual(convo_adapter["proposedModule"], "PNC/ConvoEngine/DialogueBlocks")

        pnc_action = by_key[("ProjectHoomans", "PNC/Semantics/PNC_SemanticActionPlan")]
        self.assertEqual(pnc_action["classification"], "generic_semantic_infrastructure")
        self.assertEqual(pnc_action["subDomain"], "domain_action_and_task")

        # DynamicTrading generated output routes to DTCommon/ConvoEngine/*
        dt_gen = by_key[("DynamicTrading", "DTCommon/ConvoEngine/Registry")]
        self.assertEqual(dt_gen["classification"], "convo_engine")
        self.assertEqual(dt_gen["proposedModule"], "DTCommon/ConvoEngine/Registry")

        # Every live file under Semantics/ and Conversation/Semantic/ is covered.
        for repo_name, root in (
            ("PsychopatzCore", CORE_REPO),
            ("ProjectHoomans", HOOMANS_REPO),
            ("DynamicTrading", DT_REPO),
        ):
            for path in root.glob("Contents/mods/**/media/lua/**/*.lua"):
                rel = str(path.relative_to(root)).replace("\\", "/")
                if "/Semantics/" in rel or "/Conversation/Semantic/" in rel:
                    mod = rel.split("/media/lua/", 1)[1].split("/", 1)[1][:-4]
                    self.assertIn((repo_name, mod), by_key)

    def test_rejects_retired_conversation_directory(self) -> None:
        if not (HOOMANS_REPO.is_dir() and DT_REPO.is_dir()):
            self.skipTest("Sibling participant repositories are not available")
        retired_psdl_dir = "/Conversation/PSDL/"
        for root in (CORE_REPO, HOOMANS_REPO, DT_REPO):
            for path in root.glob("Contents/mods/**/media/lua/**/*.lua"):
                rel = str(path.relative_to(root)).replace("\\", "/")
                self.assertNotIn(retired_psdl_dir, rel)

    def test_collision_check_flags_existing_convo_engine_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ("PsychopatzCore", "ProjectHoomans", "DynamicTrading"):
                (root / name / "Contents" / "mods" / name / "common" / "media" / "lua" / "shared").mkdir(parents=True)
            colliding = root / "PsychopatzCore" / "Contents" / "mods" / "PsychopatzCore" / "common" / "media" / "lua" / "shared" / "PsychopatzCore" / "ConvoEngine" / "DialogueState.lua"
            colliding.parent.mkdir(parents=True, exist_ok=True)
            colliding.write_text("return {}\n", encoding="utf-8")
            unmigrated = root / "PsychopatzCore" / "Contents" / "mods" / "PsychopatzCore" / "common" / "media" / "lua" / "shared" / "PsychopatzCore" / "Semantics" / "PsychopatzSemanticDialogueState.lua"
            unmigrated.parent.mkdir(parents=True, exist_ok=True)
            unmigrated.write_text("return {}\n", encoding="utf-8")

            report = build_ownership_inventory({
                "PsychopatzCore": root / "PsychopatzCore",
                "ProjectHoomans": root / "ProjectHoomans",
                "DynamicTrading": root / "DynamicTrading",
            })
            self.assertFalse(report["collisionCheck"]["collisionSafe"])
            self.assertIn("PsychopatzCore/ConvoEngine/DialogueState", report["collisionCheck"]["targetPathCollisions"])


if __name__ == "__main__":
    unittest.main()
