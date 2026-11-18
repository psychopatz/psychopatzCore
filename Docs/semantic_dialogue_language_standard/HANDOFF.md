# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11R5 — Post-R4 Closure Integrity Repair
chunk: R5A — acceptance inventory + ownership integrity
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
current_repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_R4_CLOSURE_AUDIT_REPAIR.md
historical_repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md
updated_at: 2026-11-18
~~~

This is a committed planning/handoff checkpoint only; it does **not** accept R5A.

## Participant checkpoint

~~~text
psychopatzCore   phase_commit: self (planning base ec49bd3ec9cafc251f360430c0858ed491ce3fcf)
ProjectHoomans   86000e26cc26561a99894a2abb978b6946da3c94
DynamicTrading   a1f9cbc3e986f5dafa35cdec34d7ac71e9846bf4
~~~

Residual fingerprints:

~~~text
psychopatzCore   rows=0   sha256=01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
ProjectHoomans   rows=0   sha256=01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
DynamicTrading   rows=2   sha256=ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5
~~~

ProjectHoomans is clean after unrelated UI/authoring commit `86000e26`. DynamicTrading has two unstaged generated ConvoEngine fingerprint drifts; treat them as uncertain/concurrent until source/reconcile evidence assigns ownership. Do not reset, stash, discard, or absorb either residual set.

## Retained accepted work

- S11A0-A8 foundation retained.
- R1 Identity retirement accepted.
- R2 command/Needs/Greeting recipe migration accepted.
- Canonical R3 recruitment/proposal/ceasefire/territory/effectful-social families retained.
- Recruitment/proposal transition-refresh + repeat-no-op fixtures retained.
- Fresh audit: Core 308 PASS / 2 skips; focused provider 17/17 PASS; reconcile clean at 410 desired; integrity/determinism clean at 588 families / 407 deterministic files.

## Why S11 is still open

- manifest coverage is not machine-complete against the branching audit;
- acceptanceOwner is not machine-verified;
- quest conversation lifecycle retains the repeated-offer shortcut;
- parameterized task state parity is not proven;
- event-expiry is absent from the manifest;
- disband and settlement/ambient owners are inadequate;
- generic `Input_Actions_Dispatch.lua` duplicates recruitment reply mapping already authored canonically;
- prior closure docs contradicted themselves and omitted residual fingerprints.

## Immediate Next Chunk — R5A only

1. Verify current participant HEAD/status/fingerprints and preserve unrelated/concurrent work.
2. Read `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md`.
3. Make constrained-family inventory closed-set/machine-complete against the normative audit inventory.
4. Make acceptance ownership machine-verifiable; a non-empty path is insufficient.
5. Add negative tests for omitted/extra audit rows, nonexistent owners/test IDs, owner-claim mismatch, and missing canonical policy.
6. Correct current manifest rows only after the mechanism can reject incomplete/mis-owned rows.
7. Reconcile continuity docs and commit accepted R5A locally; continue automatically to R5B.

## Mandatory continuation

~~~text
R5B  task/quest/event/disband/settlement-ambient closure
R5C  generic canonical reply projection; remove runtime family duplication
R5D  full acceptance + reconcile/determinism/static gates + exact final docs/fingerprints
~~~

Use existing `main`. Preserve unrelated work. Exact staging only. No reset/stash/discard/broad-stage/amend/rebase/force operations. Commit changed adopter repos first and Core last. Do not push, publish Workshop content, or launch native Project Zomboid without explicit authorization.
