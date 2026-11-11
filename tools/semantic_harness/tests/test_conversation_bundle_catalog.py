from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_bundle_catalog import (
    CONVERSATION_BUNDLE_MANIFEST_SCHEMA,
    CONVERSATION_BUNDLE_SHARD_SCHEMA,
    write_runtime_bundle_catalogs,
)


class ConversationBundleCatalogTests(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path]:
        bundle_root = root / "bundles"
        bundle_root.mkdir()
        runtime = root / "runtime"
        shard = {
            "schema": CONVERSATION_BUNDLE_SHARD_SCHEMA,
            "shardId": "conversation.content.greetings",
            "owner": "ProjectHoomans",
            "bundles": [
                {
                    "bundleId": "conversation.bundle.greetings.neutral.basic",
                    "owner": "ProjectHoomans",
                    "runtimePath": "Conversation/Bundles/greetings/neutral/basic.json",
                    "keys": [
                        {
                            "key": "opening",
                            "text": {"EN": "Hello.", "TL": "Kumusta."},
                        },
                    ],
                },
            ],
        }
        (bundle_root / "greetings.json").write_text(
            json.dumps(shard, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest = {
            "schema": CONVERSATION_BUNDLE_MANIFEST_SCHEMA,
            "bundleSchema": CONVERSATION_BUNDLE_SHARD_SCHEMA,
            "shards": [
                {
                    "path": "greetings.json",
                    "shardId": "conversation.content.greetings",
                    "owner": "ProjectHoomans",
                },
            ],
        }
        manifest_path = bundle_root / "manifest.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2) + "\n",
            encoding="utf-8",
        )
        return manifest_path, runtime

    def test_rendering_aggregates_shards_and_preserves_flat_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(source, runtime)

            self.assertEqual(len(paths), 2)
            self.assertEqual(
                json.loads(
                    (runtime / "EN/Conversation/Bundles/greetings/neutral/basic.json")
                    .read_text(encoding="utf-8")
                ),
                {"opening": "Hello."},
            )
            self.assertEqual(
                json.loads(
                    (runtime / "TL/Conversation/Bundles/greetings/neutral/basic.json")
                    .read_text(encoding="utf-8")
                ),
                {"opening": "Kumusta."},
            )

    def test_owner_filter_does_not_render_other_packages(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(source, runtime, owner="DTCommon")

            self.assertEqual(paths, [])
            self.assertFalse((runtime / "EN").exists())

    def test_duplicate_bundle_ids_across_shards_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            bundle_root = source.parent
            duplicate = json.loads(
                (bundle_root / "greetings.json").read_text(encoding="utf-8")
            )
            duplicate["shardId"] = "conversation.content.duplicate"
            (bundle_root / "duplicate.json").write_text(
                json.dumps(duplicate, indent=2) + "\n",
                encoding="utf-8",
            )
            manifest = json.loads(source.read_text(encoding="utf-8"))
            manifest["shards"].append(
                {
                    "path": "duplicate.json",
                    "shardId": "conversation.content.duplicate",
                    "owner": "ProjectHoomans",
                }
            )
            source.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "duplicate Conversation bundle ID"):
                write_runtime_bundle_catalogs(source, runtime)


if __name__ == "__main__":
    unittest.main()
