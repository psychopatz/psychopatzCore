"""Bounded Phase 6 performance evidence for the real Lua Semantic Lab worker.

This measures the Python-to-Lua worker protocol and the production semantic
router only.  It is deliberately not native Project Zomboid SP/MP evidence.
"""

from __future__ import annotations

import argparse
import json
import platform
import statistics
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

# Permit both ``python -m tools.semantic_harness.testing.performance`` and the
# direct repository-local script form without changing the worker's imports.
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


CASES: tuple[tuple[str, str], ...] = (
    ("recognized_follow", "follow me"),
    ("reviewed_wellbeing", "how are you doing"),
    ("unknown_provider_fallback", "this sentence is not authored"),
)
SERIAL_INPUTS: tuple[str, ...] = (
    "follow me",
    "how are you doing",
    "this sentence is not authored",
)


def _percentile(values: Iterable[float], percentile: float) -> float:
    ordered = sorted(float(value) for value in values)
    if not ordered:
        raise ValueError("at least one value is required")
    if not 0.0 <= percentile <= 100.0:
        raise ValueError("percentile must be between 0 and 100")
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * percentile / 100.0
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * fraction


def _json_bytes(value: Any) -> int:
    return len(
        json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode(
            "utf-8"
        )
    )


def _distribution(values: list[float]) -> dict[str, float]:
    if not values:
        raise ValueError("at least one measurement is required")
    return {
        "count": len(values),
        "min": min(values),
        "mean": statistics.fmean(values),
        "median": statistics.median(values),
        "p95": _percentile(values, 95.0),
        "p99": _percentile(values, 99.0),
        "max": max(values),
    }


def _scenario(provider_enabled: bool) -> dict[str, Any]:
    return merge(
        DEFAULT_SCENARIO,
        {
            "runtime": {
                "llmEnabled": provider_enabled,
                "providerAvailable": provider_enabled,
            }
        },
    )


def _assert_turn_contract(
    label: str, text: str, turn: dict[str, Any], provider_enabled: bool
) -> None:
    result = turn.get("result") or {}
    decision = result.get("decision") or {}
    branch = decision.get("branch")
    if label == "recognized_follow":
        expected = "COMMAND_ACCEPTED"
        if branch != expected or (result.get("ir") or {}).get("action") != "FOLLOW":
            raise AssertionError(f"{text!r} did not remain the authored follow route")
        if turn.get("llmCalls") != 0:
            raise AssertionError("recognized local command called the provider")
    elif label == "reviewed_wellbeing":
        if branch != "QUESTION_RECEIVED":
            raise AssertionError(f"{text!r} did not remain the reviewed wellbeing route")
        if turn.get("llmCalls") != 0:
            raise AssertionError("reviewed deterministic wellbeing called the provider")
    elif label == "unknown_provider_fallback":
        if branch != "ASK_CLARIFICATION":
            raise AssertionError("unknown input did not fail closed to clarification")
        if result.get("actionResult") is not None:
            raise AssertionError("unknown input produced an action result")
        if turn.get("dispatchTransport", turn.get("transport")) or turn.get("toolCalls"):
            raise AssertionError("unknown input produced an unauthorized side effect")
        expected_calls = 1 if provider_enabled else 0
        if turn.get("llmCalls") != expected_calls:
            raise AssertionError(
                f"provider call count changed: expected {expected_calls}, "
                f"got {turn.get('llmCalls')}"
            )


def _measure_case(
    worker: LuaSemanticWorker,
    label: str,
    text: str,
    provider_enabled: bool,
    samples: int,
    warmup: int,
) -> dict[str, Any]:
    elapsed_ms: list[float] = []
    context_bytes: list[float] = []
    response_bytes: list[float] = []
    provider_calls: list[int] = []
    branches: set[str] = set()
    sequences: list[int] = []
    total = warmup + samples
    for index in range(total):
        # Reset outside the timed region so each sample measures one isolated
        # production turn rather than an ever-growing transcript.
        worker.reset()
        started = time.perf_counter_ns()
        turn = worker.input(text)
        elapsed = (time.perf_counter_ns() - started) / 1_000_000.0
        _assert_turn_contract(label, text, turn, provider_enabled)
        if index < warmup:
            continue
        result = turn.get("result") or {}
        decision = result.get("decision") or {}
        state = (turn.get("contextAfter") or {}).get("state") or {}
        elapsed_ms.append(elapsed)
        context_bytes.append(_json_bytes(turn.get("contextAfter")))
        response_bytes.append(_json_bytes(turn))
        provider_calls.append(int(turn.get("llmCalls") or 0))
        branches.add(str(decision.get("branch") or ""))
        sequences.append(int(state.get("sequence") or 0))
    return {
        "providerEnabled": provider_enabled,
        "input": text,
        "branch": sorted(branches),
        "providerCalls": sorted(set(provider_calls)),
        "semanticSequences": sorted(set(sequences)),
        "turnLatencyMs": _distribution(elapsed_ms),
        "contextAfterBytes": _distribution(context_bytes),
        "turnRecordBytes": _distribution(response_bytes),
    }


