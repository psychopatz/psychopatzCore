"""S13D/S13E acceptance tests: single-artifact Behavior/Beat projections and compact Director index."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.convo_engine_director_audit import (
    DIRECTOR_READINESS_SCHEMA,
    audit_convo_engine_director_readiness,
)
from tools.semantic_harness.codebuilder.convo_engine_director_index import (
    FORBIDDEN_DIRECTOR_INDEX_FIELDS,
    build_director_index,
)
from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
    audit_convo_engine_workspace,
)


class ConvoEngineS13DirectorLayoutAndReadinessTests(unittest.TestCase):
    def test_director_readiness_audit_passes_with_zero_duplicates_and_callers(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("Sibling participant repositories are unavailable")
        report = audit_convo_engine_director_readiness(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
        )
        self.assertEqual(report["schema"], DIRECTOR_READINESS_SCHEMA)
        self.assertTrue(report["ok"], f"Director readiness failures: {report}")
        for key, value in report["counters"].items():
            self.assertEqual(value, 0, f"Expected counter {key} == 0, got {value}")
        for name, passed in report["readinessChecks"].items():
            self.assertTrue(passed, f"Expected S13E readiness invariant {name} to pass")
        self.assertEqual(report["stats"]["behaviorCount"], 30)
        self.assertEqual(report["stats"]["beatCount"], 3)

        integrity = audit_convo_engine_workspace(
            CORE_ROOT,
            hoomans_repository=HOOMANS_ROOT,
            dynamic_trading_repository=DT_ROOT,
            check_determinism=True,
        )
        self.assertTrue(integrity["ok"], integrity["violations"])
        self.assertEqual(integrity["stats"]["directorLayout"], report["counters"])

    def test_compact_director_index_has_sparse_hooks_and_no_semantic_bodies(self) -> None:
        pkg_repos = {
            "PsychopatzCore": CORE_ROOT,
            **({"ProjectHoomans": HOOMANS_ROOT} if HOOMANS_ROOT.is_dir() else {}),
            **({"DTCommon": DT_ROOT} if DT_ROOT.is_dir() else {}),
        }
        model = compile_conversation_sources(
            CORE_ROOT,
            package_repositories=pkg_repos,
        )
        rendered, reports = render_conversation_runtime_plan(model)
        index = build_director_index(model, reports)
        self.assertIn("HUMAN_UTTERANCE", index["byStimulus"])
        self.assertIn("social", index["byDomain"])
        self.assertIn("conflict", index["byTopic"])
        self.assertIn("behavior", index["byKind"])
        self.assertIn("beat", index["byKind"])
        self.assertTrue(index["byRequiredFact"])

        for rec_id, entry in index["entries"].items():
            self.assertFalse(
                FORBIDDEN_DIRECTOR_INDEX_FIELDS.intersection(entry.keys()),
                f"{rec_id} duplicated body field",
            )
            self.assertTrue(entry["module"].startswith(("PsychopatzCore/ConvoEngine/", "PNC/ConvoEngine/")))
            self.assertIn("roles", entry["roleSpec"])
            self.assertIn("baseRelevance", entry)

        retired_beh = "/".join(("Behaviors", "Director"))
        retired_beat = "/".join(("Beats", "Director"))
        for mod, _src in rendered:
            self.assertNotIn(retired_beh, mod)
            self.assertNotIn(retired_beat, mod)

    def test_audit_detects_retired_projection_file_and_caller(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fake_core = Path(tmp) / "psychopatzCore"
            src_root = fake_core / "tools/semantic_harness/codebuilder/sources/conversation"
            (src_root / "behavior/social/conflict").mkdir(parents=True, exist_ok=True)
            (src_root / "manifest.json").write_text(
                json.dumps({"schema": "pnc.conversation.manifest.v1", "defaultOwner": "PsychopatzCore", "shards": []}),
                encoding="utf-8",
            )
            retired_file = (
                fake_core
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine"
                / "Behaviors"
                / "Director"
                / "Social"
                / "Legacy.lua"
            )
            retired_file.parent.mkdir(parents=True, exist_ok=True)
            retired_file.write_text("-- Generated\nreturn {}\n", encoding="utf-8")

            caller_file = fake_core / "Contents/mods/PsychopatzCore/common/media/lua/shared/Leak.lua"
            caller_file.parent.mkdir(parents=True, exist_ok=True)
            retired_mod = "PsychopatzCore/ConvoEngine/" + "/".join(("Behaviors", "Director")) + "/Social/Conflict"
            caller_file.write_text(f'require "{retired_mod}"\n', encoding="utf-8")

            report = audit_convo_engine_director_readiness(fake_core)
            self.assertFalse(report["ok"])
            self.assertEqual(report["counters"]["duplicateBehaviorProjectionBodies"], 1)
            self.assertGreaterEqual(report["counters"]["obsoleteDirectorProjectionCallers"], 1)


if __name__ == "__main__":
    unittest.main()
