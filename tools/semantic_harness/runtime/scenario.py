"""Provider-neutral scenario document helpers used by Core tooling."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, Mapping

from ..scenario import deep_merge, load_json_document, save_json_document


DEFAULT_SCENARIO: dict[str, Any] = {
    "player": {},
    "npc": {},
    "world": {},
    "runtime": {"semanticDialogueEnabled": True},
}


def merge(*documents: Mapping[str, Any]) -> dict[str, Any]:
    """Deep-merge bounded scenario documents without mutating inputs."""

    result: dict[str, Any] = {}
    for document in documents:
        if not isinstance(document, Mapping):
            raise ValueError("scenario documents must be mappings")
        result = deep_merge(result, document)
    return result


def validate_scenario(scenario: Mapping[str, Any]) -> None:
    if not isinstance(scenario, Mapping):
        raise ValueError("scenario must be an object")


def load_scenario(path: str | Path) -> dict[str, Any]:
    document = load_json_document(path)
    validate_scenario(document)
    return document


def save_scenario(path: str | Path, scenario: Mapping[str, Any]) -> Path:
    validate_scenario(scenario)
    return save_json_document(path, scenario)


__all__ = [
    "DEFAULT_SCENARIO",
    "deep_merge",
    "load_scenario",
    "merge",
    "save_scenario",
    "validate_scenario",
]
