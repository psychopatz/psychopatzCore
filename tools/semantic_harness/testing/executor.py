"""Execution coordinator for declarative semantic test cases.

Runs isolated cases through the real-Lua LuaSemanticWorker, tracks multi-turn
continuity, evaluates bounded path expectations, and records conflicts.
"""

from __future__ import annotations

import json
import time
from copy import deepcopy
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from ..runtime.scenario import DEFAULT_SCENARIO, merge
from ..runtime.worker import LuaSemanticWorker
from .comparator import AssertionFailure, evaluate_expectations
from .loader import SemanticCase
from .operations import execute_operation, get_operation_spec
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

    worker: Any | None = None
    pending_languages: list[str] = []
    runtime_lang = case.scenario.get("runtime", {}).get("language")
    if runtime_lang:
        pending_languages.append(str(runtime_lang))

    def _get_worker() -> Any:
        nonlocal worker
        if worker is None:
            worker = worker_factory(scenario, **worker_kwargs)
            worker.__enter__()
            for lang in pending_languages:
                worker.set_language(lang)
            pending_languages.clear()
        return worker

    compiler_context = {
        "core_repository": worker_kwargs.get("core_repository"),
        "repository": worker_kwargs.get("repository"),
        "config": worker_kwargs.get("config"),
    }

    try:
        for index, turn_spec in enumerate(case.turns):
            turn_start = time.monotonic()

            # Turn-level language override
            if "language" in turn_spec:
                if worker is not None:
                    worker.set_language(turn_spec["language"])
                else:
                    pending_languages.append(str(turn_spec["language"]))

            input_text = turn_spec.get("text") or turn_spec.get("input")
            action_kind = turn_spec.get("action")
            suggestion_frame = turn_spec.get("suggestionClick")
            root_choice = turn_spec.get("rootChoice")

            if root_choice:
                active_worker = _get_worker()
                active_worker.open_conversation()
                view = active_worker.conversation_projection()
                choice_rows = ((view.get("presentation") or {}).get("responseChannel") or {}).get("rows") or []
                candidate_id = "conversation.root:menu:" + str(root_choice)
                matched = [
                    row for row in choice_rows if isinstance(row, dict)
                    and row.get("id") == candidate_id
                ]
                if len(matched) != 1:
                    raise ValueError(f"conversation root choice '{root_choice}' unavailable")
                record = active_worker.suggestion_click(matched[0]["frame"])
            elif suggestion_frame:
                record = _get_worker().suggestion_click(suggestion_frame)
            elif action_kind is not None:
                spec = get_operation_spec(action_kind)
                if spec.authority == "compiler":
                    record = execute_operation(action_kind, compiler_context, turn_spec)
                else:
                    record = execute_operation(action_kind, _get_worker(), turn_spec)
            elif input_text is not None:
                record = _get_worker().input(input_text)
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
    finally:
        if worker is not None:
            worker.__exit__(None, None, None)


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


@dataclass(frozen=True)
class BatchExecutionResult:
    results: tuple[CaseResult, ...]
    completed_ids: tuple[str, ...]
    skipped_ids: tuple[str, ...]
    cancelled: bool = False
    passed_count: int = 0
    failed_count: int = 0


def execute_cases_batch(
    cases: list[SemanticCase],
    *,
    batch_size: int = 32,
    state_file: Path | None = None,
    cancel_check: Callable[[], bool] | None = None,
    progress_callback: Callable[[CaseResult, int, int], None] | None = None,
    worker_factory: Callable[[dict[str, Any]], LuaSemanticWorker] = LuaSemanticWorker,
    fail_fast: bool = False,
    **worker_kwargs: Any,
) -> BatchExecutionResult:
    """Execute fixture cases in bounded batches with optional cancel and resume state."""
    completed_map: dict[str, bool] = {}
    if state_file is not None and state_file.is_file():
        saved = json.loads(state_file.read_text(encoding="utf-8"))
        if isinstance(saved, dict) and isinstance(saved.get("completed"), dict):
            completed_map = {
                str(k): bool(v) for k, v in saved["completed"].items()
            }

    results: list[CaseResult] = []
    skipped_ids: list[str] = []
    cancelled = False
    total = len(cases)
    effective_batch = max(1, int(batch_size))

    for offset in range(0, total, effective_batch):
        chunk = cases[offset : offset + effective_batch]
        for idx, case in enumerate(chunk):
            if cancel_check is not None and cancel_check():
                cancelled = True
                break
            if case.case_id in completed_map:
                skipped_ids.append(case.case_id)
                continue
            res = execute_case(case, worker_factory=worker_factory, **worker_kwargs)
            results.append(res)
            completed_map[case.case_id] = res.passed
            if state_file is not None:
                state_file.parent.mkdir(parents=True, exist_ok=True)
                state_file.write_text(
                    json.dumps(
                        {
                            "schema": "semantic.fixture-batch.v1",
                            "completed": completed_map,
                        },
                        indent=2,
                    ),
                    encoding="utf-8",
                )
            if progress_callback is not None:
                progress_callback(res, offset + idx + 1, total)
            if fail_fast and not res.passed:
                break
        if cancelled or (fail_fast and any(not r.passed for r in results)):
            break

    passed_count = sum(1 for ok in completed_map.values() if ok)
    failed_count = sum(1 for ok in completed_map.values() if not ok)
    return BatchExecutionResult(
        results=tuple(results),
        completed_ids=tuple(completed_map.keys()),
        skipped_ids=tuple(skipped_ids),
        cancelled=cancelled,
        passed_count=passed_count,
        failed_count=failed_count,
    )
