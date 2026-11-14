"""Core ConvoEngine Semantic Lab index, simulation, and trace helpers.

All Semantic Lab simulation and action-contract discovery delegate directly
to the live production Lua runtime via ``ConvoProbe`` and the canonical
``ConvoCatalog`` — never a duplicate Python interpreter or hard-coded
provider action table.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

from .convo_catalog import ConvoCatalog
from .convo_probe import ConvoProbe
from .translation_support import DEFAULT_LANGUAGE, normalize_language
from .workspace_catalog import WorkspaceCatalog, WorkspaceSnapshot


def _workspace_snapshot(service: Any) -> WorkspaceSnapshot:
    snapshot = getattr(service, "workspace_snapshot", None)
    if isinstance(snapshot, WorkspaceSnapshot):
        return snapshot
    return WorkspaceCatalog.discover(
        getattr(service, "repository", None),
        repository=getattr(service, "repository", None),
        core_repository=getattr(service, "core_repository", None),
        hoomans_repository=getattr(service, "hoomans_repository", None),
        dynamic_trading_repository=getattr(service, "dynamic_trading_repository", None),
        runtime_root=getattr(service, "runtime_root", None),
    )


def _convo_probe(service: Any) -> ConvoProbe:
    probe = getattr(service, "convo_probe", None)
    if isinstance(probe, ConvoProbe):
        return probe
    probe = ConvoProbe(_workspace_snapshot(service))
    try:
        service.convo_probe = probe
    except Exception:
        pass
    return probe


def _manifest_action_contracts(snapshot: WorkspaceSnapshot) -> dict[str, dict[str, Any]]:
    """Read optional data-driven actionContracts declared inside provider manifests."""
    discovered: dict[str, dict[str, Any]] = {}
    for provider in snapshot.providers:
        manifest_file = provider.manifest_path
        try:
            doc = json.loads(manifest_file.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError):
            continue
        if not isinstance(doc, Mapping):
            continue
        entries: list[Any] = []
        if isinstance(doc.get("actionContracts"), list):
            entries.extend(doc["actionContracts"])
        elif isinstance(doc.get("actionContracts"), Mapping):
            for cid, spec in doc["actionContracts"].items():
                if isinstance(spec, Mapping):
                    entries.append({"id": cid, **spec})
        for raw_entry in entries:
            if not isinstance(raw_entry, Mapping):
                continue
            cid = str(raw_entry.get("id") or "").strip()
            if cid:
                item = dict(raw_entry)
                item.setdefault("id", cid)
                item.setdefault("owner", provider.provider_id)
                item.setdefault("source", "provider_manifest")
                discovered[cid] = item
    return discovered


def list_convo_engine_families(service: Any) -> list[dict[str, Any]]:
    """Return canonical ConvoEngine single-family sources across enabled repositories."""
    catalog = getattr(service, "convo_catalog", None)
    if isinstance(catalog, ConvoCatalog):
        return catalog.list_summaries()
    return ConvoCatalog(_workspace_snapshot(service)).list_summaries()


def list_registered_action_contracts(service: Any) -> list[dict[str, Any]]:
    """Discover registered Semantic Action Contracts via ConvoProbe, manifests, and sources."""
    snapshot = _workspace_snapshot(service)
    contracts: dict[str, dict[str, Any]] = _manifest_action_contracts(snapshot)

    probe = _convo_probe(service)
    for lua_contract in probe.list_action_contracts():
        cid = str(lua_contract.get("id") or "").strip()
        if not cid:
            continue
        entry = contracts.setdefault(cid, {"id": cid})
        entry.update(lua_contract)
        entry.setdefault("source", "lua_runtime")

    for item in list_convo_engine_families(service):
        action_id = item.get("executeAction")
        if not action_id:
            continue
        action_id_str = str(action_id)
        if action_id_str not in contracts:
            contracts[action_id_str] = {
                "id": action_id_str,
                "owner": item.get("owner"),
                "mode": "request_response",
                "discoveryOnly": False,
                "inputs": {},
                "publicResultSchema": {"outcome": "string", "reasonClass": "string"},
                "declaredIn": [item["canonicalID"]],
                "source": "convo_catalog",
            }
        else:
            contracts[action_id_str].setdefault("declaredIn", [])
            if item["canonicalID"] not in contracts[action_id_str]["declaredIn"]:
                contracts[action_id_str]["declaredIn"].append(item["canonicalID"])

    return [contracts[key] for key in sorted(contracts)]


def simulate_convo_engine_family(
    service: Any,
    document: dict[str, Any],
    *,
    source_path: str | Path | None = None,
    speaker: str = "player",
    addressee: str = "npc",
    target: str | None = None,
    slot_values: Mapping[str, Any] | None = None,
    style: str = "neutral",
    locale: str = "EN",
    result_outcome: str | None = None,
    result_reason_class: str | None = None,
    result_fields: Mapping[str, Any] | None = None,
    context: Mapping[str, Any] | None = None,
    realization_key: str | None = None,
) -> dict[str, Any]:
    """Compile and simulate a ConvoEngine family through the live Lua ConvoProbe."""
    validation = service.validate_convo_engine_document(
        document,
        source_path=source_path,
        allow_legacy_schema=False,
    )
    if validation.get("ok") is not True:
        return {
            "ok": False,
            "previewOnly": True,
            "effectFree": True,
            "diagnostics": validation.get("diagnostics", []),
            "trace": [],
        }

    plans = validation.get("runtimePlan") or []
    plan = plans[0] if plans else {}
    norm_locale = normalize_language(locale or DEFAULT_LANGUAGE)

    result_env: dict[str, Any] = dict(result_fields or {})
    if result_outcome is not None:
        result_env.setdefault("outcome", result_outcome)
    if result_reason_class is not None:
        result_env.setdefault("reasonClass", result_reason_class)

    env: dict[str, Any] = dict(context or {})
    env["speaker"] = speaker
    env["addressee"] = addressee
    if target is not None:
        env["target"] = target
    env["slot"] = dict(slot_values or {})
    env["slots"] = env["slot"]
    env["result"] = result_env

    probe = _convo_probe(service)
    lua_sim = probe.simulate_exchange(
        plan,
        context=env,
        options={
            "language": norm_locale,
            "locale": norm_locale,
            "style": style,
            "realizationKey": realization_key or "",
            "consumer": speaker,
            "outcome": result_outcome,
        },
    )
    lua_sim["compiledFingerprint"] = validation["compiled"]["fingerprint"]
    lua_sim["diagnostics"] = validation.get("diagnostics", [])
    lua_sim["previewContext"] = {
        "speaker": speaker,
        "addressee": addressee,
        "target": target,
        "style": style,
        "locale": norm_locale,
        "slots": dict(slot_values or {}),
        "result": result_env,
    }
    return lua_sim


__all__ = [
    "list_convo_engine_families",
    "list_registered_action_contracts",
    "simulate_convo_engine_family",
]
