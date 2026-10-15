"""Conservative path and rectangle helpers shared by all commands."""

from __future__ import annotations

import os
from pathlib import Path
import tempfile
from typing import Any, Sequence

from .errors import AssetHarnessError


MAX_PIXELS = 64 * 1024 * 1024
MAX_SOURCE_BYTES = 256 * 1024 * 1024


def ensure_within(root: Path, target: Path, *, code: str = "PATH_UNSAFE") -> Path:
    root_resolved = root.expanduser().resolve()
    target_resolved = target.expanduser().resolve()
    try:
        target_resolved.relative_to(root_resolved)
    except ValueError as error:
        raise AssetHarnessError(
            code,
            f"path escapes the allowed root: {target_resolved}",
            diagnostics=[{
                "code": code,
                "severity": "error",
                "path": str(target_resolved),
                "message": f"expected a path below {root_resolved}",
            }],
        ) from error
    return target_resolved


def resolve_reference(
    root: Path,
    value: str | os.PathLike[str],
    *,
    allow_external: bool = False,
    must_exist: bool = False,
) -> Path:
    candidate = Path(value).expanduser()
    if not candidate.is_absolute():
        candidate = root / candidate
    resolved = candidate.resolve()
    if not allow_external:
        resolved = ensure_within(root, resolved)
    if must_exist and not resolved.exists():
        raise AssetHarnessError(
            "FILE_NOT_FOUND",
            f"file does not exist: {resolved}",
            diagnostics=[{
                "code": "FILE_NOT_FOUND",
                "severity": "error",
                "path": str(resolved),
                "message": "the referenced file was not found",
            }],
        )
    return resolved


def relative_reference(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def atomic_write_bytes(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent, prefix=f".{path.name}.", suffix=".tmp", delete=False
        ) as handle:
            temporary = Path(handle.name)
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink(missing_ok=True)


def atomic_write_text(path: Path, content: str) -> None:
    atomic_write_bytes(path, content.encode("utf-8"))


def parse_rect(value: Any, *, name: str = "rect") -> list[int]:
    if isinstance(value, str):
        pieces = [piece.strip() for piece in value.split(",")]
    elif isinstance(value, (list, tuple)):
        pieces = list(value)
    elif isinstance(value, dict):
        pieces = [value.get(key) for key in ("x", "y", "w", "h")]
    else:
        pieces = []
    if len(pieces) != 4:
        raise AssetHarnessError(
            "INVALID_RECT",
            f"{name} must contain x,y,w,h",
            diagnostics=[{
                "code": "INVALID_RECT",
                "severity": "error",
                "message": f"expected four integer values for {name}",
            }],
        )
    try:
        rect = [int(piece) for piece in pieces]
    except (TypeError, ValueError) as error:
        raise AssetHarnessError("INVALID_RECT", f"{name} contains a non-integer") from error
    if rect[2] <= 0 or rect[3] <= 0:
        raise AssetHarnessError("INVALID_RECT", f"{name} width and height must be positive")
    return rect


def rect_dict(rect: Sequence[int]) -> dict[str, int]:
    x, y, w, h = [int(value) for value in rect]
    return {"x": x, "y": y, "w": w, "h": h}


def rect_inside(rect: Sequence[int], bounds: Sequence[int]) -> bool:
    x, y, w, h = rect
    bx, by, bw, bh = bounds
    return x >= bx and y >= by and x + w <= bx + bw and y + h <= by + bh


def rect_overlap(left: Sequence[int], right: Sequence[int]) -> bool:
    lx, ly, lw, lh = left
    rx, ry, rw, rh = right
    return lx < rx + rw and rx < lx + lw and ly < ry + rh and ry < ly + lh


def canvas_rect(data: dict[str, Any]) -> list[int]:
    canvas = data.get("canvas") or {}
    return [0, 0, int(canvas.get("width", 0)), int(canvas.get("height", 0))]
