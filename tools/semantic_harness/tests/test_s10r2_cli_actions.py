"""S10R2 headless CLI discovery and option acceptance tests (no Lua worker needed)."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import unittest

from tools.semantic_harness.entrypoints.cli import _parser, cli

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _repo_flags() -> list[str]:
    flags = ["--core-repository", str(CORE_ROOT)]
    if HOOMANS_ROOT.is_dir():
        flags.extend(["--repository", str(HOOMANS_ROOT)])
    else:
        flags.extend(["--repository", str(CORE_ROOT)])
    if DT_ROOT.is_dir():
        flags.extend(["--dynamic-trading-repository", str(DT_ROOT)])
    return flags


def _run_cli(argv: list[str]) -> tuple[int, dict]:
    arguments = _parser().parse_args(argv)
    output = io.StringIO()
    with redirect_stdout(output):
        rc = cli(arguments)
    return rc, json.loads(output.getvalue())


class S10R2CliActionsTests(unittest.TestCase):
    def test_cli_selection_discovery_and_reset_ui_state(self) -> None:
        base = _repo_flags()
        rc_mods, mods_payload = _run_cli(["--list-mods", *base, "--jsonl"])
        self.assertEqual(rc_mods, 0)
        self.assertEqual(mods_payload["schema"], "semantic.harness.mod_manager.v1")
        provider_ids = {item["providerID"] for item in mods_payload["providers"]}
        self.assertIn("PsychopatzCore", provider_ids)

        rc_presets, presets_payload = _run_cli(["--list-presets", *base, "--jsonl"])
        self.assertEqual(rc_presets, 0)
        self.assertEqual(presets_payload["schema"], "semantic.harness.selection_presets.v1")
        preset_ids = {item["presetID"] for item in presets_payload["presets"]}
        self.assertIn("pnc", preset_ids)

        rc_sel, sel_payload = _run_cli([
            "--show-selection",
            "--preset",
            "pnc",
            *base,
            "--jsonl",
        ])
        self.assertEqual(rc_sel, 0)
        self.assertEqual(sel_payload.get("selectionID"), "pnc")

        args = _parser().parse_args(["--gui", "--reset-ui-state"])
        self.assertTrue(args.gui)
        self.assertTrue(args.reset_ui_state)


if __name__ == "__main__":
    unittest.main()
