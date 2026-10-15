from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "asset_harness" / "simulator_cli.py"
sys.path.insert(0, str(ROOT))

from asset_harness.simulator import RadioSimulator, list_devices  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402
from asset_harness.simulator.radio_ui import RADIO_UI_PATH, sprite  # noqa: E402


class RadioSimulatorTests(unittest.TestCase):
    def test_catalog_contains_walkie_ham_and_manpack_devices(self) -> None:
        families = {spec.family for spec in list_devices()}
        self.assertEqual(families, {"walkie", "ham", "manpack"})
        self.assertEqual(len(list_devices()), 10)

    def test_shared_event_path_updates_state_and_navigation(self) -> None:
        simulator = RadioSimulator("walkie_1")
        simulator.dispatch({"event": "press", "control": "power"})
        simulator.dispatch({"event": "press", "control": "center"})
        snapshot = simulator.snapshot()["state"]
        self.assertTrue(snapshot["powered"])
        self.assertEqual(snapshot["page"], "contacts")
        self.assertEqual(snapshot["last_event"], "press")

    def test_failed_event_is_transactional(self) -> None:
        simulator = RadioSimulator("walkie_1")
        before = simulator.snapshot()
        with self.assertRaises(ValueError):
            simulator.dispatch({"event": "set", "field": "volume", "value": 99})
        self.assertEqual(simulator.snapshot(), before)

    def test_click_and_screen_click_use_source_coordinates(self) -> None:
        simulator = RadioSimulator("walkie_1")
        simulator.dispatch({"event": "press", "control": "power"})
        simulator.dispatch({"event": "click", "x": 240, "y": 925})
        self.assertEqual(simulator.state.menu_index, 1)
        simulator.reset()
        simulator.dispatch({"event": "press", "control": "power"})
        simulator.dispatch({"event": "screen_click", "x": 300, "y": 760})
        self.assertEqual(simulator.state.page, "contacts")

    def test_render_is_rgba_and_returns_hitboxes(self) -> None:
        simulator = RadioSimulator("walkie_1")
        image, metadata = render_device(simulator, zoom=0.25, debug=True)
        self.assertIsInstance(image, Image.Image)
        self.assertEqual(image.mode, "RGBA")
        self.assertEqual(image.size[0], round(metadata["source_size"][0] * 0.25))
        self.assertEqual(image.size[1], round(metadata["source_size"][1] * 0.25))
        self.assertEqual(len(metadata["controls"]), 10)
        self.assertTrue(metadata["ui_atlas_exists"])

    def test_every_device_has_bounded_screen_calibration(self) -> None:
        expected_lcd_rects = {
            "walkie_1": (235, 603, 291, 243),
            "walkie_2": (236, 580, 291, 269),
            "walkie_3": (241, 589, 282, 261),
            "walkie_4": (235, 593, 273, 256),
            "walkie_5": (235, 599, 273, 246),
            "walkie_makeshift": (229, 588, 293, 253),
            "ham_1": (207, 592, 285, 115),
            "ham_2": (187, 585, 227, 105),
            "ham_makeshift": (199, 595, 277, 105),
            "manpack": (190, 687, 295, 211),
        }
        specs = {spec.id: spec for spec in list_devices()}
        self.assertEqual({spec.id for spec in list_devices()}, set(expected_lcd_rects))
        for device_id, expected in expected_lcd_rects.items():
            spec = specs[device_id]
            self.assertEqual(spec.lcd_rect, expected)
            sx, sy, sw, sh = spec.lcd_rect
            cx, cy, cw, ch = spec.screen_content_rect
            self.assertGreaterEqual(cx, sx)
            self.assertGreaterEqual(cy, sy)
            self.assertLessEqual(cx + cw, sx + sw)
            self.assertLessEqual(cy + ch, sy + sh)
            image, metadata = render_device(RadioSimulator(device_id), zoom=0.5)
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(metadata["screen_sprite"], spec.screen_sprite)
            self.assertEqual(len(metadata["screen_content_rect"]), 4)
            power = next(control for control in spec.controls if control.id == "power")
            simulator = RadioSimulator(device_id)
            simulator.dispatch(
                {
                    "event": "click",
                    "x": power.rect[0] + power.rect[2] / 2,
                    "y": power.rect[1] + power.rect[3] / 2,
                }
            )
            self.assertTrue(simulator.state.powered)

    def test_worn_geometry_is_registered_separately_from_clean_geometry(self) -> None:
        expected_worn_lcd_rects = {
            "walkie_1": (187, 603, 291, 243),
            "walkie_2": (169, 580, 291, 269),
            "walkie_3": (162, 589, 282, 261),
            "walkie_4": (156, 593, 273, 256),
            "walkie_5": (197, 599, 273, 246),
            "walkie_makeshift": (173, 588, 293, 253),
            "ham_1": (193, 592, 285, 115),
            "ham_2": (179, 590, 249, 105),
            "ham_makeshift": (166, 595, 277, 105),
            "manpack": (190, 687, 295, 211),
        }
        for spec in list_devices():
            clean = spec.geometry_for("clean")
            worn = spec.geometry_for("worn")
            self.assertEqual(worn.lcd_rect, expected_worn_lcd_rects[spec.id])
            self.assertEqual(len(clean.controls), len(worn.controls))
            image, metadata = render_device(RadioSimulator(spec.id, variant="worn"), zoom=0.5)
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(metadata["variant"], "worn")
            self.assertEqual(metadata["screen_sprite"], worn.screen_sprite)

            power = next(control for control in worn.controls if control.id == "power")
            simulator = RadioSimulator(spec.id, variant="worn")
            simulator.dispatch(
                {
                    "event": "click",
                    "x": power.rect[0] + power.rect[2] / 2,
                    "y": power.rect[1] + power.rect[3] / 2,
                }
            )
            self.assertTrue(simulator.state.powered)
            lcd = worn.lcd_rect
            simulator.dispatch(
                {
                    "event": "screen_click",
                    "x": lcd[0] + lcd[2] / 2,
                    "y": lcd[1] + lcd[3] / 2,
                }
            )
            self.assertEqual(simulator.state.page, "contacts")

    def test_screen_surface_uses_flat_atlas_texture_not_second_bezel(self) -> None:
        for spec in list_devices():
            for variant in ("clean", "worn"):
                geometry = spec.geometry_for(variant)
                self.assertTrue(geometry.screen_sprite.startswith("screen_panel_"))
                self.assertNotIn("screen_frame_", geometry.screen_sprite)

    def test_known_worn_sheet_bleed_is_guarded_without_editing_source_art(self) -> None:
        specs = {spec.id: spec for spec in list_devices()}
        self.assertEqual(specs["ham_makeshift"].clip_left_for("clean"), 0)
        self.assertEqual(specs["ham_makeshift"].clip_left_for("worn"), 20)
        _, metadata = render_device(RadioSimulator("ham_makeshift", variant="worn"), zoom=0.5)
        self.assertEqual(metadata["source_seam_guard_left"], 20)

    def test_radio_ui_atlas_is_available_through_named_sprites(self) -> None:
        self.assertTrue(RADIO_UI_PATH.is_file())
        self.assertIsNotNone(sprite("icon_settings"))

    def test_cli_exposes_same_event_protocol(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(CLI),
                "event",
                "--json",
                '{"event":"press","control":"power"}',
                "--json",
                '{"event":"press","control":"center"}',
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
        payload = json.loads(result.stdout)
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["data"]["state"]["page"], "contacts")


if __name__ == "__main__":
    unittest.main()
