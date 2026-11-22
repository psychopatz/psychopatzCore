"""Focused unit tests for D7 Semantic Lab / Observatory inspection extensions."""

from __future__ import annotations

import json
import unittest

from tools.semantic_harness.codebuilder.convo_engine_hygiene_audit import (
    RULE_ACTOR_OR_DIRECTION,
    RULE_MISLEADING_FLOW,
    RULE_STYLE_OR_TIER_SPLIT,
)
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.inspection.rendering import conversation_first
from tools.semantic_harness.inspection.response_observatory import (
    run_quality_matrix,
)
from tools.semantic_harness.inspection.response_turn_trace import (
    inspect_response_turn,
)
from tools.semantic_harness.studio.observatory_pane import (
    SemanticObservatoryPane,
    format_d7_observatory_lines,
)


def _sample_d7_turn(
    *,
    lane: str | None = "scene",
    scene_id: str | None = "clinic.triage",
    thread_id: str | None = None,
    family_id: str = "clinic.triage.check_in",
    stance: str = "concerned",
    outcome: str = "offer_help",
    epistemic_status: str = "known",
) -> dict:
    return {
        "type": "dialogue",
        "accepted": True,
        "input": "How is the clinic doing?",
        "contextAfter": {
            "dialogue": {
                "sequence": 4,
                "lastIntent": "ask_status",
                "lastSpeaker": "player",
                "currentTopic": "clinic_supplies",
                "memorySalience": 0.85,
            },
            "actorConversationContext": {
                "dispositionContribution": {
                    "baseDisposition": 0.4,
                    "temporaryDemeanor": 0.15,
                    "effectiveDisposition": 0.55,
                    "styleProfile": "calm_medic",
                },
            },
        },
        "observation": {
            "interactionPlan": {
                "lane": lane,
                "sceneID": scene_id,
                "threadID": thread_id,
                "beatID": "beat.triage.01",
                "familyID": family_id,
                "stance": stance,
                "outcome": outcome,
            },
            "response": {
                "templateID": "clinic.triage.check_in.01",
                "sourcePoolID": family_id,
                "familyID": family_id,
                "stance": stance,
                "outcome": outcome,
                "epistemicStatus": epistemic_status,
                "memorySalience": 0.85,
                "groundingRefs": ["fact.clinic.bandages_low", "fact.npc.medic_role"],
                "knowledgeProvenance": {
                    "source": "clinic_inventory_dossier",
                    "verifiedBy": "npc_self",
                },
                "constraintReasons": ["cooldown_ok", "witness_present"],
                "actorRoles": {
                    "initiator": "player",
                    "speaker": "npc.dr_mara",
                    "addressee": "player",
                    "audience": ["npc.guard_eli"],
                    "witness": "npc.guard_eli",
                    "victim": "npc.patient_02",
                },
                "dispositionContribution": {
                    "baseDisposition": 0.4,
                    "temporaryDemeanor": 0.15,
                    "effectiveDisposition": 0.55,
                    "styleProfile": "calm_medic",
                },
            },
        },
        "result": {
            "ir": {
                "intent": "ask_status",
                "speechAct": "question",
                "subject": "clinic",
                "extensions": {
                    "facts": {
                        "bandages": {"provider": "clinic_dossier", "value": "low"},
                    },
                },
            },
        },
        "messages": [
            {
                "speaker": "npc",
                "payload": {
                    "key": "clinic.triage.check_in.01",
                    "semanticTemplateID": "clinic.triage.check_in.01",
                    "semanticVariantID": "clinic.triage.check_in.01.v1",
                    "familyID": family_id,
                    "stance": stance,
                    "outcome": outcome,
                    "actorRoles": {
                        "initiator": "player",
                        "speaker": "npc.dr_mara",
                        "addressee": "player",
                        "witness": "npc.guard_eli",
                    },
                    "text": "We are running low on bandages, but holding steady.",
                },
            }
        ],
        "translation": {"language": "EN", "lookups": []},
    }


