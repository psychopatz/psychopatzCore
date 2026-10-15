"""Layer resolution and device-local anchor geometry."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

from PIL import Image

from .errors import AssetHarnessError
from .paths import parse_rect, resolve_reference
from .project import project_workspace
from .source import load_rgba


def layer_matches(layer: dict[str, Any], *, state: str | None, variant: str) -> bool:
    states = layer.get("states", layer.get("state"))
    if states is not None:
        allowed = [states] if isinstance(states, str) else list(states or [])
        if state not in {str(value) for value in allowed}:
            return False
    variants = layer.get("variants", layer.get("variant"))
    if variants is not None:
        allowed = [variants] if isinstance(variants, str) else list(variants or [])
        if variant not in {str(value) for value in allowed}:
            return False
    return True


def ordered_layers(
    project: dict[str, Any], *, state: str | None = None, variant: str = "pristine"
) -> list[dict[str, Any]]:
    layers = []
    for index, raw in enumerate(project.get("layers") or []):
        if not isinstance(raw, dict) or not layer_matches(raw, state=state, variant=variant):
            continue
        layer = dict(raw)
        layer["_order"] = index
        layer["z"] = int(layer.get("z", index))
        layers.append(layer)
    layers.sort(key=lambda item: (int(item["z"]), int(item["_order"]), str(item.get("id", ""))))
    return layers


def resolve_layer_image(project_path: Path, project: dict[str, Any], layer: dict[str, Any]) -> Image.Image:
    source_ref = str(layer.get("source") or "")
    region_id = str(layer.get("region") or "")
    regions = project.get("regions") or {}
    if not region_id and source_ref in regions:
        region_id = source_ref
    if region_id:
        region = regions.get(region_id)
        if not isinstance(region, dict):
            raise AssetHarnessError("REGION_NOT_FOUND", f"layer region is not defined: {region_id}")
        source_ref = str(region.get("source") or "")
        rect = parse_rect(region.get("rect"), name=f"region {region_id}")
    else:
        rect = None
    source = (project.get("sources") or {}).get(source_ref)
    if not isinstance(source, dict):
        raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"layer source is not registered: {source_ref}")
    root = project_workspace(project_path, project)
    source_value = str(source.get("path", ""))
    source_path = resolve_reference(root, source_value, allow_external=Path(source_value).is_absolute(), must_exist=True)
    image = load_rgba(source_path)
    if rect is not None:
        x, y, width, height = rect
        if x < 0 or y < 0 or x + width > image.width or y + height > image.height:
            raise AssetHarnessError("REGION_OUT_OF_BOUNDS", f"region exceeds source: {region_id}")
        image = image.crop((x, y, x + width, y + height))
    return image


def layer_position(layer: dict[str, Any], width: int, height: int) -> tuple[int, int]:
    x = int(layer.get("x", (layer.get("position") or {}).get("x", 0)))
    y = int(layer.get("y", (layer.get("position") or {}).get("y", 0)))
    anchor = str(layer.get("anchor", "top_left"))
    if anchor in {"center", "middle_center"}:
        x -= width // 2
        y -= height // 2
    elif anchor == "center_bottom":
        x -= width // 2
        y -= height
    elif anchor == "right_bottom":
        x -= width
        y -= height
    elif anchor == "right_center":
        x -= width
        y -= height // 2
    elif anchor == "left_center":
        y -= height // 2
    elif anchor not in {"top_left", "left_top"}:
        raise AssetHarnessError("INVALID_ANCHOR", f"unsupported layer anchor: {anchor}")
    return x, y


def opacity_image(image: Image.Image, opacity: float) -> Image.Image:
    if opacity >= 0.9999:
        return image
    alpha = image.getchannel("A").point(lambda value: int(round(value * opacity)))
    result = image.copy()
    result.putalpha(alpha)
    return result
