from __future__ import annotations

import unittest
from types import SimpleNamespace

from tools.semantic_harness.entrypoints.app import _should_run_cli


class AppDispatchTests(unittest.TestCase):
    def test_bare_invocation_is_gui_friendly(self) -> None:
        self.assertFalse(_should_run_cli(SimpleNamespace()))

    def test_explicit_headless_operations_stay_headless(self) -> None:
        for operation in ("input", "ping", "capabilities", "list_mods", "list_presets", "show_selection"):
            with self.subTest(operation=operation):
                self.assertTrue(_should_run_cli(SimpleNamespace(**{operation: True})))

    def test_no_gui_forces_headless_mode(self) -> None:
        self.assertTrue(_should_run_cli(SimpleNamespace(no_gui=True)))


if __name__ == "__main__":
    unittest.main()
