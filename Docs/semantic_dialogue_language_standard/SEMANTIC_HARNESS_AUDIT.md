# Semantic Harness ConvoEngine Convergence Audit

**Original audit date:** 2026-11-14
**Post-S9 re-audit:** 2026-11-14
**Repositories:** psychopatzCore, ProjectHoomans, DynamicTrading
**Status:** S9 + S9R architecture accepted; S10 reliability/acceptance gap ACTIVE after real PNC provider-worker and GUI-path failure reproduced on 2026-11-15.

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
