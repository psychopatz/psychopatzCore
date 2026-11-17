"""S11A5 tests: Core S11DomainAdapters and ProjectHoomans direct domain adapter binding."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"


class S11DomainAdaptersTests(unittest.TestCase):
    def _run_lua(self, script: str) -> str:
        core_lua = CORE_ROOT / "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"
        hoomans_lua = HOOMANS_ROOT / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua"
        pkg_path = f"{core_lua};{hoomans_lua};;"
        proc = subprocess.run(
            ["lua", "-e", f'package.path = "{pkg_path}" .. package.path\n{script}'],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            self.fail(f"Lua failed ({proc.returncode}):\n{proc.stderr}\n{proc.stdout}")
        return proc.stdout.strip()

    def test_core_adapters_fail_closed_when_unregistered_and_delegate_when_bound(self) -> None:
        out = self._run_lua(
            """
            local Adapters = require "PsychopatzCore/ConvoEngine/S11DomainAdapters"
            Adapters.Reset()

            local effFail = Adapters.DispatchEffect({ type = "consume_item" }, {}, {})
            assert(effFail.ok == false and effFail.reason == "unregistered_effect_handler:consume_item")

            local modFail = Adapters.ApplyModifier({ domain = "relationship", id = "m1" }, {}, {})
            assert(modFail.ok == false and modFail.reason == "unregistered_domain_adapter:relationship")

            local memSkip = Adapters.RecordMemoryResidue({ closureClass = "state_transition" }, {}, {})
            assert(memSkip.ok == true and memSkip.skipped == true)

            local memFail = Adapters.RecordMemoryResidue({ closureClass = "resolved_episode", episodeId = "ep1" }, {}, {})
            assert(memFail.ok == false and memFail.reason == "unregistered_memory_adapter")

            Adapters.RegisterEffectHandler("consume_item", function(spec)
                return { ok = true, type = spec.type }
            end)
            local effOk = Adapters.DispatchEffect({ type = "consume_item" }, {}, {})
            assert(effOk.ok == true and effOk.type == "consume_item")
            print("CORE_OK")
            """
        )
        self.assertEqual(out, "CORE_OK")

    def test_hoomans_direct_adapters_bind_to_authoritative_services(self) -> None:
        out = self._run_lua(
            """
            local Adapters = require "PsychopatzCore/ConvoEngine/S11DomainAdapters"
            local PNCAdapters = require "PNC/ConvoEngine/PNC_S11DomainAdapters"
            Adapters.Reset()

            local calls = {}
            PNCAdapters.Bind({
                relationships = {
                    ApplyModifier = function(src, dst, mod)
                        calls[#calls + 1] = "rel:" .. tostring(src) .. "->" .. tostring(dst) .. ":" .. tostring(mod.id)
                        return { ok = true, applied = true }
                    end,
                },
                morale = {
                    ApplyModifier = function(dst, mod)
                        calls[#calls + 1] = "mood:" .. tostring(dst) .. ":" .. tostring(mod.id)
                        return { ok = true, applied = true }
                    end,
                },
                memory = {
                    RecordSemanticEpisode = function(closure)
                        calls[#calls + 1] = "mem:" .. tostring(closure.episodeId)
                        return { ok = true, recorded = true }
                    end,
                },
                inventory = {
                    Query = function(q)
                        calls[#calls + 1] = "inv:" .. tostring(q.path)
                        return { ok = true, value = 3 }
                    end,
                },
            })

            local roles = {
                speaker = { { id = "player", kind = "actor" } },
                addressee = { { id = "npc_1", kind = "actor" } },
            }
            assert(Adapters.ApplyModifier({ id = "rel_1", domain = "relationship", field = "trust", delta = -5, targetRole = "addressee" }, roles, {}).ok)
            assert(Adapters.ApplyModifier({ id = "mood_1", domain = "mood", field = "morale", delta = 4, targetRole = "addressee" }, roles, {}).ok)
            assert(Adapters.RecordMemoryResidue({ closureClass = "resolved_episode", episodeId = "ep_aid" }, roles, {}).ok)
            assert(Adapters.ResolveQuery({ id = "q1", path = "inventory.actor.bandage_count" }, {}).value == 3)
            assert(table.concat(calls, "|") == "rel:player->npc_1:rel_1|mood:npc_1:mood_1|mem:ep_aid|inv:inventory.actor.bandage_count")
            print("PNC_OK")
            """
        )
        self.assertEqual(out, "PNC_OK")


if __name__ == "__main__":
    unittest.main()
