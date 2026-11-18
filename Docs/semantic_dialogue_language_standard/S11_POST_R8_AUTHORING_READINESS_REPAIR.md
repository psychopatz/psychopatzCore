# S11 Post-R8 Closure Integrity and Dialogue Authoring Readiness Repair

**Status:** HISTORICAL / IMPLEMENTED — R8D and R9A-R9D code are retained. Historical follow-up: `S11_POST_R9_WORKBENCH_USABILITY_REPAIR.md`. Current goal authority: `S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md`.
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Previous repair:** `S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md`

## Purpose

The post-R8 audit found that the runtime repair is substantially correct, but S11 is not ready for USER_ACCEPTANCE or for the planned broad dialogue/beat rewrite.

Two gaps remain:

1. **R8 closure integrity:** canonical acceptance is reproducibly 9/9 by result, but `real_provider_worker` mutates live DynamicTrading generated output during acceptance, so the exact participant vector is not preserved.
2. **Dialogue authoring readiness:** the canonical Dialogue Completeness Analyzer exists and works, but Semantic Lab does not expose the compiler-owned graph/report envisioned by the original S11 design. Authors cannot yet visually prove that every reachable branch terminates, progresses, or has a bounded pending/deferred exit.

Mandatory sequence:

~~~text
R8D  acceptance side-effect isolation + exact-vector closure
  ↓
R9   Dialogue Completeness Workbench + authoring-readiness gate
  ↓
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

Do not begin the planned broad rewrite of dialogues, beats, behaviors, or realization content before R9 is accepted.

## Current audited checkpoint

~~~text
psychopatzCore   9227ba6a97f0acbef8c6bf33067acb9582067442
ProjectHoomans   dadfa01b88f957dbdeac68ce0b688130d3b175d7
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=34  sha256=731b8c509b74bde3c57948b83252ddc0b6b4293405c3d1333ad835c2d688c462
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

The 34 ProjectHoomans residuals are unrelated concurrent NPC-authoring/editor/StartingCompanion work. Preserve them exactly and re-verify live status before every cross-repo phase.

## Retained accepted work

Do not rebuild unless targeted evidence disproves it:

- R8A shared native/worker task projection (`PNC_SemanticTaskProjection.lua`);
- `task_native_projection_parity` exact ownership;
- native WAIT_AT retirement and duplicate suppression;
- the original R8B Core canonical-source race repair;
- Core Python jobs=1/jobs=4 accounting;
- existing Tk/Xvfb ownership;
- S11 Identity / Needs / Greeting / companion-command migrations;
- quest / recruitment / proposal / event / disband / settlement / ambient regressions;
- single generic canonical policy admission;
- CodeBuilder canonical source/recipe ownership;
- existing Dialogue Completeness Analyzer backend and constrained-family manifest.

# Finding A — R8C exact-vector closure is invalid

Independent canonical acceptance produced two consecutive:

~~~text
9 / 9 suites PASS
2120 / 2149 cases
convoScopeOk=true
~~~

but a clean DynamicTrading tree became dirty with:

~~~text
Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Manifest.lua
Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Registry.lua
~~~

The generated whole-model fingerprint changes and subsequent `reconcile.py --check` reports two drifted files.

The mutation is reproducible from `real_provider_worker` and was isolated to:

~~~text
tools.providers.pnc.tests.test_pragmatic_interaction_beat_inspector.
PragmaticInteractionBeatInspectorTests.
test_promotion_writes_only_canonical_source_then_regenerates
~~~

That test isolates the Core source repository but still points generated adopter output at live ProjectHoomans/DynamicTrading repositories. A temporary model is therefore regenerated into live participant output.

The audit restored only those two audit-induced DT files after proving the mutation.

# R8D — acceptance side-effect isolation and exact-vector closure

## D1. Isolate all generated-output owners

Repair the identified pragmatic-interaction promotion test so its temporary source model also uses temporary adopter/output repositories.

Do not mock away generation. The test must still prove real promotion/regeneration behavior, but every owned source/generated root affected by its temporary model must be hermetic.

Audit the rest of `real_provider_worker` for the same mixed temporary/live repository pattern.

Rule:

> If a test changes canonical source/model state, every generated owner that can be affected by that model must point at the same isolated test workspace unless the test is explicitly allowed to mutate and transactionally restore it.

Canonical acceptance must never leave live participant repositories changed.

## D2. Acceptance-level effect-free guard

Add durable acceptance coverage that snapshots participant repository status before and after generation-bearing acceptance.

It must detect modified, created, deleted, or drifted generated artifacts across all participants.

Do not silently restore test-induced dirt and report success. A side effect is a failure.

## D3. Reconcile after acceptance

Final R8D evidence must include:

