"""S6M2A ownership inventory and classification for ConvoEngine vs generic Semantics."""

from __future__ import annotations

import argparse
from collections import Counter
import datetime
import json
from pathlib import Path, PurePosixPath
import re
from typing import Any, Mapping

from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
)

OWNERSHIP_INVENTORY_SCHEMA = "psychopatz.convo-engine.ownership-inventory.v1"

REPO_NAMES = (CORE_OWNER, "ProjectHoomans", "DynamicTrading")

_LUA_REQUIRE_RE = re.compile(r"""require\s*\(?\s*["']([^"']+)["']""")
_PY_MODULE_STRING_RE = re.compile(
    r"""["']((?:PsychopatzCore|PNC|DTCommon)/(?:Semantics|ConvoEngine|Conversation)[^"']*)["']"""
)
_GLOBAL_ASSIGN_RE = re.compile(
    r"""^\s*(?:local\s+\w+\s*=\s*)?((?:PsychopatzCore|PNC|DTCommon|DTHoomans|DTAbstract)\.[A-Za-z0-9_.]+)\s*=""",
    re.MULTILINE,
)

# Evidence-backed classification table for PsychopatzCore/Semantics/* modules.
# Each entry records functional ownership rather than matching filename substrings.
_CORE_SEMANTICS_RULES: dict[str, tuple[str, str, str, str | None, str]] = {
    "PsychopatzSemantic": (
        "generic_semantic_infrastructure",
        "core_nlu_facade",
        "retain_in_place_update_references",
        None,
        "Top-level generic semantic facade (RegisterConcept, RegisterSpeechAct, RegisterPattern, Parse, PackRegistry).",
    ),
    "PsychopatzSemanticIR": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Provider-neutral Semantic IR schema, cloning, and validation contract consumed by parser, providers, and adapters.",
    ),
    "PsychopatzSemanticNormalizer": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Text normalization helper used across concept indexing, pattern matching, surface recovery, and NLU parsing.",
    ),
    "PsychopatzSemanticRegistry": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Registry for generic concepts, speech acts, and grammar patterns across all adopting mods.",
    ),
    "PsychopatzSemanticConceptMatcher": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Utterance token/phrase concept matcher for NLU parsing.",
    ),
    "PsychopatzSemanticFuzzyMatcher": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Conservative typo/edit-distance concept matcher used by generic NLU parsing.",
    ),
    "PsychopatzSemanticPatternMatcher": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Grammar pattern matcher facade used by SemanticParser.",
    ),
    "PsychopatzSemanticPatternMatcher_Captures": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Pattern capture extraction spoke of SemanticPatternMatcher.",
    ),
    "PsychopatzSemanticPatternMatcher_Match": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Search/matching engine spoke of SemanticPatternMatcher.",
    ),
    "PsychopatzSemanticPatternMatcher_Rules": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Rule normalization spoke of SemanticPatternMatcher.",
    ),
    "PsychopatzSemanticPatternMatcher_Support": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Shared table/value helpers for SemanticPatternMatcher spokes.",
    ),
    "PsychopatzSemanticSurfaceRecovery": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Unparsed surface span recovery for SemanticParser.",
    ),
    "PsychopatzSemanticConfidence": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Parse confidence scoring for SemanticParser.",
    ),
    "PsychopatzSemanticParser": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Generic natural-language utterance parser producing Semantic IR.",
    ),
    "PsychopatzSemanticContext": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "Prioritized Semantic IR context resolver pipeline.",
    ),
    "PsychopatzSemanticProvider": (
        "generic_semantic_infrastructure",
        "core_nlu_and_ir",
        "retain_under_semantics",
        None,
        "External/LLM wire payload normalizer into validated Semantic IR.",
    ),
    "PsychopatzSemanticPredicate": (
        "generic_semantic_infrastructure",
        "core_predicates",
        "retain_under_semantics",
        None,
        "Bounded generic predicate contract and evaluator over public context projections.",
    ),
    "PsychopatzSemanticPackRegistry": (
        "generic_semantic_infrastructure",
        "core_pack_registry",
        "retain_in_place_update_references",
        None,
        "Cross-subsystem mod pack, capability-gated action provider, and block registry.",
    ),
    "PsychopatzSemanticDialogueFlow": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueFlow",
        "Evaluates conversation gates (relationship, capability, state) and deterministic weighted dialogue outcome selection.",
    ),
    "PsychopatzSemanticDialogueRouter": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueRouter",
        "Routes conversation turns across parser, candidate selector, context resolver, policy, and DialogueState.",
    ),
    "PsychopatzSemanticDialogueState": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueState",
        "Tracks active conversation session turn sequence, participants, topic, and entity references.",
    ),
    "PsychopatzSemanticDialogueState_Events": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueState_Events",
        "Bounded dialogue turn/event history storage spoke of DialogueState.",
    ),
    "PsychopatzSemanticDialogueState_References": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueState_References",
        "Dialogue reference resolution bookkeeping spoke of DialogueState.",
    ),
    "PsychopatzSemanticDialogueTurn": (
        "convo_engine",
        "dialogue_engine",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/DialogueTurn",
        "Multi-clause dialogue turn segmentation orchestrator used by ActorConversationService.",
    ),
    "PsychopatzSemanticOffer": (
        "convo_engine",
        "offers_and_chaining",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/Offer",
        "Normalizes participant-neutral UI label vs spoken utterance affordance frames for conversation offers.",
    ),
    "PsychopatzSemanticFoundation": (
        "convo_engine",
        "conversation_foundation",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/Foundation",
        "Loads Core generated FoundationRegistry patterns, static UI suggestions, response pools, and phrase families.",
    ),
    "PsychopatzSemanticTextBinding": (
        "convo_engine",
        "speech_realization",
        "migrate_module_to_convo_engine",
        "PsychopatzCore/ConvoEngine/TextBinding",
        "Resolves authored conversation placeholders for conversation UI text rendering and reply realization.",
    ),
}

