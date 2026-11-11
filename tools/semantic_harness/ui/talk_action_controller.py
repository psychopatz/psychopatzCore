"""Coordinate native Talk parity actions through the worker."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from .suggestion_projection import npc_message_text


def selected_talk_target(app: Any) -> str:
    return app.talk_target_ids_by_label.get(app.talk_target_var.get(), "current")


def talk_utterance(app: Any) -> str:
    return (
        app.talk_utterance_var.get().strip()
        or app.input_var.get().strip()
        or app.last_test_utterance.strip()
        or "hello"
    )


def click_talk_choice(app: Any, frame: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return

    def finish(response: dict[str, Any]) -> None:
        scenario = response.get("scenario")
        if isinstance(scenario, dict):
            app.scenario = scenario
            app._sync_workbench_from_scenario(scenario)
        if response.get("accepted") is not True:
            app._append(
                "SYSTEM",
                f"Talk choice rejected: {response.get('reason') or 'unknown'}",
            )
        app._show_response(response)
        observation = response.get("observation") or {}
        app._render_talk_choices(observation.get("choices") or [])
        app._set_text(app.talk_output, "Talk choice\n\n" + pretty(response))

    app._start_operation(
        lambda worker: worker.suggestion_click(frame), finish
    )


def start_talk_parity(app: Any) -> None:
    """Start one production Talk target and show its opening evidence."""

    if not app.session.ready or app.busy:
        return
    target_id = app._selected_talk_target()
    utterance = app._talk_utterance()
    app.activity_log.record(
        "ui", "talk_start_requested", target=target_id, utterance=utterance
    )

    def finish(result: dict[str, Any]) -> None:
        scenario = result.get("scenario")
        if isinstance(scenario, dict):
            app.scenario = scenario
            app._sync_workbench_from_scenario(scenario)
        start = result.get("start") or {}
        opening = start.get("opening") or {}
        for message in opening.get("messages") or []:
            if isinstance(message, dict) and message.get("speaker") == "npc":
                app._append("NPC", npc_message_text(message))
        turn = result.get("turn") or {}
        if isinstance(turn, dict):
            display_turn = dict(turn)
            display_turn["conversationPresentation"] = result.get(
                "conversationPresentation"
            )
            app._show_response(display_turn)
        observation = result.get("observation") or {}
        app._render_talk_choices(
            observation.get("choices") or opening.get("choices") or []
        )
        app._set_text(app.talk_output, app._format_talk_start(result))
        app.trace_tabs.select(app.compare_frame)
        app.compare_tabs.select(app.talk_parity_frame)
        target = (result.get("start") or {}).get("target") or {}
        app._append(
            "SYSTEM",
            f"Talk parity started: {target.get('label') or target_id} · "
            f"route {target.get('route') or 'unknown'}",
        )
        app.activity_log.record(
            "ui",
            "talk_start_completed",
            target=target_id,
            route=target.get("route"),
        )

    app._start_operation(
        lambda worker: worker.talk_start(target_id, utterance), finish
    )


def open_conversation(app: Any) -> None:
    """Open the production Conversation session for the primary surface."""

    if not app.session.ready:
        app._set_status("Conversation unavailable · Lua worker is still starting")
        app._append("SYSTEM", "Conversation cannot open until the Lua worker is ready.")
        return
    if app.busy:
        app._set_status("Conversation unavailable · another operation is running")
        app._append("SYSTEM", "Conversation open skipped because another operation is running.")
        return
    target_id = app._selected_talk_target()
    app.activity_log.record(
        "ui", "conversation_open_requested", target=target_id
    )
    app._set_status(f"Opening conversation · {target_id}")

    def finish(result: dict[str, Any]) -> None:
        presentation = result.get("presentation")
        if not isinstance(presentation, dict):
            presentation = {}
        opening = presentation.get("opening") or {}
        lifecycle = presentation.get("lifecycle") or {}
        if lifecycle.get("state") != "active":
            reason = (
                lifecycle.get("reason")
                or result.get("reason")
                or "production conversation did not become active"
            )
            app._set_status("Conversation open failed")
            if hasattr(app, "selection_status_var"):
                app.selection_status_var.set(f"Conversation open failed: {reason}")
            app._set_text(app.talk_output, "Conversation open failed\n\n" + pretty(result))
            app._append("ERROR", f"Conversation open failed: {reason}")
            app.activity_log.record(
                "ui", "conversation_open_failed", target=target_id, reason=reason
            )
            return
        for message in opening.get("messages") or []:
            if isinstance(message, dict) and message.get("speaker") == "npc":
                app._append("NPC", npc_message_text(message))
        # Preserve the complete production response while adding the field
        # expected by the shared response-channel renderer.
        rendered = dict(result)
        rendered["accepted"] = True
        rendered["conversationPresentation"] = presentation
        app._show_response(rendered)
        app._set_text(app.talk_output, "Conversation open\n\n" + pretty(result))
        app.main_tabs.select(app.simulation_tab)
        app._set_status(
            f"Conversation active · {len((presentation.get('responseChannel') or {}).get('rows') or [])} choices"
        )
        app._append("SYSTEM", f"Conversation opened: {target_id}")
        app.activity_log.record(
            "ui",
            "conversation_open_completed",
            target=target_id,
            choices=len((presentation.get("responseChannel") or {}).get("rows") or []),
        )

    app._start_operation(
        lambda worker: worker.open_conversation(target_id), finish
    )


def close_conversation(app: Any) -> None:
    """Close the active production Conversation session through Lua."""

    if not app.session.ready:
        app._set_status("Conversation unavailable · Lua worker is still starting")
        return
    if app.busy:
        app._set_status("Conversation unavailable · another operation is running")
        return

    def finish(result: dict[str, Any]) -> None:
        app._show_response(result)
        app._set_text(app.talk_output, "Conversation closed\n\n" + pretty(result))
        app._set_status("Conversation closed")
        app._append("SYSTEM", "Conversation closed.")

    app._start_operation(lambda worker: worker.close_conversation(), finish)


def run_talk_matrix(app: Any) -> None:
    """Compare the native Talk start across the normal production types."""

    if not app.session.ready or app.busy:
        return
    utterance = app._talk_utterance()
    app.activity_log.record("ui", "talk_matrix_requested", utterance=utterance)

    def finish(result: dict[str, Any]) -> None:
        app._set_text(app.talk_output, app._format_talk_matrix(result))
        app.trace_tabs.select(app.compare_frame)
        app.compare_tabs.select(app.talk_parity_frame)
        rows = result.get("rows") if isinstance(result, dict) else []
        app._append(
            "SYSTEM",
            "Talk parity comparison completed: "
            f"{len(rows) if isinstance(rows, list) else 0} target types.",
        )
        app.activity_log.record(
            "ui",
            "talk_matrix_completed",
            rowCount=len(rows) if isinstance(rows, list) else 0,
        )

    app._start_operation(
        lambda worker: worker.talk_matrix(text=utterance), finish
    )
