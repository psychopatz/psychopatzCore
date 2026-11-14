"""Core-owned S6M5 normalization, UI projection, outcome registry, and runtime tests."""

from __future__ import annotations

import json
import shutil
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from tools.semantic_harness.codebuilder import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.conversation_registry import (
    render_conversation_registry,
)
from tools.semantic_harness.codebuilder.psdl_compiler import (
    compile_convo_engine_sources,
    render_convo_engine_runtime_plan,
    render_psdl_ui_plan,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


CORE_REPO = Path(__file__).resolve().parents[3]


class ConvoEngineS6M5CompilerTests(unittest.TestCase):
    def test_fold_suggestion_pair_separates_label_and_say_with_text_rows(self) -> None:
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            src_dir = repo / "tools/semantic_harness/codebuilder/sources/conversation/dialogue"
            src_dir.mkdir(parents=True)
            label_file = src_dir / "ui_suggestion_follow_label.json"
            utt_file = src_dir / "ui_suggestion_follow_utterance.json"
            dest_file = src_dir / "ui_suggestion_follow.json"
            label_file.write_text(
                json.dumps({
                    "schema": CONVO_ENGINE_SCHEMA,
                    "kind": "dialogue",
                    "namespace": "ui.suggestion.follow",
                    "id": "label",
                    "owner": "ProjectHoomans",
                    "metadata": {"textTarget": "UI_PNC_Conversation"},
                    "say": {"EN": "Follow", "TL": "Sumunod"},
                }),
                encoding="utf-8",
            )
            utt_file.write_text(
                json.dumps({
                    "schema": CONVO_ENGINE_SCHEMA,
                    "kind": "dialogue",
                    "namespace": "ui.suggestion.follow",
                    "id": "utterance",
                    "owner": "ProjectHoomans",
                    "metadata": {
                        "textTarget": "UI_PNC_Conversation",
                        "textKey": "suggestion.follow.utterance",
                    },
                    "say": {"EN": "Stick with me.", "TL": "Sumama ka sa akin."},
                }),
                encoding="utf-8",
            )
            # Also add explicit textKey via textRows on label source.
            label_data = json.loads(label_file.read_text(encoding="utf-8"))
            label_data["metadata"]["textKey"] = "suggestion.follow.label"
            label_file.write_text(json.dumps(label_data), encoding="utf-8")

            svc = SemanticLabAuthoringService(repository=repo, core_repository=CORE_REPO)
            result = svc.fold_suggestion_pair(
                label_file,
                [utt_file],
                dest_path=dest_file,
                write=True,
                prune_sources=True,
            )
            self.assertTrue(result["ok"])
            self.assertEqual(result["familyId"], "ui.suggestion.follow")
            doc = result["document"]
            self.assertEqual(doc["affordance"]["label"], {"EN": "Follow", "TL": "Sumunod"})
            self.assertEqual(doc["say"], {"EN": "Stick with me.", "TL": "Sumama ka sa akin."})
            row_keys = {row["key"] for row in doc["metadata"]["textRows"]}
            self.assertEqual(row_keys, {"suggestion.follow.label", "suggestion.follow.utterance"})
            self.assertFalse(label_file.exists())
            self.assertFalse(utt_file.exists())
            self.assertTrue(dest_file.exists())

    def test_fold_outcome_family_and_registry_outcome_lookup(self) -> None:
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            src_dir = repo / "tools/semantic_harness/codebuilder/sources/conversation/dialogue"
            src_dir.mkdir(parents=True)
            queued = src_dir / "command_camp_queued.json"
            trusted = src_dir / "command_camp_queued_trusted.json"
            rejected = src_dir / "command_camp_rejected.json"
            dest = src_dir / "command_camp.json"

            for path, rid, text in (
                (queued, "command.camp.queued", {"EN": "Heading to camp.", "TL": "Pupunta na sa kampo."}),
                (trusted, "command.camp.queued.trusted", {"EN": "On it, friend.", "TL": "Sige, kaibigan."}),
                (rejected, "command.camp.rejected", {"EN": "Can't make it now.", "TL": "Hindi ako makakaalis ngayon."}),
            ):
                path.write_text(
                    json.dumps({
                        "schema": CONVO_ENGINE_SCHEMA,
                        "kind": "dialogue",
                        "id": rid,
                        "owner": "PsychopatzCore",
                        "metadata": {"responsePoolID": rid},
                        "say": text,
                    }),
                    encoding="utf-8",
                )

            svc = SemanticLabAuthoringService(repository=repo, core_repository=CORE_REPO)
            result = svc.fold_outcome_family(
                {"queued": [queued, trusted], "rejected": [rejected]},
                dest_path=dest,
                family_namespace="command",
                family_id="camp",
                write=True,
                prune_sources=True,
            )
            self.assertTrue(result["ok"])
            self.assertEqual(result["outcomes"], ["queued", "rejected"])
            doc = result["document"]
            self.assertIn("reply", doc)
            self.assertIn("queued", doc["reply"])
            self.assertIn("rejected", doc["reply"])

            compiled = compile_convo_engine_sources(
                {dest: json.loads(dest.read_text(encoding="utf-8"))},
                allow_legacy_schema=False,
            )
            plans = render_convo_engine_runtime_plan(compiled)
            registry_lua = render_conversation_registry(
                {
                    "manifest": {"defaultOwner": "PsychopatzCore", "registryOwner": "PsychopatzCore"},
                    "content": {"contentFingerprint": "test-content"},
                    "wholeModelFingerprint": "test",
                },
                [],
                include_owners={"PsychopatzCore"},
            )
            self.assertIn("Registry.CONVO_REPLY_INDEX = {}", registry_lua)
            self.assertIn("function Registry.ConvoOutcome(templateID)", registry_lua)
            self.assertIn("replies", plans[0]["exchangeFamily"])

    def test_shard_offers_and_project_affordance_to_ui_and_slots(self) -> None:
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            src_dir = repo / "tools/semantic_harness/codebuilder/sources/conversation/dialogue"
            src_dir.mkdir(parents=True)
            bag_file = src_dir / "social_core_check_in.json"
            bag_file.write_text(
                json.dumps({
                    "schema": CONVO_ENGINE_SCHEMA,
                    "kind": "dialogue",
                    "id": "social.core_check_in",
                    "owner": "PsychopatzCore",
                    "metadata": {"textNamespace": "UI_PNC_Conversation_Suggestion"},
                    "offers": [
                        {
                            "id": "question.wellbeing",
                            "frame": {
                                "patternID": "semantic.ask.wellbeing",
                                "intent": "QUESTION",
                                "speechAct": "ASK_STATE",
                                "subject": "WELLBEING",
                                "topic": "wellbeing",
                            },
                            "metadata": {"order": 100},
                            "label": {"EN": "How are you?", "TL": "Kumusta ka?"},
                            "utterance": {"EN": "How are you holding up?", "TL": "Kumusta ka na?"},
                        },
                        {
                            "id": "question.activity",
                            "frame": {
                                "patternID": "semantic.ask.activity",
                                "intent": "QUESTION",
                                "speechAct": "ASK_STATE",
                                "subject": "ACTIVITY",
                                "topic": "activity",
                            },
                            "metadata": {"order": 110},
                            "label": {"EN": "Ask what doing", "TL": "Tanungin kung ano ang ginagawa"},
                            "utterance": {"EN": "What are you up to?", "TL": "Anong ginagawa mo?"},
                        },
                    ],
                }),
                encoding="utf-8",
            )

            svc = SemanticLabAuthoringService(repository=repo, core_repository=CORE_REPO)
            sharded = svc.shard_offers_to_families(
                bag_file,
                dest_dir=src_dir,
                id_overrides={
                    "question.wellbeing": ("offer.question", "wellbeing"),
                    "question.activity": ("offer.question", "activity"),
                },
                consumers=("player", "npc"),
                slots_by_id={
                    "question.wellbeing": {"person": {"type": "entity.person", "suggest": "known_people", "limit": 4}},
                },
                after_by_id={
                    "question.wellbeing": {"recommend": ["offer.question.activity"]},
                },
                write=True,
                prune_source=True,
            )
            self.assertEqual(sharded["shardCount"], 2)
            self.assertFalse(bag_file.exists())

            source_map = {
                Path(s["destPath"]): s["document"]
                for s in sharded["shards"]
            }
            compiled = compile_convo_engine_sources(source_map, allow_legacy_schema=False)
            plans = render_convo_engine_runtime_plan(compiled)
            ui_rows = render_psdl_ui_plan(compiled)
            ui_ids = [row["id"] for row in ui_rows]
            self.assertEqual(ui_ids, ["question.wellbeing", "question.activity"])
            wellbeing_plan = next(p for p in plans if p["id"] == "offer.question.wellbeing")
            self.assertIn("slots", wellbeing_plan["exchangeFamily"])
            self.assertEqual(wellbeing_plan["exchangeFamily"]["after"]["recommend"], ["offer.question.activity"])
            self.assertEqual(wellbeing_plan["exchangeFamily"]["affordance"]["consumers"], ["player", "npc"])

    def test_convo_engine_lua_affordance_smoke(self) -> None:
        lua = shutil.which("lua") or shutil.which("luajit")
        if lua is None:
            self.skipTest("lua interpreter not installed")
        proc = subprocess.run(
            [lua, str(CORE_REPO / "tests/convo_engine_s6m5_affordance_smoke.lua")],
            cwd=CORE_REPO,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, msg=proc.stdout + proc.stderr)


if __name__ == "__main__":
    unittest.main()
