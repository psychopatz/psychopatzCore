"""Runtime scenario settings form and its side-effect-free draft parser."""

from __future__ import annotations

from copy import deepcopy
import json
import math
from pathlib import Path
from typing import Any, Callable, Mapping, Protocol

from tools.semantic_harness.inspection.rendering import pretty
from tools.semantic_harness.runtime.scenario import (
    derive_actor_identifier,
    derive_display_name,
    save_scenario,
    validate_scenario,
)
from .catalog_control import CatalogControlField, control_options


class SettingsDialogHost(Protocol):
    """Narrow GUI callbacks and state required by the settings modal."""

    root: Any
    _tk: Any
    _ttk: Any
    _ScrolledText: Any
    _filedialog: Any
    _messagebox: Any
    scenario_path: Path | None
    scenario: dict[str, Any]
    worker_ready: bool
    busy: bool
    settings_window: Any | None
    language_var: Any
    npc_profile_var: Any
    trace: Any
    persona_catalog: dict[str, Any]
    simulation_control_catalog: dict[str, Any]
    last_response: dict[str, Any]
    settings_control_fields: dict[str, Any]

    def _start_operation(self, operation: Callable[[Any], Any], callback: Callable[[Any], None]) -> bool: ...
    def _set_text(self, widget: Any, value: str) -> None: ...
    def _append(self, speaker: str, text: str) -> None: ...
    def _sync_workbench_from_scenario(self, scenario: dict[str, Any]) -> None: ...


