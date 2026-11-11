"""Load, save, and reset the GUI's in-memory semantic scenario."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from tools.semantic_harness.runtime.scenario import load_scenario, save_scenario
from .suggestion_projection import semantic_hub_diagnostic_projection


def reset(app: Any) -> None:
    if not app.session.ready:
        return

    def finish(response: dict[str, Any]) -> None:
        app.replay_steps.clear()
        app._set_text(app.transcript, "")
        app._set_text(app.inspector, "")
        app._set_text(app.authority, "")
        app._set_text(app.trace, "")
        app._set_text(app.suggestion_inspector, "")
        app._set_text(app.world_knowledge_inspector, "")
        app._set_text(app.dialogue_diagnostics, "")
        app._set_text(app.compare_output, "")
        app.dialogue_graph_pane.clear_graph()
        app._set_text(
            app.hub_diagnostics,
            pretty(semantic_hub_diagnostic_projection({})),
        )
        app._show_response(response)
        app.suggestion_rows = []
        app.suggestion_interactive = False
        app._refresh_workbench_feedback("Scenario reset; replay macro cleared.")
        app.compare_utterance_var.set("hello")
        app._render_suggestions(response, response.get("suggestions") or {})
        app._append("SYSTEM", "Scenario reset.")

    app._start_operation(lambda worker: worker.reset(), finish)


def load(app: Any) -> None:
    filename = app._filedialog.askopenfilename(
        title="Load semantic scenario",
        filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
    )
    if not filename or not app.session.ready or app.busy:
        return
    try:
        scenario = load_scenario(Path(filename))
    except (OSError, ValueError) as error:
        app._messagebox.showerror("Scenario error", str(error))
        return

    def finish(response: dict[str, Any]) -> None:
        app.scenario = scenario
        app.scenario_path = Path(filename)
        app._set_save_backed_mode(False)
        app.replay_steps.clear()
        app._sync_workbench_from_scenario(scenario)
        app._refresh_workbench_feedback("Scenario loaded; replay macro cleared.")
        app._set_text(app.transcript, "")
        app._show_response(response)
        app._append("SYSTEM", f"Loaded {filename}")

    app._start_operation(lambda worker: worker.configure(scenario), finish)


def save(app: Any) -> None:
    """Persist the current in-memory scenario to its JSON scenario store."""

    if app.busy:
        return
    filename = app.scenario_path
    if filename is None:
        selected = app._filedialog.asksaveasfilename(
            title="Save semantic scenario",
            defaultextension=".json",
            filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
        )
        if not selected:
            return
        filename = Path(selected)
    try:
        save_scenario(filename, app.scenario)
    except (OSError, TypeError, ValueError) as error:
        app._messagebox.showerror("Scenario save error", str(error))
        return
    app.scenario_path = filename
    app._set_status(f"Saved scenario · {filename.name}")
    app._append("SYSTEM", f"Saved mock runtime scenario to {filename}")
