"""Unit tests for the allowlisted typed fixture operation registry (A1)."""

from __future__ import annotations

import unittest
from typing import Any

from tools.semantic_harness.testing.comparator import evaluate_expectations
from tools.semantic_harness.testing.executor import execute_case, execute_cases_batch
from tools.semantic_harness.testing.loader import (
    SemanticCase,
    discover_domains,
    filter_cases,
)
from tools.semantic_harness.testing.operations import (
    OPERATION_REGISTRY,
    OperationValidationError,
    execute_operation,
    get_operation_spec,
    normalize_operation_result,
    validate_operation_turn,
)
from tools.semantic_harness.testing.schema import SchemaValidationError, validate_turn


class _FakeWorker:
    def __init__(self, _scenario: dict[str, Any] | None = None, **_kwargs: Any) -> None:
        self.calls: list[tuple[str, Any]] = []

    def __enter__(self) -> "_FakeWorker":
        return self

    def __exit__(self, *_args: Any) -> None:
        return None

    def set_language(self, lang: str) -> None:
        self.calls.append(("set_language", lang))

    def preview(self, text: str) -> dict[str, Any]:
        self.calls.append(("preview", text))
        return {"type": "preview", "accepted": False, "observation": {"preview": True}}

    def beat_catalog(self) -> dict[str, Any]:
        self.calls.append(("beat_catalog", None))
        return {"beatCount": 2, "behaviorCount": 3, "beats": [{"id": "beat.a"}]}

    def world_knowledge_inspect(
        self, actor_id: str | None = None, fact_id: str | None = None, max_facts: int = 32
    ) -> dict[str, Any]:
        self.calls.append(("world_knowledge_inspect", (actor_id, fact_id, max_facts)))
        return {"explanation": {"provenance": "witnessed"}}

    def world_knowledge_propagate(
        self,
        from_actor_id: str,
        to_actor_id: str,
        channel: str = "conversation",
        authorized: bool = True,
        now: float = 1000,
    ) -> dict[str, Any]:
        self.calls.append(("world_knowledge_propagate", (from_actor_id, to_actor_id)))
        return {"transferred": [{"factID": "fact.zombies"}]}

    def explain_response_selection(
        self, pool_id: str, context: dict[str, Any], salt: str = ""
    ) -> dict[str, Any]:
        self.calls.append(("explain_response_selection", (pool_id, context, salt)))
        return {"poolID": pool_id, "selected": {"key": "k1"}}

    def flow_coverage(self) -> list[dict[str, Any]]:
        self.calls.append(("flow_coverage", None))
        return [{"capability": "hoomans.camp.establish", "status": "covered"}]


