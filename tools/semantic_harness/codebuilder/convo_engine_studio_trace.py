"""Core ConvoEngine Semantic Lab index, simulation, and trace helpers.

All Semantic Lab UI operations consume this module through
SemanticLabAuthoringService so Studio never invents a second schema or
compiler/interpreter copy.
"""

from __future__ import annotations

import copy
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .convo_catalog import ConvoCatalog
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
)
from .translation_support import DEFAULT_LANGUAGE
from .workspace_catalog import WorkspaceCatalog, WorkspaceSnapshot


_PLACEHOLDER_RE = re.compile(r"\{([a-z][a-zA-Z0-9_.]*)\}")


KNOWN_ACTION_CONTRACTS: dict[str, dict[str, Any]] = {
    "pnc.companion.camp": {
        "id": "pnc.companion.camp",
        "owner": HOOMANS_OWNER,
        "mode": "request_response",
        "discoveryOnly": False,
        "capability": "companion_command",
        "inputs": {"target": "entity.person", "campSite": "string?"},
        "publicResultSchema": {
            "outcome": ["valid", "invalid", "pending", "rejected", "none"],
            "reasonClass": "string",
            "locationPhrase": "string",
        },
        "authorityPath": "PNC.Client.RequestSemanticTask / TaskRequestService.Submit",
    },
}


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


def _convo_roots(service: Any) -> list[tuple[str, Path]]:
    return _workspace_snapshot(service).source_roots_for()


def list_convo_engine_families(service: Any) -> list[dict[str, Any]]:
    """Return canonical ConvoEngine single-family sources across enabled repositories."""
    catalog = getattr(service, "convo_catalog", None)
    if isinstance(catalog, ConvoCatalog):
        return catalog.list_summaries()
    return ConvoCatalog(_workspace_snapshot(service)).list_summaries()


def list_registered_action_contracts(service: Any) -> list[dict[str, Any]]:
    """List known registered Semantic Action Contracts and any workspace references."""
    contracts: dict[str, dict[str, Any]] = copy.deepcopy(KNOWN_ACTION_CONTRACTS)
    for item in list_convo_engine_families(service):
        action_id = item.get("executeAction")
        if action_id and action_id not in contracts:
            contracts[action_id] = {
                "id": action_id,
                "owner": item.get("owner"),
                "mode": "request_response",
                "discoveryOnly": False,
                "inputs": {},
                "publicResultSchema": {"outcome": "string", "reasonClass": "string"},
                "declaredIn": [item["canonicalID"]],
            }
        elif action_id and action_id in contracts:
            contracts[action_id].setdefault("declaredIn", []).append(item["canonicalID"])
    return [contracts[key] for key in sorted(contracts)]


def _lookup_dotted(mapping: Mapping[str, Any], path: str) -> Any:
    cur: Any = mapping
    for part in path.split("."):
        if isinstance(cur, Mapping) and part in cur:
            cur = cur[part]
        else:
            return None
    return cur


def _render_placeholders(text: str, env: Mapping[str, Any]) -> str:
    def _replace(match: re.Match[str]) -> str:
        key = match.group(1)
        val = _lookup_dotted(env, key)
        if val is None and key.startswith("slot."):
            slot_short = key[len("slot."):]
            val = _lookup_dotted(env.get("slot") or {}, slot_short)
        return str(val) if val is not None else match.group(0)

    return _PLACEHOLDER_RE.sub(_replace, str(text or ""))


def _evaluate_predicate(predicate: Any, env: Mapping[str, Any]) -> bool:
    if predicate is None:
        return True
    if not isinstance(predicate, Mapping):
        return False
    if "all" in predicate:
        return all(_evaluate_predicate(child, env) for child in (predicate["all"] or []))
    if "any" in predicate:
        return any(_evaluate_predicate(child, env) for child in (predicate["any"] or []))
    if "not" in predicate:
        return not _evaluate_predicate(predicate["not"], env)
    op = str(predicate.get("op") or "exists")
    path = str(predicate.get("path", predicate.get("field", "")))
    actual = _lookup_dotted(env, path)
    if actual is None and path.startswith("result."):
        actual = _lookup_dotted(env.get("result") or {}, path[len("result."):])
    expected = predicate.get("value")
    if op == "exists":
        return actual is not None
    if op == "truthy":
        return bool(actual)
    if op == "eq":
        return actual == expected
    if op == "neq":
        return actual != expected
    if op == "in":
        return actual in (predicate.get("values") or [])
    if op in {"gt", "gte", "lt", "lte"}:
        if actual is None or expected is None:
            return False
        try:
            a, b = float(actual), float(expected)
        except (TypeError, ValueError):
            return False
        if op == "gt":
            return a > b
        if op == "gte":
            return a >= b
        if op == "lt":
            return a < b
        return a <= b
    return False


