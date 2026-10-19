# Core NPC Foundation — Progress

Snapshot: 2026-10-20. This record covers developer-side source and Lua harness evidence only. Native Project Zomboid SP/MP live testing remains user-owned; no native game was launched, no Workshop content was published, and no user save was reset.

## Current phase

P8 — Provider switching and Hoomans integration: ACCEPTED developer-side evidence. P9 is the remaining mandatory phase.

## Repository state

- PsychopatzCore: `994ef44`, `main`, local branch ahead of `origin/main` by ten and behind by one.
- ProjectHoomans: `ecedcad10`, `codex/contextual-dialogue-quest-framework-0a`, local branch ahead of its configured remote by four.
- DynamicTrading: `7ddb972e`, `main`, local branch ahead of `origin/main` by two.

All three worktrees were clean before and after the P8 commits. Existing unrelated history and changes were preserved. No force push, reset, discard, or Workshop publication was used.

## Accepted phase evidence

- P0A/P0B: ownership/risk audit, parity baseline, fail-closed migration planning, and no-loss canonical contracts remain source-backed baseline evidence.
- P1: Core actor factory, registry, JSON codec, deterministic identity/voice/appearance, authored/generated appearance policies, extensions, stable IDs, duplicate rejection, and Core-only Create → Save → Reload into a fresh registry → Get.
- P2: deterministic personal inventory starters, stable item IDs, containers, equipment slots, exact item state, and FULL/BASELINE_DELTA/SEED_ONLY payloads. Merchant stock and budget remain outside personal inventory.
- P3: ownership-hashed, idempotent, non-destructive Hoomans migration with preservation, quarantine, rollback, and retry.
- P4: authoritative directional social state with bounded approval, respect, familiarity, personality, revisions, and event memory; no duplicate social owner.
- P5: bounded locations, anchors, abstract journeys, tasks, scheduler entries, deterministic advancement, and save/reload of journey state.
- P6: Core portrait projection, map registry and knowledge filtering, nearby conversation authorization, bounded notifications, and Hoomans presentation adapter.
- P7: DynamicTrading Core actor policy with availability, settlement visits, earned/cooldown restocking, capped social pricing, authoritative basket fulfillment, and separate DT stock/budget.
- P8: Core provider lease schema and registry operations; global single-body claim protection; DTAbstract projection/acquire/materialize/dematerialize/release adapter; DTHoomans callback-backed body lifecycle adapter; Hoomans Core projection into existing records and `PNC.BodyLifecycle`; DT trader policy provider/lease metadata. Canonical identity, appearance, personal inventory, social, and world state is projected without copying DT stock or budget into the actor.

## Validation evidence

- Core: actor, inventory, journey/task, presentation, and provider lease smoke tests passed; P8 explicitly covers competing owners, duplicate body IDs, materialization, dematerialization, provider switching, and provider lease save/reload. Core Actors Kahlua verification reports zero errors.
- ProjectHoomans: P8 provider bridge, migration, social, and presentation tests passed 4/4. The new provider adapter reports zero Kahlua errors. The unrelated existing `pnc_kahlua_persistence_smoke` still fails its `next()`-less deserialization assertion and was not changed by P8.
- DynamicTrading: P8 provider adapter plus policy, service, pricing, seed, access, basket, rollback, and T0 tests passed 9/9. DTAbstract and DTHoomans adapter files report zero Kahlua errors. The unfiltered suite retains one pre-existing `dt_caravan_contract` failure for missing baseline text `groupSize = GROUP_SIZE`; no caravan source was changed for P8.
- Codebase-memory coverage was checked for every operated source path. Core and DynamicTrading media trees are intentionally excluded from the graph, so their source was read and verified directly; Hoomans coverage reports no recorded parse gap but its media tree is also not tracked for freshness.

## Remaining work

P9 must complete the developer-side configuration matrix and end-to-end acceptance evidence: Core-only, Core+DT, Core+Hoomans, combined modules, old-save/migration reload, inventory parity, unique actor/body identity, trading fulfillment, journey and relationship continuity, multiplayer authority boundaries, reconnect behavior, performance/memory bounds, and compatibility regressions. User-run native SP/MP acceptance remains explicitly outside this agent's authority.

Next bounded chunk: add the P9 configuration/authority/continuity harnesses, run the full relevant regression sets, and record any source-backed blockers without stopping independent checks.
