"""G8D: Data-driven package/target descriptors, capability ABI, and adapter stub generator.

This module contains zero hard-coded adopter names. Any package or target
descriptor compiles and validates through its declared capabilities, resolvers,
and output bindings.
"""

from __future__ import annotations

import copy
from collections.abc import Mapping, Sequence
from typing import Any

from .errors import CompileError


TARGET_DESCRIPTOR_SCHEMA = "psychopatz.psdl.target.v1"


def validate_target_descriptor(doc: Mapping[str, Any]) -> dict[str, Any]:
    """Validate a target/backend descriptor."""
    if not isinstance(doc, Mapping):
        raise CompileError("Target descriptor must be a JSON object")
    if doc.get("schema") != TARGET_DESCRIPTOR_SCHEMA:
        raise CompileError(
            f"Invalid target descriptor schema {doc.get('schema')!r}; expected {TARGET_DESCRIPTOR_SCHEMA!r}"
        )
    target_id = doc.get("target")
    if not isinstance(target_id, str) or not target_id.strip():
        raise CompileError("Target descriptor requires a non-empty target ID")
    caps = doc.get("providedCapabilities") or []
    if not isinstance(caps, list) or any(not isinstance(c, str) or not c.strip() for c in caps):
        raise CompileError("Target descriptor providedCapabilities must be a list of capability IDs")
    resolvers = doc.get("providedResolvers") or []
    if not isinstance(resolvers, list) or any(not isinstance(r, str) or not r.strip() for r in resolvers):
        raise CompileError("Target descriptor providedResolvers must be a list of resolver IDs")
    return copy.deepcopy(dict(doc))


def collect_required_capabilities(records: Sequence[Mapping[str, Any]]) -> dict[str, list[str]]:
    """Map each required capability ID to the sorted list of PSDL record IDs requiring it."""
    by_cap: dict[str, set[str]] = {}
    for rec in records:
        rec_id = str(rec.get("id") or "")
        payload = rec.get("payload") or {}
        caps = list(payload.get("requiredCapabilities") or [])
        action = payload.get("action")
        if isinstance(action, Mapping) and isinstance(action.get("capability"), str):
            caps.append(action["capability"])
        meta = payload.get("metadata")
        if isinstance(meta, Mapping) and isinstance(meta.get("capability"), str):
            caps.append(meta["capability"])
        for cap in caps:
            if isinstance(cap, str) and cap.strip():
                by_cap.setdefault(cap.strip(), set()).add(rec_id)
    return {cap: sorted(ids) for cap, ids in sorted(by_cap.items())}


def collect_required_resolvers(records: Sequence[Mapping[str, Any]]) -> dict[str, list[str]]:
    """Map each required resolver ID to the sorted list of PSDL record IDs referencing it."""
    by_res: dict[str, set[str]] = {}
    for rec in records:
        rec_id = str(rec.get("id") or "")
        payload = rec.get("payload") or {}
        bindings = payload.get("bindings")
        if isinstance(bindings, Mapping):
            for spec in bindings.values():
                if isinstance(spec, Mapping) and isinstance(spec.get("resolver"), str):
                    by_res.setdefault(spec["resolver"], set()).add(rec_id)
    return {res: sorted(ids) for res, ids in sorted(by_res.items())}


def validate_target_capabilities(
    records: Sequence[Mapping[str, Any]],
    target_descriptor: Mapping[str, Any],
) -> dict[str, Any]:
    """Fail closed when a target lacks capabilities or resolvers required by compiled PSDL."""
    target = validate_target_descriptor(target_descriptor)
    provided_caps = set(target.get("providedCapabilities") or [])
    provided_resolvers = set(target.get("providedResolvers") or [])
    required_caps = collect_required_capabilities(records)
    required_resolvers = collect_required_resolvers(records)

    missing_caps = {
        cap: owners for cap, owners in required_caps.items() if cap not in provided_caps
    }
    missing_resolvers = {
        res: owners for res, owners in required_resolvers.items() if res not in provided_resolvers
    }
    if missing_caps or missing_resolvers:
        parts: list[str] = []
        if missing_caps:
            details = ", ".join(f"{cap} (required by {', '.join(owners)})" for cap, owners in missing_caps.items())
            parts.append(f"missing capabilities: {details}")
        if missing_resolvers:
            details = ", ".join(f"{res} (required by {', '.join(owners)})" for res, owners in missing_resolvers.items())
            parts.append(f"missing resolvers: {details}")
        raise CompileError(f"Target {target['target']!r} failed capability ABI check: {'; '.join(parts)}")

    return {
        "ok": True,
        "target": target["target"],
        "requiredCapabilities": required_caps,
        "requiredResolvers": required_resolvers,
    }


def generate_adapter_stub_guidance(
    records: Sequence[Mapping[str, Any]],
    target_descriptor: Mapping[str, Any],
) -> dict[str, Any]:
    """Generate typed adapter interface/stub guidance for missing or declared capabilities."""
    target = validate_target_descriptor(target_descriptor)
    provided_caps = set(target.get("providedCapabilities") or [])
    required_caps = collect_required_capabilities(records)
    missing_caps = sorted(set(required_caps) - provided_caps)
    stubs = {
        cap: {
            "capability": cap,
            "usedBy": required_caps[cap],
            "interface": f"execute({cap!r}, args, context) -> {{outcome: 'queued'|'rejected'|'failed', data?: object}}",
        }
        for cap in sorted(required_caps)
    }
    return {
        "target": target["target"],
        "missingCapabilities": missing_caps,
        "stubs": stubs,
    }


__all__ = [
    "TARGET_DESCRIPTOR_SCHEMA",
    "collect_required_capabilities",
    "collect_required_resolvers",
    "generate_adapter_stub_guidance",
    "validate_target_capabilities",
    "validate_target_descriptor",
]
