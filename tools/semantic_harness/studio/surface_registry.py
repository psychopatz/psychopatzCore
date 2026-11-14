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
        id="dialogue_content",
        title="Dialogue Content (Legacy)",
        role="legacy_compatibility",
        default_visible=False,
        summary="Read-only/compatibility EN/TL view when legacy dataset shards exist.",
    ),
    SurfaceDescriptor(
        id="explore",
        title="Explore (Legacy)",
        role="legacy_compatibility",
        default_visible=False,
        summary="Legacy Semantic Lab definition explorer.",
    ),
    SurfaceDescriptor(
        id="dataset_library",
        title="Dataset Library (Legacy)",
        role="legacy_compatibility",
        default_visible=False,
        summary="Legacy dataset shard inspector (non-editable when shards are absent).",
    ),
    SurfaceDescriptor(
        id="interaction_specs",
        title="Interaction Specs (Developer)",
        role="developer",
        default_visible=False,
        summary="Developer compatibility surface for interaction spec templates.",
    ),
    SurfaceDescriptor(
        id="workflow",
        title="Workflow (Developer)",
        role="developer",
        default_visible=False,
        summary="Legacy multi-dataset batch generation trigger.",
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
        return any(bool(item.get("exists")) for item in dataset_sources)

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
