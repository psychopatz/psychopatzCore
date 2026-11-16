"""G1 tests: CodeBuilder generation recipe validation and effect-free desired-artifact ledger."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.generation_recipe import (
    DEFAULT_RECIPE_PATH,
    DESIRED_LEDGER_SCHEMA,
    GENERATION_RECIPE_SCHEMA,
    build_desired_artifact_ledger,
    load_generation_recipe,
    validate_generation_recipe,
)
from tools.semantic_harness.tests.test_convo_engine_s9h6_build_planner import (
    _build_three_repo_fixture,
)


class GenerationRecipeTests(unittest.TestCase):
    def test_default_recipe_loads_and_validates(self) -> None:
        recipe = load_generation_recipe(DEFAULT_RECIPE_PATH)
        self.assertEqual(recipe.schema, GENERATION_RECIPE_SCHEMA)
        self.assertEqual(recipe.version, 1)
        surface_ids = {s.id for s in recipe.surfaces}
        self.assertEqual(
            surface_ids,
            {
                "conversation_lua",
                "conversation_translations",
                "conversation_ui",
                "conversation_text",
                "lexicon_lua",
            },
        )
        self.assertEqual(recipe.surface("conversation_ui").policy, "mixed_key_catalog")
        self.assertEqual(recipe.surface("conversation_lua").policy, "owned_fileset")
        self.assertIn("--check", recipe.canonical_cli.get("check", ""))
        self.assertIn("--apply", recipe.canonical_cli.get("apply", ""))

    def test_recipe_fails_closed_on_unknown_owner_policy_generator_or_surface(self) -> None:
        base_doc = json.loads(DEFAULT_RECIPE_PATH.read_text(encoding="utf-8"))

        bad_owner = json.loads(json.dumps(base_doc))
        bad_owner["surfaces"][0]["owners"].append("UnknownOwnerMod")
        with self.assertRaisesRegex(CompileError, "unknown semantic package owner"):
            validate_generation_recipe(bad_owner)

        bad_policy = json.loads(json.dumps(base_doc))
        bad_policy["surfaces"][0]["policy"] = "delete_everything_by_timestamp"
        with self.assertRaisesRegex(CompileError, "policy is unsupported"):
            validate_generation_recipe(bad_policy)

        bad_gen = json.loads(json.dumps(base_doc))
        bad_gen["surfaces"][0]["generator"] = "shadow_generator"
        with self.assertRaisesRegex(CompileError, "generator is unsupported"):
            validate_generation_recipe(bad_gen)

        bad_surface = json.loads(json.dumps(base_doc))
        bad_surface["surfaces"][0]["id"] = "unregistered_surface"
        with self.assertRaisesRegex(CompileError, "id is unsupported"):
            validate_generation_recipe(bad_surface)

        bad_retired = json.loads(json.dumps(base_doc))
        bad_retired["retired"] = [
            {
                "id": "bad.retired",
                "surface": "conversation_lua",
                "kind": "file",
                "owner": "UnknownOwner",
                "path": "Contents/mods/Foo/Bar.lua",
            }
        ]
        with self.assertRaisesRegex(CompileError, "unknown semantic package owner"):
            validate_generation_recipe(bad_retired)

    def test_desired_artifact_ledger_is_effect_free_and_covers_all_owners(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            # Record initial file state across all three fixture repos
            before_files = {
                name: sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
                for name, root in repos.items()
            }

            ledger = build_desired_artifact_ledger(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )

            after_files = {
                name: sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
                for name, root in repos.items()
            }
            self.assertEqual(before_files, after_files)
            self.assertEqual(ledger.schema, DESIRED_LEDGER_SCHEMA)
            self.assertEqual(
                ledger.enabled_owners,
                ("PsychopatzCore", "ProjectHoomans", "DTCommon"),
            )
            self.assertGreater(len(ledger.rows), 0)

            owners_in_rows = {row.owner for row in ledger.rows}
            self.assertEqual(
                owners_in_rows,
                {"PsychopatzCore", "ProjectHoomans", "DTCommon"},
            )
            for row in ledger.rows:
                self.assertEqual(len(row.content_fingerprint), 64)
                self.assertTrue(row.rendered_content)
                self.assertTrue(row.source_lineage)


if __name__ == "__main__":
    unittest.main()
