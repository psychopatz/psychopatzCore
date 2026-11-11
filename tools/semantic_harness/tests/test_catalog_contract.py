"""Tests for strict semantic shard and locale catalog contracts."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_contract import (
    CatalogContractError,
    SHARD_SCHEMA,
    TRANSLATION_SCHEMA,
    load_catalog_document,
    validate_locale_set,
    validate_shard,
    validate_translation_catalog,
)


class CatalogContractTests(unittest.TestCase):
    def test_valid_shard_has_no_diagnostics(self) -> None:
        shard = {
            "schema": SHARD_SCHEMA,
            "shardId": "conversation.content.social.reactions",
            "kind": "content",
            "domain": "social.reactions",
            "owner": "PsychopatzCore",
            "records": [
                {"id": "greeting.001", "translationKey": "conversation.greeting.001"}
            ],
        }
        self.assertEqual(validate_shard(shard, allowed_owners={"PsychopatzCore"}), [])

    def test_strict_shard_rejects_implicit_owner_and_inline_text(self) -> None:
        shard = {
            "schema": SHARD_SCHEMA,
            "shardId": "conversation.content.social.reactions",
            "kind": "content",
            "domain": "social.reactions",
            "records": [{"id": "greeting.001", "translations": {"EN": "Hi"}}],
        }
        codes = {issue["code"] for issue in validate_shard(shard)}
        self.assertIn("shard_owner", codes)
        self.assertIn("inline_translations_forbidden", codes)

    def test_locale_set_checks_exact_keys_and_placeholders(self) -> None:
        def catalog(language: str, text: str, key: str = "conversation.greeting.001") -> dict:
            return {
                "schema": TRANSLATION_SCHEMA,
                "language": language,
                "fallback": "EN",
                "entries": {
                    key: {
                        "text": text,
                        "sourceShard": "conversation.content.social.greeting",
                    }
                },
            }

        issues = validate_locale_set({
            "EN": catalog("EN", "Hello %1"),
            "TL": catalog("TL", "Kumusta"),
        })
        codes = {issue["code"] for issue in issues}
        self.assertIn("locale_placeholder_mismatch", codes)

        issues = validate_locale_set({
            "EN": catalog("EN", "Hello"),
            "TL": catalog("TL", "Kumusta", "conversation.other.001"),
        })
        codes = {issue["code"] for issue in issues}
        self.assertIn("locale_missing_keys", codes)
        self.assertIn("locale_extra_keys", codes)

    def test_loader_rejects_duplicate_json_keys(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "EN.json"
            path.write_text('{"schema":"x","schema":"y"}', encoding="utf-8")
            with self.assertRaises(CatalogContractError):
                load_catalog_document(path)

    def test_translation_catalog_requires_source_context(self) -> None:
        catalog = {
            "schema": TRANSLATION_SCHEMA,
            "language": "EN",
            "fallback": "EN",
            "entries": {"conversation.greeting.001": {"text": "Hello"}},
        }
        codes = {issue["code"] for issue in validate_translation_catalog(catalog)}
        self.assertIn("translation_source_shard", codes)


if __name__ == "__main__":
    unittest.main()
