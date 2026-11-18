# S11 Post-R6 Closure Audit Repair

**Status:** HISTORICAL / PARTIAL ACCEPTANCE — R7A atomic claims/tests are retained; R7B's final developer-complete closure was invalidated by the post-R7 native-parity and acceptance-reproducibility audit.
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Previous repair:** `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`

**Current repair authority:** `S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md`. Do not restart R7; execute R8.

## Purpose

R6 successfully closed the major post-R5 defects: explicit exact-test `auditClaims` replaced keyword inference, the production quest lifecycle reaches READY_TO_TURN_IN → REWARDED → repeat idempotence, canonical policy admission is single-path, and broad developer-side tests/generation remain healthy.

A post-R6 audit found only two remaining behavioral acceptance gaps plus final documentation reconciliation:

1. parameterized-task acceptance checks retirement after state transition but does not prove the task affordance was actually visible/actionable before the transition;
2. the combined settlement/ambient audit claim is owned only by an ambient-visit post-success test, so settlement-admission post-success conversation refresh/retirement is not proven at the same level;
3. the final continuity documents still disagree about whether S11/S11D/S11E/R6 are closed.

This repair is intentionally the final narrow closure. Do not reopen S11A, R1-R6 architecture, quest, event, disband, recruitment/proposal policy, or other accepted domains without a targeted failing test.

## Retained evidence

Retain unless new R7 evidence disproves it:

- S11A0-A8 foundation;
- canonical Identity / Needs / Greeting / companion-command migrations;
- exact owner-declared `auditClaims` acceptance enforcement;
- all 25 maintained audit rows present in the closed-set inventory;
- production quest lifecycle offer → accept → active → READY_TO_TURN_IN → REWARDED → repeat idempotence;
- event expiry and disband acceptance;
- canonical `ProjectReply` and removal of hard-coded recruitment reply mapping;
- single family-agnostic canonical policy-admission seam before domain routing;
- fresh Core suite: 310 PASS / 2 skipped;
- fresh focused provider suite: 25/25 PASS;
- CodeBuilder reconcile clean at 410 desired outputs;
- integrity/determinism clean at 588 family files / 407 deterministic files / 0 violations;
- caller-zero retirement for legacy Identity/Needs/Greeting flows.

## R7 sequence

~~~text
R7A  atomic acceptance-proof closure
     task pre→post affordance proof
     + settlement admission post-success refresh proof
     + split settlement/ambient claim ownership
  ↓
R7B  full reproducible acceptance + one exact final continuity checkpoint
~~~

There is no R7 architecture migration phase.

# R7A — atomic acceptance-proof closure

## A. Parameterized task pre→post presentation proof

Retain the existing production worker test:

`test_parameterized_task_conversation_lifecycle_and_duplicate_suppression`

It already proves:

~~~text
admit → one dispatch
active duplicate → zero dispatch
terminal duplicate → zero dispatch
post-transition task affordance absent
~~~

Add the missing precondition proof:

~~~text
before request
→ public task affordance pnc:task.wait_at is present/actionable

after admitted/active
→ refreshed public suggestion surface removes or changes that actionable affordance according to policy

typed duplicate
→ zero dispatch

after terminal state
→ refreshed public suggestion surface remains retired/terminal

typed repeat
→ zero duplicate dispatch/effect
~~~

Do not merely assert that some unrelated `task.wait_at.active` ID is absent before dispatch.

The acceptance claim should describe this actual conversation-projection contract. Add a stable claim:

`task_conversation_projection_lifecycle`

to the branching-audit inventory and exact owning test.

Retain `task_generation_and_result_routing` for existing generation/result behavior; do not overload it to mean presentation lifecycle.

## B. Split settlement and ambient post-success claims

The current single inventory claim in R6 (`settlement_ambient_admission_boundary` in pre-R7 metadata) was too broad because the exact R6 owner proved only ambient-visit post-success refresh.

R7A replaced it with atomic stable claims:

~~~text
settlement_admission_post_success_refresh
ambient_visit_post_success_refresh
~~~

Do not retain the old combined claim as an alias/shim. This is internal acceptance metadata; update the inventory, manifest, and exact owner annotations together.

The existing ambient worker test may own:

`ambient_visit_post_success_refresh`

after verifying it still proves:

~~~text
ambient_visit visible
→ click accepted
→ authoritative visit state changes
→ active conversation refreshes
→ stale ambient_visit affordance disappears
→ stale frame replay has zero dispatch
~~~

Add one settlement-admission conversation-level test that owns:

`settlement_admission_post_success_refresh`

and proves:

~~~text
active settlement visit exposes settlement_admission affordance
→ click/execute admission through authoritative service
→ success result is handled by the production conversation path
→ NPC authoritative settlement/member state changes
→ current conversation refreshes
→ stale settlement_admission affordance disappears or changes
→ replaying the stale frame/input produces zero duplicate mutation
~~~

