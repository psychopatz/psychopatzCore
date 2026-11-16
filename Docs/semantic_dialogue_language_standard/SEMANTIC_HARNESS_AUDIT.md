# Semantic Harness ConvoEngine Convergence Audit

**Original audit date:** 2026-11-14
**Post-S9 re-audit:** 2026-11-14
**Repositories:** psychopatzCore, ProjectHoomans, DynamicTrading
**Status:** S9 + S9R architecture accepted; S10A accepted; S10B-S10D completion claims reopened by the 2026-11-16 S10R acceptance-integrity audit.

## Purpose

This document preserves the evidence that motivated S9 and S9R while distinguishing
historical findings from current truth.

The original H1-H10 findings below are **historical pre-S9 baseline findings**. S9H0-S9H7
materially resolved them.

The R1-R5 residuals below are also **resolved and verified by S9R0-S9R3** (`test_convo_engine_s9r_closure.py`, `192/192` Core Python).

## Original pre-S9 baseline

Before S9, the harness had these verified issues:

1. **H1 — legacy PSDL record-bucket service API remained.**
2. **H2 — Studio simulation reimplemented semantic predicate/text behavior in Python.**
3. **H3 — dynamic affordance/NPC selection was not runtime-faithful in Studio.**
4. **H4 — repository/source discovery diverged across Studio/service/audit.**
5. **H5 — ConvoEngine pane performed unsafe owner/path/delete/write behavior.**
6. **H6 — dead legacy Studio surfaces were still presented as canonical/editable.**
7. **H7 — the main Semantic Harness CLI did not expose ConvoEngine operations.**
8. **H8 — structured ConvoEngine editor coverage was partial and duplicated grammar knowledge.**
9. **H9 — deterministic audit/build could race on the live generated tree.**
10. **H10 — the public conceptual surface was larger than necessary for agents/humans.**

Measured pre-S9 review signals:

    harness Python                            71,593 LOC / 277 files
    SemanticLabAuthoringService                2,729 lines / 66 public methods
    main CLI                                   1,425 lines / 123 add_argument calls
    Studio + UI                              ~20.8k LOC

These numbers were architectural review signals, not deletion targets.

## S9 resolution evidence

S9 implemented the compact six-port model:

    WorkspaceCatalog
    ConvoCatalog
    OperationRegistry / ConvoTransaction
    production Lua ConvoProbe
    BuildPlanner
    thin GUI/CLI clients

Resolution mapping:

- **H1 resolved:** dead public record-bucket PSDL CRUD methods were removed from `SemanticLabAuthoringService`; only explicit compatibility/migration schema paths remain.
- **H2 resolved:** `convo_engine_studio_trace.py` now delegates behavioral truth to production Lua `ConvoProbe`; no Python predicate/rendering fallback remains.
- **H3 resolved:** production Lua affordance collection/scoring/NPC selection/reply/after paths are exposed through `ConvoProbe`.
- **H4 resolved:** `WorkspaceCatalog` and `ConvoCatalog` provide shared manifest/provider-driven discovery across GUI/CLI/audit/build.
- **H5 resolved:** canonical family mutation uses `ConvoTransaction` with owner routing, fingerprint checks, move semantics, dangling-reference protection and generation locking; the pane no longer directly unlinks canonical source.
- **H6 resolved:** primary Studio surfaces are `Conversations`, `Source / Impact`, and `Review`; legacy panes are compatibility-gated and missing sources are non-editable/not workflow-ready.
- **H7 resolved:** the main CLI exposes `workspace` and `convo` operations and the specialized ConvoEngine CLI delegates to shared authority.
- **H8 resolved at architecture level:** compiler-owned `FieldDescriptor` presentation metadata and unknown-field round-trip support reduce independent grammar copies; raw JSON remains an advanced escape hatch.
- **H9 resolved:** `BuildPlanner` uses isolated temporary output for determinism and a workspace generation lock for live apply.
- **H10 substantially resolved:** conversation work now has one bounded 11-operation registry even though the broader legacy service facade remains large.

Fresh post-S9 verification:

    canonical ConvoEngine families                 566
    discoverable operations                         11
    Core Python semantic-harness                   188/188 PASS
    Core Convo/Semantic/Conversation/Role Lua       36/36 PASS
    isolated determinism hashes                    368 / 0 diffs
    active legacy-name violations                    0
    DynamicTrading                                  89/89 PASS
    ProjectHoomans                                1020/1021
    Kahlua ConvoEngine trees                         0 errors across 276 files

The sole Hoomans failure remains the independent PopulationDirector baseline at
`tests/pnc_population_director_smoke.lua:316`.

## Post-S9 closure — R1–R5 resolved by S9R

All five post-S9 closure residuals have now been resolved and locked by `tools/semantic_harness/tests/test_convo_engine_s9r_closure.py`:

