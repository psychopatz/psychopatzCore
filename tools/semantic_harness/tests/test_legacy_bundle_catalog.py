"""Tests for canonicalizing legacy PNC conversation bundles."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.catalog_contract import TRANSLATION_SCHEMA
from tools.semantic_harness.codebuilder.legacy_bundle_catalog import (
    discover_legacy_bundles,
    migrate_legacy_bundles,
    write_legacy_runtime_catalogs,
)


class LegacyBundleCatalogTests(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path, Path]:
        legacy = root / "conversation"
        for language, text in {
            "EN": "Good morning, {playerFirstName}.",
            "TL": "Magandang umaga, {playerFirstName}.",
        }.items():
            path = legacy / "greetings" / "neutral" / language / "basic.json"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps({"opening": text}), encoding="utf-8")
        catalogs = {}
        for language in ("EN", "TL"):
            path = root / f"{language}.json"
            path.write_text(json.dumps({
                "schema": TRANSLATION_SCHEMA,
                "language": language,
                "fallback": "EN",
                "entries": {},
            }), encoding="utf-8")
            catalogs[language] = path
        return legacy, catalogs["EN"], catalogs["TL"]

    def test_discovery_is_locale_complete_and_stable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            legacy, _, _ = self._fixture(Path(temporary))
            bundles, entries = discover_legacy_bundles(legacy)

        self.assertEqual(len(bundles), 1)
        self.assertEqual(set(entries), {"EN", "TL"})
        self.assertEqual(len(entries["EN"]), len(entries["TL"]))
        self.assertEqual(bundles[0]["runtimePath"], "Conversation/Legacy/greetings/neutral/basic.json")

    def test_dry_run_does_not_write(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            legacy, en_catalog, tl_catalog = self._fixture(Path(temporary))
            manifest = Path(temporary) / "legacy_bundles.json"
            report = migrate_legacy_bundles(
                legacy,
                manifest,
                {"EN": en_catalog, "TL": tl_catalog},
                apply=False,
            )

            self.assertFalse(report["applied"])
            self.assertFalse(manifest.exists())
            self.assertNotIn("conversation.legacy", en_catalog.read_text(encoding="utf-8"))

    def test_runtime_materialization_preserves_flat_bundle_shape(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            legacy, en_catalog, tl_catalog = self._fixture(root)
            manifest = root / "legacy_bundles.json"
            migrate_legacy_bundles(
                legacy,
                manifest,
                {"EN": en_catalog, "TL": tl_catalog},
                apply=True,
            )
            paths = write_legacy_runtime_catalogs(
                manifest,
                root,
                root / "runtime",
            )
            self.assertEqual(len(paths), 2)
            self.assertEqual(
                json.loads((root / "runtime/EN/Conversation/Legacy/greetings/neutral/basic.json").read_text()),
                {"opening": "Good morning, {playerFirstName}."},
            )


if __name__ == "__main__":
    unittest.main()
