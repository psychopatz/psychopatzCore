# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S11 State-Aware Conversation Outcome Closure opened by verified post-S10R native/Semantic Lab regression evidence.
**Estimated developer progress:** S0-S10 + S10R retained as accepted infrastructure; S11A is active.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11A — regression freeze + single semantic state/outcome substrate.
**Immediate Next Chunk:** Freeze the full S11A P0 regression matrix, then implement the approved Core StatePolicy/SemanticOutcome substrate by extending the existing Predicate / Offer / capability / flow contracts—no parallel registry or shadow state system.

## S11 reopened developer work (2026-11-16)

Normative goal:

`Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`

Approved architecture:

`Docs/semantic_dialogue_language_standard/S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`

Fresh production-worker evidence disproves the prior conclusion that only native visual/gameplay acceptance remained:

- a known NPC correctly selects `question.identity.known` yet the same turn creates a first-contact `PLAYER_NAME` pending obligation;
- the Response Channel then exposes `Say your real name`, `Don't tell your name`, and `Lie about your name` despite the NPC saying the characters already know one another;
- a truthful repeated identity claim can reapply the first-introduction relationship effect (`approval +1`, `respect +2`, `familiarity +6`) on every accepted repetition;
- after an accepted identity exchange clears the live pending obligation, a later snapshot can resurrect the same first-contact identity choices;
- existing tests currently encode contradictory expectations: known-identity response parity is tested while another smoke test still requires a known identity question to create the first-contact player-name obligation.

S11 treats identity as the reference implementation for a broader invariant: state-constrained button suggestions and free-text input must share one authoritative state/outcome classification, and every recognized reachable state must have an immersive reply/effect/no-op outcome.

The approved implementation direction is explicitly **single-system**: Semantic IR continues to describe meaning; existing gameplay systems remain state authority; the existing semantic capability/flow descriptors are extended with one Predicate-backed `statePolicy` and canonical `SemanticOutcome`. Suggestions, typed input, flow transitions, responses, effects and refresh all consume that result. Do not create a second state store, action registry, suggestion-only eligibility engine, typed-input state engine, condition DSL, or repeat/cooldown subsystem.

S11 sequence:

```text
S11A — freeze regressions + single StatePolicy/SemanticOutcome substrate
  ->
S11B — identity migration onto shared substrate + effect idempotence + refresh correctness
  ->
S11C — constrained-domain parity sweep
  ->
S11D — real worker / inputbox / response-channel / Tk-Xvfb closure acceptance
  ->
S11E — retained canonical acceptance + exact committed closure
```

Do not return to `USER_ACCEPTANCE` until S11A-S11E pass.

### Expanded branching/state audit

Mandatory audit input:

`Docs/semantic_dialogue_language_standard/S11_BRANCHING_DIALOGUE_AUDIT.md`

The cross-dialogue audit confirms that identity is one instance of a wider state-parity class. Additional runtime-verified defects include:

- repeated FOLLOW/STAY/GO HOME/CAMP commands and busy-state FOLLOW can dispatch through typed input even when suggestion eligibility says the action is already satisfied or unavailable;
- the needs flow can remain indefinitely in `proposal_pending -> proposal_pending` on repeated acceptance;
- hostile/busy greeting state can hide the continuation button while typed continuation still completes the semantic flow, and hostile `hello` can combine parley wording with the friendly `How have you been?` follow-up;
- successful recruitment can leave Recruit visible and admit another recruitment request;
- accepted relationship proposal can leave its affordance visible even though authority now returns `already_lover`;
- natural free-text equivalents for relationship proposal, disband/departure, ceasefire and territory currently fall to generic clarification instead of an explicitly owned parity/confirmation policy;
- effectful authored wellbeing/trust/affinity choices have relationship effects but no explicit repeat/cooldown/retirement policy.

High-risk but comparatively strong authorities that require parity coverage rather than redesign include parameterized task admission, quest lifecycle, settlement/ambient visits, territory and parley state transitions.

Reference-good contracts to preserve include wellbeing answer convergence, event follow-up expiry, grounded gossip unknown handling, gift consent/expiry, departure warning/confirmation, settlement expiry and pragmatic apology/reconciliation. A fresh focused rerun of coherent conversation, event follow-up, gift and grounded-gossip suites passed `14/14`.

S11C/S11D must cover every family in the audit, not only identity. Each family must migrate onto the same existing-registry state/outcome substrate; a family-specific duplicate evaluator is not an acceptable fix.

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
