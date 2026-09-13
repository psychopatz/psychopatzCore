from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from steam_uploader_gui.persistence.database import SettingsDatabase
from steam_uploader_gui.ui.state import UIStateStore


class UIStateTests(unittest.TestCase):
    def test_ui_preferences_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            database = SettingsDatabase(Path(temp) / "settings.sqlite3")
            state = UIStateStore(database)
            state.set_bool("profile/Example/section/description", False)
            state.set_json("profile/Example/updates", {"description": True, "preview": False})

            self.assertFalse(state.get_bool("profile/Example/section/description", True))
            self.assertEqual(
                state.get_json("profile/Example/updates", {}),
                {"description": True, "preview": False},
            )
            database.close()


if __name__ == "__main__":
    unittest.main()
