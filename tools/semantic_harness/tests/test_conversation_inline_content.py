"""Tests for self-contained Conversation source recipes."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_assembly import (
    _hydrate_shard_provenance,
)
from tools.semantic_harness.codebuilder.dialogue_content import (
    compile_dialogue_content,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConversationInlineContentTests(unittest.TestCase):
    @staticmethod
    def _document() -> dict:
        return {
            "schemaVersion": 4,
            "source": {
                "name": "Fixture",
                "version": "1",
                "contentLicense": "CC0",
            },
            "groups": {"greetings": {"contentOwner": "test"}},
            "phraseFamilies": [{
                "semanticTemplateID": "semantic.test.greeting",
                "group": "greetings",
                "styles": {
                    "neutral": [{"EN": "Hello.", "TL": "Kumusta."}],
                },
            }],
            "playerChoices": [{
                "id": "conversation.landing:test",
                "kind": "question",
                "route": "semantic_hub",
                "hubID": "test",
                "label": {"EN": "What's up?", "TL": "Kamusta?"},
                "choice": {"EN": "What's up?", "TL": "Kamusta?"},
            }],
        }

    def test_compiler_derives_phrase_identity_and_keys(self) -> None:
        compiled = compile_dialogue_content(self._document())
        phrase = compiled["phraseFamilies"][0]["styles"]["neutral"][0]
        self.assertEqual(phrase["id"], "phrase.semantic.test.greeting.neutral.01")
        self.assertEqual(
            phrase["key"],
            "conversation.content.semantic.test.greeting.neutral.01",
        )
        self.assertEqual(compiled["translations"]["TL"][phrase["key"]], "Kumusta.")
        choice = compiled["playerChoices"][0]
        self.assertEqual(
            compiled["translations"]["EN"][choice["labelKey"]],
            "What's up?",
        )

    def test_removed_phrase_identity_fields_are_rejected(self) -> None:
        document = self._document()
        document["phraseFamilies"][0]["styles"]["neutral"][0] = {
            "phraseID": "neutral.01",
            "translationKey": "conversation.content.old",
        }
        with self.assertRaisesRegex(CompileError, "removed source fields"):
            compile_dialogue_content(document)

    def test_manifest_provenance_uses_v3_shards(self) -> None:
        document = {
            "schema": "psychopatz.semantic.shard.v3",
            "shardId": "conversation.content.social.test",
            "kind": "content",
            "domain": "social",
            "owner": "ProjectHoomans",
            "sourceProfile": "conversation.source.fixture.1234567890",
            "phraseFamilies": [],
        }
        _hydrate_shard_provenance(
            document,
            {
                "path": "content/test.json",
                "kind": "content",
                "domain": "social",
                "owner": "ProjectHoomans",
                "shardId": "conversation.content.social.test",
                "sourceProfile": "conversation.source.fixture.1234567890",
            },
            {
                "conversation.source.fixture.1234567890": {
                    "name": "Fixture",
                    "version": "1",
                    "contentLicense": "CC0",
                },
            },
        )
        self.assertEqual(document["source"]["name"], "Fixture")
        self.assertEqual(document["source"]["owner"], "ProjectHoomans")


if __name__ == "__main__":
    unittest.main()
