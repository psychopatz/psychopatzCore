"""Knowledge-domain operations for the semantic harness worker.

The Lua process and working-world projection remain owned by
``LuaSemanticWorker``.  This module owns only the command/query mapping for
knowledge, backstory, and commitment probes so the compatibility façade does
not become the home for every semantic domain.
"""

from __future__ import annotations

from typing import Any, Protocol


class _WorkerRequestHost(Protocol):
    def _request(self, command: str, value: Any = None) -> dict[str, Any]: ...


class WorkerKnowledgeOperations:
    """Issue bounded production knowledge and backstory operations."""

    def __init__(self, host: _WorkerRequestHost) -> None:
        self._host = host

    def knowledge_bootstrap(
        self, request_id: str = "harness-knowledge-bootstrap"
    ) -> dict[str, Any]:
        """Hydrate the real player-scoped Knowledge projection after reload."""

        return self._host._request(
            "KNOWLEDGE_BOOTSTRAP", {"requestID": str(request_id)}
        )

    def knowledge_metrics(
        self, synthetic_npcs: int = 0, facts_per_npc: int = 1
    ) -> dict[str, Any]:
        """Measure serialized production NPC and player Knowledge records."""

        return self._host._request(
            "KNOWLEDGE_METRICS",
            {
                "syntheticNPCs": int(synthetic_npcs),
                "factsPerNPC": int(facts_per_npc),
            },
        )

    def world_knowledge_inspect(
        self,
        actor_id: str | None = None,
        fact_id: str | None = None,
        max_facts: int = 32,
    ) -> dict[str, Any]:
        """Inspect the production World Knowledge ledger and explanations."""

        return self._host._request(
            "WORLD_KNOWLEDGE_INSPECT",
            {
                "actorID": actor_id,
                "factID": fact_id,
                "maxFacts": int(max_facts),
            },
        )

    def world_knowledge_propagate(
        self,
        from_actor_id: str,
        to_actor_id: str,
        channel: str = "conversation",
        authorized: bool = True,
        now: float = 1000,
    ) -> dict[str, Any]:
        """Exercise one authorized production propagation opportunity."""

        return self._host._request(
            "WORLD_KNOWLEDGE_PROPAGATE",
            {
                "fromActorID": str(from_actor_id),
                "toActorID": str(to_actor_id),
                "channel": str(channel),
                "authorized": bool(authorized),
                "now": float(now),
            },
        )

    def knowledge_discover(
        self, topic_id: str, npc_id: str | None = None
    ) -> dict[str, Any]:
        """Use the production direct-disclosure Knowledge path for a topic."""

        return self._host._request(
            "KNOWLEDGE_DISCOVER",
            {
                "topicID": str(topic_id),
                "npcID": str(npc_id) if npc_id is not None else None,
            },
        )

    def replay_quest_request(self, request: dict[str, Any]) -> dict[str, Any]:
        """Replay a captured request through the production server router."""

        return self._host._request("REPLAY_SEMANTIC_QUEST", request)

    def commitment(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Exercise the production NPC Knowledge commitment boundary."""

        return self._host._request("COMMITMENT", payload)

    def backstory(
        self,
        identity_seed: int,
        tactical_class: str = "colonist",
        npc_id: str = "harness-backstory-npc",
        save_seed: str | int | None = None,
    ) -> dict[str, Any]:
        """Read a bounded seed-derived backstory projection."""

        payload: dict[str, Any] = {
            "identitySeed": identity_seed,
            "tacticalClass": tactical_class,
            "npcID": npc_id,
        }
        if save_seed is not None:
            payload["saveSeed"] = save_seed
        return self._host._request("BACKSTORY", payload)

    def backstory_fact(
        self,
        identity_seed: int,
        kind: str,
        tactical_class: str = "colonist",
        language: str = "EN",
        npc_id: str = "harness-backstory-npc",
        save_seed: str | int | None = None,
    ) -> dict[str, Any]:
        """Resolve one authoritative offline backstory fact."""

        payload: dict[str, Any] = {
            "identitySeed": identity_seed,
            "kind": kind,
            "tacticalClass": tactical_class,
            "language": language,
            "npcID": npc_id,
        }
        if save_seed is not None:
            payload["saveSeed"] = save_seed
        return self._host._request("BACKSTORY_FACT", payload)
