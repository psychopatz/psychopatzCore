# S11 Post-R7 Native-Parity and Acceptance-Reproducibility Repair

**Status:** HISTORICAL / PARTIAL — R8A and original R8B repairs are retained; R8C final closure was invalidated by post-R8 live-repository mutation. Current authority: `S11_POST_R8_AUTHORING_READINESS_REPAIR.md`.
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Previous repair:** `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`

## Purpose

R7 closed the requested atomic audit-claim gaps, but a post-R7 source audit found two deeper blockers that invalidate the final USER_ACCEPTANCE handoff:

1. the new parameterized-task presentation lifecycle is proven only in the headless worker because the worker injects `Runtime.taskStates` into conversation context while native Project Zomboid conversation construction does not expose any equivalent `taskStates` projection;
2. the canonical acceptance workflow is not reproducibly green: parallel Core Python acceptance races a test that writes temporary canonical-source files into the real Core source tree, and serial Core Python acceptance exposes two unclassified Tk-display skips.

R8 is a narrow parity/reproducibility repair. Do not reopen accepted R1-R7 settlement/ambient, quest, disband, recruitment/proposal, event, identity, needs, greeting, policy-admission, CodeBuilder, or claim-ownership work unless a targeted R8 regression disproves it.

## Post-R7 audit evidence

Retain these exact findings until new evidence disproves them.

### Native task parity defect

Production suggestion code reads:

~~~text
Contents/.../Suggestions_Capabilities_Rows.lua
  context.taskStates
~~~

but the only producers found are under:

~~~text
tools/providers/pnc/lua/worker/
  Conversation_Context_Builder.lua
  SemanticAdapters_Knowledge_Commands.lua
  ScenarioSession_Lifecycle.lua
~~~

The native conversation path builds context through:

~~~text
PNC_ConversationComposer_Context.lua
PNC_ConversationDefinition_Builder.lua
Input_ContextProjection.lua
~~~

and currently projects `actorAuthority`, `npcState`, settlement/ambient data, etc., but no authoritative task-state projection.

Native task dispatch/result handling instead owns real state through existing production seams such as:

~~~text
Input_TaskDispatch.lua
  session.semanticTaskRequests

Input_Tasks.lua
  ReceiveSemanticTaskResult(...)

server semantic/task authority
~~~

Therefore the R7 worker test proves a worker-only context contract. Native runtime cannot consume the new active/completed/failed/rejected retirement logic as written.

### Acceptance reproducibility defect

Fresh post-R7 audit against Core `1bc5e92` / Hoomans `9fdfc7b6` / DT `0fcf3519`:

~~~text
canonical 9-suite acceptance --jobs 4
→ 8/9 suites
→ core_python fails
→ convoScopeOk=false
~~~

Parallel failure:

~~~text
test_psdl_semantic_domain_decomposition
  writes:
  tools/semantic_harness/codebuilder/sources/conversation/
    behavior/social/conflict/g9r_fixture_taunt.json

concurrently

test_semantic_generation_ownership_and_cleanup
  runs canonical reconcile/check against the real workspace

→ unregistered Conversation shard / generated fingerprint drift
~~~

Serial Core acceptance avoids that race but currently reports:

~~~text
308 PASS
0 failed
2 skipped
ok=false

skips:
test_gui_startup
  "requires a Tk display"
~~~

The same generation-ownership module passes alone, and plain unittest discovery passes 310 with 2 skips. This is an acceptance-harness isolation/accounting problem, not a reason to bless a new baseline.

## R8 sequence

~~~text
R8A  native task-state projection parity
  ↓
R8B  canonical acceptance isolation + deterministic accounting
  ↓
R8C  exact-vector full closure and documentation reconciliation
~~~

There is no new semantic architecture migration phase.

# R8A — native task-state projection parity

## A. One authoritative bounded task projection

Create or reuse one bounded production task-state projection that both native conversation runtime and the headless worker consume.

The projection must derive from existing authoritative task/conversation state. Reuse production seams such as:

- active `session.semanticTaskRequests`;
- authoritative semantic task admission/result state;
- existing Tasking/plan query services where terminal state must persist;
- existing client/server task result receipts.

