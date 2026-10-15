"""Project, geometry, alpha, and source-integrity validation."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

from .animations import timeline
from .errors import diagnostic
from .layers import layer_position, ordered_layers, resolve_layer_image
from .paths import canvas_rect, parse_rect, rect_inside, rect_overlap, resolve_reference
from .project import project_workspace
from .render import parse_color
from .source import inspect_image


ROLE_ORDER = {
    "lcd_backing": 10,
    "lcd_background": 20,
    "content": 30,
    "lcd_content": 30,
    "effect": 40,
    "overlay": 40,
    "shell": 50,
    "shell_front": 50,
    "front_shell": 50,
    "hardware": 60,
    "condition": 70,
    "led": 80,
}


def _rect(value: Any, name: str) -> list[int] | None:
    try:
        return parse_rect(value, name=name)
    except Exception:
        return None


def _add(
    diagnostics: list[dict[str, Any]],
    code: str,
    message: str,
    *,
    severity: str = "error",
    asset: str | None = None,
    rect: list[int] | None = None,
    path: str | None = None,
    remediation: str | None = None,
) -> None:
    diagnostics.append(diagnostic(
        code, message, severity=severity, asset=asset, rect=rect, path=path,
        remediation=remediation,
    ))


def _alpha_hole_diagnostic(
    project_path: Path,
    project: dict[str, Any],
    layer: dict[str, Any],
    aperture: list[int],
) -> dict[str, Any] | None:
    try:
        image = resolve_layer_image(project_path, project, layer)
        x, y = layer_position(layer, image.width, image.height)
    except Exception:
        return None
    ax, ay, aw, ah = aperture
    start_x, start_y = max(ax, x), max(ay, y)
    end_x, end_y = min(ax + aw, x + image.width), min(ay + ah, y + image.height)
    if start_x >= end_x or start_y >= end_y:
        return None
    alpha = image.getchannel("A").load()
    for canvas_y in range(start_y, end_y):
        for canvas_x in range(start_x, end_x):
            if int(alpha[canvas_x - x, canvas_y - y]) != 0:
                return diagnostic(
                    "LCD_ALPHA_HOLE_FILLED",
                    "shell layer is not transparent across the designated LCD aperture",
                    asset=str(layer.get("id", "shell")),
                    rect=[start_x, start_y, end_x - start_x, end_y - start_y],
                    remediation="measure the aperture from the approved source and cut it to alpha zero",
                )
    return None


def validate_project(project_path: Path, project: dict[str, Any]) -> dict[str, Any]:
    diagnostics: list[dict[str, Any]] = []
    checks = 0
    passed = 0

    def check(condition: bool, code: str, message: str, **kwargs: Any) -> None:
        nonlocal checks, passed
        checks += 1
        if condition:
            passed += 1
        else:
            _add(diagnostics, code, message, **kwargs)

    canvas = canvas_rect(project)
    check(canvas[2] > 0 and canvas[3] > 0, "CANVAS_INVALID", "canvas dimensions must be positive")
    check(canvas[2] * canvas[3] <= 64 * 1024 * 1024, "CANVAS_TOO_LARGE", "canvas exceeds the pixel safety limit")
    workspace = project_workspace(project_path, project)

    sources = project.get("sources") or {}
    source_metadata: dict[str, dict[str, Any]] = {}
    for source_id, source in sorted(sources.items()):
        if not isinstance(source, dict):
            _add(diagnostics, "SOURCE_INVALID", f"source metadata is not an object: {source_id}", asset=source_id)
            checks += 1
            continue
        try:
            source_value = str(source.get("path", ""))
            source_path = resolve_reference(workspace, source_value, allow_external=Path(source_value).is_absolute(), must_exist=True)
            metadata = inspect_image(source_path)
            source_metadata[source_id] = metadata
            check(
                metadata["sha256"] == source.get("sha256"),
                "SOURCE_HASH_MISMATCH",
                "source bytes differ from the registered SHA-256",
                asset=source_id,
                path=str(source_path),
                remediation="re-register the source instead of silently accepting changed artwork",
            )
            check(
                [metadata["width"], metadata["height"]] == [source.get("width"), source.get("height")],
                "SOURCE_DIMENSIONS_CHANGED",
                "source dimensions differ from the registered dimensions",
                asset=source_id,
                path=str(source_path),
            )
            if not bool(source.get("approved", False)):
                _add(
                    diagnostics,
                    "SOURCE_UNAPPROVED",
                    "source is usable for offline authoring but is not approved for runtime export",
                    severity="warning",
                    asset=source_id,
                    path=str(source_path),
                    remediation="record authentic provenance and explicitly approve the reviewed source",
                )
        except Exception as error:
            checks += 1
            _add(diagnostics, "SOURCE_UNREADABLE", f"cannot validate source {source_id}: {error}", asset=source_id)

    regions = project.get("regions") or {}
    for region_id, region in sorted(regions.items()):
        checks += 1
        if not isinstance(region, dict):
            _add(diagnostics, "REGION_INVALID", f"region is not an object: {region_id}", asset=region_id)
            continue
        source_id = str(region.get("source") or "")
        metadata = source_metadata.get(source_id)
        rect = _rect(region.get("rect"), f"region {region_id}")
        if metadata and rect:
            if not rect_inside(rect, [0, 0, metadata["width"], metadata["height"]]):
                _add(diagnostics, "REGION_OUT_OF_BOUNDS", "region exceeds its source image", asset=region_id, rect=rect)
            else:
                passed += 1
        else:
            _add(diagnostics, "REGION_INVALID", "region must reference a readable source and positive rectangle", asset=region_id)
    exclusive_regions = [
        (str(region_id), region) for region_id, region in regions.items()
        if isinstance(region, dict) and bool(region.get("exclusive"))
    ]
    for index, (left_id, left) in enumerate(exclusive_regions):
        left_rect = _rect(left.get("rect"), f"region {left_id}")
        for right_id, right in exclusive_regions[index + 1:]:
            if str(left.get("source")) != str(right.get("source")):
                continue
            right_rect = _rect(right.get("rect"), f"region {right_id}")
            if left_rect and right_rect and rect_overlap(left_rect, right_rect):
                _add(diagnostics, "REGION_OVERLAP", f"exclusive regions overlap: {left_id} and {right_id}", asset=left_id, severity="error")

    layer_list = project.get("layers") or []
    all_layer_ids: set[str] = set()
    for index, layer in enumerate(layer_list):
        checks += 1
        if not isinstance(layer, dict):
            _add(diagnostics, "LAYER_INVALID", f"layer {index} is not an object")
            continue
        layer_id = str(layer.get("id") or f"layer_{index}")
        if layer_id in all_layer_ids:
            _add(diagnostics, "DUPLICATE_LAYER_ID", f"duplicate layer ID: {layer_id}", asset=layer_id)
        all_layer_ids.add(layer_id)
        try:
            image = resolve_layer_image(project_path, project, layer)
            x, y = layer_position(layer, image.width, image.height)
            check(
                x >= 0 and y >= 0 and x + image.width <= canvas[2] and y + image.height <= canvas[3],
                "LAYER_OUT_OF_BOUNDS",
                "layer image lies outside the project canvas",
                asset=layer_id,
                rect=[x, y, image.width, image.height],
            )
            opacity = float(layer.get("opacity", 1))
            check(0 <= opacity <= 1, "INVALID_OPACITY", "layer opacity must be between 0 and 1", asset=layer_id)
        except Exception as error:
            _add(diagnostics, "LAYER_INVALID", f"cannot resolve layer {layer_id}: {error}", asset=layer_id)

    role_layers = sorted(
        [layer for layer in layer_list if isinstance(layer, dict)],
        key=lambda layer: (int(layer.get("z", 0)), str(layer.get("id", ""))),
    )
    previous_role = -1
    for layer in role_layers:
        role = str(layer.get("role") or "")
        role_number = ROLE_ORDER.get(role, 45)
        if role and role_number < previous_role:
            _add(
                diagnostics,
                "LAYER_ORDER_INVALID",
                "layer roles are not in deterministic compositor order",
                asset=str(layer.get("id", "")),
                remediation="set z values in backing -> content -> shell -> hardware -> condition -> LED order",
            )
        previous_role = max(previous_role, role_number)

    lcd = project.get("lcd") or {}
    aperture = _rect(lcd.get("aperture"), "lcd aperture") if lcd.get("aperture") is not None else None
    backing = _rect(lcd.get("backing"), "lcd backing") if lcd.get("backing") is not None else aperture
    content = _rect(lcd.get("content"), "lcd content") if lcd.get("content") is not None else None
    if aperture:
        check(rect_inside(aperture, canvas), "LCD_APERTURE_OUT_OF_BOUNDS", "LCD aperture exceeds the canvas", rect=aperture)
        if backing:
            check(rect_inside(aperture, backing), "LCD_BACKDROP_GAP", "opaque LCD backing does not cover the complete aperture", rect=aperture, remediation="expand or measure the opaque matte to contain the visible aperture")
            try:
                check(parse_color(lcd.get("backing_color"), (15, 36, 22, 255))[3] == 255, "LCD_BACKDROP_NOT_OPAQUE", "LCD backing color must be fully opaque", rect=backing)
            except Exception:
                _add(diagnostics, "LCD_BACKDROP_COLOR_INVALID", "LCD backing color is invalid", rect=backing)
        else:
            _add(diagnostics, "LCD_BACKDROP_MISSING", "LCD aperture has no opaque backing rectangle", rect=aperture)
        if content:
            check(rect_inside(content, aperture), "LCD_CONTENT_OUT_OF_BOUNDS", "LCD content safe rectangle exceeds the aperture", rect=content)
        for layer in layer_list:
            if isinstance(layer, dict) and str(layer.get("role") or "") in {"shell", "shell_front", "front_shell"}:
                hole = _alpha_hole_diagnostic(project_path, project, layer, aperture)
                if hole:
                    diagnostics.append(hole)
                    break

    controls = project.get("controls") or []
    control_rects: list[tuple[str, list[int]]] = []
    for index, control in enumerate(controls):
        checks += 1
        if not isinstance(control, dict):
            _add(diagnostics, "CONTROL_INVALID", f"control {index} is not an object")
            continue
        control_id = str(control.get("id") or f"control_{index}")
        rect = _rect(control.get("rect", control.get("hitbox")), f"control {control_id}")
        hitbox = _rect(control.get("hitbox", control.get("rect")), f"control {control_id} hitbox")
        if rect and hitbox and rect_inside(rect, canvas) and rect_inside(hitbox, canvas):
            passed += 1
            control_rects.append((control_id, hitbox))
        else:
            _add(diagnostics, "CONTROL_OUT_OF_BOUNDS", "control visual rect or hitbox exceeds the canvas", asset=control_id, rect=hitbox or rect)
    for index, (left_id, left) in enumerate(control_rects):
        for right_id, right in control_rects[index + 1:]:
            if rect_overlap(left, right):
                _add(diagnostics, "CONTROL_HITBOX_OVERLAP", f"control hitboxes overlap: {left_id} and {right_id}", asset=left_id, severity="warning")

    for name in sorted((project.get("animations") or {})):
        try:
            timeline(project, name)
            checks += 1
            passed += 1
        except Exception as error:
            checks += 1
            _add(diagnostics, "ANIMATION_INVALID", f"animation {name} is invalid: {error}", asset=name)

    declared_variants = project.get("variants") or {}
    if "pristine" not in declared_variants:
        _add(diagnostics, "VARIANT_MISSING_PRISTINE", "project must declare a pristine baseline variant")
    for variant_name, variant in sorted(declared_variants.items()):
        checks += 1
        if not isinstance(variant, dict):
            _add(diagnostics, "VARIANT_INVALID", "variant declaration is not an object", asset=str(variant_name))
            continue
        layer_ids = variant.get("layers") or []
        if not isinstance(layer_ids, list) or any(str(layer_id) not in all_layer_ids for layer_id in layer_ids):
            _add(diagnostics, "VARIANT_LAYER_UNKNOWN", "variant references an unknown layer", asset=str(variant_name))
        else:
            passed += 1
    for layer in layer_list:
        if not isinstance(layer, dict):
            continue
        selectors = layer.get("variants", layer.get("variant"))
        if selectors is None:
            continue
        values = [selectors] if isinstance(selectors, str) else list(selectors or [])
        for value in values:
            checks += 1
            if str(value) in declared_variants:
                passed += 1
            else:
                _add(diagnostics, "VARIANT_UNDECLARED", "layer references an undeclared variant", asset=str(layer.get("id", "")))

    errors = [item for item in diagnostics if item.get("severity") == "error"]
    warnings = [item for item in diagnostics if item.get("severity") == "warning"]
    return {
        "ok": not errors,
        "summary": {
            "checks": checks,
            "passed": passed,
            "failed": len(errors),
            "warnings": len(warnings),
        },
        "diagnostics": diagnostics,
    }
