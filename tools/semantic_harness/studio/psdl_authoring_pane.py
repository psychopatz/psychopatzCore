"""Compatibility wrapper exporting ConvoEngineAuthoringPane as PSDLAuthoringPane."""

from __future__ import annotations

from .convo_engine_authoring_pane import ConvoEngineAuthoringPane


class PSDLAuthoringPane(ConvoEngineAuthoringPane):
    """Deprecated compatibility alias; use ConvoEngineAuthoringPane."""


__all__ = ["PSDLAuthoringPane", "ConvoEngineAuthoringPane"]
