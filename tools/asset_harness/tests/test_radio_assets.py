from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from asset_harness.core.radio_assets import audit_radio_sources, write_radio_audit_artifacts  # noqa: E402
from asset_harness.core.masks import register_mask, validate_mask, write_polygon_mask  # noqa: E402
from asset_harness.core.project import default_project, save_project  # noqa: E402
from asset_harness.core.source import register_source  # noqa: E402
from asset_harness.simulator import RadioSimulator, list_devices  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402


class RadioAssetAuditTests(unittest.TestCase):
    def test_audit_covers_ten_exact_canonical_sources_and_blocks_unreviewed_art(self) -> None:
        report = audit_radio_sources(ROOT)
        self.assertEqual(report["summary"]["expected_devices"], 10)
        self.assertEqual(report["summary"]["sources_found"], 10)
        self.assertEqual(report["summary"]["blocked"], 10)
        by_id = {row["id"]: row for row in report["devices"]}
        self.assertEqual(by_id["walkie_4"]["source"]["size"], [1024, 1536])
        self.assertEqual(by_id["walkie_5"]["source"]["size"], [1024, 1535])
        self.assertEqual(by_id["ham_makeshift"]["source"]["filename"], "Base.HamRadioMakeShift .png")
        self.assertEqual(by_id["walkie_4"]["source"]["layout"]["kind"], "single_canvas")
        self.assertIn("KNOWN_WALKIETALKIE4_BAD_CUT_REGRESSION", by_id["walkie_4"]["verification"]["reasons"])
        self.assertIn("US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW", by_id["walkie_5"]["verification"]["reasons"])

    def test_simulator_uses_full_source_canvas_and_does_not_mutate_pngs(self) -> None:
        for spec in list_devices():
            before = hashlib.sha256(spec.asset_path.read_bytes()).hexdigest()
            self.assertTrue(spec.asset_exists, spec.asset_path)
            self.assertEqual(spec.variant_crop("clean"), (0, 0, spec.source_width, spec.source_height))
            self.assertEqual(spec.variant_crop("worn"), (0, 0, spec.source_width, spec.source_height))
            image, metadata = render_device(RadioSimulator(spec.id), zoom=0.1)
            self.assertEqual(image.mode, "RGBA")
            self.assertGreater(metadata["source_size"][0], spec.source_width * 0.8)
            self.assertEqual(hashlib.sha256(spec.asset_path.read_bytes()).hexdigest(), before)

    def test_audit_artifacts_preserve_sources_and_block_unavailable_diffs(self) -> None:
        report = audit_radio_sources(ROOT, family="walkie")
        with tempfile.TemporaryDirectory() as directory:
            paths = write_radio_audit_artifacts(report, Path(directory), columns=3)
            self.assertTrue((Path(directory) / "source_contact_sheet.png").is_file())
            self.assertEqual(len(paths), 15)
            self.assertEqual(report["regressions"]["walkie_4"]["legacy_crop_size"], [512, 1536])
            self.assertTrue((Path(directory) / "walkie_4_bad_cut_diff.png").is_file())
            for device in report["devices"]:
                source = device["source"]
                source_copy = Path(directory) / "sources" / f"{device['id']}.png"
                self.assertEqual(hashlib.sha256(source_copy.read_bytes()).hexdigest(), source["sha256"])
                diff = next(item for item in device["verification"]["artifacts"] if item["kind"] == "source_to_idle_diff")
                self.assertIsNone(diff["sha256"])
            regression_diff = next(item for item in report["devices"][3]["verification"]["artifacts"] if item["kind"] == "bad_cut_regression_diff")
            self.assertTrue(regression_diff["sha256"])

    def test_actual_walkie5_mask_qa_rejects_transparent_exterior_selection(self) -> None:
        source_path = ROOT / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5.png"
        with tempfile.TemporaryDirectory() as directory:
            project_path = Path(directory) / "walkie5.json"
            project = default_project("walkie5_mask_fixture", family="walkie", model="Base.WalkieTalkie5", width=1024, height=1535)
            save_project(project_path, project)
            register_source(project_path, project, "walkie5", str(source_path), provenance="canonical reference; unapproved", allow_external=True)
            mask_path = Path(directory) / "exterior_pixel.png"
            mask = Image.new("L", (1024, 1535), 0)
            mask.putpixel((0, 0), 255)
            mask.save(mask_path, format="PNG", optimize=False, compress_level=9)
            register_mask(project_path, project, "exterior_pixel", str(mask_path), source_id="walkie5", method="hand_authored", status="verified")
            result = validate_mask(project_path, project, "exterior_pixel")
            self.assertFalse(result["ok"])
            self.assertIn("MASK_SELECTS_TRANSPARENT_SOURCE", {item["code"] for item in result["diagnostics"]})

    def test_actual_walkie5_polygon_is_explicitly_proposed_until_reviewed(self) -> None:
        source_path = ROOT / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5.png"
        with tempfile.TemporaryDirectory() as directory:
            project_path = Path(directory) / "walkie5.json"
            project = default_project("walkie5_polygon_fixture", family="walkie", model="Base.WalkieTalkie5", width=1024, height=1535)
            save_project(project_path, project)
            register_source(project_path, project, "walkie5", str(source_path), provenance="canonical reference; unapproved", allow_external=True)
            record = write_polygon_mask(
                project_path,
                project,
                "lcd_candidate",
                "walkie5",
                "300,600;700,600;700,800;300,800",
                status="proposed",
            )
            self.assertEqual(record["method"], "manual_polygon")
            self.assertEqual(record["status"], "proposed")
            self.assertFalse(validate_mask(project_path, project, "lcd_candidate", production=True)["ok"])


if __name__ == "__main__":
    unittest.main()
