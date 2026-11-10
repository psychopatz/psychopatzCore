"""Bounded visible conversation history for the interactive harness."""

from __future__ import annotations

from collections import deque

_TRUNCATION_MARKER = "\n… transcript entry truncated …"


class TranscriptBuffer:
    """Keep a recent, character-bounded transcript without retaining worker objects."""

    def __init__(
        self,
        *,
        max_entries: int = 200,
        max_chars: int = 200_000,
        max_entry_chars: int = 8192,
    ) -> None:
        if max_entries <= 0 or max_chars <= 0 or max_entry_chars <= 0:
            raise ValueError("transcript limits must be positive")
        if max_entry_chars < len(_TRUNCATION_MARKER) + 2:
            raise ValueError("max_entry_chars is too small for the truncation marker")
        if max_entry_chars > max_chars:
            raise ValueError("max_entry_chars cannot exceed max_chars")
        self.max_entries = max_entries
        self.max_chars = max_chars
        self.max_entry_chars = max_entry_chars
        self._entries: deque[str] = deque()
        self._char_count = 0

    @property
    def entry_count(self) -> int:
        return len(self._entries)

    @property
    def char_count(self) -> int:
        return self._char_count

    def append(self, speaker: str, text: str) -> tuple[str, int]:
        prefix = f"{speaker}: "
        body = str(text)
        entry = f"{prefix}{body}\n\n"
        if len(entry) > self.max_entry_chars:
            suffix_size = len(_TRUNCATION_MARKER) + 2
            prefix_size = max(0, self.max_entry_chars - suffix_size)
            prefix = prefix[:prefix_size]
            body_size = max(0, self.max_entry_chars - len(prefix) - suffix_size)
            entry = f"{prefix}{body[:body_size]}{_TRUNCATION_MARKER}\n\n"

        self._entries.append(entry)
        self._char_count += len(entry)
        removed_chars = 0
        while len(self._entries) > self.max_entries or self._char_count > self.max_chars:
            removed = self._entries.popleft()
            removed_size = len(removed)
            self._char_count -= removed_size
            removed_chars += removed_size
        return entry, removed_chars

    def clear(self) -> None:
        self._entries.clear()
        self._char_count = 0
