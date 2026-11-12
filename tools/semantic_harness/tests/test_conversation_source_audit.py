"""Tests for the read-only semantic catalog audit."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_source_audit import (
    audit_conversation_sources,
)
from tools.semantic_harness.codebuilder.build import merge_translation_catalog


class CatalogAuditTests(unittest.TestCase):
    def test_ui_catalog_merge_preserves_package_owned_entries(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "UI.json"
            path.write_text(
                json.dumps({
                    "UI_PsychopatzConversation_Identity_Stranger": "Stranger",
                    "UI_PNC_Conversation_Suggestion_Identity_Label": "old",
                }),
                encoding="utf-8",
            )
            merged = merge_translation_catalog(
                path,
                {"UI_PNC_Conversation_Suggestion_Identity_Label": "new"},
            )

        self.assertEqual(
            merged["UI_PsychopatzConversation_Identity_Stranger"],
            "Stranger",
        )
        self.assertEqual(
            merged["UI_PNC_Conversation_Suggestion_Identity_Label"],
            "new",
        )

    def test_shared_conversation_ui_is_not_a_semantic_text_source(self) -> None:
        repository = Path(__file__).resolve().parents[3]
        source_root = (
            repository
            / "tools/semantic_harness/codebuilder/sources/conversation/text"
        )
        manifest = json.loads(
            (source_root / "manifest.json").read_text(encoding="utf-8")
        )
        paths = {entry["path"] for entry in manifest["sources"]}
        self.assertFalse(any(path.startswith("system/") for path in paths))
        for path in (
            "system/categories/choice.json",
            "system/categories/status.json",
            "system/categories/button.json",
            "system/categories/detail.json",
            "system/categories/sandbox.json",
            "system/categories/title.json",
        ):
            self.assertNotIn(path, paths)
            self.assertFalse((source_root / path).exists())

    def test_record_owner_and_version_are_not_source_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "behaviors").mkdir()
            (root / "manifest.json").write_text(
                json.dumps({"shards": []}), encoding="utf-8"
            )
            (root / "behaviors" / "social.json").write_text(
                json.dumps({
                    "behaviors": [{"id": "behavior.test", "owner": "ProjectHoomans", "version": 1}],
                }),
                encoding="utf-8",
            )
            report = audit_conversation_sources(root)
        self.assertEqual(report["summary"]["repeatedMetadataFileCount"], 0)

    def test_accepts_inline_locale_data_and_reports_legacy_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "content" / "social").mkdir(parents=True)
            manifest = {
                "schema": "pnc.conversation.manifest.v1",
                "defaultOwner": "ProjectHoomans",
                "shards": [
                    {
                        "domain": "social",
                        "kind": "content",
                        "order": 1,
                        "path": "content/social/reactions.json",
                    }
                ],
            }
            (root / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            (root / "content" / "social" / "reactions.json").write_text(
                json.dumps(
                    {
                        "phraseFamilies": [{
                            "styles": {
                                "neutral": [{
                                    "phraseID": "neutral.01",
                                    "EN": "Hello",
                                    "TL": "Kumusta",
                                }]
                            }
                        }],
                        "source": {"name": "Example", "owner": "ProjectHoomans"},
                    }
                ),
                encoding="utf-8",
            )
            report = audit_conversation_sources(root)

        codes = {issue["code"] for issue in report["issues"]}
        self.assertIn("implicit_default_owner", codes)
        self.assertIn("implicit_shard_owner", codes)
        self.assertIn("legacy_source_fields", codes)
        self.assertIn("repeated_source_metadata", codes)
        self.assertNotIn("authoring_locale_catalogs_present", codes)
        self.assertEqual(report["summary"]["sourceJsonCount"], 1)

    def test_locale_catalogs_are_reported_and_duplicate_stems_are_stable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "content" / "one").mkdir(parents=True)
            (root / "content" / "two").mkdir(parents=True)
            (root / "translations").mkdir()
            (root / "manifest.json").write_text(
                json.dumps({"shards": []}), encoding="utf-8"
            )
            for path in (
                root / "content" / "one" / "conversation.json",
                root / "content" / "two" / "conversation.json",
            ):
                path.write_text("{}", encoding="utf-8")
            (root / "translations" / "EN.json").write_text(
                json.dumps({"language": "EN", "entries": {}}), encoding="utf-8"
            )
            report = audit_conversation_sources(root)

        self.assertEqual(report["localeCatalogs"], ["translations/EN.json"])
        duplicates = [
            issue for issue in report["issues"]
            if issue["code"] == "duplicate_filename_stem"
        ]
        self.assertEqual(len(duplicates), 1)
        self.assertEqual(duplicates[0]["details"]["stem"], "conversation")
        self.assertIn("authoring_locale_catalogs_present", {issue["code"] for issue in report["issues"]})


if __name__ == "__main__":
    unittest.main()
