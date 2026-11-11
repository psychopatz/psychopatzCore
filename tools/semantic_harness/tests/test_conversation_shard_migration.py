"""Tests for the explicit Conversation shard envelope migration."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_contract import SHARD_SCHEMA
from tools.semantic_harness.codebuilder.conversation_shard_migration import (
    migrate_manifest_and_tree,
    shard_id_for,
)


class ConversationShardMigrationTests(unittest.TestCase):
    def test_shard_id_is_kind_qualified_and_path_stable(self) -> None:
        self.assertEqual(
            shard_id_for("content/social/reactions.json", "content"),
            "conversation.content.social.reactions",
        )

    def test_migration_dry_run_does_not_write(self) -> None:
        self.assertEqual(SHARD_SCHEMA, "psychopatz.semantic.shard.v2")
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "sources"
            shard = root / "content" / "social.json"
            shard.parent.mkdir(parents=True)
            original = {
                "schema": "pnc.conversation.shard.v1",
                "kind": "content",
                "domain": "social",
                "source": {"name": "Fixture", "owner": "ProjectHoomans", "version": "1"},
                "phraseFamilies": [],
            }
            shard.write_text(json.dumps(original), encoding="utf-8")
            manifest = {
                "schema": "pnc.conversation.manifest.v1",
                "defaultOwner": "ProjectHoomans",
                "registryOwner": "ProjectHoomans",
                "shards": [{"path": "content/social.json", "kind": "content", "domain": "social", "order": 1}],
                "sourceRoots": [],
                "externalShards": [],
            }
            manifest_path = root / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            before_shard = shard.read_text(encoding="utf-8")
            before_manifest = manifest_path.read_text(encoding="utf-8")
            report = migrate_manifest_and_tree(root, apply=False)
            self.assertEqual(report["changedFileCount"], 1)
            self.assertEqual(shard.read_text(encoding="utf-8"), before_shard)
            self.assertEqual(manifest_path.read_text(encoding="utf-8"), before_manifest)
            self.assertIn("manifestPath", report)


if __name__ == "__main__":
    unittest.main()