# Explicit non-ConvoEngine Hoomans functional subsystems under PNC/Semantics/.
_HOOMANS_NON_CONVO_PREFIXES: tuple[tuple[str, str, str], ...] = (
    (
        "ActionPlan",
        "domain_action_and_task",
        "NPC action-plan schema, lifecycle, pump service, and world/item execution providers.",
    ),
    (
        "SemanticActionPlan/",
        "domain_action_and_task",
        "NPC action-plan schema, codec, and lifecycle modules.",
    ),
    (
        "PNC_SemanticActionPlan",
        "domain_action_and_task",
        "NPC action-plan contract and server task handler.",
    ),
    (
        "PNC_SemanticTaskAdapter",
        "domain_action_and_task",
        "Client task adapter metadata and dispatch wrapper.",
    ),
    (
        "PNC_SemanticGift",
        "domain_action_and_task",
        "Gift selection, transfer projection, and lifecycle execution.",
    ),
    (
        "PNC_SemanticTelemetry",
        "domain_cognition_and_runtime",
        "Semantic telemetry prompt queue/window and persisted opt-in storage.",
    ),
    (
        "PNC_SemanticWorldContext",
        "domain_spatial_and_inventory",
        "World and time-band context projection for environment awareness.",
    ),
    (
        "PNC_SemanticActionRiskCatalog",
        "domain_action_and_task",
        "Risk classification catalog for executable NPC actions.",
    ),
    (
        "PNC_SemanticCommandAdapter",
        "domain_action_and_task",
        "Command adapter bridging parsed intents to authoritative companion/quest dispatch.",
    ),
    (
        "PNC_SemanticConsumption",
        "domain_action_and_task",
        "Consumption item policy catalog for NPC task execution.",
    ),
    (
        "SemanticConsumptionTaskHandler",
        "domain_action_and_task",
        "Server task handler executing NPC eat/drink consumption plans.",
    ),
    (
        "PNC_SemanticGiveItemTaskHandler",
        "domain_action_and_task",
        "Server task handler executing item transfer tasks.",
    ),
    (
        "PNC_SemanticItemTaskRuntime",
        "domain_action_and_task",
        "Shared runtime helpers for item task execution.",
    ),
    (
        "PNC_SemanticTaskRequest",
        "domain_action_and_task",
        "Validation/dispatch contract for NPC task execution requests.",
    ),
    (
        "PNC_SemanticTaskRuntime",
        "domain_action_and_task",
        "Runtime state/handlers for queued NPC tasks.",
    ),
    (
        "CampSite",
        "domain_spatial_and_inventory",
        "Camp site geometry, room selection, and server camp resolver.",
    ),
    (
        "PNC_SemanticCamp",
        "domain_spatial_and_inventory",
        "Camp site model, client hints, resolver, and camp task handler.",
    ),
    (
        "Inventory/",
        "domain_spatial_and_inventory",
        "Read-only NPC inventory matching and server query services.",
    ),
    (
        "PNC_SemanticInventoryQuery",
        "domain_spatial_and_inventory",
        "Read-only NPC inventory query contract and client adapter.",
    ),
    (
        "PNC_SemanticWorldTarget",
        "domain_spatial_and_inventory",
        "World object/water target vocabulary, client observer hints, and server resolver.",
    ),
    (
        "PNC_SemanticWaterTargetResolver",
        "domain_spatial_and_inventory",
        "Server resolver for water sources near an NPC.",
    ),
    (
        "PNC_SemanticAddressResolver",
        "domain_spatial_and_inventory",
        "Place/building address resolution for spatial queries.",
    ),
    (
        "PNC_SemanticLocationObservation",
        "domain_spatial_and_inventory",
        "NPC observation cache of world locations and landmarks.",
    ),
    (
        "PNC_SemanticCommunityRoleWhereabouts",
        "domain_spatial_and_inventory",
        "Community role and survivor whereabouts resolver.",
    ),
    (
        "PNC_SemanticTacticalSpatialLanguage",
        "domain_spatial_and_inventory",
        "Tactical spatial terms grounded for command parsing.",
    ),
    (
        "SemanticCatalog/",
        "adopter_nlu_catalog",
        "Hoomans NLU concepts, command patterns, question patterns, and request grammar registered into Semantics.Registry.",
    ),
    (
        "PNC_SemanticCatalog",
        "adopter_nlu_catalog",
        "Top-level Hoomans NLU lexicon and pattern catalog loader.",
    ),
    (
        "PNC_CoreSemanticPack",
        "adopter_nlu_catalog",
        "Adopter semantic pack wiring Lexicon/Catalog into PsychopatzCore.Semantics.",
    ),
    (
        "PNC_SemanticMarketSenseAdapter",
        "adopter_nlu_catalog",
        "Optional MarketSense item-taxonomy bridge for NLU item concepts.",
    ),
    (
        "PNC_SemanticCognition",
        "domain_cognition_and_runtime",
        "NPC semantic cognition projection, evidence, and client/server state sync.",
    ),
    (
        "PNC_SemanticCapability",
        "domain_cognition_and_runtime",
        "Client/server capability handshake and catalog for semantic features.",
    ),
    (
        "PNC_SemanticDiagnostics",
        "domain_cognition_and_runtime",
        "Diagnostic counters and inspection snapshots for Hoomans semantic subsystem.",
    ),
    (
        "PNC_SemanticEngineEvents",
        "domain_cognition_and_runtime",
        "Semantic engine event bus bridge between server and client.",
    ),
    (
        "PNC_SemanticEngineFacts",
        "domain_cognition_and_runtime",
        "Fact source projection for NPC state and world facts.",
    ),
    (
        "PNC_SemanticEventRuntime",
        "domain_cognition_and_runtime",
        "Server semantic world/combat event listener lifecycle.",
    ),
    (
        "PNC_SemanticLLMResult",
        "domain_cognition_and_runtime",
        "Bounded validation/normalization for asynchronous LLM fallback outputs.",
    ),
    (
        "PNC_SemanticPredicate",
        "core_predicate_bridge",
        "Thin PNC delegate re-exporting PsychopatzCore/Semantics/PsychopatzSemanticPredicate.",
    ),
    (
        "PNC_SemanticEntityResolver",
        "adopter_nlu_resolution",
        "Side-effect-free normalized entity name index for disambiguation.",
    ),
    (
        "PNC_SemanticContext",
        "adopter_nlu_resolution",
        "Semantic IR context constraints and resolver bindings.",
    ),
    (
        "PNC_SemanticPragmaticResolver",
        "adopter_nlu_resolution",
        "Pragmatic reference/slot completion over parsed Semantic IR.",
    ),
    (
        "PNC_SemanticDiscourseResolver",
        "adopter_nlu_resolution",
        "Discourse candidate ranking over Core NLU parse candidates.",
    ),
    (
        "PNC_SemanticValueBounds",
        "adopter_nlu_resolution",
        "Bounded scalar/table validation helpers.",
    ),
    (
        "PNC_SemanticCombatEncounterIntent",
        "domain_combat_telemetry",
        "Combat encounter intent telemetry classifier.",
    ),
    (
        "PNC_SemanticCombatMoment",
        "domain_combat_telemetry",
        "Combat moment detection/classification for reactions.",
    ),
    (
        "PNC_SemanticCombatObservatory",
        "domain_combat_telemetry",
        "Combat telemetry observation recorder.",
    ),
    (
        "PNC_SemanticCombatReactionProfile",
        "domain_combat_telemetry",
        "Combat reaction propensity/personality projection.",
    ),
    (
        "PNC_SemanticCombatWeaponContext",
        "domain_combat_telemetry",
        "Equipped weapon category projection for combat events.",
    ),
    (
        "PNC_SemanticCombatReactionService",
        "domain_combat_telemetry",
        "Server combat reaction trigger service.",
    ),
    (
        "PNC_SemanticCombatTargetCallouts",
        "domain_combat_telemetry",
        "Combat target threat callout coordinator.",
    ),
    (
        "PNC_SemanticTopicCatalog",
        "adopter_nlu_resolution",
        "Topic classification index shared by memory and dialogue suggestions.",
    ),
    (
        "PNC_ActorConversationContext",
        "domain_actor_context",
        "Builds bounded public actor/world context projections for Hoomans.",
    ),
    (
        "PNC_SemanticActorConversationService",
        "domain_actor_context",
        "Attaches Core ActorConversationService session to Hoomans actor records.",
    ),
    (
        "PNC_SemanticIdentityNetwork",
        "domain_actor_context",
        "Knowledge-graph tracking of survivor identities and acquaintance links.",
    ),
)

