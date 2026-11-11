"""Bounded scenario comparison and replay operations for the worker façade."""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Protocol

from .scenario import validate_scenario


class _WorkerMatrixHost(Protocol):
    scenario: dict[str, Any]

    def configure(self, scenario: dict[str, Any]) -> dict[str, Any]: ...

    def input(self, text: str) -> dict[str, Any]: ...

    def snapshot(self) -> dict[str, Any]: ...

    def preview(self, text: str) -> dict[str, Any]: ...


class WorkerMatrixOperations:
    """Run bounded A/B comparisons without owning worker state."""

    def __init__(self, host: _WorkerMatrixHost) -> None:
        self._host = host

    def context_matrix(
        self,
        scenarios: list[dict[str, Any]],
        text: str = "hello",
        maximum: int = 8,
    ) -> dict[str, Any]:
        """Run bounded scenario A/B rows through this same real Lua worker."""

        original = self._host.scenario
        rows: list[dict[str, Any]] = []
        try:
            for index, scenario in enumerate(scenarios[: max(1, int(maximum))]):
                validate_scenario(scenario)
                configured = self._host.configure(scenario)
                turn = self._host.input(text)
                snapshot = self._host.snapshot()
                observation = turn.get("observation", {})
                observation = observation if isinstance(observation, dict) else {}
                response = observation.get("response", {})
                response = response if isinstance(response, dict) else {}
                queued = (response.get("queued") or [response])[0]
                queued = queued if isinstance(queued, dict) else response
                suggestions = observation.get("suggestions") or {}
                context = snapshot.get("context") or {}
                actor_context = context.get("actorConversationContext") or {}
                actor_relationship = actor_context.get("relationship") or {}
                speech_style = (
                    context.get("speechStyleContext")
                    or response.get("speechStyleContext")
                    or {}
                )
                flow = observation.get("flow") or {}
                rows.append(
                    {
                        "index": index,
                        "label": scenario.get("runtime", {}).get(
                            "semanticLabMatrixLabel", f"case-{index + 1}"
                        ),
                        "configured": {
                            "accepted": configured.get("ok") is True,
                            "dynamicTradingLoad": configured.get(
                                "dynamicTradingLoad"
                            ),
                        },
                        "context": snapshot.get("context", {}),
                        "npcResponse": queued.get("text") or response.get("text"),
                        "semanticHubChoices": [
                            {
                                "id": candidate.get("id"),
                                "action": candidate.get("action"),
                                "label": (candidate.get("display") or {}).get("label")
                                or candidate.get("labelFallback"),
                                "status": candidate.get("status"),
                            }
                            for candidate in (suggestions.get("candidates") or [])[:24]
                            if isinstance(candidate, dict)
                        ],
                        "speechStyleContext": speech_style,
                        "relationship": {
                            "standing": actor_relationship.get("state")
                            or actor_relationship.get("standing")
                            or "unknown",
                            "bond": deepcopy(
                                actor_relationship.get("bond")
                                or (snapshot.get("simulationProjection") or {})
                                .get("npc", {})
                                .get("bond")
                                or {}
                            ),
                            "approval": actor_relationship.get("approval"),
                            "respect": actor_relationship.get("respect"),
                            "familiarity": actor_relationship.get("familiarity"),
                        },
                        "runtimeGraphPath": {
                            "kind": "semantic_flow" if flow.get("flowId") else "semantic_hub",
                            "flow": flow,
                            "graph": observation.get("conversationGraph")
                            or response.get("conversationGraph"),
                        },
                        "response": {
                            "semanticTemplateID": response.get("templateID"),
                            "renderTemplateID": response.get("renderTemplateID"),
                            "key": queued.get("key") or response.get("templateID"),
                            "text": queued.get("text") or response.get("text"),
                            "fallback": queued.get("fallback") or response.get("fallback"),
                            "translationKey": queued.get("translationKey"),
                            "realizationFamily": queued.get("realizationFamily")
                            or response.get("realizationFamily"),
                            "realizationVariant": queued.get("realizationVariant")
                            or response.get("realizationVariant"),
                            "realizationFallbackReason": queued.get(
                                "realizationFallbackReason"
                            ) or response.get("realizationFallbackReason"),
                            "familyAddress": (queued.get("args") or {}).get(
                                "familyAddress"
                            ),
                        },
                        "suggestions": {
                            "revision": suggestions.get("revision"),
                            "candidateOrder": [
                                row.get("id")
                                for row in (suggestions.get("candidates") or [])[:24]
                            ],
                            "candidates": [
                                {
                                    "id": row.get("id"),
                                    "providerID": row.get("providerID"),
                                    "source": row.get("source"),
                                    "ranking": row.get("ranking"),
                                    "display": row.get("display"),
                                }
                                for row in (suggestions.get("candidates") or [])[:24]
                            ],
                        },
                    }
                )
        finally:
            self._host.configure(original)
        return {"schema": "semantic.persona.matrix.v1", "rows": rows}

    def capture_baseline(self, text: str) -> dict[str, Any]:
        """Capture a non-mutating production baseline for the current scenario."""

        value = str(text or "").strip()
        if not value:
            raise ValueError("baseline utterance must not be empty")
        preview = self._host.preview(value)
        return {
            "schema": "semantic.persona.baseline.v1",
            "utterance": value,
            "preview": preview,
        }

    def apply_and_replay(self, text: str) -> dict[str, Any]:
        """Reapply the current scenario and replay one utterance in production Lua."""

        value = str(text or "").strip()
        if not value:
            raise ValueError("replay utterance must not be empty")
        configured = self._host.configure(self._host.scenario)
        turn = self._host.input(value)
        return {
            "schema": "semantic.persona.apply_replay.v1",
            "utterance": value,
            "configured": configured,
            "turn": turn,
        }
