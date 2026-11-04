# Roadmap — Compact Survivor World Runtime

## Parent completion boundary

One compact Core Survivor World drives ProjectHoomans and DTAbstract. Abstract mode stays lightweight; Hoomans hydrates richer physical state only when needed. Shared map/discovery/debug parity is provider-neutral. Static/parallel survivor-world authority is removed.

## S0 — Baseline, ownership matrix, footprint budget

**COMPLETE**

Measure current Core/PNC/DT serialized footprint and classify every relevant field/module.

Required measurements:

- 10/100/500/1000 actors;
- inventory modes;
- appearance payloads;
- 1/5/10/25-member group traversal;
- PNC faction/community/group/discovery persistence;
- DT static world state.

Gate: reproducible baseline, explicit byte budgets, migration ownership matrix, fail-first compactness/group tests.

## S1 — Compact Core actor persistence

**COMPLETE**

Make default actor creation seed-first and sparse.

Gate:

- untouched actors no longer store FULL inventory;
- save/reload parity;
- size budget passes;
- supported old saves migrate without silent reset.

## S2 — Compact appearance and portrait contract

**COMPLETE**

Make portrait appearance reconstructable without live body or unnecessary resolved payload.

Gate: same portrait signature across save/reload and abstract↔physical transitions.

## S3 — Lazy inventory hydration and durable deltas

**COMPLETE**

Use SEED_ONLY by default, BASELINE_DELTA for durable changes, FULL only when required.

Gate: materialize/dematerialize round-trip preserves durable items/equipment and returns to smallest safe mode.

## S4 — Core Survivor World model

**COMPLETE**

S4A established the bounded generic schema/persistence/import contract. S4B added deterministic seed/ID/name/planning contracts plus bounded runtime-only adopter generation-policy extensions.

Gate met: Core can deterministically plan/load a survivor world with ProjectHoomans and DynamicTrading absent; adopter policy registration does not change canonical IDs/plans.

## S5 — Group-shared traversal and actor projection

**COMPLETE**

S5A established one bounded Core GroupJourney per mobile group. S5B migrated ProjectHoomans abstract group progression and map projection onto that shared journey while preserving actor-specific/live-provider travel as an intentional exception.

Gate met: route storage is O(1) per group, member projection is shared, actor separation overrides remain bounded, and Hoomans no longer uses stateEndsAt as canonical abstract-travel authority.

## S6 — ProjectHoomans adopter migration

**COMPLETE**

S6A added Core runtime persistence and one-way legacy import. S6B cut generic faction/community/location/group state onto Core while retaining only Hoomans-specific extension state. S6C removed duplicate active generic save authority; legacy roots are read-only migration inputs and production saves use one Core + extension boundary.

Gate met: no duplicate PNC generic-world persistence authority, Hoomans gameplay extensions remain durable, migration/reload works, and focused/full Hoomans regression is unchanged.

## S7 — DTAbstract adopter migration

**COMPLETE**

DTAbstract now consumes Core SurvivorWorld with ProjectHoomans absent. It binds DTCommon commercial roles to existing canonical trader-group actors, uses Core communities for settlement identity, moves through Core GroupJourney, and preserves compact abstract actors. DTHoomans materialization/dematerialization keeps the same actor/group identity.

Gate met: same seed/anchor/config matches Core canonical identities, untouched abstract actors require no bodies/FULL inventory, static Kentucky world authority is inactive, and DynamicTrading regression is green.

## S8 — Shared map, discovery, highlight and debug parity

**COMPLETE**

Core now owns provider-neutral actor projection, overlap spreading, group-route presentation, portrait conversion/hover, selection/highlight/tracking and community/group/signal discovery. ProjectHoomans and DTAbstract consume the same canonical actor/group/community identities while retaining only adopter-specific policy/presentation.

Gate met: abstract and physical representations keep the same entity identity and interaction model; generic discovery/debug actions are Core-authoritative; disabled debug/portrait paths add no continuous runtime work.

Detailed evidence: `S8_SHARED_PRESENTATION_DISCOVERY.md`.

## S9 — DynamicTrading attachment and cleanup

**COMPLETE**

DTCommon now queries canonical Core communities/actors/groups without a second actor projection feed or built-in settlement geography. Commercial stock/budget/lifecycle ownership remains DT-owned; retired world/schema inputs are one-way migration only.

Gate met: DynamicTrading full regression is green, duplicate world authority is absent, and no permanent dual write/read path remains.

Detailed evidence: `S9_DYNAMIC_TRADING_CLEANUP.md`.

## S10 — Cross-repository acceptance and native handoff

**DEVELOPER COMPLETE — NATIVE ACCEPTANCE PENDING**

All developer gates are accepted. Detailed evidence and the user-owned native N1–N6 matrix are in `S10_CROSS_REPOSITORY_ACCEPTANCE.md`.

Developer gates:

- Core tests;
- Hoomans full suite;
- DynamicTrading full suite;
- Kahlua/parse/diff checks;
- footprint benchmarks;
- save/reload;
- provider hot-swap;
- absence/load-order matrix;
- MP authority/client projection harness;
- source audit for duplicate authority.

Then user-owned native acceptance.

## S11 — Post-migration consolidation

**COMPLETE**

After developer acceptance, remove migration-era fallback authority and misleading adopter names without changing the accepted ownership model.

Completed:

- retired PNC generic roots are known only by one bounded pre-SurvivorWorld import reader;
- faction/community/Hoomans abstract state are explicit runtime views, not standalone storage authorities;
- detached/partial Hoomans compositions cannot resurrect old generic ModData writes;
- PNC-only community/group generation-plan modules are removed and automatic generation consumes Core plans;
- Core supports bounded existing-member group plans;
- DT retired schema aliases and pre-SurvivorWorld actor IDs are isolated behind explicit one-way import modules;
- DTHoomans uses Core generic faction naming and Hoomans-only population policy tags.

Gate met: Core **141/148** with the same seven unrelated failures, Hoomans **995/1000** with the same five unrelated failures, DynamicTrading **62/62**, bridge harness **78/78**, changed production Lua parses cleanly, and source/diff audits show no active duplicate generic-world authority.

Detailed evidence: S11_POST_MIGRATION_CONSOLIDATION.md.

## Stop condition

Do not stop after compact persistence or one adopter.

The developer parent goal is complete because persistence, shared world lifecycle, both adopters, map/discovery/debug parity, cleanup and developer validation all pass.

Release/native acceptance remains explicitly pending until the user-owned N1–N6 Project Zomboid matrix passes.
