# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — post-R6 audit reopened only two acceptance-proof gaps plus final continuity reconciliation.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R7 — final atomic acceptance-proof closure.
**Immediate Next Chunk:** R7A only — prove task pre→post public affordance lifecycle and settlement-admission post-success conversation refresh, with atomic settlement/ambient claim ownership; then continue automatically to R7B.

## Current planning checkpoint

~~~text
psychopatzCore   phase_commit: self (planning base 8a5ba7aec2e5fecad449c3b5abf28648d0e6a148)
ProjectHoomans   f749d7efd8fb64e59d2a2e0c1013ed5bbe0380cd
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot at planning time (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans concurrent NPC-authoring/UI work has landed separately through `f749d7ef` and the worktree is now clean. Treat those commits as unrelated to S11 unless a current test proves interaction.

Current repair authority:

`S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`

`S11_POST_R5_FINAL_CLOSURE_REPAIR.md` is historical R6 context.

## Retained accepted work

Do not rebuild:

- S11A0-A8;
- Identity / Needs / Greeting / maintained companion-command migrations;
- explicit exact-test `auditClaims` enforcement;
- production quest ready→rewarded→repeat lifecycle;
- event expiry and disband acceptance;
- canonical ProjectReply;
- single family-agnostic policy admission before domain routing;
- current CodeBuilder/integrity/caller-zero foundation.

Fresh post-R6 audit evidence retained:

- Core semantic-harness: **310 PASS, 2 skipped**;
- focused task/quest/disband/event provider suite: **25/25 PASS**;
- reconcile: **clean**, `desired=410`, zero missing/drifted/stale/ambiguous;
- integrity/determinism: **PASS**, `588` families, `407` deterministic files, `0` violations/diffs;
- `git diff --check` clean in all three repositories.

## Remaining defects

1. Task acceptance asserts retirement after transition but does not assert that `pnc:task.wait_at` was actually present/actionable before dispatch.
2. `audit.root.settlement_admission` uses one broad `settlement_ambient_admission_boundary` claim whose exact R6 owner exercises ambient visit only; settlement-admission post-success conversation refresh/retirement is not proven.
3. Continuity docs still disagree: top-level/parent/PROGRESS/HANDOFF claim completion while ROADMAP S11/S11D/S11E and the R6 repair plan remain active/partial/not accepted.

## Mandatory R7 sequence

~~~text
R7A  atomic task + settlement/ambient acceptance-proof closure
  ↓
R7B  full retained acceptance + exact final documentation checkpoint
~~~

No new architecture migration phase is allowed.

## Hard rules

- Keep R7 narrow; do not reopen accepted R1-R6 work without targeted failure evidence.
- Replace the broad combined settlement/ambient claim with atomic settlement and ambient post-success claims; no legacy claim alias.
- Exact test/case owners must declare the atomic audit claims they prove.
- Existing task and settlement services remain authoritative state; no semantic shadow state.
- Preserve the single generic policy-admission seam.
- Canonical CodeBuilder source/recipe first if semantic source changes are genuinely required; generated output remains downstream-only.
- No compatibility shims, fallback readers, aliases, dual registries/writes, or parallel old/new semantic paths.
- Preserve zero-LLM semantic correctness and N-participant foundations.
- Accepted multi-repo commits: changed adopters first, Core last; exact staging only; never push/publish without explicit authorization.
