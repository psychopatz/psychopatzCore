# Portable Actor Lifecycle & Social Garbage Collection

**Status:** PLANNED — multi-repository implementation not started.
**Primary repository:** PsychopatzCore.
**Participants:** ProjectHoomans and DynamicTrading (DTCommon, DTAbstract, DTHoomans).

## Parent objective

Build one portable, server-authoritative actor lifecycle and garbage-collection architecture that lets Project Hoomans, DynamicTrading/DTAbstract, and future mods retire dead/permanently removed actors without leaving unbounded ModData or dangling references, while preserving only the social consequences and historical identity that still matter.

The system must support:

- NPC -> NPC, NPC -> player-character, and explicit player -> NPC/player references;
- live actors, retired identities, and eventual purge;
- meaningful memories of dead/departed actors without keeping full simulation state;
- sparse directional relationships;
- a bounded per-actor social memory budget rather than a per-relationship memory multiplier;
- portable STRONG / WEAK / LABEL_ONLY actor-reference semantics;
- provider-extensible GC roots for quests, debts, bonds, factions, corpses, contracts, and future mods;
- mark-and-sweep cleanup without persistent reference counts;
- server-authoritative multiplayer lifecycle and revision revalidation;
- semantic projections that degrade gracefully from LIVE -> RETIRED -> FORGOTTEN;
- interaction paths that never perform whole-world GC or full-history reconstruction.

## Core principle

**Preserve consequences, not objects.**

When an actor dies or is permanently retired, remove expensive live state. Surviving actors may retain a compact historical relationship, meaningful memories, unresolved grievances, debts, bonds, or knowledge. A tiny Core tombstone survives only while strong references require identity resolution. When no strong root remains and grace/GC policy allows, the tombstone is purged.

## Why Core owns the mechanism

Current source evidence already shows:

- PsychopatzCore owns ActorRegistry, stable actor identity, player-character identity, provider leases, portable social state, persistence, and CodeBuilder;
- Core ActorRegistry currently has a hard Remove(actorId) path and no general tombstone/reference-GC layer;
- Portable Social State currently stores up to 64 memories per relationship, which is bounded locally but can still grow as meaningful relationships multiplied by 64;
- Project Hoomans already has lightweight death markers/corpse lifecycle and removes full NPC records at death;
- DynamicTrading has trader-record removal and direct Core actor removal in migration/import paths.

## Non-goals

- no global permanent event ledger;
- no persistent reverse-reference graph or manual refcount authority;
- no dense all-actor relationship matrix;
- no full dead-actor archive;
- no per-frame/full-world GC;
- no Event/Opportunity Director or autonomy brain implementation;
- no LLM dependency;
- no automatic inference of human-player emotion;
- no replacement of Hoomans corpse/reanimation gameplay or DT commercial authority;
- no native Project Zomboid launch or Workshop publication for developer acceptance.

## Completion boundary

The complete L0-L9 roadmap in ROADMAP.md is the developer-side completion boundary.

A Core-only tombstone implementation is incomplete until Hoomans death/corpse flow, player-character death/reconnect, DTAbstract/DTHoomans/trader lifecycle, semantic queries, save/reload, and scale/GC acceptance are proven.

## Read order

1. root AGENTS.md of every participant;
2. this README;
3. PROGRESS.md and HANDOFF.md;
4. relevant AGENT_RUNBOOK.md procedure;
5. active ROADMAP.md phase;
6. relevant ARCHITECTURE.md contract;
7. exact current source/tests.
