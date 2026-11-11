"""Track staged simulation-workbench edits and derived UI state."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.runtime.scenario import derive_actor_identifier, derive_display_name


def refresh_workbench_feedback(app: Any, message: str | None = None) -> None:
    """Make staged edits visible before they are sent to the worker."""

    if app.workbench_status_var is None:
        return
    pending_labels = pending_control_labels(app)
    pending = len(pending_labels)
    app.workbench_apply_button.configure(
        text="Apply" if pending == 0 else f"Apply ({pending} pending)"
    )
    app.replay_button.configure(
        text=(
            f"Replay macro ({len(app.replay_steps)})"
            if pending == 0 and app.replay_steps
            else "Apply + replay"
            if pending == 0
            else f"Apply + replay ({pending} pending)"
        )
    )
    if message is not None:
        app.workbench_status_var.set(message)
    elif pending:
        summary = ", ".join(pending_labels[:5])
        if len(pending_labels) > 5:
            summary += f", +{len(pending_labels) - 5} more"
        app.workbench_status_var.set(
            f"Pending: {summary or 'review draft'} · Apply to commit"
        )
    else:
        app.workbench_status_var.set(
            "Auto-apply enabled · edits commit through the Lua worker."
        )


def pending_control_labels(app: Any) -> list[str]:
    labels: list[str] = []
    for control in app.workbench_controls:
        control_id = str(control.get("id") or "")
        if (
            control_id not in app._workbench_dirty_ids
            or control.get("derivedFrom")
        ):
            continue
        label = str(control.get("label") or control_id)
        if control.get("derivedFrom"):
            label = f"{label} (derived)"
        labels.append(label)
    if app._workbench_profile_pending:
        labels.insert(0, "NPC profile")
    return labels


def clear_workbench_pending(app: Any) -> None:
    app._workbench_dirty_ids.clear()
    app._workbench_profile_pending = False
    for field in app.workbench_control_fields.values():
        field.dirty = False
    app._refresh_workbench_feedback()


def schedule_workbench_auto_apply(app: Any) -> None:
    """Debounce direct edits into the existing worker configure boundary."""

    if app.closed or not app.worker_ready:
        return
    if app._auto_apply_after is not None:
        try:
            app.root.after_cancel(app._auto_apply_after)
        except app._tk.TclError:
            pass
        app._auto_apply_after = None
    if not pending_control_labels(app):
        return
    app._auto_apply_after = app.root.after(
        300, app._apply_pending_workbench_changes
    )


def apply_pending_workbench_changes(app: Any) -> None:
    app._auto_apply_after = None
    if app.closed or not app.worker_ready:
        return
    if app.busy:
        app._auto_apply_after = app.root.after(
            250, app._apply_pending_workbench_changes
        )
        return
    app.apply_simulation_settings(automatic=True)


def on_workbench_field_dirty(app: Any, field: Any) -> None:
    """Track a direct edit and refresh derived actor presentation fields."""

    control_id = str(field.control.get("id") or "")
    if (
        not control_id
        or app.workbench_control_fields.get(control_id) is not field
    ):
        return
    if app._workbench_initializing:
        return
    app._workbench_dirty_ids.add(control_id)
    app.activity_log.record(
        "ui",
        "staged_change",
        controlID=control_id,
        label=str(field.control.get("label") or control_id),
        value=str(field.get_value())[:180],
    )
    if control_id in {
        "player.forename", "player.surname", "npc.forename", "npc.surname"
    }:
        app._sync_derived_identity_fields(control_id.split(".", 1)[0])
    if control_id in {"persona.traits", "player.traits"}:
        app._render_trait_effects()
        app._schedule_personality_preview()
    app._refresh_workbench_feedback()
    app._schedule_workbench_auto_apply()


def sync_derived_identity_fields(app: Any, actor: str) -> None:
    """Keep IDs and player display text readable while names are edited."""

    prefix = "player" if actor == "player" else "npc"
    forename_field = app.workbench_control_fields.get(f"{prefix}.forename")
    surname_field = app.workbench_control_fields.get(f"{prefix}.surname")
    if forename_field is None or surname_field is None:
        return
    forename = forename_field.get_value()
    surname = surname_field.get_value()
    if prefix == "player":
        derived = {
            "player.characterUUID": derive_actor_identifier(
                "char", forename, surname
            ),
            "player.displayName": derive_display_name(forename, surname),
        }
    else:
        derived = {
            "npc.npcID": derive_actor_identifier("npc", forename, surname),
        }
    for control_id, value in derived.items():
        field = app.workbench_control_fields.get(control_id)
        if field is not None:
            field.set_value(value)
            app._workbench_dirty_ids.add(control_id)
            app.activity_log.record(
                "ui",
                "derived_change",
                controlID=control_id,
                label=str(field.control.get("label") or control_id),
                value=str(value)[:180],
            )


def update_generated_personality_controls(app: Any) -> None:
    override_field = app.workbench_control_fields.get("npc.personalityOverride")
    enabled = bool(override_field and override_field.get_value())
    for control in app.workbench_controls:
        if not control.get("requiresOverride"):
            continue
        field = app.workbench_control_fields.get(str(control.get("id") or ""))
        if field is not None:
            field.set_enabled(enabled)
            control_id = str(control.get("id") or "")
            preview_key = (
                "socialStyle"
                if control_id == "persona.socialStyle"
                else control_id.rsplit(".", 1)[-1]
            )
            if not enabled and preview_key in app.generated_personality_preview:
                field.set_value(app.generated_personality_preview[preview_key])
