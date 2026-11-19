---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
base_checkpoint: "903e064"
participant_checkpoint_vector: "psychopatz-core=903e064;project-hoomans=451cdc2db;dynamic-trading=349b226f"
worktree_status_fingerprint: "81a8b25cc105b403b9eea1a9d584bc2c84b2fbfdf889fa8c523a67627e3459e0"
participant_worktree_status_vector: "psychopatz-core=81a8b25cc105b403b9eea1a9d584bc2c84b2fbfdf889fa8c523a67627e3459e0;project-hoomans=fc70567fed30529eb46a230f2827f00b6d4b7954b2586fcf0ce3d98a74f5ed84;dynamic-trading=65de531eb3c602623e3e91e6f5e2ccdac14e4eb681af96f150f6d2159590fc3a"
state: "USER_ACCEPTANCE"
parent_status: "READY_FOR_USER_LIVE_TEST"
phase: "P12"
chunk: "All P0-P12 / H0-H8 / DT0-DT6 developer milestones complete and ready for user live playtesting"
retrieval_tier: "verify"
phase_commit: "self"
phase_commit_phase: "P12"
phase_commit_message: "phase(P12): P12: remove sandboxed os.time from PsychopatzPlayerIdentity and complete P0-P12 proof"
phase_commit_vector: "psychopatz-core=self;project-hoomans=aa5d422567d1567a478acb4b28d1cde0089166dd;dynamic-trading=c5a45962047068f6e597b36a0111bdd8d99abe13"
phase_residual_vector: "psychopatz-core=257e51a2d5ccfdfd1282a2c208716b591691eca17028e88ba65368715d222c7c;project-hoomans=572792a94bb71aa94c7162f5125623c49535f4517783e452b425a5d009dac9bb;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "257e51a2d5ccfdfd1282a2c208716b591691eca17028e88ba65368715d222c7c"
codebase_memory_indexed_commit: "fba98ab4791bde95a12fb1fcb7fbeede88408d7a"
updated_at: "2026-11-19T12:50:45.098657Z"
---




# Session Handoff — Portable Social State

## Accepted completion (P0-P12, H0-H8, DT0-DT6)

All 13 Core phases (`P0-P12`), 9 ProjectHoomans participant phases (`H0-H8`), and 7 DynamicTrading participant phases (`DT0-DT6`) are complete, source-verified, tested, and committed locally across all three repositories.

## Post-P9 cleanup resolution

1. **P10 / H7 (ProjectHoomans `90fd69fb41ade486f26b181c09482b6015e9c463`, Core `b2190598f0c774115e8f388b90177f46852d76c4`):** Core `actor.social` is now the single persisted authority for generic directed social relationships and memories; Project Hoomans persists only PNC-specific extensions (`authority == "core"`, morale, conduct without derived scores, bond, interactionJournal) with explicit one-time migration for legacy saves.
2. **P11 (Core `407d7d8982944ad78fea815694ed82e7f16daf86`):** Removed `EvaluateAutonomyCandidates` and concrete action vocabulary from Core Actors social modules after caller-zero proof; `QueryCandidateProjection` exposes bounded action-neutral social decision features evaluated externally in tests.
3. **P12 / H8 / DT6 (DT `c5a45962047068f6e597b36a0111bdd8d99abe13`, Hoomans `aa5d422567d1567a478acb4b28d1cde0089166dd`, Core `self`):** Removed `os.time` dependence from `PsychopatzPlayerIdentity.lua` using PZ-safe timestamps, `ZombRand`/fallback RNG, and monotonic persisted issuance sequencing; proved 50 collision-free SP+MP UUID issuances and save/reload/reconnect/cross-account checks under `_G.os = nil`.

## Final reproduced evidence

- Core `acceptance --suite core_lua`: `66/66` PASS.
- DynamicTrading `acceptance --suite dynamic_trading` & `tests/run_tests.py` (`DT6`): `90/90` PASS (zero DT production edits).
- ProjectHoomans H8 scoped social/conduct/semantic-evidence/convergence suite: `26/26` PASS (1.30s).
- ProjectHoomans full Lua sweep: `1,065/1,070` PASS (0 portable-social regressions; only the 4 pre-existing unrelated baselines plus 1 unrelated concurrent dirty starting-companion UI test `pnc_starting_companion_ui_interaction_smoke`).
- Kahlua lint (`pz_verify.py`): `0` errors across all `32/32` `PsychopatzCore/Actors` files and all `9` modified ProjectHoomans production files.
- Social Policy CodeBuilder unit tests: `8/8` OK; `reconcile.py --check`: `ok=true, clean=true` (`desired=467`, `missing=0`, `drifted=0`, `stale=0`).

## Exact next step (User-owned)

Ready for user live Project Zomboid playtesting across Core-only, Core + DTCommon + DTAbstract (PNC disabled), and combined Core + ProjectHoomans + DynamicTrading.

## Safety

All unrelated portrait and NPC authoring/starting-companion work in `psychopatzCore` and `ProjectHoomans` has been preserved untouched. Only phase-owned paths were staged and committed locally (no push, reset, stash, rebase, publish, or native PZ execution).
