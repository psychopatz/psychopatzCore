from __future__ import annotations

import unittest

from semantic_harness.codebuilder import (
    CatalogNameError,
    CompileError,
    ModuleNameRegistry,
    merge_language_sets,
    module_path,
    normalize_language,
    normalize_translations,
    pascal_segment,
)


class CoreCodeBuilderTests(unittest.TestCase):
    def test_translation_helpers_are_deterministic_and_fail_closed(self) -> None:
        self.assertEqual(normalize_language(" tl "), "TL")
        self.assertEqual(
            normalize_translations({"tl": " Kumusta ", "en": " Hello "}, "reply"),
            {"EN": "Hello", "TL": "Kumusta"},
        )
        self.assertEqual(
            merge_language_sets({"tl": "Kumusta"}, {"en": "Hello"}),
            ("EN", "TL"),
        )
        with self.assertRaises(CompileError):
            normalize_language("not a locale")
        with self.assertRaises(CompileError):
            normalize_translations({"TL": "missing fallback"}, "reply")

    def test_module_naming_is_readable_and_collision_safe(self) -> None:
        self.assertEqual(pascal_segment("whats_up_part_01"), "WhatsUpPart01")
        registry = ModuleNameRegistry()
        first = module_path(
            "Catalog/Patterns", ["Question", "Identity"], "core.one", registry
        )
        second = module_path(
            "Catalog/Patterns", ["Question", "Identity"], "core.two", registry
        )
        self.assertEqual(first, "Catalog/Patterns/Question/Identity")
        self.assertTrue(second.startswith(first + "__"))

    def test_catalog_name_errors_use_the_core_compile_contract(self) -> None:
        self.assertTrue(issubclass(CatalogNameError, CompileError))


if __name__ == "__main__":
    unittest.main()
