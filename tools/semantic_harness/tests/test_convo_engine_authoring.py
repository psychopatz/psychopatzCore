"""Core-owned S6M1B headless ConvoEngine create/edit/move/shard/write tests."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from tools.semantic_harness.codebuilder import CONVO_ENGINE_SCHEMA, LEGACY_PSDL_SCHEMA
from tools.semantic_harness.codebuilder.convo_engine_cli import main as cli_main
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


class ConvoEngineS6M1BAuthoringTests(unittest.TestCase):
    def test_service_create_edit_move_and_write_convo_engine_family(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            service = SemanticLabAuthoringService(
                repository=repo,
                core_repository=core_repo,
            )
            dest = repo / "sources/conversation/dialogue/social/identity/ask_name.json"

            # Effect-free create preview first.
            preview = service.create_convo_engine_family(
                {
                    "namespace": "social.identity",
                    "id": "ask_name",
                    "owner": "ProjectHoomans",
                    "invoke": {"intent": "QUESTION", "subject": "IDENTITY"},
                    "affordance": {"label": "Ask who they are"},
                    "say": "Who are you?",
                    "reply": {"named": {"say": "I'm {addressee.name}."}},
                },
                source_path=dest,
                write=False,
            )
            self.assertTrue(preview["ok"])
            self.assertTrue(preview["previewOnly"])
            self.assertTrue(preview["effectFree"])
            self.assertEqual(preview["writes"], [])
            self.assertFalse(dest.exists())

            # Write validated canonical family.
            created = service.create_convo_engine_family(
                preview["document"],
                source_path=dest,
                write=True,
            )
            self.assertTrue(created["ok"])
            self.assertEqual(created["writes"], [str(dest.resolve())])
            self.assertTrue(dest.is_file())
            written_json = json.loads(dest.read_text(encoding="utf-8"))
            self.assertEqual(written_json["schema"], CONVO_ENGINE_SCHEMA)

            # Edit with stale fingerprint fails closed without modifying disk.
            stale = service.edit_convo_engine_family(
                dest,
                {"say": {"1": "Who are you?", "2": "What's your name?"}},
                expected_source_fingerprint="stale-fp",
                write=True,
            )
            self.assertFalse(stale["ok"])
            self.assertTrue(stale["stale"])

            # Edit with matching fingerprint succeeds.
            edited = service.edit_convo_engine_family(
                dest,
                {"say": {"1": "Who are you?", "2": "What's your name?"}},
                expected_source_fingerprint=created["sourceFingerprint"],
                write=True,
            )
            self.assertTrue(edited["ok"])
            self.assertEqual(
                json.loads(dest.read_text(encoding="utf-8"))["say"],
                {"1": "Who are you?", "2": "What's your name?"},
            )

            # Dry-run move does not touch disk.
            relocated = repo / "sources/conversation/dialogue/social/contact/ask_name.json"
            dry_move = service.move_convo_engine_source(
                dest,
                relocated,
                namespace="social.contact",
                dry_run=True,
            )
            self.assertTrue(dry_move["ok"])
            self.assertTrue(dry_move["effectFree"])
            self.assertTrue(dest.is_file())
            self.assertFalse(relocated.exists())

            # Actual move relocates, re-namespaces, and removes old file.
            moved = service.move_convo_engine_source(
                dest,
                relocated,
                namespace="social.contact",
            )
            self.assertTrue(moved["ok"])
            self.assertFalse(dest.exists())
            self.assertTrue(relocated.is_file())
            self.assertEqual(
                json.loads(relocated.read_text(encoding="utf-8"))["namespace"],
                "social.contact",
            )

    def test_shard_migrates_legacy_bucket_to_canonical_single_family_files(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            service = SemanticLabAuthoringService(
                repository=repo,
                core_repository=core_repo,
            )
            legacy_bucket = repo / "psdl/dialogue/social_greetings.json"
            legacy_bucket.parent.mkdir(parents=True, exist_ok=True)
            legacy_doc = {
                "schema": LEGACY_PSDL_SCHEMA,
                "records": [
                    {
                        "kind": "dialogue",
                        "id": "semantic.social.greeting.1",
                        "owner": "ProjectHoomans",
                        "on": {"intent": "GREET"},
                        "respond": {"EN": "Hello."},
                    },
                    {
                        "kind": "dialogue",
                        "id": "semantic.social.farewell.1",
                        "owner": "ProjectHoomans",
                        "on": {"intent": "FAREWELL"},
                        "respond": {"EN": "See you around."},
                    },
                ],
            }
            legacy_bucket.write_text(json.dumps(legacy_doc), encoding="utf-8")

            plan = [
                {
                    "destPath": "sources/conversation/dialogue/social/greeting.json",
                    "sourceRecordIds": ["semantic.social.greeting.1"],
                    "family": {
                        "namespace": "social",
                        "id": "greeting",
                        "invoke": {"intent": "GREET"},
                        "affordance": {"label": "Greet"},
                        "say": "Hey there.",
                        "reply": {"warm": {"say": "Hello."}},
                    },
                },
                {
                    "destPath": "sources/conversation/dialogue/social/farewell.json",
                    "sourceRecordIds": ["semantic.social.farewell.1"],
                    "family": {
                        "namespace": "social",
                        "id": "farewell",
                        "invoke": {"intent": "FAREWELL"},
                        "affordance": {"label": "Say goodbye"},
                        "say": "Gotta run.",
                        "reply": {"acknowledged": {"say": "See you around."}},
                    },
                },
            ]

            dry = service.shard_convo_engine_source(legacy_bucket, plan, write=False)
            self.assertTrue(dry["ok"])
            self.assertTrue(dry["effectFree"])
            self.assertEqual(len(dry["plannedWrites"]), 2)
            self.assertFalse((repo / "sources/conversation/dialogue/social/greeting.json").exists())

            written = service.shard_convo_engine_source(
                legacy_bucket,
                plan,
                write=True,
                prune_source=True,
            )
            self.assertTrue(written["ok"])
            self.assertEqual(written["remainingSourceRecords"], 0)
            self.assertFalse(legacy_bucket.exists())
            greeting_path = repo / "sources/conversation/dialogue/social/greeting.json"
            farewell_path = repo / "sources/conversation/dialogue/social/farewell.json"
            self.assertTrue(greeting_path.is_file())
            self.assertTrue(farewell_path.is_file())
            self.assertEqual(
                json.loads(greeting_path.read_text(encoding="utf-8"))["schema"],
                CONVO_ENGINE_SCHEMA,
            )

    def test_write_rejects_legacy_schema_and_forbidden_folder_segments(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            service = SemanticLabAuthoringService(
                repository=repo,
                core_repository=core_repo,
            )
            bad_path = repo / "sources/conversation/dialogue/Legacy/greeting.json"
            with self.assertRaises(Exception):
                service.create_convo_engine_family(
                    {
                        "namespace": "social",
                        "id": "greeting",
                        "owner": "ProjectHoomans",
                        "say": "Hello.",
                    },
                    source_path=bad_path,
                    write=True,
                )

            old_doc_res = service.write_convo_engine_source(
                repo / "sources/conversation/dialogue/social/greeting.json",
                {
                    "schema": LEGACY_PSDL_SCHEMA,
                    "kind": "dialogue",
                    "id": "social.greeting",
                    "owner": "ProjectHoomans",
                    "on": {"intent": "GREET"},
                    "respond": {"EN": "Hello."},
                },
            )
            self.assertFalse(old_doc_res["ok"])

    def test_headless_cli_create_validate_and_write_fixture(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            spec_file = repo / "spec.json"
            out_file = repo / "sources/conversation/dialogue/social/knowledge/ask_person.json"
            spec_file.write_text(
                json.dumps({
                    "namespace": "social.knowledge",
                    "id": "ask_person",
                    "owner": "ProjectHoomans",
                    "slots": {"person": {"type": "entity.person", "required": True}},
                    "invoke": {"intent": "QUESTION", "subject": "PERSON_LOCATION", "target": "$slot.person"},
                    "affordance": {"label": "Ask about {slot.person.name}"},
                    "say": {"1": "Have you seen {slot.person.name}?", "2": "Where is {slot.person.name}?"},
                    "reply": {
                        "known": {"say": "{slot.person.name} is nearby."},
                        "unknown": {"say": "Haven't seen {slot.person.name}."},
                    },
                }),
                encoding="utf-8",
            )
            rc = cli_main([
                "create",
                "--repository", str(repo),
                "--core-repository", str(core_repo),
                "--spec", str(spec_file),
                "--output", str(out_file),
                "--write",
            ])
            self.assertEqual(rc, 0)
            self.assertTrue(out_file.is_file())

            proc = subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "tools.semantic_harness.codebuilder.convo_engine_cli",
                    "validate",
                    "--repository", str(repo),
                    "--core-repository", str(core_repo),
                    "--input", str(out_file),
                    "--strict",
                ],
                cwd=core_repo,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            payload = json.loads(proc.stdout)
            self.assertTrue(payload["ok"])
            self.assertEqual(payload["sourceSchema"], CONVO_ENGINE_SCHEMA)

    def test_migrate_bucket_accounts_all_records_and_rejects_unconsumed(self) -> None:
        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            repo = Path(tmp)
            bucket = repo / "sources/conversation/psdl/dialogue/mixed_bucket.json"
            bucket.parent.mkdir(parents=True, exist_ok=True)
            bucket.write_text(
                json.dumps({
                    "schema": "psychopatz.semantic.dialogue-language.v1",
                    "owner": "PsychopatzCore",
                    "records": [
                        {
                            "kind": "dialogue",
                            "id": "core.world_event.warn",
                            "respond": {"EN": "Careful out there."},
                        },
                        {
                            "kind": "dialogue",
                            "id": "text.response.goodbye.1",
                            "respond": {"EN": "Bye."},
                        },
                        {
                            "kind": "dialogue",
                            "id": "text.response.goodbye.2",
                            "respond": {"EN": "See ya."},
                        },
                    ],
                }),
                encoding="utf-8",
            )
            svc = SemanticLabAuthoringService(repository=repo, core_repository=core_repo)

            with self.assertRaises(CompileError):
                svc.migrate_convo_engine_bucket(
                    bucket,
                    [
                        {
                            "destPath": "sources/conversation/dialogue/world_event/warn.json",
                            "sourceRecordIds": ["core.world_event.warn"],
                        }
                    ],
                    write=False,
                )

            with self.assertRaises(CompileError):
                svc.migrate_convo_engine_bucket(
                    bucket,
                    [
                        {
                            "destPath": "sources/conversation/dialogue/world_event/warn.json",
                            "sourceRecordIds": ["core.world_event.warn"],
                            "preNormalizationLegacy": True,
                        },
                        {
                            "destPath": "sources/conversation/dialogue/goodbye/goodbye.json",
                            "sourceRecordIds": [
                                "text.response.goodbye.1",
                                "text.response.goodbye.2",
                            ],
                            "preNormalizationLegacy": True,
                        },
                    ],
                    write=False,
                )

            preview = svc.migrate_convo_engine_bucket(
                bucket,
                [
                    {
                        "destPath": "sources/conversation/dialogue/world_event/warn.json",
                        "sourceRecordIds": ["core.world_event.warn"],
                    },
                    {
                        "destPath": "sources/conversation/dialogue/goodbye/goodbye.json",
                        "sourceRecordIds": [
                            "text.response.goodbye.1",
                            "text.response.goodbye.2",
                        ],
                        "preNormalizationLegacy": True,
                    },
                ],
                write=False,
            )
            self.assertTrue(preview["ok"])
            self.assertEqual(preview["canonicalCount"], 1)
            self.assertEqual(preview["preNormalizationLegacyCount"], 1)
            self.assertTrue(bucket.is_file())

            plan_file = repo / "migration_plan.json"
            plan_file.write_text(
                json.dumps([
                    {
                        "destPath": "sources/conversation/dialogue/world_event/warn.json",
                        "sourceRecordIds": ["core.world_event.warn"],
                    },
                    {
                        "destPath": "sources/conversation/dialogue/goodbye/goodbye.json",
                        "sourceRecordIds": [
                            "text.response.goodbye.1",
                            "text.response.goodbye.2",
                        ],
                        "preNormalizationLegacy": True,
                    },
                ]),
                encoding="utf-8",
            )
            rc = cli_main([
                "migrate-bucket",
                "--repository", str(repo),
                "--core-repository", str(core_repo),
                "--source", str(bucket),
                "--plan", str(plan_file),
                "--write",
                "--prune-source",
            ])
            self.assertEqual(rc, 0)
            self.assertFalse(bucket.exists())
            warn_doc = json.loads(
                (repo / "sources/conversation/dialogue/world_event/warn.json").read_text(encoding="utf-8")
            )
            self.assertEqual(warn_doc["schema"], CONVO_ENGINE_SCHEMA)
            self.assertEqual(warn_doc["namespace"], "core.world_event")
            self.assertEqual(warn_doc["id"], "warn")

    def test_external_source_roots_with_domain_from_subdir_compiles(self) -> None:
        from tools.semantic_harness.codebuilder.conversation_manifest import load_manifest

        core_repo = Path(__file__).resolve().parents[3]
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            core = root / "core"
            adopter = root / "adopter"
            (core / "sources/conversation/dialogue/core_domain").mkdir(parents=True)
            (adopter / "sources/conversation/dialogue/trade").mkdir(parents=True)
            manifest_path = core / "sources/conversation/manifest.json"
            manifest_path.write_text(
                json.dumps({
                    "schema": "pnc.conversation.manifest.v1",
                    "registryOwner": "ProjectHoomans",
                    "defaultOwner": "PsychopatzCore",
                    "sourceProfiles": {
                        "convo.test": {
                            "owner": "PsychopatzCore",
                            "kind": "convo_engine",
                        }
                    },
                    "shards": [],
                    "sourceRoots": [
                        {
                            "path": "dialogue",
                            "kind": "convo_engine",
                            "domain": "general",
                            "order": 1,
                            "owner": "PsychopatzCore",
                            "domainFromSubdir": True,
                        }
                    ],
                    "externalShards": [],
                    "externalSourceRoots": [
                        {
                            "path": "adopters/dt/dialogue",
                            "kind": "convo_engine",
                            "domain": "general",
                            "order": 2,
                            "owner": "DynamicTrading",
                            "sourcePath": "sources/conversation/dialogue",
                            "domainFromSubdir": True,
                        }
                    ],
                }),
                encoding="utf-8",
            )
            (core / "sources/conversation/dialogue/core_domain/ping.json").write_text(
                json.dumps({"schema": CONVO_ENGINE_SCHEMA, "kind": "dialogue", "namespace": "core", "id": "ping", "say": "Ping."}),
                encoding="utf-8",
            )
            (adopter / "sources/conversation/dialogue/trade/hello.json").write_text(
                json.dumps({"schema": CONVO_ENGINE_SCHEMA, "kind": "dialogue", "namespace": "trade", "id": "hello", "say": "Trade?"}),
                encoding="utf-8",
            )
            _manifest, entries = load_manifest(
                core,
                manifest_path,
                package_repositories={
                    "PsychopatzCore": core,
                    "DynamicTrading": adopter,
                },
            )
            domains = {entry["path"]: entry["domain"] for entry in entries}
            self.assertEqual(domains["dialogue/core_domain/ping.json"], "core_domain")
            self.assertEqual(domains["adopters/dt/dialogue/trade/hello.json"], "trade")
            self.assertTrue(core_repo.is_dir())


if __name__ == "__main__":
    unittest.main()
