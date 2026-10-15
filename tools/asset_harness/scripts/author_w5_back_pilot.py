"""Author the bounded W5 Back-button pilot from an inspected source mask.

This is deliberately a developer-staging tool.  It never writes to the
canonical game-loaded Radio tree and never mutates the source PNG.  The
resulting chassis patch is a localized reconstruction candidate; review status
is recorded by the project/CLI rather than assumed by this script.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


FACE_BOUNDS = (297, 925, 395, 1026)
FACE_POLYGON = (
    (311, 925),
    (382, 925),
    (394, 937),
    (394, 1013),
    (382, 1025),
    (309, 1025),
    (297, 1013),
    (297, 937),
)
SOCKET_POLYGON = (
    (303, 920),
    (390, 920),
    (401, 932),
    (401, 1017),
    (388, 1031),
    (303, 1031),
    (290, 1017),
    (290, 933),
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=False, compress_level=9)


def _polygon_mask(size: tuple[int, int], points: Iterable[tuple[int, int]]) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(list(points), fill=255)
    return mask


def _colored_layer(size: tuple[int, int], color: tuple[int, int, int, int], mask: Image.Image) -> Image.Image:
    layer = Image.new("RGBA", size, color)
    layer.putalpha(ImageChops.multiply(mask, Image.new("L", size, color[3])))
    return layer


def _socket_patch(source: Image.Image, face_mask: Image.Image) -> tuple[Image.Image, Image.Image]:
    size = source.size
    socket_mask = _polygon_mask(size, SOCKET_POLYGON)
    face_shape = _polygon_mask(size, FACE_POLYGON)

    # Use the source's own graphite face material as the texture seed, then
    # suppress the glyph with a broad, localized blend.  This keeps the
    # reconstructed recess in the same material/lighting family without
    # copying a neighboring device or inventing a generic button.
    texture = source.crop(FACE_BOUNDS).convert("RGBA")
    texture = texture.filter(ImageFilter.MedianFilter(7))
    texture = texture.filter(ImageFilter.GaussianBlur(3.0))
    texture = ImageEnhance.Brightness(texture).enhance(0.34)
    texture = ImageEnhance.Contrast(texture).enhance(0.62)
    dark_overlay = Image.new("RGBA", texture.size, (16, 16, 15, 220))
    texture = Image.alpha_composite(texture, dark_overlay)

    cavity = Image.new("RGBA", size, (0, 0, 0, 0))
    cavity.paste(texture, (FACE_BOUNDS[0], FACE_BOUNDS[1]))
    cavity.putalpha(face_shape)

    patch = _colored_layer(size, (8, 8, 7, 198), socket_mask)
    patch.alpha_composite(cavity)
    draw = ImageDraw.Draw(patch, "RGBA")

    # The layered rim makes the empty socket read as a recess: a subdued
    # highlight catches the upper/left bevel while the lower/right edge stays
    # in contact shadow.  All strokes remain inside the localized socket.
    draw.line(
        [FACE_POLYGON[0], FACE_POLYGON[1], FACE_POLYGON[2]],
        fill=(116, 113, 101, 95),
        width=2,
        joint="curve",
    )
    draw.line(
        [FACE_POLYGON[0], FACE_POLYGON[7], FACE_POLYGON[6]],
        fill=(84, 84, 77, 85),
        width=2,
        joint="curve",
    )
    draw.line(
        [FACE_POLYGON[2], FACE_POLYGON[3], FACE_POLYGON[4], FACE_POLYGON[5]],
        fill=(2, 2, 2, 165),
        width=2,
        joint="curve",
    )
    draw.line(
        [FACE_POLYGON[5], FACE_POLYGON[6], FACE_POLYGON[7]],
        fill=(5, 5, 4, 150),
        width=2,
        joint="curve",
    )
    return patch, socket_mask


def _pressed_state(face_idle: Image.Image) -> Image.Image:
    bbox = face_idle.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("face mask produced an empty idle state")
    crop = face_idle.crop(bbox)
    target_size = (max(1, int(crop.width * 0.94)), max(1, int(crop.height * 0.93)))
    compressed = crop.resize(target_size, Image.Resampling.LANCZOS)
    x = bbox[0] + 3
    y = bbox[1] + 4

    pressed = Image.new("RGBA", face_idle.size, (0, 0, 0, 0))
    alpha = compressed.getchannel("A")
    placed_alpha = Image.new("L", face_idle.size, 0)
    placed_alpha.paste(alpha, (x, y))
    contact = placed_alpha.filter(ImageFilter.MaxFilter(7))
    contact = ImageChops.subtract(contact, placed_alpha)
    contact = contact.point(lambda value: min(150, int(value * 0.72)))
    shadow = Image.new("RGBA", face_idle.size, (3, 3, 3, 0))
    shadow.putalpha(contact)
    pressed.alpha_composite(shadow)

    placed = Image.new("RGBA", face_idle.size, (0, 0, 0, 0))
    placed.alpha_composite(compressed, (x, y))
    pressed.alpha_composite(placed)
    return pressed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--mask", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    source_path = args.source.expanduser().resolve()
    mask_path = args.mask.expanduser().resolve()
    output = args.out.expanduser().resolve()
    with Image.open(source_path) as source_file, Image.open(mask_path) as mask_file:
        source = source_file.convert("RGBA").copy()
        face_mask = mask_file.convert("L").copy()
    if source.size != face_mask.size:
        raise SystemExit(f"source/mask canvas mismatch: {source.size} != {face_mask.size}")

    face_idle = source.copy()
    face_idle.putalpha(ImageChops.multiply(source.getchannel("A"), face_mask))
    socket_patch, socket_mask = _socket_patch(source, face_mask)
    chassis = source.copy()
    chassis.alpha_composite(socket_patch)
    pressed = _pressed_state(face_idle)

    paths = {
        "socket_patch": output / "artifacts" / "back_socket_patch.png",
        "socket_mask": output / "artifacts" / "back_socket_mask.png",
        "chassis_pristine_candidate": output / "artifacts" / "back_chassis_pristine_candidate.png",
        "back_idle": output / "artifacts" / "back_idle.png",
        "back_pressed": output / "artifacts" / "back_pressed.png",
    }
    _save(socket_patch, paths["socket_patch"])
    _save(socket_mask, paths["socket_mask"])
    _save(chassis, paths["chassis_pristine_candidate"])
    _save(face_idle, paths["back_idle"])
    _save(pressed, paths["back_pressed"])

    metadata = {
        "schema_version": 1,
        "asset_kind": "w5_back_one_control_pilot",
        "source": {"path": str(source_path), "sha256": _sha256(source_path), "size": list(source.size)},
        "mask": {"path": str(mask_path), "sha256": _sha256(mask_path), "face_bounds": list(FACE_BOUNDS), "face_polygon": [list(point) for point in FACE_POLYGON]},
        "socket": {"polygon": [list(point) for point in SOCKET_POLYGON], "reconstruction": "localized graphite recess with upper-left bevel and lower-right contact shadow"},
        "states": {
            "idle": {"path": str(paths["back_idle"]), "source_face_preserved": True, "travel": [0, 0]},
            "pressed": {"path": str(paths["back_pressed"]), "source_face_preserved": True, "travel": [3, 4], "scale": [0.94, 0.93], "contact_shadow": True},
        },
        "artifacts": {name: {"path": str(path), "sha256": _sha256(path), "size": list(Image.open(path).size)} for name, path in paths.items()},
        "review_status": "proposed_pending_visual_review",
        "runtime_export": False,
    }
    metadata_path = output / "artifacts" / "back_pilot_metadata.json"
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(metadata, ensure_ascii=True, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
