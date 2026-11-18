"""G9R1–G9R4: Semantic domain decomposition, owner-isolated generated surfaces,
cross-owner collision isolation, variant-growth stability, and global hash audit tests."""

from __future__ import annotations

import copy
import json
import random
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_naming import audit_hashed_module_names
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.convo_engine_inspect import locate_convo_engine
from tools.semantic_harness.codebuilder.source_manifest import derive_subdir_domain_path

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


class PsdlSemanticDomainDecompositionTests(unittest.TestCase):
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

    def test_semantic_path_contract_and_zero_global_hashes(self) -> None:
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

    def test_source_semantic_decomposition(self) -> None:
        core_beh = CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/behavior"
        for sub in ("acknowledgement", "conflict", "repair", "context", "world_events"):
            self.assertTrue((core_beh / "social" / sub).is_dir())
            self.assertTrue(list((core_beh / "social" / sub).glob("*.json")))

        hoomans_beh = HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/conversation/behavior"
        for sub in ("horde", "excursion", "task_work", "news", "post_combat"):
            self.assertTrue((hoomans_beh / "scene" / sub).is_dir())
            self.assertTrue(list((hoomans_beh / "scene" / sub).glob("*.json")))

    def test_owner_isolated_decomposed_surfaces_and_no_stale_refs(self) -> None:
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

    def test_variant_growth_cross_owner_shuffle_and_navigation(self) -> None:
        base_map = {mod: src for mod, src in self.rendered}

        # 1. Adding a same-type variant under social/conflict changes only Conflict modules
        mutated = copy.deepcopy(self.model)
        extra_plan = copy.deepcopy(
            next(p for p in mutated["convoRuntimePlans"] if p["id"] == "behavior.retaliate_verbally")
        )
        extra_plan["id"] = "behavior.taunt_verbally"
        mutated["convoRuntimePlans"].append(extra_plan)
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
        cross_model["convoRuntimePlans"].append(cross_plan)
        cross_rendered, _ = render_conversation_runtime_plan(cross_model)
        cross_mods = {mod for mod, _ in cross_rendered}
        self.assertIn("PsychopatzCore/ConvoEngine/Behavior/Social/Conflict", cross_mods)
        self.assertIn("PNC/ConvoEngine/Behavior/Social/Conflict", cross_mods)
        self.assertEqual(audit_hashed_module_names(cross_mods), [])

        # 3. Shuffled source order produces identical generated module names & content
        shuffled = copy.deepcopy(self.model)
        rng = random.Random(42)
        rng.shuffle(shuffled["convoRuntimePlans"])
        shuffled_rendered, _ = render_conversation_runtime_plan(shuffled)
        self.assertEqual({m: s for m, s in shuffled_rendered}, base_map)

        # 4. Navigation exposes domain and domainPath
        loc = locate_convo_engine(
            self.model,
            record_id="behavior.retaliate_verbally",
            package_repositories=self.pkg_repos,
        )
        self.assertEqual(loc["domain"], "social")
        self.assertEqual(loc["domainPath"], "social/conflict")
        self.assertEqual(loc["package"], "PsychopatzCore")

    def test_real_source_variant_and_new_subdomain_are_local(self) -> None:
        base_map = {mod: src for mod, src in self.rendered}
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_core = Path(tmpdir) / "psychopatzCore"
            src_codebuilder = CORE_ROOT / "tools/semantic_harness/codebuilder"
            dst_codebuilder = temp_core / "tools/semantic_harness/codebuilder"
            shutil.copytree(src_codebuilder / "sources", dst_codebuilder / "sources")
            pkg_repos = {**self.pkg_repos, "PsychopatzCore": temp_core}

            behavior_root = dst_codebuilder / "sources/conversation/behavior/social"
            conflict_dir = behavior_root / "conflict"
            fixture_variant = conflict_dir / "g9r_fixture_taunt.json"
            smalltalk_dir = behavior_root / "smalltalk_g9r_fixture"
            smalltalk_file = smalltalk_dir / "g9r_fixture_smalltalk.json"

            def compile_map() -> dict[str, str]:
                model = compile_conversation_sources(
                    temp_core,
                    package_repositories=pkg_repos,
                )
                rendered, _ = render_conversation_runtime_plan(model)
                return {mod: src for mod, src in rendered}

            fixture = json.loads((conflict_dir / "warn.json").read_text(encoding="utf-8"))
            fixture["id"] = "behavior.g9r_fixture_taunt"
            fixture["act"] = "G9R_FIXTURE_TAUNT"

            fixture_variant.write_text(json.dumps(fixture, indent=2) + "\n", encoding="utf-8")
            variant_map = compile_map()

            for changed_mod in (
                "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Conflict",
            ):
                self.assertNotEqual(variant_map[changed_mod], base_map[changed_mod])

            for stable_mod in (
                "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Repair",
                "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Acknowledgement",
                "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Context",
            ):
                self.assertEqual(variant_map[stable_mod], base_map[stable_mod])

            fixture_variant.unlink()
            smalltalk_dir.mkdir(parents=True, exist_ok=True)
            smalltalk = dict(fixture)
            smalltalk["id"] = "behavior.g9r_fixture_smalltalk"
            smalltalk["act"] = "G9R_FIXTURE_SMALLTALK"
            smalltalk_file.write_text(json.dumps(smalltalk, indent=2) + "\n", encoding="utf-8")
            subdomain_map = compile_map()

            new_runtime_modules = {
                mod for mod in subdomain_map
                if mod.startswith("PsychopatzCore/ConvoEngine/Behavior/Social/") and mod not in base_map
            }
            new_director_modules = {
                mod for mod in subdomain_map
                if mod.startswith("PsychopatzCore/ConvoEngine/Behaviors/Director/Social/") and mod not in base_map
            }
            self.assertEqual(len(new_runtime_modules), 1)
            self.assertEqual(len(new_director_modules), 1)
            self.assertTrue(all("__" not in mod for mod in (*new_runtime_modules, *new_director_modules)))
            self.assertTrue(all("Smalltalk" in mod for mod in (*new_runtime_modules, *new_director_modules)))
            for stable_mod in (
                "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Conflict",
                "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
                "PsychopatzCore/ConvoEngine/Behaviors/Director/Social/Repair",
            ):
                self.assertEqual(subdomain_map[stable_mod], base_map[stable_mod])
