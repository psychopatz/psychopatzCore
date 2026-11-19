# Progress — Portable Social State

**Status:** READY FOR USER LIVE TEST — P0-P12, H0-H8, and DT0-DT6 accepted.
**Current phase:** P12 — Complete (`13/13` phases accepted).
**Developer completion:** 13/13 phases accepted (`P0-P12`), plus participant completion (`H0-H8`, `DT0-DT6`).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified progress

- P0-P12 remain source and test verified across all three repositories:
  - P10 / H7 (ProjectHoomans `90fd69fb41ade486f26b181c09482b6015e9c463`, Core `b2190598f0c774115e8f388b90177f46852d76c4`): single persisted generic social authority in Core `actor.social` (`PNC` stores only `authority == "core"` extensions `morale`, `moraleBaseline`, `conduct` without derived `scores`, and `relationshipExtensions` with `bond` and `interactionJournal`; one-time `core_social_single_authority` v1 migration).
  - P11 (Core `407d7d8982944ad78fea815694ed82e7f16daf86`): removed `EvaluateAutonomyCandidates` and all action-specific scoring vocabulary (`TALK`, `TRADE`, `HELP`, `AVOID`, `CONFRONT`, `REPORT`, `RETALIATE`) from Core Actors after caller-zero check; enriched `QueryCandidateProjection` with bounded action-neutral decision features (`trustSignal`, `grievancePressure`, `assistanceHistory`, `familiaritySignal`, `cautionSignal`, `provenanceConfidence`, `directWitness`, `hearsayOnly`, `relationshipRevision`, `socialRevision`, `personality`, and `features`).
  - P12 / H8 / DT6 (`DT6` `c5a45962047068f6e597b36a0111bdd8d99abe13`, `H8` `aa5d422567d1567a478acb4b28d1cde0089166dd`, `P12` committed in Core): removed both `os.time` calls from `PsychopatzPlayerIdentity.lua` using PZ-safe `nowTimestamp()`, `ZombRand`/fallback RNG, and monotonic `issuedSeq` sequence persistence; proved `_G.os = nil` + constant clock/RNG 50-UUID collision-free SP/MP issuance, save/reset/reload, reconnect stability, and cross-account conflict rejection in `psychopatz_player_identity_smoke.lua` Test 8.
- Final P12 cross-repository verification matrix:
  - `acceptance --suite core_lua`: `66/66` PASS (Core-only, Core+Hoomans, Core+DTCommon+DTAbstract without PNC, combined `DTAbstract -> DTHoomans -> DTAbstract`, MP/replay/client rejection, reconnect convergence, single-persistence proof, bounded `SCENE`/`SHORT`/`LONG`/`ANCHOR` consolidation, lazy decay, RuntimeStore chunking, scale stress, and native Kahlua player identity safety).
  - `acceptance --suite dynamic_trading` & `DynamicTrading/tests/run_tests.py`: `90/90` PASS (zero DT production edits required).
  - ProjectHoomans scoped social/conduct/semantic-evidence/convergence suite: `26/26` PASS (1.30s).
  - ProjectHoomans full Lua sweep: `1,065/1,070` PASS (0 portable-social regressions; only the 4 pre-existing unrelated baselines plus 1 unrelated concurrent dirty starting-companion UI test `pnc_starting_companion_ui_interaction_smoke`).
  - `pz_verify.py` on `PsychopatzCore/Actors`: `32/32` files clean (`0` errors, `0` warnings); all `9` modified Hoomans production files clean (`0` errors).
  - CodeBuilder Social Policy & generation recipe unit tests: `8/8` OK; `reconcile.py --check`: `ok=true, clean=true` (`desired=467`, `missing=0`, `drifted=0`, `stale=0`).

## Immediate Next Chunk

All developer phases (`P0-P12`, `H0-H8`, `DT0-DT6`) are complete and verified. Ready for user live playtesting in Project Zomboid.
