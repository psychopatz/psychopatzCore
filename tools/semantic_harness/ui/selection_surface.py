"""Provider composition surface and live worker reconfiguration controls."""

from __future__ import annotations

from concurrent.futures import Future
from typing import Any, Callable

from tools.semantic_harness.core.worker_session import WorkerReady
from tools.semantic_harness.inspection.rendering import pretty
from tools.semantic_harness.providers.mod_manager import (
    CORE_PROVIDER_ID,
    ModManagerError,
)
from tools.semantic_harness.runtime.scenario import load_scenario
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def _preset_rows(app: Any) -> list[dict[str, Any]]:
    return [
        row
        for row in app.selection_manager.presets()
        if isinstance(row, dict) and not row.get("aliasOf")
    ]


def _preset_label(row: dict[str, Any]) -> str:
    return f"{row.get('displayName') or row.get('presetID')} · {row.get('presetID')}"


def _active_request(app: Any) -> dict[str, Any]:
    mode = app.selection_mode_var.get()
    custom = mode == "Custom providers"
    if mode == "Selected save":
        entry = app._selected_saved_world_entry()
        if not isinstance(entry, dict):
            raise ModManagerError("discover and select a saved world first")
        activation = entry.get("modActivation")
        mod_ids = (
            activation.get("modIDs")
            if isinstance(activation, dict)
            else None
        )
        if not isinstance(mod_ids, list):
            raise ModManagerError("selected save has no readable mod activation list")
        resolution = app.selection_manager.resolve_activation_ids(mod_ids)
        if not resolution.get("activationPlan"):
            errors = resolution.get("errors") or [
                "no harness composition could be resolved"
            ]
            raise ModManagerError("; ".join(str(error) for error in errors))
        provider_ids = tuple(
            str(provider_id)
            for provider_id in resolution.get("providerIDs") or ()
            if str(provider_id) != CORE_PROVIDER_ID
        )
        plan = app.selection_manager.resolve(provider_ids=provider_ids)
        return {
            "mode": "save",
            "presetID": None,
            "providerIDs": plan.provider_ids,
            "plan": plan,
            "activation": resolution,
            "save": entry,
        }
    if custom:
        selection = tuple(
            app.selection_provider_ids_by_label[app.selection_provider_listbox.get(index)]
            for index in app.selection_provider_listbox.curselection()
        )
        if not selection:
            raise ModManagerError("select at least one provider")
        plan = app.selection_manager.resolve(provider_ids=selection)
        return {
            "mode": "custom",
            "presetID": None,
            "providerIDs": selection,
            "plan": plan,
        }

    label = app.selection_preset_var.get()
    preset_id = app.selection_preset_ids_by_label.get(label)
    if not preset_id:
        raise ModManagerError("select a harness preset")
    plan = app.selection_manager.resolve(preset=preset_id)
    return {
        "mode": "preset",
        "presetID": preset_id,
        "providerIDs": plan.provider_ids,
        "plan": plan,
    }


def _request_view(request: dict[str, Any]) -> dict[str, Any]:
    plan = request["plan"]
    return {
        "mode": request["mode"],
        "presetID": request.get("presetID"),
        "providerIDs": list(request["providerIDs"]),
        "activationPlan": plan.to_dict(),
        "saveActivation": request.get("activation"),
        "save": {
            "path": request.get("save", {}).get("path"),
            "saveName": request.get("save", {}).get("saveName"),
        } if isinstance(request.get("save"), dict) else None,
    }


def _write_plan(app: Any, request: dict[str, Any]) -> None:
    rendered = pretty(_request_view(request))
    app._selection_plan_rendered = rendered
    if getattr(app, "selection_details_visible", False):
        app._set_text(app.selection_plan_text, rendered)
    if hasattr(app, "selection_summary_var"):
        app.selection_summary_var.set(_selection_summary(request))


