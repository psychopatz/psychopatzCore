from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.providers.mod_manager import (
    ModManager,
    ModManagerError,
    ProviderSpec,
)
from tools.semantic_harness.providers.provider_registry import CORE_PROVIDER_ID


def spec(
    root: Path,
    provider_id: str,
    *,
    requires: tuple[str, ...] = (),
    routes: dict[str, int] | None = None,
    modes: tuple[str, ...] = ("abstract", "physical"),
    conflicts: tuple[str, ...] = (),
) -> ProviderSpec:
    return ProviderSpec(
        provider_id=provider_id,
        display_name=provider_id,
        repository_kind="fixture",
        repository_root=root,
        manifest_path=root / "provider.json",
        requires=requires,
        route_claims=routes or {},
        materialization_modes=modes,
        conflicts=conflicts,
    )


class ModManagerTests(unittest.TestCase):
    def test_resolves_dependencies_and_routes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manager = ModManager(
                root,
                (
                    spec(root, "ProjectHoomans", requires=(CORE_PROVIDER_ID,), routes={"semantic.conversation": 100}, modes=("physical",)),
                    spec(root, "DTCommon", requires=(CORE_PROVIDER_ID,)),
                    spec(root, "DTHoomans", requires=(CORE_PROVIDER_ID, "DTCommon"), routes={"trading.interaction": 100}, modes=("physical",)),
                ),
                presets={
                    "combined": {
                        "providers": ["ProjectHoomans", "DTHoomans"],
                        "materializationMode": "physical",
                    }
                },
            )

            plan = manager.resolve(preset="combined")

            self.assertEqual(
                plan.provider_ids,
                (CORE_PROVIDER_ID, "ProjectHoomans", "DTCommon", "DTHoomans"),
            )
            self.assertEqual(plan.routes["semantic.conversation"], "ProjectHoomans")
            self.assertEqual(plan.routes["trading.interaction"], "DTHoomans")

    def test_rejects_competing_route_owners(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manager = ModManager(
                root,
                (
                    spec(root, "First", requires=(CORE_PROVIDER_ID,), routes={"semantic.conversation": 10}),
                    spec(root, "Second", requires=(CORE_PROVIDER_ID,), routes={"semantic.conversation": 10}),
                ),
            )
            with self.assertRaisesRegex(ModManagerError, "competing owners"):
                manager.resolve(provider_ids=("First", "Second"))

    def test_rejects_conflicting_provider_selection(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manager = ModManager(
                root,
                (
                    spec(root, "First", requires=(CORE_PROVIDER_ID,), conflicts=("Second",)),
                    spec(root, "Second", requires=(CORE_PROVIDER_ID,)),
                ),
            )
            with self.assertRaisesRegex(ModManagerError, "conflicts"):
                manager.resolve(provider_ids=("First", "Second"))

    def test_custom_selection_uses_a_shared_materialization_mode(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manager = ModManager(
                root,
                (
                    spec(root, "AbstractOnly", requires=(CORE_PROVIDER_ID,), modes=("abstract",)),
                ),
            )

            plan = manager.resolve(provider_ids=("AbstractOnly",))

            self.assertEqual(plan.materialization_mode, "abstract")

    def test_manifest_environment_is_part_of_the_activation_contract(self) -> None:
        manager = ModManager.discover(
            core_repository="/home/psychopatz/Zomboid/Workshop/psychopatzCore",
            repository_roots=(
                "/home/psychopatz/Zomboid/Workshop/ProjectHoomans",
                "/home/psychopatz/Zomboid/Workshop/DynamicTrading",
            ),
        )

        plan = manager.resolve(preset="pnc-with-dthoomans")

        self.assertEqual(
            plan.environment["SEMANTIC_HARNESS_PNC_REPOSITORY"],
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans",
        )
        self.assertEqual(
            plan.environment["SEMANTIC_HARNESS_DT_REPOSITORY"],
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading",
        )
        self.assertIn("${runtime:ProjectHoomans}", plan.environment["PZ_TEST_HOOMANS_RUNTIME"])

    def test_direct_expansion_manifest_is_discovered_without_core_changes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            core = root / "Core"
            expansion = root / "FutureExpansion"
            core.mkdir()
            expansion.mkdir()
            (expansion / "provider.json").write_text(
                '{"schema":"semantic.provider_manifest.v2",'
                '"providers":[{"providerID":"FutureExpansion",'
                '"displayName":"Future Expansion",'
                '"requires":["PsychopatzCore"],'
                '"capabilities":["future.example"],'
                '"materializationModes":["abstract"]}]}',
                encoding="utf-8",
            )

            manager = ModManager.discover(
                core_repository=core,
                repository_roots=(expansion,),
            )
            plan = manager.resolve(provider_ids=("FutureExpansion",))

            self.assertEqual(plan.provider_ids, (CORE_PROVIDER_ID, "FutureExpansion"))

    def test_discovers_workspace_provider_manifests(self) -> None:
        manager = ModManager.discover(
            core_repository="/home/psychopatz/Zomboid/Workshop/psychopatzCore",
            repository_roots=(
                "/home/psychopatz/Zomboid/Workshop/ProjectHoomans",
                "/home/psychopatz/Zomboid/Workshop/DynamicTrading",
            ),
        )

        plan = manager.resolve(preset="pnc-with-dthoomans")

        self.assertIn("ProjectHoomans", plan.provider_ids)
        self.assertIn("DTHoomans", plan.provider_ids)
        self.assertNotIn("provider/DTAbstract", plan.modules)
        self.assertIn("provider/DTHoomans", plan.modules)


if __name__ == "__main__":
    unittest.main()