# Explicit ConvoEngine-owned Hoomans modules with target module paths under PNC/ConvoEngine/.
_HOOMANS_CONVO_PREFIXES: tuple[tuple[str, str, str, str], ...] = (
    (
        "PNC/Conversation/PSDL/",
        "adopter_psdl_adapter",
        "PNC/ConvoEngine/DialogueBlocks",
        "Adapts generated ConvoEngine dialogue plans to PNC Conversation block definitions.",
    ),
    (
        "PNC/Conversation/Semantic/",
        "adopter_conversation_facade",
        "PNC/ConvoEngine/RuntimeFacade",
        "Conversation-owned facade wiring ConvoEngine dialogue input into conversation UI and group sessions.",
    ),
    (
        "PNC/Semantics/PNC_SpeechRealization",
        "speech_realization",
        "PNC/ConvoEngine/SpeechRealization",
        "Speech realization registry/resolver selecting phrasing families and styles for conversation replies.",
    ),
    (
        "PNC/Semantics/SpeechRealization/",
        "speech_realization",
        "PNC/ConvoEngine/SpeechRealization",
        "Built-in speech realization phrase family pack.",
    ),
    (
        "PNC/Semantics/PNC_SpeechStyleContext",
        "speech_realization",
        "PNC/ConvoEngine/SpeechStyleContext",
        "Deterministic speech-style projection for ConvoEngine realization selection.",
    ),
    (
        "PNC/Semantics/PNC_SemanticToolResultRealization",
        "speech_realization",
        "PNC/ConvoEngine/ToolResultRealization",
        "Maps authoritative tool results to ConvoEngine response pools and realized speech.",
    ),
    (
        "PNC/Semantics/PNC_SemanticUtterancePlan",
        "speech_realization",
        "PNC/ConvoEngine/UtterancePlan",
        "Normalized utterance/style realization plan consumed by conversation presentation.",
    ),
    (
        "PNC/Semantics/PNC_SemanticSpeechDelivery",
        "speech_realization",
        "PNC/ConvoEngine/SpeechDelivery",
        "Delivers selected ConvoEngine speech plans to active conversation or world speech.",
    ),
    (
        "PNC/Semantics/PNC_SemanticConversationSpeechProvider",
        "speech_realization",
        "PNC/ConvoEngine/ConversationSpeechProvider",
        "Conversation speech provider binding ConvoEngine realization to NPC speech.",
    ),
    (
        "PNC/Semantics/PNC_SemanticCompanionSpeech",
        "speech_realization",
        "PNC/ConvoEngine/CompanionSpeech",
        "Realizes companion event/command speech through ConvoEngine.",
    ),
    (
        "PNC/Semantics/PNC_SemanticCombatResponseSurface",
        "interaction_presentation",
        "PNC/ConvoEngine/CombatResponseSurface",
        "Selects and presents combat reaction speech lines via ConvoEngine.",
    ),
    (
        "PNC/Semantics/PNC_SemanticCombatBanterArbiter",
        "interaction_presentation",
        "PNC/ConvoEngine/CombatBanterArbiter",
        "Arbitrates conversation/banter chatter stream budgets and priorities.",
    ),
    (
        "PNC/Semantics/PNC_SemanticDialogue",
        "dialogue_engine",
        "PNC/ConvoEngine/Dialogue",
        "Hoomans ConvoEngine dialogue response, flow, policy, input, suggestions, and realization module.",
    ),
    (
        "PNC/Semantics/PNC_SemanticAutomaticFlow",
        "dialogue_engine",
        "PNC/ConvoEngine/AutomaticFlow",
        "Hoomans ConvoEngine automatic flow generator and manifest.",
    ),
    (
        "PNC/Semantics/SemanticDialogueResponseCatalog/",
        "dialogue_engine",
        "PNC/ConvoEngine/ResponseCatalog",
        "Hoomans ConvoEngine response catalog provider spoke.",
    ),
    (
        "PNC/Semantics/SemanticDialogueSuggestions/",
        "offers_and_chaining",
        "PNC/ConvoEngine/Suggestions",
        "Hoomans ConvoEngine offer/affordance ranking, continuation, and suggestion provider.",
    ),
    (
        "PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows",
        "dialogue_engine",
        "PNC/ConvoEngine/GeneratedAutomaticFlows",
        "Registers generated ConvoEngine automatic dialogue flows.",
    ),
    (
        "PNC/Semantics/PNC_SemanticSocial",
        "interaction_and_social_director",
        "PNC/ConvoEngine/Social",
        "Autonomous social conversation catalog/features/reactions driven by ConvoEngine.",
    ),
    (
        "PNC/Semantics/SemanticSocial/",
        "interaction_and_social_director",
        "PNC/ConvoEngine/Social",
        "Autonomous social conversation director, turn/choice policy, and budget.",
    ),
    (
        "PNC/Semantics/PNC_SemanticInteraction",
        "interaction_and_social_director",
        "PNC/ConvoEngine/Interaction",
        "ConvoEngine interaction scene/behavior/beat director, arbitration, lifecycle, and presentation.",
    ),
    (
        "PNC/Semantics/PNC_SemanticIdentityExchange",
        "dialogue_engine",
        "PNC/ConvoEngine/IdentityExchange",
        "Dialogue-driven mutual identity introduction and disclosure exchange.",
    ),
    (
        "PNC/Semantics/PNC_SemanticConversationCategoryOwnership",
        "dialogue_engine",
        "PNC/ConvoEngine/CategoryOwnership",
        "Maps ConvoEngine dialogue categories to owning mod capabilities.",
    ),
    (
        "PNC/Semantics/PNC_SemanticConversationMemoryProvider",
        "dialogue_engine",
        "PNC/ConvoEngine/MemoryProvider",
        "Projects conversation memory/gossip facts into ConvoEngine dialogue turns.",
    ),
    (
        "PNC/Semantics/PNC_SemanticFoundation",
        "conversation_foundation",
        "PNC/ConvoEngine/Foundation",
        "Hoomans wrapper integrating Core ConvoEngine Foundation.",
    ),
)


