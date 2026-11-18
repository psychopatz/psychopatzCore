# ConvoEngine Handoff

~~~yaml
status: CLEAN_CHECKPOINT
checkpoint_mode: committed_handoff
planning_doc_commit: self
phase: S11R7 — Final Atomic Acceptance Closure
chunk: R7A — task + settlement/ambient acceptance proof
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R6_CLOSURE_AUDIT_REPAIR.md
previous_repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R5_FINAL_CLOSURE_REPAIR.md
updated_at: 2026-11-18
~~~

This planning checkpoint does **not** accept R7A. It records the audited final scope and clean participant baton.

## Participant planning checkpoint

~~~text
psychopatzCore   phase_commit: self (planning base 8a5ba7aec2e5fecad449c3b5abf28648d0e6a148)
ProjectHoomans   f749d7efd8fb64e59d2a2e0c1013ed5bbe0380cd
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

The unrelated ProjectHoomans authoring/UI work is now separately committed through `f749d7ef`; do not reinterpret it as S11 work.

## Retained accepted evidence

- R6A exact explicit `auditClaims` enforcement is accepted.
- R6B production quest READY_TO_TURN_IN → REWARDED → repeat idempotence is accepted.
- R6C single generic canonical policy-admission seam is accepted.
- Event expiry, disband, recruitment/proposal reply projection and legacy caller-zero remain accepted.
- Fresh audit reruns: Core 310 PASS / 2 skipped; focused provider 25/25 PASS; reconcile clean at 410 desired; integrity/determinism clean at 588 families / 407 deterministic files.

## Why S11 remains open

- task presentation test lacks explicit pre-transition actionable-affordance proof;
- settlement-admission post-success active-conversation refresh is not covered by the ambient-only exact owner;
- the broad combined settlement/ambient claim obscures this missing half;
- final continuity docs are internally contradictory.

## Immediate Next Chunk — R7A

1. Verify participant HEAD/status before edits.
2. Read `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`.
3. Add `task_conversation_projection_lifecycle` to the task audit requirements and exact task owner; assert `pnc:task.wait_at` is present/actionable before dispatch and retired/terminal after transition.
4. Replace `settlement_ambient_admission_boundary` with atomic `settlement_admission_post_success_refresh` and `ambient_visit_post_success_refresh` claims. No alias.
5. Keep the existing ambient post-success test as the ambient owner.
6. Add a real settlement-admission conversation-level test proving success → active-conversation refresh → stale admission affordance retirement → stale replay zero mutation.
7. Update manifest exact owners and run strict explicit-claim validation + focused tests.
8. Reconcile continuity docs, commit changed ProjectHoomans paths first and Core last, then continue automatically to R7B.

## R7B

Run full retained acceptance/generation/static/caller-zero gates. If green, rewrite all current closure docs to one final state and record exact participant commits plus live residual fingerprints.

No push, Workshop publication, or native Project Zomboid launch without explicit authorization.
