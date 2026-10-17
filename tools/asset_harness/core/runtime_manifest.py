"""Compile canonical modular radio pilots into the Core runtime contract.

The pilot JSON files remain the authoring source.  This module only produces a
deterministic, game-relative projection of that source for the Project Zomboid
Lua runtime.  It intentionally contains no simulator state and no provider
registration logic.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

from .errors import AssetHarnessError
from .paths import parse_rect, rect_inside, rect_overlap, resolve_reference
from .project import load_project, project_workspace


RUNTIME_MANIFEST_SCHEMA_VERSION = 2
RUNTIME_MANIFEST_KIND = "psychopatz_radio_runtime"
RADIO_FAMILIES = ("walkie", "ham", "manpack")
DEFAULT_INTERACTIVE_CONTROLS = (
    "back",
    "down",
    "home",
    "left",
    "ok",
    "power",
    "right",
    "up",
)
DEFAULT_HIDDEN_COMPONENTS = ("channel", "ptt", "volume")

UI_ICON_NAMES = (
    ("contacts", "radio_call", "trade", "dossier", "scan", "home", "back", "settings"),
    ("chat", "logs", "faction", "trader", "caravan", "signal", "battery", "mic"),
    ("speaker", "mute", "connecting", "receiving", "transmitting", "offline", "alert", "search"),
    ("plus", "minus", "next", "prev", "up", "down", "left", "right"),
)


def default_interaction_policy(full_type: str) -> dict[str, list[str]]:
    """Return the shared control policy used by the harness and compiler."""

    full_type = str(full_type or "")
    if full_type.startswith(("Base.WalkieTalkie", "Base.HamRadio", "Base.ManPackRadio")):
        return {
            "hidden_components": list(DEFAULT_HIDDEN_COMPONENTS),
            "interactive_controls": list(DEFAULT_INTERACTIVE_CONTROLS),
        }
    return {"hidden_components": [], "interactive_controls": []}


def interaction_policy(project: Mapping[str, Any]) -> dict[str, list[str]]:
    """Normalize explicit pilot policy, falling back to the shared default."""

    device = project.get("device") or {}
    full_type = str(device.get("fullType") or device.get("model") or "")
    raw = project.get("interaction") or project.get("simulator")
    if not isinstance(raw, Mapping) or not raw:
        raw = default_interaction_policy(full_type)
    hidden = sorted({str(value) for value in (raw.get("hidden_components") or ())})
    interactive = sorted({str(value) for value in (raw.get("interactive_controls") or ())})
    return {"hidden_components": hidden, "interactive_controls": interactive}


def semantic_action(value: Any, component_id: str | None = None) -> str:
    """Normalize authored action names without discarding the physical ID."""

    component = str(component_id or "").strip().lower()
    component_aliases = {
        "back": "back",
        "home": "home",
        "up": "up",
        "down": "down",
        "left": "left",
        "right": "right",
        "ok": "select",
        "center": "select",
        "power": "power",
        "ptt": "ptt",
    }
    if component in component_aliases:
        return component_aliases[component]
    normalized = str(value if value is not None else component_id or "").strip()
    aliases = {
        "BACK": "back",
        "HOME": "home",
        "MENU": "menu",
        "UP": "previous",
        "DOWN": "next",
        "LEFT": "previous",
        "RIGHT": "next",
        "SELECT": "select",
        "OK": "select",
        "POWER": "power",
        "POWER_TOGGLE": "power",
        "PTT": "ptt",
        "TRANSMIT_TOGGLE": "ptt",
        "TUNE": "channel",
        "VOLUME": "volume",
    }
    return aliases.get(normalized.upper(), normalized.lower())


def _rect(value: Any, *, name: str) -> list[int]:
    return parse_rect(value, name=name)


def _lcd_geometry(project: Mapping[str, Any]) -> dict[str, list[int]]:
    canvas = project.get("canvas") or {}
    canvas_rect = [0, 0, int(canvas.get("width", 0)), int(canvas.get("height", 0))]
    lcd = project.get("lcd") or {}
    modular = project.get("modular") or {}
    components = modular.get("components") or {}
    lcd_component = components.get("lcd") if isinstance(components, Mapping) else None

    def first(*values: Any) -> list[int] | None:
        for value in values:
            if value is None:
                continue
            try:
                return _rect(value, name="lcd geometry")
            except AssetHarnessError:
                continue
        return None

    aperture = first(
        lcd.get("aperture"),
        lcd_component.get("hitbox") if isinstance(lcd_component, Mapping) else None,
        lcd_component.get("rect") if isinstance(lcd_component, Mapping) else None,
    )
    backing = first(
        lcd.get("backing"),
        lcd_component.get("content") if isinstance(lcd_component, Mapping) else None,
        lcd_component.get("content_rect") if isinstance(lcd_component, Mapping) else None,
    )
    content = first(
        lcd.get("content"),
        lcd_component.get("content") if isinstance(lcd_component, Mapping) else None,
        lcd_component.get("content_rect") if isinstance(lcd_component, Mapping) else None,
    )
    aperture = aperture or backing or content or canvas_rect
    backing = backing or content or aperture
    content = content or backing or aperture
    return {"aperture": aperture, "backing": backing, "content": content}


def _asset_path(
    project_path: Path,
    project: Mapping[str, Any],
    value: Any,
    *,
    label: str,
) -> str:
    """Validate an authored image and rewrite it to a game-relative path."""

    if not isinstance(value, str) or not value.strip():
        raise AssetHarnessError("RUNTIME_ASSET_MISSING", f"{label} has no image path")
    workspace = project_workspace(project_path, project)
    source = resolve_reference(workspace, value, must_exist=True)
    runtime_root_value = str(
        (project.get("export") or {}).get("runtime_root")
        or "Contents/mods/PsychopatzCore/common/media/ui"
    )
    runtime_root = resolve_reference(workspace, runtime_root_value)
    try:
        relative = source.relative_to(runtime_root).as_posix()
    except ValueError as error:
        raise AssetHarnessError(
            "RUNTIME_ASSET_OUTSIDE_MEDIA",
            f"{label} is outside the Core runtime media root: {source}",
        ) from error
    return "media/ui/" + relative


def _state_entry(
    project_path: Path,
    project: Mapping[str, Any],
    value: Any,
    *,
    label: str,
) -> dict[str, Any]:
    if isinstance(value, str):
        value = {"image": value}
    if not isinstance(value, Mapping):
        raise AssetHarnessError("RUNTIME_STATE_INVALID", f"{label} must be an object or image path")
    entry = {
        "image": _asset_path(project_path, project, value.get("image"), label=label),
        "x": int(value.get("x", 0)),
        "y": int(value.get("y", 0)),
    }
    if value.get("anchor") is not None:
        entry["anchor"] = str(value.get("anchor"))
    return entry


def _layer_entry(
    project_path: Path,
    project: Mapping[str, Any],
    value: Any,
    *,
    label: str,
) -> dict[str, Any]:
    if isinstance(value, str):
        value = {"image": value}
    if not isinstance(value, Mapping):
        raise AssetHarnessError("RUNTIME_LAYER_INVALID", f"{label} must be an object or image path")
    return {
        "image": _asset_path(project_path, project, value.get("image"), label=label),
        "x": int(value.get("x", 0)),
        "y": int(value.get("y", 0)),
    }


def _compile_ui_manifest(
    project_path: Path,
    project: Mapping[str, Any],
) -> dict[str, Any]:
    """Compile Core-owned app chrome from the same runtime projection."""

    regions = {}
    for row, names in enumerate(UI_ICON_NAMES):
        for column, name in enumerate(names):
            regions[f"icon_{name}"] = [column * 64, row * 64, 64, 64]
    return {
        "icons": {
            "image": _asset_path(
                project_path,
                project,
                "Contents/mods/PsychopatzCore/common/media/ui/Radio/OS/Icons.png",
                label="ui.icons",
            ),
            "width": 512,
            "height": 512,
            "cell": 64,
            "regions": regions,
        },
    }


def _compile_device(project_path: Path, project: Mapping[str, Any]) -> dict[str, Any]:
    device = project.get("device") or {}
    if not isinstance(device, Mapping):
        raise AssetHarnessError("RUNTIME_DEVICE_INVALID", f"device must be an object: {project_path}")
    device_id = str(project.get("project_id") or device.get("id") or "")
    full_type = str(device.get("fullType") or device.get("model") or "")
    if not device_id or not full_type:
        raise AssetHarnessError("RUNTIME_DEVICE_INVALID", f"device identity is incomplete: {project_path}")
    canvas = project.get("canvas") or {}
    width = int(canvas.get("width", 0))
    height = int(canvas.get("height", 0))
    if width <= 0 or height <= 0:
        raise AssetHarnessError("RUNTIME_CANVAS_INVALID", f"invalid canvas for {device_id}")
    canvas_rect = [0, 0, width, height]
    modular = project.get("modular") or {}
    chassis_source = modular.get("chassis") or {}
    chassis: dict[str, Any] = {}
    for variant in ("pristine", "worn"):
        entry = chassis_source.get(variant)
        if not isinstance(entry, Mapping):
            raise AssetHarnessError("RUNTIME_CHASSIS_MISSING", f"{device_id} has no {variant} chassis")
        image = _asset_path(project_path, project, entry.get("image"), label=f"{device_id}.chassis.{variant}")
        record: dict[str, Any] = {"image": image}
        if isinstance(entry.get("anchors"), Mapping):
            record["anchors"] = {
                str(name): [int(point[0]), int(point[1])]
                for name, point in sorted(entry["anchors"].items())
                if isinstance(point, (list, tuple)) and len(point) == 2
            }
        chassis[variant] = record

    lcd_layers_source = modular.get("lcd_layers") or {}
    lcd_layers: dict[str, Any] = {}
    for layer_name in ("matte", "glass", "bezel_overlay"):
        entry = lcd_layers_source.get(layer_name)
        if entry is not None:
            lcd_layers[layer_name] = _layer_entry(
                project_path,
                project,
                entry,
                label=f"{device_id}.lcd.{layer_name}",
            )

    policy = interaction_policy(project)
    hidden = set(policy["hidden_components"])
    interactive = set(policy["interactive_controls"])
    components_source = modular.get("components") or {}
    components: list[dict[str, Any]] = []
    for component_id, source in sorted(components_source.items(), key=lambda item: str(item[0])):
        if not isinstance(source, Mapping):
            raise AssetHarnessError("RUNTIME_COMPONENT_INVALID", f"{device_id}.{component_id} is not an object")
        component_id = str(component_id)
        hitbox = source.get("hitbox") or source.get("rect")
        if hitbox is None:
            raise AssetHarnessError("RUNTIME_HITBOX_MISSING", f"{device_id}.{component_id} has no hitbox")
        hitbox = _rect(hitbox, name=f"{device_id}.{component_id}.hitbox")
        if not rect_inside(hitbox, canvas_rect):
            raise AssetHarnessError("RUNTIME_HITBOX_OUTSIDE_CANVAS", f"{device_id}.{component_id} hitbox is outside canvas")
        states_source = source.get("states") or {}
        if not isinstance(states_source, Mapping) or not states_source:
            raise AssetHarnessError("RUNTIME_STATES_MISSING", f"{device_id}.{component_id} has no states")
        states = {
            str(state_name): _state_entry(
                project_path,
                project,
                state,
                label=f"{device_id}.{component_id}.{state_name}",
            )
            for state_name, state in sorted(states_source.items(), key=lambda item: str(item[0]))
        }
        kind = str(source.get("kind") or "momentary").lower()
        is_interactive = component_id in interactive and kind != "led" and component_id not in hidden
        component: dict[str, Any] = {
            "id": component_id,
            "kind": kind,
            "action": semantic_action(source.get("action"), component_id),
            "hitbox": hitbox,
            "interactive": is_interactive,
            "visible": component_id not in hidden,
            "states": states,
        }
        if source.get("pivot") is not None:
            pivot = source.get("pivot")
            if not isinstance(pivot, (list, tuple)) or len(pivot) != 2:
                raise AssetHarnessError("RUNTIME_PIVOT_INVALID", f"{device_id}.{component_id} pivot is invalid")
            component["pivot"] = [int(pivot[0]), int(pivot[1])]
        if source.get("detents") is not None:
            component["detents"] = int(source.get("detents"))
        components.append(component)

    active = [item for item in components if item["interactive"]]
    for index, first in enumerate(active):
        for second in active[index + 1:]:
            if rect_overlap(first["hitbox"], second["hitbox"]):
                raise AssetHarnessError(
                    "RUNTIME_HITBOX_OVERLAP",
                    f"{device_id} interactive hitboxes overlap: {first['id']} and {second['id']}",
                )

    return {
        "id": device_id,
        "family": str(device.get("family") or "radio"),
        "model": str(device.get("model") or full_type),
        "fullType": full_type,
        "canvas": {
            "width": width,
            "height": height,
            "origin": str(canvas.get("origin") or "top_left"),
        },
        "lcd": _lcd_geometry(project),
        "chassis": chassis,
        "lcd_layers": lcd_layers,
        "interaction": policy,
        "components": components,
    }


def compile_runtime_manifest(
    project_root: Path,
    *,
    device_id: str | None = None,
) -> dict[str, Any]:
    """Compile every canonical pilot, or one selected pilot, deterministically."""

    project_root = Path(project_root).expanduser().resolve()
    paths = sorted(project_root.glob("*_pilot.json"))
    if device_id:
        normalized = str(device_id).strip()
        paths = [
            path
            for path in paths
            if str((json.loads(path.read_text(encoding="utf-8")).get("project_id") or "")) == normalized
            or str((json.loads(path.read_text(encoding="utf-8")).get("device") or {}).get("id") or "") == normalized
        ]
    if not paths:
        raise AssetHarnessError("RUNTIME_PROJECT_NOT_FOUND", f"no canonical pilot found in {project_root}")
    first_project = load_project(paths[0])
    devices = [
        _compile_device(path, load_project(path))
        for path in paths
    ]
    full_types = [device["fullType"] for device in devices]
    if len(set(full_types)) != len(full_types):
        raise AssetHarnessError("RUNTIME_FULLTYPE_DUPLICATE", "canonical pilots contain duplicate fullType values")
    devices.sort(key=lambda item: (item["family"], item["fullType"], item["id"]))
    return {
        "schema_version": RUNTIME_MANIFEST_SCHEMA_VERSION,
        "manifest_kind": RUNTIME_MANIFEST_KIND,
        "ui": _compile_ui_manifest(paths[0], first_project),
        "devices": devices,
    }


def manifest_json(manifest: Mapping[str, Any]) -> str:
    """Return stable compact JSON suitable for the packaged mod file."""

    return json.dumps(manifest, ensure_ascii=True, sort_keys=True, separators=(",", ":")) + "\n"
