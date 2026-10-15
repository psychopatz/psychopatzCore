"""Versioned modular-radio project contracts and Pillow composition.

This is an additive layer over the existing v1 project/layer compositor.  It
owns modular chassis/component state data and only renders when the authored
files exist; incomplete source audits stay visibly blocked.
"""

from __future__ import annotations

from pathlib import Path
from itertools import islice, product
from typing import Any, Mapping, Sequence

from PIL import Image

from .errors import AssetHarnessError, diagnostic
from .masks import validate_mask
from .layers import layer_position, resolve_layer_image
from .paths import canvas_rect, parse_rect, rect_inside, resolve_reference
from .project import project_workspace
from .responses import sha256_path


MODULAR_SCHEMA_VERSION = 1
CHASSIS_VARIANTS = ("pristine", "worn")
REQUIRED_STATES = {
    "momentary": ("idle", "pressed"),
    "button": ("idle", "pressed"),
    "hold": ("idle", "held"),
    "ptt": ("idle", "held"),
    "power": ("off", "on"),
    "switch": ("off", "on"),
    "rotary": (),
    "knob": (),
    "led": ("off", "on"),
}
LCD_LAYER_KEYS = ("glass", "bezel_overlay")


def ensure_modular(project: dict[str, Any]) -> dict[str, Any]:
    value = project.get("modular")
    if not isinstance(value, dict):
        value = {}
        project["modular"] = value
    value.setdefault("schema_version", MODULAR_SCHEMA_VERSION)
    value.setdefault("status", "incomplete")
    value.setdefault("chassis", {})
    value.setdefault("components", {})
    value.setdefault("verification", {"reviewed": False, "status": "incomplete", "reasons": []})
    return value


