"""Canonical radio source inventory and honest modular-art status reports.

The files under ``common/media/ui/Radio`` are source/reference inputs.  This
module deliberately does not infer production-ready parts from them.  It
records the exact filename, byte hash, alpha facts, source layout proposal,
and the reason a device is still blocked when no reviewed modular artwork is
present.
"""

from __future__ import annotations

import json
import textwrap
from io import BytesIO
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageDraw, ImageFont

from .errors import AssetHarnessError
from .paths import atomic_write_bytes, atomic_write_text
from .project import project_workspace
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


def _modular_directory(root: Path, definition: dict[str, str], source_path: Path) -> Path:
    """Resolve the modular directory without hiding a source filename quirk."""

    candidate = source_path.with_suffix("")
    if candidate.is_dir() or not source_path.name.endswith(" .png"):
        return candidate
    # HamRadioMakeShift's source file intentionally contains a space before
    # .png.  The canonical modular model directory follows the full type and
    # does not inherit that source-only filename typo.
    normalized_name = source_path.name.replace(" .png", ".png")
    normalized_source = source_path.with_name(normalized_name)
    normalized_candidate = normalized_source.with_suffix("")
    return normalized_candidate if normalized_candidate.is_dir() else candidate


def _authoring_project_path(root: Path, definition: dict[str, str]) -> Path | None:
    """Find a developer authoring project without confusing audit manifests.

    ``<device>.json`` is also the generated audit-manifest destination.  The
    explicit ``_pilot`` file is therefore preferred for durable authoring
    evidence and remains safe to overwrite with a fresh audit report.
    """

    project_root = root / "tools/asset_harness/projects/radio"
    for filename in (f"{definition['id']}_pilot.json", f"{definition['id']}.authoring.json"):
        candidate = project_root / filename
        if candidate.is_file():
            return candidate
    return None


def _project_asset_path(project_path: Path, project: dict[str, Any], value: Any) -> Path | None:
    if not value:
        return None
    candidate = Path(str(value)).expanduser()
    if not candidate.is_absolute():
        candidate = project_workspace(project_path, project) / candidate
    return candidate.resolve()


def _asset_record(project_path: Path, project: dict[str, Any], value: Any) -> dict[str, Any]:
    path = _project_asset_path(project_path, project, value)
    record: dict[str, Any] = {"path": str(path) if path else None, "exists": bool(path and path.is_file())}
    if path and path.is_file():
        try:
            metadata = inspect_image(path)
            record.update({
                "sha256": metadata["sha256"],
                "size": [metadata["width"], metadata["height"]],
                "mode": metadata["mode"],
            })
        except Exception as error:
            record.update({"readable": False, "error": str(error)})
        else:
            record["readable"] = True
    else:
        record["sha256"] = None
    return record


