"""Apply worker capabilities to the GUI after startup."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from tools.semantic_harness.worker_session import WorkerReady
from .ui_state_persistence import remember_active_source


def worker_ready(app: Any, result: WorkerReady) -> None:
    app._worker_initialized = True
    app._workbench_initializing = True
    app.persona_catalog = result.capabilities.get("personaCatalog") or {}
    app.simulation_control_catalog = (
        result.capabilities.get("simulationControlCatalog") or {}
    )
    app.talk_catalog = result.capabilities.get("talkCatalog") or {}
    app._set_talk_catalog()
    app._update_simulation_projection(result.capabilities)
    app._build_simulation_workbench()
    app._set_status(f"Ready · Lua PID {result.status.get('pid')}")
    app._set_controls(True)
    app.root.update_idletasks()
    app._restore_splitters()
    app._clear_workbench_pending()
    app._workbench_initializing = False
    app._append("SYSTEM", "Lua worker ready. Production semantic modules are loaded.")

    if app._initial_saved_pair_requested():
        app._append(
            "SYSTEM",
            "Explicit saved pair requested. Loading the read-only source save…",
        )
    elif app._remembered_saved_pair_requested():
        app._append("SYSTEM", "Restoring saved target…")
    else:
        app._append(
            "SYSTEM",
            "Fixture mode is active. Load a saved Player/NPC pair from "
            "Load saved NPC to exercise production rehydration.",
        )

    # Keep the diagnostic capability projection available to Inspect, but do
    # not turn it into an accepted turn or a player-facing button set.
    app._render_suggestions(
        {
            "type": "worker_ready",
            "accepted": False,
            "conversationPresentation": result.capabilities.get(
                "conversationPresentation"
            ),
        },
        result.capabilities.get("suggestions") or {},
    )

    capabilities = result.capabilities or {}
    flow_catalog = capabilities.get("flowCatalog", {})
    beat_catalog = capabilities.get("beatCatalog", {})
    app._set_text(
        app.inspector,
        pretty(
            {
                "state": "ready",
                "worker": result.status,
                "flows": flow_catalog.get("flowCount", 0),
                "beats": beat_catalog.get("beatCount", 0),
                "behaviors": beat_catalog.get("behaviorCount", 0),
                "engineFacts": len(flow_catalog.get("factCatalog", [])),
                "engineEvents": len(flow_catalog.get("eventCatalog", [])),
                "commands": len(flow_catalog.get("commandCatalog", [])),
                "hint": "Use Studio → Advanced → Flow editor to build and validate production branches.",
            }
        ),
    )
    app._set_text(app.trace, pretty(capabilities))
    app.flow_editor.set_catalog(flow_catalog)
    app.interaction_modules.set_catalog(beat_catalog)
    app._beat_catalog = beat_catalog
    app.interaction_explorer.set_catalog(flow_catalog)
    app.interaction_composer.set_production_catalog(flow_catalog)
    app.block_registry.set_catalog(flow_catalog)
    app._production_catalog = flow_catalog
    app.workflow_pane.set_production_catalog(flow_catalog)

    if app._initial_saved_pair_requested():
        app._startup_after = app.root.after_idle(app._load_initial_saved_pair)
    elif app._remembered_saved_pair_requested():
        app._startup_after = app.root.after_idle(app._restore_remembered_saved_pair)
    else:
        app._startup_after = app.root.after_idle(app._populate_studio_explore)


def set_talk_catalog(app: Any) -> None:
    """Populate the Talk parity selector from the production catalog."""

    rows = app.talk_catalog.get("targets", [])
    if not isinstance(rows, list):
        rows = []
    labels: list[str] = []
    app.talk_target_ids_by_label = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        target_id = str(row.get("id") or "")
        label = str(row.get("label") or target_id)
        if not target_id or label in app.talk_target_ids_by_label:
            continue
        labels.append(label)
        app.talk_target_ids_by_label[label] = target_id
    if not labels:
        labels = ["Current target"]
        app.talk_target_ids_by_label[labels[0]] = "current"
    app.talk_target_box.configure(values=tuple(labels))
    wanted = str(app._ui_state.get("talk_target") or "current")
    selected = next(
        (
            label
            for label, target_id in app.talk_target_ids_by_label.items()
            if target_id == wanted
        ),
        labels[0],
    )
    app.talk_target_var.set(selected)


def initial_saved_pair_requested(app: Any) -> bool:
    return bool(
        getattr(app.arguments, "gui", False)
        and app.arguments.save
        and app.arguments.player
        and app.arguments.npc
    )


def remembered_saved_pair_requested(app: Any) -> bool:
    """Return whether startup should restore the prior active SAVE intent."""

    return bool(
        not app._initial_saved_pair_requested()
        and str(app._ui_state.get("active_source_kind") or "").upper()
        == "SAVE"
    )


def _normalized_save_path(value: str | Path) -> Path:
    path = Path(str(value)).expanduser().resolve()
    if path.is_dir():
        path = path / "global_mod_data.bin"
    return path


def _set_restore_status(app: Any, message: str) -> None:
    for name in ("saved_world_target_var", "saved_world_status_var"):
        variable = getattr(app, name, None)
        if variable is not None:
            variable.set(message)
    if hasattr(app, "simulation_context_var"):
        app.simulation_context_var.set(message)


def load_initial_saved_pair(app: Any) -> None:
    """Load an explicit GUI ``--save --player --npc`` pair."""

    if not app._initial_saved_pair_requested() or not app.worker_ready:
        return
    _start_saved_pair_import(
        app,
        _normalized_save_path(str(app.arguments.save)),
        str(app.arguments.player),
        str(app.arguments.npc),
        remembered=False,
    )


def restore_remembered_saved_pair(app: Any) -> None:
    """Rebuild the remembered SAVE source through the existing importer."""

    if not app._remembered_saved_pair_requested() or not app.worker_ready:
        return
    state = app._ui_state
    save_value = str(state.get("saved_world_save_path") or "").strip()
    player_uuid = str(state.get("saved_world_player_id") or "").strip()
    npc_id = str(state.get("saved_world_npc_id") or "").strip()
    missing = [
        label
        for label, value in (
            ("save path", save_value),
            ("Player ID", player_uuid),
            ("NPC ID", npc_id),
        )
        if not value
    ]
    if missing:
        _saved_pair_restore_failed(
            app,
            "remembered SAVE target is incomplete (missing "
            + ", ".join(missing)
            + ")",
            remembered=True,
        )
        _populate_studio_explore(app)
        return
    _start_saved_pair_import(
        app,
        _normalized_save_path(save_value),
        player_uuid,
        npc_id,
        remembered=True,
    )


def _start_saved_pair_import(
    app: Any,
    save_path: Path,
    player_uuid: str,
    npc_id: str,
    *,
    remembered: bool,
) -> None:
    _set_restore_status(
        app,
        "Restoring saved target…"
        if remembered
        else f"Loading saved Player {player_uuid} → NPC {npc_id}",
    )

    def operation(worker: Any) -> dict[str, Any]:
        try:
            return worker.import_saved_selection(
                save_path,
                player_uuid=player_uuid,
                npc_id=npc_id,
            )
        except Exception as error:  # external read-only save boundary
            return {
                "ok": False,
                "restoreError": str(error)[:400],
            }

    def finish(result: dict[str, Any]) -> None:
        error = result.get("restoreError") if isinstance(result, dict) else None
        if error:
            _saved_pair_restore_failed(
                app,
                str(error),
                remembered=remembered,
            )
            _populate_studio_explore(app)
            return
        _apply_saved_pair(app, result, save_path, player_uuid, npc_id)
        _populate_studio_explore(app)

    if not app._start_operation(operation, finish) and not app.closed:
        app.root.after(
            50,
            lambda: _start_saved_pair_import(
                app,
                save_path,
                player_uuid,
                npc_id,
                remembered=remembered,
            ),
        )


def _apply_saved_pair(
    app: Any,
    result: dict[str, Any],
    save_path: Path,
    player_uuid: str,
    npc_id: str,
) -> None:
    scenario = result.get("scenario")
    if isinstance(scenario, dict):
        app.scenario = scenario
        app._sync_workbench_from_scenario(scenario)
    app._update_simulation_projection(result)
    app._set_save_backed_mode(True)
    source = (result.get("sourceSnapshot") or {}).get("metadata", {})
    resolved_path = str(source.get("savePath") or save_path)
    resolved_player = str(source.get("playerUUID") or player_uuid)
    resolved_npc = str(source.get("npcID") or npc_id)
    remember_active_source(
        app,
        "SAVE",
        save_path=resolved_path,
        player_id=resolved_player,
        npc_id=resolved_npc,
    )
    app.saved_world_browser = {
        "source": "SAVE",
        "sourceKind": "SAVE",
        "path": resolved_path,
        "saveName": Path(resolved_path).parent.name,
    }
    app._refresh_npc_dossier_if_selected()
    player = app.scenario.get("player", {})
    npc = app.scenario.get("npc", {})
    player_label = (
        str(
            player.get("displayName")
            or player.get("characterUUID")
            or resolved_player
        )
        if isinstance(player, dict)
        else resolved_player
    )
    npc_label = (
        str(npc.get("displayName") or npc.get("npcID") or resolved_npc)
        if isinstance(npc, dict)
        else resolved_npc
    )
    app.saved_world_target_var.set(
        f"Loaded Player {player_label} → NPC {npc_label}"
    )
    app.saved_world_status_var.set(
        "Imported saved target: "
        f"{player_label} → {npc_label} · "
        f"source {source.get('sourceKind', 'SAVE')}"
    )
    app._set_text(app.trace, pretty(result))
    app._append(
        "SYSTEM",
        f"Imported saved target {npc_label} from read-only source save.",
    )
    app._save_ui_state()
    app.main_tabs.select(app.simulation_tab)


def _saved_pair_restore_failed(
    app: Any,
    reason: str,
    *,
    remembered: bool,
) -> None:
    app._set_save_backed_mode(False)
    remember_active_source(app, "FIXTURE")
    _set_restore_status(app, "No saved Player/NPC pair loaded")
    app._refresh_simulation_context()
    prefix = (
        "Remembered SAVE target could not be restored"
        if remembered
        else "Saved target could not be loaded"
    )
    app._append(
        "WARNING",
        f"{prefix}; using FIXTURE. Open World Browser to choose a readable "
        f"save, Player, and NPC. Detail: {reason[:300]}",
    )
    app._set_status("Ready · fixture fallback")
    app._save_ui_state()


def _populate_studio_explore(app: Any, attempt: int = 0) -> None:
    """Request one bounded Explore page after startup/import work is idle."""

    if app.closed or not app.worker_ready:
        return
    if app.observatory.catalog_ready or app.observatory.loading:
        return
    if app.busy:
        if attempt >= 100:
            app.observatory.status_var.set(
                "Catalog is still busy; use Search to retry the first page."
            )
            return
        app._explore_retry_after = app.root.after(
            50, lambda: _populate_studio_explore(app, attempt + 1)
        )
        return
    if not app.observatory.refresh() and attempt < 100:
        app._explore_retry_after = app.root.after(
            50, lambda: _populate_studio_explore(app, attempt + 1)
        )


__all__ = [
    "initial_saved_pair_requested",
    "remembered_saved_pair_requested",
    "load_initial_saved_pair",
    "restore_remembered_saved_pair",
    "set_talk_catalog",
    "worker_ready",
]
