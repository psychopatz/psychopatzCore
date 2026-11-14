"""Componentized port container for Semantic Lab / Semantic Harness services."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .convo_catalog import ConvoCatalog
from .convo_transaction import ConvoTransaction
from .workspace_catalog import WorkspaceSnapshot


@dataclass
class HarnessContext:
    """Explicit six-port composition root owned by ``SemanticLabAuthoringService``."""

    workspace: WorkspaceSnapshot
    convo: ConvoCatalog
    transaction: ConvoTransaction
    runtime: Any = None
    build: Any = None
    audit: Any = None
    compat: Any = None


__all__ = ["HarnessContext"]
