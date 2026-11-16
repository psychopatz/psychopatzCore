# Semantic Harness Reliability and Maintainability

**Goal:** Make the Semantic Harness / Semantic Lab reliable enough that a newly introduced feature cannot be considered complete until its real runtime path and, when user-facing, its real GUI path are automatically exercised.

**Active phase:** S10 — Semantic Lab end-to-end reliability and feature acceptance.

`LANGUAGE_SPEC.md` remains the normative semantic/authoring contract. `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md` defines the mandatory runtime/harness proof for UI-label versus spoken-realization separation, starting with the ProjectHoomans identity exchange.

## Why S10 exists

S9/S9R successfully converged the harness architecture, but its final acceptance matrix overclaimed developer completion because it did not include the full ProjectHoomans provider Python/GUI suite.

Fresh 2026-11-15 audit evidence:

- the real PNC provider worker used by Semantic Lab fails during startup;
- `tools.providers.pnc.tests.test_semantic_test_subsystem.RealWorkerExecutionTests.test_single_turn_greeting_execution` reproduces the same failure;
- ProjectHoomans `tests/run_tests.py` runs only root `tests/*_smoke.lua` and therefore did not execute the provider Python/GUI suite;
- `tools/providers/pnc/tests/` currently contains about 866 discoverable Python tests;
- 147 provider test files instantiate the real `LuaSemanticWorker`;
- 33 provider test files contain Tk/SemanticHarnessApp GUI coverage;
- Xvfb (`/usr/bin/xvfb-run`) and Tk 8.6 are available, so real GUI acceptance can be automated instead of silently skipped.

The reproduced worker failure is:

```text
automatic semantic response registration failed:
semantic.generated.parameterized_task.consume.active
```

Diagnostic instrumentation proved the real registration reason is:

```text
reason=response_pool_empty
poolCount=171
max=256
```

This is not a response-pool-capacity failure.

The current task adapter still authors legacy response template IDs such as `task.consume.active`, while canonical ConvoEngine task wording uses identities such as `convo.task.consume.reply.active.say.1.default`.

No maintained wording/fallback was found for `task.consume.active`. The automatic generator consequently creates a pool whose only variant normalizes away because it cannot resolve text.

### Current dirty S10A progression — 2026-11-16

The in-progress S10A preflight/wording changes now move beyond that original empty-pool failure. The focused Lua preflight smoke passes, while the exact manifest-selected PNC provider-worker regression currently reaches:

```text
pool=semantic.generated.multi_stage_gift.gift.failed
reason=response_pool_limit
capability=pnc:gift.offer
action=GIFT
```

The exact worker test currently errors 3/3 at startup. This newer failure does not retroactively make the original `CONSUME` diagnosis wrong; it means the current repairs expose a later registration boundary. Do not blindly raise `MAX_POOLS`. First audit automatic pool uniqueness/granularity, repeated-registration idempotence and canonical ownership.

Fresh Semantic Lab identity testing also exposes a separate runtime realization defect covered by `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md`: the UI label `Say your real name` can become the player transcript even though the semantic frame already owns the authoritative name.

## Reliability contract

A harness feature is not developer-complete merely because its CLI/service/controller function has unit tests.

For every supported feature, acceptance must prove the real path that users or agents invoke:

```text
GUI or CLI action
  -> canonical operation/session boundary
  -> selected provider composition
  -> real provider Python worker when one is declared
  -> real production Lua worker/runtime
  -> bounded result/error
  -> user-visible projection or machine result
```

A GUI-exposed capability additionally requires a real Tk/Xvfb acceptance case unless the feature is explicitly classified as presentation-only and covered by an equivalent real-surface test.

No mandatory acceptance suite may silently disappear because `DISPLAY` is absent when Xvfb is available.

## Stable acceptance layers

Keep test responsibilities explicit rather than treating one giant count as proof of the whole harness.

### Layer A — Core mechanism tests

Covers provider-neutral harness mechanisms:

- workspace/provider discovery;
- worker/session/process lifecycle;
- OperationRegistry and ConvoTransaction;
- ConvoCatalog / ConvoProbe / BuildPlanner;
- deterministic audit/build behavior;
- Core GUI composition helpers.

