"""S11A2 tests: canonical compact source -> Canonical IR -> Portable Dialogue Plan.

Uses synthetic/minimal fixtures only (no production dialogue migration).
"""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.portable_runtime import (
    compile_portable_plan,
    portable_plan_records,
)
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import (
    CONVO_ENGINE_SCHEMA,
    canonical_ir_fingerprint,
    validate_canonical_ir,
)


def _doc(record: dict) -> dict:
    return {
        "schema": CONVO_ENGINE_SCHEMA,
        "owner": "PsychopatzCore",
        "records": [record],
    }


class ConvoEngineSourceToPortablePlanTests(unittest.TestCase):
    def test_synthetic_one_to_one_state_action_and_roundtrip(self) -> None:
        source = {
            "kind": "dialogue",
            "namespace": "test",
            "id": "one_to_one_state_action",
            "archetype": "one_to_one_state_action",
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
            "continuation": "close",
            "closure": {"closureClass": "state_transition"},
            "say": "Activate now.",
            "reply": {
                "already_done": {"say": "Already active."},
                "accepted": {"say": "Activating."},
            },
        }
        compiled = compile_convo_engine_document(_doc(source))
        ir_rec = compiled["records"][0]
        self.assertTrue(validate_canonical_ir(ir_rec))
        self.assertEqual(ir_rec["roles"]["speaker"]["cardinality"], "ONE")
        self.assertEqual(ir_rec["payload"]["inputPolicy"], "typed_parity")
        self.assertEqual(ir_rec["payload"]["repeatPolicy"], "state_retired")
        self.assertEqual(len(ir_rec["payload"]["statePolicy"]), 2)
        self.assertEqual(ir_rec["payload"]["closure"]["closureClass"], "state_transition")

        plan = compile_portable_plan(compiled["records"], package="test")
        entry = plan["dialogues"]["test.one_to_one_state_action"]
        self.assertEqual(entry["roles"]["addressee"]["cardinality"], "ONE")
        self.assertEqual(entry["statePolicy"][0]["admission"], "no_op")
        self.assertEqual(entry["postconditions"], ["addressee.state_active"])

        roundtrip = portable_plan_records(plan)
        self.assertEqual(roundtrip[0]["roles"], ir_rec["roles"])
        self.assertEqual(roundtrip[0]["payload"]["statePolicy"], ir_rec["payload"]["statePolicy"])

    def test_group_argument_and_optional_mediator_roles(self) -> None:
        source = {
            "kind": "dialogue",
            "namespace": "test",
            "id": "optional_mediator_group",
            "archetype": "group_mediation",
            "participantSet": {
                "maxSize": 5,
                "participants": [
                    {"id": "p_speaker", "kind": "actor", "role": "speaker"},
                    {"id": "p_target", "kind": "actor", "role": "target"},
                ],
            },
            "roles": {
                "speaker": {"cardinality": "ONE", "kinds": ["actor"]},
                "target": {"cardinality": "ONE_OR_MORE", "kinds": ["actor"]},
                "mediator": {"cardinality": "OPTIONAL_ONE", "kinds": ["actor"]},
                "audience": {"cardinality": "BOUNDED_MANY", "min": 0, "max": 3, "kinds": ["actor"]},
            },
            "activities": [{"id": "patrol", "role": "mediator"}],
            "say": "Settle down.",
            "reply": {"calmed": {"say": "Understood."}},
        }
        compiled = compile_convo_engine_document(_doc(source))
        ir_rec = compiled["records"][0]
        self.assertEqual(ir_rec["participantSet"]["maxSize"], 5)
        self.assertEqual(ir_rec["roles"]["mediator"]["cardinality"], "OPTIONAL_ONE")
        self.assertEqual(ir_rec["roles"]["audience"]["max"], 3)
        self.assertEqual(ir_rec["payload"]["activities"], [{"id": "patrol", "role": "mediator"}])

        plan = compile_portable_plan(compiled["records"], package="test")
        entry = plan["dialogues"]["test.optional_mediator_group"]
        self.assertEqual(entry["participantSet"]["maxSize"], 5)
        self.assertEqual(entry["roles"]["target"]["cardinality"], "ONE_OR_MORE")

    def test_inventory_gated_timed_modifiers_and_semantic_episode(self) -> None:
        source = {
            "kind": "dialogue",
            "namespace": "test",
            "id": "semantic_episode_with_obligation",
            "queries": [
                {"id": "has_bandage", "path": "inventory.actor.bandage_count", "op": ">=", "value": 1}
            ],
            "effects": [
                {"type": "consume_item", "targetRole": "actor", "params": {"item": "Base.Bandage", "count": 1}}
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
                },
                {
                    "id": "mood_boost",
                    "domain": "mood",
                    "field": "morale",
                    "delta": 4,
                    "retention": {"kind": "TIMED", "duration": "6h"},
                    "stacking": "stack",
                    "targetRole": "speaker",
                },
            ],
            "closure": {
                "closureClass": "open_domain_obligation",
                "episodeId": "ep_aid",
                "retention": {"kind": "TIMED", "duration": "30d"},
                "obligationRef": "task:deliver_bandage",
            },
            "topics": ["medical_aid"],
            "events": [{"id": "aid_promised", "kind": "semantic_event"}],
            "memories": ["helped_injured"],
            "domains": [{"domain": "relationship", "owner": "ProjectHoomans"}],
            "say": "Take this bandage.",
            "reply": {
                "accepted": {
                    "say": "Thank you.",
                    "effects": [{"type": "record_promise", "targetRole": "speaker", "params": {"id": "ep_aid"}}],
                    "closure": {"closureClass": "resolved_episode", "episodeId": "ep_aid"},
                }
            },
        }
        compiled = compile_convo_engine_document(_doc(source))
        ir_rec = compiled["records"][0]
        payload = ir_rec["payload"]
        self.assertEqual(payload["modifiers"][0]["retention"]["durationMinutes"], 7 * 24 * 60)
        self.assertEqual(payload["modifiers"][1]["retention"]["durationMinutes"], 6 * 60)
        self.assertEqual(payload["closure"]["retention"]["durationMinutes"], 30 * 24 * 60)
        self.assertEqual(payload["queries"][0]["path"], "inventory.actor.bandage_count")
        self.assertEqual(payload["reply"]["accepted"]["closure"]["closureClass"], "resolved_episode")

        # Source-path independence of IR fingerprint.
        compiled_other = compile_convo_engine_document(
            _doc(source), source_path="other/path.json"
        )
        self.assertEqual(
            canonical_ir_fingerprint(ir_rec),
            canonical_ir_fingerprint(compiled_other["records"][0]),
        )

    def test_rejects_positional_roles_and_private_query_paths(self) -> None:
        bad_role = {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_role",
            "roles": {"actor1": {"cardinality": "ONE", "kinds": ["actor"]}},
            "say": "Hello.",
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_document(_doc(bad_role))

        bad_query = {
            "kind": "dialogue",
            "namespace": "test",
            "id": "bad_query",
            "queries": [{"id": "leak", "path": "actor.private.secret"}],
            "say": "Hello.",
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_document(_doc(bad_query))


if __name__ == "__main__":
    unittest.main()
