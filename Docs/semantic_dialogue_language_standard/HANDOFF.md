---
handoff_schema: 2
checkpoint_mode: "clean_phase_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
head: "PENDING_CORE_S9H4_COMMIT"
participant_heads: "project-hoomans=d45a2c6af097eddd5baef1e9ba94950b577bc8e6;dynamic-trading=d7c888de62d6f90dcf6746a24e5f50d7f7346e1d"
state: "ACTIVE_GOAL"
parent_status: "IN_PROGRESS"
phase: "S9 — Semantic Harness ConvoEngine convergence"
chunk: "S9H5 — compact main CLI + compatibility quarantine"
evidence: "S8R_TEST_VERIFIED_BASELINE; S9_DESIGN_FROZEN; S9H0_COMPLETE; S9H1_PASS_171; S9H2_PASS_175; S9H3_CONVO_PROBE_PASS_178; S9H4_STUDIO_PASS_182"
retrieval_tier: "verify"
updated_at: "2026-11-14"
---

# ConvoEngine Session Handoff

## Current truth

S0-S8R ConvoEngine compiler/runtime/content work is accepted. Do not reopen its architecture without a concrete regression.

**S9H0–S9H4 complete:**

- **S9H0:** Pinned all 13 regression locks (`test_convo_engine_s9_regressions.py`).
- **S9H1:** `WorkspaceCatalog` + `ConvoCatalog` (`171/171 OK`, `expected failures=10`).
- **S9H2:** `OperationRegistry` (11 ops) + `ConvoTransaction` (`ChangeSet` preview/apply, move semantics, dangling-ref rejection, fingerprint guard) + `HarnessContext` (`175/175 OK`, `expected failures=5`).
- **S9H3:** Core Lua `CONVO_PROBE` handler (`lua/worker/ConvoProbe.lua`, wired in Core and Hoomans workers) + Python `ConvoProbe` (`codebuilder/convo_probe.py`) with strict capability negotiation; migrated `convo_engine_studio_trace.py` onto `ConvoProbe` and deleted Python simulation & `KNOWN_ACTION_CONTRACTS` CAMP hard-coding (`test_convo_engine_s9h3_convo_probe.py`). Verified Core Python `178/178 OK (expected failures=3)` and Core Lua `33/33 PASS`.
- **S9H4:** Compiler `FieldDescriptor` registry (`convo_engine_fields.py`), `SurfaceRegistry` (`Conversations` / `Source / Impact` / `Review` primary tabs + explicit `"Show Legacy Compatibility Tools"` toggle), missing dataset/workflow read-only fixes in `dataset_catalog.py` / `DatasetLibraryPane` / `DialogueContentPane`, and `test_convo_engine_s9h4_studio.py`. Verified Core Python `182/182 OK (expected failures=1)` (`test_11` only remaining for S9H6).

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

## Active next phase — S9H5 compact main CLI + compatibility quarantine

1. Add `workspace` (`describe`) and `convo` (`operations`, `catalog`, `get`, `impact`, `validate`, `simulate`, `change`, `build`, `audit`) subcommands to main `entrypoints/cli.py` dispatching `OperationRegistry`.
2. Route `convo_engine_cli.py` onto the same `OperationRegistry` / `Service` operations without duplicating CLI logic.
3. Audit callers of dead legacy PSDL record-bucket CRUD methods in `service.py` / `tests/` and delete dead CRUD methods once caller-free; quarantine legacy shard readers behind explicit flags.