def _active_summary(request: dict[str, Any]) -> str:
    plan = request["plan"]
    save = request.get("save")
    label = (
        f"save {save.get('saveName') or 'source'}"
        if isinstance(save, dict)
        else request.get("presetID") or "custom composition"
    )
    providers = ", ".join(plan.provider_ids)
    return (
        f"Active: {label} · {providers} · "
        f"materialization={plan.materialization_mode}"
    )


def _request_key(request: dict[str, Any] | None) -> tuple[Any, ...] | None:
    if not isinstance(request, dict):
        return None
    plan = request.get("plan")
    if plan is None:
        return None
    return (
        tuple(plan.provider_ids),
        str(plan.materialization_mode),
        tuple(sorted(dict(plan.routes).items())),
    )


def _selection_banner(app: Any) -> str:
    active = app.selection_active if isinstance(app.selection_active, dict) else None
    pending = app.selection_pending
    active_text = _active_summary(active) if _request_key(active) else None
    pending_text = _active_summary(pending) if _request_key(pending) else None
    if active_text and pending_text and _request_key(active) != _request_key(pending):
        return f"{active_text} · Pending: {pending_text.removeprefix('Active: ')}"
    if pending_text:
        return pending_text
    return active_text or "No composition resolved yet. Select a save or preset."


def _selection_summary(request: dict[str, Any]) -> str:
    plan = request["plan"]
    activation = request.get("activation")
    source = request.get("save") if isinstance(request.get("save"), dict) else None
    source_label = (
        f"Save: {source.get('saveName') or 'unnamed'}"
        if source is not None
        else f"Source: {request.get('presetID') or request.get('mode') or 'custom'}"
    )
    providers = ", ".join(plan.provider_ids) or "none"
    lines = [
        source_label,
        f"Harness providers: {providers}",
        f"Materialization: {plan.materialization_mode}",
    ]
    if isinstance(activation, dict):
        mod_ids = activation.get("modIDs") or []
        unknown = activation.get("unknownModIDs") or []
        status = str(activation.get("status") or "unknown").upper()
        lines.append(
            f"Detected save mods: {len(mod_ids)} · resolution: {status}"
        )
        if unknown:
            lines.append("Unavailable to harness: " + ", ".join(map(str, unknown)))
    return "\n".join(lines)


def _sync_provider_labels(app: Any, provider_ids: tuple[str, ...] | list[str]) -> None:
    """Mirror a resolved composition without re-entering the selection handler."""

    if not hasattr(app, "selection_provider_listbox"):
        return
    wanted = set(provider_ids)
    app._selection_syncing = True
    try:
        app.selection_provider_listbox.selection_clear(0, "end")
        for index in range(app.selection_provider_listbox.size()):
            label = app.selection_provider_listbox.get(index)
            selected = app.selection_provider_ids_by_label.get(label) in wanted
            if selected:
                app.selection_provider_listbox.selection_set(index)
            if hasattr(app.selection_provider_listbox, "itemconfigure"):
                app.selection_provider_listbox.itemconfigure(
                    index,
                    background="#e4f2e4" if selected else "#ffffff",
                    foreground="#1f5d2b" if selected else "#202124",
                )
    finally:
        app._selection_syncing = False


def _set_pending_selection(app: Any, request: dict[str, Any]) -> None:
    app.selection_pending = request
    _sync_provider_labels(app, request["providerIDs"])
    _write_plan(app, request)
    app.selection_active_var.set(_selection_banner(app))
    if hasattr(app, "selection_summary_var"):
        app.selection_summary_var.set(_selection_summary(request))