~~~text
participant fingerprints BEFORE
real_provider_worker
participant fingerprints AFTER
→ identical

canonical 9-suite --jobs 4
canonical 9-suite --jobs 4
participant fingerprints AFTER
→ identical to BEFORE

reconcile.py --check
→ clean=true

git diff --check
→ clean for R8-owned paths
~~~

Pre-existing unrelated Hoomans dirt may remain, but its raw status bytes must be unchanged.

## R8D gate

R8D is accepted only when:

- the identified test cannot write generated output into live DT/Hoomans;
- remaining `real_provider_worker` modules are audited for equivalent mixed-root defects;
- `real_provider_worker` is effect-free against all live participants;
- two canonical 9-suite runs are 9/9 from one exact vector;
- participant fingerprints before/after are identical;
- post-acceptance reconcile is clean;
- no cleanup shim or new baseline hides the defect.

# Finding B — the planned Dialogue Completeness GUI is not implemented

The canonical backend exists:

~~~text
SemanticLabAuthoringService.analyze_convo_completeness()
→ completeness_analyzer.analyze_portable_plan()
~~~

Fresh strict analysis of the current compiled model reports:

~~~text
families=520
errors=0
warnings=1
info=0
sccs=520
~~~

Current warning:

~~~text
command.camp
stale_poststate_risk
Mutating family has no postconditions or statePolicy to prevent stale re-dispatch.
~~~

The backend can detect dead ends, unreachable branches, pending-without-exit, unbounded loops, missing state/action outcomes, missing repeat policy, stale poststate risk, dangling memory/lost commitment, role/cardinality issues, group-effect hazards, and missing fixture coverage.

But currently:

- there are **zero GUI callers** of `analyze_convo_completeness()`;
- the primary Conversations pane exposes only `when`, `invoke`, `affordance`, `execute`, `say`, `reply`, `after`, and `metadata` JSON editors;
- `statePolicy`, `inputPolicy`, `repeatPolicy`, `postconditions`, `closure`, roles/cardinality, and structured topic/event/activity/memory/domain references are not first-class visible controls there;
- Flow Editor `Terminal node` is an authored local flag, not compiler proof that every reachable semantic branch closes;
- no completeness-driven safe structural scaffolding is wired into the GUI.

This is a missed original S11 requirement. `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md` explicitly requires one analyzer result shared by Semantic Lab and lists “expose the same graph/report in Semantic Lab” before broad content migration.

# R9 — Dialogue Completeness Workbench and authoring readiness

R9 is mandatory before broad dialogue/beat/behavior/realization rewriting.

The GUI must consume the **same compiler-owned graph/report** used by acceptance. Do not build a second UI-only graph analyzer.

## R9A — canonical authoring report enrichment

Keep `completeness_analyzer.py` as the single semantic graph authority.

Enrich the report where needed for authoring/navigation with bounded data such as:

- canonical source provenance/path;
- graph node/edge identity;
- dead-end/continuation witness path;
- cycle witness / SCC members;
- state/action outcome matrix;
- missing progress/ownership category;
- closure classification;
- suggested valid structural closure classes;
- affected-family dependency closure;
- fixture / typed-click ownership.

Do not duplicate semantic interpretation in Tk code.

Provide bounded family-level analysis for changed-family + affected-closure refresh. Whole-package strict analysis remains the acceptance gate.


## R9B — primary Dialogue Completeness Workbench

Add a first-class primary Semantic Lab surface or first-class tab inside Conversations named clearly, for example:

~~~text
Dialogue Completeness
~~~

It must not be hidden only under legacy/developer tools.

### Batch view

Show all maintained canonical families with at least:

- owner;
- kind;
- canonical ID;
- reachable/handled branch counts where derivable;
- closure health;
- warning/error count;
- fixture/test coverage state;
- changed/affected indicator when available.

Filters must include at least:

~~~text
errors only
warnings only
owner
kind
namespace/domain
missing closure
missing action/state outcome
pending without exit
unbounded cycle
missing repeat policy
missing fixture/acceptance coverage
typed/click parity gap when reportable
recently changed / affected
~~~

### Family graph view

For a selected family, render the compiler-derived semantic path, including relevant nodes such as:

~~~text
family entry
state-policy outcome
input-policy gate
ActionContract dispatch
authoritative result outcome
reply outcome
continuation / goto / recommend
pending / confirmation / deferred obligation
terminal closure
memory/domain obligation residue
~~~

The semantic states must be visually obvious and also text-accessible. Recommended classes:

~~~text
GREEN   valid resolved/terminal closure
BLUE    valid continuation to another family
PURPLE  valid domain obligation survives conversation
YELLOW  bounded pending/deferred with known exit/expiry
ORANGE  warning / valid but incomplete safety or coverage
RED     invalid dead end / missing outcome / unbounded loop / unowned continuation
~~~