These tests prove mechanisms, not adopter runtime acceptance.

### Layer B — adopter runtime tests

Every provider that declares a Python worker and/or provider worker script must have mandatory startup/runtime acceptance using that exact selected-provider path.

For PNC this means the path selected from `provider.json`:

```text
tools.providers.pnc.runtime.worker:LuaSemanticWorker
tools/providers/pnc/lua/worker.lua
```

A Core neutral worker using PNC metadata is not equivalent evidence.

### Layer C — real GUI acceptance

Run real Tk under Xvfb and exercise supported user journeys through widgets/controllers, the real session queue and selected provider worker.

Assertions should prefer semantic/UI state over pixel snapshots:

- widget/surface exists and is mapped when expected;
- control is enabled only when its preconditions are satisfied;
- invoking the control reaches the canonical operation/runtime seam;
- the real worker returns or fails with an actionable bounded error;
- the intended UI model/projection changes;
- no unexpected modal/error occurs;
- mutating authoring tests use isolated temporary fixture repositories.

Screenshots may be captured on failure for diagnosis but are not the primary oracle.

### Layer D — provider/lifecycle matrix

For every supported provider composition, exercise:

```text
discover
start
capabilities
basic read-only request
restart
capabilities again
reconfigure when supported
restart again
shutdown
```

At minimum cover currently supported Core, PNC, DTAbstract, and DTHoomans selections when their manifests advertise them.

Repeated start/restart must not accumulate duplicate registration, mutate canonical source, or produce registry drift without a declared source change.

### Layer E — source/build/static acceptance

Retain:

- canonical ConvoEngine validation;
- deterministic generation/audit;
- Kahlua/static verification;
- source/save immutability;
- exact Git/worktree verification.

## Feature Acceptance Registry

S10 introduces a compact, machine-readable feature acceptance registry owned by the harness.

Every maintained user-facing or agent-facing harness feature must have one stable feature ID and declare enough metadata to answer:

- what surface exposes it;
- whether it is GUI, CLI, agent/API, or shared;
- what canonical operation/worker capability it depends on;
- whether it mutates source/runtime state;
- what provider compositions apply;
- which automated acceptance case proves its real path;
- whether a display/save/external fixture is required;
- whether the feature is mandatory or compatibility-only.

Example identities:

```text
worker.start
worker.restart
worker.snapshot
simulation.open_conversation
simulation.preview
simulation.send
simulation.reset_world
simulation.change_language
quality_sweep.plan
quality_sweep.run
quality_sweep.cancel
quality_sweep.replay
studio.convo.catalog
studio.convo.create
studio.convo.simulate
studio.convo.write
studio.convo.delete
studio.convo.audit
world.discover_saves
world.inspect
world.import
```

The exact schema and file location are implementation decisions, but there must be exactly one canonical registry rather than independent GUI/CLI inventories.

### Registry gate

Acceptance fails when:

- a supported public action has no registry entry;
- a mandatory registry entry has no automated acceptance case;
- a registered acceptance test no longer exists;
- a GUI feature has only a service/CLI test but no real-surface case;
- a declared provider requirement is not exercised by its provider matrix;
- a mandatory test is skipped without an explicit, reviewed reason.

New features therefore extend a small manifest plus their focused test instead of requiring maintainers to remember an undocumented checklist.

## S10A — real PNC worker startup and automatic-flow integrity

### Objective

Restore the actual PNC provider worker and eliminate the metadata/content mismatch that creates an empty generated response pool.

### Required work

1. Freeze the reproduced provider-worker failure in a focused regression that instantiates the exact manifest-selected PNC worker.
2. Add an automatic-flow preflight that validates generated response pools/variants before registry mutation.
3. Audit all parameterized task response metadata (`GIVE`, `EAT`, `DRINK`, `REFILL`, `CONSUME`, plus specialized task families) against canonical ConvoEngine wording authority.
4. Fix the source of truth so generated response pools reference maintained canonical wording identities or an explicit bounded fallback contract.
5. Do not patch only `CONSUME.active`; prove all generated pools are non-empty and resolvable.
6. Preserve strict failure for invalid generated pools. Do not ignore failures, silently skip actions, inflate pool limits, or accept empty variants.
7. Improve failure diagnostics to include at least pool ID, returned registration reason, capability/action, and template/realization identity.
8. Audit worker production-module loading for safe idempotence/re-entry. The use of `dofile()` versus `require()` is not presumed to be this failure's cause, but repeated worker startup must be proven safe.
9. Enforce the existing language contract that a conversational `affordance.label` is UI-only and may not silently substitute for initiating `say`.
10. Migrate the truthful/generated identity choices to bound typed identity claims whose canonical/generated name is realized through `say`, with healthy natural wording variation and unchanged semantic meaning.
11. Add the real-worker identity click regression defined in `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md`.
12. Audit maintained affordance projections for accidental label/text fallback coupling without rewriting intentional explicit label/speech equality.

