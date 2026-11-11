"""Provider composition surface and live worker reconfiguration controls."""

from __future__ import annotations

from concurrent.futures import Future
from typing import Any

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
    custom = app.selection_mode_var.get() == "Custom providers"
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
    }


def _write_plan(app: Any, request: dict[str, Any]) -> None:
    app._set_text(app.selection_plan_text, pretty(_request_view(request)))


def _active_summary(request: dict[str, Any]) -> str:
    plan = request["plan"]
    label = request.get("presetID") or "custom composition"
    providers = ", ".join(plan.provider_ids)
    return (
        f"Active: {label} · {providers} · "
        f"materialization={plan.materialization_mode}"
    )


def build_selection_surface(app: Any, parent: Any, ttk: Any, scrolled_text: Any) -> None:
    """Build the provider-neutral selection tab from discovered manifests."""

    parent.rowconfigure(2, weight=1)
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

    controls = ttk.LabelFrame(parent, text="Choose a harness composition", padding=8)
    controls.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(0, 8))
    controls.columnconfigure(1, weight=1)
    controls.columnconfigure(3, weight=1)

    app.selection_mode_var = app._tk.StringVar(value="Preset")
    app.selection_mode_box = ttk.Combobox(
        controls,
        textvariable=app.selection_mode_var,
        values=("Preset", "Custom providers"),
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

    actions = ttk.Frame(parent)
    actions.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(8, 0))
    actions.columnconfigure(2, weight=1)
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
    app.selection_status_var = app._tk.StringVar(value="Choose a preset or providers.")
    ttk.Label(
        actions,
        textvariable=app.selection_status_var,
        anchor="w",
        justify="left",
    ).grid(row=0, column=2, sticky="ew", padx=(12, 0))

    app.selection_plan_text = scrolled_text(parent, wrap="none", state="disabled")
    app.selection_plan_text.grid(
        row=2, column=0, columnspan=2, sticky="nsew", pady=(0, 0)
    )

    requested_mods = app._selected_mods()
    if requested_mods:
        app.selection_mode_var.set("Custom providers")
        _select_provider_labels(app, requested_mods)
    else:
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
        app.selection_status_var.set(f"Selection error: {error}")
    else:
        app.selection_active = request
        _write_plan(app, request)
        app.selection_active_var.set(_active_summary(request))
        app.selection_status_var.set("Active selection is ready.")


def _select_provider_labels(app: Any, provider_ids: tuple[str, ...] | list[str]) -> None:
    wanted = set(provider_ids)
    app.selection_provider_listbox.selection_clear(0, "end")
    for index in range(app.selection_provider_listbox.size()):
        label = app.selection_provider_listbox.get(index)
        if app.selection_provider_ids_by_label.get(label) in wanted:
            app.selection_provider_listbox.selection_set(index)


def selection_mode_changed(app: Any) -> None:
    custom = app.selection_mode_var.get() == "Custom providers"
    app.selection_preset_box.configure(state="disabled" if custom else "readonly")
    app.selection_provider_listbox.configure(state="normal")
    if not custom:
        selection_preset_changed(app)
    else:
        selection_provider_changed(app)


def selection_preset_changed(app: Any) -> None:
    if app.selection_mode_var.get() != "Custom providers":
        try:
            request = _active_request(app)
        except ModManagerError as error:
            app.selection_status_var.set(f"Selection error: {error}")
            return
        app.selection_pending = request
        _write_plan(app, request)
        app.selection_status_var.set("Preset changed; validate before applying.")


def selection_provider_changed(app: Any) -> None:
    if app.selection_mode_var.get() == "Custom providers":
        try:
            request = _active_request(app)
        except ModManagerError as error:
            app.selection_status_var.set(f"Selection error: {error}")
            return
        app.selection_pending = request
        _write_plan(app, request)
        app.selection_status_var.set("Custom composition changed; validate before applying.")


def validate_selection(app: Any) -> dict[str, Any] | None:
    try:
        request = _active_request(app)
    except ModManagerError as error:
        app.selection_pending = None
        app.selection_status_var.set(f"Invalid selection: {error}")
        return None
    app.selection_pending = request
    _write_plan(app, request)
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
    kwargs["profile"] = str(request.get("presetID") or "pnc")
    kwargs["preset"] = request.get("presetID")
    kwargs["mods"] = (
        tuple(request["providerIDs"])
        if request["mode"] == "custom"
        else None
    )
    return kwargs


def apply_selection(app: Any) -> None:
    request = validate_selection(app)
    if request is None:
        return
    if app.busy:
        app.selection_status_var.set("A worker operation is already running.")
        return
    if not app.worker_ready:
        app.selection_status_var.set("The worker is still starting; try again when ready.")
        return

    kwargs = _selection_worker_kwargs(app, request)
    scenario = load_scenario(None)
    app.busy = True
    app._worker_initialized = False
    app._set_controls(False)
    app._set_status("Switching provider composition…")
    app.selection_status_var.set("Closing the current worker and starting the new composition…")
    app.scenario = scenario
    app.last_response = {}
    app.last_test_utterance = ""
    app.replay_steps = []
    app._set_save_backed_mode(False)
    app._remember_active_source("FIXTURE")
    app._set_text(app.transcript, "")
    app._set_text(app.trace, "")

    try:
        app._selection_future = app.session.reconfigure(
            lambda: LuaSemanticWorker(scenario, **kwargs)
        )
    except Exception as error:
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
        app.busy = False
        app._worker_initialized = False
        app._set_controls(False)
        app._set_status("Provider switch failed")
        app.selection_status_var.set(f"Provider switch failed: {error}")
        app._append("ERROR", f"Provider switch failed: {error}")
        return

    request = app.selection_pending
    if request is not None:
        app.selection_active = request
        app.selection_pending = None
        if request["mode"] == "custom":
            app.arguments.mods = list(request["providerIDs"])
            app.arguments.preset = None
        else:
            app.arguments.mods = None
            app.arguments.preset = request["presetID"]
            app.arguments.profile = request["presetID"]
        app.selection_active_var.set(_active_summary(request))
    app.busy = False
    app._worker_ready(result)
    app.main_tabs.select(app.simulation_tab)
    app.selection_status_var.set("Provider composition active. Conversation state was reset.")
    app._append("SYSTEM", "Provider composition switched and the Lua worker is ready.")
    app._save_ui_state()


__all__ = [
    "apply_selection",
    "build_selection_surface",
    "poll_selection_future",
    "selection_mode_changed",
    "selection_preset_changed",
    "selection_provider_changed",
    "validate_selection",
]
