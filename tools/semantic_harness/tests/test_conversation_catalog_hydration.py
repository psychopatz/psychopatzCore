"""Tests for catalog-backed compiler input hydration."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    _hydrate_catalog_translations,
    _hydrate_shard_provenance,
)
from tools.semantic_harness.codebuilder.dialogue_content import (
    compile_dialogue_content,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConversationCatalogHydrationTests(unittest.TestCase):
    def _document(self) -> dict:
        return {
            "schema": "pnc.conversation.shard.v1",
            "kind": "content",
            "domain": "social",
            "source": {},
            "groups": {"greetings": {"contentOwner": "test"}},
            "phraseFamilies": [{
                "semanticTemplateID": "semantic.test.greeting",
                "group": "greetings",
                "styles": {"neutral": [{
                    "phraseID": "neutral.01",
                    "translationKey": "conversation.content.semantic.test.greeting.neutral.01",
                }]},
            }],
            "playerChoices": [],
        }

    def test_hydrates_phrase_wording_from_locale_catalog(self) -> None:
        document = self._document()
        key = "conversation.content.semantic.test.greeting.neutral.01"
        _hydrate_catalog_translations(
            document,
            {"kind": "content", "path": "content/test.json"},
            {"EN": {key: "Hello."}, "TL": {key: "Kumusta."}},
        )
        self.assertEqual(
            document["phraseFamilies"][0]["styles"]["neutral"][0]["translations"],
            {"EN": "Hello.", "TL": "Kumusta."},
        )

    def test_rejects_inline_wording_even_when_catalog_has_a_value(self) -> None:
        document = self._document()
        document["phraseFamilies"][0]["styles"]["neutral"][0]["translations"] = {
            "EN": "Different."
        }
        key = "conversation.content.semantic.test.greeting.neutral.01"
        with self.assertRaises(CompileError):
            _hydrate_catalog_translations(
                document,
                {"kind": "content", "path": "content/test.json"},
                {"EN": {key: "Hello."}, "TL": {key: "Kumusta."}},
            )

    def test_requires_explicit_translation_key(self) -> None:
        document = self._document()
        del document["phraseFamilies"][0]["styles"]["neutral"][0]["translationKey"]
        with self.assertRaisesRegex(CompileError, "requires explicit translationKey"):
            _hydrate_catalog_translations(
                document,
                {"kind": "content", "path": "content/test.json"},
                {"EN": {}, "TL": {}},
            )

    def test_compiler_requires_explicit_phrase_identity(self) -> None:
        document = {
            "schemaVersion": 3,
            "source": {
                "name": "Fixture",
                "version": "1",
                "contentLicense": "CC0",
            },
            "groups": {"greetings": {"contentOwner": "test"}},
            "phraseFamilies": [{
                "semanticTemplateID": "semantic.test.greeting",
                "group": "greetings",
                "styles": {"neutral": [{
                    "phraseID": "neutral.01",
                    "translationKey": "conversation.content.semantic.test.greeting.neutral.01",
                    "translations": {"EN": "Hello."},
                }]},
            }],
            "playerChoices": [],
        }
        compiled = compile_dialogue_content(document)
        phrase = compiled["phraseFamilies"][0]["styles"]["neutral"][0]
        self.assertEqual(phrase["id"], "phrase.semantic.test.greeting.neutral.01")
        self.assertEqual(
            phrase["key"],
            "conversation.content.semantic.test.greeting.neutral.01",
        )

        document["phraseFamilies"][0]["styles"]["neutral"] = [{}]
        with self.assertRaisesRegex(CompileError, "phraseID"):
            compile_dialogue_content(document)

    def test_hydrates_provenance_from_manifest_profile(self) -> None:
        document = {
            "schema": "psychopatz.semantic.shard.v2",
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
                },
            },
        )
        self.assertEqual(document["source"]["name"], "Fixture")
        self.assertEqual(document["source"]["owner"], "ProjectHoomans")

    def test_rejects_manifest_shard_identity_mismatch(self) -> None:
        document = {
            "schema": "psychopatz.semantic.shard.v2",
            "shardId": "conversation.content.social.actual",
            "kind": "content",
            "domain": "social",
            "owner": "ProjectHoomans",
            "sourceProfile": "conversation.source.fixture.1234567890",
            "phraseFamilies": [],
        }
        with self.assertRaises(CompileError):
            _hydrate_shard_provenance(
                document,
                {
                    "path": "content/test.json",
                    "kind": "content",
                    "domain": "social",
                    "owner": "ProjectHoomans",
                    "shardId": "conversation.content.social.expected",
                    "sourceProfile": "conversation.source.fixture.1234567890",
                },
                {"conversation.source.fixture.1234567890": {"name": "Fixture"}},
            )


if __name__ == "__main__":
    unittest.main()
