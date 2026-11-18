"""G8R1–G8R5: Production compact PSDL, portable-plan seam, special-logic migration,
data-driven routing, and cross-backend trace equivalence tests."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.capability_abi import (
    TARGET_DESCRIPTOR_SCHEMA,
    validate_target_capabilities,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.generation_ownership import (
    PACKAGE_DESCRIPTORS,
    temporary_package_descriptors,
)
from tools.semantic_harness.codebuilder.generation_recipe import (
    build_desired_artifact_ledger,
    load_generation_recipe,
)
from tools.semantic_harness.codebuilder.portable_runtime import (
    PORTABLE_PLAN_SCHEMA,
    PortableReferenceVM,
)
from tools.semantic_harness.codebuilder.psdl_compact import (
    COMPACT_PSDL_SCHEMA,
    PACKAGE_DESCRIPTOR_SCHEMA,
    PROVENANCE_LOCK_SCHEMA,
)
from tools.semantic_harness.codebuilder.psdl_compiler import (
    render_pz_backend_from_portable_plan,
)
from tools.semantic_harness.codebuilder.psdl_inspect import inspect_psdl
from tools.semantic_harness.codebuilder.reconcile import reconcile_apply, reconcile_check

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"
RECIPE_PATH = CORE_ROOT / "tools/semantic_harness/codebuilder/generation_recipe.json"


class PsdlProductionToolchainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.model = compile_conversation_sources(
            CORE_ROOT,
            package_repositories={
                "PsychopatzCore": CORE_ROOT,
                "ProjectHoomans": HOOMANS_ROOT,
                "DTCommon": DT_ROOT,
            },
        )
        cls.portable_plan = cls.model["portablePlan"]

    def test_production_compact_psdl_corpus_and_sidecars(self) -> None:
        conv_root = CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation"
        pkg = json.loads((conv_root / "package.json").read_text(encoding="utf-8"))
        prov = json.loads((conv_root / "provenance.lock").read_text(encoding="utf-8"))
        self.assertEqual(pkg["schema"], PACKAGE_DESCRIPTOR_SCHEMA)
        self.assertEqual(prov["schema"], PROVENANCE_LOCK_SCHEMA)

        v1_count = 0
        v2_count = 0
        for root in (
            conv_root,
            HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/conversation",
            DT_ROOT / "tools/providers/dt/codebuilder/sources/conversation",
        ):
            for p in root.rglob("*.json"):
                if "translations" in p.relative_to(root).parts:
                    continue
                d = json.loads(p.read_text(encoding="utf-8"))
                if d.get("schema") == "psychopatz.convo-engine.v1":
                    v1_count += 1
                elif d.get("schema") == COMPACT_PSDL_SCHEMA:
                    v2_count += 1

        # 11 canonical S11 state-aware psychopatz.convo-engine.v1 definitions (6 in R2 + 5 in R3).
        self.assertEqual(v1_count, 11)
        self.assertGreaterEqual(v2_count, 577)

        # Verify large localized family via textSidecars compiled into runtime plans
        knowledge_plan = next(
            p for p in self.model["psdlRuntimePlans"] if p["id"] == "question.knowledge"
        )
        known_variants = (
            knowledge_plan["payload"]["reply"]["known"]["say"]["realizations"]["1"]["variants"]
        )
        self.assertTrue(known_variants[0]["text"]["EN"])
        self.assertTrue(known_variants[0]["text"]["TL"])

    def test_portable_dialogue_plan_is_production_seam(self) -> None:
        self.assertEqual(self.portable_plan["schema"], PORTABLE_PLAN_SCHEMA)
        self.assertIn("behavior.retaliate_verbally", self.portable_plan["behaviors"])
        self.assertIn("beat.argument_escalation", self.portable_plan["beats"])
        self.assertIn("question.knowledge", self.portable_plan["dialogues"])

        # Bypassing portable plan seam must fail closed
        with self.assertRaises(CompileError):
            render_pz_backend_from_portable_plan({"schema": "invalid.plan"})

    def test_profanity_beats_behaviors_fuzzy_and_camp_production(self) -> None:
        # 1. Handwritten pnc.social.profanity* must be absent from Catalog_Register.lua
        catalog_reg = (
            HOOMANS_ROOT
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Social/Catalog_Register.lua"
        ).read_text(encoding="utf-8")
        self.assertNotIn('"pnc.social.profanity"', catalog_reg)
        self.assertNotIn('"pnc.social.profanity_prefixed"', catalog_reg)
        self.assertNotIn('"pnc.social.profanity_you"', catalog_reg)

        # Generated Pack lua exists and carries the compiled profanity patterns
        pack_files = list(
            (
                HOOMANS_ROOT
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Packs/Dialogue"
            ).glob("SocialReactionsHostile*.lua")
        )
        self.assertTrue(pack_files)
        pack_lua = pack_files[0].read_text(encoding="utf-8")
        self.assertIn("pnc.social.profanity", pack_lua)
        self.assertIn("pnc.social.profanity_you", pack_lua)

        # 2. Reference VM executes real production profanity + beat + behavior
        vm = PortableReferenceVM(self.portable_plan)
        trace_profanity = vm.step(
            utterance="you are an ass",
            context={
                "stimulus": {"type": "HUMAN_UTTERANCE"},
                "actor": {"disposition": {"aggression": 0.8}, "condition": {"panic": 0.0}},
                "history": {"hostilityCount": 1},
            },
        )
        self.assertEqual(trace_profanity["recognition"]["ruleID"], "pnc.social.profanity_you")
        self.assertEqual(trace_profanity["recognition"]["semantic"]["speechAct"], "HOSTILE_REMARK")
        self.assertEqual(trace_profanity["activeBeat"], "beat.argument_escalation")
        self.assertEqual(trace_profanity["selectedBehavior"], "behavior.retaliate_verbally")

        # 3. Real camp production record owns action contract & reply outcomes
        camp_dlg = self.portable_plan["dialogues"]["command.camp"]
        self.assertEqual(camp_dlg["action"]["capability"], "hoomans.camp.establish")
        self.assertTrue(camp_dlg["action"]["mutating"])
        self.assertIn("queued", camp_dlg["reply"])
        self.assertIn("rejected", camp_dlg["reply"])
        self.assertIn("failed", camp_dlg["reply"])

        # 4. Fuzzy recovery safety on mutating capability
        fuzzy_vm = PortableReferenceVM(
            {
                "schema": PORTABLE_PLAN_SCHEMA,
                "runtimeVersion": "1.0.0",
                "package": "ProjectHoomans",
                "dialogues": {"command.camp": camp_dlg},
                "behaviors": {},
                "beats": {},
                "realizations": {},
                "recognitionRules": [
                    {
                        "id": "pnc.command.camp",
                        "dialogueID": "command.camp",
                        "policy": "safe_recovered",
                        "mutating": True,
                        "patterns": ["set up camp"],
                        "semantic": {"speechAct": "COMMAND", "intent": "CAMP"},
                    }
                ],
            }
        )
        fuzzy = fuzzy_vm.recognize("set up cmp")
        self.assertIsNotNone(fuzzy)
        self.assertEqual(fuzzy["mode"], "fuzzy")
        self.assertTrue(fuzzy["requiresConfirmation"])
        exact = fuzzy_vm.recognize("set up camp")
        self.assertEqual(exact["mode"], "exact")
        self.assertFalse(exact["requiresConfirmation"])

    def test_data_driven_synthetic_adopter_normal_build(self) -> None:
        # Missing capability fails closed before generation
        with self.assertRaises(CompileError):
            validate_target_capabilities(
                [
                    {
                        "id": "command.camp",
                        "kind": "dialogue",
                        "owner": "ProjectHoomans",
                        "payload": {"requiredCapabilities": ["hoomans.camp.establish"]},
                    }
                ],
                {
                    "schema": TARGET_DESCRIPTOR_SCHEMA,
                    "target": "MinimalTarget",
                    "backend": "pz-lua",
                    "providedCapabilities": ["speech"],
                    "providedResolvers": [],
                },
            )

        # Synthetic adopter defined purely via descriptor data runs through normal production compiler & ledger
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp)
            adopter_repo = ws / "SyntheticSurvivalMod"
            src_root = adopter_repo / "tools/semantic_harness/codebuilder/sources/conversation"
            (src_root / "dialogue/survival").mkdir(parents=True)
            (adopter_repo / "Contents/mods/SyntheticSurvivalMod/common/media/lua/shared").mkdir(parents=True)
            (adopter_repo / "Contents/mods/SyntheticSurvivalMod/common/media/translation").mkdir(parents=True)

            (src_root / "package.json").write_text(
                json.dumps(
                    {
                        "schema": PACKAGE_DESCRIPTOR_SCHEMA,
                        "version": 1,
                        "package": "SyntheticSurvivalMod",
                        "defaultOwner": "SyntheticSurvivalMod",
                        "registryOwner": "SyntheticSurvivalMod",
                        "defaults": {
                            "participants": {"speaker": ["participant"], "addressee": ["participant"]}
                        },
                        "profiles": {},
                        "sourceRoots": [
                            {
                                "path": "dialogue",
                                "kind": "convo_engine",
                                "domain": "survival",
                                "order": 100,
                                "owner": "SyntheticSurvivalMod",
                                "domainFromSubdir": False,
                            }
                        ],
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            (src_root / "provenance.lock").write_text(
                json.dumps(
                    {
                        "schema": PROVENANCE_LOCK_SCHEMA,
                        "version": 1,
                        "sourceProfiles": {"default": {"owner": "SyntheticSurvivalMod", "version": "1"}},
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            (src_root / "dialogue/survival/fire_check.json").write_text(
                json.dumps(
                    {
                        "schema": COMPACT_PSDL_SCHEMA,
                        "id": "survival.fire_check",
                        "metadata": {"category": "synthetic:survival", "responseAct": "REPLY"},
                        "say": {
                            "variants": [
                                {"id": "neutral", "text": {"EN": ["The fire is burning."], "TL": ["Nagliliyab ang apoy."]}}
                            ]
                        },
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )

            synthetic_descriptor = {
                "owner": "SyntheticSurvivalMod",
                "aliases": ["synthetic", "syntheticsurvival"],
                "backend": "pz-lua",
                "localizationPolicy": "build42-json",
                "sharedLuaRelative": "Contents/mods/SyntheticSurvivalMod/common/media/lua/shared",
                "conversationPrefix": "Synthetic/ConvoEngine",
                "translationRelative": "Contents/mods/SyntheticSurvivalMod/common/media/translation",
                "repositoryMarkers": ["Contents/mods/SyntheticSurvivalMod"],
                "isDefaultProject": True,
                "capabilities": ["speech"],
            }
            with temporary_package_descriptors({"SyntheticSurvivalMod": synthetic_descriptor}):
                compiled = compile_conversation_sources(
                    adopter_repo,
                    manifest_path=src_root / "package.json",
                    package_repositories={"SyntheticSurvivalMod": adopter_repo},
                )
                self.assertEqual(compiled["portablePlan"]["package"], "SyntheticSurvivalMod")
                self.assertIn("survival.fire_check", compiled["portablePlan"]["dialogues"])
                raw_recipe = json.loads(RECIPE_PATH.read_text(encoding="utf-8"))
                raw_recipe["surfaces"] = [
                    {**s, "owners": ["SyntheticSurvivalMod"] if s.get("generator") == "conversation" else s["owners"]}
                    for s in raw_recipe["surfaces"]
                ]
                raw_recipe["retired"] = []
                syn_recipe_path = ws / "generation_recipe.json"
                syn_recipe_path.write_text(json.dumps(raw_recipe, indent=2), encoding="utf-8")
                syn_recipe = load_generation_recipe(syn_recipe_path)
                ledger = build_desired_artifact_ledger(
                    adopter_repo,
                    recipe=syn_recipe,
                    model=compiled,
                )
                paths = {row.path for row in ledger.rows}
                self.assertTrue(
                    any("Synthetic/ConvoEngine/" in p for p in paths),
                    f"Expected Synthetic/ConvoEngine/ in {sorted(paths)[:10]}",
                )

    def test_cross_backend_trace_equivalence_and_inspect(self) -> None:
        # Compare Reference VM traces against PZ backend runtime plan projections from the same Portable Plan
        vm = PortableReferenceVM(self.portable_plan)
        pz_by_id = {p["id"]: p for p in self.model["psdlRuntimePlans"]}
        pz_beh_by_id = {b["id"]: b for b in self.model["behaviors"]}
        pz_beat_by_id = {b["id"]: b for b in self.model["beats"]}

        # 1. Profanity -> Hostile beat -> Retaliate behavior
        t1 = vm.step(
            utterance="fuck",
            context={
                "stimulus": {"type": "HUMAN_UTTERANCE"},
                "actor": {"disposition": {"aggression": 0.9}, "condition": {"panic": 0.0}},
                "history": {"hostilityCount": 1},
            },
        )
        self.assertEqual(t1["recognition"]["ruleID"], "pnc.social.profanity")
        self.assertIn(t1["activeBeat"], pz_beat_by_id)
        self.assertIn(t1["selectedBehavior"], pz_beh_by_id)
        self.assertEqual(
            pz_beh_by_id[t1["selectedBehavior"]]["outputs"]["speech"]["dialogueAct"],
            "RETALIATE_VERBALLY",
        )

        # 2. Camp command dialogue & outcomes match between Portable Plan and PZ projection
        self.assertIn("command.camp", pz_by_id)
        self.assertEqual(
            pz_by_id["command.camp"]["payload"]["action"],
            self.portable_plan["dialogues"]["command.camp"]["action"],
        )

        # 3. Progressive disclosure inspection works on compact PSDL
        from tools.semantic_harness.codebuilder.portable_runtime import portable_plan_records
        summary = inspect_psdl(
            portable_plan_records(self.portable_plan),
            self.model.get("_source_documents") or {},
            record_id="behavior.retaliate_verbally",
            mode="summary",
        )
        self.assertEqual(summary["id"], "behavior.retaliate_verbally")
        self.assertEqual(summary["kind"], "behavior")
