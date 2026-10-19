# Core NPC Foundation — Progress

Snapshot: 2026-10-20. P1–P9 developer-implementable requirements are complete and source-backed. Status: READY FOR USER LIVE TEST. Native Project Zomboid SP/MP validation remains user-owned; no native game was launched, no Workshop content was published, and no user save was reset.

## Repository state

- PsychopatzCore: `4cdd547` (`main`), local branch ahead of `origin/main` by twelve and behind by one.
- ProjectHoomans: `9b123bd3` (`codex/contextual-dialogue-quest-framework-0a`), local branch ahead of its configured remote by five.
- DynamicTrading: `2d1ee62a` (`main`), local branch ahead of `origin/main` by three.
- Documentation commits: Core `a2862df` records P8; this P9 update follows the implementation commits above.

All three worktrees were checked clean before each phase commit and after the final changes. Existing unrelated history and changes were preserved. No force push, reset, discard, or Workshop publication was used.

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
- P9: Core-only, Core+DT, Core+Hoomans, and combined configuration harnesses; explicit client/server provider authority rejection; stable actor/body uniqueness; migration, save/reload, inventory/social/journey continuity; merchant stock separation and relationship pricing; bounded actor creation/payload checks; focused compatibility and Kahlua verification.

## Validation evidence

- Core foundation/matrix tests passed, including actor, inventory, social, journey/task, presentation, provider lease, and acceptance matrix coverage. The Core Actors directory and provider files report zero Kahlua errors. The broad Core smoke sweep passed 95/103; the eight remaining failures are unrelated UI/native-fixture tests outside NPC Foundation paths.
- ProjectHoomans foundation tests passed 5/5: combined end-to-end, provider bridge, migration, social, and presentation. The provider adapter reports zero Kahlua errors. The broad headless harness reports 14 failures outside this focused foundation set, including UI tests requiring the native `ISUI/ISPanel` module and the existing `next()`-less persistence assertion; none fail the new provider or combined acceptance tests.
- DynamicTrading foundation/trading tests passed 9/9: provider adapter, policy, service, pricing, stock seed, basket, access, rollback, and T0 cases. DTAbstract and DTHoomans provider files report zero Kahlua errors. The unfiltered suite retains one unrelated `dt_caravan_contract` failure for missing baseline text `groupSize = GROUP_SIZE`; no caravan source was changed for P8/P9.
- Codebase-memory coverage was checked for every operated source path. Core and DynamicTrading media trees are intentionally excluded from the graph, so those paths were read and verified directly; Hoomans coverage reports no recorded parse gap but its media tree is not tracked for freshness.

## User-owned next action

Run the native compatibility matrix in a disposable/test save: Core-only; Core+DTCommon+DTAbstract; Core+DTCommon+Hoomans+DTHoomans; both provider frontends; Core+DTCommon alone; Hoomans without DT; save/restart provider switching; and a dedicated two-client multiplayer authority/reconnect pass. Confirm visual appearance, physical item parity, portrait/UI coexistence, body lifecycle behavior, and native performance. The developer-side implementation is ready for that live test.
