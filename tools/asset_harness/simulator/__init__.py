"""Offline, human/agent-operable radio simulator."""

from .catalog import DeviceGeometry, DeviceSpec
from .model import RadioSimulator
from .registry import RadioProjectRef, list_project_refs, project_path_for_device

__all__ = [
    "DeviceGeometry",
    "DeviceSpec",
    "RadioProjectRef",
    "RadioSimulator",
    "list_project_refs",
    "project_path_for_device",
]
