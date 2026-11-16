"""G3 tests: Apply-mode safe cleanup, mixed UI key ownership, and fail-closed transaction safety."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.reconcile import (
    reconcile_apply,
    reconcile_check,
)
from tools.semantic_harness.tests.test_convo_engine_s9h6_build_planner import (
    _build_three_repo_fixture,
    _sample_family,
    _write_json,
)


def _sample_ui_family(*, owner: str, namespace: str, family_id: str, pattern_id: str, order: int) -> dict:
    return {
        "schema": "psychopatz.convo-engine.v1",
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "QUESTION", "speechAct": "QUESTION", "subject": "WELLBEING", "patternID": pattern_id},
        "affordance": {"label": {"EN": f"Ask {family_id}", "TL": f"Itanong {family_id}"}},
        "say": {"EN": f"Tell me {family_id}?", "TL": f"Sabihin {family_id}?"},
        "reply": {"acknowledged": {"say": {"EN": f"Answer {family_id}.", "TL": f"Sagot {family_id}."}}},
        "metadata": {
            "textNamespace": "UI_PNC_Conversation_Suggestion",
            "ui": {
                "id": f"question.{family_id}",
                "order": order,
                "topic": "wellbeing",
                "domain": "wellbeing",
            },
        },
    }


class ReconcileApplyTests(unittest.TestCase):
    def test_generate_a_and_b_then_remove_b_prunes_b_and_preserves_authored_neighbor(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            # Add source B in a separate domain so it emits its own generated Lua shard
            source_b = (
                repos["hoomans"]
                / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/temp_domain/pnc_temp_b.json"
            )
            _write_json(
                source_b,
                _sample_family(owner="ProjectHoomans", namespace="temp_domain", family_id="pnc_temp_b"),
            )

            # Place a structurally marked hand-written adapter neighbor file
            preserved_neighbor = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/DialogueBlocks.lua"
            )
            preserved_bytes = b"-- ConvoEngine: hand-written adapter\nreturn { preserved = true }\n"
            preserved_neighbor.parent.mkdir(parents=True, exist_ok=True)
            preserved_neighbor.write_bytes(preserved_bytes)

            # Apply pass 1 (A + B)
            pass1 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(pass1["clean"])
            shard_a = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/Social.lua"
            )
            shard_b = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/TempDomain.lua"
            )
            self.assertTrue(shard_a.is_file())
            self.assertTrue(shard_b.is_file())
            self.assertEqual(preserved_neighbor.read_bytes(), preserved_bytes)
            preserved_mtime_before = preserved_neighbor.stat().st_mtime_ns

            # Remove source B
            source_b.unlink()

            # Check reports shard B as stale
            check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(check["clean"])
            stale_paths = [item["path"] for item in check["owners"]["ProjectHoomans"]["stale"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/TempDomain.lua",
                stale_paths,
            )

            # Apply pass 2 removes B and keeps A and preserved neighbor byte-stable
            pass2 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(pass2["clean"])
            self.assertTrue(shard_a.is_file())
            self.assertFalse(shard_b.exists())
            self.assertEqual(preserved_neighbor.read_bytes(), preserved_bytes)
            self.assertEqual(preserved_neighbor.stat().st_mtime_ns, preserved_mtime_before)

    def test_mixed_ui_catalog_prunes_removed_generated_key_and_preserves_authored_keys(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            # Register external pattern references in Core manifest for UI suggestions
            manifest_path = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
            )
            manifest_doc = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest_doc["externalReferences"] = {
                "patternIDs": ["pnc.test.alpha", "pnc.test.beta"]
            }
            _write_json(manifest_path, manifest_doc)

            src_alpha = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/ui_alpha.json"
            )
            src_beta = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/ui_beta.json"
            )
            _write_json(
                src_alpha,
                _sample_ui_family(
                    owner="PsychopatzCore",
                    namespace="social",
                    family_id="alpha",
                    pattern_id="pnc.test.alpha",
                    order=10,
                ),
            )
            _write_json(
                src_beta,
                _sample_ui_family(
                    owner="PsychopatzCore",
                    namespace="social",
                    family_id="beta",
                    pattern_id="pnc.test.beta",
                    order=20,
                ),
            )

            # Seed an authored key in PsychopatzCore EN/Conversation/UI.json
            core_ui_en = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/translation/EN/Conversation/UI.json"
            )
            _write_json(
                core_ui_en,
                {"UI_PsychopatzConversation_Authored_Keep": "Authored Core UI String"},
            )

            # Apply pass 1 (alpha + beta)
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            after_pass1 = json.loads(core_ui_en.read_text(encoding="utf-8"))
            self.assertEqual(
                after_pass1.get("UI_PsychopatzConversation_Authored_Keep"),
                "Authored Core UI String",
            )
            self.assertIn("UI_PNC_Conversation_Suggestion_Alpha_Label", after_pass1)
            self.assertIn("UI_PNC_Conversation_Suggestion_Beta_Label", after_pass1)

            # Remove beta source and re-apply
            src_beta.unlink()
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            after_pass2 = json.loads(core_ui_en.read_text(encoding="utf-8"))
            self.assertEqual(
                after_pass2.get("UI_PsychopatzConversation_Authored_Keep"),
                "Authored Core UI String",
            )
            self.assertIn("UI_PNC_Conversation_Suggestion_Alpha_Label", after_pass2)
            self.assertNotIn("UI_PNC_Conversation_Suggestion_Beta_Label", after_pass2)
            self.assertNotIn("UI_PNC_Conversation_Suggestion_Beta_Utterance", after_pass2)

    def test_failed_compile_validation_leaves_existing_outputs_untouched(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )

            # Plant a stale generated file that would be pruned if apply reached mutation stage
            stale_lua = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/StaleIfMutated.lua"
            )
            stale_lua.write_text("-- Generated; do not edit by hand.\nreturn {}\n", encoding="utf-8")

            # Corrupt a canonical source file so compilation fails
            bad_src = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/broken.json"
            )
            _write_json(
                bad_src,
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "namespace": "social",
                    "id": "Invalid Uppercase ID",
                    "owner": "PsychopatzCore",
                },
            )

            with self.assertRaises(CompileError):
                reconcile_apply(
                    repos["hoomans"],
                    core_repository=repos["core"],
                    hoomans_repository=repos["hoomans"],
                    dynamic_trading_repository=repos["dt"],
                    receipt_root=receipt_dir,
                )

            # Existing runtime output and even the planted stale file must be untouched
            self.assertTrue(stale_lua.is_file())


if __name__ == "__main__":
    unittest.main()
