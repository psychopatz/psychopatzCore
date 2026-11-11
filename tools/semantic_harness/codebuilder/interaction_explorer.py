"""Searchable view over the live Semantic Lab interaction surfaces."""

from __future__ import annotations


import copy
import json
from typing import Any, Iterable


def _copy(value: Any) -> Any:
    return copy.deepcopy(value)


def _text(value: Any) -> str:
    return str(value or "")


def _trigger_branch_map(policy_catalog: dict[str, Any]) -> dict[str, list[str]]:
    mapping: dict[str, list[str]] = {}
    for branch in policy_catalog.get("branches", []):
        if not isinstance(branch, dict):
            continue
        branch_id = _text(branch.get("id"))
        if not branch_id:
            continue
        for trigger_id in branch.get("triggerIDs", []):
            trigger_id = _text(trigger_id)
            if trigger_id:
                mapping.setdefault(trigger_id, []).append(branch_id)
    return mapping


def _route_steps(kind: str, value: dict[str, Any]) -> list[str]:
    if kind == "policy_branch":
        branch_id = _text(value.get("policyBranch") or value.get("id"))
        if branch_id in {"HOSTILE_REMARK_RECEIVED", "THREAT_RECEIVED"}:
            return [
                "PsychopatzCore IR",
                "PNC.Semantics.DialoguePolicy",
                "directed social authority / transport",
                "social event or truthful rejection",
                "response selection",
            ]
        return [
            "PsychopatzCore IR",
            "PNC.Semantics.DialoguePolicy",
            "response selection",
        ]
    if kind == "trigger":
        return [
            "PsychopatzCore semantic catalog",
            "recognized trigger frame",
            "PNC.Semantics.DialoguePolicy",
        ]
    if kind == "flow":
        return [
            "PsychopatzCore IR",
            "PNC Semantic Dialogue FlowRegistry",
            "FlowKernel / response plan",
        ]
    if kind == "capability":
        return [
            "PsychopatzCore IR",
            "PNC.Semantics.CapabilityCatalog",
            "registered gameplay authority / transport",
            "response selection",
        ]
    if kind == "generated":
        return [
            "AutomaticFlowGenerator",
            "PNC Semantic Dialogue FlowRegistry",
            "registered capability binding",
            "generated response pool",
        ]
    if kind == "response_pool":
        return [
            "generated or reviewed response pool",
            "response plan selection",
            "EN/TL translation",
        ]
    if kind == "concept":
        return ["PsychopatzCore semantic concept catalog", "PsychopatzCore IR"]
    if kind == "speech_act":
        return ["PsychopatzCore speech-act catalog", "PsychopatzCore IR"]
    return ["live Semantic Lab production catalog"]


def _row(
    *,
    kind: str,
    identifier: str,
    label: str,
    source: str,
    value: dict[str, Any],
    **extra: Any,
) -> dict[str, Any]:
    row = {
        "id": identifier,
        "kind": kind,
        "label": label or identifier,
        "source": source,
        "route": kind,
        "routeSteps": _route_steps(kind, {"id": identifier, **value}),
        **_copy(value),
        **extra,
    }
    return row


def _iter_dicts(values: Any) -> Iterable[dict[str, Any]]:
    if isinstance(values, list):
        return (value for value in values if isinstance(value, dict))
    return ()