def _norm(value: str) -> str:
    return value.replace("\\", "/").lstrip("./")


def _lua_module_from_rel(relative: str) -> str | None:
    parts = PurePosixPath(_norm(relative)).parts
    for index in range(len(parts) - 2):
        if parts[index : index + 3] == ("media", "lua", "shared") or parts[index : index + 3] == ("media", "lua", "client") or parts[index : index + 3] == ("media", "lua", "server"):
            sub = parts[index + 3 :]
            if sub and sub[-1].endswith(".lua"):
                return "/".join(sub[:-1] + (sub[-1][:-4],))
    return None


def _header_summary(text: str) -> str:
    for line in text.splitlines()[:12]:
        stripped = line.strip()
        if stripped.startswith("--"):
            cleaned = stripped.lstrip("-").strip()
            if cleaned:
                return cleaned
        elif stripped and not stripped.startswith("--"):
            break
    return ""


def _owner_prefix_for_module(module: str) -> str:
    if module.startswith("PsychopatzCore/"):
        return "PsychopatzCore"
    if module.startswith("PNC/"):
        return "PNC"
    if module.startswith("DTCommon/"):
        return "DTCommon"
    return module.split("/", 1)[0]


def map_generated_convo_engine_module(module: str) -> str:
    """Map an old <Owner>/Semantics/Generated/Conversation/... module to <Owner>/ConvoEngine/..."""
    owner_prefix = _owner_prefix_for_module(module)
    marker = f"{owner_prefix}/Semantics/Generated/Conversation/"
    if not module.startswith(marker):
        return module
    rest = module[len(marker) :]
    parts = [part for part in rest.split("/") if part]
    # Remove redundant PSDL/Psdl taxonomic segment when present.
    filtered = [part for idx, part in enumerate(parts) if not (part.lower() == "psdl" and idx in (0, 1))]
    # Replace vague literal Catalog leaves (<Parent>/<Domain>/Catalog[__hash]) -> <Parent>/<Domain>[__hash].
    if len(filtered) >= 2 and (filtered[-1] == "Catalog" or filtered[-1].startswith("Catalog__")):
        leaf = filtered[-1]
        domain = filtered[-2]
        if leaf.startswith("Catalog__"):
            domain = f"{domain}__{leaf.split('__', 1)[1]}"
        filtered = filtered[:-2] + [domain]
    return f"{owner_prefix}/ConvoEngine/" + "/".join(filtered)


