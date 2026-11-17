"""S11A7 tests: dependency index, required-fact projection, invalidation, and incremental cache."""

from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.portable_runtime import compile_portable_plan
from tools.semantic_harness.codebuilder.psdl_compiler import compile_convo_engine_document
from tools.semantic_harness.codebuilder.s11_dependency_index import (
    DEPENDENCY_INDEX_SCHEMA,
    IncrementalAnalysisCache,
    build_dependency_index,
    families_invalidated_by,
    project_required_facts,
)
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import CONVO_ENGINE_SCHEMA

CORE_ROOT = Path(__file__).resolve().parents[3]


class S11OptimizationTests(unittest.TestCase):
    def _sample_plan(self) -> dict:
        compiled = compile_convo_engine_document(
            {
                "schema": CONVO_ENGINE_SCHEMA,
                "owner": "PsychopatzCore",
                "records": [
                    {
                        "kind": "dialogue",
                        "namespace": "test",
                        "id": "alpha",
                        "when": {"path": "speaker.known", "op": "==", "value": True},
                        "statePolicy": [
                            {
                                "id": "already_following",
                                "when": {"path": "addressee.following", "op": "==", "value": True},
                                "outcome": "already_satisfied",
                                "reason": "already_following",
                                "admission": "no_op",
                            },
                            {"id": "ready", "outcome": "actionable", "reason": "ready", "admission": "dispatch"},
                        ],
                        "postconditions": ["addressee.following"],
                        "modifiers": [
                            {
                                "id": "rel_boost",
                                "domain": "relationship",
                                "field": "trust",
                                "delta": 2,
                                "retention": {"kind": "TIMED", "duration": "1d"},
                                "stacking": "refresh",
                            }
                        ],
                        "say": "Follow.",
                    },
                    {
                        "kind": "dialogue",
                        "namespace": "test",
                        "id": "beta",
                        "queries": [
                            {"id": "q_inv", "path": "inventory.actor.bandage_count", "op": "gte", "value": 1}
                        ],
                        "say": "Bandage.",
                    },
                ],
            }
        )
        return compile_portable_plan(compiled["records"], package="test")

    def test_dependency_index_projection_and_invalidation(self) -> None:
        plan = self._sample_plan()
        idx = build_dependency_index(plan)
        self.assertEqual(idx["schema"], DEPENDENCY_INDEX_SCHEMA)
        self.assertEqual(idx["stableIds"], {"test.alpha": 1, "test.beta": 2})
        self.assertEqual(idx["idToFamily"], {"1": "test.alpha", "2": "test.beta"})
        self.assertEqual(
            idx["familyRequiredFacts"]["test.alpha"],
            ["addressee.following", "speaker.known"],
        )
        self.assertEqual(idx["modifierAffectedFacts"], {"rel_boost": "relationship.trust"})

        full_ctx = {
            "speaker": {"known": True, "unrelated": "huge"},
            "addressee": {"following": False},
            "inventory": {"actor": {"bandage_count": 3}},
            "other_nxn": {"npc_99": {"trust": 10}},
        }
        projected = project_required_facts("test.alpha", idx, full_ctx)
        self.assertEqual(projected, {"speaker": {"known": True}, "addressee": {"following": False}})
        self.assertNotIn("other_nxn", projected)
        self.assertNotIn("inventory", projected)

        self.assertEqual(families_invalidated_by(["addressee.following"], idx), ["test.alpha"])
        self.assertEqual(families_invalidated_by(["inventory.actor.bandage_count"], idx), ["test.beta"])

    def test_lua_dependency_index_parity(self) -> None:
        plan = self._sample_plan()
        idx = build_dependency_index(plan)
        core_lua = CORE_ROOT / "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"
        idx_json = json.dumps(idx)
        script = f"""
        local DI = require "PsychopatzCore/ConvoEngine/S11DependencyIndex"
        local index = {{
            familyRequiredFacts = {{
                ["test.alpha"] = {{ "addressee.following", "speaker.known" }},
                ["test.beta"] = {{ "inventory.actor.bandage_count" }},
            }},
            factToFamilies = {{
                ["addressee.following"] = {{ "test.alpha" }},
                ["inventory.actor.bandage_count"] = {{ "test.beta" }},
            }},
        }}
        local ctx = {{
            speaker = {{ known = true, extra = "skip" }},
            addressee = {{ following = false }},
            other_nxn = {{ x = 1 }},
        }}
        local proj = DI.ProjectRequiredFacts("test.alpha", index, ctx)
        assert(proj.speaker.known == true and proj.speaker.extra == nil)
        assert(proj.addressee.following == false)
        assert(proj.other_nxn == nil)

        local cache = DI.CreateProjectionCache()
        cache.entries["test.alpha"] = proj
        cache.entries["test.beta"] = {{ ok = true }}
        local invCount = DI.Invalidate(cache, {{ "addressee.following" }}, index)
        assert(invCount == 1 and cache.entries["test.alpha"] == nil and cache.entries["test.beta"] ~= nil)

        -- Safe full-rebuild fallback when index is missing
        local fb = DI.Invalidate(cache, {{ "anything" }}, nil)
        assert(fb == -1 and cache.rebuilds == 1 and cache.entries["test.beta"] == nil)
        print("LUA_OPT_OK")
        """
        proc = subprocess.run(
            ["lua", "-e", f'package.path = "{core_lua};;" .. package.path\n{script}'],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout.strip(), "LUA_OPT_OK")
        self.assertIn("test.alpha", idx["stableIds"])
        _ = idx_json

    def test_incremental_analysis_cache(self) -> None:
        plan = self._sample_plan()
        cache = IncrementalAnalysisCache()
        for fid, dlg in plan["dialogues"].items():
            cache.get_or_compute(fid, dlg, lambda k, v: {"id": k})
        self.assertEqual((cache.hits, cache.misses), (0, 2))
        for fid, dlg in plan["dialogues"].items():
            cache.get_or_compute(fid, dlg, lambda k, v: {"id": k})
        self.assertEqual((cache.hits, cache.misses), (2, 2))


if __name__ == "__main__":
    unittest.main()
