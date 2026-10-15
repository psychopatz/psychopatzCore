"""Lossless mask registration, inspection, previews, and contamination QA.

Masks are source-canvas artifacts.  Rectangles remain useful for locating a
candidate, but a component cannot become verified production artwork without
an explicit non-rectangular/hand-authored mask and a review status.
"""

from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any, Mapping, Sequence

from PIL import Image, ImageChops, ImageColor, ImageDraw

from .errors import AssetHarnessError, diagnostic
from .paths import MAX_PIXELS, atomic_write_bytes, ensure_within, parse_rect, resolve_reference, relative_reference
from .project import project_workspace
from .responses import artifact_descriptor, sha256_path
from .source import inspect_image, load_rgba


MASK_SCHEMA_VERSION = 1
MASK_METHODS = {"alpha", "manual_polygon", "manual_path", "hand_authored", "derived_proposal", "rectangle"}
MASK_STATUSES = {"proposed", "verified", "blocked", "rejected"}


def _mask_from_image(image: Image.Image) -> Image.Image:
    if image.width * image.height > MAX_PIXELS:
        raise AssetHarnessError("IMAGE_TOO_LARGE", "mask exceeds the pixel safety limit")
    if "A" in image.getbands():
        return image.getchannel("A").convert("L")
    return image.convert("L")


def load_mask(path: Path) -> Image.Image:
    target = Path(path).expanduser().resolve()
    if not target.exists() or not target.is_file():
        raise AssetHarnessError("MASK_NOT_FOUND", f"mask does not exist: {target}")
    try:
        with Image.open(target) as image:
            image.load()
            return _mask_from_image(image).copy()
    except (OSError, ValueError, UnicodeError) as error:
        raise AssetHarnessError("MASK_UNREADABLE", f"cannot read mask: {target}: {error}") from error


def inspect_mask(path: Path) -> dict[str, Any]:
    target = Path(path).expanduser().resolve()
    mask = load_mask(target)
    histogram = mask.histogram()
    bbox = mask.getbbox()
    nonzero = sum(histogram[1:])
    bbox_area = bbox[2] * bbox[3] if bbox else 0
    return {
        "path": str(target),
        "sha256": sha256_path(target),
        "bytes": target.stat().st_size,
        "width": mask.width,
        "height": mask.height,
        "mode": "L",
        "transparent_pixels": int(histogram[0]),
        "partial_pixels": int(sum(histogram[1:255])),
        "opaque_pixels": int(histogram[255]),
        "nonzero_pixels": int(nonzero),
        "nonzero_bounds": [bbox[0], bbox[1], bbox[2] - bbox[0], bbox[3] - bbox[1]] if bbox else None,
        "bbox_fill_ratio": round(nonzero / bbox_area, 6) if bbox_area else 0.0,
    }


def _mask_workspace_path(project_path: Path, project: dict[str, Any], mask_id: str) -> Path:
    if not mask_id or any(character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for character in mask_id):
        raise AssetHarnessError("INVALID_MASK_ID", f"invalid mask ID: {mask_id!r}")
    workspace = project_workspace(project_path, project)
    return ensure_within(workspace, workspace / "masks" / f"{mask_id}.png")