def _serial_summary(
    worker: LuaSemanticWorker, provider_enabled: bool, turn_count: int
) -> dict[str, Any]:
    worker.reset()
    sequences: list[int] = []
    recent_turn_counts: list[int] = []
    recent_event_counts: list[int] = []
    timestamps: list[int] = []
    for index in range(turn_count):
        turn = worker.input(SERIAL_INPUTS[index % len(SERIAL_INPUTS)])
        state = (turn.get("contextAfter") or {}).get("state") or {}
        dialogue = (turn.get("contextAfter") or {}).get("dialogue") or {}
        sequences.append(int(state.get("sequence") or 0))
        recent_turn_counts.append(len(dialogue.get("recentTurns") or []))
        recent_event_counts.append(len(state.get("recentSemanticEvents") or []))
        event = state.get("lastEvent") or {}
        if event.get("timestamp") is not None:
            timestamps.append(int(event["timestamp"]))
    snapshot = worker.snapshot()
    if any(after <= before for before, after in zip(sequences, sequences[1:])):
        raise AssertionError("serialized worker sequence was not strictly increasing")
    if any(after < before for before, after in zip(timestamps, timestamps[1:])):
        raise AssertionError("serialized worker timestamps moved backwards")
    state = (snapshot.get("context") or {}).get("state") or {}
    max_events = int(state.get("maxEvents") or 0)
    if max_events and max(recent_event_counts, default=0) > max_events:
        raise AssertionError("semantic event history exceeded its declared bound")
    return {
        "providerEnabled": provider_enabled,
        "turns": turn_count,
        "sequenceFirst": sequences[0] if sequences else None,
        "sequenceLast": sequences[-1] if sequences else None,
        "maxRecentDialogueTurns": max(recent_turn_counts, default=0),
        "maxRecentSemanticEvents": max(recent_event_counts, default=0),
        "declaredMaxSemanticEvents": max_events or None,
        "queuedMessages": len(snapshot.get("queued") or []),
        "transcriptMessages": len(snapshot.get("transcript") or []),
        "strictlyIncreasingSequence": True,
        "nonDecreasingTimestamps": True,
    }


def run_benchmark(*, samples: int = 8, warmup: int = 2, serial_turns: int = 24) -> dict[str, Any]:
    if samples < 1:
        raise ValueError("samples must be positive")
    if warmup < 0:
        raise ValueError("warmup cannot be negative")
    if serial_turns < 1:
        raise ValueError("serial_turns must be positive")

    cases: dict[str, dict[str, Any]] = {}
    serial: list[dict[str, Any]] = []
    for provider_enabled in (False, True):
        scenario = _scenario(provider_enabled)
        with LuaSemanticWorker(scenario) as worker:
            for label, text in CASES:
                cases[f"{label}:provider_{'enabled' if provider_enabled else 'disabled'}"] = _measure_case(
                    worker,
                    label,
                    text,
                    provider_enabled,
                    samples,
                    warmup,
                )
            serial.append(_serial_summary(worker, provider_enabled, serial_turns))

    comparisons: dict[str, dict[str, Any]] = {}
    for label, _text in CASES:
        disabled = cases[f"{label}:provider_disabled"]["turnLatencyMs"]
        enabled = cases[f"{label}:provider_enabled"]["turnLatencyMs"]
        disabled_median = float(disabled["median"])
        enabled_median = float(enabled["median"])
        delta = enabled_median - disabled_median
        comparisons[label] = {
            "providerDisabledMedianMs": disabled_median,
            "providerEnabledMedianMs": enabled_median,
            "medianDeltaMs": delta,
            "medianDeltaPercent": (delta / disabled_median * 100.0)
            if disabled_median > 0.0
            else None,
            "providerDisabledP95Ms": disabled["p95"],
            "providerEnabledP95Ms": enabled["p95"],
        }

    return {
        "schemaVersion": 1,
        "kind": "contextual-semantic-phase6-performance",
        "scope": "semantic_lab_real_lua_worker_non_native",
        "nativeAcceptance": False,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "python": platform.python_version(),
        "samples": samples,
        "warmup": warmup,
        "serialTurns": serial_turns,
        "cases": cases,
        "providerComparison": comparisons,
        "serializedWorker": serial,
        "limitations": [
            "Measures the real production Lua semantic router through the Semantic Lab worker protocol.",
            "Does not measure Project Zomboid engine tick cost, native queue scheduling, SP, MP, or server authority.",
            "The enabled provider path is the existing deterministic rejection adapter, not a live provider response.",
        ],
    }


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=int, default=8)
    parser.add_argument("--warmup", type=int, default=2)
    parser.add_argument("--serial-turns", type=int, default=24)
    parser.add_argument("--output", type=Path)
    options = parser.parse_args(arguments)
    report = run_benchmark(
        samples=options.samples,
        warmup=options.warmup,
        serial_turns=options.serial_turns,
    )
    encoded = json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if options.output:
        options.output.parent.mkdir(parents=True, exist_ok=True)
        options.output.write_text(encoded, encoding="utf-8")
    sys.stdout.write(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
