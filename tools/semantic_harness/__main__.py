"""Run Semantic Lab with ``python -m tools.semantic_harness``."""

from __future__ import annotations

from .entrypoints.app import main


if __name__ == "__main__":
    raise SystemExit(main())
