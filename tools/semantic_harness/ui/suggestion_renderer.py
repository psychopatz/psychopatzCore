"""Render bounded semantic suggestion groups and rows."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from .suggestion_projection import (
    conversation_presented_rows,
    semantic_suggestion_rows,
    semantic_suggestion_title,
)


def _diagnostic_inspector_rows(
    suggestions: dict[str, Any],
) -> list[dict[str, Any]]:
    return [
        {
            "id": row.get("id"),
            "action": row.get("action"),
            "label": semantic_suggestion_title(row),
            "status": row.get("status"),
            "enabled": row.get("enabled"),
            "source": row.get("source"),
            "eligibility": row.get("eligibility"),
        }
        for row in semantic_suggestion_rows(suggestions)
    ]


def render_suggestions(
    self, response: dict[str, Any], suggestions: dict[str, Any]
) -> None:
    self.suggestion_projection = suggestions
    self.suggestion_response = response
    observation = response.get("observation") or {}
    presentation = (
        response.get("conversationPresentation")
        or observation.get("conversationPresentation")
    )
    native_presentation = (
        isinstance(presentation, dict)
        and presentation.get("schema") == "semantic.native_conversation_view.v1"
    )
    if native_presentation:
        native_rows = conversation_presented_rows(presentation)
        channel = presentation.get("responseChannel") or {}
        lifecycle = presentation.get("lifecycle") or {}
        self.suggestion_primary_projection = presentation
        self.suggestion_group_override_id = None
        self.suggestion_group_ids_by_display = {}
        self.suggestion_group_box.grid_remove()
        self.suggestion_revision = channel.get("revision")
        self.suggestion_rows = conversation_presented_rows(presentation)
        self._ensure_suggestion_buttons(len(self.suggestion_rows))
        self.suggestion_interactive = (
            lifecycle.get("state") not in {
                "busy",
                "pending",
                "closing",
                "closed",
            }
            and (presentation.get("semanticInput") or {}).get(
                "available", True
            )
            and bool(self.suggestion_rows)
        )
        for index, button in enumerate(self.suggestion_buttons):
            row = (
                self.suggestion_rows[index]
                if index < len(self.suggestion_rows)
                else None
            )
            if row:
                button.configure(text=semantic_suggestion_title(row))
                button.grid()
            else:
                button.configure(text="")
                button.grid_remove()
        if self.suggestion_rows:
            status = (
                f"Response Channel · "
                f"Group {channel.get('groupID') or '—'} · "
                f"Revision {channel.get('revision', '—')} · "
                f"{len(self.suggestion_rows)} presented"
            )
        else:
            status = "No conversation open · Response Channel has 0 native rows"
        self.suggestion_status.configure(text=status)
        self._set_text(
            self.suggestion_inspector,
            pretty(
                {
                    "productionPresentation": presentation,
                    "diagnosticProjection": suggestions,
                    "diagnosticRows": _diagnostic_inspector_rows(suggestions),
                    "visualRows": [
                        {
                            "id": row.get("id"),
                            "label": semantic_suggestion_title(row),
                            "enabled": row.get("enabled"),
                            "semanticFrame": row.get("semanticFrame"),
                        }
                        for row in self.suggestion_rows
                    ],
                }
            ),
        )
        self._refresh_suggestion_controls(
            self.session.ready and not self.busy
        )
        return

    # Diagnostic suggestions remain available in Inspect → Predicates, but
    # they are never promoted to clickable rows in the native Response
    # Channel.  This is also the safe state for fixture input before the
    # production Conversation session has been opened.
    self.suggestion_primary_projection = (
        None
    )
    self.suggestion_group_ids_by_display = {}
    self.suggestion_group_override_id = None
    self.suggestion_group_box.configure(values=())
    self.suggestion_group_box.set("")
    self.suggestion_group_box.grid_remove()
    self.suggestion_revision = suggestions.get("revision")
    self.suggestion_rows = []
    self.suggestion_interactive = False
    for button in self.suggestion_buttons:
        button.configure(text="", state="disabled")
        button.grid_remove()
    trace_count = len(suggestions.get("predicateTrace") or [])
    self.suggestion_status.configure(
        text=(
            "No conversation open · diagnostic suggestions are available "
            f"under Inspect → Predicates ({trace_count} bounded trace rows)"
        )
    )
    self._set_text(
        self.suggestion_inspector,
        pretty(
            {
                "nativePresentation": (
                    presentation if isinstance(presentation, dict) else None
                ),
                "diagnosticProjection": suggestions,
                "diagnosticRows": _diagnostic_inspector_rows(suggestions),
                "playerFacingResponseChannel": {
                    "visibleRows": [],
                    "reason": "native_conversation_presentation_unavailable",
                },
            }
        ),
    )
    self._refresh_suggestion_controls(self.session.ready and not self.busy)


__all__ = ["render_suggestions"]
