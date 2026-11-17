"""G8R7A–G8R7C: Descriptor-selected backend dispatch, executed Reference VM <-> Lua ConvoProbe
trace equivalence, and authored-vs-canonical source lineage tests."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.backend_registry import (
    list_backends,
    render_portable_plan_for_target,
    resolve_backend,
    temporary_backend,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.codebuilder.convo_probe import ConvoProbe
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.generation_ownership import (
    OwnerConfigurationError,
    combined_target_descriptor,
    temporary_package_descriptors,
)
from tools.semantic_harness.codebuilder.portable_runtime import (
    PORTABLE_PLAN_SCHEMA,
    PortableReferenceVM,
    portable_plan_records,
)
from tools.semantic_harness.codebuilder.psdl_compact import (
    COMPACT_PSDL_SCHEMA,
    PACKAGE_DESCRIPTOR_SCHEMA,
    PROVENANCE_LOCK_SCHEMA,
)
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.semantic_trace import (
    SEMANTIC_TRACE_SCHEMA,
    normalized_trace_comparison_key,
    trace_from_lua_probe,
    trace_from_reference_vm,
)
from tools.semantic_harness.codebuilder.workspace_catalog import WorkspaceCatalog

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


class PsdlBackendPortabilityAndTraceEquivalenceTests(unittest.TestCase):
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
        cls.runtime_plans_by_id = {
            p["id"]: p for p in cls.model["psdlRuntimePlans"]
        }
        cls.snapshot = WorkspaceCatalog.discover(
            CORE_ROOT,
            core_repository=CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        cls.probe = ConvoProbe(cls.snapshot)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.probe.close()

    def test_descriptor_selected_backend_dispatch(self) -> None:
        self.assertIn("pz-lua", list_backends())
        self.assertIn("portable-json", list_backends())
        self.assertEqual(self.model["targetBackend"], "pz-lua")

        # Unknown backend fails closed
        with self.assertRaises(CompileError):
            resolve_backend("nonexistent-engine")
        with self.assertRaises(CompileError):
            render_portable_plan_for_target(
                self.portable_plan,
                target_descriptor={
                    "schema": "psychopatz.psdl.target.v1",
                    "target": "Broken",
                    "backend": "nonexistent-engine",
                },
            )

        # Incompatible backends fail closed when combined
        with temporary_package_descriptors(
            {
                "PortablePackage": {
                    "owner": "PortablePackage",
                    "backend": "portable-json",
                    "sharedLuaRelative": "lua",
                    "conversationPrefix": "Portable/ConvoEngine",
                    "translationRelative": "translation",
                }
            }
        ):
            with self.assertRaises(OwnerConfigurationError):
                combined_target_descriptor(["PsychopatzCore", "PortablePackage"])

        # Normal production compiler selects non-PZ backend through descriptor with 0 compiler edits
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp)
            adopter_repo = ws / "PortableDemo"
            src_root = adopter_repo / "tools/semantic_harness/codebuilder/sources/conversation"
            (src_root / "dialogue/demo").mkdir(parents=True)
            (src_root / "package.json").write_text(
                json.dumps(
                    {
                        "schema": PACKAGE_DESCRIPTOR_SCHEMA,
                        "version": 1,
                        "package": "PortableDemo",
                        "defaultOwner": "PortableDemo",
                        "registryOwner": "PortableDemo",
                        "defaults": {
                            "participants": {"speaker": ["participant"], "addressee": ["participant"]}
                        },
                        "profiles": {},
                        "sourceRoots": [
                            {
                                "path": "dialogue",
                                "kind": "convo_engine",
                                "domain": "demo",
                                "order": 100,
                                "owner": "PortableDemo",
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
                        "sourceProfiles": {"default": {"owner": "PortableDemo", "version": "1"}},
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            (src_root / "dialogue/demo/hello.json").write_text(
                json.dumps(
                    {
                        "schema": COMPACT_PSDL_SCHEMA,
                        "id": "demo.hello",
                        "metadata": {"category": "demo:greeting", "responseAct": "GREET"},
                        "say": {"variants": [{"id": "neutral", "text": {"EN": ["Hello."]}}]},
                    },
                    indent=2,
                ),
                encoding="utf-8",
            )
            with temporary_package_descriptors(
                {
                    "PortableDemo": {
                        "owner": "PortableDemo",
                        "backend": "portable-json",
                        "sharedLuaRelative": "lua",
                        "conversationPrefix": "PortableDemo/ConvoEngine",
                        "translationRelative": "translation",
                        "isDefaultProject": True,
                        "capabilities": ["speech"],
                    }
                }
            ):
                compiled = compile_conversation_sources(
                    adopter_repo,
                    manifest_path=src_root / "package.json",
                    package_repositories={"PortableDemo": adopter_repo},
                )
                self.assertEqual(compiled["targetBackend"], "portable-json")
                self.assertIn("portable_plan.json", compiled["portableArtifacts"])
                self.assertEqual(
                    compiled["portableArtifacts"]["portable_plan.json"]["schema"],
                    PORTABLE_PLAN_SCHEMA,
                )

    def test_executed_reference_vm_vs_lua_convo_probe_equivalence(self) -> None:
        # 1. Exact profanity + beat.argument_escalation + behavior.retaliate_verbally
        vm = PortableReferenceVM(self.portable_plan)
        hostile_ctx = {
            "stimulus": {"type": "HUMAN_UTTERANCE"},
            "actor": {"disposition": {"aggression": 0.9}, "condition": {"panic": 0.0}},
            "history": {"hostilityCount": 1},
        }
        ref_prof = trace_from_reference_vm(
            vm,
            utterance="you are an ass",
            context=hostile_ctx,
        )
        lua_prof = trace_from_lua_probe(
            self.probe,
            portable_plan=self.portable_plan,
            runtime_plans_by_id=self.runtime_plans_by_id,
            utterance="you are an ass",
            context=hostile_ctx,
        )
        self.assertEqual(ref_prof["schema"], SEMANTIC_TRACE_SCHEMA)
        self.assertEqual(ref_prof["recognition"]["ruleID"], "pnc.social.profanity_you")
        self.assertEqual(ref_prof["activeBeat"], "beat.argument_escalation")
        self.assertEqual(ref_prof["selectedBehavior"], "behavior.retaliate_verbally")
        self.assertEqual(
            normalized_trace_comparison_key(ref_prof),
            normalized_trace_comparison_key(lua_prof),
        )

        # 2. Real command.camp result branching (queued / rejected / failed)
        for outcome in ("queued", "rejected", "failed"):
            ref_camp = trace_from_reference_vm(
                PortableReferenceVM(self.portable_plan),
                context={"stimulus": {"type": "HUMAN_UTTERANCE"}},
                dialogue_id="command.camp",
                result_outcome=outcome,
                style="neutral",
            )
            lua_camp = trace_from_lua_probe(
                self.probe,
                portable_plan=self.portable_plan,
                runtime_plans_by_id=self.runtime_plans_by_id,
                context={"stimulus": {"type": "HUMAN_UTTERANCE"}},
                dialogue_id="command.camp",
                result_outcome=outcome,
                style="neutral",
            )
            self.assertEqual(ref_camp["action"], "hoomans.camp.establish")
            self.assertEqual(ref_camp["resultOutcome"], outcome)
            self.assertEqual(
                normalized_trace_comparison_key(ref_camp),
                normalized_trace_comparison_key(lua_camp),
            )

        # 3. Deterministic realization/template identity (question.knowledge -> known)
        ref_know = trace_from_reference_vm(
            PortableReferenceVM(self.portable_plan),
            context={"stimulus": {"type": "HUMAN_UTTERANCE"}},
            dialogue_id="question.knowledge",
            result_outcome="known",
            style="neutral",
        )
        lua_know = trace_from_lua_probe(
            self.probe,
            portable_plan=self.portable_plan,
            runtime_plans_by_id=self.runtime_plans_by_id,
            context={"stimulus": {"type": "HUMAN_UTTERANCE"}},
            dialogue_id="question.knowledge",
            result_outcome="known",
            style="neutral",
        )
        self.assertEqual(
            normalized_trace_comparison_key(ref_know),
            normalized_trace_comparison_key(lua_know),
        )

        # 4. Fuzzy mutating confirmation safety equivalence
        camp_plan = {
            "schema": PORTABLE_PLAN_SCHEMA,
            "runtimeVersion": "1.0.0",
            "package": "ProjectHoomans",
            "dialogues": {"command.camp": self.portable_plan["dialogues"]["command.camp"]},
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
        ref_fuzzy = trace_from_reference_vm(
            PortableReferenceVM(camp_plan),
            utterance="set up cmp",
            dialogue_id="command.camp",
            result_outcome="queued",
        )
        lua_fuzzy = trace_from_lua_probe(
            self.probe,
            portable_plan=camp_plan,
            runtime_plans_by_id=self.runtime_plans_by_id,
            utterance="set up cmp",
            dialogue_id="command.camp",
            result_outcome="queued",
        )
        self.assertEqual(ref_fuzzy["recognition"]["mode"], "fuzzy")
        self.assertTrue(ref_fuzzy["recognition"]["requiresConfirmation"])
        self.assertEqual(
            normalized_trace_comparison_key(ref_fuzzy),
            normalized_trace_comparison_key(lua_fuzzy),
        )

    def test_authored_vs_canonical_source_lineage(self) -> None:
        records_by_id = {
            r["id"]: r for r in portable_plan_records(self.portable_plan)
        }
        for rec_id in (
            "command.camp",
            "behavior.retaliate_verbally",
            "beat.argument_escalation",
            "lexeme.social.profanity.fuck",
        ):
            rec = records_by_id[rec_id]
            lineage = rec["lineage"]
            self.assertEqual(lineage["authoringSchema"], COMPACT_PSDL_SCHEMA)
            self.assertEqual(lineage["canonicalSchema"], CONVO_ENGINE_SCHEMA)
            self.assertEqual(lineage["sourceSchema"], COMPACT_PSDL_SCHEMA)
            self.assertTrue(str(lineage.get("sourcePath") or "").endswith(".json"))

        # Compatibility verbose psychopatz.convo-engine.v1 input still reports truthful authored schema
        compat_compiled = compile_convo_engine_document(
            {
                "schema": CONVO_ENGINE_SCHEMA,
                "kind": "dialogue",
                "namespace": "demo",
                "id": "verbose_sample",
                "owner": "PsychopatzCore",
                "participants": {"speaker": ["participant"], "addressee": ["participant"]},
                "say": {"variants": [{"id": "neutral", "text": {"EN": ["Compat."]}}]},
            },
            source_path="dialogue/demo/verbose_sample.json",
        )
        compat_lineage = compat_compiled["records"][0]["lineage"]
        self.assertEqual(compat_lineage["authoringSchema"], CONVO_ENGINE_SCHEMA)
        self.assertEqual(compat_lineage["canonicalSchema"], CONVO_ENGINE_SCHEMA)
        self.assertEqual(compat_lineage["sourceSchema"], CONVO_ENGINE_SCHEMA)
