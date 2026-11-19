# Progress — Portable Social State

**Status:** IN PROGRESS — P0, P1, P2 accepted; advancing to P3.
**Current phase:** P3 — CodeBuilder Social Policy IR.
**Developer completion:** 3/10 phases accepted (P0, P1, P2).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- **P0 (Accepted):** Reconciled cross-repo ownership audit completed (`Docs/portable_social_state/AUDIT.md` and participant docs); baseline footprint benchmarked; baseline smoke tests and `reconcile.py --check` green.
- **P1 (Accepted):** Froze portable Core contracts in `Docs/portable_social_state/ARCHITECTURE.md` §15.
- **P2 (Accepted):** Evolved `PsychopatzSocial.lua` in place (with cohesive helpers `PsychopatzSocialRetention.lua` and `PsychopatzSocialProjections.lua` and `PsychopatzActorSocialAuthority.lua` wrappers): `ParseTargetKey`, `SCENE`/`SHORT`/`LONG`/`ANCHOR` retention limits, salience-aware replacement/demotion (`MAX_ANCHOR_MEMORIES = 6`), lazy decay (`CalculateMemoryStrength`, zero per-tick loop), consolidation (`consolidationKey`/`count`/`firstCreatedAt`/caps), provenance (`direct`/`witnessed`/`hearsay`/`system`, `confidence`, `sourceKey`), `ApplyPersonalityModulation`, `RecalculateRelationship`, `QueryCandidateProjection`, and `EvaluateAutonomyCandidates`. Preserved `Social.NewState()` compact default-omission invariant. Updated `acceptance.py` `CORE_LUA_PATTERNS` so all 62 Core Lua suites run (`62/62` passing). Added `tests/psychopatz_social_retention_consolidation_smoke.lua`.

## Immediate Next Chunk

**P3 — Extend the existing CodeBuilder framework (`tools/semantic_harness/codebuilder/`) with portable `psychopatz.social-policy.v1` / `psychopatz.social-policy.package.v1` IR, `social_policy_lua` surface, `DomainSchemaRegistry` bridge, `PsychopatzSocialPolicy.lua` runtime loader, and canonical Core/Hoomans/DT social policy packages.**