def _strip_hoomans_prefix(stem: str, prefix: str) -> str:
    if stem.startswith(prefix):
        return stem[len(prefix) :]
    return stem


def _map_hoomans_convo_module(module: str, target_base: str) -> str:
    parts = module.split("/")
    filename = parts[-1]
    if target_base in {"PNC/ConvoEngine/DialogueBlocks", "PNC/ConvoEngine/RuntimeFacade"}:
        return target_base
    if target_base == "PNC/ConvoEngine/SpeechRealization":
        if "Families/" in module:
            return "PNC/ConvoEngine/SpeechRealization/Families/" + filename
        suffix = _strip_hoomans_prefix(filename, "PNC_SpeechRealization")
        if suffix.startswith("_"):
            return "PNC/ConvoEngine/SpeechRealization" + suffix
        return "PNC/ConvoEngine/SpeechRealization"
    if target_base == "PNC/ConvoEngine/ResponseCatalog":
        suffix = _strip_hoomans_prefix(filename, "PNC_SemanticDialogueResponseCatalog_")
        return f"PNC/ConvoEngine/ResponseCatalog/{suffix}"
    if target_base == "PNC/ConvoEngine/Suggestions":
        if filename.startswith("PNC_SemanticDialogueSuggestions_"):
            suffix = _strip_hoomans_prefix(filename, "PNC_SemanticDialogueSuggestions_")
            return f"PNC/ConvoEngine/Suggestions/{suffix}"
        if filename.startswith("PNC_SemanticAffordance"):
            suffix = _strip_hoomans_prefix(filename, "PNC_SemanticAffordance")
            return f"PNC/ConvoEngine/Suggestions/Affordance{suffix}"
        return f"PNC/ConvoEngine/Suggestions/{filename}"
    if target_base == "PNC/ConvoEngine/Social":
        suffix = _strip_hoomans_prefix(filename, "PNC_SemanticSocial")
        return f"PNC/ConvoEngine/Social/{suffix or 'Social'}"
    if target_base == "PNC/ConvoEngine/Dialogue":
        suffix = _strip_hoomans_prefix(filename, "PNC_SemanticDialogue")
        if not suffix:
            return "PNC/ConvoEngine/Dialogue/Dialogue"
        return f"PNC/ConvoEngine/Dialogue/{suffix}"
    if target_base == "PNC/ConvoEngine/AutomaticFlow":
        suffix = _strip_hoomans_prefix(filename, "PNC_SemanticAutomatic")
        return f"PNC/ConvoEngine/{suffix}"
    if target_base == "PNC/ConvoEngine/Interaction":
        suffix = _strip_hoomans_prefix(filename, "PNC_SemanticInteraction")
        return f"PNC/ConvoEngine/Interaction/{suffix or 'Interaction'}"
    return target_base


