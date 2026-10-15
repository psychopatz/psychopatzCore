"""Pillow renderer for the device simulator."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

from ..core.modular import render_modular
from .catalog import DeviceSpec, Rect, normalize_variant
from .model import RadioSimulator
from .radio_ui import RADIO_UI_PATH, paste_cover, paste_scaled


def _font(size: int, *, bold: bool = False) -> ImageFont.ImageFont:
    candidates = (
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    )
    for candidate in candidates:
        path = Path(candidate)
        if path.is_file():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


@lru_cache(maxsize=32)
def _source_image(path_string: str) -> Image.Image:
    with Image.open(path_string) as source:
        return source.convert("RGBA")


def _checkerboard(size: tuple[int, int], square: int = 18) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (34, 40, 47, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, height, square):
        for x in range(0, width, square):
            if ((x // square) + (y // square)) % 2:
                draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(46, 54, 63, 255))
    return image


def _rect_scale(rect: Rect, scale: float) -> tuple[int, int, int, int]:
    return tuple(int(round(value * scale)) for value in rect)  # type: ignore[return-value]


def _draw_screen(
    canvas: Image.Image,
    simulator: RadioSimulator,
    content_rect: Rect,
    screen_sprite: str,
) -> None:
    """Render dynamic LCD content inside the bezel already present in device art.

    The staged device PNGs already contain their physical LCD bezel.  The
    shared ``radioUI.png`` atlas therefore supplies only the screen-surface
    texture and the menu/icon sprites; pasting a second atlas bezel here makes
    worn variants look visibly doubled and offset.
    """

    draw = ImageDraw.Draw(canvas, "RGBA")
    cx, cy, cwidth, cheight = content_rect
    # Fill only the measured inner screen surface.  The source artwork keeps
    # ownership of its bezel, screws, bevels, and surrounding shell.
    draw.rectangle((cx, cy, cx + cwidth - 1, cy + cheight - 1), fill=(12, 29, 19, 255))
    used_atlas = paste_cover(canvas, screen_sprite, content_rect)
    if not used_atlas:
        draw.rounded_rectangle(
            (cx, cy, cx + cwidth, cy + cheight),
            radius=12,
            fill=(12, 29, 19, 255),
            outline=(49, 92, 59, 255),
            width=4,
        )
        draw.rectangle((cx + 14, cy + 12, cx + cwidth - 12, cy + cheight - 12), fill=(17, 42, 26, 255))

    if not simulator.state.powered:
        if used_atlas:
            shade = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            shade_draw = ImageDraw.Draw(shade, "RGBA")
            shade_draw.rectangle((cx, cy, cx + cwidth - 1, cy + cheight - 1), fill=(0, 0, 0, 112))
            canvas.alpha_composite(shade)
        draw.text((cx + 5, cy + cheight // 2 - 16), "POWER OFF", font=_font(24, bold=True), fill=(121, 164, 123, 255))
        draw.text((cx + 5, cy + cheight // 2 + 18), "Press Power", font=_font(16), fill=(87, 121, 92, 255))
        return

    lines = simulator.screen_lines()
    line_height = max(18, min(30, int(cheight / max(4, len(lines) + 1))))
    text_font = _font(max(14, min(24, line_height - 4)), bold=False)
    bold_font = _font(max(14, min(24, line_height - 4)), bold=True)
    text_y = cy + 4
    for index, line in enumerate(lines):
        if index >= 2:
            row_rect = (cx + 2, text_y - 4, max(1, cwidth - 4), line_height + 5)
            paste_scaled(canvas, "row_selected" if index - 2 == simulator.state.menu_index else "row_idle", row_rect)
            icon_name = _menu_icon(simulator, index - 2)
            if icon_name:
                icon_size = max(12, line_height - 4)
                paste_scaled(canvas, icon_name, (cx + 8, text_y + 1, icon_size, icon_size))
        color = (166, 222, 159, 255) if index == 0 else (127, 185, 130, 255)
        text_x = cx + 5 if index < 2 else cx + 5 + line_height
        draw.text((text_x, text_y), line[:24], font=bold_font if index == 0 else text_font, fill=color)
        text_y += line_height
    signal_width = max(1, int(max(1, cwidth - 30) * (0.25 if simulator.state.signal == "none" else 0.6 if simulator.state.signal == "search" else 0.95)))
    draw.rectangle((cx + 5, cy + cheight - 12, cx + 5 + signal_width, cy + cheight - 6), fill=(106, 176, 112, 255))
    signal_icon = "signal_low" if simulator.state.signal == "none" else "signal_medium" if simulator.state.signal == "search" else "signal_full"
    paste_scaled(canvas, signal_icon, (cx + cwidth - 25, cy + 2, 20, 19))
    scanlines = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    scanline_draw = ImageDraw.Draw(scanlines, "RGBA")
    for scan_y in range(cy + 2, cy + cheight - 2, 12):
        scanline_draw.line((cx + 2, scan_y, cx + cwidth - 2, scan_y), fill=(75, 123, 82, 35), width=1)
    canvas.alpha_composite(scanlines)


def _menu_icon(simulator: RadioSimulator, index: int) -> str | None:
    if simulator.state.page == "home":
        return ("icon_contacts", "icon_settings")[index] if index < 2 else None
    if simulator.state.page == "contacts":
        return ("icon_alert", "icon_radio", "icon_signal")[index] if index < 3 else None
    if simulator.state.page == "settings":
        return ("icon_radio", "icon_radio", "icon_signal", "icon_menu")[index] if index < 4 else None
    return None


def render_device(simulator: RadioSimulator, *, zoom: float = 0.5, debug: bool = False) -> tuple[Image.Image, dict[str, Any]]:
    """Render one device and return image plus hit-test metadata."""

    if simulator.project is not None and simulator.project_path is not None:
        variant = "pristine" if normalize_variant(simulator.state.variant) == "clean" else "worn"
        image, modular_metadata = render_modular(
            simulator.project_path,
            simulator.project,
            variant=variant,
            states=simulator.modular_state_selection(),
        )
        geometry = simulator.geometry
        _draw_screen(image, simulator, geometry.screen_content_rect, geometry.screen_sprite)
        if debug:
            draw = ImageDraw.Draw(image, "RGBA")
            ax, ay, aw, ah = geometry.lcd_rect
            cx, cy, cw, ch = geometry.screen_content_rect
            draw.rectangle((ax, ay, ax + aw - 1, ay + ah - 1), outline=(255, 176, 64, 225), width=2)
            draw.rectangle((cx, cy, cx + cw - 1, cy + ch - 1), outline=(88, 190, 255, 225), width=2)
        scale = max(0.2, min(2.0, float(zoom)))
        size = (max(1, int(round(image.width * scale))), max(1, int(round(image.height * scale))))
        image = image.resize(size, Image.Resampling.LANCZOS)
        controls = []
        for control in geometry.controls:
            left, top, width, height = _rect_scale(control.rect, scale)
            controls.append({"id": control.id, "label": control.label, "action": control.action, "rect": [left, top, width, height], "kind": control.kind, "pressed": control.id in simulator.state.pressed_controls})
        metadata = {
            **modular_metadata,
            "device_id": simulator.device.id,
            "full_type": simulator.device.full_type,
            "family": simulator.device.family,
            "variant": normalize_variant(simulator.state.variant),
            "variant_art_status": "modular_project_preview",
            "variant_is_authored": True,
            "source": str(simulator.device.asset_path),
            "image_size": list(image.size),
            "source_size": [simulator.device.source_width, simulator.device.source_height],
            "source_offset": [0, 0],
            "source_seam_guard_left": 0,
            "ui_atlas": str(RADIO_UI_PATH),
            "ui_atlas_exists": RADIO_UI_PATH.is_file(),
            "screen_sprite": geometry.screen_sprite,
            "controls": controls,
            "lcd_rect": list(_rect_scale(geometry.lcd_rect, scale)),
            "screen_content_rect": list(_rect_scale(geometry.screen_content_rect, scale)),
        }
        return image, metadata

    spec = simulator.device
    variant = normalize_variant(simulator.state.variant)
    geometry = spec.geometry_for(variant)
    if not spec.asset_exists:
        raise FileNotFoundError(f"device artwork is missing: {spec.asset_path}")
    source = _source_image(str(spec.asset_path))
    crop_left, crop_top, crop_width, crop_height = spec.variant_crop(variant)
    crop = source.crop((
        crop_left,
        crop_top,
        min(source.width, crop_left + crop_width),
        min(source.height, crop_top + crop_height),
    ))
    crop = crop.convert("RGBA")
    clip_left = spec.clip_left_for(variant)
    if clip_left:
        # A single staged sheet contains one known cross-half bleed on the
        # worn Ham makeshift radio.  Clear only that seam strip in the
        # simulator; the source PNG remains untouched and authoritative.
        alpha = crop.getchannel("A")
        alpha.paste(0, (0, 0, min(clip_left, crop.width), crop.height))
        crop.putalpha(alpha)
    alpha_bounds = crop.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise ValueError(f"device artwork contains no visible pixels: {spec.asset_path}")
    margin = 8
    trim_left = max(0, alpha_bounds[0] - margin)
    trim_top = max(0, alpha_bounds[1] - margin)
    trim_right = min(crop.width, alpha_bounds[2] + margin)
    trim_bottom = min(crop.height, alpha_bounds[3] + margin)
    crop = crop.crop((trim_left, trim_top, trim_right, trim_bottom))
    lcd_rect = (
        geometry.lcd_rect[0] - trim_left,
        geometry.lcd_rect[1] - trim_top,
        geometry.lcd_rect[2],
        geometry.lcd_rect[3],
    )
    screen_content_rect = (
        geometry.screen_content_rect[0] - trim_left,
        geometry.screen_content_rect[1] - trim_top,
        geometry.screen_content_rect[2],
        geometry.screen_content_rect[3],
    )
    control_specs = tuple(
        (
            control.id,
            control.label,
            control.action,
            (control.rect[0] - trim_left, control.rect[1] - trim_top, control.rect[2], control.rect[3]),
            control.kind,
            control.detents,
        )
        for control in geometry.controls
    )
    _draw_screen(crop, simulator, screen_content_rect, geometry.screen_sprite)
    if debug:
        debug_draw = ImageDraw.Draw(crop, "RGBA")
        lx, ly, lw, lh = lcd_rect
        cx, cy, cw, ch = screen_content_rect
        debug_draw.rectangle((lx, ly, lx + lw, ly + lh), outline=(255, 176, 64, 225), width=3)
        debug_draw.rectangle((cx, cy, cx + cw, cy + ch), outline=(88, 190, 255, 225), width=3)
        debug_draw.text((lx + 4, ly + 4), "lcd", font=_font(14, bold=True), fill=(255, 220, 150, 235))
        debug_draw.text((cx + 4, cy + 4), "content", font=_font(14, bold=True), fill=(175, 230, 255, 235))
    scale = max(0.2, min(2.0, float(zoom)))
    size = (max(1, int(round(crop.width * scale))), max(1, int(round(crop.height * scale))))
    image = crop.resize(size, Image.Resampling.LANCZOS)
    control_metadata = []
    for control_id, control_label, control_action, control_rect, control_kind, control_detents in control_specs:
        left, top, width, height = _rect_scale(control_rect, scale)
        control_metadata.append({
            "id": control_id,
            "label": control_label,
            "action": control_action,
            "rect": [left, top, width, height],
            "kind": control_kind,
            "detents": control_detents or None,
            "pressed": control_id in simulator.state.pressed_controls,
        })
        if debug:
            draw = ImageDraw.Draw(image, "RGBA")
            draw.rounded_rectangle((left, top, left + width, top + height), radius=max(4, int(8 * scale)), outline=(88, 220, 145, 220), width=max(1, int(3 * scale)))
            draw.text((left + 4, top + 4), control_id, font=_font(max(10, int(16 * scale)), bold=True), fill=(190, 255, 210, 235))
    metadata = {
        "device_id": spec.id,
        "full_type": spec.full_type,
        "family": spec.family,
        "variant": variant,
        "variant_art_status": "blocked_source_alias" if spec.source_layout == "single_canvas" else "review_required_sheet_proposal",
        "variant_is_authored": False,
        "source": str(spec.asset_path),
        "image_size": list(image.size),
        "source_size": [crop.width, crop.height],
        "source_offset": [trim_left, trim_top],
        "source_seam_guard_left": clip_left,
        "ui_atlas": str(RADIO_UI_PATH),
        "ui_atlas_exists": RADIO_UI_PATH.is_file(),
        "screen_sprite": geometry.screen_sprite,
        "controls": control_metadata,
        "lcd_rect": list(_rect_scale(lcd_rect, scale)),
        "screen_content_rect": list(_rect_scale(screen_content_rect, scale)),
    }
    return image, metadata


def compose_canvas(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Place the transparent device image on a readable checkerboard."""

    canvas = _checkerboard(size)
    left = max(0, (size[0] - image.width) // 2)
    top = max(0, (size[1] - image.height) // 2)
    if image.width <= size[0] and image.height <= size[1]:
        canvas.alpha_composite(image, (left, top))
        return canvas
    origin_x = (size[0] - image.width) // 2
    origin_y = (size[1] - image.height) // 2
    source_left = max(0, -origin_x)
    source_top = max(0, -origin_y)
    source_right = min(image.width, size[0] - origin_x)
    source_bottom = min(image.height, size[1] - origin_y)
    if source_right > source_left and source_bottom > source_top:
        visible = image.crop((source_left, source_top, source_right, source_bottom))
        canvas.alpha_composite(visible, (max(0, origin_x), max(0, origin_y)))
    return canvas
