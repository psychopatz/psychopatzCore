# ConvoEngine Handoff

~~~yaml
status: COMPLETE
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11 — State-Aware Conversation Outcome Closure (R0-R4 / S11A-S11E COMPLETE)
chunk: None (ready for user-owned native Project Zomboid acceptance)
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
repair_doc: Docs/semantic_dialogue_language_standard/S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md
foundation_order_doc: Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md
updated_at: 2026-11-18T09:46:00Z
~~~

## Final S11E participant checkpoint

~~~text
DynamicTrading   a1f9cbc3e986f5dafa35cdec34d7ac71e9846bf4
ProjectHoomans   fcbc787ad708dd38aff13511f07dcf48e3460558
psychopatzCore   phase_commit: self (R3: 19677f677e3139a2b505baff12d63bc3ca381e8b)
~~~

- **DynamicTrading** and **psychopatzCore** worktrees are clean at closure.
- **ProjectHoomans** retains only unrelated pre-existing dirty/untracked NPCAuthoring, StartingCompanions, and UniqueNPCEditor files (preserved untouched).

## Accepted closure summary (R0-R4 / S11A-S11E)

- **R0 (`72d4cf8`):** `constrained_family_manifest.json` + strict completeness analyzer gate + `tests/psychopatz_runtime_role_split_smoke.lua` fix.
- **R1 (`DynamicTrading` `866a50c9`, `ProjectHoomans` `9e33b03c`, `psychopatzCore` `2ce524d`):** Canonical Identity triggers/flow in `identity_exchange_responses.json`; `Flow_Identity.lua` deleted with caller-zero.
- **R2 (`DynamicTrading` `1de18b1d`, `ProjectHoomans` `eaef787d`, `psychopatzCore` `1137e1e`):** Canonical recipes for `follow`, `stay`, `camp`, `return_home`, `flow_needs_exchange.json`, `flow_greeting_exchange.json`; `Input_Actions_Dispatch.lua` uses generic `S11PolicyEvaluator`; `Flow_Needs.lua` & `Flow_Greeting.lua` deleted with caller-zero.
- **R3 (`DynamicTrading` `f90ea5f2`, `ProjectHoomans` `75906e99`, `psychopatzCore` `19677f6`):** Canonical recipes for `social_recruitment_offer.json`, `social_relationship_proposal.json`, `social_parley_ceasefire.json`, `social_territory_set.json`, `social_effectful_wellbeing_trust.json`; all `CANONICAL_STATEFUL` manifest rows accepted (`strict_manifest=True -> ok=True`); multi-turn transition-refresh + repeat no-op fixtures for recruitment and relationship proposal added.
- **R4 (`DynamicTrading` `a1f9cbc3`, `ProjectHoomans` `fcbc787a`, `psychopatzCore` `phase_commit: self`):** Greeting constraints + hostile greeting `semantic.flow.greeting.opening` (`guarded`) + `pnc_conversation_smoke` / `pnc_convo_engine_camp_action_smoke` / `test_flow_editor` / `TEST_CLASSIFICATION.json` aligned; full acceptance green (`convoScopeOk=True`, `core_python` `308/308`, `core_lua` `36/36`, `hoomans_provider_python` `146/146`, `real_provider_worker` `331/331`, `tk_xvfb_gui` `144/144`, `dynamic_trading` `89/89`, `convo_audit` `1/1`, `kahlua_static` `3/3`, `reconcile --check clean=true`, `audit-integrity diffs=[]`).

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
