"""Reusable Semantic Lab block catalog over existing production contracts.

This module describes reusable authoring blocks and their registered values. It
does not evaluate conditions, interpret natural language, or invoke gameplay
actions. Those responsibilities remain with Conversation Blocks, the
PsychopatzCore parser, and the Project Hoomans Lua registry/dispatchers.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Iterable

SCHEMA_VERSION = 1
MAX_BLOCKS = 512
GATE_TYPES = (
    "none", "pnc:fact", "pnc:weather", "pnc:time", "pnc:skill",
    "pnc:trait", "pnc:personality", "pnc:relationship",
    "pnc:relationship_state", "pnc:audience", "pnc:history",
)
TRANSITION_FIELDS = (
    "next", "onMatch", "onRefuse", "onUnrelated", "onClarify",
    "onPass", "onFail", "onUnknown",
)

# Declarative authoring contracts.  These ports constrain Studio composition;
# they never evaluate conditions or execute gameplay actions.
BLOCK_PORTS: dict[str, dict[str, tuple[str, ...]]] = {
    "language.speech_act": {"inputs": (), "outputs": ("semantic",)},
    "language.concept": {"inputs": ("semantic",), "outputs": ("semantic",)},
    "language.trigger": {"inputs": (), "outputs": ("semantic",)},
    "language.backstory_subject": {
        "inputs": ("semantic",),
        "outputs": ("fact", "context", "knowledge"),
    },
    "conditions.gate": {"inputs": ("fact",), "outputs": ("gate",)},
    "conditions.fact_match": {"inputs": ("fact",), "outputs": ("gate",)},
    "world_facts.engine_fact": {"inputs": (), "outputs": ("fact",)},
    "world_facts.engine_event": {"inputs": (), "outputs": ("context",)},
    "context.conversation_state": {"inputs": ("context",), "outputs": ()},
    "context.participant_scope": {"inputs": ("context",), "outputs": ()},
    "memory.knowledge": {"inputs": ("knowledge",), "outputs": ()},
    "memory.backstory_fact": {"inputs": ("fact",), "outputs": ("response",)},
    "memory.gossip": {"inputs": ("context",), "outputs": ("response",)},
    "dialogue_responses.response_pool": {"inputs": ("response",), "outputs": ()},
    "gameplay_actions.capability": {
        "inputs": ("semantic", "gate"),
        "outputs": ("response",),
    },
    "quests.command": {"inputs": ("semantic", "gate"), "outputs": ("response",)},
}


def block_port_contract(block_type: str) -> dict[str, list[str]]:
    """Return a JSON-safe copy of one registered block's typed ports."""

    ports = BLOCK_PORTS.get(str(block_type), {"inputs": (), "outputs": ()})
    return {key: list(values) for key, values in ports.items()}

CATEGORY_SPECS = (
    ("language", "Language", "Registered speech acts, concepts, and trigger frames."),
    ("conditions", "Conditions", "Typed gates evaluated by the production Conversation Blocks bridge."),
    ("world_facts", "World facts", "Authoritative engine facts and observed event types."),
    ("context", "Context", "Bounded participant-scoped conversation state."),
    ("memory", "Memory", "Registered NPC knowledge, gossip, and conversation-memory contracts."),
    ("dialogue_responses", "Dialogue responses", "Reviewed EN/TL response pools and response plans."),
    ("gameplay_actions", "Gameplay actions", "Registered capability bindings and typed action slots."),
    ("quests", "Quests", "Server-owned quest capability requests and lifecycle contracts."),
)

