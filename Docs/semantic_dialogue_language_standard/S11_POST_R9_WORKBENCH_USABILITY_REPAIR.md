# S11 Post-R9 Workbench Usability, Full-Family Coverage and Legacy Retirement Repair

**Status:** NORMATIVE ACTIVE REPAIR PLAN
**Audit date:** 2026-11-18
**Parent goal:** S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
**Previous repair:** S11_POST_R8_AUTHORING_READINESS_REPAIR.md
**Repair phase:** S11R9R1
**Content rewrite gate:** BULK_DIALOGUE_REWRITE_ALLOWED=false

## Why R9 is reopened

R8D is accepted and retained. The compiler-owned completeness report, S11 semantic controls, structural scaffolding, canonical-report parity, and acceptance side-effect guard are real.

The post-R9 usability audit found that the authoring-readiness gate was closed too early. The Workbench is technically connected to the canonical analyzer, but it is not yet safe or efficient enough to drive the planned broad rewrite of dialogues, beats, behaviors, and realizations.

Mandatory order:

~~~text
R9R1A  correctness + full-family coverage
  ↓
R9R1B  problem-first visual UX
  ↓
R9R1C  authoring workflow completion
  ↓
R9R1D  legacy surface retirement
  ↓
R9R1E  real usability acceptance
  ↓
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

Do not reopen R8D, S11A foundation, or accepted state/outcome runtime migrations unless targeted regression evidence requires it.

## Current audited checkpoint

~~~text
psychopatzCore   097ae97a425b6cecd88a7bdac5c36077e57510e0
ProjectHoomans   77994e19dccc5a4d94579b480fd24f3db8e68979
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot, raw git status porcelain SHA-256:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=34  sha256=731b8c509b74bde3c57948b83252ddc0b6b4293405c3d1333ad835c2d688c462
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

The 34 ProjectHoomans residuals are unrelated concurrent NPC-authoring/editor/StartingCompanion work. Preserve them exactly. Re-verify live HEAD/status before every cross-repository phase.

## Retained accepted work

Retain unless a focused regression disproves it:

- R8D hermetic promotion test and participant worktree side-effect guard;
- two consecutive canonical 9-suite acceptance runs from one exact vector;
- post-acceptance reconcile discipline;
- canonical Dialogue Completeness Analyzer as the single semantic graph authority;
- enriched graph/report fields from R9A;
- S11 Semantic Controls driven by compiler-owned FieldDescriptors;
- safe structural scaffold preview/apply through ConvoTransaction and CodeBuilder;
- canonical-source navigation foundation;
- existing unit and Tk/Xvfb infrastructure.

# Audit findings

## A. Completeness currently covers dialogues only

The maintained canonical source catalog contains:

~~~text
588 total
520 dialogue
30 behavior
3 beat
35 realization
~~~

The strict completeness report currently analyzes only 520 dialogue families. The 30 behavior, 3 beat, and 35 realization families are absent from Workbench health coverage.

The planned rewrite explicitly includes these kinds, so authoring readiness is incomplete.

## B. Editor and Workbench family selection can disagree

The audited UI showed:

~~~text
main editor: action.trade
Workbench:   accept
~~~

The editor selection path does not synchronize the Workbench selection. This is an authoring correctness hazard.

## C. Semantic colors are text labels, not visual prioritization

The report produces GREEN, BLUE, PURPLE, YELLOW, ORANGE, and RED semantic states, but the current Workbench renders a plain Listbox with text prefixes such as [GREEN].

There is no real row coloring, severity tagging, or problem-first default. With 518 resolved dialogue families and only one warning, the warning is buried among healthy entries.

## D. Human-facing authoring workflow is incomplete

Current gaps:

- Open affected field does not focus or highlight the exact offending control.
- Run family tests exists in the Workbench class but is not wired by ConvoEngineAuthoringPane.
- scaffold controls remain visible for healthy families with no diagnostic;
- graph detail is primarily a raw compiler text dump rather than a human-first branch/closure summary;
- fixture/test health is not a first-class batch column;
- namespace/domain is not a dedicated filter;
- default issue filter is all rather than needs-attention.

## E. Legacy detection is incorrect

SurfaceRegistry.has_active_legacy_datasets currently treats any existing listed source as legacy.

Current active source inventory includes ConvoEngine, NLU patterns and WordNet, causing legacyDatasetsPresent=True even though list_dialogue_content returns 0 records.

