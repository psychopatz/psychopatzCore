"""Device catalog for the offline radio simulator.

The catalog is deliberately separate from the simulator state reducer.  It
describes where staging artwork lives and which regions are interactive; it
does not decide what a button does after an event is received.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = REPO_ROOT / "Contents" / "mods" / "PsychopatzCore" / "common" / "media" / "ui" / "Radio"

Rect = tuple[int, int, int, int]


@dataclass(frozen=True)
class ControlSpec:
    """A physical control in source-crop coordinates."""

    id: str
    label: str
    action: str
    rect: Rect


@dataclass(frozen=True)
class DeviceGeometry:
    """Variant-local screen and control geometry."""

    lcd_rect: Rect
    screen_content_rect: Rect
    screen_sprite: str
    controls: tuple[ControlSpec, ...]


@dataclass(frozen=True)
class DeviceSpec:
    """Static device geometry and source-art metadata."""

    id: str
    label: str
    family: str
    full_type: str
    asset_path: Path
    lcd_rect: Rect
    screen_content_rect: Rect
    screen_sprite: str
    controls: tuple[ControlSpec, ...]
    source_width: int = 627
    source_height: int = 1254
    variant_geometries: tuple[DeviceGeometry, DeviceGeometry] | None = None
    variant_clip_left: tuple[int, int] = (0, 0)

    @property
    def asset_exists(self) -> bool:
        return self.asset_path.is_file()

    def geometry_for(self, variant: str) -> DeviceGeometry:
        """Return geometry registered for the requested clean/worn sheet half."""

        normalized = normalize_variant(variant)
        if self.variant_geometries is not None:
            return self.variant_geometries[0 if normalized == "clean" else 1]
        return DeviceGeometry(
            lcd_rect=self.lcd_rect,
            screen_content_rect=self.screen_content_rect,
            screen_sprite=self.screen_sprite,
            controls=self.controls,
        )

    def clip_left_for(self, variant: str) -> int:
        """Return a source-half seam guard for a known bleed artifact."""

        normalized = normalize_variant(variant)
        return self.variant_clip_left[0 if normalized == "clean" else 1]

    def variant_crop(self, variant: str) -> Rect:
        """Return the clean/worn half of a two-variant source sheet."""

        normalized = normalize_variant(variant)
        left = 0 if normalized == "clean" else self.source_width
        return (left, 0, self.source_width, self.source_height)


def _control(id: str, label: str, action: str, rect: Rect) -> ControlSpec:
    return ControlSpec(id=id, label=label, action=action, rect=rect)


def _offset_controls(controls: tuple[ControlSpec, ...], dx: int, dy: int = 0) -> tuple[ControlSpec, ...]:
    """Translate physical hitboxes when a source-sheet variant is re-registered."""

    return tuple(
        ControlSpec(
            id=control.id,
            label=control.label,
            action=control.action,
            rect=(control.rect[0] + dx, control.rect[1] + dy, control.rect[2], control.rect[3]),
        )
        for control in controls
    )


_WALKIE_CONTROLS = (
    _control("power", "Power", "power_toggle", (185, 394, 122, 118)),
    _control("channel_down", "Channel −", "channel_down", (326, 401, 116, 112)),
    _control("channel_up", "Channel +", "channel_up", (451, 412, 112, 106)),
    _control("side_left_up", "Volume −", "volume_down", (86, 608, 94, 133)),
    _control("side_left_down", "Volume +", "volume_up", (86, 755, 94, 133)),
    _control("side_right_up", "Signal", "signal_cycle", (555, 608, 72, 133)),
    _control("side_right_down", "PTT", "transmit_toggle", (555, 755, 72, 133)),
    _control("left", "Previous", "previous", (216, 887, 108, 83)),
    _control("center", "Select", "select", (329, 887, 108, 83)),
    _control("right", "Next", "next", (443, 887, 111, 83)),
)

_HAM_CONTROLS = (
    _control("power", "Power", "power_toggle", (154, 582, 52, 48)),
    _control("menu", "Menu", "menu", (150, 620, 55, 48)),
    _control("previous", "Previous", "previous", (150, 665, 55, 48)),
    _control("left", "Previous", "previous", (194, 706, 95, 52)),
    _control("center", "Select", "select", (294, 706, 95, 52)),
    _control("right", "Next", "next", (394, 706, 110, 52)),
    _control("volume", "Volume +", "volume_up", (466, 579, 125, 139)),
    _control("channel", "Channel +", "channel_up", (477, 720, 111, 92)),
)

_HAM2_CONTROLS = (
    _control("power", "Power", "power_toggle", (430, 590, 48, 48)),
    _control("menu", "Menu", "menu", (210, 710, 55, 45)),
    _control("previous", "Previous", "previous", (255, 710, 55, 45)),
    _control("left", "Previous", "previous", (294, 704, 75, 70)),
    _control("center", "Select", "select", (356, 704, 75, 70)),
    _control("right", "Next", "next", (418, 704, 75, 70)),
    _control("volume", "Volume +", "volume_up", (515, 580, 85, 95)),
    _control("channel", "Channel +", "channel_up", (418, 635, 120, 120)),
)

_HAM_MAKESHIFT_CONTROLS = (
    _control("power", "Power", "power_toggle", (490, 720, 90, 70)),
    _control("left", "Previous", "previous", (185, 710, 78, 80)),
    _control("center", "Select", "select", (280, 710, 78, 80)),
    _control("right", "Next", "next", (365, 710, 78, 80)),
    _control("volume", "Volume +", "volume_up", (420, 710, 70, 80)),
    _control("channel", "Channel +", "channel_up", (500, 590, 115, 135)),
)

_MANPACK_CONTROLS = (
    _control("power", "Power", "power_toggle", (88, 663, 76, 76)),
    _control("menu", "Menu", "menu", (88, 748, 76, 82)),
    _control("previous", "Previous", "previous", (88, 815, 76, 76)),
    _control("back", "Back", "back", (88, 882, 76, 76)),
    _control("left", "Previous", "previous", (177, 930, 104, 78)),
    _control("center", "Select", "select", (294, 930, 104, 78)),
    _control("right", "Next", "next", (416, 930, 104, 78)),
    _control("volume", "Volume +", "volume_up", (430, 1000, 170, 190)),
    _control("channel", "Channel +", "channel_up", (140, 620, 115, 110)),
)


def _walkie(index: str, label: str, filename: str) -> DeviceSpec:
    geometry = {
        # These are the visible LCD apertures in each source sheet, not the
        # smaller decorative inner line.  Each source was measured separately
        # because the vanilla art is not registered to one shared baseline.
        "1": ((235, 603, 291, 243), (258, 626, 245, 197), "screen_panel_green_compact"),
        "2": ((236, 580, 291, 269), (260, 606, 243, 217), "screen_panel_green_compact"),
        "3": ((241, 589, 282, 261), (264, 614, 236, 211), "screen_panel_green_compact"),
        "4": ((235, 593, 273, 256), (258, 618, 227, 206), "screen_panel_green_compact"),
        "5": ((235, 599, 273, 246), (258, 624, 227, 196), "screen_panel_green_compact"),
        "MakeShift": ((229, 588, 293, 253), (253, 612, 245, 205), "screen_panel_green_compact"),
    }
    lcd_rect, screen_content_rect, screen_sprite = geometry[index]
    worn_x_offset = {
        "1": -48,
        "2": -67,
        "3": -79,
        "4": -79,
        "5": -38,
        "MakeShift": -56,
    }[index]
    clean_geometry = DeviceGeometry(lcd_rect, screen_content_rect, screen_sprite, _WALKIE_CONTROLS)
    worn_geometry = DeviceGeometry(
        (lcd_rect[0] + worn_x_offset, lcd_rect[1], lcd_rect[2], lcd_rect[3]),
        (screen_content_rect[0] + worn_x_offset, screen_content_rect[1], screen_content_rect[2], screen_content_rect[3]),
        screen_sprite,
        _offset_controls(_WALKIE_CONTROLS, worn_x_offset),
    )
    return DeviceSpec(
        id=f"walkie_{index.lower()}",
        label=label,
        family="walkie",
        full_type=f"Base.WalkieTalkie{index}" if index != "MakeShift" else "Base.WalkieTalkieMakeShift",
        asset_path=ASSET_ROOT / "WalkieTalkie" / filename,
        lcd_rect=lcd_rect,
        screen_content_rect=screen_content_rect,
        screen_sprite=screen_sprite,
        controls=_WALKIE_CONTROLS,
        variant_geometries=(clean_geometry, worn_geometry),
    )


DEVICE_SPECS: tuple[DeviceSpec, ...] = (
    _walkie("1", "WalkieTalkie 1 · clean/worn", "Radio.WalkieTalkie1.png"),
    _walkie("2", "WalkieTalkie 2 · clean/worn", "Radio.WalkieTalkie2.png"),
    _walkie("3", "WalkieTalkie 3 · clean/worn", "Radio.WalkieTalkie3.png"),
    _walkie("4", "WalkieTalkie 4 · clean/worn", "Radio.WalkieTalkie4.png"),
    _walkie("5", "WalkieTalkie 5 · clean/worn", "Radio.WalkieTalkie5.png"),
    _walkie("MakeShift", "WalkieTalkie makeshift · clean/worn", "Radio.WalkieTalkieMakeShift.png"),
    DeviceSpec(
        id="ham_1",
        label="Ham radio 1 · clean/worn",
        family="ham",
        full_type="Base.HamRadio1",
        asset_path=ASSET_ROOT / "Ham" / "Base.HamRadio1.png",
        lcd_rect=(207, 592, 285, 115),
        screen_content_rect=(220, 605, 259, 89),
        screen_sprite="screen_panel_green_landscape",
        controls=_HAM_CONTROLS,
        variant_geometries=(
            DeviceGeometry((207, 592, 285, 115), (220, 605, 259, 89), "screen_panel_green_landscape", _HAM_CONTROLS),
            DeviceGeometry((193, 592, 285, 115), (206, 605, 259, 89), "screen_panel_green_landscape", _offset_controls(_HAM_CONTROLS, -14)),
        ),
    ),
    DeviceSpec(
        id="ham_2",
        label="Ham radio 2 · clean/worn",
        family="ham",
        full_type="Base.HamRadio2",
        asset_path=ASSET_ROOT / "Ham" / "Base.HamRadio2.png",
        lcd_rect=(187, 585, 227, 105),
        screen_content_rect=(198, 596, 205, 83),
        screen_sprite="screen_panel_green_landscape",
        controls=_HAM2_CONTROLS,
        variant_geometries=(
            DeviceGeometry((187, 585, 227, 105), (198, 596, 205, 83), "screen_panel_green_landscape", _HAM2_CONTROLS),
            DeviceGeometry((179, 590, 249, 105), (190, 600, 227, 83), "screen_panel_green_landscape", _offset_controls(_HAM2_CONTROLS, -8, 5)),
        ),
    ),
    DeviceSpec(
        id="ham_makeshift",
        label="Ham radio makeshift · clean/worn",
        family="ham",
        full_type="Base.HamRadioMakeShift",
        asset_path=ASSET_ROOT / "Ham" / "Base.HamRadioMakeShift.png",
        lcd_rect=(199, 595, 277, 105),
        screen_content_rect=(211, 607, 253, 81),
        screen_sprite="screen_panel_green_landscape",
        controls=_HAM_MAKESHIFT_CONTROLS,
        variant_geometries=(
            DeviceGeometry((199, 595, 277, 105), (211, 607, 253, 81), "screen_panel_green_landscape", _HAM_MAKESHIFT_CONTROLS),
            DeviceGeometry((166, 595, 277, 105), (178, 607, 253, 81), "screen_panel_green_landscape", _offset_controls(_HAM_MAKESHIFT_CONTROLS, -24)),
        ),
        variant_clip_left=(0, 20),
    ),
    DeviceSpec(
        id="manpack",
        label="Manpack radio · clean/worn",
        family="manpack",
        full_type="Base.ManPackRadio",
        asset_path=ASSET_ROOT / "ManPack" / "Base.ManPackRadio.png",
        lcd_rect=(190, 687, 295, 211),
        screen_content_rect=(213, 710, 249, 165),
        screen_sprite="screen_panel_green_compact",
        controls=_MANPACK_CONTROLS,
        variant_geometries=(
            DeviceGeometry((190, 687, 295, 211), (213, 710, 249, 165), "screen_panel_green_compact", _MANPACK_CONTROLS),
            DeviceGeometry((190, 687, 295, 211), (213, 710, 249, 165), "screen_panel_green_compact", _MANPACK_CONTROLS),
        ),
    ),
)

_BY_ID = {spec.id: spec for spec in DEVICE_SPECS}


def normalize_variant(value: str | None) -> str:
    normalized = (value or "clean").strip().lower()
    aliases = {"pristine": "clean", "new": "clean", "damaged": "worn", "scratched": "worn"}
    normalized = aliases.get(normalized, normalized)
    if normalized not in {"clean", "worn"}:
        raise ValueError(f"unknown radio artwork variant: {value!r}; expected clean or worn")
    return normalized


def list_devices() -> tuple[DeviceSpec, ...]:
    return DEVICE_SPECS


def get_device(device_id: str) -> DeviceSpec:
    try:
        return _BY_ID[device_id]
    except KeyError as error:
        known = ", ".join(_BY_ID)
        raise ValueError(f"unknown radio device {device_id!r}; expected one of: {known}") from error


def iter_existing_devices(devices: Iterable[DeviceSpec] | None = None) -> Iterable[DeviceSpec]:
    return (spec for spec in devices or DEVICE_SPECS if spec.asset_exists)