### Diagnostic detail

Selecting a diagnostic must show:

- stable code;
- family;
- canonical source path;
- semantic path;
- witness/cycle path where applicable;
- explanation;
- repair hint;
- relevant closure/progress class.

### Source navigation

Provide direct actions such as:

~~~text
Open canonical source
Open affected branch / field
Open continuation target
Run affected analysis
Run family fixtures / tests
~~~

Navigation must resolve to canonical authoring source, never generated Lua.

## R9C — complete primary authoring controls and safe structural scaffolding

The primary Conversations surface must make S11 semantic controls visible/editable without raw-source spelunking:

- `statePolicy`;
- `inputPolicy`;
- `repeatPolicy`;
- `postconditions`;
- `closure`;
- roles/cardinality where relevant;
- continuation / `after`;
- reply outcome coverage;
- memory/domain obligation references;
- relevant topic/event/activity/memory/domain metadata.

Use compiler-owned field descriptors/schema metadata, not a second hard-coded UI schema.

Add safe **structural** scaffold operations driven by analyzer evidence, e.g.:

- missing reply outcome;
- missing terminal/continuation declaration;
- missing bounded pending exit;
- missing repeat-policy placeholder;
- missing closure-residue skeleton;
- missing fixture/acceptance stub where current testing architecture supports it.

Scaffolding must:

- operate on canonical compact source through existing ConvoTransaction/CodeBuilder services;
- be previewable/effect-free before explicit write;
- never invent final prose as semantic authority;
- never hand-edit generated Lua/registry/manifest/translation output;
- never introduce compatibility shims or parallel source formats.

This is structural assistance, not automatic creative authorship.

## R9D — GUI/runtime acceptance and content-rewrite gate

Add focused unit and Tk/Xvfb coverage proving:

1. Workbench calls the canonical completeness service rather than reimplementing graph logic.
2. Batch counts/filters derive from the canonical report.
3. Selecting a diagnostic navigates to the exact canonical family/path.
4. Dead-end, missing-outcome, pending-without-exit, unbounded-cycle, and stale-poststate fixtures render correctly.
5. Valid continuation, resolved terminal, bounded pending, and domain-obligation closure render distinctly.
6. Changed-family analysis updates affected rows without corrupting unrelated state.
7. Structural scaffold preview is effect-free.
8. Explicit scaffold apply changes only intended canonical source and generated outputs through normal CodeBuilder recipe flow.
9. GUI code never directly edits generated output.
10. The Workbench reports the same real-package summary as direct `analyze_convo_completeness(strict_manifest=True)`.

Run fake-widget/unit coverage and real Tk/Xvfb interaction coverage where practical.

## R9 content-rewrite gate

Document:

~~~text
BULK_DIALOGUE_REWRITE_ALLOWED=false
~~~

until R9D is accepted.

Broad dialogue/beat redesign may begin only when:

> A human or agent can select any maintained canonical conversation family in Semantic Lab and visually prove every reachable branch, state outcome, action result, continuation obligation, repeat path, and terminal/domain closure from the compiler-owned graph; every defect can navigate to canonical source; missing structure can be scaffolded safely without inventing gameplay semantics; and acceptance consumes the same report rather than a UI-specific analyzer.

After R9 acceptance:

~~~text
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

The future content rewrite should then use the Workbench continuously as its authoring/acceptance loop.

# Final closure order

S11 is not developer-complete until:

~~~text
R8D ACCEPTED
R9A-R9D ACCEPTED
~~~

Only then reconcile:

~~~text
S11          COMPLETE_DEVELOPER_SIDE / ACCEPTED
S11D         ACCEPTED
S11E         ACCEPTED
S11R8        ACCEPTED / CLOSED (including R8D)
S11R9        ACCEPTED / CLOSED
PROGRESS     USER_ACCEPTANCE
HANDOFF      USER_ACCEPTANCE
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

Until then, `USER_ACCEPTANCE` and broad content rewriting are premature.

# Single-authority / no-shim invariants

Do not introduce:

- a second completeness graph in GUI code;
- GUI-owned semantic closure truth;
- direct generated-Lua edits;
- compatibility readers between old/new completeness-report shapes unless a verified external contract requires them;
- acceptance cleanup that silently restores test-induced mutation and reports success;
- a second GUI harness when current Tk/Xvfb infrastructure suffices;
- bulk dialogue rewriting before the Workbench gate.

Preserve:

~~~text
canonical compact source
→ canonical IR
→ Portable Dialogue Plan
→ Dialogue Completeness Analyzer
→ one machine-readable graph/report
    ├─ acceptance
    ├─ CodeBuilder
    ├─ agent repair packets
    └─ Semantic Lab Workbench
→ backend/runtime generation
~~~
