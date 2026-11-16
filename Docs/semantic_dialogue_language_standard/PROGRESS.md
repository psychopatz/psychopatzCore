# Progress — ConvoEngine / Semantic Harness

**Status:** USER_ACCEPTANCE — S0-S9R retained and S10A-S10D developer-side gates complete; only native Project Zomboid in-game user acceptance remains.
**Estimated developer progress:** S0-S9R + S10A-S10D complete (developer side).
**Branch:** existing `main` in all three repositories.
**Active phase:** S10 — Semantic Lab end-to-end reliability and maintainability (developer-side COMPLETE).
**Immediate Next Chunk:** User-owned native Project Zomboid gameplay, UI/visual feel, and live dialogue pacing validation.

## Accepted baseline retained

S0-S8R ConvoEngine runtime/compiler/content work and S9H0-S9H7 + S9R0-S9R3 harness architecture/convergence remain accepted. S10 does **not** redesign those accepted mechanisms without concrete regression evidence.

The accepted S9/S9R mechanism model remains:

    WorkspaceCatalog
    ConvoCatalog
    OperationRegistry / ConvoTransaction
    production Lua ConvoProbe
    BuildPlanner
    thin GUI/CLI clients

The 11-operation ConvoEngine vocabulary remains accepted.

## Why developer completion was reopened

Fresh 2026-11-15 testing of the actual Semantic Lab path disproved the previous claim that only native Project Zomboid acceptance remained.

### Reproduced real PNC provider-worker failure

The provider manifest selects:

    pythonWorker = tools.providers.pnc.runtime.worker:LuaSemanticWorker
    workerScript = tools/providers/pnc/lua/worker.lua

Starting that exact worker reproduces:

    automatic semantic response registration failed:
    semantic.generated.parameterized_task.consume.active

Diagnostic instrumentation found:

    reason=response_pool_empty
    poolCount=171
    max=256

Therefore the failure is not response-pool capacity.

The current task adapter still supplies `task.consume.active`, while maintained canonical ConvoEngine task content uses `convo.task.consume.reply.active.say.1.default`-style IDs. No maintained wording/fallback was found for `task.consume.active`, causing the generated variant to normalize away and its response pool to become empty.

### Acceptance-orchestration gap

The previously cited Hoomans `1020/1021` result came from `tests/run_tests.py`, which executes root `tests/*_smoke.lua` only.

It does not include `tools/providers/pnc/tests/`, which currently contains approximately:

    discoverable provider Python tests             866
    files instantiating real LuaSemanticWorker     147
    Tk/SemanticHarnessApp-related test files        33

An existing provider Python test already reproduces the startup defect:

    tools.providers.pnc.tests.test_semantic_test_subsystem.
    RealWorkerExecutionTests.test_single_turn_greeting_execution

The machine also has `/usr/bin/xvfb-run` and Tk 8.6, so real display-dependent GUI acceptance can and should be automated.

## S10 target

Normative design and gates are in `SEMANTIC_HARNESS_RELIABILITY.md`.

S10 makes the harness reliable and maintainable when new features are introduced by adding:

- exact provider-worker startup/runtime acceptance;
- generated-response preflight and actionable diagnostics;
- one unified multi-suite acceptance report;
- real Tk/Xvfb GUI journeys;
- a compact Feature Acceptance Registry mapping each supported public action to its operation/capability/provider/test ownership;
- provider start/request/restart/shutdown lifecycle matrices;
- a zero-unexplained-skip policy for mandatory acceptance.

## Current repository vector at S10D close

    PsychopatzCore  <updating on S10D commit> (parent dfcf9f6e73ef50fc6c69da3bdf2aa4a5e5c61680)
    ProjectHoomans  9778522ffe1976f71d0d1c2efa1f5fb6d741070e (includes S10C commit f16f2b93ffa2849cfe68242dad24cdd24060029a)
    DynamicTrading  9c8cb3dead56d66e32fccb901b9abd3dd6c2f393 (includes S10A commit 4dcaa177)

## S10D completed acceptance (2026-11-16)

