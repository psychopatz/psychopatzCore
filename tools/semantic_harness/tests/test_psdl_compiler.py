"""Core-owned PSDL compiler and language-validation tests."""

from __future__ import annotations

import copy
from pathlib import Path
import unittest
from tempfile import TemporaryDirectory

from tools.semantic_harness.codebuilder import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.psdl_compiler import (
    PSDL_COMPILED_SCHEMA,
    compile_psdl_document,
    compile_psdl_sources,
    render_psdl_director_plan,
    render_psdl_semantic_pack_plan,
    render_psdl_ui_plan,
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
                "mode": "beat",
                "requiredCapabilities": ["speech"],
                "outputs": {
                    "speech": {
                        "dialogueAct": "BOUNDARY_WARNING",
                        "contentTemplateID": "semantic.social.boundary_warning",
                    }
                },
                "baseRelevance": 0.65,
                "modifiers": [
                    {
                        "delta": 0.1,
                        "reason": "admitted",
                        "when": {"pragmatic.admitted": {"truthy": True}},
                    }
                ],
                "when": {"pragmatic.admitted": {"truthy": True}},
            },
            {
                "kind": "beat",
                "id": "beat.social.argument",
                "owner": "ProjectHoomans",
                "stimuli": ["NPC_SEMANTIC_ACT"],
                "entry": {"stimulus.semantic.speechAct": {"in": ["THREATEN"]}},
                "maintain": {"history.hostilityCount": {">": 0}},
                "exit": {"scene.ended": {"truthy": True}},
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
    def test_core_authoring_service_mutates_and_validates_psdl_catalogs(self) -> None:
        repository = Path(__file__).resolve().parents[3]
        service = SemanticLabAuthoringService(
            repository=repository,
            core_repository=repository,
        )
        document = {
            "schema": "psychopatz.semantic.dialogue-language.v1",
            "records": [{
                "kind": "dialogue",
                "id": "social.authoring.seed",
                "owner": "ProjectHoomans",
                "participants": {
                    "speaker": ["participant"],
                    "addressee": ["participant"],
                },
                "response": {
                    "act": "REPLY",
                    "turns": [{
                        "id": "reply",
                        "text": {
                            "EN": "Hello, {addressee.name}.",
                            "TL": "Kumusta, {addressee.name}.",
                        },
                    }],
                },
            }],
        }
        created = service.create_psdl_record(
            document,
            {
                "kind": "dialogue",
                "id": "social.authoring.created",
                "owner": "ProjectHoomans",
                "participants": {
                    "speaker": ["participant"],
                    "addressee": ["participant"],
                },
                "response": {
                    "act": "REPLY",
                    "turns": [{"id": "reply", "text": {
                        "EN": "Welcome.", "TL": "Maligayang pagdating."
                    }}],
                },
            },
        )
        self.assertTrue(created["ok"])
        edited = service.edit_psdl_record(
            created["document"],
            "social.authoring.created",
            {"metadata": {"topic": "welcome"}},
        )
        self.assertTrue(edited["ok"])
        duplicated = service.duplicate_psdl_record(
            edited["document"],
            "social.authoring.created",
            "social.authoring.duplicate",
        )
        self.assertTrue(duplicated["ok"])
        reordered = service.reorder_psdl_records(
            duplicated["document"],
            [
                "social.authoring.duplicate",
                "social.authoring.seed",
                "social.authoring.created",
            ],
        )
        self.assertTrue(reordered["ok"])
        deleted = service.delete_psdl_record(
            reordered["document"],
            "social.authoring.duplicate",
        )
        self.assertTrue(deleted["ok"])
        self.assertEqual(
            [item["id"] for item in deleted["document"]["records"]],
            ["social.authoring.seed", "social.authoring.created"],
        )

        invalid = service.validate_psdl_document({
            "schema": "psychopatz.semantic.dialogue-language.v1",
            "records": [],
        })
        self.assertFalse(invalid["ok"])
        self.assertTrue(invalid["effectFree"])

        with TemporaryDirectory() as temporary:
            writable = SemanticLabAuthoringService(
                repository=Path(temporary),
                core_repository=repository,
            )
            written = writable.write_psdl_source(
                "dialogue/authoring/authoring.json",
                deleted["document"],
            )
            self.assertTrue(written["ok"])
            self.assertTrue(written["generatedOutputRequired"])
            self.assertTrue(
                (Path(temporary) / "dialogue/authoring/authoring.json").is_file()
            )

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
        self.assertTrue(dialogue_plan["module"].startswith("PNC/ConvoEngine/Dialogue/"))
        self.assertEqual(dialogue_plan["responsePlan"]["schemaVersion"], 1)
        self.assertEqual(dialogue_plan["responsePlan"]["kind"], "dialogue_act_plan")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["segments"][0]["kind"], "translation")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["offers"][0]["labelFallback"], "Ask for directions")
        self.assertEqual(dialogue_plan["responsePlan"]["turns"][0]["offers"][0]["consumers"], ["participant"])
        director_plan = render_psdl_director_plan(compiled)
        self.assertEqual([item["id"] for item in director_plan["behaviors"]], ["behavior.social.warn"])
        self.assertEqual([item["id"] for item in director_plan["beats"]], ["beat.social.argument"])
        self.assertEqual(director_plan["behaviors"][0]["outputs"]["speech"]["dialogueAct"], "BOUNDARY_WARNING")
        self.assertEqual(director_plan["beats"][0]["maintain"]["op"], "gt")
        self.assertNotIn("text", director_plan["behaviors"][0])
        self.assertNotIn("text", director_plan["beats"][0])

    def test_service_indexes_manifest_routed_psdl_sources_for_studio(self) -> None:
        workspace = Path(__file__).resolve().parents[3]
        hoomans = workspace.parent / "ProjectHoomans"
        dynamic_trading = workspace.parent / "DynamicTrading"
        service = SemanticLabAuthoringService(
            repository=hoomans,
            core_repository=workspace,
            dynamic_trading_repository=dynamic_trading,
        )
        sources = service.list_psdl_sources()
        self.assertGreaterEqual(len(sources), 3)
        self.assertEqual(
            {"PsychopatzCore", "ProjectHoomans", "DTCommon"},
            {item["owner"] for item in sources},
        )
        trading = next(
            item for item in sources if item["path"] == "adopters/dt/dialogue/trading/trade_conversation_suggestions.json"
        )
        self.assertTrue(trading["exists"])
        document = service.load_psdl_source(trading["sourceID"])
        self.assertEqual(document["schema"], "psychopatz.convo-engine.v1")
        self.assertEqual(document["kind"], "dialogue")
        self.assertEqual(document["namespace"], "trade.conversation")
        self.assertEqual(document["id"], "suggestions")

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

    def test_representative_social_beats_project_through_one_director_contract(self) -> None:
        source = _catalog()
        source["records"].extend(
            [
                {
                    "kind": "beat",
                    "id": "beat.social.reconciliation",
                    "owner": "ProjectHoomans",
                    "stimuli": ["NPC_SEMANTIC_ACT"],
                    "entry": {"stimulus.semantic.intent": {"in": ["APOLOGIZE"]}},
                    "maintain": {"history.hostilityCount": {">": 0}},
                    "exit": {"scene.ended": {"truthy": True}},
                    "candidates": [{"behavior": "behavior.social.warn", "relevance": 0.45}],
                    "group": "beat_group.social_primary",
                    "cooldownTurns": 2,
                    "maxTurns": 4,
                },
                {
                    "kind": "beat",
                    "id": "beat.social.suspicious_first_contact",
                    "owner": "ProjectHoomans",
                    "stimuli": ["NPC_SEMANTIC_ACT"],
                    "entry": {"stimulus.semantic.intent": {"in": ["INTRODUCE"]}},
                    "maintain": {"not": {"path": "scene.ended", "op": "truthy"}},
                    "exit": {"scene.ended": {"truthy": True}},
                    "candidates": [{"behavior": "behavior.social.warn", "relevance": 0.25}],
                    "group": "beat_group.social_primary",
                    "cooldownTurns": 1,
                    "maxTurns": 3,
                },
            ]
        )
        compiled = compile_psdl_document(source)
        director_plan = render_psdl_director_plan(compiled)
        self.assertEqual(
            [item["id"] for item in director_plan["beats"]],
            [
                "beat.social.argument",
                "beat.social.reconciliation",
                "beat.social.suspicious_first_contact",
            ],
        )
        self.assertTrue(
            all(item["stimuli"] == ["NPC_SEMANTIC_ACT"] for item in director_plan["beats"])
        )

    def test_semantic_offers_project_to_existing_ui_suggestion_rows(self) -> None:
        compiled = compile_psdl_document(
            {
                "schema": "psychopatz.semantic.dialogue-language.v1",
                "kind": "dialogue",
                "id": "trade.conversation.suggestions",
                "owner": "DTCommon",
                "metadata": {"textNamespace": "UI_DT_Conversation_Suggestion"},
                "offers": [
                    {
                        "id": "question.trader",
                        "label": {"EN": "Ask who they are", "TL": "Itanong kung sino sila"},
                        "utterance": {"EN": "Who are you?", "TL": "Sino kayo?"},
                        "frame": {
                            "intent": "QUESTION",
                            "speechAct": "QUESTION",
                            "subject": "TRADER",
                            "topic": "identity",
                            "patternID": "pattern.trade.concept_who",
                            "extensions": {"hubID": "trading"},
                        },
                        "consumers": ["participant"],
                        "metadata": {"order": 10, "domain": "identity"},
                    }
                ],
            }
        )
        rows = render_psdl_ui_plan(compiled)
        self.assertEqual([row["id"] for row in rows], ["question.trader"])
        self.assertEqual(rows[0]["labelKey"], "UI_DT_Conversation_Suggestion_Trader_Label")
        self.assertEqual(rows[0]["utteranceFallback"], "Who are you?")
        self.assertEqual(rows[0]["patternID"], "pattern.trade.concept_who")
        self.assertEqual(rows[0]["domain"], "identity")
        self.assertEqual(rows[0]["extensions"]["hubID"], "trading")

    def test_recognition_projects_to_existing_semantic_pack_contract(self) -> None:
        compiled = compile_psdl_document(
            {
                "schema": "psychopatz.semantic.dialogue-language.v1",
                "kind": "dialogue",
                "id": "trade.conversation.recognition",
                "owner": "DTCommon",
                "offers": [
                    {
                        "id": "action.trade",
                        "frame": {"intent": "TRADE", "patternID": "pattern.trade.open"},
                        "consumers": ["participant"],
                    }
                ],
                "recognition": {
                    "packID": "pack.DT.trader_story",
                    "ownerModID": "DynamicTrading",
                    "version": 2,
                    "concepts": [
                        {
                            "id": "concept.trade.open",
                            "aliases": ["trade", "barter"],
                            "kind": "intent",
                            "priority": 100,
                        }
                    ],
                    "speechActs": [
                        {
                            "id": "act.trade.request",
                            "definition": {"id": "act.trade.request", "intent": "TRADE"},
                        }
                    ],
                    "patterns": [
                        {
                            "id": "pattern.trade.open",
                            "match": [{"concept": "concept.trade.open"}],
                            "emit": {
                                "intent": "TRADE",
                                "speechAct": "act.trade.request",
                            },
                        }
                    ],
                    "actionProviders": [
                        {
                            "id": "DT.trade_action",
                            "sourceKind": "dynamic_trading",
                            "effectID": "DT.trade",
                        }
                    ],
                },
            }
        )
        packs = render_psdl_semantic_pack_plan(compiled)
        self.assertEqual([item["id"] for item in packs], ["pack.DT.trader_story"])
        self.assertEqual(packs[0]["concepts"][0]["aliases"], ["trade", "barter"])
        self.assertEqual(packs[0]["patterns"][0]["emit"]["intent"], "TRADE")
        self.assertEqual(packs[0]["actionProviders"][0]["effectID"], "DT.trade")

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

    def test_director_contract_fields_are_required(self) -> None:
        invalid = _catalog()
        invalid["records"][0].pop("stimuli")
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)

        invalid = _catalog()
        invalid["records"][1].pop("maintain")
        with self.assertRaises(CompileError):
            compile_psdl_document(invalid)


if __name__ == "__main__":
    unittest.main()
