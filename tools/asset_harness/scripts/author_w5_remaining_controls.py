"""Author the next bounded W5 component slice in developer staging.

The source PNG is an immutable visual reference.  This script creates masks,
transparent face layers, localized empty sockets, keyed states, LCD layers and
two chassis candidates under the ignored Asset Harness workspace only.  It
does not write the canonical Project Zomboid media tree.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


SIZE = (1024, 1535)


CONTROL_SPECS = {
    "home": {
        "kind": "button",
        "polygon": [(668, 925), (740, 925), (753, 938), (753, 1014), (740, 1027), (668, 1027), (655, 1014), (655, 938)],
        "bbox": (655, 925, 754, 1028),
        "anchor": (704, 976),
    },
    "up": {
        "kind": "button",
        "polygon": [(468, 875), (570, 875), (597, 901), (597, 937), (570, 964), (468, 964), (439, 937), (439, 901)],
        "bbox": (439, 875, 598, 965),
        "anchor": (518, 920),
    },
    "down": {
        "kind": "button",
        "polygon": [(468, 1030), (570, 1030), (597, 1056), (597, 1094), (570, 1121), (468, 1121), (439, 1094), (439, 1056)],
        "bbox": (439, 1030, 598, 1122),
        "anchor": (518, 1075),
    },
    "left": {
        "kind": "button",
        "polygon": [(419, 944), (451, 925), (483, 951), (483, 1016), (451, 1042), (419, 1022), (397, 1000), (397, 963)],
        "bbox": (397, 925, 484, 1043),
        "anchor": (440, 984),
    },
    "right": {
        "kind": "button",
        "polygon": [(584, 944), (616, 925), (648, 951), (648, 1016), (616, 1042), (584, 1022), (563, 1000), (563, 963)],
        "bbox": (563, 925, 649, 1043),
        "anchor": (606, 984),
    },
    "ok": {
        "kind": "button",
        "polygon": [(487, 946), (566, 946), (575, 955), (575, 1018), (566, 1027), (487, 1027), (478, 1018), (478, 955)],
        "bbox": (478, 946, 576, 1028),
        "anchor": (526, 986),
    },
    "power": {
        "kind": "knob",
        "polygon": [(371, 368), (416, 368), (431, 382), (431, 409), (416, 423), (371, 423), (356, 409), (356, 382)],
        "bbox": (356, 368, 432, 424),
        "anchor": (394, 395),
    },
    "volume": {
        "kind": "knob",
        "polygon": [(480, 235), (575, 235), (600, 250), (615, 276), (615, 327), (597, 350), (470, 350), (445, 329), (445, 276), (460, 250)],
        "bbox": (445, 235, 616, 351),
        "anchor": (530, 293),
    },
    "channel": {
        "kind": "knob",
        "polygon": [(668, 274), (748, 274), (772, 288), (785, 312), (785, 353), (770, 372), (650, 372), (635, 354), (635, 312), (647, 288)],
        "bbox": (635, 274, 786, 373),
        "anchor": (710, 323),
    },
    "ptt": {
        "kind": "hold",
        "polygon": [(812, 823), (858, 823), (879, 841), (879, 965), (858, 985), (812, 985), (792, 965), (792, 841)],
        "bbox": (792, 823, 880, 986),
        "anchor": (836, 904),
    },
    "pwr_led": {
        "kind": "led",
        "polygon": [(399, 478), (431, 478), (446, 490), (446, 516), (432, 520), (399, 520), (384, 516), (384, 490)],
        "bbox": (384, 478, 447, 521),
        "anchor": (415, 503),
    },
    "rx_led": {
        "kind": "led",
        "polygon": [(505, 478), (537, 478), (552, 490), (552, 516), (538, 520), (505, 520), (490, 516), (490, 490)],
        "bbox": (490, 478, 553, 521),
        "anchor": (521, 503),
    },
    "tx_led": {
        "kind": "led",
        "polygon": [(611, 478), (643, 478), (658, 490), (658, 516), (644, 520), (611, 520), (596, 516), (596, 490)],
        "bbox": (596, 478, 659, 521),
        "anchor": (627, 503),
    },
    "lcd": {
        "kind": "lcd",
        "polygon": [(335, 610), (710, 610), (724, 624), (724, 805), (710, 820), (335, 820), (319, 805), (319, 624)],
        "bbox": (319, 610, 725, 821),
        "anchor": (522, 715),
    },
}


BUTTON_IDS = ("home", "up", "down", "left", "right", "ok")
KNOB_IDS = ("power", "volume", "channel")
LED_IDS = ("pwr_led", "rx_led", "tx_led")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if image.mode == "L":
        image.save(path, format="PNG", optimize=False)
    else:
        image.convert("RGBA").save(path, format="PNG", optimize=False)


def polygon_mask(points: Iterable[tuple[int, int]], source_alpha: Image.Image) -> Image.Image:
    shape = Image.new("L", SIZE, 0)
    ImageDraw.Draw(shape).polygon(list(points), fill=255)
    return ImageChops.multiply(shape, source_alpha)


def full_canvas_layer(source: Image.Image, mask: Image.Image) -> Image.Image:
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.paste(source, (0, 0), mask)
    return layer


def alpha_layer(color: tuple[int, int, int], mask: Image.Image) -> Image.Image:
    layer = Image.new("RGBA", SIZE, (*color, 0))
    layer.putalpha(mask)
    return layer


def transformed_state(face: Image.Image, bbox: tuple[int, int, int, int], scale: float, dx: int, dy: int) -> Image.Image:
    x0, y0, x1, y1 = bbox
    crop = face.crop((x0, y0, x1, y1))
    width = max(1, round(crop.width * scale))
    height = max(1, round(crop.height * scale))
    crop = crop.resize((width, height), Image.Resampling.LANCZOS)
    alpha = crop.getchannel("A")
    shadow = alpha.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(2))
    shadow = shadow.point(lambda value: round(value * 0.58))
    result = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", crop.size, (4, 5, 5, 0))
    shadow_layer.putalpha(shadow)
    result.alpha_composite(shadow_layer, (x0 + dx + 3, y0 + dy + 4))
    result.alpha_composite(crop, (x0 + dx, y0 + dy))
    return result


def rotated_state(face: Image.Image, bbox: tuple[int, int, int, int], degrees: float) -> Image.Image:
    x0, y0, x1, y1 = bbox
    crop = face.crop((x0, y0, x1, y1))
    rotated = crop.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=False)
    result = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    result.alpha_composite(rotated, (x0, y0))
    return result


def socket_material(source: Image.Image, kind: str) -> Image.Image:
    sample_boxes = {
        "button": (405, 1122, 635, 1165),
        "knob": (458, 350, 602, 415),
        "hold": (780, 770, 887, 814),
        "led": (448, 474, 482, 523),
    }
    sample = source.crop(sample_boxes.get(kind, sample_boxes["button"]))
    sample = sample.resize(SIZE, Image.Resampling.BICUBIC)
    sample.putalpha(255)
    return ImageEnhance.Contrast(sample).enhance(0.72)


def reconstruct_socket(current: Image.Image, source: Image.Image, spec: dict, color: tuple[int, int, int], dilation: int = 11) -> Image.Image:
    mask = polygon_mask(spec["polygon"], current.getchannel("A"))
    expanded = mask.filter(ImageFilter.MaxFilter(dilation))
    material = socket_material(source, spec["kind"])
    neutral = Image.new("RGBA", SIZE, (*color, 255))
    textured = Image.blend(neutral, material, 0.24)
    result = Image.composite(textured, current, expanded)
    inner_color = Image.blend(neutral, textured, 0.45)
    inner_color.putalpha(mask)
    inner = inner_color
    result.alpha_composite(inner)
    outer_rim = ImageChops.subtract(expanded, expanded.filter(ImageFilter.MinFilter(5)))
    border = ImageChops.subtract(expanded, mask)
    dark_rim = alpha_layer((9, 11, 12), outer_rim.point(lambda value: round(value * 0.56)))
    highlight = alpha_layer((112, 116, 112), border.point(lambda value: round(value * 0.20)))
    result.alpha_composite(dark_rim)
    result.alpha_composite(highlight)
    return result


def reconstruct_lcd(current: Image.Image, spec: dict) -> Image.Image:
    mask = polygon_mask(spec["polygon"], current.getchannel("A"))
    texture = current.filter(ImageFilter.GaussianBlur(7))
    matte_color = Image.blend(Image.new("RGBA", SIZE, (39, 62, 43, 255)), texture, 0.20)
    matte_color.putalpha(mask)
    matte = matte_color
    result = current.copy()
    result.alpha_composite(matte)
    inset = mask.filter(ImageFilter.MinFilter(9))
    inner = alpha_layer((51, 79, 54), inset)
    result.alpha_composite(inner)
    return result


def create_lcd_layers(source: Image.Image, source_alpha: Image.Image, root: Path) -> dict[str, Path]:
    spec = CONTROL_SPECS["lcd"]
    glass_mask = polygon_mask(spec["polygon"], source_alpha)
    outer_points = [(315, 594), (730, 594), (755, 620), (755, 817), (730, 845), (315, 845), (288, 817), (288, 620)]
    outer = polygon_mask(outer_points, source_alpha)
    ring = ImageChops.subtract(outer, glass_mask)
    paths = {
        "glass": root / "lcd_glass.png",
        "bezel_overlay": root / "lcd_bezel_overlay.png",
        "matte": root / "lcd_matte.png",
    }
    save(full_canvas_layer(source, glass_mask), paths["glass"])
    save(full_canvas_layer(source, ring), paths["bezel_overlay"])
    save(alpha_layer((39, 62, 43), glass_mask), paths["matte"])
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source_path = args.source.expanduser().resolve()
    root = args.out.expanduser().resolve()
    source = Image.open(source_path).convert("RGBA")
    if source.size != SIZE:
        raise SystemExit(f"unexpected W5 source size: {source.size}, expected {SIZE}")
    source_alpha = source.getchannel("A")
    mask_root = root / "remaining" / "masks"
    artifact_root = root / "remaining" / "artifacts"
    mask_root.mkdir(parents=True, exist_ok=True)
    artifact_root.mkdir(parents=True, exist_ok=True)

    metadata: dict[str, object] = {
        "schema_version": 1,
        "status": "proposed",
        "source": {"path": str(source_path), "sha256": sha256(source_path), "size": list(source.size), "immutable": True},
        "controls": {},
        "lcd": {},
        "chassis": {},
        "notes": [
            "Coordinates were selected from native-resolution visual inspection of Base.WalkieTalkie5.png.",
            "All output remains developer staging; no canonical runtime asset is written.",
            "Socket reconstruction is localized and proposed until visual review accepts each candidate.",
        ],
    }
    masks: dict[str, Image.Image] = {}
    faces: dict[str, Image.Image] = {}
    for control_id, spec in CONTROL_SPECS.items():
        mask = polygon_mask(spec["polygon"], source_alpha)
        masks[control_id] = mask
        face = full_canvas_layer(source, mask)
        faces[control_id] = face
        mask_path = mask_root / f"{control_id}_face.png"
        socket_path = mask_root / f"{control_id}_socket.png"
        face_path = artifact_root / f"{control_id}_idle.png"
        save(mask, mask_path)
        socket_envelope = mask.filter(ImageFilter.MaxFilter(9 if spec["kind"] == "led" else 11))
        # The socket envelope may expand beyond a beveled face, but it must
        # never claim transparent pixels in the immutable source.  The
        # reconstructed pixels live in the chassis candidate; the source-space
        # mask remains constrained to the canonical silhouette for validation.
        socket_mask = ImageChops.multiply(socket_envelope, source_alpha)
        save(socket_mask, socket_path)
        save(face, face_path)
        metadata["controls"][control_id] = {
            "kind": spec["kind"],
            "polygon": spec["polygon"],
            "bbox": list(spec["bbox"]),
            "anchor": list(spec["anchor"]),
            "mask": str(mask_path.relative_to(root)),
            "socket_mask": str(socket_path.relative_to(root)),
            "idle": str(face_path.relative_to(root)),
            "mask_sha256": sha256(mask_path),
            "socket_mask_sha256": sha256(socket_path),
            "idle_sha256": sha256(face_path),
        }

    for control_id in BUTTON_IDS + ("ptt",):
        spec = CONTROL_SPECS[control_id]
        pressed = transformed_state(faces[control_id], spec["bbox"], 0.94 if control_id != "ptt" else 0.96, 3, 4)
        path = artifact_root / f"{control_id}_{'held' if control_id == 'ptt' else 'pressed'}.png"
        save(pressed, path)
        metadata["controls"][control_id]["pressed"] = str(path.relative_to(root))

    for control_id in KNOB_IDS:
        spec = CONTROL_SPECS[control_id]
        degrees = (-18.0, 0.0, 18.0, 36.0) if control_id != "power" else (-20.0, 20.0)
        frames = []
        for index, angle in enumerate(degrees):
            path = artifact_root / f"{control_id}_frame_{index:02d}.png"
            save(rotated_state(faces[control_id], spec["bbox"], angle), path)
            frames.append(str(path.relative_to(root)))
        metadata["controls"][control_id]["frames"] = frames

    for control_id in LED_IDS:
        on_path = artifact_root / f"{control_id}_on.png"
        off_mask = masks[control_id].point(lambda value: round(value * 0.92))
        off = alpha_layer((32, 29, 24), off_mask)
        save(faces[control_id], on_path)
        off_path = artifact_root / f"{control_id}_off.png"
        save(off, off_path)
        metadata["controls"][control_id]["on"] = str(on_path.relative_to(root))
        metadata["controls"][control_id]["off"] = str(off_path.relative_to(root))

    lcd_paths = create_lcd_layers(source, source_alpha, artifact_root)
    metadata["lcd"] = {key: str(path.relative_to(root)) for key, path in lcd_paths.items()}

    base_path = root / "pilot" / "artifacts" / "back_chassis_pristine_candidate.png"
    base = Image.open(base_path).convert("RGBA") if base_path.is_file() else source.copy()
    for control_id, spec in CONTROL_SPECS.items():
        if control_id == "lcd":
            base = reconstruct_lcd(base, spec)
        elif control_id not in ("back",):
            color = (19, 22, 24) if spec["kind"] == "led" else (34, 37, 41)
            if spec["kind"] == "knob":
                color = (29, 31, 33)
            base = reconstruct_socket(base, source, spec, color, 9 if spec["kind"] == "led" else 11)
    pristine_path = artifact_root / "chassis_pristine_full.png"
    save(base, pristine_path)
    worn = ImageEnhance.Color(base).enhance(0.78)
    worn = ImageEnhance.Contrast(worn).enhance(1.07)
    worn = ImageEnhance.Brightness(worn).enhance(0.94)
    worn_path = artifact_root / "chassis_worn_full.png"
    save(worn, worn_path)
    metadata["chassis"] = {
        "pristine": {"path": str(pristine_path.relative_to(root)), "sha256": sha256(pristine_path)},
        "worn": {"path": str(worn_path.relative_to(root)), "sha256": sha256(worn_path)},
        "anchors": {"device_center": [512, 768], "lcd_center": [522, 715], "speaker_center": [522, 1210]},
    }

    metadata_path = root / "remaining" / "w5_remaining_metadata.json"
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"source_sha256": sha256(source_path), "metadata": str(metadata_path), "controls": len(CONTROL_SPECS), "pristine": str(pristine_path), "worn": str(worn_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
