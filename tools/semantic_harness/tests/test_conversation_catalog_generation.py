"""Tests for self-contained Conversation locale catalog generation."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from tools.semantic_harness.codebuilder.conversation_catalog_generation import (
    catalogs_from_model,
)


class ConversationCatalogGenerationTests(unittest.TestCase):
    def test_catalogs_are_one_file_per_language_with_sorted_entries(self) -> None:
        model = {
            "content": {
                "phraseFamilies": [{
                    "sourceShard": "content/social/reactions.json",
                    "conversationDomain": "social",
                    "styles": {"neutral": [{"key": "key.b"}, {"key": "key.a"}]},
                }],
                "playerChoices": [],
            },
            "ui": [],
            "locations": {},
            "dialogue": {"translations": {}},
            "semantic": {"translations": {}},
        }
        bundles = {
            "ProjectHoomans": {
                "EN": {"Social": {"key.b": "B", "key.a": "A"}},
                "TL": {"Social": {"key.b": "B-TL", "key.a": "A-TL"}},
            }
        }
        with patch(
            "tools.semantic_harness.codebuilder.conversation_compiler.conversation_translation_bundles_by_owner",
            return_value=bundles,
        ):
            catalogs = catalogs_from_model(model)

        self.assertEqual(list(catalogs), ["EN", "TL"])
        self.assertEqual(list(catalogs["EN"]["entries"]), ["key.a", "key.b"])
        self.assertEqual(
            catalogs["EN"]["entries"]["key.a"]["sourceShard"],
            "conversation.content.social.reactions",
        )
        self.assertEqual(catalogs["EN"]["entries"]["key.a"]["owners"], ["ProjectHoomans"])


if __name__ == "__main__":
    unittest.main()
