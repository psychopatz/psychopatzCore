"""Read-only save-backed actor, faction, and community browser."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .state_providers import SemanticStateCatalog, StateProviderError


class SaveBrowserError(ValueError):
    """A save cannot be projected into the bounded world browser."""


def _display_group_label(row: dict[str, Any], kind: str) -> tuple[str, str]:
    """Return a readable label while preserving missing source truth."""

    group_id = str(row.get("id") or row.get(f"{kind}ID") or "").strip()
    label = str(row.get("label") or row.get("name") or "").strip()
    if label and label != group_id:
        return label, "SAVE"
    if not group_id:
        return f"{kind.title()} (unnamed)", "MISSING"
    suffix = group_id.rsplit("_", 1)[-1]
    return f"{kind.title()} · {suffix}", "DERIVED"


def _group_labels(rows: list[dict[str, Any]], kind: str) -> dict[str, dict[str, str]]:
    labels: dict[str, dict[str, str]] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        group_id = str(row.get("id") or row.get(f"{kind}ID") or "").strip()
        if not group_id:
            continue
        label, label_source = _display_group_label(row, kind)
        labels[group_id] = {"label": label, "labelSource": label_source}
    return labels


@dataclass(frozen=True)
class SavedWorldBrowser:
    """Project persisted world actors without mutating or materializing PZ."""

    core_repository: Path

    def __post_init__(self) -> None:
        object.__setattr__(self, "core_repository", Path(self.core_repository))

    def browse(self, save_path: Path) -> dict[str, Any]:
        save_path = Path(save_path).expanduser().resolve()
        try:
            state_catalog = SemanticStateCatalog(
                core_repository=self.core_repository,
            ).load(save_path)
        except StateProviderError as error:
            raise SaveBrowserError(str(error)) from error
        providers = state_catalog["providers"]
        hoomans = providers["projecthoomans"]["projection"]
        trading = providers["dynamictrading"]["projection"]
        actors = deepcopy(hoomans.get("actors") or [])
        factions = deepcopy(hoomans.get("factions") or [])
        communities = deepcopy(hoomans.get("communities") or [])
        faction_labels = _group_labels(factions, "faction")
        community_labels = _group_labels(communities, "community")
        provider_rows = {
            str(row.get("id")): row
            for row in trading.get("knownActors") or []
            if isinstance(row, dict)
        }
        for actor in actors:
            provider_row = provider_rows.get(str(actor.get("id")))
            actor["isTrader"] = provider_row is not None
            faction = faction_labels.get(str(actor.get("factionID")))
            community = community_labels.get(str(actor.get("communityID")))
            if faction is not None:
                actor["factionLabel"] = faction["label"]
                actor["factionLabelSource"] = faction["labelSource"]
            if community is not None:
                actor["communityLabel"] = community["label"]
                actor["communityLabelSource"] = community["labelSource"]
            if provider_row is not None:
                actor["provider"] = provider_row.get("provider")

        categories: dict[str, list[dict[str, Any]]] = {
            "All NPCs": actors,
            "Companions": [actor for actor in actors if actor["isFollower"]],
            "Colonists": [
                actor
                for actor in actors
                if actor.get("factionID") or actor.get("communityID")
            ],
            "Followers": [actor for actor in actors if actor["isFollower"]],
            "Neutral NPCs": [
                actor for actor in actors if not actor["isHostile"]
            ],
            "Hostile NPCs": [actor for actor in actors if actor["isHostile"]],
            "Known Traders": [actor for actor in actors if actor["isTrader"]],
        }
        if not communities:
            derived: dict[str, dict[str, Any]] = {}
            for actor in actors:
                community_id = actor.get("communityID")
                if not community_id:
                    continue
                row = derived.setdefault(
                    str(community_id),
                    {
                        "id": str(community_id),
                        "label": _display_group_label(
                            {"id": str(community_id)}, "community"
                        )[0],
                        "labelSource": "DERIVED",
                        "memberIDs": [],
                        "source": "DERIVED",
                        "baseSource": "SAVE",
                    },
                )
                row["memberIDs"].append(actor["id"])
            for row in derived.values():
                row["memberIDs"] = sorted(set(row["memberIDs"]))
            communities = sorted(derived.values(), key=lambda item: item["id"])
            community_labels = _group_labels(communities, "community")
            for actor in actors:
                community = community_labels.get(str(actor.get("communityID")))
                if community is not None:
                    actor["communityLabel"] = community["label"]
                    actor["communityLabelSource"] = community["labelSource"]
        world_hierarchy = _build_world_hierarchy(
            actors=actors,
            factions=hoomans.get("factions") or [],
            communities=communities,
            provider_actors=trading.get("knownActors") or [],
        )
        raw = state_catalog["raw"]

        return {
            "schema": "semantic.save_browser.v1",
            "schemaVersion": 1,
            "source": "SAVE",
            "sourceID": raw["sourceID"],
            "savePath": str(save_path),
            "saveName": raw["saveName"],
            "worldVersion": raw["worldVersion"],
            "providers": providers,
            "players": hoomans.get("players") or [],
            "categories": categories,
            "factions": factions,
            "communities": communities,
            "providerActors": trading.get("knownActors") or [],
            "worldHierarchy": world_hierarchy,
            "counts": {
                "players": len(hoomans.get("players") or []),
                "npcs": len(actors),
                "factions": len(hoomans.get("factions") or []),
                "communities": len(communities),
                "providerActors": len(trading.get("knownActors") or []),
            },
        }


def _actor_reference(actor: dict[str, Any], provider_row: dict[str, Any] | None) -> dict[str, Any]:
    """Return a bounded actor reference for hierarchy rendering.

    The full actor projections remain available in ``categories``.  Hierarchy
    rows deliberately contain only the persisted identity/group fields needed
    by a browser so a large save is not duplicated once per group.
    """

    reference = {
        "id": actor.get("id"),
        "label": actor.get("label") or actor.get("id"),
        "factionID": actor.get("factionID"),
        "factionLabel": actor.get("factionLabel"),
        "communityID": actor.get("communityID"),
        "communityLabel": actor.get("communityLabel"),
        "role": actor.get("role"),
        "isFollower": actor.get("isFollower") is True,
        "isHostile": actor.get("isHostile") is True,
        "isTrader": provider_row is not None,
        "source": actor.get("source") or "SAVE",
    }
    if provider_row is not None:
        reference["provider"] = provider_row.get("provider")
    return reference


def _member_ids(value: Any) -> list[str]:
    """Normalize persisted member collections without inventing membership."""

    if isinstance(value, dict):
        return sorted({str(key) for key, present in value.items() if present is not False})
    if isinstance(value, (list, tuple, set)):
        return sorted({str(item) for item in value if item is not None})
    return []


def _build_world_hierarchy(
    *,
    actors: list[dict[str, Any]],
    factions: list[dict[str, Any]],
    communities: list[dict[str, Any]],
    provider_actors: list[dict[str, Any]],
) -> dict[str, Any]:
    """Project persisted groups plus explicit actor overlays for Tk.

    Group membership is taken from persisted ``memberIDs`` when available.
    The actor affiliation projection is used only as a bounded fallback for a
    persisted group whose member list is absent, and is marked ``DERIVED``.
    Tk consumes this projection and never infers ownership from labels.
    """

    actors_by_id = {
        str(actor.get("id")): actor
        for actor in actors
        if isinstance(actor, dict) and actor.get("id")
    }
    provider_by_id = {
        str(row.get("id")): row
        for row in provider_actors
        if isinstance(row, dict) and row.get("id")
    }
    groups: list[dict[str, Any]] = []

    def add_persisted_groups(rows: list[dict[str, Any]], kind: str) -> None:
        for row in rows:
            if not isinstance(row, dict):
                continue
            group_id = str(row.get("id") or row.get(f"{kind}ID") or "")
            if not group_id:
                continue
            member_ids = _member_ids(row.get("memberIDs"))
            membership_source = str(row.get("source") or "SAVE")
            if not member_ids:
                affiliation_key = "factionID" if kind == "faction" else "communityID"
                member_ids = sorted(
                    actor_id
                    for actor_id, actor in actors_by_id.items()
                    if actor.get(affiliation_key) == group_id
                )
                if member_ids:
                    membership_source = "DERIVED"
            members = [
                _actor_reference(actors_by_id[actor_id], provider_by_id.get(actor_id))
                for actor_id in member_ids
                if actor_id in actors_by_id
            ]
            groups.append(
                {
                    "id": f"{kind}:{group_id}",
                    "kind": kind,
                    "label": _display_group_label(row, kind)[0],
                    "labelSource": _display_group_label(row, kind)[1],
                    "source": row.get("source") or "SAVE",
                    "membershipSource": membership_source,
                    "group": deepcopy(row),
                    "memberIDs": [member["id"] for member in members],
                    "members": members,
                }
            )

    add_persisted_groups(factions, "faction")
    add_persisted_groups(communities, "community")

    def add_overlay(
        group_id: str,
        kind: str,
        label: str,
        rows: list[dict[str, Any]],
        *,
        include_empty: bool = False,
    ) -> None:
        members = [
            _actor_reference(actor, provider_by_id.get(str(actor.get("id"))))
            for actor in rows
            if isinstance(actor, dict) and actor.get("id")
        ]
        if members or include_empty:
            groups.append(
                {
                    "id": group_id,
                    "kind": kind,
                    "label": label,
                    "source": "DERIVED",
                    "membershipSource": "DERIVED",
                    "memberIDs": [member["id"] for member in members],
                    "members": members,
                }
            )

    faction_or_community = {
        str(actor.get("id"))
        for actor in actors
        if actor.get("factionID") or actor.get("communityID")
    }
    add_overlay(
        "unaffiliated",
        "overlay",
        "Unaffiliated",
        [
            actor
            for actor in actors
            if actor.get("id") not in faction_or_community
            and not actor.get("isHostile")
        ],
    )
    add_overlay(
        "hostile",
        "overlay",
        "Hostile",
        [actor for actor in actors if actor.get("isHostile")],
    )
    add_overlay(
        "traders",
        "provider_overlay",
        "Known Traders",
        [actor for actor in actors if str(actor.get("id")) in provider_by_id],
        include_empty=True,
    )
    return {"schema": "semantic.save_world_hierarchy.v1", "groups": groups}


__all__ = ["SaveBrowserError", "SavedWorldBrowser"]
