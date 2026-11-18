# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — R5A accepted (closed-set `S11_BRANCHING_AUDIT_INVENTORY.json` + machine-verifiable `acceptance` ownership + 6 negative guards passing); advancing to R5B.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R5 — R5B remaining S11D state/lifecycle closure (tasks + quests + event expiry + disband + settlement/ambient).
**Immediate Next Chunk:** R5B — close parameterized task lifecycle, QuestService conversation lifecycle, disband explicit confirmation/typed policy, and settlement/ambient post-transition projection.

## Current checkpoint

~~~text
psychopatzCore   phase_commit: self (planning base ec49bd3ec9cafc251f360430c0858ed491ce3fcf)
ProjectHoomans   86000e26cc26561a99894a2abb978b6946da3c94
DynamicTrading   a1f9cbc3e986f5dafa35cdec34d7ac71e9846bf4
~~~

Residual worktree fingerprints:

~~~text
psychopatzCore   rows=0   sha256=01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
ProjectHoomans   rows=0   sha256=01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
DynamicTrading   rows=2   sha256=ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5
~~~

- Core is clean.
- ProjectHoomans concurrent NPCAuthoring/StartingCompanions/UniqueNPCEditor work landed separately as `86000e26`; the worktree is now clean. Treat that commit as unrelated to S11 unless current tests show interaction.
- DynamicTrading currently has two unstaged generated ConvoEngine fingerprint-only drifts in `Manifest.lua` and `Registry.lua`. Preserve them until ownership/reconcile evidence proves whether they belong to R5 or concurrent work.

Current repair authority: `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md`. The earlier `S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md` is historical R0-R4 context.

## Accepted / retained implementation

Do not rebuild or remigrate these merely because S11 closure is reopened:

- S11A0-A8 compiler/runtime foundation remains accepted.
- R1 Identity migration is accepted: superseded `Flow_Identity.lua` is deleted and absent from `FlowCatalog.lua`.
- R2 command/Needs/Greeting migration is accepted: superseded `Flow_Needs.lua` and `Flow_Greeting.lua` are deleted; maintained companion command policies are canonical.
- R3 canonical families for recruitment, relationship proposal, ceasefire, territory, and effectful wellbeing/trust exist.
- Recruitment and relationship proposal have real multi-turn transition-refresh + repeat-no-op fixtures.
- Fresh Core semantic-harness unit suite: **308 tests PASS, 2 skipped**.
- Focused ProjectHoomans quest/event/automatic-flow tests rerun during audit: **17/17 PASS**.
- CodeBuilder reconcile: **clean**, `desired=410`, `missing=0`, `drifted=0`, `stale=0`, `ambiguous=0`.
- Integrity/determinism: **PASS**, `familyFilesChecked=588`, `legacyNameViolations=0`, deterministic `fileCount=407`, `diffs=[]`, `violationCount=0`.

## Reopened acceptance defects

1. `constrained_family_manifest.json` is manually enumerated; its `auditSource` is not consumed, so an audit row can be omitted while strict validation still passes.
2. `acceptanceOwner` is only checked as a non-empty string; existence and behavioral ownership are not proven.
3. Quest conversation lifecycle still permits two repeated `"Can you help me?"` offers to return `available` instead of proving real offer→accept→active→ready→rewarded→repeat projection.
4. Parameterized-task tests prove generation/result routing, not the required conversation-state lifecycle.
5. Event response-window expiry is required and tested, but absent from the manifest.
6. Disband and settlement/ambient rows point at an owner file that does not test those behaviors; their intended policies still need explicit acceptance.
7. `Input_Actions_Dispatch.lua` duplicates recruitment reply mapping already authored canonically through `replyOutcome`/reply branches.
8. Previous final continuity docs were contradictory and omitted residual fingerprints.

## Mandatory R5 sequence

~~~text
R5A  acceptance inventory + ownership integrity
  ↓
R5B  remaining S11D state/lifecycle closure
     tasks + quests + event expiry + disband + settlement/ambient
  ↓
R5C  generic policy/reply projection de-duplication
  ↓
R5D  full reproducible acceptance + exact final documentation checkpoint
~~~

Do not return to user-owned native Project Zomboid acceptance until R5A-R5D pass.

## Hard rules

- Canonical CodeBuilder source/recipe first; generated output is downstream-only.
- No compatibility shims, fallback readers, aliases, dual registries/writes, or parallel old/new semantic authority for project-owned internal code.
- Do not re-migrate accepted Identity/Needs/Greeting/command families unless a targeted failing test proves a real defect.
- The constrained-family inventory must be closed-set against its normative audit source; manual omission must fail.
- An acceptance-owner string is not evidence; ownership must resolve to real test/fixture/case coverage.
- Generic runtime may route/evaluate canonical policy but may not own family-specific admission or reply mappings already expressed canonically.
- Semantic correctness must require zero LLM calls. Preserve ParticipantSet/roles/beat/topic/event/activity/memory foundations; do not implement the future Dialogue Director in R5.
- Accepted multi-repo commits: changed adopters first, Core last. Exact paths only. Never push/publish without explicit authorization.