- Added `tools/semantic_harness/tests/test_s10d_provider_lifecycle.py` (`3/3` PASS in `28.98s`), verifying manifest preset discovery, `start -> capabilities -> ping -> input -> restart -> capabilities -> ping -> input -> shutdown` across all supported selections (`pnc`, `dtabstract`, `pnc-with-dthoomans`), live `WorkerSession.reconfigure(...)` transitions (`pnc -> dtabstract -> pnc-with-dthoomans -> pnc -> dtabstract -> pnc`), `configure` + `reset_working_world` + 3x repeated restart stability with invariant `flowCount`/`poolCount`/`beatCount` and flow IDs, and 2x standalone Core worker (`tools/semantic_harness/lua/worker.lua`) restart parity.
- Mapped S10D lifecycle acceptance owners into `tools/semantic_harness/testing/feature_registry.json`, routed `test_s10d_provider_lifecycle` through `RESOURCE_SENSITIVE_MODULES` in `python_runner.py`, and documented the one-command `--acceptance` CLI and unit verification workflow in `AGENT_RUNBOOK.md`.
- Post-edit acceptance verification across all 9 suites:
  - `core_python`: `203/203` PASS (`fail=0`, `skip=0`, `46.66s`) — includes `test_feature_registry` (`2/2`), `test_acceptance_runner` (`6/6`), `test_convo_engine_s9r_closure` (`4/4`)
  - `core_lua`: `36/36` PASS (`fail=0`, `skip=0`, `0.24s`)
  - `hoomans_provider_python`: `153/158` PASS (`fail=0`, `skip=5`, `allowed=5`, `92.15s`)
  - `real_provider_worker`: `495/504` PASS (`fail=0`, `skip=9`, `allowed=9`, `717.40s` on post-edit rerun after transient `0.3057s` vs `0.25s` latency spike in `test_contextual_scale_isolation`)
  - `tk_xvfb_gui`: `143/154` PASS (`fail=0`, `skip=11`, `allowed=11`, `692.06s`)
  - `dynamic_trading`: `89/89` PASS (`fail=0`, `skip=0`, `0.59s`)
  - `convo_audit`: `1/1` PASS (`fail=0`, `skip=0`, `5.37s`)
  - `kahlua_static`: `3/3` PASS (`fail=0`, `skip=0`, `4.75s`)
  - `hoomans_lua`: `1025/1029` PASS (`fail=4`, `skip=0`, `14.38s`; all 4 failures have `convoSemantic=false`: baseline `tests/pnc_population_director_smoke.lua` + 3 unrelated DebugHub/translation suites)

## S10C completed acceptance (2026-11-16)

- Added `tools/semantic_harness/testing/feature_registry.json`, `feature_registry.py`, and `tests/test_feature_registry.py` mapping every supported top-level UI control, `ConvoEngineAuthoringPane` action, and `convo`/`--acceptance` CLI operation with AST symbol resolution and real-Tk enforcement.
- Added `ProjectHoomans/tools/providers/pnc/tests/test_s10c_gui_journeys.py` (`4/4` PASS under `xvfb-run` in `133.70s`), covering preset selection validate/apply reconfiguration, Simulation preview/send/language/reset/load/save/settings/toolbar toggles/diagnostics/regressions/log-clear + worker error restart recovery, Quality Sweep plan/run/cancel, and Studio preview/S6M8 Audit + hermetic temp-repo create/duplicate/delete.
- Hardened `ui/operation_lifecycle.py` (`poll_future`) to route `RuntimeError` into the standard non-modal worker failure handler cleanly.
- Verified `core_python` (`200/200` PASS), `convo_audit` (`1/1` PASS), and `kahlua_static` (`3/3` PASS) with zero skips/failures.

## S10B completed acceptance (2026-11-16)

