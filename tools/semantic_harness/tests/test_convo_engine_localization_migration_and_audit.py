"""Tests for T2 fail-closed localization audits and T3 CodeBuilder translation migration."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.convo_engine_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.convo_engine_localization_audit import (
    CONVO_TRANSLATION_SCHEMA,
    classify_family_localization,
    deterministic_translation_path,
)
from tools.semantic_harness.codebuilder.convo_engine_translation_migration import (
    hydrate_family_translations,
    migrate_family_document,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConvoEngineLocalizationMigrationAndAuditTests(unittest.TestCase):
    def test_migrate_inline_and_sidecar_fails_closed_on_conflict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src_root = Path(tmp) / "sources/conversation"
            fam_dir = src_root / "dialogue/demo"
            sc_dir = fam_dir / "translations"
            sc_dir.mkdir(parents=True)
            fam_path = fam_dir / "demo_family.json"
            (sc_dir / "demo_family.en.json").write_text(
                json.dumps({"variants": {"default": ["Sidecar EN"]}}),
                encoding="utf-8",
            )
            doc = {
                "schema": "psychopatz.convo-engine.v1",
                "id": "demo.family",
                "owner": "PsychopatzCore",
                "textSidecars": {"EN": "translations/demo_family.en.json"},
                "say": {
                    "variants": [
                        {"id": "default", "text": {"EN": ["Different Inline EN"]}},
                    ],
                },
            }
            with self.assertRaises(CompileError):
                migrate_family_document(doc, fam_path, src_root)

    def test_migrate_roundtrip_hydrates_and_compiles_identically(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src_root = Path(tmp) / "sources/conversation"
            fam_dir = src_root / "dialogue/demo"
            fam_dir.mkdir(parents=True)
            fam_path = fam_dir / "demo_family.json"
            doc = {
                "schema": "psychopatz.convo-engine.v1",
                "id": "demo.family",
                "owner": "PsychopatzCore",
                "affordance": {
                    "label": {"EN": "Ask demo", "TL": "Magtanong"},
                },
                "say": {
                    "variants": [
                        {"id": "default", "text": {"EN": ["Hello."], "TL": ["Kumusta."]}},
                    ],
                },
                "reply": {
                    "ok": {
                        "say": {"EN": "Sure.", "TL": "Sige."},
                    },
                },
            }
            before_compiled = compile_convo_engine_document(doc, source_path=fam_path)
            stripped, by_locale, _legacy = migrate_family_document(doc, fam_path, src_root)

            # Stripped semantic source has zero inline locale maps
            info = classify_family_localization(stripped, fam_path, src_root)
            self.assertEqual(info["shape"], "NO_LOCALIZED_TEXT")
            self.assertEqual(info["inlinePaths"], [])

            # Write canonical translation files
            for lang, entries in by_locale.items():
                tr_path = deterministic_translation_path(src_root, fam_path, lang)
                tr_path.parent.mkdir(parents=True, exist_ok=True)
                tr_path.write_text(
                    json.dumps({
                        "schema": CONVO_TRANSLATION_SCHEMA,
                        "family": "demo.family",
                        "locale": lang,
                        "entries": entries,
                    }),
                    encoding="utf-8",
                )
            fam_path.write_text(json.dumps(stripped), encoding="utf-8")

            # After writing canonical translation files, shape is CANONICAL_EXTERNAL_TRANSLATION
            info_after = classify_family_localization(stripped, fam_path, src_root)
            self.assertEqual(info_after["shape"], "CANONICAL_EXTERNAL_TRANSLATION")
            self.assertEqual(info_after["canonicalLocales"], ["EN", "TL"])

            # Compiling the stripped file hydrates from canonical translation files identically
            after_compiled = compile_convo_engine_document(stripped, source_path=fam_path)
            self.assertEqual(
                before_compiled["records"][0]["payload"],
                after_compiled["records"][0]["payload"],
            )

            # Direct round-trip helper check
            hydrated = hydrate_family_translations(stripped, by_locale)
            self.assertEqual(hydrated["affordance"]["label"], {"EN": "Ask demo", "TL": "Magtanong"})


if __name__ == "__main__":
    unittest.main()