The visible Show Legacy Compatibility Tools control is therefore preserved by the wrong condition.

# R9R1A — correctness and full-family authoring health

## Shared family identity

Create one explicit current-family selection contract for Conversations and Dialogue Completeness.

Required:

- main family selection synchronizes Workbench;
- Workbench selection synchronizes main editor;
- continuation navigation updates both;
- filtering cannot silently switch the other view to an unrelated family;
- synchronization is deterministic and recursion-safe;
- regression reproduces the action.trade versus accept mismatch and proves it impossible.

## Full maintained-family health model

Extend the same compiler-owned authoring-health report to all 588 maintained families.

Dialogue keeps the existing reachability, state/action outcome, continuation, repeat, pending/deferred, closure and fixture/parity checks.

Behavior health must cover applicable canonical bindings/references, roles/cardinality, trigger/input ownership, action/result/continuation references, unresolved targets, bounded transition semantics where represented, and fixture ownership.

Beat health must cover applicable role/cardinality binding, entry conditions, transition/continuation references, bounded progression, referenced behavior/dialogue families, and fixture ownership.

Realization health must cover applicable referenced family, required slots, locale/template availability, unresolved template/response references, variant/reference coverage, and orphan records.

Do not invent dialogue terminal semantics for non-dialogue kinds. Use one common health envelope plus kind-specific detail.

The Workbench summary must explicitly show:

~~~text
588 maintained
520 dialogues
30 behaviors
3 beats
35 realizations
~~~

with analyzed/healthy/warning/error counts per kind.

# R9R1B — problem-first visual UX

Replace the concatenated Listbox with a sortable Treeview or equivalent structured table.

Recommended columns:

~~~text
Health
Family
Owner
Type
Branches / Coverage
Issues
Closure / Health
Tests
~~~

Use actual Tk row tags/styles for:

~~~text
RED      broken / must fix
ORANGE   warning / should fix
YELLOW   valid bounded pending/deferred
BLUE     valid continuation
PURPLE   valid domain obligation
GREEN    healthy / resolved
~~~

Color is supplemental: also show textual/icon state.

Default filter must be Needs attention, not All. Default sorting must place RED then ORANGE before healthy rows, with stable family ID inside each severity.

Healthy families remain available through All.

Add quick summary counters for Needs fixing, Warnings, Pending review, Continuations and Healthy where practical.

The primary selected-family view must answer in human language whether every applicable path ends, progresses, or remains valid. Show a simple branch/health summary first. Put SCCs, node IDs, edge IDs, witness payloads and raw matrices under Technical details.

Add dedicated filters for severity, owner, kind, namespace/domain, missing coverage, and changed/affected. Keep diagnostic-code filters under an advanced filter if needed.

# R9R1C — complete the authoring workflow

Open affected field must navigate to and focus/highlight the exact canonical control derived from the diagnostic path, such as:

~~~text
reply.failed
statePolicy
postconditions
repeatPolicy
closure
after
roles
participantSet
~~~

Selecting only the correct tab is insufficient.

Wire a real Run family tests action from the primary authoring pane/service. It must delegate to the narrowest maintained fixture/test owner available and show the result. If no exact runnable owner exists, state that clearly.

Repairs must be contextual. For healthy families, disable or hide structural repair controls and show No structural repair needed.

For an applicable diagnostic, show:

~~~text
Problem
Why it matters
Suggested structural fix
Preview
Apply
~~~

Keep arbitrary scaffold-kind selection only under an advanced section.

After canonical save or scaffold apply, automatically rerun affected-family analysis, retain current selection and filters, update the row immediately, and surface whether the defect is resolved.

# R9R1D — legacy and redundant surface retirement

Do not bulk-delete by name. Audit callers, current data ownership and parity first.

Classify each candidate as:

~~~text
KEEP_CURRENT
MOVE_OR_RENAME_CURRENT
RETIRE_AFTER_PARITY
DELETE_CALLER_ZERO
~~~

## Legacy toggle and Dialogue Content

Fix legacy detection so canonical/pattern/WordNet sources do not count as legacy.

If no supported legacy content datasets or verified external contract remain:

- remove Show Legacy Compatibility Tools;
- delete Dialogue Content (Legacy) after caller-zero;
- delete toggle/state-persistence/test code owned only by that UI.

No compatibility shim.

## Explore legacy container

