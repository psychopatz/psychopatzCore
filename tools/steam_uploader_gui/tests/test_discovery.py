from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from steam_uploader_gui.core.discovery import discover_profiles, parse_workshop_txt


class DiscoveryTests(unittest.TestCase):
    def test_parses_generic_workshop_project(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            (mod / "Contents").mkdir(parents=True)
            (mod / "preview.gif").write_bytes(b"GIF89a" + b"x")
            (mod / "workshop.txt").write_text(
                "id=123\ntitle=Any Mod\ndescription=BBCode\ntags=Build 42;Framework\nvisibility=private\n",
                encoding="utf-8",
            )
            self.assertEqual(parse_workshop_txt(mod / "workshop.txt")["id"], "123")
            profiles = discover_profiles(root)
            self.assertEqual(len(profiles), 1)
            profile = profiles[0]
            self.assertEqual(profile.key, "AnyMod")
            self.assertEqual(profile.workshopid, 123)
            self.assertEqual(profile.tags, ["Build 42", "Framework"])
            self.assertEqual(profile.preview_path, mod / "preview.gif")

    def test_prefers_an_uploadable_preview_when_gif_is_oversized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            (mod / "Contents").mkdir(parents=True)
            (mod / "preview.gif").write_bytes(b"GIF89a" + b"x" * 1_000_000)
            (mod / "preview.png").write_bytes(b"GIF89a" + b"x")
            profiles = discover_profiles(root)
            self.assertEqual(profiles[0].preview_path, mod / "preview.png")

    def test_joins_repeated_description_lines_and_normalizes_crlf(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "workshop.txt"
            path.write_text(
                "description=[h1]Title[/h1]\r\n"
                "description=\r\n"
                "description=Second line\r\n",
                encoding="utf-8",
            )
            values = parse_workshop_txt(path)
            self.assertEqual(values["description"], "[h1]Title[/h1]\n\nSecond line")


if __name__ == "__main__":
    unittest.main()
