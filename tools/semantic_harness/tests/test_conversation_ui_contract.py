"""Tests for self-contained Conversation UI recipes."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_ui_contract import (
    suggestion_text_keys,
    text_key,
    validate_ui_shard,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConversationUIContractTests(unittest.TestCase):
    def test_runtime_keys_are_derived_from_compact_ids(self) -> None:
        self.assertEqual(
            suggestion_text_keys("UI_PNC_Conversation_Suggestion", "question.identity_nickname"),
            (
                "UI_PNC_Conversation_Suggestion_IdentityNickname_Label",
                "UI_PNC_Conversation_Suggestion_IdentityNickname_Utterance",
            ),
        )
        self.assertEqual(
            text_key("UI_PNC_Conversation", "suggestion.identity.real.label"),
            "UI_PNC_Conversation_Suggestion_Identity_Real_Label",
        )

    def test_validation_compiles_display_text_without_authoring_keys(self) -> None:
        compiled = validate_ui_shard(
            {
                "textNamespace": "UI_Test_Conversation",
                "suggestions": [{
                    "id": "question.name",
                    "topic": "identity",
                    "patternID": "pattern.identity.name",
                    "order": 10,
                    "display": {
                        "EN": {"label": "Ask their name", "utterance": "What's your name?"},
                        "TL": {"label": "Itanong ang pangalan", "utterance": "Ano ang pangalan mo?"},
                    },
                }],
                "texts": [{
                    "id": "suggestion.back.label",
                    "display": {"EN": "Back", "TL": "Bumalik"},
                }],
            },
            "ui/test.json",
        )
        suggestion = compiled["suggestions"][0]
        self.assertEqual(suggestion["labelKey"], "UI_Test_Conversation_Name_Label")
        self.assertEqual(suggestion["utteranceKey"], "UI_Test_Conversation_Name_Utterance")
        self.assertEqual(compiled["texts"][0]["key"], "UI_Test_Conversation_Suggestion_Back_Label")

    def test_generated_key_fields_are_not_accepted_as_authoring_input(self) -> None:
        with self.assertRaises(CompileError):
            validate_ui_shard(
                {
                    "textNamespace": "UI_Test_Conversation",
                    "suggestions": [{
                        "id": "question.name",
                        "topic": "identity",
                        "patternID": "pattern.identity.name",
                        "order": 10,
                        "labelKey": "UI_Test_Conversation_Name_Label",
                        "utteranceKey": "UI_Test_Conversation_Name_Utterance",
                        "display": {
                            "EN": {"label": "Ask their name", "utterance": "What's your name?"},
                        },
                    }],
                },
                "ui/test.json",
            )


if __name__ == "__main__":
    unittest.main()
