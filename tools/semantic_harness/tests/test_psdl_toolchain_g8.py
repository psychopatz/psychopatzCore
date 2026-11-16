"""G8A-G8F acceptance tests for the compact portable PSDL toolchain & standard runtime."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.capability_abi import (
    TARGET_DESCRIPTOR_SCHEMA,
    generate_adapter_stub_guidance,
    validate_target_capabilities,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.portable_runtime import (
    PortableReferenceVM,
    compile_portable_plan,
)
from tools.semantic_harness.codebuilder.psdl_compact import (
    COMPACT_PSDL_SCHEMA,
    PACKAGE_DESCRIPTOR_SCHEMA,
    expand_compact_psdl_document,
    parse_predicate_expr,
    split_manifest_and_provenance,
    validate_package_descriptor,
)
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.psdl_inspect import inspect_psdl
from tools.semantic_harness.codebuilder.reconcile import reconcile_apply, reconcile_check
from tools.semantic_harness.tests.test_convo_engine_s9h6_build_planner import (
    _build_three_repo_fixture,
)


class PSDLToolchainG8Tests(unittest.TestCase):
    def test_g8a_compact_behavior_and_beat_match_canonical_ir_and_reduce_size(self) -> None:
        verbose_behavior_path = (
            CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/behavior/social/retaliate_verbally.json"
        )
        verbose_beat_path = (
            CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/beat/social/argument_escalation.json"
        )
        verbose_behavior = json.loads(verbose_behavior_path.read_text(encoding="utf-8"))
        verbose_beat = json.loads(verbose_beat_path.read_text(encoding="utf-8"))

        manifest_doc = json.loads(
            (CORE_ROOT / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json").read_text(
                encoding="utf-8"
            )
        )
        pkg, prov = split_manifest_and_provenance(manifest_doc)
        pkg["defaultOwner"] = "PsychopatzCore"
        validate_package_descriptor(pkg)
        self.assertIn("sourceProfiles", prov)
        self.assertNotIn("sourceProfiles", pkg)

        compact_behavior = {
            "schema": COMPACT_PSDL_SCHEMA,
            "profile": "social_behavior",
            "id": "behavior.retaliate_verbally",
            "act": "RETALIATE_VERBALLY",
            "baseRelevance": 0.55,
            "when": "stimulus.semantic.speechAct in [INSULT, HOSTILE_REMARK, THREATEN]",
            "modifiers": [
                {
                    "delta": 0.2,
                    "reason": "aggressive_personality",
                    "when": "actor.disposition.aggression >= .65",
                },
                {
                    "delta": -0.3,
                    "reason": "fear_suppresses_retaliation",
                    "when": "actor.condition.panic >= .6",
                },
            ],
            "outputs": {
                "speech": {
                    "contentTemplateID": "interaction.argument.retaliate",
                    "dialogueAct": "RETALIATE_VERBALLY",
                }
            },
        }
        compact_beat = {
            "schema": COMPACT_PSDL_SCHEMA,
            "profile": "social_beat",
            "id": "beat.argument_escalation",
            "group": "beat_group.social_primary",
            "baseRelevance": 0.7,
            "cooldownTurns": 3,
            "maxTurns": 6,
            "entry": "stimulus.semantic.speechAct in [INSULT, HOSTILE_REMARK, THREATEN]",
            "maintain": "history.hostilityCount > 0",
            "exit": "stimulus.semantic.intent == APOLOGIZE || scene.ended || beat.turnsInBeat >= 6 || world.immediateDanger",
            "candidates": {
                "behavior.warn": 0.65,
                "behavior.retaliate_verbally": 0.55,
                "behavior.deescalate": 0.35,
                "behavior.end_conversation": 0.2,
            },
        }

        expanded_beh = expand_compact_psdl_document(compact_behavior, package=pkg)
        expanded_beat = expand_compact_psdl_document(compact_beat, package=pkg)
        ir_verbose_beh = compile_convo_engine_document(verbose_behavior)["records"][0]
        ir_compact_beh = compile_convo_engine_document(expanded_beh)["records"][0]
        ir_verbose_beat = compile_convo_engine_document(verbose_beat, validate_cross_references=False)["records"][0]
        ir_compact_beat = compile_convo_engine_document(expanded_beat, validate_cross_references=False)["records"][0]

        for ir in (ir_verbose_beh, ir_compact_beh, ir_verbose_beat, ir_compact_beat):
            ir.pop("lineage", None)
        self.assertEqual(ir_compact_beh, ir_verbose_beh)
        self.assertEqual(ir_compact_beat, ir_verbose_beat)

        # Measure byte reduction
        self.assertLess(
            len(json.dumps(compact_beat)),
            len(json.dumps(verbose_beat)) * 0.75,
        )

    def test_g8a_rejects_deep_inheritance_and_unsafe_paths_and_loads_sidecars(self) -> None:
        with self.assertRaises(CompileError):
            validate_package_descriptor({
                "schema": PACKAGE_DESCRIPTOR_SCHEMA,
                "extends": "other.json",
            })
        with self.assertRaises(CompileError):
            parse_predicate_expr("private.secret == true")

        sidecars = {
            "text/EN/command.camp.json": {"variants": {"neutral": ["Okay, setting up camp."]}},
            "text/TL/command.camp.json": {"variants": {"neutral": ["Sige, magtatayo ng kampo."]}},
        }
        pkg = {
            "schema": PACKAGE_DESCRIPTOR_SCHEMA,
            "defaultOwner": "ProjectHoomans",
            "defaults": {"participants": {"speaker": ["participant"], "addressee": ["participant"]}},
            "profiles": {},
        }
        compact_dlg = {
            "schema": COMPACT_PSDL_SCHEMA,
            "id": "command.camp",
            "textSidecars": {
                "EN": "text/EN/command.camp.json",
                "TL": "text/TL/command.camp.json",
            },
        }
        expanded = expand_compact_psdl_document(
            compact_dlg,
            package=pkg,
            text_loader=lambda p: sidecars[p],
        )
        compiled = compile_convo_engine_document(expanded)
        self.assertEqual(compiled["records"][0]["id"], "command.camp")

    def test_g8b_g8c_g8d_g8e_portable_runtime_profanity_camp_abi_and_inspect(self) -> None:
        records = []
        # 1. Profanity recognition & projection
        profanity_doc = compile_convo_engine_document({
            "schema": COMPACT_PSDL_SCHEMA,
            "id": "social.profanity",
            "owner": "PsychopatzCore",
            "recognition": {
                "packID": "social.profanity",
                "version": 1,
                "patterns": [
                    {
                        "id": "pnc.social.profanity",
                        "policy": "exact",
                        "phrases": ["fuck", "fuck you", "asshole"],
                        "semantic": {"intent": "INSULT", "speechAct": "INSULT"},
                    }
                ],
            },
            "say": {"EN": "Watch your mouth.", "TL": "Ingat sa pananalita mo."},
        })["records"]
        records.extend(profanity_doc)

        # 2. Camp command with typed capability ABI & reply outcomes (no PZ geometry)
        camp_doc = compile_convo_engine_document({
            "schema": COMPACT_PSDL_SCHEMA,
            "id": "command.camp",
            "owner": "SyntheticAdopter",
            "requiredCapabilities": ["companion.camp"],
            "metadata": {
                "recognitionPolicy": "safe_recovered",
                "utterances": {"positives": ["set up camp here"]},
                "emit": {"intent": "REQUEST", "action": "CAMP"},
            },
            "action": {"capability": "companion.camp", "mode": "immediate"},
            "say": {"EN": "Setting up camp.", "TL": "Magtatayo ng kampo."},
            "reply": {
                "queued": {"say": {"EN": "Okay, I'll set up camp.", "TL": "Sige, magtatayo ako ng kampo."}},
                "rejected": {"say": {"EN": "I can't camp here.", "TL": "Hindi ako makakakampo rito."}},
            },
        })["records"]
        records.extend(camp_doc)

        # G8D: Target missing companion.camp fails closed and emits stub guidance
        incomplete_target = {
            "schema": TARGET_DESCRIPTOR_SCHEMA,
            "target": "minimal_target",
            "providedCapabilities": ["speech"],
            "providedResolvers": [],
        }
        with self.assertRaises(CompileError) as ctx:
            validate_target_capabilities(records, incomplete_target)
        self.assertIn("companion.camp", str(ctx.exception))
        guidance = generate_adapter_stub_guidance(records, incomplete_target)
        self.assertEqual(guidance["missingCapabilities"], ["companion.camp"])

        # G8D: Complete target passes
        full_target = {
            "schema": TARGET_DESCRIPTOR_SCHEMA,
            "target": "reference_target",
            "providedCapabilities": ["companion.camp"],
            "providedResolvers": [],
        }
        self.assertTrue(validate_target_capabilities(records, full_target)["ok"])

        # G8B & G8E: Compile portable plan and execute in Reference VM
        plan = compile_portable_plan(records, package="SyntheticAdopter")
        called_caps: list[str] = []

        def adapter(cap: str, _action: dict, _ctx: dict) -> dict:
            called_caps.append(cap)
            return {"outcome": "queued"}

        vm = PortableReferenceVM(plan, capability_adapter=adapter)
        prof_step = vm.step(utterance="fuck you")
        self.assertEqual(prof_step["recognition"]["semantic"]["speechAct"], "INSULT")
        self.assertEqual(prof_step["text"], "Watch your mouth.")

        # Exact camp command executes capability
        camp_exact = vm.step(utterance="set up camp here")
        self.assertEqual(camp_exact["actionOutcome"], "queued")
        self.assertEqual(camp_exact["text"], "Okay, I'll set up camp.")
        self.assertEqual(called_caps, ["companion.camp"])

        # Fuzzy typo on safe_recovered mutating action requires confirmation & does NOT execute
        camp_fuzzy = vm.step(utterance="set up cmpp here")
        self.assertEqual(camp_fuzzy["recognition"]["mode"], "fuzzy")
        self.assertEqual(camp_fuzzy["actionOutcome"], "confirmation_required")
        self.assertEqual(len(called_caps), 1)

        # G8E: Progressive-disclosure inspection
        summary = inspect_psdl(records, {}, record_id="command.camp", mode="summary")
        self.assertEqual(summary["requiredCapabilities"], ["companion.camp"])
        self.assertEqual(summary["outcomes"], ["queued", "rejected"])
        self.assertNotIn("Okay, I'll set up camp.", json.dumps(summary))

    def test_g8f_clean_rebuild_and_second_noop(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            build1 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(build1["clean"])
            self.assertGreater(len(build1["writtenFiles"]), 0)

            build2 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(build2["clean"])
            self.assertEqual(build2["writtenFiles"], [])
            self.assertEqual(build2["prunedFiles"], [])

            check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(check["clean"])


if __name__ == "__main__":
    unittest.main()
