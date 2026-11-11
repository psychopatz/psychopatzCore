"""Tests for the Conversation manifest filesystem boundary."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_manifest import (
    load_manifest,
    validate_id,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConversationManifestTests(unittest.TestCase):
    def test_loads_explicit_shard_with_canonical_identity(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            shard_path = root / "content" / "social.json"
            shard_path.parent.mkdir(parents=True)
            shard_path.write_text("{}", encoding="utf-8")
            manifest_path = root / "manifest.json"
            manifest_path.write_text(
                json.dumps({
                    "schema": "pnc.conversation.manifest.v1",
                    "defaultOwner": "ProjectHoomans",
                    "registryOwner": "ProjectHoomans",
                    "sourceProfiles": {"core": {"name": "Core"}},
                    "shards": [{
                        "path": "content/social.json",
                        "kind": "content",
                        "domain": "social",
                        "order": 1,
                        "owner": "ProjectHoomans",
                        "shardId": "conversation.content.social",
                        "sourceProfile": "core",
                    }],
                    "sourceRoots": [],
                    "externalShards": [],
                }),
                encoding="utf-8",
            )

            manifest, entries = load_manifest(root, manifest_path)

        self.assertEqual(manifest["registryOwner"], "ProjectHoomans")
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["shardId"], "conversation.content.social")
        self.assertEqual(entries[0]["path"], "content/social.json")

    def test_rejects_non_canonical_ids_at_boundary(self) -> None:
        with self.assertRaises(CompileError):
            validate_id("Not Canonical", "shardId")


if __name__ == "__main__":
    unittest.main()
