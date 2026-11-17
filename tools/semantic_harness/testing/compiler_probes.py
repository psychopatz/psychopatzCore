"""Bounded PSDL / canonical IR / portable plan compiler probes for fixtures.

Delegates all semantic compilation and inspection to canonical CodeBuilder
authorities without reimplementing PSDL semantics in the fixture engine.
"""

from __future__ import annotations

from collections.abc import Mapping
from pathlib import Path
import threading
from typing import Any

from ..codebuilder.conversation_compiler import compile_conversation_sources
from ..codebuilder.portable_runtime import portable_plan_records
from ..codebuilder.psdl_compiler import render_pz_backend_from_portable_plan
from ..codebuilder.psdl_inspect import inspect_psdl, locate_psdl
from ..runtime.config import HarnessConfig

_MODEL_CACHE_LOCK = threading.Lock()
_MODEL_CACHE: dict[tuple[str, tuple[tuple[str, str], ...]], dict[str, Any]] = {}


def _resolve_package_repositories(
    *,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> tuple[Path, dict[str, Path]]:
    resolved_config = config
    if resolved_config is None:
        resolved_config = HarnessConfig.discover(
            repository=repository,
            core_repository=core_repository,
        )
    core_root = Path(resolved_config.core_repository).resolve()
    repos: dict[str, Path] = {"PsychopatzCore": core_root}
    active_repo = Path(resolved_config.repository).resolve()
    if active_repo != core_root:
        # Map active provider ID if known, otherwise directory name.
        provider_id = getattr(resolved_config, "provider_id", None) or active_repo.name
        repos[str(provider_id)] = active_repo
        if active_repo.name == "ProjectHoomans":
            repos["ProjectHoomans"] = active_repo
    dt_sibling = core_root.parent / "DynamicTrading"
    if dt_sibling.is_dir():
        repos.setdefault("DTCommon", dt_sibling.resolve())
    return core_root, repos


def get_compiled_model(
    *,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> tuple[dict[str, Any], dict[str, Path]]:
    core_root, repos = _resolve_package_repositories(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    cache_key = (
        str(core_root),
        tuple(sorted((k, str(v)) for k, v in repos.items())),
    )
    with _MODEL_CACHE_LOCK:
        model = _MODEL_CACHE.get(cache_key)
        if model is None:
            model = compile_conversation_sources(
                core_root,
                package_repositories=repos,
            )
            _MODEL_CACHE[cache_key] = model
    return model, repos


def probe_psdl_validate(
    *,
    record_id: str | None = None,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    model, _ = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    portable_plan = model.get("portablePlan") or {}
    records = portable_plan_records(portable_plan)
    result: dict[str, Any] = {
        "valid": True,
        "portablePlanSchema": portable_plan.get("schema"),
        "recordCount": len(records),
    }
    if record_id:
        summary = inspect_psdl(
            records,
            model.get("_source_documents") or {},
            record_id=record_id,
            mode="summary",
        )
        result["record"] = summary
    return result


def probe_psdl_inspect(
    *,
    record_id: str,
    mode: str = "summary",
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    model, _ = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    portable_plan = model.get("portablePlan") or {}
    records = portable_plan_records(portable_plan)
    inspected = inspect_psdl(
        records,
        model.get("_source_documents") or {},
        record_id=record_id,
        mode=mode,
    )
    if mode == "summary":
        runtime_rec = next(
            (r for r in (model.get("psdlRuntimePlans") or []) if r.get("id") == record_id),
            None,
        )
        if isinstance(runtime_rec, Mapping):
            inspected.setdefault("domain", runtime_rec.get("domain"))
            inspected.setdefault(
                "domainPath",
                runtime_rec.get("domainPath") or runtime_rec.get("domain"),
            )
            inspected.setdefault("package", runtime_rec.get("owner"))
    return inspected


def probe_canonical_ir_inspect(
    *,
    record_id: str,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    model, _ = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    for rec in model.get("psdlRuntimePlans") or []:
        if rec.get("id") == record_id:
            return dict(rec)
    portable_plan = model.get("portablePlan") or {}
    return inspect_psdl(
        portable_plan_records(portable_plan),
        model.get("_source_documents") or {},
        record_id=record_id,
        mode="ir",
    )


def probe_portable_plan_inspect(
    *,
    record_id: str | None = None,
    section: str | None = None,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    model, _ = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    portable_plan = model.get("portablePlan") or {}
    if record_id:
        sections = (
            [section]
            if section
            else ["dialogues", "beats", "behaviors", "realizations"]
        )
        for sec in sections:
            bucket = portable_plan.get(sec) or {}
            if isinstance(bucket, Mapping) and record_id in bucket:
                entry = dict(bucket[record_id])
                return {
                    "schema": portable_plan.get("schema"),
                    "section": sec,
                    "id": record_id,
                    "entry": entry,
                }
        raise ValueError(f"Record '{record_id}' not found in portablePlan")
    return {
        "schema": portable_plan.get("schema"),
        "dialogueCount": len(portable_plan.get("dialogues") or {}),
        "beatCount": len(portable_plan.get("beats") or {}),
        "behaviorCount": len(portable_plan.get("behaviors") or {}),
    }


def probe_backend_projection_inspect(
    *,
    record_id: str,
    backend: str = "pz-lua",
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    if backend != "pz-lua":
        raise ValueError(f"Unsupported backend projection '{backend}'")
    model, _ = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    portable_plan = model.get("portablePlan") or {}
    pz_plan = render_pz_backend_from_portable_plan(
        portable_plan,
        default_owner="PsychopatzCore",
    )
    for sec in ("runtimePlans", "beats", "behaviors", "flows", "realizations"):
        for item in pz_plan.get(sec) or ():
            if isinstance(item, Mapping) and item.get("id") == record_id:
                return {
                    "backend": backend,
                    "section": sec,
                    "id": record_id,
                    "projection": dict(item),
                }
    raise ValueError(
        f"Record '{record_id}' not found in '{backend}' backend projection"
    )


def probe_source_lineage_locate(
    *,
    record_id: str,
    core_repository: Path | None = None,
    repository: Path | None = None,
    config: HarnessConfig | None = None,
) -> dict[str, Any]:
    model, repos = get_compiled_model(
        core_repository=core_repository,
        repository=repository,
        config=config,
    )
    return locate_psdl(
        model,
        record_id=record_id,
        package_repositories=repos,
    )


__all__ = [
    "get_compiled_model",
    "probe_backend_projection_inspect",
    "probe_canonical_ir_inspect",
    "probe_portable_plan_inspect",
    "probe_psdl_inspect",
    "probe_psdl_validate",
    "probe_source_lineage_locate",
]