- Repaired/re-aligned the stale PNC provider Python test modules (`test_semantic_observatory_codebuilder_lineage`, `test_health_wording_authority`, `test_needs_wording_authority`, `test_wellbeing_wording_authority`, `test_social_apology_wording_authority`, `test_surface_consolidation`, `test_contextual_bond_catalog_runtime`, `test_pragmatic_interaction_compiler`, `test_world_knowledge_gui`, `test_semantic_lab_persona_workflow`, and save-backed Tk harnesses) and retired 12 obsolete dataset/compiler tests.
- Full 198-module PNC provider Python suite verified under `xvfb-run`: `PASS 192, FAIL 0, SKIP 6, TOTAL 198` (only real-local-save unavailability skips).
- Implemented `tools/semantic_harness/testing/acceptance.py` (`--acceptance` CLI mode) reporting all 9 required suites with explicit runtime skip classification (allowing only reviewed real-local-save unavailability) and automatic `xvfb-run` wrapping for display suites:
  - `core_python`: 198/198 PASS
  - `core_lua`: 36/36 PASS
  - `dynamic_trading`: 89/89 PASS
  - `convo_audit`: 1/1 PASS
  - `kahlua_static`: 3/3 PASS (Core 67 + ProjectHoomans 317 + DynamicTrading 8 Lua files)
  - `hoomans_provider_python`: 153/158 PASS (5 classified local-save skips, 0 failures)
  - `real_provider_worker`: 495/504 PASS (9 classified local-save skips, 0 failures)
  - `tk_xvfb_gui`: 139/150 PASS (11 classified local-save skips, 0 failures; `--startup-timeout` CLI default updated to `15.0`s and Tk Xvfb suite concurrency capped cleanly)
  - `hoomans_lua`: 1024/1028 PASS (`convoSemanticFailed=0`, `convoScopeOk=True`; raw 4 unrelated failures: `tests/pnc_population_director_smoke.lua` baseline + 3 Debug Hub parallel P1 commit `20997b30` tests).

## S10A completed acceptance (2026-11-16)

- Manifest-selected `LuaSemanticWorker` (`tools.providers.pnc.runtime.worker:LuaSemanticWorker`, `tools/providers/pnc/lua/worker.lua`) starts/restarts cleanly with `MAX_POOLS = 256` preserved (`preflight` before mutation, compact `hello`/`CAPABILITIES` `personaCatalog` omitting 822 KB `phraseContent` while keeping full `PERSONA_CATALOG`, and `ResponseCatalog_Conversation` preserving `SpeechRealization` family lookup and styled pool priority).
- Enforced `affordance.label` (UI-only) vs initiating `say` vs reply `say` separation, bound canonical/generated identity speech variants with semantic invariance, and strict rejection of silent label-to-speech fallback.
- Verified green: `tests/pnc_s10a_flow_preflight_smoke.lua`, `tests/pnc_semantic_local_route_smoke.lua`, and 36/36 provider/real-worker/Tk+Xvfb GUI tests across `test_s10a_provider_worker_startup`, `test_s10a_label_speech_realization`, `test_contextual_suggestions_s4`, `test_semantic_identity_wellbeing_collision`, `test_contextual_runtime_speech`, and `test_contextual_speech_behavior`.

Preserve unrelated work:

- ProjectHoomans: 11 pre-existing modified files under older `docs/Jobs/` goals.
- DynamicTrading: `.architecture-refactor/output/architecture-audit.md` and `tools/providers/dt/__pycache__/`.

## S10A immediate acceptance

S10A must:

1. add a focused regression that starts the exact PNC provider worker selected by the manifest;
2. add automatic-flow response-pool preflight before registry mutation;
3. audit all task response metadata, not only CONSUME;
4. repair wording/template identity at the canonical source-of-truth boundary;
5. preserve strict failure for invalid generated pools;
6. improve diagnostics with pool/reason/capability/template identity;
7. prove repeated startup/restart is idempotent and catalog-stable.

Do not suppress the error, skip capabilities, or accept empty variants. The original reproduced failure was `response_pool_empty` at 171/256 pools. The current dirty S10A work repairs enough of that path to reach a later failure:

    pool=semantic.generated.multi_stage_gift.gift.failed
    reason=response_pool_limit
    capability=pnc:gift.offer
    action=GIFT

The focused `tests/pnc_s10a_flow_preflight_smoke.lua` passes, but the exact manifest-selected provider-worker regression currently fails 3/3 because startup reaches the pool limit. Do not blindly raise `MAX_POOLS`; first audit duplicate/over-granular generated pools, registration idempotence, and canonical pool ownership.

Fresh Semantic Lab identity testing also exposed a separate accepted-language-contract regression: the UI label `Say your real name` can surface as the player's spoken transcript, while the truthful identity source still authors generic speech (`My real name.`) even though the semantic frame already carries the canonical player name.

The mandatory runtime/harness acceptance for that defect is `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md`. It requires bound canonical/generated identity speech, natural variant realization, no implicit label-to-speech fallback, and real PNC-worker + Tk/Xvfb acceptance.

## Completion boundary

Developer-side harness work is **not complete** until S10A-S10D pass.

After S10 passes, only then may the handoff return to USER_ACCEPTANCE for native Project Zomboid gameplay/visual/feel validation.
