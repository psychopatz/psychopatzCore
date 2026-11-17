"""S11A6 tests: memory vs modifier retention, stacking/dedupe, and bounded expiry."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]


class S11LifecycleTests(unittest.TestCase):
    def _run_lua(self, script: str) -> str:
        core_lua = CORE_ROOT / "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"
        proc = subprocess.run(
            ["lua", "-e", f'package.path = "{core_lua};;" .. package.path\n{script}'],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            self.fail(f"Lua failed ({proc.returncode}):\n{proc.stderr}\n{proc.stdout}")
        return proc.stdout.strip()

    def test_memory_and_modifier_expiry_remain_independent(self) -> None:
        out = self._run_lua(
            """
            local L = require "PsychopatzCore/ConvoEngine/S11Lifecycle"
            local store = L.NewStore()

            -- Day 0: insult memory = 30d (43200m), relationship penalty = 7d (10080m)
            assert(L.RecordMemory(store, {
                closureClass = "resolved_episode",
                episodeId = "insult_episode",
                retention = { kind = "TIMED", durationMinutes = 43200 },
            }, 0))
            assert(L.ApplyModifier(store, {
                id = "insult_penalty",
                domain = "relationship",
                field = "trust",
                delta = -10,
                retention = { kind = "TIMED", durationMinutes = 10080 },
                stacking = "replace",
            }, 0, "npc_1"))

            assert(L.SumDomainField(store, "relationship", "trust", "npc_1") == -10)
            assert(store.memories["insult_episode"] ~= nil)

            -- Day 7 (10080m): penalty expires, memory remains
            local pruned7 = L.PruneExpired(store, 10080)
            assert(pruned7 == 1)
            assert(L.SumDomainField(store, "relationship", "trust", "npc_1") == 0)
            assert(store.memories["insult_episode"] ~= nil)

            -- Day 30 (43200m): memory expires
            local pruned30 = L.PruneExpired(store, 43200)
            assert(pruned30 == 1)
            assert(store.memories["insult_episode"] == nil)
            print("INDEPENDENT_OK")
            """
        )
        self.assertEqual(out, "INDEPENDENT_OK")

    def test_stacking_modes_until_and_session_cleanup(self) -> None:
        out = self._run_lua(
            """
            local L = require "PsychopatzCore/ConvoEngine/S11Lifecycle"
            local store = L.NewStore()

            -- accumulate
            L.ApplyModifier(store, { id = "m_acc", domain = "mood", field = "morale", delta = 2, retention = { kind = "TIMED", durationMinutes = 60 }, stacking = "accumulate" }, 0, "a1")
            L.ApplyModifier(store, { id = "m_acc", domain = "mood", field = "morale", delta = 3, retention = { kind = "TIMED", durationMinutes = 60 }, stacking = "accumulate" }, 10, "a1")
            assert(L.SumDomainField(store, "mood", "morale", "a1") == 5)

            -- stack
            L.ApplyModifier(store, { id = "m_stk", domain = "mood", field = "stress", delta = 1, retention = { kind = "SESSION" }, stacking = "stack" }, 0, "a1")
            L.ApplyModifier(store, { id = "m_stk", domain = "mood", field = "stress", delta = 1, retention = { kind = "SESSION" }, stacking = "stack" }, 5, "a1")
            assert(L.SumDomainField(store, "mood", "stress", "a1") == 2)

            -- ignore
            L.ApplyModifier(store, { id = "m_ign", domain = "relationship", field = "respect", delta = 4, retention = { kind = "PERMANENT" }, stacking = "ignore" }, 0, "a1")
            L.ApplyModifier(store, { id = "m_ign", domain = "relationship", field = "respect", delta = 99, retention = { kind = "PERMANENT" }, stacking = "ignore" }, 1, "a1")
            assert(L.SumDomainField(store, "relationship", "respect", "a1") == 4)

            -- UNTIL fact expiry
            L.ApplyModifier(store, { id = "m_until", domain = "mood", field = "worry", delta = -5, retention = { kind = "UNTIL", untilFact = "task.done" }, stacking = "replace" }, 0, "a1")
            assert(L.SumDomainField(store, "mood", "worry", "a1") == -5)
            L.PruneExpired(store, 20, function(fact) return fact == "task.done" end)
            assert(L.SumDomainField(store, "mood", "worry", "a1") == 0)

            -- SESSION cleanup leaves PERMANENT intact
            local endRemoved = L.EndSession(store)
            assert(endRemoved == 2)
            assert(L.SumDomainField(store, "mood", "stress", "a1") == 0)
            assert(L.SumDomainField(store, "relationship", "respect", "a1") == 4)
            print("MODES_OK")
            """
        )
        self.assertEqual(out, "MODES_OK")


if __name__ == "__main__":
    unittest.main()
