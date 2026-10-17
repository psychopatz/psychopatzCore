from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from asset_harness.core.masks import register_mask, validate_mask, write_polygon_mask  # noqa: E402
from asset_harness.core.project import default_project, save_project  # noqa: E402
from asset_harness.core.radio_assets import audit_radio_sources, write_radio_audit_artifacts  # noqa: E402
from asset_harness.core.source import register_source  # noqa: E402
from asset_harness.simulator import RadioSimulator, list_project_refs  # noqa: E402
from asset_harness.simulator.render import render_device  # noqa: E402


class RadioAssetAuditTests(unittest.TestCase):
    def test_audit_covers_ten_canonical_modular_projects(self) -> None:
        report = audit_radio_sources(ROOT, include_staged=False)
        self.assertEqual(report["audit_kind"], "radio_modular_inventory")
        self.assertEqual(report["summary"]["expected_devices"], 10)
        self.assertEqual(report["summary"]["sources_found"], 10)
        self.assertEqual(report["summary"]["blocked"], 0)
        self.assertEqual(report["summary"]["proposed"], 10)

        by_id = {row["id"]: row for row in report["devices"]}
        for row in by_id.values():
            source = row["source"]
            self.assertTrue(source["path"].endswith("/Chassis/Pristine.png"), row["id"])
            self.assertEqual(source["layout"]["kind"], "modular_canvas", row["id"])
            self.assertEqual(
                row["verification"]["manual_reconstruction"]["reason"],
                "MODULAR_ARTWORK_REQUIRES_REVIEW",
                row["id"],
            )
        self.assertNotIn("bad_cut_regression", {item["id"] for item in by_id["walkie_4"]["verification"]["qa_requirements"]})

    def test_all_pilot_projects_use_modular_artwork_and_no_flat_atlas(self) -> None:
        report = audit_radio_sources(ROOT)
        self.assertEqual(report["summary"]["proposed"], 10)
        for project in sorted((ROOT / "tools/asset_harness/projects/radio").glob("*_pilot.json")):
            text = project.read_text(encoding="utf-8")
            self.assertNotRegex(text, r"Base\.(?:WalkieTalkie(?:1|2|3|4|5|MakeShift)|HamRadio(?:1|2|MakeShift)|ManPackRadio)(?: \.png|\.png)")

    def test_simulator_uses_modular_chassis_and_does_not_mutate_pngs(self) -> None:
        for project in list_project_refs():
            simulator = RadioSimulator(project.device_id)
            spec = simulator.device
            before = hashlib.sha256(spec.asset_path.read_bytes()).hexdigest()
            self.assertTrue(spec.asset_exists, spec.asset_path)
            self.assertTrue(spec.asset_path.as_posix().endswith("/Chassis/Pristine.png"))
            image, metadata = render_device(simulator, zoom=0.1)
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(metadata["variant_art_status"], "modular_project_preview")
            self.assertEqual(hashlib.sha256(spec.asset_path.read_bytes()).hexdigest(), before)

    def test_audit_artifacts_are_built_from_active_chassis_only(self) -> None:
        report = audit_radio_sources(ROOT, family="ham", include_staged=False)
        with tempfile.TemporaryDirectory() as directory:
            paths = write_radio_audit_artifacts(report, Path(directory), columns=3)
            self.assertTrue((Path(directory) / "source_contact_sheet.png").is_file())
            self.assertTrue(paths)
            self.assertFalse((Path(directory) / "walkie_4_bad_cut_regression.png").exists())
            for device in report["devices"]:
                source_copy = Path(directory) / "sources" / f"{device['id']}.png"
                self.assertTrue(source_copy.is_file())
                self.assertEqual(hashlib.sha256(source_copy.read_bytes()).hexdigest(), device["source"]["sha256"])

    def test_actual_walkie5_mask_qa_rejects_transparent_exterior_selection(self) -> None:
        source_path = ROOT / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5/Chassis/Pristine.png"
        with tempfile.TemporaryDirectory() as directory:
            project_path = Path(directory) / "walkie5.json"
            project = default_project("walkie5_mask_fixture", family="walkie", model="Base.WalkieTalkie5", width=1024, height=1535)
            save_project(project_path, project)
            register_source(project_path, project, "walkie5", str(source_path), provenance="canonical modular chassis", allow_external=True)
            mask_path = Path(directory) / "exterior_pixel.png"
            mask = Image.new("L", (1024, 1535), 0)
            mask.putpixel((0, 0), 255)
            mask.save(mask_path, format="PNG", optimize=False, compress_level=9)
            register_mask(project_path, project, "exterior_pixel", str(mask_path), source_id="walkie5", method="hand_authored", status="verified")
            result = validate_mask(project_path, project, "exterior_pixel")
            self.assertFalse(result["ok"])
            self.assertIn("MASK_SELECTS_TRANSPARENT_SOURCE", {item["code"] for item in result["diagnostics"]})

    def test_actual_walkie5_polygon_is_explicitly_proposed_until_reviewed(self) -> None:
        source_path = ROOT / "Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5/Chassis/Pristine.png"
        with tempfile.TemporaryDirectory() as directory:
            project_path = Path(directory) / "walkie5.json"
            project = default_project("walkie5_polygon_fixture", family="walkie", model="Base.WalkieTalkie5", width=1024, height=1535)
            save_project(project_path, project)
            register_source(project_path, project, "walkie5", str(source_path), provenance="canonical modular chassis", allow_external=True)
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
