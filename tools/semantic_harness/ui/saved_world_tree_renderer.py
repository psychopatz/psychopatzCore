"""Render the saved-world actor hierarchy into the Tk tree."""

from __future__ import annotations

def render_saved_world_tree(self) -> None:
    if not hasattr(self, "saved_world_tree"):
        return
    for item in self.saved_world_tree.get_children(""):
        self.saved_world_tree.delete(item)
    self.saved_world_tree_actor_rows = {}
    self.saved_world_tree_group_nodes = {}
    self.saved_world_tree_actor_groups = {}
    hierarchy = self.saved_world_browser.get("worldHierarchy") or {}
    relationship_view = self.saved_world_view_var.get() == "Relationship to Player"
    groups = (
        self._relationship_world_groups()
        if relationship_view
        else hierarchy.get("groups") if isinstance(hierarchy, dict) else []
    )
    relationship_category = str(
        getattr(self, "saved_world_relationship_category_var", None).get()
        if hasattr(self, "saved_world_relationship_category_var")
        else "All relationship categories"
    )
    if relationship_view and relationship_category != "All relationship categories":
        groups = [
            group for group in groups
            if isinstance(group, dict)
            and str(group.get("label") or "") == relationship_category
        ]
    query = self.saved_world_search_var.get().strip().casefold()
    if not isinstance(groups, list):
        groups = []
    root_iid = getattr(self, "saved_world_tree_root_iid", "world-root")
    root_open = self._ui_state.get("saved_world_root_open", True) is not False
    source = str(
        self.saved_world_browser.get("source")
        or self.saved_world_browser.get("sourceKind")
        or "MISSING"
    ).upper()
    visible_actor_count = 0
    for group in groups:
        if not isinstance(group, dict):
            continue
        members = [
            row for row in (group.get("members") or []) if isinstance(row, dict)
        ]
        if not query:
            visible_actor_count += len(members)
            continue
        group_label = str(group.get("label") or group.get("id") or "World")
        visible_actor_count += sum(
            1
            for row in members
            if query in group_label.casefold()
            or query in str(row.get("label") or "").casefold()
            or query in str(row.get("id") or "").casefold()
            or query in str(row.get("affiliationLabel") or "").casefold()
            or query in str(row.get("relationshipBadge") or "").casefold()
        )
    self.saved_world_tree.insert(
        "",
        "end",
        iid=root_iid,
        text=f"Saved world ({visible_actor_count})",
        values=("world", source, "all actors"),
        open=root_open,
    )
    open_group_ids = {
        str(value)
        for value in (self._ui_state.get("saved_world_open_groups") or [])
        if value
    }
    for group_index, group in enumerate(groups):
        if not isinstance(group, dict):
            continue
        members = [
            row for row in (group.get("members") or []) if isinstance(row, dict)
        ]
        matching_members = [
            row
            for row in members
            if not query
            or query in str(row.get("label") or "").casefold()
            or query in str(row.get("id") or "").casefold()
            or query in str(row.get("affiliationLabel") or "").casefold()
            or query in str(row.get("relationshipBadge") or "").casefold()
        ]
        group_label = str(group.get("label") or group.get("id") or "World")
        if query and query not in group_label.casefold() and not matching_members:
            continue
        group_iid = f"world-group-{group_index}"
        kind = str(group.get("kind") or "group")
        source = str(group.get("membershipSource") or group.get("source") or "MISSING")
        group_tag = str(group.get("relationshipTag") or "")
        group_tags = (group_tag,) if group_tag else ()
        self.saved_world_tree.insert(
            root_iid,
            "end",
            iid=group_iid,
            text=f"{group_label} ({len(matching_members) if query else len(members)})",
            values=(
                kind,
                source,
                "player-relative" if relationship_view else "",
            ),
            open=str(group.get("id") or "") in open_group_ids,
            tags=group_tags,
        )
        self.saved_world_tree_group_nodes[group_iid] = group
        for member_index, member in enumerate(matching_members):
            actor_iid = f"{group_iid}-actor-{member_index}"
            flags: list[str] = []
            badge = str(member.get("relationshipBadge") or "").strip()
            if badge:
                flags.append(badge)
            else:
                if member.get("isFollower") is True:
                    flags.append("follower")
                if member.get("isHostile") is True:
                    flags.append("hostile")
                if member.get("isTrader") is True:
                    flags.append("trader")
            label = str(member.get("label") or member.get("id") or "NPC")
            group_affiliation = str(
                member.get("affiliationLabel")
                or member.get("factionLabel")
                or member.get("communityLabel")
                or "unaffiliated"
            ).strip()
            if flags:
                label = f"{label} · {', '.join(flags)}"
            tag = str(member.get("relationshipTag") or "")
            if not tag:
                if member.get("isHostile") is True:
                    tag = "relationship_hostile"
                elif member.get("isTrader") is True:
                    tag = "relationship_trader"
                elif member.get("isFollower") is True:
                    tag = "relationship_companion"
            self.saved_world_tree.insert(
                group_iid,
                "end",
                iid=actor_iid,
                text=label,
                values=(
                    "NPC",
                    str(member.get("source") or "MISSING"),
                    group_affiliation,
                ),
                open=False,
                tags=(tag,) if tag else (),
            )
            self.saved_world_tree_actor_rows[actor_iid] = member
            self.saved_world_tree_actor_groups[actor_iid] = group_iid

def _restore_saved_world_tree_selection(self) -> None:
    """Restore the last NPC selection without importing it automatically."""

    wanted = str(self._ui_state.get("saved_world_npc_id") or "")
    if not wanted:
        return
    root_iid = getattr(self, "saved_world_tree_root_iid", "world-root")
    for actor_iid, actor in self.saved_world_tree_actor_rows.items():
        if str(actor.get("id") or "") != wanted:
            continue
        group_iid = self.saved_world_tree_actor_groups.get(actor_iid)
        if group_iid:
            self.saved_world_tree.item(root_iid, open=True)
            self.saved_world_tree.item(group_iid, open=True)
        self.saved_world_tree.selection_set(actor_iid)
        self.saved_world_tree.focus(actor_iid)
        self._on_saved_world_tree_select()
        return


__all__ = ["render_saved_world_tree"]
