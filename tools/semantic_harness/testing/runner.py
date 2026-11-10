"""Reusable case runner and bounded conflict ledger for semantic tests."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from ..runtime.scenario import DEFAULT_SCENARIO, load_scenario, merge
from ..runtime.worker import LuaSemanticWorker

MAX_TRACKED_EVENT_IDS = 4096
MAX_REPORTED_CONFLICTS = 256
MAX_EVENT_ID_LENGTH = 256


@dataclass(frozen=True)
class HarnessCase:
    case_id: str
    scenario: dict[str, Any]
    inputs: tuple[str, ...]
    tags: tuple[str, ...] = ()

    @classmethod
    def from_mapping(cls, value: dict[str, Any], *, default_id: str = "case") -> "HarnessCase":
        inputs = value.get("inputs", [])
        if not isinstance(inputs, list) or not all(isinstance(item, str) for item in inputs):
            raise ValueError("case.inputs must be a list of strings")
        tags = value.get("tags", [])
        if not isinstance(tags, list) or not all(isinstance(item, str) for item in tags):
            raise ValueError("case.tags must be a list of strings")
        scenario = value.get("scenario", {})
        if not isinstance(scenario, dict):
            raise ValueError("case.scenario must be an object")
        return cls(
            case_id=str(value.get("id") or default_id),
            scenario=merge(DEFAULT_SCENARIO, scenario),
            inputs=tuple(inputs),
            tags=tuple(tags),
        )


def load_case(path: Path) -> HarnessCase:
    import json

    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("case root must be an object")
    return HarnessCase.from_mapping(value, default_id=path.stem)


class ConflictLedger:
    """Incrementally detect conflicts while bounding retained audit state."""

    def __init__(self) -> None:
        self._previous_sequence = 0
        self._event_ids: dict[str, int] = {}
        self._conflicts: list[dict[str, Any]] = []
        self._truncation_reasons: set[str] = set()
        self._turn_index = 0

    def _record(self, conflict: dict[str, Any]) -> None:
        if len(self._conflicts) < MAX_REPORTED_CONFLICTS:
            self._conflicts.append(conflict)
        else:
            self._truncation_reasons.add("conflict_limit")

    def add(self, turn: dict[str, Any]) -> None:
        self._turn_index += 1
        index = self._turn_index
        if not isinstance(turn, dict):
            self._record({"kind": "invalid_turn_record", "turnIndex": index})
            return

        result = turn.get("result")
        is_preview = turn.get("type") == "preview"
        sequence = result.get("sequence") if isinstance(result, dict) else None
        if isinstance(sequence, int) and sequence > 0 and not is_preview:
            if sequence <= self._previous_sequence:
                self._record(
                    {
                        "kind": "turn_sequence_regression",
                        "turnIndex": index,
                        "previous": self._previous_sequence,
                        "current": sequence,
                    }
                )
            self._previous_sequence = max(self._previous_sequence, sequence)

        relationship_before = turn.get("relationshipBefore", {})
        relationship_after = turn.get("relationshipAfter", {})
        before_revision = relationship_before.get("revision") if isinstance(relationship_before, dict) else None
        after_revision = relationship_after.get("revision") if isinstance(relationship_after, dict) else None
        if isinstance(before_revision, int) and isinstance(after_revision, int):
            if after_revision < before_revision:
                self._record(
                    {
                        "kind": "relationship_revision_regression",
                        "turnIndex": index,
                        "before": before_revision,
                        "after": after_revision,
                    }
                )

        transports = turn.get("transport", [])
        if not isinstance(transports, (list, tuple)):
            self._record({"kind": "invalid_transport_collection", "turnIndex": index})
            return
        for transport in transports:
            if not isinstance(transport, dict) or transport.get("direction") != "server_to_client":
                continue
            payload = transport.get("payload", {})
            event_id = payload.get("eventID") if isinstance(payload, dict) else None
            if not isinstance(event_id, str) or not event_id:
                continue
            if len(event_id) > MAX_EVENT_ID_LENGTH:
                self._truncation_reasons.add("event_id_length_limit")
                continue
            first_turn = self._event_ids.get(event_id)
            if first_turn is not None:
                self._record(
                    {
                        "kind": "duplicate_authoritative_event",
                        "turnIndex": index,
                        "eventID": event_id,
                        "firstTurnIndex": first_turn,
                    }
                )
            elif len(self._event_ids) >= MAX_TRACKED_EVENT_IDS:
                self._truncation_reasons.add("event_id_limit")
            else:
                self._event_ids[event_id] = index

    def report(self) -> list[dict[str, Any]]:
        conflicts = list(self._conflicts)
        if self._truncation_reasons:
            if len(conflicts) >= MAX_REPORTED_CONFLICTS:
                conflicts = conflicts[: MAX_REPORTED_CONFLICTS - 1]
            conflicts.append(
                {
                    "kind": "audit_truncated",
                    "reasons": sorted(self._truncation_reasons),
                    "trackedEventIDs": len(self._event_ids),
                }
            )
        return conflicts


def detect_conflicts(turns: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Find ordering/duplication problems using a bounded incremental ledger."""

    ledger = ConflictLedger()
    for turn in turns:
        ledger.add(turn)
    return ledger.report()


@dataclass
class HarnessRun:
    case_id: str
    turns: list[dict[str, Any]] = field(default_factory=list)
    conflicts: list[dict[str, Any]] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "type": "harness_run",
            "caseID": self.case_id,
            "turns": self.turns,
            "conflicts": self.conflicts,
            "ok": not self.conflicts,
        }


def run_case(case: HarnessCase, **worker_kwargs: Any) -> HarnessRun:
    worker = LuaSemanticWorker(case.scenario, **worker_kwargs)
    run = HarnessRun(case_id=case.case_id)
    try:
        for value in case.inputs:
            run.turns.append(worker.input(value))
        run.conflicts = detect_conflicts(run.turns)
    finally:
        worker.close()
    return run


def run_scenario_file(path: Path, inputs: Iterable[str], **worker_kwargs: Any) -> HarnessRun:
    scenario = load_scenario(path)
    return run_case(
        HarnessCase(case_id=path.stem, scenario=scenario, inputs=tuple(inputs)),
        **worker_kwargs,
    )
