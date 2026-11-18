# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S11R9R1 authoring-readiness corrective closure is active.
**Branch:** existing main in all three repositories.
**Active phase:** S11R9R1F1-F5 — primary Conversations authoring simplification.
**Content rewrite gate:** BULK_DIALOGUE_REWRITE_ALLOWED=false.

## Current checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 5aa3c089d6c92a0f9926434f16d0148d9315aad9)
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
R9R1F  primary authoring simplification (F1-F5)
R9R1G  truthful coverage and exact family-test execution
R9R1H  kind-aware authoring routing + non-dialogue safety
R9R1I  real usability acceptance + reproducible closure
~~~

## Completed in this session (R9R1F-I)

- **R9R1F1-F5:** Replaced the flat `Listbox` in `ConvoEngineAuthoringPane` with a health-colored `ttk.Treeview` using compact `canonicalID` labels, live `All` / `Dialogues` / `Behaviors` / `Beats` / `Realizations` kind filters, selection preservation across filters, single normal dialogue editing path with `Advanced schema / details` disclosure, concise selected-family header + `Family settings…` + `State & Flow` progressive disclosure, removed embedded `Simulation / trace` tab in favor of `Preview in Simulation`, moved `Run ConvoEngine Integrity Audit` to `Review`, demoted infrequent/destructive actions to `⋯`, and fixed single-line JSON rendering with compact single-line serialization.
- **R9R1G:** Replaced stale `familyId` / `canonicalFamilies` lookups with `canonicalFamilyId`, introduced truthful coverage states (`exact_owner`, `suite_covered`, `uncovered`, `unknown`) with `missingCoverage` counting `uncovered` + `unknown`, and implemented real execution in `run_family_tests()` for `declarative_fixture`, `python_test`, and `lua_test`.
- **R9R1H:** Added kind-aware routing (`behavior`/`beat` -> `InteractionModulesPane`, `realization` -> `ConvoEngineAuthoringPane` realization panel), exact-field navigation (`behavior.stimuli`/`outputs`, `beat.entry`/`candidates`, `realization.translations`/`dialogueAct`/`strategy`/`concept`), non-dialogue round-trip write safety, and F7 behavior/realization health checks.
- **R9R1I:** Added real Tk/Xvfb usability journey (`test_real_tk_full_usability_acceptance_journey`), updated `ProjectHoomans` GUI journey assertions, verified `reconcile.py --check` clean, and verified all ConvoEngine/Semantic Harness test suites pass. Two sequential `acceptance --jobs 4` runs passed all ConvoEngine suites but hit `participant_worktree_mutated` due to concurrent unrelated `NPCAuthoring` edits in `ProjectHoomans`.

## Immediate Next Chunk

Re-run `xvfb-run -a python3 -m tools.semantic_harness.testing.acceptance --jobs 4` twice sequentially once `ProjectHoomans` is quiescent, then set `BULK_DIALOGUE_REWRITE_ALLOWED=true` and reconcile S11 to user-acceptance state.
