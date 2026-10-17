from __future__ import annotations

import json
from pathlib import Path
import unittest

from asset_harness.core.runtime_manifest import (
    RUNTIME_MANIFEST_KIND,
    RUNTIME_MANIFEST_SCHEMA_VERSION,
    compile_runtime_manifest,
    default_interaction_policy,
    manifest_json,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1] / "projects" / "radio"


class RuntimeManifestTests(unittest.TestCase):
    def test_compiles_all_canonical_pilots_to_game_relative_assets(self) -> None:
        manifest = compile_runtime_manifest(PROJECT_ROOT)
        self.assertEqual(manifest["schema_version"], RUNTIME_MANIFEST_SCHEMA_VERSION)
        self.assertEqual(manifest["manifest_kind"], RUNTIME_MANIFEST_KIND)
        self.assertEqual(len(manifest["devices"]), 10)
        icons = manifest["ui"]["icons"]
        self.assertEqual(icons["image"], "media/ui/Radio/OS/Icons.png")
        self.assertEqual(len(icons["regions"]), 32)
        self.assertEqual(icons["regions"]["icon_contacts"], [0, 0, 64, 64])
        self.assertEqual(
            len({device["fullType"] for device in manifest["devices"]}),
            10,
        )
        for device in manifest["devices"]:
            self.assertTrue(device["chassis"]["pristine"]["image"].startswith("media/ui/"))
            self.assertTrue(device["chassis"]["worn"]["image"].startswith("media/ui/"))
            self.assertTrue(all(
                state["image"].startswith("media/ui/")
                for component in device["components"]
                for state in component["states"].values()
            ))

    def test_w5_policy_and_interactive_components_are_canonical(self) -> None:
        manifest = compile_runtime_manifest(PROJECT_ROOT, device_id="walkie_5")
        device = manifest["devices"][0]
        self.assertEqual(device["fullType"], "Base.WalkieTalkie5")
        self.assertEqual(
            device["interaction"],
            default_interaction_policy("Base.WalkieTalkie5"),
        )
        active = [component["id"] for component in device["components"] if component["interactive"]]
        self.assertEqual(
            active,
            ["back", "down", "home", "left", "ok", "power", "right", "up"],
        )
        hidden = {component["id"] for component in device["components"] if not component["visible"]}
        self.assertEqual(hidden, {"ptt"})
        self.assertEqual(next(item for item in device["components"] if item["id"] == "power")["action"], "power")

    def test_output_is_deterministic(self) -> None:
        first = manifest_json(compile_runtime_manifest(PROJECT_ROOT))
        second = manifest_json(compile_runtime_manifest(PROJECT_ROOT))
        self.assertEqual(first, second)
        self.assertEqual(json.loads(first)["manifest_kind"], RUNTIME_MANIFEST_KIND)

    def test_optimized_runtime_assets_preserve_canvas_positions(self) -> None:
        manifest = compile_runtime_manifest(
            PROJECT_ROOT,
            device_id="walkie_5",
            optimize_assets=True,
        )
        device = manifest["devices"][0]
        self.assertEqual(set(device["shell"]), {"pristine", "worn"})
        power = next(item for item in device["components"] if item["id"] == "power")
        idle = power["states"]["idle"]
        self.assertIn("/Optimized/Components/power/", idle["image"])
        self.assertGreater(idle["x"], 0)
        self.assertGreater(idle["y"], 0)


if __name__ == "__main__":
    unittest.main()
