"""Tests for unified .convo DSL integration in the PsychopatzCore Semantic Harness."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_dsl_integration import (
    compile_convo_scripts,
    discover_convo_scripts,
    find_convo_pool_lineage,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


HOOMANS_REPO = Path(__file__).resolve().parents[4] / "ProjectHoomans"


class ConvoDSLIntegrationTests(unittest.TestCase):
    def test_discovers_and_validates_project_hoomans_convo_packs(self) -> None:
        if not HOOMANS_REPO.is_dir():
            self.skipTest("ProjectHoomans sibling repository not present")
        scripts = discover_convo_scripts(HOOMANS_REPO)
        self.assertGreaterEqual(len(scripts), 15)
        self.assertTrue(all(row["kind"] == "convo_dsl" for row in scripts))

        report = compile_convo_scripts(HOOMANS_REPO, check_only=True)
        self.assertTrue(report["ok"], msg=report.get("stderr") or report.get("stdout"))

    def test_authoring_service_exposes_convo_lineage_and_compilation(self) -> None:
        if not HOOMANS_REPO.is_dir():
            self.skipTest("ProjectHoomans sibling repository not present")
        service = SemanticLabAuthoringService(repository=HOOMANS_REPO)
        self.assertGreaterEqual(len(service.list_convo_scripts()), 15)

        lineage = find_convo_pool_lineage(
            HOOMANS_REPO,
            "semantic.greeting",
            {"semantic.greeting.rain": {"id": "semantic.greeting.rain"}},
        )
        rows = lineage.get("semantic.greeting.rain") or []
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["validatedBy"], "convo_dsl_compiler")
        self.assertIn("situational_and_weather.convo", rows[0]["sourcePath"])
        self.assertGreater(rows[0]["lineNumber"], 0)


if __name__ == "__main__":
    unittest.main()
