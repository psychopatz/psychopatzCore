"""Bounded undo/redo state for the Semantic Lab Flow Editor."""

from __future__ import annotations

import copy
from typing import Any


class FlowEditorHistory:
    """Own immutable-in-practice flow snapshots and cursor movement."""

    def __init__(self) -> None:
        self._entries: list[dict[str, Any]] = []
        self._index = -1

    @property
    def index(self) -> int:
        return self._index

    def __len__(self) -> int:
        return len(self._entries)

    def reset(self, snapshot: dict[str, Any]) -> None:
        self._entries = [copy.deepcopy(snapshot)]
        self._index = 0

    def record(self, snapshot: dict[str, Any]) -> None:
        candidate = copy.deepcopy(snapshot)
        if self._index >= 0 and self._entries[self._index] == candidate:
            return
        self._entries = self._entries[: self._index + 1]
        self._entries.append(candidate)
        self._index = len(self._entries) - 1

    def append(self, snapshot: dict[str, Any]) -> None:
        self._entries = self._entries[: self._index + 1]
        self._entries.append(copy.deepcopy(snapshot))
        self._index = len(self._entries) - 1

    def snapshot(self, index: int) -> dict[str, Any] | None:
        if index < 0 or index >= len(self._entries):
            return None
        return copy.deepcopy(self._entries[index])

    def move_to(self, index: int) -> bool:
        if index < 0 or index >= len(self._entries):
            return False
        self._index = index
        return True
