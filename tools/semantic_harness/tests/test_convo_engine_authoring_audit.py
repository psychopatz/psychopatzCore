"""Focused S0 tests for the Core-owned ConvoEngine inventory/guard."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_engine_authoring_audit import (
    guard_changed_paths,
)
from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
    audit_convo_engine_workspace,
)
from tools.semantic_harness.codebuilder.convo_engine_naming_audit import (
    scan_active_legacy_name_leakage,
)


class ConvoEngineAuthoringGuardTests(unittest.TestCase):
    def test_rejects_changed_first_party_surfaces_in_all_adopters(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repositories = {
                "PsychopatzCore": root / "core",
                "ProjectHoomans": root / "hoomans",
                "DynamicTrading": root / "trading",
            }
            for repository in repositories.values():
                repository.mkdir()
            result = guard_changed_paths(
                repositories,
                changed_paths={
                    "PsychopatzCore": [
                        "tools/semantic_harness/codebuilder/sources/conversation/content/new.json",
                    ],
                    "ProjectHoomans": [
                        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Conversation/Definitions/New.lua",
                    ],
                    "DynamicTrading": [
                        "tools/providers/dt/codebuilder/sources/conversation/packs/new.json",
                    ],
                },
            )

        self.assertFalse(result["passed"])
        self.assertEqual(len(result["violations"]), 3)
        self.assertEqual(
            {violation["repository"] for violation in result["violations"]},
            {"PsychopatzCore", "ProjectHoomans", "DynamicTrading"},
        )

    def test_allows_convo_engine_records_generated_outputs_and_external_adapters(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repositories = {
                "PsychopatzCore": root / "core",
                "ProjectHoomans": root / "hoomans",
                "DynamicTrading": root / "trading",
            }
            for repository in repositories.values():
                repository.mkdir()
            convo_record = repositories["DynamicTrading"] / "tools/providers/dt/convo_engine/trader.json"
            convo_record.parent.mkdir(parents=True)
            convo_record.write_text(
                json.dumps({
                    "schema": "psychopatz.convo-engine.v1",
                    "kind": "dialogue",
                    "id": "trade.open",
                    "owner": "DTCommon",
                }),
                encoding="utf-8",
            )
            result = guard_changed_paths(
                repositories,
                changed_paths={
                    "PsychopatzCore": [
                        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/Conversation/Registry.lua",
                    ],
                    "ProjectHoomans": [
                        "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Compatibility/ExternalDialogue.lua",
                    ],
                    "DynamicTrading": ["tools/providers/dt/convo_engine/trader.json"],
                },
            )

        self.assertTrue(result["passed"])
        self.assertEqual(result["violations"], [])
        accepted = [item for repo in result["repositories"] for item in repo["accepted"]]
        self.assertIn("convo_engine_record", {item["reason"] for item in accepted})
        self.assertIn("generated_output_or_translation_boundary", {item["reason"] for item in accepted})

    def test_inventory_ignores_interpreter_editor_and_cache_noise(self) -> None:
        from tools.semantic_harness.codebuilder.convo_engine_authoring_audit import (
            _surface_files,
        )

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "tools/semantic_harness/codebuilder/sources/conversation"
            (source / "dialogue").mkdir(parents=True)
            (source / "__pycache__").mkdir()
            (source / "dialogue/authoring.json").write_text("{}", encoding="utf-8")
            (source / "__pycache__/authoring.cpython-311.pyc").write_bytes(b"cache")
            (source / "editor.json~").write_text("{}", encoding="utf-8")
            (source / "authoring.json.swp").write_text("{}", encoding="utf-8")

            files = _surface_files(
                root,
                ["tools/semantic_harness/codebuilder/sources/conversation"],
            )

        self.assertEqual(
            files,
            [
                "tools/semantic_harness/codebuilder/sources/conversation/dialogue/authoring.json",
            ],
        )

    def test_rejects_retired_directory_as_convo_engine_record(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            core = root / "core"
            hoomans = root / "hoomans"
            dt = root / "trading"
            for repo in (core, hoomans, dt):
                repo.mkdir()
            retired_src = core / "tools/semantic_harness/codebuilder/sources/conversation/psdl/authoring.json"
            retired_src.parent.mkdir(parents=True)
            retired_src.write_text("{}", encoding="utf-8")

            retired_dt = dt / "tools/providers/dt/codebuilder/sources/conversation/psdl/trader.json"
            retired_dt.parent.mkdir(parents=True)
            retired_dt.write_text(
                json.dumps({
                    "schema": "psychopatz.semantic.dialogue-language.v1",
                    "kind": "dialogue",
                    "id": "trade.open",
                    "owner": "DTCommon",
                }),
                encoding="utf-8",
            )
            guard_result = guard_changed_paths(
                {"PsychopatzCore": core, "ProjectHoomans": hoomans, "DynamicTrading": dt},
                changed_paths={
                    "PsychopatzCore": [],
                    "ProjectHoomans": [],
                    "DynamicTrading": ["tools/providers/dt/codebuilder/sources/conversation/psdl/trader.json"],
                },
            )
            self.assertFalse(guard_result["passed"])
            accepted_reasons = {
                item["reason"] for repo in guard_result["repositories"] for item in repo["accepted"]
            }
            self.assertNotIn("convo_engine_record", accepted_reasons)

            leakage = scan_active_legacy_name_leakage(core_repository=core, dynamic_trading_repository=dt)
            self.assertFalse(leakage["ok"])
            self.assertGreaterEqual(leakage["activeCurrentPsdlIdentityCount"], 1)

            integrity = audit_convo_engine_workspace(core, check_determinism=False)
            self.assertFalse(integrity["ok"])
            self.assertIn("legacy_psdl_directory", {v["code"] for v in integrity["violations"]})


if __name__ == "__main__":
    unittest.main()
