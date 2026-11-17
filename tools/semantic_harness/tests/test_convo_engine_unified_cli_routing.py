"""S9H5 tests: unified main CLI (workspace/convo), convo_engine_cli delegation, and legacy PSDL CRUD removal."""

from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.convo_engine_cli import main as convo_cli_main
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.entrypoints.app import main as harness_main
from tools.semantic_harness.entrypoints.cli import _parser

HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _run_harness_cli(argv: list[str]) -> tuple[int, dict]:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = harness_main(argv)
    return rc, json.loads(buf.getvalue())


class ConvoEngineUnifiedCliRoutingTests(unittest.TestCase):
    def test_dead_legacy_psdl_crud_methods_removed_and_legacy_quarantined(self) -> None:
        for removed in (
            "preview_psdl_document",
            "preview_psdl_sources",
            "list_psdl_sources",
            "load_psdl_source",
            "validate_psdl_document",
            "create_psdl_record",
            "edit_psdl_record",
            "duplicate_psdl_record",
            "delete_psdl_record",
            "reorder_psdl_records",
            "write_psdl_source",
        ):
            self.assertFalse(hasattr(SemanticLabAuthoringService, removed), removed)

        service = SemanticLabAuthoringService(core_repository=CORE_ROOT)
        legacy_doc = {
            "schema": "psychopatz.semantic.dialogue-language.v1",
            "kind": "dialogue",
            "id": "social.greeting.quarantine",
            "owner": "PsychopatzCore",
            "on": {"intent": "GREET"},
            "respond": {"EN": "Hello."},
        }
        with self.assertRaises(CompileError):
            service.preview_convo_engine_document(legacy_doc)
        rejected = service.validate_convo_engine_document(legacy_doc)
        self.assertFalse(rejected["ok"])
        allowed = service.validate_convo_engine_document(legacy_doc, allow_legacy_schema=True)
        self.assertTrue(allowed["ok"])

    def test_main_cli_exposes_workspace_and_convo_operations(self) -> None:
        repo_flags = [
            "--repository", str(CORE_ROOT),
            "--core-repository", str(CORE_ROOT),
            "--hoomans-repository", str(HOOMANS_ROOT),
            "--dynamic-trading-repository", str(DT_ROOT),
        ]
        rc_ws, ws_payload = _run_harness_cli(["workspace", "describe", *repo_flags])
        self.assertEqual(rc_ws, 0)
        self.assertTrue(ws_payload["ok"])
        self.assertEqual(set(ws_payload["repositories"].keys()), {"PsychopatzCore", "ProjectHoomans", "DTCommon"})

        rc_ops, ops_payload = _run_harness_cli(["convo", "operations", *repo_flags])
        self.assertEqual(rc_ops, 0)
        op_names = {item.get("id") or item.get("name") for item in ops_payload["operations"]}
        self.assertIn("convo.catalog", op_names)
        self.assertIn("convo.change.apply", op_names)

        rc_cat, cat_payload = _run_harness_cli([
            "convo", "catalog", *repo_flags, "--owner", "DTCommon", "--limit", "10",
        ])
        self.assertEqual(rc_cat, 0)
        self.assertTrue(cat_payload["ok"])
        self.assertGreater(cat_payload["total"], 0)
        self.assertTrue(all(item["owner"] == "DTCommon" for item in cat_payload["items"]))

        rc_get, get_payload = _run_harness_cli(["convo", "get", "action.trade", *repo_flags])
        self.assertEqual(rc_get, 0)
        self.assertTrue(get_payload["ok"])
        self.assertEqual(get_payload["owner"], "DTCommon")

        rc_imp, imp_payload = _run_harness_cli(["convo", "impact", "action.trade", *repo_flags])
        self.assertEqual(rc_imp, 0)
        self.assertTrue(imp_payload["ok"])
        self.assertIn("closureIDs", imp_payload)

    def test_main_cli_and_convo_engine_cli_enforce_legacy_quarantine_and_safe_change(self) -> None:
        gui_args = _parser().parse_args(["--gui", "--ui-state", "state.json"])
        self.assertTrue(gui_args.gui)
        self.assertIsNone(gui_args.command)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            legacy_file = root / "legacy.json"
            legacy_file.write_text(
                json.dumps({
                    "schema": "psychopatz.semantic.dialogue-language.v1",
                    "kind": "dialogue",
                    "id": "social.greeting.quarantine",
                    "owner": "PsychopatzCore",
                    "on": {"intent": "GREET"},
                    "respond": {"EN": "Hi."},
                }),
                encoding="utf-8",
            )
            rc_default, payload_default = _run_harness_cli([
                "convo", "validate",
                "--repository", str(CORE_ROOT),
                "--core-repository", str(CORE_ROOT),
                "--input", str(legacy_file),
            ])
            self.assertEqual(rc_default, 2)
            self.assertFalse(payload_default["ok"])

            rc_optin, payload_optin = _run_harness_cli([
                "convo", "validate",
                "--repository", str(CORE_ROOT),
                "--core-repository", str(CORE_ROOT),
                "--input", str(legacy_file),
                "--allow-legacy",
            ])
            self.assertEqual(rc_optin, 0)
            self.assertTrue(payload_optin["ok"])

            # Create and preview-delete via main CLI convo change in an isolated workspace
            from tools.semantic_harness.tests.convo_engine_test_support import (
                _setup_three_repo_workspace,
            )

            repos = _setup_three_repo_workspace(root / "isolated")
            spec = {
                "schema": "psychopatz.convo-engine.v1",
                "kind": "dialogue",
                "namespace": "social",
                "id": "cli_roundtrip",
                "owner": "DTCommon",
                "participants": {"speaker": ["participant"], "addressee": ["participant"]},
                "invoke": {"intent": "GREET"},
                "say": "Hello from main CLI.",
            }
            rc_chg, chg_payload = _run_harness_cli([
                "convo", "change", "apply",
                "--repository", str(repos["core"]),
                "--core-repository", str(repos["core"]),
                "--hoomans-repository", str(repos["hoomans"]),
                "--dynamic-trading-repository", str(repos["dt"]),
                "--operation", "create",
                "--owner", "DTCommon",
                "--document", json.dumps(spec),
            ])
            self.assertEqual(rc_chg, 0)
            self.assertTrue(chg_payload["ok"])
            self.assertTrue(Path(chg_payload["destPath"]).is_file())

            # convo_engine_cli validate also quarantines legacy by default
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                rc_ce = convo_cli_main([
                    "validate",
                    "--repository", str(CORE_ROOT),
                    "--core-repository", str(CORE_ROOT),
                    "--input", str(legacy_file),
                ])
            self.assertEqual(rc_ce, 2)


if __name__ == "__main__":
    unittest.main()
