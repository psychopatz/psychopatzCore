"""Pure suggestion and diagnostic projections used by the Tk shell."""

from __future__ import annotations

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


def semantic_suggestion_title(row: dict[str, Any]) -> str:
    display = row.get("display") or {}
    return str(
        display.get("label")
        or display.get("labelFallback")
        or display.get("utterance")
        or display.get("utteranceFallback")
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
    This adapter only supplies the renderer's established row shape.
    """

    presentation = presentation if isinstance(presentation, dict) else {}
    channel = presentation.get("responseChannel") or {}
    rows: list[dict[str, Any]] = []
    for row in channel.get("rows") or []:
        if not isinstance(row, dict):
            continue
        text = str(row.get("text") or row.get("id") or "Choice")
        frame = row.get("semanticFrame") or row.get("frame")
        rows.append(
            {
                "id": row.get("id"),
                "text": text,
                "display": {"label": text, "labelFallback": text},
                "frame": deepcopy(frame),
                "semanticFrame": deepcopy(frame),
                "enabled": row.get("enabled") is True,
                "source": deepcopy(row.get("source") or {}),
                "groupID": channel.get("groupID"),
            }
        )
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
    "npc_message_text",
    "semantic_suggestion_rows",
    "semantic_suggestion_title",
    "conversation_presented_rows",
    "semantic_hub_diagnostic_projection",
]
