# S11 Post-R9 Workbench Usability, Full-Family Coverage and Legacy Retirement Repair

**Status:** HISTORICAL / IMPLEMENTED — remaining CAMP single-authority and schema-standardization work is absorbed into S12A.
**Audit date:** 2026-11-18
**Parent goal:** S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
**Previous repair:** S11_POST_R8_AUTHORING_READINESS_REPAIR.md
**Repair phase:** S11R9R1
**Content rewrite gate:** BULK_DIALOGUE_REWRITE_ALLOWED=false

## Current truth

R8D and the useful R9/R9R1 implementation are retained. The semantic runtime, compiler-owned completeness report, 588-family inventory, real Tk health colors in the Dialogue Completeness Workbench, synchronized dialogue selection, contextual repair UI, and legacy-surface retirement are real.

The post-R9R1 audit nevertheless proved that authoring readiness was closed too early for the planned broad rewrite of dialogues, behaviors, beats, and realizations.

Current clean participant checkpoint before this planning-doc commit:

~~~text
psychopatzCore   fba98ab4791bde95a12fb1fcb7fbeede88408d7a
ProjectHoomans   a64c3bcb325f209c599a77689387135e918c2de1
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot at planning start:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

Do not reopen R8D, S11A, the accepted state/outcome runtime migrations, or the completed legacy deletions unless targeted regression evidence requires it.

## Retained accepted work

- all 588 maintained families enter one compiler-owned health report: 520 dialogue, 30 behavior, 3 beat, 35 realization;
- behavior/beat/realization have real kind-specific structural validators rather than dummy rows;
- Dialogue Completeness is a real ttk.Treeview with RED / ORANGE / YELLOW / BLUE / PURPLE / GREEN Tk row tags and human-readable health summaries;
- Needs attention is the Workbench default and command.camp is visibly surfaced as the current warning;
- Workbench to dialogue editor selection synchronization works and exact dialogue/S11 field focusing works;
- contextual repair controls disable on healthy families;
- Show Legacy Compatibility Tools is removed;
- dialogue_content_pane.py, workflow.py, and interaction_spec_pane.py are deleted after caller-zero;
- Interaction Explorer and Canonical Data Sources remain as current capabilities;
- focused unit/Tk tests and canonical 9-suite acceptance are green apart from the four reviewed unrelated Hoomans Lua baselines.

## Reopened findings

### F1 — the primary ConvoEngine family browser is still dense, repetitive and uncolored

The left ConvoEngine families browser still renders rows like:

~~~text
[ProjectHoomans] dialogue · social.greetings.firstmeet.sunset
[ProjectHoomans] dialogue · social.greetings.firstmeet.twilight
[ProjectHoomans] dialogue · social.territory.set
~~~

This wastes the narrow column on repeated owner/kind prefixes and does not project the canonical health colors where the user actually browses families.

The Workbench being color-coded is not sufficient. The primary family browser itself must visibly project health from the same compiler report.

### F2 — behavior/beat/realization families are technically present but not discoverable enough

The catalog contains all four kinds, but a flat family browser makes the 30 behaviors, 3 beats, and 35 realizations easy to miss among 520 dialogues.

The primary browser needs explicit kind discovery without duplicating semantic truth.

Required quick navigation at this checkpoint:

~~~text
All 588
Dialogues 520
Behaviors 30
Beats 3
Realizations 35
~~~

Counts must come from the current catalog/report, not hardcoded constants.

### F3 — family test coverage truth is currently broken

Fresh audit evidence:

~~~text
dialogue     fixtureCoverage=unknown   520
behavior     fixtureCoverage=unknown    30
beat         fixtureCoverage=unknown     3
realization  fixtureCoverage=unknown    35
~~~

Yet the current report shows missingCoverage=0 and the Missing Coverage filter returns no rows.

This is misleading for mass rewrite safety.

The constrained manifest uses canonicalFamilyId, while run_family_tests() and one manifest-family aggregation path still look for obsolete/nonexistent familyId / canonicalFamilies fields.

Known manifest-owned families such as offer.question.identity, flow.needs.exchange, flow.greeting.exchange, and command.companion.camp currently return ran=False and No exact family-level runnable test is registered even though exact acceptance ownership is recorded.

### F4 — Run family tests is wired visually but not functionally complete

After fixing family lookup, execution must be truthful:

- Python ownership runs the narrowest registered test method(s), not an unrelated whole module by default;
- declarative fixture ownership executes the registered fixture case(s) through the canonical fixture runner, not merely verifies that IDs exist;
- Lua ownership executes the registered Lua test through the maintained Lua runner;
- a genuinely unowned family may report no exact family-level runnable test, but this must be distinguishable from lookup failure;
- UI and machine report must show what actually ran and the result.

