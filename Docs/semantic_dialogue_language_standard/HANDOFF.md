---
handoff_schema: 2
checkpoint_mode: "clean_phase_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
head: "fef242bba2c70156924a08a23d90e46bb05b5d70"
participant_heads: "project-hoomans=d45a2c6af097eddd5baef1e9ba94950b577bc8e6;dynamic-trading=d7c888de62d6f90dcf6746a24e5f50d7f7346e1d"
state: "DONE"
parent_status: "DEVELOPER_SIDE_COMPLETE"
phase: "S9 — Semantic Harness ConvoEngine convergence"
chunk: "S9H7 — Final acceptance & complexity audit (COMPLETE)"
evidence: "S8R_TEST_VERIFIED_BASELINE; S9_DESIGN_FROZEN; S9H0_COMPLETE; S9H1_PASS_171; S9H2_PASS_175; S9H3_CONVO_PROBE_PASS_178; S9H4_STUDIO_PASS_182; S9H5_CLI_PASS_185; S9H6_BUILD_PLANNER_PASS_188; S9H7_THREE_REPO_ACCEPTED"
retrieval_tier: "verify"
updated_at: "2026-11-14"
---

# ConvoEngine Session Handoff

## Current truth

S0-S8R ConvoEngine compiler/runtime/content work and S9H0–S9H7 Semantic Harness convergence are **developer-side complete** on `main` across all three repositories.

**S9H0–S9H7 completed summary:**

- **S9H0:** Pinned all 13 regression locks (`test_convo_engine_s9_regressions.py`).
- **S9H1:** `WorkspaceCatalog` + `ConvoCatalog` (`171/171 OK`, `expected failures=10`).
- **S9H2:** `OperationRegistry` (11 ops) + `ConvoTransaction` (`ChangeSet` preview/apply, move semantics, dangling-ref rejection, fingerprint guard) + `HarnessContext` (`175/175 OK`, `expected failures=5`).
- **S9H3:** Core Lua `CONVO_PROBE` handler (`lua/worker/ConvoProbe.lua`, wired in Core and Hoomans workers) + Python `ConvoProbe` (`codebuilder/convo_probe.py`) with strict capability negotiation (`test_convo_engine_s9h3_convo_probe.py`, Core Python `178/178`, Core Lua `33/33`).
- **S9H4:** Compiler `FieldDescriptor` registry (`convo_engine_fields.py`), `SurfaceRegistry`, missing dataset/workflow read-only fixes, `test_convo_engine_s9h4_studio.py` (Core Python `182/182`).
- **S9H5:** Main CLI `workspace` + `convo` subcommands (`convo_cli_ops.py` -> `OperationRegistry`), `convo_engine_cli.py` delegation, legacy schema quarantine (`allow_legacy_schema=False` default), deleted 342 lines of dead PSDL record-bucket CRUD methods in `service.py`, and `test_convo_engine_s9h5_cli.py`.
- **S9H6:** Added `BuildPlanner` (`codebuilder/build_planner.py`), `output_repositories` redirection in `codebuilder/build.py`, thread-reentrant `workspace_generation_lock` in `codebuilder/convo_transaction.py`, wired `OperationRegistry` (`convo.build.preview` / `convo.build.apply`) and `convo_engine_s6m8_audit.py` determinism checks to isolated temp staging directories, un-xfailed `test_11`, and added `test_convo_engine_s9h6_build_planner.py` (Core Python `188/188 OK`, `expected failures=0`).
- **S9H7:** Full three-repo acceptance verified:
  - Unified CLI `convo audit --check-determinism`: `566` families, `0` legacy violations, `368` isolated determinism file hashes / `0` diffs.
  - Core Python semantic harness: `188/188 PASS` (`0` expected failures).
  - Core Lua ConvoEngine / Semantic / Conversation / RuntimeRole: `36/36 PASS`.
  - `DynamicTrading` Lua suite: `89/89 PASS`.
  - `ProjectHoomans` Lua suite: `1020/1021` (only unrelated pre-existing `tests/pnc_population_director_smoke.lua:316`).
  - `pz-verify` Kahlua check on generated/shared ConvoEngine trees (`52 + 219 + 5 = 276` mod Lua files): `0` errors.

## Repository vector

    Core
    /home/psychopatz/Zomboid/Workshop/psychopatzCore
    branch: main

    ProjectHoomans
    /home/psychopatz/Zomboid/Workshop/ProjectHoomans
    branch: main (commit d45a2c6af097eddd5baef1e9ba94950b577bc8e6)
    preserve 11 pre-existing modified docs/Jobs files

    DynamicTrading
    /home/psychopatz/Zomboid/Workshop/DynamicTrading
    branch: main (HEAD d7c888de62d6f90dcf6746a24e5f50d7f7346e1d)
    preserve .architecture-refactor/output/architecture-audit.md
    preserve tools/providers/dt/__pycache__/

## Remaining user-owned boundary

- Live native Project Zomboid SP/MP visual/feel testing of ConvoEngine dialogues, UI affordances, CAMP actions, and Semantic Lab Studio GUI.
