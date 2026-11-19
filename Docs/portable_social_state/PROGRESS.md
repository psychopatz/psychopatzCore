# Progress — Portable Social State

**Status:** IN PROGRESS — P0 and P1 accepted; advancing to P2.
**Current phase:** P2 — Core bounded retention and consolidation.
**Developer completion:** 2/10 phases accepted (P0, P1).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- **P0 (Accepted):** Reconciled cross-repo ownership audit completed (`Docs/portable_social_state/AUDIT.md` and participant docs); baseline footprint benchmarked; baseline smoke tests and `reconcile.py --check` green.
- **P1 (Accepted):** Froze portable Core contracts in `Docs/portable_social_state/ARCHITECTURE.md` §15: target-key parsing (`actor:`, `npc:`, `player:`, `steam:`), directed relationship fields + baseline/memory convergence invariant, `SCENE`/`SHORT`/`LONG`/`ANCHOR` retention limits, lazy decay, consolidation, provenance, `QueryCandidateProjection` / `EvaluateAutonomyCandidates` read seams, compact default-omission invariant, and `psychopatz.social-policy.v1` CodeBuilder IR contract.

## Immediate Next Chunk

**P2 — Evolve `PsychopatzSocial.lua` and `PsychopatzActorSocialAuthority.lua` in place**, update `acceptance.py` `CORE_LUA_PATTERNS`, and prove bounded retention, consolidation, lazy decay, provenance, and candidate projections via `tests/psychopatz_social_retention_consolidation_smoke.lua`.