_BLOCK_TYPE_SPECS = (
    {
        "id": "language.speech_act",
        "category": "language",
        "label": "Speech act",
        "owner": "PsychopatzCore",
        "source": "flow_catalog.speechActCatalog",
        "contract": "candidate IR speechAct",
        "fields": ["speechAct"],
    },
    {
        "id": "language.concept",
        "category": "language",
        "label": "Semantic concept",
        "owner": "ProjectHoomans",
        "source": "flow_catalog.conceptCatalog",
        "contract": "registered concept ID",
        "fields": ["conceptID"],
    },
    {
        "id": "language.trigger",
        "category": "language",
        "label": "Trigger frame",
        "owner": "ProjectHoomans",
        "source": "flow_catalog.triggerCatalog",
        "contract": "registered semantic trigger frame",
        "fields": ["triggerID", "intent", "speechAct"],
    },
    {
        "id": "language.backstory_subject",
        "category": "language",
        "label": "NPC backstory subject",
        "owner": "Project Hoomans Semantic Dialogue",
        "source": "PNC.Semantics.DialogueFacts",
        "contract": "typed immutable fact kind, provider, disclosure state, and context follow-up",
        "fields": [
            "backstoryKind", "factProvider", "topicID", "disclosure",
            "dialogueFollowUp", "referenceSubject",
        ],
    },
    {
        "id": "conditions.gate",
        "category": "conditions",
        "label": "Tri-state condition gate",
        "owner": "Project Hoomans Conversation Blocks",
        "source": "PNC_SemanticDialogueFlowKernel.EvaluateGateStatus",
        "contract": "PASS / FAIL / UNKNOWN; unknown fails closed for sensitive branches",
        "fields": ["type", "fact", "operator", "value", "onPass", "onFail", "onUnknown"],
    },
    {
        "id": "conditions.fact_match",
        "category": "conditions",
        "label": "Typed fact match",
        "owner": "Project Hoomans Conversation Blocks",
        "source": "PNC.Semantics.EngineFacts",
        "contract": "registered fact provider; no Python-side evaluation",
        "fields": ["factID", "operator", "expectedValue"],
    },
    {
        "id": "world_facts.engine_fact",
        "category": "world_facts",
        "label": "Engine fact",
        "owner": "Project Hoomans",
        "source": "PNC.Semantics.EngineFacts.List",
        "contract": "typed value with authority, scope, provenance, and known/unknown status",
        "fields": ["factID", "scope", "type", "authority"],
    },
    {
        "id": "world_facts.engine_event",
        "category": "world_facts",
        "label": "Engine observation",
        "owner": "Project Hoomans",
        "source": "PNC.Semantics.EngineEvents.ListTypes",
        "contract": "bounded observation; never direct arbitrary execution",
        "fields": ["eventType", "scope", "authority"],
    },
    {
        "id": "context.conversation_state",
        "category": "context",
        "label": "Conversation context",
        "owner": "Project Hoomans",
        "source": "PNC.Semantics.DialogueInput",
        "contract": "bounded topic, pending question, active/suspended flow, and participant scope",
        "fields": ["topic", "pendingQuestion", "activeFlow", "suspendedFlows", "participants"],
    },
    {
        "id": "context.participant_scope",
        "category": "context",
        "label": "Participant scope",
        "owner": "Project Hoomans",
        "source": "PNC.ConversationAuthority",
        "contract": "speaker/addressee/player scope validated by existing authority",
        "fields": ["speakerID", "addresseeID", "playerUUID", "scope"],
    },
    {
        "id": "memory.knowledge",
        "category": "memory",
        "label": "NPC knowledge reference",
        "owner": "Project Hoomans NPCKnowledgeService",
        "source": "PNC.NPCKnowledgeService",
        "contract": "authoritative, target-scoped knowledge projection",
        "fields": ["knowledgeID", "targetID", "freshness", "provenance"],
    },
    {
        "id": "memory.backstory_fact",
        "category": "memory",
        "label": "Registered personal fact provider",
        "owner": "Project Hoomans NPCKnowledgeService",
        "source": "PNC.Semantics.DialogueFacts.RegisterProvider",
        "contract": "server-authoritative immutable fact with known/suspected/refused projection",
        "fields": [
            "providerID", "subject", "authority", "immutable", "privacy",
        ],
    },
    {
        "id": "memory.gossip",
        "category": "memory",
        "label": "Gossip memory reference",
        "owner": "Project Hoomans Conversation Memory",
        "source": "PNC.Conversation.Memory.BuildGossipPacket",
        "contract": "registered gossip template/code; bounded and target-scoped",
        "fields": ["gossipCode", "targetID", "source", "freshness"],
    },
    {
        "id": "dialogue_responses.response_pool",
        "category": "dialogue_responses",
        "label": "Localized response pool",
        "owner": "Project Hoomans CodeBuilder",
        "source": "canonical JSON responsePools",
        "contract": "reviewed EN/TL fallback and response-plan variants",
        "fields": ["poolID", "variantID", "when", "priority"],
        "typedArguments": [
            "string", "number", "boolean", "identifier", "fact_content",
        ],
    },
    {
        "id": "gameplay_actions.capability",
        "category": "gameplay_actions",
        "label": "Registered gameplay capability",
        "owner": "Project Hoomans capability owner",
        "source": "flow_catalog.actionCatalog",
        "contract": "typed binding ID routed exactly once through existing dispatcher",
        "fields": ["capabilityID", "bindingID", "requiredSlots", "permissionGate", "outcomes"],
    },
    {
        "id": "quests.command",
        "category": "quests",
        "label": "Server-owned quest command",
        "owner": "Project Hoomans QuestService",
        "source": "flow_catalog.actionCatalog quest bindings",
        "contract": "server-authoritative request/result lifecycle; no fabricated quest state",
        "fields": ["capabilityID", "questID", "operation", "giverID", "result"],
    },
)


