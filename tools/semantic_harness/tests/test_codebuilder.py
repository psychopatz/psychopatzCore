from __future__ import annotations

import unittest

from semantic_harness.codebuilder import (
    CatalogNameError,
    CompileError,
    ModuleNameRegistry,
    compile_typed_dataset,
    merge_language_sets,
    module_path,
    normalize_language,
    normalize_translations,
    pascal_segment,
)


class CoreCodeBuilderTests(unittest.TestCase):
    def test_typed_dataset_compiler_owns_envelope_and_ordering(self) -> None:
        document = {
            "schemaVersion": 1,
            "source": {
                "name": "Fixture",
                "version": "1",
                "contentLicense": "CC0",
                "references": [{
                    "name": "Fixture source",
                    "url": "https://example.test/fixture",
                    "use": "contract test",
                    "license": "CC0",
                    "reviewedOn": "2026-11-10",
                }],
            },
            "patterns": [
                {"id": "pattern.b", "utterance": "second"},
                {"id": "pattern.a", "utterance": "first"},
            ],
            "responsePools": [
                {"id": "pool.b", "variants": [{"id": "reply.b"}]},
                {"id": "pool.a", "variants": [{"id": "reply.a"}]},
            ],
        }

        def compile_pattern(value, source_names):
            self.assertEqual(source_names, {"Fixture source"})
            return {"id": value["id"]}, []

        def compile_pool(value, source_names):
            self.assertEqual(source_names, {"Fixture source"})
            return (
                {"id": value["id"], "variants": value["variants"]},
                {},
            )

        compiled = compile_typed_dataset(
            document,
            pattern_compiler=compile_pattern,
            response_compiler=compile_pool,
        )
        self.assertEqual(
            [item["id"] for item in compiled["patterns"]],
            ["pattern.a", "pattern.b"],
        )
        self.assertEqual(
            [item["id"] for item in compiled["responsePools"]],
            ["pool.a", "pool.b"],
        )

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
