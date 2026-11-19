# Progress — Portable Social State

**Status:** IN PROGRESS — P0–P8 accepted; advancing to P9.
**Current phase:** P9 — Scale, determinism, cross-mod regression, and final acceptance.
**Developer completion:** 9/10 phases accepted (P0, P1, P2, P3, P4, P5, P6, P7, P8).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- **P0 (Accepted):** Cross-repo ownership audit completed.
- **P1 (Accepted):** Froze portable Core contracts in `Docs/portable_social_state/ARCHITECTURE.md` §15.
- **P2 (Accepted):** Evolved `PsychopatzSocial.lua` (`PsychopatzSocialRetention.lua`, `PsychopatzSocialProjections.lua`, `PsychopatzActorSocialAuthority.lua`); `62/62` Core Lua suites pass.
- **P3 (Accepted):** Implemented CodeBuilder Social Policy IR (`psychopatz.social-policy.v1`), compiler (`social_policy_compiler.py`), `reconcile.py` surface (`social_policy_lua`), `PsychopatzSocialPolicy.lua`, and canonical packages across Core, Hoomans, and DTCommon.
- **P4 (Accepted):** Reconciled `ProjectHoomans` (`PNC_EntityRef`, `PNC_RelationshipTypes_Public`, `PNC_Persistence_CoreSocial`, `PNC_RelationshipMath`, `PNC_SocialEventDefinitions`, `PNC_RelationshipService_Queries`, `PNC_RelationshipService_Context`) onto Core generic relationship authority and `PNC/SocialPolicy/Registry`. Verified `24/24` Hoomans tests including cross-adopter DT+Hoomans convergence (`pnc_portable_social_convergence_smoke.lua`).
- **P5 (Accepted):** Completed `DynamicTrading / DTAbstract` (`DT2–DT3`) portable social adoption (`DTCommon_CoreActorPolicy` compiled `DTCommon/SocialPolicy/Registry` retention/consolidation, `BindFaction`/`EnsureTraderForFaction` `ca.actorID`, `DTAbstract_PreSurvivorWorldImport` social/lease sync, `DTHoomans_ProviderRuntime.DematerializeTrader` social preservation) working cleanly with `PNC = nil`.
- **P6 (Accepted):** Completed trader immersion and non-LLM conversation integration (`DT4`) across `DTCommon_CoreActorPolicy.QuerySocialProjection` / `PriceContext`, `DTCommon_MarketPricing.ContextRevision`, `DTCommon_TraderService.Snapshot`, and `DTCommon_TraderConversation` (`resolveRelationshipFrom`, differentiated non-LLM `responseFor`, `policyFor` context forwarding). Verified `90/90` DynamicTrading tests including `tests/dt_portable_social_trader_adoption_smoke.lua` and `pz_verify --kahlua` (`0` errors on all 8 modified DT production Lua files).
- **P7 (Accepted):** Proved MP authority and representation continuity across all 4 install matrices (`Core-only`, `Core+DTCommon+DTAbstract` with `PNC=nil`, `Core+ProjectHoomans` reconnect alias migration, and combined `DTAbstract -> DTHoomans -> DTAbstract` transition) in `tests/psychopatz_social_mp_continuity_matrix_smoke.lua`. Verified `63/63` Core Lua tests pass (`0` failures).
- **P8 (Accepted):** Proved the read-only future-autonomy candidate seam (`Authority.EvaluateAutonomyCandidates`) across `TALK`, `TRADE`, `HELP`, `AVOID`, `CONFRONT`, `REPORT`, and `RETALIATE` in `tests/psychopatz_social_autonomy_seam_smoke.lua` (`64/64` Core Lua tests pass): distinct personalities weight identical remembered betrayal + trade history deterministically (`selectedAction == nil`, `mutated == false`, zero state mutation, direct vs hearsay provenance sensitivity, and zero LLM use).

## Immediate Next Chunk

**P9 — Scale, cleanup, determinism, cross-mod regression, and final developer acceptance (`1,000+` actors, `500` repeated same-pair events, observer/hearsay/anchor bounds, `365d` lazy decay, `RuntimeStore` chunking, and full 3-repo suites).**
