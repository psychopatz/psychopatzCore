from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_text_catalog import (
    CONVERSATION_TEXT_MANIFEST_SCHEMA,
    CONVERSATION_TEXT_SOURCE_SCHEMA,
    write_runtime_text_catalogs,
)


class ConversationTextCatalogTests(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path]:
        source_root = root / "text"
        source_root.mkdir()
        runtime = root / "runtime"
        source = {
            "schema": CONVERSATION_TEXT_SOURCE_SCHEMA,
            "sourceId": "conversation.content.greetings",
            "owner": "ProjectHoomans",
            "catalogs": [
                {
                    "catalogId": "conversation.greetings.neutral.opening",
                    "owner": "ProjectHoomans",
                    "target": "greetings/neutral/opening",
                    "entries": [
                        {
                            "key": "opening",
                            "text": {"EN": "Hello.", "TL": "Kumusta."},
                        },
                    ],
                },
                {
                    "catalogId": "conversation.greetings.neutral.weather",
                    "owner": "ProjectHoomans",
                    "target": "greetings/neutral/opening",
                    "entries": [
                        {
                            "key": "weather",
                            "text": {"EN": "Nice weather.", "TL": "Magandang panahon."},
                        },
                    ],
                },
            ],
        }
        (source_root / "greetings.json").write_text(
            json.dumps(source, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest = {
            "schema": CONVERSATION_TEXT_MANIFEST_SCHEMA,
            "sourceSchema": CONVERSATION_TEXT_SOURCE_SCHEMA,
            "sources": [
                {
                    "path": "greetings.json",
                    "sourceId": "conversation.content.greetings",
                    "owner": "ProjectHoomans",
                },
            ],
        }
        manifest_path = source_root / "manifest.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2) + "\n",
            encoding="utf-8",
        )
        return manifest_path, runtime

    def test_rendering_aggregates_focused_sources_and_preserves_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_text_catalogs(source, runtime)

            self.assertEqual(len(paths), 2)
            self.assertEqual(
                json.loads(
                    (runtime / "EN/Conversation/Text/greetings/neutral/opening.json")
                    .read_text(encoding="utf-8")
                ),
                {"opening": "Hello.", "weather": "Nice weather."},
            )
            self.assertEqual(
                json.loads(
                    (runtime / "TL/Conversation/Text/greetings/neutral/opening.json")
                    .read_text(encoding="utf-8")
                ),
                {"opening": "Kumusta.", "weather": "Magandang panahon."},
            )

    def test_owner_filter_does_not_render_other_packages(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            paths = write_runtime_text_catalogs(source, runtime, owner="DTCommon")

            self.assertEqual(paths, [])
            self.assertFalse((runtime / "EN").exists())

    def test_rendering_prunes_stale_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            stale = runtime / "EN/Conversation/Text/old/obsolete.json"
            stale.parent.mkdir(parents=True)
            stale.write_text("{}\n", encoding="utf-8")

            write_runtime_text_catalogs(source, runtime)

            self.assertFalse(stale.exists())

    def test_duplicate_catalog_ids_across_sources_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            source_root = source.parent
            duplicate = json.loads(
                (source_root / "greetings.json").read_text(encoding="utf-8")
            )
            duplicate["sourceId"] = "conversation.content.duplicate"
            (source_root / "duplicate.json").write_text(
                json.dumps(duplicate, indent=2) + "\n",
                encoding="utf-8",
            )
            manifest = json.loads(source.read_text(encoding="utf-8"))
            manifest["sources"].append(
                {
                    "path": "duplicate.json",
                    "sourceId": "conversation.content.duplicate",
                    "owner": "ProjectHoomans",
                }
            )
            source.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "duplicate Conversation text catalog ID"):
                write_runtime_text_catalogs(source, runtime)

    def test_duplicate_entry_keys_across_focused_sources_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            source_root = source.parent
            duplicate = json.loads(
                (source_root / "greetings.json").read_text(encoding="utf-8")
            )
            duplicate["sourceId"] = "conversation.content.duplicate"
            duplicate["catalogs"][0]["catalogId"] = "conversation.greetings.neutral.followup"
            duplicate["catalogs"][1]["catalogId"] = "conversation.greetings.neutral.weather_followup"
            (source_root / "duplicate.json").write_text(
                json.dumps(duplicate, indent=2) + "\n",
                encoding="utf-8",
            )
            manifest = json.loads(source.read_text(encoding="utf-8"))
            manifest["sources"].append(
                {
                    "path": "duplicate.json",
                    "sourceId": "conversation.content.duplicate",
                    "owner": "ProjectHoomans",
                }
            )
            source.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "duplicate Conversation text key"):
                write_runtime_text_catalogs(source, runtime)

    def test_generic_targets_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            source_root = source.parent
            document = json.loads(
                (source_root / "greetings.json").read_text(encoding="utf-8")
            )
            document["catalogs"][0]["target"] = "greetings/neutral/basic"
            (source_root / "greetings.json").write_text(
                json.dumps(document, indent=2) + "\n", encoding="utf-8"
            )

            with self.assertRaisesRegex(ValueError, "generic segment"):
                write_runtime_text_catalogs(source, runtime)

    def test_runtime_paths_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source, runtime = self._fixture(Path(temporary))
            source_root = source.parent
            document = json.loads(
                (source_root / "greetings.json").read_text(encoding="utf-8")
            )
            document["catalogs"][0]["runtimePath"] = (
                "Conversation/Text/greetings/neutral/opening.json"
            )
            (source_root / "greetings.json").write_text(
                json.dumps(document, indent=2) + "\n", encoding="utf-8"
            )

            with self.assertRaisesRegex(ValueError, "semantic target"):
                write_runtime_text_catalogs(source, runtime)


if __name__ == "__main__":
    unittest.main()
