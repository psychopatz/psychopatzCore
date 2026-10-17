from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from asset_harness.hitbox_editor import (
    find_hitbox_overlaps,
    load_project_hitboxes,
    save_project_json,
    update_project_hitboxes,
)
from asset_harness.simulator import RadioSimulator
from asset_harness.simulator.registry import project_path_for_device


class HitboxEditorPersistenceTests(unittest.TestCase):
    def test_positive_area_overlap_detection_allows_shared_edges(self) -> None:
        self.assertEqual(find_hitbox_overlaps({"left": [0, 0, 10, 10], "right": [10, 0, 10, 10]}), ())
        self.assertEqual(
            find_hitbox_overlaps({"left": [0, 0, 10, 10], "right": [9, 0, 10, 10]}),
            (("left", "right"),),
        )

    def test_round_trip_writes_canonical_modular_hitboxes(self) -> None:
        source_path = project_path_for_device("walkie_1")
        assert source_path is not None
        project = json.loads(Path(source_path).read_text(encoding="utf-8"))
        control_ids = tuple(
            str(item) for item in RadioSimulator("walkie_1")._project_simulator_policy()["interactive_controls"]
        )
        rects = load_project_hitboxes(project, control_ids)
        original_power = rects["power"][:]
        rects["power"] = [original_power[0] + 1, original_power[1] + 2, original_power[2], original_power[3]]

        with tempfile.TemporaryDirectory() as temporary_directory:
            target = Path(temporary_directory) / "walkie_1_pilot.json"
            update_project_hitboxes(project, rects)
            save_project_json(target, project)
            saved = json.loads(target.read_text(encoding="utf-8"))

        self.assertEqual(saved["modular"]["components"]["power"]["hitbox"], rects["power"])
        self.assertEqual(saved["modular"]["components"]["back"]["hitbox"], rects["back"])
        self.assertEqual(saved["controls"], project["controls"])


if __name__ == "__main__":
    unittest.main()
