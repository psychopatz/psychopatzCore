"""Read-only source PNG inspection and project source registration."""

from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

from PIL import Image

from .errors import AssetHarnessError
from .paths import MAX_PIXELS, MAX_SOURCE_BYTES, atomic_write_bytes, ensure_within, resolve_reference, relative_reference
from .project import project_workspace
from .responses import sha256_path


def _bounds_from_alpha(alpha: Image.Image, predicate: str) -> list[int] | None:
    width, height = alpha.size
    pixels = alpha.load()
    min_x, min_y, max_x, max_y = width, height, -1, -1
    for y in range(height):
        for x in range(width):
            value = int(pixels[x, y])
            active = value > 0 if predicate == "nonzero" else value == 255
            if active:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < 0:
        return None
    return [min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]


def inspect_image(path: Path) -> dict[str, Any]:
    target = Path(path).expanduser().resolve()
    if not target.exists():
        raise AssetHarnessError("FILE_NOT_FOUND", f"image does not exist: {target}")
    if not target.is_file():
        raise AssetHarnessError("FILE_NOT_IMAGE", f"image path is not a file: {target}")
    if target.stat().st_size > MAX_SOURCE_BYTES:
        raise AssetHarnessError("IMAGE_TOO_LARGE", f"image exceeds byte limit: {target}")
    try:
        with Image.open(target) as image:
            width, height = image.size
            if width * height > MAX_PIXELS:
                raise AssetHarnessError("IMAGE_TOO_LARGE", f"image exceeds pixel limit: {target}")
            image.load()
            bands = image.getbands()
            rgba = image.convert("RGBA")
            alpha = rgba.getchannel("A")
            histogram = alpha.histogram()
            nonzero = sum(histogram[1:])
            opaque = histogram[255]
            transparent = histogram[0]
            return {
                "path": str(target),
                "sha256": sha256_path(target),
                "bytes": target.stat().st_size,
                "format": image.format,
                "width": width,
                "height": height,
                "mode": image.mode,
                "bands": list(bands),
                "has_alpha": "A" in bands,
                "alpha": {
                    "transparent_pixels": transparent,
                    "nonzero_pixels": nonzero,
                    "opaque_pixels": opaque,
                    "partial_pixels": max(0, nonzero - opaque),
                    "histogram": histogram,
                },
                "nonzero_bounds": _bounds_from_alpha(alpha, "nonzero"),
                "opaque_bounds": _bounds_from_alpha(alpha, "opaque"),
                "metadata_keys": sorted(str(key) for key in image.info),
            }
    except AssetHarnessError:
        raise
    except (OSError, UnicodeError, ValueError) as error:
        raise AssetHarnessError("IMAGE_UNREADABLE", f"cannot inspect image: {target}: {error}") from error


def load_rgba(path: Path) -> Image.Image:
    info = inspect_image(path)
    try:
        with Image.open(path) as image:
            return image.convert("RGBA").copy()
    except (OSError, ValueError) as error:
        raise AssetHarnessError("IMAGE_UNREADABLE", f"cannot load image: {info['path']}") from error


def register_source(
    project_path: Path,
    project: dict[str, Any],
    source_id: str,
    input_path: str,
    *,
    provenance: str | None = None,
    approved: bool = False,
    allow_external: bool = False,
) -> dict[str, Any]:
    if not source_id or any(character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for character in source_id):
        raise AssetHarnessError("INVALID_SOURCE_ID", f"invalid source ID: {source_id!r}")
    workspace = project_workspace(project_path, project)
    target = resolve_reference(workspace, input_path, allow_external=allow_external, must_exist=True)
    metadata = inspect_image(target)
    stored = {
        "path": relative_reference(target, workspace),
        "sha256": metadata["sha256"],
        "bytes": metadata["bytes"],
        "width": metadata["width"],
        "height": metadata["height"],
        "mode": metadata["mode"],
        "format": metadata["format"],
        "has_alpha": metadata["has_alpha"],
        "provenance": str(provenance or "unattributed"),
        "approved": bool(approved),
    }
    sources = project.setdefault("sources", {})
    sources[source_id] = stored
    return stored


def import_source(
    project_path: Path,
    project: dict[str, Any],
    source_id: str,
    input_path: str,
    *,
    provenance: str | None = None,
    approved: bool = False,
) -> dict[str, Any]:
    """Copy original source bytes into the project without recompression."""
    workspace = project_workspace(project_path, project)
    source_path = resolve_reference(workspace, input_path, allow_external=True, must_exist=True)
    metadata = inspect_image(source_path)
    if metadata.get("format") != "PNG":
        raise AssetHarnessError("IMAGE_FORMAT_UNSUPPORTED", "asset harness imports PNG sources only")
    destination = ensure_within(workspace, workspace / "sources" / f"{source_id}.png")
    original = source_path.read_bytes()
    if destination.exists() and destination.read_bytes() != original:
        raise AssetHarnessError("SOURCE_CONFLICT", f"project source already exists with different bytes: {destination}")
    if not destination.exists():
        atomic_write_bytes(destination, original)
    return register_source(
        project_path,
        project,
        source_id,
        relative_reference(destination, workspace),
        provenance=provenance,
        approved=approved,
        allow_external=False,
    )