- **R1 resolved:** Final Core `HANDOFF.md` uses `checkpoint_mode: committed_handoff`, `phase_commit: self`, the exact participant commit vector, and residual worktree fingerprints.
- **R2 resolved:** Continuity docs (`PROGRESS.md`, `ROADMAP.md`, `SEMANTIC_HARNESS_AUDIT.md`, `AGENT_RUNBOOK.md`, `CONVO_ENGINE.md`, `HANDOFF.md`) record H1-H10 as historical pre-S9 baseline and S9 + S9R as complete/accepted.
- **R3 resolved:** `convo.simulate` `OperationDescriptor` now advertises `requiredCapability = "semantic.convo_probe"` and `workerRequirement = "required"`, preserving the 11-operation vocabulary and no-fallback `ConvoProbeUnavailableError`.
- **R4 resolved:** `HarnessContext.build` exposes the workspace-aware `BuildPlanner` instance updated on `refresh_workspace()`, and `OperationRegistry` (`convo.build.preview` / `convo.build.apply`) consumes `harness.build` with no private competing factory.
- **R5 resolved:** `ConvoEngineAuthoringPane` dispatches canonical operations (`convo.catalog`, `convo.get`, `convo.change.preview`, `convo.simulate`, `convo.change.apply`, `convo.audit`) via `dispatch_operation()` with focused parity tests.

Latest verification after S9R closure:

- `192/192` Core Python Semantic Harness (`0` expected failures)
- `36/36` Core ConvoEngine / Semantic / Conversation / RuntimeRole Lua
- `566`-family zero-violation isolated 3-repo audit (`368` determinism hashes, `0` diffs)
- `89/89` DynamicTrading
- `1020/1021` ProjectHoomans (only unrelated pre-existing `tests/pnc_population_director_smoke.lua:316`)
- `0` Kahlua errors across `276` ConvoEngine Lua files (`52` Core, `219` Hoomans, `5` DTCommon)

At S9R close, the recorded conclusion was that only user-owned native Project Zomboid SP/MP visual/feel acceptance remained. Fresh 2026-11-15 evidence below supersedes that conclusion and opens S10.


## 2026-11-15 S10 reliability re-audit

The previous post-S9 conclusion that only user-owned native Project Zomboid acceptance remained is superseded by fresh developer-side evidence.

### A1 — real PNC provider worker fails startup

The PNC manifest selects `tools.providers.pnc.runtime.worker:LuaSemanticWorker` and `tools/providers/pnc/lua/worker.lua`. Starting that exact path reproduces:

```text
automatic semantic response registration failed:
semantic.generated.parameterized_task.consume.active
```

Temporary diagnostic instrumentation preserved the repository and exposed the returned registration reason:

```text
reason=response_pool_empty
poolCount=171
max=256
```

Therefore the failure is not pool capacity. The task adapter still declares `task.consume.active`, while canonical ConvoEngine task wording uses `convo.task.consume.reply.active.say.1.default`-style identities. No maintained fallback was found for the old template ID.

### A2 — accepted Hoomans gate omitted the provider Python/GUI suite

`ProjectHoomans/tests/run_tests.py` discovers only root `tests/*_smoke.lua`. The provider suite under `tools/providers/pnc/tests/` is separate and currently contains about 866 discoverable Python tests.

Measured audit signals:

    provider test files instantiating real LuaSemanticWorker   147
    Tk/SemanticHarnessApp-related provider test files          33

An existing provider test, `RealWorkerExecutionTests.test_single_turn_greeting_execution`, already reproduces the startup failure. The prior `1020/1021` root-Lua result therefore was not complete Semantic Harness acceptance evidence.

### A3 — real GUI acceptance is automatable

The development machine has `/usr/bin/xvfb-run` and Tk 8.6. A real Semantic Lab launch under Xvfb maps the window and starts the PNC worker but never reaches worker-ready because the provider worker fails before the handshake. Display-gated tests must therefore become first-class Xvfb acceptance rather than optional skips.

### A4 — label/speech realization contract is not enforced end to end

Fresh 2026-11-16 Semantic Lab identity testing shows a visible choice labelled
`Say your real name` can become the player's transcript line. The ProjectHoomans
identity provider already carries separate label/utterance fields and the
semantic frame contains the canonical player name, but the truthful speech
fallback is still generic (`My real name.`).

This is not a missing-language-spec problem. The accepted ConvoEngine language
contract already makes `affordance.label` UI-only, `say` initiating speech, and
forbids implicit label-to-speech canonicalization. The gap is runtime projection,
binding and acceptance coverage.

`S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md` defines the mandatory regression.

### A5 — current dirty S10A work now exposes a later pool-limit failure

The focused Lua preflight smoke passes. Running the new exact manifest-selected
PNC provider-worker tests with the Core/Hoomans Python paths resolves the original
empty-CONSUME failure far enough to reach:

```text
pool=semantic.generated.multi_stage_gift.gift.failed
reason=response_pool_limit
capability=pnc:gift.offer
action=GIFT
```

