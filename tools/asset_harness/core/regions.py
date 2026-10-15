"""Alpha-island proposals, manual rectangles, and lossless slices."""

from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Any

from PIL import Image

from .errors import AssetHarnessError
from .paths import MAX_PIXELS, parse_rect, rect_dict, resolve_reference
from .project import project_workspace
from .source import load_rgba


def connected_components(
    image: Image.Image,
    *,
    threshold: int = 1,
    min_area: int = 4,
    padding: int = 0,
    limit: int = 256,
) -> list[dict[str, Any]]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    if width * height > MAX_PIXELS:
        raise AssetHarnessError("IMAGE_TOO_LARGE", "connected-component scan exceeds pixel limit")
    threshold = max(0, min(255, int(threshold)))
    min_area = max(1, int(min_area))
    padding = max(0, int(padding))
    alpha = rgba.getchannel("A").load()
    visited = bytearray(width * height)
    proposals: list[dict[str, Any]] = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if visited[index] or int(alpha[x, y]) < threshold:
                continue
            visited[index] = 1
            queue = deque([(x, y)])
            area = 0
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                current_x, current_y = queue.popleft()
                area += 1
                min_x = min(min_x, current_x)
                max_x = max(max_x, current_x)
                min_y = min(min_y, current_y)
                max_y = max(max_y, current_y)
                for next_x, next_y in (
                    (current_x - 1, current_y), (current_x + 1, current_y),
                    (current_x, current_y - 1), (current_x, current_y + 1),
                ):
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    next_index = next_y * width + next_x
                    if visited[next_index] or int(alpha[next_x, next_y]) < threshold:
                        continue
                    visited[next_index] = 1
                    queue.append((next_x, next_y))
            if area < min_area:
                continue
            x0 = max(0, min_x - padding)
            y0 = max(0, min_y - padding)
            x1 = min(width, max_x + padding + 1)
            y1 = min(height, max_y + padding + 1)
            proposals.append({
                "rect": [x0, y0, x1 - x0, y1 - y0],
                "area": area,
                "status": "proposed",
                "method": "alpha_connected_component",
                "threshold": threshold,
            })
    proposals.sort(key=lambda item: (-int(item["area"]), item["rect"][1], item["rect"][0]))
    return proposals[: max(1, int(limit))]


def detect_source_regions(
    project_path: Path,
    project: dict[str, Any],
    source_id: str,
    *,
    threshold: int = 1,
    min_area: int = 4,
    padding: int = 0,
    limit: int = 64,
) -> list[dict[str, Any]]:
    source = (project.get("sources") or {}).get(source_id)
    if not isinstance(source, dict):
        raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"source is not registered: {source_id}")
    root = project_workspace(project_path, project)
    source_value = str(source.get("path", ""))
    source_path = resolve_reference(root, source_value, allow_external=Path(source_value).is_absolute(), must_exist=True)
    image = load_rgba(source_path)
    return connected_components(
        image, threshold=threshold, min_area=min_area, padding=padding, limit=limit
    )


def add_proposals(
    project: dict[str, Any],
    source_id: str,
    proposals: list[dict[str, Any]],
) -> list[str]:
    regions = project.setdefault("regions", {})
    added: list[str] = []
    for index, proposal in enumerate(proposals, start=1):
        region_id = f"{source_id}_candidate_{index:03d}"
        while region_id in regions:
            index += 1
            region_id = f"{source_id}_candidate_{index:03d}"
        regions[region_id] = {
            "source": source_id,
            "rect": list(proposal["rect"]),
            "purpose": "unknown",
            "status": "proposed",
            "method": proposal.get("method", "alpha_connected_component"),
            "area": int(proposal.get("area", 0)),
            "threshold": int(proposal.get("threshold", 1)),
        }
        added.append(region_id)
    return added


def set_region(
    project: dict[str, Any],
    region_id: str,
    source_id: str,
    rect: Any,
    *,
    purpose: str = "unknown",
    status: str = "verified",
    exclusive: bool = False,
) -> dict[str, Any]:
    if source_id not in (project.get("sources") or {}):
        raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"source is not registered: {source_id}")
    if status not in {"proposed", "verified", "rejected"}:
        raise AssetHarnessError("INVALID_REGION_STATUS", f"unsupported region status: {status}")
    parsed = parse_rect(rect)
    result = {
        "source": source_id,
        "rect": parsed,
        "purpose": str(purpose or "unknown"),
        "status": status,
        "method": "manual",
        "exclusive": bool(exclusive),
    }
    project.setdefault("regions", {})[region_id] = result
    return result


def slice_region(project_path: Path, project: dict[str, Any], region_id: str, output: Path) -> Path:
    region = (project.get("regions") or {}).get(region_id)
    if not isinstance(region, dict):
        raise AssetHarnessError("REGION_NOT_FOUND", f"region is not defined: {region_id}")
    source_id = str(region.get("source") or "")
    source = (project.get("sources") or {}).get(source_id)
    if not isinstance(source, dict):
        raise AssetHarnessError("SOURCE_NOT_REGISTERED", f"source is not registered: {source_id}")
    root = project_workspace(project_path, project)
    source_value = str(source.get("path", ""))
    source_path = resolve_reference(root, source_value, allow_external=Path(source_value).is_absolute(), must_exist=True)
    image = load_rgba(source_path)
    rect = parse_rect(region.get("rect"), name=f"region {region_id}")
    x, y, width, height = rect
    if x < 0 or y < 0 or x + width > image.width or y + height > image.height:
        raise AssetHarnessError("REGION_OUT_OF_BOUNDS", f"region is outside source: {region_id}")
    output = Path(output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    image.crop((x, y, x + width, y + height)).save(
        output, format="PNG", optimize=False, compress_level=9
    )
    return output
