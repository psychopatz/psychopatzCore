# Roadmap — Portable Actor Lifecycle & Social Garbage Collection

**Parent status:** PLANNED.
**Primary repository:** PsychopatzCore.
**Participants:** ProjectHoomans, DynamicTrading.
**Completion boundary:** L0-L9 developer-side acceptance.
**Native SP/MP acceptance:** user-owned after all developer gates.

## L0 — Cross-repository lifecycle/reference/footprint audit

Audit:

- every Core ActorRegistry hard-remove caller;
- player-character identity lifetime/death/reconnect;
- provider leases/materialization;
- Portable Social relationship/memory persistence and footprint;
- Hoomans Health.Kill, RemoveRecord, corpse/reanimation, DeathMarkers, bonds/factions/quests;
- DT trader removal, migration, provider paths, debts/contracts if present;
- semantic/interaction identity queries;
- CodeBuilder Social Policy extension seams;
- every persisted actor ref that can keep history reachable.

Measure representative 0/10/100/1000 actor save sizes and worst-case relationship-memory multiplication.

**Gate:** one source-verified map classifies every removal/ref as rollback-hard-delete, lifecycle-retire, STRONG, WEAK, LABEL_ONLY, transient/cache, or obsolete.

## L1 — Core ActorRef lifecycle and tombstones

Implement portable lifecycle for Core actors and persistent player-character refs:

- lifecycle state/revision;
- minimal tombstone schema/persistence;
- server-authoritative Retire;
- explicit rollback hard-delete;
- LIVE/RETIRED/FORGOTTEN identity projection;
- grace/minimum-purge metadata;
- versioned migration.

**Gate:** Core-only tests retire NPC/player refs, release full live state, reload tombstones, reject stale/client mutation, and preserve hard delete only for proven rollback.

## L2 — Reference providers and budgeted mark/sweep

Implement:

- bounded provider registry;
- strong/weak roots;
- no persistent refcount authority;
- mark/sweep generations;
- grace;
- budget cursor/slices;
- orphan/alias cleanup;
- ExplainRetention/ExplainPurge;
- fail-closed provider validation.

**Gate:** strong roots retain, expired unreferenced tombstones purge, provider failure cannot partially delete state, and large stores process incrementally.

## L3 — Actor-level social memory bank and historical edges

Migrate from persisted per-relationship memories to one bounded actor-level memory bank.

Requirements:

- measured total/SHORT/LONG/ANCHOR budgets;
- deterministic migration;
- consolidation/baseline promotion parity;
- ephemeral target/class/event indexes;
- historical edge compaction;
- lifecycle revision metadata;
- prune zero/default edges;
- no permanent dual memory representation.

**Gate:** hundreds of contacts remain bounded by actor memory budget; anchors/grievances survive; low-value dead-target edges disappear; save/load and semantic query parity pass.

## L4 — Reference strength in CodeBuilder Social Policy

Extend existing Social Policy IR with STRONG/WEAK/LABEL_ONLY metadata.

Validate bounded role fan-out, retention/reference compatibility, owner routing, deterministic generation, and source maps.

**Gate:** Core/Hoomans/DT fixtures compile deterministically; malformed/unbounded refs fail closed; portable IR contains no adopter implementation calls.

## L5 — Project Hoomans adoption

Bridge Health.Kill/retirement to Core lifecycle while preserving corpse/death-marker/reanimation authority.

Register only verified durable Hoomans roots such as active corpse/reanimation identity, durable bond/family/romance, active quest/memorial/faction refs.

**Gate:** death removes full PNC/live Core state, leaves only warranted history, corpse/reanimation works, survivor memories/bonds work, irrelevant dead NPC identity later collects.

## L6 — Player-character death and multiplayer identity

Wire authoritative character death.

Prove reconnect same living character, death retirement, new-character identity, survivor memories, no automatic relationship transfer, account reputation separation, stale interaction invalidation, and client mutation rejection.

**Gate:** SP/MP fixtures cover death/reconnect/new character/save/reload/cross-account safety with no dangling refs.

## L7 — DynamicTrading / DTAbstract / DTHoomans adoption

Classify/fix:

- rollback trader deletion;
- commercial-role removal;
- true actor death/permanent retirement;
- superseded migration actor;
- real debt/contract roots if present.

**Gate:** Core+DTAbstract works without PNC; role removal does not fabricate death; migration creates no fake tombstone; meaningful trader history and DTHoomans continuity survive correctly.

## L8 — Semantic/interaction integration

Add lifecycle-aware identity/social projections:

- immediate hot snapshot;
- no GC on click;
- bounded SocialQueryPlan;
- lifecycle/social/relationship revisions;
- RETIRED/FORGOTTEN graceful degradation;
- no raw tombstone/memory access by semantic content.

**Gate:** LIVE, recently dead, historical named, and purged/label-only targets all produce bounded valid context and interaction stays within measured budget.

## L9 — Scale, persistence, GC soak and final acceptance

Stress thousands of actors, sparse contacts, hundreds/thousands of retirements, player deaths/reconnects, repeated events, anchor-heavy/weak history, long world time, save/reload, and mixed installs.

Acceptance:

- storage scales with live actors + sparse meaningful edges + bounded actor memory + referenced tombstones;
- dead outgoing state is reclaimed;
- no dangling refs;
- no population-squared state;
- no per-tick full GC;
- budgeted GC remains bounded;
- interaction/semantic latency does not materially regress;
- CodeBuilder reconcile/determinism clean;
- Core/Hoomans/DT relevant regressions and Kahlua/static checks pass;
- source saves untouched;
- no native/Workshop automation.

Only after L9 mark READY FOR USER LIVE TEST.

## Stop rules

A phase is not the parent completion boundary.

After each accepted phase:

1. reconcile participant docs;
2. stage only phase-owned paths;
3. commit participant repositories first if changed;
4. update Core HANDOFF with exact participant commit vector;
5. commit Core last;
6. verify unrelated dirty work remains preserved;
7. continue automatically.

Do not push, reset, stash, discard unrelated work, or create adopter-owned parallel GC/tombstone/social databases.
