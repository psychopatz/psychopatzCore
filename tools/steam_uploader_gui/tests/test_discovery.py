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

    def test_repairs_missing_workshop_and_mod_ids_from_unambiguous_sources(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            info = mod / "Contents" / "mods" / "AnyMod" / "42.20" / "mod.info"
            info.parent.mkdir(parents=True)
            (mod / "workshop.txt").write_text("version=1\ntitle=Any Mod\n", encoding="utf-8")
            (mod / "workshop_update.vdf").write_text(
                '"workshopitem"\n{\n\t"publishedfileid" "987654321"\n}\n',
                encoding="utf-8",
            )
            info.write_text("name=Any Mod\n", encoding="utf-8")

            profile = discover_profiles(root)[0]

            self.assertEqual(profile.workshopid, 987654321)
            self.assertEqual(profile.mod_ids, ["AnyMod"])
            self.assertTrue(any("Workshop ID" in repair for repair in profile.identity_repairs))
            self.assertTrue(any("Mod ID" in repair for repair in profile.identity_repairs))
            self.assertIn("id=987654321", (mod / "workshop.txt").read_text(encoding="utf-8"))
            self.assertIn("id=AnyMod", info.read_text(encoding="utf-8"))

    def test_repairs_missing_workshop_id_from_cached_profile(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            (mod / "Contents").mkdir(parents=True)
            (mod / "workshop.txt").write_text("title=Any Mod\n", encoding="utf-8")

            profile = discover_profiles(root, cached_workshop_ids={"AnyMod": 2468})[0]

            self.assertEqual(profile.workshopid, 2468)
            self.assertEqual(profile.workshopid_source, "cached profile")
            self.assertIn("id=2468", (mod / "workshop.txt").read_text(encoding="utf-8"))

    def test_conflicting_workshop_sources_are_reported(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            (mod / "Contents").mkdir(parents=True)
            (mod / "workshop.txt").write_text("id=123\n", encoding="utf-8")
            (mod / "workshop_update.vdf").write_text(
                '"publishedfileid" "456"\n',
                encoding="utf-8",
            )

            profile = discover_profiles(root)[0]

            self.assertEqual(profile.workshopid, 123)
            self.assertTrue(any("sources disagree" in conflict for conflict in profile.identity_conflicts))

    def test_conflicting_workshop_sources_are_not_repaired_automatically(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            mod = root / "AnyMod"
            (mod / "Contents").mkdir(parents=True)
            workshop = mod / "workshop.txt"
            workshop.write_text("workshopid=123\n", encoding="utf-8")
            (mod / "workshop_update.vdf").write_text(
                '"publishedfileid" "456"\n',
                encoding="utf-8",
            )

            profile = discover_profiles(root)[0]

            self.assertTrue(profile.identity_conflicts)
            self.assertEqual(workshop.read_text(encoding="utf-8"), "workshopid=123\n")


if __name__ == "__main__":
    unittest.main()
