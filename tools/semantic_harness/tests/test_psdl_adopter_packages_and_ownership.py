"""G9A–G9D: Self-contained adopter packages, semantic ownership audit,
human-readable deterministic shard naming, and navigation UX tests."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_naming import (
    ModuleNameRegistry,
    audit_hashed_module_names,
    module_path,
    semantic_chunk_label,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.psdl_compact import (
    CONVO_ENGINE_PACKAGE_SCHEMA,
    PROVENANCE_LOCK_SCHEMA,
)
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.psdl_inspect import locate_psdl

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


class PsdlAdopterPackagesAndOwnershipTests(unittest.TestCase):
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

    def test_self_contained_adopter_packages_and_imports(self) -> None:
        core_pkg_path = CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/package.json"
        hoomans_pkg_path = HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/conversation/package.json"
        dt_pkg_path = DT_ROOT / "tools/providers/dt/codebuilder/sources/conversation/package.json"

        core_pkg = json.loads(core_pkg_path.read_text(encoding="utf-8"))
        hoomans_pkg = json.loads(hoomans_pkg_path.read_text(encoding="utf-8"))
        dt_pkg = json.loads(dt_pkg_path.read_text(encoding="utf-8"))

        self.assertEqual(core_pkg["package"], "PsychopatzCore")
        self.assertEqual(core_pkg["registryOwner"], "PsychopatzCore")
        self.assertNotIn("externalSourceRoots", core_pkg)

        self.assertEqual(hoomans_pkg["package"], "ProjectHoomans")
        self.assertIn("PsychopatzCore", hoomans_pkg["imports"])
        self.assertEqual(dt_pkg["package"], "DTCommon")
        self.assertIn("PsychopatzCore", dt_pkg["imports"])

        # Core package compiles standalone without adopter federation
        core_only = compile_conversation_sources(
            CORE_ROOT,
            manifest_path=core_pkg_path,
            package_repositories={"PsychopatzCore": CORE_ROOT},
        )
        owners = {p["owner"] for p in core_only["psdlRuntimePlans"]}
        self.assertEqual(owners, {"PsychopatzCore"})

        # Missing/unknown imported package fails closed
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp)
            pkg_dir = ws / "sources/conversation"
            (pkg_dir / "dialogue").mkdir(parents=True)
            (pkg_dir / "package.json").write_text(
                json.dumps(
                    {
                        "schema": CONVO_ENGINE_PACKAGE_SCHEMA,
                        "version": 1,
                        "package": "ProjectHoomans",
                        "defaultOwner": "ProjectHoomans",
                        "registryOwner": "ProjectHoomans",
                        "imports": ["NonExistentCorePkg"],
                        "sourceRoots": [],
                    }
                ),
                encoding="utf-8",
            )
            (pkg_dir / "provenance.lock").write_text(
                json.dumps({"schema": PROVENANCE_LOCK_SCHEMA, "version": 1, "sourceProfiles": {"d": {}}}),
                encoding="utf-8",
            )
            with self.assertRaises(CompileError):
                compile_conversation_sources(ws, manifest_path=pkg_dir / "package.json")

    def test_semantic_ownership_audit(self) -> None:
        plans_by_id = {p["id"]: p for p in self.model["psdlRuntimePlans"]}
        # Reusable Core social beats/behaviors stay in PsychopatzCore
        for core_id in (
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.retaliate_verbally",
            "behavior.deescalate",
            "behavior.warn",
            "behavior.reconcile",
        ):
            self.assertEqual(plans_by_id[core_id]["owner"], "PsychopatzCore")

        # Hoomans-domain scene behaviors live in ProjectHoomans
        for hoomans_id in (
            "behavior.scene_horde_prompt",
            "behavior.scene_horde_reply_brave",
            "behavior.scene_excursion_preparing",
            "behavior.scene_task_work_assigned",
            "behavior.scene_post_combat_clear",
        ):
            self.assertEqual(plans_by_id[hoomans_id]["owner"], "ProjectHoomans")

    def test_readable_deterministic_shard_naming_and_collision_fallback(self) -> None:
        # ProjectHoomans generated ConvoEngine tree has zero avoidable __<8hex>.lua files
        hoomans_gen = HOOMANS_ROOT / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine"
        hashed_hoomans = list(hoomans_gen.rglob("*__*.lua"))
        self.assertEqual(hashed_hoomans, [])

        # CompanionCommandsLifecycle splits deterministically into readable modules
        lifecycle_dir = hoomans_gen / "Dialogue/CompanionCommandsLifecycle"
        self.assertTrue((lifecycle_dir / "CampToFollow.lua").is_file())
        self.assertTrue((lifecycle_dir / "ReturnHomeToStay.lua").is_file())
        self.assertTrue((lifecycle_dir / "CommandStopFollowing.lua").is_file())

        # Audit report classifies any remaining hashed modules cleanly
        rendered, _ = render_conversation_runtime_plan(self.model)
        audit = audit_hashed_module_names([mod for mod, _ in rendered])
        for item in audit:
            self.assertIn(item["reason"], {"collision_fallback", "segment_length_limit"})

        # True collision fallback still works deterministically in ModuleNameRegistry
        reg = ModuleNameRegistry()
        m1 = module_path("PNC/ConvoEngine", ["Dialogue", "SameName"], "id.one", reg)
        m2 = module_path("PNC/ConvoEngine", ["Dialogue", "SameName"], "id.two", reg)
        self.assertEqual(m1, "PNC/ConvoEngine/Dialogue/SameName")
        self.assertTrue(m2.startswith("PNC/ConvoEngine/Dialogue/SameName__"))

        self.assertEqual(semantic_chunk_label(["command.camp", "command.follow"]), "CampToFollow")

    def test_navigation_locate(self) -> None:
        loc_hoomans = locate_psdl(
            self.model,
            record_id="behavior.scene_horde_prompt",
            package_repositories=self.pkg_repos,
        )
        self.assertEqual(loc_hoomans["package"], "ProjectHoomans")
        self.assertIn("PsychopatzCore", loc_hoomans["importedPackages"])
        self.assertTrue(loc_hoomans["authoredSourcePath"].endswith("behavior/scene/horde/scene_horde_prompt.json"))
        self.assertTrue(loc_hoomans["generatedModules"])

        loc_core = locate_psdl(
            self.model,
            record_id="beat.argument_escalation",
            package_repositories=self.pkg_repos,
        )
        self.assertEqual(loc_core["package"], "PsychopatzCore")

        loc_dt = locate_psdl(
            self.model,
            record_id="action.trade",
            package_repositories=self.pkg_repos,
        )
        self.assertEqual(loc_dt["package"], "DTCommon")
        self.assertIn("PsychopatzCore", loc_dt["importedPackages"])
