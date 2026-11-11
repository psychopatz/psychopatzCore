"""Tests for source-to-runtime module naming."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.catalog_naming import (
    ModuleNameRegistry,
    source_owned_module,
)


class CatalogNamingTests(unittest.TestCase):
    def test_responses_root_is_not_repeated_in_generated_module(self) -> None:
        module = source_owned_module(
            "PNC/Semantics/Generated/Conversation/Responses",
            "responses/common/social.json",
            ModuleNameRegistry(),
        )
        self.assertEqual(
            module,
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        )


if __name__ == "__main__":
    unittest.main()
