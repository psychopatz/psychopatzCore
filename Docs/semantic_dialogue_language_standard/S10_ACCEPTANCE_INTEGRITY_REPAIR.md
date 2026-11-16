# S10R — Semantic Harness Acceptance Integrity Repair

**Status:** ACTIVE
**Audit date:** 2026-11-16
**Parent goal:** S10 — Semantic Lab end-to-end reliability and maintainability
**Accepted baseline retained:** S0-S9R and S10A
**Reopened claims:** S10B acceptance completeness, S10C feature-ownership completeness, and S10D final closure

## Purpose

S10R exists because a post-completion audit found that the S10 implementation is materially useful but the developer-complete claim is not yet defensible.

This phase does **not** reopen the accepted S10A worker/startup and label-versus-speech implementation unless new regression evidence appears. The real identity path is retained: the UI label remains presentation-only, initiating `say` binds the canonical/generated identity name, refusal remains distinct, and the focused real-worker/Tk acceptance remains green.

S10R repairs the acceptance system around that implementation so future agents cannot make a suite green by deleting still-relevant tests, omit supported public surfaces from feature ownership, depend on dirty work for closure evidence, or hard-code a provider list that silently misses future manifests.

## Verified audit findings

### R1 — S10B deleted coverage without proving the covered surfaces were retired

ProjectHoomans commit `5f8b5000` deleted 12 provider test modules containing approximately 68 test methods:

- `test_c7f_dataset_precision.py`
- `test_codebuilder_consolidation.py`
- `test_conversation_compiler.py`
- `test_conversation_content_authority.py`
- `test_conversation_context_health_c5.py`
- `test_dataset_adapters.py`
- `test_dialogue_dataset.py`
- `test_dialogue_variation_auditor.py`
- `test_f4_semantic_lab_acceptance.py`
- `test_interaction_spec.py`
- `test_modular_dataset_authoring.py`
- `test_v1_visual_authoring.py`

The Core modules and service seams exercised by those tests still exist, including `dialogue_dataset`, `dataset_adapters`, `interaction_spec`, `variation_auditor`, dataset-library operations, workflow preview/generation, and interaction authoring.

Reconstructed deleted tests fail against the current code because several of those surfaces still reference old/missing canonical source layouts or stale schemas. Therefore deletion was not proven by caller-zero/dead-surface evidence.

S10R must not blindly restore stale tests. For every deleted test responsibility, either:

1. migrate equivalent acceptance to the current canonical architecture and prove parity; or
2. explicitly retire the public/service surface, remove callers/CLI/UI exposure, and prove caller-zero before deleting its test ownership.

### R2 — supported top-level CLI surfaces are not covered by Feature Acceptance Registry discovery

The S10C validator discovers top-level `app.*_button` controls, a bounded Studio action set, and `convo <subcommand>` parsers. It does not automatically discover many supported argparse actions that remain visible in `python3 -m tools.semantic_harness --help`.

Verified currently unregistered public surfaces include:

- `--list-datasets`
- `--search-datasets`
- `--show-dataset`
- `--validate-dataset`
- `--workflow-preview`
- `--workflow-generate`
- `--adapt-dataset`
- `--inspect-interaction-history`

This invalidates the S10C claim that every supported public action has acceptance ownership.

Fresh runtime evidence also proves this is not only a registry bookkeeping defect:

- `--list-datasets` advertises legacy dataset sources whose paths report `exists=false`;
- `--show-dataset common_dialogue` fails because the advertised `tools/semantic_harness/codebuilder/sources/conversation/responses/common/social.json` path is missing;
- `--workflow-preview common_dialogue --workflow-blocks language.speech_act,dialogue_responses.response_pool` returns `ok=false` and exits with code 2 for the same stale source layout.

Every supported public action must either work and have an acceptance owner or be explicitly removed/deprecated from the supported public surface.

### R3 — the canonical one-command acceptance workflow is not green

The runbook defines `python3 -m tools.semantic_harness --acceptance` as the canonical S10 developer gate.

Fresh focused reruns on 2026-11-16 show:

- S10A provider + label/speech: `8/8 PASS`;
- S10C real Tk/Xvfb journeys: `4/4 PASS`;
- S10D provider lifecycle: `3/3 PASS`;
- Feature Registry + acceptance-runner unit gates: `8/8 PASS`;
- `pnc_s10a_flow_preflight_smoke.lua`: PASS.

But the mandatory `hoomans_lua` suite is not accepted:

- current workspace rerun: failures remain and the runner reports `FAIL`;
- exact ProjectHoomans S10D participant commit `9778522f`: `1024/1029` with 5 failures;
- even `--allow-unrelated-baselines` fails because only `pnc_population_director_smoke.lua` is classified as a known unrelated baseline while the remaining failures are `unexpected_failure`.

`convoScopeOk=true` is useful diagnostic information, but it is **not** equivalent to the mandatory suite passing.

