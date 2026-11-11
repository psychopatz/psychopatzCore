"""Human-readable, bounded presentation of production dialogue-director evidence."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty


MAX_BEAT_TIMELINE = 64


def _id(value: Any) -> str:
    return str(value or "—")


def interaction_summary(observation: dict[str, Any]) -> str:
    director = observation.get("director")
    if not isinstance(director, dict) or not director:
        return "No dialogue-director evidence on this turn."

    lines = ["PRAGMATIC INTERACTION DIRECTOR", ""]
    stimulus = director.get("stimulus") or {}
    stimulus_source = stimulus.get("source") or {}
    pragmatic = director.get("pragmatic") or {}
    semantic = pragmatic.get("semantic") or {}
    providers = pragmatic.get("providers") or {}
    reply_to = pragmatic.get("replyTo") or {}
    admission = pragmatic.get("contextualAdmission") or {}
    evidence = pragmatic.get("evidence") or {}
    lines.extend(
        [
            "Typed stimulus",
            f"  type: {_id(stimulus.get('type'))}",
            f"  source: {_id(stimulus_source.get('kind'))}"
            f" / {_id(stimulus_source.get('providerID'))}",
            f"  source actor: {_id(stimulus_source.get('actorID'))}",
            f"  targets: {_id(', '.join(stimulus.get('targets') or []))}",
            "",
            "Pragmatic interpretation",
            f"  intent: {_id(semantic.get('intent'))}",
            f"  speech act: {_id(semantic.get('speechAct'))}",
            f"  topic: {_id(pragmatic.get('topic'))}"
            f" ({_id(pragmatic.get('topicSource'))})",
            f"  subject: {_id(pragmatic.get('subject'))}"
            f" ({_id(pragmatic.get('subjectSource'))})",
            f"  reply-to: {_id(reply_to.get('kind'))}"
            f" {_id(reply_to.get('flowID') or reply_to.get('actorID'))}",
            f"  hostility count: {_id(pragmatic.get('hostilityCount'))}",
            f"  first contact: {_id(pragmatic.get('firstContact'))}",
            f"  immediate danger: {_id(pragmatic.get('immediateDanger'))}",
            "",
            "Provider provenance",
            f"  actor: {_id(providers.get('actor'))}",
            f"  relationship: {_id(providers.get('relationship'))}",
            f"  world: {_id(providers.get('world'))}",
            f"  knowledge: {_id(providers.get('knowledge'))}",
            "",
        ]
    )
    lines.extend(["", "Semantic evidence",
        f"  contextual admission: {_id(admission.get('status'))} / {_id(admission.get('reason'))}",
        f"  rows: {len(evidence.get('rows') or [])}/{evidence.get('limit', 16)}; matched: {evidence.get('matched', 0)}; truncated: {evidence.get('truncated', False)}"])
    candidates = {row.get("sourceRef"): row for row in admission.get("candidates", [])[:8]
                  if isinstance(row, dict)}
    def metric(value: Any) -> str:
        return "—" if value is None else str(value)
    for row in (evidence.get("rows") or [])[:16]:
        if not isinstance(row, dict):
            continue
        derived = candidates.get(row.get("sourceRef"), {})
        lines.extend([
            f"  [{_id(row.get('sourceTier'))}] {_id(row.get('providerID'))}: {_id(row.get('sourceRef'))}",
            f"    semantic relations: {row.get('relations') or {}}",
            f"    retention salience: {metric(row.get('retentionSalience'))}; confidence: {metric(row.get('confidence'))}",
            f"    effective strength: {metric(row.get('effectiveStrength'))}; recency hours: {metric(row.get('ageHours'))}",
            f"    contextual relevance: {metric(derived.get('contextualRelevance'))}; priority: {metric(derived.get('priority'))}",
        ])
    before = director.get("activeBefore") or {}
    after = director.get("activeAfter") or {}
    entered = director.get("entered") or {}
    exited = director.get("exited") or {}
    lines.extend(
        [
            "Beat transition",
            f"  active before: {_id(before.get('id'))}",
            f"  exited: {_id(exited.get('id'))}  {_id(exited.get('reason'))}",
            f"  entered: {_id(entered.get('id'))}  {_id(entered.get('reason'))}",
            f"  active after: {_id(after.get('id'))}",
            "",
            "Beat candidates",
        ]
    )
    for row in director.get("beatCandidates") or []:
        if not isinstance(row, dict):
            continue
        mark = "✓" if row.get("eligible") else "·"
        lines.append(
            f"  {mark} {_id(row.get('id'))}: "
            f"{_id(row.get('status'))} score={row.get('score', 0)} "
            f"reason={_id(row.get('reason'))}"
        )
        trace = (row.get("predicateTrace") or {}).get("rows") or []
        failed = [
            item for item in trace
            if isinstance(item, dict) and item.get("passed") is False
            and item.get("path")
        ]
        for item in failed[:3]:
            lines.append(
                "      failed: "
                f"{item.get('path')} {item.get('op')} "
                f"{item.get('expected')} (actual {item.get('actual')})"
            )

    selected = director.get("selectedBehavior") or {}
    lines.extend(["", "Behavior candidates"])
    for row in director.get("behaviorCandidates") or []:
        if not isinstance(row, dict):
            continue
        winner = "WIN" if row.get("id") == selected.get("id") else "   "
        eligibility = "eligible" if row.get("eligible") else "ineligible"
        lines.append(
            f"  {winner} {_id(row.get('id'))}: "
            f"{eligibility} score={row.get('score', 0)}"
        )
        for modifier in row.get("modifiers") or []:
            if isinstance(modifier, dict) and modifier.get("matched"):
                lines.append(
                    f"      {modifier.get('reason')}: "
                    f"{modifier.get('delta'):+g}"
                )

    response = observation.get("response") or {}
    interaction_plan = observation.get("interactionPlan") or {}
    outputs = interaction_plan.get("outputs") or {}
    metrics = director.get("metrics") or {}
    lod = (
        "player/full"
        if stimulus.get("type") == "HUMAN_UTTERANCE"
        else "semantic-preview"
    )
    lines.extend(
        [
            "",
            "Selected result",
            f"  behavior source: {_id(director.get('behaviorSource'))}",
            f"  beat: {_id((director.get('selectedBeat') or {}).get('id'))}",
            f"  behavior: {_id(selected.get('id'))}",
            f"  behavior act: {_id(interaction_plan.get('behaviorAct'))}",
            f"  interaction act: {_id(interaction_plan.get('dialogueAct'))}",
            f"  output adapters: {_id(', '.join(sorted(outputs)))}",
            f"  content: {_id(interaction_plan.get('contentTemplateID'))}",
            f"  simulation LOD: {lod}",
            f"  response pool: {_id(response.get('sourcePoolID'))}",
            f"  response-plan act: {_id(response.get('dialogueAct'))}",
            f"  response: {_id(response.get('text') or response.get('fallback'))}",
            "",
            "Bounded evaluation",
            f"  catalog beats: {_id(metrics.get('catalogBeatCount'))}",
            f"  indexed beats: {_id(metrics.get('indexedBeatCandidateCount'))}",
            f"  evaluated beats: {_id(metrics.get('beatCandidatesEvaluated'))}",
            f"  indexed one-shots: "
            f"{_id(metrics.get('indexedOneShotBehaviorCount'))}",
            f"  evaluated one-shots: "
            f"{_id(metrics.get('oneShotBehaviorCandidatesEvaluated'))}",
            f"  predicate trace rows: {_id(metrics.get('predicateTraceRows'))}",
        ]
    )
    override = director.get("override")
    if override:
        lines.extend(["", f"HARNESS_OVERRIDE: {pretty(override).strip()}"])
    return "\n".join(lines)


def interaction_timeline_record(response: dict[str, Any]) -> dict[str, Any]:
    observation = response.get("observation")
    observation = observation if isinstance(observation, dict) else {}
    director = observation.get("director")
    director = director if isinstance(director, dict) else {}
    flow = observation.get("flow")
    flow = flow if isinstance(flow, dict) else {}
    ir = observation.get("ir")
    ir = ir if isinstance(ir, dict) else {}
    selected = director.get("selectedBehavior") or {}
    active = director.get("activeAfter") or {}
    entered = director.get("entered") or {}
    exited = director.get("exited") or {}
    visible = observation.get("response") or {}
    return {
        "sequence": response.get("result", {}).get("sequence"),
        "input": response.get("input"),
        "intent": ir.get("intent"),
        "speechAct": ir.get("speechAct"),
        "stimulus": (director.get("stimulus") or {}).get("type"),
        "behaviorSource": director.get("behaviorSource"),
        "flow": (flow.get("activeAfter") or [{}])[0].get("flowId")
        if isinstance(flow.get("activeAfter"), list) and flow.get("activeAfter")
        else None,
        "beat": active.get("id"),
        "entered": entered.get("id"),
        "exited": exited.get("id"),
        "behavior": selected.get("id"),
        "response": visible.get("text") or visible.get("fallback"),
        "evidence": deepcopy(
            {
                "ir": ir,
                "flow": flow,
                "director": director,
                "stimulus": director.get("stimulus"),
                "pragmatic": director.get("pragmatic"),
                "metrics": director.get("metrics"),
                "interactionPlan": observation.get("interactionPlan"),
                "response": visible,
                "sideEffects": observation.get("sideEffects"),
                "actionResult": observation.get("actionResult"),
            }
        ),
    }


def update_interaction_inspector(app: Any, response: dict[str, Any]) -> None:
    observation = response.get("observation")
    observation = observation if isinstance(observation, dict) else {}
    app._set_text(app.interaction_inspector_text, interaction_summary(observation))

    record = interaction_timeline_record(response)
    if (
        record.get("sequence") is None
        and not record.get("beat")
        and not record.get("behavior")
    ):
        return
    timeline = getattr(app, "beat_interaction_timeline_records", None)
    if not isinstance(timeline, list):
        timeline = []
        app.beat_interaction_timeline_records = timeline
    timeline.append(record)
    if len(timeline) > MAX_BEAT_TIMELINE:
        del timeline[: len(timeline) - MAX_BEAT_TIMELINE]

    tree = app.interaction_timeline_tree
    for item in tree.get_children():
        tree.delete(item)
    for index, row in enumerate(timeline):
        transition = " / ".join(
            part for part in (
                f"+{row.get('entered')}" if row.get("entered") else "",
                f"-{row.get('exited')}" if row.get("exited") else "",
            )
            if part
        )
        tree.insert(
            "",
            "end",
            iid=str(index),
            text=str(row.get("sequence") or index + 1),
            values=(
                _id(row.get("stimulus")),
                _id(row.get("intent")),
                _id(row.get("flow")),
                _id(row.get("beat")),
                transition or "—",
                _id(row.get("behavior")),
                _id(row.get("behaviorSource")),
            ),
        )
    if timeline:
        last = str(len(timeline) - 1)
        tree.selection_set(last)
        tree.see(last)
        app._set_text(
            app.interaction_turn_details,
            pretty(timeline[-1]["evidence"]),
        )


def show_selected_interaction_timeline_turn(app: Any) -> None:
    selection = app.interaction_timeline_tree.selection()
    if not selection:
        return
    try:
        index = int(selection[0])
        record = app.beat_interaction_timeline_records[index]
    except (ValueError, IndexError, AttributeError):
        return
    app._set_text(app.interaction_turn_details, pretty(record["evidence"]))


__all__ = [
    "MAX_BEAT_TIMELINE",
    "interaction_summary",
    "show_selected_interaction_timeline_turn",
    "interaction_timeline_record",
    "update_interaction_inspector",
]