### Gate

- exact PNC provider worker starts successfully through `LuaSemanticWorker`;
- its hello/capabilities contract succeeds;
- all generated automatic response pools contain at least one valid variant;
- repeated start/restart does not change pool/flow counts without source changes;
- the focused real-worker semantic test passes;
- the truthful/generated identity choices pass bound-name realization tests and never use the UI label as implicit speech;
- the maintained label/speech projection audit has no unexplained fallback coupling.

## S10B — unified test orchestration

### Objective

Make the accepted test command/report represent the actual harness rather than only the root Lua smoke suite.

### Required work

Create or extend a bounded top-level acceptance runner/report that includes, as distinct suites:

- Core Python Semantic Harness;
- Core relevant Lua;
- ProjectHoomans root Lua smoke suite;
- ProjectHoomans provider Python suite;
- mandatory real-worker provider acceptance;
- real Tk/Xvfb GUI acceptance;
- DynamicTrading suite;
- unified ConvoEngine deterministic audit;
- Kahlua/static verification.

Report per suite: total, passed, failed, skipped, expected/allowed skips, duration, and bounded failure summary.

Do not collapse unrelated suites into one misleading count.

The existing PopulationDirector root-Lua baseline may remain separately classified only while fresh dependency/Git evidence continues to prove it unrelated.

### Skip policy

- mandatory harness tests: zero unexplained skips;
- display-required tests: run under Xvfb when available;
- save-dependent tests: use hermetic fixtures where possible; otherwise report as explicit environment-dependent coverage rather than silently treating them as pass;
- intentionally compatibility-only tests must be labeled as such.

## S10C — maintainable real GUI acceptance

### Objective

Make GUI reliability automatically follow feature growth.

### Required work

1. Create the Feature Acceptance Registry described above.
2. Inventory current supported top-level GUI actions across World & Mods, Simulation, Quality Sweep, Studio, and actionable Log/developer diagnostics.
3. Map each action to its canonical controller/operation/capability and acceptance case.
4. Add real Tk/Xvfb journeys for the highest-value end-to-end paths.
5. Use shared GUI test helpers for isolated UI state, deterministic worker readiness, operation completion, modal/error capture, widget lookup by stable feature ID, and clean worker/session shutdown.
6. Avoid brittle pixel coordinates and private widget-tree assumptions where a stable feature ID/controller seam can be exposed.
7. Source-writing GUI tests must use temporary fixture repositories or explicitly isolated generated outputs; never mutate the user's live canonical sources.
8. Add coverage checks so introducing a supported GUI action without registry/test ownership fails acceptance.

### Minimum real GUI journeys

At minimum automate:

- app start -> real PNC worker ready;
- provider selection/reconfiguration -> worker ready;
- conversation open -> native response channel visible;
- pending identity exchange -> click `Say your real name` -> transcript emits a natural bound-name `say` realization while trace retains the canonical typed identity claim;
- preview/send -> result and trace update;
- restart worker -> ready again with stable catalogs;
- ConvoEngine catalog/select/simulate/audit;
- isolated ConvoEngine create/write/delete transaction;
- quality sweep plan/run/cancel/replay smoke;
- saved-world discover/inspect/import using hermetic fixture data;
- expected worker failure -> actionable error -> restart/recovery.

## S10D — lifecycle, maintainability and final closure

### Objective

Prove the harness remains reliable under repeated use and leave a compact maintenance contract for future agents.

### Required work