Do not create a second task authority.

The worker may emulate or adapt the same projection contract, but `Runtime.taskStates` must not remain a worker-only semantic truth that production code cannot supply.

## B. Generic projection before presentation

The shared suggestion layer may project task state, but should not become a second family-specific task engine.

Prefer a bounded generic shape such as:

~~~text
taskProjection[action-or-binding] = {
  status = ...
  requestID = ...?
  authoritative = true
}
~~~

or an equivalent existing project structure.

The exact shape is implementation-owned, but it must:

- be derivable in native runtime;
- be reproducible in the worker;
- be keyed stably by action/binding rather than UI frame identity;
- remain read-only presentation input;
- never duplicate server/task authority;
- support the maintained parameterized-task lifecycle, not merely a hard-coded worker flag.

If `Suggestions_Capabilities_Rows.lua` retains `WAIT_AT`-specific presentation policy, that code must consume the shared production projection rather than worker-only state. Prefer moving reusable state-retirement logic behind the capability/task policy contract if existing structure supports it without a new subsystem.

## C. Native-equivalent acceptance

Add a regression that exercises the native conversation context/projection seam, not merely `Conversation_Context_Builder.lua` worker injection.

The acceptance chain must prove:

~~~text
native/native-equivalent conversation context
→ pnc:task.wait_at visible/actionable before request
→ authoritative task dispatch/admission
→ production task projection updates
→ rebuilt/refreshed native suggestion context consumes that projection
→ pnc:task.wait_at retires while active
→ duplicate typed/click attempt causes zero duplicate dispatch
→ completed/failed/rejected state projects according to retained policy
~~~

The exact test owner should declare an additional stable atomic claim such as:

`task_native_projection_parity`

and `audit.task.parameterized` should require it alongside:

~~~text
task_generation_and_result_routing
task_conversation_projection_lifecycle
~~~

Do not let the existing worker-only lifecycle test own native parity by implication.

## D. Worker parity

Update the worker so it obtains task projection through the same bounded contract or adapter semantics as production.

Add a regression that fails if the worker has a private field/state path with no native producer.

## R8A gate

R8A is accepted only when:

- native production conversation context has a real task-state projection producer;
- worker and native/native-equivalent tests consume the same semantic contract;
- `task_native_projection_parity` is explicitly owned by an exact test;
- active/terminal suggestion retirement no longer depends on worker-only `Runtime.taskStates` truth;
- no shadow task store or compatibility shim is introduced;
- focused task + native projection tests pass;
- unrelated ProjectHoomans dirty files remain byte-for-byte untouched unless they independently change outside R8.

Commit exact R8A-owned ProjectHoomans paths first. Do not stage the unrelated StartingCompanion/NPC-authoring residuals. Then commit Core acceptance metadata/docs last and continue automatically to R8B.

# R8B — canonical acceptance isolation and reproducibility

## A. Remove real-workspace mutation from parallel Core tests

`test_psdl_semantic_domain_decomposition.test_real_source_variant_and_new_subdomain_are_local` must not transiently write fixture files into the live canonical source tree during the parallel acceptance suite.

Move its mutation into an isolated temporary repository/workspace fixture, or provide an equivalent hermetic test seam.

The test must still prove:

- adding a variant changes only the expected generated domain modules;
- adding a new subdomain generates the expected new modules;
- stable sibling modules remain byte-identical;
- source order remains deterministic.

But it must never make a concurrent canonical reconcile/check observe test-only source files.

Add a regression/guard if practical so acceptance modules that mutate canonical source use isolated roots.

## B. Resolve Core Tk skip ownership deliberately

`test_gui_startup` currently contributes two unclassified `requires a Tk display` skips to Core Python when run serially.

Do not hide these by changing counts opportunistically.

Choose one durable ownership model:

1. GUI-startup tests are excluded from non-GUI `core_python` discovery and owned by the dedicated `tk_xvfb_gui` suite; or
2. Core Python runs them under an explicit display fixture; or
3. the skips are intentionally classified by the canonical acceptance policy with documented ownership.

