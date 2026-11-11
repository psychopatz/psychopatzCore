"""Append bounded production social-action evidence to the transcript."""

from __future__ import annotations

from typing import Any

def append_production_action(self, response: dict[str, Any]) -> None:
    result = response.get("result") if isinstance(response, dict) else None
    action = result.get("actionResult") if isinstance(result, dict) else None
    if not isinstance(action, dict):
        return
    requested = action.get("requestedEffects")
    requested = requested if isinstance(requested, dict) else {}
    delta = action.get("relationshipDelta")
    delta = delta if isinstance(delta, dict) else {}
    before = action.get("relationshipBefore")
    before = before if isinstance(before, dict) else {}
    after = action.get("relationshipAfter")
    after = after if isinstance(after, dict) else {}
    lines = [
        "Production social action",
        f"  Event: {action.get('eventType') or action.get('action') or action.get('speechAct') or 'social_action'}",
        f"  Status: {str(action.get('status') or 'UNKNOWN').upper()} · "
        f"authority={action.get('authority') or 'production'}",
        f"  Result: {'accepted' if action.get('accepted') is True else 'rejected'} · "
        f"reason={action.get('reason') or 'none'}",
        "  Requested effect: "
        f"Approval {self._format_signed(requested.get('approval'))} · "
        f"Respect {self._format_signed(requested.get('respect'))} · "
        f"Familiarity {self._format_signed(requested.get('familiarity'))}",
        "  Visible change: "
        f"Approval {self._format_signed(delta.get('approval'))} · "
        f"Respect {self._format_signed(delta.get('respect'))} · "
        f"Familiarity {self._format_signed(delta.get('familiarity'))}",
        f"  Memory recorded: {action.get('memoryRecorded', 'MISSING')} · "
        f"standing changed: {action.get('visibleRelationshipChange', 'MISSING')}",
        "  Before: " + self._relationship_evidence(before),
        "  After:  " + self._relationship_evidence(after),
    ]
    self._append("TOOL/ACTION", "\n".join(lines))

__all__ = ["append_production_action"]
