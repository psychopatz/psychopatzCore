"""Canonical project-backed radio device registry.

The pilot JSON files are the simulator's authored device definitions.  This
module owns discovery of those definitions so GUI and CLI entry points resolve
the same project before constructing the shared :class:`RadioSimulator`.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1] / "projects" / "radio"


@dataclass(frozen=True)
class RadioProjectRef:
    """Stable reference to one authored pilot project."""

    device_id: str
    label: str
    family: str
    full_type: str
    path: Path


def _project_ref(path: Path) -> RadioProjectRef:
    """Read only the identity fields needed to populate a device selector."""

    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"radio project must be an object: {path}")
    device = value.get("device") or {}
    if not isinstance(device, dict):
        raise ValueError(f"radio project device must be an object: {path}")
    device_id = str(device.get("id") or value.get("project_id") or path.stem.removesuffix("_pilot"))
    return RadioProjectRef(
        device_id=device_id,
        label=device_id,
        family=str(device.get("family") or "radio"),
        full_type=str(device.get("fullType") or device.get("model") or ""),
        path=path.resolve(),
    )


def list_project_refs() -> tuple[RadioProjectRef, ...]:
    """Return all authored pilot projects in deterministic device order."""

    if not PROJECT_ROOT.is_dir():
        return ()
    return tuple(_project_ref(path) for path in sorted(PROJECT_ROOT.glob("*_pilot.json")))


def project_path_for_device(device_id: str) -> Path | None:
    """Return the canonical pilot project for ``device_id`` when available."""

    normalized = str(device_id).strip()
    for project in list_project_refs():
        if project.device_id == normalized:
            return project.path
    return None
