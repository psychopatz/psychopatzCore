from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from unittest.mock import patch

from steam_uploader_gui.services.workshop import (
    WorkshopIdentityRecoveryError,
    WorkshopItem,
    WorkshopItemLookupError,
    fetch_workshop_item_with_identity_repair,
    sync_workshop_metadata,
)


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

    def test_not_found_id_retries_verified_workshop_txt_id(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "workshop.txt").write_text("id=987654321\ntitle=Test\n", encoding="utf-8")
            replacement = self._item(published_file_id=987654321)

            with patch(
                "steam_uploader_gui.services.workshop.fetch_workshop_item",
                side_effect=[WorkshopItemLookupError(123, 9), replacement],
            ) as fetch:
                result = fetch_workshop_item_with_identity_repair(123, root)

            self.assertEqual([call.args[0] for call in fetch.call_args_list], [123, 987654321])
            self.assertEqual(result.item.published_file_id, 987654321)
            self.assertEqual(result.identity_source, "workshop.txt:id")
            self.assertIn("Repaired stale Workshop ID 123", result.identity_repair)

    def test_verified_vdf_id_is_written_to_workshop_txt(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "workshop.txt").write_text("title=Test\n", encoding="utf-8")
            (root / "workshop_update.vdf").write_text(
                '"publishedfileid" "987654321"\n',
                encoding="utf-8",
            )
            replacement = self._item(published_file_id=987654321)

            with patch(
                "steam_uploader_gui.services.workshop.fetch_workshop_item",
                side_effect=[WorkshopItemLookupError(123, 9), replacement],
            ):
                result = fetch_workshop_item_with_identity_repair(123, root)

            self.assertEqual(result.identity_source, "workshop_update.vdf:publishedfileid")
            self.assertIn("id=987654321", (root / "workshop.txt").read_text(encoding="utf-8"))

    def test_not_found_id_does_not_guess_from_a_mod_id(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            info = root / "Contents" / "mods" / "AnyMod" / "mod.info"
            info.parent.mkdir(parents=True)
            info.write_text("name=Any Mod\nid=AnyMod\n", encoding="utf-8")
            (root / "workshop.txt").write_text("title=Any Mod\n", encoding="utf-8")

            with patch(
                "steam_uploader_gui.services.workshop.fetch_workshop_item",
                side_effect=WorkshopItemLookupError(123, 9),
            ) as fetch:
                with self.assertRaisesRegex(WorkshopIdentityRecoveryError, "Mod ID cannot be used"):
                    fetch_workshop_item_with_identity_repair(123, root)

            fetch.assert_called_once_with(123)

    def test_not_found_id_stops_when_local_workshop_ids_conflict(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "workshop.txt").write_text("id=123\n", encoding="utf-8")
            (root / "workshop_update.vdf").write_text(
                '"publishedfileid" "456"\n',
                encoding="utf-8",
            )

            with patch(
                "steam_uploader_gui.services.workshop.fetch_workshop_item",
                side_effect=WorkshopItemLookupError(123, 9),
            ) as fetch:
                with self.assertRaisesRegex(WorkshopIdentityRecoveryError, "sources disagree"):
                    fetch_workshop_item_with_identity_repair(123, root)

            fetch.assert_called_once_with(123)
            self.assertEqual((root / "workshop.txt").read_text(encoding="utf-8"), "id=123\n")


if __name__ == "__main__":
    unittest.main()
