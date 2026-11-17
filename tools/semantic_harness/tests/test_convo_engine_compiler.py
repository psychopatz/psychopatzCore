"""Core-owned ConvoEngine S6M1A exchange-family compiler and service tests."""

from __future__ import annotations

import copy
import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder import (
    CONVO_ENGINE_SCHEMA,
    LEGACY_PSDL_SCHEMA,
    TEXT_ROLE_BUTTON_LABEL,
    TEXT_ROLE_RESPONSE,
    TEXT_ROLE_SPOKEN_ACTION,
    CompileError,
    canonicalize_dialogue,
    compile_convo_engine_document,
    compile_convo_engine_sources,
    render_convo_engine_runtime_plan,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


FIXTURE_PATH = Path(__file__).resolve().parent / "fixtures" / "convo_engine_ask_person.json"


def _load_fixture() -> dict:
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


class ConvoEngineCompilerTests(unittest.TestCase):
    def test_compact_fixture_previews_and_validates_through_codebuilder(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        service = SemanticLabAuthoringService(
            repository=core_repo,
            core_repository=core_repo,
        )
        fixture = _load_fixture()
        report = service.validate_convo_engine_document(fixture, source_path=FIXTURE_PATH)
        self.assertTrue(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertEqual(report["sourceSchema"], CONVO_ENGINE_SCHEMA)
        self.assertEqual(report["diagnostics"], [])

        records = report["compiled"]["records"]
        self.assertEqual(len(records), 1)
        family = records[0]
        self.assertEqual(family["id"], "social.knowledge.ask_person")
        self.assertEqual(family["namespace"], "social.knowledge")
        self.assertEqual(family["lineage"]["localId"], "ask_person")
        self.assertEqual(family["slots"]["person"]["suggest"], "knowledge.people")
        self.assertEqual(family["slots"]["person"]["limit"], 4)

        plans = report["runtimePlan"]
        self.assertEqual(len(plans), 1)
        exchange = plans[0]["exchangeFamily"]
        self.assertEqual(exchange["familyID"], "social.knowledge.ask_person")
        self.assertEqual(exchange["affordance"]["textRole"], TEXT_ROLE_BUTTON_LABEL)
        self.assertEqual(exchange["initiatingSay"]["textRole"], TEXT_ROLE_SPOKEN_ACTION)
        self.assertEqual(exchange["initiatingSay"]["keyOrder"], ["1", "4"])
        self.assertEqual(
            [v["id"] for v in exchange["initiatingSay"]["realizations"]["1"]["variants"]],
            ["warm", "guarded"],
        )
        self.assertEqual(exchange["replies"]["known"]["textRole"], TEXT_ROLE_RESPONSE)
        self.assertEqual(exchange["replies"]["known"]["say"]["keyOrder"], ["2"])
        self.assertEqual(exchange["replies"]["unknown"]["say"]["keyOrder"], ["1"])
        self.assertTrue(exchange["replies"]["unknown"]["say"]["realizations"]["1"]["shorthand"])
        roles = {entry["role"] for entry in plans[0]["textRoles"]}
        self.assertEqual(
            roles,
            {TEXT_ROLE_BUTTON_LABEL, TEXT_ROLE_SPOKEN_ACTION, TEXT_ROLE_RESPONSE},
        )

    def test_direct_single_say_and_sparse_numeric_keys_preserve_independence(self) -> None:
        doc = {
            "schema": CONVO_ENGINE_SCHEMA,
            "kind": "dialogue",
            "namespace": "social.identity",
            "id": "ask_name",
            "owner": "PsychopatzCore",
            "invoke": {"intent": "QUESTION", "subject": "IDENTITY"},
            "affordance": {"label": "Ask who they are"},
            "say": "Who are you?",
            "reply": {
                "named": {
                    "say": {
                        "2": "I'm {addressee.name}.",
                        "5": "Name's {addressee.name}.",
                    }
                }
            },
        }
        compiled = compile_convo_engine_document(doc)
        record = compiled["records"][0]
        self.assertEqual(record["id"], "social.identity.ask_name")
        self.assertEqual(record["payload"]["say"]["mode"], "single")
        self.assertEqual(record["payload"]["say"]["keyOrder"], ["1"])
        self.assertEqual(
            record["payload"]["reply"]["named"]["say"]["keyOrder"],
            ["2", "5"],
        )

        # Standalone IR canonicalization also supports namespace + id + CONVO_ENGINE_SCHEMA.
        ir = canonicalize_dialogue(doc, source_path="dialogue/social/identity/ask_name.json")
        self.assertEqual(ir["id"], "social.identity.ask_name")
        self.assertEqual(ir["namespace"], "social.identity")
        self.assertEqual(ir["lineage"]["sourceSchema"], CONVO_ENGINE_SCHEMA)

    def test_legacy_schema_is_read_only_compatibility_only(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        service = SemanticLabAuthoringService(
            repository=core_repo,
            core_repository=core_repo,
        )
        legacy_doc = {
            "schema": LEGACY_PSDL_SCHEMA,
            "kind": "dialogue",
            "id": "social.greeting.basic_read",
            "owner": "PsychopatzCore",
            "on": {"intent": "GREET"},
            "respond": {"EN": "Hello, {addressee.name}."},
        }
        with self.assertRaises(CompileError):
            service.preview_convo_engine_document(legacy_doc)
        preview = service.preview_convo_engine_document(
            legacy_doc,
            allow_legacy_schema=True,
        )
        self.assertTrue(preview["ok"])
        self.assertEqual(preview["diagnostics"][0]["code"], "legacy_schema_migration_only")

        strict = service.validate_convo_engine_document(
            legacy_doc,
            allow_legacy_schema=False,
        )
        self.assertFalse(strict["ok"])

        bad_hybrid = _load_fixture()
        bad_hybrid["schema"] = LEGACY_PSDL_SCHEMA
        with self.assertRaises(CompileError):
            compile_convo_engine_document(bad_hybrid)

    def test_affordance_without_say_does_not_fallback_from_button_label(self) -> None:
        doc = {
            "schema": CONVO_ENGINE_SCHEMA,
            "kind": "dialogue",
            "namespace": "social.identity",
            "id": "ask_name",
            "owner": "PsychopatzCore",
            "invoke": {"intent": "QUESTION", "subject": "IDENTITY"},
            "affordance": {"label": "Ask who they are"},
            "reply": {"named": {"say": "I'm {addressee.name}."}},
        }
        with self.assertRaises(CompileError) as ctx:
            compile_convo_engine_document(doc)
        self.assertIn("button_label", str(ctx.exception))

    def test_invalid_say_keys_and_reply_outcome_names_fail_closed(self) -> None:
        base = _load_fixture()
        for bad_say in (
            ["Who are you?", "What's your name?"],
            {"0": "Zero is invalid"},
            {"-1": "Negative is invalid"},
            {"01": "Leading zero is invalid"},
            {"warm": "Non-numeric key without variants"},
            {1: "Integer key"},
            {},
            "",
        ):
            doc = copy.deepcopy(base)
            doc["say"] = bad_say
            with self.assertRaises(CompileError, msg=f"accepted bad say: {bad_say!r}"):
                compile_convo_engine_document(doc)

        bad_reply_doc = copy.deepcopy(base)
        bad_reply_doc["reply"] = {"1": {"say": "Numeric outcome is invalid"}}
        with self.assertRaises(CompileError):
            compile_convo_engine_document(bad_reply_doc)

    def test_semantic_references_cannot_target_wording_realization_keys(self) -> None:
        base = _load_fixture()
        for bad_ref in (
            "social.knowledge.ask_person.1",
            "social.knowledge.ask_person.4",
            "social.knowledge.ask_person.say.1",
            "social.knowledge.ask_person#1",
            "1",
        ):
            doc = copy.deepcopy(base)
            doc["after"] = {"recommend": [bad_ref]}
            with self.assertRaises(CompileError, msg=f"accepted wording ref: {bad_ref!r}"):
                compile_convo_engine_document(doc)

            goto_doc = copy.deepcopy(base)
            goto_doc["reply"]["known"]["after"] = {"goto": bad_ref}
            with self.assertRaises(CompileError, msg=f"accepted wording goto: {bad_ref!r}"):
                compile_convo_engine_document(goto_doc)

        # Cross-source check: referencing another family's realization key fails closed.
        other = {
            "schema": CONVO_ENGINE_SCHEMA,
            "kind": "dialogue",
            "namespace": "navigation",
            "id": "ask_direction",
            "owner": "ProjectHoomans",
            "say": "Which way?",
            "after": {"goto": "social.knowledge.ask_person.1"},
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_sources({"ask_person.json": base, "ask_direction.json": other})

    def test_family_id_cannot_encode_numeric_realization_key_or_undeclared_slot(self) -> None:
        bad_id_doc = {
            "schema": CONVO_ENGINE_SCHEMA,
            "kind": "dialogue",
            "id": "social.knowledge.ask_person.1",
            "owner": "ProjectHoomans",
            "say": "Have you seen Bob?",
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_document(bad_id_doc)

        bad_slot_doc = _load_fixture()
        bad_slot_doc["say"] = "Where is {slot.missing.name}?"
        with self.assertRaises(CompileError):
            compile_convo_engine_document(bad_slot_doc)

    def test_default_owner_resolution_and_ambiguity_fail_closed(self) -> None:
        no_owner = _load_fixture()
        no_owner.pop("owner")
        with self.assertRaises(CompileError):
            compile_convo_engine_document(no_owner)

        compiled = compile_convo_engine_document(no_owner, default_owner="ProjectHoomans")
        self.assertEqual(compiled["records"][0]["owner"], "ProjectHoomans")
        plans = render_convo_engine_runtime_plan(compiled)
        self.assertEqual(plans[0]["owner"], "ProjectHoomans")


if __name__ == "__main__":
    unittest.main()
