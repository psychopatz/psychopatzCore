"""Small, named-sprite view of the shared RadioMenu UI atlas."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from PIL import Image

from .catalog import ASSET_ROOT, Rect


RADIO_UI_PATH = ASSET_ROOT / "RadioMenu" / "radioUI.png"

# These are measured atlas regions, kept here instead of scattered through the
# renderer.  Coordinates are top-left-origin pixels in radioUI.png.
SPRITES: dict[str, Rect] = {
    # Full LCD frame variants remain named for atlas inspection and future
    # consumers.  The simulator deliberately uses the flat screen_panel_*
    # sprites below because staged device art already owns the physical bezel.
    "screen_frame_wide": (28, 27, 343, 147),
    "screen_frame_medium": (380, 29, 228, 139),
    "screen_frame_13": (615, 37, 164, 126),
    "screen_frame_14": (793, 42, 166, 121),
    "screen_frame_square": (971, 50, 134, 117),
    "screen_frame_narrow": (1120, 62, 107, 92),
    "screen_panel_green": (30, 188, 258, 104),
    "screen_panel_green_landscape": (30, 188, 258, 104),
    "screen_panel_green_wide": (298, 188, 188, 105),
    "screen_panel_green_compact": (499, 193, 122, 91),
    "screen_panel_dark": (29, 319, 228, 104),
    "row_selected": (30, 436, 282, 95),
    "row_idle": (331, 436, 230, 100),
    "signal_low": (31, 814, 62, 60),
    "signal_medium": (168, 814, 66, 61),
    "signal_full": (240, 814, 65, 60),
    "icon_signal": (31, 814, 62, 60),
    "icon_home": (31, 892, 79, 67),
    "icon_menu": (127, 892, 79, 66),
    "icon_contacts": (221, 892, 68, 66),
    "icon_radio": (385, 892, 69, 66),
    "icon_search": (467, 892, 70, 66),
    "icon_settings": (687, 892, 71, 69),
    "icon_alert": (781, 892, 70, 67),
}


@lru_cache(maxsize=1)
def load_radio_ui() -> Image.Image | None:
    """Load the optional atlas once; callers retain a generic fallback."""

    if not RADIO_UI_PATH.is_file():
        return None
    try:
        with Image.open(RADIO_UI_PATH) as source:
            return source.convert("RGBA")
    except OSError:
        return None


def sprite(name: str) -> Image.Image | None:
    atlas = load_radio_ui()
    rect = SPRITES.get(name)
    if atlas is None or rect is None:
        return None
    x, y, width, height = rect
    return atlas.crop((x, y, x + width, y + height))


def paste_scaled(canvas: Image.Image, name: str, rect: Rect) -> bool:
    """Paste one named atlas sprite into a target rectangle."""

    source = sprite(name)
    if source is None:
        return False
    x, y, width, height = rect
    resized = source.resize((max(1, width), max(1, height)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, (x, y))
    return True


def paste_cover(canvas: Image.Image, name: str, rect: Rect) -> bool:
    """Paste a named sprite while preserving its aspect ratio.

    The old renderer resized atlas sprites independently on both axes.  That
    made the frame thickness visibly uneven on the nearly-square walkie and
    ManPack LCDs.  Cover-scaling keeps the atlas frame proportionate and
    crops only the excess outside the measured aperture.
    """

    source = sprite(name)
    if source is None:
        return False
    x, y, width, height = rect
    scale = max(width / max(1, source.width), height / max(1, source.height))
    resized = source.resize(
        (max(1, int(round(source.width * scale))), max(1, int(round(source.height * scale)))),
        Image.Resampling.LANCZOS,
    )
    left = max(0, (resized.width - width) // 2)
    top = max(0, (resized.height - height) // 2)
    visible = resized.crop((left, top, left + width, top + height))
    canvas.alpha_composite(visible, (x, y))
    return True