Tests must positively exercise known-owned families. Do not retain a regression test whose expected success condition is the current false no-test-registered result.

### F5 — non-dialogue diagnostics cannot navigate to their real authoring controls

The Workbench can diagnose behavior.stimuli, behavior.outputs, beat.entry, beat.candidates, realization.translations, and realization.dialogueAct, but Open affected field currently resolves these to no editor target.

Dialogue/S11 navigation is accepted. Extend routing by kind; do not duplicate editors.

### F6 — the primary Conversations form is unsafe as a generic editor for non-dialogue kinds

Fresh real-Tk round-trip evidence shows that loading a behavior, beat, or realization into ConvoEngineAuthoringPane._form_document() injects dialogue-shaped fields such as participants, changes schema representation, and normal Validate & trace rejects real production non-dialogue records.

Therefore:

- do not treat the dialogue form as a universal four-kind editor;
- opening a non-dialogue family must not mutate it merely by loading/saving;
- route each kind to its authoritative current authoring surface;
- reuse existing Interaction Modules beat/behavior authoring instead of creating another behavior/beat editor;
- audit the current realization editing path and promote/reuse the smallest current canonical surface that can safely edit realizations;
- if a kind is read-only in a surface, state that clearly and provide the correct navigation action.

### F7 — non-dialogue GREEN currently means basic structural health, not full rewrite readiness

Retain the useful existing checks, but close the remaining promised checks where applicable.

Behavior health must additionally verify canonical output/template references and required capabilities where represented.

Realization health must additionally verify required slot/template compatibility, relevant variant/reference coverage, and orphan/reference ownership where the model exposes enough information.

Do not manufacture warnings for concepts that are not represented by the canonical model.

## Corrective execution order

~~~text
R9R1F  compact, health-colored, kind-discoverable primary family browser
  ↓
R9R1G  truthful coverage + exact family-test ownership/execution
  ↓
R9R1H  kind-aware authoring navigation + non-dialogue rewrite safety
  ↓
R9R1I  real usability acceptance + reproducible closure
  ↓
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

R9R1A/B/D implementation is retained. R9R1C/E are reopened only where the audit disproved their completion.

# R9R1F — primary authoring simplification

## Governing principle

The primary Conversations surface must follow one rule:

~~~text
Normal mode     explains and edits the conversation
Advanced mode   exposes canonical schema/details
Debug mode      exposes compiler/integrity internals
~~~

Do not mix all three modes into one always-visible screen.

The current pane violates this by simultaneously showing identity metadata, participant JSON, shortcut controls for affordance/say/execute/reply/after, raw Exchange JSON for the same fields, S11 internals, a second local simulation surface, and package-level integrity tooling.

R9R1F therefore has five mandatory subphases.

## R9R1F1 — compact, health-colored, kind-discoverable family browser

Make the left ConvoEngine families browser the first place to skim health and find any maintained family.

Default visible family text is the canonical family ID only. Do not repeat owner/kind prefixes such as [ProjectHoomans] dialogue · on every row. Owner and kind remain available through filters, selected-family context, tooltip, or a compact optional Type/Owner column.

Project the same compiler-owned health class already used by Dialogue Completeness onto this primary browser:

~~~text
RED      broken / must fix
ORANGE   warning / risky
YELLOW   bounded pending / review
BLUE     continuation
PURPLE   domain obligation
GREEN    healthy
~~~

Color is supplemental; preserve a textual/icon status without bloating every family label.

Add compact live quick filters/counters for All, Dialogues, Behaviors, Beats, and Realizations. Current checkpoint counts are 588 / 520 / 30 / 3 / 35 and must be derived dynamically, not hardcoded.

The family browser, Workbench, continuation navigation and kind-aware authoring router share one loop-safe current-family identity. Filtering may hide the current family visually but must not silently switch the logical selection.

## R9R1F2 — one normal editing path per canonical concept

Remove duplicated authoring paths between the always-visible upper compact controls and Exchange family structure.

The current upper block directly edits shortcuts for canonical concepts that are also edited in the Exchange tab:

~~~text
UI-only affordance label   ↔ affordance
Direct single say          ↔ say
Execute contract           ↔ execute
Recommend family           ↔ after.recommend
Reply outcome / Reply say  ↔ reply
~~~

There must be one normal authoring path for each concept. Friendly structured authoring is the normal path; raw canonical JSON remains available under Advanced schema/details for expert/agent use.

Preferred normal dialogue editor:

