"""Deterministic Pillow compositor for previews and validation fixtures."""

from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any, Iterable, Sequence

from PIL import Image, ImageChops, ImageDraw

from .errors import AssetHarnessError
from .layers import layer_position, opacity_image, ordered_layers, resolve_layer_image
from .paths import atomic_write_bytes, canvas_rect, parse_rect


def parse_color(value: Any, default: tuple[int, int, int, int] = (0, 0, 0, 0)) -> tuple[int, int, int, int]:
    if value is None:
        return default
    if isinstance(value, str):
        text = value.strip().lstrip("#")
        if len(text) in {6, 8}:
            try:
                channels = tuple(int(text[index:index + 2], 16) for index in range(0, len(text), 2))
                return channels if len(channels) == 4 else (*channels, 255)
            except ValueError:
                pass
    if isinstance(value, (list, tuple)) and len(value) in {3, 4}:
        channels = tuple(max(0, min(255, int(channel))) for channel in value)
        return channels if len(channels) == 4 else (*channels, 255)
    if isinstance(value, dict):
        return parse_color([value.get(key, 0) for key in ("r", "g", "b", "a")], default)
    raise AssetHarnessError("INVALID_COLOR", f"invalid color value: {value!r}")


def _rect_value(value: Any, *, name: str) -> list[int]:
    return parse_rect(value, name=name)


def _clip_image(image: Image.Image, x: int, y: int, clip: Sequence[int]) -> Image.Image:
    clip_x, clip_y, clip_w, clip_h = [int(value) for value in clip]
    mask = Image.new("L", image.size, 0)
    local = (clip_x - x, clip_y - y, clip_x - x + clip_w, clip_y - y + clip_h)
    draw = ImageDraw.Draw(mask)
    draw.rectangle(local, fill=255)
    alpha = ImageChops.multiply(image.getchannel("A"), mask)
    result = image.copy()
    result.putalpha(alpha)
    return result


def _layer_clip(project: dict[str, Any], layer: dict[str, Any]) -> list[int] | None:
    clip = layer.get("clip")
    lcd = project.get("lcd") or {}
    if clip in {"lcd", "aperture"} and lcd.get("aperture") is not None:
        return _rect_value(lcd["aperture"], name="lcd aperture")
    if clip == "content" and lcd.get("content") is not None:
        return _rect_value(lcd["content"], name="lcd content")
    if isinstance(clip, (list, tuple, dict, str)) and clip not in {None, "lcd", "aperture", "content"}:
        return _rect_value(clip, name="layer clip")
    return None


