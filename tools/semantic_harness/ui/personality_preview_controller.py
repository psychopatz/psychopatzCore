"""Schedule and apply production personality previews for draft controls."""

from __future__ import annotations

from concurrent.futures import Future
from typing import Any

from tools.semantic_harness.runtime.config import ConfigurationError
from tools.semantic_harness.process import HarnessError


def schedule_personality_preview(app: Any) -> None:
    if app._personality_preview_after is not None:
        try:
            app.root.after_cancel(app._personality_preview_after)
        except app._tk.TclError:
            pass
    app._personality_preview_after = app.root.after(
        120, app._request_personality_preview
    )


def request_personality_preview(app: Any) -> None:
    app._personality_preview_after = None
    if app.closed or not app.worker_ready or app.busy:
        return
    if app._personality_preview_future is not None:
        if not app._personality_preview_future.done():
            app._personality_preview_after = app.root.after(
                120, app._request_personality_preview
            )
            return
    try:
        staged = app._collect_workbench_scenario()
    except (TypeError, ValueError, app._tk.TclError):
        return
    try:
        future = app.session.submit(
            lambda worker: worker.persona_preview(staged)
        )
    except (HarnessError, RuntimeError):
        return
    app._personality_preview_future = future
    app._poll_personality_preview(future)


def poll_personality_preview(app: Any, future: Future[Any]) -> None:
    if app.closed:
        return
    if not future.done():
        app.root.after(25, app._poll_personality_preview, future)
        return
    try:
        result = future.result()
        value = result.value if hasattr(result, "value") else result
    except (HarnessError, ConfigurationError, OSError, ValueError):
        return
    preview = value.get("personality") if isinstance(value, dict) else None
    app.generated_personality_preview = (
        dict(preview) if isinstance(preview, dict) else {}
    )
    if isinstance(value, dict):
        player_profile = value.get("playerSocialProfile")
        app.player_social_profile_preview = (
            dict(player_profile) if isinstance(player_profile, dict) else {}
        )
        conflicts = value.get("playerTraitConflicts")
        app.player_trait_conflicts = (
            list(conflicts) if isinstance(conflicts, list) else []
        )
        app.player_trait_fingerprint = str(
            value.get("playerTraitFingerprint") or ""
        )
        for control in app.workbench_controls:
            control_id = str(control.get("id") or "")
            if not control_id.startswith("player.socialProfile."):
                continue
            field = app.workbench_control_fields.get(control_id)
            if field is not None:
                field.set_value(app._scenario_control_value(control, app.scenario))
    app._update_generated_personality_controls()
    app._render_trait_effects()
