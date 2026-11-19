# Progress — Portable Social State

**Status:** ACTIVE — P10 accepted; P11-P12 remaining.
**Current phase:** P11 — Action-neutral social decision features.
**Developer completion:** 11/13 phases accepted. P0-P10 are accepted; P11-P12 are pending.
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- P0-P10 remain source and test verified (P0-P9 committed historical milestones; P10 / H7 accepted).
- The 2026-11-19 re-audit independently reproduced 65/65 Core Lua, 90/90 DynamicTrading Lua, and 1,066/1,070 ProjectHoomans Lua with the same four known unrelated failures.
- CodeBuilder Social Policy tests remain 8/8 and reconcile.py --check is clean.
- The portable Core runtime is real: sparse directed relationships, SCENE/SHORT/LONG/ANCHOR retention, salience, bounded consolidation, lazy decay, provenance and confidence, revisions, server-authorized events, compact default omission, candidate projection and RuntimeStore chunking.
- DynamicTrading adoption is real: trader actor continuity, DTAbstract operation without PNC, relationship-aware pricing context, social-aware trader conversation and DTHoomans handoff sync are implemented.
- P10 / H7 complete (ProjectHoomans `90fd69fb41ade486f26b181c09482b6015e9c463`): Project Hoomans now serializes only PNC-owned extensions (`authority == "core"`, `morale`, `moraleBaseline`, `conduct` without derived `scores`, `relationshipExtensions` with `bond` and `interactionJournal`) while Core `actor.social` is the sole persisted generic relationship/memory authority. Combined serialization, reload with stripped Core `ProjectHoomans` extensions, versioned one-time legacy save migration, SemanticEvidence, Conduct, SocialEvents, RelationshipPresentation, and DTAbstract/DTHoomans dematerialization all pass (`core_lua` 66/66 including `psychopatz_social_single_persistence_authority_smoke`; Hoomans `pnc_portable_social_convergence_smoke` + 17/17 social/persistence smoke tests; Kahlua 0 errors on all 9 modified Hoomans files).
- Remaining finding B (P11): PsychopatzSocialProjections.EvaluateAutonomyCandidates is read-only but contains action-specific utility formulas. Portable Social State must expose action-neutral features; final candidate scoring belongs outside the social subsystem.
- Remaining finding C (P12): PsychopatzPlayerIdentity.lua still uses sandboxed os.time in identity issuance and UUID generation. This predates the job but is inside the multiplayer identity contract and must be removed before native-ready acceptance.

## Immediate Next Chunk

Execute P11 only: replace EvaluateAutonomyCandidates action-specific scoring in Core Actors with action-neutral social decision features in QueryCandidateProjection, migrate P2/P8 consumers to external synthetic tests, prove caller-zero across all three repos, and close P11 before advancing to P12.

Do not redo P0-P10 unless a P11-P12 regression requires touching an accepted foundation.