def compose(
    project_path: Path,
    project: dict[str, Any],
    *,
    state: str | None = None,
    variant: str = "pristine",
    content_color: Any = None,
    debug: bool = False,
    grid: int = 0,
) -> tuple[Image.Image, dict[str, Any]]:
    bounds = canvas_rect(project)
    if bounds[2] <= 0 or bounds[3] <= 0:
        raise AssetHarnessError("PROJECT_INVALID", "canvas width and height must be positive")
    width, height = bounds[2], bounds[3]
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    lcd = project.get("lcd") or {}
    backing = lcd.get("backing", lcd.get("aperture"))
    if backing is not None:
        rect = _rect_value(backing, name="lcd backing")
        color = parse_color(lcd.get("backing_color", lcd.get("background_color")), (15, 36, 22, 255))
        ImageDraw.Draw(canvas).rectangle(
            (rect[0], rect[1], rect[0] + rect[2] - 1, rect[1] + rect[3] - 1), fill=color
        )
    if content_color is not None and lcd.get("content") is not None:
        rect = _rect_value(lcd["content"], name="lcd content")
        color = parse_color(content_color, (0, 0, 0, 0))
        ImageDraw.Draw(canvas).rectangle(
            (rect[0], rect[1], rect[0] + rect[2] - 1, rect[1] + rect[3] - 1), fill=color
        )
    drawn: list[dict[str, Any]] = []
    for layer in ordered_layers(project, state=state, variant=variant):
        image = resolve_layer_image(project_path, project, layer)
        scale = float(layer.get("scale", 1))
        if scale <= 0 or scale > 16:
            raise AssetHarnessError("INVALID_SCALE", f"invalid layer scale: {scale}")
        if abs(scale - 1.0) > 0.000001:
            image = image.resize(
                (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                Image.Resampling.NEAREST,
            )
        opacity = float(layer.get("opacity", 1))
        if opacity < 0 or opacity > 1:
            raise AssetHarnessError("INVALID_OPACITY", f"layer opacity must be between 0 and 1: {layer.get('id')}")
        image = opacity_image(image, opacity)
        x, y = layer_position(layer, image.width, image.height)
        clip = _layer_clip(project, layer)
        if clip is not None:
            image = _clip_image(image, x, y, clip)
        overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        overlay.paste(image, (x, y), image)
        canvas = Image.alpha_composite(canvas, overlay)
        drawn.append({
            "id": str(layer.get("id", "")),
            "z": int(layer.get("z", 0)),
            "x": x,
            "y": y,
            "width": image.width,
            "height": image.height,
            "role": layer.get("role"),
        })
    if debug:
        _draw_debug(canvas, project, drawn, grid)
    return canvas, {
        "width": width,
        "height": height,
        "state": state,
        "variant": variant,
        "layers": drawn,
    }


def _draw_debug(canvas: Image.Image, project: dict[str, Any], drawn: list[dict[str, Any]], grid: int) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    width, height = canvas.size
    draw.rectangle((0, 0, width - 1, height - 1), outline=(0, 170, 255, 220), width=1)
    lcd = project.get("lcd") or {}
    for key, color in (
        ("aperture", (255, 30, 190, 240)),
        ("backing", (255, 160, 30, 240)),
        ("content", (30, 255, 100, 240)),
    ):
        if lcd.get(key) is not None:
            rect = _rect_value(lcd[key], name=f"lcd {key}")
            draw.rectangle((rect[0], rect[1], rect[0] + rect[2] - 1, rect[1] + rect[3] - 1), outline=color, width=1)
    for control in project.get("controls") or []:
        if isinstance(control, dict) and control.get("rect") is not None:
            rect = _rect_value(control["rect"], name="control rect")
            draw.rectangle((rect[0], rect[1], rect[0] + rect[2] - 1, rect[1] + rect[3] - 1), outline=(255, 230, 40, 240), width=1)
            if control.get("hitbox") is not None:
                hitbox = _rect_value(control["hitbox"], name="control hitbox")
                draw.rectangle((hitbox[0], hitbox[1], hitbox[0] + hitbox[2] - 1, hitbox[1] + hitbox[3] - 1), outline=(255, 80, 40, 240), width=1)
    for layer in drawn:
        draw.rectangle(
            (layer["x"], layer["y"], layer["x"] + layer["width"] - 1, layer["y"] + layer["height"] - 1),
            outline=(255, 255, 255, 110), width=1,
        )
    if grid and grid > 0:
        for x in range(0, width, int(grid)):
            draw.line((x, 0, x, height - 1), fill=(255, 255, 255, 45), width=1)
        for y in range(0, height, int(grid)):
            draw.line((0, y, width - 1, y), fill=(255, 255, 255, 45), width=1)


def render_image(
    project_path: Path,
    project: dict[str, Any],
    *,
    state: str | None = None,
    variant: str = "pristine",
    scale: float = 1,
    content_color: Any = None,
    debug: bool = False,
    grid: int = 0,
) -> tuple[Image.Image, dict[str, Any]]:
    if scale <= 0 or scale > 16:
        raise AssetHarnessError("INVALID_SCALE", "render scale must be greater than 0 and no more than 16")
    declared_variants = project.get("variants") or {}
    if variant != "pristine" and variant not in declared_variants:
        raise AssetHarnessError("VARIANT_NOT_FOUND", f"variant is not declared: {variant}")
    image, metadata = compose(
        project_path,
        project,
        state=state,
        variant=variant,
        content_color=content_color,
        debug=debug,
        grid=grid,
    )
    if abs(float(scale) - 1.0) > 0.000001:
        image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.NEAREST)
    metadata["scale"] = float(scale)
    metadata["output_width"], metadata["output_height"] = image.size
    return image, metadata


def png_bytes(image: Image.Image) -> bytes:
    buffer = BytesIO()
    image.convert("RGBA").save(buffer, format="PNG", optimize=False, compress_level=9)
    return buffer.getvalue()


def save_png(image: Image.Image, output: Path) -> Path:
    output = Path(output).expanduser().resolve()
    atomic_write_bytes(output, png_bytes(image))
    return output


def contact_sheet(images: Iterable[Image.Image], *, columns: int = 4, gap: int = 4) -> Image.Image:
    frames = [image.convert("RGBA") for image in images]
    if not frames:
        raise AssetHarnessError("ANIMATION_EMPTY", "animation has no frames")
    columns = max(1, int(columns))
    rows = (len(frames) + columns - 1) // columns
    cell_width = max(image.width for image in frames)
    cell_height = max(image.height for image in frames)
    sheet = Image.new("RGBA", (columns * cell_width + (columns - 1) * gap, rows * cell_height + (rows - 1) * gap), (0, 0, 0, 0))
    for index, image in enumerate(frames):
        x = (index % columns) * (cell_width + gap)
        y = (index // columns) * (cell_height + gap)
        sheet.alpha_composite(image, (x, y))
    return sheet


def difference_image(before: Image.Image, after: Image.Image) -> tuple[Image.Image, dict[str, Any]]:
    left = before.convert("RGBA")
    right = after.convert("RGBA")
    if left.size != right.size:
        raise AssetHarnessError("DIFF_SIZE_MISMATCH", "difference inputs must have identical dimensions")
    raw = ImageChops.difference(left, right)
    rgb_diff = ImageChops.difference(left.convert("RGB"), right.convert("RGB"))
    changed = rgb_diff.getchannel("R")
    for channel in rgb_diff.getbands()[1:]:
        changed = ImageChops.lighter(changed, rgb_diff.getchannel(channel))
    changed = ImageChops.lighter(changed, raw.getchannel("A"))
    rgb = raw.convert("RGB")
    output = Image.new("RGBA", raw.size, (0, 0, 0, 0))
    output.paste(rgb, (0, 0), changed)
    bbox = changed.getbbox()
    count = sum(1 for value in changed.getdata() if value)
    return output, {"changed_pixels": count, "changed_bounds": list(bbox) if bbox else None}