class SemanticBlockRegistry:
    """Build a bounded, searchable catalog of reusable authoring blocks."""

    def __init__(
        self,
        repository: Path,
        dataset_specs: Iterable[dict[str, Any]],
        *,
        max_blocks: int = MAX_BLOCKS,
    ) -> None:
        self.repository = repository.expanduser().resolve()
        self.dataset_specs = {
            str(spec["id"]): spec for spec in dataset_specs if isinstance(spec, dict)
        }
        self.max_blocks = max(1, int(max_blocks))

    def catalog(self, production_catalog: dict[str, Any] | None = None) -> dict[str, Any]:
        production_catalog = production_catalog if isinstance(production_catalog, dict) else {}
        blocks = [self._type_block(spec, production_catalog) for spec in _BLOCK_TYPE_SPECS]
        blocks.extend(self._value_blocks(production_catalog))
        blocks.sort(key=lambda block: (str(block.get("category")), str(block.get("id"))))
        truncated = len(blocks) > self.max_blocks
        blocks = blocks[: self.max_blocks]
        counts: dict[str, int] = {}
        for block in blocks:
            category = str(block["category"])
            counts[category] = counts.get(category, 0) + 1
        return {
            "ok": True,
            "type": "semantic_block_registry",
            "schemaVersion": SCHEMA_VERSION,
            "categories": [
                {"id": category, "label": label, "description": description}
                for category, label, description in CATEGORY_SPECS
            ],
            "blocks": blocks,
            "counts": counts,
            "blockCount": len(blocks),
            "maxBlocks": self.max_blocks,
            "truncated": truncated,
            "productionCatalogLoaded": bool(production_catalog),
        }

    def search(
        self,
        query: str = "",
        *,
        category: str | None = None,
        production_catalog: dict[str, Any] | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        needle = str(query or "").strip().lower()
        rows = self.catalog(production_catalog).get("blocks", [])
        results: list[dict[str, Any]] = []
        for block in rows:
            if category and block.get("category") != category:
                continue
            if needle and needle not in json.dumps(block, ensure_ascii=False, sort_keys=True).lower():
                continue
            results.append(copy.deepcopy(block))
            if len(results) >= max(1, int(limit)):
                break
        return results

    def validate_selection(
        self,
        block_ids: Iterable[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        requested = [str(block_id) for block_id in block_ids]
        catalog = self.catalog(production_catalog)
        known = {str(block["id"]): block for block in catalog["blocks"]}
        diagnostics: list[dict[str, str]] = []
        selected: list[dict[str, Any]] = []
        seen: set[str] = set()
        for block_id in requested:
            if block_id in seen:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "duplicate block selection"})
                continue
            seen.add(block_id)
            block = known.get(block_id)
            if block is None:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "unknown registered block"})
                continue
            if block.get("available") is not True:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "block contract is unavailable"})
                continue
            selected.append(copy.deepcopy(block))
        if not requested:
            diagnostics.append({"severity": "error", "message": "at least one block is required"})
        return {
            "ok": not diagnostics,
            "type": "semantic_block_selection_validation",
            "schemaVersion": SCHEMA_VERSION,
            "valid": not diagnostics,
            "blockIDs": requested,
            "blocks": selected,
            "diagnostics": diagnostics,
            "effectFree": True,
            "writes": [],
        }

    def _type_block(
        self,
        spec: dict[str, Any],
        production_catalog: dict[str, Any],
    ) -> dict[str, Any]:
        block = {
            **copy.deepcopy(spec),
            "kind": "block_type",
            "reusable": True,
            "available": True,
            "productionOnly": spec["id"] in {
                "language.speech_act",
                "language.concept",
                "language.trigger",
                "world_facts.engine_fact",
                "world_facts.engine_event",
                "gameplay_actions.capability",
                "quests.command",
            },
        }
        block["values"] = self._values_for_type(spec["id"], production_catalog)
        block["ports"] = block_port_contract(spec["id"])
        return block

    def _values_for_type(self, block_type: str, catalog: dict[str, Any]) -> list[Any]:
        if block_type == "language.speech_act":
            return sorted({str(value) for value in catalog.get("speechActCatalog", []) if value})
        if block_type == "language.concept":
            return self._catalog_ids(catalog.get("conceptCatalog", []))
        if block_type == "language.trigger":
            return self._catalog_ids(catalog.get("triggerCatalog", []))
        if block_type == "conditions.gate":
            return [value for value in GATE_TYPES if value != "none"]
        if block_type == "conditions.fact_match":
            return self._catalog_ids(catalog.get("factCatalog", []))
        if block_type == "world_facts.engine_fact":
            return self._catalog_values(catalog.get("factCatalog", []))
        if block_type == "world_facts.engine_event":
            return self._catalog_values(catalog.get("eventCatalog", []))
        if block_type == "gameplay_actions.capability":
            return self._catalog_values(catalog.get("actionCatalog", []), "id")
        if block_type == "quests.command":
            return [
                value for value in self._catalog_values(catalog.get("actionCatalog", []))
                if isinstance(value, dict)
                if ":quest." in str(value.get("bindingID", ""))
                or ":quest." in str(value.get("capabilityID", ""))
            ]
        return []

    @staticmethod
    def _catalog_ids(values: Any) -> list[str]:
        if not isinstance(values, list):
            return []
        output: list[str] = []
        for value in values:
            item = value.get("id") if isinstance(value, dict) else value
            if item:
                output.append(str(item))
        return sorted(set(output))

    @staticmethod
    def _catalog_values(values: Any, key: str | None = None) -> list[Any]:
        if not isinstance(values, list):
            return []
        output: list[Any] = []
        for value in values:
            item = value.get(key) if key and isinstance(value, dict) else value
            if item:
                output.append(copy.deepcopy(item))
        return sorted(output, key=lambda item: json.dumps(item, ensure_ascii=False, sort_keys=True))

    def _value_blocks(self, catalog: dict[str, Any]) -> list[dict[str, Any]]:
        blocks: list[dict[str, Any]] = []
        for action in catalog.get("actionCatalog", []):
            if not isinstance(action, dict) or not action.get("id"):
                continue
            binding_id = str(action.get("bindingID") or action.get("capabilityID") or action["id"])
            category = "quests" if ":quest." in binding_id else "gameplay_actions"
            prefix = "quest" if category == "quests" else "action"
            blocks.append({
                "id": f"{prefix}:{binding_id}",
                "category": category,
                "kind": "registered_capability",
                "label": str(action["id"]),
                "owner": action.get("owner") or action.get("translationOwner") or "Project Hoomans",
                "source": "flow_catalog.actionCatalog",
                "contract": "registered typed capability binding",
                "reusable": True,
                "available": action.get("dispatchable") is not False,
                "definition": copy.deepcopy(action),
                "ports": block_port_contract("gameplay_actions.capability"),
            })
        for fact in catalog.get("factCatalog", []):
            if isinstance(fact, dict) and fact.get("id"):
                blocks.append({
                    "id": f"fact:{fact['id']}",
                    "category": "world_facts",
                    "kind": "registered_fact",
                    "label": str(fact["id"]),
                    "owner": fact.get("authority") or "Project Hoomans",
                    "source": "flow_catalog.factCatalog",
                    "contract": "typed authoritative fact provider",
                    "reusable": True,
                    "available": True,
                    "definition": copy.deepcopy(fact),
                    "ports": block_port_contract("world_facts.engine_fact"),
                })
        for event in catalog.get("eventCatalog", []):
            if isinstance(event, dict) and event.get("type"):
                blocks.append({
                    "id": f"event:{event['type']}",
                    "category": "world_facts",
                    "kind": "registered_event",
                    "label": str(event["type"]),
                    "owner": event.get("authority") or "Project Hoomans",
                    "source": "flow_catalog.eventCatalog",
                    "contract": "bounded observation; not executable by itself",
                    "reusable": True,
                    "available": True,
                    "definition": copy.deepcopy(event),
                    "ports": block_port_contract("world_facts.engine_event"),
                })
        blocks.extend(self._response_blocks())
        return blocks

    def _response_blocks(self) -> list[dict[str, Any]]:
        blocks: list[dict[str, Any]] = []
        for source_id in ("semantic_flows", "common_dialogue"):
            spec = self.dataset_specs.get(source_id)
            if not spec:
                continue
            source_path = (
                spec.get("responsePath")
                if source_id == "common_dialogue"
                else spec.get("path")
            )
            if source_path is None:
                continue
            path = self.repository / source_path
            try:
                document = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, UnicodeError, json.JSONDecodeError):
                continue
            if source_id == "semantic_flows":
                pools = []
                for definition in document.get("definitions", []):
                    if isinstance(definition, dict) and isinstance(definition.get("responses"), dict):
                        pools.append(definition["responses"])
            else:
                pools = document.get("responsePools", [])
            for pool in pools:
                if not isinstance(pool, dict) or not pool.get("poolID") and not pool.get("id"):
                    continue
                pool_id = str(pool.get("poolID") or pool.get("id"))
                variants = pool.get("variants", [])
                blocks.append({
                    "id": f"response:{pool_id}",
                    "category": "dialogue_responses",
                    "kind": "response_pool",
                    "label": pool_id,
                    "owner": "Project Hoomans CodeBuilder",
                    "source": str(source_path),
                    "contract": "reviewed localized response pool",
                    "reusable": True,
                    "available": True,
                    "variantCount": len(variants) if isinstance(variants, list) else 0,
                    "definition": {"poolID": pool_id},
                    "ports": block_port_contract("dialogue_responses.response_pool"),
                })
        return blocks
