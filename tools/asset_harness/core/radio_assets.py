"""Canonical radio source inventory and honest modular-art status reports.

The files under ``common/media/ui/Radio`` are source/reference inputs.  This
module deliberately does not infer production-ready parts from them.  It
records the exact filename, byte hash, alpha facts, source layout proposal,
and the reason a device is still blocked when no reviewed modular artwork is
present.
"""

from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageDraw

from .errors import AssetHarnessError
from .paths import atomic_write_bytes, atomic_write_text
from .responses import sha256_path
from .render import difference_image
from .source import inspect_image


CANONICAL_IMAGE_ROOT = Path("Contents/mods/PsychopatzCore/common/media/ui/Radio")
FAMILY_DIRECTORIES = {
    "walkie": "WalkieTalkie",
    "ham": "Ham",
    "manpack": "ManPack",
}

# The trailing space in the Ham makeshift filename is intentional.  It is a
# source quirk that must be reported, never silently normalised away.
RADIO_DEVICE_DEFINITIONS: tuple[dict[str, str], ...] = (
    {"id": "walkie_1", "family": "walkie", "full_type": "Base.WalkieTalkie1", "filename": "Base.WalkieTalkie1.png"},
    {"id": "walkie_2", "family": "walkie", "full_type": "Base.WalkieTalkie2", "filename": "Base.WalkieTalkie2.png"},
    {"id": "walkie_3", "family": "walkie", "full_type": "Base.WalkieTalkie3", "filename": "Base.WalkieTalkie3.png"},
    {"id": "walkie_4", "family": "walkie", "full_type": "Base.WalkieTalkie4", "filename": "Base.WalkieTalkie4.png"},
    {"id": "walkie_5", "family": "walkie", "full_type": "Base.WalkieTalkie5", "filename": "Base.WalkieTalkie5.png"},
    {"id": "walkie_makeshift", "family": "walkie", "full_type": "Base.WalkieTalkieMakeShift", "filename": "Base.WalkieTalkieMakeShift.png"},
    {"id": "ham_1", "family": "ham", "full_type": "Base.HamRadio1", "filename": "Base.HamRadio1.png"},
    {"id": "ham_2", "family": "ham", "full_type": "Base.HamRadio2", "filename": "Base.HamRadio2.png"},
    {"id": "ham_makeshift", "family": "ham", "full_type": "Base.HamRadioMakeShift", "filename": "Base.HamRadioMakeShift .png"},
    {"id": "manpack", "family": "manpack", "full_type": "Base.ManPackRadio", "filename": "Base.ManPackRadio.png"},
)

EXPECTED_COMPONENT_PATHS = (
    "Chassis/Pristine.png",
    "Chassis/Worn.png",
    "Buttons/Back/Idle.png",
    "Buttons/Back/Pressed.png",
    "Switches/Power/Off.png",
    "Switches/Power/On.png",
    "PTT/Idle.png",
    "PTT/Held.png",
    "LCD/Glass.png",
    "LCD/BezelOverlay.png",
)

REQUIRED_SEMANTIC_COMPONENTS = (
    "back",
    "home",
    "up",
    "down",
    "left",
    "right",
    "ok",
    "ptt",
    "power",
    "volume",
    "channel",
    "pwr_led",
    "rx_led",
    "tx_led",
    "lcd",
)


def _alpha_bbox(image: Image.Image) -> list[int] | None:
    bbox = image.convert("RGBA").getchannel("A").getbbox()
    if bbox is None:
        return None
    left, top, right, bottom = bbox
    return [left, top, right - left, bottom - top]


def _half_alpha(image: Image.Image, box: tuple[int, int, int, int]) -> dict[str, Any]:
    rgba = image.convert("RGBA").crop(box)
    alpha = rgba.getchannel("A")
    histogram = alpha.histogram()
    return {
        "size": [rgba.width, rgba.height],
        "transparent_pixels": int(histogram[0]),
        "partial_pixels": int(sum(histogram[1:255])),
        "opaque_pixels": int(histogram[255]),
        "nonzero_bounds": _alpha_bbox(rgba),
    }


