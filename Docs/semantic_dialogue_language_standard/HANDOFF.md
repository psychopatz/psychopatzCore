# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: dirty_snapshot
planning_doc_commit: self
phase: S11R8 — Native-Parity and Acceptance-Reproducibility Repair
chunk: R8A — native task-state projection parity
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md
previous_repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R6_CLOSURE_AUDIT_REPAIR.md
updated_at: 2026-11-18
~~~

This planning snapshot does **not** accept R8A. ProjectHoomans is under active unrelated concurrent editing, so the stored residual fingerprint is a resume baseline only. Re-verify live HEAD/status before any R8 edit; never reset/stash/discard a mismatch.

## Participant planning checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 1bc5e92b83890c913da5ef46f50be04c0c270831)
ProjectHoomans   9fdfc7b63354f6d29912ff90b0d98c5edffdeb8c
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=29  sha256=24fc41eef99d6cd3649ab1b09e4bcc4a5aea0359330e3a2825254ea9e624b00f
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans has 29 unrelated concurrent NPC-authoring/editor residual paths at this dirty snapshot. Preserve them; on resume, re-verify live status and treat divergence as concurrent work, never as permission to reset/stash/discard.

## Retained accepted evidence

- R6 explicit exact `auditClaims` ownership remains accepted.
- R7 settlement-admission and ambient-visit atomic claim split/tests remain accepted.
- Quest READY_TO_TURN_IN → REWARDED → repeat remains accepted.
- Single generic policy admission remains accepted.
- Reconcile/integrity/determinism and legacy caller-zero remained green in the post-R7 audit.
- Focused R7 task/settlement/quest/event tests pass; the task defect is native-context parity, not the worker assertion itself.

## Why USER_ACCEPTANCE was revoked

### Native task projection

Production `Suggestions_Capabilities_Rows.lua` reads `context.taskStates`. The post-R7 audit found no native `Contents/` producer for that field; it is populated only by headless worker modules. Therefore `task_conversation_projection_lifecycle` is not sufficient proof of native runtime behavior.

### Canonical acceptance reproducibility

Fresh `python3 -m tools.semantic_harness.testing.acceptance --jobs 4` returns `8/9` because parallel Core tests observe temporary source files written into the live canonical source tree. Serial Core acceptance avoids that race but reports two unclassified Tk-display skips. R7B's "reproducibly green" gate is therefore not satisfied on current source.

## Immediate Next Chunk — R8A

1. Verify all participant HEADs/status and preserve the unrelated Hoomans residuals.
2. Read `S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md`.
3. Trace the authoritative native semantic-task lifecycle: dispatch, pending request ownership, server/task authority, result receipt, and terminal state.
4. Define/reuse one bounded task projection consumed by both native conversation context and worker.
5. Remove the worker-only semantic dependency: production suggestion state must not require a field only `Conversation_Context_Builder` can provide.
6. Add `task_native_projection_parity` to `audit.task.parameterized` and bind it to an exact native/native-equivalent test.
7. Prove WAIT_AT visible before request → admitted → native projection refresh → hidden/retired active/terminal → duplicate zero-dispatch.
8. Run focused native+worker task tests and explicit claim validation.
9. Stage/commit only R8A-owned Hoomans paths, preserving unrelated dirt; update Core manifest/inventory/docs and commit Core last.
10. Continue automatically to R8B.

## R8B

Make Core acceptance hermetic under parallel execution, move real-source mutation tests to isolated workspaces, resolve Tk test ownership deterministically, prove Core Python jobs=1/jobs=4 green, and run two consecutive canonical 9-suite `--jobs 4` passes from one exact vector.

## R8C

Run the full retained matrix from the exact final vector, reconcile docs to developer-complete only if green, record exact commits/residual fingerprints, then return to USER_ACCEPTANCE.

No push, Workshop publication, or native Project Zomboid launch without explicit authorization.
