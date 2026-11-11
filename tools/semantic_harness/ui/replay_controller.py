"""Keep and execute bounded interaction replay steps."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def record_replay_step(app: Any, step: dict[str, Any]) -> None:
    """Keep a bounded, canonical interaction macro for later replay."""

    if not isinstance(step, dict):
        return
    recorded = deepcopy(step)
    recorded.pop("requestRevision", None)
    app.replay_steps.append(recorded)
    app.replay_steps = app.replay_steps[-32:]
    app.activity_log.record(
        "ui",
        "replay_step_recorded",
        index=len(app.replay_steps),
        kind=str(recorded.get("kind") or "unknown"),
        candidateID=str(recorded.get("candidateID") or ""),
        text=str(recorded.get("text") or "")[:180],
    )
    app._refresh_workbench_feedback(
        f"Recorded replay step {len(app.replay_steps)}."
    )


def replay_projection_frame(
    worker: LuaSemanticWorker, step: dict[str, Any]
) -> dict[str, Any] | None:
    """Resolve a recorded choice against the worker's current revision."""

    snapshot = worker.snapshot()
    suggestions = snapshot.get("suggestions") or {}
    candidate_id = str(step.get("candidateID") or "")
    for group in suggestions.get("groups", []) or []:
        if not isinstance(group, dict):
            continue
        for collection_name in ("navigation", "candidates", "capabilities"):
            for row in group.get(collection_name, []) or []:
                if (
                    not isinstance(row, dict)
                    or str(row.get("id") or "") != candidate_id
                ):
                    continue
                frame = row.get("frame")
                if isinstance(frame, dict):
                    return deepcopy(frame)
    frame = step.get("frame")
    if not isinstance(frame, dict):
        return None
    frame = deepcopy(frame)
    revision = suggestions.get("revision")
    if revision is not None:
        frame["requestRevision"] = revision
    return frame


def replay_step(worker: LuaSemanticWorker, step: dict[str, Any]) -> dict[str, Any]:
    kind = str(step.get("kind") or "input")
    if kind == "input":
        return worker.input(str(step.get("text") or ""))
    frame = replay_projection_frame(worker, step)
    if frame is not None:
        return worker.suggestion_click(frame)
    return worker.input(str(step.get("text") or ""))
