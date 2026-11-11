"""Small shared helpers for canonical Conversation authoring.

Conversation source loading, validation, editing, and generation live in the
manifest-backed compiler/service. This module intentionally contains no
standalone legacy source pipelines.
"""

from __future__ import annotations

import difflib
import hashlib
from pathlib import Path
from typing import Any

REPOSITORY = Path(__file__).resolve().parents[3]
MAX_ARTIFACT_DIFF_LINES = 96
MAX_ARTIFACT_DIFF_CHARS = 12_000


def _artifact_diff(
    repository: Path,
    relative_path: str,
    expected: str,
) -> dict[str, Any]:
    """Return one bounded effect-free diff against a generated artifact."""
    target = repository / relative_path
    current: str | None = None
    read_error: str | None = None
    try:
        if target.is_file():
            current = target.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        read_error = str(error)

    if read_error:
        status = "unreadable"
    elif current is None:
        status = "added"
    elif current == expected:
        status = "unchanged"
    else:
        status = "changed"

    diff_lines = list(difflib.unified_diff(
        (current or "").splitlines(keepends=True),
        expected.splitlines(keepends=True),
        fromfile=f"current/{relative_path}",
        tofile=f"preview/{relative_path}",
    ))
    diff_truncated = len(diff_lines) > MAX_ARTIFACT_DIFF_LINES
    diff = "".join(diff_lines[:MAX_ARTIFACT_DIFF_LINES])
    if len(diff) > MAX_ARTIFACT_DIFF_CHARS:
        diff = diff[:MAX_ARTIFACT_DIFF_CHARS]
        diff_truncated = True

    row: dict[str, Any] = {
        "path": relative_path,
        "status": status,
        "expectedChars": len(expected),
        "expectedSha256": hashlib.sha256(
            expected.encode("utf-8")
        ).hexdigest(),
        "currentChars": len(current) if current is not None else 0,
        "currentSha256": (
            hashlib.sha256(current.encode("utf-8")).hexdigest()
            if current is not None
            else None
        ),
        "diff": diff,
        "diffTruncated": diff_truncated,
    }
    if read_error:
        row["readError"] = read_error[:256]
    return row
