from __future__ import annotations

import unittest

from semantic_harness.profile_loader import compose_profile
from semantic_harness.provider_registry import (
    CORE_PROVIDER_ID,
    ProviderDescriptor,
    ProviderRegistry,
    ProfileDescriptor,
)


class ProfileLoaderTests(unittest.TestCase):
    def register_fixture(self, registry: ProviderRegistry) -> None:
        registry.register_provider(
            ProviderDescriptor(
                provider_id="FixtureAbstract",
                display_name="Fixture abstract provider",
                requires=(CORE_PROVIDER_ID,),
                materialization_modes=("abstract",),
            )
        )
        registry.register_profile(
            ProfileDescriptor(
                profile_id="fixture-abstract",
                display_name="Fixture abstract profile",
                provider_ids=(CORE_PROVIDER_ID, "FixtureAbstract"),
                materialization_mode="abstract",
            )
        )

    def test_composes_adopter_registrar_without_importing_it(self) -> None:
        selection = compose_profile(
            "fixture-abstract",
            registrars=(self.register_fixture,),
            available_provider_ids=(CORE_PROVIDER_ID, "FixtureAbstract"),
        )

        self.assertEqual(selection.profile_id, "fixture-abstract")
        self.assertEqual(
            selection.provider_ids,
            (CORE_PROVIDER_ID, "FixtureAbstract"),
        )
        self.assertEqual(selection.materialization_mode, "abstract")
        self.assertEqual(
            selection.launch_environment()["SEMANTIC_HARNESS_PROVIDER_IDS"],
            "PsychopatzCore,FixtureAbstract",
        )

    def test_registrar_must_not_replace_registry(self) -> None:
        def bad_registrar(_registry: ProviderRegistry) -> object:
            return ProviderRegistry()

        with self.assertRaisesRegex(TypeError, "must mutate"):
            compose_profile("core", registrars=(bad_registrar,))


if __name__ == "__main__":
    unittest.main()