The new real-worker test currently errors 3/3 at startup. This does not justify
blindly increasing `MAX_POOLS`; first prove whether the valid generated catalog
contains duplicate/over-granular pools or registration drift.

### S10 response

S10 does not reopen the six-port S9/S9R architecture. It repairs the concrete provider/runtime defect and closes the acceptance-system gap through:

- provider-exact worker startup/runtime tests;
- automatic-flow preflight and actionable registration diagnostics;
- unified multi-suite acceptance orchestration;
- a compact Feature Acceptance Registry;
- real Tk/Xvfb user journeys;
- supported-provider lifecycle/restart matrices;
- zero unexplained skips for mandatory harness acceptance.

See `SEMANTIC_HARNESS_RELIABILITY.md` for the normative design and phase gates.

## 2026-11-16 post-S10 closure audit — S10R opened

The S10 implementation materially improved the harness, and the original identity-label defect is fixed. Fresh independent reruns nevertheless disprove the final developer-complete/USER_ACCEPTANCE claim.

### A6 — S10A identity/worker repair is verified and retained

Fresh audit reruns pass:

    S10A provider + label/speech                 8/8
    S10C real Tk/Xvfb journeys                  4/4
    S10D provider lifecycle                     3/3
    Feature Registry + acceptance-runner unit   8/8
    pnc_s10a_flow_preflight_smoke.lua            PASS

The truthful identity choice now renders bound canonical-name speech rather than the UI label, generated aliases use the same typed mechanism, refusal remains distinct, and the GUI path rejects missing initiating speech instead of substituting the label.

This accepted S10A result is not reopened merely because later acceptance closure was incorrect.

### A7 — S10B removed acceptance for still-present surfaces

ProjectHoomans commit `5f8b5000` removed 12 provider test modules containing approximately 68 test methods while the Core modules/service/CLI seams they exercised remain present.

Those responsibilities include dataset-library, workflow, dataset-adapter, interaction-spec, variation-auditor and authoring-service behavior.

Reconstructed deleted tests expose current stale-source/schema failures. This means the tests were not proven obsolete by dead-surface/caller-zero evidence.

The repair requirement is not to blindly restore stale historical tests. Each deleted responsibility must be migrated to current canonical acceptance or its associated public/service surface must be formally retired and removed from callers/public exposure.

### A8 — Feature Acceptance Registry does not cover all supported public CLI actions

The current validator discovers `app.*_button`, a bounded Studio action set and `convo <subcommand>`. It does not discover all supported top-level argparse actions.

Verified unregistered examples:

    --list-datasets
    --search-datasets
    --show-dataset
    --validate-dataset
    --workflow-preview
    --workflow-generate
    --adapt-dataset
    --inspect-interaction-history

Fresh CLI runtime evidence shows the omission hides real breakage:

- `--list-datasets` advertises canonical sources whose current paths report `exists=false`;
- `--show-dataset common_dialogue` fails on missing `responses/common/social.json`;
- `--workflow-preview common_dialogue --workflow-blocks language.speech_act,dialogue_responses.response_pool` returns `ok=false` and exits 2.

Therefore the S10C statement that every supported public action has acceptance ownership is false until discovery/ownership is widened or those actions are explicitly retired.

### A9 — canonical acceptance and committed closure are not reproducibly green

The runbook names `python3 -m tools.semantic_harness --acceptance` as the canonical developer gate.

Fresh reruns show the mandatory `hoomans_lua` suite still reports FAIL. The exact S10D ProjectHoomans participant commit `9778522f` reruns at `1024/1029` with five failures. Only the PopulationDirector failure is currently recognized as the reviewed known unrelated baseline; the others remain `unexpected_failure`.

`convoScopeOk=true` is useful scope metadata but cannot promote a failed mandatory suite to accepted status.

The S10D handoff also records `psychopatz-core=<updating-on-S10D-commit>` instead of a resolved checkpoint, and its Hoomans count does not reproduce from the exact recorded participant commit. Later dirty/parallel work changes the root-suite result, so closure evidence was partly worktree-dependent.

### A10 — lifecycle coverage is current-set hard-coded, not manifest-complete

`test_s10d_provider_lifecycle.py` performs manifest discovery but executes a hard-coded tuple of `pnc`, `dtabstract`, and `pnc-with-dthoomans`.

That verifies the current known selections but does not enforce the stated maintainability invariant that a newly supported worker-bearing provider/preset automatically enters lifecycle acceptance.

### S10R response

S10R repairs acceptance integrity without redesigning accepted S0-S9R or S10A mechanisms.

Normative repair plan: `S10_ACCEPTANCE_INTEGRITY_REPAIR.md`.

The completion claim remains reopened until:

- deleted test responsibilities have current acceptance or proven retirement;
- all supported public actions enter Feature Acceptance Registry coverage;
- the canonical nine-suite acceptance command is genuinely green/reproducible;
- lifecycle coverage derives from manifest discovery;
- final Git/HANDOFF state contains exact participant commits and residual-work fingerprints.
