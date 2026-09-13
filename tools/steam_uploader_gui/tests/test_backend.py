from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from steam_uploader_gui.core.limits import (
    MAX_CHANGE_NOTE_LENGTH,
    MAX_DESCRIPTION_LENGTH,
    MAX_TITLE_LENGTH,
)
from steam_uploader_gui.services.uploader import (
    MAX_PRIMARY_PREVIEW_BYTES,
    image_kind,
    selective_request_for,
    validate,
)
from steam_uploader_gui.core.models import ModProfile, UpdateSelection


class BackendValidationTests(unittest.TestCase):
    def test_preview_size_is_checked_as_strict_steam_limit(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            preview = root / "preview.gif"
            preview.write_bytes(b"GIF89a" + b"x" * MAX_PRIMARY_PREVIEW_BYTES)
            profile = ModProfile(
                key="Test", name="Test", mod_root=root, workshopid=1,
                content_path=root, preview_path=preview, title="Test",
            )
            selection = UpdateSelection(content=False, title=False, description=False, tags=False, visibility=False)
            result = validate(profile, selection)
            self.assertFalse(result.ok)
            self.assertIn("under", result.errors[0])

    def test_actual_gif_signature_is_detected_even_without_extension(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "preview.png"
            path.write_bytes(b"GIF89a" + b"x")
            self.assertEqual(image_kind(path), "GIF")

    def test_steam_field_limits_are_validated(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            profile = ModProfile(
                key="Test",
                name="Test",
                mod_root=root,
                workshopid=1,
                content_path=root,
                title="x" * (MAX_TITLE_LENGTH + 1),
                description="x" * (MAX_DESCRIPTION_LENGTH + 1),
            )
            selection = UpdateSelection(
                content=False,
                preview=False,
                title=True,
                description=True,
                tags=False,
                visibility=False,
                change_note="x" * (MAX_CHANGE_NOTE_LENGTH + 1),
            )
            result = validate(profile, selection)
            self.assertFalse(result.ok)
            self.assertTrue(any("Title must" in error for error in result.errors))
            self.assertTrue(any("Description must" in error for error in result.errors))
            self.assertTrue(any("Change note must" in error for error in result.errors))

    def test_selective_request_contains_field_mask_without_changing_values(self) -> None:
        profile = ModProfile(
            key="Test",
            name="Test",
            mod_root=Path("/tmp"),
            workshopid=42,
            title="Local title",
            description="Local description",
            tags=["Build 42"],
        )
        request = selective_request_for(
            profile,
            UpdateSelection(
                content=True,
                preview=False,
                title=False,
                description=False,
                tags=False,
                visibility=False,
                change_note="Only content changed",
            ),
        )
        self.assertEqual(request["fields"], ["content"])
        self.assertEqual(request["title"], "Local title")
        self.assertEqual(request["description"], "Local description")
        self.assertEqual(request["tags"], ["Build 42"])


if __name__ == "__main__":
    unittest.main()
