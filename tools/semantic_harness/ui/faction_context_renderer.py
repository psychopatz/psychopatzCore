"""Render persisted faction and community context in the workbench."""

from __future__ import annotations

def refresh_faction_context(self) -> None:
    """Render group membership and standing without confusing it with NPC affinity."""

    if self.faction_context_summary is None:
        return
    group = self.saved_world_selected_group
    if not isinstance(group, dict) or not group:
        self._set_text(
            self.faction_context_summary,
            "No saved faction or community target selected.\n\n"
            "Choose a group or NPC in World Browser to inspect its persisted context.",
        )
        return
    persisted = group.get("group")
    persisted = persisted if isinstance(persisted, dict) else {}
    kind = str(group.get("kind") or "group").title()
    label = str(group.get("label") or "Unnamed group")
    source = str(group.get("source") or "MISSING").upper()
    membership_source = str(
        group.get("membershipSource") or "MISSING"
    ).upper()
    if str(group.get("kind") or "") == "relationship_category":
        self._set_text(
            self.faction_context_summary,
            "\n".join(
                [
                    f"Player-relative category: {label}",
                    f"Source: {source} · membership: {membership_source}",
                    "This lens is a derived presentation grouping over SAVE "
                    "provider facts.",
                    "",
                    "It does not assert a personal enemy relationship or "
                    "replace production faction diplomacy.",
                    f"Members: {len(group.get('members') or [])}",
                ]
            ),
        )
        return
    member_rows = [
        row for row in (group.get("members") or []) if isinstance(row, dict)
    ]
    member_labels = {
        str(row.get("id")): str(row.get("label") or row.get("id"))
        for row in member_rows
    }
    leader_id = persisted.get("leaderNPCID")
    leader = member_labels.get(str(leader_id), "MISSING") if leader_id else "MISSING"
    standing = persisted.get("standing")
    diplomacy = persisted.get("diplomacy")
    group_projection = self.simulation_projection.get("factionRelationship")
    group_projection = (
        group_projection if isinstance(group_projection, dict) else {}
    )
    imported_standing = group_projection.get("imported", standing)
    effective_standing = group_projection.get(
        "effective",
        group_projection.get("standing", standing),
    )
    standing_source = str(
        group_projection.get("source")
        or (
            "HARNESS_MUTATION"
            if group_projection.get("mutated") is True
            else source if imported_standing is not None else "MISSING"
        )
    ).upper()
    personal = self.simulation_projection.get("relationship")
    personal = personal if isinstance(personal, dict) else {}
    personal_source = str(
        self._actor_source_info("npc.relationship", "MISSING").get("source")
        or "MISSING"
    ).upper()
    lines = [
        f"Target: {kind} · {label}",
        f"Source: {source} · membership: {membership_source}",
        f"Technical group ID: {persisted.get('id') or group.get('id') or 'MISSING'}",
        f"Leader: {leader}",
        f"Members: {len(member_rows)}",
        "",
        "Standing verification",
        "Personal NPC relationship (NPC ↔ Player): "
        f"{personal.get('standing') or personal.get('state') or 'MISSING'} "
        f"· source {personal_source}",
        "Faction/community standing (group):",
        f"  imported: {imported_standing if imported_standing is not None else 'MISSING'}",
        f"  effective: {effective_standing if effective_standing is not None else 'MISSING'}",
        f"  source: {standing_source}",
    ]
    if imported_standing is None and not group_projection:
        lines.append(
            "No authoritative persisted group-standing value is available; "
            "the harness will not infer one from NPC approval."
        )
    if diplomacy not in (None, "", {}, []):
        lines.append(f"Diplomacy: {str(diplomacy)[:280]}")
    for title, key in (
        ("Roles", "roles"),
        ("Member roles", "memberRoles"),
        ("Provider overlay", "providerOverlay"),
    ):
        value = persisted.get(key)
        if value not in (None, "", {}, []):
            lines.append(f"{title}: {str(value)[:280]}")
    lines.append("")
    lines.append("Members")
    for row in member_rows[:48]:
        member = str(row.get("label") or row.get("id") or "NPC")
        if row.get("role"):
            member += f" · role {row['role']}"
        lines.append(f"  • {member}")
    self._set_text(self.faction_context_summary, "\n".join(lines))


__all__ = ["refresh_faction_context"]
