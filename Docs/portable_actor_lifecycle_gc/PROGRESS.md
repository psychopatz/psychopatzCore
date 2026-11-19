# Progress — Portable Actor Lifecycle & Social Garbage Collection

**Status:** IN_PROGRESS — L1 accepted, starting L2.
**Current phase:** L2 — Reference providers and budgeted mark-and-sweep GC.
**Developer completion:** 2/10 phases accepted (L0, L1 ACCEPTED).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans (H0), DynamicTrading (D0).

## Verified L1 Facts

- Created `PsychopatzActorLifecycle.lua` owning portable `LIVE -> RETIRED -> TOMBSTONE -> FORGOTTEN` transitions, `lifecycleRevision`, `Retire`, `PurgeTombstone`, `ResolveRef`, `ProjectIdentity`, and strict compact tombstone validation (rejecting inventory/social/knowledge/appearance/stock/unknown fields).
- Extended `PsychopatzPlayerIdentity.lua` with server-authoritative `RetireIssuedIdentity`, `PurgeRetiredIdentity`, `GetLifecycleState`, and `IsIssuedIdentity` rejection (`"identity_retired"`) for retired UUIDs while supporting `includeRetired = true` for lifecycle inspection.
- Integrated `Retire`, `HardDelete`, `GetTombstone`, `ListTombstones`, `TombstoneCount`, `GetLifecycleState`, and `ProjectIdentity` into `PsychopatzActorRegistry.lua` and `PsychopatzActors.lua`, preserving backward compatibility on legacy `Remove` while updating `PsychopatzActorMigration.Rollback` to use `HardDelete` with `reason = "rollback"`.
- Bumped `PsychopatzActorPersistence.lua` to `SCHEMA_VERSION = 3` (with v1/v2 backward-compatible decode, fail-closed tombstone/conflict validation, and zero extra fields on default live actors).
- Verified via `tests/psychopatz_actor_lifecycle_tombstone_smoke.lua` and 14 existing Core Actor/PlayerIdentity/Persistence/Social/Hotplug smoke tests (all PASS) plus `pz_verify.py --kahlua --severity ERROR` (0 errors across all 6 files).

## Immediate Next Chunk

**L2 — Reference providers and budgeted mark/sweep GC.**

Implement `PsychopatzActorGC.lua` (`RegisterReferenceProvider`, built-in `PsychopatzCore.Social` / `PsychopatzCore.SurvivorWorld` / `PsychopatzCore.WorldKnowledge` providers, generation/cursor-budgeted fail-closed mark-and-sweep, `ExplainRetention`, `ExplainPurge`, `GetDiagnostics`) and non-tick triggers in `PsychopatzActorRuntimeStore.lua` and `PsychopatzActors.lua`.
