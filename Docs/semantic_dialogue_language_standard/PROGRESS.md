# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S11R9R1 authoring-readiness corrective closure is active.
**Branch:** existing main in all three repositories.
**Active phase:** S11R9R1F — compact primary family browser.
**Content rewrite gate:** BULK_DIALOGUE_REWRITE_ALLOWED=false.

## Current checkpoint

~~~text
psychopatzCore   fba98ab4791bde95a12fb1fcb7fbeede88408d7a
ProjectHoomans   a64c3bcb325f209c599a77689387135e918c2de1
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

All three worktrees were clean at planning start.

## Retained accepted implementation

- 588-family compiler-owned health inventory exists: 520 dialogue, 30 behavior, 3 beat, 35 realization.
- Dialogue Completeness has real Tk semantic colors, needs-attention default, human summaries, and selection synchronization.
- Dialogue/S11 exact-field navigation and contextual repair behavior work.
- Legacy compatibility toggle and three retired panes are deleted; useful current surfaces were retained/moved.
- Focused R9R1 tests and canonical acceptance remain green apart from reviewed unrelated Lua baselines.

## Reopened blockers

1. The primary left ConvoEngine family browser still repeats owner/kind on every row and is not health-color-coded.
2. Behaviors/beats/realizations are too hard to discover in one flat dialogue-heavy list.
3. All 588 families currently report fixtureCoverage=unknown, while missingCoverage=0; coverage UI is misleading.
4. run_family_tests() looks up stale manifest keys instead of canonicalFamilyId, so known-owned families falsely report no runnable owner.
5. Non-dialogue diagnostics cannot navigate to behavior/beat/realization fields.
6. The dialogue-shaped Conversations form is unsafe as a generic editor for non-dialogue records.
7. Behavior/realization health still lacks some applicable reference/capability/slot/orphan checks promised by the authoring-readiness contract.

## Remaining sequence

~~~text
R9R1F  compact health-colored kind-discoverable primary family browser
R9R1G  truthful coverage and exact family-test execution
R9R1H  kind-aware authoring routing + non-dialogue safety
R9R1I  real usability acceptance + reproducible closure
~~~

## Immediate Next Chunk

**R9R1F only:** make the left ConvoEngine family browser compact and health-aware without creating a second analyzer. Remove repeated owner/kind prefixes from Family text, project canonical health colors there, add live kind quick filters/counters for All/Dialogues/Behaviors/Beats/Realizations, and preserve loop-safe shared family selection. Then validate with fake-widget and real Tk/Xvfb tests before advancing automatically to R9R1G.
