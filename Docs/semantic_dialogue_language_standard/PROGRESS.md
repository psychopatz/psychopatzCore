# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S11A6 accepted (generic memory/modifier retention, stacking/dedupe, and bounded expiry lifecycle); advancing to S11A7 compiler/runtime optimization.
**Estimated developer progress:** S0-S10R + G7-G9 + S11A0-S11A6 accepted; S11A7-S11A8 foundation build active before any production dialogue migration.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11A — preflight/regression freeze + compiler completeness + participant-agnostic portable facts/effects + optimized runtime substrate.
**Immediate Next Chunk:** S11A7 — compiler/runtime optimization (stable compiled IDs, required-fact dependency indexes, fact->consuming-family & action/effect/modifier invalidation maps, dependency-driven projection, incremental analysis fingerprints, no shadow state).

## S11 reopened developer work — post-G9 re-audit (2026-11-18)

Normative goal: S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md. Approved architecture: S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md. Mandatory branching audit: S11_BRANCHING_DIALOGUE_AUDIT.md.

Re-audited structural-cleanup HEADs:

~~~text
psychopatzCore   a583dbd246b6d8f6f4ba519462aecae92424a06f
ProjectHoomans   942ef41304287e6dadc6023a0c2577910cef2408
DynamicTrading   e21387081776e3c8c8e2ba34d419a83441be801f
~~~

Accepted cleanup architecture is now compact PSDL/ConvoEngine package → canonical Semantic Dialogue IR → Portable Dialogue Plan → descriptor-selected backend → generated runtime → typed capability adapter.

Focused structural baseline reruns are green: Core G8/G9 production/backend/decomposition 13/13; Hoomans focused stateful/flow/proposal 15/15. These suites do not catch S11.

Fresh production-worker audit still reproduces all major P0 defects: known reminder → PLAYER_NAME, stranger choices in known state, repeat identity reward farming, stale identity choices, repeated/busy companion command dispatch, Needs proposal self-loop, hostile greeting plus friendly follow-up, stale recruitment, and stale relationship proposal.

The old runtime-descriptor-first S11 design is superseded. State/input/repeat/postcondition policy must be authored in canonical compact source and survive canonical IR → Portable Dialogue Plan → Reference VM/PZ backend. Existing Core ActionContract is the mutation/result seam; SemanticOutcome is a normalized data contract around pre-admission plus ActionContract.ProjectResult, not a second execution runtime.

Provider-owned declarative fixtures under tools/providers/pnc/fixtures/v1/ are the primary behavioral acceptance surface. Correct existing contracts that bless repeated FOLLOW dispatch and unbounded Needs pending state; preserve valid first-contact identity fixtures.

Authoritative S11 execution order:

`Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`

Foundation contracts:

`Docs/semantic_dialogue_language_standard/S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`

`Docs/semantic_dialogue_language_standard/S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`

`Docs/semantic_dialogue_language_standard/S11_COMPILER_RUNTIME_OPTIMIZATION.md`