Audit Explore (Legacy). Move useful current production functionality such as live Interaction Explorer to a current surface first. Then delete the legacy container after parity and caller-zero.

## Dataset Library

DatasetLibraryPane edits canonical JSON and is not inherently legacy. Move/rename it as Canonical Data Sources under Source / Impact or Developer Tools, then remove its legacy descriptor.

## Workflow Composer

It is described as a legacy multi-dataset batch generation trigger. Audit callers and replacements. If ConvoEngine, CodeBuilder and Interaction Modules cover its supported workflow, retire/delete it with caller-zero proof. No wrapper.

## Interaction Composer

Audit InteractionSpecPane against Interaction Modules plus Conversations. If fully superseded, retire it after parity and caller-zero. If a unique current capability remains, keep only that capability and rename it descriptively.

## Explicit keep candidates

Do not delete merely as cleanup:

- Interaction Modules;
- Flow Editor unless a separate caller/parity audit proves it obsolete;
- Block Contracts;
- Source / Impact;
- Review;
- Simulation;
- Quality Sweep;
- World & Mods;
- Log.

# R9R1E — usability acceptance

Machine tests must prove:

1. all 588 maintained families enter authoring-health inventory;
2. kind counts are 520 dialogue, 30 behavior, 3 beat, 35 realization at this checkpoint;
3. editor and Workbench selection synchronize both directions;
4. severity sorting is deterministic;
5. default filter is needs-attention;
6. real semantic row tags/classes are assigned;
7. exact-field navigation resolves diagnostic paths;
8. family-test action is wired;
9. healthy families have no active repair controls;
10. diagnostic repairs are contextual;
11. post-save/apply affected analysis preserves selection and filters;
12. legacy detection does not classify canonical/pattern/WordNet sources as legacy;
13. retired surfaces have caller-zero tests;
14. moved current surfaces retain required capabilities.

Add a real Tk/Xvfb journey that opens Studio and proves:

~~~text
Dialogue Completeness opens
→ Needs attention is default
→ command.camp warning is immediately visible
→ warning row is visually ORANGE plus textual warning state
→ selecting command.camp synchronizes the main editor
→ selecting its diagnostic highlights the exact relevant semantic field
→ contextual suggested repair appears
→ a healthy family is GREEN and has no active repair controls
~~~

Also prove RED, YELLOW, BLUE and PURPLE with isolated/synthetic Tk fixtures.

After focused R9R1 tests, run full Core Python, Tk/Xvfb, provider/real-worker coverage as required, canonical 9-suite acceptance twice, participant status fingerprint comparison, post-acceptance reconcile, and git diff --check.

The current real command.camp stale_poststate_risk warning may be fixed if the canonical repair is clear and narrowly owned. Otherwise it must remain visibly surfaced; do not baseline it away.

# Content rewrite gate

BULK_DIALOGUE_REWRITE_ALLOWED=false throughout R9R1.

Only set true after R9R1E when a human or agent can immediately see which maintained families need attention, understand why without reading raw compiler dumps, navigate to the exact canonical field, apply only context-appropriate structural repairs, run affected tests/analysis, and cover dialogue, behavior, beat and realization families from the same compiler-owned authoring-health model.

# Final continuity state

Only after R9R1E:

~~~text
S11R8       ACCEPTED / CLOSED
S11R9       ACCEPTED WITH R9R1 REPAIR
S11R9R1     ACCEPTED / CLOSED
S11         COMPLETE_DEVELOPER_SIDE / ACCEPTED
PROGRESS    USER_ACCEPTANCE
HANDOFF     USER_ACCEPTANCE
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

Until then:

~~~text
S11         IN_PROGRESS
S11R9       REOPENED FOR AUTHORING READINESS
S11R9R1     ACTIVE
BULK_DIALOGUE_REWRITE_ALLOWED=false
~~~

# Non-negotiable architecture rules

Do not introduce:

- a second UI-only completeness/health analyzer;
- duplicated semantic truth in Tk;
- compatibility shims for retired project-owned UI;
- hidden legacy panes retained after caller-zero;
- direct generated Lua edits;
- arbitrary scaffold actions on healthy families;
- broad content rewrite during R9R1;
- another GUI harness when existing Tk/Xvfb suffices.

Preserve:

~~~text
canonical compact source
→ canonical IR
→ Portable Dialogue Plan / canonical kind models
→ one compiler-owned authoring-health report
→ acceptance + Workbench
→ CodeBuilder generation
~~~
