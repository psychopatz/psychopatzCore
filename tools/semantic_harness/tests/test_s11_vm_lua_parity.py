"""S11A3 tests: Reference VM <-> PZ/Lua backend structural parity."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_probe import ConvoProbe
from tools.semantic_harness.codebuilder.portable_runtime import (
    PortableReferenceVM,
    compile_portable_plan,
)
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.workspace_catalog import WorkspaceCatalog

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _compile_plan(records: list[dict]) -> dict:
    compiled = compile_convo_engine_document(
        {"schema": CONVO_ENGINE_SCHEMA, "owner": "PsychopatzCore", "records": records}
    )
    return compile_portable_plan(compiled["records"], package="test")


class S11VmLuaParityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
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

    def _assert_vm_lua_parity(
        self,
        plan: dict,
        dialogue_id: str,
        *,
        context: dict | None = None,
        role_bindings: dict | None = None,
        participant_set: dict | None = None,
        reply_outcome: str | None = None,
    ) -> dict:
        vm = PortableReferenceVM(plan)
        vm_eval = vm.evaluate_s11_family(
            dialogue_id,
            context=context,
            role_bindings=role_bindings,
            participant_set=participant_set,
            reply_outcome=reply_outcome,
        )
        lua_resp = self.probe.evaluate_s11_family(
            plan["dialogues"][dialogue_id],
            context=context,
            role_bindings=role_bindings,
            participant_set=participant_set,
            reply_outcome=reply_outcome,
        )
        self.assertTrue(lua_resp.get("ok"), lua_resp)
        lua_eval = lua_resp["evaluation"]
        self.assertEqual(vm_eval["roleValidation"], lua_eval["roleValidation"])
        self.assertEqual(vm_eval["stateOutcome"], lua_eval["stateOutcome"])
        self.assertEqual(vm_eval["queries"], lua_eval["queries"])
        self.assertEqual(vm_eval["consequences"], lua_eval["consequences"])
        return vm_eval

    def test_state_policy_and_step_noop_parity(self) -> None:
        plan = _compile_plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "one_to_one_state_action",
                    "roles": {
                        "speaker": {"cardinality": "ONE", "kinds": ["actor"]},
                        "addressee": {"cardinality": "ONE", "kinds": ["actor"]},
                    },
                    "inputPolicy": "typed_parity",
                    "repeatPolicy": "state_retired",
                    "statePolicy": [
                        {
                            "id": "already_active",
                            "when": {"path": "addressee.state", "op": "==", "value": "active"},
                            "outcome": "already_satisfied",
                            "reason": "already_active",
                            "admission": "no_op",
                            "replyOutcome": "already_done",
                        },
                        {
                            "id": "dispatch_ready",
                            "outcome": "actionable",
                            "reason": "ready",
                            "admission": "dispatch",
                        },
                    ],
                    "postconditions": ["addressee.state_active"],
                    "action": {"capability": "test.activate"},
                    "recognition": {
                        "packID": "test.activate_pack",
                        "patterns": [{"id": "test.activate_pat", "policy": "exact", "patterns": ["activate"]}],
                    },
                    "say": "Activate.",
                    "reply": {
                        "already_done": {"say": "Already active."},
                        "accepted": {"say": "Activated."},
                    },
                }
            ]
        )
        roles = {
            "speaker": [{"id": "player", "kind": "actor"}],
            "addressee": [{"id": "npc_1", "kind": "actor"}],
        }
        # 1. Already satisfied -> no_op parity
        eval_noop = self._assert_vm_lua_parity(
            plan,
            "test.one_to_one_state_action",
            context={"addressee": {"state": "active"}},
            role_bindings=roles,
        )
        self.assertEqual(eval_noop["stateOutcome"]["admission"], "no_op")
        self.assertEqual(eval_noop["stateOutcome"]["replyOutcome"], "already_done")

        # Reference VM step must short-circuit with zero capability_adapter calls
        dispatches: list[str] = []
        vm = PortableReferenceVM(
            plan,
            capability_adapter=lambda cap, action, ctx: dispatches.append(cap) or {"outcome": "accepted"},
        )
        step_noop = vm.step(
            utterance="activate",
            context={"addressee": {"state": "active"}},
        )
        self.assertEqual(dispatches, [])
        self.assertEqual(step_noop["actionOutcome"], "already_done")
        self.assertEqual(step_noop["text"], "Already active.")

        # 2. Actionable -> dispatch parity
        eval_ready = self._assert_vm_lua_parity(
            plan,
            "test.one_to_one_state_action",
            context={"addressee": {"state": "idle"}},
            role_bindings=roles,
        )
        self.assertEqual(eval_ready["stateOutcome"]["admission"], "dispatch")
        step_ready = vm.step(
            utterance="activate",
            context={"addressee": {"state": "idle"}},
        )
        self.assertEqual(dispatches, ["test.activate"])
        self.assertEqual(step_ready["actionOutcome"], "accepted")

    def test_role_cardinality_and_optional_mediator_parity(self) -> None:
        plan = _compile_plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "optional_mediator_group",
                    "roles": {
                        "speaker": {"cardinality": "ONE", "kinds": ["actor"]},
                        "target": {"cardinality": "ONE_OR_MORE", "kinds": ["actor"]},
                        "mediator": {"cardinality": "OPTIONAL_ONE", "kinds": ["actor"]},
                        "audience": {"cardinality": "BOUNDED_MANY", "min": 0, "max": 2, "kinds": ["actor"]},
                    },
                    "say": "Settle down.",
                    "reply": {"calmed": {"say": "Okay."}},
                }
            ]
        )
        # Valid without optional mediator
        valid_no_med = self._assert_vm_lua_parity(
            plan,
            "test.optional_mediator_group",
            role_bindings={
                "speaker": [{"id": "s1", "kind": "actor"}],
                "target": [{"id": "t1", "kind": "actor"}, {"id": "t2", "kind": "actor"}],
                "audience": [{"id": "a1", "kind": "actor"}],
            },
        )
        self.assertTrue(valid_no_med["roleValidation"]["ok"])

        # Invalid: audience exceeds max=2
        invalid_aud = self._assert_vm_lua_parity(
            plan,
            "test.optional_mediator_group",
            role_bindings={
                "speaker": [{"id": "s1", "kind": "actor"}],
                "target": [{"id": "t1", "kind": "actor"}],
                "audience": [
                    {"id": "a1", "kind": "actor"},
                    {"id": "a2", "kind": "actor"},
                    {"id": "a3", "kind": "actor"},
                ],
            },
        )
        self.assertFalse(invalid_aud["roleValidation"]["ok"])
        self.assertIn("BOUNDED_MANY", invalid_aud["roleValidation"]["reason"])

    def test_queries_effects_timed_modifiers_and_closure_parity(self) -> None:
        plan = _compile_plan(
            [
                {
                    "kind": "dialogue",
                    "namespace": "test",
                    "id": "semantic_episode_with_obligation",
                    "queries": [
                        {"id": "has_bandage", "path": "inventory.actor.bandage_count", "op": "gte", "value": 1}
                    ],
                    "modifiers": [
                        {
                            "id": "rel_penalty",
                            "domain": "relationship",
                            "field": "trust",
                            "delta": -5,
                            "retention": {"kind": "TIMED", "duration": "7d"},
                            "stacking": "refresh",
                            "targetRole": "addressee",
                        }
                    ],
                    "closure": {
                        "closureClass": "open_domain_obligation",
                        "episodeId": "ep_aid",
                        "retention": {"kind": "TIMED", "duration": "30d"},
                        "obligationRef": "task:deliver_bandage",
                    },
                    "say": "Take this.",
                    "reply": {
                        "accepted": {
                            "say": "Thanks.",
                            "effects": [{"type": "consume_item", "targetRole": "actor", "params": {"count": 1}}],
                            "closure": {"closureClass": "resolved_episode", "episodeId": "ep_aid"},
                        }
                    },
                }
            ]
        )
        eval_res = self._assert_vm_lua_parity(
            plan,
            "test.semantic_episode_with_obligation",
            context={"inventory": {"actor": {"bandage_count": 2}}},
            reply_outcome="accepted",
        )
        self.assertTrue(eval_res["queries"][0]["passed"])
        self.assertEqual(eval_res["consequences"]["modifiers"][0]["retention"]["durationMinutes"], 10080)
        self.assertEqual(eval_res["consequences"]["closure"]["closureClass"], "resolved_episode")
        self.assertEqual(len(eval_res["consequences"]["effects"]), 1)


if __name__ == "__main__":
    unittest.main()