Prefer the model that avoids duplicate coverage and makes suite meaning obvious. The dedicated Tk/Xvfb suite already exists, so do not create a second GUI harness.

## C. Deterministic acceptance accounting

Add acceptance-runner regressions proving Core Python accounting is stable between supported execution modes.

At minimum verify:

~~~text
core_python jobs=1
core_python jobs=4
~~~

have no race-induced failures and deterministic test ownership/accounting.

The canonical R8 gate remains the documented parallel workflow. Do not downgrade to serial-only acceptance to hide concurrency defects.

## D. Reproducibility proof

Before R8B acceptance, run:

~~~text
core_python jobs=1
core_python jobs=4
canonical 9-suite acceptance --jobs 4
canonical 9-suite acceptance --jobs 4   # second consecutive run
~~~

Both canonical runs must pass from the same exact repo vector with no workspace mutation left behind.

Do not add a new unrelated baseline for the generation race or GUI skips.

## R8B gate

R8B is accepted only when:

- no Core acceptance test writes transient canonical source into the real workspace under parallel execution;
- Core Tk tests have one explicit deterministic suite ownership policy;
- Core Python jobs=1 and jobs=4 are both green under that policy;
- two consecutive canonical 9-suite runs are 9/9 green from one exact checkpoint;
- repo status bytes before/after acceptance are unchanged except for explicitly owned R8 edits;
- no generated drift is left behind.

Commit Core harness/test changes only after this gate passes, then continue automatically to R8C.

# R8C — exact-vector final closure

## Full retained acceptance

From the exact final participant vector run:

- focused R8 native task projection tests;
- explicit `auditClaims` guards;
- retained settlement/ambient, quest, event, disband, recruitment/proposal regressions;
- full Core semantic harness;
- provider Python;
- real LuaSemanticWorker;
- Tk/Xvfb GUI;
- Core/ProjectHoomans/DynamicTrading Lua/static suites;
- canonical 9-suite acceptance twice consecutively with `--jobs 4`;
- CodeBuilder `reconcile.py --check`;
- ConvoEngine integrity/determinism;
- Kahlua/static verification;
- Flow_Identity / Flow_Needs / Flow_Greeting caller-zero;
- `git diff --check`.

The final result must be based on the exact participant HEADs/residual work recorded in HANDOFF.

## Final documentation reconciliation

Only after the R8C gate is green, rewrite current-state docs to:

~~~text
S11          COMPLETE_DEVELOPER_SIDE / ACCEPTED
S11D         ACCEPTED
S11E         ACCEPTED
R7           HISTORICAL / SUPERSEDED CLOSURE CLAIM
R8           ACCEPTED / CLOSED
PROGRESS     USER_ACCEPTANCE
HANDOFF      USER_ACCEPTANCE
~~~

R7A's atomic settlement/ambient and task claim work remains accepted; only its final developer-complete closure claim was invalidated by the R8 audit.

Remove stale current directives such as `execute R7` from historical repair docs.

## Final participant checkpoint

Record after the final commits:

~~~text
exact psychopatzCore commit
exact ProjectHoomans commit
exact DynamicTrading commit
exact residual path count per repo
SHA-256 of exact git status --porcelain=v1 -uall bytes
full R8 acceptance evidence
~~~

A dirty participant is allowed when the dirt is proven unrelated. Preserve it and fingerprint it; do not reset/stash/discard it to manufacture a clean checkpoint.

## No-shim / no-shadow invariant

Do not introduce:

- task-state compatibility aliases;
- worker-only task authority;
- native-only duplicate task authority;
- fallback readers between parallel task-state shapes;
- dual task stores/writes;
- generated-output hand edits;
- new GUI acceptance harnesses;
- new baselines for the R8 harness defects.

## Completion invariant

S11 returns to USER_ACCEPTANCE only when:

> the same bounded authoritative task projection drives native and worker conversation suggestions; `pnc:task.wait_at` retirement is proven through the native/native-equivalent production context rather than worker-only `Runtime.taskStates`; Core acceptance is hermetic under parallel execution; GUI test ownership/accounting is deterministic; two consecutive canonical 9-suite runs pass from the same exact repo vector; and all current continuity docs record that exact final checkpoint.
