"""Execution coordinator for declarative semantic test cases.

Runs isolated cases through the real-Lua LuaSemanticWorker, tracks multi-turn
continuity, evaluates bounded path expectations, and records conflicts.
"""

from __future__ import annotations

import time
from copy import deepcopy
from dataclasses import dataclass, field
from typing import Any, Callable

from ..runtime.scenario import DEFAULT_SCENARIO, merge
from ..runtime.worker import LuaSemanticWorker
from .comparator import AssertionFailure, evaluate_expectations
from .loader import SemanticCase
from .runner import ConflictLedger


@dataclass(frozen=True)
class TurnResult:
    index: int
    input_text: str | None
    observation: dict[str, Any]
    failures: tuple[AssertionFailure, ...]
    elapsed: float

    @property
    def passed(self) -> bool:
        return len(self.failures) == 0


@dataclass(frozen=True)
class CaseResult:
    case: SemanticCase
    passed: bool
    duration: float
    turns: tuple[TurnResult, ...] = ()
    conflicts: tuple[dict[str, Any], ...] = ()
    failures: tuple[AssertionFailure, ...] = ()
    error: str | None = None

    @property
    def case_id(self) -> str:
        return self.case.case_id

    @property
    def suite(self) -> str:
        return self.case.suite

    def summary(self) -> str:
        status = "PASS" if self.passed else "FAIL"
        details = ""
        if not self.passed:
            if self.error:
                details = f": {self.error}"
            elif self.failures:
                first = self.failures[0]
                details = f": {first.message} (+{len(self.failures)-1} more)" if len(self.failures) > 1 else f": {first.message}"
            elif self.conflicts:
                details = f": {len(self.conflicts)} conflict(s) detected"
        return f"{status} [{self.case.suite}] {self.case.case_id} ({self.duration:.3f}s){details}"


def execute_case(
    case: SemanticCase,
    *,
    worker_factory: Callable[[dict[str, Any]], LuaSemanticWorker] = LuaSemanticWorker,
    **worker_kwargs: Any,
) -> CaseResult:
    """Execute a single declarative semantic test case against an isolated production Lua worker."""
    started = time.monotonic()
    scenario = merge(DEFAULT_SCENARIO, case.scenario)
    turn_results: list[TurnResult] = []
    all_failures: list[AssertionFailure] = []
    ledger = ConflictLedger()

    try:
        with worker_factory(scenario, **worker_kwargs) as worker:
            # Set initial scenario language if configured
            runtime_lang = case.scenario.get("runtime", {}).get("language")
            if runtime_lang:
                worker.set_language(str(runtime_lang))

            for index, turn_spec in enumerate(case.turns):
                turn_start = time.monotonic()

                # Turn-level language override
                if "language" in turn_spec:
                    worker.set_language(turn_spec["language"])

                input_text = turn_spec.get("text") or turn_spec.get("input")
                action_kind = turn_spec.get("action")
                suggestion_frame = turn_spec.get("suggestionClick")
                root_choice = turn_spec.get("rootChoice")

                if root_choice:
                    worker.open_conversation()
                    view = worker.conversation_projection()
                    choice_rows = ((view.get("presentation") or {}).get("responseChannel") or {}).get("rows") or []
                    candidate_id = "conversation.root:menu:" + str(root_choice)
                    matched = [
                        row for row in choice_rows if isinstance(row, dict)
                        and row.get("id") == candidate_id
                    ]
                    if len(matched) != 1:
                        raise ValueError(f"conversation root choice '{root_choice}' unavailable")
                    record = worker.suggestion_click(matched[0]["frame"])
                elif suggestion_frame:
                    record = worker.suggestion_click(suggestion_frame)
                elif action_kind == "preview" and input_text:
                    record = worker.preview(input_text)
                elif input_text is not None:
                    record = worker.input(input_text)
                else:
                    raise ValueError(f"Turn {index} has unsupported action structure: {turn_spec}")

                turn_elapsed = time.monotonic() - turn_start

                # Track streaming conflicts
                ledger.add(record)

                # Evaluate expectations
                expectations = turn_spec.get("expect", {})
                failures = evaluate_expectations(record, expectations)
                if failures:
                    all_failures.extend(failures)

                obs = record.get("observation") or record.get("result") or {}
                turn_results.append(
                    TurnResult(
                        index=index,
                        input_text=input_text,
                        observation=obs,
                        failures=tuple(failures),
                        elapsed=turn_elapsed,
                    )
                )

        duration = time.monotonic() - started
        conflicts = tuple(ledger.report())
        passed = (len(all_failures) == 0 and len(conflicts) == 0)

        return CaseResult(
            case=case,
            passed=passed,
            duration=duration,
            turns=tuple(turn_results),
            conflicts=conflicts,
            failures=tuple(all_failures),
        )

    except Exception as exc:
        duration = time.monotonic() - started
        return CaseResult(
            case=case,
            passed=False,
            duration=duration,
            turns=tuple(turn_results),
            conflicts=tuple(ledger.report()),
            failures=tuple(all_failures),
            error=str(exc),
        )


def execute_cases(
    cases: list[SemanticCase],
    *,
    worker_factory: Callable[[dict[str, Any]], LuaSemanticWorker] = LuaSemanticWorker,
    fail_fast: bool = False,
    **worker_kwargs: Any,
) -> list[CaseResult]:
    """Execute a collection of semantic cases sequentially with isolated worker sessions."""
    results: list[CaseResult] = []
    for case in cases:
        result = execute_case(case, worker_factory=worker_factory, **worker_kwargs)
        results.append(result)
        if fail_fast and not result.passed:
            break
    return results
