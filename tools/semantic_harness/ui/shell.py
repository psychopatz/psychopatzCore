"""Tk adapter for the real-Lua semantic dialogue worker."""

from __future__ import annotations

import argparse
import sys
from concurrent.futures import Future
from pathlib import Path
from typing import Any, Callable

from tools.semantic_harness.inspection.rendering import pretty
from .dialogs.catalog_control import CatalogControlField
from .dialogs.settings import open_runtime_settings as show_runtime_settings
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.core.worker_session import WorkerReady
from .suggestion_projection import (
    npc_message_text,
    semantic_hub_diagnostic_projection,
    semantic_suggestion_rows,
)
from .simulation_workbench_builder import build_simulation_workbench
from .saved_world_browser_builder import build_saved_world_browser
from .saved_world_relationship_projection import relationship_world_groups
from .saved_world_tree_renderer import (
    _restore_saved_world_tree_selection,
    render_saved_world_tree,
)
from .saved_world_group_renderer import render_saved_world_group_details
from .actor_inspector_renderer import refresh_actor_inspectors
from .faction_context_renderer import refresh_faction_context
from .social_context_projection import social_context_from_response, social_context_lines
from .social_context_renderer import refresh_social_context_summary, refresh_relationship_missing_state
from .relationship_preview import (
    on_relationship_slider_changed,
    poll_relationship_preview,
    request_relationship_preview,
    set_relationship_preview_fields,
    set_relationship_preview_from_projection,
)
from .response_renderer import show_response
from .suggestion_renderer import render_suggestions
from .save_backed_mode import set_save_backed_mode
from .production_action_renderer import append_production_action
from .npc_dossier_renderer import refresh_npc_dossier
from .npc_interaction_history_renderer import refresh_npc_interaction_history
from .operation_lifecycle import (
    operation_finished,
    poll_background_future,
    poll_future,
    show_operation_error,
    start_background_operation,
    start_operation,
)
from .activity_log_view import (
    clear_activity_log,
    poll_activity_log,
    schedule_activity_poll,
)
from .studio_surface_builder import build_studio_editors
from .trace_conversation_builder import build_conversation_trace
from .trace_diagnostic_builder import build_diagnostic_trace
from .simulation_pane_builder import build_simulation_panes
from .simulation_conversation_builder import build_conversation_panel
from .simulation_controls_builder import build_workbench_controls
from .simulation_apply_controller import apply_simulation_settings
from .selection_surface import (
    apply_selection,
    poll_selection_future,
    save_source_selected,
)
from .source_provenance_projection import update_source_provenance
from .simulation_projection import update_simulation_projection
from .scenario_control_projection import scenario_control_value
from .trait_effects_renderer import (
    flatten_trait_effects,
    format_trait_effect_value,
    render_trait_effects,
    write_trait_effects,
)
from .control_state import set_controls
from .persona_matrix_controller import (
    format_compare_result,
    inspect_persona_matrix,
)
from .layout_state_controller import (
    on_main_tab_changed,
    reset_ui_state,
    restore_panel_state,
    restore_splitters,
    restore_ui_state,
    restore_workbench_tabs,
    schedule_splitter_restore,
    toggle_advanced_controls,
    toggle_simulation_workbench,
    toggle_trace_panel,
)
from .ui_state_persistence import (
    remember_active_source,
    save_ui_state,
    schedule_save,
)
from .saved_world_controller import (
    discover_saved_worlds,
    import_saved_world_target,
    inspect_saved_world,
    selected_saved_world_entry,
)
from .worker_ready_controller import (
    initial_saved_pair_requested,
    load_initial_saved_pair,
    remembered_saved_pair_requested,
    restore_remembered_saved_pair,
    set_talk_catalog,
    worker_ready,
)
from .simulation_context_renderer import refresh_simulation_context
from .gift_controller import (
    format_number,
    format_signed,
    gift_result_text,
    gift_selected_inventory_item,
    inventory_delta,
    inventory_item_map,
    relationship_evidence,
)
from .talk_surface_renderer import (
    format_talk_matrix,
    format_talk_start,
    render_talk_choices,
)
from .talk_action_controller import (
    click_talk_choice,
    close_conversation,
    open_conversation,
    run_talk_matrix,
    selected_talk_target,
    start_talk_parity,
    talk_utterance,
)
from .personality_preview_controller import (
    poll_personality_preview,
    request_personality_preview,
    schedule_personality_preview,
)
from .app_initializer import initialize_app
from .surface_builder import build_ui
from .workbench_state import (
    apply_pending_workbench_changes,
    clear_workbench_pending,
    on_workbench_field_dirty,
    pending_control_labels,
    refresh_workbench_feedback,
    schedule_workbench_auto_apply,
    sync_derived_identity_fields,
    update_generated_personality_controls,
)
from .workbench_scenario import (
    collect_workbench_scenario,
    on_npc_profile,
    selected_npc_profile,
    sync_workbench_from_scenario,
)
from .replay_controller import (
    record_replay_step,
    replay_projection_frame,
    replay_step,
)
from .suggestion_controls import ensure_suggestion_buttons, refresh_suggestion_controls
from .suggestion_actions import (
    click_graph_frame,
    click_suggestion,
    on_suggestion_group,
    submit,
)
from .authoring_actions import (
    generate_interaction_spec,
    generate_workflow,
    preview_interaction_spec,
)
from .scenario_persistence import load, reset, save
from .runtime_actions import (
    capture_baseline,
    explain_current_selection,
    preview,
    propose_relationship,
    reset_working_world,
    restart,
    set_language,
    show_snapshot,
)
from .regression_controller import (
    run_regression,
    run_regression_command_rejections,
    run_regression_lifecycle,
    run_regression_selection,
)
from .saved_world_selection_controller import (
    on_saved_world_player,
    on_saved_world_tree_select,
    on_saved_world_view,
    select_saved_world_relationship_category,
)
from .provenance_utils import provenance_value, value_at_path
from .world_knowledge_controller import inspect_world_knowledge
from .flow_catalog_controller import (
    flow_catalog_finished,
    refresh_flow_catalog,
    register_flow_draft,
    validate_flow_draft,
)
from .interaction_module_controller import (
    beat_catalog_finished,
    load_canonical_interaction_definition,
    preview_beat_draft,
    preview_interaction_promotion,
    promote_interaction_definition,
    refresh_beat_catalog,
    register_beat_draft,
    register_behavior_draft,
    validate_beat_draft,
    validate_behavior_draft,
)
from .lifecycle_controller import close_app, run_gui as run_gui_app
from .worker_lifecycle import start_worker, worker_kwargs