def build_selection_surface(app: Any, parent: Any, ttk: Any, scrolled_text: Any) -> None:
    """Build the provider-neutral selection tab from discovered manifests."""

    app.selection_surface_parent = parent
    parent.rowconfigure(2, weight=0)
    parent.rowconfigure(3, weight=1)
    parent.columnconfigure(0, weight=1)
    parent.columnconfigure(1, weight=1)

    app.selection_active_var = app._tk.StringVar(value="Active: resolving selection…")
    ttk.Label(
        parent,
        textvariable=app.selection_active_var,
        anchor="w",
        justify="left",
        wraplength=900,
    ).grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 8))

    controls = ttk.LabelFrame(parent, text="Choose active mod composition", padding=8)
    controls.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(0, 8))
    controls.columnconfigure(1, weight=1)
    controls.columnconfigure(3, weight=1)

    app.selection_mode_var = app._tk.StringVar(value="Preset")
    app.selection_mode_box = ttk.Combobox(
        controls,
        textvariable=app.selection_mode_var,
        values=("Selected save", "Preset", "Custom providers"),
        state="readonly",
        width=20,
    )
    ttk.Label(controls, text="Selection mode").grid(row=0, column=0, sticky="w")
    app.selection_mode_box.grid(row=0, column=1, sticky="w", padx=(8, 24))
    app.selection_mode_box.bind(
        "<<ComboboxSelected>>",
        lambda _event: selection_mode_changed(app),
    )

    app.selection_preset_var = app._tk.StringVar()
    app.selection_preset_ids_by_label: dict[str, str] = {}
    for row in _preset_rows(app):
        label = _preset_label(row)
        app.selection_preset_ids_by_label[label] = str(row["presetID"])
    app.selection_preset_box = ttk.Combobox(
        controls,
        textvariable=app.selection_preset_var,
        values=tuple(app.selection_preset_ids_by_label),
        state="readonly",
        width=42,
    )
    ttk.Label(controls, text="Canonical preset").grid(row=0, column=2, sticky="w")
    app.selection_preset_box.grid(row=0, column=3, sticky="ew", padx=(8, 0))
    app.selection_preset_box.bind(
        "<<ComboboxSelected>>",
        lambda _event: selection_preset_changed(app),
    )

    app.selection_provider_ids_by_label: dict[str, str] = {}
    provider_labels: list[str] = []
    for provider in app.selection_manager.providers():
        if provider.provider_id == CORE_PROVIDER_ID:
            continue
        label = f"{provider.display_name} · {provider.provider_id}"
        provider_labels.append(label)
        app.selection_provider_ids_by_label[label] = provider.provider_id
    app.selection_provider_listbox = app._tk.Listbox(
        controls,
        selectmode="extended",
        height=min(8, max(4, len(provider_labels))),
        exportselection=False,
    )
    for label in provider_labels:
        app.selection_provider_listbox.insert("end", label)
    app.selection_provider_listbox.grid(
        row=1, column=0, columnspan=4, sticky="ew", pady=(8, 0)
    )
    app.selection_provider_listbox.bind(
        "<<ListboxSelect>>",
        lambda _event: selection_provider_changed(app),
    )

    summary = ttk.LabelFrame(parent, text="Composition summary", padding=8)
    summary.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(0, 8))
    summary.columnconfigure(0, weight=1)
    summary.rowconfigure(0, weight=1)
    app.selection_summary_var = app._tk.StringVar(
        value="Select a save or preset to resolve its provider composition."
    )
    ttk.Label(
        summary,
        textvariable=app.selection_summary_var,
        anchor="nw",
        justify="left",
        wraplength=1050,
    ).grid(row=0, column=0, sticky="nw")

    app.selection_plan_text = scrolled_text(parent, wrap="none", state="disabled")
    app.selection_plan_text.grid(
        row=3, column=0, columnspan=2, sticky="nsew", pady=(0, 8)
    )
    app.selection_plan_text.grid_remove()
    parent.rowconfigure(3, weight=0)
    app.selection_details_visible = False

    actions = ttk.Frame(parent)
    actions.grid(row=4, column=0, columnspan=2, sticky="ew", pady=(0, 0))
    actions.columnconfigure(3, weight=1)
    app.selection_validate_button = ttk.Button(
        actions,
        text="Validate selection",
        command=lambda: validate_selection(app),
    )
    app.selection_validate_button.grid(row=0, column=0, sticky="w")
    app.selection_apply_button = ttk.Button(
        actions,
        text="Apply selection",
        command=lambda: apply_selection(app),
    )
    app.selection_apply_button.grid(row=0, column=1, sticky="w", padx=(8, 0))
    app.selection_details_button = ttk.Button(
        actions,
        text="Show technical plan",
        command=lambda: toggle_selection_details(app),
    )
    app.selection_details_button.grid(row=0, column=2, sticky="w", padx=(8, 0))
    app.selection_status_var = app._tk.StringVar(value="Choose a preset or providers.")
    ttk.Label(
        actions,
        textvariable=app.selection_status_var,
        anchor="w",
        justify="left",
    ).grid(row=0, column=3, sticky="ew", padx=(12, 0))

    remembered_mode = str(
        app._ui_state.get("selection_source_mode") or ""
    ).strip()
    if remembered_mode in {"Selected save", "Preset", "Custom providers"}:
        app.selection_mode_var.set(remembered_mode)
    requested_mods = app._selected_mods()
    if requested_mods:
        app.selection_mode_var.set("Custom providers")
        _select_provider_labels(app, requested_mods)
    elif remembered_mode not in {"Selected save", "Custom providers"}:
        wanted = str(
            getattr(app.arguments, "preset", None)
            or getattr(app.arguments, "profile", None)
            or "pnc"
        ).strip()
        wanted_label = next(
            (
                label
                for label, preset_id in app.selection_preset_ids_by_label.items()
                if preset_id == wanted
            ),
            next(iter(app.selection_preset_ids_by_label), ""),
        )
        app.selection_preset_var.set(wanted_label)
    selection_mode_changed(app)
    try:
        request = _active_request(app)
    except ModManagerError as error:
        app.selection_active_var.set(_selection_banner(app))
        app.selection_status_var.set(f"Selection error: {error}")
    else:
        app.selection_active = request
        app.selection_pending = None
        _sync_provider_labels(app, request["providerIDs"])
        _write_plan(app, request)
        app.selection_active_var.set(_selection_banner(app))
        app.selection_status_var.set("Active selection is ready.")


