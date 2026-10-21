# Grounded World Knowledge & Gossip

Status: PLANNED / IMPLEMENTATION NOT YET ACCEPTED
Canonical owner: PsychopatzCore for reusable fact/knowledge mechanisms.
Adopters: ProjectHoomans and DynamicTrading.
Planning baseline: Core 159df9e2f12cb4a3911f50d6c27dcc1d48a861fc; ProjectHoomans 2bcefd74d3c46df0f707467a7e9b8a6ba42cb185; DynamicTrading 938721fa538a13845684acb22a5468fe0a9dc9e5.

## Product goal

Build one grounded World Knowledge Network so NPCs talk about things that actually happened in the Project Zomboid world instead of generating baseless random gossip.

Authoritative systems produce compact typed facts. Actors learn only facts they can legitimately know through experience, witnessing, faction/public dissemination, radio, or another actor. Conversation then projects a bounded set of relevant known facts into the existing shared Core/Hoomans dialogue path. Offline semantics and optional PBrainZ receive the same authorized facts. DynamicTrading uses the same Core actor knowledge rather than a second trader rumor store.

The system must support, at minimum, grounded information about:
- NPC/faction incidents such as member death, severe attack, rescue, war/peace and faction destruction when the owning domain can prove them;
- nearby zombie pressure using existing Hoomans WorldCensus/Spatial/Perception caches, never a new global zombie scan;
- Project Zomboid environmental state such as helicopter activity, power, water and season through audited authoritative game adapters;
- later DynamicTrading facts such as trader arrival/departure, route disruption and market observations without moving trade authority into Core.

## Core rule

A world event is not gossip. Gossip is an actor's knowledge of a world event.

Truth, knowledge, communication and presentation stay separate:
- authoritative owner: what actually happened;
- WorldFact: compact stable event/state reference;
- actor knowledge reference: who knows it, how and with what confidence;
- propagation: how another actor may learn it;
- realization: localized sentence generated only when needed.

Never persist localized gossip prose as canonical truth.

## Existing accepted foundation

Do not rebuild these:
- Core portable actors, identity, relationships, player-scoped Knowledge, provider leases and shared contextual conversation are developer-accepted C1-C6 foundations.
- Hoomans already has bounded WorldCensus/SpatialIndex/Perception threat counting, zombie horde awareness memories, faction incident authority, relationship memories, a deterministic GOSSIP semantic branch, npcGossip.statements projection and optional PBrainZ consumption.
- DynamicTrading already binds one trader to one Core actor across DTAbstract/DTHoomans and exposes shared Core Talk while preserving DTCommon stock/budget/trade authority.

## Documents

Read in this order for this goal:
1. AGENT_RUNBOOK.md
2. PROGRESS.md
3. ARCHITECTURE.md
4. ROADMAP.md
5. HARNESS_ACCEPTANCE.md
6. ProjectHoomans adopter audit/contract under docs/Jobs/GroundedWorldKnowledgeGossip/
7. DynamicTrading adopter contract under Docs/world_knowledge_gossip/

The executable /goal prompt is chat-only and must not be committed.
