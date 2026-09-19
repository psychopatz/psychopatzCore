from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from steam_uploader_gui.services.workshop import WorkshopItem, sync_workshop_metadata


class WorkshopSyncTests(unittest.TestCase):
    def _item(self, **changes: object) -> WorkshopItem:
        values = {
            "published_file_id": 42,
            "title": "Steam title",
            "description": "Steam description\nSecond line",
            "tags": ["Build 42", "Framework"],
            "visibility": 0,
        }
        values.update(changes)
        return WorkshopItem(**values)

    def test_sync_fills_missing_fields_and_preserves_unknown_workshop_keys(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            workshop = root / "workshop.txt"
            workshop.write_text(
                "version=1\n"
                "id=42\n"
                "title=Local title\n"
                "description=\n"
                "tags=\n"
                "visibility=private\n"
                "custom_field=keep-me\n",
                encoding="utf-8",
            )

            result = sync_workshop_metadata(root, self._item())
            updated = workshop.read_text(encoding="utf-8")

            self.assertEqual(result.applied_fields, ("description", "tags"))
            self.assertEqual(set(result.conflicts or {}), {"title", "visibility"})
            self.assertIn("description=Steam description\n", updated)
            self.assertIn("description=Second line\n", updated)
            self.assertIn("custom_field=keep-me\n", updated)

    def test_sync_updates_remote_changes_when_local_matches_last_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "workshop.txt").write_text(
                "id=42\n"
                "title=Old title\n"
                "description=Old description\n"
                "tags=Old tag\n"
                "visibility=private\n",
                encoding="utf-8",
            )
            previous = {
                "steam": {
                    "title": "Old title",
                    "description": "Old description",
                    "tags": ["Old tag"],
                    "visibility": 2,
                },
                "local": {
                    "title": "Old title",
                    "description": "Old description",
                    "tags": ["Old tag"],
                    "visibility": 2,
                },
            }

            result = sync_workshop_metadata(root, self._item(), previous)

            self.assertEqual(result.applied_fields, ("title", "description", "tags", "visibility"))
            self.assertEqual(result.conflicts, {})
            self.assertEqual(result.local_after["title"], "Steam title")
            self.assertEqual(result.local_after["visibility"], 0)

    def test_sync_preserves_local_edits_as_conflicts(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            workshop = root / "workshop.txt"
            workshop.write_text(
                "id=42\n"
                "title=User title\n"
                "description=User description\n"
                "tags=User tag\n"
                "visibility=private\n",
                encoding="utf-8",
            )
            previous = {
                "local": {
                    "title": "Old title",
                    "description": "Old description",
                    "tags": ["Old tag"],
                    "visibility": 2,
                }
            }

            result = sync_workshop_metadata(root, self._item(), previous)

            self.assertEqual(result.applied_fields, ("visibility",))
            self.assertEqual(set(result.conflicts or {}), {"title", "description", "tags"})
            self.assertIn("title=User title\n", workshop.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
