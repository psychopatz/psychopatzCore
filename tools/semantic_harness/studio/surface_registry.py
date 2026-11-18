"""Registry of Semantic Lab Studio notebook surfaces and visibility gates."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any, Iterable, Mapping


@dataclass(frozen=True)
class SurfaceDescriptor:
    """Declarative metadata for one Studio authoring or inspection surface."""

    id: str
    title: str
    role: str
    default_visible: bool
    summary: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


STUDIO_SURFACES: tuple[SurfaceDescriptor, ...] = (
    SurfaceDescriptor(
        id="conversations",
        title="Conversations",
        role="primary",
        default_visible=True,
        summary="Canonical ConvoEngine exchange-family editor, action contracts, and production Lua trace.",
    ),
    SurfaceDescriptor(
        id="source_impact",
        title="Source / Impact",
        role="primary",
        default_visible=True,
        summary="Manifest-aware canonical file navigator, reference closure, and artifact impact.",
    ),
    SurfaceDescriptor(
        id="review",
        title="Review",
        role="primary",
        default_visible=True,
        summary="Reviewed proposals and explicit generation/validation summary.",
    ),
    SurfaceDescriptor(
        id="canonical_data_sources",
        title="Canonical Data Sources",
        role="developer",
        default_visible=False,
        summary="Canonical JSON source inspector and editor (ConvoEngine, NLU patterns, WordNet).",
    ),
    SurfaceDescriptor(
        id="interaction_explorer",
        title="Interaction Explorer",
        role="developer",
        default_visible=False,
        summary="Live Interaction Explorer and flow navigator.",
    ),
    SurfaceDescriptor(
        id="semantic_blocks",
        title="Semantic Blocks (Developer)",
        role="developer",
        default_visible=False,
        summary="Shared Core semantic block / registry inspector.",
    ),
)


class SurfaceRegistry:
    """Resolve Studio surface visibility without hardcoding pane-specific branches."""

    def __init__(self, surfaces: tuple[SurfaceDescriptor, ...] = STUDIO_SURFACES) -> None:
        self._surfaces = surfaces

    @staticmethod
    def has_active_legacy_datasets(dataset_sources: Iterable[Mapping[str, Any]] | None) -> bool:
        if not dataset_sources:
            return False
        for item in dataset_sources:
            if not item.get("exists"):
                continue
            if item.get("legacy") is True or item.get("kind") == "legacy_dialogue_content":
                return True
            if int(item.get("legacyRecords") or 0) > 0:
                return True
        return False

    def list_surfaces(
        self,
        *,
        include_legacy: bool = False,
        include_developer: bool = False,
        dataset_sources: Iterable[Mapping[str, Any]] | None = None,
    ) -> list[dict[str, Any]]:
        has_legacy = self.has_active_legacy_datasets(dataset_sources)
        visible: list[dict[str, Any]] = []
        for surface in self._surfaces:
            if surface.role == "primary":
                show = True
            elif surface.role == "legacy_compatibility":
                show = bool(include_legacy)
            elif surface.role == "developer":
                show = bool(include_developer or include_legacy)
            else:
                show = surface.default_visible
            entry = surface.to_dict()
            entry["visible"] = show
            entry["legacyDatasetsPresent"] = has_legacy
            visible.append(entry)
        return visible

    def primary_surface_ids(self) -> list[str]:
        return [item.id for item in self._surfaces if item.role == "primary"]


__all__ = [
    "STUDIO_SURFACES",
    "SurfaceDescriptor",
    "SurfaceRegistry",
]
