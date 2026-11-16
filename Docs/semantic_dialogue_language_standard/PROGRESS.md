# Progress — ConvoEngine / Semantic Harness

**Status:** ACTIVE — S10R acceptance-integrity repair.
**Estimated developer progress:** S0-S9R retained; S10A accepted; S10B-S10D mechanisms implemented but completion/closure claims reopened by audit.
**Branch:** existing `main` in all three repositories.
**Active phase:** S10R — acceptance integrity, public-surface ownership, reproducible closure.
**Immediate Next Chunk:** S10R2 — make Feature Acceptance Registry public-surface discovery complete across all supported top-level CLI actions (`--list-datasets`, `--search-datasets`, `--show-dataset`, `--validate-dataset`, `--workflow-preview`, `--workflow-generate`, `--adapt-dataset`, `--inspect-interaction-history`, etc.) with negative validation tests.

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

## Why S10 completion is reopened

The post-S10 audit disproved the claim that only native Project Zomboid user acceptance remains.

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