S10R must make the canonical acceptance command return success from a reproducible participant checkpoint. Unrelated baselines may be allowed only when explicitly reviewed, machine-classified, and proven outside the S10-owned surface; unexplained failures remain failures.

### R4 — the recorded S10D closure is not a reproducible committed checkpoint

The final handoff records:

`psychopatz-core=<updating-on-S10D-commit>`

instead of the actual committed Core checkpoint and omits the stronger committed-handoff metadata previously used by S9R.

The S10D documentation also records a Hoomans result that does not reproduce from the exact recorded Hoomans participant commit. Some later dirty/parallel work changes the root-suite result, so a worktree-dependent result cannot be treated as committed acceptance evidence unless its residual state is fingerprinted and explicitly owned.

S10R closure must produce:

- exact participant commit vector;
- committed Core phase identity (`phase_commit: self` or equivalent derivable checkpoint);
- residual dirty-work fingerprints for every participant;
- acceptance run from the exact checkpoint or a documented dirty-resumable state that is not misrepresented as committed;
- no placeholder commit IDs.

### R5 — provider lifecycle acceptance is not manifest-complete

`test_s10d_provider_lifecycle.py` discovers presets through `ModManager` but then executes a hard-coded tuple of:

- `pnc`
- `dtabstract`
- `pnc-with-dthoomans`

This covers the current known set but does not enforce the maintainability rule that a newly supported non-alias provider manifest automatically enters lifecycle acceptance.

The lifecycle matrix must derive its executable provider/preset set from current manifest discovery and fail when a supported worker-bearing selection lacks lifecycle ownership.

## S10R work plan

### S10R1 — restore acceptance ownership for the deleted/stale surfaces

**Status:** COMPLETE (`test_s10r1_dataset_and_workflow.py`, `test_s10r1_c5_variation_adapters_specs.py`, and `ProjectHoomans/tools/providers/pnc/tests/test_s10r1_worker_precision_and_history.py` green; `dataset_catalog.py`, `interaction_generation.py`, and `variation_auditor.py` repaired to canonical sources).

#### S10R1 Responsibility Ledger (ProjectHoomans commit `5f8b5000`, 12 deleted files / 68 test methods)

| Deleted `5f8b5000` test file | Former methods | Responsibility | Outcome & current canonical owner |
| --- | --- | --- | --- |
| `test_c7f_dataset_precision.py` | 2 | Reviewed `common_patterns` compilation + C7F holdout real-worker P/R (`1.0`/`1.0`, `0` false exec) | **Migrated**: `ProjectHoomans:tools/providers/pnc/tests/test_s10r1_worker_precision_and_history.py` |
| `test_codebuilder_consolidation.py` | 9 | `validate_branch_offers`, dataset library list/search/show/validate, workflow preview/approval-gated generate, CLI routing | **Migrated + retired stale specs**: retired pre-ConvoEngine `semantic_flows`/`common_dialogue`/`grounded_personal` specs; repaired `dataset_catalog.py` + `interaction_generation.py` to `convo_engine`, `common_patterns`, `grounded_personal_patterns`, `wordnet_concepts`; tested in `PsychopatzCore:tests/test_s10r1_dataset_and_workflow.py` |
| `test_conversation_compiler.py` | 6 | Manifest owners/fingerprints, move provenance, targeted writes, bounded plan without snapshot, third-locale auto-discovery | **Covered/Migrated**: `test_conversation_manifest.py`, `test_convo_engine_authoring.py`, `test_convo_engine_s9h1_catalog.py`, `test_convo_engine_s9h2_transactions.py`, plus third-locale & snapshot-free plan assertions in `test_s10r1_c5_variation_adapters_specs.py` |
| `test_conversation_content_authority.py` | 5 | Deterministic manifest compilation, phrase/label layer separation, response-pool lineage | **Covered**: `test_convo_engine_s6m8_audit.py`, `test_convo_engine_compiler.py`, `ProjectHoomans:test_response_observatory.py`, `ProjectHoomans:test_s10a_label_speech_realization.py` |
| `test_conversation_context_health_c5.py` | 8 | `conversation_context_health`, `conversation_discovery_index`, `conversation_affected_closure`, shard byte budget | **Migrated**: `test_convo_engine_s9_regressions.py` + `PsychopatzCore:tests/test_s10r1_c5_variation_adapters_specs.py` |
| `test_dataset_adapters.py` | 5 | MASSIVE/SGD read-only adapters, runtime-media rejection, explicit license promotion, `--adapt-dataset` CLI | **Migrated**: `PsychopatzCore:tests/test_s10r1_c5_variation_adapters_specs.py` |
| `test_dialogue_dataset.py` | 8 | `compile_dialogue_dataset`, `render_dialogue_lua`, `render_dialogue_translation`, negative-example isolation | **Migrated**: `PsychopatzCore:tests/test_s10r1_dataset_and_workflow.py` (`test_dialogue_dataset_compiler_and_rendering_contract`) |
| `test_dialogue_variation_auditor.py` | 7 | `MAX_PHRASES_PER_STYLE=16`, empty/over-limit rejection, normalization, classification, `audit_corpus` + `--variation-audit` CLI | **Repaired + Migrated**: repaired `variation_auditor.py` for canonical `convo_engine` corpus (`510` families / `1002` styles); tested in `test_s10r1_c5_variation_adapters_specs.py` |
| `test_f4_semantic_lab_acceptance.py` | 1 | Backstory spec compilation + live NPC backstory/follow worker turn + inspector | **Migrated**: `ProjectHoomans:tools/providers/pnc/tests/test_s10r1_worker_precision_and_history.py` |
| `test_interaction_spec.py` | 12 | Typed block graph validation, wrong-edge rejection, `edit_interaction_graph`, preview/approval gate, `compile_interaction_spec` | **Repaired + Migrated**: `interaction_generation.py` defaults to `convo_engine`; tested across `test_s10r1_c5_variation_adapters_specs.py` and `test_s10r1_worker_precision_and_history.py` |
| `test_modular_dataset_authoring.py` | 4 | Real canonical dataset list/load/preview without legacy paths + live worker backstory/follow turns | **Migrated + retired stale IDs**: split cleanly across `test_s10r1_dataset_and_workflow.py` and `test_s10r1_worker_precision_and_history.py` |
| `test_v1_visual_authoring.py` | 1 | Backstory/action spec compile + inspector inspection on real worker | **Migrated**: `ProjectHoomans:tools/providers/pnc/tests/test_s10r1_worker_precision_and_history.py` |

