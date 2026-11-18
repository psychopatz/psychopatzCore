"""Focused unit tests for S9H2 OperationRegistry and ConvoTransaction."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_transaction import ChangeSet
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.psdl_compiler import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import ConvoEngineAuthoringPane
from tools.semantic_harness.tests.convo_engine_test_support import (
    _FakeMessageBox,
    _FakeTk,
    _FakeTtk,
    _FakeWidget,
    _setup_three_repo_workspace,
)


def _sample_doc(
    *,
    owner: str,
    namespace: str,
    family_id: str,
    say: str = "Sample line.",
    after: dict | None = None,
) -> dict:
    payload: dict = {
        "schema": CONVO_ENGINE_SCHEMA,
        "kind": "dialogue",
        "owner": owner,
        "namespace": namespace,
        "id": family_id,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "GREET"},
        "affordance": {"label": f"Say {family_id}"},
        "say": say,
        "reply": {"acknowledged": {"say": f"Reply {family_id}."}},
    }
    if after is not None:
        payload["after"] = after
    return payload


class ConvoEngineOperationTransactionTests(unittest.TestCase):
    def test_operation_registry_exposes_eleven_versioned_operations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            listed = service.describe_operations()
            ids = {entry["id"] for entry in listed}
            expected = {
                "workspace.describe",
                "convo.catalog",
                "convo.get",
                "convo.impact",
                "convo.validate",
                "convo.simulate",
                "convo.change.preview",
                "convo.change.apply",
                "convo.build.preview",
                "convo.build.apply",
                "convo.audit",
            }
            self.assertEqual(ids, expected)
            self.assertIsNotNone(service.operations.describe("convo.change.apply"))
            with self.assertRaises(CompileError):
                service.dispatch_operation("convo.does_not_exist", {})

            ws = service.dispatch_operation("workspace.describe", {})
            self.assertEqual(ws["operation"], "workspace.describe")
            self.assertIn("ProjectHoomans", ws["repositories"])

            cat = service.dispatch_operation("convo.catalog", {"limit": 10})
            self.assertGreaterEqual(cat["total"], 1)

            got = service.dispatch_operation("convo.get", {"target": "social.core_greet"})
            self.assertTrue(got["found"])

            impact = service.dispatch_operation("convo.impact", {"target": "social.core_greet"})
            self.assertTrue(impact["found"])

            validated = service.dispatch_operation(
                "convo.validate",
                {"target": "social.core_greet"},
            )
            self.assertTrue(validated["ok"])

            sim = service.dispatch_operation(
                "convo.simulate",
                {"target": "social.core_greet"},
            )
            self.assertEqual(sim["familyID"], "social.core_greet")

            build_prev = service.dispatch_operation("convo.build.preview", {})
            self.assertTrue(build_prev["ok"])
            self.assertTrue(build_prev["previewOnly"])
            self.assertTrue(build_prev["effectFree"])

    def test_preview_is_effect_free_and_apply_creates_routes_by_owner(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            doc = _sample_doc(
                owner="ProjectHoomans",
                namespace="social",
                family_id="tx_created_greet",
            )
            preview = service.dispatch_operation(
                "convo.change.preview",
                {"operation": "create", "document": doc},
            )
            self.assertTrue(preview["ok"], preview)
            planned_path = Path(preview["destPath"])
            self.assertIn(repos["hoomans"].resolve(), planned_path.parents)
            self.assertFalse(planned_path.exists())

            applied = service.dispatch_operation(
                "convo.change.apply",
                {"operation": "create", "document": doc},
            )
            self.assertTrue(applied["ok"], applied)
            self.assertTrue(planned_path.is_file())
            written = json.loads(planned_path.read_text(encoding="utf-8"))
            self.assertEqual(written["id"], "tx_created_greet")

    def test_edit_stale_fingerprint_rejected_and_identity_change_moves_atomically(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            initial = service.dispatch_operation("convo.get", {"target": "social.core_greet"})
            old_path = Path(initial["sourcePath"])
            fp = initial["sourceFingerprint"]

            stale = service.dispatch_operation(
                "convo.change.apply",
                {
                    "operation": "edit",
                    "target": "social.core_greet",
                    "expectedFingerprint": "wrong-fp",
                    "patch": {"say": "Stale edit"},
                },
            )
            self.assertFalse(stale["ok"])
            self.assertTrue(stale["stale"])

            moved = service.convo_transaction.apply(
                ChangeSet(
                    operation="move",
                    target=old_path,
                    expected_fingerprint=fp,
                    requested_identity={
                        "owner": "DTCommon",
                        "namespace": "trade",
                        "id": "moved_greet",
                    },
                    remove_source=True,
                )
            )
            self.assertTrue(moved["ok"], moved)
            new_path = Path(moved["destPath"])
            self.assertFalse(old_path.exists())
            self.assertTrue(new_path.is_file())
            self.assertIn(repos["dt"].resolve(), new_path.parents)
            self.assertEqual(moved["canonicalID"], "trade.moved_greet")

    def test_delete_blocks_dangling_refs_in_service_and_pane_and_allows_unreferenced(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            leaf_doc = _sample_doc(
                owner="PsychopatzCore",
                namespace="social",
                family_id="leaf_topic",
            )
            leaf_res = service.dispatch_operation(
                "convo.change.apply",
                {"operation": "create", "document": leaf_doc},
            )
            self.assertTrue(leaf_res["ok"], leaf_res)
            leaf_path = Path(leaf_res["sourcePath"])

            caller_doc = _sample_doc(
                owner="PsychopatzCore",
                namespace="social",
                family_id="caller_topic",
                after={"recommend": ["social.leaf_topic"]},
            )
            caller_res = service.dispatch_operation(
                "convo.change.apply",
                {"operation": "create", "document": caller_doc},
            )
            self.assertTrue(caller_res["ok"], caller_res)
            caller_path = Path(caller_res["sourcePath"])

            blocked = service.delete_convo_engine_family(
                leaf_path,
                expected_source_fingerprint=leaf_res["sourceFingerprint"],
            )
            self.assertFalse(blocked["ok"])
            self.assertEqual(blocked["blockedBy"], "dangling_references")
            self.assertTrue(blocked["danglingReferences"])
            self.assertTrue(leaf_path.is_file())

            # Unreferenced caller CAN be deleted via pane.delete_family()
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            pane._filter_var.set("social.caller_topic")
            pane._apply_filter()
            pane._family_tree.selection_set(pane._family_tree.get_children()[0])
            pane._family_selected()
            del_res = pane.delete_family()
            self.assertTrue(del_res["ok"], del_res)
            self.assertFalse(caller_path.exists())

            # Now leaf_topic is unreferenced and can be deleted cleanly
            pane._filter_var.set("social.leaf_topic")
            pane._apply_filter()
            pane._family_tree.selection_set(pane._family_tree.get_children()[0])
            pane._family_selected()
            leaf_del = pane.delete_family()
            self.assertTrue(leaf_del["ok"], leaf_del)
            self.assertFalse(leaf_path.exists())


if __name__ == "__main__":
    unittest.main()
