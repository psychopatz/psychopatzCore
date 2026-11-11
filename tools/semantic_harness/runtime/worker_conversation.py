"""Conversation-facing operations for the semantic harness worker.

These operations are intentionally thin.  Lua remains the owner of semantic
policy and authoritative projections; the host façade remains the owner of
transport and working-world synchronization.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Protocol

from tools.semantic_harness.core.item_catalog import search_item_catalog
from .scenario import validate_scenario


class _WorkerConversationHost(Protocol):
    scenario: dict[str, Any]

    def _request(self, command: str, value: Any = None) -> dict[str, Any]: ...

    def _sync_effective_scenario(
        self, response: dict[str, Any], *, establish_baseline: bool = False
    ) -> None: ...


class WorkerConversationOperations:
    """Issue semantic conversation and inspection commands for one worker."""

    def __init__(self, host: _WorkerConversationHost) -> None:
        self._host = host

    def input(self, text: str) -> dict[str, Any]:
        return self.mutation_response(self._host._request("INPUT", str(text)))

    def preview(self, text: str) -> dict[str, Any]:
        """Preview a production semantic turn without recording or dispatching it."""

        return self._host._request("PREVIEW", str(text))

    def suggestion_predicate(self, predicate: dict[str, Any]) -> dict[str, Any]:
        """Evaluate one production suggestion predicate."""

        return self._host._request("SUGGESTION_PREDICATE", {"predicate": predicate})

    def suggestion_click(self, frame: dict[str, Any]) -> dict[str, Any]:
        """Submit one canonical suggestion frame through production input."""

        return self.mutation_response(
            self._host._request("SUGGESTION_CLICK", {"frame": frame})
        )

    def set_language(self, language: str) -> dict[str, Any]:
        """Change the production translation manager language in this session."""

        value = str(language or "EN").strip().upper()
        response = self._host._request("LANGUAGE", value)
        self._host.scenario.setdefault("runtime", {})["language"] = value
        return response

    def tool_result_speech(
        self,
        results: list[dict[str, Any]],
        context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Realize authoritative tool-result speech through production semantics."""

        return self._host._request(
            "TOOL_RESULT_SPEECH",
            {"results": results, "context": context or {}},
        )

    def snapshot(self) -> dict[str, Any]:
        response = self._host._request("SNAPSHOT")
        self._host._sync_effective_scenario(response)
        return response

    def mutation_response(self, response: dict[str, Any]) -> dict[str, Any]:
        """Attach the authoritative post-mutation worker projection."""

        snapshot = self._host._request("MUTATION_PROJECTION")
        self._host._sync_effective_scenario(snapshot)
        if not isinstance(response, dict):
            return snapshot
        merged = deepcopy(response)
        for key in (
            "scenario",
            "context",
            "sourceSnapshot",
            "workingWorld",
            "runtimeRelationshipOverrides",
            "productionRehydration",
            "productionFactionRehydration",
            "productionPlayerRehydration",
            "productionKnowledgeRehydration",
            "productionFactionContext",
            "simulationProjection",
            "provenance",
            "conversationPresentation",
        ):
            if key in snapshot:
                merged[key] = deepcopy(snapshot[key])
        self._host._sync_effective_scenario(snapshot)
        return merged

    def inspect_actor_state(self) -> dict[str, Any]:
        """Return bounded production actor state after an isolated mutation."""

        return self._host._request("INSPECT_ACTOR_STATE")

    def inspect_npc_dossier(self) -> dict[str, Any]:
        """Return the production player-scoped NPC dossier and social history."""

        return self._host._request("INSPECT_NPC_DOSSIER")

    def relationship_proposal(self, npc_id: str | None = None) -> dict[str, Any]:
        """Submit the canonical proposal action to the authority seam."""

        payload = {"npcID": npc_id} if npc_id else None
        return self.mutation_response(
            self._host._request("RELATIONSHIP_PROPOSAL", payload)
        )

    def relationship_preview(
        self,
        relationship: dict[str, Any],
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Resolve staged relationship scores without mutating the scenario."""

        payload: dict[str, Any] = {"relationship": dict(relationship)}
        if npc_id:
            payload["npcID"] = npc_id
        return self._host._request("RELATIONSHIP_PREVIEW", payload)

    def apply_runtime_relationship_baseline(
        self,
        relationship: dict[str, Any],
        npc_id: str | None = None,
    ) -> dict[str, Any]:
        """Apply a production-owned relationship baseline to the working world."""

        payload: dict[str, Any] = {"relationship": dict(relationship)}
        if npc_id:
            payload["npcID"] = npc_id
        response = self._host._request(
            "APPLY_RUNTIME_RELATIONSHIP_BASELINE", payload
        )
        self._host._sync_effective_scenario(response)
        return response

    def conversation_graph(self) -> dict[str, Any]:
        """Return the developer-only full selected ConversationBlock graph."""

        return self._host._request("CONVERSATION_GRAPH")

    def conversation_projection(self) -> dict[str, Any]:
        """Return the production-owned native Conversation presentation."""

        return self._host._request("CONVERSATION_PROJECTION")

    def talk_projection(self) -> dict[str, Any]:
        """Compatibility alias for the production Talk presentation seam."""

        return self.conversation_projection()

    def persona_catalog(
        self, register_relationship_kind: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        """Return the bounded catalog owned by the production Lua registries."""

        payload = None
        if register_relationship_kind is not None:
            payload = {"registerRelationshipKind": register_relationship_kind}
        return self._host._request("PERSONA_CATALOG", payload)

    def persona_preview(self, scenario: dict[str, Any]) -> dict[str, Any]:
        """Preview generated NPC personality for a staged scenario."""

        validate_scenario(scenario)
        return self._host._request("PERSONA_PREVIEW", {"scenario": scenario})

    def simulation_control_catalog(self) -> dict[str, Any]:
        """Return worker-owned, bounded Semantic Lab control metadata."""

        return self._host._request("SIMULATION_CONTROL_CATALOG")

    def talk_catalog(self) -> dict[str, Any]:
        """Return the production-owned native Talk target catalog."""

        return self._host._request("TALK_CATALOG")

    def talk_start(
        self, target_id: str = "current", utterance: str = "hello"
    ) -> dict[str, Any]:
        """Start the native Talk parity projection for one target type."""

        result = self._host._request(
            "TALK_START",
            {
                "targetID": str(target_id or "current"),
                "utterance": str(utterance or "hello"),
            },
        )
        scenario = result.get("scenario")
        if isinstance(scenario, dict):
            self._host.scenario = scenario
        return result

    def open_conversation(self, target_id: str = "current") -> dict[str, Any]:
        """Open the production Conversation session without submitting speech."""

        result = self._host._request(
            "CONVERSATION_OPEN", {"targetID": str(target_id or "current")}
        )
        scenario = result.get("scenario")
        if isinstance(scenario, dict):
            self._host.scenario = scenario
        return result

    def suspend_conversation(self) -> dict[str, Any]:
        """Suspend the live production session without resetting semantic state."""

        return self._host._request("CONVERSATION_SUSPEND")

    def resume_conversation(self) -> dict[str, Any]:
        """Resume a production session suspended by the Lua lifecycle seam."""

        return self._host._request("CONVERSATION_RESUME")

    def close_conversation(self, reason: str = "conversation_closed") -> dict[str, Any]:
        """Close the live production presentation through its Lua session."""

        return self._host._request(
            "CONVERSATION_CLOSE", {"reason": str(reason or "conversation_closed")}
        )

    def conversation_emote(
        self,
        emote_id: str,
        *,
        topic: str | None = None,
        meaningful: bool = False,
    ) -> dict[str, Any]:
        """Submit an emote through the production semantic lifecycle seam."""

        payload: dict[str, Any] = {
            "emote": {"id": str(emote_id or "")},
            "meaningful": bool(meaningful),
        }
        if topic:
            payload["topic"] = str(topic)
        return self._host._request("CONVERSATION_EMOTE", payload)

    def talk_matrix(
        self,
        target_types: list[str] | None = None,
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        """Compare native Talk startup and the first turn across target types."""

        payload: dict[str, Any] = {
            "utterance": str(text or "hello"),
            "maximum": int(maximum),
        }
        if target_types is not None:
            payload["targetIDs"] = [str(value) for value in target_types]
        return self._host._request("TALK_MATRIX", payload)

    def item_catalog(self, query: str = "", limit: int = 50) -> dict[str, Any]:
        """Search installed Project Zomboid item definitions for the Lab editor."""

        return search_item_catalog(query, limit, self._host.scenario)
