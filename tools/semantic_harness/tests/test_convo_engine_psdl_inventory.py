"""Focused S8R1 tests for first-party PSDL reference classification and leakage scan."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_engine_psdl_inventory import (
    CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
    CLASS_BOUNDED_MIGRATION_OR_FIXTURE,
    CLASS_GENERIC_SEMANTIC,
    CLASS_OBSOLETE_ALIAS,
    classify_psdl_references,
    scan_active_legacy_name_leakage,
)


class ConvoEnginePsdlInventoryTests(unittest.TestCase):
    def test_distinguishes_all_four_inventory_classifications_by_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            core = root / "psychopatzCore"
            hoomans = root / "ProjectHoomans"
            dt = root / "DynamicTrading"
            for r in (core, hoomans, dt):
                r.mkdir()

            # 1. Generic semantic Lua under Semantics/ with prose comment -> generic_semantic_infrastructure
            sem_lua = core / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticIR.lua"
            sem_lua.parent.mkdir(parents=True)
            sem_lua.write_text("-- shared PSDL-compatible IR contract\nreturn {}\n", encoding="utf-8")

            # 2. Bounded migration reader test fixture
            mig_test = core / "tools/semantic_harness/tests/test_convo_engine_compiler.py"
            mig_test.parent.mkdir(parents=True)
            mig_test.write_text(
                'LEGACY_PSDL_SCHEMA = "psychopatz.semantic.dialogue-language.v1"\n',
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

            # Filename with psdl in test dir but no active identity tokens -> bounded fixture, not active!
            ui_test = dt / "tests/dt_psdl_ui_projection_smoke.lua"
            ui_test.parent.mkdir(parents=True)
            ui_test.write_text('assert(true, "PSDL UI projection check")\n', encoding="utf-8")

            report = classify_psdl_references(
                core_repository=core,
                hoomans_repository=hoomans,
                dynamic_trading_repository=dt,
            )
            by_path = {item["path"]: item for item in report["entries"]}

            self.assertEqual(
                by_path["Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticIR.lua"]["classification"],
                CLASS_GENERIC_SEMANTIC,
            )
            self.assertEqual(
                by_path["tools/semantic_harness/tests/test_convo_engine_compiler.py"]["classification"],
                CLASS_BOUNDED_MIGRATION_OR_FIXTURE,
            )
            self.assertEqual(
                by_path["tools/semantic_harness/studio/psdl_authoring_pane.py"]["classification"],
                CLASS_OBSOLETE_ALIAS,
            )
            self.assertEqual(
                by_path["Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Dialogue/Trading.lua"]["classification"],
                CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
            )
            self.assertEqual(
                by_path["tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/wellbeing.json"]["classification"],
                CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
            )
            self.assertEqual(
                by_path["Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/social/wellbeing.json"]["classification"],
                CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
            )
            self.assertEqual(
                by_path["tests/dt_psdl_ui_projection_smoke.lua"]["classification"],
                CLASS_BOUNDED_MIGRATION_OR_FIXTURE,
            )

            leakage = scan_active_legacy_name_leakage(
                core_repository=core,
                hoomans_repository=hoomans,
                dynamic_trading_repository=dt,
            )
            self.assertFalse(leakage["ok"])
            flagged_paths = {item["path"] for item in leakage["violations"]}
            self.assertIn("Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Dialogue/Trading.lua", flagged_paths)
            self.assertIn("tools/semantic_harness/studio/psdl_authoring_pane.py", flagged_paths)
            self.assertNotIn("tests/dt_psdl_ui_projection_smoke.lua", flagged_paths)


if __name__ == "__main__":
    unittest.main()
