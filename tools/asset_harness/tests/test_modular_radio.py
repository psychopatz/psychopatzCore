from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from asset_harness.core.masks import register_mask, validate_mask  # noqa: E402
from asset_harness.core.modular import render_modular, render_modular_contact_sheet, set_chassis, set_component, set_lcd_layers, validate_modular  # noqa: E402
from asset_harness.core.project import default_project, save_project  # noqa: E402
from asset_harness.core.source import register_source  # noqa: E402
from asset_harness.simulator import RadioSimulator  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402
from asset_harness.simulator_gui import RadioSimulatorApp  # noqa: E402


class ModularRadioTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.project_path = self.root / "radio.json"
        self.project = default_project("radio_fixture", family="walkie", model="pilot", width=16, height=16)
        self.project["workspace_root"] = "."
        save_project(self.project_path, self.project)

        for name, color in (
            ("pristine.png", (40, 50, 60, 255)),
            ("worn.png", (70, 80, 90, 255)),
            ("idle.png", (10, 20, 30, 255)),
            ("pressed.png", (220, 230, 240, 255)),
        ):
            Image.new("RGBA", (16, 16) if name in {"pristine.png", "worn.png"} else (4, 4), color).save(self.root / name, format="PNG", optimize=False, compress_level=9)
        for name, pixel in (("glass.png", (0, 240, 255, 140)), ("bezel.png", (255, 180, 0, 180)), ("matte.png", (20, 30, 40, 160))):
            layer = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
            layer.putpixel((1, 1), pixel)
            layer.save(self.root / name, format="PNG", optimize=False, compress_level=9)
        mask = Image.new("L", (16, 16), 0)
        for y in range(4, 8):
            for x in range(4, 8):
                mask.putpixel((x, y), 255)
        mask.save(self.root / "socket.png", format="PNG", optimize=False, compress_level=9)
        forbidden = Image.new("L", (16, 16), 0)
        forbidden.putpixel((5, 5), 255)
        forbidden.save(self.root / "forbidden.png", format="PNG", optimize=False, compress_level=9)

        register_source(self.project_path, self.project, "pristine", "pristine.png", provenance="synthetic chassis", approved=True)
        register_source(self.project_path, self.project, "worn", "worn.png", provenance="synthetic chassis", approved=True)
        review = {"reviewed": True, "reviewed_by": "synthetic-test", "artifacts": ["fixture-preview.png"]}
        register_mask(self.project_path, self.project, "socket", "socket.png", source_id="pristine", method="hand_authored", status="verified", provenance="synthetic mask", review=review)
        register_mask(self.project_path, self.project, "forbidden", "forbidden.png", method="hand_authored", status="verified", provenance="synthetic guard", review=review)
        save_project(self.project_path, self.project)

    def tearDown(self) -> None:
        self.directory.cleanup()

    def test_mask_qa_rejects_neighbor_contamination_and_rectangles(self) -> None:
        register_mask(self.project_path, self.project, "contaminated", "socket.png", source_id="pristine", method="hand_authored", status="verified", forbidden_mask_id="forbidden")
        self.assertFalse(validate_mask(self.project_path, self.project, "contaminated")["ok"])
        register_mask(self.project_path, self.project, "rectangle", "socket.png", source_id="pristine", method="rectangle", status="verified")
        self.assertFalse(validate_mask(self.project_path, self.project, "rectangle", production=True)["ok"])

    def test_modular_contract_requires_two_chassis_and_composes_states(self) -> None:
        review = {"reviewed": True, "reviewed_by": "synthetic-test", "artifacts": ["fixture-contact-sheet.png"]}
        set_chassis(self.project, "pristine", image="pristine.png", socket_mask="socket", anchors={"lcd": [4, 4], "back": [4, 4]}, status="verified", review=review)
        set_chassis(self.project, "worn", image="worn.png", socket_mask="socket", anchors={"lcd": [4, 4], "back": [4, 4]}, status="verified", review=review)
        set_lcd_layers(self.project, glass="glass.png", bezel_overlay="bezel.png", matte="matte.png", status="verified", review=review)
        set_component(
            self.project,
            "back",
            kind="button",
            action="BACK",
            states={"idle": {"image": "idle.png", "x": 4, "y": 4}, "pressed": {"image": "pressed.png", "x": 4, "y": 4}},
            hitbox=[4, 4, 4, 4],
            mask="socket",
            socket_mask="socket",
            status="verified",
            review=review,
        )
        self.project["modular"]["status"] = "verified"
        self.project["modular"]["verification"] = {"status": "verified", "reviewed": True, "reasons": []}
        save_project(self.project_path, self.project)
        result = validate_modular(self.project_path, self.project)
        self.assertTrue(result["ok"], result["diagnostics"])
        image, metadata = render_modular(self.project_path, self.project, variant="worn", states={"back": "pressed"})
        self.assertEqual(image.size, (16, 16))
        self.assertEqual(image.getpixel((5, 5)), (220, 230, 240, 255))
        self.assertEqual(metadata["variant"], "worn")
        layer_ids = [layer["id"] for layer in metadata["layers"]]
        self.assertIn("lcd.glass", layer_ids)
        self.assertIn("lcd.bezel_overlay", layer_ids)
        self.assertIn("lcd.matte", layer_ids)
        sheet, frames = render_modular_contact_sheet(self.project_path, self.project, columns=2, max_combinations=4)
        self.assertEqual(sheet.mode, "RGBA")
        self.assertEqual(len(frames), 4)

    def test_lcd_layers_require_glass_and_bezel_and_support_required_semantic_id(self) -> None:
        set_chassis(self.project, "pristine", image="pristine.png", anchors={"lcd": [4, 4]}, status="proposed")
        set_chassis(self.project, "worn", image="worn.png", anchors={"lcd": [4, 4]}, status="proposed")
        set_lcd_layers(self.project, glass="glass.png", bezel_overlay="bezel.png")
        self.project["modular"]["required_components"] = ["lcd"]
        result = validate_modular(self.project_path, self.project)
        self.assertTrue(result["ok"], result["diagnostics"])
        del self.project["modular"]["lcd_layers"]["bezel_overlay"]
        result = validate_modular(self.project_path, self.project)
        self.assertFalse(result["ok"])
        self.assertIn("LCD_LAYER_MISSING", {item["code"] for item in result["diagnostics"]})

    def test_state_contract_rejects_identical_led_and_underprovisioned_rotary(self) -> None:
        set_component(
            self.project,
            "tx_led",
            kind="led",
            action=None,
            states={"off": "idle.png", "on": "idle.png"},
        )
        set_component(
            self.project,
            "volume",
            kind="rotary",
            action="VOLUME",
            states={"frame_00": "idle.png", "frame_01": "pressed.png"},
            pivot=[4, 4],
            detents=1,
        )
        result = validate_modular(self.project_path, self.project)
        codes = {item["code"] for item in result["diagnostics"]}
        self.assertIn("COMPONENT_STATES_IDENTICAL", codes)
        self.assertIn("ROTARY_DETENTS_INVALID", codes)

    def test_missing_socket_fails_production_modular_validation(self) -> None:
        set_chassis(self.project, "pristine", image="pristine.png", anchors={"lcd": [4, 4]}, status="verified")
        set_chassis(self.project, "worn", image="worn.png", anchors={"lcd": [4, 4]}, status="verified")
        self.project["modular"]["status"] = "verified"
        self.project["modular"]["verification"] = {"status": "verified", "reviewed": True, "reasons": []}
        result = validate_modular(self.project_path, self.project)
        self.assertFalse(result["ok"])
        self.assertIn("SOCKET_MASK_MISSING", {item["code"] for item in result["diagnostics"]})

    def test_offline_simulator_loads_same_modular_project_and_event_states(self) -> None:
        set_chassis(self.project, "pristine", image="pristine.png", socket_mask="socket", anchors={"lcd": [4, 4]}, status="proposed")
        set_chassis(self.project, "worn", image="worn.png", socket_mask="socket", anchors={"lcd": [4, 4]}, status="proposed")
        set_component(
            self.project,
            "back",
            kind="button",
            action="BACK",
            states={"idle": {"image": "idle.png", "x": 4, "y": 4}, "pressed": {"image": "pressed.png", "x": 4, "y": 4}},
            hitbox=[4, 4, 4, 4],
            mask="socket",
            socket_mask="socket",
        )
        save_project(self.project_path, self.project)
        simulator = RadioSimulator(project_path=self.project_path)
        self.assertEqual([control["id"] for control in simulator.snapshot()["state"]["available_controls"]], ["back", "home"])
        simulator.dispatch({"event": "press", "control": "power"})
        simulator.dispatch({"event": "pointer_down", "control": "back"})
        self.assertIn("back", simulator.state.pressed_controls)
        image, metadata = render_device(simulator, zoom=1.0)
        self.assertEqual(image.size, (16, 16))
        self.assertEqual(metadata["variant"], "clean")

    def test_project_led_alias_follows_power_state(self) -> None:
        set_chassis(self.project, "pristine", image="pristine.png", socket_mask="socket", anchors={"lcd": [4, 4]}, status="proposed")
        set_chassis(self.project, "worn", image="worn.png", socket_mask="socket", anchors={"lcd": [4, 4]}, status="proposed")
        set_component(self.project, "pwr_led", kind="led", action=None, states={"off": "idle.png", "on": "pressed.png"})
        save_project(self.project_path, self.project)
        simulator = RadioSimulator(project_path=self.project_path)
        self.assertEqual(simulator.modular_state_selection()["pwr_led"], "off")
        simulator.dispatch({"event": "press", "control": "power"})
        self.assertEqual(simulator.modular_state_selection()["pwr_led"], "on")

    def test_authored_w5_project_uses_lcd_masks_and_live_component_states(self) -> None:
        project_path = Path(__file__).resolve().parents[1] / "projects" / "radio" / "walkie_5_pilot.json"
        if not project_path.is_file():
            self.skipTest("tracked W5 pilot project is unavailable")
        simulator = RadioSimulator(project_path=project_path, variant="pristine")
        if not simulator.device.asset_exists:
            self.skipTest("ignored W5 pilot workspace is unavailable")

        self.assertEqual(simulator.geometry.lcd_rect, (314, 605, 416, 221))
        self.assertEqual(simulator.geometry.screen_content_rect, (319, 610, 406, 211))
        self.assertEqual(
            [control.id for control in simulator.geometry.controls],
            ["back", "down", "home", "left", "ok", "power", "right", "up"],
        )
        self.assertNotIn("volume", simulator.modular_state_selection())
        self.assertNotIn("channel", simulator.modular_state_selection())
        self.assertNotIn("ptt", simulator.modular_state_selection())
        self.assertEqual(simulator.modular_state_selection()["power"], "idle")

        simulator.dispatch({"event": "pointer_down", "control": "power"})
        self.assertEqual(simulator.modular_state_selection()["power"], "pressed")
        self.assertFalse(simulator.state.powered)
        simulator.dispatch({"event": "pointer_up", "control": "power"})
        self.assertTrue(simulator.state.powered)
        self.assertEqual(simulator.modular_state_selection()["power"], "idle")

        image, metadata = render_device(simulator, zoom=0.5, debug=True)
        self.assertEqual(image.size, (512, 768))
        self.assertEqual(metadata["lcd_rect"], [157, 302, 208, 110])
        self.assertEqual(metadata["screen_content_rect"], [160, 305, 203, 106])
        self.assertEqual(metadata["hidden_components"], ["channel", "ptt", "volume"])
        self.assertEqual(metadata["skipped_components"], ["channel", "ptt", "volume"])
        self.assertEqual(
            {layer["id"] for layer in metadata["layers"]} & {"channel", "ptt", "volume"},
            set(),
        )

    def test_w5_geometry_and_pressed_layers_stay_on_the_face(self) -> None:
        project_path = Path(__file__).resolve().parents[1] / "projects" / "radio" / "walkie_5_pilot.json"
        simulator = RadioSimulator(project_path=project_path, variant="pristine")
        controls = {control.id: control for control in simulator.geometry.controls}
        self.assertNotIn("volume", controls)
        self.assertNotIn("channel", controls)
        self.assertNotIn("ptt", controls)
        self.assertEqual(controls["up"].rect, (449, 883, 139, 61))
        self.assertEqual(controls["down"].rect, (449, 1028, 139, 48))
        self.assertEqual(controls["power"].kind, "button")

        asset_root = project_path.parents[4] / "Contents" / "mods" / "PsychopatzCore" / "common" / "media" / "ui" / "Radio" / "WalkieTalkie" / "Base.WalkieTalkie5"
        expected_bottoms = {"Up": 951, "Down": 1083, "OK": 1030}
        for control_name, bottom in expected_bottoms.items():
            alpha = Image.open(asset_root / "Buttons" / control_name / "Pressed.png").convert("RGBA").getchannel("A")
            bbox = alpha.getbbox()
            self.assertIsNotNone(bbox)
            self.assertLessEqual(bbox[3], bottom, control_name)

        source = Image.open(asset_root.parent / "Base.WalkieTalkie5.png").convert("RGBA")
        power_idle = Image.open(asset_root / "Buttons" / "Power" / "Idle.png").convert("RGBA")
        power_pressed = Image.open(asset_root / "Buttons" / "Power" / "Pressed.png").convert("RGBA")
        self.assertEqual(power_idle.getpixel((394, 395)), source.getpixel((394, 395)))
        self.assertNotEqual(power_pressed.getpixel((394, 398)), source.getpixel((394, 398)))
        idle_bbox = power_idle.getchannel("A").getbbox()
        pressed_bbox = power_pressed.getchannel("A").getbbox()
        self.assertIsNotNone(idle_bbox)
        self.assertIsNotNone(pressed_bbox)
        self.assertEqual(pressed_bbox[1], idle_bbox[1] + 3)
        self.assertEqual(pressed_bbox[3], idle_bbox[3] + 3)

    def test_all_radio_pilot_projects_validate_and_render_individually(self) -> None:
        project_root = Path(__file__).resolve().parents[1] / "projects" / "radio"
        projects = sorted(project_root.glob("*_pilot.json"))
        self.assertEqual(len(projects), 10)
        for project_path in projects:
            project = json.loads(project_path.read_text(encoding="utf-8"))
            result = validate_modular(project_path, project)
            self.assertTrue(result["ok"], f"{project_path.name}: {result['diagnostics']}")
            self.assertEqual(result["summary"]["failed"], 0)
            for variant in ("pristine", "worn"):
                image, metadata = render_modular(project_path, project, variant=variant, states={})
                self.assertEqual(image.size, (project["canvas"]["width"], project["canvas"]["height"]))
            self.assertEqual(metadata["variant"], variant)
            expected_min_layers = 4 + len(project["modular"]["components"])
            self.assertGreaterEqual(len(metadata["layers"]), expected_min_layers, project_path.name)
            simulator = RadioSimulator(project_path=project_path)
            control_ids = {control.id for control in simulator.geometry.controls}
            self.assertTrue(
                control_ids <= {"back", "down", "home", "left", "ok", "power", "right", "up"},
                project_path.name,
            )
            self.assertNotIn("channel", control_ids, project_path.name)
            self.assertNotIn("volume", control_ids, project_path.name)
            self.assertNotIn("ptt", control_ids, project_path.name)

    def test_gui_discovers_only_the_canonical_pilot(self) -> None:
        project_root = Path(__file__).resolve().parents[1] / "projects" / "radio"
        for device_id in ("ham_2", "walkie_5"):
            expected = (project_root / f"{device_id}_pilot.json").resolve()
            self.assertEqual(RadioSimulatorApp._discover_project(device_id), expected)

    def test_gui_rejects_the_retired_source_mode(self) -> None:
        self.assertEqual(RadioSimulatorApp._resolve_mode("auto", None, "walkie_5"), "modular")
        with self.assertRaises(ValueError):
            RadioSimulatorApp._resolve_mode("source", None, "walkie_5")

    def test_legacy_radio_project_cannot_reenter_the_shared_simulator(self) -> None:
        legacy = Path(__file__).resolve().parents[1] / "projects" / "radio" / "walkie_1.json"
        if legacy.is_file():
            with self.assertRaises(ValueError):
                RadioSimulator(project_path=legacy)

    def test_project_registry_exposes_all_pilot_devices(self) -> None:
        from asset_harness.simulator.registry import list_project_refs, project_path_for_device

        projects = list_project_refs()
        self.assertEqual(len(projects), 10)
        self.assertEqual({project.device_id for project in projects}, {
            "ham_1", "ham_2", "ham_makeshift", "manpack",
            "walkie_1", "walkie_2", "walkie_3", "walkie_4", "walkie_5", "walkie_makeshift",
        })
        for project in projects:
            self.assertEqual(project_path_for_device(project.device_id), project.path)

    def test_all_pilot_power_controls_use_authored_pressed_lifecycle(self) -> None:
        from asset_harness.simulator.registry import list_project_refs

        for project in list_project_refs():
            simulator = RadioSimulator(project_path=project.path)
            power = (simulator.project.get("modular") or {}).get("components", {}).get("power", {})
            self.assertNotIn("Antenna", " ".join(str(state.get("image", "")) for state in (power.get("states") or {}).values()), project.device_id)
            self.assertIn("pressed", power.get("states", {}), project.device_id)
            simulator.dispatch({"event": "pointer_down", "control": "power"})
            self.assertEqual(simulator.modular_state_selection().get("power"), "pressed", project.device_id)
            simulator.dispatch({"event": "pointer_up", "control": "power"})
            self.assertTrue(simulator.state.powered, project.device_id)


if __name__ == "__main__":
    unittest.main()
