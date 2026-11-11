"""Project Hoomans profiler aliases over the Core read-only provider."""

from __future__ import annotations

from typing import Mapping

from tools.semantic_harness.core.live_profiler_provider import (
    DEFAULT_CONFIG_NAME,
    DEFAULT_SNAPSHOT_NAME,
    FORBIDDEN_OPERATIONS,
    LIVE_CATALOG_SCHEMA,
    LIVE_PROVIDER_SCHEMA,
    READ_ONLY_OPERATIONS,
    LiveProfilerProvider as _CoreLiveProfilerProvider,
)


_HOOMANS_SECTION_ALIASES: Mapping[str, tuple[str, ...]] = {
    "world": ("world", "worldState", "ProjectHoomans.world"),
    "player": ("player", "playerState", "ProjectHoomans.player"),
    "factions": ("factions", "factionState", "ProjectHoomans.factions"),
}


class LiveProfilerProvider(_CoreLiveProfilerProvider):
    """Bind Core's generic profiler projection to Hoomans namespaces."""

    def __init__(self, **kwargs: object) -> None:
        kwargs["section_aliases"] = _HOOMANS_SECTION_ALIASES
        super().__init__(**kwargs)


__all__ = [
    "DEFAULT_CONFIG_NAME",
    "DEFAULT_SNAPSHOT_NAME",
    "FORBIDDEN_OPERATIONS",
    "LIVE_CATALOG_SCHEMA",
    "LIVE_PROVIDER_SCHEMA",
    "LiveProfilerProvider",
    "READ_ONLY_OPERATIONS",
]
