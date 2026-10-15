"""Versioned, resumable project documents."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

from .errors import AssetHarnessError
from .paths import atomic_write_text
from .responses import canonical_json, revision_for


PROJECT_SCHEMA_VERSION = 1


def canonical_radio_device_path(family: str, model: str) -> str:
    """Return the canonical developer/runtime-relative radio asset path.

    Existing v1 projects may override ``export.device_path`` and continue to
    do so.  New projects default to the source-of-truth Radio hierarchy so a
    future reviewed export cannot accidentally target the superseded device
    tree.
    """

    family_directory = {
        "walkie": "WalkieTalkie",
        "ham": "Ham",
        "manpack": "ManPack",
    }.get(str(family), str(family))
    return f"Radio/{family_directory}/{model}"


def default_project(
    project_id: str,
    *,
    family: str = "walkie",
    model: str = "demo",
    width: int = 256,
    height: int = 432,
    full_type: str | None = None,
    workspace_root: str = ".",
) -> dict[str, Any]:
    return {
        "schema_version": PROJECT_SCHEMA_VERSION,
        "project_id": str(project_id),
        "device": {
            "family": str(family),
            "model": str(model),
            "fullType": full_type,
        },
        "canvas": {
            "width": int(width),
            "height": int(height),
            "origin": "top_left",
        },
        "workspace_root": workspace_root,
        "sources": {},
        "regions": {},
        "layers": [],
        "lcd": {},
        "controls": [],
        "animations": {},
        "variants": {"pristine": {"layers": []}},
        "masks": {},
        "modular": {
            "schema_version": 1,
            "status": "unconfigured",
            "chassis": {},
            "components": {},
            "verification": {"reviewed": False, "status": "incomplete", "reasons": []},
        },
        "export": {
            "runtime_root": "Contents/mods/PsychopatzCore/common/media/ui",
            "device_path": canonical_radio_device_path(family, model),
            "textures": [{
                "name": "shell_front",
                "filename": "shell_front.png",
                "variant": "pristine",
                "kind": "shell",
            }],
            "manifest_filename": "skin.lua",
        },
    }


def load_project(path: Path) -> dict[str, Any]:
    target = Path(path).expanduser().resolve()
    try:
        value = json.loads(target.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise AssetHarnessError("PROJECT_NOT_FOUND", f"project not found: {target}") from error
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise AssetHarnessError("PROJECT_UNREADABLE", f"project is unreadable: {target}") from error
    if not isinstance(value, dict):
        raise AssetHarnessError("PROJECT_INVALID", "project root must be a JSON object")
    if int(value.get("schema_version", 0)) != PROJECT_SCHEMA_VERSION:
        raise AssetHarnessError(
            "PROJECT_VERSION_UNSUPPORTED",
            f"unsupported project schema: {value.get('schema_version')}",
        )
    for key, default in (
        ("sources", {}), ("regions", {}), ("layers", []), ("lcd", {}),
        ("controls", []), ("animations", {}), ("variants", {}), ("export", {}),
        ("masks", {}),
    ):
        if key not in value:
            value[key] = default
    if "modular" not in value or not isinstance(value.get("modular"), dict):
        value["modular"] = {
            "schema_version": 1,
            "status": "unconfigured",
            "chassis": {},
            "components": {},
            "verification": {"reviewed": False, "status": "incomplete", "reasons": []},
        }
    return value


def save_project(path: Path, value: Mapping[str, Any]) -> None:
    target = Path(path).expanduser().resolve()
    if not isinstance(value, Mapping):
        raise AssetHarnessError("PROJECT_INVALID", "project must be a JSON object")
    content = json.dumps(value, ensure_ascii=True, sort_keys=True, indent=2) + "\n"
    atomic_write_text(target, content)


def project_revision(value: Mapping[str, Any]) -> str:
    return revision_for(value)


def project_id(value: Mapping[str, Any]) -> str:
    return str(value.get("project_id") or "unknown")


def project_workspace(project_path: Path, value: Mapping[str, Any]) -> Path:
    base = Path(project_path).expanduser().resolve().parent
    configured = value.get("workspace_root") or "."
    candidate = Path(str(configured))
    if not candidate.is_absolute():
        candidate = base / candidate
    return candidate.resolve()
