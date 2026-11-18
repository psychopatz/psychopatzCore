# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — R7A atomic acceptance-proof closure is accepted; executing R7B full reproducible acceptance and final continuity closure.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R7 — final atomic acceptance-proof closure.
**Immediate Next Chunk:** R7B only — run focused retained regressions and full acceptance gates, rewrite all closure/continuity documents to one final consistent checkpoint, and record final participant commits and residual fingerprints.

## Current R7A checkpoint

~~~text
psychopatzCore   phase_commit: self (parent f2fd68542bf77f93ceb4f649cab484e98ad3140a)
ProjectHoomans   ec0d61f85d077d81d58b5da855e7fab527427742
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0    sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=40   sha256=80332df13f94402e85f808560350bd638aaa9d44c042ad3cd0fd875cb40552de
DynamicTrading   rows=0    sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans concurrent NPC-authoring/UI work remains preserved in its dirty working tree (40 unrelated rows) and is not touched by S11R7.

Current repair authority:

`S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`

## Accepted R7A evidence

- `task_conversation_projection_lifecycle` added to `audit.task.parameterized` in `S11_BRANCHING_AUDIT_INVENTORY.json` and `constrained_family_manifest.json`, explicitly owned by `test_parameterized_task_conversation_lifecycle_and_duplicate_suppression` (`test_automatic_flow_generation.py`, 10/10 PASS), proving `pnc:task.wait_at` is visible/actionable before dispatch, retired after active transition with zero duplicate dispatch on typed repeat, and remains retired across `completed`/`failed`/`rejected` states.
- `settlement_ambient_admission_boundary` replaced with atomic `settlement_admission_post_success_refresh` and `ambient_visit_post_success_refresh` claims (no compatibility alias).
- `test_ambient_visit_root_choice_refreshes_and_retires_after_start` owns `ambient_visit_post_success_refresh`.
- `test_settlement_admission_root_choice_executes_authority_and_refreshes_conversation` owns `settlement_admission_post_success_refresh` (`test_production_leave_group.py`, 7/7 PASS), proving active settlement visit exposes `conversation.root:menu:settlement_admission`, click executes `MobileSettlementVisitService.AdmitPlayer` through production authority, NPC/member/settlement state updates, active conversation refreshes/closes and retires `settlement_admission`, and stale frame replay yields zero dispatch and zero duplicate mutation.
- `test_convo_engine_completeness_analyzer.py` (6/6 PASS) and `test_classification_guard.py` (2/2 PASS) green.

## Immediate Next Chunk — R7B

1. Run focused retained regressions (task presentation lifecycle, settlement-admission refresh, ambient-visit refresh, production quest ready→rewarded→repeat, event expiry, disband confirmation/cancel/replay, recruitment/proposal canonical policy + reply projection, explicit `auditClaims` negative guards).
2. Run full retained acceptance gates (Core semantic-harness suite, ProjectHoomans provider suite, real `LuaSemanticWorker` paths, typed/free-text acceptance, response-channel/click acceptance, canonical nine-suite acceptance, CodeBuilder `reconcile --check`, ConvoEngine integrity/determinism, Kahlua/static verification, `Flow_Identity` / `Flow_Needs` / `Flow_Greeting` caller-zero, `git diff --check`).
3. Rewrite all 8 continuity/closure documents to one final consistent `COMPLETE_DEVELOPER_SIDE` / `ACCEPTED` state and record exact post-commit participant checkpoint in `HANDOFF.md`.
