from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from asset_harness.core.animations import render_animation
from asset_harness.core.export import apply_export, build_export_plan, verify_export
from asset_harness.core.project import default_project, load_project, save_project
from asset_harness.core.regions import connected_components, detect_source_regions, set_region
from asset_harness.core.render import difference_image, render_image, save_png
from asset_harness.core.source import inspect_image, register_source
from asset_harness.core.validation import validate_project
from asset_harness.core.errors import AssetHarnessError


class HarnessFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.project_path = self.root / "walkie.json"
        self.shell_path = self.root / "shell.png"
        shell = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        pixels = shell.load()
        for y in range(32):
            for x in range(32):
                if x < 3 or y < 3 or x >= 29 or y >= 29:
                    pixels[x, y] = (90, 110, 80, 255)
        shell.save(self.shell_path, format="PNG", optimize=False, compress_level=9)
        self.led_path = self.root / "led.png"
        led = Image.new("RGBA", (4, 4), (0, 255, 0, 255))
        led.save(self.led_path, format="PNG", optimize=False, compress_level=9)
        self.project = default_project("fixture", family="walkie", model="test", width=32, height=32)
        self.project["lcd"] = {
            "aperture": [3, 3, 26, 26],
            "backing": [3, 3, 26, 26],
            "content": [6, 6, 20, 20],
            "backing_color": [15, 36, 22, 255],
        }
        self.project["controls"] = [{"id": "select", "rect": [12, 27, 8, 4], "action": "select"}]
        save_project(self.project_path, self.project)
        register_source(self.project_path, self.project, "shell", "shell.png", provenance="synthetic fixture", approved=True)
        register_source(self.project_path, self.project, "led", "led.png", provenance="synthetic fixture", approved=True)
        self.project["layers"] = [
            {"id": "shell_front", "source": "shell", "x": 0, "y": 0, "z": 50, "role": "shell_front"},
            {"id": "led", "source": "led", "x": 14, "y": 4, "z": 80, "role": "led", "states": ["led.green"]},
        ]
        self.project["animations"] = {
            "indicator": {"frames": [
                {"state": "led.off", "duration_ms": 100},
                {"state": "led.green", "duration_ms": 100},
            ]}
        }
        self.project["export"].update({
            "runtime_root": "runtime",
            "device_path": "psychopatz/radio/devices/walkie/test",
        })
        save_project(self.project_path, self.project)

    def tearDown(self) -> None:
        self.directory.cleanup()

    def test_source_inspection_and_connected_components_are_exact(self) -> None:
        result = inspect_image(self.shell_path)
        self.assertEqual(result["width"], 32)
        self.assertTrue(result["has_alpha"])
        proposals = connected_components(Image.open(self.shell_path), min_area=4)
        self.assertEqual(len(proposals), 1)
        self.assertEqual(proposals[0]["rect"], [0, 0, 32, 32])

    def test_render_has_transparent_exterior_opaque_backing_and_state_layer(self) -> None:
        image, metadata = render_image(self.project_path, self.project, state="led.green", content_color="#294d37")
        self.assertEqual(metadata["output_width"], 32)
        self.assertEqual(image.getpixel((0, 0)), (90, 110, 80, 255))
        self.assertEqual(image.getpixel((4, 4)), (15, 36, 22, 255))
        self.assertEqual(image.getpixel((10, 10)), (41, 77, 55, 255))
        self.assertEqual(image.getpixel((15, 5)), (0, 255, 0, 255))

    def test_validation_rejects_filled_lcd_hole(self) -> None:
        self.assertTrue(validate_project(self.project_path, self.project)["ok"])
        self.project["lcd"]["aperture"] = [2, 2, 28, 28]
        result = validate_project(self.project_path, self.project)
        self.assertFalse(result["ok"])
        self.assertIn("LCD_ALPHA_HOLE_FILLED", {item["code"] for item in result["diagnostics"]})

    def test_animation_contact_sheet_and_diff_are_deterministic(self) -> None:
        first = self.root / "first.png"
        second = self.root / "second.png"
        render_animation(self.project_path, self.project, "indicator", first)
        render_animation(self.project_path, self.project, "indicator", second)
        self.assertEqual(first.read_bytes(), second.read_bytes())
        before, _ = render_image(self.project_path, self.project, state="led.off")
        after, _ = render_image(self.project_path, self.project, state="led.green")
        diff, metadata = difference_image(before, after)
        self.assertGreater(metadata["changed_pixels"], 0)
        self.assertIsNotNone(metadata["changed_bounds"])
        self.assertEqual(diff.mode, "RGBA")

    def test_variant_selector_keeps_cosmetic_layers_modular(self) -> None:
        self.project["variants"]["worn"] = {"layers": ["wear"], "description": "fixture wear"}
        self.project["layers"].append({
            "id": "wear", "source": "led", "x": 4, "y": 4, "z": 70,
            "role": "condition", "variants": ["worn"], "opacity": 0.5,
        })
        pristine, _ = render_image(self.project_path, self.project, variant="pristine")
        worn, _ = render_image(self.project_path, self.project, variant="worn")
        self.assertNotEqual(pristine.getpixel((4, 4)), worn.getpixel((4, 4)))
        self.assertTrue(validate_project(self.project_path, self.project)["ok"])

    def test_source_change_is_rejected_by_registered_hash(self) -> None:
        with Image.open(self.shell_path) as image:
            changed = image.convert("RGBA")
        changed.putpixel((0, 0), (1, 2, 3, 255))
        changed.save(self.shell_path, format="PNG", optimize=False, compress_level=9)
        result = validate_project(self.project_path, self.project)
        self.assertFalse(result["ok"])
        self.assertIn("SOURCE_HASH_MISMATCH", {item["code"] for item in result["diagnostics"]})

    def test_export_requires_approved_flag_and_round_trips(self) -> None:
        plan = build_export_plan(self.project_path, self.project)
        self.assertEqual(len(plan["files"]), 2)
        with self.assertRaises(Exception):
            apply_export(self.project_path, self.project, approved=False)
        apply_export(self.project_path, self.project, approved=True)
        self.assertTrue(verify_export(self.project_path, load_project(self.project_path))["ok"])
        with self.assertRaises(Exception):
            apply_export(self.project_path, load_project(self.project_path), approved=True)

    def test_export_rejects_unapproved_source_even_with_cli_approval(self) -> None:
        self.project["sources"]["shell"]["approved"] = False
        with self.assertRaises(AssetHarnessError) as context:
            apply_export(self.project_path, self.project, approved=True)
        self.assertEqual(context.exception.code, "SOURCE_NOT_APPROVED")

    def test_ham_and_manpack_shapes_can_use_variable_control_counts(self) -> None:
        ham_path = self.root / "ham.json"
        ham = default_project("ham_fixture", family="ham", model="desktop", width=4, height=4)
        ham["controls"] = []
        ham["sources"] = {}
        ham["layers"] = [{"id": "front", "source": "led", "x": 0, "y": 0, "z": 50, "role": "shell_front"}]
        save_project(ham_path, ham)
        register_source(ham_path, ham, "led", "led.png", provenance="synthetic HAM fixture", approved=True)
        self.assertTrue(validate_project(ham_path, ham)["ok"])

        manpack_path = self.root / "manpack.json"
        manpack = default_project("manpack_fixture", family="manpack", model="field", width=8, height=8)
        manpack["sources"] = {}
        manpack["controls"] = [{"id": f"knob_{index}", "rect": [index, 0, 1, 1], "action": "adjust"} for index in range(5)]
        manpack["layers"] = [{"id": "front", "source": "led", "x": 0, "y": 0, "z": 50, "role": "shell_front"}]
        save_project(manpack_path, manpack)
        register_source(manpack_path, manpack, "led", "led.png", provenance="synthetic manpack fixture", approved=True)
        self.assertTrue(validate_project(manpack_path, manpack)["ok"])


if __name__ == "__main__":
    unittest.main()
