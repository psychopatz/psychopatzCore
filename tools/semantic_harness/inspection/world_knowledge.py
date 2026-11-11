"""Bounded World Knowledge inspection for the existing Semantic Lab UI."""

from __future__ import annotations

from typing import Any


MAX_ITEMS = 32
MAX_TEXT = 512


def _bounded(value: Any, depth: int = 0, limit: int = MAX_ITEMS) -> Any:
    if depth >= 5:
        return "<depth limit>"
    if isinstance(value, str):
        return value if len(value) <= MAX_TEXT else value[:MAX_TEXT] + "…"
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    if isinstance(value, list):
        result = [_bounded(item, depth + 1) for item in value[:limit]]
        if len(value) > limit:
            result.append(f"<{len(value) - limit} more>")
        return result
    if isinstance(value, dict):
        keys = sorted(value, key=str)
        result = {
            str(key): _bounded(value[key], depth + 1)
            for key in keys[:limit]
        }
        if len(keys) > limit:
            result["_truncatedKeys"] = len(keys) - limit
        return result
    return str(value)


def _actor_row(actors: Any, actor_id: str | None) -> dict[str, Any]:
    if not isinstance(actors, list):
        return {}
    for row in actors:
        if isinstance(row, dict) and str(row.get("actorID") or "") == str(actor_id or ""):
            return row
    return {}


def _explanation(record: dict[str, Any], actor: dict[str, Any]) -> dict[str, Any] | None:
    explicit = record.get("explanation")
    if isinstance(explicit, dict):
        return explicit
    rows = actor.get("explanations", [])
    if isinstance(rows, list) and rows and isinstance(rows[0], dict):
        return rows[0]
    return None


def build_world_knowledge_inspector(record: dict[str, Any]) -> dict[str, Any]:
    """Project the real worker response into explainable WKG sections."""

    record = record if isinstance(record, dict) else {}
    ledger = record.get("ledger") if isinstance(record.get("ledger"), dict) else {}
    actors = record.get("actorKnowledge")
    actors = actors if isinstance(actors, list) else []
    actor_id = record.get("actorID")
    actor = _actor_row(actors, actor_id)
    final = record.get("finalRealization")
    final = final if isinstance(final, dict) else {}
    propagation = record.get("propagationTrace")
    propagation = propagation if isinstance(propagation, list) else []
    core_trace = record.get("corePropagationTrace")
    core_trace = core_trace if isinstance(core_trace, list) else []
    candidates = record.get("candidates")
    candidates = candidates if isinstance(candidates, list) else []
    explanation = _explanation(record, actor)
    return {
        "source": "real_lua_worker",
        "scenarioOwned": record.get("scenarioOwned") is True,
        "actorID": actor_id,
        "factLedger": _bounded({
            "facts": ledger.get("facts", []),
            "metrics": ledger.get("metrics", {}),
            "maxFacts": ledger.get("maxFacts"),
            "revision": ledger.get("revision"),
        }),
        "actorKnowledge": _bounded({
            "actorID": actor_id,
            "references": actor.get("references", []),
            "explanations": actor.get("explanations", []),
        }),
        "propagationTrace": _bounded({
            "adapter": propagation,
            "core": core_trace,
        }),
        "candidateSelection": _bounded({
            "ranked": True,
            "bounded": True,
            "candidates": candidates,
        }),
        "whyActorKnows": _bounded(explanation),
        "authorization": _bounded({
            "scenarioOwned": record.get("scenarioOwned") is True,
            "lastPropagation": propagation[-1] if propagation else None,
            "rejectionReason": (
                propagation[-1].get("reason")
                if propagation and isinstance(propagation[-1], dict)
                and propagation[-1].get("accepted") is False
                else None
            ),
        }),
        "finalRealization": _bounded({
            "source": final.get("source") or "world_knowledge",
            "localization": final.get("language") or record.get("language") or "EN",
            "statements": final.get("statements", []),
            "factRefs": final.get("factRefs", []),
        }),
    }
