"""R9C: Safe structural scaffolding driven by canonical completeness diagnostics.

Scaffolds only structural fields/slots (with explicit TODO placeholders) and
never fabricates final dialogue prose or hand-edits generated Lua output.
"""

from __future__ import annotations

import copy
from typing import Any, Mapping


SCAFFOLD_KINDS: tuple[str, ...] = (
    "reply_outcome",
    "closure",
    "pending_exit",
    "repeat_policy",
    "poststate_guard",
    "closure_residue",
    "fixture_stub",
)

DIAGNOSTIC_TO_SCAFFOLD: dict[str, str] = {
    "unhandled_state_outcome": "reply_outcome",
    "unhandled_action_outcome": "reply_outcome",
    "dead_end": "closure",
    "pending_without_exit": "pending_exit",
    "unbounded_loop": "repeat_policy",
    "missing_repeat_policy": "repeat_policy",
    "stale_poststate_risk": "poststate_guard",
    "dangling_memory": "closure_residue",
    "lost_commitment": "closure_residue",
    "uncovered_fixture": "fixture_stub",
}


def suggest_scaffold_kind(diagnostic_code: str) -> str:
    """Map a completeness diagnostic code to its structural scaffold kind."""
    return DIAGNOSTIC_TO_SCAFFOLD.get(str(diagnostic_code or "").strip(), "closure")


def build_structural_scaffold_patch(
    document: Mapping[str, Any],
    *,
    scaffold_kind: str,
    family_id: str,
    outcome_name: str | None = None,
    closure_class: str | None = None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Return ``(patch, metadata)`` for a structural scaffold without prose invention."""
    local_id = str(document.get("id") or family_id.rsplit(".", 1)[-1] or "family")
    patch: dict[str, Any] = {}
    summary: dict[str, Any] = {"scaffoldKind": scaffold_kind, "familyId": family_id}

    if scaffold_kind == "reply_outcome":
        target_outcome = str(outcome_name or "accepted").strip() or "accepted"
        reply = copy.deepcopy(dict(document.get("reply") or {}))
        if target_outcome not in reply:
            reply[target_outcome] = {
                "say": f"TODO: {target_outcome} spoken realization",
            }
        patch["reply"] = reply
        summary["addedReplyOutcome"] = target_outcome
    elif scaffold_kind == "closure":
        chosen_class = str(closure_class or "resolved_episode").strip() or "resolved_episode"
        if chosen_class == "open_domain_obligation":
            patch["closure"] = {
                "closureClass": "open_domain_obligation",
                "obligationRef": f"TODO:{local_id}",
            }
        elif chosen_class == "bounded_pending":
            patch["after"] = {"end": True}
        else:
            patch["closure"] = {
                "closureClass": "resolved_episode",
                "episodeId": f"ep_{local_id}",
            }
        if not document.get("after"):
            patch["after"] = {"end": True}
        summary["closureClass"] = chosen_class
    elif scaffold_kind == "pending_exit":
        reply = copy.deepcopy(dict(document.get("reply") or {}))
        if "pending_exit" not in reply:
            reply["pending_exit"] = {
                "say": "TODO: bounded pending exit realization",
                "after": {"end": True},
            }
        patch["reply"] = reply
        if not document.get("after"):
            patch["after"] = {"end": True}
        summary["addedReplyOutcome"] = "pending_exit"
    elif scaffold_kind == "repeat_policy":
        patch["repeatPolicy"] = "state_retired"
        summary["repeatPolicy"] = "state_retired"
    elif scaffold_kind == "poststate_guard":
        postconditions = list(document.get("postconditions") or ())
        if not postconditions:
            postconditions.append(f"TODO.{local_id}.completed")
        patch["postconditions"] = postconditions
        if not document.get("statePolicy"):
            patch["statePolicy"] = [
                {
                    "id": "ready",
                    "outcome": "actionable",
                    "reason": "ready",
                    "admission": "dispatch",
                }
            ]
        summary["addedPostconditions"] = postconditions
    elif scaffold_kind == "closure_residue":
        closure = copy.deepcopy(dict(document.get("closure") or {}))
        cclass = str(closure.get("closureClass") or closure_class or "resolved_episode")
        closure["closureClass"] = cclass
        if cclass == "open_domain_obligation" and not closure.get("obligationRef"):
            closure["obligationRef"] = f"TODO:{local_id}"
        elif cclass == "resolved_episode" and not closure.get("episodeId"):
            closure["episodeId"] = f"ep_{local_id}"
        patch["closure"] = closure
        summary["closureClass"] = cclass
    elif scaffold_kind == "fixture_stub":
        summary["fixtureStub"] = {
            "id": f"TODO_{local_id}_completeness",
            "familyId": family_id,
            "auditClaims": [f"TODO.{family_id}.claim"],
            "turns": [{"input": "TODO: user input", "expect": {"familyId": family_id}}],
        }
    else:
        raise ValueError(f"Unsupported structural scaffold kind: {scaffold_kind!r}")

    return patch, summary
