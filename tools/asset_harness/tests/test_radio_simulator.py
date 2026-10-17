from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "asset_harness" / "simulator_cli.py"
sys.path.insert(0, str(ROOT))

from asset_harness.simulator import RadioSimulator, list_project_refs  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402
from asset_harness.simulator.radio_ui import RADIO_UI_PATH, sprite  # noqa: E402


class RadioSimulatorTests(unittest.TestCase):
    def test_canonical_registry_contains_walkie_ham_and_manpack_devices(self) -> None:
        projects = list_project_refs()
        families = {project.family for project in projects}
        self.assertEqual(families, {"walkie", "ham", "manpack"})
        self.assertEqual(len(projects), 10)

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

    def test_canonical_projects_do_not_expose_removed_controls(self) -> None:
        simulator = RadioSimulator("walkie_1")
        allowed = {"back", "center", "down", "home", "left", "ok", "power", "right", "up"}
        for project in list_project_refs():
            candidate = RadioSimulator(project.device_id)
            ids = {control.id for control in candidate.geometry.controls}
            self.assertTrue(ids <= allowed, project.device_id)
            self.assertNotIn("channel", ids, project.device_id)
            self.assertNotIn("volume", ids, project.device_id)
            self.assertNotIn("ptt", ids, project.device_id)

        with self.assertRaises(ValueError):
            simulator.dispatch({"event": "pointer_down", "control": "side_right_down"})

    def test_every_canonical_device_exposes_soft_back_home_and_power_reopens(self) -> None:
        for project in list_project_refs():
            simulator = RadioSimulator(project.device_id)
            controls = simulator.geometry.controls
            self.assertIn("back", {control.id for control in controls}, project.device_id)
            self.assertIn("home", {control.id for control in controls}, project.device_id)
            simulator.dispatch({"event": "press", "control": "power"})
            simulator.dispatch({"event": "press", "control": "back"})
            self.assertTrue(simulator.state.closed, project.device_id)
            simulator.dispatch({"event": "press", "control": "power"})
            self.assertTrue(simulator.state.powered, project.device_id)
            self.assertFalse(simulator.state.closed, project.device_id)

    def test_canonical_interactive_hitboxes_are_disjoint(self) -> None:
        for project in list_project_refs():
            controls = list(RadioSimulator(project.device_id).geometry.controls)
            for index, first in enumerate(controls):
                first_left, first_top, first_width, first_height = first.rect
                for second in controls[index + 1:]:
                    second_left, second_top, second_width, second_height = second.rect
                    overlap_width = min(first_left + first_width, second_left + second_width) - max(first_left, second_left)
                    overlap_height = min(first_top + first_height, second_top + second_height) - max(first_top, second_top)
                    self.assertFalse(
                        overlap_width > 0 and overlap_height > 0,
                        f"{project.device_id}: {first.id} overlaps {second.id}",
                    )

    def test_walkie_power_uses_the_authored_side_button_except_w5(self) -> None:
        side_power_walkies = {"walkie_1", "walkie_2", "walkie_3", "walkie_4", "walkie_makeshift"}
        for project in list_project_refs():
            payload = json.loads(project.path.read_text(encoding="utf-8"))
            modular = payload["modular"]["components"]
            power = modular["power"]
            power_images = [state["image"] for state in power["states"].values() if isinstance(state, dict)]
            if project.device_id in side_power_walkies:
                self.assertEqual(power["hitbox"], modular["ptt"]["hitbox"], project.device_id)
                self.assertTrue(all("/PTT/" in image for image in power_images), project.device_id)
                self.assertNotIn("Buttons/Power", " ".join(power_images), project.device_id)
            elif project.device_id == "walkie_5":
                self.assertTrue(any("Buttons/Power" in image for image in power_images), project.device_id)

    def test_pristine_and_worn_chassis_art_are_distinct(self) -> None:
        for project in list_project_refs():
            pristine_path = RadioSimulator(project.device_id).device.asset_path
            worn_path = pristine_path.with_name("Worn.png")
            with Image.open(pristine_path) as pristine_source, Image.open(worn_path) as worn_source:
                pristine = pristine_source.convert("RGBA")
                worn = worn_source.convert("RGBA")
            self.assertEqual(pristine.size, worn.size, project.device_id)
            self.assertIsNotNone(ImageChops.difference(pristine, worn).getbbox(), project.device_id)

    def test_removed_rotary_controls_are_not_dispatchable(self) -> None:
        simulator = RadioSimulator("ham_1")
        for event in (
            {"event": "wheel", "control": "channel", "delta": 3},
            {"event": "pointer_down", "control": "volume"},
        ):
            with self.assertRaises(ValueError):
                simulator.dispatch(event)

    def test_back_uses_bounded_page_stack(self) -> None:
        simulator = RadioSimulator("walkie_5")
        simulator.dispatch({"event": "press", "control": "power"})
        simulator.dispatch({"event": "press", "control": "ok"})
        simulator.dispatch({"event": "press", "control": "ok"})
        self.assertEqual(simulator.state.page, "contact_detail")
        simulator.dispatch({"event": "press", "control": "back"})
        self.assertEqual(simulator.state.page, "contacts")
        simulator.dispatch({"event": "press", "control": "back"})
        self.assertEqual(simulator.state.page, "home")

    def test_click_and_screen_click_use_source_coordinates(self) -> None:
        simulator = RadioSimulator("walkie_1")
        simulator.dispatch({"event": "press", "control": "power"})
        left = next(control for control in simulator.geometry.controls if control.id == "left")
        simulator.dispatch({"event": "click", "x": left.rect[0] + left.rect[2] / 2, "y": left.rect[1] + left.rect[3] / 2})
        self.assertEqual(simulator.state.menu_index, 1)
        simulator.reset()
        simulator.dispatch({"event": "press", "control": "power"})
        lcd = simulator.geometry.lcd_rect
        simulator.dispatch({"event": "screen_click", "x": lcd[0] + lcd[2] / 2, "y": lcd[1] + lcd[3] / 2})
        self.assertEqual(simulator.state.page, "contacts")

    def test_render_is_rgba_and_returns_hitboxes(self) -> None:
        simulator = RadioSimulator("walkie_1")
        image, metadata = render_device(simulator, zoom=0.25, debug=True)
        self.assertIsInstance(image, Image.Image)
        self.assertEqual(image.mode, "RGBA")
        self.assertEqual(image.size[0], round(metadata["source_size"][0] * 0.25))
        self.assertEqual(image.size[1], round(metadata["source_size"][1] * 0.25))
        self.assertGreaterEqual(len(metadata["controls"]), 6)
        self.assertNotIn("volume", {control["id"] for control in metadata["controls"]})
        self.assertNotIn("channel", {control["id"] for control in metadata["controls"]})
        self.assertTrue(metadata["ui_atlas_exists"])

    def test_every_device_has_bounded_screen_calibration(self) -> None:
        for project in list_project_refs():
            simulator = RadioSimulator(project.device_id)
            spec = simulator.device
            device_id = project.device_id
            sx, sy, sw, sh = simulator.geometry.lcd_rect
            cx, cy, cw, ch = simulator.geometry.screen_content_rect
            self.assertGreaterEqual(sx, 0)
            self.assertGreaterEqual(sy, 0)
            self.assertLessEqual(sx + sw, spec.source_width)
            self.assertLessEqual(sy + sh, spec.source_height)
            self.assertGreaterEqual(cx, sx)
            self.assertGreaterEqual(cy, sy)
            self.assertLessEqual(cx + cw, sx + sw)
            self.assertLessEqual(cy + ch, sy + sh)
            image, metadata = render_device(RadioSimulator(device_id), zoom=0.5)
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(metadata["screen_sprite"], spec.screen_sprite)
            self.assertEqual(len(metadata["screen_content_rect"]), 4)
            power = next(control for control in simulator.geometry.controls if control.id == "power")
            simulator.dispatch(
                {
                    "event": "click",
                    "x": power.rect[0] + power.rect[2] / 2,
                    "y": power.rect[1] + power.rect[3] / 2,
                }
            )
            self.assertTrue(simulator.state.powered)

    def test_worn_geometry_is_registered_separately_from_clean_geometry(self) -> None:
        for project in list_project_refs():
            clean_simulator = RadioSimulator(project.device_id, variant="clean")
            worn_simulator = RadioSimulator(project.device_id, variant="worn")
            clean = clean_simulator.geometry
            worn = worn_simulator.geometry
            self.assertEqual(worn.lcd_rect, clean.lcd_rect)
            self.assertEqual(len(clean.controls), len(worn.controls))
            image, metadata = render_device(worn_simulator, zoom=0.5)
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(metadata["variant"], "worn")
            self.assertEqual(metadata["screen_sprite"], worn.screen_sprite)

            power = next(control for control in worn.controls if control.id == "power")
            simulator = worn_simulator
            simulator.dispatch(
                {
                    "event": "click",
                    "x": power.rect[0] + power.rect[2] / 2,
                    "y": power.rect[1] + power.rect[3] / 2,
                }
            )
            self.assertTrue(simulator.state.powered)
            lcd = worn_simulator.geometry.lcd_rect
            simulator.dispatch(
                {
                    "event": "screen_click",
                    "x": lcd[0] + lcd[2] / 2,
                    "y": lcd[1] + lcd[3] / 2,
                }
            )
            self.assertEqual(simulator.state.page, "contacts")

    def test_screen_surface_uses_flat_atlas_texture_not_second_bezel(self) -> None:
        for project in list_project_refs():
            for variant in ("clean", "worn"):
                geometry = RadioSimulator(project.device_id, variant=variant).geometry
                self.assertTrue(geometry.screen_sprite.startswith("screen_panel_"))
                self.assertNotIn("screen_frame_", geometry.screen_sprite)

    def test_known_worn_sheet_bleed_is_guarded_without_editing_source_art(self) -> None:
        simulator = RadioSimulator("ham_makeshift", variant="worn")
        self.assertEqual(simulator.device.clip_left_for("clean"), 0)
        self.assertEqual(simulator.device.clip_left_for("worn"), 0)
        _, metadata = render_device(simulator, zoom=0.5)
        self.assertEqual(metadata["source_seam_guard_left"], 0)

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

    def test_cli_catalog_lists_semantic_soft_controls(self) -> None:
        result = subprocess.run(
            [sys.executable, str(CLI), "list"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
        devices = json.loads(result.stdout)["data"]["devices"]
        for device in devices:
            self.assertIn("back", device["controls"])
            self.assertIn("home", device["controls"])

    def test_cli_defaults_to_the_canonical_pilot_project(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "w5-default.png"
            result = subprocess.run(
                [
                    sys.executable,
                    str(CLI),
                    "render",
                    "--device",
                    "walkie_5",
                    "--out",
                    str(output),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )
            payload = json.loads(result.stdout)
            self.assertTrue(payload["ok"])
            metadata = payload["data"]["metadata"]
            self.assertEqual(metadata["variant_art_status"], "modular_project_preview")
            self.assertTrue(metadata["source"].endswith("/Chassis/Pristine.png"))
            self.assertEqual(metadata["skipped_components"], ["channel", "ptt", "volume"])
            self.assertEqual(
                {layer["id"] for layer in metadata["layers"]} & {"channel", "ptt", "volume"},
                set(),
            )

    def test_cli_saves_authored_modular_render_when_w5_workspace_exists(self) -> None:
        project = ROOT / "asset_harness" / "projects" / "radio" / "walkie_5_pilot.json"
        if not project.is_file():
            self.skipTest("tracked W5 pilot project is unavailable")
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "w5.png"
            result = subprocess.run(
                [
                    sys.executable,
                    str(CLI),
                    "render",
                    "--project",
                    str(project),
                    "--variant",
                    "pristine",
                    "--out",
                    str(output),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )
            payload = json.loads(result.stdout)
            self.assertTrue(payload["ok"])
            self.assertTrue(output.is_file())
            self.assertEqual(payload["data"]["metadata"]["lcd_rect"], [314, 605, 416, 221])


if __name__ == "__main__":
    unittest.main()