class SemanticHarnessApp:
    """Nonblocking Tk adapter over the same session API used by the CLI."""

    def __init__(self, root: Any, arguments: argparse.Namespace) -> None:
        initialize_app(self, root, arguments)

    def _selected_mods(self) -> tuple[str, ...] | None:
        values = getattr(self.arguments, "mods", None) or ()
        selected = tuple(
            item.strip()
            for value in values
            for item in str(value).split(",")
            if item.strip()
        )
        return selected or None

    def _build_ui(self) -> None:
        build_ui(self)

    def _build_saved_world_browser(self, parent: Any) -> None:
        build_saved_world_browser(self, parent)
    def _set_controls(self, enabled: bool) -> None:
        set_controls(self, enabled)

    def _refresh_workbench_feedback(self, message: str | None = None) -> None:
        refresh_workbench_feedback(self, message)

    def _pending_control_labels(self) -> list[str]:
        return pending_control_labels(self)

    def _clear_workbench_pending(self) -> None:
        clear_workbench_pending(self)

    def _schedule_workbench_auto_apply(self) -> None:
        schedule_workbench_auto_apply(self)

    def _apply_pending_workbench_changes(self) -> None:
        apply_pending_workbench_changes(self)

    def _on_workbench_field_dirty(self, field: CatalogControlField) -> None:
        on_workbench_field_dirty(self, field)

    def _sync_derived_identity_fields(self, actor: str) -> None:
        sync_derived_identity_fields(self, actor)

    @staticmethod
    def _format_trait_effect_value(value: Any) -> str:
        return format_trait_effect_value(value)

    def _flatten_trait_effects(self, value: Any, prefix: str = "") -> list[str]:
        return flatten_trait_effects(value, prefix)

    def _write_trait_effects(self, actor: str, lines: list[str]) -> None:
        write_trait_effects(self, actor, lines)

    def _render_trait_effects(self) -> None:
        render_trait_effects(self)
    def _schedule_personality_preview(self) -> None:
        schedule_personality_preview(self)

    def _request_personality_preview(self) -> None:
        request_personality_preview(self)

    def _poll_personality_preview(self, future: Future[Any]) -> None:
        poll_personality_preview(self, future)

    def _ensure_suggestion_buttons(self, count: int) -> None:
        ensure_suggestion_buttons(self, count)

    def _refresh_suggestion_controls(self, enabled: bool) -> None:
        refresh_suggestion_controls(self, enabled)

    @property
    def worker_ready(self) -> bool:
        return self.session.ready and self._worker_initialized

    def _set_status(self, value: str) -> None:
        if hasattr(self, "status_var"):
            self.status_var.set(value)

    def _restore_ui_state(self) -> None:
        restore_ui_state(self)

    def _restore_panel_state(self) -> None:
        restore_panel_state(self)

    def _restore_splitters(self) -> None:
        restore_splitters(self)

    def _schedule_splitter_restore(self, delay_ms: int = 250) -> None:
        schedule_splitter_restore(self, delay_ms)

    def _on_main_tab_changed(self) -> None:
        on_main_tab_changed(self)

    def _restore_workbench_tabs(self) -> None:
        restore_workbench_tabs(self)

    def _save_ui_state(self) -> None:
        save_ui_state(self)

    def _schedule_ui_state_save(self, delay_ms: int = 250) -> None:
        schedule_save(self, delay_ms)

    def _append(self, speaker: str, text: str) -> None:
        self.activity_log.record(
            "ui",
            "conversation",
            speaker=str(speaker),
            message=str(text)[:240],
        )
        entry, removed_chars = self._transcript_buffer.append(speaker, text)
        self.transcript.configure(state="normal")
        if removed_chars:
            self.transcript.delete("1.0", f"1.0 + {removed_chars} chars")
        self.transcript.insert("end", entry)
        self.transcript.see("end")
        self.transcript.configure(state="disabled")

    def _set_text(self, widget: Any, value: str) -> None:
        if widget is getattr(self, "transcript", None):
            self._transcript_buffer.clear()
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("end", value)
        widget.configure(state="disabled")

    def _schedule_activity_poll(self) -> None:
        schedule_activity_poll(self)

    def _poll_activity_log(self) -> None:
        poll_activity_log(self)

    def clear_activity_log(self) -> None:
        clear_activity_log(self)

    def _worker_kwargs(self) -> dict[str, Any]:
        return worker_kwargs(self)

    def _start_worker(self) -> None:
        start_worker(self)

    def _poll_future(self, future: Future[Any], callback: Callable[[Any], None]) -> None:
        poll_future(self, future, callback)

    def _poll_background_future(
        self, future: Future[Any], callback: Callable[[Any], None]
    ) -> None:
        poll_background_future(self, future, callback)

    def _poll_selection_future(self) -> None:
        poll_selection_future(self)

    def _worker_ready(self, result: WorkerReady) -> None:
        worker_ready(self, result)

    def _set_talk_catalog(self) -> None:
        set_talk_catalog(self)

    def _initial_saved_pair_requested(self) -> bool:
        return initial_saved_pair_requested(self)

    def _remembered_saved_pair_requested(self) -> bool:
        return remembered_saved_pair_requested(self)

    def _open_saved_world_browser(self) -> None:
        """Open the saved-world surface and discover saves on first use."""

        self.main_tabs.select(self.world_sources_tab)
        self.world_sources_notebook.select(self.saved_world_tab)
        if not self.worker_ready or self.busy or self.saved_world_entries:
            return
        self._discover_saved_worlds()

    def _load_initial_saved_pair(self) -> None:
        load_initial_saved_pair(self)

    def _restore_remembered_saved_pair(self) -> None:
        restore_remembered_saved_pair(self)

    def _populate_studio_explore(self) -> None:
        from .worker_ready_controller import _populate_studio_explore

        _populate_studio_explore(self)

    def _remember_active_source(
        self,
        kind: str,
        *,
        save_path: str | None = None,
        player_id: str | None = None,
        npc_id: str | None = None,
    ) -> None:
        remember_active_source(
            self,
            kind,
            save_path=save_path,
            player_id=player_id,
            npc_id=npc_id,
        )

    def _discover_saved_worlds(self) -> None:
        discover_saved_worlds(self)

    def _selected_saved_world_entry(self) -> dict[str, Any] | None:
        return selected_saved_world_entry(self)

    def _on_saved_world_save(self) -> None:
        save_source_selected(self, self._selected_saved_world_entry())
        if self.saved_world_save_var.get():
            self._inspect_saved_world()

    def _on_saved_world_player(self) -> None:
        on_saved_world_player(self)

    def _on_saved_world_view(self) -> None:
        on_saved_world_view(self)

    def _select_saved_world_relationship_category(self, category: str) -> None:
        select_saved_world_relationship_category(self, category)

    def _relationship_world_groups(self) -> list[dict[str, Any]]:
        return relationship_world_groups(self)
    def _inspect_saved_world(self) -> None:
        inspect_saved_world(self)

    def _render_saved_world_tree(self) -> None:
        render_saved_world_tree(self)
    def _restore_saved_world_tree_selection(self) -> None:
        _restore_saved_world_tree_selection(self)
    def _render_saved_world_group_details(
        self, group: dict[str, Any] | None
    ) -> None:
        render_saved_world_group_details(self, group)
    def _on_saved_world_tree_select(self) -> None:
        on_saved_world_tree_select(self)

    def _import_saved_world_target(self) -> None:
        import_saved_world_target(self)

    def _selected_talk_target(self) -> str:
        return selected_talk_target(self)

    def _talk_utterance(self) -> str:
        return talk_utterance(self)

    def _render_talk_choices(self, choices: Any) -> None:
        render_talk_choices(self, choices)

    def _click_talk_choice(self, frame: dict[str, Any]) -> None:
        click_talk_choice(self, frame)

    def start_talk_parity(self) -> None:
        start_talk_parity(self)

    def open_conversation(self) -> None:
        open_conversation(self)

    def close_conversation(self) -> None:
        close_conversation(self)

    def apply_selection(self) -> None:
        apply_selection(self)

    def run_talk_matrix(self) -> None:
        run_talk_matrix(self)

    def _format_talk_start(self, result: dict[str, Any]) -> str:
        return format_talk_start(result)

    def _format_talk_matrix(self, result: dict[str, Any]) -> str:
        return format_talk_matrix(result)

    def _scenario_control_value(self, control: dict[str, Any], scenario: dict[str, Any]) -> Any:
        return scenario_control_value(self, control, scenario)
    def _build_simulation_workbench(self) -> None:
        build_simulation_workbench(self)
    def _update_generated_personality_controls(self, *_args: Any) -> None:
        update_generated_personality_controls(self)

    def toggle_simulation_workbench(self) -> None:
        toggle_simulation_workbench(self)

    def _toggle_trace_panel(self) -> None:
        toggle_trace_panel(self)

    def _toggle_advanced_controls(self) -> None:
        toggle_advanced_controls(self)

    def _reset_ui_state(self) -> None:
        reset_ui_state(self)

    def _refresh_simulation_context(self) -> None:
        refresh_simulation_context(self)

    def _selected_npc_profile(self) -> str:
        return selected_npc_profile(self)

    def _sync_workbench_from_scenario(
        self, scenario: dict[str, Any], *, clear_pending: bool = True
    ) -> None:
        sync_workbench_from_scenario(
            self, scenario, clear_pending=clear_pending
        )

    def _actor_source_info(self, path: str, fallback: str = "MISSING") -> dict[str, Any]:
        source_snapshot = getattr(self, "source_snapshot_projection", {})
        if not isinstance(source_snapshot, dict):
            return {"source": fallback}
        provenance = source_snapshot.get("provenance")
        paths = provenance.get("paths") if isinstance(provenance, dict) else {}
        info = paths.get(path) if isinstance(paths, dict) else None
        if isinstance(info, dict):
            return info
        return {"source": fallback}

    @staticmethod
    def _social_context_from_response(response: Any) -> dict[str, Any]:
        return social_context_from_response(response)

    @staticmethod
    def _social_context_lines(social: dict[str, Any]) -> list[str]:
        return social_context_lines(social, SemanticHarnessApp._format_number)
    def _refresh_social_context_summary(self) -> None:
        refresh_social_context_summary(self)

    def _refresh_relationship_missing_state(self) -> None:
        refresh_relationship_missing_state(self)

    @staticmethod
    def _dossier_value(value: Any) -> str:
        if isinstance(value, (dict, list)):
            return pretty(value).replace("\n", " ")
        return str(value)

    def _refresh_npc_dossier(self) -> None:
        refresh_npc_dossier(self)
    def _refresh_npc_interaction_history(self) -> None:
        refresh_npc_interaction_history(self)
    def _on_actor_panel_tab_changed(self, panel_name: str) -> None:
        """Load large production dossier projections only when requested."""

        if panel_name != "NPC Target" or self.save_backed_mode is not True:
            return
        notebook = self.workbench_panel_notebooks.get(panel_name)
        if notebook is None:
            return
        try:
            tab_name = str(notebook.tab(notebook.select(), "text"))
        except Exception:
            return
        if tab_name in {"Dossier", "Interactions"}:
            self._request_npc_dossier_projection()

    def _request_npc_dossier_projection(self) -> None:
        """Refresh the explicit, bounded inspector projection from production Lua."""

        if (
            self.closed
            or self.save_backed_mode is not True
            or not self.session.ready
            or self.busy
        ):
            return

        def finish(response: dict[str, Any]) -> None:
            self._update_simulation_projection(response)

        self._start_operation(
            lambda worker: worker.inspect_npc_dossier(),
            finish,
        )

    def _refresh_npc_dossier_if_selected(self) -> None:
        """Honor a restored Dossier/Interactions tab after save import."""

        if self._npc_dossier_tab_selected():
            self._request_npc_dossier_projection()

    def _refresh_actor_inspectors(self) -> None:
        refresh_actor_inspectors(self)
    def _refresh_faction_context(self) -> None:
        refresh_faction_context(self)
    def _collect_workbench_scenario(self) -> dict[str, Any]:
        return collect_workbench_scenario(self)

    def _on_npc_profile(self) -> None:
        on_npc_profile(self)

    def _record_replay_step(self, step: dict[str, Any]) -> None:
        record_replay_step(self, step)

    @staticmethod
    def _replay_projection_frame(
        worker: LuaSemanticWorker,
        step: dict[str, Any],
    ) -> dict[str, Any] | None:
        return replay_projection_frame(worker, step)

    @classmethod
    def _replay_step(
        cls, worker: LuaSemanticWorker, step: dict[str, Any]
    ) -> dict[str, Any]:
        return replay_step(worker, step)

    def apply_simulation_settings(
        self, replay: bool = False, *, automatic: bool = False
    ) -> None:
        apply_simulation_settings(self, replay, automatic=automatic)
    def _start_operation(
        self,
        operation: Callable[[LuaSemanticWorker], Any],
        callback: Callable[[Any], None],
    ) -> bool:
        return start_operation(self, operation, callback)

    def _start_background_operation(
        self,
        operation: Callable[[LuaSemanticWorker], Any],
        callback: Callable[[Any], None],
    ) -> bool:
        return start_background_operation(self, operation, callback)

    def _operation_finished(self, callback: Callable[[Any], None]) -> Callable[[Any], None]:
        return operation_finished(self, callback)

    def _show_operation_error(self, error: Exception) -> None:
        show_operation_error(self, error)

    @staticmethod
    def _provenance_value(value: Any, depth: int = 2) -> Any:
        return provenance_value(value, depth)

    @staticmethod
    def _value_at_path(value: Any, path: str) -> Any:
        return value_at_path(value, path)

    def _update_source_provenance(self, response: dict[str, Any]) -> None:
        update_source_provenance(self, response)
    def _update_simulation_projection(self, response: dict[str, Any]) -> None:
        update_simulation_projection(self, response)
    def _set_relationship_preview_from_projection(self) -> None:
        set_relationship_preview_from_projection(self)

    def _on_relationship_slider_changed(self, *_args: Any) -> None:
        on_relationship_slider_changed(self, *_args)

    def _request_relationship_preview(self) -> None:
        request_relationship_preview(self)

    def _poll_relationship_preview(self, future: Future[Any]) -> None:
        poll_relationship_preview(self, future)

    def _set_relationship_preview_fields(self, preview: dict[str, Any]) -> None:
        set_relationship_preview_fields(self, preview)
    def _show_response(self, response: dict[str, Any]) -> None:
        show_response(self, response)
    def _npc_dossier_tab_selected(self) -> bool:
        notebook = self.workbench_panel_notebooks.get("NPC Target")
        if notebook is None:
            return False
        try:
            return str(notebook.tab(notebook.select(), "text")) in {
                "Dossier",
                "Interactions",
            }
        except Exception:
            return False

    @staticmethod
    def _inventory_item_map(inventory: Any) -> dict[str, dict[str, Any]]:
        return inventory_item_map(inventory)

    @classmethod
    def _inventory_delta(cls, before: Any, after: Any) -> str:
        return inventory_delta(before, after)

    @staticmethod
    def _format_number(value: Any) -> str:
        return format_number(value)

    @classmethod
    def _format_signed(cls, value: Any) -> str:
        return format_signed(value)

    @classmethod
    def _relationship_evidence(cls, value: Any) -> str:
        return relationship_evidence(value)

    def _gift_result_text(
        self,
        response: dict[str, Any],
        before: dict[str, Any],
        after: dict[str, Any],
        selected_item: dict[str, Any],
        quantity: int,
    ) -> str:
        return gift_result_text(
            self, response, before, after, selected_item, quantity
        )

    def gift_selected_inventory_item(self, item: dict[str, Any], raw_quantity: Any) -> None:
        gift_selected_inventory_item(self, item, raw_quantity)

    def reset_working_world(self) -> None:
        reset_working_world(self)

    def _on_suggestion_group(self) -> None:
        on_suggestion_group(self)

    def _render_suggestions(
        self, response: dict[str, Any], suggestions: dict[str, Any]
    ) -> None:
        render_suggestions(self, response, suggestions)
    def _set_save_backed_mode(self, active: bool) -> None:
        set_save_backed_mode(self, active)
    def _append_production_action(self, response: dict[str, Any]) -> None:
        append_production_action(self, response)

    def submit(self) -> None:
        submit(self)

    def click_suggestion(self, index: int) -> None:
        click_suggestion(self, index)

    def click_graph_frame(self, frame: dict[str, Any]) -> bool:
        return click_graph_frame(self, frame)

    def show_conversation_graph_diagnostics(
        self, diagnostics: dict[str, Any]
    ) -> None:
        self._set_text(self.dialogue_diagnostics, pretty(diagnostics))
        self.trace_tabs.select(self.graph_frame)
        self.graph_tabs.select(self.graph_detail_frame)
        self.graph_detail_tabs.select(self.dialogue_diagnostics_frame)

    def preview(self) -> None:
        preview(self)

    def reset(self) -> None:
        reset(self)

    def load(self) -> None:
        load(self)

    def save(self) -> None:
        save(self)

    def open_runtime_settings(self) -> None:
        show_runtime_settings(self)

    def show_snapshot(self) -> None:
        show_snapshot(self)

    def explain_current_selection(self) -> None:
        explain_current_selection(self)

    def propose_relationship(self) -> None:
        propose_relationship(self)

    def capture_baseline(self) -> None:
        capture_baseline(self)

    def apply_and_replay(self) -> None:
        """Apply the current workbench draft, then replay the latest utterance."""

        self.apply_simulation_settings(replay=True)

    def _comparison_utterance(self) -> str:
        """Return the explicit Compare utterance or the current test input."""

        return (
            self.input_var.get().strip()
            or self.compare_utterance_var.get().strip()
            or self.last_test_utterance.strip()
            or "hello"
        )

    def inspect_persona_matrix(self) -> None:
        inspect_persona_matrix(self)

    def run_regression(self) -> None:
        run_regression(self)

    def run_regression_lifecycle(self) -> None:
        run_regression_lifecycle(self)

    def run_regression_command_rejections(self) -> None:
        run_regression_command_rejections(self)

    def run_regression_selection(self) -> None:
        run_regression_selection(self)

    def _format_compare_result(self, result: dict[str, Any]) -> str:
        return format_compare_result(result)

    def inspect_world_knowledge(self) -> None:
        inspect_world_knowledge(self)

    def refresh_beat_catalog(self) -> None:
        refresh_beat_catalog(self)

    def _beat_catalog_finished(self, response: dict[str, Any]) -> None:
        beat_catalog_finished(self, response)

    def validate_beat_draft(self, definition: dict[str, Any]) -> None:
        validate_beat_draft(self, definition)

    def preview_beat_draft(
        self, definition: dict[str, Any], text: str
    ) -> None:
        preview_beat_draft(self, definition, text)

    def register_beat_draft(self, definition: dict[str, Any]) -> None:
        register_beat_draft(self, definition)

    def validate_behavior_draft(self, definition: dict[str, Any]) -> None:
        validate_behavior_draft(self, definition)

    def register_behavior_draft(self, definition: dict[str, Any]) -> None:
        register_behavior_draft(self, definition)

    def load_canonical_interaction_definition(
        self, record_id: str
    ) -> dict[str, Any]:
        return load_canonical_interaction_definition(self, record_id)

    def preview_interaction_promotion(
        self,
        record_id: str,
        definition: dict[str, Any],
        source_fingerprint: str | None,
    ) -> None:
        preview_interaction_promotion(
            self, record_id, definition, source_fingerprint
        )

    def promote_interaction_definition(
        self,
        record_id: str,
        definition: dict[str, Any],
        source_fingerprint: str | None,
    ) -> None:
        promote_interaction_definition(
            self, record_id, definition, source_fingerprint
        )

    def refresh_flow_catalog(self) -> None:
        refresh_flow_catalog(self)

    def _flow_catalog_finished(self, response: dict[str, Any]) -> None:
        flow_catalog_finished(self, response)

    def validate_flow_draft(self, definition: dict[str, Any]) -> None:
        validate_flow_draft(self, definition)

    def register_flow_draft(self, definition: dict[str, Any]) -> None:
        register_flow_draft(self, definition)

    def preview_interaction_spec(self, spec: dict[str, Any]) -> dict[str, Any]:
        return preview_interaction_spec(self, spec)

    def generate_interaction_spec(self, spec: dict[str, Any]) -> None:
        generate_interaction_spec(self, spec)

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        interaction_spec: dict[str, Any] | None = None,
    ) -> None:
        generate_workflow(self, source_id, block_ids, interaction_spec)

    def set_language(self) -> None:
        set_language(self)

    def inspect_live_worker(self) -> None:
        """Return to the real-worker conversation surface after a build."""
        self.main_tabs.select(self.simulation_tab)
        self._append("SYSTEM", "Live worker inspection is ready in the Simulation tab.")

    def restart(self) -> None:
        restart(self)

    def close(self) -> None:
        close_app(self)


def run_gui(arguments: argparse.Namespace) -> int:
    return run_gui_app(SemanticHarnessApp, arguments)