def register_mask(
    project_path: Path,
    project: dict[str, Any],
    mask_id: str,
    input_path: str,
    *,
    source_id: str | None = None,
    method: str = "hand_authored",
    status: str = "proposed",
    provenance: str | None = None,
    bounds: Any = None,
    forbidden_mask_id: str | None = None,
    review: Mapping[str, Any] | None = None,
    allow_external: bool = True,
) -> dict[str, Any]:
    if method not in MASK_METHODS:
        raise AssetHarnessError("INVALID_MASK_METHOD", f"unsupported mask method: {method}")
    if status not in MASK_STATUSES:
        raise AssetHarnessError("INVALID_MASK_STATUS", f"unsupported mask status: {status}")
    workspace = project_workspace(project_path, project)
    source_path = resolve_reference(workspace, input_path, allow_external=allow_external, must_exist=True)
    metadata = inspect_mask(source_path)
    destination = _mask_workspace_path(project_path, project, mask_id)
    original = source_path.read_bytes()
    if destination.exists() and destination.read_bytes() != original:
        raise AssetHarnessError("MASK_CONFLICT", f"mask already exists with different bytes: {destination}")
    if not destination.exists():
        atomic_write_bytes(destination, original)
    record: dict[str, Any] = {
        "schema_version": MASK_SCHEMA_VERSION,
        "path": relative_reference(destination, workspace),
        "sha256": sha256_path(destination),
        "bytes": destination.stat().st_size,
        "width": metadata["width"],
        "height": metadata["height"],
        "source": source_id,
        "method": method,
        "status": status,
        "provenance": str(provenance or "unattributed"),
        "review": dict(review or {}),
        "nonzero_bounds": metadata["nonzero_bounds"],
        "bbox_fill_ratio": metadata["bbox_fill_ratio"],
    }
    if bounds is not None:
        record["declared_bounds"] = parse_rect(bounds, name=f"mask {mask_id} bounds")
    if forbidden_mask_id:
        record["forbidden_mask"] = str(forbidden_mask_id)
    project.setdefault("masks", {})[mask_id] = record
    return record


def _parse_points(value: Any, *, name: str = "points") -> list[tuple[int, int]]:
    if isinstance(value, str):
        raw_points = [piece.strip() for piece in value.split(";") if piece.strip()]
        points: list[tuple[int, int]] = []
        for raw_point in raw_points:
            pieces = [piece.strip() for piece in raw_point.split(",")]
            if len(pieces) != 2:
                raise AssetHarnessError("INVALID_POINTS", f"{name} points must be x,y pairs separated by semicolons")
            try:
                points.append((int(pieces[0]), int(pieces[1])))
            except (TypeError, ValueError) as error:
                raise AssetHarnessError("INVALID_POINTS", f"{name} contains a non-integer point") from error
        value = points
    if not isinstance(value, (list, tuple)) or len(value) < 3:
        raise AssetHarnessError("INVALID_POINTS", f"{name} requires at least three points")
    points = []
    for point in value:
        if not isinstance(point, (list, tuple)) or len(point) != 2:
            raise AssetHarnessError("INVALID_POINTS", f"{name} contains an invalid point")
        try:
            points.append((int(point[0]), int(point[1])))
        except (TypeError, ValueError) as error:
            raise AssetHarnessError("INVALID_POINTS", f"{name} contains a non-integer point") from error
    return points


def write_polygon_mask(
    project_path: Path,
    project: dict[str, Any],
    mask_id: str,
    source_id: str,
    points: Any,
    *,
    status: str = "proposed",
    provenance: str = "manual polygon; pending visual review",
    forbidden_mask_id: str | None = None,
) -> dict[str, Any]:
    """Create a source-canvas polygon mask without promoting its review status."""

    source = (project.get("sources") or {}).get(source_id)
    if not isinstance(source, dict):
        raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"source is not registered: {source_id}")
    workspace = project_workspace(project_path, project)
    source_value = str(source.get("path") or "")
    source_path = resolve_reference(
        workspace,
        source_value,
        allow_external=Path(source_value).is_absolute(),
        must_exist=True,
    )
    source_image = load_rgba(source_path)
    parsed = _parse_points(points)
    if any(x < 0 or y < 0 or x >= source_image.width or y >= source_image.height for x, y in parsed):
        raise AssetHarnessError("MASK_POINT_OUT_OF_BOUNDS", "manual polygon point is outside the source canvas")
    mask = Image.new("L", source_image.size, 0)
    ImageDraw.Draw(mask).polygon(parsed, fill=255)
    destination = _mask_workspace_path(project_path, project, mask_id)
    buffer = BytesIO()
    mask.save(buffer, format="PNG", optimize=False, compress_level=9)
    encoded = buffer.getvalue()
    if destination.exists() and destination.read_bytes() != encoded:
        raise AssetHarnessError("MASK_CONFLICT", f"mask already exists with different bytes: {destination}")
    if not destination.exists():
        atomic_write_bytes(destination, encoded)
    return register_mask(
        project_path,
        project,
        mask_id,
        str(destination),
        source_id=source_id,
        method="manual_polygon",
        status=status,
        provenance=provenance,
        forbidden_mask_id=forbidden_mask_id,
    )


