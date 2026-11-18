# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11R6 — Final Closure Repair
chunk: R6A — explicit exact-test acceptance claim ownership
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R5_FINAL_CLOSURE_REPAIR.md
previous_repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R4_CLOSURE_AUDIT_REPAIR.md
updated_at: 2026-11-18
~~~

This committed planning checkpoint does **not** accept R6A. It only records the audited R6 scope and resume baton.

## Participant planning base

~~~text
psychopatzCore   phase_commit: self (planning base bd1a242f0cd9d641ea442b4050e2958471c84fd1)
ProjectHoomans   233ff16bac368588dfa1d0deb3b087b31fca18e7
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual worktree snapshot (`git status --porcelain=v1 -uall` SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=47  sha256=4235fbd994cfc2065023158211f001105ca06e7942a6dd8647d86ec3c0b75e6a
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans has concurrent unrelated NPCAuthoring/StartingCompanions/UniqueNPCEditor work. Preserve it. Re-verify the residual fingerprint before every edit/accepted phase because concurrent work may continue.

## Retained accepted evidence

- S11A/R1/R2 accepted.
- R5 closed-set audit inventory and exact source/test ID resolution retained.
- Event expiry and disband acceptance retained.
- Canonical `ProjectReply` retained; hard-coded recruitment text/reason mappings remain removed.
- Fresh audit reruns: Core 310 PASS / 2 skips; focused provider 24/24 PASS; reconcile clean at 410 desired; integrity/determinism clean at 588 families / 407 deterministic files.

## Why S11 remains open

- claim ownership is still keyword/source-text heuristic instead of explicit stable claim IDs declared by the exact owner;
- production quest lifecycle does not reach ready/rewarded/repeat;
- task suggestion/response-channel projection after active/terminal transition is not proven;
- settlement/ambient active-conversation refresh after success is not proven;
- recruitment/proposal are still special-cased solely for policy admission in generic dispatch;
- prior closure docs/checkpoint were inconsistent/stale.

## Immediate Next Chunk — R6A only

1. Verify all participant HEAD/status/residual fingerprints; preserve concurrent Hoomans work.
2. Read `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`.
3. Keep the closed-set 25-row inventory.
4. Replace `claimKeywords` acceptance proof with exact owner-declared stable audit claim IDs.
5. Prefer test-local metadata: declarative case `auditClaims`; exact Python method metadata/docstring/classification; exact Lua smoke/test claim marker. Do not create a duplicate broad test registry.
6. Make manifest self-declaration and source keywords insufficient to pass.
7. Add negative guards for missing/wrong owner claims, keyword-only false positives, Lua whole-file false positives, and stale renamed tests.
8. Reconcile continuity docs and commit accepted R6A locally; continue automatically to R6B.

## Mandatory continuation

~~~text
R6B  complete production quest ready/rewarded/repeat +
     task and settlement/ambient conversation projection
R6C  unify policy admission before domain dispatch
R6D  full acceptance + one exact final docs/vector/fingerprint checkpoint
~~~

Use existing `main`. Preserve unrelated work. Exact staging only. No reset/stash/discard/broad-stage/amend/rebase/force operations. Commit changed adopter repos first and Core last. Do not push, publish Workshop content, or launch native Project Zomboid without explicit authorization.
