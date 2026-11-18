# ConvoEngine Handoff

~~~yaml
status: IN_PROGRESS
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11 repair — R2 accepted
chunk: R3 — execute S11D full constrained-domain sweep
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md
foundation_order_doc: Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md
updated_at: 2026-11-18T09:03:00Z
~~~

## Audited participant checkpoint

Audit-start commits before this documentation correction:

~~~text
psychopatzCore   3f8b933f2545a5e5f2e6b897555c86eee96b2d31
ProjectHoomans   35d1a6bc6b26a0515c2dd19247c3adbc4b4e5d3e
DynamicTrading   503d13037fbc51c66ad42c81191c8b91d1fd4da2
~~~

All three worktrees were clean at audit start. The Core commit containing this handoff is `phase_commit: self`; re-read HEAD/status before implementation.

## Accepted foundation — keep

- S11A0-A8 contains real canonical-contract, source->IR->Portable Plan, VM/Lua parity, Completeness, adapter, lifecycle, and dependency/index work.
- Fresh focused foundation tests: **23/23 PASS**.
- ProjectHoomans automatic-flow tests: **9/9 PASS**.
- CodeBuilder reconcile: **clean**, `desired=407`, `missing=0`, `drifted=0`, `stale=0`.
- Integrity/determinism: **PASS**, 577 families, 0 legacy-name violations, 404 deterministic files, 0 diffs.

Do not rebuild A0-A8 from scratch unless a targeted test proves a defect.

## Not accepted

### Completeness acceptance authority

The analyzer can report green while required stateful families remain outside canonical S11 metadata. R0 must add a compiler-visible constrained-family manifest derived from `S11_BRANCHING_DIALOGUE_AUDIT.md`.

Allowed final classifications:

~~~text
CANONICAL_STATEFUL
EXPLICIT_PRESENTATION_ONLY
REFERENCE_GOOD_REGRESSION
RETIRED
~~~

This is acceptance metadata over canonical family IDs, not a second semantic registry.

### S11B — PARTIAL / REOPENED

`question_identity.json` is canonically migrated and behavior fixes exist, but `Flow_Identity.lua` is still loaded by `FlowCatalog.lua`. Finish canonical ownership, prove caller/reference zero, and delete the superseded semantic flow. No forwarding shim.

### S11C — NOT ACCEPTED / REOPENED

Behavior patches exist, but semantic ownership is in the wrong place: command-specific admission lives in `Input_Actions_Dispatch.lua`, and Needs/Greeting remain hand-authored in `Flow_Needs.lua` / `Flow_Greeting.lua`. Recipe-author these semantics canonically, regenerate, prove parity/caller-zero, and remove superseded flows.

### S11D — NOT DONE

The mandatory full constrained-domain sweep was not implemented before the false S11E closure. Recruitment, relationship proposal, disband, ceasefire/territory, tasks/quests, effect repeat semantics, settlement/ambient refresh, and retained reference-good regressions still require explicit closure.

### S11E — NOT ACCEPTED

Fresh full Core semantic-harness:

~~~text
Ran 307 tests
FAILED (failures=1, skipped=2)
~~~

Current failure:

~~~text
test_acceptance_runner.AcceptanceRunnerTests.test_fast_subset_of_real_suites_executes_cleanly
core_lua: tests/psychopatz_runtime_role_split_smoke.lua
attempt to index a nil value (local 'f')
~~~

Do not assume S11 caused it; diagnose. It still blocks reproducible S11E closure.

## Immediate Next Chunk — R0 only

1. Re-read all repo HEAD/status and preserve unrelated work.
2. Read `S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md`.
3. Build the constrained-family acceptance manifest from the branching audit.
4. Wire Completeness/acceptance so every maintained required stateful family must be canonically owned or explicitly classified.
5. Add negative tests proving missing canonical policy fails for a required stateful family.
6. Diagnose/fix or correctly baseline the current retained Core Lua acceptance failure.
7. Rerun focused foundation/acceptance guards.
8. Reconcile ROADMAP/PROGRESS/HANDOFF and locally commit accepted R0 before proceeding automatically to R1.

Do not broad-migrate dialogue during R0.

## Mandatory continuation

~~~text
R1  finish S11B Identity retirement
R2  redo/finish S11C using canonical CodeBuilder recipes
R3  execute full S11D constrained-domain sweep
R4  rerun S11E and close reproducibly
~~~

At accepted multi-repo boundaries: adopter repos first, Core last; exact paths only; no broad staging; no push/publication.

## Hard rules

- Canonical source/recipe first; generated output is downstream-only.
- Use `tools/semantic_harness/codebuilder/generation_recipe.json` and recipe-driven reconcile.
- Do not solve migration defects with more family-specific semantic policy in hand-written runtime Lua.
- No compatibility shims/fallback readers/dual registries/writes/permanent old+new semantic paths for project-owned internal code.
- Genuine external mod compatibility adapters are not automatically legacy shims; verify before changing them.
- Parity + caller-zero before deleting superseded semantic code.
- Semantic correctness requires zero LLM calls.
- Do not implement the future autonomous Dialogue Director during this repair.
- The full parent S11 objective, not a focused green suite, is the completion boundary.
