"""Apply simulation workbench changes through the semantic worker."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.inspection.tool_calls import format_tool_call
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from .suggestion_projection import npc_message_text


def apply_simulation_settings(
    app: Any, replay: bool = False, *, automatic: bool = False
) -> None:
    """Apply catalog-backed state and optionally replay the dialogue."""

    if not app.session.ready or app.busy:
        if automatic and not app.busy:
            app._schedule_workbench_auto_apply()
        return
    current_text = app.input_var.get().strip()
    value = current_text or app.last_test_utterance.strip()
    target_id = app._selected_talk_target()
    steps = deepcopy(app.replay_steps)
    if replay and current_text:
        if not steps or steps[-1].get("text") != current_text:
            steps.append({"kind": "input", "text": current_text})
    if replay and not steps and value:
        steps = [{"kind": "input", "text": value}]
    if replay and not steps:
        app.workbench_status_var.set("Record a dialogue step before replaying.")
        return
    try:
        updated = app._collect_workbench_scenario()
    except (TypeError, ValueError, app._tk.TclError) as error:
        app._messagebox.showerror("Simulation workbench", str(error))
        return
    relationship_dirty = bool(
        app._workbench_dirty_ids
        & {
            "relationship.approval",
            "relationship.respect",
            "relationship.familiarity",
        }
    )
    app.activity_log.record(
        "ui",
        "apply_started",
        replay=replay,
        automatic=automatic,
        pending=", ".join(app._pending_control_labels()),
    )

    def operation(worker: LuaSemanticWorker) -> dict[str, Any]:
        configured = worker.configure(updated)
        runtime_override = None
        if app.save_backed_mode and relationship_dirty:
            relationship = updated.get("npc", {}).get("relationship", {})
            runtime_override = worker.apply_runtime_relationship_baseline(
                {
                    key: relationship.get(key)
                    for key in ("approval", "respect", "familiarity")
                },
                npc_id=updated.get("npc", {}).get("npcID"),
            )
            configured = runtime_override
        if not replay:
            # CONFIG resets the production conversation view. Fetch that
            # same view once so automatic edits cannot leave stale
            # suggestions, graph nodes, or projection text on screen.
            return {
                "configured": configured,
                "runtimeOverride": runtime_override,
                "snapshot": worker.snapshot(),
            }
        # Replays are a production Conversation session, not a shortcut
        # through the broad diagnostic candidate projection. Re-open the
        # native session after CONFIG so recorded input/click frames execute
        # against the same presentation boundary as the primary UI.
        opened = worker.open_conversation(target_id)
        step_results: list[dict[str, Any]] = []
        for step in steps:
            response = app._replay_step(worker, step)
            step_results.append({"step": step, "response": response})
            if response.get("accepted") is not True:
                break
        return {
            "configured": configured,
            "runtimeOverride": runtime_override,
            "opened": opened,
            "steps": step_results,
            "snapshot": worker.snapshot(),
        }

    def finish(result: dict[str, Any]) -> None:
        final_snapshot = result.get("snapshot") or {}
        effective_scenario = (
            final_snapshot.get("scenario")
            if isinstance(final_snapshot, dict)
            and isinstance(final_snapshot.get("scenario"), dict)
            else updated
        )
        app.scenario = effective_scenario
        configured = result.get("configured") or {}
        rendered_state = final_snapshot if isinstance(final_snapshot, dict) else configured
        app._update_simulation_projection(rendered_state)
        app._sync_workbench_from_scenario(effective_scenario)
        if replay:
            response = {}
            app._set_text(app.transcript, "")
            app._append(
                "SYSTEM",
                f"Replaying {len(result.get('steps') or [])} recorded dialogue steps.",
            )
            for item in result.get("steps") or []:
                step = item.get("step") or {}
                step_response = item.get("response") or {}
                response = step_response
                if step_response.get("accepted") is not True:
                    app._append(
                        "SYSTEM",
                        f"Replay step rejected: {step_response.get('reason') or 'unknown'}",
                    )
                    break
                step_kind = str(step.get("kind") or "input")
                frame_kind = str(
                    (step.get("frame") or {}).get("kind") or ""
                )
                if step_kind == "input" or frame_kind not in {
                    "semantic_back_click_frame",
                    "semantic_group_click_frame",
                }:
                    text = str(
                        step.get("text")
                        or step.get("label")
                        or step.get("candidateID")
                        or "choice"
                    )
                    app.last_test_utterance = text
                    app._append("PLAYER", text)
                elif frame_kind == "semantic_back_click_frame":
                    for message in step_response.get(
                        "transcriptMessages", []
                    ):
                        if message.get("speaker") == "player":
                            app._append(
                                "PLAYER",
                                str(message.get("value") or ""),
                            )
                for message in step_response.get("messages", []):
                    if message.get("speaker") == "npc":
                        app._append("NPC", npc_message_text(message))
                for call in step_response.get("toolCalls", []):
                    app._append("TOOL/ACTION", format_tool_call(call))
                app._append_production_action(step_response)
            app.input_var.set("")
            replay_suggestions = (
                response.get("observation", {}).get("suggestions", {})
                if isinstance(response, dict)
                else {}
            )
            replay_group_id = replay_suggestions.get("currentGroupID")
            app.suggestion_group_override_id = (
                replay_group_id
                if any(
                    isinstance(group, dict)
                    and group.get("id") == replay_group_id
                    for group in replay_suggestions.get("groups", []) or []
                )
                else None
            )
            app._show_response(response)
            app._append(
                "SYSTEM",
                f"Applied simulation context and replayed {len(result.get('steps') or [])} steps.",
            )
            app._refresh_workbench_feedback(
                "Applied and replayed through the Lua worker."
            )
        else:
            response = rendered_state
            # The worker reset is authoritative, so clear the old visual
            # conversation and render the returned production snapshot.
            app._set_text(app.transcript, "")
            app._show_response(response)
            message = (
                "Auto-applied staged changes through the Lua worker."
                if automatic
                else "Applied simulation workbench settings to the Lua worker."
            )
            app._append("SYSTEM", message)
            app._refresh_workbench_feedback(
                "Auto-applied staged changes through the Lua worker."
                if automatic
                else "Applied to the Lua worker."
            )
        app.activity_log.record(
            "ui",
            "apply_completed",
            replay=replay,
            automatic=automatic,
            message="simulation settings applied",
        )

    app._refresh_workbench_feedback(
        "Applying staged changes through the Lua worker…"
    )
    app._start_operation(operation, finish)
