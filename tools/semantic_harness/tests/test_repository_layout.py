from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.repository_layout import (
    DT_ABSTRACT_PROVIDER_ID,
    DT_HOOMANS_PROVIDER_ID,
    DT_COMMON_PROVIDER_ID,
    HOOMANS_PROVIDER_ID,
    RepositoryLayoutError,
    discover_layout,
)


def make_repository(root: Path, name: str, *modules: str) -> Path:
    repository = root / name
    for module in modules:
        (repository / "Contents/mods" / module).mkdir(parents=True)
    return repository


class RepositoryLayoutTests(unittest.TestCase):
    def test_core_only_discovery_does_not_require_adopters(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            core = make_repository(root, "psychopatzCore", "PsychopatzCore")

            layout = discover_layout(
                core_repository=core,
                cwd=root / "unrelated",
                environ={},
            )

            self.assertEqual(layout.core_repository, core.resolve())
            self.assertIsNone(layout.hoomans_repository)
            self.assertIsNone(layout.dynamic_trading_repository)
            self.assertEqual(layout.available_provider_ids(), ("PsychopatzCore",))

    def test_optional_repositories_advertise_available_provider_modes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_repository(root, "psychopatzCore", "PsychopatzCore")
            hoomans = make_repository(root, "ProjectHoomans", "ProjectHoomans")
            dynamic = make_repository(
                root,
                "DynamicTrading",
                "DTCommon",
                "DTAbstract",
                "DTHoomans",
            )

            layout = discover_layout(
                core_repository=root / "psychopatzCore",
                hoomans_repository=hoomans,
                dynamic_trading_repository=dynamic,
                cwd=root,
                environ={},
            )

            available = layout.available_provider_ids()
            self.assertIn(HOOMANS_PROVIDER_ID, available)
            self.assertIn(DT_COMMON_PROVIDER_ID, available)
            self.assertIn(DT_ABSTRACT_PROVIDER_ID, available)
            self.assertIn(DT_HOOMANS_PROVIDER_ID, available)

    def test_current_environment_selects_core_without_adopter_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            core = make_repository(root, "psychopatzCore", "PsychopatzCore")
            layout = discover_layout(
                cwd=root,
                environ={"SEMANTIC_HARNESS_CORE_REPOSITORY": str(core)},
            )

            self.assertEqual(layout.core_repository, core.resolve())

    def test_invalid_core_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            with self.assertRaises(RepositoryLayoutError):
                discover_layout(cwd=Path(temporary), environ={})


if __name__ == "__main__":
    unittest.main()
