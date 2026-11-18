# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — post-R7 audit invalidated only native task-projection parity and reproducible final acceptance.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R8 — native-parity and acceptance-reproducibility repair.
**Immediate Next Chunk:** R8A only — replace worker-only task-state presentation truth with one bounded native+worker task projection, add exact native-equivalent acceptance ownership, and preserve unrelated ProjectHoomans dirt; then continue automatically to R8B.

## Current planning checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 1bc5e92b83890c913da5ef46f50be04c0c270831)
ProjectHoomans   9fdfc7b63354f6d29912ff90b0d98c5edffdeb8c
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot at planning time (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=7   sha256=b11302923307a5444314d5d55a1ee8ca8e3cfe59cf9c4a2f8f06cce0c7a4e720
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

The seven ProjectHoomans residuals are unrelated StartingCompanion/NPC-authoring work:

~~~text
Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter.lua
Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/CharacterCreation/PNC_StartingCompanionSession.lua
Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Identity/PNC_NPCAuthoringComposer.lua
Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Identity.lua
Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_NPCAuthoringResolver.lua
Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_StartingCompanionCustomization.lua
Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_StartingCompanionSanitizer.lua
~~~

Do not reset, stash, stage, rewrite, or otherwise absorb these paths into R8.

Current repair authority:

`S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md`

`S11_POST_R6_CLOSURE_AUDIT_REPAIR.md` is historical R7 context.

## Retained accepted work

Do not rebuild:

- S11A0-A8;
- Identity / Needs / Greeting / companion-command migrations;
- exact explicit `auditClaims` validation;
- production quest ready→rewarded→repeat;
- settlement-admission and ambient-visit atomic post-success claims/tests;
- event expiry and disband acceptance;
- canonical ProjectReply;
- single generic policy admission before domain routing;
- CodeBuilder reconciliation/integrity foundation;
- legacy Identity/Needs/Greeting caller-zero.

## Post-R7 blockers

### 1. Native task projection parity

R7's task lifecycle test passes because the headless worker injects `Runtime.taskStates` into `Conversation_Context_Builder`. Native conversation construction does not produce `taskStates`, while production `Suggestions_Capabilities_Rows.lua` reads it. Therefore the new WAIT_AT retirement behavior is not proven to work in-game.

### 2. Canonical acceptance is not reproducibly green

Fresh canonical acceptance from the recorded vector returns `8/9` because parallel Core tests race on real canonical source mutation. `test_psdl_semantic_domain_decomposition` transiently writes `g9r_fixture_taunt.json` into the live source tree while `test_semantic_generation_ownership_and_cleanup` concurrently runs the canonical reconcile/check.

Serial Core acceptance avoids that race but produces two unclassified `requires a Tk display` skips from `test_gui_startup`.

## Mandatory R8 sequence

~~~text
R8A  native task-state projection parity
  ↓
R8B  acceptance isolation + deterministic GUI/accounting ownership
  ↓
R8C  exact-vector full acceptance + final continuity closure
~~~

## Hard rules

- Keep R8 narrow; do not reopen retained R1-R7 behavior without targeted failure evidence.
- Native and worker task presentation must consume one bounded authoritative task projection contract.
- Worker `Runtime.taskStates` cannot remain the only producer for state used by production suggestion code.
- Do not create shadow task state, fallback task readers, dual stores/writes, or compatibility aliases.
- Parallel tests must not mutate live canonical source trees; use isolated temporary repositories/workspaces.
- Do not solve the acceptance defect by forcing serial-only canonical acceptance or adding a new baseline.
- Tk/GUI tests need one explicit deterministic suite ownership policy; do not create another GUI harness.
- Two consecutive canonical 9-suite `--jobs 4` runs must pass from the same exact final vector.
- Canonical CodeBuilder source/recipe discipline remains mandatory; generated output is downstream-only.
- Preserve unrelated dirty work exactly.
- Accepted multi-repo commits: changed adopter paths first, Core last; exact staging only; never push/publish without explicit authorization.
