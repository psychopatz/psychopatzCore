"""Apply enabled/disabled state across the semantic harness UI."""

from __future__ import annotations

from typing import Any


def set_controls(app: Any, enabled: bool) -> None:
    """Synchronize widget and editor availability with worker state."""

    state = "normal" if enabled and not app.busy else "disabled"
    for button in (
        app.send_button,
        app.open_conversation_button,
        app.reset_button,
        app.load_button,
        app.settings_button,
        app.preview_button,
        app.save_button,
        app.snapshot_button,
        app.persona_matrix_button,
        app.capture_baseline_button,
        app.talk_start_button,
        app.talk_matrix_button,
        app.workbench_apply_button,
        app.replay_button,
        app.world_knowledge_button,
        app.selection_explain_button,
        app.saved_world_discover_button,
        app.saved_world_inspect_button,
        app.saved_world_import_button,
    ):
        button.configure(state=state)
    # Layout recovery must remain available while the worker is starting,
    # busy, or has failed. It only changes Tk state and does not require a
    # semantic worker round-trip.
    for button in (app.advanced_toggle_button, app.reset_layout_button):
        button.configure(state="normal")
    if hasattr(app, "saved_world_save_box"):
        combo_state = "readonly" if enabled and not app.busy else "disabled"
        app.saved_world_save_box.configure(
            state=combo_state if app.saved_world_entries else "disabled"
        )
        browser_state = (
            combo_state if app.saved_world_browser else "disabled"
        )
        app.saved_world_player_box.configure(state=browser_state)
        app.saved_world_tree.configure(
            selectmode=(
                "browse" if enabled and app.saved_world_browser else "none"
            )
        )
    if hasattr(app, "proposal_button"):
        app.proposal_button.configure(state=state)
    if hasattr(app, "auto_replay_checkbutton"):
        app.auto_replay_checkbutton.configure(state=state)
    inventory_gift_workbench = getattr(app, "inventory_gift_workbench", None)
    if inventory_gift_workbench is not None:
        inventory_gift_workbench.set_busy(not enabled)
    if app.language_box is not None:
        app.language_box.configure(
            state="readonly" if enabled and not app.busy else "disabled"
        )
    if hasattr(app, "compare_utterance_box"):
        app.compare_utterance_box.configure(
            state="normal" if enabled and not app.busy else "disabled"
        )
    if hasattr(app, "talk_target_box"):
        app.talk_target_box.configure(
            state="readonly" if enabled and not app.busy else "disabled"
        )
    if hasattr(app, "talk_utterance_box"):
        app.talk_utterance_box.configure(
            state="normal" if enabled and not app.busy else "disabled"
        )
    app.npc_profile_box.configure(
        state="readonly" if enabled and not app.busy else "disabled"
    )
    for field in app.workbench_control_fields.values():
        field.set_enabled(enabled and not app.busy)
    if enabled and not app.busy:
        app._update_generated_personality_controls()
    app.matrix_dimension_box.configure(
        state="readonly" if enabled and not app.busy else "disabled"
    )
    for button in getattr(app, "regression_buttons", ()):
        button.configure(state=state)
    app.restart_button.configure(
        state="normal" if app.session.ready and not app.busy else "disabled"
    )
    app.flow_editor.set_enabled(enabled and not app.busy)
    if hasattr(app, "interaction_modules"):
        app.interaction_modules.set_enabled(enabled and not app.busy)
    app.interaction_explorer.set_enabled(enabled and not app.busy)
    if hasattr(app, "source_explorer"):
        app.source_explorer.set_enabled(enabled and not app.busy)
    app.interaction_composer.set_enabled(enabled and not app.busy)
    app.workflow_pane.set_enabled(enabled and not app.busy)
    app._refresh_suggestion_controls(enabled and not app.busy)