def _collect_legacy_scenario_settings(
    draft: dict[str, Any], values: Mapping[str, Any]
) -> dict[str, Any]:
    """Build and validate an updated scenario from primitive form values."""

    def read_value(key: str) -> Any:
        return values[key]

    def number_value(key: str) -> float:
        try:
            return float(read_value(key))
        except (TypeError, ValueError) as error:
            raise ValueError(f"{key} must be a number") from error

    def json_value(key: str) -> Any:
        try:
            return json.loads(read_value(key))
        except json.JSONDecodeError as error:
            raise ValueError(f"{key} must contain valid JSON: {error.msg}") from error

    updated = deepcopy(draft)
    updated_runtime = updated.setdefault("runtime", {})
    updated_world = updated.setdefault("world", {})
    updated_player = updated.setdefault("player", {})
    updated_npc = updated.setdefault("npc", {})
    # Relationship state is a production-derived view of the editable scores;
    # never preserve a normal-mode override from an older scenario draft.
    updated_npc.pop("relationshipState", None)
    updated_relationship = updated_npc.setdefault("relationship", {})
    updated_identity = updated_npc.setdefault("identity", {})
    updated_conversation = updated.setdefault("conversation", {})
    for key in ("mode", "language"):
        updated_runtime[key] = str(read_value(f"runtime.{key}")).strip()
    for key in ("llmEnabled", "providerAvailable"):
        updated_runtime[key] = bool(read_value(f"runtime.{key}"))
    for key in ("hunger", "thirst", "fatigue", "stress", "boredom", "panic", "timeOfDay", "worldAgeHours", "zombieKills"):
        if f"world.{key}" in values:
            updated_world[key] = number_value(f"world.{key}")
    updated_world["weather"] = str(read_value("world.weather")).strip()
    if "world.weatherTransition" in values:
        updated_world["weatherTransition"] = str(read_value("world.weatherTransition")).strip() or None
    for key in ("characterUUID", "forename", "surname", "displayName"):
        updated_player[key] = str(read_value(f"player.{key}")).strip()
    for key in ("npcID", "forename", "surname", "identityState"):
        updated_npc[key] = str(read_value(f"npc.{key}")).strip()
    # These are harness conveniences derived from the editable actor names.
    # Production identity remains owned by the runtime actor records.
    updated_player["characterUUID"] = derive_actor_identifier(
        "char", updated_player["forename"], updated_player["surname"]
    )
    updated_player["displayName"] = derive_display_name(
        updated_player["forename"], updated_player["surname"]
    )
    updated_npc["npcID"] = derive_actor_identifier(
        "npc", updated_npc["forename"], updated_npc["surname"]
    )
    if "npc.gender" in values:
        updated_identity["gender"] = str(read_value("npc.gender")).strip()
    if "npc.role" in values:
        role = str(read_value("npc.role")).strip().lower()
        if role in {"", "none"}:
            updated_npc.pop("role", None)
        else:
            updated_npc["role"] = role
    if "persona.bondKind" in values:
        bond_kind = str(read_value("persona.bondKind")).strip().lower()
        if bond_kind in {"", "none"}:
            updated_npc.pop("startingRelationship", None)
        else:
            existing_bond = updated_npc.get("startingRelationship")
            existing_bond = existing_bond if isinstance(existing_bond, dict) else {}
            updated_npc["startingRelationship"] = {
                "kind": bond_kind,
                "source": existing_bond.get(
                    "source", "starting_companion_trait"
                ),
            }
            if existing_bond.get("since") is not None:
                updated_npc["startingRelationship"]["since"] = existing_bond[
                    "since"
                ]
    for key in ("healthState", "activeBehavior"):
        if f"npc.{key}" in values:
            updated_npc[key] = str(read_value(f"npc.{key}")).strip()
    for key in ("approval", "respect", "familiarity", "revision"):
        updated_relationship[key] = number_value(f"relationship.{key}")
        if key == "revision":
            updated_relationship[key] = int(updated_relationship[key])
    updated_relationship["identityTrust"] = str(read_value("relationship.identityTrust")).strip()
    if "npc.traits" in values:
        updated_npc["traits"] = json_value("npc.traits")
    else:
        updated_npc["traits"] = list(updated_npc.get("traits", []))
    if "npc.personality" in values:
        updated_npc["personality"] = json_value("npc.personality")
    else:
        updated_npc["personality"] = dict(updated_npc.get("personality", {}))
    if not isinstance(updated_npc["traits"], list):
        raise ValueError("npc.traits must be a JSON array")
    if not isinstance(updated_npc["personality"], dict):
        raise ValueError("npc.personality must be a JSON object")
    if "persona.traits" in values:
        selected_traits = read_value("persona.traits")
        if not isinstance(selected_traits, list):
            raise ValueError("persona.traits must be a list")
        updated_npc["traits"] = [str(value).strip() for value in selected_traits]
    if "persona.socialStyle" in values:
        updated_npc["personality"]["socialStyle"] = str(
            read_value("persona.socialStyle")
        ).strip()
    for key in (
        "compassion", "sociability", "forgiveness", "bravery",
        "materialism", "aggression", "loyalty",
    ):
        field = f"persona.personality.{key}"
        if field in values:
            updated_npc["personality"][key] = number_value(field)
    for key in ("companion", "owned", "eligible"):
        field = f"persona.authority.{key}"
        if field in values:
            updated_npc.setdefault("actorAuthority", {})[key] = bool(
                read_value(field)
            )
    player_inventory = json_value("player.inventory")
    if not isinstance(player_inventory, dict):
        raise ValueError("player.inventory must be a JSON object")
    npc_inventory = json_value("npc.inventory")
    if not isinstance(npc_inventory, dict):
        raise ValueError("npc.inventory must be a JSON object")
    updated_player["inventory"] = player_inventory
    updated_npc["inventory"] = npc_inventory
    for key in ("topic", "token"):
        updated_conversation[key] = str(read_value(f"conversation.{key}")).strip()
    command_responses = json_value("runtime.commandResponses")
    if not isinstance(command_responses, dict):
        raise ValueError("runtime.commandResponses must be a JSON object")
    translations = json_value("runtime.nativeTranslations")
    if not isinstance(translations, dict):
        raise ValueError("runtime.nativeTranslations must be a JSON object")
    updated_runtime["commandResponses"] = command_responses
    updated_runtime["nativeTranslations"] = translations
    if "runtime.DTHoomans" in values:
        updated_runtime.setdefault("availableMods", {})["DTHoomans"] = bool(
            read_value("runtime.DTHoomans")
        )
    validate_scenario(updated)
    return updated


def _path_value(source: Mapping[str, Any], path: str) -> Any:
    value: Any = source
    for segment in path.split("."):
        if not isinstance(value, Mapping):
            return None
        value = value.get(segment)
    return value


def _set_path(target: dict[str, Any], path: str, value: Any) -> None:
    segments = path.split(".")
    current = target
    for segment in segments[:-1]:
        child = current.get(segment)
        if not isinstance(child, dict):
            child = {}
            current[segment] = child
        current = child
    current[segments[-1]] = value


def _delete_path(target: dict[str, Any], path: str) -> None:
    segments = path.split(".")
    current: Any = target
    for segment in segments[:-1]:
        if not isinstance(current, dict):
            return
        current = current.get(segment)
    if isinstance(current, dict):
        current.pop(segments[-1], None)


