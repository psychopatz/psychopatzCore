"""S10R1 migrated acceptance for C5 context health, variation auditor, dataset adapters, and interaction specs."""

from __future__ import annotations

from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.conversation_contract import (
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_SOURCE_RELATIVE,
)
from tools.semantic_harness.codebuilder.conversation_health import (
    conversation_affected_closure,
    conversation_context_health,
)
from tools.semantic_harness.codebuilder.dataset_adapters import (
    preview_dataset_adapter,
    promote_reviewed_candidates,
)
from tools.semantic_harness.codebuilder.dialogue_content import (
    MAX_PHRASES_PER_STYLE,
    CompileError,
    compile_dialogue_content,
)
from tools.semantic_harness.codebuilder.interaction_spec import (
    compile_interaction_spec,
    edit_interaction_graph,
    graph_block,
    graph_connection,
    validate_interaction_spec,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.variation_auditor import (
    CLASSIFICATION_EXPAND,
    CLASSIFICATION_PLAYER_UI,
    CLASSIFICATION_THIRD_PARTY,
    audit_corpus,
    classify_style,
    extract_placeholders,
    normalize_exact,
    normalize_near,
)
from tools.semantic_harness.entrypoints.cli import _parser, cli
from tools.semantic_harness.tests.test_convo_engine_convergence_regressions import (
    _sample_family,
    _setup_three_repo_workspace,
)

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


def _run_cli(argv: list[str]) -> tuple[int, str]:
    arguments = _parser().parse_args(argv)
    output = io.StringIO()
    with redirect_stdout(output):
        rc = cli(arguments)
    return rc, output.getvalue()


class ContextHealthVariationAdaptersAndSpecsTests(unittest.TestCase):
    def test_c5_context_health_closure_budget_and_third_locale_compile(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repository=repos["core"],
                runtime_root=repos["core"],
                core_repository=repos["core"],
                dynamic_trading_repository=repos["dt"],
            )
            family_path = (
                repos["core"]
                / CONVERSATION_SOURCE_RELATIVE
                / "dialogue/social/third_locale_demo.json"
            )
            doc = _sample_family(
                owner="PsychopatzCore",
                namespace="social",
                family_id="third_locale_demo",
            )
            doc["say"] = {
                "EN": "Hello there.",
                "TL": "Kamusta ka.",
                "DE": "Hallo dort.",
            }
            family_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")

            model = compile_conversation_sources(
                repos["core"],
                runtime_root=repos["core"],
                package_repositories={
                    "PsychopatzCore": repos["core"],
                    "ProjectHoomans": repos["hoomans"],
                    "DTCommon": repos["dt"],
                },
            )
            rendered, reports = render_conversation_runtime_plan(model)
            self.assertTrue(rendered)
            self.assertNotIn("wholeModelFingerprint", json.dumps(reports))

            health = conversation_context_health(model, reports)
            self.assertEqual(health["status"], "pass", health)
            self.assertEqual(health["errors"], [])

            closure = conversation_affected_closure(model, reports, "social.core_greet")
            self.assertIsNotNone(closure)
            self.assertIn("social.core_greet", closure["closureIDs"])

            svc_health = service.conversation_context_health()
            self.assertEqual(svc_health["status"], "pass")
            svc_closure = service.conversation_affected_closure("social.core_greet")
            self.assertIsNotNone(svc_closure)
            svc_discovery = service.conversation_discovery_record("social.core_greet")
            self.assertIsNotNone(svc_discovery)

            # Assert third locale flows through compiled translations without a whitelist.
            self.assertIn("DE", json.dumps(model, default=str))

    def test_dialogue_content_limits_and_variation_auditor_live_plus_cli(self) -> None:
        self.assertEqual(MAX_PHRASES_PER_STYLE, 16)
        phrases = [
            {"EN": f"Line {i}.", "TL": f"Linya {i}."}
            for i in range(16)
        ]
        valid_doc = {
            "schemaVersion": 4,
            "source": {"name": "Fixture", "version": "1", "contentLicense": "CC0"},
            "groups": {
                "demo": {
                    "patternID": "pnc.demo",
                    "intent": "GREET",
                    "speechAct": "GREET",
                    "contentOwner": "pnc.dialogue_content.social",
                }
            },
            "phraseFamilies": [
                {
                    "semanticTemplateID": "semantic.greeting.demo",
                    "group": "demo",
                    "styles": {"neutral": phrases},
                }
            ],
        }
        compiled = compile_dialogue_content(valid_doc)
        self.assertEqual(len(compiled["phraseFamilies"][0]["styles"]["neutral"]), 16)

        too_many = {
            **valid_doc,
            "phraseFamilies": [
                {
                    **valid_doc["phraseFamilies"][0],
                    "styles": {
                        "neutral": phrases
                        + [{"EN": "Extra.", "TL": "Sobra."}]
                    },
                }
            ],
        }
        with self.assertRaises(CompileError):
            compile_dialogue_content(too_many)

        with self.assertRaises(CompileError):
            compile_dialogue_content({
                **valid_doc,
                "phraseFamilies": [
                    {**valid_doc["phraseFamilies"][0], "styles": {"neutral": []}}
                ],
            })

        self.assertEqual(normalize_exact("  Hello   World! "), "hello world!")
        self.assertEqual(normalize_near("Hello, World!"), "hello world")
        self.assertEqual(extract_placeholders("Hi {speaker_name}, see {target_name}"), ["speaker_name", "target_name"])
        self.assertEqual(classify_style("content/compatibility.json", "semantic.compat.bandit", "neutral", [])[0], CLASSIFICATION_THIRD_PARTY)
        self.assertEqual(classify_style("content/command/player.json", "semantic.command.player.follow", "neutral", [])[0], CLASSIFICATION_PLAYER_UI)
        self.assertEqual(classify_style("dialogue/social/greet.json", "social.greet", "neutral", [])[0], CLASSIFICATION_EXPAND)

        report = audit_corpus(repository=CORE_ROOT)
        self.assertGreater(report.total_families, 100)
        self.assertGreater(report.total_styles, 100)

        rc, raw_json = _run_cli(["--variation-audit", "--variation-audit-json"])
        self.assertEqual(rc, 0)
        parsed = json.loads(raw_json)
        self.assertEqual(parsed["total_families"], report.total_families)

        rc, ledger = _run_cli(["--variation-audit", "--variation-audit-ledger", "--variation-audit-under-10"])
        self.assertEqual(rc, 0)
        self.assertIn("Canonical Dialogue Variation", ledger)

    def test_dataset_adapters_massive_sgd_media_rejection_promotion_and_cli(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            massive_src = root / "massive_sample.jsonl"
            massive_src.write_text(
                json.dumps({"id": "m1", "utt": "how is the weather today", "intent": "weather_query", "locale": "en-US"}) + "\n",
                encoding="utf-8",
            )
            massive_sha = hashlib.sha256(massive_src.read_bytes()).hexdigest()
            massive_manifest = root / "massive_manifest.json"
            massive_manifest.write_text(
                json.dumps({
                    "sourceName": "MASSIVE",
                    "adapter": "massive",
                    "version": "1.0",
                    "revision": "rev1",
                    "url": "https://example.invalid/massive",
                    "sha256": massive_sha,
                    "language": "en-US",
                    "license": "CC-BY-4.0",
                    "allowedUse": "evaluation_and_review",
                    "redistribution": "metadata_only",
                    "reviewedOn": "2026-11-16",
                    "allowRawText": False,
                }),
                encoding="utf-8",
            )
            massive_report = preview_dataset_adapter("massive", massive_src, massive_manifest)
            self.assertTrue(massive_report["ok"], massive_report)
            self.assertFalse(massive_report["runtimePackaged"])
            self.assertEqual(massive_report["candidateCount"], 1)

            # Metadata-only manifests block raw-text promotion.
            blocked = promote_reviewed_candidates(massive_report, [{"candidateID": massive_report["candidates"][0]["id"], "approved": True, "mapping": {"emit": {"intent": "QUESTION"}, "canonicalConcept": "WEATHER", "dialogueState": "WEATHER_TOPIC"}}])
            self.assertFalse(blocked["ok"])

            # Approved SGD review converts bounded user turns.
            sgd_src = root / "sgd_sample.json"
            sgd_src.write_text(
                json.dumps([{
                    "dialogue_id": "d1",
                    "service": "weather_1",
                    "turns": [
                        {"speaker": "USER", "utterance": "Is it going to rain?", "frames": [{"service": "weather_1", "state": {"active_intent": "GetWeather", "slot_values": {}}}]},
                        {"speaker": "SYSTEM", "utterance": "Yes."},
                    ],
                }]),
                encoding="utf-8",
            )
            sgd_sha = hashlib.sha256(sgd_src.read_bytes()).hexdigest()
            sgd_manifest = root / "sgd_manifest.json"
            sgd_manifest.write_text(
                json.dumps({
                    "sourceName": "SGD",
                    "adapter": "sgd",
                    "version": "1.0",
                    "revision": "rev1",
                    "url": "https://example.invalid/sgd",
                    "sha256": sgd_sha,
                    "language": "en-US",
                    "license": "CC-BY-SA-4.0",
                    "allowedUse": "pattern_authoring",
                    "redistribution": "approved",
                    "allowRawText": True,
                    "reviewedOn": "2026-11-16",
                }),
                encoding="utf-8",
            )
            sgd_report = preview_dataset_adapter("sgd", sgd_src, sgd_manifest)
            self.assertTrue(sgd_report["ok"], sgd_report)
            promoted = promote_reviewed_candidates(
                sgd_report,
                [{
                    "candidateID": sgd_report["candidates"][0]["id"],
                    "approved": True,
                    "mapping": {
                        "emit": {"intent": "QUESTION", "subject": "WEATHER"},
                        "canonicalConcept": "WEATHER",
                        "dialogueState": "WEATHER_TOPIC",
                    },
                }],
            )
            self.assertTrue(promoted["ok"], promoted)
            self.assertEqual(promoted["promotedCount"], 1)

            # Runtime media paths are rejected.
            media_dir = root / "Contents/mods/TestMod/media"
            media_dir.mkdir(parents=True)
            media_src = media_dir / "leak.json"
            media_src.write_text("[]", encoding="utf-8")
            media_manifest = root / "media_manifest.json"
            media_manifest.write_text(json.dumps({
                "sourceName": "BAD", "adapter": "sgd", "version": "1", "revision": "r1",
                "url": "https://example.invalid/bad", "sha256": hashlib.sha256(media_src.read_bytes()).hexdigest(),
                "language": "en-US", "license": "MIT", "allowedUse": "none",
                "redistribution": "metadata_only", "reviewedOn": "2026-11-16",
            }), encoding="utf-8")
            rejected = preview_dataset_adapter("sgd", media_src, media_manifest)
            self.assertFalse(rejected["ok"])

            # CLI routes --adapt-dataset cleanly.
            rc, out = _run_cli([
                "--adapt-dataset", "massive",
                "--dataset-source", str(massive_src),
                "--dataset-manifest", str(massive_manifest),
                "--jsonl",
            ])
            self.assertEqual(rc, 0)
            cli_payload = json.loads(out)
            self.assertTrue(cli_payload["ok"])
            self.assertEqual(cli_payload["candidateCount"], 1)

    def test_interaction_spec_graph_validation_compile_and_codeblocks_cli(self) -> None:
        service = SemanticLabAuthoringService(
            repository=CORE_ROOT,
            runtime_root=CORE_ROOT,
            core_repository=CORE_ROOT,
            dynamic_trading_repository=DT_ROOT if DT_ROOT.is_dir() else None,
        )
        valid_spec = {
            "schema": "semantic.interaction_spec.v1",
            "id": "pnc.lab.stay",
            "owner": "SemanticLab",
            "blocks": [
                graph_block(
                    "trigger",
                    "language.trigger",
                    parameters={
                        "utterance": "stay with me",
                        "negativeUtterance": "don't stay with me",
                        "frame": {"intent": "REQUEST", "speechAct": "REQUEST", "action": "STAY"},
                    },
                ),
                graph_block(
                    "capability",
                    "gameplay_actions.capability",
                    parameters={
                        "capabilityID": "pnc:companion.stay",
                        "action": "STAY",
                    },
                ),
                graph_block(
                    "response",
                    "dialogue_responses.response_pool",
                    parameters={
                        "poolID": "semantic.lab.stay",
                        "variants": [{
                            "id": "accepted",
                            "key": "UI_PNC_Conversation_Semantic_LabStayAccepted",
                            "translations": {"EN": "Okay, I'll stay.", "TL": "Sige, mananatili ako."},
                        }],
                    },
                ),
            ],
            "connections": [
                graph_connection("trigger", "capability", "semantic"),
                graph_connection("capability", "response", "response"),
            ],
        }
        validation = validate_interaction_spec(valid_spec)
        self.assertTrue(validation["ok"], validation)

        # Wrong typed edge is rejected.
        bad_spec = {
            **valid_spec,
            "connections": [graph_connection("trigger", "response", "response")],
        }
        self.assertFalse(validate_interaction_spec(bad_spec)["ok"])

        # Editable graph helpers mutate cleanly and fail closed on invalid cycles.
        edited = edit_interaction_graph(valid_spec, "disconnect", source_id="capability", target_id="response", connection_type="response")
        self.assertEqual(len(edited["connections"]), 1)

        preview = service.preview_interaction_spec(valid_spec, source_id="convo_engine")
        self.assertTrue(preview["ok"], preview)
        self.assertTrue(preview["previewOnly"])
        self.assertEqual(preview["writes"], [])

        unapproved = service.generate_interaction_spec(valid_spec, approved=False)
        self.assertFalse(unapproved["ok"])
        self.assertFalse(unapproved["generationApproved"])
        self.assertEqual(unapproved["writes"], [])

        with tempfile.TemporaryDirectory() as tmp:
            codeblocks_file = Path(tmp) / "flow.codeblocks.json"
            codeblocks_file.write_text(
                json.dumps({
                    "schema": "semantic.codeblocks.v1",
                    "flowID": "semantic.demo.codeblocks",
                    "owner": "PsychopatzCore",
                    "initial": "start",
                    "blocks": [
                        {"id": "start", "type": "terminal", "definition": {"terminal": True}},
                    ],
                    "connections": [],
                }),
                encoding="utf-8",
            )
            rc, out = _run_cli(["--validate-codeblocks", str(codeblocks_file), "--jsonl"])
            self.assertEqual(rc, 0)
            cb_payload = json.loads(out)
            self.assertTrue(cb_payload["ok"], cb_payload)


if __name__ == "__main__":
    unittest.main()
