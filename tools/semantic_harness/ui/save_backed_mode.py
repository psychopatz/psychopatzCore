"""Apply save-backed UI mode transitions."""

from __future__ import annotations

from .ui_state_persistence import remember_active_source

def set_save_backed_mode(self, active: bool) -> None:
    """Demote synthetic fixture controls after a real save import."""

    self.save_backed_mode = active
    remember_active_source(self, "SAVE" if active else "FIXTURE")
    self._refresh_relationship_missing_state()

    if active:
        self.fixture_mode_var.set(
            "Save-backed mode active · synthetic fixtures are hidden"
        )
        self.npc_profile_label.grid_remove()
        self.npc_profile_box.grid_remove()
        self.developer_test_frame.grid_remove()
        preferred_trace = self._ui_state.get("trace_panel_visible")
        if isinstance(preferred_trace, bool):
            if preferred_trace != self.trace_panel_visible:
                self._toggle_trace_panel()
        preferred_advanced = self._ui_state.get("advanced_controls_visible")
        if isinstance(preferred_advanced, bool):
            if preferred_advanced != self.advanced_controls_visible:
                self._toggle_advanced_controls()
        self._schedule_splitter_restore()
    else:
        self.fixture_mode_var.set(
            "Synthetic scenario controls · not save-backed authority"
        )
        self.npc_profile_label.grid()
        self.npc_profile_box.grid()
        self.developer_test_frame.grid()
        if not self.trace_panel_visible:
            self._toggle_trace_panel()
        if not self.advanced_controls_visible:
            self._toggle_advanced_controls()
    self._refresh_simulation_context()
    self._refresh_suggestion_controls(self.session.ready and not self.busy)


__all__ = ["set_save_backed_mode"]