class _StubWorker:
    def __init__(self, turn: dict | None = None) -> None:
        self._turn = turn or _sample_d7_turn()

    def __enter__(self) -> "_StubWorker":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        return None

    def response_key_lookup(self, key: str) -> dict:
        return {
            "matches": [
                {
                    "matchKind": "REGISTERED_VARIANT_ID",
                    "variantID": key,
                    "templateID": "clinic.triage.check_in.01",
                }
            ],
            "matchCount": 1,
            "truncated": False,
        }

    def input(self, _utterance: str) -> dict:
        return self._turn


class _FakeVar:
    def __init__(self, value: str = "") -> None:
        self._value = value

    def get(self) -> str:
        return self._value

    def set(self, value: str) -> None:
        self._value = value


class _FakeWidget:
    def __init__(self, *_args, **_kwargs) -> None:
        self.text = ""

    def grid(self, **_kwargs) -> None:
        return None

    def pack(self, **_kwargs) -> None:
        return None

    def configure(self, **_kwargs) -> None:
        return None

    def rowconfigure(self, *_args, **_kwargs) -> None:
        return None

    def columnconfigure(self, *_args, **_kwargs) -> None:
        return None

    def add(self, *_args, **_kwargs) -> None:
        return None

    def heading(self, *_args, **_kwargs) -> None:
        return None

    def column(self, *_args, **_kwargs) -> None:
        return None

    def bind(self, *_args, **_kwargs) -> None:
        return None

    def yview(self, *_args, **_kwargs) -> None:
        return None

    def delete(self, *_args, **_kwargs) -> None:
        self.text = ""

    def insert(self, _idx: str, value: str) -> None:
        self.text = value

    def get(self, *_args, **_kwargs) -> str:
        return self.text

    def set(self, *_args, **_kwargs) -> None:
        return None


class _FakeTk:
    StringVar = _FakeVar


class _FakeTtk:
    Frame = _FakeWidget
    Label = _FakeWidget
    Entry = _FakeWidget
    Button = _FakeWidget
    Panedwindow = _FakeWidget
    Treeview = _FakeWidget
    Scrollbar = _FakeWidget
    Notebook = _FakeWidget


