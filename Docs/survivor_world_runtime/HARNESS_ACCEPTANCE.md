# Acceptance — Compact Survivor World Runtime

## Evidence classes

Use source/static, serialized-footprint benchmark, deterministic unit, migration round-trip, provider contract, split authority/client, production composition, persistence/restart, cross-repository regression, native SP and native MP evidence.

## S0 footprint baseline

Measure serialized bytes for:

- 0/10/100/500/1000 actors;
- generated/authored appearance;
- SEED_ONLY/BASELINE_DELTA/FULL inventory;
- 1/5/10/25-member groups;
- shared vs individual journey;
- faction/community/discovery registries.

Record total bytes, bytes/object, slope, largest sections and duplicates.

S1 cannot be accepted until explicit budgets replace the provisional target.

Provisional target:

- untouched abstract actors average roughly <= 2 KiB incremental serialized Core state each excluding shared faction/community/group state;
- zero FULL inventory payloads for untouched actors;
- provider runtime contributes zero canonical bytes;
- shared group journey storage is approximately O(1) with member count.

## Compact actor

Untouched generated actor must preserve stable ID, deterministic identity/portrait, affiliations/provider lease/world refs and save/reload while remaining compact and body/AI-free.

## Appearance

Generated portrait signature must match before save, after reload, abstract, materialized and dematerialized. Authored appearance must remain exact. No live body required for portrait.

## Inventory

Required:

1. untouched abstract -> reload -> still SEED_ONLY;
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

Same seed/config must yield same faction/community/group/actor IDs, memberships, world intent and discovery IDs. Physical provider may enrich runtime but cannot regenerate a different world.

## DynamicTrading

DTCommon attaches economics to canonical Core actors/groups/communities; stock/budget remains DT-owned; static settlement fallback is not active once Core world is authoritative; exactly-once trader invariants remain green.

## Map/discovery/debug

Both modes expose per-actor dots, overlap spread, route, portrait, hover, selection, highlight/tracking, settlement/group/signal discovery, raw debug overlays and inspectors.

Representation change must not replace marker identity.

## Persistence/migration

Supported old Core/PNC data migrates without loss or duplicate authority. Unknown versions quarantine explicitly. New writes use compact schema only. Repeated save/load must not grow payload without semantic changes.

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
- inspect actual ModData footprint on large/long-running saves.