def _scan_cross_repo_references(
    repositories: Mapping[str, Path],
) -> tuple[dict[str, dict[str, list[str]]], list[dict[str, Any]]]:
    """Scan all repos for require(...) callers and legacy ConvoEngine/PSDL references."""
    callers: dict[str, dict[str, set[str]]] = {}
    legacy_refs: list[dict[str, Any]] = []
    for repo_name, root in repositories.items():
        for ext in ("*.lua", "*.py"):
            for path in sorted(root.rglob(ext)):
                rel = _norm(str(path.relative_to(root)))
                if "/.git/" in f"/{rel}" or "/__pycache__/" in f"/{rel}" or "/.venv/" in f"/{rel}":
                    continue
                if "/Semantics/Generated/" in rel:
                    continue
                try:
                    text = path.read_text(encoding="utf-8")
                except (OSError, UnicodeDecodeError):
                    continue
                is_test = rel.startswith("tests/") or "/tests/" in f"/{rel}"
                bucket = "tests" if is_test else ("tools" if rel.startswith("tools/") else "production")
                caller_id = f"{repo_name}:{rel}"
                for match in _LUA_REQUIRE_RE.finditer(text):
                    mod = match.group(1)
                    callers.setdefault(mod, {"production": set(), "tests": set(), "tools": set()})[bucket].add(caller_id)
                for match in _PY_MODULE_STRING_RE.finditer(text):
                    mod = match.group(1)
                    callers.setdefault(mod, {"production": set(), "tests": set(), "tools": set()})[bucket].add(caller_id)
                tokens = []
                if "Semantics/Generated/Conversation" in text:
                    tokens.append("Semantics/Generated/Conversation")
                if "Conversation/PSDL" in text or "PNC_ConversationPSDLBlocks" in text:
                    tokens.append("Conversation/PSDL")
                if "PSDL_PLANS" in text or "PSDL_RESPONSE_TEMPLATES" in text:
                    tokens.append("PSDL_PLANS")
                if tokens and not (rel.startswith("Docs/") or rel.startswith("docs/")):
                    legacy_refs.append({
                        "repository": repo_name,
                        "path": rel,
                        "layer": bucket,
                        "tokens": tokens,
                    })
    normalized_callers = {
        mod: {bucket: sorted(items) for bucket, items in buckets.items()}
        for mod, buckets in callers.items()
    }
    return normalized_callers, legacy_refs


def _classify_core_module(module: str, requires: list[str], text: str) -> dict[str, Any] | None:
    if module.startswith("PsychopatzCore/ConvoEngine/"):
        return {
            "classification": "convo_engine",
            "subDomain": "migrated_convo_engine",
            "migrationDisposition": "migrated_to_convo_engine",
            "proposedModule": module,
            "reasons": [
                "Migrated Core ConvoEngine module at canonical PsychopatzCore/ConvoEngine/* namespace (S6M2B).",
            ],
        }
    if module.startswith("PsychopatzCore/Semantics/Generated/Conversation/"):
        target = map_generated_convo_engine_module(module)
        return {
            "classification": "convo_engine",
            "subDomain": "generated_convo_engine",
            "migrationDisposition": "migrate_generated_to_convo_engine",
            "proposedModule": target,
            "reasons": [
                "Generated by Core conversation_compiler.py under Semantics/Generated/Conversation.",
                f"S6M2B routes ConvoEngine generated output directly to {target}.",
            ],
        }
    if module.startswith("PsychopatzCore/Semantics/Generated/Lexicon/"):
        return {
            "classification": "generic_semantic_infrastructure",
            "subDomain": "lexicon_nlu",
            "migrationDisposition": "retain_under_semantics",
            "proposedModule": module,
            "reasons": [
                "Generated by lexicon_compiler.py (concept aliases and verb forms for NLU parsing, broader than conversation).",
            ],
        }
    if module.startswith("PsychopatzCore/Semantics/"):
        stem = module.split("/")[-1]
        rule = _CORE_SEMANTICS_RULES.get(stem)
        if rule is not None:
            classification, sub_domain, disposition, proposed, reason = rule
            reasons = [reason]
            if any("Generated/Conversation" in req or "Dialogue" in req for req in requires):
                reasons.append("Imports/bridges conversation-engine modules in current source.")
            return {
                "classification": classification,
                "subDomain": sub_domain,
                "migrationDisposition": disposition,
                "proposedModule": proposed or module,
                "reasons": reasons,
            }
    if module.startswith("PsychopatzCore/Conversation/"):
        # Host conversation shell, UI text catalogs, and legacy node registry remain in place,
        # but we record references when they consume Core Semantics or ConvoEngine modules.
        if any("PsychopatzSemantic" in req or "Generated/Conversation" in req for req in requires) or "DialogueState" in text or "DialogueRouter" in text:
            return {
                "classification": "generic_semantic_infrastructure",
                "subDomain": "host_conversation_shell",
                "migrationDisposition": "retain_in_place_update_references",
                "proposedModule": module,
                "reasons": [
                    "Host Conversation UI/service/registry shell; stays under PsychopatzCore/Conversation/ and updates references to ConvoEngine modules.",
                ],
            }
    return None