def _source_layout(path: Path) -> dict[str, Any]:
    """Return a conservative layout proposal, never a verified split.

    A complete paired sheet normally leaves transparent margin at the inner
    edge of each half.  If both halves touch the seam, treating each half as
    a device would crop the centre of one full radio; that is the exact class
    of defect AH-R0 is meant to expose.
    """

    with Image.open(path) as image:
        image.load()
        width, height = image.size
        if width < 2 or width % 2:
            return {
                "kind": "single_canvas",
                "confidence": "high",
                "reason": "canvas is not evenly divisible into horizontal variants",
                "variants": {},
            }
        half = width // 2
        left = _half_alpha(image, (0, 0, half, height))
        right = _half_alpha(image, (half, 0, width, height))
        left_box = left.get("nonzero_bounds")
        right_box = right.get("nonzero_bounds")
        left_touches_seam = bool(left_box and left_box[0] + left_box[2] >= half - 2)
        right_touches_seam = bool(right_box and right_box[0] <= 2)
        looks_like_pair = bool(
            left_box
            and right_box
            and not left_touches_seam
            and not right_touches_seam
            and left_box[2] < half * 0.92
            and right_box[2] < half * 0.92
        )
        if looks_like_pair:
            return {
                "kind": "paired_sheet_proposal",
                "confidence": "medium",
                "axis": "x",
                "variants": {
                    "pristine": {"rect": [0, 0, half, height]},
                    "worn": {"rect": [half, 0, half, height]},
                },
                "halves": {"left": left, "right": right},
                "review_required": True,
            }
        return {
            "kind": "single_canvas",
            "confidence": "high",
            "reason": "alpha silhouette reaches the horizontal seam; halves would crop one full device",
            "halves": {"left": left, "right": right},
            "variants": {},
            "review_required": True,
        }


def _alpha_summary(metadata: dict[str, Any]) -> dict[str, Any]:
    alpha = metadata.get("alpha") or {}
    nonzero = int(alpha.get("nonzero_pixels", 0))
    partial = int(alpha.get("partial_pixels", 0))
    return {
        "transparent_pixels": int(alpha.get("transparent_pixels", 0)),
        "partial_pixels": partial,
        "opaque_pixels": int(alpha.get("opaque_pixels", 0)),
        "nonzero_pixels": nonzero,
        "partial_ratio_of_nonzero": round(partial / nonzero, 6) if nonzero else 0.0,
        "nonzero_bounds": metadata.get("nonzero_bounds"),
        "opaque_bounds": metadata.get("opaque_bounds"),
    }


def _device_path(root: Path, definition: dict[str, str]) -> Path:
    family_dir = FAMILY_DIRECTORIES[definition["family"]]
    return root / CANONICAL_IMAGE_ROOT / family_dir / definition["filename"]


def _status_for(
    definition: dict[str, str],
    path: Path,
    layout: dict[str, Any] | None,
    modular_dir: Path,
    modular_files: list[str],
) -> tuple[str, list[str], list[str]]:
    reasons: list[str] = []
    warnings: list[str] = []
    if not path.exists():
        reasons.append("SOURCE_FILE_MISSING")
    if not modular_dir.is_dir():
        reasons.append("NO_MODULAR_ARTWORK_DIRECTORY")
    elif not modular_files:
        reasons.append("MODULAR_ARTWORK_DIRECTORY_EMPTY")
    else:
        missing = sorted(set(EXPECTED_COMPONENT_PATHS) - set(modular_files))
        if missing:
            reasons.append("MODULAR_ARTWORK_INCOMPLETE")
    if layout and layout.get("kind") != "paired_sheet_proposal":
        reasons.append("SOURCE_IS_SINGLE_CANVAS_NOT_CLEAN_WORN_PAIR")
    if layout and layout.get("review_required"):
        reasons.append("SOURCE_LAYOUT_REQUIRES_MANUAL_REVIEW")
    reasons.append("SOURCE_PROVENANCE_NOT_APPROVED_FOR_PRODUCTION")
    if definition["id"] == "walkie_4":
        reasons.append("KNOWN_WALKIETALKIE4_BAD_CUT_REGRESSION")
    if definition["id"] == "walkie_5":
        reasons.append("US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW")
    if path.name.endswith(" .png"):
        warnings.append("FILENAME_CONTAINS_LITERAL_SPACE_BEFORE_EXTENSION")
    if reasons:
        return "blocked", reasons, warnings
    return "proposed", reasons, warnings


