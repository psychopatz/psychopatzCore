"""U2 tests: Multi-IR offline inheritance, JSON Patch overlays, cross-IR linking, and SocialPolicy stacking."""

from __future__ import annotations

import json
import math
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.ai_cross_ir_linker import link_workspace_ai_irs
from tools.semantic_harness.codebuilder.ai_ir_core import (
    AssetCatalog,
    apply_json_patch_overlays,
    flatten_inheritance,
    load_b42_asset_catalog,
)
from tools.semantic_harness.codebuilder.autonomy_ad_compiler import (
    AUTONOMY_AD_PACKAGE_SCHEMA,
    AUTONOMY_AD_SHARD_SCHEMA,
    compile_autonomy_ad_package,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.reaction_policy_compiler import (
    REACTION_POLICY_PACKAGE_SCHEMA,
    REACTION_POLICY_SHARD_SCHEMA,
    compile_reaction_policy_package,
)
from tools.semantic_harness.codebuilder.reconcile import reconcile_check
from tools.semantic_harness.codebuilder.social_policy_compiler import (
    SOCIAL_POLICY_PACKAGE_SCHEMA,
    SOCIAL_POLICY_SHARD_SCHEMA,
    compile_social_policy_package,
)
from tools.semantic_harness.codebuilder.work_scenario_compiler import (
    WORK_SCENARIO_PACKAGE_SCHEMA,
    WORK_SCENARIO_SHARD_SCHEMA,
    compile_work_scenario_package,
)

HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


class AiMultiIrCompilerTests(unittest.TestCase):
    def test_offline_inheritance_deep_merges_and_strips_abstract_templates(self) -> None:
        resolved = flatten_inheritance([
            {
                "id": "base.template",
                "abstract": True,
                "cooldownMs": 5000,
                "nested": {"a": 1, "b": 2},
                "removeMe": True,
            },
            {
                "id": "child.concrete",
                "parent": "base.template",
                "nested": {"b": 99, "c": 3},
                "removeMe": None,
            },
        ])
        self.assertEqual(len(resolved), 1)
        child = resolved[0]
        self.assertEqual(child["id"], "child.concrete")
        self.assertEqual(child["cooldownMs"], 5000)
        self.assertEqual(child["nested"], {"a": 1, "b": 99, "c": 3})
        self.assertNotIn("removeMe", child)
        self.assertNotIn("abstract", child)
        self.assertNotIn("parent", child)

    def test_offline_inheritance_rejects_cycles_and_missing_parents(self) -> None:
        with self.assertRaisesRegex(CompileError, "inheritance cycle"):
            flatten_inheritance([
                {"id": "a", "parent": "b"},
                {"id": "b", "parent": "a"},
            ])
        with self.assertRaisesRegex(CompileError, "missing parent"):
            flatten_inheritance([{"id": "orphan", "parent": "ghost"}])

    def test_json_patch_overlays_apply_and_fail_closed(self) -> None:
        doc = {"ads": [{"id": "a", "cooldownMs": 100}]}
        patched = apply_json_patch_overlays(
            doc,
            [
                {"op": "test", "path": "/ads/0/id", "value": "a"},
                {"op": "replace", "path": "/ads/0/cooldownMs", "value": 250},
                {"op": "add", "path": "/ads/0/tag", "value": "tuned"},
            ],
        )
        self.assertEqual(patched["ads"][0]["cooldownMs"], 250)
        self.assertEqual(patched["ads"][0]["tag"], "tuned")

        patched2 = apply_json_patch_overlays(patched, [{"op": "remove", "path": "/ads/0/tag"}])
        self.assertNotIn("tag", patched2["ads"][0])

        with self.assertRaisesRegex(CompileError, "test failed"):
            apply_json_patch_overlays(doc, [{"op": "test", "path": "/ads/0/id", "value": "nope"}])
        with self.assertRaisesRegex(CompileError, "missing target key"):
            apply_json_patch_overlays(doc, [{"op": "replace", "path": "/ads/0/missing", "value": 1}])

    def test_reaction_policy_precomputes_cos_half_fov(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_json(
                root / "package.json",
                {
                    "schema": REACTION_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "owner": "ProjectHoomans",
                    "shards": ["policies/p.json"],
                },
            )
            _write_json(
                root / "policies/p.json",
                {
                    "schema": REACTION_POLICY_SHARD_SCHEMA,
                    "version": 1,
                    "owner": "ProjectHoomans",
                    "domain": "Test",
                    "perceptionProfiles": [
                        {"id": "p120", "fovDegrees": 120},
                        {"id": "p90", "fovDegrees": 90},
                    ],
                },
            )
            plan = compile_reaction_policy_package(root)
            self.assertAlmostEqual(plan["perceptionProfiles"]["p120"]["cosHalfFov"], 0.5, places=6)
            self.assertAlmostEqual(
                plan["perceptionProfiles"]["p90"]["cosHalfFov"],
                round(math.cos(math.radians(45.0)), 6),
                places=6,
            )

    def test_social_policy_supports_thought_stacking_and_nullifying_traits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_json(
                root / "package.json",
                {
                    "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "owner": "PsychopatzCore",
                    "shards": ["events/stack.json"],
                },
            )
            _write_json(
                root / "events/stack.json",
                {
                    "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                    "version": 1,
                    "owner": "PsychopatzCore",
                    "domain": "Stacking",
                    "events": [
                        {
                            "id": "social.stacked_praise",
                            "memory": {
                                "retentionClass": "SHORT",
                                "salience": 110,
                                "stackLimit": 4,
                                "stackedEffectMultiplier": 0.5,
                            },
                            "relationship": {
                                "approvalDelta": 8,
                                "nullifyingTraits": ["Callous", "Cynical"],
                            },
                        }
                    ],
                },
            )
            plan = compile_social_policy_package(root)
            ev = plan["events"]["social.stacked_praise"]
            self.assertEqual(ev["stackLimit"], 4)
            self.assertEqual(ev["stackedEffectMultiplier"], 0.5)
            self.assertEqual(ev["nullifyingTraits"], ["Callous", "Cynical"])

            # Out-of-bounds stackLimit must fail closed
            _write_json(
                root / "events/stack.json",
                {
                    "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                    "version": 1,
                    "owner": "PsychopatzCore",
                    "domain": "Stacking",
                    "events": [
                        {
                            "id": "social.bad_stack",
                            "memory": {"retentionClass": "SHORT", "stackLimit": 99},
                        }
                    ],
                },
            )
            with self.assertRaises(CompileError):
                compile_social_policy_package(root)

    def test_cross_ir_linker_fails_closed_on_dangling_references_and_assets(self) -> None:
        catalog = AssetCatalog(
            anim_states=frozenset({"idle"}),
            anim_variables=frozenset({"PNCAlertLevel"}),
            voice_events=frozenset({"social.shout_hey"}),
        )
        base_kwargs = {
            "convo_model": {"convoRuntimePlans": [{"id": "greet"}]},
            "social_plans": {"Core": {"events": {"social.grievance": {}}, "aliases": {}}},
            "autonomy_plans": {"Hoomans": {"ads": {"ad.lounge": {}}, "situations": {}}},
            "reaction_plans": {"Hoomans": {"reactions": {}, "barks": {"bark.hey": {"voiceEvent": "social.shout_hey"}}}},
            "work_scenario_plans": {"Hoomans": {"workDefs": {"work.farm": {}}, "scenarios": {"scen.am": {"adId": "ad.lounge", "workDefId": "work.farm"}}}},
            "asset_catalog": catalog,
        }
        summary = link_workspace_ai_irs(**base_kwargs)
        self.assertGreater(summary["counts"]["linkedEdges"], 0)

        # Dangling SocialPolicy ref
        bad_social = {
            **base_kwargs,
            "reaction_plans": {
                "Hoomans": {
                    "reactions": {"rx.1": {"socialEventId": "social.missing_event"}},
                    "barks": {},
                }
            },
        }
        with self.assertRaisesRegex(CompileError, "SocialPolicy.event"):
            link_workspace_ai_irs(**bad_social)

        # Dangling ConvoEngine act ref
        bad_convo = {
            **base_kwargs,
            "reaction_plans": {
                "Hoomans": {
                    "reactions": {"rx.1": {"convoActId": "nonexistent_act"}},
                    "barks": {},
                }
            },
        }
        with self.assertRaisesRegex(CompileError, "ConvoEngine.family_or_act"):
            link_workspace_ai_irs(**bad_convo)

        # Dangling Build 42 AnimSet variable
        bad_anim = {
            **base_kwargs,
            "reaction_plans": {
                "Hoomans": {
                    "reactions": {"rx.1": {"secondaryAnimVar": "FakeMissingAnimVar"}},
                    "barks": {},
                }
            },
        }
        with self.assertRaisesRegex(CompileError, "Build42.AnimSet.variable"):
            link_workspace_ai_irs(**bad_anim)

        # Dangling NPCVoice catalog event
        bad_voice = {
            **base_kwargs,
            "reaction_plans": {
                "Hoomans": {
                    "reactions": {},
                    "barks": {"bark.bad": {"voiceEvent": "voice.missing_clip"}},
                }
            },
        }
        with self.assertRaisesRegex(CompileError, "NPCVoice.Catalog.Event"):
            link_workspace_ai_irs(**bad_voice)

        # Dangling AutonomyAd / nextScenarioId
        bad_scen = {
            **base_kwargs,
            "work_scenario_plans": {
                "Hoomans": {
                    "workDefs": {},
                    "scenarios": {"scen.1": {"adId": "ad.missing"}},
                }
            },
        }
        with self.assertRaisesRegex(CompileError, "AutonomyAd.ad"):
            link_workspace_ai_irs(**bad_scen)

    def test_live_workspace_multi_ir_packages_compile_and_reconcile_clean(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")

        # Verify live Build 42 asset catalog reads real Hoomans XML + Lua catalog
        catalog = load_b42_asset_catalog(HOOMANS_ROOT)
        self.assertIn("PNCActor", catalog.anim_variables)
        self.assertIn("PNCMoveAnim", catalog.anim_variables)
        self.assertIn("injury.generic", catalog.voice_events)
        self.assertIn("social.shout_hey", catalog.voice_events)

        # Verify JSON Patch overlay & inheritance took effect on live ProjectHoomans packages
        autonomy_plan = compile_autonomy_ad_package(
            HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/autonomy_ad",
            expected_owner="ProjectHoomans",
        )
        self.assertEqual(autonomy_plan["ads"]["ad.social_lounge"]["cooldownMs"], 8000)
        self.assertEqual(autonomy_plan["situations"]["situation.camp_chat"]["cooldownMs"], 42000)
        self.assertNotIn("ad.base_idle_facility", autonomy_plan["ads"])

        reaction_plan = compile_reaction_policy_package(
            HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/reaction_policy",
            expected_owner="ProjectHoomans",
        )
        self.assertAlmostEqual(
            reaction_plan["perceptionProfiles"]["profile.colonist_default"]["cosHalfFov"],
            0.5,
            places=6,
        )

        work_plan = compile_work_scenario_package(
            HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/work_scenario",
            expected_owner="ProjectHoomans",
        )
        self.assertEqual(work_plan["workDefs"]["work.farming"]["operation"], "FARMING")

        # Verify full two-pass reconcile check clean
        check_a = reconcile_check(
            HOOMANS_ROOT,
            core_repository=CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        check_b = reconcile_check(
            HOOMANS_ROOT,
            core_repository=CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        self.assertTrue(check_a["clean"], f"Dirty reconcile check: {check_a['counts']}")
        self.assertEqual(check_a["modelFingerprint"], check_b["modelFingerprint"])


if __name__ == "__main__":
    unittest.main()