class ObservatoryD7InspectionTests(unittest.TestCase):
    def test_conversation_inspector_projects_all_d7_fields(self) -> None:
        turn = _sample_d7_turn()
        view = build_conversation_inspector(turn)

        self.assertEqual(
            view["laneOwnership"],
            {
                "lane": "scene",
                "sceneID": "clinic.triage",
                "threadID": None,
                "sceneThreadCollision": False,
                "collisionWarning": None,
            },
        )
        self.assertEqual(view["familyGranularity"]["familyID"], "clinic.triage.check_in")
        self.assertEqual(view["familyGranularity"]["stance"], "concerned")
        self.assertEqual(view["familyGranularity"]["outcome"], "offer_help")
        self.assertEqual(view["familyGranularity"]["hygiene"]["badge"], "CLEAN")
        self.assertEqual(view["familyGranularity"]["hygiene"]["warningCount"], 0)

        self.assertEqual(
            view["dispositionContribution"],
            {
                "baseDisposition": 0.4,
                "temporaryDemeanor": 0.15,
                "effectiveDisposition": 0.55,
                "styleProfile": "calm_medic",
            },
        )
        self.assertEqual(view["constraintReasons"], ["cooldown_ok", "witness_present"])
        self.assertEqual(
            view["groundingRefs"],
            ["fact.clinic.bandages_low", "fact.npc.medic_role"],
        )
        self.assertEqual(
            view["knowledgeProvenance"],
            {
                "source": "clinic_inventory_dossier",
                "verifiedBy": "npc_self",
            },
        )
        self.assertEqual(view["epistemicStatus"], "known")
        self.assertEqual(view["memorySalience"], 0.85)
        self.assertEqual(
            view["actorRoles"],
            {
                "initiator": "player",
                "speaker": "npc.dr_mara",
                "addressee": "player",
                "audience": ["npc.guard_eli"],
                "witness": "npc.guard_eli",
                "victim": "npc.patient_02",
            },
        )

        rendered = conversation_first(view)
        self.assertIn("LANE OWNERSHIP", rendered)
        self.assertIn("FAMILY GRANULARITY & HYGIENE", rendered)
        self.assertIn("DISPOSITION & GROUNDING", rendered)
        self.assertIn("ACTOR ROLES", rendered)
        json.dumps(view)

    def test_lane_collision_and_inline_hygiene_warnings(self) -> None:
        collision_turn = _sample_d7_turn(
            lane="beat",
            scene_id="clinic.scene_a",
            thread_id="clinic.thread_b",
            family_id="flow.npc_to_player.friend",
            epistemic_status="uncertain",
        )
        view = build_conversation_inspector(collision_turn)

        lane = view["laneOwnership"]
        self.assertTrue(lane["sceneThreadCollision"])
        self.assertIn("clinic.scene_a", lane["collisionWarning"])
        self.assertIn("clinic.thread_b", lane["collisionWarning"])

        hygiene = view["familyGranularity"]["hygiene"]
        self.assertEqual(hygiene["badge"], "WARN (3)")
        codes = {row["code"] for row in hygiene["warnings"]}
        self.assertEqual(
            codes,
            {
                RULE_ACTOR_OR_DIRECTION,
                RULE_STYLE_OR_TIER_SPLIT,
                RULE_MISLEADING_FLOW,
            },
        )
        self.assertEqual(view["epistemicStatus"], "uncertain")

    def test_response_turn_trace_and_quality_matrix_preserve_d7_fields(self) -> None:
        turn = _sample_d7_turn(
            lane="beat",
            scene_id=None,
            thread_id="clinic.supply_thread",
            epistemic_status="unknown",
        )
        worker = _StubWorker(turn)
        trace = inspect_response_turn(worker, turn)

        self.assertEqual(trace["laneOwnership"]["lane"], "beat")
        self.assertEqual(trace["laneOwnership"]["threadID"], "clinic.supply_thread")
        self.assertFalse(trace["laneOwnership"]["sceneThreadCollision"])
        self.assertEqual(trace["epistemicStatus"], "unknown")
        self.assertEqual(trace["npcMessages"][0]["familyID"], "clinic.triage.check_in")
        self.assertEqual(trace["npcMessages"][0]["stance"], "concerned")
        self.assertEqual(trace["npcMessages"][0]["outcome"], "offer_help")
        self.assertIn("witness", trace["npcMessages"][0]["actorRoles"])

        matrix = run_quality_matrix(
            [{"label": "d7_smoke", "utterance": "How is the clinic doing?"}],
            worker_factory=lambda _scenario: _StubWorker(turn),
        )
        self.assertTrue(matrix["ok"])
        row = matrix["cases"][0]
        self.assertEqual(row["laneOwnership"]["threadID"], "clinic.supply_thread")
        self.assertEqual(row["familyGranularity"]["hygiene"]["badge"], "CLEAN")
        self.assertEqual(row["actorRoles"]["victim"], "npc.patient_02")

    def test_observatory_pane_renders_d7_detail_and_turn_inspection(self) -> None:
        pane = SemanticObservatoryPane(
            _FakeWidget(),
            _FakeTk,
            _FakeTtk,
            _FakeWidget,
            lambda _op, _cb: True,
        )
        turn = _sample_d7_turn(
            lane="scene",
            scene_id="clinic.triage",
            thread_id="clinic.conflict",
            family_id="greet.npc_to_player.warm",
        )
        inspector = build_conversation_inspector(turn)
        rendered = pane.show_turn_inspection(inspector)
        self.assertIn("[COLLISION WARNING]", rendered)
        self.assertIn("hygiene=[WARN (2)]", rendered)
        self.assertIn("effective=0.55", rendered)
        self.assertIn("epistemicStatus=known", rendered)
        self.assertIn("victim=npc.patient_02", rendered)

        pane._on_detail(
            {
                "poolID": "greet.npc_to_player.warm",
                "variantCount": 1,
                "variants": [
                    {
                        "id": "greet.npc_to_player.warm.01",
                        "templateID": "greet.01",
                        "fallback": "Hello there.",
                    }
                ],
            }
        )
        explore_text = pane.views["Explore"].get("1.0", "end")
        self.assertIn("hygiene=[WARN (2)]", explore_text)
        self.assertIn("[HYGIENE actor_or_direction_encoded_family_id]", explore_text)
        self.assertTrue(format_d7_observatory_lines(inspector))


if __name__ == "__main__":
    unittest.main()
