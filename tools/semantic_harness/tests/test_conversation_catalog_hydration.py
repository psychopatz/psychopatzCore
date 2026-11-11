"""Tests for catalog-backed compiler input hydration."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    _hydrate_catalog_translations,
)
from tools.semantic_harness.codebuilder.dialogue_content import phrase_translation_key
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
                "styles": {"neutral": [{}]},
            }],
            "playerChoices": [],
        }

    def test_hydrates_phrase_wording_from_locale_catalog(self) -> None:
        document = self._document()
        key = phrase_translation_key("semantic.test.greeting", "neutral", 1)
        _hydrate_catalog_translations(
            document,
            {"kind": "content", "path": "content/test.json"},
            {"EN": {key: "Hello."}, "TL": {key: "Kumusta."}},
        )
        self.assertEqual(
            document["phraseFamilies"][0]["styles"]["neutral"][0]["translations"],
            {"EN": "Hello.", "TL": "Kumusta."},
        )

    def test_rejects_legacy_wording_that_disagrees_with_catalog(self) -> None:
        document = self._document()
        document["phraseFamilies"][0]["styles"]["neutral"][0]["translations"] = {
            "EN": "Different."
        }
        key = phrase_translation_key("semantic.test.greeting", "neutral", 1)
        with self.assertRaises(CompileError):
            _hydrate_catalog_translations(
                document,
                {"kind": "content", "path": "content/test.json"},
                {"EN": {key: "Hello."}, "TL": {key: "Kumusta."}},
            )


if __name__ == "__main__":
    unittest.main()
