"""Update saved-world lens selections without importing source data."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from .saved_world_relationship_projection import RELATIONSHIP_CATEGORY_LABELS


def on_saved_world_player(app: Any) -> None:
    """Reclassify the read-only actor lens for the selected Player."""

    if not app.saved_world_browser:
        return
    app.saved_world_selected_actor = {}
    app.saved_world_selected_group = {}
    app._render_saved_world_tree()
    app._restore_saved_world_tree_selection()
    app._save_ui_state()


def on_saved_world_view(app: Any) -> None:
    """Switch between player-relative and persisted-affiliation views."""

    if app.saved_world_view_var.get() not in {
        "Relationship to Player",
        "Saved affiliations",
    }:
        app.saved_world_view_var.set("Relationship to Player")
    if app.saved_world_view_var.get() == "Saved affiliations":
        app.saved_world_relationship_category_var.set(
            "Saved affiliations / overlays"
        )
    else:
        app.saved_world_relationship_category_var.set(
            "All relationship categories"
        )
    app._render_saved_world_tree()
    app._restore_saved_world_tree_selection()
    app._save_ui_state()


def select_saved_world_relationship_category(app: Any, category: str) -> None:
    """Make relationship navigation explicit without changing save authority."""

    if category == "Saved affiliations / overlays":
        app.saved_world_view_var.set("Saved affiliations")
        app.saved_world_relationship_category_var.set(category)
    else:
        valid = {
            "All relationship categories",
            *RELATIONSHIP_CATEGORY_LABELS,
        }
        selected = category if category in valid else "All relationship categories"
        app.saved_world_view_var.set("Relationship to Player")
        app.saved_world_relationship_category_var.set(selected)
    app._render_saved_world_tree()
    app._restore_saved_world_tree_selection()
    app._save_ui_state()


def on_saved_world_tree_select(app: Any) -> None:
    selection = app.saved_world_tree.selection()
    if not selection:
        return
    selected_id = selection[0]
    if selected_id == getattr(app, "saved_world_tree_root_iid", "world-root"):
        app.saved_world_selected_group = {}
        app.saved_world_selected_actor = {}
        app.saved_world_npc_var.set("")
        app.saved_world_target_var.set(
            "Saved world root selected; expand a group to choose an NPC"
        )
        app._render_saved_world_group_details(None)
        app._refresh_faction_context()
        return
    group = app.saved_world_tree_group_nodes.get(selected_id)
    if group is not None:
        app.saved_world_selected_group = deepcopy(group)
        app.saved_world_selected_actor = {}
        app._render_saved_world_group_details(group)
        app._refresh_faction_context()
        return
    actor = app.saved_world_tree_actor_rows.get(selected_id)
    if not actor:
        return
    group_id = app.saved_world_tree_actor_groups.get(selected_id)
    group = app.saved_world_tree_group_nodes.get(group_id)
    app.saved_world_selected_actor = deepcopy(actor)
    app.saved_world_selected_group = deepcopy(group or {})
    app._render_saved_world_group_details(group)
    app.saved_world_npc_var.set(str(actor.get("id") or ""))
    label = str(actor.get("label") or actor.get("id") or "NPC")
    app.saved_world_target_var.set(
        f"Selected NPC: {label} · source {actor.get('source') or 'MISSING'} · "
        "double-click or Load selected NPC"
    )
    app._refresh_faction_context()
    app._refresh_simulation_context()
