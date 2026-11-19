# Progress — Portable Actor Lifecycle & Social Garbage Collection

**Status:** IN_PROGRESS — L0 accepted, starting L1.
**Current phase:** L1 — Core ActorRef lifecycle and tombstones.
**Developer completion:** 1/10 phases accepted (L0 ACCEPTED).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans (H0), DynamicTrading (D0).

## Verified L0 Facts

- Complete source-verified cross-repo removal/reference inventory and footprint baseline recorded in [AUDIT.md](AUDIT.md).
- Core `ActorRegistry:Remove` has 1 Core caller (`PsychopatzActorMigration.lua:315` -> `rollback-hard-delete`), 2 DT callers (`DTCommon_TraderGeneration.lua:98` -> `rollback-hard-delete`; `DTAbstract_PreSurvivorWorldImport.lua:181` -> `migration-redirect`), and 0 Hoomans callers (`PNC_Health_Death.lua` and `PNC_API/Lifecycle.lua` delete PNC records while leaking canonical Core actors).
- Measured serialized `ActorRegistry` baseline at `HEAD d2d6c62`:
  - `zero_social`: `0 -> 83 B`, `10 -> 12,353 B`, `100 -> 122,912 B` (5 chunks), `1000 -> 1,230,185 B` (42 chunks).
  - `sparse_5x4`: `10 -> 74,643 B`, `100 -> 751,552 B`, `1000 -> 7,584,695 B` (253 chunks).
  - High-contact `N × 64` multiplier (1 actor, same world hour): `1 -> 17,671 B`, `10 -> 162,208 B`, `25 -> 402,993 B`, `50 -> 804,193 B`, `100 -> 1,606,721 B` (6,400 persisted memories in one actor).
  - Compact tombstone estimate: `159 B`.
- Per-relationship `memories` readers/writers exist in only 3 Core files, 0 DT files, and ~24 Hoomans files.
- Confirmed non-existent subsystems: no DT debts/contracts/loans/trade logs; no Hoomans memorials/cemetery/prisoners/squads/persisted bed ownership.
- CodeBuilder `reconcile.py --check` (`467` desired, `0` drifted/stale) and `psychopatz_social_scale_stress_smoke.lua` (`1000` actors, `48` chunks) both pass cleanly at baseline.

## Immediate Next Chunk

**L1 — Core ActorRef lifecycle and tombstones.**

Implement `PsychopatzActorLifecycle.lua` and integrate `LIVE -> RETIRED -> TOMBSTONE -> FORGOTTEN` lifecycle, `lifecycleRevision`, `Retire`, `HardDelete`, compact tombstone validation/persistence (`v3` w/ `v1`/`v2` load support), `PlayerIdentity` character retirement/purge, and `LIVE/RETIRED/FORGOTTEN` identity projections in `psychopatzCore`.