def _select_provider_labels(app: Any, provider_ids: tuple[str, ...] | list[str]) -> None:
    _sync_provider_labels(app, provider_ids)


def toggle_selection_details(app: Any) -> None:
    app.selection_details_visible = not app.selection_details_visible
    if app.selection_details_visible:
        app._set_text(
            app.selection_plan_text,
            getattr(app, "_selection_plan_rendered", "No composition resolved."),
        )
        app.selection_plan_text.grid()
        app.selection_surface_parent.rowconfigure(3, weight=1)
        app.selection_details_button.configure(text="Hide technical plan")
    else:
        app.selection_plan_text.grid_remove()
        app.selection_surface_parent.rowconfigure(3, weight=0)
        app.selection_details_button.configure(text="Show technical plan")


def selection_mode_changed(app: Any) -> None:
    mode = app.selection_mode_var.get()
    custom = mode == "Custom providers"
    app.selection_preset_box.configure(
        state="readonly" if mode == "Preset" else "disabled"
    )
    app.selection_provider_listbox.configure(
        state="normal" if custom else "disabled"
    )
    if mode == "Preset":
        selection_preset_changed(app)
    elif custom:
        selection_provider_changed(app)
    else:
        selection_saved_changed(app)


def selection_preset_changed(app: Any) -> None:
    if app.selection_mode_var.get() != "Custom providers":
        try:
            request = _active_request(app)
        except ModManagerError as error:
            app.selection_active_var.set(_selection_banner(app))
            app.selection_status_var.set(f"Selection error: {error}")
            return
        _set_pending_selection(app, request)
        app.selection_status_var.set("Preset changed; validate before applying.")