def _record_device(root: Path, definition: dict[str, str]) -> dict[str, Any]:
    path = _device_path(root, definition)
    family_dir = FAMILY_DIRECTORIES[definition["family"]]
    owner_path = (CANONICAL_IMAGE_ROOT / family_dir / definition["filename"]).as_posix()
    modular_dir = path.with_suffix("")
    modular_files = sorted(
        item.relative_to(modular_dir).as_posix()
        for item in modular_dir.rglob("*")
        if item.is_file()
    ) if modular_dir.is_dir() else []
    layout: dict[str, Any] | None = None
    metadata: dict[str, Any] | None = None
    if path.is_file():
        metadata = inspect_image(path)
        layout = _source_layout(path)
    status, reasons, warnings = _status_for(definition, path, layout, modular_dir, modular_files)
    missing_required_paths = sorted(set(EXPECTED_COMPONENT_PATHS) - set(modular_files))
    source_record: dict[str, Any] = {
        "path": owner_path,
        "absolute_path": str(path.resolve()),
        "filename": path.name,
        "immutable": True,
    }
    if metadata is not None:
        source_record.update({
            "sha256": metadata["sha256"],
            "bytes": metadata["bytes"],
            "format": metadata["format"],
            "mode": metadata["mode"],
            "size": [metadata["width"], metadata["height"]],
            "alpha": _alpha_summary(metadata),
            "layout": layout,
        })
    else:
        source_record["sha256"] = None
        source_record["size"] = None
        source_record["alpha"] = None
        source_record["layout"] = None
    return {
        "id": definition["id"],
        "family": definition["family"],
        "full_type": definition["full_type"],
        "owner_path": owner_path,
        "source": source_record,
        "modular_output": {
            "directory": (modular_dir.relative_to(root)).as_posix(),
            "exists": modular_dir.is_dir(),
            "files": modular_files,
            "required_paths": list(EXPECTED_COMPONENT_PATHS),
            "missing_required_paths": missing_required_paths,
        },
        "verification": {
            "status": status,
            "reviewed": False,
            "reasons": reasons,
            "warnings": warnings,
            "artifacts": [],
        },
    }


def audit_radio_sources(root: Path, *, family: str | None = None) -> dict[str, Any]:
    """Audit the ten canonical radio sources without mutating any source PNG."""

    root = Path(root).expanduser().resolve()
    if family is not None and family not in FAMILY_DIRECTORIES:
        raise AssetHarnessError("INVALID_RADIO_FAMILY", f"unknown radio family: {family}")
    definitions = [item for item in RADIO_DEVICE_DEFINITIONS if family is None or item["family"] == family]
    devices = [_record_device(root, item) for item in definitions]
    statuses = [str(item["verification"]["status"]) for item in devices]
    return {
        "schema_version": 1,
        "audit_kind": "radio_source_inventory",
        "root": str(root),
        "canonical_root": (root / CANONICAL_IMAGE_ROOT).as_posix(),
        "devices": devices,
        "summary": {
            "expected_devices": len(definitions),
            "sources_found": sum(1 for item in devices if item["source"]["sha256"]),
            "blocked": statuses.count("blocked"),
            "proposed": statuses.count("proposed"),
            "verified": statuses.count("verified"),
            "complete": statuses.count("complete"),
        },
        "scope": {
            "source_mutation": False,
            "production_export_apply": False,
            "native_pz_rendering": False,
        },
    }


