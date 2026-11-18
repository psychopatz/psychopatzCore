"""Progressive-disclosure ConvoEngine inspection (`get --summary/--source/--ir`, `impact`, and `locate`)."""

from __future__ import annotations

import copy
from collections.abc import Mapping, Sequence
from pathlib import Path
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


def inspect_convo_engine(
    records: Sequence[Mapping[str, Any]],
    raw_sources: Mapping[str, Any],
    *,
    record_id: str,
    mode: str = "summary",
) -> dict[str, Any]:
    """Return summary, source, canonical IR, or impact for *record_id*."""
    by_id = {str(rec.get("id") or ""): rec for rec in records}
    if record_id not in by_id:
        raise CompileError(f"Unknown ConvoEngine record ID: {record_id!r}")
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


def locate_convo_engine(
    compiled_model: Mapping[str, Any],
    *,
    record_id: str,
    package_repositories: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    """Derive full source -> package -> portable plan -> generated module navigation."""
    from .conversation_compiler import render_conversation_runtime_plan
    from .generation_ownership import package_descriptor

    records = compiled_model.get("convoRuntimePlans") or []
    by_id = {str(rec.get("id") or ""): rec for rec in records}
    if record_id not in by_id:
        raise CompileError(f"Unknown ConvoEngine record ID: {record_id!r}")
    rec = by_id[record_id]
    owner = str(rec.get("owner") or "")
    if not owner:
        portable_plan = compiled_model.get("portablePlan") or {}
        for sec in ("dialogues", "beats", "behaviors", "realizations"):
            entry = (portable_plan.get(sec) or {}).get(record_id)
            if isinstance(entry, Mapping) and entry.get("owner"):
                owner = str(entry["owner"])
                break
    desc = package_descriptor(owner)
    lineage = rec.get("lineage") or {}
    source_path = str(lineage.get("sourcePath") or "")

    # Read owning package's imports from its package.json if available
    imported_packages: list[str] = []
    if package_repositories and owner in package_repositories:
        pkg_json = Path(package_repositories[owner]) / desc.source_root_relative / "package.json"
        if pkg_json.is_file():
            import json
            pkg_doc = json.loads(pkg_json.read_text(encoding="utf-8"))
            imported_packages = list(pkg_doc.get("imports") or [])

    # Required capabilities
    payload = rec.get("payload") or {}
    caps = list(payload.get("requiredCapabilities") or [])
    act = payload.get("action")
    if isinstance(act, Mapping) and act.get("capability") and act["capability"] not in caps:
        caps.append(str(act["capability"]))

    # Generated backend modules from the canonical runtime plan renderer
    _, reports = render_conversation_runtime_plan(dict(compiled_model))
    generated_modules = sorted({
        str(rep["module"])
        for rep in reports
        if record_id in (rep.get("recordIDs") or []) and rep.get("module")
    })

    # Portable Dialogue Plan presence
    portable_plan = compiled_model.get("portablePlan") or {}
    section_map = {
        "dialogue": "dialogues",
        "behavior": "behaviors",
        "beat": "beats",
        "realization": "realizations",
    }
    section = section_map.get(str(rec.get("kind") or ""), "dialogues")
    in_portable = record_id in (portable_plan.get(section) or {})

    deps, consumers = _build_dependency_graph(records)
    return {
        "id": record_id,
        "kind": rec.get("kind"),
        "package": desc.owner,
        "owner": owner,
        "domain": rec.get("domain"),
        "domainPath": rec.get("domainPath") or rec.get("domain"),
        "authoredSourcePath": (desc.source_root_relative / source_path).as_posix() if source_path else "",
        "packageRelativeSourcePath": source_path,
        "authoringSchema": lineage.get("authoringSchema"),
        "canonicalSchema": lineage.get("canonicalSchema"),
        "importedPackages": imported_packages,
        "requiredCapabilities": sorted(caps),
        "portablePlanSection": section if in_portable else None,
        "generatedModules": generated_modules,
        "dependencies": sorted(deps.get(record_id, ())),
        "consumers": sorted(consumers.get(record_id, ())),
    }


__all__ = ["inspect_convo_engine", "locate_convo_engine"]