class FixtureOperationRegistryTests(unittest.TestCase):
    def test_expected_runtime_operations_are_registered(self) -> None:
        required = {
            "preview",
            "beat.catalog",
            "beat.validate",
            "beat.register",
            "beat.preview",
            "behavior.validate",
            "behavior.register",
            "interaction.preview",
            "knowledge.bootstrap",
            "knowledge.metrics",
            "knowledge.inspect",
            "knowledge.propagate",
            "knowledge.discover",
            "backstory.inspect",
            "backstory.fact",
            "commitment.apply",
            "response.lookup",
            "response.list",
            "response.detail",
            "response.explain",
            "response.sample",
            "flow.catalog",
            "flow.validate",
            "flow.register",
            "flow.generate",
            "flow.coverage",
            "fact.catalog",
            "event.catalog",
        }
        self.assertTrue(required.issubset(set(OPERATION_REGISTRY)))
        self.assertTrue(get_operation_spec("beat.register").mutating)
        self.assertFalse(get_operation_spec("beat.catalog").mutating)

    def test_unknown_action_is_rejected_by_registry_and_schema(self) -> None:
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("arbitrary.python_method", {}, {})
        with self.assertRaises(SchemaValidationError):
            validate_turn({"action": "arbitrary.python_method"}, 0, "case.bad")

    def test_payload_validation_rejects_missing_or_invalid_fields(self) -> None:
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("beat.validate", {}, {})
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("knowledge.propagate", {"fromActorID": "a"}, {})
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("backstory.inspect", {"identitySeed": "not-an-int"}, {})
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("response.explain", {"context": {}}, {})
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("beat.preview", {"definition": {"id": "b1"}}, {})

    def test_normalization_and_comparator_support_dict_and_list_results(self) -> None:
        spec = get_operation_spec("flow.coverage")
        env = normalize_operation_result(spec, [{"capability": "c1"}])
        self.assertEqual(env["operation"]["id"], "flow.coverage")
        self.assertEqual(env["operation"]["status"], "ok")
        self.assertEqual(env["result"]["count"], 1)
        failures = evaluate_expectations(
            env,
            {
                "operation.status": "ok",
                "result.count": 1,
                "result.capabilityCoverage.0.capability": "c1",
            },
        )
        self.assertEqual(failures, [])

    def test_execute_case_runs_allowlisted_operations_and_preview(self) -> None:
        case = SemanticCase(
            case_id="ops.smoke",
            suite="ops",
            tags=("ops",),
            scenario={},
            turns=(
                {
                    "action": "beat.catalog",
                    "expect": {"operation.status": "ok", "result.beatCount": 2},
                },
                {
                    "action": "knowledge.inspect",
                    "payload": {"actorID": "actor:alice", "factID": "fact.zombies"},
                    "expect": {"result.explanation.provenance": "witnessed"},
                },
                {
                    "action": "knowledge.propagate",
                    "payload": {"fromActorID": "actor:alice", "toActorID": "actor:bob"},
                    "expect": {"result.transferred.0.factID": "fact.zombies"},
                },
                {
                    "action": "response.explain",
                    "payload": {"poolID": "pool.1", "context": {}},
                    "expect": {"result.selected.key": "k1"},
                },
                {
                    "action": "flow.coverage",
                    "expect": {"result.count": 1},
                },
                {
                    "action": "preview",
                    "text": "hello",
                    "expect": {"observation.preview": True},
                },
            ),
        )
        result = execute_case(case, worker_factory=_FakeWorker)
        self.assertTrue(result.passed, result.summary())

    def test_unsupported_worker_method_raises_clear_error(self) -> None:
        class _MinimalWorker:
            pass

        with self.assertRaisesRegex(RuntimeError, "does not support operation 'knowledge.bootstrap'"):
            execute_operation("knowledge.bootstrap", _MinimalWorker(), {})

    def test_compiler_probes_are_registered_and_validated(self) -> None:
        for action_id in (
            "compiler.psdl_validate",
            "compiler.psdl_inspect",
            "compiler.canonical_ir",
            "compiler.portable_plan",
            "compiler.backend_projection",
            "compiler.source_lineage",
        ):
            spec = get_operation_spec(action_id)
            self.assertEqual(spec.authority, "compiler")
            self.assertFalse(spec.mutating)
        with self.assertRaises(OperationValidationError):
            validate_operation_turn("compiler.psdl_inspect", {"recordID": "command.camp", "mode": "bad"}, {})

    def test_domain_filtering_and_batch_cancel_resume(self) -> None:
        import tempfile
        from pathlib import Path

        cases = [
            SemanticCase(
                case_id="c1",
                suite="s1",
                tags=("beats",),
                domain="beats",
                scenario={},
                turns=({"action": "beat.catalog", "expect": {"operation.status": "ok"}},),
            ),
            SemanticCase(
                case_id="c2",
                suite="s2",
                tags=("knowledge",),
                domain="knowledge",
                scenario={},
                turns=({"action": "beat.catalog", "expect": {"operation.status": "ok"}},),
            ),
        ]
        self.assertEqual(discover_domains(cases), {"beats": 1, "knowledge": 1})
        self.assertEqual([c.case_id for c in filter_cases(cases, domain="beats")], ["c1"])

        with tempfile.TemporaryDirectory() as tmp:
            state_path = Path(tmp) / "batch.json"
            calls = 0

            def _cancel_after_one() -> bool:
                return calls >= 1

            def _progress(_res: Any, _idx: int, _total: int) -> None:
                nonlocal calls
                calls += 1

            first = execute_cases_batch(
                cases,
                batch_size=1,
                state_file=state_path,
                cancel_check=_cancel_after_one,
                progress_callback=_progress,
                worker_factory=_FakeWorker,
            )
            self.assertTrue(first.cancelled)
            self.assertEqual(first.completed_ids, ("c1",))

            resumed = execute_cases_batch(
                cases,
                batch_size=1,
                state_file=state_path,
                worker_factory=_FakeWorker,
            )
            self.assertFalse(resumed.cancelled)
            self.assertEqual(resumed.skipped_ids, ("c1",))
            self.assertEqual([r.case_id for r in resumed.results], ["c2"])
            self.assertEqual(resumed.passed_count, 2)

    def test_linter_detects_global_duplicates_naming_violations_and_overlaps(self) -> None:
        import json
        import tempfile
        from pathlib import Path
        from tools.semantic_harness.testing.lint import lint_fixtures

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "dialogue").mkdir(parents=True)
            (root / "suggestions").mkdir(parents=True)
            (root / "dialogue" / "greetings.json").write_text(
                json.dumps({
                    "schema": "semantic.harness-test.v1",
                    "suite": "pnc.dialogue.greetings",
                    "domain": "dialogue",
                    "cases": [{
                        "id": "dialogue.greetings.hello",
                        "turns": [{"text": "hello", "expect": {"ir.intent": "GREET"}}],
                    }],
                }),
                encoding="utf-8",
            )
            (root / "suggestions" / "batch1_bad.json").write_text(
                json.dumps({
                    "schema": "semantic.harness-test.v1",
                    "suite": "pnc.suggestions.c0a",
                    "domain": "dialogue",
                    "cases": [{
                        "id": "suggestions.c0a.hello",
                        "turns": [{"text": "hello", "expect": {"ir.intent": "GREET"}}],
                    }],
                }),
                encoding="utf-8",
            )
            report = lint_fixtures(root)
            self.assertFalse(report["ok"])
            self.assertEqual(len(report["exact_duplicates"]), 1)
            self.assertTrue(report["naming_violations"])
            self.assertTrue(report["domain_path_mismatches"])
            self.assertEqual(len(report["stimulus_overlaps"]), 1)


if __name__ == "__main__":
    unittest.main()
