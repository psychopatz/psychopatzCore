"""G8R7B: Versioned normalized semantic trace contract for Reference VM <-> Lua/PZ equivalence."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from .convo_probe import ConvoProbe
from .portable_runtime import PortableReferenceVM, evaluate_predicate

SEMANTIC_TRACE_SCHEMA = "psychopatz.psdl.semantic-trace.v1"


def confidence_bucket(confidence: float | None) -> str | None:
    if confidence is None:
        return None
    val = float(confidence)
    if val >= 0.999:
        return "exact"
    if val >= 0.85:
        return "high"
    if val >= 0.70:
        return "medium"
    return "low"


def trace_from_reference_vm(
    vm: PortableReferenceVM,
    *,
    utterance: str = "",
    context: Mapping[str, Any] | None = None,
    dialogue_id: str | None = None,
    result_outcome: str | None = None,
    locale: str = "EN",
    style: str = "neutral",
) -> dict[str, Any]:
    """Execute one turn on PortableReferenceVM and project to normalized trace."""
    step_res = vm.step(
        utterance=utterance,
        context=context,
        locale=locale,
        style=style,
    )
    recog = step_res.get("recognition")
    norm_recog = None
    if isinstance(recog, Mapping):
        norm_recog = {
            "ruleID": recog.get("ruleID"),
            "dialogueID": recog.get("dialogueID"),
            "mode": recog.get("mode"),
            "confidenceBucket": confidence_bucket(recog.get("confidence")),
            "requiresConfirmation": bool(recog.get("requiresConfirmation", False)),
            "semantic": dict(recog.get("semantic") or {}),
        }

    selected_dialogue = dialogue_id or step_res.get("selectedDialogue") or (
        recog.get("dialogueID") if isinstance(recog, Mapping) else None
    )
    dlg = (vm.plan.get("dialogues") or {}).get(selected_dialogue or "") or {}
    action_spec = dlg.get("action")
    action_id = (
        action_spec.get("capability")
        if isinstance(action_spec, Mapping)
        else (action_spec if isinstance(action_spec, str) else None)
    )

    reply_branch = None
    reply_template_id = None
    if result_outcome and isinstance(dlg.get("reply"), Mapping):
        branch = dlg["reply"].get(result_outcome)
        if isinstance(branch, Mapping):
            reply_branch = result_outcome
            say = branch.get("say")
            if isinstance(say, Mapping):
                realizations = say.get("realizations")
                if isinstance(realizations, Mapping) and realizations:
                    first_key = (say.get("keyOrder") or sorted(realizations))[0]
                    variants = (realizations.get(first_key) or {}).get("variants") or []
                    chosen = next((v for v in variants if v.get("id") == style), variants[0] if variants else None)
                    vid = chosen.get("id") if isinstance(chosen, Mapping) else "default"
                    reply_template_id = f"convo.{selected_dialogue}.reply.{result_outcome}.say.{first_key}.{vid}"
                else:
                    reply_template_id = f"convo.{selected_dialogue}.reply.{result_outcome}.say.1.default"

    return {
        "schema": SEMANTIC_TRACE_SCHEMA,
        "runtime": "reference_vm",
        "recognition": norm_recog,
        "activeBeat": step_res.get("activeBeat"),
        "selectedBehavior": step_res.get("selectedBehavior"),
        "selectedDialogue": selected_dialogue,
        "action": action_id,
        "resultOutcome": reply_branch,
        "replyTemplateID": reply_template_id,
    }


def trace_from_lua_probe(
    probe: ConvoProbe,
    *,
    portable_plan: Mapping[str, Any],
    runtime_plans_by_id: Mapping[str, Mapping[str, Any]],
    utterance: str = "",
    context: Mapping[str, Any] | None = None,
    dialogue_id: str | None = None,
    result_outcome: str | None = None,
    locale: str = "EN",
    style: str = "neutral",
    recognition_policy: str | None = None,
) -> dict[str, Any]:
    """Execute beat/behavior predicates and dialogue/reply simulation in live Lua ConvoProbe."""
    ctx = dict(context or {})

    # 1. Recognition using the portable plan's rules (confidence/confirmation semantics)
    vm_recog = PortableReferenceVM(portable_plan).recognize(utterance, policy=recognition_policy) if utterance else None
    norm_recog = None
    if isinstance(vm_recog, Mapping):
        norm_recog = {
            "ruleID": vm_recog.get("ruleID"),
            "dialogueID": vm_recog.get("dialogueID"),
            "mode": vm_recog.get("mode"),
            "confidenceBucket": confidence_bucket(vm_recog.get("confidence")),
            "requiresConfirmation": bool(vm_recog.get("requiresConfirmation", False)),
            "semantic": dict(vm_recog.get("semantic") or {}),
        }
        ctx.setdefault("stimulus", {})
        if isinstance(ctx["stimulus"], dict):
            ctx["stimulus"].setdefault("semantic", {})
            if isinstance(ctx["stimulus"]["semantic"], dict):
                ctx["stimulus"]["semantic"].update(vm_recog.get("semantic") or {})

    # 2. Evaluate beat entry and behavior `when` predicates inside Lua ConvoProbe
    active_beat: str | None = None
    best_beat_score = -1e9
    for bid, beat in sorted((portable_plan.get("beats") or {}).items()):
        entry_pred = beat.get("entry")
        if entry_pred and probe.evaluate_predicate(entry_pred, ctx).get("allowed"):
            score = float(beat.get("baseRelevance") or 0.0)
            if score > best_beat_score:
                best_beat_score = score
                active_beat = bid

    selected_behavior: str | None = None
    best_beh_score = -1e9
    behaviors = portable_plan.get("behaviors") or {}
    if active_beat:
        cand_pairs = [
            (str(c["behavior"]), float(c.get("relevance") or 0.0))
            for c in ((portable_plan.get("beats") or {})[active_beat].get("candidates") or [])
        ]
    else:
        cand_pairs = [(bid, float(b.get("baseRelevance") or 0.0)) for bid, b in sorted(behaviors.items())]

    for beh_id, base_rel in cand_pairs:
        beh = behaviors.get(beh_id)
        if not beh:
            continue
        when_pred = beh.get("when")
        if when_pred is not None and not probe.evaluate_predicate(when_pred, ctx).get("allowed"):
            continue
        score = base_rel
        for mod in beh.get("modifiers") or []:
            if mod.get("when") and probe.evaluate_predicate(mod["when"], ctx).get("allowed"):
                score += float(mod.get("delta") or 0.0)
        if score > best_beh_score:
            best_beh_score = score
            selected_behavior = beh_id

    # 3. Simulate dialogue/action/reply-branch in Lua ConvoProbe
    target_dlg_id = dialogue_id
    if target_dlg_id is None and selected_behavior and selected_behavior in behaviors:
        beh_outputs = behaviors[selected_behavior].get("outputs") or {}
        speech_out = beh_outputs.get("speech") if isinstance(beh_outputs, Mapping) else None
        if isinstance(speech_out, Mapping) and speech_out.get("contentTemplateID"):
            target_dlg_id = str(speech_out["contentTemplateID"])
    if target_dlg_id is None and isinstance(vm_recog, Mapping):
        target_dlg_id = vm_recog.get("dialogueID")
    action_id = None
    reply_branch = None
    reply_template_id = None
    if target_dlg_id and target_dlg_id in runtime_plans_by_id:
        sim_ctx = {
            **ctx,
            "speaker": "player",
            "addressee": "npc",
            "result": {"outcome": result_outcome} if result_outcome else {},
        }
        sim = probe.simulate_exchange(
            dict(runtime_plans_by_id[target_dlg_id]),
            context=sim_ctx,
            options={"language": locale, "locale": locale, "style": style, "outcome": result_outcome},
        )
        dlg_spec = (portable_plan.get("dialogues") or {}).get(target_dlg_id) or {}
        act_spec = dlg_spec.get("action")
        action_id = (
            act_spec.get("capability")
            if isinstance(act_spec, Mapping)
            else (act_spec if isinstance(act_spec, str) else None)
        )
        reply_preview = sim.get("replyPreview")
        if isinstance(reply_preview, Mapping):
            reply_branch = reply_preview.get("outcome")
            speech = reply_preview.get("speech")
            if isinstance(speech, Mapping):
                reply_template_id = speech.get("templateID")

    return {
        "schema": SEMANTIC_TRACE_SCHEMA,
        "runtime": "lua_convo_probe",
        "recognition": norm_recog,
        "activeBeat": active_beat,
        "selectedBehavior": selected_behavior,
        "selectedDialogue": target_dlg_id,
        "action": action_id,
        "resultOutcome": reply_branch,
        "replyTemplateID": reply_template_id,
    }


def normalized_trace_comparison_key(trace: Mapping[str, Any]) -> dict[str, Any]:
    """Return runtime-neutral comparison projection of a semantic trace."""
    return {
        "schema": trace.get("schema"),
        "recognition": trace.get("recognition"),
        "activeBeat": trace.get("activeBeat"),
        "selectedBehavior": trace.get("selectedBehavior"),
        "selectedDialogue": trace.get("selectedDialogue"),
        "action": trace.get("action"),
        "resultOutcome": trace.get("resultOutcome"),
        "replyTemplateID": trace.get("replyTemplateID"),
    }


__all__ = [
    "SEMANTIC_TRACE_SCHEMA",
    "confidence_bucket",
    "normalized_trace_comparison_key",
    "trace_from_lua_probe",
    "trace_from_reference_vm",
]
