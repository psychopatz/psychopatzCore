# Audit — Compact Survivor World Runtime

## Snapshot

Date: 2026-11-03

Repositories inspected:

- PsychopatzCore main at d7a8921.
- ProjectHoomans main at 564f3656.
- DynamicTrading main at 23e3bad3, with two unrelated unstaged mod.info edits preserved.

## Verdict

**Trader commercial authority is unified, but survivor-world authority is not.**

ProjectHoomans owns a rich abstract+physical survivor world. DTAbstract still presents a separate trader-centric world. This is the source of the missing Hoomans debug tools, per-NPC map dots/highlighting, and dynamic faction/settlement parity.

## A — reusable world systems are still under PNC

ProjectHoomans contains body-independent concepts that should become Core mechanisms:

- PopulationDirector;
- SettlementGenerator and GroupGenerator;
- faction model/name generation;
- communities/settlements;
- mobile groups;
- abstract travel/projection;
- WorldDiscovery entities/signals;
- generic map-presentation descriptors.

Physical body creation, combat, needs, jobs, local AI/pathfinding and animations remain Hoomans-specific.

## B — map authority is split

DTAbstract_WorldMap renders DynamicTrading trader records through a separate marker model.

ProjectHoomans PNC_MapLayer_Travel renders individual NPC entries from PNC.TravelDirectory.ListProjected(), including:

- one marker per actor;
- overlap spreading;
- routes;
- names/roles;
- hover/selection;
- portrait data;
- tracking/highlight.

Abstract-only mode cannot currently expose equivalent NPC map behavior.

## C — discovery/debug is Hoomans-only

ProjectHoomans registers PNC_WorldDiscoveryDebugMap through Hoomans client composition.

That exposes discover-all settlements, groups, signals, raw entity overlays, and reset/inspection behavior.

DTAbstract does not load that system, so the tools are absent by architecture, not hidden by a UI bug.

## D — DTCommon still has static settlement defaults

DTCommon_SettlementDirectory defines static Kentucky town defaults including Muldraugh, West Point, Rosewood, Riverside, March Ridge, Fallas Lake, and Louisville.

DTAbstract uses this directory for placement/routing. These defaults are not acceptable final survivor-world authority.

## E — current Core actor creation is too heavy for large abstract populations

Core ActorRegistry:Create currently creates ActorInventory and persists it as FULL for every actor.

Core ActorInventory already supports:

- SEED_ONLY;
- BASELINE_DELTA;
- FULL.

The capability exists; the lifecycle/default policy is wrong for abstract scale.

## F — deterministic compact foundations already exist

Useful foundations:

- identitySeed and generatorVersion;
- deterministic generated appearance;
- portrait-capable appearance contracts;
- seed/delta inventory codecs;
- Core world/journey/provider lease/projection;
- provider-neutral DynamicTrading trader identity.

Extend these rather than creating parallel persistence.

## G — traversal should be group-shared

Mobile-group travel is naturally shared state.

Final design:

- group owns journey/mission/destination;
- actor stores groupID and personal role;
- map derives each member position from the group journey;
- individual actor world override exists only for separation/exceptions.

Do not serialize identical route state N times for N group members.

## H — provider runtime is disposable

Canonical Core ModData must not contain physical-runtime state such as:

- body references;
- AI blackboards;
- path nodes;
- combat targets;
- animation state;
- perception caches;
- transient needs;
- local movement scratch;
- UI/debug caches.

Materialization reconstructs runtime state. Dematerialization commits only approved durable deltas.

## Required direction

Promote reusable survivor-world mechanisms from PNC to Core, make seed+delta compact persistence canonical, migrate Hoomans and DTAbstract onto the same world, and delete parallel/static authority.

Do not:

- duplicate PNC world systems into DTAbstract;
- make DTAbstract depend on ProjectHoomans;
- persist full Hoomans records for abstract actors;
- use FULL inventory by default;
- duplicate group journey per actor;
- retain permanent dual registries/dual writes.
