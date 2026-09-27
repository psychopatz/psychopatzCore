from __future__ import annotations

import unittest
from types import SimpleNamespace

from steam_uploader_gui.ui.editor import ModEditor


class DescriptionSectionTests(unittest.TestCase):
    def test_description_section_opens_when_description_updates_are_selected(self) -> None:
        class Section:
            expanded = False

            def set_expanded(self, value: bool) -> None:
                self.expanded = value

        section = Section()
        editor = SimpleNamespace(
            update_description_var=SimpleNamespace(get=lambda: True),
            sections={"description": section},
        )

        ModEditor._expand_description_for_update(editor)

        self.assertTrue(section.expanded)

    def test_description_section_stays_collapsed_when_description_is_not_selected(self) -> None:
        class Section:
            expanded = False

            def set_expanded(self, value: bool) -> None:
                self.expanded = value

        section = Section()
        editor = SimpleNamespace(
            update_description_var=SimpleNamespace(get=lambda: False),
            sections={"description": section},
        )

        ModEditor._expand_description_for_update(editor)

        self.assertFalse(section.expanded)


if __name__ == "__main__":
    unittest.main()
