"""G5 tests: Complete lifecycle regression matrix and two-pass determinism closure."""

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
    validate_generation_recipe,
)
from tools.semantic_harness.codebuilder.reconcile import (
    reconcile_apply,
    reconcile_check,
)
from tools.semantic_harness.tests.test_convo_engine_build_planner import (
    _build_three_repo_fixture,
    _sample_family,
    _write_json,
)
from tools.semantic_harness.tests.test_reconcile_apply import _sample_ui_family


class SemanticGenerationDeterminismLifecycleTests(unittest.TestCase):
    def test_source_rename_retires_old_path_and_creates_new_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            old_src = (
                repos["hoomans"]
                / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/former_topic/pnc_alpha.json"
            )
            _write_json(
                old_src,
                _sample_family(owner="ProjectHoomans", namespace="former_topic", family_id="pnc_alpha"),
            )
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            old_out = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/FormerTopic.lua"
            )
            new_out = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/RenamedTopic.lua"
            )
            self.assertTrue(old_out.is_file())
            self.assertFalse(new_out.exists())

            # Rename canonical source domain/file
            old_src.unlink()
            new_src = (
                repos["hoomans"]
                / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/renamed_topic/pnc_beta.json"
            )
            _write_json(
                new_src,
                _sample_family(owner="ProjectHoomans", namespace="renamed_topic", family_id="pnc_beta"),
            )

            check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(check["clean"])
            h_rep = check["owners"]["ProjectHoomans"]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/FormerTopic.lua",
                [item["path"] for item in h_rep["stale"]],
            )
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/RenamedTopic.lua",
                [item["path"] for item in h_rep["missing"]],
            )

            applied = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(applied["clean"])
            self.assertFalse(old_out.exists())
            self.assertTrue(new_out.is_file())

    def test_owner_migration_hoomans_to_core_and_to_dtcommon_removes_old_owner_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            hoomans_src = (
                repos["hoomans"]
                / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/migrating_topic/shared_fam.json"
            )
            _write_json(
                hoomans_src,
                _sample_family(
                    owner="ProjectHoomans",
                    namespace="migrating_topic",
                    family_id="shared_fam",
                ),
            )
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            hoomans_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/MigratingTopic.lua"
            )
            core_lua = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Dialogue/MigratingTopic.lua"
            )
            dt_lua = (
                repos["dt"]
                / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Dialogue/MigratingTopic.lua"
            )
            self.assertTrue(hoomans_lua.is_file())
            self.assertFalse(core_lua.exists())
            self.assertFalse(dt_lua.exists())

            # Step 1: Migrate ProjectHoomans -> PsychopatzCore
            hoomans_src.unlink()
            core_src = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/migrating_topic/shared_fam.json"
            )
            _write_json(
                core_src,
                _sample_family(
                    owner="PsychopatzCore",
                    namespace="migrating_topic",
                    family_id="shared_fam",
                ),
            )
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(hoomans_lua.exists())
            self.assertTrue(core_lua.is_file())
            self.assertFalse(dt_lua.exists())

            # Step 2: Migrate PsychopatzCore -> DTCommon
            core_src.unlink()
            dt_src = (
                repos["dt"]
                / "tools/providers/dt/codebuilder/sources/conversation/dialogue/migrating_topic/shared_fam.json"
            )
            _write_json(
                dt_src,
                _sample_family(
                    owner="DTCommon",
                    namespace="migrating_topic",
                    family_id="shared_fam",
                ),
            )
            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(hoomans_lua.exists())
            self.assertFalse(core_lua.exists())
            self.assertTrue(dt_lua.is_file())

    def test_obsolete_translation_domain_and_conversation_text_are_pruned(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            # Add a family that emits a Conversation/Text catalog via metadata.textTarget
            text_src = (
                repos["hoomans"]
                / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/pnc_text_target.json"
            )
            doc = _sample_family(
                owner="ProjectHoomans",
                namespace="social",
                family_id="pnc_text_target",
            )
            doc["metadata"] = {
                "textTarget": "convo/social/custom_branch",
                "textRows": [
                    {
                        "key": "custom.greeting",
                        "text": {"EN": "Hello branch.", "TL": "Kumusta sangay."},
                    }
                ],
            }
            _write_json(text_src, doc)

            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            text_out_en = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/convo/social/custom_branch.json"
            )
            self.assertTrue(text_out_en.is_file())

            # Also simulate a previously owned translation domain file tracked in the receipt
            obsolete_domain_rel = (
                "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/ObsoleteDomain.json"
            )
            obsolete_domain_path = repos["hoomans"] / obsolete_domain_rel
            _write_json(obsolete_domain_path, {"old.domain.key": "Old value"})
            receipt_file = receipt_dir / "ProjectHoomans.json"
            receipt_data = json.loads(receipt_file.read_text(encoding="utf-8"))
            receipt_data["ownedFiles"].append(obsolete_domain_rel)
            _write_json(receipt_file, receipt_data)

            # Remove the textTarget source
            text_src.unlink()

            check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(check["clean"])
            stale_paths = [item["path"] for item in check["owners"]["ProjectHoomans"]["stale"]]
            self.assertIn(
                "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/convo/social/custom_branch.json",
                stale_paths,
            )
            self.assertIn(obsolete_domain_rel, stale_paths)

            applied = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(applied["clean"])
            self.assertFalse(text_out_en.exists())
            self.assertFalse(obsolete_domain_path.exists())

    def test_retired_path_reintroduction_fails_check_and_apply_cleans_only_proven_owned(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )

            # Reintroduce a retired legacy text directory from the default recipe (e.g. Conversation/Text/psdl)
            reintroduced = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Text/psdl/legacy.json"
            )
            _write_json(reintroduced, {"legacy.apology": "Sorry"})

            # Also reintroduce a retired legacy root with a generated Lua file
            retired_root_lua = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation/Old.lua"
            )
            retired_root_lua.parent.mkdir(parents=True, exist_ok=True)
            retired_root_lua.write_text("-- Generated; do not edit by hand.\nreturn {}\n", encoding="utf-8")

            check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertFalse(check["clean"])
            self.assertGreaterEqual(check["counts"]["retired_present"], 2)

            applied = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(applied["clean"])
            self.assertFalse(reintroduced.exists())
            self.assertFalse(retired_root_lua.exists())

            second_check = reconcile_check(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(second_check["clean"])

    def test_unknown_unowned_file_is_never_deleted_and_causes_strict_closure_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            unknown_file = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/CustomHandWritten.lua"
            )
            unknown_bytes = b"-- Hand-written custom module not in recipe\nreturn { custom = 1 }\n"
            unknown_file.parent.mkdir(parents=True, exist_ok=True)
            unknown_file.write_bytes(unknown_bytes)

            with self.assertRaisesRegex(CompileError, "Post-reconciliation closure check failed"):
                reconcile_apply(
                    repos["hoomans"],
                    core_repository=repos["core"],
                    hoomans_repository=repos["hoomans"],
                    dynamic_trading_repository=repos["dt"],
                    receipt_root=receipt_dir,
                )

            # Unknown file must never be deleted
            self.assertTrue(unknown_file.is_file())
            self.assertEqual(unknown_file.read_bytes(), unknown_bytes)

    def test_active_hash_suffixed_shard_is_preserved_and_two_consecutive_applies_are_noop(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repos = _build_three_repo_fixture(base)
            receipt_dir = base / "receipts"

            # Add 20 families in one domain so ConvoEngine chunking (>16 records) emits a hash-suffixed shard
            for idx in range(20):
                fam_id = f"item_{idx + 1:02d}"
                src = (
                    repos["hoomans"]
                    / f"tools/providers/pnc/codebuilder/sources/conversation/dialogue/sharded_domain/{fam_id}.json"
                )
                _write_json(
                    src,
                    _sample_family(
                        owner="ProjectHoomans",
                        namespace="sharded_domain",
                        family_id=fam_id,
                    ),
                )

            pass1 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(pass1["clean"])
            dialogue_dir = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue"
            )
            split_shards = sorted((dialogue_dir / "ShardedDomain").glob("*.lua"))
            self.assertEqual(len(split_shards), 2)
            self.assertTrue(all(p.is_file() for p in split_shards))

            # Snapshot all file contents and mtimes after pass 1
            snapshot_pass1 = {
                (name, p.relative_to(root).as_posix()): (p.read_bytes(), p.stat().st_mtime_ns)
                for name, root in repos.items()
                for p in sorted(root.rglob("*"))
                if p.is_file()
            }

            # Run a second consecutive apply pass
            pass2 = reconcile_apply(
                repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
                receipt_root=receipt_dir,
            )
            self.assertTrue(pass2["clean"])
            self.assertEqual(pass2["prunedFiles"], [])
            self.assertEqual(pass2["prunedKeys"], [])
            self.assertEqual(pass2["writtenFiles"], [])
            self.assertTrue(all(p.is_file() for p in split_shards))

            snapshot_pass2 = {
                (name, p.relative_to(root).as_posix()): (p.read_bytes(), p.stat().st_mtime_ns)
                for name, root in repos.items()
                for p in sorted(root.rglob("*"))
                if p.is_file()
            }
            self.assertEqual(snapshot_pass1, snapshot_pass2)

    def test_g6_agent_workflow_and_cli_discoverability(self) -> None:
        import subprocess
        from tools.semantic_harness.codebuilder.generation_recipe import load_generation_recipe

        recipe = load_generation_recipe(DEFAULT_RECIPE_PATH)
        # 1. Recipe exposes canonical check and apply CLI invocations
        self.assertIn("reconcile.py", recipe.canonical_cli.get("check", ""))
        self.assertIn("--check", recipe.canonical_cli.get("check", ""))
        self.assertIn("reconcile.py", recipe.canonical_cli.get("apply", ""))
        self.assertIn("--apply", recipe.canonical_cli.get("apply", ""))

        # 2. CLI --help documents canonical sources and check/apply commands
        proc = subprocess.run(
            [sys.executable, "tools/semantic_harness/codebuilder/reconcile.py", "--help"],
            cwd=str(CORE_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertIn("--check", proc.stdout)
        self.assertIn("--apply", proc.stdout)
        self.assertIn("sources/conversation", proc.stdout)
        self.assertIn("generation_recipe.json", proc.stdout)

        # 3. Root AGENTS.md and codebuilder/README.md document the canonical workflow
        core_agents = (CORE_ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("Semantic CodeBuilder generated artifacts", core_agents)
        self.assertIn("generation_recipe.json", core_agents)
        readme = (CORE_ROOT / "tools/semantic_harness/codebuilder/README.md").read_text(encoding="utf-8")
        self.assertIn("reconcile.py", readme)
        self.assertIn("--check", readme)
        self.assertIn("--apply", readme)


if __name__ == "__main__":
    unittest.main()
