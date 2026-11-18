# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — post-R5 audit reopened final S11 closure; accepted S11A/R1/R2 and useful R5 work are retained.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R6 — exact acceptance claims + residual lifecycle/presentation closure + single generic policy admission.
**Immediate Next Chunk:** R6A only — replace keyword-based acceptance-claim inference with explicit stable claim IDs owned by the exact test/case; then continue automatically through R6B-R6D.

## Current planning checkpoint

~~~text
psychopatzCore   phase_commit: self (planning base bd1a242f0cd9d641ea442b4050e2958471c84fd1)
ProjectHoomans   233ff16bac368588dfa1d0deb3b087b31fca18e7
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual worktree snapshot for this planning checkpoint:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=48  sha256=a89ef933ce04f0c1e1e9d8ddc14883ba76f4e0a022c9f7a24639e405caa74f47
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans currently contains concurrent unrelated `UnifiedStartingCompanionAuthoring` / NPCAuthoring / StartingCompanions / UniqueNPCEditor work; preserve it exactly. Core and DynamicTrading are clean after the planning commit. Re-verify the Hoomans fingerprint at resume because concurrent work may continue.

Current repair authority:

`S11_POST_R5_FINAL_CLOSURE_REPAIR.md`

`S11_POST_R4_CLOSURE_AUDIT_REPAIR.md` is historical R5 context and must not be restarted.

## Retained accepted work

Do not rebuild these unless a new targeted test proves an actual defect:

- S11A0-A8 compiler/runtime foundation;
- canonical Identity, Needs, Greeting, and maintained companion-command migrations;
- R5 closed-set 25-row branching-audit inventory and exact owner source/test-ID existence checks;
- event response-window expiry acceptance;
- disband presentation-only confirmation/cancel/replay acceptance;
- recruitment/proposal canonical reply projection via `S11PolicyEvaluator.ProjectReply`;
- removed hard-coded recruitment reason→template/text mappings;
- fresh Core suite: **310 PASS, 2 skipped**;
- fresh focused R5B provider suite: **24/24 PASS**;
- CodeBuilder reconcile: **clean**, `desired=410`, no missing/drifted/stale/ambiguous output;
- integrity/determinism: **PASS**, `588` family files, `407` deterministic files, `0` violations/diffs.

## Reopened final defects

1. Acceptance semantic ownership still relies on `claimKeywords`/source-text matching. The exact test/case must explicitly declare stable audit claim IDs; manifest repetition or source keywords are not proof.
2. Production quest conversation acceptance stops at active/premature turn-in and does not prove READY_TO_TURN_IN → REWARDED → repeat idempotence.
3. Parameterized-task acceptance proves duplicate suppression but not refreshed suggestion/response-channel parity across active/terminal state.
4. Settlement/ambient acceptance proves service/authority/replay/expiry but not post-success active-conversation affordance refresh/retirement.
5. Generic `Input_Actions_Dispatch.lua` still names `RECRUIT`/`RELATIONSHIP_PROPOSAL` solely to run canonical policy before their domain dispatchers; policy admission must be one generic path.
6. Previous R5 closure docs disagreed and the Hoomans residual fingerprint became stale.

## Mandatory R6 sequence

~~~text
R6A  explicit exact-test acceptance claim ownership
  ↓
R6B  quest + task + settlement/ambient lifecycle/presentation closure
  ↓
R6C  single generic canonical policy-admission seam
  ↓
R6D  full reproducible acceptance + exact final continuity checkpoint
~~~

Do not return to user-owned native Project Zomboid acceptance until R6A-R6D pass.

## Hard rules

- Preserve accepted R5 mechanisms; repair only the remaining gaps.
- No semantic acceptance proof by keyword/substrings or whole-file text search.
- The audit inventory defines required stable claim IDs; the exact owner test/case explicitly declares the claims it owns.
- Existing QuestService/task/settlement authorities remain mutable truth; do not create ConvoEngine shadow state.
- Generic runtime evaluates canonical policy once before domain routing; family names may remain in mutation routing, not in policy-admission selection.
- Canonical CodeBuilder source/recipe first; generated outputs downstream-only.
- No compatibility shims, fallback readers, dual registries/writes, aliases, or parallel legacy/new semantic paths.
- Preserve N-participant/emergent-dialogue foundations and zero-LLM semantic correctness; do not implement the future Dialogue Director.
- Accepted multi-repo phase commits: changed adopters first, Core last. Exact staging only. Never push/publish without explicit authorization.