def _pick_realization_text(
    say_projection: Mapping[str, Any] | None,
    *,
    realization_key: str | None,
    style: str,
    locale: str,
    env: Mapping[str, Any],
) -> dict[str, Any] | None:
    if not isinstance(say_projection, Mapping):
        return None
    realizations = say_projection.get("realizations") or {}
    key_order = say_projection.get("keyOrder") or list(realizations)
    selected_key = realization_key if realization_key in realizations else (key_order[0] if key_order else None)
    if selected_key is None:
        return None
    entry = realizations[selected_key]
    variants = entry.get("variants") or []
    chosen = next(
        (v for v in variants if v.get("id") == style and _evaluate_predicate(v.get("when"), env)),
        None,
    )
    if chosen is None:
        chosen = next((v for v in variants if _evaluate_predicate(v.get("when"), env)), None)
    if chosen is None and variants:
        chosen = variants[0]
    if chosen is None:
        return None
    translations = chosen.get("text") or {}
    lines = translations.get(locale) or translations.get(DEFAULT_LANGUAGE) or []
    raw_line = lines[0] if lines else ""
    return {
        "realizationKey": selected_key,
        "variantID": chosen.get("id"),
        "templateID": chosen.get("templateID"),
        "textRole": say_projection.get("textRole"),
        "locale": locale if locale in translations else DEFAULT_LANGUAGE,
        "rawText": raw_line,
        "renderedText": _render_placeholders(raw_line, env),
    }


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
    """Compile and deterministically simulate a ConvoEngine family end-to-end."""
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
    exchange = plan.get("exchangeFamily") or {}
    payload = plan.get("payload") or {}
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

    # Evaluate affordance button preview strictly separately from initiating speech.
    aff_proj = exchange.get("affordance")
    button_preview: dict[str, Any] | None = None
    if isinstance(aff_proj, Mapping):
        translations = aff_proj.get("translations") or {}
        lines = translations.get(locale) or translations.get(DEFAULT_LANGUAGE) or [aff_proj.get("labelFallback", "")]
        button_preview = {
            "textRole": aff_proj.get("textRole"),
            "labelKey": aff_proj.get("labelKey"),
            "consumers": aff_proj.get("consumers", []),
            "renderedLabel": _render_placeholders(lines[0] if lines else "", env),
        }

    initiating_speech = _pick_realization_text(
        exchange.get("initiatingSay"),
        realization_key=realization_key,
        style=style,
        locale=locale,
        env=env,
    )

    execute_spec = exchange.get("execute")
    execute_trace: dict[str, Any] | None = None
    if isinstance(execute_spec, Mapping):
        action_id = execute_spec.get("use") or execute_spec.get("action")
        contract = KNOWN_ACTION_CONTRACTS.get(str(action_id or ""), {})
        resolved_inputs = {
            k: (_lookup_dotted(env, str(v)[1:]) if isinstance(v, str) and str(v).startswith("$") else v)
            for k, v in (execute_spec.get("with") or {}).items()
        }
        execute_trace = {
            "action": action_id,
            "mode": execute_spec.get("mode") or contract.get("mode", "sync"),
            "resolvedWith": resolved_inputs,
            "discoveryOnly": bool(contract.get("discoveryOnly", False)),
            "publicResult": copy.deepcopy(result_env),
            "authorityPath": contract.get("authorityPath"),
        }
        if not result_env.get("outcome"):
            # Pick first available reply outcome for deterministic trace when caller didn't override.
            replies_keys = sorted((exchange.get("replies") or {}).keys())
            if replies_keys:
                result_env["outcome"] = replies_keys[0]
                execute_trace["publicResult"] = copy.deepcopy(result_env)

    # Select reply outcome by predicate match first (result.outcome / result.reasonClass),
    # then explicit outcome name, then deterministic first branch fallback.
    replies = exchange.get("replies") or {}
    selected_reply_name: str | None = None
    selected_reply_branch: Mapping[str, Any] | None = None
    desired_outcome = result_outcome or result_env.get("outcome")
    for outcome_name, branch in replies.items():
        if branch.get("when") is not None and _evaluate_predicate(branch.get("when"), env):
            selected_reply_name = outcome_name
            selected_reply_branch = branch
            break
    if selected_reply_branch is None and desired_outcome and desired_outcome in replies:
        selected_reply_name = str(desired_outcome)
        selected_reply_branch = replies[selected_reply_name]
    if selected_reply_branch is None and replies:
        for outcome_name, branch in replies.items():
            if _evaluate_predicate(branch.get("when"), env):
                selected_reply_name = outcome_name
                selected_reply_branch = branch
                break
        if selected_reply_branch is None:
            selected_reply_name = sorted(replies)[0]
            selected_reply_branch = replies[selected_reply_name]

    reply_speech: dict[str, Any] | None = None
    if isinstance(selected_reply_branch, Mapping):
        if isinstance(selected_reply_branch.get("say"), Mapping):
            reply_speech = _pick_realization_text(
                selected_reply_branch["say"],
                realization_key=None,
                style=style,
                locale=locale,
                env=env,
            )
        elif isinstance(selected_reply_branch.get("variants"), list) and selected_reply_branch["variants"]:
            v = next(
                (item for item in selected_reply_branch["variants"] if item.get("id") == style),
                selected_reply_branch["variants"][0],
            )
            trans = v.get("text") or {}
            lines = trans.get(locale) or trans.get(DEFAULT_LANGUAGE) or []
            reply_speech = {
                "variantID": v.get("id"),
                "textRole": selected_reply_branch.get("textRole"),
                "rawText": lines[0] if lines else "",
                "renderedText": _render_placeholders(lines[0] if lines else "", env),
            }

    predicate_passed = _evaluate_predicate(plan.get("when"), env)
    after_branch = (
        selected_reply_branch.get("after")
        if isinstance(selected_reply_branch, Mapping) and "after" in selected_reply_branch
        else exchange.get("after")
    )

    trace = [
        {"stage": "predicate", "passed": predicate_passed, "when": plan.get("when")},
        {"stage": "affordance", "button": button_preview},
        {"stage": "invoke", "invoke": exchange.get("invoke")},
        {"stage": "speech", "speaker": speaker, "say": initiating_speech},
        {"stage": "execute", "action": execute_trace},
        {"stage": "result", "publicResult": copy.deepcopy(result_env)},
        {"stage": "reply", "speaker": addressee, "outcome": selected_reply_name, "say": reply_speech},
        {"stage": "after", "after": after_branch},
    ]

    return {
        "ok": True,
        "previewOnly": True,
        "effectFree": True,
        "familyID": plan.get("id"),
        "kind": plan.get("kind"),
        "owner": plan.get("owner"),
        "compiledFingerprint": validation["compiled"]["fingerprint"],
        "diagnostics": validation.get("diagnostics", []),
        "previewContext": {
            "speaker": speaker,
            "addressee": addressee,
            "target": target,
            "style": style,
            "locale": locale,
            "slots": dict(slot_values or {}),
            "result": result_env,
        },
        "buttonPreview": button_preview,
        "initiatingSpeechPreview": initiating_speech,
        "executePreview": execute_trace,
        "replyPreview": {
            "outcome": selected_reply_name,
            "speech": reply_speech,
        },
        "afterPreview": after_branch,
        "textRoles": plan.get("textRoles", []),
        "beatBehaviorPreview": {
            "group": payload.get("group"),
            "candidates": payload.get("candidates"),
            "entry": payload.get("entry"),
            "maintain": payload.get("maintain"),
            "exit": payload.get("exit"),
        } if plan.get("kind") in {"beat", "behavior"} else None,
        "trace": trace,
    }
