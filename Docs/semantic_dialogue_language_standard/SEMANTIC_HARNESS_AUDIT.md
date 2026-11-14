# Semantic Harness ConvoEngine Convergence Audit

**Original audit date:** 2026-11-14
**Post-S9 re-audit:** 2026-11-14
**Repositories:** psychopatzCore, ProjectHoomans, DynamicTrading
**Status:** PRE-S9 FINDINGS (H1-H10) AND POST-S9 RESIDUALS (R1-R5) RESOLVED (S9 + S9R ACCEPTED).

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

After S9R, only user-owned native Project Zomboid SP/MP visual/feel acceptance remains.
