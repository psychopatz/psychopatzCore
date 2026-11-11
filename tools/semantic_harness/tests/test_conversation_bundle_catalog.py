from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_bundle_catalog import (
    CONVERSATION_BUNDLE_SCHEMA,
    write_runtime_bundle_catalogs,
)
from tools.semantic_harness.codebuilder.catalog_contract import TRANSLATION_SCHEMA


class ConversationBundleCatalogTests(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path, Path]:
        source = root / "conversation_bundles.json"
        catalogs = root / "translations"
        runtime = root / "runtime"
        catalogs.mkdir()
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
                                    "translationKey": "conversation.bundle.greetings.opening",
                                }
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        for language, text in (("EN", "Hello."), ("TL", "Kumusta.")):
            (catalogs / f"{language}.json").write_text(
                json.dumps(
                    {
                        "schema": TRANSLATION_SCHEMA,
                        "language": language,
                        "fallback": "EN",
                        "entries": {
                            "conversation.bundle.greetings.opening": {
                                "text": text,
                                "sourceShard": "conversation.content.greetings",
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
        return source, catalogs, runtime

    def test_rendering_preserves_flat_bundle_shape_and_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, catalogs, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(source, catalogs, runtime)

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
            source, catalogs, runtime = self._fixture(Path(temporary))
            paths = write_runtime_bundle_catalogs(
                source,
                catalogs,
                runtime,
                owner="DTCommon",
            )

            self.assertEqual(paths, [])
            self.assertFalse((runtime / "EN").exists())


if __name__ == "__main__":
    unittest.main()