def resolve_project_mask(project_path: Path, project: dict[str, Any], mask_id: str) -> tuple[dict[str, Any], Image.Image, Path]:
    record = (project.get("masks") or {}).get(mask_id)
    if not isinstance(record, dict):
        raise AssetHarnessError("MASK_NOT_REGISTERED", f"mask is not registered: {mask_id}")
    workspace = project_workspace(project_path, project)
    path_value = str(record.get("path") or "")
    path = resolve_reference(workspace, path_value, allow_external=Path(path_value).is_absolute(), must_exist=True)
    mask = load_mask(path)
    return record, mask, path


def _overlap_count(left: Image.Image, right: Image.Image) -> int:
    if left.size != right.size:
        raise AssetHarnessError("MASK_SIZE_MISMATCH", "masks used for overlap checks must have identical dimensions")
    overlap = ImageChops.multiply(left, right)
    return sum(1 for value in overlap.getdata() if int(value) > 0)


def validate_mask(
    project_path: Path,
    project: dict[str, Any],
    mask_id: str,
    *,
    production: bool = False,
    required_size: tuple[int, int] | None = None,
    allowed_bounds: Sequence[int] | None = None,
) -> dict[str, Any]:
    diagnostics: list[dict[str, Any]] = []
    checks = 0
    passed = 0
    record, mask, path = resolve_project_mask(project_path, project, mask_id)

    def check(condition: bool, code: str, message: str, **kwargs: Any) -> None:
        nonlocal checks, passed
        checks += 1
        if condition:
            passed += 1
        else:
            diagnostics.append(diagnostic(code, message, asset=mask_id, path=str(path), **kwargs))

    check(mask.width > 0 and mask.height > 0, "MASK_EMPTY_CANVAS", "mask canvas must be non-empty")
    if required_size is not None:
        check(mask.size == tuple(required_size), "MASK_CANVAS_MISMATCH", "mask dimensions must match the source canvas")
    bbox = mask.getbbox()
    check(bbox is not None, "MASK_EMPTY", "mask selects no pixels", remediation="author a visible component silhouette")
    if allowed_bounds is not None and bbox is not None:
        allowed = parse_rect(allowed_bounds, name=f"mask {mask_id} allowed bounds")
        check(
            bbox[0] >= allowed[0]
            and bbox[1] >= allowed[1]
            and bbox[2] <= allowed[0] + allowed[2]
            and bbox[3] <= allowed[1] + allowed[3],
            "MASK_OUT_OF_BOUNDS",
            "mask selects pixels outside the declared component bounds",
            rect=[bbox[0], bbox[1], bbox[2], bbox[3]],
            remediation="tighten the hand-authored mask or correct the measured source bounds",
        )
    declared = record.get("declared_bounds")
    if declared is not None and bbox is not None:
        declared_rect = parse_rect(declared, name=f"mask {mask_id} declared bounds")
        check(
            bbox[0] >= declared_rect[0]
            and bbox[1] >= declared_rect[1]
            and bbox[2] <= declared_rect[0] + declared_rect[2]
            and bbox[3] <= declared_rect[1] + declared_rect[3],
            "MASK_DECLARED_BOUNDS_VIOLATION",
            "mask selects pixels outside its declared bounds",
            rect=[bbox[0], bbox[1], bbox[2], bbox[3]],
        )
    method = str(record.get("method") or "")
    check(method in MASK_METHODS, "MASK_METHOD_INVALID", "mask method is not recognised")
    if production or str(record.get("status")) == "verified":
        check(
            method != "rectangle",
            "MASK_RECTANGULAR_APPROXIMATION",
            "rectangular crop masks cannot be production-ready",
            remediation="import a hand-authored alpha, polygon, or path mask that follows the actual silhouette",
        )
        check(
            str(record.get("status")) == "verified",
            "MASK_NOT_VISUALLY_VERIFIED",
            "production mask requires an explicit visual-review status",
            remediation="inspect the mask preview at full resolution and record reviewer evidence",
        )
        review = record.get("review") if isinstance(record.get("review"), dict) else {}
        check(
            bool(review.get("reviewed")),
            "MASK_REVIEW_EVIDENCE_MISSING",
            "verified mask requires explicit visual-review evidence",
            remediation="record reviewer identity and the full-resolution preview/contact-sheet artifact",
        )
    forbidden_id = record.get("forbidden_mask")
    if forbidden_id:
        _, forbidden, forbidden_path = resolve_project_mask(project_path, project, str(forbidden_id))
        overlap = _overlap_count(mask, forbidden)
        check(
            overlap == 0,
            "MASK_NEIGHBOR_CONTAMINATION",
            f"mask overlaps forbidden neighbor pixels ({overlap} pixels)",
            remediation=f"remove neighboring pixels from the mask; guard={forbidden_path}",
        )
    source_id = record.get("source")
    if source_id:
        source = (project.get("sources") or {}).get(str(source_id))
        if isinstance(source, dict):
            source_path = str(source.get("path") or "")
            resolved_source = resolve_reference(
                project_workspace(project_path, project),
                source_path,
                allow_external=Path(source_path).is_absolute(),
                must_exist=True,
            )
            source_image = load_rgba(resolved_source)
            check(
                mask.size == source_image.size,
                "MASK_SOURCE_CANVAS_MISMATCH",
                "source-space mask must match the registered source canvas",
                remediation="author masks in integer source-canvas coordinates",
            )
            if mask.size == source_image.size:
                source_alpha = source_image.getchannel("A")
                # Antialiased source edges are legitimate artwork.  The
                # contamination gate must reject only truly empty source
                # pixels, not every alpha value below 255.
                empty_source = source_alpha.point(lambda value: 255 if int(value) == 0 else 0)
                covered_transparent = _overlap_count(mask, empty_source)
                check(
                    covered_transparent == 0,
                    "MASK_SELECTS_TRANSPARENT_SOURCE",
                    f"mask selects {covered_transparent} transparent/empty source pixels",
                    remediation="separate the component from the transparent exterior and document any reconstruction area",
                )
    errors = [item for item in diagnostics if item.get("severity") == "error"]
    return {
        "ok": not errors,
        "mask_id": mask_id,
        "summary": {"checks": checks, "passed": passed, "failed": len(errors)},
        "diagnostics": diagnostics,
    }


def masked_image(source: Image.Image, mask: Image.Image) -> Image.Image:
    rgba = source.convert("RGBA")
    alpha = ImageChops.multiply(rgba.getchannel("A"), mask.convert("L"))
    result = rgba.copy()
    result.putalpha(alpha)
    return result


def mask_preview(source: Image.Image, mask: Image.Image, *, color: str = "#ff2abf", opacity: int = 120) -> Image.Image:
    rgba = source.convert("RGBA").copy()
    selection = mask.convert("L")
    tint = Image.new("RGBA", rgba.size, (*ImageColor.getrgb(color), max(0, min(255, int(opacity)))))
    rgba.alpha_composite(Image.composite(tint, Image.new("RGBA", rgba.size), selection))
    return rgba


def write_masked_extract(source: Image.Image, mask: Image.Image, output: Path) -> Path:
    result = masked_image(source, mask)
    output = Path(output).expanduser().resolve()
    buffer = BytesIO()
    result.save(buffer, format="PNG", optimize=False, compress_level=9)
    atomic_write_bytes(output, buffer.getvalue())
    return output


def mask_artifact(path: Path, kind: str) -> dict[str, Any]:
    return artifact_descriptor(path, kind)
