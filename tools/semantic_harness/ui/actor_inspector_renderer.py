"""Render the shared read-only player and NPC inspector family."""

from __future__ import annotations

from typing import Any

def refresh_actor_inspectors(self) -> None:
    """Refresh the shared read-only Player/NPC actor inspector family."""

    if not hasattr(self, "actor_inventory_views"):
        return
    source_snapshot = getattr(self, "source_snapshot_projection", {})
    metadata = source_snapshot.get("metadata", {}) if isinstance(source_snapshot, dict) else {}
    provider_payloads = (
        source_snapshot.get("providerPayloads", {})
        if isinstance(source_snapshot, dict)
        else {}
    )
    native_player = (
        provider_payloads.get("ProjectZomboid", {})
        if isinstance(provider_payloads, dict)
        else {}
    )
    for panel_name, actor_key in (("Player", "player"), ("NPC Target", "npc")):
        actor = self.scenario.get(actor_key, {})
        actor = actor if isinstance(actor, dict) else {}
        actor_source = self._actor_source_info(actor_key, "MISSING")
        needs_source = self._actor_source_info(f"{actor_key}.needs", "MISSING")
        traits_source = self._actor_source_info(f"{actor_key}.traits", "MISSING")
        personality_source = self._actor_source_info(
            f"{actor_key}.personality",
            "DERIVED" if actor_key == "npc" else "MISSING",
        )

        identity_lines = [
            f"Actor: {actor.get('displayName') or actor.get('npcID') or 'unknown'}",
            f"Source: {str(actor_source.get('source') or 'MISSING').upper()}",
        ]
        if actor_key == "player":
            for label, key in (
                ("technical character UUID", "characterUUID"),
                ("technical account key", "accountKey"),
                ("technical entity key", "entityKey"),
                ("gender", "gender"),
            ):
                if actor.get(key) not in (None, ""):
                    identity_lines.append(f"{label}: {actor.get(key)}")
            if isinstance(native_player, dict) and native_player.get("available"):
                identity_lines.append(
                    "native engine state: SAVE · "
                    f"world {native_player.get('worldVersion')} · "
                    f"local Player {native_player.get('localPlayerID')}"
                )
            elif isinstance(native_player, dict):
                identity_lines.append(
                    "native engine state: "
                    f"{str(native_player.get('source') or 'MISSING').upper()} · "
                    f"{native_player.get('reason') or 'unavailable'}"
                )
        else:
            selected_actor = self.saved_world_selected_actor
            selected_actor = (
                selected_actor
                if isinstance(selected_actor, dict)
                and selected_actor.get("id") == actor.get("npcID")
                else {}
            )
            faction_label = str(
                selected_actor.get("factionLabel")
                or actor.get("factionLabel")
                or "MISSING"
            )
            community_label = str(
                selected_actor.get("communityLabel")
                or actor.get("communityLabel")
                or "MISSING"
            )
            identity_lines.extend(
                [
                    f"Faction: {faction_label}",
                    f"Community: {community_label}",
                ]
            )
            for label, key in (
                ("technical NPC ID", "npcID"),
                ("tactical class", "tacticalClass"),
                ("technical faction ID", "factionID"),
                ("technical community ID", "communityID"),
                ("role", "role"),
                ("behavior", "activeBehavior"),
            ):
                if actor.get(key) not in (None, ""):
                    identity_lines.append(f"{label}: {actor.get(key)}")
            social = self.social_context_projection
            if isinstance(social, dict):
                identity_lines.extend(
                    [
                        "",
                        "Canonical social context",
                        *self._social_context_lines(social),
                    ]
                )
        identity_lines.append(
            f"source save: {metadata.get('sourceID') or 'developer/test fixture'}"
        )
        self._set_text(
            self.actor_overview_summaries[panel_name],
            "\n".join(identity_lines),
        )

        needs = actor.get("needs")
        needs = needs if isinstance(needs, dict) else {}
        need_lines = [
            f"Source: {str(needs_source.get('source') or 'MISSING').upper()}",
            " · ".join(
                f"{key}={needs.get(key, 'MISSING')}"
                for key in ("hunger", "thirst", "fatigue", "stress", "panic")
            )
            or "No persisted/offline need values available.",
        ]
        self._set_text(
            self.actor_needs_summaries[panel_name],
            "\n".join(need_lines),
        )

        traits = actor.get("traits")
        trait_text = (
            ", ".join(str(item) for item in traits[:32])
            if isinstance(traits, list) and traits
            else "none recorded"
        )
        personality = actor.get("personality") if actor_key == "npc" else actor.get("socialProfile")
        trait_lines = [
            f"Traits source: {str(traits_source.get('source') or 'MISSING').upper()}",
            f"traits: {trait_text}",
            f"Profile source: {str(personality_source.get('source') or 'MISSING').upper()}",
            f"personality/social profile: {', '.join(f'{key}={value}' for key, value in list(personality.items())[:8]) if isinstance(personality, dict) and personality else 'not recorded'}",
        ]
        self._set_text(
            self.actor_traits_summaries[panel_name],
            "\n".join(trait_lines),
        )

        self.actor_inventory_views[panel_name].update(
            actor.get("inventory"),
            self._actor_source_info(f"{actor_key}.inventory", "MISSING"),
        )
    if self.inventory_gift_workbench is not None:
        self.inventory_gift_workbench.update(
            self.scenario.get("player", {}).get("inventory"),
            self.scenario.get("npc", {}).get("inventory"),
            self._actor_source_info("player.inventory", "MISSING"),
            self._actor_source_info("npc.inventory", "MISSING"),
        )
    self._refresh_faction_context()
    self._refresh_simulation_context()
    self._refresh_social_context_summary()
    self._refresh_npc_dossier()
    self._refresh_npc_interaction_history()


__all__ = ["refresh_actor_inspectors"]
