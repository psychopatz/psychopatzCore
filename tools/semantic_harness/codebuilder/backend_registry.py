"""Descriptor-driven backend registry and dispatch for Portable Dialogue Plans."""

from __future__ import annotations

from collections.abc import Callable, Mapping
from contextlib import contextmanager
from typing import Any, Iterator

from .errors import CompileError
from .portable_runtime import PORTABLE_PLAN_SCHEMA

BackendRenderer = Callable[..., dict[str, Any]]

_BACKEND_REGISTRY: dict[str, BackendRenderer] = {}


def register_backend(backend_id: str, renderer: BackendRenderer) -> None:
    """Register one backend renderer under its descriptor backend ID."""
    key = str(backend_id or "").strip()
    if not key:
        raise CompileError("backend_id must be a non-empty string")
    _BACKEND_REGISTRY[key] = renderer


def unregister_backend(backend_id: str) -> None:
    """Remove a backend renderer (primarily for isolated tests)."""
    _BACKEND_REGISTRY.pop(str(backend_id or "").strip(), None)


def list_backends() -> list[str]:
    """Return sorted registered backend IDs."""
    return sorted(_BACKEND_REGISTRY)


def resolve_backend(backend_id: Any) -> BackendRenderer:
    """Resolve a registered backend renderer or fail closed."""
    key = str(backend_id or "").strip()
    if not key:
        raise CompileError("Target descriptor requires a non-empty backend ID")
    renderer = _BACKEND_REGISTRY.get(key)
    if renderer is None:
        known = ", ".join(sorted(_BACKEND_REGISTRY)) or "<none>"
        raise CompileError(
            f"Unknown target backend {key!r}; registered backends: {known}"
        )
    return renderer


@contextmanager
def temporary_backend(backend_id: str, renderer: BackendRenderer) -> Iterator[None]:
    """Temporarily register or override a backend renderer."""
    key = str(backend_id or "").strip()
    had_prev = key in _BACKEND_REGISTRY
    prev = _BACKEND_REGISTRY.get(key)
    register_backend(key, renderer)
    try:
        yield
    finally:
        if had_prev and prev is not None:
            _BACKEND_REGISTRY[key] = prev
        else:
            _BACKEND_REGISTRY.pop(key, None)


def render_portable_json_backend(
    portable_plan: Mapping[str, Any],
    *,
    target_descriptor: Mapping[str, Any] | None = None,
    entry_by_record_id: Mapping[str, Mapping[str, Any]] | None = None,
    default_owner: Any = None,
) -> dict[str, Any]:
    """Minimal portable-json reference backend proving non-PZ target dispatch."""
    if not isinstance(portable_plan, Mapping) or portable_plan.get("schema") != PORTABLE_PLAN_SCHEMA:
        raise CompileError(
            f"portable-json backend requires a validated Portable Dialogue Plan ({PORTABLE_PLAN_SCHEMA})"
        )
    target_name = str((target_descriptor or {}).get("target") or portable_plan.get("package") or "default")
    return {
        "backend": "portable-json",
        "portablePlanSchema": portable_plan["schema"],
        "target": target_name,
        "runtimePlans": [],
        "behaviors": list((portable_plan.get("behaviors") or {}).values()),
        "beats": list((portable_plan.get("beats") or {}).values()),
        "ui": [],
        "semanticPacks": [],
        "responsePools": [],
        "responsePoolOwners": {},
        "flows": [],
        "realizations": list((portable_plan.get("realizations") or {}).values()),
        "portableArtifacts": {
            "portable_plan.json": dict(portable_plan),
        },
    }


def render_portable_plan_for_target(
    portable_plan: Mapping[str, Any],
    *,
    target_descriptor: Mapping[str, Any],
    entry_by_record_id: Mapping[str, Mapping[str, Any]] | None = None,
    default_owner: Any = None,
) -> dict[str, Any]:
    """Dispatch a Portable Dialogue Plan to the backend named by *target_descriptor*."""
    if not isinstance(target_descriptor, Mapping):
        raise CompileError("target_descriptor must be a mapping")
    backend_id = target_descriptor.get("backend")
    renderer = resolve_backend(backend_id)
    return renderer(
        portable_plan,
        target_descriptor=target_descriptor,
        entry_by_record_id=entry_by_record_id,
        default_owner=default_owner,
    )


def _pz_lua_backend_adapter(
    portable_plan: Mapping[str, Any],
    *,
    target_descriptor: Mapping[str, Any] | None = None,
    entry_by_record_id: Mapping[str, Mapping[str, Any]] | None = None,
    default_owner: Any = None,
) -> dict[str, Any]:
    from .psdl_compiler import render_pz_backend_from_portable_plan

    result = render_pz_backend_from_portable_plan(
        portable_plan,
        entry_by_record_id=entry_by_record_id,
        default_owner=default_owner,
    )
    result["backend"] = "pz-lua"
    return result


register_backend("pz-lua", _pz_lua_backend_adapter)
register_backend("portable-json", render_portable_json_backend)

__all__ = [
    "list_backends",
    "register_backend",
    "render_portable_json_backend",
    "render_portable_plan_for_target",
    "resolve_backend",
    "temporary_backend",
    "unregister_backend",
]
