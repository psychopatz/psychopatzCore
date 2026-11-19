# Progress — Portable Actor Lifecycle & Social Garbage Collection

**Status:** IN_PROGRESS — L3 accepted, starting L4.
**Current phase:** L4 — CodeBuilder Social Policy reference strength and bounded refs.
**Developer completion:** 4/10 phases accepted (L0, L1, L2, L3 ACCEPTED).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans (H0, H3A at `b19d3a03`), DynamicTrading (D0).

## Verified L3 Facts

- Migrated `PsychopatzSocialRetention.lua` & `PsychopatzSocial.lua` (`SCHEMA_VERSION = 3`) from per-relationship `memories` (`N × 64`) to one actor-level bounded `memoryBank[]` (`MAX_ACTOR_MEMORIES = 96`: `MAX_ANCHOR_MEMORIES = 16`, `MAX_LONG_MEMORIES = 56`, `MAX_SHORT_MEMORIES = 24`), adding `REF_STRONG`/`REF_WEAK`/`REF_LABEL_ONLY` (`NormalizeRefStrength`), deterministic `v1/v2 -> v3` migration in `NewState`/`Load` with evicted baseline promotion, and fail-closed `Validate` forbidding `relationship.memories ~= nil` (`relationship_memories_forbidden`) and `SCENE` persistence.
- Added FIFO-bounded (`MAX_MEMORY_INDEX_CACHE = 32`) non-persisted runtime index cache (`byTarget`, `byClass`, `byEvent`, zero keys added to persisted `social` tables), query/compaction APIs (`GetMemoriesForTarget`, `GetMemoriesByClass`, `GetMemoriesByEvent`, `GetRelationshipSummary`, `GetHotRelationshipSnapshot`, `GetActorMemoryStats`, `RemoveMemory`, `CompactHistoricalEdge`, `PruneDefaultEdges`, `IsSignificantEdge`), and updated `PsychopatzSocialProjections.lua`, `PsychopatzActorSocialAuthority.lua`, and `PsychopatzActorGC.lua` (`PsychopatzCore.Social` provider now uses `memoryBank` + `refStrength`/`sourceRefStrength`/`subjectKey`/`roleRefs` and degrades weak refs on `OnBeforePurge`).
- Measured 100-contact × 64-event (`6,400` events) high-activity actor save size = `35,943` bytes vs L0 baseline `1,606,721` bytes (`44.7×` reduction, strictly `< 50 KB`), with `#memoryBank <= 96` and zero persisted `rel.memories`.
- Updated `ProjectHoomans` `PNC_Persistence_CoreSocial.lua` (H3A `b19d3a0382a9adf1e07eba1af7535f9bd671ec50`) so `ToCoreSocial` & `SyncToCore` write exclusively to Core `memoryBank` while `FromCoreSocial` projects `memories` onto Hoomans runtime views only.
- Verified: Core `39/39` smoke tests PASS (`tests/psychopatz_social_*_smoke.lua`, `psychopatz_actor_*_smoke.lua`, `psychopatz_npc_*_smoke.lua`, `psychopatz_player_identity_smoke.lua`, `psychopatz_hotplug_save_matrix_smoke.lua` including `_G.next = nil` under `Save()`), `ProjectHoomans` `5/5` tests PASS (`core_social`, `portable_social`, `non_destructive_social`, `social_adapter`, `hotplug_matrix`), `DynamicTrading` `2/2` tests PASS (`dt_trade_relationship_event_smoke`, `dt_portable_social_trader_adoption_smoke`), and `pz_verify.py --kahlua --severity ERROR` returned 0 errors on all modified Core and Hoomans Lua files.

## Verified L2 Facts

- Created `PsychopatzActorGC.lua` implementing bounded provider registration (`RegisterReferenceProvider`, `UnregisterReferenceProvider`, `ListReferenceProviders`, max 64 providers, max 4096 refs/provider), built-in Core providers (`PsychopatzCore.Social`, `PsychopatzCore.SurvivorWorld`, `PsychopatzCore.WorldKnowledge`), generation/cursor-budgeted fail-closed mark-and-sweep (`Step`, `RunFull`, `ReconcileOnLoad`, `TickBudgeted`), and read-only diagnostics (`ExplainRetention`, `ExplainPurge`, `GetDiagnostics`).
- Wired allowed non-tick triggers in `PsychopatzActorRuntimeStore.lua` (startup `Load` reconciliation, `Save` threshold/active-cursor step, and `Events.EveryDays` maintenance; guarded for minimal mock registries) and exported GC surfaces in `PsychopatzActors.lua`.
- Verified fail-closed behavior (provider errors/malformed refs/overflow abort sweep with zero tombstones purged; partial `OnBeforePurge` failures preserve failing tombstone for retry), active ownership blocking, grace enforcement, weak-ref compaction before purge, zero persistent refcount dependency, and `budget = 5` cursor parity across 40 tombstones.
- Verified via `tests/psychopatz_actor_gc_mark_sweep_smoke.lua`, `tests/psychopatz_actor_lifecycle_tombstone_smoke.lua`, and all 36 existing `psychopatz_actor_*`/`psychopatz_social_*`/`psychopatz_npc_*`/`psychopatz_player_identity`/`psychopatz_hotplug_save_matrix`/`psychopatz_world_knowledge`/`psychopatz_survivor_world_registry` smoke tests (all PASS), plus `pz_verify.py --kahlua --severity ERROR` (0 errors).

## Immediate Next Chunk

**L4 — CodeBuilder Social Policy reference strength and bounded refs.**

Extend `social_policy_compiler.py` (`MAX_ANCHOR_BUDGET = 16`, `STRONG`/`WEAK`/`LABEL_ONLY` ref metadata, retention/reference compatibility checks, role fan-out caps), update Core/ProjectHoomans/DynamicTrading social policy JSON sources, regenerate via `reconcile.py --apply`, and verify determinism & runtime policy propagation.
