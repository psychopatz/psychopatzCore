# Progress — ConvoEngine / Semantic Harness

**Status:** IN PROGRESS — S10A complete and committed across Core, ProjectHoomans, and DynamicTrading; S10B unified multi-suite acceptance orchestration is active.
**Estimated developer progress:** S0-S9R retained, S10A complete, S10B-S10D remaining before developer-side acceptance closes.
**Branch:** existing `main` in all three repositories.
**Active phase:** S10 — Semantic Lab end-to-end reliability and feature acceptance.
**Immediate Next Chunk:** S10B — catalog/repair any stale/broken provider tests in `ProjectHoomans/tools/providers/pnc/tests/` and wire the Core unified multi-suite acceptance runner reporting Core Python/Lua, ProjectHoomans root Lua (explicitly classifying the unrelated `pnc_population_director_smoke.lua` baseline), ProjectHoomans provider Python + real-worker + Tk/Xvfb GUI suites, DynamicTrading suite, `audit-s6m8 --check-determinism`, and Kahlua/static verification with zero unexplained skips.

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

## Current repository vector after S10A

    PsychopatzCore  <updating on S10A commit>
    ProjectHoomans  fdee75424c93bd818b829ef82bb378a2b6343ebf
    DynamicTrading  4dcaa177bc59118e82e1681c57b742318de6fd62

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
