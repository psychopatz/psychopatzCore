"""Present a worker response across the shell inspector surfaces."""

from __future__ import annotations

from typing import Any

from ..inspection.conversation_inspector import build_conversation_inspector
from tools.semantic_harness.inspection.rendering import conversation_first, pretty
from .suggestion_projection import semantic_hub_diagnostic_projection
from .interaction_inspector import update_interaction_inspector

def show_response(self, response: dict[str, Any]) -> None:
    self.last_response = response if isinstance(response, dict) else {}
    response_scenario = self.last_response.get("scenario")
    if isinstance(response_scenario, dict):
        self.scenario = response_scenario
    self._update_simulation_projection(self.last_response)
    relationship_field = self.workbench_control_fields.get("relationship.state")
    if relationship_field is not None:
        relationship_control = next(
            (
                control for control in self.workbench_controls
                if control.get("id") == "relationship.state"
            ),
            None,
        )
        if relationship_control is not None:
            relationship_field.set_value(
                self._scenario_control_value(relationship_control, self.scenario)
            )
    inspector_record = dict(self.last_response)
    inspector_record["personaCatalog"] = self.persona_catalog
    view = build_conversation_inspector(inspector_record)
    self._set_text(self.inspector, conversation_first(view))
    self._set_text(self.authority, pretty(view.get("commandAuthority", {})))
    self._set_text(self.trace, pretty(response))
    observation = response.get("observation") or {}
    if hasattr(self, "interaction_inspector_text"):
        update_interaction_inspector(self, response)
    conversation_graph = observation.get("conversationGraph")
    if conversation_graph is None:
        conversation_graph = response.get("conversationGraph")
    if isinstance(conversation_graph, dict):
        self.dialogue_graph_pane.set_graph(conversation_graph)
    # The primary button surface is always the production-native Response
    # Channel. Diagnostic/contextual projections are rendered in Inspect.
    self.suggestion_frame.configure(text="Response Channel")
    suggestions = (
        observation.get("suggestions")
        or response.get("suggestions")
        or {}
    )
    hub_diagnostics = semantic_hub_diagnostic_projection(suggestions)
    self._set_text(self.hub_diagnostics, pretty(hub_diagnostics))
    self._render_suggestions(response, suggestions)
    if isinstance(conversation_graph, dict):
        self.trace_tabs.select(self.graph_frame)
        self.graph_tabs.select(self.dialogue_graph_frame)
    elif hub_diagnostics.get("activeHub") is not None:
        self.trace_tabs.select(self.graph_frame)
        self.graph_tabs.select(self.graph_detail_frame)
        self.graph_detail_tabs.select(self.hub_diagnostics_frame)
    if (
        self.save_backed_mode is True
        and "npcDossier" not in response
        and self._npc_dossier_tab_selected()
    ):
        self._request_npc_dossier_projection()


__all__ = ["show_response"]
