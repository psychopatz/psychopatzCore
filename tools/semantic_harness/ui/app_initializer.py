"""Bootstrap the Tk application runtime and its bounded state containers."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.inspection.transcript import TranscriptBuffer
from tools.semantic_harness.runtime.scenario import load_scenario
from tools.semantic_harness.activity import ActivityLog, default_activity_path
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.worker_session import WorkerSession
from .dialogs.catalog_control import CatalogControlField
from .state import load as load_ui_state
from .state import state_path as ui_state_path


def initialize_app(app: Any, root: Any, arguments: argparse.Namespace) -> None:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
    from tkinter.scrolledtext import ScrolledText

    app.root = root
    app._tk = tk
    app._filedialog = filedialog
    app._messagebox = messagebox
    app._ttk = ttk
    app._ScrolledText = ScrolledText
    app.arguments = arguments
    repository = Path(arguments.repository) if arguments.repository else None
    app.authoring_service = SemanticLabAuthoringService(
        repository=repository,
        runtime_root=repository,
        core_repository=(
            Path(arguments.core_repository)
            if getattr(arguments, "core_repository", None)
            else None
        ),
        dynamic_trading_repository=(
            Path(arguments.dynamic_trading_repository)
            if getattr(arguments, "dynamic_trading_repository", None)
            else None
        ),
    )
    app.activity_log = ActivityLog(
        path=default_activity_path(
            app.authoring_service.repository,
            getattr(arguments, "activity_log", None),
        ),
        client="gui",
    )
    app._activity_seen_ids: set[str] = set()
    app._activity_after: Any | None = None
    app.ui_state_path = ui_state_path(
        app.authoring_service.repository,
        Path(arguments.scenario).expanduser() if arguments.scenario else None,
        getattr(arguments, "ui_state", None),
    )
    app._ui_state = (
        {}
        if getattr(arguments, "reset_ui_state", False)
        else load_ui_state(app.ui_state_path)
    )
    # The relationship-category lens is the safe default for state created
    # before the saved-world root/lens contract existed.  Once the user has
    # saved the current UI state, an explicit Saved affiliations choice is
    # preserved normally.
    if app._ui_state.get("saved_world_lens_revision") != 2:
        app._ui_state["saved_world_view"] = "Relationship to Player"
    selected_profile = str(
        getattr(arguments, "preset", None)
        or getattr(arguments, "profile", None)
        or "core"
    ).strip() or "core"
    root.title(f"Semantic Lab — {selected_profile}")
    root.minsize(1080, 700)
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    initial_width = min(1320, max(1080, screen_width - 48))
    initial_height = min(860, max(700, screen_height - 96))
    saved_geometry = app._ui_state.get("geometry")
    if isinstance(saved_geometry, str) and saved_geometry:
        root.geometry(saved_geometry)
    else:
        root.geometry(f"{initial_width}x{initial_height}")
    app.scenario_path = Path(arguments.scenario) if arguments.scenario else None
    app.scenario = load_scenario(app.scenario_path)
    if arguments.language:
        app.scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
    startup_scenario = app.scenario
    startup_kwargs = app._worker_kwargs()
    app.session = WorkerSession(
        lambda: LuaSemanticWorker(startup_scenario, **startup_kwargs)
    )
    app.closed = False
    app.busy = False
    app._background_busy = False
    app._background_future = None
    app._foreground_poll_after = None
    app._background_poll_after = None
    app._start_worker_after = None
    app._startup_after = None
    app._explore_retry_after = None
    app._layout_restore_after = None
    app._restore_workbench_tabs_after = None
    app._restore_ui_state_after = None
    app._worker_initialized = False
    app._production_catalog: dict[str, Any] | None = None
    app.saved_catalog: dict[str, Any] = {}
    app.saved_world_browser: dict[str, Any] = {}
    app.saved_world_entries: list[dict[str, Any]] = []
    app.saved_world_category_rows: dict[str, list[dict[str, Any]]] = {}
    app.saved_world_save_labels: dict[str, dict[str, Any]] = {}
    app.saved_world_selected_actor: dict[str, Any] = {}
    app.saved_world_selected_group: dict[str, Any] = {}
    app.save_backed_mode = False
    app.trace_panel_visible = True
    app.advanced_controls_visible = True
    app.persona_catalog: dict[str, Any] = {}
    app.simulation_control_catalog: dict[str, Any] = {}
    app.talk_catalog: dict[str, Any] = {}
    app.talk_target_ids_by_label: dict[str, str] = {}
    app.simulation_projection: dict[str, Any] = {}
    app.social_context_projection: dict[str, Any] = {}
    app.runtime_relationship_override_projection: dict[str, Any] = {}
    app.npc_dossier_projection: dict[str, Any] = {}
    app.relationship_history_projection: dict[str, Any] = {}
    app.source_snapshot_projection: dict[str, Any] = {}
    app.working_world_projection: dict[str, Any] = {}
    app.provenance_projection: dict[str, Any] = {}
    app.settings_variables: dict[str, Any] = {}
    app.settings_control_widgets: dict[str, Any] = {}
    app.settings_control_fields: dict[str, Any] = {}
    app.workbench_control_fields: dict[str, CatalogControlField] = {}
    app.workbench_controls: list[dict[str, Any]] = []
    app.workbench_panel_notebooks: dict[str, Any] = {}
    app.workbench_expanded = True
    app.last_test_utterance = ""
    app.workbench_status_var: Any | None = None
    app.relationship_preview_var: Any | None = None
    app.relationship_context_summary: Any | None = None
    app.npc_dossier_summary: Any | None = None
    app.npc_interaction_summary: Any | None = None
    app.trait_effects_var: Any | None = None
    app.trait_effects_widget: Any | None = None
    app.trait_effects_widgets: dict[str, Any] = {}
    app.player_social_profile_preview: dict[str, Any] = {}
    app.player_trait_conflicts: list[Any] = []
    app.player_trait_fingerprint = ""
    app.auto_replay_var: Any | None = None
    app._relationship_preview_after: Any | None = None
    app._personality_preview_after: Any | None = None
    app._auto_replay_after: Any | None = None
    app._auto_apply_after: Any | None = None
    app._splitter_restore_after: Any | None = None
    app.replay_steps: list[dict[str, Any]] = []
    app._relationship_preview_future: Any | None = None
    app._personality_preview_future: Any | None = None
    app.generated_personality_preview: dict[str, Any] = {}
    app._workbench_dirty_ids: set[str] = set()
    app._workbench_profile_pending = False
    app._workbench_initializing = False
    app.last_response: dict[str, Any] = {}
    app.settings_window: Any | None = None
    app._future: Any | None = None
    app._transcript_buffer = TranscriptBuffer()
    app.baseline_record: dict[str, Any] = {}
    app.activity_log.record(
        "ui",
        "window_start",
        geometry=root.geometry(),
        state_path=str(app.ui_state_path),
        activity_path=str(app.activity_log.path or ""),
    )
    app._build_ui()
    root.protocol("WM_DELETE_WINDOW", app.close)
    app._set_status("Starting Lua worker…")
    app._start_worker_after = root.after(20, app._start_worker)
