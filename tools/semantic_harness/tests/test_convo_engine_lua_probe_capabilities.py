"""Focused tests for S9H3 Production Lua ConvoProbe & capability negotiation."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.convo_probe import (
    CONVO_TRACE_SCHEMA,
    ConvoProbe,
    ConvoProbeUnavailableError,
)
from tools.semantic_harness.codebuilder.convo_engine_compiler import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.workspace_catalog import WorkspaceCatalog
from tools.semantic_harness.tests.convo_engine_test_support import (
    _setup_three_repo_workspace,
    _write_json,
)


class _DummyNoProbeWorker:
    def capabilities(self) -> dict:
        return {"ok": True, "capabilities": ["PING", "CAPABILITIES"]}

    def _request(self, command: str, payload: dict | None = None) -> dict:
        raise AssertionError(f"Should not call {command} on incapable worker")


class ConvoEngineLuaProbeCapabilityTests(unittest.TestCase):
    def test_convo_probe_executes_all_lua_operations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            try:
                probe = service.convo_probe
                desc = probe.describe()
                self.assertEqual(desc["schema"], CONVO_TRACE_SCHEMA)
                self.assertIn("simulate_exchange", desc["ops"])

                pred = probe.evaluate_predicate(
                    {
                        "all": [
                            {"path": "actor.hostile", "op": "falsy"},
                            {"path": "actor.tags", "op": "contains_all", "values": ["medic", "trusted"]},
                            {"path": "actor.mood", "op": "not_in", "values": ["panicked", "enraged"]},
                        ]
                    },
                    {"actor": {"hostile": False, "mood": "calm", "tags": ["trusted", "medic"]}},
                )
                self.assertTrue(pred["allowed"], pred)

                family_doc = {
                    "schema": CONVO_ENGINE_SCHEMA,
                    "kind": "dialogue",
                    "owner": "PsychopatzCore",
                    "namespace": "social",
                    "id": "probe_exchange",
                    "participants": {"speaker": ["player", "npc"], "addressee": ["npc"]},
                    "invoke": {"intent": "ASK_ASSIST"},
                    "affordance": {
                        "label": {"EN": ["Ask {target} for help"]},
                        "consumers": ["player", "npc"],
                        "priority": 5,
                        "utility": {"helpful": 3},
                    },
                    "say": {"EN": ["Could you lend a hand, {target}?"]},
                    "reply": {
                        "accepted": {"say": {"EN": ["On my way, {speaker}."]}},
                        "rejected": {"say": {"EN": ["Not right now."]}},
                    },
                }
                val = service.validate_convo_engine_document(
                    family_doc,
                    source_path=repos["core"] / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/probe_exchange.json",
                )
                self.assertTrue(val["ok"], val)
                plan = val["runtimePlan"][0]

                btn = probe.render_role_text(plan, "button_label", {"speaker": "Alex", "target": "Sam"})
                self.assertEqual(btn["text"], "Ask Sam for help")
                spoken = probe.render_role_text(plan, "spoken_action", {"speaker": "Alex", "target": "Sam"})
                self.assertEqual(spoken["text"], "Could you lend a hand, Sam?")

                score = probe.score_affordance(plan, {"utility": {"helpful": 2}})
                self.assertEqual(score["score"], 11)

                collected = probe.collect_affordances(
                    [plan],
                    consumer="npc",
                    context={"speaker": "Alex", "target": "Sam", "utility": {"helpful": 2}},
                )
                self.assertEqual(collected["count"], 1)

                npc_pick = probe.select_npc_affordance(
                    [plan],
                    context={"speaker": "Alex", "target": "Sam", "utility": {"helpful": 2}},
                )
                self.assertEqual(npc_pick["selected"]["familyID"], "social.probe_exchange")

                rep = probe.select_reply(
                    plan,
                    context={"speaker": "Alex", "target": "Sam"},
                    options={"outcome": "accepted"},
                )
                self.assertTrue(rep["ok"], rep)
                self.assertEqual(rep["reply"]["text"], "On my way, Alex.")

                projected = probe.project_action_result(
                    {"id": "custom.test.op", "mode": "sync", "resultSchema": {"item": {"type": "string"}}},
                    {"status": "completed", "data": {"item": "Bandage"}, "secretToken": "hide-me"},
                )
                self.assertEqual(projected["result"]["outcome"], "completed")
                self.assertEqual(projected["result"]["data"], {"item": "Bandage"})
                self.assertNotIn("secretToken", projected["result"]["data"])

                after = probe.resolve_after(plan, outcome="accepted", context={})
                self.assertEqual(after["after"]["mode"], "none")
            finally:
                service.close()

    def test_convo_probe_fails_explicitly_without_capability_or_worker(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            ws = WorkspaceCatalog.discover(repos["core"], core_repository=repos["core"])

            probe_no_cap = ConvoProbe(ws, worker=_DummyNoProbeWorker())
            with self.assertRaises(ConvoProbeUnavailableError):
                probe_no_cap.evaluate_predicate({"path": "actor.ok", "op": "truthy"}, {"actor": {"ok": True}})

            probe_missing_script = ConvoProbe(ws, worker_script=Path(tmp) / "missing_worker.lua")
            with self.assertRaises(ConvoProbeUnavailableError):
                probe_missing_script.describe()

    def test_provider_manifest_action_contracts_discovered_without_core_hardcoding(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            provider_file = repos["core"] / "tools/semantic_harness/provider.json"
            doc = json.loads(provider_file.read_text(encoding="utf-8"))
            doc["actionContracts"] = [
                {
                    "id": "custom.medical.treat",
                    "mode": "sync",
                    "capability": "medical.treat",
                    "inputs": {"target": "entity.person"},
                }
            ]
            _write_json(provider_file, doc)

            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            try:
                contracts = service.list_convo_engine_action_contracts()
                ids = {c["id"] for c in contracts}
                self.assertIn("custom.medical.treat", ids)
                self.assertNotIn("pnc.companion.camp", ids)
            finally:
                service.close()


if __name__ == "__main__":
    unittest.main()
