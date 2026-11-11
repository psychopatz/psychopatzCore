"""Refresh and mutate production beat/behavior catalogs from Semantic Lab."""

from __future__ import annotations

from typing import Any


def refresh_beat_catalog(app: Any) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.beat_catalog(),
        app._beat_catalog_finished,
    )


def beat_catalog_finished(app: Any, response: dict[str, Any]) -> None:
    app.interaction_modules.set_catalog(response)
    app._beat_catalog = response
    app._append(
        "SYSTEM",
        (
            f"Loaded {response.get('beatCount', 0)} production beats and "
            f"{response.get('behaviorCount', 0)} reusable behaviors."
        ),
    )


def validate_beat_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.validate_beat(definition),
        app.interaction_modules.show_validation,
    )


def preview_beat_draft(
    app: Any, definition: dict[str, Any], text: str
) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.preview_beat(definition, text),
        app.interaction_modules.show_preview,
    )


def register_beat_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.register_beat(definition),
        app.interaction_modules.show_registration,
    )


def validate_behavior_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.validate_behavior(definition),
        app.interaction_modules.show_behavior_validation,
    )


def register_behavior_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.register_behavior(definition),
        app.interaction_modules.show_behavior_registration,
    )


def load_canonical_interaction_definition(
    app: Any, record_id: str
) -> dict[str, Any]:
    return app.authoring_service.load_interaction_definition(record_id)


def preview_interaction_promotion(
    app: Any,
    record_id: str,
    definition: dict[str, Any],
    source_fingerprint: str | None,
) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_background_operation(
        lambda _worker: app.authoring_service.preview_interaction_definition_edit(
            record_id,
            definition,
            expected_source_fingerprint=source_fingerprint,
        ),
        app.interaction_modules.show_promotion_preview,
    )


def promote_interaction_definition(
    app: Any,
    record_id: str,
    definition: dict[str, Any],
    source_fingerprint: str | None,
) -> None:
    if not app.session.ready or app.busy:
        return

    def finish(report: dict[str, Any]) -> None:
        app.interaction_modules.show_promotion_result(report)
        if report.get("ok") is True:
            app._append(
                "SYSTEM",
                f"Promoted canonical interaction definition {record_id}; "
                "restarting the Lua worker from regenerated Conversation artifacts.",
            )
            app.restart()

    app._start_background_operation(
        lambda _worker: app.authoring_service.write_interaction_definition_edit(
            record_id,
            definition,
            expected_source_fingerprint=source_fingerprint,
        ),
        finish,
    )
