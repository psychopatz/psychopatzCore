"""Dispatch typed and projected semantic suggestion interactions."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.inspection.tool_calls import format_tool_call
from .suggestion_projection import npc_message_text, semantic_suggestion_title


def submit(app: Any) -> None:
    value = app.input_var.get().strip()
    if not value or not app.session.ready or app.busy:
        return
    app.input_var.set("")
    app.suggestion_group_override_id = None
    app.last_test_utterance = value
    app.compare_utterance_var.set(value)

    def finish(response: dict[str, Any]) -> None:
        app._append("PLAYER", value)
        for message in response.get("messages", []):
            if message.get("speaker") == "npc":
                app._append("NPC", npc_message_text(message))
        for call in response.get("toolCalls", []):
            app._append("TOOL/ACTION", format_tool_call(call))
        app._append_production_action(response)
        if response.get("accepted") is True:
            app._record_replay_step({"kind": "input", "text": value})
        app._show_response(response)

    app._start_operation(lambda worker: worker.input(value), finish)


def click_suggestion(app: Any, index: int) -> None:
    if not app.session.ready or app.busy or not app.suggestion_interactive:
        return
    if index < 0 or index >= len(app.suggestion_rows):
        return
    row = app.suggestion_rows[index]
    frame = row.get("semanticFrame") or row.get("frame")
    if not isinstance(frame, dict) or row.get("enabled") is not True:
        return
    label = semantic_suggestion_title(row)

    def finish(response: dict[str, Any]) -> None:
        if response.get("accepted") is True:
            utterance = (row.get("display") or {}).get("utterance") or label
            app.last_test_utterance = str(utterance)
            presentation_only = str(frame.get("kind") or "") in {
                "semantic_back_click_frame",
                "semantic_group_click_frame",
            }
            if not presentation_only:
                app._append("PLAYER", str(utterance))
            for message in response.get("messages", []):
                if message.get("speaker") == "npc":
                    app._append("NPC", npc_message_text(message))
            for call in response.get("toolCalls", []):
                app._append("TOOL/ACTION", format_tool_call(call))
            app._append_production_action(response)
            app._append("SYSTEM", f"Clicked semantic suggestion: {label}")
            app._record_replay_step(
                {
                    "kind": "suggestion_click",
                    "candidateID": frame.get("candidateID") or row.get("id"),
                    "label": label,
                    "text": str(utterance),
                    "frame": deepcopy(frame),
                }
            )
        else:
            app._append(
                "SYSTEM",
                f"Suggestion rejected: {response.get('reason') or 'unknown'}",
            )
        app._show_response(response)

    app._start_operation(lambda worker: worker.suggestion_click(frame), finish)


def click_graph_frame(app: Any, frame: dict[str, Any]) -> bool:
    """Submit a live graph edge through the exact suggestion-click lane."""

    if not app.session.ready or app.busy or not isinstance(frame, dict):
        return False
    label = str(frame.get("textFallback") or frame.get("candidateID") or "choice")

    def finish(response: dict[str, Any]) -> None:
        if response.get("accepted") is True:
            app.last_test_utterance = label
            app._append("PLAYER", label)
            for message in response.get("messages", []):
                if message.get("speaker") == "npc":
                    app._append("NPC", npc_message_text(message))
            for call in response.get("toolCalls", []):
                app._append("TOOL/ACTION", format_tool_call(call))
            app._append_production_action(response)
            app._record_replay_step(
                {
                    "kind": "suggestion_click",
                    "candidateID": frame.get("candidateID"),
                    "label": label,
                    "text": label,
                    "frame": deepcopy(frame),
                }
            )
        else:
            app._append(
                "SYSTEM",
                f"Graph choice rejected: {response.get('reason') or 'unknown'}",
            )
        app._show_response(response)

    return app._start_operation(
        lambda worker: worker.suggestion_click(frame), finish
    )


def on_suggestion_group(app: Any) -> None:
    if not app.suggestion_projection:
        return
    selected_display = app.suggestion_group_box.get()
    selected_id = app.suggestion_group_ids_by_display.get(selected_display)
    app.suggestion_group_override_id = selected_id
    group = next(
        (
            item
            for item in app.suggestion_projection.get("groups", [])
            if item.get("id") == selected_id
        ),
        None,
    )
    frame = group and group.get("frame")
    if isinstance(frame, dict) and app.session.ready and not app.busy:
        def finish(response: dict[str, Any]) -> None:
            if response.get("accepted") is not True:
                app._append(
                    "SYSTEM",
                    f"Topic selection rejected: {response.get('reason') or 'unknown'}",
                )
            app._show_response(response)

        app._start_operation(
            lambda worker: worker.suggestion_click(frame), finish
        )
        return
    app._render_suggestions(app.suggestion_response, app.suggestion_projection)
