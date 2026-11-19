from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder.convo_engine_authoring import strip_stale_migration_metadata
from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
    audit_convo_engine_workspace,
    discover_convo_engine_repositories,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


HOOMANS_ROOT = ROOT.parent / "ProjectHoomans"
DT_ROOT = ROOT.parent / "DynamicTrading"


class ConvoEngineIntegrityAndDeterminismAuditTests(unittest.TestCase):
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

    def test_live_three_repository_integrity_audit_and_two_pass_determinism(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        report = audit_convo_engine_workspace(
            ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            check_determinism=True,
        )
        self.assertTrue(report["ok"], f"Audit violations: {report['violations']}")
        self.assertGreaterEqual(report["stats"]["familyFilesChecked"], 400)
        self.assertEqual(report["stats"]["psdlDirectories"], 0)
        self.assertEqual(report["stats"]["catalogLuaLeaves"], 0)
        self.assertEqual(report["stats"]["legacyRuntimeDirectories"], 0)
        self.assertEqual(report["stats"]["activeCurrentPsdlIdentityCount"], 0)
        self.assertEqual(report["stats"]["legacyNameViolations"], 0)
        self.assertGreaterEqual(report["stats"]["historicalNegativeDetectionCount"], 1)
        self.assertEqual(report["determinism"]["diffs"], [])
        self.assertGreaterEqual(report["compiled"]["convoPlans"], 400)

    def test_rejects_active_legacy_symbols_in_codebuilder_ui_studio_entrypoints(self) -> None:
        import ast
        from tools.semantic_harness.codebuilder.convo_engine_naming_audit import (
            _ALLOWED_AUDIT_IDENTIFIERS,
            _HISTORICAL_PREFIX_IDENT_RE,
        )

        allowed_audit_symbols = set(_ALLOWED_AUDIT_IDENTIFIERS) | {
            "psdl_dirs",
            "_PSDL_RE",
            "path_has_psdl",
            "text_has_psdl",
        }
        harness_root = ROOT / "tools" / "semantic_harness"
        findings: list[str] = []
        for sub in ("codebuilder", "ui", "studio", "entrypoints"):
            sub_dir = harness_root / sub
            if not sub_dir.is_dir():
                continue
            for py_path in sorted(sub_dir.rglob("*.py")):
                rel = py_path.relative_to(ROOT).as_posix()
                tree = ast.parse(py_path.read_text(encoding="utf-8"), str(py_path))
                for node in ast.walk(tree):
                    candidates: list[str] = []
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                        candidates.append(node.name)
                    elif isinstance(node, ast.Name):
                        candidates.append(node.id)
                    elif isinstance(node, ast.Attribute):
                        candidates.append(node.attr)
                    for name in candidates:
                        if "psdl" not in name.lower():
                            continue
                        if name in allowed_audit_symbols or _HISTORICAL_PREFIX_IDENT_RE.match(name):
                            continue
                        findings.append(f"{rel}:{getattr(node, 'lineno', 0)}:{name}")
        self.assertEqual(findings, [])

        studio_builder = harness_root / "ui" / "studio_surface_builder.py"
        if studio_builder.is_file():
            studio_src = studio_builder.read_text(encoding="utf-8")
            self.assertNotIn("psdl_authoring", studio_src)
            self.assertNotIn("psdl_frame", studio_src)

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

    def test_service_exposes_integrity_audit(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        svc = SemanticLabAuthoringService(
            HOOMANS_ROOT,
            core_repository=ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        report = svc.run_convo_engine_integrity_audit(check_determinism=False)
        self.assertTrue(report["ok"], f"Service audit violations: {report['violations']}")
        self.assertEqual(report["stats"]["legacyNameViolations"], 0)

    def test_audit_rejects_active_psdl_output_domains_text_and_obsolete_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fake_core = Path(tmp) / "psychopatzCore"
            fake_hoomans = Path(tmp) / "ProjectHoomans"
            core_src = fake_core / "tools/semantic_harness/codebuilder/sources/conversation"
            (core_src / "dialogue/social").mkdir(parents=True, exist_ok=True)
            (core_src / "manifest.json").write_text(
                json.dumps({"schema": "pnc.conversation.manifest.v1", "defaultOwner": "PsychopatzCore", "shards": []}),
                encoding="utf-8",
            )
            (core_src / "dialogue/social/good.json").write_text(
                json.dumps({
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "namespace": "social",
                    "id": "good",
                    "say": {"1": "psdl.social.leaked"},
                }),
                encoding="utf-8",
            )
            obsolete_alias = fake_core / "tools/semantic_harness/studio/psdl_authoring_pane.py"
            obsolete_alias.parent.mkdir(parents=True, exist_ok=True)
            obsolete_alias.write_text("PSDLAuthoringPane = object\n", encoding="utf-8")

            hoomans_src = fake_hoomans / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social"
            hoomans_src.mkdir(parents=True, exist_ok=True)
            (hoomans_src / "sample.json").write_text(
                json.dumps({
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "namespace": "social",
                    "id": "sample",
                    "metadata": {
                        "textTarget": "psdl/social/bad",
                        "textDomain": "pnc.psdl.social.bad",
                    },
                    "say": "Hello.",
                }),
                encoding="utf-8",
            )
            bad_tr = fake_hoomans / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/bad.json"
            bad_tr.parent.mkdir(parents=True, exist_ok=True)
            bad_tr.write_text("{}\n", encoding="utf-8")
            bad_gen = fake_hoomans / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/Bad.lua"
            bad_gen.parent.mkdir(parents=True, exist_ok=True)
            bad_gen.write_text(
                'return { ["kind"] = "PSDL", templateID = "psdl.social.bad" }\n',
                encoding="utf-8",
            )
            bad_caller = fake_hoomans / "Contents/mods/ProjectHoomans/42.20/media/lua/client/Caller.lua"
            bad_caller.parent.mkdir(parents=True, exist_ok=True)
            bad_caller.write_text('local p = "Conversation/Text/psdl/bad.json"\n', encoding="utf-8")

            report = audit_convo_engine_workspace(
                fake_core,
                hoomans_repository=fake_hoomans,
                check_determinism=False,
                require_all_owners=True,
            )
            self.assertFalse(report["ok"])
            self.assertGreaterEqual(report["stats"]["legacyNameViolations"], 5)
            codes = {v["code"] for v in report["violations"]}
            self.assertIn("active_legacy_psdl_identity", codes)
            self.assertIn("obsolete_psdl_compatibility_alias", codes)
            self.assertIn("missing_mandatory_repository", codes)
            flagged_paths = {v["path"] for v in report["violations"]}
            self.assertIn("tools/semantic_harness/studio/psdl_authoring_pane.py", flagged_paths)
            self.assertIn("tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/sample.json", flagged_paths)
            self.assertIn("Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/bad.json", flagged_paths)
            self.assertIn("Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/Bad.lua", flagged_paths)
            self.assertIn("Contents/mods/ProjectHoomans/42.20/media/lua/client/Caller.lua", flagged_paths)

    def test_service_and_discovery_fail_closed_when_missing_or_ambiguous(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fake_core = Path(tmp) / "psychopatzCore"
            src = fake_core / "tools/semantic_harness/codebuilder/sources/conversation"
            src.mkdir(parents=True, exist_ok=True)
            (src / "manifest.json").write_text("{}", encoding="utf-8")

            svc = SemanticLabAuthoringService(fake_core, core_repository=fake_core)
            report = svc.run_convo_engine_integrity_audit(check_determinism=False)
            self.assertFalse(report["ok"])
            self.assertIn("missing_mandatory_repository", {v["code"] for v in report["violations"]})

            for dup in ("HoomansA", "HoomansB"):
                d = Path(tmp) / dup
                (d / "tools/providers/pnc/codebuilder/sources/conversation").mkdir(parents=True, exist_ok=True)
                (d / "Contents/mods/ProjectHoomans").mkdir(parents=True, exist_ok=True)
            with self.assertRaises(CompileError):
                discover_convo_engine_repositories(fake_core)

    def test_bare_cli_invocation_audits_all_three_repositories(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        proc = subprocess.run(
            [
                sys.executable,
                "tools/semantic_harness/codebuilder/convo_engine_cli.py",
                "audit-integrity",
            ],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        payload = json.loads(proc.stdout)
        self.assertTrue(payload["ok"], payload["violations"])
        self.assertEqual(
            set(payload["stats"]["owners"]),
            {"PsychopatzCore", "ProjectHoomans", "DTCommon"},
        )
        self.assertEqual(payload["stats"]["legacyNameViolations"], 0)


if __name__ == "__main__":
    unittest.main()
