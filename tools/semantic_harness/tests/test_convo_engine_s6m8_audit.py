from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder.convo_engine_authoring import strip_stale_migration_metadata
from tools.semantic_harness.codebuilder.convo_engine_s6m8_audit import audit_convo_engine_workspace
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


HOOMANS_ROOT = ROOT.parent / "ProjectHoomans"
DT_ROOT = ROOT.parent / "DynamicTrading"


class ConvoEngineS6M8AuditTests(unittest.TestCase):
    def test_strip_stale_migration_metadata_removes_migration_only_keys(self) -> None:
        doc = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "namespace": "social",
            "id": "example",
            "sourceSurface": "legacy_ui",
            "migration": {"from": "psdl"},
            "sourceCatalog": "old_catalog.json",
            "originalOwner": "Core",
            "metadata": {
                "runtimeBlockID": "core:example",
                "sourcePath": "psdl/old.json",
                "sourceProfile": "seed",
                "contentOwner": "psychopatz.core",
            },
            "say": "Hello.",
        }
        cleaned = strip_stale_migration_metadata(doc)
        self.assertNotIn("sourceSurface", cleaned)
        self.assertNotIn("migration", cleaned)
        self.assertNotIn("sourceCatalog", cleaned)
        self.assertNotIn("originalOwner", cleaned)
        self.assertNotIn("sourcePath", cleaned["metadata"])
        self.assertNotIn("sourceProfile", cleaned["metadata"])
        self.assertEqual(cleaned["metadata"]["runtimeBlockID"], "core:example")
        self.assertEqual(cleaned["metadata"]["contentOwner"], "psychopatz.core")

    def test_live_three_repository_s6m8_audit_and_two_pass_determinism(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        report = audit_convo_engine_workspace(
            ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            check_determinism=True,
        )
        self.assertTrue(report["ok"], f"Audit violations: {report['violations']}")
        self.assertGreaterEqual(report["stats"]["familyFilesChecked"], 500)
        self.assertEqual(report["stats"]["psdlDirectories"], 0)
        self.assertEqual(report["stats"]["catalogLuaLeaves"], 0)
        self.assertEqual(report["stats"]["legacyRuntimeDirectories"], 0)
        self.assertEqual(report["determinism"]["diffs"], [])
        self.assertGreaterEqual(report["compiled"]["convoPlans"], 500)

    def test_audit_catches_stale_metadata_and_legacy_schema_in_isolated_tree(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fake_core = Path(tmp) / "psychopatzCore"
            src_root = fake_core / "tools/semantic_harness/codebuilder/sources/conversation"
            (src_root / "dialogue/sample").mkdir(parents=True, exist_ok=True)
            (src_root / "manifest.json").write_text(
                json.dumps({"schema": "pnc.conversation.manifest.v1", "defaultOwner": "PsychopatzCore", "shards": []}),
                encoding="utf-8",
            )
            (src_root / "dialogue/sample/bad.json").write_text(
                json.dumps({
                    "schema": "psychopatz.semantic.dialogue-language.v1",
                    "kind": "dialogue",
                    "namespace": "semantic.sample",
                    "id": "line.1",
                    "sourceSurface": "stale",
                    "say": "Hi",
                }),
                encoding="utf-8",
            )
            report = audit_convo_engine_workspace(fake_core, check_determinism=False)
            codes = {v["code"] for v in report["violations"]}
            self.assertFalse(report["ok"])
            self.assertIn("legacy_schema_present", codes)
            self.assertIn("redundant_semantic_prefix", codes)
            self.assertIn("wording_numeric_family_id", codes)
            self.assertIn("stale_migration_metadata", codes)
            self.assertIn("missing_convo_engine_runtime_root", codes)

    def test_service_exposes_s6m8_audit(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        svc = SemanticLabAuthoringService(
            HOOMANS_ROOT,
            core_repository=ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        report = svc.run_convo_engine_s6m8_audit(check_determinism=False)
        self.assertTrue(report["ok"], f"Service audit violations: {report['violations']}")


if __name__ == "__main__":
    unittest.main()