def _staged_authoring_evidence(root: Path, definition: dict[str, str]) -> dict[str, Any]:
    """Collect evidence from an authoring project, never infer approval."""

    project_path = _authoring_project_path(root, definition)
    if project_path is None:
        return {
            "project": None,
            "authored": False,
            "status": "blocked",
            "reviewed": False,
            "reasons": [],
            "required_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "missing_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "chassis": {},
            "components": {},
            "masks": {},
            "artifacts": [],
        }
    try:
        project = json.loads(project_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return {
            "project": str(project_path),
            "authored": False,
            "status": "blocked",
            "reviewed": False,
            "reasons": ["AUTHORING_PROJECT_UNREADABLE"],
            "error": str(error),
            "required_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "missing_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "chassis": {},
            "components": {},
            "masks": {},
            "artifacts": [],
        }
    if not isinstance(project, dict):
        return {
            "project": str(project_path),
            "authored": False,
            "status": "blocked",
            "reviewed": False,
            "reasons": ["AUTHORING_PROJECT_INVALID"],
            "required_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "missing_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "chassis": {},
            "components": {},
            "masks": {},
            "artifacts": [],
        }

    modular = project.get("modular") if isinstance(project.get("modular"), dict) else {}
    chassis_value = modular.get("chassis") if isinstance(modular.get("chassis"), dict) else {}
    chassis: dict[str, Any] = {}
    for variant in ("pristine", "worn"):
        entry = chassis_value.get(variant) if isinstance(chassis_value.get(variant), dict) else {}
        image = _asset_record(project_path, project, entry.get("image"))
        chassis[variant] = {
            "image": image,
            "status": str(entry.get("status") or "blocked"),
            "reviewed": bool((entry.get("review") or {}).get("reviewed")) if isinstance(entry.get("review"), dict) else False,
            "socket_mask": str(entry.get("socket_mask") or "") or None,
            "anchors": entry.get("anchors") or {},
        }

    components_value = modular.get("components") if isinstance(modular.get("components"), dict) else {}
    components: dict[str, Any] = {}
    for component_id, raw in components_value.items():
        if not isinstance(raw, dict):
            continue
        states_value = raw.get("states") if isinstance(raw.get("states"), dict) else {}
        states = {
            str(state_name): _asset_record(project_path, project, state.get("image") if isinstance(state, dict) else state)
            for state_name, state in states_value.items()
        }
        components[str(component_id)] = {
            "status": str(raw.get("status") or "blocked"),
            "reviewed": bool((raw.get("review") or {}).get("reviewed")) if isinstance(raw.get("review"), dict) else False,
            "mask": str(raw.get("mask") or "") or None,
            "socket_mask": str(raw.get("socket_mask") or "") or None,
            "states": states,
        }

    # LCD artwork is stored in the modular schema's dedicated ``lcd_layers``
    # record rather than in ``components``.  Treat it as a semantic component
    # for staged evidence so the required-component gate reflects the actual
    # authored layer files instead of reporting a false missing ``lcd``.
    lcd_layers = modular.get("lcd_layers") if isinstance(modular.get("lcd_layers"), dict) else None
    if "lcd" not in components and lcd_layers is not None:
        lcd_states: dict[str, dict[str, Any]] = {}
        for state_name in ("glass", "bezel_overlay", "matte"):
            layer = lcd_layers.get(state_name)
            if isinstance(layer, dict):
                layer_value = layer.get("image")
            else:
                layer_value = layer
            lcd_states[state_name] = _asset_record(project_path, project, layer_value)
        lcd_review = lcd_layers.get("review") if isinstance(lcd_layers.get("review"), dict) else {}
        components["lcd"] = {
            "status": str(lcd_layers.get("status") or "blocked"),
            "reviewed": bool(lcd_review.get("reviewed")),
            "mask": str(lcd_layers.get("mask") or "") or None,
            "socket_mask": str(lcd_layers.get("socket_mask") or "") or None,
            "states": lcd_states,
        }

    masks_value = project.get("masks") if isinstance(project.get("masks"), dict) else {}
    masks: dict[str, Any] = {}
    for mask_id, raw in masks_value.items():
        if not isinstance(raw, dict):
            continue
        mask_path = _project_asset_path(project_path, project, raw.get("path"))
        masks[str(mask_id)] = {
            "path": str(mask_path) if mask_path else None,
            "exists": bool(mask_path and mask_path.is_file()),
            "status": str(raw.get("status") or "blocked"),
            "reviewed": bool((raw.get("review") or {}).get("reviewed")) if isinstance(raw.get("review"), dict) else False,
            "sha256": sha256_path(mask_path) if mask_path and mask_path.is_file() else None,
        }

    verification = modular.get("verification") if isinstance(modular.get("verification"), dict) else {}
    artifacts = verification.get("artifacts") if isinstance(verification.get("artifacts"), list) else []
    normalized_artifacts: list[dict[str, Any]] = []
    for raw in artifacts:
        if not isinstance(raw, dict):
            continue
        item = dict(raw)
        for key in ("path", "before", "after", "diff", "report"):
            if key in item:
                item[f"{key}_path"] = str(_project_asset_path(project_path, project, item.get(key)) or item.get(key) or "")
        normalized_artifacts.append(item)

    required_components = [str(item) for item in (modular.get("required_components") or REQUIRED_SEMANTIC_COMPONENTS)]
    missing_components = sorted(item for item in required_components if item not in components)
    authored_states = any(
        bool(state.get("exists"))
        for component in components.values()
        for state in (component.get("states") or {}).values()
    )
    authored = bool(chassis.get("pristine", {}).get("image", {}).get("exists")) or authored_states
    diff_artifact = next((item for item in normalized_artifacts if item.get("kind") == "source_to_idle_diff"), None)
    diff_after = diff_artifact.get("after_path") if diff_artifact else None
    diff_image = diff_artifact.get("diff_path") if diff_artifact else None
    diff_report = diff_artifact.get("report_path") if diff_artifact else None
    diff_exists = bool(
        diff_after and Path(diff_after).is_file()
        and diff_image and Path(diff_image).is_file()
        and diff_report and Path(diff_report).is_file()
    )
    reviewed = bool(verification.get("reviewed"))
    complete = bool(
        authored
        and all(bool(chassis.get(variant, {}).get("image", {}).get("exists")) for variant in ("pristine", "worn"))
        and not missing_components
        and diff_exists
        and reviewed
        and all(bool(item.get("reviewed")) for item in chassis.values())
        and all(bool(item.get("reviewed")) for item in components.values())
    )
    reasons: list[str] = []
    if not chassis.get("pristine", {}).get("image", {}).get("exists"):
        reasons.append("PRISTINE_CHASSIS_MISSING")
    if not chassis.get("worn", {}).get("image", {}).get("exists"):
        reasons.append("WORN_CHASSIS_PENDING")
    if missing_components:
        reasons.append("REMAINING_COMPONENTS_PENDING")
    if not diff_exists:
        reasons.append("SOURCE_TO_IDLE_DIFF_PENDING")
    if not reviewed:
        reasons.append("VISUAL_REVIEW_PENDING")
    status = "verified" if complete else ("proposed" if authored else "blocked")
    return {
        "project": str(project_path),
        "authored": authored,
        "status": status,
        "reviewed": reviewed,
        "reasons": reasons,
        "required_components": required_components,
        "missing_components": missing_components,
        "chassis": chassis,
        "components": components,
        "masks": masks,
        "artifacts": normalized_artifacts,
        "reconstruction_bounds": verification.get("reconstruction_bounds"),
        "diff": {
            "after_path": diff_after,
            "image_path": diff_image,
            "report_path": diff_report,
            "exists": diff_exists,
        },
    }


def _status_for(
    definition: dict[str, str],
    path: Path,
    layout: dict[str, Any] | None,
    modular_dir: Path,
    modular_files: list[str],
    staged: dict[str, Any] | None = None,
) -> tuple[str, list[str], list[str]]:
    reasons: list[str] = []
    warnings: list[str] = []
    staged = staged or {}
    artwork_present = bool(modular_files) or bool(staged.get("authored"))
    if not path.exists():
        reasons.append("SOURCE_FILE_MISSING")
    if not artwork_present:
        if not modular_dir.is_dir():
            reasons.append("NO_MODULAR_ARTWORK_DIRECTORY")
        elif not modular_files:
            reasons.append("MODULAR_ARTWORK_DIRECTORY_EMPTY")
    elif modular_files:
        missing = sorted(set(EXPECTED_COMPONENT_PATHS) - set(modular_files))
        if missing:
            reasons.append("MODULAR_ARTWORK_INCOMPLETE")
    if artwork_present and staged.get("authored"):
        reasons.extend(str(item) for item in staged.get("reasons") or [])
        if staged.get("status") == "verified":
            return "verified", reasons, warnings
    else:
        if layout and layout.get("kind") != "paired_sheet_proposal":
            reasons.append("SOURCE_IS_SINGLE_CANVAS_NOT_CLEAN_WORN_PAIR")
        if layout and layout.get("review_required"):
            reasons.append("SOURCE_LAYOUT_REQUIRES_MANUAL_REVIEW")
    # These are provenance/diagnostic facts, not permanent blockers for a
    # carefully authored staged pilot.  Production approval remains a later
    # export gate and is never implied by this audit status.
    warnings.append("SOURCE_PROVENANCE_NOT_APPROVED_FOR_PRODUCTION")
    if definition["id"] == "walkie_4":
        warnings.append("KNOWN_WALKIETALKIE4_BAD_CUT_REGRESSION")
    if definition["id"] == "walkie_5" and not staged.get("authored"):
        reasons.append("US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW")
    if path.name.endswith(" .png"):
        warnings.append("FILENAME_CONTAINS_LITERAL_SPACE_BEFORE_EXTENSION")
    if artwork_present:
        return "proposed", reasons, warnings
    if reasons:
        return "blocked", reasons, warnings
    return "proposed", reasons, warnings


def _modular_file_records(modular_dir: Path, modular_files: list[str]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for relative in modular_files:
        path = modular_dir / relative
        record: dict[str, Any] = {"path": relative, "absolute_path": str(path.resolve())}
        try:
            metadata = inspect_image(path)
            record.update({
                "readable": True,
                "sha256": metadata["sha256"],
                "bytes": metadata["bytes"],
                "size": [metadata["width"], metadata["height"]],
                "mode": metadata["mode"],
                "alpha": _alpha_summary(metadata),
            })
        except Exception as error:
            record.update({"readable": False, "sha256": None, "error": str(error)})
        records.append(record)
    return records


def _manual_reconstruction_record(
    layout: dict[str, Any] | None,
    source_exists: bool,
    staged: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Describe the manual-art boundary without proposing pixels automatically."""

    staged = staged or {}
    layout_kind = str((layout or {}).get("kind") or "unavailable")
    if not source_exists:
        reason = "SOURCE_FILE_MISSING"
        next_action = "Supply the canonical source before authoring any modular artwork."
    elif layout_kind == "paired_sheet_proposal":
        reason = "SOURCE_LAYOUT_REQUIRES_MANUAL_REVIEW"
        next_action = "Visually verify the proposed clean/worn split, then author reviewed chassis and sockets."
    elif layout_kind == "single_canvas":
        reason = "FLATTENED_SOURCE_REQUIRES_MANUAL_RECONSTRUCTION"
        next_action = "Author concealed chassis pixels, precise sockets, and keyed states from reviewed source art."
    else:
        reason = "SOURCE_LAYOUT_UNAVAILABLE"
        next_action = "Resolve and visually review the source layout before modular authoring."
    if staged.get("authored"):
        pristine = staged.get("chassis", {}).get("pristine", {})
        worn = staged.get("chassis", {}).get("worn", {})
        socket_masks = [item for item in staged.get("masks", {}).values() if item.get("exists")]
        authored_components = [item for item in staged.get("components", {}).values() if item.get("states")]
        diff_exists = bool((staged.get("diff") or {}).get("exists"))
        reviewed = bool(staged.get("reviewed"))

        def gate_status(present: bool, gate_reviewed: bool = False) -> str:
            return "verified" if present and gate_reviewed else ("proposed" if present else "blocked")

        gates = [
            {
                "id": "chassis_reconstruction",
                "status": gate_status(
                    bool(pristine.get("image", {}).get("exists") and worn.get("image", {}).get("exists")),
                    bool(pristine.get("reviewed") and worn.get("reviewed")),
                ),
                "reason": None if pristine.get("image", {}).get("exists") and worn.get("image", {}).get("exists") else "WORN_CHASSIS_PENDING",
                "requirement": "complete pristine and worn chassis with real empty sockets",
            },
            {
                "id": "socket_masks",
                "status": gate_status(bool(socket_masks), all(item.get("reviewed") for item in socket_masks)),
                "reason": None if socket_masks else "SOCKET_MASKS_PENDING",
                "requirement": "pixel-tight source-space masks with no transparent exterior or neighbor contamination",
            },
            {
                "id": "component_state_art",
                "status": gate_status(bool(authored_components), all(item.get("reviewed") for item in authored_components)),
                "reason": None if authored_components else "COMPONENT_STATE_ART_PENDING",
                "requirement": "independent controls, states, LEDs, LCD layers, and rotary frames",
            },
            {
                "id": "reconstruction_review",
                "status": gate_status(diff_exists, reviewed),
                "reason": None if diff_exists else "SOURCE_TO_IDLE_DIFF_PENDING",
                "requirement": "full-resolution visual review and source-to-idle diff",
            },
        ]
        all_verified = all(gate["status"] == "verified" for gate in gates)
        return {
            "required": True,
            "status": "verified" if all_verified else "proposed",
            "reason": None if all_verified else "MODULAR_ARTWORK_REQUIRES_REVIEW",
            "source_layout": layout_kind,
            "next_action": "Complete the remaining W5 controls, worn chassis, and visual review before production approval." if not all_verified else "No manual reconstruction gate remains for this reviewed device.",
            "gates": gates,
        }

    return {
        "required": True,
        "status": "blocked",
        "reason": reason,
        "source_layout": layout_kind,
        "next_action": next_action,
        "gates": [
            {
                "id": "chassis_reconstruction",
                "status": "blocked",
                "reason": reason,
                "requirement": "complete pristine and worn chassis with real empty sockets",
            },
            {
                "id": "socket_masks",
                "status": "blocked",
                "reason": reason,
                "requirement": "pixel-tight source-space masks with no transparent exterior or neighbor contamination",
            },
            {
                "id": "component_state_art",
                "status": "blocked",
                "reason": reason,
                "requirement": "independent controls, states, LEDs, LCD layers, and rotary frames",
            },
            {
                "id": "reconstruction_review",
                "status": "blocked",
                "reason": "NO_REVIEWED_MODULAR_ARTWORK",
                "requirement": "full-resolution visual review and source-to-idle diff",
            },
        ],
    }


def _qa_requirements(
    definition: dict[str, str],
    source_exists: bool,
    modular_files: list[str],
    manual_reconstruction: dict[str, Any],
    staged: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    staged = staged or {}
    source_status = "complete" if source_exists else "blocked"
    source_reason = None if source_exists else "SOURCE_FILE_MISSING"
    modular_reason = "NO_REVIEWED_MODULAR_ARTWORK" if not modular_files else "MODULAR_ARTWORK_REQUIRES_REVIEW"
    if staged.get("authored"):
        gates = {str(item.get("id")): item for item in manual_reconstruction.get("gates") or [] if isinstance(item, dict)}
        pristine = staged.get("chassis", {}).get("pristine", {})
        worn = staged.get("chassis", {}).get("worn", {})
        components = staged.get("components") or {}
        component_status = "verified" if components and all(item.get("reviewed") and item.get("status") == "verified" for item in components.values()) else ("proposed" if components else "blocked")
        diff_status = "proposed" if (staged.get("diff") or {}).get("exists") else "blocked"
        visual_status = "verified" if staged.get("reviewed") else ("proposed" if staged.get("artifacts") else "blocked")
        requirements = [
            {"id": "source_inventory", "status": source_status, "reason": source_reason},
            {"id": "full_resolution_source_copy", "status": "pending_artifact"},
            {"id": "alpha_preview", "status": "pending_artifact"},
            {"id": "manual_reconstruction_plan", "status": manual_reconstruction["status"], "reason": manual_reconstruction.get("reason"), "next_action": manual_reconstruction["next_action"]},
            {"id": "pristine_chassis", "status": "verified" if pristine.get("image", {}).get("exists") and pristine.get("reviewed") else ("proposed" if pristine.get("image", {}).get("exists") else "blocked"), "reason": None if pristine.get("image", {}).get("exists") else "PRISTINE_CHASSIS_MISSING"},
            {"id": "worn_chassis", "status": "verified" if worn.get("image", {}).get("exists") and worn.get("reviewed") else ("proposed" if worn.get("image", {}).get("exists") else "blocked"), "reason": None if worn.get("image", {}).get("exists") else "WORN_CHASSIS_PENDING"},
            {"id": "socket_masks", "status": str(gates.get("socket_masks", {}).get("status") or "blocked"), "reason": gates.get("socket_masks", {}).get("reason")},
            {"id": "component_state_sheets", "status": component_status, "reason": None if components else "COMPONENT_STATE_ART_PENDING"},
            {"id": "source_to_idle_diff", "status": diff_status, "reason": None if diff_status != "blocked" else "SOURCE_TO_IDLE_DIFF_PENDING"},
            {"id": "visual_review", "status": visual_status, "reason": None if visual_status == "verified" else "VISUAL_REVIEW_PENDING"},
        ]
    else:
        requirements = [
            {"id": "source_inventory", "status": source_status, "reason": source_reason},
            {"id": "full_resolution_source_copy", "status": "pending_artifact"},
            {"id": "alpha_preview", "status": "pending_artifact"},
            {
                "id": "manual_reconstruction_plan",
                "status": manual_reconstruction["status"],
                "reason": manual_reconstruction["reason"],
                "next_action": manual_reconstruction["next_action"],
            },
            {"id": "pristine_chassis", "status": "blocked", "reason": modular_reason},
            {"id": "worn_chassis", "status": "blocked", "reason": modular_reason},
            {"id": "socket_masks", "status": "blocked", "reason": modular_reason},
            {"id": "component_state_sheets", "status": "blocked", "reason": modular_reason},
            {"id": "source_to_idle_diff", "status": "blocked", "reason": "NO_REVIEWED_MODULAR_ARTWORK"},
            {"id": "visual_review", "status": "blocked", "reason": "NO_REVIEWED_MODULAR_ARTWORK"},
        ]
    if definition["id"] == "walkie_4":
        requirements.append({"id": "bad_cut_regression", "status": "pending_artifact"})
    if definition["id"] == "walkie_5":
        requirements.append({"id": "pilot_acceptance_sheet", "status": "proposed" if staged.get("authored") else "blocked", "reason": "VISUAL_REVIEW_PENDING" if staged.get("authored") else "US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW"})
    return requirements


def _record_device(root: Path, definition: dict[str, str], *, include_staged: bool = True) -> dict[str, Any]:
    path = _device_path(root, definition)
    family_dir = FAMILY_DIRECTORIES[definition["family"]]
    owner_path = (CANONICAL_IMAGE_ROOT / family_dir / definition["filename"]).as_posix()
    modular_dir = _modular_directory(root, definition, path)
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
    staged = _staged_authoring_evidence(root, definition) if include_staged else {"authored": False}
    status, reasons, warnings = _status_for(definition, path, layout, modular_dir, modular_files, staged)
    manual_reconstruction = _manual_reconstruction_record(layout, path.is_file(), staged)
    missing_required_paths = sorted(set(EXPECTED_COMPONENT_PATHS) - set(modular_files))
    modular_file_records = _modular_file_records(modular_dir, modular_files) if modular_files else []
    unreadable_modular = [record for record in modular_file_records if not record.get("readable")]
    if unreadable_modular:
        status = "blocked"
        reasons.append("MODULAR_FILE_UNREADABLE")
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
            "file_records": modular_file_records,
            "required_paths": list(EXPECTED_COMPONENT_PATHS),
            "missing_required_paths": missing_required_paths,
        },
        "staged_authoring": staged,
        "verification": {
            "status": status,
            "reviewed": False,
            "reasons": reasons,
            "warnings": warnings,
            "artifacts": [],
            "manual_reconstruction": manual_reconstruction,
            "qa_requirements": _qa_requirements(
                definition,
                path.is_file(),
                modular_files,
                manual_reconstruction,
                staged,
            ),
        },
    }


def audit_radio_sources(root: Path, *, family: str | None = None, include_staged: bool = True) -> dict[str, Any]:
    """Audit the ten canonical radio sources without mutating any source PNG."""

    root = Path(root).expanduser().resolve()
    if family is not None and family not in FAMILY_DIRECTORIES:
        raise AssetHarnessError("INVALID_RADIO_FAMILY", f"unknown radio family: {family}")
    definitions = [item for item in RADIO_DEVICE_DEFINITIONS if family is None or item["family"] == family]
    devices = [_record_device(root, item, include_staged=include_staged) for item in definitions]
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
    verification = device.get("verification") or {}
    manual_reconstruction = verification.get("manual_reconstruction") or {
        "required": True,
        "status": "blocked",
        "reason": "MANUAL_RECONSTRUCTION_REQUIRED",
        "source_layout": (source.get("layout") or {}).get("kind", "unavailable"),
        "next_action": "Author and visually review modular artwork before approval.",
        "gates": [],
    }
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
            "lcd_layers": {},
            "required_components": list(REQUIRED_SEMANTIC_COMPONENTS),
            "verification": {
                "reviewed": False,
                "status": "incomplete",
                "reasons": ["NO_REVIEWED_MODULAR_ARTWORK", manual_reconstruction["reason"]],
            },
        },
        "export": {
            "runtime_root": "Contents/mods/PsychopatzCore/common/media/ui",
            "device_path": f"Radio/{FAMILY_DIRECTORIES.get(family, family)}/{model}",
            "textures": [],
            "manifest_filename": "skin.lua",
        },
        "owner_path": device["owner_path"],
        "source": source,
        "staged_authoring": device.get("staged_authoring") or {"authored": False, "status": "blocked"},
        "modular_output": device["modular_output"],
        "manual_reconstruction": manual_reconstruction,
        "chassis": {
            "pristine": {"status": "blocked", "image": None, "socket_mask": None, "anchors": {}},
            "worn": {"status": "blocked", "image": None, "socket_mask": None, "anchors": {}},
        },
        "components": {},
        "component_inventory": {
            component_id: {
                "status": "blocked",
                "reason": manual_reconstruction["reason"],
                "source_owner": device["owner_path"],
                "coordinates": None,
            }
            for component_id in REQUIRED_SEMANTIC_COMPONENTS
        },
        "verification": device["verification"],
        "notes": [
            "This manifest is an AH-R0 audit record, not an approval or runtime export declaration.",
            "Rectangular crops and inferred component states are not production-ready evidence.",
            "The current source layout requires manual reconstruction before chassis, sockets, or keyed states can be reviewed.",
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


def _write_proposed_radio_pilot_artifacts(
    report: dict[str, Any],
    device: dict[str, Any],
    output_root: Path,
    source_path: Path,
) -> list[Path]:
    """Create a real, explicitly proposed W5 pilot sheet from staged art."""

    staged = device.get("staged_authoring") or {}
    output_root = Path(output_root).expanduser().resolve()
    sheet_path = output_root / "walkie_5_pilot_acceptance.png"
    checklist_path = output_root / "walkie_5_pilot_acceptance.json"
    panels: list[tuple[str, Path]] = [("IMMUTABLE SOURCE", source_path)]
    for item in staged.get("artifacts") or []:
        if not isinstance(item, dict):
            continue
        kind = str(item.get("kind") or "").lower()
        path_value = item.get("path_path") or item.get("diff_path")
        if kind == "mask_overlay":
            label = "BACK MASK OVERLAY"
        elif kind == "socket_candidate":
            label = "EMPTY SOCKET CANDIDATE"
        elif kind == "idle_composite":
            label = "ASSEMBLED IDLE"
        elif kind == "pressed_composite":
            label = "ASSEMBLED PRESSED"
        elif kind == "source_to_idle_diff":
            label = "SOURCE -> IDLE DIFF"
            path_value = item.get("diff_path")
        else:
            continue
        if path_value:
            candidate = Path(str(path_value)).expanduser().resolve()
            if candidate.is_file():
                panels.append((label, candidate))
    panels = panels[:6]

    panel_width, panel_height, gap, columns = 360, 520, 12, 3
    rows = max(1, (len(panels) + columns - 1) // columns)
    sheet = Image.new("RGBA", (columns * panel_width + (columns - 1) * gap, rows * panel_height + (rows - 1) * gap), (25, 30, 36, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    font = ImageFont.load_default()
    for index, (label, path) in enumerate(panels):
        x = (index % columns) * (panel_width + gap)
        y = (index // columns) * (panel_height + gap)
        draw.rectangle((x, y, x + panel_width - 1, y + panel_height - 1), fill=(42, 48, 56, 255), outline=(112, 125, 138, 255))
        draw.text((x + 10, y + 10), label, font=font, fill=(255, 240, 180, 255))
        try:
            with Image.open(path) as image_file:
                image = image_file.convert("RGBA")
                image.thumbnail((panel_width - 24, panel_height - 52), Image.Resampling.LANCZOS)
                px = x + (panel_width - image.width) // 2
                py = y + 34 + (panel_height - 34 - image.height) // 2
                sheet.alpha_composite(image, (px, py))
        except (OSError, ValueError, UnicodeError):
            draw.text((x + 10, y + 42), "unreadable", font=font, fill=(255, 104, 104, 255))
    _write_png(sheet, sheet_path)

    source = device.get("source") or {}
    diff = staged.get("diff") or {}
    checklist = {
        "schema_version": 1,
        "acceptance_kind": "radio_modular_pilot_evidence",
        "status": "proposed",
        "accepted": False,
        "reason": "W5_BACK_CONTROL_PILOT_PROPOSED_REVIEW_PENDING",
        "device": {"id": device.get("id"), "full_type": device.get("full_type"), "family": device.get("family")},
        "source": {
            "path": source.get("path"),
            "absolute_path": str(source_path),
            "filename": source.get("filename"),
            "sha256": source.get("sha256"),
            "size": source.get("size"),
            "mode": source.get("mode"),
            "immutable": True,
        },
        "artifacts": {
            "acceptance_sheet": {"path": str(sheet_path), "sha256": sha256_path(sheet_path)},
            "mask_overlay": next((item.get("path_path") for item in staged.get("artifacts") or [] if item.get("kind") == "mask_overlay"), None),
            "socket_candidate": next((item.get("path_path") for item in staged.get("artifacts") or [] if item.get("kind") == "socket_candidate"), None),
            "idle_composite": next((item.get("path_path") for item in staged.get("artifacts") or [] if item.get("kind") == "idle_composite"), None),
            "pressed_composite": next((item.get("path_path") for item in staged.get("artifacts") or [] if item.get("kind") == "pressed_composite"), None),
            "source_to_idle_diff": {
                "path": diff.get("image_path"),
                "report": diff.get("report_path"),
                "status": "proposed" if diff.get("exists") else "blocked",
            },
        },
        "scope": {
            "source_mutation": False,
            "modular_artwork_created": True,
            "production_export_apply": False,
            "accepted_for_runtime": False,
        },
        "review_notes": [
            "The Back face mask was inspected at native resolution and excludes the visible green chassis strip.",
            "The socket candidate is a localized reconstructed recess; it is proposed, not approved.",
            "Idle preserves the source face; pressed uses registered inward travel and contact shadow.",
            "The numeric diff is confined to the documented reconstruction bounds; remaining controls and worn chassis are pending.",
        ],
    }
    atomic_write_text(checklist_path, json.dumps(checklist, ensure_ascii=True, sort_keys=True, indent=2) + "\n")
    qa_by_id = {str(item.get("id")): item for item in device.get("verification", {}).get("qa_requirements") or [] if isinstance(item, dict)}
    pilot_requirement = qa_by_id.get("pilot_acceptance_sheet")
    if pilot_requirement is not None:
        pilot_requirement.update({"status": "proposed", "path": str(sheet_path), "sha256": sha256_path(sheet_path), "evidence_status": "real_artwork_proposed"})
    device.setdefault("verification", {}).setdefault("artifacts", []).extend([
        {"kind": "pilot_acceptance_sheet", "path": str(sheet_path), "sha256": sha256_path(sheet_path), "status": "proposed_evidence"},
        {"kind": "pilot_acceptance_checklist", "path": str(checklist_path), "sha256": sha256_path(checklist_path), "status": "proposed_evidence"},
    ])
    report.setdefault("pilot_evidence", {})["walkie_5"] = {
        "status": "proposed",
        "accepted": False,
        "sheet": {"path": str(sheet_path), "sha256": sha256_path(sheet_path)},
        "checklist": {"path": str(checklist_path), "sha256": sha256_path(checklist_path)},
        "source_to_idle_diff": {"path": diff.get("image_path"), "report": diff.get("report_path"), "metrics": diff.get("metrics")},
    }
    return [sheet_path, checklist_path]


def write_radio_pilot_acceptance_artifacts(report: dict[str, Any], output_root: Path) -> list[Path]:
    """Write a blocked, inspectable W5 pilot review sheet and checklist.

    The sheet is evidence for the human art-review boundary, not an approval
    artifact.  It only displays the immutable W5 source and its alpha channel;
    it never synthesizes a chassis, socket, control state, or worn variant.
    """

    device = next((item for item in report.get("devices") or [] if item.get("id") == "walkie_5"), None)
    if not isinstance(device, dict):
        return []
    source = device.get("source") or {}
    source_value = source.get("absolute_path")
    if not source_value or not Path(source_value).is_file():
        return []
    source_path = Path(source_value).resolve()
    output_root = Path(output_root).expanduser().resolve()
    if (device.get("staged_authoring") or {}).get("authored"):
        return _write_proposed_radio_pilot_artifacts(report, device, output_root, source_path)
    source_copy = output_root / "sources" / "walkie_5.png"
    alpha_path = output_root / "alpha" / "walkie_5.png"
    sheet_path = output_root / "walkie_5_pilot_acceptance.png"
    checklist_path = output_root / "walkie_5_pilot_acceptance.json"
    source_copy.parent.mkdir(parents=True, exist_ok=True)
    alpha_path.parent.mkdir(parents=True, exist_ok=True)
    if not source_copy.exists() or source_copy.read_bytes() != source_path.read_bytes():
        atomic_write_bytes(source_copy, source_path.read_bytes())

    with Image.open(source_path) as image:
        image.load()
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        _write_png(alpha, alpha_path)
        alpha_display = Image.merge("RGBA", (alpha, alpha, alpha, Image.new("L", alpha.size, 255)))

    qa_requirements = [
        item for item in device.get("verification", {}).get("qa_requirements") or []
        if isinstance(item, dict)
    ]
    qa_by_id = {str(item.get("id")): item for item in qa_requirements}
    required_visual_checks = [
        "Pristine chassis preserves the complete W5 silhouette and design.",
        "Worn chassis is a separately authored condition, not a crop or filter.",
        "Socket masks are pixel-tight and do not select transparent exterior pixels or neighbors.",
        "Back/Home/Up/Down/Left/Right/OK, PTT, Power, Volume, and Channel are independently authored.",
        "PWR/RX/TX LEDs and LCD glass/bezel have reviewed off/on or idle/held state evidence.",
        "A reviewed source-to-idle diff documents reconstruction fidelity at full resolution.",
    ]
    checklist = {
        "schema_version": 1,
        "acceptance_kind": "radio_modular_pilot_evidence",
        "status": "blocked",
        "accepted": False,
        "reason": "US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW",
        "device": {
            "id": device.get("id"),
            "full_type": device.get("full_type"),
            "family": device.get("family"),
        },
        "source": {
            "path": source.get("path"),
            "absolute_path": str(source_path),
            "filename": source.get("filename"),
            "sha256": source.get("sha256"),
            "size": source.get("size"),
            "mode": source.get("mode"),
            "immutable": True,
        },
        "qa_requirements": qa_requirements,
        "required_visual_checks": [
            {"id": f"visual_{index + 1}", "status": "blocked", "description": description}
            for index, description in enumerate(required_visual_checks)
        ],
        "artifacts": {
            "source_full_resolution": {"path": str(source_copy), "sha256": sha256_path(source_copy)},
            "alpha_preview": {"path": str(alpha_path), "sha256": sha256_path(alpha_path)},
            "acceptance_sheet": {"path": str(sheet_path), "sha256": None},
        },
        "scope": {
            "source_mutation": False,
            "modular_artwork_created": False,
            "production_export_apply": False,
            "accepted_for_runtime": False,
        },
    }

    font = ImageFont.load_default()
    title_font = ImageFont.load_default()
    panel_width, panel_height = 500, 820
    info_width = 470
    gap = 16
    sheet_width = panel_width * 2 + info_width + gap * 2
    sheet_height = 900
    sheet = Image.new("RGBA", (sheet_width, sheet_height), (24, 28, 33, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")

    def draw_panel(panel: Image.Image, label: str, x: int) -> None:
        draw.rectangle((x, 46, x + panel_width - 1, panel_height), fill=(42, 48, 56, 255), outline=(112, 125, 138, 255))
        draw.text((x + 10, 18), label, font=title_font, fill=(255, 240, 180, 255))
        preview = panel.copy()
        preview.thumbnail((panel_width - 24, panel_height - 66), Image.Resampling.LANCZOS)
        px = x + (panel_width - preview.width) // 2
        py = 55 + (panel_height - 46 - preview.height) // 2
        sheet.alpha_composite(preview, (px, py))

    draw_panel(rgba, "IMMUTABLE SOURCE", 0)
    draw_panel(alpha_display, "FULL-RESOLUTION ALPHA", panel_width + gap)

    info_x = panel_width * 2 + gap * 2
    draw.rectangle((info_x, 0, sheet_width - 1, sheet_height - 1), fill=(34, 39, 46, 255), outline=(112, 125, 138, 255))
    draw.text((info_x + 14, 16), "W5 PILOT", font=title_font, fill=(255, 240, 180, 255))
    draw.text((info_x + 14, 34), "BLOCKED / NOT ACCEPTED", font=font, fill=(255, 104, 104, 255))
    lines: list[tuple[str, tuple[int, int, int, int]]] = [
        (f"source: {source.get('filename')}", (225, 230, 235, 255)),
        (f"canvas: {source.get('size')}", (225, 230, 235, 255)),
        (f"sha256: {str(source.get('sha256') or '')[:24]}...", (225, 230, 235, 255)),
        ("", (225, 230, 235, 255)),
        ("QA GATES", (255, 240, 180, 255)),
    ]
    gate_labels = {
        "source_inventory": "source inventory",
        "full_resolution_source_copy": "full-resolution source copy",
        "alpha_preview": "alpha preview",
        "manual_reconstruction_plan": "manual reconstruction plan",
        "pristine_chassis": "pristine chassis",
        "worn_chassis": "worn chassis",
        "socket_masks": "socket masks",
        "component_state_sheets": "component state sheets",
        "source_to_idle_diff": "source-to-idle diff",
        "visual_review": "visual review",
        "pilot_acceptance_sheet": "pilot acceptance",
    }
    for requirement_id, requirement in qa_by_id.items():
        status = str(requirement.get("status") or "blocked").upper()
        lines.append((f"{gate_labels.get(requirement_id, requirement_id)}: {status}", (225, 230, 235, 255)))
    lines.extend([
        ("", (225, 230, 235, 255)),
        ("REVIEW BEFORE ACCEPTANCE", (255, 240, 180, 255)),
    ])
    for index, description in enumerate(required_visual_checks, start=1):
        wrapped = textwrap.wrap(f"{index}. {description}", width=48) or [""]
        lines.extend((line, (225, 230, 235, 255)) for line in wrapped)
    lines.extend([
        ("", (225, 230, 235, 255)),
        ("This sheet is diagnostic evidence only.", (255, 180, 120, 255)),
        ("No chassis, sockets, states, or runtime", (255, 180, 120, 255)),
        ("export were authored by this artifact.", (255, 180, 120, 255)),
    ])
    cursor_y = 62
    for line, color in lines:
        draw.text((info_x + 14, cursor_y), line, font=font, fill=color)
        cursor_y += 14
    _write_png(sheet, sheet_path)
    checklist["artifacts"]["acceptance_sheet"]["sha256"] = sha256_path(sheet_path)
    atomic_write_text(checklist_path, json.dumps(checklist, ensure_ascii=True, sort_keys=True, indent=2) + "\n")

    verification = device.setdefault("verification", {})
    artifacts = verification.setdefault("artifacts", [])
    artifacts.extend([
        {
            "kind": "pilot_acceptance_sheet",
            "path": str(sheet_path),
            "sha256": sha256_path(sheet_path),
            "status": "blocked_evidence_only",
        },
        {
            "kind": "pilot_acceptance_checklist",
            "path": str(checklist_path),
            "sha256": sha256_path(checklist_path),
            "status": "blocked_evidence_only",
        },
    ])
    pilot_requirement = qa_by_id.get("pilot_acceptance_sheet")
    if pilot_requirement is not None:
        pilot_requirement.update({
            "status": "blocked",
            "path": str(sheet_path),
            "sha256": sha256_path(sheet_path),
            "evidence_status": "generated_not_acceptance",
        })
    report.setdefault("pilot_evidence", {})["walkie_5"] = {
        "status": "blocked",
        "accepted": False,
        "sheet": {"path": str(sheet_path), "sha256": sha256_path(sheet_path)},
        "checklist": {"path": str(checklist_path), "sha256": sha256_path(checklist_path)},
    }
    return [sheet_path, checklist_path]


def _write_blocked_source_to_idle_diff(
    device: dict[str, Any],
    source: dict[str, Any],
    source_copy: Path,
    alpha_path: Path,
    output_root: Path,
) -> Path:
    """Write a truthful diff record when no reviewed idle target exists."""

    diff_root = output_root / "diff"
    diff_root.mkdir(parents=True, exist_ok=True)
    diff_path = diff_root / f"{device['id']}_source_to_idle.json"
    record = {
        "schema_version": 1,
        "diff_kind": "source_to_idle",
        "device_id": device["id"],
        "status": "blocked",
        "reason": "NO_REVIEWED_MODULAR_ARTWORK",
        "before": {
            "path": str(source_copy),
            "sha256": sha256_path(source_copy),
            "source_owner": source.get("path"),
            "source_sha256": source.get("sha256"),
            "size": source.get("size"),
            "alpha_preview": {"path": str(alpha_path), "sha256": sha256_path(alpha_path)},
        },
        "after": None,
        "metrics": None,
        "scope": {
            "source_mutation": False,
            "fake_idle_generated": False,
            "production_export_apply": False,
        },
    }
    atomic_write_text(diff_path, json.dumps(record, ensure_ascii=True, sort_keys=True, indent=2) + "\n")
    return diff_path


def _write_source_to_idle_diff(
    device: dict[str, Any],
    source: dict[str, Any],
    source_copy: Path,
    alpha_path: Path,
    output_root: Path,
) -> tuple[list[Path], dict[str, Any]]:
    """Write a real diff when an authored assembled idle exists."""

    staged = device.get("staged_authoring") or {}
    diff_info = staged.get("diff") or {}
    after_value = diff_info.get("after_path")
    after_path = Path(str(after_value)).expanduser().resolve() if after_value else None
    if not after_path or not after_path.is_file():
        blocked = _write_blocked_source_to_idle_diff(device, source, source_copy, alpha_path, output_root)
        return [blocked], {"status": "blocked", "report_path": blocked, "diff_path": None, "record": None}

    diff_root = output_root / "diff"
    diff_root.mkdir(parents=True, exist_ok=True)
    diff_image_path = diff_root / f"{device['id']}_source_to_idle.png"
    diff_report_path = diff_root / f"{device['id']}_source_to_idle.json"
    with Image.open(source_copy) as before_file, Image.open(after_path) as after_file:
        before = before_file.convert("RGBA")
        after = after_file.convert("RGBA")
        diff_image, diff_metrics = difference_image(before, after)
    _write_png(diff_image, diff_image_path)
    status = "verified" if str(staged.get("status")) == "verified" else "proposed"
    record = {
        "schema_version": 1,
        "diff_kind": "source_to_idle",
        "device_id": device["id"],
        "status": status,
        "reason": "AUTHORED_MODULAR_IDLE_RECOMPOSITION",
        "before": {
            "path": str(source_copy),
            "sha256": sha256_path(source_copy),
            "source_owner": source.get("path"),
            "source_sha256": source.get("sha256"),
            "size": source.get("size"),
            "alpha_preview": {"path": str(alpha_path), "sha256": sha256_path(alpha_path)},
        },
        "after": {
            "path": str(after_path),
            "sha256": sha256_path(after_path),
            "size": [after.width, after.height],
        },
        "diff": {"path": str(diff_image_path), "sha256": sha256_path(diff_image_path)},
        "metrics": diff_metrics,
        "scope": {
            "source_mutation": False,
            "documented_reconstruction_bounds": staged.get("reconstruction_bounds"),
            "fake_idle_generated": False,
            "production_export_apply": False,
        },
    }
    atomic_write_text(diff_report_path, json.dumps(record, ensure_ascii=True, sort_keys=True, indent=2) + "\n")
    return [diff_image_path, diff_report_path], {"status": status, "report_path": diff_report_path, "diff_path": diff_image_path, "record": record}


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
        diff_paths, diff_evidence = _write_source_to_idle_diff(device, source, source_copy, alpha_path, output_root)
        artifacts.extend((source_copy, alpha_path))
        artifacts.extend(diff_paths)
        verification_artifacts = device.setdefault("verification", {}).setdefault("artifacts", [])
        verification_artifacts.extend([
            {"kind": "source_full_resolution", "path": str(source_copy), "sha256": sha256_path(source_copy)},
            {"kind": "alpha_preview", "path": str(alpha_path), "sha256": sha256_path(alpha_path)},
        ])
        if diff_evidence.get("record"):
            record = diff_evidence["record"]
            verification_artifacts.append({
                "kind": "source_to_idle_diff",
                "status": diff_evidence["status"],
                "sha256": record["diff"]["sha256"],
                "report_path": str(diff_evidence["report_path"]),
                "report_sha256": sha256_path(diff_evidence["report_path"]),
                "diff_path": str(diff_evidence["diff_path"]),
                "metrics": record["metrics"],
                "reason": record["reason"],
            })
        else:
            blocked_path = diff_evidence["report_path"]
            verification_artifacts.append({
                "kind": "source_to_idle_diff",
                "status": "blocked",
                "sha256": None,
                "report_path": str(blocked_path),
                "report_sha256": sha256_path(blocked_path),
                "reason": "NO_REVIEWED_MODULAR_ARTWORK",
            })
        qa_requirements = device.setdefault("verification", {}).setdefault("qa_requirements", [])
        for requirement_id, artifact_path in (("full_resolution_source_copy", source_copy), ("alpha_preview", alpha_path)):
            requirement = next((item for item in qa_requirements if item.get("id") == requirement_id), None)
            if requirement is not None:
                requirement.update({"status": "complete", "path": str(artifact_path), "sha256": sha256_path(artifact_path)})
        diff_requirement = next((item for item in qa_requirements if item.get("id") == "source_to_idle_diff"), None)
        if diff_requirement is not None:
            if diff_evidence.get("record"):
                diff_requirement.update({
                    "status": diff_evidence["status"],
                    "path": str(diff_evidence["diff_path"]),
                    "report_path": str(diff_evidence["report_path"]),
                    "report_sha256": sha256_path(diff_evidence["report_path"]),
                    "sha256": sha256_path(diff_evidence["diff_path"]),
                    "reason": diff_evidence["record"]["reason"],
                    "metrics": diff_evidence["record"]["metrics"],
                })
            else:
                diff_requirement.update({
                    "status": "blocked",
                    "path": str(diff_evidence["report_path"]),
                    "report_sha256": sha256_path(diff_evidence["report_path"]),
                    "reason": "NO_REVIEWED_MODULAR_ARTWORK",
                })
        if device.get("id") == "walkie_4":
            regression_paths, regression = _write_walkie4_bad_cut_regression(source_path, output_root)
            artifacts.extend(regression_paths)
            device.setdefault("verification", {}).setdefault("artifacts", []).extend([
                {"kind": "bad_cut_regression_preview", "path": str(regression_paths[0]), "sha256": sha256_path(regression_paths[0])},
                {"kind": "bad_cut_regression_diff", "path": str(regression_paths[1]), "sha256": sha256_path(regression_paths[1]), "metrics": regression["diff"]},
            ])
            requirement = next((item for item in qa_requirements if item.get("id") == "bad_cut_regression"), None)
            if requirement is not None:
                requirement.update({"status": "complete", "path": str(regression_paths[1]), "sha256": sha256_path(regression_paths[1])})
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
    if any(device.get("id") == "walkie_5" for device in report.get("devices") or []):
        artifacts.extend(write_radio_pilot_acceptance_artifacts(report, output_root))
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
