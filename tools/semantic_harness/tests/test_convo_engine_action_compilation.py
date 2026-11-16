from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder import CompileError
from tools.semantic_harness.codebuilder.psdl_compiler import (
    compile_convo_engine_document,
    render_convo_engine_runtime_plan,
)
from tools.semantic_harness.codebuilder.semantic_dialogue_ir import validate_context_path


ACTION_CONTRACTS = {
    "pnc.companion.camp": {
        "mode": "request_response",
        "capability": "companion.camp",
        "inputs": {
            "target": {"type": "entity.location", "required": True, "source": "target"},
            "scope": {"type": "string", "required": False},
        },
        "result": {
            "site": {"type": "entity.location"},
        },
    },
    "core.ping": {
        "mode": "sync",
        "inputs": {},
    },
}


class ConvoEngineActionCompilationTests(unittest.TestCase):
    def test_result_root_is_public_while_private_result_paths_fail_closed(self) -> None:
        self.assertEqual(validate_context_path("result.outcome"), "result.outcome")
        self.assertEqual(validate_context_path("result.reasonClass"), "result.reasonClass")
        self.assertEqual(validate_context_path("result.data.site.label"), "result.data.site.label")
        for bad in ("result.private.raw", "result.secretToken", "result.lua"):
            with self.assertRaises(CompileError):
                validate_context_path(bad)

    def test_compile_and_project_execute_bindings_and_result_predicates(self) -> None:
        doc = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "namespace": "command",
            "id": "camp",
            "owner": "ProjectHoomans",
            "slots": {
                "camp_site": {"type": "entity.location", "required": True},
            },
            "bindings": {
                "camp.locationPhrase": {
                    "resolver": "pnc.camp.location_phrase",
                    "from": "result.data.site",
                    "type": "entity.location",
                }
            },
            "affordance": {
                "label": "Camp {slot.camp_site.label}",
                "consumers": ["player"],
            },
            "say": "Let's camp here.",
            "execute": {
                "use": "pnc.companion.camp",
                "with": {
                    "target": "$slot.camp_site",
                    "scope": "single",
                },
                "mode": "request_response",
            },
            "reply": {
                "queued": {"say": "I'll head {camp.locationPhrase} and set up camp."},
                "rejected_range": {
                    "when": {"path": "result.reasonClass", "op": "eq", "value": "out_of_range"},
                    "say": "That camp location is too far away.",
                },
                "rejected": {"say": "I can't set up camp there right now."},
                "completed": {"say": "We're set up {camp.locationPhrase}."},
            },
        }
        compiled = compile_convo_engine_document(doc, action_contracts=ACTION_CONTRACTS)
        plans = render_convo_engine_runtime_plan(compiled)
        self.assertEqual(len(plans), 1)
        family = plans[0]["exchangeFamily"]
        self.assertEqual(family["execute"]["use"], "pnc.companion.camp")
        self.assertEqual(family["execute"]["mode"], "request_response")
        self.assertEqual(family["execute"]["with"]["target"], "$slot.camp_site")
        self.assertIn("camp.locationPhrase", family["bindings"])
        self.assertEqual(family["bindings"]["camp.locationPhrase"]["from"], "result.data.site")
        self.assertEqual(
            family["replies"]["rejected_range"]["when"],
            {"path": "result.reasonClass", "op": "eq", "value": "out_of_range"},
        )

    def test_shorthand_execute_string_normalizes(self) -> None:
        doc = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "namespace": "core.action",
            "id": "ping",
            "owner": "PsychopatzCore",
            "say": "Check status.",
            "execute": "core.ping",
            "reply": {"completed": {"say": "All systems ready."}},
        }
        compiled = compile_convo_engine_document(doc, action_contracts=ACTION_CONTRACTS)
        family = render_convo_engine_runtime_plan(compiled)[0]["exchangeFamily"]
        self.assertEqual(family["execute"]["use"], "core.ping")
        self.assertEqual(family["execute"]["mode"], "sync")

    def test_rejects_arbitrary_lua_or_callbacks_anywhere_in_execute(self) -> None:
        bad_payloads = [
            {"use": "core.ping", "lua": "return true"},
            {"use": "core.ping", "callback": "doCamp"},
            {"use": "core.ping", "module": "Bad/Hack"},
            {"use": "core.ping", "with": {"target": "function() return 1 end"}},
            {"use": "core.ping", "with": {"fn": "hack"}},
        ]
        for bad_exec in bad_payloads:
            doc = {
                "schema": "psychopatz.convo-engine.v1",
                "kind": "dialogue",
                "namespace": "core.action",
                "id": "bad_exec",
                "owner": "PsychopatzCore",
                "say": "Run.",
                "execute": bad_exec,
                "reply": {"completed": {"say": "Done."}},
            }
            with self.assertRaises(CompileError):
                compile_convo_engine_document(doc)

    def test_validates_against_registered_contracts_and_slots(self) -> None:
        base = {
            "schema": "psychopatz.convo-engine.v1",
            "kind": "dialogue",
            "namespace": "command",
            "id": "camp_bad",
            "owner": "ProjectHoomans",
            "slots": {"camp_site": {"type": "entity.location", "required": True}},
            "say": "Camp.",
            "reply": {"queued": {"say": "Ok."}},
        }
        unknown_action = {**base, "execute": "pnc.companion.unknown"}
        with self.assertRaises(CompileError):
            compile_convo_engine_document(unknown_action, action_contracts=ACTION_CONTRACTS)

        unknown_input = {
            **base,
            "execute": {"use": "pnc.companion.camp", "with": {"secretFlag": True}},
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_document(unknown_input, action_contracts=ACTION_CONTRACTS)

        undeclared_slot = {
            **base,
            "execute": {"use": "pnc.companion.camp", "with": {"target": "$slot.missing"}},
        }
        with self.assertRaises(CompileError):
            compile_convo_engine_document(undeclared_slot, action_contracts=ACTION_CONTRACTS)


if __name__ == "__main__":
    unittest.main()
