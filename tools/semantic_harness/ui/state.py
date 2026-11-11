"""Small, user-owned persistence for Semantic Lab window state."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
from typing import Any


def state_path(
    repository: Path,
    scenario: Path | None = None,
    explicit: str | Path | None = None,
) -> Path:
    if explicit:
        return Path(explicit).expanduser().resolve()
    state_root = Path(
        os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")
    )
    scenario_identity = (
        str(scenario.expanduser().resolve()) if scenario is not None else "<default>"
    )
    identity = f"{repository.resolve()}::{scenario_identity}"
    digest = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:16]
    return state_root / "project-hoomans" / f"semantic-lab-{digest}.json"


def load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return {}
    return value if isinstance(value, dict) else {}


def save(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(path)