def _classify_hoomans_module(module: str, requires: list[str]) -> dict[str, Any] | None:
    if module.startswith("PNC/ConvoEngine/"):
        return {
            "classification": "convo_engine",
            "subDomain": "migrated_convo_engine",
            "migrationDisposition": "migrated_to_convo_engine",
            "proposedModule": module,
            "reasons": [
                "Migrated ProjectHoomans ConvoEngine module at canonical PNC/ConvoEngine/* namespace (S6M2B).",
            ],
        }
    if module.startswith("PNC/Semantics/Generated/Conversation/"):
        target = map_generated_convo_engine_module(module)
        return {
            "classification": "convo_engine",
            "subDomain": "generated_convo_engine",
            "migrationDisposition": "migrate_generated_to_convo_engine",
            "proposedModule": target,
            "reasons": [
                "Adopter-owned ConvoEngine generated Lua emitted by Core conversation_compiler.py.",
                f"S6M2B routes to {target} and replaces Catalog.lua leaves with semantic names.",
            ],
        }
    for prefix, sub_domain, target_base, reason in _HOOMANS_CONVO_PREFIXES:
        if module.startswith(prefix):
            return {
                "classification": "convo_engine",
                "subDomain": sub_domain,
                "migrationDisposition": "migrate_module_to_convo_engine",
                "proposedModule": _map_hoomans_convo_module(module, target_base),
                "reasons": [
                    reason,
                    "Exports or consumes ConvoEngine dialogue plans, offers, social turns, or realization.",
                ],
            }
    if module.startswith("PNC/Semantics/"):
        rel_after = module[len("PNC/Semantics/") :]
        for prefix, sub_domain, reason in _HOOMANS_NON_CONVO_PREFIXES:
            if rel_after.startswith(prefix):
                needs_ref_update = any(
                    "Generated/Conversation" in req or "PsychopatzSemanticDialogue" in req or "PsychopatzSemanticOffer" in req
                    for req in requires
                )
                return {
                    "classification": "generic_semantic_infrastructure",
                    "subDomain": sub_domain,
                    "migrationDisposition": (
                        "retain_in_place_update_references" if needs_ref_update else "retain_under_semantics"
                    ),
                    "proposedModule": module,
                    "reasons": [reason],
                }
    if module.startswith("PNC/Conversation/") and any("Generated/Conversation" in req or "PSDL" in req or "PNC/Semantics/PNC_SemanticDialogue" in req or "PNC/Semantics/PNC_SpeechRealization" in req for req in requires):
        return {
            "classification": "generic_semantic_infrastructure",
            "subDomain": "host_conversation_shell",
            "migrationDisposition": "retain_in_place_update_references",
            "proposedModule": module,
            "reasons": [
                "Host PNC/Conversation composer/authority/UI module; stays in place and updates ConvoEngine require targets.",
            ],
        }
    return None


def _classify_dt_module(module: str, requires: list[str]) -> dict[str, Any] | None:
    if module.startswith("DTCommon/ConvoEngine/"):
        return {
            "classification": "convo_engine",
            "subDomain": "migrated_convo_engine",
            "migrationDisposition": "migrated_to_convo_engine",
            "proposedModule": module,
            "reasons": [
                "Migrated DynamicTrading ConvoEngine module at canonical DTCommon/ConvoEngine/* namespace (S6M2B).",
            ],
        }
    if module.startswith("DTCommon/Semantics/Generated/Conversation/"):
        target = map_generated_convo_engine_module(module)
        return {
            "classification": "convo_engine",
            "subDomain": "generated_convo_engine",
            "migrationDisposition": "migrate_generated_to_convo_engine",
            "proposedModule": target,
            "reasons": [
                "DTCommon ConvoEngine generated Lua emitted by Core conversation_compiler.py.",
                f"S6M2B routes to {target} and drops Psdl/Catalog wrapper segments.",
            ],
        }
    if module == "DTCommon/DTCommon_SemanticPack":
        return {
            "classification": "generic_semantic_infrastructure",
            "subDomain": "adopter_semantic_pack",
            "migrationDisposition": "retain_in_place_update_references",
            "proposedModule": module,
            "reasons": [
                "Registers DTCommon trader NLU concepts/speech-acts/patterns/providers via Semantics.RegisterPack while consuming generated DTCommon ConvoEngine registry.",
            ],
        }
    if module in {
        "DTCommon/DTCommon_TraderConversation",
        "DTAbstract/DTAbstract_CoreConversation",
        "DTHoomans/DTHoomans_Conversation",
    }:
        needs_update = any("Semantics/" in req or "Foundation" in req for req in requires)
        return {
            "classification": "generic_semantic_infrastructure",
            "subDomain": "host_conversation_shell",
            "migrationDisposition": (
                "retain_in_place_update_references" if needs_update else "retain_in_place_update_references"
            ),
            "proposedModule": module,
            "reasons": [
                "DynamicTrading conversation transport/opening adapter; keeps existing mod namespace and updates ConvoEngine Foundation/Registry requires.",
            ],
        }
    return None