~~~text
Player option / affordance
Spoken line
Action + typed parameters
NPC outcome replies
After this: end / continue / recommend
~~~

Keep canonical source ownership unchanged; this is presentation consolidation, not a second schema.

## R9R1F3 — progressive disclosure of identity, participants and semantic internals

Shrink the current Family identity, participants & compact controls block into a concise selected-family header.

Normal header should communicate only useful context, for example:

~~~text
social.territory.set
Dialogue · ProjectHoomans · GREEN Healthy
social.territory
~~~

Move rarely changed identity controls behind Family settings / overflow: owner, namespace, family ID, kind, source path and raw metadata. Changing owner should behave as an explicit move operation where appropriate. Changing kind must not look like an ordinary harmless text edit on an existing record.

Default participants must not consume two JSON text fields. When speaker/addressee are the normal participant defaults, render a compact human form such as Participants: Default or friendly selectors.

Hide empty/default data instead of spending permanent rows on it: empty slots, no extra/preserved fields, absent memories/domains/topics/events/activities, empty diagnostics and irrelevant S11 controls.

Rename S11 Semantic Controls to a user-facing State & Flow surface. Show common controls first, such as availability, repeat behavior, post-state/after-success and closure. Put roles, participantSet, topics, events, activities, memories, domains, raw statePolicy/postconditions and similar low-level fields under Advanced semantic fields unless populated, diagnosed or explicitly expanded.

Diagnostics must automatically reveal/focus the relevant hidden advanced field when needed.

## R9R1F4 — consolidate duplicate surfaces and demote maintenance controls

Remove the embedded Simulation / trace tab from Conversations as a competing simulation home. Replace it with a compact Preview in Simulation action that opens the existing top-level Simulation workspace with the selected family/context preloaded.

Move Run ConvoEngine Integrity Audit out of the normal authoring toolbar into Review or Developer Tools / ConvoEngine maintenance.

Make family refresh automatic after canonical writes and affected analysis. Keep an unobtrusive refresh action only for explicit recovery/manual reload.

Keep + New visible. Move Duplicate, Delete, Move family, Open source and similar infrequent/destructive actions into an overflow/context menu unless evidence shows a frequently used action needs primary placement.

Do not remove useful capability; consolidate it into one authoritative surface.

## R9R1F5 — single-line rendering cleanup and participant UX

Fix the visible control-glyph bug. The current code uses _pretty() to generate multi-line JSON such as:

~~~text
[
  "participant"
]
~~~

then places that multi-line string into a single-line ttk.Entry. The embedded newline/control characters render as odd glyphs around participant.

Single-line controls must never receive pretty-printed multi-line JSON.

Requirements:

- use compact serialization for any JSON that legitimately remains in a single-line field;
- preferably replace speaker/addressee JSON with friendly participant selectors/chips;
- audit Slots JSON and every other ttk.Entry fed by _pretty() or another multi-line formatter;
- add a regression proving no single-line authoring Entry receives embedded newline/control characters;
- preserve Unicode correctly; do not solve this by stripping legitimate non-ASCII content.

## R9R1F acceptance gate

R9R1F is accepted only when real Tk/Xvfb proves:

1. primary family rows are compact and health-colored;
2. kind filters expose All/Dialogues/Behaviors/Beats/Realizations with live counts;
3. no repeated owner/kind prefix dominates family labels;
4. default participant controls render without control glyphs;
5. normal dialogue authoring has one visible editing path per canonical concept;
6. duplicate raw JSON remains available only under Advanced details;
7. default/empty metadata and diagnostics are collapsed/hidden;
8. State & Flow uses progressive disclosure and diagnostics can reveal hidden fields;
9. Conversations no longer contains a competing local Simulation surface;
10. package Integrity Audit is no longer a primary authoring-toolbar control;
11. destructive/infrequent family operations are demoted without losing capability;
12. existing selection synchronization, health analysis and canonical write behavior remain intact.

# R9R1G — truthful coverage and family verification

## Coverage states

Replace ambiguous unknown handling with explicit truthful states. At minimum distinguish:

~~~text
exact_owner        exact family acceptance owner is registered
suite_covered      covered by a maintained broader suite but no exact owner
uncovered          known to have no maintained coverage
unknown            ownership could not be determined
~~~

Do not count unknown as missingCoverage=0 or silently classify it as healthy coverage.

Health and coverage are separate dimensions: a structurally GREEN family may still have unknown or missing test coverage.

The Workbench Tests column, primary family browser context, summary counters and Missing Coverage filter must agree.

## Manifest ownership

