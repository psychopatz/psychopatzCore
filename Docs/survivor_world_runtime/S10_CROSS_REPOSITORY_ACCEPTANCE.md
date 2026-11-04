# S10 Cross-Repository Acceptance and Native Handoff

Snapshot: 2026-11-04.

## Result

**DEVELOPER ACCEPTED — native Project Zomboid SP/MP acceptance remains user-owned.**

The compact SurvivorWorld roadmap is complete on the developer side.

One PsychopatzCore SurvivorWorld now owns generic survivor-world identity, persistence, group traversal, projection, map/discovery state and provider-neutral presentation. ProjectHoomans and DynamicTrading consume that authority through adopter/provider seams without retaining a second active generic world.

No native game result is claimed by this document.

## Full regression baselines

### PsychopatzCore

Full Lua sweep:

- **141/148 pass**;
- the same seven unrelated baseline failures remain:
  - `psychopatz_command_hub_callback_smoke.lua`;
  - `psychopatz_image_resolver_smoke.lua`;
  - `psychopatz_label_layout_smoke.lua`;
  - `psychopatz_profiler_client_composition_smoke.lua`;
  - `psychopatz_profiler_server_composition_smoke.lua`;
  - `psychopatz_widget_window_smoke.lua`;
  - `psychopatz_world_inventory_smoke.lua`.

S8 independently reproduced the exact same seven failures on detached clean HEAD `cae306c`; no SurvivorWorld phase introduced them.

### ProjectHoomans

Full suite:

- **995/1000 pass**;
- the same five unrelated semantic/harness baselines remain:
  - companion camp rejection wording;
  - semantic harness protocol message-bound expectation;
  - horde command acknowledgement wording;
  - horde tactical prompt profanity expectation;
  - local-route fishing wording.

All SurvivorWorld cutover/map/discovery/MP gates pass.

### DynamicTrading

Full suite:

- **62/62 pass**.

The additional Hoomans bridge harness passes **78/78** checks when invoked with its production mod-content root.

Abstract and physical Radio OS provider smokes pass.

## Compact persistence and footprint

Fresh S10 production-serializer benchmark:

| Actors | Total bytes | Bytes/actor | SEED_ONLY | FULL |
| ---: | ---: | ---: | ---: | ---: |
| 10 | 12,767 | 1,276.70 | 10 | 0 |
| 100 | 127,092 | 1,270.92 | 100 | 0 |
| 500 | 636,054 | 1,272.11 | 500 | 0 |
| 1000 | 1,272,265 | 1,272.27 | 1000 | 0 |

The locked target is <= 1,900 bytes/actor at 1000 untouched actors. S10 remains at **1,272.27 bytes/actor**, with **1000/1000 SEED_ONLY** and **0 FULL**.

Large-registry round trip:

- 900 actors;
- **1,132,286 bytes** serialized;
- reload succeeds above the generic 1 MiB JSON boundary through the actor-registry-specific bound.

Shared group-journey footprint remains:

- 1 member: 1,110 bytes;
- 5 members: 1,174 bytes;
- 10 members: 1,254 bytes;
- 25 members: 1,494 bytes;
- one shared journey: **687 bytes** at every member count.

This preserves O(1) route/journey storage per group.

Generated evidence:

- `S10_FOOTPRINT.json`;
- `S10_FOOTPRINT.md`.

## Save/reload, migration and hotplug acceptance

Core persistence matrix passes:

- compact actor save/reload;
- large actor registry save/reload;
- SurvivorWorld registry/runtime-store/schema save/reload;
- group-shared journey save/reload;
- deterministic bootstrap;
- PNC one-way import;
- provider lease persistence;
- actor projection sync/transport;
- Core-only acceptance with ProjectHoomans and DynamicTrading absent.

The Core hotplug matrix passes all eight stages:

1. Core + DynamicTrading create/save/reload;
2. add ProjectHoomans;
3. exercise Hoomans extensions;
4. remove ProjectHoomans and reload;
5. re-add ProjectHoomans and recover extensions;
6. reverse Core + Hoomans -> add/remove/re-add DynamicTrading;
7. repeated migration/load idempotence;
8. migration conflict fails visibly without destructive reset.

The Hoomans real cross-adopter matrix passes:

- DynamicTrading-first save/reload/add/remove/re-add Hoomans;
- Hoomans-first save/reload/add/remove/re-add DynamicTrading;
- conversation-capability isolation;
- DT whereabouts/road-news/story grounding through reload;
- semantic-pack unregister/re-register without residue;
- repeated migration/sync idempotence.

## Provider and representation acceptance

DynamicTrading focused gates pass:

- provider hot-swap persistence;
- provider runtime handoff;
- abstract <-> physical hybrid handoff;
- canonical group-journey handoff/rebase;
- pre-SurvivorWorld standalone-actor import;
- trader-world persistence/performance;
- Core SurvivorWorld identity parity;
- Core-backed settlement directory;
- Hoomans canonical settlement routing;
- both Core-map-host load orders;
- abstract and physical Radio OS provider modes.

The standalone bridge harness passes **78/78** checks after being aligned with the production integration registry. Its prior name-resolution failure was a stale mock record/integration setup, not a production failure.

## Multiplayer authority/client acceptance

All **20/20** ProjectHoomans `pnc_mp_*` developer smokes pass, covering:

- targeted body-binding recovery;
- body-audit streaming;
- bounds;
- client/server binding;
- death cleanup;
- multi-client binding;
- incarnation identity;
- replication boundary;
- follow stability;
- human-visual repair;
- late-stream rehydrate;
- presence authority;
- replica transport;
- replica visual ownership;
- restart carrier claim;
- scale guardrails;
- server-file loader gate;
- snapshot budget;
- zombie aggro controller.

Core projection transport and SurvivorWorld discovery transport also pass.

This is headless/simulated developer evidence, not a substitute for native MP visual acceptance.

## Final authority audit

### Generic persistence

Canonical SurvivorWorld ModData is owned by:

- `PsychopatzSurvivorWorldRuntimeStore.lua`.

Hoomans faction/community/abstract-world/discovery surfaces are runtime compatibility/adopter views, not generic persistence authorities:

- faction/community view commits route into Core + Hoomans extension state;
- `PNC.HoomansWorldView` has no public Save authority;
- if the cutover boundary is unavailable, generic view commits fail closed;
- retired PNC generic roots are read/retired only by the bounded `PNC_SurvivorWorldImportSource.lua` one-way import path and are never runtime fallback stores.

DynamicTrading has no generic SurvivorWorld ModData root; its persistence remains commercial trader/market/event state.

### Projection and map state

Core owns canonical actor projection, overlap spreading, group route, portrait conversion, selection/highlight/tracking and discovery.

Hoomans canonical map entries consume `PsychopatzSurvivorWorldClient`; Hoomans-only records remain adopter-specific.

DynamicTrading has no `DynamicTrading` actor projection source and no `DTCommon_TraderProjectionServer.lua`.

### Traversal

Core `GroupJourney` owns generic group route/progress/ETA.

ProjectHoomans uses Core GroupJourney for canonical abstract mobile-group travel; individual actor travel remains only the intentional separated/live-provider exception.

DTAbstract movement calls Core group journey start/advance/rebase/project APIs. DTCommon retains commercial destination intent, not world geometry.

### Discovery

Core owns durable community/group/signal discovery.

Hoomans uses a compatibility view/transport adapter and preserves Core-only signal knowledge.

DTAbstract nearby discovery advances Core discovery and retains only transient notification hysteresis/cooldown.

### Static geography and retired schema

DynamicTrading contains:

- no built-in Kentucky settlement list;
- no `EnsureDefaults` world bootstrap;
- no live `coreActorID/coreActorId/coreProvider` aliases outside `DTCommon_PreSurvivorWorldImport.lua`;
- no permanent retired-world subsystem.

Pre-SurvivorWorld actor IDs are recognized only by bounded `DTAbstract_PreSurvivorWorldImport.lua`.

## Parser and source-quality gates

At S10 acceptance, the then-current authority surfaces passed:

- Core SurvivorWorld: **15/15 luac**, **15/15 installed-PZ Kahlua**;
- ProjectHoomans cutover/persistence surfaces: **24/24 luac**, **24/24 installed-PZ Kahlua**;
- DynamicTrading S9 authority surfaces: **16/16 luac**, **16/16 installed-PZ Kahlua**.