def build_interaction_rows(production_catalog: dict[str, Any] | None) -> list[dict[str, Any]]:
    """Build bounded rows from the live worker's canonical catalog surfaces."""

    catalog = production_catalog if isinstance(production_catalog, dict) else {}
    policy_catalog = catalog.get("policyCatalog", {})
    if not isinstance(policy_catalog, dict):
        policy_catalog = {}
    trigger_branches = _trigger_branch_map(policy_catalog)
    rows: list[dict[str, Any]] = []

    for branch in _iter_dicts(policy_catalog.get("branches")):
        branch_id = _text(branch.get("id"))
        if not branch_id:
            continue
        rows.append(_row(
            kind="policy_branch",
            identifier=f"policy:{branch_id}",
            label=branch_id,
            source="PNC.Semantics.DialoguePolicy.ResponseTemplates",
            value={
                "policyBranch": branch_id,
                "triggerIDs": _copy(branch.get("triggerIDs", [])),
                "triggerFrames": _copy(branch.get("triggerFrames", [])),
                "responseTemplate": _copy(branch.get("responseTemplate", {})),
                "reason": branch.get("reason"),
            },
        ))

    for trigger in _iter_dicts(catalog.get("triggerCatalog")):
        trigger_id = _text(trigger.get("id"))
        if not trigger_id:
            continue
        rows.append(_row(
            kind="trigger",
            identifier=f"trigger:{trigger_id}",
            label=_text(trigger.get("label")) or trigger_id,
            source="PsychopatzCore semantic trigger catalog",
            value={
                "triggerID": trigger_id,
                "frame": _copy(trigger.get("frame", {})),
                "priority": trigger.get("priority"),
                "confidence": trigger.get("confidence"),
                "policyBranches": sorted(set(trigger_branches.get(trigger_id, []))),
            },
        ))

    for flow in _iter_dicts(catalog.get("flows")):
        flow_id = _text(flow.get("id"))
        if not flow_id:
            continue
        rows.append(_row(
            kind="flow",
            identifier=f"flow:{flow_id}",
            label=flow_id,
            source="PNC Semantic Dialogue FlowRegistry",
            value={
                "flowID": flow_id,
                "owner": flow.get("owner"),
                "workflowKind": flow.get("workflowKind"),
                "capabilityID": flow.get("capabilityID"),
                "triggers": _copy(flow.get("triggers", [])),
                "nodeIDs": sorted(
                    str(node_id) for node_id in (flow.get("nodes") or {})
                ),
            },
        ))

    for action in _iter_dicts(catalog.get("actionCatalog")):
        action_id = _text(action.get("id"))
        if not action_id:
            continue
        rows.append(_row(
            kind="capability",
            identifier=f"capability:{action_id}",
            label=action_id,
            source="PNC.Semantics.CapabilityCatalog.actionCatalog",
            value={
                "capabilityID": action_id,
                "bindingID": action.get("bindingID"),
                "bindingStatus": action.get("bindingStatus"),
                "dispatchable": action.get("dispatchable"),
                "frame": _copy(action.get("frame", {})),
                "transports": _copy(action.get("transports", [])),
                "responsePools": _copy(action.get("responsePools", {})),
            },
        ))

    coverage = catalog.get("capabilityCoverage")
    if not isinstance(coverage, list):
        generation = catalog.get("generation", {})
        coverage = generation.get("coverage", []) if isinstance(generation, dict) else []
    for generated in _iter_dicts(coverage):
        generated_id = _text(generated.get("id"))
        if not generated_id:
            continue
        rows.append(_row(
            kind="generated",
            identifier=f"generated:{generated_id}",
            label=generated_id,
            source="PNC.Semantics.AutomaticFlowGenerator.coverage",
            value={
                "definitionID": generated_id,
                "capabilityID": generated.get("capabilityID"),
                "classification": generated.get("classification"),
                "flowID": generated.get("flowID"),
                "reason": generated.get("reason"),
                "missingMetadata": _copy(generated.get("missingMetadata", [])),
            },
        ))

    for pool in _iter_dicts(catalog.get("responsePoolCatalog")):
        pool_id = _text(pool.get("id"))
        if not pool_id:
            continue
        variants = pool.get("variants", [])
        variant_count = pool.get("variantCount")
        if not isinstance(variant_count, int):
            variant_count = len(variants) if isinstance(variants, list) else 0
        rows.append(_row(
            kind="response_pool",
            identifier=f"response_pool:{pool_id}",
            label=pool_id,
            source="production Lua PNC.Semantics.ResponseCatalog",
            value={
                "responsePoolID": pool_id,
                "variantCount": variant_count,
                "contentOwners": _copy(pool.get("contentOwners", [])),
                "followUpOfferCount": pool.get("followUpOfferCount", 0),
                "semanticAuthority": "PNC.Semantics.ResponseCatalog",
                "inspection": "response_pool_detail provides variants, plans, provenance and offers",
                "languages": sorted({
                    language.upper()
                    for variant in _iter_dicts(variants)
                    for language in (
                        variant.get("translations") or {}
                    )
                }),
            },
        ))

    for concept in _iter_dicts(catalog.get("conceptCatalog")):
        concept_id = _text(concept.get("id"))
        if not concept_id:
            continue
        rows.append(_row(
            kind="concept",
            identifier=f"concept:{concept_id}",
            label=concept_id,
            source="PsychopatzCore semantic concept catalog",
            value={"conceptID": concept_id, "owner": concept.get("owner")},
        ))

    for speech_act in catalog.get("speechActCatalog", []):
        speech_act_id = _text(speech_act)
        if not speech_act_id:
            continue
        rows.append(_row(
            kind="speech_act",
            identifier=f"speech_act:{speech_act_id}",
            label=speech_act_id,
            source="PsychopatzCore speech-act catalog",
            value={"speechAct": speech_act_id},
        ))

    return rows


def search_interactions(
    production_catalog: dict[str, Any] | None,
    query: str = "",
    *,
    limit: int = 128,
) -> list[dict[str, Any]]:
    """Search actual interaction rows without inventing runtime definitions."""

    if limit < 1:
        return []
    needle = _text(query).strip().lower()
    rows = build_interaction_rows(production_catalog)
    if needle:
        rows = [
            row for row in rows
            if needle in json.dumps(row, ensure_ascii=False, sort_keys=True).lower()
        ]
    rows.sort(key=lambda row: (_text(row.get("label")).lower(), _text(row.get("id"))))
    return rows[:limit]


def interaction_summary(rows: list[dict[str, Any]]) -> dict[str, int]:
    summary: dict[str, int] = {}
    for row in rows:
        kind = _text(row.get("kind")) or "unknown"
        summary[kind] = summary.get(kind, 0) + 1
    return summary
