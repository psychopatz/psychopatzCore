---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1"
phase_commit_message: "phase(P1): freeze portable social state contracts and migration design"
phase_commit_vector: "psychopatz-core=self;project-hoomans=93452dc8d91d9f60cce4abc64adc8a76fd3cbdab;dynamic-trading=d94a62f421068c9d902d6d2dfcfa6b1a18825d82"
phase_residual_vector: "psychopatz-core=09d8026a0cd7fa3165e80567da675052525ad614419a54b596bec89ef2d54868;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "09d8026a0cd7fa3165e80567da675052525ad614419a54b596bec89ef2d54868"
codebase_memory_indexed_commit: "fba98ab4791bde95a12fb1fcb7fbeede88408d7a"
updated_at: "2026-11-19T10:28:50.492389Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "Evolve PsychopatzSocial in place with bounded retention, consolidation, lazy decay and projections"
retrieval_tier: "verify"
---


# Session Handoff — Portable Social State

## What became true

- P1 contracts frozen in `Docs/portable_social_state/ARCHITECTURE.md` §15:
  - Target key parsing (`actor:`, `npc:`, `player:`, `steam:`) and alias redirection.
  - Directed relationship baselines + memory/delta convergence invariant.
  - `SCENE`/`SHORT`/`LONG`/`ANCHOR` retention, hard bounds (`MAX_MEMORIES=64`, `SHORT=16`, `LONG=42`, `ANCHOR=6`), lazy decay, consolidation, and provenance (`direct`, `witnessed`, `hearsay`, `system`).
  - Non-mutating `QueryCandidateProjection` and `EvaluateAutonomyCandidates` read seams.
  - `psychopatz.social-policy.v1` / `psychopatz.social-policy.package.v1` CodeBuilder contract with `DomainSchemaRegistry` bridge.

## Remaining

- Implement P2–P9 across `PsychopatzCore`, `ProjectHoomans`, and `DynamicTrading`.

## Resume

Exact next action:

1. Evolve `PsychopatzSocial.lua` and `PsychopatzActorSocialAuthority.lua` for P2.
2. Update `tools/semantic_harness/testing/acceptance.py` `CORE_LUA_PATTERNS` and run `tests/psychopatz_social_retention_consolidation_smoke.lua` plus existing Core social/actor tests.

## Evidence

- `CODE_VERIFIED`: Frozen P1 contracts aligned against P0 audit evidence in `PsychopatzCore`, `ProjectHoomans`, and `DynamicTrading`.

## Expensive discoveries worth preserving

- `baselineApproval`/`baselineRespect` + active memory residues solve the cross-mod recalculation conflict between `DynamicTrading` and `ProjectHoomans`.
- Keeping `Social.NewState()` minimal preserves compact v2 default-omission in `PsychopatzActorPersistence.lua`.

## Blockers / open decisions

- None.

## Acceptance

P1 contracts frozen in `ARCHITECTURE.md`; proceed to P2 Core implementation.