`Docs/semantic_dialogue_language_standard/S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

Before broad S11 migration, the compiler must build one canonical conversation graph and report reachability, missing state/action branches, unbounded cycles, continuation obligations, closure classes, semantic memory residue, and fixture coverage. Closed branches with meaningful residue project compact same-day semantic episodes through the existing ConversationMemory/domain authorities; live flow state is not memory.

Conditions and consequences must also normalize through one portable EntityRef / Predicate-Query / Action / Effect / Modifier / Retention vocabulary. ProjectHoomans relationship effects/memories, morale modifiers, and inventory query/consumption services remain domain authorities behind compiler-visible schemas; no relationship/mood/inventory mini-DSL or duplicate modifier engine is allowed.

Optimization is compiler-heavy/runtime-light. S11A must measure baselines before hard thresholds, generate stable compact definitions/dependency indexes, project only required facts, invalidate by authoritative fact changes with a safe full-rebuild fallback, lower eligible rules to compact runtime programs while retaining generic evaluator parity, support incremental analysis by normalized fingerprints, schedule timed expiry without per-frame global scans, dedupe/aggregate repeated memories/modifiers, persist only mutable instance data, and keep detailed traces opt-in.

Future emergent dialogue must be possible without rebuilding semantics around an LLM. S11 therefore generalizes scenes to bounded ParticipantSets plus dynamic role/cardinality binding and preserves machine-readable semantic act/archetype/topic/event/activity/memory discovery metadata. The autonomous Dialogue Director/scorer is explicitly out of scope; semantic correctness must require zero LLM calls.

Current CodeBuilder reconcile check is desired=407, missing=0, stale=0, ambiguous=0, drifted=2. The two pre-existing drifts are DTCommon generated ConvoEngine/Manifest.lua and ConvoEngine/Registry.lua whole-model fingerprints. Close or explicitly baseline them before S11 source implementation.

S11 sequence:

~~~text
S11A — preflight + declarative regression freeze + compiler completeness/memory continuity + participant-agnostic portable facts/effects/modifiers + optimized runtime substrate
→ S11B — identity reference migration
→ S11C — companion commands + Needs/Greeting flow migrations
→ S11D — full constrained-domain sweep + real surfaces
→ S11E — retained acceptance + generation closure + exact handoff
~~~

Do not return to USER_ACCEPTANCE until S11A-S11E pass.

## Accepted baseline retained

The S0-S9R architecture remains accepted:

    WorkspaceCatalog
    ConvoCatalog
    OperationRegistry / ConvoTransaction
    production Lua ConvoProbe
    BuildPlanner
    thin GUI/CLI clients

The 11-operation ConvoEngine vocabulary remains accepted.

S10A also remains accepted unless new regression evidence appears:

- exact manifest-selected PNC worker starts/restarts with `MAX_POOLS = 256`;
- generated response pools are preflighted before registry mutation;
- truthful/generated identity claims bind authoritative names into initiating `say`;
- `affordance.label` remains UI presentation only;
- refusal remains semantically distinct;
- real-worker and real Tk/Xvfb identity-click acceptance is green.

Fresh audit reruns on 2026-11-16:

    S10A provider + label/speech                 8/8 PASS
    S10C real Tk/Xvfb journeys                  4/4 PASS
    S10D provider lifecycle                     3/3 PASS
    Feature Registry + acceptance-runner unit   8/8 PASS
    pnc_s10a_flow_preflight_smoke.lua                PASS

## Resolved S10R audit findings (2026-11-16)

All 5 audit findings below were repaired across `S10R1 -> S10R2 -> S10R3 -> S10R4`:

Normative repair design:

`Docs/semantic_dialogue_language_standard/S10_ACCEPTANCE_INTEGRITY_REPAIR.md`

### 1. S10B test-deletion gate was not proven

ProjectHoomans commit `5f8b5000` deleted 12 provider test modules containing approximately 68 test methods.

The Core APIs and public/service surfaces exercised by those tests still exist, including dataset-library, workflow, dataset-adapter, interaction-spec, variation-auditor and related authoring seams.

Reconstructed deleted tests expose current stale-source/schema failures. Therefore the deleted responsibilities must be migrated to current canonical acceptance or the associated surface must be formally retired with caller-zero/public-surface removal proof.

### 2. Feature Acceptance Registry is not complete for the public CLI

The S10C validator discovers `app.*_button`, a bounded Studio action set and `convo <subcommand>`, but not many supported top-level argparse actions.

Verified supported-but-unregistered actions include:

    --list-datasets
    --search-datasets
    --show-dataset
    --validate-dataset
    --workflow-preview
    --workflow-generate
    --adapt-dataset
    --inspect-interaction-history

Fresh runtime checks prove this omission hides real breakage:

- `--list-datasets` advertises sources whose paths report `exists=false`;
- `--show-dataset common_dialogue` fails on missing `responses/common/social.json`;
- `--workflow-preview common_dialogue --workflow-blocks language.speech_act,dialogue_responses.response_pool` returns `ok=false` and exits 2.

### 3. Canonical one-command acceptance is not green

The runbook's canonical `--acceptance` workflow currently reports the mandatory `hoomans_lua` suite as FAIL.

Fresh current-workspace acceptance includes unexpected non-Convo failures; `--allow-unrelated-baselines` does not make the suite pass.

The exact recorded S10D ProjectHoomans participant commit `9778522f` reruns at:

    1024/1029 PASS
    5 FAIL

Only `pnc_population_director_smoke.lua` is currently classified as the reviewed known unrelated baseline. The other failures remain unexpected.

`convoScopeOk=true` is diagnostic only and may not substitute for a mandatory suite passing.

### 4. Final S10D checkpoint is not reproducible

The S10D handoff recorded:

    psychopatz-core=<updating-on-S10D-commit>

instead of a resolved Core phase checkpoint.

Its Hoomans count also does not reproduce from the exact recorded participant commit, and later dirty/parallel work changes the root-suite result. Final closure therefore needs an exact participant vector and residual-work fingerprints.

### 5. Lifecycle coverage is hard-coded

`test_s10d_provider_lifecycle.py` discovers presets but executes a hard-coded current tuple:

    pnc
    dtabstract
    pnc-with-dthoomans

A newly supported non-alias worker-bearing provider can therefore avoid lifecycle acceptance. S10R must derive the executable matrix from current manifest discovery.

## S10R4 completed acceptance and final closure (2026-11-16)

- Removed hard-coded preset tuples (`("pnc", "dtabstract", "pnc-with-dthoomans")`) and hard-coded provider tables from `tools/semantic_harness/tests/test_s10d_provider_lifecycle.py`; `_evaluate_lifecycle_matrix(ModManager)` now derives all non-alias lifecycle presets and `WorkerSession.reconfigure` matrices dynamically from `ModManager.discover(...)` and fails if any executable/worker-bearing provider manifest lacks preset coverage (`4/4` PASS in `25.82s`).
- Hardened `tools/semantic_harness/codebuilder/workspace_catalog.py` (`temp_roots` exclusion during sibling directory scanning) so temporary test checkouts created under `/tmp` (`tempfile.gettempdir()`) are never poisoned by unrelated `/tmp/*` directories (covered by `test_workspace_catalog_ignores_system_temp_root_siblings`).
- Full 9-suite canonical `--acceptance` matrix (`PYTHONPATH=. python3 -m tools.semantic_harness --acceptance --acceptance-jobs 4`): **`PASS` `9/9` suites, `2171/2200` cases (`25` allowed local-save skips, `4` signature-proven unrelated `hoomans_lua` baselines from `20997b30`/`79114089`, `0` unexpected failures) in `1448.07s`**.
- Focused retained S10A checks: `pnc_s10a_flow_preflight_smoke.lua` `PASS`; `test_s10a_label_speech_realization` + `test_s10a_provider_worker_startup` `8/8 PASS` (`38.74s`).

## S10R3 completed acceptance (2026-11-16)

- Updated `tools/semantic_harness/testing/suite.py` (`BoundedLuaTestRunner.report`) to include bounded `failureOutput` (`output[-4000:]`) on failing Lua test entries in `--harness-report`.
- Added `tools/semantic_harness/testing/unrelated_baselines.json` and replaced filename-only matching in `acceptance.py` with `load_unrelated_baselines()`, `match_unrelated_baseline()`, and `classify_hoomans_lua_results()` requiring suite, test, non-Convo test status (`_is_convo_semantic_lua_test` forbidden), owner, `provenanceCommit`, non-timeout, and exact `failureOutput` signature pattern matching.
- Updated `cli.py` and `acceptance.py:main` so canonical `--acceptance` uses signature-proven reviewed baselines by default (`allow_unrelated_baselines=not strict_baselines`), added `--strict-baselines` to `acceptance.py`, `cli.py`, and `feature_registry.py` (`CLI_MODIFIER_OPTIONS`), and kept `convoScopeOk` strictly diagnostic.
- Verified `test_acceptance_runner.py` + `test_feature_registry.py` `11/11` PASS and `PYTHONPATH=. python3 -m tools.semantic_harness --acceptance --acceptance-suite hoomans_lua --acceptance-jobs 4` `PASS` (`1028/1032`, 4 signature-verified reviewed baselines from `20997b30` / `79114089`, `0` unexpected failures).

## S10R2 completed acceptance (2026-11-16)

- Extended `tools/semantic_harness/testing/feature_registry.py` (`discover_public_top_level_cli_actions`) to inspect live `cli._parser()._actions`, separating configuration/filter modifiers (`CLI_MODIFIER_OPTIONS`), mapping option aliases onto one canonical control, and enforcing AST-verified ownership over all 66 discovered public top-level CLI actions plus `app.*_button`, Studio `ConvoEngineAuthoringPane`, and `convo.*` subcommands.
- Updated `tools/semantic_harness/testing/feature_registry.json` with ownership entries for all top-level CLI actions and added headless + real-worker CLI acceptance in `test_s10r2_cli_actions.py` and `test_s10r2_worker_cli.py`.
- Verified negative registry failure on uncovered newly added top-level actions (`test_feature_registry.py` `4/4`, `test_s10r2_cli_actions.py` `1/1`, `test_s10r2_worker_cli.py` `2/2`, `test_acceptance_runner.py` `6/6`, `test_convo_engine_s9r_closure.py` `4/4` — `17/17 OK`).

## S10R1 completed acceptance (2026-11-16)

- Built the 12-module (`68`-method) responsibility ledger in `S10_ACCEPTANCE_INTEGRITY_REPAIR.md`.
- Retired obsolete pre-ConvoEngine dataset specs (`semantic_flows`, `common_dialogue`, `grounded_personal`) from `dataset_catalog.py` and wired canonical live sources (`convo_engine`, `common_patterns`, `grounded_personal_patterns`, `wordnet_concepts`) across `dataset_catalog.py`, `interaction_generation.py`, and `service.py` (while protecting `convo_engine` against raw bulk overwrites).
- Updated `variation_auditor.py` so `--variation-audit` audits canonical `convo_engine` shards (`510` families / `1002` styles) in addition to `"content"` fixtures.
- Restored Core & Hoomans acceptance (`test_s10r1_dataset_and_workflow.py`, `test_s10r1_c5_variation_adapters_specs.py`, plus `test_convo_engine_s9h4_studio`, `test_convo_engine_s9_regressions`, `test_acceptance_runner`, `test_convo_engine_s9r_closure`: `40/40 PASS`; `ProjectHoomans/tools/providers/pnc/tests/test_s10r1_worker_precision_and_history.py`: `2/2 PASS`).

## Current repository vector after S10R1

    PsychopatzCore  <updating on S10R1 commit>
    ProjectHoomans  fb4c43ce23ee0106f52dab931f12f817ddb9f991
    DynamicTrading  9c8cb3dead56d66e32fccb901b9abd3dd6c2f393

All three repositories preserve unrelated concurrent dirty work cleanly outside S10R commits.

## S10R sequence

    S10R1 — restore acceptance ownership for deleted/stale surfaces
      ->
    S10R2 — complete Feature Acceptance Registry discovery
      ->
    S10R3 — make canonical nine-suite acceptance genuinely green/reproducible
      ->
    S10R4 — derive lifecycle coverage dynamically and close with exact Git truth

Do not skip forward because a focused suite is green.

## Completion boundary

Developer-side work is **not complete** until S10R1-S10R4 pass.

Only after the canonical acceptance report is reproducibly green, every supported public action has acceptance ownership, provider lifecycle coverage is manifest-complete, and the final committed handoff contains exact participant/residual truth may the project return to `USER_ACCEPTANCE` for native Project Zomboid gameplay/UI/visual/feel validation.
