"""Project saved-world actors into player-relative relationship groups."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

RELATIONSHIP_CATEGORY_LABELS = (
    "Player faction / companions",
    "Settlers / communities",
    "Hostile / looters",
    "Traders / providers",
    "Neutral / unaffiliated",
    "Other faction members",
    "Unknown / unsupported",
)

def relationship_world_groups(self) -> list[dict[str, Any]]:
    """Return mutually exclusive, player-relative browser categories.

    This is a presentation lens over persisted provider projections. It
    never writes relationship, faction, hostility, or diplomacy state.
    """

    browser = self.saved_world_browser
    hierarchy = browser.get("worldHierarchy") or {}
    raw_groups = hierarchy.get("groups") if isinstance(hierarchy, dict) else []
    raw_groups = raw_groups if isinstance(raw_groups, list) else []
    faction_groups = {
        str(group.get("group", {}).get("id")): group
        for group in raw_groups
        if isinstance(group, dict)
        and group.get("kind") == "faction"
        and isinstance(group.get("group"), dict)
        and group.get("group", {}).get("id")
    }
    player = getattr(self, "saved_world_player_labels", {}).get(
        self.saved_world_player_var.get(), {}
    )
    player_key = str(player.get("entityKey") or "").strip()
    player_faction_ids: set[str] = set()
    for group in faction_groups.values():
        persisted = group.get("group") or {}
        if not player_key or not isinstance(persisted, dict):
            continue
        if str(persisted.get("ownerPlayerKey") or "") == player_key:
            player_faction_ids.add(str(persisted.get("id")))
            continue
        player_member_keys = persisted.get("playerMemberKeys")
        if isinstance(player_member_keys, dict) and player_member_keys.get(player_key):
            player_faction_ids.add(str(persisted.get("id")))

    all_actors = (browser.get("categories") or {}).get("All NPCs")
    if not isinstance(all_actors, list):
        all_actors = []
        seen: set[str] = set()
        for group in raw_groups:
            members = group.get("members") or [] if isinstance(group, dict) else []
            for actor in members:
                if not isinstance(actor, dict):
                    continue
                actor_id = str(actor.get("id") or "")
                if actor_id and actor_id not in seen:
                    seen.add(actor_id)
                    all_actors.append(deepcopy(actor))

    bucket_specs = [
        ("player", RELATIONSHIP_CATEGORY_LABELS[0], "relationship_companion"),
        ("settlers", RELATIONSHIP_CATEGORY_LABELS[1], "relationship_settler"),
        ("hostile", RELATIONSHIP_CATEGORY_LABELS[2], "relationship_hostile"),
        ("traders", RELATIONSHIP_CATEGORY_LABELS[3], "relationship_trader"),
        ("neutral", RELATIONSHIP_CATEGORY_LABELS[4], "relationship_neutral"),
        ("other", RELATIONSHIP_CATEGORY_LABELS[5], "relationship_other"),
        ("unknown", RELATIONSHIP_CATEGORY_LABELS[6], "relationship_unknown"),
    ]
    buckets: dict[str, dict[str, Any]] = {
        key: {
            "id": f"relationship:{key}",
            "kind": "relationship_category",
            "label": label,
            "source": "DERIVED",
            "membershipSource": "DERIVED",
            "relationshipTag": tag,
            "group": {
                "lens": "Relationship to Player",
                "category": label,
                "playerKey": player_key or "MISSING",
                "classificationSource": "SAVE provider facts + derived presentation lens",
            },
            "memberIDs": [],
            "members": [],
        }
        for key, label, tag in bucket_specs
    }

    for source_actor in all_actors:
        if not isinstance(source_actor, dict):
            continue
        actor = deepcopy(source_actor)
        actor_id = str(actor.get("id") or "").strip()
        faction_id = str(actor.get("factionID") or "").strip()
        community_id = str(actor.get("communityID") or "").strip()
        faction_group = faction_groups.get(faction_id, {})
        persisted_faction = faction_group.get("group") or {}
        archetype = str(
            persisted_faction.get("archetypeID")
            or actor.get("archetypeID")
            or ""
        ).casefold()
        hostile = actor.get("isHostile") is True or archetype in {
            "looter", "raider", "hostile",
        }
        trader = actor.get("isTrader") is True or archetype in {
            "trader", "provider",
        }
        companion = actor.get("isFollower") is True
        player_faction_member = faction_id in player_faction_ids
        if not actor_id or not actor.get("source"):
            bucket_key, badge, reason = (
                "unknown", "unknown", "actor identity/source is incomplete"
            )
        elif hostile:
            bucket_key, badge, reason = (
                "hostile", "hostile / looter", "SAVE hostility or faction archetype"
            )
        elif companion or player_faction_member:
            bucket_key = "player"
            badge = "companion" if companion else "player faction member"
            reason = "SAVE follower flag or selected Player faction membership"
        elif trader:
            bucket_key, badge, reason = (
                "traders", "trader / provider", "SAVE provider or faction archetype"
            )
        elif community_id or archetype in {"settler", "refugee", "community"}:
            bucket_key, badge, reason = (
                "settlers", "settler / community", "SAVE community or faction archetype"
            )
        elif faction_id:
            bucket_key, badge, reason = (
                "other", "other faction member", "SAVE faction membership"
            )
        elif not faction_id and not community_id:
            bucket_key, badge, reason = (
                "neutral", "neutral / unaffiliated", "SAVE has no faction or community"
            )
        else:
            bucket_key, badge, reason = (
                "unknown", "unknown", "persisted affiliation is unsupported"
            )

        actor["relationshipCategory"] = buckets[bucket_key]["label"]
        actor["relationshipBadge"] = badge
        actor["relationshipReason"] = reason
        actor["relationshipTag"] = buckets[bucket_key]["relationshipTag"]
        actor["affiliationLabel"] = str(
            actor.get("factionLabel")
            or actor.get("communityLabel")
            or "unaffiliated"
        )
        buckets[bucket_key]["members"].append(actor)
        if actor_id:
            buckets[bucket_key]["memberIDs"].append(actor_id)

    return [
        buckets[key]
        for key, _label, _tag in bucket_specs
        if buckets[key]["members"]
    ]


__all__ = ["RELATIONSHIP_CATEGORY_LABELS", "relationship_world_groups"]
