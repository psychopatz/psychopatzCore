"""G7 acceptance tests: structural ownership, compacted recipe, dynamic family cleanup, and canonical CLI."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.generation_recipe import (
    DEFAULT_RECIPE_PATH,
    load_generation_recipe,
)
from tools.semantic_harness.codebuilder.reconcile import reconcile_apply
from tools.semantic_harness.tests.convo_engine_test_support import (
    _build_three_repo_fixture,
    _write_json,
)


class SemanticGenerationOwnershipAndCleanupTests(unittest.TestCase):
    def test_steady_state_recipe_is_structurally_compact(self) -> None:
        recipe = load_generation_recipe(DEFAULT_RECIPE_PATH)
        self.assertEqual(recipe.surface("conversation_lua").preserved_by_owner, {})
        self.assertEqual(recipe.surface("conversation_translations").preserved_by_owner, {})
        self.assertLessEqual(len(recipe.retired), 5)
        for entry in recipe.retired:
            self.assertEqual(entry.kind, "directory_glob")

    def test_dynamic_family_add_and_delete_requires_no_recipe_or_receipt_edit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)

            # Register external pattern for the synthetic UI suggestion
            core_manifest = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
            )
            manifest_doc = json.loads(core_manifest.read_text(encoding="utf-8"))
            manifest_doc["externalReferences"] = {"patternIDs": ["pnc.test.probe"]}
            _write_json(core_manifest, manifest_doc)

            # Seed ordinary application translations and hand-written engine Lua
            char_json = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/translation/EN/Character/Character.json"
            )
            _write_json(char_json, {"UI_PNC_SemanticAddress_Test": "Keep ordinary asset"})
            engine_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/DialogueBlocks.lua"
            )
            engine_lua.parent.mkdir(parents=True, exist_ok=True)
            engine_lua.write_text("-- ConvoEngine: hand-written adapter\nreturn {}\n", encoding="utf-8")

            core_ui_en = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/translation/EN/Conversation/UI.json"
            )
            _write_json(core_ui_en, {"UI_PsychopatzConversation_Keep": "Core authored UI"})

            # Add brand-new canonical family F
            family_f = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/temp_probe/dynamic_probe.json"
            )
            _write_json(
                family_f,
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "namespace": "temp_probe",
                    "id": "dynamic_probe",
                    "owner": "PsychopatzCore",
                    "participants": {"speaker": ["participant"], "addressee": ["participant"]},
                    "invoke": {
                        "intent": "QUESTION",
                        "speechAct": "QUESTION",
                        "subject": "WELLBEING",
                        "patternID": "pnc.test.probe",
                    },
                    "affordance": {"label": {"EN": "Ask probe", "TL": "Tanong probe"}},
                    "say": {"EN": "Probe question?", "TL": "Tanong probe?"},
                    "reply": {"acknowledged": {"say": {"EN": "Probe reply.", "TL": "Sagot probe."}}},
                    "metadata": {
                        "textNamespace": "UI_PNC_Conversation_Suggestion",
                        "textTarget": "convo/DynamicProbe",
                        "textRows": [
                            {
                                "key": "dynamic_probe.extra",
                                "text": {"EN": "Probe extra.", "TL": "Dagdag probe."},
                            }
                        ],
                        "ui": {
                            "id": "question.dynamic_probe",
                            "order": 99,
                            "topic": "wellbeing",
                            "domain": "wellbeing",
                        },
                    },
                },
            )

            # Pass 1: apply WITHOUT receipt_root or recipe edit
            pass1 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(pass1["clean"])
            gen_lua = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Dialogue/TempProbe.lua"
            )
            gen_text = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/translation/EN/Conversation/Text/convo/DynamicProbe.json"
            )
            self.assertTrue(gen_lua.is_file())
            self.assertTrue(gen_text.is_file())
            self.assertIn(
                "UI_PNC_Conversation_Suggestion_DynamicProbe_Label",
                json.loads(core_ui_en.read_text(encoding="utf-8")),
            )

            # Delete canonical family F WITHOUT editing generation_recipe.json
            family_f.unlink()
            family_f.parent.rmdir()

            # Pass 2: apply WITHOUT receipt_root
            pass2 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(pass2["clean"])
            self.assertFalse(gen_lua.exists())
            self.assertFalse(gen_text.exists())
            core_ui_after = json.loads(core_ui_en.read_text(encoding="utf-8"))
            self.assertNotIn("UI_PNC_Conversation_Suggestion_DynamicProbe_Label", core_ui_after)
            self.assertEqual(core_ui_after.get("UI_PsychopatzConversation_Keep"), "Core authored UI")
            self.assertTrue(engine_lua.is_file())
            self.assertTrue(char_json.is_file())

    def test_advertised_canonical_cli_executes_cleanly_in_real_workspace(self) -> None:
        recipe = load_generation_recipe(DEFAULT_RECIPE_PATH)
        cmd = recipe.canonical_cli["check"]
        proc = subprocess.run(
            cmd,
            cwd=CORE_ROOT,
            shell=True,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr or proc.stdout)
        report = json.loads(proc.stdout)
        self.assertTrue(report["clean"], report["counts"])
        self.assertEqual(
            report["enabledOwners"],
            ["PsychopatzCore", "ProjectHoomans", "DTCommon"],
        )
        self.assertEqual(report["counts"]["missing"], 0)
        self.assertEqual(report["counts"]["drifted"], 0)
        self.assertEqual(report["counts"]["stale"], 0)
        self.assertEqual(report["counts"]["retired_present"], 0)
        self.assertEqual(report["counts"]["ambiguous"], 0)


if __name__ == "__main__":
    unittest.main()
