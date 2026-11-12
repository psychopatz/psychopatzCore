"""S2 Core-owned PSDL compiler and language-validation tests."""

from __future__ import annotations

import copy
import unittest

from tools.semantic_harness.codebuilder import CompileError
from tools.semantic_harness.codebuilder.psdl_compiler import (
    PSDL_COMPILED_SCHEMA,
    compile_psdl_document,
    compile_psdl_sources,
    render_psdl_runtime_plan,
)


def _catalog() -> dict:
    return {
        "schema": "psychopatz.semantic.dialogue-language.v1",
        "records": [
            {
                "kind": "behavior",
                "id": "behavior.social.warn",
                "owner": "ProjectHoomans",
                "stimuli": ["NPC_SEMANTIC_ACT"],
                "act": "BOUNDARY_WARNING",
                "when": {"pragmatic.admitted": {"truthy": True}},
            },
            {
                "kind": "beat",
                "id": "beat.social.argument",
                "owner": "ProjectHoomans",
                "entry": {"stimulus.semantic.speechAct": {"in": ["THREATEN"]}},
                "candidates": [{"behavior": "behavior.social.warn", "relevance": 0.65}],
                "cooldownTurns": 3,
                "maxTurns": 6,
            },
            {
                "kind": "dialogue",
                "id": "social.location.ask",
                "owner": "ProjectHoomans",
                "participants": {"speaker": ["player", "npc"], "addressee": ["player", "npc"]},
                "target": {"type": "entity.location", "required": True},
                "slots": {"person": {"type": "entity.person", "required": True}},
                "bindings": {
                    "direction": {
                        "resolver": "spatial.direction",
                        "from": "target.position",
                        "type": "topic",
                    }
                },
                "when": {
                    "all": [
                        {"path": "speaker.knowledge", "op": "exists"},
                        {"relationship.speakerToAddressee.approval": {">=": 30}},
                    ]
                },
                "on": {"intent": "QUESTION", "subject": "PERSON_LOCATION"},
                "response": {
                    "act": "ANSWER_LOCATION",
                    "turns": [
                        {
                            "id": "answer",
                            "text": {
                                "EN": ["{slot.person.name} is {direction} of here."],
                                "TL": ["Si {slot.person.name} ay {direction} dito."],
                            },
                            "offers": [
                                {
                                    "id": "ask.direction",
                                    "label": {"EN": "Ask for directions", "TL": "Magtanong ng daan"},
                                    "utterance": {"EN": "Which way?", "TL": "Saan banda?"},
                                    "frame": {"intent": "QUESTION", "subject": "LOCATION_DIRECTION"},
                                    "consumers": ["participant"],
                                }
                            ],
                        }
                    ],
                },
            },
            {
                "kind": "realization",
                "id": "realization.social.acknowledge",
                "owner": "PsychopatzCore",
                "text": {"EN": ["I understand, {addressee.name}."], "TL": ["Naiintindihan ko, {addressee.name}."]},
            },
        ],
    }


class PSDLCompilerTests(unittest.TestCase):
    def test_catalog_compiles_to_one_core_ir_and_runtime_plan(self) -> None:
        compiled = compile_psdl_document(_catalog(), source_path="dialogue/social.json")
        self.assertEqual(compiled["schema"], PSDL_COMPILED_SCHEMA)
        self.assertEqual(
            [record["id"] for record in compiled["records"]],
            [
                "beat.social.argument",
                "behavior.social.warn",
                "realization.social.acknowledge",
                "social.location.ask",
            ],
        )
        dialogue = next(item for item in compiled["records"] if item["kind"] == "dialogue")
        self.assertEqual(dialogue["when"]["all"][1]["op"], "gte")
        self.assertEqual(dialogue["payload"]["response"]["turns"][0]["offers"][0]["consumers"], ["participant"])
        self.assertEqual(dialogue["payload"]["bindings"]["direction"]["resolver"], "spatial.direction")
        plans = render_psdl_runtime_plan(compiled)
        dialogue_plan = next(item for item in plans if item["id"] == "social.location.ask")
        self.assertEqual(dialogue_plan["owner"], "ProjectHoomans")
        self.assertTrue(dialogue_plan["module"].startswith("PNC/Semantics/Generated/Conversation/PSDL/"))
        self.assertEqual(dialogue_plan["responsePlan"]["schemaVersion"], 1)
        self.assertEqual(dialogue_plan["responsePlan"]["kind"], "dialogue_act_plan")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["segments"][0]["kind"], "translation")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["offers"][0]["labelFallback"], "Ask for directions")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["offers"][0]["consumers"], ["participant"])

    def test_compilation_is_deterministic_and_source_path_is_lineage_only(self) -> None:
        source = _catalog()
        left = compile_psdl_document(source, source_path="one.json")
        right = compile_psdl_document(source, source_path="two.json")
        self.assertEqual(
            [record["id"] for record in left["records"]],
            [record["id"] for record in right["records"]],
        )
        self.assertEqual(left["records"][0]["lineage"]["sourceId"], right["records"][0]["lineage"]["sourceId"])
        self.assertNotEqual(left["records"][0]["lineage"]["sourcePath"], right["records"][0]["lineage"]["sourcePath"])
        sources = {"b.json": source, "a.json": {"schema": source["schema"], "records": [copy.deepcopy(source["records"][-1])]}}
        with self.assertRaises(CompileError):
            compile_psdl_sources(sources)

    def test_translation_and_binding_validation_fails_closed(self) -> None:
        invalid = _catalog()
        invalid["records"] = [
            {
                "kind": "dialogue",
                "id": "social.bad_translation",
                "owner": "DTCommon",
                "response": {"text": {"EN": ["Hi {speaker.name}"], "TL": ["Kumusta"]}},
            }
        ]
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

        invalid["records"][0]["response"]["text"] = {"EN": ["Hi {unknown}" ]}
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

        invalid["records"][0]["response"]["text"] = {"EN": ["Hi {speaker.name}"]}
        invalid["records"][0]["bindings"] = {"x": {"resolver": "inline.lua", "from": "java.actor"}}
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

    def test_old_identity_and_beat_wording_are_rejected(self) -> None:
        invalid = {
            "schema": "psychopatz.semantic.dialogue-language.v1",
            "records": [
                {"kind": "dialogue", "id": "social.legacy.greeting", "owner": "ProjectHoomans"}
            ],
        }
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

        invalid["records"] = [
            {
                "kind": "beat",
                "id": "beat.social.test",
                "owner": "ProjectHoomans",
                "text": {"EN": ["wording does not belong to a beat"]},
                "candidates": [{"behavior": "behavior.social.missing"}],
            }
        ]
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

    def test_unknown_fields_and_cross_module_references_are_rejected(self) -> None:
        invalid = _catalog()
        invalid["records"][1]["candidates"][0]["behavior"] = "behavior.social.missing"
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)
        invalid = {
            "schema": "psychopatz.semantic.dialogue-language.v1",
            "kind": "dialogue",
            "id": "social.unknown",
            "owner": "ProjectHoomans",
            "notAField": True,
        }
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)


if __name__ == "__main__":
    unittest.main()
