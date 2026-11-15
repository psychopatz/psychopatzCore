"""Pure suggestion and diagnostic projections used by the Tk shell."""

from __future__ import annotations

from collections.abc import Mapping
from copy import deepcopy
from typing import Any

def npc_message_text(message: dict[str, Any]) -> str:
    """Return rendered production text before its English fallback."""

    direct = message.get("text")
    if isinstance(direct, str) and direct:
        return direct
    payload = message.get("payload") or message.get("value") or {}
    if isinstance(payload, str):
        return payload
    return str(payload.get("text") or payload.get("fallback") or "")


def semantic_suggestion_rows(
    suggestions: dict[str, Any],
    group_id: str | None = None,
    *,
    use_global_candidates: bool = False,
) -> list[dict[str, Any]]:
    """Build the bounded visual slice from the production projection."""

    # Production Lua owns the privacy/performance bound. The Tk adapter must
    # render every row in the selected group, including capability rows, so
    # the old five-slot prototype cannot silently discard safe choices.
    groups = suggestions.get("groups") or []
    selected = None
    if groups and not use_global_candidates:
        requested = group_id or suggestions.get("currentGroupID")
        selected = next(
            (group for group in groups if group.get("id") == requested),
            None,
        )
        if selected is None:
            selected = groups[0]
    candidates = (
        selected.get("candidates") if selected is not None
        else suggestions.get("candidates")
    ) or []
    capabilities = (
        selected.get("capabilities") if selected is not None
        else suggestions.get("permittedCapabilities")
    ) or []
    rows: list[dict[str, Any]] = []
    for navigation in (
        selected.get("navigation") if selected is not None else []
    ) or []:
        rows.append(
            {
                "id": navigation.get("id"),
                "frame": navigation.get("frame"),
                "display": navigation.get("display") or {},
                "status": "navigation",
                "enabled": True,
                "source": navigation.get("source"),
                "groupID": selected.get("id") if selected else None,
            }
        )
    for candidate in candidates:
        rows.append(
            {
                "id": candidate.get("id"),
                "frame": candidate.get("frame"),
                "display": candidate.get("display") or {},
                "status": "eligible",
                "enabled": candidate.get("enabled", True) is not False,
                "eligibility": candidate.get("eligibility"),
                "source": candidate.get("source"),
                "groupID": selected.get("id") if selected else candidate.get("groupID"),
            }
        )
    for capability in capabilities:
        status = capability.get("status") or "unavailable_unknown"
        rows.append(
            {
                "id": capability.get("id"),
                "action": capability.get("action"),
                "frame": capability.get("frame"),
                "display": capability.get("display") or {},
                "status": status,
                "enabled": status in {"eligible", "selected_for_preflight"},
                "source": capability.get("source"),
                "eligibility": capability.get("eligibility"),
                "groupID": selected.get("id") if selected else capability.get("groupID"),
            }
        )
    return rows


def is_navigation_frame(frame: Any) -> bool:
    """Return True only when ``frame`` is a navigation-only affordance."""
    if not isinstance(frame, dict):
        return False
    return bool(frame.get("navigationExchange") is True) or str(
        frame.get("kind") or ""
    ) in {
        "semantic_back_click_frame",
        "semantic_group_click_frame",
    }


def resolve_initiating_say(
    row: Mapping[str, Any] | dict[str, Any] | None,
    frame: Mapping[str, Any] | dict[str, Any] | None = None,
    response: Mapping[str, Any] | dict[str, Any] | None = None,
) -> str | None:
    """Resolve explicit initiating speech without ever falling back to UI labels."""
    row_dict = row if isinstance(row, Mapping) else {}
    frame_dict = frame if isinstance(frame, Mapping) else {}
    display = row_dict.get("display")
    display_dict = display if isinstance(display, Mapping) else {}
    resp_dict = response if isinstance(response, Mapping) else {}
    result = resp_dict.get("result")
    result_dict = result if isinstance(result, Mapping) else {}
    ir = result_dict.get("ir") or resp_dict.get("ir")
    ir_dict = ir if isinstance(ir, Mapping) else {}
    for candidate in (
        resp_dict.get("playerUtterance"),
        ir_dict.get("rawText"),
        display_dict.get("utterance"),
        display_dict.get("utteranceFallback"),
        row_dict.get("utterance"),
        row_dict.get("utteranceFallback"),
        frame_dict.get("utterance"),
        frame_dict.get("utteranceFallback"),
        frame_dict.get("textFallback"),
    ):
        if isinstance(candidate, str) and candidate.strip():
            return candidate.strip()
    return None


def validate_affordance_speech(
    row: Mapping[str, Any] | dict[str, Any] | None,
    frame: Mapping[str, Any] | dict[str, Any] | None = None,
) -> tuple[bool, str]:
    """Validate that conversational affordances declare explicit initiating ``say``."""
    row_dict = row if isinstance(row, Mapping) else {}
    frame_dict = frame if isinstance(frame, Mapping) else row_dict.get("semanticFrame") or row_dict.get("frame")
    if is_navigation_frame(frame_dict):
        return True, "navigation_frame"
    if resolve_initiating_say(row_dict, frame_dict) is not None:
        return True, "valid_initiating_say"
    return False, "initiating_say_required"


def semantic_suggestion_title(row: dict[str, Any]) -> str:
    display = row.get("display") or {}
    return str(
        display.get("label")
        or display.get("labelFallback")
        or row.get("label")
        or row.get("text")
        or row.get("id")
        or row.get("action")
        or "Suggestion"
    )