def set_chassis(
    project: dict[str, Any],
    variant: str,
    *,
    image: str,
    socket_mask: str | None = None,
    anchors: Mapping[str, Any] | None = None,
    status: str = "proposed",
    notes: str | None = None,
    review: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    normalized = str(variant).strip().lower()
    if normalized not in CHASSIS_VARIANTS:
        raise AssetHarnessError("INVALID_CHASSIS_VARIANT", f"expected pristine or worn, got: {variant}")
    if status not in {"proposed", "verified", "blocked"}:
        raise AssetHarnessError("INVALID_CHASSIS_STATUS", f"unsupported chassis status: {status}")
    entry: dict[str, Any] = {
        "image": str(image),
        "socket_mask": str(socket_mask) if socket_mask else None,
        "anchors": dict(anchors or {}),
        "status": status,
        "review": dict(review or {}),
    }
    if notes:
        entry["notes"] = str(notes)
    modular = ensure_modular(project)
    modular.setdefault("chassis", {})[normalized] = entry
    return entry


def set_lcd_layers(
    project: dict[str, Any],
    *,
    glass: str,
    bezel_overlay: str,
    matte: str | None = None,
    status: str = "proposed",
    notes: str | None = None,
    review: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Register independent LCD shell layers without baking dynamic content."""

    if status not in {"proposed", "verified", "blocked"}:
        raise AssetHarnessError("INVALID_LCD_STATUS", f"unsupported LCD status: {status}")
    if not glass or not bezel_overlay:
        raise AssetHarnessError("LCD_LAYERS_REQUIRED", "LCD glass and bezel overlay are both required")
    entry: dict[str, Any] = {
        "glass": {"image": str(glass)},
        "bezel_overlay": {"image": str(bezel_overlay)},
        "status": status,
        "review": dict(review or {}),
    }
    if matte:
        entry["matte"] = {"image": str(matte)}
    if notes:
        entry["notes"] = str(notes)
    ensure_modular(project)["lcd_layers"] = entry
    return entry


def set_component(
    project: dict[str, Any],
    component_id: str,
    *,
    kind: str,
    action: str | None,
    states: Mapping[str, Any],
    hitbox: Sequence[int] | str | None = None,
    pivot: Sequence[int] | None = None,
    detents: int | None = None,
    mask: str | None = None,
    socket_mask: str | None = None,
    status: str = "proposed",
    notes: str | None = None,
    review: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    if not component_id or any(character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for character in component_id):
        raise AssetHarnessError("INVALID_COMPONENT_ID", f"invalid component ID: {component_id!r}")
    if not isinstance(states, Mapping) or not states:
        raise AssetHarnessError("COMPONENT_STATES_REQUIRED", f"component {component_id} needs at least one state")
    if status not in {"proposed", "verified", "blocked"}:
        raise AssetHarnessError("INVALID_COMPONENT_STATUS", f"unsupported component status: {status}")
    entry: dict[str, Any] = {
        "kind": str(kind).strip().lower(),
        "action": str(action) if action is not None else None,
        "states": {str(name): value for name, value in states.items()},
        "status": status,
        "review": dict(review or {}),
    }
    if hitbox is not None:
        entry["hitbox"] = parse_rect(hitbox, name=f"component {component_id} hitbox")
    if pivot is not None:
        if len(pivot) != 2:
            raise AssetHarnessError("INVALID_PIVOT", f"component {component_id} pivot must contain x,y")
        entry["pivot"] = [int(pivot[0]), int(pivot[1])]
    if detents is not None:
        entry["detents"] = int(detents)
    if socket_mask:
        entry["socket_mask"] = str(socket_mask)
    if mask:
        entry["mask"] = str(mask)
    if notes:
        entry["notes"] = str(notes)
    ensure_modular(project).setdefault("components", {})[component_id] = entry
    return entry


def _resolve_image_path(project_path: Path, project: dict[str, Any], value: str) -> Path:
    workspace = project_workspace(project_path, project)
    return resolve_reference(workspace, value, allow_external=Path(value).is_absolute(), must_exist=True)


def _load_entry_image(project_path: Path, project: dict[str, Any], entry: Mapping[str, Any], *, label: str) -> tuple[Image.Image, Path | None]:
    image_value = entry.get("image")
    if image_value:
        path = _resolve_image_path(project_path, project, str(image_value))
        try:
            with Image.open(path) as image:
                image.load()
                return image.convert("RGBA").copy(), path
        except (OSError, ValueError, UnicodeError) as error:
            raise AssetHarnessError("MODULAR_IMAGE_UNREADABLE", f"cannot load {label}: {path}: {error}") from error
    source_id = entry.get("source")
    if source_id:
        pseudo_layer = {
            "id": label,
            "source": str(source_id),
            "region": entry.get("region"),
            "x": int(entry.get("x", 0)),
            "y": int(entry.get("y", 0)),
            "anchor": entry.get("anchor", "top_left"),
        }
        return resolve_layer_image(project_path, project, pseudo_layer), None
    raise AssetHarnessError("MODULAR_IMAGE_MISSING", f"{label} has no image or registered source")


def _paste(canvas: Image.Image, image: Image.Image, entry: Mapping[str, Any]) -> dict[str, Any]:
    x = int(entry.get("x", (entry.get("position") or {}).get("x", 0)))
    y = int(entry.get("y", (entry.get("position") or {}).get("y", 0)))
    anchor = str(entry.get("anchor", "top_left"))
    x, y = layer_position({"x": x, "y": y, "anchor": anchor}, image.width, image.height)
    canvas.alpha_composite(image, (x, y))
    return {"x": x, "y": y, "width": image.width, "height": image.height}


def render_modular(
    project_path: Path,
    project: dict[str, Any],
    *,
    variant: str = "pristine",
    states: Mapping[str, str] | None = None,
) -> tuple[Image.Image, dict[str, Any]]:
    modular = ensure_modular(project)
    normalized_variant = str(variant).strip().lower()
    if normalized_variant not in CHASSIS_VARIANTS:
        raise AssetHarnessError("INVALID_CHASSIS_VARIANT", f"expected pristine or worn, got: {variant}")
    chassis = (modular.get("chassis") or {}).get(normalized_variant)
    if not isinstance(chassis, dict):
        raise AssetHarnessError("CHASSIS_VARIANT_MISSING", f"modular project has no {normalized_variant} chassis")
    bounds = canvas_rect(project)
    if bounds[2] <= 0 or bounds[3] <= 0:
        raise AssetHarnessError("PROJECT_INVALID", "canvas dimensions must be positive")
    canvas, chassis_path = _load_entry_image(project_path, project, chassis, label=f"chassis.{normalized_variant}")
    if canvas.size != (bounds[2], bounds[3]):
        raise AssetHarnessError("CHASSIS_CANVAS_MISMATCH", f"{normalized_variant} chassis must match project canvas")
    drawn = [{"id": f"chassis.{normalized_variant}", "path": str(chassis_path) if chassis_path else None, "state": normalized_variant, "x": 0, "y": 0, "width": canvas.width, "height": canvas.height}]
    lcd_layers = modular.get("lcd_layers") or {}
    if lcd_layers:
        if not isinstance(lcd_layers, Mapping):
            raise AssetHarnessError("LCD_LAYERS_INVALID", "modular LCD layers must be an object")
        for layer_id in ("matte", "glass", "bezel_overlay"):
            layer_entry = lcd_layers.get(layer_id)
            if layer_entry is None:
                continue
            if isinstance(layer_entry, str):
                layer_entry = {"image": layer_entry}
            if not isinstance(layer_entry, Mapping):
                raise AssetHarnessError("LCD_LAYER_INVALID", f"invalid LCD layer: {layer_id}")
            image, image_path = _load_entry_image(project_path, project, layer_entry, label=f"lcd.{layer_id}")
            placed = _paste(canvas, image, layer_entry)
            drawn.append({"id": f"lcd.{layer_id}", "state": "static", "path": str(image_path) if image_path else None, **placed})
    selected = {str(key): str(value) for key, value in (states or {}).items()}
    for component_id, component in sorted((modular.get("components") or {}).items()):
        if not isinstance(component, dict):
            raise AssetHarnessError("COMPONENT_INVALID", f"component is not an object: {component_id}")
        state_map = component.get("states") or {}
        if not isinstance(state_map, Mapping) or not state_map:
            raise AssetHarnessError("COMPONENT_STATES_REQUIRED", f"component has no states: {component_id}")
        state_name = selected.get(str(component_id), str(component.get("default_state") or ("idle" if "idle" in state_map else next(iter(state_map)))))
        state_entry = state_map.get(state_name)
        if isinstance(state_entry, str):
            state_entry = {"image": state_entry}
        if not isinstance(state_entry, Mapping):
            raise AssetHarnessError("COMPONENT_STATE_INVALID", f"invalid state {state_name} for {component_id}")
        image, image_path = _load_entry_image(project_path, project, state_entry, label=f"component {component_id}.{state_name}")
        placed = _paste(canvas, image, state_entry)
        drawn.append({"id": str(component_id), "state": state_name, "path": str(image_path) if image_path else None, **placed})
    return canvas, {
        "width": canvas.width,
        "height": canvas.height,
        "variant": normalized_variant,
        "states": selected,
        "layers": drawn,
        "status": modular.get("status"),
    }


def render_modular_contact_sheet(
    project_path: Path,
    project: dict[str, Any],
    *,
    columns: int = 4,
    max_combinations: int = 64,
) -> tuple[Image.Image, list[dict[str, Any]]]:
    """Render bounded pristine/worn × component-state combinations."""

    modular = ensure_modular(project)
    components = modular.get("components") or {}
    component_ids = sorted(str(key) for key in components)
    state_values: list[list[str]] = []
    for component_id in component_ids:
        state_map = components[component_id].get("states") or {}
        state_values.append([str(name) for name in sorted(state_map)])
    if state_values:
        combinations = list(islice(product(*state_values), max(1, int(max_combinations))))
    else:
        combinations = [()]
    images: list[Image.Image] = []
    metadata: list[dict[str, Any]] = []
    for variant in CHASSIS_VARIANTS:
        for values in combinations:
            selected = dict(zip(component_ids, values))
            image, frame_metadata = render_modular(project_path, project, variant=variant, states=selected)
            images.append(image)
            metadata.append({"variant": variant, "states": selected, "width": image.width, "height": image.height, "layers": frame_metadata["layers"]})
    from .render import contact_sheet

    return contact_sheet(images, columns=columns), metadata


def _sha_for_entry(project_path: Path, project: dict[str, Any], entry: Any) -> str | None:
    if isinstance(entry, str):
        path = _resolve_image_path(project_path, project, entry)
    elif isinstance(entry, Mapping) and entry.get("image"):
        path = _resolve_image_path(project_path, project, str(entry["image"]))
    else:
        return None
    return sha256_path(path)


def validate_modular(project_path: Path, project: dict[str, Any]) -> dict[str, Any]:
    modular = project.get("modular")
    if (
        not isinstance(modular, dict)
        or not modular
        or (
            str(modular.get("status")) == "unconfigured"
            and not (modular.get("chassis") or modular.get("components") or modular.get("lcd_layers"))
        )
    ):
        return {"ok": True, "summary": {"checks": 0, "passed": 0, "failed": 0, "warnings": 0}, "diagnostics": []}
    diagnostics: list[dict[str, Any]] = []
    checks = 0
    passed = 0
    errors = {"error"}
    verification = modular.get("verification") or {}
    production = str(modular.get("status")) in {"verified", "complete", "production_ready"} or str(verification.get("status")) in {"verified", "complete", "production_ready"}

    def check(condition: bool, code: str, message: str, *, severity: str = "error", asset: str | None = None, remediation: str | None = None) -> None:
        nonlocal checks, passed
        checks += 1
        if condition:
            passed += 1
        else:
            diagnostics.append(diagnostic(code, message, severity=severity, asset=asset, remediation=remediation))

    check(int(modular.get("schema_version", 0)) == MODULAR_SCHEMA_VERSION, "MODULAR_SCHEMA_UNSUPPORTED", "unsupported modular project schema")
    chassis = modular.get("chassis") or {}
    for variant in CHASSIS_VARIANTS:
        entry = chassis.get(variant)
        check(isinstance(entry, Mapping), "CHASSIS_VARIANT_MISSING", f"missing {variant} chassis", asset=variant, remediation="author independent Pristine.png and Worn.png files")
        if not isinstance(entry, Mapping):
            continue
        try:
            image, _ = _load_entry_image(project_path, project, entry, label=f"chassis.{variant}")
            canvas = canvas_rect(project)
            check(image.size == (canvas[2], canvas[3]), "CHASSIS_CANVAS_MISMATCH", f"{variant} chassis does not match project canvas", asset=variant)
        except AssetHarnessError as error:
            diagnostics.append(diagnostic(error.code, error.message, asset=variant))
            checks += 1
        anchors = entry.get("anchors")
        if anchors is not None:
            check(isinstance(anchors, Mapping), "CHASSIS_ANCHORS_INVALID", f"{variant} chassis anchors must be an object", asset=variant)
            if isinstance(anchors, Mapping):
                for anchor_id, point in anchors.items():
                    valid_point = isinstance(point, (list, tuple)) and len(point) == 2
                    if valid_point:
                        try:
                            x, y = int(point[0]), int(point[1])
                            valid_point = 0 <= x < canvas_rect(project)[2] and 0 <= y < canvas_rect(project)[3]
                        except (TypeError, ValueError):
                            valid_point = False
                    check(valid_point, "CHASSIS_ANCHOR_INVALID", "chassis anchor must be an integer point inside the canvas", asset=f"{variant}.{anchor_id}")
        if production:
            check(str(entry.get("status")) == "verified", "CHASSIS_NOT_VISUALLY_VERIFIED", f"production {variant} chassis is not visually verified", asset=variant)
            chassis_review = entry.get("review") if isinstance(entry.get("review"), Mapping) else {}
            check(bool(chassis_review.get("reviewed")), "CHASSIS_REVIEW_EVIDENCE_MISSING", f"production {variant} chassis has no visual-review evidence", asset=variant, remediation="record reviewer identity and full-resolution chassis previews")
            check(bool(entry.get("socket_mask")), "SOCKET_MASK_MISSING", f"{variant} chassis has no reconstructed socket mask", asset=variant, remediation="author and visually verify every empty control socket")
            check(bool(entry.get("anchors")), "CHASSIS_ANCHORS_MISSING", f"{variant} chassis has no registered anchors", asset=variant)
            socket_mask = entry.get("socket_mask")
            if socket_mask:
                try:
                    mask_result = validate_mask(project_path, project, str(socket_mask), production=True)
                    diagnostics.extend(mask_result["diagnostics"])
                    checks += int(mask_result["summary"].get("checks", 0))
                    passed += int(mask_result["summary"].get("passed", 0))
                except AssetHarnessError as error:
                    diagnostics.append(diagnostic(error.code, error.message, asset=f"{variant}.socket_mask"))
                    checks += 1
    pristine_anchors = (chassis.get("pristine") or {}).get("anchors") if isinstance(chassis.get("pristine"), Mapping) else None
    worn_anchors = (chassis.get("worn") or {}).get("anchors") if isinstance(chassis.get("worn"), Mapping) else None
    if pristine_anchors is not None or worn_anchors is not None:
        check(pristine_anchors == worn_anchors, "CHASSIS_ANCHOR_DRIFT", "pristine and worn chassis anchors differ", remediation="register both conditions on one integer source canvas")

    canvas = canvas_rect(project)
    components = modular.get("components") or {}
    required_components = modular.get("required_components") or []
    lcd_layers = modular.get("lcd_layers")
    lcd_required = (
        isinstance(required_components, Sequence)
        and not isinstance(required_components, (str, bytes))
        and "lcd" in {str(item) for item in required_components}
    )
    if lcd_required or lcd_layers:
        check(
            isinstance(lcd_layers, Mapping),
            "LCD_LAYERS_MISSING",
            "LCD requires independent glass and bezel overlay layers",
            remediation="register LCD/Glass.png and LCD/BezelOverlay.png",
        )
        if isinstance(lcd_layers, Mapping):
            for layer_id in ("matte",) + LCD_LAYER_KEYS:
                layer_entry = lcd_layers.get(layer_id)
                if layer_id in LCD_LAYER_KEYS:
                    check(layer_entry is not None, "LCD_LAYER_MISSING", f"LCD layer is missing: {layer_id}", asset=f"lcd.{layer_id}")
                elif layer_entry is None:
                    continue
                if layer_entry is None:
                    continue
                if isinstance(layer_entry, str):
                    layer_entry = {"image": layer_entry}
                check(isinstance(layer_entry, Mapping), "LCD_LAYER_INVALID", f"LCD layer must be an image entry: {layer_id}", asset=f"lcd.{layer_id}")
                if not isinstance(layer_entry, Mapping):
                    continue
                try:
                    layer_image, _ = _load_entry_image(project_path, project, layer_entry, label=f"lcd.{layer_id}")
                    check(layer_image.size == (canvas[2], canvas[3]), "LCD_LAYER_CANVAS_MISMATCH", f"LCD {layer_id} does not match project canvas", asset=f"lcd.{layer_id}")
                except AssetHarnessError as error:
                    diagnostics.append(diagnostic(error.code, error.message, asset=f"lcd.{layer_id}"))
                    checks += 1
            if production:
                check(str(lcd_layers.get("status")) == "verified", "LCD_LAYERS_NOT_VISUALLY_VERIFIED", "production LCD layers are not visually verified", asset="lcd")
                lcd_review = lcd_layers.get("review") if isinstance(lcd_layers.get("review"), Mapping) else {}
                check(bool(lcd_review.get("reviewed")), "LCD_REVIEW_EVIDENCE_MISSING", "production LCD layers have no visual-review evidence", asset="lcd", remediation="record full-resolution glass/bezel previews")
    if isinstance(required_components, Sequence) and not isinstance(required_components, (str, bytes)):
        for required_id in required_components:
            required_name = str(required_id)
            if required_name == "lcd" and isinstance(lcd_layers, Mapping):
                continue
            check(required_name in components, "REQUIRED_COMPONENT_MISSING", "required semantic component is not authored", asset=required_name, remediation="add a reviewed device-local component or document why this model lacks it")
    for component_id, component in sorted(components.items()):
        if not isinstance(component, Mapping):
            diagnostics.append(diagnostic("COMPONENT_INVALID", "component must be an object", asset=str(component_id)))
            checks += 1
            continue
        kind = str(component.get("kind") or "").strip().lower()
        state_map = component.get("states") or {}
        check(bool(kind), "COMPONENT_KIND_MISSING", "component kind is required", asset=str(component_id))
        check(isinstance(state_map, Mapping) and bool(state_map), "COMPONENT_STATES_REQUIRED", "component needs one or more keyed states", asset=str(component_id))
        required = REQUIRED_STATES.get(kind, ())
        for required_state in required:
            check(required_state in state_map, "COMPONENT_STATE_MISSING", f"{kind} component is missing {required_state} state", asset=str(component_id))
        hitbox = component.get("hitbox")
        if hitbox is not None:
            try:
                check(rect_inside(parse_rect(hitbox), canvas), "CONTROL_OUT_OF_BOUNDS", "component hitbox exceeds the canvas", asset=str(component_id))
            except AssetHarnessError:
                diagnostics.append(diagnostic("CONTROL_INVALID", "component hitbox is invalid", asset=str(component_id)))
                checks += 1
        if kind in {"rotary", "knob"}:
            frames = [name for name in state_map if str(name).startswith("frame_")]
            detents = int(component.get("detents", len(frames)))
            check(len(frames) >= 2 or detents >= 2, "ROTARY_FRAMES_MISSING", "rotary component needs at least two authored detents", asset=str(component_id))
            check(isinstance(component.get("pivot"), (list, tuple)) and len(component.get("pivot")) == 2, "ROTARY_PIVOT_MISSING", "rotary component needs a registered pivot", asset=str(component_id))
            check(2 <= detents <= 16, "ROTARY_DETENTS_INVALID", "rotary detents must be bounded between 2 and 16", asset=str(component_id))
        if production:
            check(bool(component.get("mask")), "COMPONENT_MASK_MISSING", "movable component has no independently authored silhouette mask", asset=str(component_id), remediation="register a source-canvas alpha/path mask for the moving face")
            check(bool(component.get("socket_mask")), "SOCKET_MASK_MISSING", "movable component has no socket mask", asset=str(component_id), remediation="author the empty recess separately from the moving part")
            check(str(component.get("status")) == "verified", "COMPONENT_NOT_VISUALLY_VERIFIED", "production component is not visually verified", asset=str(component_id))
            component_review = component.get("review") if isinstance(component.get("review"), Mapping) else {}
            check(bool(component_review.get("reviewed")), "COMPONENT_REVIEW_EVIDENCE_MISSING", "production component has no visual-review evidence", asset=str(component_id), remediation="record reviewer identity and full-resolution state previews")
            for mask_key in ("mask", "socket_mask"):
                mask_id = component.get(mask_key)
                if mask_id:
                    try:
                        mask_result = validate_mask(project_path, project, str(mask_id), production=True)
                        diagnostics.extend(mask_result["diagnostics"])
                        checks += int(mask_result["summary"].get("checks", 0))
                        passed += int(mask_result["summary"].get("passed", 0))
                    except AssetHarnessError as error:
                        diagnostics.append(diagnostic(error.code, error.message, asset=f"{component_id}.{mask_key}"))
                        checks += 1
        hashes: list[str] = []
        for state_name, state_entry in sorted(state_map.items()):
            try:
                state_value = {"image": state_entry} if isinstance(state_entry, str) else state_entry
                if not isinstance(state_value, Mapping):
                    raise AssetHarnessError("COMPONENT_STATE_INVALID", "state entry must be an image path or object")
                state_hash = _sha_for_entry(project_path, project, state_value)
                if state_hash:
                    hashes.append(state_hash)
            except AssetHarnessError as error:
                diagnostics.append(diagnostic(error.code, error.message, asset=f"{component_id}.{state_name}"))
                checks += 1
        if len(state_map) > 1:
            check(len(set(hashes)) > 1, "COMPONENT_STATES_IDENTICAL", "keyed component states resolve to identical image bytes", asset=str(component_id), remediation="author a real pressed/held/on/detent visual state")
    if production:
        check(bool(verification.get("reviewed")), "MODULAR_VISUAL_REVIEW_MISSING", "production-ready modular status requires explicit visual review evidence")
    error_count = sum(1 for item in diagnostics if item.get("severity") in errors)
    warning_count = sum(1 for item in diagnostics if item.get("severity") == "warning")
    return {
        "ok": error_count == 0,
        "summary": {"checks": checks, "passed": passed, "failed": error_count, "warnings": warning_count},
        "diagnostics": diagnostics,
    }
