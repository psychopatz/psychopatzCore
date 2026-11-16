"""G2 tests: Check-mode reconciler detection across Lua, translation, Text, retired, unknown neighbor, and mixed UI catalogs."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.generation_recipe import (
    DEFAULT_RECIPE_PATH,
    validate_generation_recipe,
)
from tools.semantic_harness.codebuilder.reconcile import (
    reconcile_apply,
    reconcile_check,
)
from tools.semantic_harness.tests.test_convo_engine_s9h6_build_planner import (
    _build_three_repo_fixture,
    _write_json,
)


class ReconcileCheckTests(unittest.TestCase):
    def test_check_mode_reports_missing_before_apply_and_never_writes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            before_files = {
                name: sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
                for name, root in repos.items()
            }
            report = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            after_files = {
                name: sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
                for name, root in repos.items()
            }
            self.assertEqual(before_files, after_files)
            self.assertEqual(report["mode"], "check")
            self.assertTrue(report["effectFree"])
            self.assertFalse(report["clean"])
            self.assertGreater(report["counts"]["missing"], 0)
            self.assertEqual(report["counts"]["drifted"], 0)
            self.assertEqual(report["counts"]["stale"], 0)
            self.assertEqual(report["counts"]["retired_present"], 0)
            self.assertEqual(report["counts"]["ambiguous"], 0)

    def test_check_mode_detects_drift_stale_retired_unknown_neighbor_and_mixed_keys(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            # First seed the fixture via reconcile_apply so baseline desired files exist.
            seeded = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(seeded["clean"])

            # 1. Content drift on a generated Lua file
            drifted_lua = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Registry.lua"
            )
            drifted_lua.write_text(
                drifted_lua.read_text(encoding="utf-8") + "-- drifted comment\n",
                encoding="utf-8",
            )

            # 2. Stale proven-owned generated Lua file
            stale_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/ObsoleteShard.lua"
            )
            stale_lua.parent.mkdir(parents=True, exist_ok=True)
            stale_lua.write_text(
                "-- Generated; do not edit by hand.\nreturn {}\n",
                encoding="utf-8",
            )

            # 3. Stale Conversation/Text JSON file
            stale_text = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/obsolete/old_topic.json"
            )
            stale_text.parent.mkdir(parents=True, exist_ok=True)
            stale_text.write_text('{"old": "text"}\n', encoding="utf-8")

            # 4. Preserved authored Lua file declared in recipe
            preserved_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/DialogueBlocks.lua"
            )
            preserved_lua.write_text("-- Hand-authored adapter\nreturn {}\n", encoding="utf-8")

            # 5. Unknown unowned neighbor file inside ConvoEngine root (no generated header, not in preserved list)
            unknown_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/MysteryHandWritten.lua"
            )
            unknown_lua.write_text("-- Custom hand-authored file\nreturn {}\n", encoding="utf-8")

            # 6. Mixed UI catalog with authored key + formerly generated key in receipt + retired key
            ui_rel = "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/UI.json"
            ui_path = repos["hoomans"] / ui_rel
            ui_data = json.loads(ui_path.read_text(encoding="utf-8")) if ui_path.is_file() else {}
            ui_data["UI_Authored_Custom_Survives"] = "Keep me"
            ui_data["UI_Former_Generated_From_Receipt"] = "Prune me via receipt"
            ui_data["UI_Retired_Key_From_Recipe"] = "Prune me via recipe"
            _write_json(ui_path, ui_data)

            # Add UI_Former_Generated_From_Receipt to the ProjectHoomans receipt
            hoomans_receipt_path = receipt_dir / "ProjectHoomans.json"
            receipt_doc = json.loads(hoomans_receipt_path.read_text(encoding="utf-8"))
            ui_rel = "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/UI.json"
            receipt_doc["mixedCatalogGeneratedKeys"].setdefault(ui_rel, []).append(
                "UI_Former_Generated_From_Receipt"
            )
            _write_json(hoomans_receipt_path, receipt_doc)

            # 7. Retired file present on disk
            retired_cmd = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Command.json"
            )
            retired_cmd.parent.mkdir(parents=True, exist_ok=True)
            retired_cmd.write_text('{"legacy.key": "Legacy value"}\n', encoding="utf-8")

            recipe_doc = json.loads(DEFAULT_RECIPE_PATH.read_text(encoding="utf-8"))
            recipe_doc["retired"] = [
                {
                    "id": "retired.test.command_json",
                    "surface": "conversation_translations",
                    "kind": "file",
                    "owner": "ProjectHoomans",
                    "path": "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Command.json",
                    "reason": "test retired domain file",
                },
                {
                    "id": "retired.test.ui_key",
                    "surface": "conversation_ui",
                    "kind": "mixed_keys",
                    "owner": "ProjectHoomans",
                    "path": ui_rel,
                    "keys": ["UI_Retired_Key_From_Recipe"],
                    "reason": "test retired UI key",
                },
            ]
            custom_recipe = validate_generation_recipe(recipe_doc)

            check = reconcile_check(
                repos["hoomans"],
                recipe=custom_recipe,
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )

            self.assertFalse(check["clean"])
            core_rep = check["owners"]["PsychopatzCore"]
            hoomans_rep = check["owners"]["ProjectHoomans"]

            drifted_paths = [item["path"] for item in core_rep["drifted"]]
            self.assertIn(
                "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Registry.lua",
                drifted_paths,
            )

            stale_paths = [item["path"] for item in hoomans_rep["stale"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/ObsoleteShard.lua",
                stale_paths,
            )
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/obsolete/old_topic.json",
                stale_paths,
            )

            retired_paths = [item["path"] for item in hoomans_rep["retired_present"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Command.json",
                retired_paths,
            )
            self.assertIn(ui_rel, retired_paths)

            mixed_stale = hoomans_rep["mixed_stale_keys"]
            self.assertEqual(len(mixed_stale), 1)
            self.assertEqual(
                mixed_stale[0]["keys"],
                ["UI_Former_Generated_From_Receipt", "UI_Retired_Key_From_Recipe"],
            )

            ambiguous_paths = [item["path"] for item in hoomans_rep["ambiguous"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/MysteryHandWritten.lua",
                ambiguous_paths,
            )

            preserved_paths = [item["path"] for item in hoomans_rep["preserved"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/DialogueBlocks.lua",
                preserved_paths,
            )
            self.assertIn(ui_rel, preserved_paths)

            # Verify check mode did not delete or modify any of the seeded test files
            self.assertTrue(stale_lua.is_file())
            self.assertTrue(stale_text.is_file())
            self.assertTrue(retired_cmd.is_file())
            self.assertTrue(unknown_lua.is_file())


if __name__ == "__main__":
    unittest.main()
