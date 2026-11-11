"""Coordinate Code Builder previews and approved artifact generation."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.rendering import pretty


def preview_interaction_spec(app: Any, spec: dict[str, Any]) -> dict[str, Any]:
    """Preview a configured Studio interaction through the embedded builder."""

    report = app.authoring_service.preview_interaction_spec(
        spec,
        production_catalog=app._production_catalog,
    )
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    return report


def generate_interaction_spec(app: Any, spec: dict[str, Any]) -> None:
    """Write an approved InteractionSpec, then restart the real Lua worker."""

    report = app.authoring_service.generate_interaction_spec(
        spec,
        approved=True,
        production_catalog=app._production_catalog,
    )
    app.interaction_composer.show_generation(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "generation failed"
        app._append("SYSTEM", f"Interaction generation rejected: {message}")
        return
    app._append(
        "SYSTEM",
        f"Generated {len(report.get('writes', []))} interaction artifacts; restarting Lua worker.",
    )
    app.restart()


def generate_workflow(
    app: Any,
    source_id: str,
    block_ids: list[str],
    interaction_spec: dict[str, Any] | None = None,
) -> None:
    """Generate the approved in-app workflow through the shared service."""

    report = app.authoring_service.generate_workflow(
        source_id,
        block_ids,
        approved=True,
        production_catalog=app._production_catalog,
        interaction_spec=interaction_spec,
    )
    app.workflow_pane.show_generation(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "workflow generation failed"
        app._append("SYSTEM", f"Workflow generation rejected: {message}")
        return
    app._append(
        "SYSTEM",
        f"Generated {len(report.get('writes', []))} artifacts; restarting Lua worker.",
    )
    app.restart()
