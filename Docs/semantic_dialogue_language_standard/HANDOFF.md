---
handoff_schema: 2
checkpoint_mode: "clean_phase_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
head: "PENDING_CORE_S9H5_COMMIT"
participant_heads: "project-hoomans=d45a2c6af097eddd5baef1e9ba94950b577bc8e6;dynamic-trading=d7c888de62d6f90dcf6746a24e5f50d7f7346e1d"
state: "ACTIVE_GOAL"
parent_status: "IN_PROGRESS"
phase: "S9 — Semantic Harness ConvoEngine convergence"
chunk: "S9H6 — BuildPlanner + isolated determinism/cache/lock"
evidence: "S8R_TEST_VERIFIED_BASELINE; S9_DESIGN_FROZEN; S9H0_COMPLETE; S9H1_PASS_171; S9H2_PASS_175; S9H3_CONVO_PROBE_PASS_178; S9H4_STUDIO_PASS_182; S9H5_CLI_PASS_185"
retrieval_tier: "verify"
updated_at: "2026-11-14"
---

# ConvoEngine Session Handoff

## Current truth

S0-S8R ConvoEngine compiler/runtime/content work is accepted. Do not reopen its architecture without a concrete regression.

**S9H0–S9H5 complete:**

- **S9H0:** Pinned all 13 regression locks (`test_convo_engine_s9_regressions.py`).
- **S9H1:** `WorkspaceCatalog` + `ConvoCatalog` (`171/171 OK`, `expected failures=10`).
- **S9H2:** `OperationRegistry` (11 ops) + `ConvoTransaction` (`ChangeSet` preview/apply, move semantics, dangling-ref rejection, fingerprint guard) + `HarnessContext` (`175/175 OK`, `expected failures=5`).
- **S9H3:** Core Lua `CONVO_PROBE` handler (`lua/worker/ConvoProbe.lua`, wired in Core and Hoomans workers) + Python `ConvoProbe` (`codebuilder/convo_probe.py`) with strict capability negotiation (`test_convo_engine_s9h3_convo_probe.py`, Core Python `178/178`, Core Lua `33/33`).
- **S9H4:** Compiler `FieldDescriptor` registry (`convo_engine_fields.py`), `SurfaceRegistry`, missing dataset/workflow read-only fixes, `test_convo_engine_s9h4_studio.py` (Core Python `182/182`).
- **S9H5:** Main CLI `workspace` + `convo` subcommands (`convo_cli_ops.py` -> `OperationRegistry`), `convo_engine_cli.py` delegation, legacy schema quarantine (`allow_legacy_schema=False` default), deleted 342 lines of dead PSDL record-bucket CRUD methods in `service.py`, and `test_convo_engine_s9h5_cli.py`. Verified Core Python `185/185 OK (expected failures=1)` (`test_11` only remaining).

## Repository vector

    Core
    /home/psychopatz/Zomboid/Workshop/psychopatzCore
    branch: main

    ProjectHoomans
    /home/psychopatz/Zomboid/Workshop/ProjectHoomans
    branch: main (S9H3 commit applied)
    preserve 11 pre-existing modified docs/Jobs files

    DynamicTrading
    /home/psychopatz/Zomboid/Workshop/DynamicTrading
    HEAD d7c888de62d6f90dcf6746a24e5f50d7f7346e1d
    preserve .architecture-refactor/output/architecture-audit.md
    preserve tools/providers/dt/__pycache__/

## Active next phase — S9H6 BuildPlanner + isolated determinism/cache/lock

1. Implement `BuildPlanner` (`codebuilder/build_planner.py`) for planned preview/apply/determinism verification.
2. Isolate `convo_engine_s6m8_audit.py` determinism checks into temporary staging directories under `workspace_generation_lock` so live `media/` is never written during audit (clearing `test_11`).
3. Add concurrency & determinism isolation tests (`test_convo_engine_s9h6_build_planner.py`).
