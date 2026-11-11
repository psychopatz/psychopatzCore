"""Convert staged workbench controls to and from scenario state."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.runtime.npc_profiles import PROFILE_IDS, apply_npc_profile, profile_id, profile_label
from .dialogs.settings import collect_scenario_settings


def selected_npc_profile(app: Any) -> str:
    selected_label = app.npc_profile_var.get()
    return next(
        (value for value in PROFILE_IDS if profile_label(value) == selected_label),
        "custom",
    )


def sync_workbench_from_scenario(
    app: Any, scenario: dict[str, Any], *, clear_pending: bool = True
) -> None:
    app.npc_profile_var.set(profile_label(profile_id(scenario)))
    app.language_var.set(scenario.get("runtime", {}).get("language", "EN"))
    for control in app.workbench_controls:
        control_id = str(control.get("id") or "")
        field = app.workbench_control_fields.get(control_id)
        if field is not None:
            field.set_value(app._scenario_control_value(control, scenario))
            field.dirty = False
    app.generated_personality_preview = {}
    app.player_social_profile_preview = {}
    app.player_trait_conflicts = []
    app.player_trait_fingerprint = ""
    app._update_generated_personality_controls()
    app._render_trait_effects()
    app._refresh_actor_inspectors()
    if clear_pending:
        app._clear_workbench_pending()


def collect_workbench_scenario(app: Any) -> dict[str, Any]:
    selected_profile = app._selected_npc_profile()
    draft = deepcopy(app.scenario)
    if selected_profile != profile_id(draft):
        draft = apply_npc_profile(draft, selected_profile)
    values: dict[str, Any] = {}
    override_field = app.workbench_control_fields.get("npc.personalityOverride")
    personality_override = bool(override_field and override_field.get_value())
    for control in app.workbench_controls:
        control_id = str(control.get("id") or "")
        field = app.workbench_control_fields.get(control_id)
        if field is None or field.kind == "read_only":
            continue
        if control.get("requiresOverride") and not personality_override:
            continue
        current = app._scenario_control_value(control, draft)
        if field.initial is None and current is None and not field.dirty:
            continue
        values[control_id] = field.get_value()
    return collect_scenario_settings(
        draft, values, app.simulation_control_catalog
    )


def on_npc_profile(app: Any) -> None:
    """Stage a preset in the shared workbench draft; Apply owns the change."""

    selected = app._selected_npc_profile()
    try:
        staged = apply_npc_profile(app.scenario, selected)
    except ValueError as error:
        app._messagebox.showerror("NPC profile", str(error))
        app.npc_profile_var.set(profile_label(profile_id(app.scenario)))
        return
    app._sync_workbench_from_scenario(staged, clear_pending=False)
    app._workbench_profile_pending = True
    app.activity_log.record("ui", "profile_staged", label=profile_label(selected))
    app._refresh_workbench_feedback(
        f"{profile_label(selected)} staged · applying automatically…"
    )
    app._schedule_workbench_auto_apply()
