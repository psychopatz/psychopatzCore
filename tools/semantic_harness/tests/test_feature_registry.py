"""Feature Acceptance Registry completeness and AST ownership gate."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.entrypoints.cli import _parser
from tools.semantic_harness.testing.feature_registry import (
    load_feature_registry,
    validate_feature_registry,
)

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"


class FeatureRegistryTests(unittest.TestCase):
    def test_feature_registry_covers_all_supported_ui_and_cli_controls(self) -> None:
        hoomans = HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None
        result = validate_feature_registry(CORE_ROOT, hoomans_repo=hoomans)
        self.assertTrue(result["ok"], f"Feature registry errors: {result['errors']}")
        self.assertGreaterEqual(result["featureCount"], 30)
        self.assertGreaterEqual(result["discoveredUiControls"], 25)
        self.assertGreaterEqual(result["discoveredCliCommands"], 8)
        self.assertGreaterEqual(result["discoveredTopLevelCliActions"], 60)

    def test_unmapped_ui_control_fails_registry_validation(self) -> None:
        payload = load_feature_registry()
        payload["features"] = [
            row
            for row in payload["features"]
            if row.get("featureID") != "sweep.dedicated.generate_cancel"
        ]
        with tempfile.TemporaryDirectory() as tmp:
            bad_path = Path(tmp) / "registry.json"
            import json

            bad_path.write_text(json.dumps(payload), encoding="utf-8")
            result = validate_feature_registry(
                CORE_ROOT,
                hoomans_repo=HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None,
                registry_path=bad_path,
            )
            self.assertFalse(result["ok"])
            self.assertTrue(
                any("app.qs_generate_button" in err for err in result["errors"]),
                result["errors"],
            )

    def test_unmapped_new_top_level_cli_action_fails_registry_validation(self) -> None:
        augmented = _parser()
        augmented.add_argument(
            "--hypothetical-new-action",
            action="store_true",
            help="Uncovered public CLI action",
        )
        result = validate_feature_registry(
            CORE_ROOT,
            hoomans_repo=HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None,
            cli_parser=augmented,
        )
        self.assertFalse(result["ok"])
        self.assertTrue(
            any("--hypothetical-new-action" in err for err in result["errors"]),
            result["errors"],
        )

    def test_cli_alias_shares_canonical_feature_without_duplicate_record(self) -> None:
        augmented = _parser()
        augmented.add_argument(
            "--list-datasets-alias",
            dest="list_datasets",
            action="store_true",
        )
        # Same option group alias shares canonical primary flag:
        aliased = _parser()
        aliased.add_argument(
            "--list-mods-v2",
            "--list-mods-alias",
            action="store_true",
        )
        res_missing = validate_feature_registry(
            CORE_ROOT,
            hoomans_repo=HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None,
            cli_parser=aliased,
        )
        self.assertFalse(res_missing["ok"])
        self.assertTrue(any("--list-mods-v2" in err for err in res_missing["errors"]))
        # Adding only primary canonical flag covers the alias on the same option group:
        payload = load_feature_registry()
        payload["features"].append({
            "featureID": "cli.alias_demo",
            "surface": "CLI & Agent Ops",
            "controls": ["--list-mods-v2"],
            "canonicalOperation": "ModManager.describe",
            "providerApplicability": ["all"],
            "mutationClass": "read_only",
            "mandatory": True,
            "requiresRealGui": False,
            "acceptanceOwners": [
                "PsychopatzCore:tools.semantic_harness.tests.test_semantic_harness_cli_discovery:SemanticHarnessCliDiscoveryTests.test_cli_selection_discovery_and_reset_ui_state",
            ],
        })
        with tempfile.TemporaryDirectory() as tmp:
            import json

            reg_path = Path(tmp) / "registry.json"
            reg_path.write_text(json.dumps(payload), encoding="utf-8")
            res_ok = validate_feature_registry(
                CORE_ROOT,
                hoomans_repo=HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None,
                registry_path=reg_path,
                cli_parser=aliased,
            )
            self.assertTrue(res_ok["ok"], res_ok["errors"])


if __name__ == "__main__":
    unittest.main()
