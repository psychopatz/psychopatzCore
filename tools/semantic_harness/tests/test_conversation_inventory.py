"""Tests for the deterministic Conversation freeze inventory."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from tools.semantic_harness.codebuilder.conversation_inventory import inventory_from_model


class ConversationInventoryTests(unittest.TestCase):
    def test_inventory_sorts_shards_and_counts_keys(self) -> None:
        model = {
            "wholeModelFingerprint": "abc",
            "shards": [
                {
                    "path": "b.json",
                    "kind": "content",
                    "domain": "b",
                    "owner": "ProjectHoomans",
                    "recordIDs": ["b.2", "b.1"],
                    "fingerprint": "bfp",
                },
                {
                    "path": "a.json",
                    "kind": "content",
                    "domain": "a",
                    "owner": "ProjectHoomans",
                    "recordIDs": ["a.1"],
                    "fingerprint": "afp",
                },
            ],
        }
        with patch(
            "tools.semantic_harness.codebuilder.conversation_compiler.conversation_languages",
            return_value=("EN", "TL"),
        ), patch(
            "tools.semantic_harness.codebuilder.conversation_compiler.conversation_translation_bundles_by_owner",
            return_value={
                "ProjectHoomans": {
                    "EN": {"Social": {"key.b": "B", "key.a": "A"}},
                    "TL": {"Social": {"key.a": "A"}},
                }
            },
        ):
            report = inventory_from_model(model)

        self.assertEqual(report["languages"], ["EN", "TL"])
        self.assertEqual([item["path"] for item in report["shards"]], ["a.json", "b.json"])
        self.assertEqual(report["shards"][1]["recordIDs"], ["b.1", "b.2"])
        self.assertEqual(report["summary"]["recordCount"], 3)
        self.assertEqual(report["summary"]["translationKeyCount"], 3)
        self.assertEqual(
            report["translations"]["ProjectHoomans"]["EN"]["Social"]["keys"],
            ["key.a", "key.b"],
        )


if __name__ == "__main__":
    unittest.main()