S11 later changed additional consolidation files; its current parse/regression evidence and explicit Kahlua status are recorded in `S11_POST_MIGRATION_CONSOLIDATION.md`.

All three repositories pass `git diff --check`.

DynamicTrading's two unrelated user-owned `mod.info` edits remain unstaged and outside the SurvivorWorld commits.

## Native SP/MP handoff matrix

Run these in native Project Zomboid before release/publish. Record PASS/FAIL plus save name and any log/screenshot evidence.

### N1 — Core + DTAbstract, ProjectHoomans absent

1. Start a fresh save with Core + DynamicTrading abstract composition only.
2. Verify factions, communities, groups and trader actors exist without Hoomans.
3. Open the map and verify per-actor trader dots plus discovered community/group/signal markers.
4. Let a trader group travel; verify all actor dots follow one route and overlapping dots remain distinguishable.
5. Trigger nearby discovery and verify a trader becomes known without duplicate markers.
6. Save/reload while traveling and verify the same actor/group/trader IDs, route and stock/budget continue.

Pass condition: no Hoomans dependency, no duplicate actor/group, stable map/discovery identity.

### N2 — Core + ProjectHoomans, DynamicTrading absent

1. Start a fresh Hoomans save.
2. Verify canonical factions/communities/groups appear once.
3. Approach an abstract survivor until materialization.
4. Verify the same actor name/portrait/faction/community/group identity before and after body creation.
5. Verify the body is a human visual, not a zombie-looking placeholder.
6. Move/travel, then leave range and allow dematerialization.
7. Verify the same map marker survives the abstract -> physical -> abstract transition.
8. Save/reload once abstract and once materialized.

Pass condition: one actor identity, at most one live body lease, no duplicate group/faction, durable inventory/identity continuity.

### N3 — Core + ProjectHoomans + DynamicTrading

1. Find an abstract DT trader/caravan.
2. Note trader ID/name, group/community, stock/budget and map marker.
3. Approach to materialize through DTHoomans.
4. Verify the trader retains the same actor/trader identity, portrait, stock/budget and group route.
5. Trade once physically.
6. Leave range and allow return to abstract representation.
7. Verify route rebase/resume and exactly-once settlement arrival/visit behavior.
8. Save/reload across both representation states.

Pass condition: commercial state stays DT-owned while world identity/route stays Core-owned; no duplicate trader or actor.

### N4 — Native multiplayer, at least two clients

1. Host/server starts a fresh save with Core + Hoomans + DynamicTrading.
2. Connect two clients near the same survivor/trader group.
3. Verify both clients see the same actor/group identities and only the server owns body lifecycle authority.
4. Verify no startup survivor appears as a zombie/husk placeholder.
5. Move one group through abstract/materialized boundaries and observe both clients.
6. Disconnect/reconnect one client.
7. Verify streamed bodies/map projections recover without duplicate bodies or actor IDs.
8. Kill one managed survivor and verify exact cleanup/death state on server and both clients.
9. Save/restart server and reconnect both clients.

Pass condition: no duplicate bodies, no incarnation mismatch, no client-authored durable world mutation, stable projection after reconnect/restart.

### N5 — Discovery/debug parity

1. With debug disabled, verify no raw undiscovered overlays/inspectors appear.
2. Enable authorized debug.
3. Use discover-all for communities, groups and signals.
4. Verify map updates through the same Core discovery identity.
5. Reset one entity and verify unrelated signal/group/community knowledge remains.
6. Disable debug and confirm normal gameplay presentation remains.

Pass condition: debug is opt-in, server-authoritative and does not create a second discovery store.

### N6 — Long-save sanity

After representative play:

1. save/reload repeatedly without semantic changes;
2. verify actor/group counts do not grow spuriously;
3. verify no duplicate old PNC/DT generic-world root becomes active;
4. if inspecting ModData, confirm Core SurvivorWorld is the generic world root and Hoomans/DT roots contain adopter/commercial state only.

Pass condition: no unexplained save growth or duplicate authority.

## Completion boundary

All developer-side S0-S10 requirements are accepted. S11 post-migration consolidation subsequently removed the remaining migration-era fallback/name residue without changing this native acceptance matrix.

The remaining release gate is the native N1-N6 matrix above. Until that user-owned native run is complete, status is **developer complete / native acceptance pending**, not fully release-accepted.
