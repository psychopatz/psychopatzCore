"""S1 actor-neutral IR and shared predicate contract tests."""

from __future__ import annotations

import copy
import unittest

from tools.semantic_harness.codebuilder import (
    CompileError,
    canonical_ir_fingerprint,
    canonicalize_dialogue,
    normalize_predicate,
    validate_canonical_ir,
    validate_context_path,
)


class SemanticDialogueIRTests(unittest.TestCase):
    def test_friendly_and_explicit_predicates_share_one_normal_form(self) -> None:
        friendly = normalize_predicate({
            "speaker.traits": {"contains": "Brave"},
            "relationship.speakerToAddressee.approval": {">=": 30},
        })
        explicit = {
            "all": [
                {"path": "relationship.speakerToAddressee.approval", "op": "gte", "value": 30},
                {"path": "speaker.traits", "op": "contains", "value": "Brave"},
            ]
        }
        self.assertEqual(
            {item["path"] for item in friendly["all"]},
            {item["path"] for item in explicit["all"]},
        )
        self.assertEqual(
            {item["op"] for item in friendly["all"]},
            {"contains", "gte"},
        )
        collection = normalize_predicate({
            "speaker.capabilities": {"contains_all": ["trade", "guard"]},
        })
        self.assertEqual(collection["op"], "contains_all")
        self.assertEqual(collection["values"], ["trade", "guard"])

    def test_actor_neutral_ir_is_stable_when_source_path_changes(self) -> None:
        source = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "id": "social.ask_person_location",
            "owner": "ProjectHoomans",
            "participants": {"speaker": ["player", "npc"], "addressee": ["player", "npc"]},
            "target": {"type": "entity.person", "required": True},
            "slots": {"person": {"type": "entity.person", "required": True}},
            "references": {"known_location": {"type": "entity.location"}},
            "when": {
                "all": [
                    {"path": "speaker.knowledge", "op": "exists"},
                    {"path": "speaker.traits", "op": "contains", "value": "Brave"},
                ]
            },
            "response": {"act": "ANSWER_LOCATION"},
        }
        left = canonicalize_dialogue(source, source_path="content/dialogue.json")
        right = canonicalize_dialogue(source, source_path="other/dialogue.json")
        self.assertTrue(validate_canonical_ir(left))
        self.assertEqual(left["id"], "social.ask_person_location")
        self.assertEqual(left["participants"], right["participants"])
        self.assertEqual(canonical_ir_fingerprint(left), canonical_ir_fingerprint(right))
        self.assertEqual(left["target"]["type"], "entity.person")
        self.assertEqual(left["slots"]["person"]["type"], "entity.person")

    def test_public_context_rejects_private_and_actor_specific_paths(self) -> None:
        for path in (
            "speaker.name",
            "addressee.identity.gender",
            "relationship.addresseeToSpeaker.respect",
            "slot.person.name",
            "reference.event.location",
        ):
            self.assertEqual(validate_context_path(path), path)
        for path in ("npcName", "speaker.private.secret", "java.actor", "slot"):
            with self.assertRaises(CompileError):
                validate_context_path(path)

    def test_invalid_type_and_predicate_operator_fail_closed(self) -> None:
        with self.assertRaises(CompileError):
            canonicalize_dialogue({
                "schema": "psychopatz.convo-engine.v1",
                "kind": "dialogue",
                "id": "social.bad",
                "owner": "DTCommon",
                "slots": {"person": {"type": "npc_name"}},
            })
        with self.assertRaises(CompileError):
            normalize_predicate({"speaker.traits": {"contains_any": []}})
        with self.assertRaises(CompileError):
            normalize_predicate({"speaker.traits": {"edit_distance": 2}})
        with self.assertRaises(CompileError):
            normalize_predicate({"speaker.traits": {"contains": {"nested": True}}})
        with self.assertRaises(CompileError):
            normalize_predicate({"speaker.traits": {"contains_all": ["a"] * 9}})
        with self.assertRaises(CompileError):
            normalize_predicate({"speaker.traits": {"op": "contains", "path": "java.actor", "value": "x"}})

    def test_normalization_does_not_mutate_source(self) -> None:
        source = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "id": "social.greeting.basic",
            "owner": "PsychopatzCore",
            "when": {"speaker.traits": {"contains": "Brave"}},
        }
        before = copy.deepcopy(source)
        canonicalize_dialogue(source, source_path="dialogue/greeting.json")
        self.assertEqual(source, before)


if __name__ == "__main__":
    unittest.main()
