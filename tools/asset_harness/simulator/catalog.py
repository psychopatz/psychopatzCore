"""Shared simulator geometry types and variant normalization.

Device discovery and authored control geometry live in the canonical pilot
projects and :mod:`asset_harness.simulator.registry`.  This module intentionally
contains no second device catalog; the small data classes remain here because
the renderer and project-backed reducer share them.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = REPO_ROOT / "Contents" / "mods" / "PsychopatzCore" / "common" / "media" / "ui" / "Radio"

Rect = tuple[int, int, int, int]


@dataclass(frozen=True)
class ControlSpec:
    """A physical control in canonical project coordinates."""

    id: str
    label: str
    action: str
    rect: Rect
    kind: str = "momentary"
    detents: int = 0


@dataclass(frozen=True)
class DeviceGeometry:
    """Variant-local screen and control geometry."""

    lcd_rect: Rect
    screen_content_rect: Rect
    screen_sprite: str
    controls: tuple[ControlSpec, ...]


@dataclass(frozen=True)
class DeviceSpec:
    """Project-backed device metadata used by the shared renderer."""

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
    source_layout: str = "single_canvas"

    @property
    def asset_exists(self) -> bool:
        return self.asset_path.is_file()

    def geometry_for(self, variant: str) -> DeviceGeometry:
        """Return geometry registered for the requested clean/worn variant."""

        normalized = normalize_variant(variant)
        if self.variant_geometries is not None:
            return with_semantic_controls(self.variant_geometries[0 if normalized == "clean" else 1])
        return with_semantic_controls(DeviceGeometry(
            lcd_rect=self.lcd_rect,
            screen_content_rect=self.screen_content_rect,
            screen_sprite=self.screen_sprite,
            controls=self.controls,
        ))

    def clip_left_for(self, variant: str) -> int:
        """Return a source-half seam guard for a known bleed artifact."""

        normalized = normalize_variant(variant)
        return self.variant_clip_left[0 if normalized == "clean" else 1]

    def variant_crop(self, variant: str) -> Rect:
        """Return the registered source region for a clean/worn alias."""

        normalized = normalize_variant(variant)
        if self.source_layout == "paired_sheet":
            left = 0 if normalized == "clean" else self.source_width // 2
            return (left, 0, self.source_width // 2, self.source_height)
        return (0, 0, self.source_width, self.source_height)


def normalize_variant(value: str | None) -> str:
    normalized = (value or "clean").strip().lower()
    aliases = {"pristine": "clean", "new": "clean", "damaged": "worn", "scratched": "worn"}
    normalized = aliases.get(normalized, normalized)
    if normalized not in {"clean", "worn"}:
        raise ValueError(f"unknown radio artwork variant: {value!r}; expected clean or worn")
    return normalized


def with_semantic_controls(geometry: DeviceGeometry) -> DeviceGeometry:
    """Add bounded LCD soft-key fallbacks to geometry missing Back or Home.

    Canonical radio pilots author their physical controls directly.  This
    helper only preserves the generic renderer contract for small project
    fixtures that intentionally omit one of the two semantic soft keys.
    """

    controls = list(geometry.controls)
    ids = {control.id for control in controls}
    actions = {control.action for control in controls}
    left, top, width, height = geometry.screen_content_rect
    footer_height = max(1, min(48, max(1, height // 4)))
    footer_top = top + max(0, height - footer_height)
    left_width = max(1, width // 2)
    if "back" not in ids and "back" not in actions:
        controls.append(ControlSpec("back", "Back", "back", (left, footer_top, left_width, footer_height), kind="softkey"))
    if "home" not in ids and "home" not in actions:
        controls.append(ControlSpec("home", "Home", "home", (left + left_width, footer_top, max(1, width - left_width), footer_height), kind="softkey"))
    return DeviceGeometry(
        lcd_rect=geometry.lcd_rect,
        screen_content_rect=geometry.screen_content_rect,
        screen_sprite=geometry.screen_sprite,
        controls=tuple(controls),
    )