def manifest_for_device(device: dict[str, Any]) -> dict[str, Any]:
    """Build a deterministic per-device developer manifest from an audit row."""

    source = device.get("source") or {}
    size = source.get("size") or [1, 1]
    family = str(device.get("family") or "radio")
    model = Path(str(device.get("filename") or device.get("owner_path") or device.get("id") or "radio")).stem
    return {
        "schema_version": 1,
        "manifest_kind": "radio_modular_asset",
        "project_id": str(device["id"]),
        "device": {
            "id": device["id"],
            "family": family,
            "model": model,
            "fullType": device["full_type"],
        },
        "canvas": {"width": int(size[0]), "height": int(size[1]), "origin": "top_left"},
        "workspace_root": ".",
        "sources": {
            "canonical": {
                "path": source.get("absolute_path"),
                "sha256": source.get("sha256"),
                "bytes": source.get("bytes"),
                "width": int(size[0]),
                "height": int(size[1]),
                "format": source.get("format"),
                "mode": source.get("mode"),
                "provenance": "canonical concept/reference source; pending visual review",
                "approved": False,
            }
        },
        "regions": {},
        "layers": [],
        "lcd": {},
        "controls": [],
        "animations": {},
        "variants": {"pristine": {"layers": []}, "worn": {"layers": []}},
        "masks": {},
        "modular": {
            "schema_version": 1,
            "status": "incomplete",
            "chassis": {},
            "components": {},
            "required_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "verification": {"reviewed": False, "status": "incomplete", "reasons": ["NO_REVIEWED_MODULAR_ARTWORK"]},
        },
        "export": {
            "runtime_root": "Contents/mods/PsychopatzCore/common/media/ui",
            "device_path": f"Radio/{FAMILY_DIRECTORIES.get(family, family)}/{model}",
            "textures": [],
            "manifest_filename": "skin.lua",
        },
        "owner_path": device["owner_path"],
        "source": source,
        "modular_output": device["modular_output"],
        "chassis": {
            "pristine": {"status": "blocked", "image": None, "socket_mask": None, "anchors": {}},
            "worn": {"status": "blocked", "image": None, "socket_mask": None, "anchors": {}},
        },
        "components": {},
        "component_inventory": {
            component_id: {
                "status": "blocked",
                "reason": "NO_REVIEWED_MODULAR_ARTWORK",
                "source_owner": device["owner_path"],
                "coordinates": None,
            }
            for component_id in REQUIRED_SEMANTIC_COMPONENTS
        },
        "verification": device["verification"],
        "notes": [
            "This manifest is an AH-R0 audit record, not an approval or runtime export declaration.",
            "Rectangular crops and inferred component states are not production-ready evidence.",
        ],
    }


def write_radio_manifests(report: dict[str, Any], output_root: Path) -> list[Path]:
    """Write audit manifests under a caller-approved development directory."""

    output_root = Path(output_root).expanduser().resolve()
    paths: list[Path] = []
    for device in report.get("devices") or []:
        if not isinstance(device, dict):
            continue
        target = output_root / f"{device['id']}.json"
        content = json.dumps(manifest_for_device(device), ensure_ascii=True, sort_keys=True, indent=2) + "\n"
        atomic_write_text(target, content)
        paths.append(target)
    return paths


def _write_png(image: Image.Image, path: Path) -> Path:
    buffer = BytesIO()
    image.save(buffer, format="PNG", optimize=False, compress_level=9)
    atomic_write_bytes(path, buffer.getvalue())
    return path


def _write_walkie4_bad_cut_regression(source_path: Path, output_root: Path) -> tuple[list[Path], dict[str, Any]]:
    """Create a visual/numeric record of the old half-crop failure.

    This is diagnostic evidence only.  The legacy panels are deliberately
    placed beside the immutable full canvas and never written over it.
    """

    with Image.open(source_path) as image:
        image.load()
        source = image.convert("RGBA")
        width, height = source.size
        half_width = width // 2
        left = source.crop((0, 0, half_width, height))
        right = source.crop((half_width, 0, width, height))
        legacy_canvas = Image.new("RGBA", source.size, (0, 0, 0, 0))
        legacy_canvas.alpha_composite(left, (0, 0))
        diff, diff_metrics = difference_image(source, legacy_canvas)

        panels = [("full_source", source), ("legacy_left_half", left), ("legacy_right_half", right)]
        cell_width, cell_height = 320, 480
        gap = 8
        sheet = Image.new("RGBA", (cell_width * 3 + gap * 2, cell_height), (26, 30, 34, 255))
        draw = ImageDraw.Draw(sheet, "RGBA")
        for index, (label, panel) in enumerate(panels):
            preview = panel.copy()
            preview.thumbnail((cell_width - 12, cell_height - 28), Image.Resampling.LANCZOS)
            x = index * (cell_width + gap) + (cell_width - preview.width) // 2
            y = 24 + (cell_height - 24 - preview.height) // 2
            sheet.alpha_composite(preview, (x, y))
            draw.text((index * (cell_width + gap) + 6, 6), label, fill=(255, 240, 180, 255))

    preview_path = output_root / "walkie_4_bad_cut_regression.png"
    diff_path = output_root / "walkie_4_bad_cut_diff.png"
    _write_png(sheet, preview_path)
    _write_png(diff, diff_path)
    return [preview_path, diff_path], {
        "source_size": [width, height],
        "legacy_crop_size": [half_width, height],
        "corrected_crop_size": [width, height],
        "legacy_crop_is_full_canvas": False,
        "diff": {"path": str(diff_path), "sha256": sha256_path(diff_path), **diff_metrics},
        "status": "blocked_regression_evidence",
    }


