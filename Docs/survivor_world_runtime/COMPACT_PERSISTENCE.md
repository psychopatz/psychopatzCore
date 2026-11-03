# Compact Persistence Contract

## Objective

Keep large abstract populations cheap in GlobalModData while preserving identity, portraits, traversal, affiliation, durable relationships and the ability to hydrate the same actor into ProjectHoomans.

## Current baseline

Core ActorRegistry:Create currently stores:

`actor.personalInventory = inventory:ToPayload("FULL")`

for every actor.

Core ActorInventory already supports SEED_ONLY, BASELINE_DELTA and FULL.

Core generated appearance is deterministic, but current actor state persists policy, resolved appearance and contract together.

## Storage rule

Persist a value only if:

1. it cannot be reconstructed deterministically; or
2. it is a durable delta from baseline; or
3. it is required for identity/provider/world continuity; or
4. it is bounded world state that must advance without a body.

Everything else is runtime/cache.

## Compact actor envelope

Target persisted sections:

- schema/version/revision;
- actorID;
- identity seed + minimal durable identity;
- appearance seed/profile/version + sparse authored/durable delta;
- affiliation references;
- role/tags;
- provider lease;
- durable condition flags;
- optional individual world override;
- bounded non-default social/knowledge/persona deltas;
- personalInventory in smallest safe mode.

Default/empty sections should be omitted from serialized form and reconstructed during decode.

## Inventory policy

### SEED_ONLY

Default for untouched deterministic actors.

Persist seed/baseline version and only irreducible equipment contract.

Do not persist every generated item.

### BASELINE_DELTA

Use after durable mutations.

Persist deterministic baseline identity plus compact/coalesced item/equipment deltas.

Mutation history must not grow forever.

### FULL

Use only when exact state cannot safely round-trip as seed+delta, such as unsupported/imported/non-deterministic state.

FULL is never the default merely because an actor exists.

## Appearance policy

Generated appearance: persist seed/profile/generator version + durable overrides.

Authored appearance: persist exact authored policy/delta required for reconstruction.

Transient blood/dirt/animation/body scratch state remains runtime unless explicitly promoted.

## Social/knowledge boundedness

- bounded memory count;
- bounded knowledge facts;
- omit deterministic/default persona where possible;
- sparse relationships only when non-default/material;
- explicit eviction/compaction;
- shared group/faction/community facts are referenced, not copied into every actor.

## Group compression

Group owns shared journey, destination, mission and lifecycle.

Actor owns groupID, role/rank, and optional personal exception.

A ten-person caravan must not persist ten copies of the route.

## Runtime denylist

Canonical persistence rejects/strips:

- engine body object references;
- AI blackboards;
- behavior trees;
- path nodes;
- combat target refs;
- animation state;
- perception caches;
- transient task internals;
- per-tick needs micro-state unless deliberately promoted to coarse durable condition;
- UI/debug/network caches.

## Hydration

Abstract actors do not hydrate full inventory, live AI, needs, pathing or body visuals beyond portrait reconstruction.

Hoomans hydrates these only when physical simulation is required.

## Dehydration

Before body release:

1. capture final position;
2. capture durable condition/appearance changes;
3. compact inventory;
4. capture durable social/knowledge changes;
5. rebase group/actor journey;
6. discard runtime state;
7. release body lease.

## Size telemetry

Measure serialized bytes for:

- empty world;
- 10/100/500/1000 actors;
- groups of 1/5/10/25;
- generated/authored appearance;
- SEED_ONLY/BASELINE_DELTA/FULL inventory;
- abstract-only;
- mixed abstract/materialized;
- save/reload round-trip.

S0 must replace provisional limits with measured budgets.

Initial provisional target:

- untouched abstract actor average <= roughly 2 KiB incremental serialized Core state, excluding shared faction/community/group records;
- zero FULL inventory payloads for untouched abstract actors;
- shared group journey adds approximately O(1) journey storage, not O(member count);
- provider runtime adds zero canonical serialized bytes.

Every new canonical field requires owner/classification, serialization reason, boundedness, migration behavior and size-impact coverage.
