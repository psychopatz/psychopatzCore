---
handoff_schema: 2
checkpoint_mode: "clean_phase_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
head: "PENDING_CORE_S9H3_COMMIT"
participant_heads: "project-hoomans=d45a2c6af097eddd5baef1e9ba94950b577bc8e6;dynamic-trading=d7c888de62d6f90dcf6746a24e5f50d7f7346e1d"
state: "ACTIVE_GOAL"
parent_status: "IN_PROGRESS"
phase: "S9 — Semantic Harness ConvoEngine convergence"
chunk: "S9H4 — compact Studio + compiler field descriptors"
evidence: "S8R_TEST_VERIFIED_BASELINE; S9_DESIGN_FROZEN; S9H0_COMPLETE; S9H1_PASS_171; S9H2_PASS_175; S9H3_CONVO_PROBE_PASS_178"
retrieval_tier: "verify"
updated_at: "2026-11-14"
---

# ConvoEngine Session Handoff

## Current truth

S0-S8R ConvoEngine compiler/runtime/content work is accepted. Do not reopen its architecture without a concrete regression.

**S9H0–S9H3 complete:**

- **S9H0:** Pinned all 13 regression locks (`test_convo_engine_s9_regressions.py`).
- **S9H1:** `WorkspaceCatalog` + `ConvoCatalog` (`171/171 OK`, `expected failures=10`).
- **S9H2:** `OperationRegistry` (11 ops) + `ConvoTransaction` (`ChangeSet` preview/apply, move semantics, dangling-ref rejection, fingerprint guard) + `HarnessContext` (`175/175 OK`, `expected failures=5`).
- **S9H3:** Core Lua `CONVO_PROBE` handler (`lua/worker/ConvoProbe.lua`, wired in Core and Hoomans workers) + Python `ConvoProbe` (`codebuilder/convo_probe.py`) with strict capability negotiation; migrated `convo_engine_studio_trace.py` onto `ConvoProbe` and deleted Python simulation & `KNOWN_ACTION_CONTRACTS` CAMP hard-coding (`test_convo_engine_s9h3_convo_probe.py`). Verified Core Python `178/178 OK (expected failures=3)` (`test_06`, `test_07`, `test_11`) and Core Lua `33/33 PASS`.

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

## Active next phase — S9H4 compact Studio + compiler field descriptors

1. Add compiler-owned `FieldDescriptor` registry + `SurfaceRegistry` (`Conversations`, `Source / Impact`, `Review`).
2. Fix `dataset_catalog.py` so missing Dataset Library sources report `exists=false, editable=false` and missing workflow datasets report `workflowReady=false` (clearing `test_06`, `test_07`).
3. Hide zero-source legacy authoring surfaces behind compatibility toggle, keep ConvoEngine as primary Conversation Studio home, and preserve unknown future fields through structured form editing.
