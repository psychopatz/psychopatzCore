from __future__ import annotations

import unittest

from semantic_harness.provider_registry import (
    CORE_PROVIDER_ID,
    ProfileDescriptor,
    ProviderContractError,
    ProviderDescriptor,
    ProviderRegistry,
    core_registry,
    register_provider_profile,
)


class ProviderRegistryTests(unittest.TestCase):
    def test_core_registry_is_standalone(self) -> None:
        registry = core_registry()
        resolved = registry.resolve("core")

        self.assertEqual(resolved.provider_ids, (CORE_PROVIDER_ID,))
        self.assertEqual(resolved.profile.materialization_mode, "none")
        self.assertEqual(
            registry.describe()["schema"],
            "semantic.harness.provider_registry.v1",
        )

    def test_adopter_profile_is_explicitly_composed(self) -> None:
        registry = core_registry()
        register_provider_profile(
            registry,
            provider=ProviderDescriptor(
                provider_id="DTCommon",
                display_name="Dynamic Trading shared provider",
                repository_kind="dynamic_trading",
                requires=(CORE_PROVIDER_ID,),
                capabilities=("trading.conversation",),
                materialization_modes=("abstract", "physical"),
            ),
            profile_id="dtabstract",
            profile_name="Dynamic Trading abstract",
            provider_ids=(CORE_PROVIDER_ID, "DTCommon"),
            materialization_mode="abstract",
        )

        resolved = registry.resolve("dtabstract")
        self.assertEqual(
            resolved.provider_ids,
            (CORE_PROVIDER_ID, "DTCommon"),
        )

    def test_profile_missing_provider_fails_closed(self) -> None:
        registry = core_registry()
        registry.register_profile(
            ProfileDescriptor(
                profile_id="hoomans",
                display_name="Project Hoomans",
                provider_ids=(CORE_PROVIDER_ID, "ProjectHoomans"),
                materialization_mode="physical",
            )
        )

        with self.assertRaisesRegex(
            ProviderContractError, r"missing provider\(s\): ProjectHoomans"
        ):
            registry.resolve("hoomans")

    def test_provider_dependency_must_be_in_profile(self) -> None:
        registry = core_registry()
        registry.register_provider(
            ProviderDescriptor(
                provider_id="DTAbstract",
                display_name="Dynamic Trading abstract provider",
                requires=("DTCommon",),
                materialization_modes=("abstract",),
            )
        )
        registry.register_profile(
            ProfileDescriptor(
                profile_id="invalid",
                display_name="Invalid profile",
                provider_ids=(CORE_PROVIDER_ID, "DTAbstract"),
                materialization_mode="abstract",
            )
        )

        with self.assertRaisesRegex(
            ProviderContractError, r"omits dependency\(s\) for DTAbstract"
        ):
            registry.resolve("invalid")


if __name__ == "__main__":
    unittest.main()
