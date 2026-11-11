"""Render selected saved-world group details into the Tk inspector."""

from __future__ import annotations

from typing import Any

def render_saved_world_group_details(
    self, group: dict[str, Any] | None
) -> None:
    if not hasattr(self, "saved_world_group_inspector"):
        return
    if not isinstance(group, dict):
        self.saved_world_group_title_var.set(
            "Select a faction, community, or overlay"
        )
        self.saved_world_group_source_var.set("Source: MISSING")
        self._set_text(
            self.saved_world_group_inspector,
            "No saved group is selected.",
        )
        return
    persisted = group.get("group")
    persisted = persisted if isinstance(persisted, dict) else {}
    kind = str(group.get("kind") or "group")
    label = str(group.get("label") or group.get("id") or "Group")
    source = str(group.get("source") or "MISSING").upper()
    membership_source = str(
        group.get("membershipSource") or "MISSING"
    ).upper()
    self.saved_world_group_title_var.set(f"{kind.title()}: {label}")
    self.saved_world_group_source_var.set(
        f"Source: {source} · membership: {membership_source}"
    )
    if kind == "relationship_category":
        lens = persisted.get("lens") or "Relationship to Player"
        classification_source = persisted.get("classificationSource") or "MISSING"
        player_label = (
            getattr(self, "saved_world_player_var", None).get()
            if getattr(self, "saved_world_player_var", None) is not None
            else "MISSING"
        )
        lines = [
            f"Lens: {lens}",
            f"Player: {player_label or 'MISSING'}",
            f"Classification: {persisted.get('category') or label}",
            f"Facts: {classification_source}",
            f"members: {len(group.get('members') or [])}",
            "",
            "Members",
        ]
        for member in (group.get("members") or [])[:48]:
            if not isinstance(member, dict):
                continue
            member_line = str(member.get("label") or member.get("id") or "NPC")
            member_line += f" · {member.get('relationshipBadge') or 'unknown'}"
            member_line += f" · {member.get('affiliationLabel') or 'unaffiliated'}"
            lines.append(f"  • {member_line}")
        self._set_text(self.saved_world_group_inspector, "\n".join(lines))
        return
    lines = [
        f"ID: {persisted.get('id') or group.get('id') or 'MISSING'}",
        f"status: {persisted.get('status') or 'MISSING'}",
    ]
    for title, key in (
        ("leader", "leaderNPCID"),
        ("owner", "ownerPlayerKey"),
        ("faction", "factionID"),
        ("community", "communityID"),
        ("archetype", "archetypeID"),
    ):
        if persisted.get(key) not in (None, ""):
            lines.append(f"{title}: {persisted[key]}")
    for title, key in (
        ("roles", "roles"),
        ("member roles", "memberRoles"),
        ("role by member", "roleByMemberID"),
        ("standing", "standing"),
        ("diplomacy", "diplomacy"),
    ):
        value = persisted.get(key)
        if value not in (None, "", {}, []):
            lines.append(f"{title}: {str(value)[:240]}")
    overlay = persisted.get("providerOverlay") or persisted.get("provider")
    if overlay not in (None, "", {}, []):
        lines.append(f"provider overlay: {str(overlay)[:240]}")
    member_ids = group.get("memberIDs")
    member_ids = member_ids if isinstance(member_ids, list) else []
    lines.append(f"members: {len(member_ids)}")
    members = group.get("members")
    members = members if isinstance(members, list) else []
    for member in members[:32]:
        if not isinstance(member, dict):
            continue
        member_line = str(member.get("label") or member.get("id") or "NPC")
        if member.get("role"):
            member_line += f" · role {member['role']}"
        if member.get("provider"):
            member_line += f" · provider {member['provider']}"
        lines.append(f"  • {member_line}")
    self._set_text(self.saved_world_group_inspector, "\n".join(lines))


__all__ = ["render_saved_world_group_details"]
