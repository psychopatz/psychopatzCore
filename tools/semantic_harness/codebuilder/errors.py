"""Provider-neutral CodeBuilder validation errors."""

from __future__ import annotations


class CompileError(ValueError):
    """Raised when a compiler input or generated artifact is invalid."""
