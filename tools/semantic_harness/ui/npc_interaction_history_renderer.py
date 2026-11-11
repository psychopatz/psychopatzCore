"""Render the bounded production relationship-history projection."""

from __future__ import annotations

def refresh_npc_interaction_history(self) -> None:
    if self.npc_interaction_summary is None:
        return
    projection = self.relationship_history_projection
    if not isinstance(projection, dict) or not projection:
        self._set_text(
            self.npc_interaction_summary,
            "No production relationship history has been projected yet.",
        )
        return
    snapshot = projection.get("snapshot")
    snapshot = snapshot if isinstance(snapshot, dict) else {}
    relationship = snapshot.get("relationship")
    relationship = relationship if isinstance(relationship, dict) else {}
    lines = [
        f"Source: {str(projection.get('source') or 'MISSING').upper()}",
        f"Status: {projection.get('status') or 'MISSING'} · "
        f"owner: {projection.get('owner') or 'MISSING'}",
        "Current relationship: " + self._relationship_evidence(relationship),
        "Saved baseline: "
        f"Approval {self._format_number(relationship.get('baselineApproval'))} · "
        f"Respect {self._format_number(relationship.get('baselineRespect'))}",
        f"memory count: {relationship.get('memoryCount', 0)} · "
        f"relationship revision: {self._format_number(relationship.get('revision'))}",
        "Saturation budgets:",
        "",
        "Recorded interactions",
    ]
    saturation = snapshot.get("saturation")
    saturation = saturation if isinstance(saturation, dict) else {}
    for event_type, budget in sorted(saturation.items()):
        if not isinstance(budget, dict):
            continue
        lines.append(
            f"  {event_type}: approval {self._format_signed(budget.get('approval'))} · "
            f"respect {self._format_signed(budget.get('respect'))}"
        )
    if not saturation:
        lines.append("  none recorded")
    lines.append(f"Cooldowns: {self._dossier_value(snapshot.get('cooldowns') or {})}")
    journal = snapshot.get("interactionJournal")
    journal = journal if isinstance(journal, list) else []
    for entry in reversed(journal[-64:]):
        if not isinstance(entry, dict):
            continue
        before = entry.get("before") or {}
        after = entry.get("after") or {}
        delta = entry.get("delta") or {}
        event_id = str(entry.get("eventID") or "MISSING")
        if len(event_id) > 96:
            event_id = event_id[:93] + "..."
        lines.extend(
            [
                f"  Interaction {entry.get('sequence', '?')} · "
                f"{entry.get('eventType') or entry.get('kind') or 'interaction'}",
                f"     result: {'APPLIED' if entry.get('applied') is True else entry.get('applied', 'MISSING')} · "
                f"event ID: {event_id}",
                f"     before: {self._relationship_evidence(before)}",
                f"     after:  {self._relationship_evidence(after)}",
                "     change: "
                f"Approval {self._format_signed(delta.get('approval'))} · "
                f"Respect {self._format_signed(delta.get('respect'))} · "
                f"Familiarity {self._format_signed(delta.get('familiarity'))}",
            ]
        )
    if not journal:
        lines.append("  none recorded")

    memories = snapshot.get("memories")
    memories = memories if isinstance(memories, list) else []
    lines.extend(["", f"Memories ({len(memories)})"])
    for memory in memories[:32]:
        if isinstance(memory, dict):
            lines.append(
                f"  {memory.get('type') or 'memory'} · "
                f"strength={memory.get('currentStrength', memory.get('strength', 'MISSING'))} · "
                f"source={memory.get('knowledgeSource') or memory.get('sourceKey') or 'MISSING'}"
            )
    if not memories:
        lines.append("  none recorded")
    action = snapshot.get("actionResult")
    if isinstance(action, dict):
        lines.extend(["", "Last semantic action"])
        lines.append(
            f"  {action.get('eventType') or 'social action'} · "
            f"status={str(action.get('status') or 'unknown').upper()} · "
            f"memory recorded={action.get('memoryRecorded', 'MISSING')}"
        )
        lines.append(
            "  visible standing change: "
            f"{action.get('visibleRelationshipChange', 'MISSING')} · "
            f"reason={action.get('reason') or 'none'}"
        )
        requested = action.get('requestedEffects')
        if isinstance(requested, dict):
            lines.append(
                "  Requested effect: "
                f"Approval {self._format_signed(requested.get('approval'))} · "
                f"Respect {self._format_signed(requested.get('respect'))} · "
                f"Familiarity {self._format_signed(requested.get('familiarity'))}"
            )
    self._set_text(self.npc_interaction_summary, "\n".join(lines))


__all__ = ["refresh_npc_interaction_history"]
