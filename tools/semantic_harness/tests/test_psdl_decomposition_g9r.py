"""G9R1–G9R4: Semantic domain decomposition, owner-isolated generated surfaces,
cross-owner collision isolation, variant-growth stability, and global hash audit tests."""

from __future__ import annotations

import copy
import random
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_naming import audit_hashed_module_names
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.psdl_inspect import locate_psdl
from tools.semantic_harness.codebuilder.source_manifest import derive_subdir_domain_path

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


class PsdlDecompositionG9RTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.pkg_repos = {
            "PsychopatzCore": CORE_ROOT,
            "ProjectHoomans": HOOMANS_ROOT,
            "DTCommon": DT_ROOT,
        }
        cls.model = compile_conversation_sources(
            CORE_ROOT,
            package_repositories=cls.pkg_repos,
        )
        cls.rendered, cls.reports = render_conversation_runtime_plan(cls.model)

    def test_g9r1_semantic_path_contract_and_zero_global_hashes(self) -> None:
        domain, dpath = derive_subdir_domain_path(
            Path("social/conflict/retaliate_verbally.json"),
            fallback_domain="social",
            validate_id=lambda v, _: str(v),
        )
        self.assertEqual(domain, "social")
        self.assertEqual(dpath, "social/conflict")

        # Zero avoidable hash-suffixed generated modules across all 3 repos
        for gen_dir in (
            CORE_ROOT / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine",
            HOOMANS_ROOT / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine",
            DT_ROOT / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine",
        ):
            self.assertEqual(list(gen_dir.rglob("*__*.lua")), [], f"Unexpected hash files in {gen_dir}")

        self.assertEqual(audit_hashed_module_names([m for m, _ in self.rendered]), [])

    def test_g9r2_source_semantic_decomposition(self) -> None:
        core_beh = CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/behavior"
        for sub in ("acknowledgement", "conflict", "repair", "context", "world_events"):
            self.assertTrue((core_beh / "social" / sub).is_dir())
            self.assertTrue(list((core_beh / "social" / sub).glob("*.json")))

        hoomans_beh = HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/conversation/behavior"
        for sub in ("horde", "excursion", "task_work", "news", "post_combat"):
            self.assertTrue((hoomans_beh / "scene" / sub).is_dir())
            self.assertTrue(list((hoomans_beh / "scene" / sub).glob("*.json")))

    def test_g9r3_owner_isolated_decomposed_surfaces_and_no_stale_refs(self) -> None:
        modules = {mod: src for mod, src in self.rendered}
        # Core director contains ONLY Core behaviors, decomposed by domainPath
        self.assertIn("PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Conflict", modules)
        self.assertIn("PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Repair", modules)
        self.assertNotIn("behavior.scene_horde_prompt", modules["PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Conflict"])

        # Hoomans director contains Hoomans scene behaviors, decomposed by domainPath
        self.assertIn("PNC/ConvoEngine/Behaviors/Director/Scene/Horde", modules)
        self.assertIn("behavior.scene_horde_prompt", modules["PNC/ConvoEngine/Behaviors/Director/Scene/Horde"])

        # No references to retired hash modules
        for mod, src in self.rendered:
            self.assertNotIn("Social__d6475647", src, mod)
            self.assertNotIn("CoreKnowledgeFacts__d73c98cf", src, mod)

    def test_g9r4_variant_growth_cross_owner_shuffle_and_navigation(self) -> None:
        base_map = {mod: src for mod, src in self.rendered}

        # 1. Adding a same-type variant under social/conflict changes only Conflict modules
        mutated = copy.deepcopy(self.model)
        extra_plan = copy.deepcopy(
            next(p for p in mutated["psdlRuntimePlans"] if p["id"] == "behavior.retaliate_verbally")
        )
        extra_plan["id"] = "behavior.taunt_verbally"
        mutated["psdlRuntimePlans"].append(extra_plan)
        mutated_rendered, _ = render_conversation_runtime_plan(mutated)
        mutated_map = {mod: src for mod, src in mutated_rendered}

        self.assertNotEqual(
            mutated_map["PsychopatzCore/ConvoEngine/Behavior/Social/Conflict"],
            base_map["PsychopatzCore/ConvoEngine/Behavior/Social/Conflict"],
        )
        for stable_mod in (
            "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
            "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
            "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
            "PsychopatzCore/ConvoEngine/Behavior/Social/WorldEvents",
        ):
            self.assertEqual(mutated_map[stable_mod], base_map[stable_mod])

        # 2. Cross-owner same semantic leaf (ProjectHoomans social/conflict alongside Core social/conflict)
        cross_model = copy.deepcopy(self.model)
        cross_plan = copy.deepcopy(extra_plan)
        cross_plan["owner"] = "ProjectHoomans"
        cross_plan["id"] = "behavior.hoomans_conflict_callout"
        cross_plan["sourceShard"] = "behavior/social/conflict/hoomans_callout.json"
        cross_model["shards"].append({
            "path": "behavior/social/conflict/hoomans_callout.json",
            "owner": "ProjectHoomans",
        })
        cross_model["psdlRuntimePlans"].append(cross_plan)
        cross_rendered, _ = render_conversation_runtime_plan(cross_model)
        cross_mods = {mod for mod, _ in cross_rendered}
        self.assertIn("PsychopatzCore/ConvoEngine/Behavior/Social/Conflict", cross_mods)
        self.assertIn("PNC/ConvoEngine/Behavior/Social/Conflict", cross_mods)
        self.assertEqual(audit_hashed_module_names(cross_mods), [])

        # 3. Shuffled source order produces identical generated module names & content
        shuffled = copy.deepcopy(self.model)
        rng = random.Random(42)
        rng.shuffle(shuffled["psdlRuntimePlans"])
        shuffled_rendered, _ = render_conversation_runtime_plan(shuffled)
        self.assertEqual({m: s for m, s in shuffled_rendered}, base_map)

        # 4. Navigation exposes domain and domainPath
        loc = locate_psdl(
            self.model,
            record_id="behavior.retaliate_verbally",
            package_repositories=self.pkg_repos,
        )
        self.assertEqual(loc["domain"], "social")
        self.assertEqual(loc["domainPath"], "social/conflict")
        self.assertEqual(loc["package"], "PsychopatzCore")