def selection_provider_changed(app: Any) -> None:
    if app._selection_syncing:
        return
    if app.selection_mode_var.get() == "Custom providers":
        try:
            request = _active_request(app)
        except ModManagerError as error:
            app.selection_active_var.set(_selection_banner(app))
            app.selection_status_var.set(f"Selection error: {error}")
            return
        _set_pending_selection(app, request)
        app.selection_status_var.set("Custom composition changed; validate before applying.")


def selection_saved_changed(app: Any) -> None:
    try:
        request = _active_request(app)
    except ModManagerError as error:
        app.selection_pending = None
        app.selection_active_var.set(_selection_banner(app))
        app.selection_status_var.set(f"Save composition unavailable: {error}")
        return
    _set_pending_selection(app, request)
    activation = request.get("activation") or {}
    unknown = activation.get("unknownModIDs") or []
    suffix = (
        f" · unknown mods: {', '.join(str(item) for item in unknown)}"
        if unknown else ""
    )
    app.selection_status_var.set(
        f"Save composition resolved · {len(request['plan'].provider_ids)} providers"
        + suffix
    )


def save_source_selected(app: Any, entry: dict[str, Any] | None) -> None:
    """Make the selected save the source of the Mod Composition sub-tab."""

    if not isinstance(entry, dict):
        return
    app.selection_mode_var.set("Selected save")
    selection_mode_changed(app)


def validate_selection(app: Any) -> dict[str, Any] | None:
    try:
        request = _active_request(app)
    except ModManagerError as error:
        app.selection_pending = None
        app.selection_status_var.set(f"Invalid selection: {error}")
        return None
    _set_pending_selection(app, request)
    app.selection_status_var.set(
        f"Valid · {len(request['plan'].provider_ids)} providers · "
        f"{request['plan'].materialization_mode}"
    )
    if hasattr(app, "selection_apply_button"):
        app.selection_apply_button.configure(
            state="normal" if app.worker_ready and not app.busy else "disabled"
        )
    return request


def _selection_worker_kwargs(app: Any, request: dict[str, Any]) -> dict[str, Any]:
    kwargs = app._worker_kwargs()
    kwargs["profile"] = str(request.get("presetID") or "save")
    kwargs["preset"] = request.get("presetID")
    kwargs["mods"] = (
        tuple(
            provider_id
            for provider_id in request["providerIDs"]
            if provider_id != CORE_PROVIDER_ID
        )
        if request["mode"] in {"custom", "save"}
        else None
    )
    return kwargs


def apply_selection(
    app: Any,
    completion: Callable[[], None] | None = None,
) -> None:
    request = validate_selection(app)
    if request is None:
        return
    if app.busy:
        app.selection_status_var.set("A worker operation is already running.")
        return
    if not app.worker_ready:
        app.selection_status_var.set("The worker is still starting; try again when ready.")
        return

    if _request_key(request) == _request_key(app.selection_active):
        app.selection_active = request
        app.selection_pending = None
        app.selection_active_var.set(_selection_banner(app))
        app.selection_status_var.set("This composition is already active.")
        if completion is not None:
            app.root.after_idle(completion)
        return

    kwargs = _selection_worker_kwargs(app, request)
    preserve_save = (
        app.save_backed_mode is True
        or str(app._ui_state.get("active_source_kind") or "").upper() == "SAVE"
    )
    scenario = load_scenario(None)
    app.busy = True
    app._selection_completion = completion
    app._selection_inflight = request
    app._worker_initialized = False
    app._set_controls(False)
    app._set_status("Switching provider composition…")
    app.selection_status_var.set("Closing the current worker and starting the new composition…")
    app.scenario = scenario
    app.last_response = {}
    app.last_test_utterance = ""
    app.replay_steps = []
    if not preserve_save:
        app._set_save_backed_mode(False)
        app._remember_active_source("FIXTURE")
    app._set_text(app.transcript, "")
    app._set_text(app.trace, "")

    try:
        app._selection_future = app.session.reconfigure(
            lambda: LuaSemanticWorker(scenario, **kwargs)
        )
    except Exception as error:
        app._selection_completion = None
        app._selection_inflight = None
        app.busy = False
        app._set_controls(False)
        app._set_status("Provider switch failed")
        app.selection_status_var.set(f"Provider switch failed: {error}")
        app._append("ERROR", f"Provider switch failed: {error}")
        return
    app._poll_selection_future()


