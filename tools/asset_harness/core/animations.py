"""Bounded deterministic animation timelines and contact sheets."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .errors import AssetHarnessError
from .render import contact_sheet, render_image, save_png


def timeline(project: dict[str, Any], name: str) -> list[dict[str, Any]]:
    raw = (project.get("animations") or {}).get(name)
    if isinstance(raw, dict):
        raw = raw.get("frames")
    if not isinstance(raw, list) or not raw:
        raise AssetHarnessError("ANIMATION_NOT_FOUND", f"animation is not defined or empty: {name}")
    result: list[dict[str, Any]] = []
    for index, frame in enumerate(raw):
        if isinstance(frame, str):
            frame = {"state": frame, "duration_ms": 100}
        if not isinstance(frame, dict):
            raise AssetHarnessError("ANIMATION_INVALID", f"frame {index} is not an object")
        duration = int(frame.get("duration_ms", frame.get("duration", 100)))
        if duration <= 0 or duration > 60 * 60 * 1000:
            raise AssetHarnessError("ANIMATION_INVALID", f"frame {index} has invalid duration")
        result.append({
            "state": frame.get("state"),
            "variant": str(frame.get("variant", "pristine")),
            "duration_ms": duration,
        })
    return result


def render_animation(
    project_path: Path,
    project: dict[str, Any],
    name: str,
    output: Path,
    *,
    scale: float = 1,
    columns: int = 4,
    content_color: Any = None,
    debug: bool = False,
) -> tuple[Path, list[Path], list[dict[str, Any]]]:
    frames = timeline(project, name)
    output = Path(output).expanduser().resolve()
    frame_dir = output.parent / f"{output.stem}_frames"
    frame_paths: list[Path] = []
    images = []
    metadata: list[dict[str, Any]] = []
    for index, frame in enumerate(frames):
        image, frame_metadata = render_image(
            project_path,
            project,
            state=frame.get("state"),
            variant=str(frame.get("variant", "pristine")),
            scale=scale,
            content_color=content_color,
            debug=debug,
        )
        frame_path = frame_dir / f"frame_{index:04d}.png"
        save_png(image, frame_path)
        frame_paths.append(frame_path)
        images.append(image)
        metadata.append({**frame_metadata, "index": index, "duration_ms": frame["duration_ms"]})
    sheet = contact_sheet(images, columns=columns)
    save_png(sheet, output)
    return output, frame_paths, metadata
