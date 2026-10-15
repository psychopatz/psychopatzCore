from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "cli.py"


class CliTests(unittest.TestCase):
    def run_cli(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CLI), *arguments],
            text=True,
            capture_output=True,
            check=check,
        )

    def test_doctor_is_one_bounded_json_object(self) -> None:
        result = self.run_cli("doctor", "--token-budget", "500")
        parsed = json.loads(result.stdout)
        self.assertTrue(parsed["ok"])
        self.assertEqual(parsed["schema_version"], 1)
        self.assertLessEqual(len(result.stdout), 2500)

    def test_missing_source_has_stable_code_and_nonzero_exit(self) -> None:
        result = self.run_cli("source", "inspect", "--input", "/definitely/missing.png", check=False)
        parsed = json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(parsed["ok"])
        self.assertEqual(parsed["diagnostics"][0]["code"], "FILE_NOT_FOUND")

    def test_subprocess_project_source_region_render_validate_flow(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.png"
            image = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
            for x in range(5, 15):
                for y in range(5, 15):
                    image.putpixel((x, y), (120, 120, 120, 255))
            image.save(source, format="PNG", optimize=False, compress_level=9)
            project = root / "project.json"
            self.run_cli("project", "init", "--project", str(project), "--width", "20", "--height", "20")
            self.run_cli("source", "import", "--project", str(project), "--id", "shell", "--input", str(source), "--approved", "--provenance", "test")
            self.run_cli("lcd", "set", "--project", str(project), "--aperture", "0,0,4,4", "--backing", "0,0,4,4", "--content", "1,1,2,2")
            self.run_cli("controls", "set", "--project", str(project), "--id", "select", "--rect", "4,16,12,4", "--action", "select")
            self.run_cli("variants", "set", "--project", str(project), "--name", "worn", "--description", "synthetic wear")
            listed = self.run_cli("variants", "list", "--project", str(project))
            self.assertIn("worn", json.loads(listed.stdout)["data"]["variants"])
            detected = self.run_cli("regions", "detect", "--project", str(project), "--source", "shell", "--min-area", "2")
            self.assertTrue(json.loads(detected.stdout)["ok"])
            self.run_cli("layers", "set", "--project", str(project), "--id", "shell", "--source", "shell", "--x", "0", "--y", "0", "--role", "shell_front", "--z", "50")
            rendered = self.run_cli("render", "--project", str(project), "--out", str(root / "render.png"))
            render_json = json.loads(rendered.stdout)
            self.assertTrue(render_json["ok"])
            with Image.open(root / "render.png") as rendered_image:
                self.assertEqual(rendered_image.size, (20, 20))
            validated = self.run_cli("validate", "--project", str(project), "--no-report", check=False)
            self.assertEqual(json.loads(validated.stdout)["ok"], True)
            export_plan = self.run_cli("export", "plan", "--project", str(project))
            self.assertTrue(json.loads(export_plan.stdout)["ok"])
            self.assertTrue(json.loads(export_plan.stdout)["data"]["plan"]["files"])
            self.run_cli("export", "apply", "--project", str(project), "--approved")
            export_verify = self.run_cli("export", "verify", "--project", str(project))
            self.assertTrue(json.loads(export_verify.stdout)["ok"])
            manifest = next((root / "Contents").rglob("skin.lua"))
            self.assertIn("media/ui/", manifest.read_text(encoding="utf-8"))
            batch_file = root / "batch.json"
            batch_file.write_text(json.dumps({"operations": [{"argv": ["doctor"]}, {"argv": ["project", "inspect", "--project", str(project)]}]}), encoding="utf-8")
            batch = self.run_cli("batch", "--file", str(batch_file))
            self.assertEqual(len(json.loads(batch.stdout)["data"]["results"]), 2)


if __name__ == "__main__":
    unittest.main()