**Gate:** no still-supported public/service responsibility has lost acceptance merely because an old test file was deleted.

### S10R2 — make Feature Acceptance Registry discovery complete

1. Discover supported top-level argparse actions in addition to `convo` subcommands.
2. Normalize aliases/groups so one user action does not create duplicate ownership records.
3. Require every supported public GUI/CLI/agent action to have:
   - stable action/control ID;
   - canonical operation/capability;
   - provider applicability;
   - mutation class;
   - real acceptance owner.
4. Support an explicit deprecated/unsupported classification only when the action is no longer advertised as supported.
5. Add negative tests proving a newly added public CLI option fails registry validation until ownership is supplied.

**Gate:** adding an uncovered supported public CLI/UI action fails validation.

### S10R3 — make canonical acceptance genuinely green and reproducible

1. Run all nine mandatory suites through the canonical `--acceptance` command.
2. Fix S10-owned failures.
3. For unrelated failures, require explicit reviewed baseline records with reason, owner, provenance, and stable classification; do not infer unrelated status from filename alone.
4. Keep `convoScopeOk` as diagnostic metadata only; it must not override mandatory suite failure.
5. Verify the accepted report against the exact participant vector.
6. Preserve the strict real-local-save skip policy.

**Gate:** the canonical one-command acceptance returns success with zero unexplained failures/skips and its report can be reproduced from the recorded checkpoint.

### S10R4 — dynamic lifecycle coverage and final closure

1. Derive lifecycle-tested selections from current manifest/preset discovery rather than a hard-coded expected tuple.
2. Require every supported non-alias worker-bearing selection to run start/capabilities/request/restart/reconfigure/shutdown acceptance as applicable.
3. Re-run retained S9/S9R and S10A identity/worker gates.
4. Reconcile `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md`, `SEMANTIC_HARNESS_AUDIT.md`, and this document only after the complete matrix is green.
5. Commit changed adopter repositories first, Core last, using exact phase-owned staging.
6. Record exact participant commits and residual dirty-work fingerprints.
7. Do not push or publish.

**Gate:** only after S10R1-S10R4 pass may S10 return to developer-complete / USER_ACCEPTANCE.

## Non-goals

- Do not redesign the accepted S0-S9R six-port ConvoEngine architecture without new evidence.
- Do not reopen S10A's identity realization implementation merely because the closure phase was wrong.
- Do not make old tests pass by recreating obsolete architecture when the public surface should instead be retired.
- Do not hide failures by deleting tests, widening skip policy, treating `convoScopeOk` as overall success, or broadening unrelated-baseline allowlists without proof.
- Do not hard-code future provider names into Core acceptance.
- Do not mutate user saves or launch native Project Zomboid as part of developer acceptance.

## Final completion boundary

S10 is developer-complete only when:

1. S10A remains green;
2. every still-supported public dataset/workflow/adapter/interaction surface has current acceptance ownership;
3. Feature Acceptance Registry discovery covers all supported public GUI/CLI/agent actions;
4. all supported manifest-selected providers automatically enter lifecycle acceptance;
5. the canonical nine-suite `--acceptance` workflow returns success from the recorded participant checkpoint;
6. every skip/baseline is explicitly classified and reviewed;
7. final docs contain no stale failure text, contradictory phase state, or placeholder checkpoint IDs;
8. accepted phase changes are committed locally with exact participant vector and residual-work fingerprints;
9. no automatic push or Workshop publication occurs.

Only then may the handoff return to native Project Zomboid user acceptance.
