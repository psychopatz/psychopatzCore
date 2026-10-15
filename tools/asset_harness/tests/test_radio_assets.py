from __future__ import annotations

import hashlib
import json
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
        for row in by_id.values():
            self.assertEqual(row["verification"]["manual_reconstruction"]["source_layout"], "single_canvas")
            self.assertEqual(
                row["verification"]["manual_reconstruction"]["reason"],
                "FLATTENED_SOURCE_REQUIRES_MANUAL_RECONSTRUCTION",
            )
        reconstruction = by_id["walkie_5"]["verification"]["manual_reconstruction"]
        self.assertTrue(reconstruction["required"])
        self.assertEqual(reconstruction["reason"], "FLATTENED_SOURCE_REQUIRES_MANUAL_RECONSTRUCTION")
        self.assertEqual(
            {gate["id"] for gate in reconstruction["gates"]},
            {"chassis_reconstruction", "socket_masks", "component_state_art", "reconstruction_review"},
        )

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
        walkie5_source = ROOT / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5.png"
        walkie5_before = hashlib.sha256(walkie5_source.read_bytes()).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            paths = write_radio_audit_artifacts(report, Path(directory), columns=3)
            self.assertTrue((Path(directory) / "source_contact_sheet.png").is_file())
            self.assertEqual(len(paths), 23)
            self.assertEqual(report["regressions"]["walkie_4"]["legacy_crop_size"], [512, 1536])
            self.assertTrue((Path(directory) / "walkie_4_bad_cut_diff.png").is_file())
            pilot_sheet = Path(directory) / "walkie_5_pilot_acceptance.png"
            pilot_checklist = Path(directory) / "walkie_5_pilot_acceptance.json"
            self.assertTrue(pilot_sheet.is_file())
            self.assertTrue(pilot_checklist.is_file())
            pilot = json.loads(pilot_checklist.read_text(encoding="utf-8"))
            self.assertEqual(pilot["status"], "blocked")
            self.assertFalse(pilot["accepted"])
            self.assertFalse(pilot["scope"]["modular_artwork_created"])
            self.assertEqual(hashlib.sha256(walkie5_source.read_bytes()).hexdigest(), walkie5_before)
            walkie5_qa = {item["id"]: item for item in report["devices"][4]["verification"]["qa_requirements"]}
            self.assertEqual(walkie5_qa["full_resolution_source_copy"]["status"], "complete")
            self.assertEqual(walkie5_qa["alpha_preview"]["status"], "complete")
            self.assertEqual(walkie5_qa["manual_reconstruction_plan"]["status"], "blocked")
            self.assertEqual(
                walkie5_qa["manual_reconstruction_plan"]["reason"],
                "FLATTENED_SOURCE_REQUIRES_MANUAL_RECONSTRUCTION",
            )
            self.assertEqual(walkie5_qa["pristine_chassis"]["status"], "blocked")
            diff_report_path = Path(directory) / "diff" / "walkie_5_source_to_idle.json"
            self.assertTrue(diff_report_path.is_file())
            diff_report = json.loads(diff_report_path.read_text(encoding="utf-8"))
            self.assertEqual(diff_report["status"], "blocked")
            self.assertIsNone(diff_report["after"])
            self.assertFalse(diff_report["scope"]["fake_idle_generated"])
            self.assertEqual(diff_report["before"]["sha256"], report["devices"][4]["source"]["sha256"])
            self.assertEqual(walkie5_qa["pilot_acceptance_sheet"]["status"], "blocked")
            self.assertEqual(walkie5_qa["pilot_acceptance_sheet"]["evidence_status"], "generated_not_acceptance")
            for device in report["devices"]:
                source = device["source"]
                source_copy = Path(directory) / "sources" / f"{device['id']}.png"
                self.assertEqual(hashlib.sha256(source_copy.read_bytes()).hexdigest(), source["sha256"])
                diff = next(item for item in device["verification"]["artifacts"] if item["kind"] == "source_to_idle_diff")
                self.assertIsNone(diff["sha256"])
                self.assertTrue(Path(diff["report_path"]).is_file())
                self.assertTrue(diff["report_sha256"])
            regression_diff = next(item for item in report["devices"][3]["verification"]["artifacts"] if item["kind"] == "bad_cut_regression_diff")
            self.assertTrue(regression_diff["sha256"])
            w4_qa = {item["id"]: item for item in report["devices"][3]["verification"]["qa_requirements"]}
            self.assertEqual(w4_qa["bad_cut_regression"]["status"], "complete")

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
