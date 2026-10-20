# Portable NPC Conversation — System Ownership and Execution Contracts

## Existing authority: preserve, extend, do NOT duplicate

| Domain | Owner | Adopter behavior |
| --- | --- | --- |
| Canonical actor ID, identity seed, appearance, voice, personal inventory, provider lease, world, location | PsychopatzCore Actors Factory/Registry/Persistence/Provider | Hoomans body and DT abstract/physical adapters project fields, never copy into independent canonical NPC |
| Shared personality, directional relationship, limited event memory | Core `PsychopatzSocial` | Hoomans and DT project/emit authorized events, preserve player identity mapping |
| Generic seeded stable-ID backstory and portable personal facts | NEW Core extension of actor/identity contracts, reviewing existing Hoomans `PNC.Conversation.Memory` without replacing its existing data blindly | Mod-registered, versioned catalogs; special Hoomans lore and quests remain Hoomans-owned |
| Server-authoritative player-character-scoped personal Knowledge/evidence/disclosure | NEW shared Core service evolved from vetted Hoomans `PNC.NPCKnowledge` contracts | Keep Hoomans special Knowledge descriptors and Dossier compatibility; DTO clients receive authorized projections only |
| Semantic ParseCandidates, IR, DialogueRouter, DialogueState | Existing Core Semantics | Add portable *contextual turn interpretation/response plan* atop existing router; Hoomans flow hooks remain registered adapters |
| Generic offline replies, agenda/causal context, conversation memory | NEW Core-owned reusable Conversation service using existing Core Semantics and translation | User-facing text from keyed localized response plans, fail-closed fact admission; no runtime LLM requirement |
| Custom translation keys and interpolation | Existing Core CustomTranslationManager, adopter registered catalogs | Reuse EN/TL; no new runtime translation dictionary/Tagalog hardcoding |
| Generic CodeBlocks authoring, graph/compiler/writer, real Lua-worker inspection | Existing Hoomans Semantic Lab/CodeBuilder | Extend service to emit registered portable Core content and adopter packs in correct media folders. One compiler, not a second Core authoring tool |
| Hoomans physical NPC, needs/health/zombie combat, colony/factions, companion actions, quest authority, special NPC Dossier | ProjectHoomans | Registered context/fact/capability providers, Hoomans view/presentation only |
| Merchant stock, budget, MarketSense, quotes, trade access and commit | DTCommon | ActorID ↔ traderID mapping, registered merchant capability; no personal-inventory/stock conflation |
| Abstract radio contact/authenticated channel | DTAbstract | Calls Core conversation API with RADIO channel and Core actor, never runs separate parser or authorizes physical trade |
| Materialized merchant body and interaction | DTHoomans + Hoomans lifecycle | Same Core actorID and conversation state; body provider lease, not duplicate actor |

## Shared Core API, proposed NOT YET IMPLEMENTED

A versioned, bounded and server-authorized facade (illustrative shape; final names decided after source audit):

```lua
Core.Conversation.ProcessTurn({
  actorID = actorID, characterUUID = playerCharacterUUID,
  sessionKey = boundedSessionID,
  channel = "RADIO", -- or NEARBY, Core-only fixture
  text = playerUtterance,
  access = authoritativeChannelProof,
})
-- returns bounded: semantic IR/parts, responsePlan, translationKey+args,
-- factRefs/status/provenance, pending agenda, proposed capabilities, trace
-- never auto-commits a gameplay effect without owning server authorization
```

Authorization is separate: authenticate player identity and channel BEFORE conversation; Core server checks actor and lease, presence/radio capability, stale channel/session versions, supplied actor/player binding. Domain intents are proposed capabilities with ownership tags, not client-executable commands. Hoomans executes legitimate companion/quest actions; DTCommon independently validates trade sessions and orders. Talk over radio does NOT imply remote instant stock transfer or inventory interaction. No game Java objects cross Core API or persist.

## Contextual semantic policy

Use existing Core `Parser.ParseCandidates`, `DialogueRouter`, `DialogueState` and Hoomans Flow/ResponsePlan as migration reference. Preserve:
- A **pending dialogue act** keyed by actor+player character, topic, asked question, expected answer types, flow provenance and bounded turn expiry.
- One input may contain **multiple clauses** (e.g. WELLBEING self-answer + reciprocal WELLBEING question); process in a bounded order with a single final localized NPC response and explicit side-effect admission.
- References such as `why is that`, `what about you`, `where`, `and then` require antecedent resolution against the last authoritative proposition/response, topic and recent named referents; never invent a cause for unknown residence/health.
- Distinguish answer to NPC-initiated question, user-initiated query, interruption, clarification, refusal, fallback; retain ability to resume pending topics. Do not equate flow-owned generated speech with an arbitrary THANK-only expected response.
- Policies stay domain-independent and constrained by confirmed/unknown/suspected authoritative facts; response text uses existing translation keys, plus appropriate Core/adopter registered localized assets.

## Minimal persistence

Stable `actorID` and `identitySeed`, versioned generator and selected stable definition IDs, explicit authored overrides and sparse deltas. Keep bounded Social and event refs; player Knowledge by persistent character UUID with learned fact ID, observed payload/provenance, confidence/status and revision. No full rendered biography per actor, no unbounded chat history, no tick-based recomputation of language or personality. Pending context is bounded/recoverable session state where necessary, not a copy of raw transcript. Measure same serializer 0/1/10 discoveries, 100/1000 actor fixtures, and cache limits.

## Non-goals

Do NOT wholesale migrate Hoomans quest/colony facts/physical simulation into Core, copy merchant stock into actor personal inventory, build another parser/compiler/translation manager/GUI/Knowledge store, mandate PBrainZ, or claim native Project Zomboid testing without the user. All new work uses preexisting `main` in each repository and no new branches.
