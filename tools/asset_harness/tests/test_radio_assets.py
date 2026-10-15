from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from asset_harness.core.radio_assets import audit_radio_sources, write_radio_audit_artifacts  # noqa: E402
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
            self.assertEqual(len(paths), 13)
            for device in report["devices"]:
                source = device["source"]
                source_copy = Path(directory) / "sources" / f"{device['id']}.png"
                self.assertEqual(hashlib.sha256(source_copy.read_bytes()).hexdigest(), source["sha256"])
                diff = next(item for item in device["verification"]["artifacts"] if item["kind"] == "source_to_idle_diff")
                self.assertIsNone(diff["sha256"])


if __name__ == "__main__":
    unittest.main()
