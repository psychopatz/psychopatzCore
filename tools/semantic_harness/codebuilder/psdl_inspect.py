"""G8E: Progressive-disclosure PSDL inspection (`get --summary/--source/--ir` and `impact`)."""

from __future__ import annotations

import copy
from collections.abc import Mapping, Sequence
from typing import Any

from .errors import CompileError


def _summarize_record(
    rec: Mapping[str, Any],
    *,
    consumers: list[str],
    dependencies: list[str],
) -> dict[str, Any]:
    payload = rec.get("payload") or {}
    meta = payload.get("metadata") if isinstance(payload.get("metadata"), Mapping) else {}
    locales: set[str] = set()
    variant_counts: dict[str, int] = {}

    say = payload.get("say")
    if isinstance(say, Mapping):
        if isinstance(say.get("realizations"), Mapping):
            for rkey, real in say["realizations"].items():
                variants = real.get("variants") if isinstance(real, Mapping) else None
                if isinstance(variants, list):
                    variant_counts[f"say.{rkey}"] = len(variants)
                    for v in variants:
                        if isinstance(v, Mapping) and isinstance(v.get("text"), Mapping):
                            locales.update(str(k) for k in v["text"])
        elif isinstance(say.get("variants"), list):
            variant_counts["say"] = len(say["variants"])
            for v in say["variants"]:
                if isinstance(v, Mapping) and isinstance(v.get("text"), Mapping):
                    locales.update(str(k) for k in v["text"])

    outcomes: list[str] = []
    reply = payload.get("reply")
    if isinstance(reply, Mapping):
        outcomes = sorted(str(k) for k in reply)
        for out_name, branch in reply.items():
            if isinstance(branch, Mapping) and isinstance(branch.get("say"), Mapping):
                bsay = branch["say"]
                if isinstance(bsay.get("realizations"), Mapping):
                    for rkey, real in bsay["realizations"].items():
                        variants = real.get("variants") if isinstance(real, Mapping) else None
                        if isinstance(variants, list):
                            variant_counts[f"reply.{out_name}.{rkey}"] = len(variants)
                            for v in variants:
                                if isinstance(v, Mapping) and isinstance(v.get("text"), Mapping):
                                    locales.update(str(k) for k in v["text"])

    return {
        "id": rec.get("id"),
        "kind": rec.get("kind"),
        "owner": rec.get("owner"),
        "when": rec.get("when"),
        "slots": sorted((rec.get("slots") or {}).keys()) if isinstance(rec.get("slots"), Mapping) else [],
        "references": sorted((rec.get("references") or {}).keys()) if isinstance(rec.get("references"), Mapping) else [],
        "requiredCapabilities": sorted(
            set(payload.get("requiredCapabilities") or [])
            | ({meta["capability"]} if isinstance(meta.get("capability"), str) else set())
        ),
        "action": payload.get("action"),
        "outcomes": outcomes,
        "locales": sorted(locales),
        "variantCounts": variant_counts,
        "dependencies": sorted(dependencies),
        "consumers": sorted(consumers),
    }


def _build_dependency_graph(records: Sequence[Mapping[str, Any]]) -> tuple[dict[str, set[str]], dict[str, set[str]]]:
    deps: dict[str, set[str]] = {}
    consumers: dict[str, set[str]] = {}
    for rec in records:
        rid = str(rec.get("id") or "")
        deps.setdefault(rid, set())
        consumers.setdefault(rid, set())
        payload = rec.get("payload") or {}
        if rec.get("kind") == "beat":
            for cand in payload.get("candidates") or []:
                if isinstance(cand, Mapping) and isinstance(cand.get("behavior"), str):
                    target = cand["behavior"]
                    deps[rid].add(target)
                    consumers.setdefault(target, set()).add(rid)
        if rec.get("kind") == "behavior":
            outputs = payload.get("outputs") or {}
            if isinstance(outputs, Mapping):
                for out in outputs.values():
                    if isinstance(out, Mapping) and isinstance(out.get("contentTemplateID"), str):
                        target = out["contentTemplateID"]
                        deps[rid].add(target)
                        consumers.setdefault(target, set()).add(rid)
    return deps, consumers


def inspect_psdl(
    records: Sequence[Mapping[str, Any]],
    raw_sources: Mapping[str, Any],
    *,
    record_id: str,
    mode: str = "summary",
) -> dict[str, Any]:
    """Return summary, source, canonical IR, or impact for *record_id*."""
    by_id = {str(rec.get("id") or ""): rec for rec in records}
    if record_id not in by_id:
        raise CompileError(f"Unknown PSDL record ID: {record_id!r}")
    rec = by_id[record_id]
    deps, consumers = _build_dependency_graph(records)

    if mode == "summary":
        return _summarize_record(
            rec,
            dependencies=list(deps.get(record_id, ())),
            consumers=list(consumers.get(record_id, ())),
        )
    if mode == "source":
        lineage = rec.get("lineage") or {}
        src_path = str(lineage.get("sourcePath") or "")
        if src_path in raw_sources:
            return {"id": record_id, "sourcePath": src_path, "source": copy.deepcopy(raw_sources[src_path])}
        return {"id": record_id, "sourcePath": src_path, "source": None}
    if mode == "ir":
        return copy.deepcopy(dict(rec))
    if mode == "impact":
        return {
            "id": record_id,
            "kind": rec.get("kind"),
            "directDependencies": sorted(deps.get(record_id, ())),
            "directConsumers": sorted(consumers.get(record_id, ())),
        }
    raise CompileError(f"Unsupported inspection mode {mode!r}; expected summary, source, ir, or impact")


__all__ = ["inspect_psdl"]