def poll_selection_future(app: Any) -> None:
    future: Future[WorkerReady] | None = app._selection_future
    if future is None or app.closed:
        return
    if not future.done():
        app._selection_poll_after = app.root.after(25, app._poll_selection_future)
        return
    app._selection_poll_after = None
    app._selection_future = None
    try:
        result = future.result()
    except Exception as error:
        app._selection_completion = None
        app._selection_inflight = None
        app.busy = False
        app._worker_initialized = False
        app._set_controls(False)
        app._set_status("Provider switch failed")
        app.selection_status_var.set(f"Provider switch failed: {error}")
        app._append("ERROR", f"Provider switch failed: {error}")
        return

    request = app._selection_inflight or app.selection_pending
    pending = app.selection_pending
    completion = app._selection_completion
    app._selection_completion = None
    app._selection_inflight = None
    if request is not None:
        app.selection_active = request
        if _request_key(pending) == _request_key(request):
            app.selection_pending = None
        if request["mode"] in {"custom", "save"}:
            app.arguments.mods = list(request["providerIDs"])
            app.arguments.preset = None
        else:
            app.arguments.mods = None
            app.arguments.preset = request["presetID"]
            app.arguments.profile = request["presetID"]
        app.selection_active_var.set(_selection_banner(app))
    app.busy = False
    app._worker_ready(result)
    if completion is None:
        app.main_tabs.select(app.simulation_tab)
    app.selection_status_var.set("Provider composition active. Conversation state was reset.")
    app._append("SYSTEM", "Provider composition switched and the Lua worker is ready.")
    app._save_ui_state()
    if completion is not None and _request_key(pending) == _request_key(request):
        app.root.after_idle(completion)
    elif completion is not None:
        app.selection_status_var.set(
            "Selection changed while switching; apply the newer composition before loading."
        )


def ensure_selection_for_save(
    app: Any,
    completion: Callable[[], None],
) -> None:
    """Make the selected save's provider plan active before importing it."""

    if app.closed:
        return
    if app.selection_mode_var.get() != "Selected save":
        save_source_selected(app, app._selected_saved_world_entry())
    try:
        request = _active_request(app)
    except ModManagerError as error:
        app.selection_pending = None
        app.selection_status_var.set(f"Cannot load save composition: {error}")
        app.selection_active_var.set(_selection_banner(app))
        return
    _set_pending_selection(app, request)
    if _request_key(request) == _request_key(app.selection_active):
        app.selection_active = request
        app.selection_pending = None
        app.selection_active_var.set(_selection_banner(app))
        app.root.after_idle(completion)
        return
    if app.busy:
        app.selection_status_var.set(
            "Waiting for the current operation before switching save composition…"
        )
        if app._selection_ensure_after is None:
            app._selection_ensure_after = app.root.after(
                50,
                lambda: _retry_selection_for_save(app, completion),
            )
        return
    app._selection_ensure_after = None
    app.selection_status_var.set("Applying the save composition before loading the NPC…")
    apply_selection(app, completion=completion)


def _retry_selection_for_save(app: Any, completion: Callable[[], None]) -> None:
    app._selection_ensure_after = None
    ensure_selection_for_save(app, completion)


__all__ = [
    "apply_selection",
    "build_selection_surface",
    "poll_selection_future",
    "save_source_selected",
    "selection_mode_changed",
    "selection_preset_changed",
    "selection_provider_changed",
    "validate_selection",
    "ensure_selection_for_save",
]
