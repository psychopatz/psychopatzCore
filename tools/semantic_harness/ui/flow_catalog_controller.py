"""Refresh and mutate the production flow catalog from the GUI."""

from __future__ import annotations

from typing import Any


def refresh_flow_catalog(app: Any) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(lambda worker: worker.flow_catalog(), app._flow_catalog_finished)


def flow_catalog_finished(app: Any, response: dict[str, Any]) -> None:
    app.flow_editor.set_catalog(response)
    app.interaction_explorer.set_catalog(response)
    app.interaction_composer.set_production_catalog(response)
    app.block_registry.set_catalog(response)
    app._production_catalog = response
    app.workflow_pane.set_production_catalog(response)
    app._append(
        "SYSTEM",
        f"Loaded {response.get('flowCount', 0)} normalized production flows.",
    )


def validate_flow_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.validate_flow(definition),
        app.flow_editor.show_validation,
    )


def register_flow_draft(app: Any, definition: dict[str, Any]) -> None:
    if not app.session.ready or app.busy:
        return
    app._start_operation(
        lambda worker: worker.register_flow(definition),
        app.flow_editor.show_registration,
    )
