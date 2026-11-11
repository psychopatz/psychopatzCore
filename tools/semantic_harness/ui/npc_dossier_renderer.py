"""Render the bounded production NPC dossier projection."""

from __future__ import annotations

def refresh_npc_dossier(self) -> None:
    if self.npc_dossier_summary is None:
        return
    projection = self.npc_dossier_projection
    if not isinstance(projection, dict) or not projection:
        self._set_text(
            self.npc_dossier_summary,
            "No production NPC dossier has been projected yet.",
        )
        return
    snapshot = projection.get("snapshot")
    snapshot = snapshot if isinstance(snapshot, dict) else {}
    rehydration = projection.get("rehydration")
    rehydration = rehydration if isinstance(rehydration, dict) else {}
    lines = [
        f"Source: {str(projection.get('source') or 'MISSING').upper()}",
        f"Status: {projection.get('status') or 'MISSING'} · "
        f"owner: {projection.get('owner') or 'MISSING'}",
        f"NPC: {projection.get('npcID') or snapshot.get('npcID') or 'MISSING'} · "
        f"knowledge load: {rehydration.get('status') or 'MISSING'}",
        f"Knowledge revision: {snapshot.get('revision', 0)} · "
        f"first met: {snapshot.get('firstMetAt', 'MISSING')} · "
        f"last interaction: {snapshot.get('lastInteractionAt', 'MISSING')}",
        "",
        "Known information",
    ]
    identity = snapshot.get("identity")
    if isinstance(identity, dict):
        lines.append(
            "  identity: "
            + " · ".join(
                f"{key}={identity.get(key, 'MISSING')}"
                for key in ("displayName", "archetypeLabel", "factionName", "factionRole")
                if identity.get(key) not in (None, "")
            )
        )
    categories = snapshot.get("categories")
    categories = categories if isinstance(categories, list) else []
    descriptor_count = 0
    for category in categories[:64]:
        if not isinstance(category, dict):
            continue
        lines.append(f"  [{category.get('id') or 'category'}]")
        descriptors = category.get("descriptors")
        descriptors = descriptors if isinstance(descriptors, list) else []
        for descriptor in descriptors[:128]:
            if not isinstance(descriptor, dict):
                continue
            descriptor_count += 1
            presentation = descriptor.get("presentation")
            presentation = presentation if isinstance(presentation, dict) else {}
            label = presentation.get("label") or presentation.get("labelKey")
            lines.append(
                f"    {label or descriptor.get('descriptorID')}: "
                f"{self._dossier_value(descriptor.get('value'))} · "
                f"{descriptor.get('status') or 'unknown'} · "
                f"confidence={descriptor.get('confidence', 'MISSING')} · "
                f"source={descriptor.get('primarySource') or 'MISSING'}"
            )
    if descriptor_count == 0:
        lines.append("  no known descriptors")

    journal = snapshot.get("journalEntries")
    journal = journal if isinstance(journal, list) else []
    lines.extend(["", f"Knowledge journal ({len(journal)})"])
    for entry in journal[-32:]:
        if isinstance(entry, dict):
            lines.append(
                f"  {entry.get('type') or 'knowledge'} · "
                f"{entry.get('translationKey') or 'untranslated'} · "
                f"at {entry.get('createdAt', 'MISSING')} · "
                f"params={self._dossier_value(entry.get('params') or {})}"
            )
    if not journal:
        lines.append("  none recorded")

    notes = snapshot.get("manualNotes")
    notes = notes if isinstance(notes, list) else []
    lines.extend(["", f"Manual notes ({len(notes)})"])
    for note in notes[-16:]:
        if isinstance(note, dict):
            lines.append(
                f"  {note.get('createdAt', 'MISSING')}: "
                f"{note.get('text') or ''}"
            )
    if not notes:
        lines.append("  none recorded")

    gift_preferences = snapshot.get("giftPreferences")
    gift_preferences = gift_preferences if isinstance(gift_preferences, dict) else {}
    lines.extend(["", f"Gift preferences ({len(gift_preferences)})"])
    for item_type, disposition in sorted(gift_preferences.items())[:64]:
        lines.append(f"  {item_type}: {disposition}")
    if not gift_preferences:
        lines.append("  none recorded")
    self._set_text(self.npc_dossier_summary, "\n".join(lines))


__all__ = ["refresh_npc_dossier"]