1. Run the provider/lifecycle matrix across all supported manifest selections.
2. Repeat startup/restart enough times to expose stale globals, duplicate registration, resource leaks or registry drift.
3. Verify feature-registry coverage is complete and bounded.
4. Remove redundant test entrypoints only when the canonical acceptance runner supersedes them and caller-zero is proven.
5. Keep the acceptance runner modular: provider-specific suites remain provider-owned; Core orchestrates contracts rather than importing adopter policy.
6. Document the one-command developer acceptance workflow and smaller focused commands for local iteration.
7. Reconcile ROADMAP/PROGRESS/HANDOFF/AUDIT only after the complete real-path matrix is green.

## Maintainability constraints

- Do not build a second GUI automation framework if shared Tk helpers can express the journey.
- Do not duplicate operation semantics in test code; use canonical operations/controllers and inspect their observable results.
- Do not move adopter-specific runtime policy into Core just to simplify tests.
- Do not make tests depend on the user's real save or canonical source tree when a hermetic fixture can prove the contract.
- Prefer stable feature/action IDs over button text or pixel locations.
- New provider manifests must automatically enter provider-start/lifecycle acceptance.
- New supported GUI/CLI actions must automatically enter feature-coverage validation.
- Test manifests/registries must remain compact enough for Luna-class agents to understand without reading the entire UI codebase.
- Failure output must identify the failed layer, provider, feature ID, operation and underlying reason when available.

## S10R — acceptance integrity repair

The original S10A runtime/identity implementation remains accepted. Post-completion audit reopened the S10B-S10D acceptance and closure claims.

Normative repair requirements are in `S10_ACCEPTANCE_INTEGRITY_REPAIR.md`.

S10R adds these reliability requirements:

1. Test removal requires parity replacement or proven retirement/caller-zero; a green suite obtained by deleting coverage for still-supported surfaces is not acceptance.
2. Feature Acceptance Registry discovery must cover all supported public GUI, top-level CLI, subcommand and agent-facing actions, not only a selected parser subset.
3. Public actions that remain in `--help` are supported surfaces unless explicitly deprecated/removed; broken compatibility surfaces must either be repaired to current canonical sources or removed from the public interface.
4. `convoScopeOk` is diagnostic metadata only. It cannot convert a failed mandatory suite into accepted overall status.
5. Unrelated baseline allowances require explicit reviewed machine-readable classification and provenance; unexplained failures are never silently accepted.
6. Provider lifecycle acceptance must derive worker-bearing selections from manifest/preset discovery. Hard-coded provider tuples are insufficient for the maintainability contract.
7. Final acceptance must reproduce from the recorded participant checkpoint. Dirty work may be preserved, but it must be fingerprinted and may not silently contribute to an accepted committed result.
8. Final HANDOFF must contain exact participant commits and no placeholder IDs.

## Completion gate

S10 is complete only when all of the following are true:

1. the exact PNC provider worker used by the GUI starts and restarts reliably;
2. automatic generated response pools are preflight-valid and canonically worded;
3. the complete provider Python suite is a first-class acceptance gate rather than an unrun side suite;
4. real Tk/Xvfb GUI journeys cover all mandatory feature classes;
5. Feature Acceptance Registry discovery and validation prove every supported public GUI/top-level-CLI/subcommand/agent action has acceptance ownership;
6. every supported non-alias worker-bearing provider selection discovered from current manifests automatically enters start/request/restart/reconfigure/shutdown lifecycle acceptance as applicable;
7. removed/replaced tests satisfy parity-replacement or caller-zero retirement proof;
8. mandatory skips/baselines are zero or explicitly machine-classified and reviewed, and no mandatory suite is promoted from FAIL merely because a narrower scope diagnostic is green;
9. the canonical nine-suite `--acceptance` command returns success from the recorded participant checkpoint;
10. the existing Core/DT/Hoomans Lua, deterministic audit and Kahlua gates remain green apart from separately proven unrelated baselines;
11. final Git/HANDOFF truth is reconciled with exact participant commits, committed phase identity and residual-work fingerprints; accepted phase changes are committed locally, adopters first and Core last;
12. no automatic push or Workshop publication occurs.

Only after S10 may the project again claim that developer-side Semantic Harness work is complete and that only native Project Zomboid gameplay/visual acceptance remains.