Use the actual constrained-manifest schema canonicalFamilyId consistently. Remove stale internal lookup keys rather than adding compatibility shims for project-owned code.

Machine tests must fail if the service and analyzer disagree on manifest family identity.

## Run family tests

Implement exact execution for supported owner kinds and return a structured result containing familyId, coverageState, ownerKind, source, requestedTestIds, executedTestIds, ran, passed/failed, and output summary.

No false-positive ok=true, ran=false for known-owned families.

# R9R1H — kind-aware authoring navigation and rewrite safety

## Routing

The unified family browser/Workbench chooses the current family, but authoring routes to the authoritative editor for that kind.

Required routing intent:

~~~text
dialogue     → Conversations / canonical dialogue editor
behavior     → existing Interaction Modules behavior editor
beat         → existing Interaction Modules beat editor
realization  → audited current canonical realization editing surface
~~~

Do not create parallel semantic editors merely to satisfy navigation.

If Interaction Modules is hidden behind Developer Tools and that makes normal behavior/beat rewrite impractical, promote/reuse that existing pane as a current first-class Studio authoring destination rather than cloning it.

## Exact-field navigation

Open affected field must route and focus/highlight kind-specific fields where the destination editor exposes them.

At minimum prove behavior.stimuli, behavior.outputs, beat.entry, beat.candidates, realization.translations, and realization.dialogueAct/strategy/concept.

Unsupported exact subfields must still open the correct family and surface a precise reason rather than silently doing nothing.

## Non-dialogue round-trip safety

Add tests proving that merely selecting/opening/saving a behavior, beat, or realization does not inject dialogue-only fields, rewrite its schema incorrectly, or delete preserved data.

The dialogue editor must either refuse non-dialogue writes and route to the right editor, or become genuinely kind-aware without duplicating existing authoring logic.

Prefer routing/reuse unless evidence shows a shared editor is simpler and safer.

## Health depth

Close the applicable F7 validator gaps before calling a non-dialogue family rewrite-ready.

# R9R1I — usability acceptance and closure

Add a real Tk/Xvfb journey that proves the primary family browser, not only the Completeness table:

1. opens with compact family labels and no repeated owner/kind prefix;
2. visibly color-codes real family rows from the canonical health report;
3. exposes kind quick filters with live 520 / 30 / 3 / 35 checkpoint counts;
4. selecting Beats immediately exposes all 3 beats;
5. selecting Behaviors/Realizations exposes those families without dialogue scrolling;
6. family selection synchronizes with Dialogue Completeness;
7. selecting a dialogue warning still focuses the exact dialogue/S11 field;
8. a synthetic/controlled broken behavior routes to the behavior editor and exact field;
9. a broken beat routes to the beat editor and exact field;
10. a broken realization routes to the realization authoring surface;
11. known manifest-owned families actually execute their registered test/fixture/Lua owner;
12. coverage unknown/uncovered is visible and Missing Coverage is truthful;
13. non-dialogue open/save round trips are mutation-safe;
14. contextual repair remains disabled on structurally healthy families;
15. retired legacy panes/toggles remain caller-zero.

Then run focused unit tests, real Tk/Xvfb, relevant provider/worker coverage, canonical 9-suite acceptance twice from one exact participant vector, post-acceptance CodeBuilder reconcile, git diff --check, exact participant HEADs and residual fingerprints.

Do not launch native Project Zomboid without explicit authorization.

# Content rewrite gate

BULK_DIALOGUE_REWRITE_ALLOWED=false throughout R9R1F-I.

Only restore it when a user or agent can:

~~~text
find any of the 588 maintained families quickly
→ see its structural health in the primary browser
→ see truthful test coverage independently of structural health
→ open the correct kind-specific editor
→ navigate to the actual failing field
→ make a canonical edit without kind/schema corruption
→ run the relevant family verification
→ rerun affected health
→ confirm the row/coverage state changed truthfully
~~~

# Non-negotiable architecture rules

Do not introduce:

- a second UI-only health/completeness analyzer;
- duplicated behavior/beat/realization editors;
- compatibility shims for the stale manifest lookup keys;
- project-owned legacy UI wrappers;
- direct edits to generated Lua/registries/manifests/translations;
- arbitrary scaffold actions on healthy families;
- broad dialogue/beat/behavior/realization rewrite before R9R1I;
- a second GUI harness when existing Tk/Xvfb is sufficient.

Preserve:

~~~text
canonical compact source
→ canonical IR
→ Portable Dialogue Plan / canonical kind models
→ one compiler-owned authoring-health report
→ compact unified family navigation
→ authoritative kind-specific authoring surface
→ CodeBuilder generation
→ acceptance
~~~
