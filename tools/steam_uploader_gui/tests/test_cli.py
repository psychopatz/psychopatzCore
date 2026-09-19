from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from steam_uploader_gui.cli import main


class CliTests(unittest.TestCase):
    def _project(self, root: Path) -> None:
        project = root / "AnyMod"
        info = project / "Contents" / "mods" / "AnyMod" / "42.20" / "mod.info"
        info.parent.mkdir(parents=True)
        (project / "workshop.txt").write_text(
            "id=123\n"
            "title=Any Mod\n"
            "description=Old description\n"
            "tags=Build 42\n"
            "visibility=private\n",
            encoding="utf-8",
        )
        info.write_text("name=Any Mod\nid=AnyMod\n", encoding="utf-8")

    def _run(self, arguments: list[str]) -> tuple[int, str]:
        output = io.StringIO()
        with redirect_stdout(output):
            result = main(arguments)
        return result, output.getvalue()

    def test_projects_json_exposes_recovered_identity(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "workshop"
            root.mkdir()
            self._project(root)
            database = Path(temp) / "settings.sqlite3"

            result, output = self._run(
                [
                    "--workshop-root", str(root),
                    "--database", str(database),
                    "projects", "--json",
                ]
            )

            self.assertEqual(result, 0)
            document = json.loads(output)
            self.assertEqual(document["projects"][0]["workshopid"], 123)
            self.assertEqual(document["projects"][0]["mod_ids"], ["AnyMod"])

    def test_edit_description_from_stdin_updates_local_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "workshop"
            root.mkdir()
            self._project(root)
            database = Path(temp) / "settings.sqlite3"

            with patch("sys.stdin", io.StringIO("[h1]New description[/h1]\nSecond line")):
                result, output = self._run(
                    [
                        "--workshop-root", str(root),
                        "--database", str(database),
                        "edit", "--project", "AnyMod",
                        "--description-file", "-", "--json",
                    ]
                )

            self.assertEqual(result, 0)
            self.assertTrue(json.loads(output)["changed"])
            self.assertIn(
                "description=[h1]New description[/h1]\n"
                "description=Second line\n",
                (root / "AnyMod" / "workshop.txt").read_text(encoding="utf-8"),
            )

    def test_push_requires_yes_and_dry_run_does_not_start_process(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "workshop"
            root.mkdir()
            self._project(root)
            database = Path(temp) / "settings.sqlite3"

            result, output = self._run(
                [
                    "--workshop-root", str(root),
                    "--database", str(database),
                    "push", "--project", "AnyMod", "--fields", "description", "--json",
                ]
            )
            self.assertEqual(result, 2)
            self.assertIn("--yes", json.loads(output)["message"])

            with patch("steam_uploader_gui.cli.default_log_dir", return_value=Path(temp) / "logs"):
                result, output = self._run(
                    [
                        "--workshop-root", str(root),
                        "--database", str(database),
                        "push", "--project", "AnyMod", "--fields", "description",
                        "--dry-run", "--json",
                    ]
                )
            self.assertEqual(result, 0)
            document = json.loads(output)
            self.assertFalse(document["started"])
            self.assertEqual(document["fields"], ["description"])


if __name__ == "__main__":
    unittest.main()
