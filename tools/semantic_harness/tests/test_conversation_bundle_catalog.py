from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_bundle_catalog import (
    CONVERSATION_BUNDLE_SCHEMA,
    write_runtime_bundle_catalogs,
)


class ConversationBundleCatalogTests(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path]:
        source = root / "conversation_bundles.json"
        runtime = root / "runtime"
        source.write_text(
            json.dumps(
                {
                    "schema": CONVERSATION_BUNDLE_SCHEMA,
                    "bundles": [
                        {
                            "bundleId": "conversation.bundle.greetings.neutral.basic",
                            "owner": "ProjectHoomans",
                            "runtimePath": "Conversation/Bundles/greetings/neutral/basic.json",
                            "keys": [
                                {
                                    "key": "opening",
                                    "text": {
                                        "EN": "Hello.",
                                        "TL": "Kumusta.",
                                    },
                                }
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return source, runtime

    def test_rendering_preserves_flat_bundle_shape_and_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(source, runtime)

            self.assertEqual(len(paths), 2)
            self.assertEqual(
                json.loads(
                    (runtime / "EN/Conversation/Bundles/greetings/neutral/basic.json").read_text()
                ),
                {"opening": "Hello."},
            )
            self.assertEqual(
                json.loads(
                    (runtime / "TL/Conversation/Bundles/greetings/neutral/basic.json").read_text()
                ),
                {"opening": "Kumusta."},
            )

    def test_owner_filter_does_not_render_other_packages(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(
                source,
                runtime,
                owner="DTCommon",
            )

            self.assertEqual(paths, [])
            self.assertFalse((runtime / "EN").exists())


if __name__ == "__main__":
    unittest.main()
