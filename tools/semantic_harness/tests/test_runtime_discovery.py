from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from semantic_harness.runtime_discovery import (
    ConfigurationError,
    discover_newest_runtime,
)


class RuntimeDiscoveryTests(unittest.TestCase):
    def test_discover_newest_runtime_uses_numeric_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("common", "42.9", "42.20", "42.21", "notes"):
                (root / name).mkdir()

            self.assertEqual(discover_newest_runtime(root), "42.21")

    def test_discover_newest_runtime_rejects_missing_numeric_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "common").mkdir()

            with self.assertRaises(ConfigurationError):
                discover_newest_runtime(root)


if __name__ == "__main__":
    unittest.main()
