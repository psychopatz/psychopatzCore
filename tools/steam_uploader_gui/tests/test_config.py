from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from steam_uploader_gui.core.config import resolve_uploader_path


class UploaderPathTests(unittest.TestCase):
    def test_uses_a_valid_configured_executable(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            executable = Path(temp) / "SteamUploader"
            executable.write_text("binary placeholder", encoding="utf-8")

            self.assertEqual(resolve_uploader_path(str(executable)), executable)

    def test_missing_or_invalid_setting_uses_discovered_executable(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            executable = Path(temp) / "SteamUploader"
            executable.write_text("binary placeholder", encoding="utf-8")

            with patch(
                "steam_uploader_gui.core.config.first_existing_uploader",
                return_value=executable,
            ):
                self.assertEqual(resolve_uploader_path("."), executable)
                self.assertEqual(resolve_uploader_path(""), executable)

    def test_returns_none_when_no_executable_is_configured_or_discovered(self) -> None:
        with patch(
            "steam_uploader_gui.core.config.first_existing_uploader",
            return_value=None,
        ):
            self.assertIsNone(resolve_uploader_path("."))


if __name__ == "__main__":
    unittest.main()
