"""Tests for the one-shot inline wording migration."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_catalog_migration import (
    strip_inline_translations,
)


class ConversationCatalogMigrationTests(unittest.TestCase):
    def test_removes_only_inline_locale_fields(self) -> None:
        value, removed = strip_inline_translations({
            "id": "example",
            "translations": {"EN": "Hello"},
            "labelTranslations": {"EN": "Label"},
            "nested": [{"choiceTranslations": {"EN": "Choose"}, "keep": True}],
        })
        self.assertEqual(removed, 3)
        self.assertEqual(value, {"id": "example", "nested": [{"keep": True}]})

    def test_non_locale_fields_are_preserved(self) -> None:
        original = {"id": "example", "text": "not a locale map", "metadata": {"owner": "Core"}}
        normalized, removed = strip_inline_translations(original)
        self.assertEqual(removed, 0)
        self.assertEqual(normalized, original)


if __name__ == "__main__":
    unittest.main()
