from __future__ import annotations

import unittest
from types import SimpleNamespace

from tools.semantic_harness.ui.shell import SemanticHarnessApp


class GuiShellTests(unittest.TestCase):
    def test_selected_mods_flattens_repeatable_comma_values(self) -> None:
        app = object.__new__(SemanticHarnessApp)
        app.arguments = SimpleNamespace(mods=["ProjectHoomans,DTCommon", "DTHoomans"])

        self.assertEqual(
            app._selected_mods(),
            ("ProjectHoomans", "DTCommon", "DTHoomans"),
        )

    def test_selected_mods_returns_none_for_empty_selection(self) -> None:
        app = object.__new__(SemanticHarnessApp)
        app.arguments = SimpleNamespace(mods=None)

        self.assertIsNone(app._selected_mods())


if __name__ == "__main__":
    unittest.main()