def _typed_value(
    control: Mapping[str, Any], raw: Any, existing: Any = None
) -> Any:
    value_type = str(control.get("valueType") or "text")
    if value_type == "boolean":
        if isinstance(raw, bool):
            return raw
        if str(raw).lower() in {"true", "1", "yes"}:
            return True
        if str(raw).lower() in {"false", "0", "no"}:
            return False
        raise ValueError(f"{control.get('id')} must be a boolean")
    if value_type in {"number", "integer"}:
        try:
            number = float(raw)
        except (TypeError, ValueError) as error:
            raise ValueError(f"{control.get('id')} must be a number") from error
        if not math.isfinite(number):
            raise ValueError(f"{control.get('id')} must be finite")
        minimum = control.get("min")
        maximum = control.get("max")
        if minimum is not None and number < float(minimum):
            raise ValueError(f"{control.get('id')} must be at least {minimum}")
        if maximum is not None and number > float(maximum):
            raise ValueError(f"{control.get('id')} must be at most {maximum}")
        step = control.get("step")
        if step is not None and float(step) > 0:
            origin = float(minimum) if minimum is not None else 0.0
            units = (number - origin) / float(step)
            if not math.isclose(units, round(units), rel_tol=0.0, abs_tol=1e-7):
                raise ValueError(f"{control.get('id')} must use increments of {step}")
        if value_type == "integer":
            if not number.is_integer():
                raise ValueError(f"{control.get('id')} must be a whole number")
            return int(number)
        return round(number, 8)
    if value_type == "enum":
        value = str(raw)
        options = control_options(control)
        if options and value not in options and value != existing:
            raise ValueError(f"{control.get('id')} is not in the worker catalog")
        return value
    if value_type == "array":
        if not isinstance(raw, list):
            raise ValueError(f"{control.get('id')} must be a selection list")
        options = control_options(control)
        selected = [str(item) for item in raw]
        existing_values = (
            {str(item) for item in existing}
            if isinstance(existing, list)
            else set()
        )
        if options and any(
            item not in options and item not in existing_values
            for item in selected
        ):
            raise ValueError(f"{control.get('id')} contains an option outside the worker catalog")
        return selected
    if value_type == "object":
        if isinstance(raw, dict):
            value = deepcopy(raw)
        else:
            try:
                value = json.loads(raw)
            except (json.JSONDecodeError, TypeError) as error:
                message = error.msg if isinstance(error, json.JSONDecodeError) else "expected JSON text"
                raise ValueError(f"{control.get('id')} Advanced JSON is invalid: {message}") from error
        if not isinstance(value, dict):
            raise ValueError(f"{control.get('id')} Advanced JSON must be an object")
        return value
    value = str(raw).strip()
    if control.get("emptyToNull") and not value:
        return None
    return value


def _collect_catalog_scenario_settings(
    draft: dict[str, Any],
    values: Mapping[str, Any],
    control_catalog: Mapping[str, Any],
) -> dict[str, Any]:
    updated = deepcopy(draft)
    controls = control_catalog.get("controls", [])
    if not isinstance(controls, list) or len(controls) > 96:
        raise ValueError("worker simulation control catalog is invalid")
    # Relationship state is computed from the editable standing by production.
    updated.setdefault("npc", {}).pop("relationshipState", None)
    for control in controls:
        if not isinstance(control, Mapping):
            continue
        control_type = str(control.get("control") or "")
        if control_type == "read_only" or control.get("id") not in values:
            continue
        field_id = str(control.get("id"))
        path = control.get("path")
        if not isinstance(path, str) or not path:
            continue
        value = _typed_value(control, values[field_id], _path_value(draft, path))
        none_value = control.get("noneValue")
        if none_value is not None and value == none_value:
            clear_path = control.get("clearPath")
            _delete_path(updated, str(clear_path or path))
            continue
        if field_id == "persona.bondKind":
            existing = _path_value(updated, "npc.startingRelationship")
            existing = existing if isinstance(existing, dict) else {}
            starting_relationship = {
                "kind": value,
                "source": existing.get("source", "starting_companion_trait"),
            }
            if existing.get("since") is not None:
                starting_relationship["since"] = existing["since"]
            _set_path(updated, "npc.startingRelationship", starting_relationship)
        else:
            _set_path(updated, path, value)
    validate_scenario(updated)
    return updated