def write_radio_audit_artifacts(report: dict[str, Any], output_root: Path, *, columns: int = 4) -> list[Path]:
    """Write review-only full-resolution source/alpha previews and a sheet.

    These files are copies/diagnostics in the ignored harness workspace.  No
    runtime Radio PNG is changed and no missing modular component is invented.
    """

    output_root = Path(output_root).expanduser().resolve()
    source_root = output_root / "sources"
    alpha_root = output_root / "alpha"
    source_root.mkdir(parents=True, exist_ok=True)
    alpha_root.mkdir(parents=True, exist_ok=True)
    artifacts: list[Path] = []
    thumbs: list[tuple[str, Image.Image]] = []
    for device in report.get("devices") or []:
        source = device.get("source") or {}
        absolute = source.get("absolute_path")
        if not absolute or not Path(absolute).is_file():
            continue
        source_path = Path(absolute).resolve()
        source_copy = source_root / f"{device['id']}.png"
        if not source_copy.exists() or source_copy.read_bytes() != source_path.read_bytes():
            atomic_write_bytes(source_copy, source_path.read_bytes())
        alpha_path = alpha_root / f"{device['id']}.png"
        with Image.open(source_path) as image:
            image.load()
            rgba = image.convert("RGBA")
            alpha = rgba.getchannel("A")
            _write_png(alpha, alpha_path)
            thumb = rgba.copy()
            thumb.thumbnail((256, 256), Image.Resampling.LANCZOS)
            thumbs.append((str(device["id"]), thumb))
        artifacts.extend((source_copy, alpha_path))
        device.setdefault("verification", {}).setdefault("artifacts", []).extend([
            {"kind": "source_full_resolution", "path": str(source_copy), "sha256": sha256_path(source_copy)},
            {"kind": "alpha_preview", "path": str(alpha_path), "sha256": sha256_path(alpha_path)},
            {"kind": "source_to_idle_diff", "status": "blocked", "sha256": None, "reason": "no reviewed modular chassis/idle layers exist"},
        ])
        if device.get("id") == "walkie_4":
            regression_paths, regression = _write_walkie4_bad_cut_regression(source_path, output_root)
            artifacts.extend(regression_paths)
            device.setdefault("verification", {}).setdefault("artifacts", []).extend([
                {"kind": "bad_cut_regression_preview", "path": str(regression_paths[0]), "sha256": sha256_path(regression_paths[0])},
                {"kind": "bad_cut_regression_diff", "path": str(regression_paths[1]), "sha256": sha256_path(regression_paths[1]), "metrics": regression["diff"]},
            ])
            report.setdefault("regressions", {})["walkie_4"] = regression
    if thumbs:
        columns = max(1, min(8, int(columns)))
        gap = 8
        cell_width = max(image.width for _, image in thumbs)
        cell_height = max(image.height for _, image in thumbs)
        rows = (len(thumbs) + columns - 1) // columns
        sheet = Image.new("RGBA", (columns * cell_width + (columns - 1) * gap, rows * cell_height + (rows - 1) * gap), (26, 30, 34, 255))
        draw = ImageDraw.Draw(sheet, "RGBA")
        for index, (device_id, image) in enumerate(thumbs):
            x = (index % columns) * (cell_width + gap)
            y = (index // columns) * (cell_height + gap)
            sheet.alpha_composite(image, (x, y))
            draw.text((x + 6, y + 6), device_id, fill=(255, 240, 180, 255))
        sheet_path = output_root / "source_contact_sheet.png"
        _write_png(sheet, sheet_path)
        artifacts.append(sheet_path)
        report["contact_sheet"] = {"path": str(sheet_path), "sha256": sha256_path(sheet_path), "device_count": len(thumbs)}
    report["artifact_summary"] = {
        "count": len(artifacts),
        "paths": [str(path) for path in artifacts],
        "source_bytes_preserved": True,
        "production_export_apply": False,
    }
    return artifacts


def iter_device_definitions(family: str | None = None) -> Iterable[dict[str, str]]:
    return (
        item for item in RADIO_DEVICE_DEFINITIONS
        if family is None or item["family"] == family
    )
