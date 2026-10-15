from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from asset_harness.core.masks import register_mask, validate_mask  # noqa: E402
from asset_harness.core.modular import render_modular, set_chassis, set_component, validate_modular  # noqa: E402
from asset_harness.core.project import default_project, save_project  # noqa: E402
from asset_harness.core.source import register_source  # noqa: E402
from asset_harness.simulator import RadioSimulator  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402


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
        register_mask(self.project_path, self.project, "socket", "socket.png", source_id="pristine", method="hand_authored", status="verified", provenance="synthetic mask")
        register_mask(self.project_path, self.project, "forbidden", "forbidden.png", method="hand_authored", status="verified", provenance="synthetic guard")
        save_project(self.project_path, self.project)

    def tearDown(self) -> None:
        self.directory.cleanup()

    def test_mask_qa_rejects_neighbor_contamination_and_rectangles(self) -> None:
        register_mask(self.project_path, self.project, "contaminated", "socket.png", source_id="pristine", method="hand_authored", status="verified", forbidden_mask_id="forbidden")
        self.assertFalse(validate_mask(self.project_path, self.project, "contaminated")["ok"])
        register_mask(self.project_path, self.project, "rectangle", "socket.png", source_id="pristine", method="rectangle", status="verified")
        self.assertFalse(validate_mask(self.project_path, self.project, "rectangle", production=True)["ok"])

    def test_modular_contract_requires_two_chassis_and_composes_states(self) -> None:
        set_chassis(self.project, "pristine", image="pristine.png", socket_mask="socket", anchors={"lcd": [4, 4], "back": [4, 4]}, status="verified")
        set_chassis(self.project, "worn", image="worn.png", socket_mask="socket", anchors={"lcd": [4, 4], "back": [4, 4]}, status="verified")
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


if __name__ == "__main__":
    unittest.main()