def collect_scenario_settings(
    draft: dict[str, Any],
    values: Mapping[str, Any],
    control_catalog: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Collect typed worker-catalog values, retaining a legacy test adapter."""

    if control_catalog is None:
        return _collect_legacy_scenario_settings(draft, values)
    return _collect_catalog_scenario_settings(draft, values, control_catalog)


def open_runtime_settings(host: SettingsDialogHost) -> None:
    """Render uncommon and advanced controls from the worker catalog.

    Controls owned by the actor-centric Simulation workbench stay in their
    primary panel. A catalog row may explicitly opt into both surfaces with
    ``settingsVisible=True`` when a diagnostic or advanced workflow needs it.
    """

    if not host.worker_ready or host.busy:
        return
    if host.settings_window is not None and host.settings_window.winfo_exists():
        host.settings_window.deiconify()
        host.settings_window.lift()
        host.settings_window.focus_force()
        return

    tk = host._tk
    ttk = host._ttk
    ScrolledText = host._ScrolledText
    catalog = host.simulation_control_catalog
    controls = catalog.get("controls", []) if isinstance(catalog, dict) else []
    if not isinstance(controls, list) or not controls:
        host._messagebox.showerror(
            "Simulation settings",
            "The Lua worker did not provide a simulation control catalog.",
        )
        return
    controls = [
        control for control in controls[:96]
        if isinstance(control, dict) and control.get("id")
    ]

    def settings_visible(control: dict[str, Any]) -> bool:
        if control.get("settingsVisible") is False:
            return False
        return not (
            control.get("workbench") is True
            and control.get("settingsVisible") is not True
        )

    dialog = tk.Toplevel(host.root)
    host.settings_window = dialog
    dialog.title("Simulation settings")
    dialog.geometry("940x740")
    dialog.minsize(760, 560)
    dialog.transient(host.root)
    dialog.columnconfigure(0, weight=1)
    dialog.rowconfigure(0, weight=1)

    def close_dialog() -> None:
        if dialog.winfo_exists():
            try:
                dialog.grab_release()
            except tk.TclError:
                pass
            dialog.destroy()
        host.settings_window = None
        host.settings_variables = {}
        host.settings_control_widgets = {}
        host.settings_control_fields = {}

    dialog.protocol("WM_DELETE_WINDOW", close_dialog)
    draft = deepcopy(host.scenario)
    variables: dict[str, Any] = {}
    widgets: dict[str, Any] = {}
    fields: dict[str, CatalogControlField] = {}
    host.settings_variables = variables
    host.settings_control_widgets = widgets
    host.settings_control_fields = fields

    notebook = ttk.Notebook(dialog)
    notebook.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    pages: dict[str, Any] = {}
    sections: dict[tuple[str, str], Any] = {}
    section_rows: dict[tuple[str, str], int] = {}

    def page(title: str) -> Any:
        existing = pages.get(title)
        if existing is not None:
            return existing
        outer = ttk.Frame(notebook)
        outer.columnconfigure(0, weight=1)
        outer.rowconfigure(0, weight=1)
        canvas = tk.Canvas(outer, highlightthickness=0)
        scrollbar = ttk.Scrollbar(outer, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.grid(row=0, column=0, sticky="nsew")
        scrollbar.grid(row=0, column=1, sticky="ns")
        inner = ttk.Frame(canvas, padding=12)
        inner.columnconfigure(0, weight=1)
        window_id = canvas.create_window((0, 0), window=inner, anchor="nw")
        inner.bind(
            "<Configure>",
            lambda _event, current=canvas: current.configure(
                scrollregion=current.bbox("all")
            ),
        )
        canvas.bind(
            "<Configure>",
            lambda event, current=canvas, item=window_id: current.itemconfigure(
                item, width=event.width
            ),
        )
        notebook.add(outer, text=title)
        pages[title] = inner
        return inner

    def section_frame(page_title: str, section_title: str) -> Any:
        key = (page_title, section_title)
        existing = sections.get(key)
        if existing is not None:
            return existing
        page_frame = page(page_title)
        row = sum(1 for page_key, _ in sections if page_key == page_title)
        frame = ttk.LabelFrame(page_frame, text=section_title, padding=10)
        frame.grid(row=row, column=0, sticky="ew", pady=(0, 10))
        frame.columnconfigure(1, weight=1)
        sections[key] = frame
        section_rows[key] = 0
        return frame

    def current_value(control: dict[str, Any]) -> Any:
        control_id = str(control.get("id"))
        if control_id == "relationship.state":
            response = host.last_response if isinstance(host.last_response, dict) else {}
            context = response.get("contextAfter") or response.get("context") or {}
            actor = context.get("actorConversationContext", {}) if isinstance(context, dict) else {}
            relationship = actor.get("relationship", {}) if isinstance(actor, dict) else {}
            return relationship.get("state", "unknown")
        path = control.get("path")
        if path is None:
            return control.get("currentValue")
        value = _path_value(draft, str(path)) if isinstance(path, str) else None
        if control_id == "persona.bondKind":
            return value or "none"
        if control_id == "npc.role":
            return value or "none"
        return value

    for control in controls:
        if not settings_visible(control):
            continue
        control_id = str(control["id"])
        page_title = str(control.get("page") or "Simulation")
        section_title = str(control.get("section") or "Scenario")
        parent = section_frame(page_title, section_title)
        section_key = (page_title, section_title)
        row = section_rows[section_key]
        section_rows[section_key] = row + 1
        initial = current_value(control)
        field = CatalogControlField(
            parent,
            tk,
            ttk,
            ScrolledText,
            host,
            control,
            initial,
            row=row,
        )
        fields[control_id] = field
        variables[control_id] = field.variable or field.editor or field.widget
        widgets[control_id] = field.widget

    override_field = fields.get("npc.personalityOverride")

    def update_personality_controls(*_args: Any) -> None:
        enabled = bool(override_field and override_field.get_value())
        for control in controls:
            if not control.get("requiresOverride"):
                continue
            field = fields.get(str(control.get("id") or ""))
            if field is not None:
                field.set_enabled(enabled)

    if override_field is not None and override_field.variable is not None:
        override_field.variable.trace_add("write", update_personality_controls)
    update_personality_controls()

    ttk.Label(
        page("Runtime"),
        text=(
            "These controls edit one scenario draft. The Lua worker validates and applies it; "
            "the catalog describes the UI and does not grant gameplay authority."
        ),
        wraplength=720,
    ).grid(row=100, column=0, sticky="w", pady=(8, 0))

    footer = ttk.Frame(dialog)
    footer.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 10))
    footer.columnconfigure(0, weight=1)
    ttk.Label(
        footer,
        text="Apply updates the live Lua worker. Save scenario writes the complete scenario to JSON.",
    ).grid(row=0, column=0, sticky="w")

    def collect() -> dict[str, Any]:
        values: dict[str, Any] = {}
        for control in controls:
            if not settings_visible(control):
                continue
            control_id = str(control["id"])
            widget_kind = str(control.get("control") or "text")
            field = fields[control_id]
            if (
                (field.variable is None and field.editor is None)
                or widget_kind == "read_only"
            ):
                continue
            if (
                field.initial is None
                and not field.dirty
                and widget_kind != "structured_collection"
            ):
                continue
            if control.get("requiresOverride") and not bool(
                override_field and override_field.get_value()
            ):
                continue
            values[control_id] = field.get_value()
        return collect_scenario_settings(draft, values, catalog)

    def apply(save_after: bool = False) -> None:
        try:
            updated = collect()
        except (TypeError, ValueError, tk.TclError) as error:
            host._messagebox.showerror("Simulation settings", str(error), parent=dialog)
            return
        destination = host.scenario_path
        if save_after and destination is None:
            selected = host._filedialog.asksaveasfilename(
                parent=dialog,
                title="Save semantic scenario",
                defaultextension=".json",
                filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
            )
            if not selected:
                return
            destination = Path(selected)

        def finish(response: dict[str, Any]) -> None:
            host.scenario = updated
            host.language_var.set(updated["runtime"]["language"])
            from tools.semantic_harness.runtime.npc_profiles import profile_id, profile_label

            host.npc_profile_var.set(profile_label(profile_id(updated)))
            host._sync_workbench_from_scenario(updated)
            host._set_text(host.trace, pretty(response))
            host._append("SYSTEM", "Applied simulation settings to the Lua worker.")
            if save_after and destination is not None:
                try:
                    save_scenario(destination, updated)
                except (OSError, TypeError, ValueError) as error:
                    host._messagebox.showerror("Scenario save error", str(error), parent=dialog)
                    return
                host.scenario_path = destination
                host._append("SYSTEM", f"Saved simulation scenario to {destination}")
            close_dialog()

        if not host._start_operation(lambda worker: worker.configure(updated), finish):
            return

    ttk.Button(footer, text="Cancel", command=close_dialog).grid(
        row=0, column=1, padx=6
    )
    ttk.Button(footer, text="Apply", command=apply).grid(
        row=0, column=2, padx=6
    )
    ttk.Button(footer, text="Apply & Save", command=lambda: apply(True)).grid(
        row=0, column=3
    )
    dialog.grab_set()
    dialog.focus_force()