Reuse the existing settlement authority and client conversation result path. Do not create ConvoEngine settlement shadow state.

The low-level service/server smokes remain useful supporting evidence but are not substitutes for this public conversation-surface proof.

## C. Atomic claim rule

For any audit row that covers multiple independently observable surfaces, acceptance must either:

1. use separate atomic required claim IDs and exact owners for each surface; or
2. use one exact test that genuinely exercises every constituent behavior.

A sibling behavior must never certify an untested sibling merely because both share a broad combined claim name.

## R7A gate

R7A is accepted only when:

- `audit.task.parameterized` requires and owns `task_conversation_projection_lifecycle`;
- the task owner explicitly proves pre-transition affordance presence and post-transition retirement/terminal projection;
- `audit.root.settlement_admission` requires both atomic settlement and ambient post-success claims;
- an exact ambient owner declares `ambient_visit_post_success_refresh`;
- an exact settlement-admission conversation owner declares `settlement_admission_post_success_refresh`;
- strict closed-set/explicit-claim Completeness passes;
- focused task + settlement/ambient tests pass;
- no compatibility shim or duplicate state authority is introduced.

Commit any changed ProjectHoomans paths first, then Core manifest/inventory/docs last. Continue automatically to R7B.

# R7B — final reproducible closure

Only after R7A is accepted.

## Focused reruns

Run at least:

- Core completeness-analyzer explicit-claim tests;
- parameterized-task lifecycle/presentation test;
- settlement-admission conversation refresh test;
- ambient-visit conversation refresh test;
- quest production lifecycle regression;
- event expiry regression;
- disband confirmation regression;
- recruitment/proposal policy/reply regressions.

## Full retained gates

Then run:

- full Core semantic-harness;
- ProjectHoomans provider tests;
- real LuaSemanticWorker paths;
- response-channel/click and typed/free-text acceptance;
- canonical nine-suite acceptance;
- CodeBuilder `reconcile.py --check`;
- ConvoEngine integrity/determinism;
- Kahlua/static verification;
- legacy Flow_Identity / Flow_Needs / Flow_Greeting caller-zero;
- `git diff --check`.

Do not bless new baselines merely to make the matrix green.

## Final documentation reconciliation

Rewrite, do not append, current closure state in:

- `ROADMAP.md`;
- `PROGRESS.md`;
- `HANDOFF.md`;
- `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`;
- `S11_BRANCHING_DIALOGUE_AUDIT.md`;
- this R7 repair doc;
- `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`;
- `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md` where it still names a newer repair as active.

At final acceptance:

- parent ROADMAP status must be COMPLETE_DEVELOPER_SIDE;
- S11 must be COMPLETE_DEVELOPER_SIDE / ACCEPTED;
- S11D must be ACCEPTED;
- S11E must be ACCEPTED;
- R6 must be HISTORICAL / ACCEPTED;
- R7 must be ACCEPTED / CLOSED;
- R6/R5 repair documents must be historical, not active repair authorities;
- PROGRESS must contain exactly one next responsibility: user-owned native Project Zomboid acceptance;
- HANDOFF must contain one exact participant checkpoint.

Git history is the archive. Do not leave stale IN_PROGRESS/PARTIAL/NOT ACCEPTED prose under a final completion heading.

## Final checkpoint

Final HANDOFF records:

~~~text
exact psychopatzCore commit
exact ProjectHoomans commit
exact DynamicTrading commit
exact residual path count per repo
SHA-256 of exact git status --porcelain=v1 -uall bytes
full acceptance evidence
~~~

Re-snapshot after the final participant/Core commits. Never predict the final primary SHA.

## No-shim / CodeBuilder invariant

Do not introduce:

- compatibility wrappers;
- old/new acceptance claim aliases;
- fallback readers;
- dual registries or writes;
- shadow task or settlement state;
- hand-edited generated CodeBuilder output.

Dialogue semantic changes, if any are actually required, remain canonical source/recipe first and generated downstream through the established reconcile pipeline.

## Completion invariant

R7's intended developer-side completion gate was:

> the representative task public affordance (`pnc:task.wait_at`) is proven present before dispatch and correctly retired/projected after active/terminal state (`task_conversation_projection_lifecycle`); settlement admission (`settlement_admission_post_success_refresh`) and ambient visit (`ambient_visit_post_success_refresh`) each have their own exact post-success conversation-refresh claim owner; the full retained acceptance is reproducibly green (`9/9` canonical suites PASS); and every continuity document records one consistent committed checkpoint with current participant residual fingerprints. Next responsibility is user-owned native Project Zomboid SP/MP acceptance.
