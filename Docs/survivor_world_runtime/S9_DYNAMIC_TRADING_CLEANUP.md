# S9 DynamicTrading Attachment and Cleanup

Snapshot: 2026-11-04.

## Accepted ownership

DynamicTrading is now attached to the canonical PsychopatzCore SurvivorWorld without a second generic world authority.

PsychopatzCore SurvivorWorld owns:

- actor identity and provider-neutral actor projection;
- faction/community/group identity and geography;
- group-shared route/progress/ETA;
- player discovery and map-world presentation.

DTCommon owns only commercial state and policy:

- trader binding to a canonical actor;
- stock and budget;
- commercial destination intent;
- compact commercial lifecycle/journey metadata;
- visits, exchange, restock, cooldown and pricing context;
- representation-switch policy.

DTAbstract and DTHoomans own representation execution only.

## Removed redundant authority

S9 removed:

- the separate `DynamicTrading` actor projection source;
- `DTCommon_TraderProjectionServer.lua`;
- actor/world projection reads from `DTCommon_TraderPresentation.lua`;
- the old DT-owned map projection helper;
- hard-coded Kentucky settlement defaults and `EnsureDefaults`;
- the now-unused trader-world change-listener bus that existed for the deleted projection publisher;
- live `coreActorID/coreProvider*` schema aliases and old `BindCore*/SetCore*` API names.

`TraderPresentation` is now a commercial-record binding cache only. Cache invalidation uses the synchronized DT commercial-store revision rather than an actor-projection revision.

## Canonical schema and migration

Live DT records use:

- `actorID`;
- `provider`;
- `providerState`;
- `providerLeaseID`;
- `providerBodyID`.

Retired `coreActorID/coreProvider` keys are accepted only by `CoreActorPolicy.Normalize` as one-way save inputs and are immediately rewritten to the canonical shape.

Pre-S7 standalone actor IDs are isolated in `DTAbstract_TraderWorldMigration.lua`. The migration:

- recognizes only retired `actor:dt:world:*` / `actor:abstract:*` inputs;
- selects an existing canonical SurvivorWorld trader actor/group;
- preserves the DT commercial record, budget and stock;
- does not copy retired static geography or actor-owned route state into the canonical group journey;
- retires the old actor only when no other trader references it;
- does not remain active after the record has canonical identity.

No runtime legacy world subsystem or dual-write path remains.

## Legitimate remaining representation hooks

Provider `getPosition` remains part of representation switching, not persistent world ownership.

- DTAbstract resolves the current canonical Core group/member position.
- DTHoomans reads a live physical body when materialized.
- physical -> abstract handoff returns the final body position so the Core group journey can be rebased.
- an intentionally separated actor may still retain its Core ActorWorld journey override, consistent with the S5 contract.

## Settlement directory

`DTCommon_SettlementDirectory` remains a commercial lookup/provider facade, but contains no built-in geography.

Production geography is supplied by `DTCommon_CoreSettlementDirectoryProvider`, which reads Core SurvivorWorld communities.

External providers may still register commercial settlement views without becoming a second persistent SurvivorWorld authority.

## Source audit

Production source audit is clean for:

- no DynamicTrading actor projection server/client source;
- no hard-coded Kentucky settlement geography;
- no retired DT schema aliases outside the one-way normalization boundary;
- no old `BindCoreActor`, `SetCoreProviderLease`, `SetCoreActorAvailability` or `ProjectCoreMapEntry` APIs;
- no DynamicTrading world ModData root beyond commercial trader/market/event storage;
- canonical group journey mutations occur through Core SurvivorWorld.

ProjectHoomans has its own `coreActorID` physical-persistence fields; those belong to PNC's provider projection schema and are not DTCommon aliases.

## Validation

DynamicTrading:

- full suite: **62/62**;
- settlement-directory/Core identity parity focused tests: pass;
- provider hot-swap, hybrid handoff, group-journey handoff, persistence, nearby/map and retired-world migration regressions: pass;
- changed S9 production Lua: **16/16** luac;
- installed-PZ Kahlua: **16/16**;
- `git diff --check`: pass.

Cross-repository focused validation:

- Core SurvivorWorld presentation, transport, discovery and group-journey tests: pass;
- ProjectHoomans Core travel-directory, live-body projection, discovery client/server cutover and map-layer tests: pass.

Historical DynamicTrading job docs were reconciled so they no longer advertise the deleted projection server or retired service API names.

## Commit

DynamicTrading: `86b712a5` — Remove redundant DynamicTrading world authority.

The two unrelated user-owned edits remain unstaged:

- `Contents/mods/DTAbstract/42.20/mod.info`;
- `Contents/mods/DTHoomans/42.20/mod.info`.

## Native status

No native Project Zomboid SP/MP result is claimed by S9.

Developer-side S9 acceptance is complete.

## Next

S10 performs the final cross-repository acceptance gate: full suites, footprint/persistence, provider hot-swap, absence/load-order, split MP authority/client projection, duplicate-authority audit and native handoff matrix.
