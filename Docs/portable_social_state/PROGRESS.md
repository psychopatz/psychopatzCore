# Progress — Portable Social State

**Status:** ACTIVE — P11 accepted; P12 remaining.
**Current phase:** P12 — Native player identity safety and final cross-repository proof.
**Developer completion:** 12/13 phases accepted. P0-P11 are accepted; P12 is active.
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- P0-P11 remain source and test verified (P0-P9 committed historical milestones; P10/H7 and P11 accepted).
- The 2026-11-19 re-audit independently reproduced 65/65 Core Lua, 90/90 DynamicTrading Lua, and 1,066/1,070 ProjectHoomans Lua with the same four known unrelated failures.
- CodeBuilder Social Policy tests remain 8/8 and reconcile.py --check is clean.
- The portable Core runtime is real: sparse directed relationships, SCENE/SHORT/LONG/ANCHOR retention, salience, bounded consolidation, lazy decay, provenance and confidence, revisions, server-authorized events, compact default omission, candidate projection and RuntimeStore chunking.
- DynamicTrading adoption is real: trader actor continuity, DTAbstract operation without PNC, relationship-aware pricing context, social-aware trader conversation and DTHoomans handoff sync are implemented.
- P10 / H7 complete (ProjectHoomans `90fd69fb41ade486f26b181c09482b6015e9c463`, Core `b2190598f0c774115e8f388b90177f46852d76c4`): Project Hoomans now serializes only PNC-owned extensions while Core `actor.social` is the sole persisted generic relationship/memory authority.
- P11 complete: removed `EvaluateAutonomyCandidates` and all concrete action vocabulary (`TALK`, `TRADE`, `HELP`, `AVOID`, `CONFRONT`, `REPORT`, `RETALIATE`) and utility formulas from Core Actors social modules (`PsychopatzSocialProjections.lua`, `PsychopatzSocial.lua`, `PsychopatzActorSocialAuthority.lua`) after caller-zero proof across all three repositories. Enriched `QueryCandidateProjection` with bounded action-neutral decision features (`trustSignal`, `grievancePressure`, `assistanceHistory`, `familiaritySignal`, `cautionSignal`, `provenanceConfidence`, `directWitness`, `hearsayOnly`, `relationshipRevision`, `socialRevision`, normalized `personality`, and `features`). Migrated P2/P8 tests (`psychopatz_social_retention_consolidation_smoke.lua`, `psychopatz_social_autonomy_seam_smoke.lua`) to an external synthetic consumer; Kahlua 0 errors and `core_lua` 66/66 PASS.
- Remaining finding C (P12): PsychopatzPlayerIdentity.lua still uses sandboxed os.time in identity issuance and UUID generation (`L78`, `L135`). Must be replaced with a Project Zomboid-safe server-authoritative issuance mechanism before final cross-repo matrix validation and native-ready handoff.

## Immediate Next Chunk

Execute P12: remove sandboxed `os.*` usage from `PsychopatzPlayerIdentity.lua`, prove SP/MP collision-safe/reconnect/save-reload/cross-account identity issuance under `_G.os = nil`, and run the full P12 / DT6 / H8 cross-repository validation matrix before returning the job to READY FOR USER LIVE TEST.

Do not redo P0-P11 unless a P12 regression requires touching an accepted foundation.
