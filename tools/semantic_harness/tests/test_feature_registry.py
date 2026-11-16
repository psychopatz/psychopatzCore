"""S10C Feature Acceptance Registry completeness and AST ownership gate."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

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
        self.assertGreaterEqual(result["featureCount"], 20)
        self.assertGreaterEqual(result["discoveredUiControls"], 25)
        self.assertGreaterEqual(result["discoveredCliCommands"], 8)

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


if __name__ == "__main__":
    unittest.main()