def _collision_audit(
    repositories: Mapping[str, Path],
    records: list[dict[str, Any]],
) -> dict[str, Any]:
    existing_convo_engine_files: list[str] = []
    for repo_name, root in repositories.items():
        for path in sorted(root.rglob("*ConvoEngine*")):
            rel = _norm(str(path.relative_to(root)))
            if "/.git/" in f"/{rel}":
                continue
            existing_convo_engine_files.append(f"{repo_name}:{rel}")

    target_owners: dict[str, list[str]] = {}
    for item in records:
        if item["classification"] == "convo_engine":
            target = str(item["proposedModule"])
            target_owners.setdefault(target, []).append(f"{item['repository']}:{item['module']}")

    target_collisions = {
        target: sources for target, sources in sorted(target_owners.items()) if len(sources) > 1
    }
    has_unmigrated_convo = any(
        item["classification"] == "convo_engine"
        and item.get("migrationDisposition") != "migrated_to_convo_engine"
        for item in records
    )
    return {
        "existingConvoEnginePaths": existing_convo_engine_files,
        "targetPathCollisions": target_collisions,
        "collisionSafe": (
            not target_collisions
            and (not existing_convo_engine_files or not has_unmigrated_convo)
        ),
    }


def build_ownership_inventory(
    repositories: Mapping[str, Path],
    *,
    generated_at: str | None = None,
) -> dict[str, Any]:
    """Build machine-readable S6M2A ownership inventory across Core, ProjectHoomans, and DynamicTrading."""
    callers, legacy_refs = _scan_cross_repo_references(repositories)
    records: list[dict[str, Any]] = []
    repo_reports: list[dict[str, Any]] = []

    for repo_name in REPO_NAMES:
        root = Path(repositories[repo_name]).expanduser().resolve()
        lua_files = sorted(root.glob("Contents/mods/*/common/media/lua/**/*.lua")) + sorted(
            root.glob("Contents/mods/*/42.20/media/lua/**/*.lua")
        )
        repo_count = 0
        for path in lua_files:
            rel = _norm(str(path.relative_to(root)))
            module = _lua_module_from_rel(rel)
            if not module:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            requires = sorted(set(_LUA_REQUIRE_RE.findall(text)))
            if repo_name == CORE_OWNER:
                decision = _classify_core_module(module, requires, text)
            elif repo_name == HOOMANS_OWNER:
                decision = _classify_hoomans_module(module, requires)
            else:
                decision = _classify_dt_module(module, requires)
            if decision is None:
                continue
            mod_callers = callers.get(module, {"production": [], "tests": [], "tools": []})
            exports = sorted(set(_GLOBAL_ASSIGN_RE.findall(text)))
            records.append({
                "repository": repo_name,
                "path": rel,
                "module": module,
                **decision,
                "evidence": {
                    "headerSummary": _header_summary(text),
                    "requires": requires,
                    "exports": exports[:16],
                    "callerCounts": {
                        bucket: len(items) for bucket, items in mod_callers.items()
                    },
                    "sampleCallers": {
                        bucket: items[:8] for bucket, items in mod_callers.items() if items
                    },
                },
            })
            repo_count += 1
        repo_reports.append({
            "name": repo_name,
            "root": str(root),
            "inventoriedModuleCount": repo_count,
        })

    records.sort(key=lambda item: (item["repository"], item["module"]))
    collisions = _collision_audit(repositories, records)
    class_counts = Counter(item["classification"] for item in records)
    disp_counts = Counter(item["migrationDisposition"] for item in records)
    sub_counts = Counter(item["subDomain"] for item in records)

    return {
        "schema": OWNERSHIP_INVENTORY_SCHEMA,
        "phase": "S6M2A",
        "generatedAtUtc": generated_at or datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "repositories": repo_reports,
        "collisionCheck": collisions,
        "summary": {
            "totalInventoriedModules": len(records),
            "classifications": dict(sorted(class_counts.items())),
            "migrationDispositions": dict(sorted(disp_counts.items())),
            "subDomains": dict(sorted(sub_counts.items())),
            "legacyReferenceFileCount": len(legacy_refs),
        },
        "modules": records,
        "legacyReferences": legacy_refs,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core", type=Path, required=True)
    parser.add_argument("--hoomans", type=Path, required=True)
    parser.add_argument("--dt", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    options = parser.parse_args(argv)
    report = build_ownership_inventory({
        CORE_OWNER: options.core,
        "ProjectHoomans": options.hoomans,
        "DynamicTrading": options.dt,
    })
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if options.output:
        options.output.parent.mkdir(parents=True, exist_ok=True)
        options.output.write_text(rendered, encoding="utf-8", newline="\n")
    else:
        print(rendered, end="")
    return 0 if report["collisionCheck"]["collisionSafe"] else 1


__all__ = [
    "OWNERSHIP_INVENTORY_SCHEMA",
    "build_ownership_inventory",
    "map_generated_convo_engine_module",
]


if __name__ == "__main__":
    raise SystemExit(main())
