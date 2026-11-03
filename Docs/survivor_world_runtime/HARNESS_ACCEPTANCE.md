# Acceptance — Compact Survivor World Runtime

## Evidence classes

Use source/static, serialized-footprint benchmark, deterministic unit, migration round-trip, provider contract, split authority/client, production composition, persistence/restart, cross-repository regression, native SP and native MP evidence.

## S0 footprint baseline — ACCEPTED

Production encoder measurements are in `S0_BASELINE.md/json`.

At 1000 generated actors:

- current FULL actor: **3041.12 bytes/actor**;
- same schema with SEED_ONLY inventory: **2664.12 bytes/actor**.

Top sections in the representative actor:

- FULL personalInventory: 1117 bytes;
- SEED_ONLY personalInventory: 740 bytes;
- appearance: 455 bytes;
- identity: 423 bytes;
- providerLease: 271 bytes;
- world: 238 bytes;
- social: 143 bytes;
- persona: 108 bytes;
- knowledge: 46 bytes.

A 25-member route benchmark used 869 bytes shared versus 11,337 bytes duplicated per member.

### Locked budgets

- untouched compact actor after S1+S2: **<= 1900 bytes/actor average at 1000 actors**;
- untouched actors: **0 FULL inventory payloads**;
- generated-default appearance after S2: **<= 180 bytes/actor canonical serialized contribution**;
- provider runtime: **0 canonical bytes**;
- shared journey: approximately O(1) journey state with member count.

## S1 compact actor acceptance

Required:

- ActorRegistry:Create defaults to SEED_ONLY personal inventory;
- rich in-memory actor API remains compatible;
- persistence schema is versioned;
- supported schema-v1 actors decode without reset/loss;
- migration never converts FULL to compact unless deterministic equivalence is proven;
- unsafe/unsupported inventory remains FULL rather than losing state;
- save/reload identity, appearance, social, world and provider parity;
- untouched actor footprint materially improves from 2664-byte seed-only counterfactual.

## Appearance

Generated portrait signature must match before save, after reload, abstract, materialized and dematerialized. Authored appearance remains exact. No live body required.

## Inventory

Required:

1. untouched abstract -> reload -> SEED_ONLY;
2. materialize/dematerialize unchanged -> smallest safe compact mode;
3. durable physical mutation -> BASELINE_DELTA where representable;
4. unsupported exact state -> FULL only when required;
5. rematerialize -> same durable item/equipment state.

## Group traversal

For N members:

- one group journey;
- N member refs;
- actor projection derived from group;
- no N-fold route duplication;
- individual override only for separation;
- save/reload IDs stable;
- every actor dot renders.

## Hoomans hydration

Materialization preserves actor identity/portrait/faction/community/group/role, creates one body lease, lazily hydrates inventory and creates runtime AI/needs/pathing.

Dematerialization captures durable changes, compacts inventory, releases body and discards runtime-only state.

## Abstract-only

With ProjectHoomans absent:

- Core survivor world generates/loads;
- actors/factions/communities/groups exist;
- traversal advances;
- portraits work;
- per-actor map dots work;
- discovery/debug tools work;
- hover/select/highlight work;
- no live-body/physical-AI dependency;
- footprint budget passes.

## Cross-provider parity

Same seed/config yields same faction/community/group/actor IDs, memberships, world intent and discovery IDs. Physical provider may enrich runtime but cannot regenerate a different world.

## DynamicTrading

DTCommon attaches economics to canonical Core actors/groups/communities; stock/budget remains DT-owned; static settlement fallback is not active once Core world is authoritative; exactly-once trader invariants remain green.

## Map/discovery/debug

Both modes expose per-actor dots, overlap spread, route, portrait, hover, selection, highlight/tracking, settlement/group/signal discovery, raw debug overlays and inspectors.

Representation change must not replace marker identity.

## Persistence/migration

Supported old Core/PNC data migrates without loss or duplicate authority. Unknown versions quarantine explicitly. Repeated save/load must not grow payload without semantic changes.

## Performance

Reject per-frame full-world scans, per-member duplicate group journey updates, unbounded memories/facts, hydration of all abstract inventories, and physical AI initialization for off-screen abstract actors.

## Cross-repository developer gate

Before native handoff:

- Core tests;
- Hoomans full suite;
- DynamicTrading full suite;
- duplicate-authority source audit;
- diff/parse/Kahlua checks;
- footprint report;
- load-order/absence matrix;
- save/reload;
- MP authority/client projection harness.

## Native acceptance

User-owned after developer gates:

- abstract-only large population;
- Hoomans physical population;
- DynamicTrading + abstract/Hoomans;
- materialize/move/dematerialize;
- save/reload both representations;
- MP reconnect/resync;
- map dots/highlight/hover parity;
- discover-all debug tools;
- no duplicate actor/body/group/faction;
- actual ModData footprint on large/long-running saves.
