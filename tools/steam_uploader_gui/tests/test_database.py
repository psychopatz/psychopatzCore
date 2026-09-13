from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from steam_uploader_gui.core.config import SETTING_UPLOADER_PATH, SETTING_WORKSHOP_ROOT
from steam_uploader_gui.core.models import ModProfile
from steam_uploader_gui.persistence.database import SettingsDatabase


class DatabaseTests(unittest.TestCase):
    def test_settings_and_profiles_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            database = SettingsDatabase(Path(temp) / "settings.sqlite3")
            database.set_setting(SETTING_WORKSHOP_ROOT, "/tmp/workshop")
            database.set_setting(SETTING_UPLOADER_PATH, "/opt/SteamUploader/SteamUploader")
            self.assertEqual(database.get_setting(SETTING_WORKSHOP_ROOT), "/tmp/workshop")
            self.assertEqual(database.get_setting(SETTING_UPLOADER_PATH), "/opt/SteamUploader/SteamUploader")
            profile = ModProfile(key="A", name="A", mod_root=Path(temp), workshopid=10, tags=["Build 42"])
            database.save_profile(profile)
            loaded = database.load_profile("A")
            assert loaded is not None
            self.assertEqual(loaded.workshopid, 10)
            self.assertEqual(loaded.tags, ["Build 42"])
            database.close()


if __name__ == "__main__":
    unittest.main()
