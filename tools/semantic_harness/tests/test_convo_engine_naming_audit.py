"""Tests for line-level ConvoEngine legacy naming audit and active leakage scan."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_engine_naming_audit import (
    CLASS_ACTIVE_CANONICAL_CLAIM,
    CLASS_ACTIVE_INTERNAL_IDENTIFIER,
    CLASS_ACTIVE_SCHEMA_OR_CONTRACT,
    CLASS_GENERIC_SEMANTIC,
    CLASS_HISTORICAL_NEGATIVE_DETECTION,
    CLASS_OBSOLETE_ALIAS,
    NAMING_AUDIT_SCHEMA,
    audit_legacy_psdl_references,
    scan_active_legacy_name_leakage,
)

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


class ConvoEngineNamingAuditTests(unittest.TestCase):
    def test_live_three_repo_naming_audit_has_zero_active_leakage(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        report = scan_active_legacy_name_leakage(
            core_repository=CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        self.assertEqual(report["schema"], NAMING_AUDIT_SCHEMA)
        self.assertEqual(report["schema"], "psychopatz.convo-engine.naming-audit.v1")
        self.assertTrue(report["ok"], report["violations"][:10])
        self.assertEqual(report["activeCurrentPsdlIdentityCount"], 0, report["violations"][:10])
        self.assertGreaterEqual(report["historicalNegativeDetectionCount"], 1)
        self.assertEqual(report["violations"], [])

    def test_distinguishes_all_classifications_in_synthetic_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            core = root / "psychopatzCore"
            hoomans = root / "ProjectHoomans"
            dt = root / "DynamicTrading"
            for r in (core, hoomans, dt):
                r.mkdir()

            # 1. Generic semantic Lua under Semantics/ with comment-only mention -> generic_semantic_infrastructure
            sem_lua = core / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticIR.lua"
            sem_lua.parent.mkdir(parents=True)
            sem_lua.write_text("-- shared semantic IR contract (historically PSDL-aligned)\nreturn {}\n", encoding="utf-8")

            # 2. Negative rejection fixture asserting legacy rejection -> historical_negative_detection
            neg_test = core / "tools/semantic_harness/tests/test_convo_engine_compiler.py"
            neg_test.parent.mkdir(parents=True)
            neg_test.write_text(
                "def test_rejects_legacy_schema(self):\n"
                "    with self.assertRaises(ValueError):\n"
                '        compile_doc({"schema": "psychopatz.psdl.v2"})\n',
                encoding="utf-8",
            )

            # 3. Active ConvoEngine output in generated Lua and Hoomans translation
            gen_lua = dt / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Dialogue/Trading.lua"
            gen_lua.parent.mkdir(parents=True)
            gen_lua.write_text('return { { templateID = "psdl.action.trade.say_1" } }\n', encoding="utf-8")

            src_json = hoomans / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/wellbeing.json"
            src_json.parent.mkdir(parents=True)
            src_json.write_text(
                json.dumps({
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "namespace": "social",
                    "id": "wellbeing",
                    "say": "How are you?",
                    "metadata": {
                        "textTarget": "psdl/social/wellbeing",
                        "textDomain": "pnc.psdl.social.wellbeing",
                    },
                }),
                encoding="utf-8",
            )

            trans_json = hoomans / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/social/wellbeing.json"
            trans_json.parent.mkdir(parents=True)
            trans_json.write_text('{"opening": "How are you?"}\n', encoding="utf-8")

            # 4. Obsolete alias module
            alias = core / "tools/semantic_harness/studio/psdl_authoring_pane.py"
            alias.parent.mkdir(parents=True)
            alias.write_text("class PSDLAuthoringPane:\n    pass\n", encoding="utf-8")

            # 5. Active naming violation in test filename/content
            ui_test = dt / "tests/dt_psdl_ui_projection_smoke.lua"
            ui_test.parent.mkdir(parents=True)
            ui_test.write_text('assert(true, "PSDL UI projection check")\n', encoding="utf-8")

            report = audit_legacy_psdl_references(
                core_repository=core,
                hoomans_repository=hoomans,
                dynamic_trading_repository=dt,
            )
            self.assertEqual(report["schema"], NAMING_AUDIT_SCHEMA)
            self.assertFalse(report["ok"])
            self.assertGreater(report["activeCurrentPsdlIdentityCount"], 0)
            self.assertGreaterEqual(report["historicalNegativeDetectionCount"], 1)

            by_cls = report["counts"]["byClassification"]
            self.assertGreaterEqual(by_cls.get(CLASS_GENERIC_SEMANTIC, 0), 1)
            self.assertGreaterEqual(by_cls.get(CLASS_HISTORICAL_NEGATIVE_DETECTION, 0), 1)
            self.assertGreaterEqual(by_cls.get(CLASS_OBSOLETE_ALIAS, 0), 1)
            self.assertGreaterEqual(by_cls.get(CLASS_ACTIVE_SCHEMA_OR_CONTRACT, 0), 1)
            self.assertGreaterEqual(by_cls.get(CLASS_ACTIVE_CANONICAL_CLAIM, 0), 1)
            self.assertGreaterEqual(by_cls.get(CLASS_ACTIVE_INTERNAL_IDENTIFIER, 0), 1)

            leakage = scan_active_legacy_name_leakage(
                core_repository=core,
                hoomans_repository=hoomans,
                dynamic_trading_repository=dt,
            )
            self.assertFalse(leakage["ok"])
            flagged_paths = {item["path"] for item in leakage["violations"]}
            self.assertIn("Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Dialogue/Trading.lua", flagged_paths)
            self.assertIn("tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/wellbeing.json", flagged_paths)
            self.assertIn("Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/social/wellbeing.json", flagged_paths)
            self.assertIn("tools/semantic_harness/studio/psdl_authoring_pane.py", flagged_paths)
            self.assertIn("tests/dt_psdl_ui_projection_smoke.lua", flagged_paths)
            self.assertNotIn("tools/semantic_harness/tests/test_convo_engine_compiler.py", flagged_paths)
            self.assertNotIn("Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticIR.lua", flagged_paths)

    def test_audit_rejects_active_leakage_without_path_whitelisting(self) -> None:
        injections = (
            (
                "tools/semantic_harness/codebuilder/targets/pz_packages.json",
                json.dumps({"schema": "psdl.target-registry.v1", "packages": {}}),
            ),
            (
                "tools/semantic_harness/codebuilder/conversation_assembly.py",
                "# PSDL is the canonical authoring surface.\n",
            ),
            (
                "tools/semantic_harness/codebuilder/conversation_compiler.py",
                "def _compiled_psdl_documents(): return []\n",
            ),
            (
                "tools/semantic_harness/ui/studio_surface_builder.py",
                "app.psdl_authoring = app.convo_engine_authoring\n",
            ),
            (
                "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
                json.dumps({"schema": "pnc.conversation.manifest.v1", "sourceRoots": [{"path": "dialogue", "kind": "psdl"}]}),
            ),
            (
                "tools/semantic_harness/tests/test_mixed_file.py",
                "def test_rejects_legacy_schema(self):\n"
                '    self.assertNotEqual(schema, LEGACY_PSDL_SCHEMA)\n'
                "def _compiled_psdl_documents():\n"
                "    return []\n",
            ),
        )
        for rel_path, content in injections:
            with self.subTest(rel_path=rel_path):
                with tempfile.TemporaryDirectory() as tmp:
                    core = Path(tmp) / "psychopatzCore"
                    target = core / rel_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(content, encoding="utf-8")

                    report = scan_active_legacy_name_leakage(core_repository=core)
                    self.assertFalse(report["ok"], f"Expected failure for {rel_path}")
                    self.assertGreaterEqual(report["activeCurrentPsdlIdentityCount"], 1)
                    self.assertIn(rel_path, {v["path"] for v in report["violations"]})


if __name__ == "__main__":
    unittest.main()