def conversation_presented_rows(
    presentation: dict[str, Any] | None,
) -> list[dict[str, Any]]:
    """Adapt the production Conversation rows for the primary button surface.

    Lua owns the selected group, ordering, eligibility and semantic frames.
    This adapter preserves label vs. spoken-utterance separation.
    """

    presentation = presentation if isinstance(presentation, dict) else {}
    channel = presentation.get("responseChannel") or {}
    rows: list[dict[str, Any]] = []
    for row in channel.get("rows") or []:
        if not isinstance(row, dict):
            continue
        frame = row.get("semanticFrame") or row.get("frame")
        frame_dict = frame if isinstance(frame, dict) else {}
        label = str(
            row.get("label")
            or row.get("text")
            or frame_dict.get("labelFallback")
            or row.get("id")
            or "Choice"
        )
        utterance = resolve_initiating_say(row, frame_dict)
        display: dict[str, Any] = {
            "label": label,
            "labelFallback": label,
        }
        if utterance is not None:
            display["utterance"] = utterance
            display["utteranceFallback"] = utterance
        projected: dict[str, Any] = {
            "id": row.get("id"),
            "text": label,
            "label": label,
            "display": display,
            "frame": deepcopy(frame),
            "semanticFrame": deepcopy(frame),
            "enabled": row.get("enabled") is True,
            "source": deepcopy(row.get("source") or {}),
            "groupID": channel.get("groupID"),
        }
        if utterance is not None:
            projected["utterance"] = utterance
        rows.append(projected)
    return rows


def semantic_hub_diagnostic_projection(
    suggestions: dict[str, Any],
) -> dict[str, Any]:
    """Project only player-safe hub candidates into the developer inspector."""

    suggestions = suggestions if isinstance(suggestions, dict) else {}
    active_hub = suggestions.get("activeHub")
    if not isinstance(active_hub, dict) or active_hub.get("route") != "semantic_hub":
        return {"activeHub": None, "candidateCount": 0, "candidates": []}
    privacy = suggestions.get("privacy")
    privacy = privacy if isinstance(privacy, dict) else {}
    if (
        privacy.get("playerVisible") is not True
        or privacy.get("privateFieldsInspected") is not False
        or privacy.get("unknownFieldsExposed") is not False
    ):
        return {
            "activeHub": deepcopy(active_hub),
            "candidateCount": 0,
            "candidates": [],
            "diagnosticsHidden": True,
            "reason": "player_safe_projection_unavailable",
        }

    candidates: list[dict[str, Any]] = []

    def public_reason(value: Any) -> str | None:
        reason = str(value or "")
        if not reason:
            return None
        safe_reasons = {
            "candidate_not_eligible": "candidate not eligible in current public context",
            "non_hostile_public_context": "non-hostile public topic",
            "safe_public_weather_context": "safe public weather topic",
            "player_safe_gossip_available": "player-safe gossip context available",
            "safe_gossip_unavailable": "player-safe gossip context unavailable",
            "owned_companion_context": "eligible companion context",
            "owned_companion_required": "eligible companion context required",
            "trusted_close_relationship": "personal avenue permitted by disclosure policy",
        }
        return safe_reasons.get(reason, "contextual eligibility policy")

    for candidate in (suggestions.get("candidates") or [])[:32]:
        if not isinstance(candidate, dict) or candidate.get("visibility") == "private":
            continue
        frame = candidate.get("frame")
        frame = frame if isinstance(frame, dict) else {}
        extensions = frame.get("extensions")
        extensions = extensions if isinstance(extensions, dict) else {}
        display = candidate.get("display")
        display = display if isinstance(display, dict) else {}
        eligibility = candidate.get("eligibility")
        eligibility = eligibility if isinstance(eligibility, dict) else {}
        ranking = candidate.get("ranking")
        ranking = ranking if isinstance(ranking, dict) else {}
        is_eligible = (
            eligibility.get("allowed") is True
            and candidate.get("enabled") is not False
            and eligibility.get("status") not in {"hidden", "denied", "blocked"}
        )
        candidates.append(
            {
                "candidateID": candidate.get("id"),
                "providerID": candidate.get("providerID") or frame.get("providerID"),
                "semanticOwner": candidate.get("semanticOwner"),
                "rank": candidate.get("rank"),
                "rankClass": ranking.get("class") or "UNCLASSIFIED",
                "eligibility": "eligible" if is_eligible else "hidden",
                "eligibilityStatus": eligibility.get("status") or "unknown",
                "hiddenReason": (
                    None
                    if is_eligible
                    else public_reason(
                        candidate.get("hiddenReason")
                        or eligibility.get("reason")
                        or "candidate_not_eligible"
                    )
                ),
                "contextReason": public_reason(
                    candidate.get("contextReason") or eligibility.get("reason")
                ),
                "translationKeys": {
                    "label": display.get("labelKey"),
                    "utterance": display.get("utteranceKey"),
                },
                "resolvedLabel": display.get("label")
                or display.get("labelFallback")
                or candidate.get("id"),
                "resolvedUtterance": display.get("utterance")
                or display.get("utteranceFallback"),
                "semanticDestination": {
                    "route": extensions.get("route"),
                    "hubID": extensions.get("hubID") or active_hub.get("id"),
                    "topic": candidate.get("topic") or extensions.get("topic"),
                    "subject": frame.get("subject"),
                    "speechAct": frame.get("speechAct"),
                },
                "semanticFrame": deepcopy(frame),
            }
        )
    return {
        "activeHub": deepcopy(active_hub),
        "candidateCount": len(candidates),
        "candidates": candidates,
        "privacySafe": True,
    }

__all__ = [
    "is_navigation_frame",
    "npc_message_text",
    "resolve_initiating_say",
    "semantic_suggestion_rows",
    "semantic_suggestion_title",
    "conversation_presented_rows",
    "semantic_hub_diagnostic_projection",
    "validate_affordance_speech",
]
