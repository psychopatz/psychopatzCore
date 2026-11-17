"""S10R1 migrated acceptance for CodeBuilder dataset library, dialogue dataset compiler, and workflows."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.semantic_harness.codebuilder.dialogue_contract import (
    CompileError,
    validate_branch_offers,
)
from tools.semantic_harness.codebuilder.dialogue_dataset import compile_dialogue_dataset
from tools.semantic_harness.codebuilder.dialogue_rendering import (
    render_dialogue_lua,
    render_dialogue_translation,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.entrypoints import app
from tools.semantic_harness.entrypoints.cli import _parser, cli

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _package_repositories() -> dict[str, Path]:
    repos: dict[str, Path] = {"PsychopatzCore": CORE_ROOT}
    if HOOMANS_ROOT.is_dir():
        repos["ProjectHoomans"] = HOOMANS_ROOT
    if DT_ROOT.is_dir():
        repos["DTCommon"] = DT_ROOT
    return repos


def _run_cli(argv: list[str]) -> tuple[int, dict]:
    arguments = _parser().parse_args(argv)
    output = io.StringIO()
    with redirect_stdout(output):
        rc = cli(arguments)
    return rc, json.loads(output.getvalue())


class DatasetCompilerAndWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.service = SemanticLabAuthoringService(
            repository=CORE_ROOT,
            runtime_root=CORE_ROOT,
            core_repository=CORE_ROOT,
            dynamic_trading_repository=DT_ROOT if DT_ROOT.is_dir() else None,
        )

    def test_branch_offer_contract_is_typed_bounded_and_player_safe(self) -> None:
        offer = {
            "id": "lab.branch.offer",
            "labelKey": "UI_Lab_Branch_Label",
            "labelFallback": "Choose this",
            "utteranceKey": "UI_Lab_Branch_Utterance",
            "utteranceFallback": "Choose this.",
            "frame": {"intent": "THANK", "speechAct": "THANK"},
            "constraints": {
                "all": [
                    {"path": "ir.intent", "op": "eq", "value": "GREET"},
                    {
                        "any": [
                            {
                                "path": "npcState.activeBehavior",
                                "op": "eq",
                                "value": "idle",
                            },
                            {
                                "not": {
                                    "path": "npcState.healthState",
                                    "op": "eq",
                                    "value": "dead",
                                }
                            },
                        ],
                    },
                ],
            },
        }
        normalized = validate_branch_offers([offer], "lab.offers")
        self.assertEqual(normalized[0]["id"], "lab.branch.offer")
        self.assertEqual(normalized[0]["frame"]["intent"], "THANK")
        with self.assertRaises(CompileError):
            validate_branch_offers([{**offer, "visibility": "private"}], "lab.private")
        with self.assertRaises(CompileError):
            validate_branch_offers([{**offer, "constraints": {"mystery": True}}], "lab.unknown")

    def test_dataset_library_lists_only_existing_canonical_sources(self) -> None:
        sources = self.service.list_dataset_sources()
        ids = [source["id"] for source in sources]
        self.assertEqual(
            ids,
            [
                "convo_engine",
                "common_patterns",
                "grounded_personal_patterns",
                "wordnet_concepts",
            ],
        )
        # Retired pre-ConvoEngine dataset buckets must not be advertised.
        for retired in ("semantic_flows", "common_dialogue", "grounded_personal"):
            self.assertNotIn(retired, ids)
        self.assertTrue(all(source["exists"] for source in sources), sources)
        convo_source = next(source for source in sources if source["id"] == "convo_engine")
        self.assertFalse(convo_source["editable"])
        for source in sources:
            if source["id"] != "convo_engine":
                self.assertTrue(source["editable"], source)

        # Raw whole-catalog overwrite against convo_engine is refused.
        refused = self.service.write_dataset_document("convo_engine", {})
        self.assertFalse(refused["ok"])
        self.assertTrue(refused["previewOnly"])
        self.assertEqual(refused["writes"], [])

    def test_dataset_search_validation_and_generation_preview_use_canonical_sources(self) -> None:
        matches = self.service.search_dataset("follow", limit=8)
        self.assertTrue(matches)
        self.assertTrue(any(row["sourceID"] == "convo_engine" for row in matches))

        for source in self.service.list_dataset_sources():
            with self.subTest(source_id=source["id"]):
                doc = self.service.load_dataset_document(source["id"])
                report = self.service.preview_dataset_edit(source["id"], doc)
                self.assertTrue(report["ok"], report)
                self.assertTrue(report["previewOnly"])
                self.assertTrue(report["effectFree"])
                self.assertEqual(report["writes"], [])

        preview = self.service.preview_dataset_generation("convo_engine")
        self.assertTrue(preview["ok"], preview)
        self.assertTrue(preview["previewOnly"])
        self.assertEqual(preview["writes"], [])
        self.assertTrue(preview["generatedPaths"])
        self.assertTrue(all("Generated/Dialogue/" not in p for p in preview["generatedPaths"]))

    def test_cli_routes_dataset_block_and_workflow_operations(self) -> None:
        rc, listing = _run_cli(["--list-datasets", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertEqual(listing["type"], "dataset_library")
        self.assertTrue(all(item["exists"] for item in listing["sources"]))

        rc, search = _run_cli(["--search-datasets", "greet", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertEqual(search["type"], "dataset_search")
        self.assertTrue(search["results"])

        rc, shown = _run_cli(["--show-dataset", "convo_engine", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertEqual(shown["type"], "dataset")
        self.assertTrue(shown["entries"])

        rc, validated = _run_cli(["--validate-dataset", "convo_engine", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertTrue(validated["ok"])
        self.assertEqual(validated["writes"], [])

        rc, blocks = _run_cli(["--list-blocks", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertEqual(blocks["type"], "semantic_block_registry")
        self.assertTrue(blocks["blocks"])

        rc, block_search = _run_cli(["--search-blocks", "speech", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertTrue(block_search["results"])

        rc, block_val = _run_cli(["--validate-blocks", "language.speech_act,dialogue_responses.response_pool", "--jsonl"])
        self.assertEqual(rc, 0)
        self.assertTrue(block_val["ok"])

        rc, wf_preview = _run_cli([
            "--workflow-preview",
            "convo_engine",
            "--workflow-blocks",
            "language.speech_act,dialogue_responses.response_pool",
            "--jsonl",
        ])
        self.assertEqual(rc, 0)
        self.assertTrue(wf_preview["ok"])
        self.assertTrue(wf_preview["previewOnly"])
        self.assertEqual(wf_preview["writes"], [])

        # Unapproved --workflow-generate refuses without mutating workspace.
        unapproved = self.service.generate_workflow(
            "convo_engine",
            ["language.speech_act"],
            approved=False,
        )
        self.assertFalse(unapproved["ok"])
        self.assertFalse(unapproved["generationApproved"])
        self.assertEqual(unapproved["writes"], [])

        # CLI-only authoring flag selects headless mode rather than Tk GUI.
        with patch.object(app, "install_shutdown_handler"), patch.object(
            app, "cli", return_value=0
        ) as run_cli:
            self.assertEqual(app.main(["--list-datasets"]), 0)
        run_cli.assert_called_once()

    def test_workflow_generate_approved_runs_in_isolated_temp_workspace(self) -> None:
        from tools.semantic_harness.tests.convo_engine_test_support import (
            _setup_three_repo_workspace,
        )

        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            isolated = SemanticLabAuthoringService(
                repository=repos["core"],
                runtime_root=repos["core"],
                core_repository=repos["core"],
                dynamic_trading_repository=repos["dt"],
            )
            generated = isolated.generate_workflow(
                "convo_engine",
                ["language.speech_act", "dialogue_responses.response_pool"],
                approved=True,
            )
            self.assertTrue(generated["ok"], generated)
            self.assertTrue(generated["generationApproved"])
            self.assertTrue(generated["writes"])

    def test_dialogue_dataset_compiler_and_rendering_contract(self) -> None:
        synthetic_dataset = {
            "schemaVersion": 1,
            "source": {
                "name": "Reviewed fixture dataset",
                "version": "1",
                "contentLicense": "first_party",
                "references": [
                    {
                        "name": "Reviewed fixture dataset",
                        "url": "https://example.invalid/fixture",
                        "use": "unit_test_fixture",
                        "license": "first_party",
                        "reviewedOn": "2026-11-16",
                        "version": "1",
                        "contentLicense": "first_party",
                        "importStatus": {"imported": 1, "mapped": 1, "approved": 1},
                    }
                ]
            },
            "patterns": [
                {
                    "id": "pnc.dataset.weather.rain_check",
                    "utterance": "Is it raining outside?",
                    "emit": {
                        "intent": "QUESTION",
                        "speechAct": "QUESTION",
                        "subject": "WEATHER",
                    },
                    "reviewed": True,
                    "sourceRefs": ["Reviewed fixture dataset"],
                    "mapping": {
                        "canonicalConcept": "WEATHER",
                        "dialogueState": "WEATHER_TOPIC",
                        "sourceRefs": ["Reviewed fixture dataset"],
                    },
                    "negatives": ["Is the car working?"],
                    "confidence": 0.95,
                    "priority": 100,
                }
            ],
            "responsePools": [
                {
                    "id": "semantic.flow.weather.raining",
                    "variants": [
                        {
                            "id": "semantic.flow.weather.raining.default",
                            "templateID": "UI_PNC_Conversation_DatasetWeatherRain",
                            "fallback": "Yeah, it's pouring out there.",
                            "translations": {
                                "EN": "Yeah, it's pouring out there.",
                                "TL": "Oo, malakas ang ulan sa labas.",
                            },
                            "reviewed": True,
                            "sourceRefs": ["Reviewed fixture dataset"],
                            "when": {"pattern": "pnc.dataset.weather.rain_check"},
                            "plan": {
                                "dialogueAct": "WEATHER_REPORT",
                                "groundedFactRefs": ["world.weather.raining"],
                                "uncertainty": "known",
                                "turns": [{
                                    "segments": [{
                                        "kind": "translation",
                                        "templateID": "UI_PNC_Conversation_DatasetWeatherRain",
                                        "fallback": "Yeah, it's pouring out there.",
                                    }],
                                }],
                            },
                        }
                    ],
                }
            ],
        }
        compiled = compile_dialogue_dataset(synthetic_dataset)
        self.assertEqual(len(compiled["patterns"]), 1)
        self.assertNotIn("Is the car working?", json.dumps(compiled["patterns"]))
        self.assertEqual(
            render_dialogue_translation(compiled, "EN"),
            render_dialogue_translation(compiled, "EN"),
        )
        self.assertIn("UI_PNC_Conversation_DatasetWeatherRain", render_dialogue_lua(compiled))

        unreviewed = {
            **synthetic_dataset,
            "patterns": [{**synthetic_dataset["patterns"][0], "reviewed": False}],
        }
        with self.assertRaises(CompileError):
            compile_dialogue_dataset(unreviewed)

    def test_workspace_catalog_ignores_system_temp_root_siblings(self) -> None:
        from tools.semantic_harness.codebuilder.workspace_catalog import WorkspaceCatalog

        with tempfile.TemporaryDirectory() as isolated_repo, tempfile.TemporaryDirectory() as stray_sibling:
            stray_manifest = Path(stray_sibling) / "provider.json"
            stray_manifest.write_text(
                json.dumps(
                    {
                        "schema": "semantic.provider_manifest.v2",
                        "schemaVersion": 2,
                        "providers": [
                            {
                                "providerID": "ProjectHoomans",
                                "displayName": "Duplicate Temp Checkout",
                                "repositoryKind": "project_hoomans",
                                "requires": ["PsychopatzCore"],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            snapshot = WorkspaceCatalog.discover(
                repository=Path(isolated_repo),
                core_repository=CORE_ROOT,
            )
            self.assertNotEqual(
                snapshot.repository_by_owner.get("ProjectHoomans"),
                Path(stray_sibling).resolve(),
            )


if __name__ == "__main__":
    unittest.main()
