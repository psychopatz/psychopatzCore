# Progress — Portable Actor Lifecycle & Social Garbage Collection

**Status:** IN_PROGRESS — L2 accepted, starting L3.
**Current phase:** L3 — Actor-level social memory bank and historical edges.
**Developer completion:** 3/10 phases accepted (L0, L1, L2 ACCEPTED).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans (H0), DynamicTrading (D0).

## Verified L2 Facts

- Created `PsychopatzActorGC.lua` implementing bounded provider registration (`RegisterReferenceProvider`, `UnregisterReferenceProvider`, `ListReferenceProviders`, max 64 providers, max 4096 refs/provider), built-in Core providers (`PsychopatzCore.Social`, `PsychopatzCore.SurvivorWorld`, `PsychopatzCore.WorldKnowledge`), generation/cursor-budgeted fail-closed mark-and-sweep (`Step`, `RunFull`, `ReconcileOnLoad`, `TickBudgeted`), and read-only diagnostics (`ExplainRetention`, `ExplainPurge`, `GetDiagnostics`).
- Wired allowed non-tick triggers in `PsychopatzActorRuntimeStore.lua` (startup `Load` reconciliation, `Save` threshold/active-cursor step, and `Events.EveryDays` maintenance; guarded for minimal mock registries) and exported GC surfaces in `PsychopatzActors.lua`.
- Verified fail-closed behavior (provider errors/malformed refs/overflow abort sweep with zero tombstones purged; partial `OnBeforePurge` failures preserve failing tombstone for retry), active ownership blocking, grace enforcement, weak-ref compaction before purge, zero persistent refcount dependency, and `budget = 5` cursor parity across 40 tombstones.
- Verified via `tests/psychopatz_actor_gc_mark_sweep_smoke.lua`, `tests/psychopatz_actor_lifecycle_tombstone_smoke.lua`, and all 36 existing `psychopatz_actor_*`/`psychopatz_social_*`/`psychopatz_npc_*`/`psychopatz_player_identity`/`psychopatz_hotplug_save_matrix`/`psychopatz_world_knowledge`/`psychopatz_survivor_world_registry` smoke tests (all PASS), plus `pz_verify.py --kahlua --severity ERROR` (0 errors).

## Immediate Next Chunk

**L3 — Actor-level social memory bank and historical edges.**

Migrate `PsychopatzSocial` / `PsychopatzSocialRetention` / `PsychopatzSocialProjections` from per-relationship `memories` arrays (`N × 64` multiplier) to one bounded actor-level `memoryBank[]` with fixed actor-level hard memory budget, deterministic migration/consolidation/baseline promotion parity, ephemeral runtime indexes, and historical edge compaction/pruning.
