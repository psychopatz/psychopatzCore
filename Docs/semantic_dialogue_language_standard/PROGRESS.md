# Progress — ConvoEngine

**Status:** DEVELOPER-SIDE COMPLETE (S0–S8R ConvoEngine + S9H0–S9H7 Semantic Harness convergence); ready for user native Project Zomboid SP/MP live visual/feel acceptance.
**Estimated developer progress:** 100% of developer-side ConvoEngine + Semantic Harness S9 scope.
**Branch:** existing `main` in all three repositories.
**Active phase:** S9 complete (all chunks S9H0–S9H7 verified and committed locally).
**Immediate Next Chunk:** None (developer-side S9 closed; only user-owned native PZ SP/MP verification remains).

## Accepted ConvoEngine + S9 verified summary

S0-S8R runtime/compiler/content work remains accepted and un-reopened, and S9 converged Semantic Lab and the main CLI onto ConvoEngine as the single conversation authoring, simulation, and build authority across the six target ports (`WorkspaceCatalog`, `ConvoCatalog`, `OperationRegistry` / `ConvoTransaction`, production Lua `ConvoProbe`, `BuildPlanner`, thin GUI/CLI clients).

Verified 2026-11-14 post-S9 checks:

    canonical ConvoEngine families                 566
    active psdl.* / pnc.psdl.* output violations    0
    isolated determinism audit hashes              368 / 0 diffs
    Core Python semantic-harness                   188/188 PASS (0 expected failures)
    Core Convo/Semantic/Conversation/Role Lua       36/36 PASS
    DynamicTrading Lua                              89/89 PASS
    ProjectHoomans Lua                            1020/1021 (only tests/pnc_population_director_smoke.lua:316)
    Kahlua ConvoEngine trees (52+219+5 files)        0 errors

Post-S9 harness complexity & surface metrics (excluding `.venv`/`__pycache__`):

    Python files                                  294 (added clean port modules + 6 S9 test suites)
    Python LOC                                 77,218
    codebuilder LOC                            28,351
    Studio + UI LOC                            21,279
    SemanticLabAuthoringService                  2,433 lines (down from 2,729) / 66 public methods
    entrypoints/cli.py                           1,432 lines / 124 add_argument calls

The single Hoomans failure remains `tests/pnc_population_director_smoke.lua:316`. Fresh Git/dependency evidence continues to show it is outside the ConvoEngine change surface.

Current committed heads before S9 edits:

    Core            f85bc27badb91849fe22c7b050a3d695471612b3
    ProjectHoomans  a21cfd5f806abe9075d97f9dd9c774a43127b412
    DynamicTrading  d7c888de62d6f90dcf6746a24e5f50d7f7346e1d

Preserve unrelated work:

- Hoomans: 11 pre-existing modified files under older `docs/Jobs/` goals.
- DynamicTrading: `.architecture-refactor/output/architecture-audit.md` plus `tools/providers/dt/__pycache__/`.

## Current authority model

- PsychopatzCore owns ConvoEngine schema/compiler/IR contracts, generic validation, predicates, slots/bindings, action-result contracts, package routing, CodeBuilder service and generated naming.
- ProjectHoomans and DynamicTrading own adopter content/gameplay/adapters.
- Canonical conversation source is one-family ConvoEngine JSON under `sources/conversation/{dialogue,behavior,beat,realization}/...`.
- Generated/runtime output is `<Owner>/ConvoEngine/...`.
- CodeBuilder is the authoring/generation authority. Generated Lua/translation output is downstream-only.
- Generic semantic/NLU infrastructure that is broader than conversation remains under Core `Semantics/`.
- Native Project Zomboid live SP/MP visual/feel acceptance remains user-owned.

## 2026-11-14 Semantic Harness audit

Full evidence and acceptance criteria are in `SEMANTIC_HARNESS_AUDIT.md`.

The harness supports ConvoEngine compilation and basic family authoring, but it is not yet optimally converged on the final architecture.

### Verified current strengths

- `SemanticLabAuthoringService` has ConvoEngine create/edit/move/shard/normalize/write/validate APIs.
- family discovery currently finds all 566 sources.
- compiler-owned `conversation_discovery_record()` and `conversation_affected_closure()` already exist.
- the Lua worker follows the correct thin-host pattern: Python sends commands and Lua owns semantic policy.
- production Lua already exposes Predicate, TextBinding, Affordance and ActionContract APIs needed for authoritative harness simulation.

### Verified harness defects

1. **Legacy PSDL CRUD API remains in `SemanticLabAuthoringService`.** Record-bucket `list/load/create/edit/duplicate/delete/reorder/write_psdl_*` methods are now called only by legacy tests, not the ConvoEngine pane.
2. **Studio simulation duplicates runtime policy in Python.** `convo_engine_studio_trace.py` reimplements predicates/text rendering, omits production predicate operators, and hard-codes CAMP action-contract metadata.
3. **Dynamic affordance behavior is not runtime-faithful.** Candidate providers, slot expansion, utility/relationship scoring, deterministic NPC selection, recency/cooldowns and bounded chaining are not actually exercised by the Python trace.
4. **Studio family discovery duplicates layout logic.** It scans folders and guesses sibling repositories instead of consuming the hardened compiler/manifest participant map.
5. **ConvoEngine pane CRUD is unsafe.** New files can default into Core regardless of owner, delete uses direct `Path.unlink()`, identity edits bypass move semantics, writes lack source-fingerprint guards, and regeneration is manual.
6. **Cross-reference deletion safety is incomplete.** Compiler checks semantic-reference shape and wording-key misuse but does not prove every `after.goto` / `after.recommend` target exists.
7. **Legacy Studio surfaces are dead but still primary.** Live workspace measurements: 566 ConvoEngine families, 0 Dialogue Content rows, and 4 Dataset Library sources all `exists=false` while reported `editable=true`; 3 missing workflow datasets are still reported `workflowReady=true`.
8. **The real ConvoEngine editor is buried under Developer Tools** while the top-level Studio `Dialogue Content` tab is empty.
9. **Main Semantic Harness CLI does not expose ConvoEngine authoring.** A separate `convo_engine_cli.py` exists, creating overlapping entrypoints.
10. **Structured editor coverage is partial.** Advanced final features remain raw JSON: locales, keyed realizations/styles, reply varieties, candidate providers, utility/prefer, recommend groups, goto/end/resume, execute bindings/results, beat/behavior specifics.
11. **Determinism/build is not concurrency-safe.** Two concurrent regenerating audits can race on the live generated tree; sequential runs pass.

## Compact/future-proof target frozen 2026-11-14

Normative design: `SEMANTIC_HARNESS_COMPACT_ARCHITECTURE.md`.

Fresh harness-owned measurements excluding the bundled virtualenv/caches:

    Python files                                  277
    Python LOC                                 71,593
    codebuilder LOC                            25,340
    Studio + UI LOC                           ~20,863
    SemanticLabAuthoringService                  2,729 lines / 66 public methods
    main CLI                                     1,425 lines / 123 add_argument calls

These are review signals, not arbitrary deletion targets. The target is six
stable conceptual ports:

    WorkspaceCatalog
    ConvoCatalog
    OperationRegistry / ConvoTransaction
    production Lua ConvoProbe
    BuildPlanner
    thin GUI/CLI clients

The existing `semantic.provider_manifest.v2` system remains the future-provider
extension boundary. Normal new providers/families/action contracts must become
discoverable through capability/source/runtime registration without adding Core
adopter-specific branches.

Agent-facing operations must remain bounded and search-first; ordinary work
must not require full-corpus dumps or reading the giant service/CLI modules.

## S9 phase status

- **S9H0 — regression-lock + architecture freeze: COMPLETE.** `test_convo_engine_s9_regressions.py` pins all 13 reproduced defects/invariants (16 tests, originally 12 expected failures).
- **S9H1 — WorkspaceCatalog + ConvoCatalog: COMPLETE.** Added `codebuilder/workspace_catalog.py` (`WorkspaceCatalog`, immutable bounded `WorkspaceSnapshot`, `semantic.provider_manifest.v2` conversation-source normalization, explicit override precedence, fail-closed required owners) and `codebuilder/convo_catalog.py` (`ConvoCatalog`, cached lightweight `FamilySummary` index, on-demand single-family loading, `query`/`impact`/reference validation). Migrated `SemanticLabAuthoringService`, `convo_engine_studio_trace.py`, `CanonicalSourceExplorerPane`, `convo_engine_s6m8_audit.py`, and `build.py`. Full Core Python suite verified: `171/171 OK (expected failures=10)`.
- **S9H2 — OperationRegistry + safe ConvoTransaction: COMPLETE.** Added `codebuilder/convo_transaction.py` (`ChangeSet`, `ConvoTransaction`, `atomic_write_json`, `workspace_generation_lock`, identity-change auto-move, global dangling-reference protection, stale source-fingerprint guards), `codebuilder/harness_context.py` (`HarnessContext`), and `codebuilder/operation_registry.py` (`OperationRegistry` registering all 11 versioned operations). Routed `SemanticLabAuthoringService` and `ConvoEngineAuthoringPane` CRUD/delete through `OperationRegistry` / `ConvoTransaction`, removing direct `Path.unlink()` from the pane. Added `tools/semantic_harness/tests/test_convo_engine_s9h2_transactions.py` and cleared S9H2 regression locks (`test_01`, `test_02`, `test_03b`, `test_04b`, `test_05`). Full Core Python suite verified: `175/175 OK (expected failures=5)`.
- **S9H3 — production Lua ConvoProbe: COMPLETE.** Added Core Lua `CONVO_PROBE` worker handler (`tools/semantic_harness/lua/worker/ConvoProbe.lua`, wired into `lua/worker.lua` and `ProjectHoomans` `CommandRouter`) and Python `ConvoProbe` client (`codebuilder/convo_probe.py`) with strict capability negotiation (`semantic.convo_probe`, explicit `ConvoProbeUnavailableError` with zero Python fallback). Migrated `convo_engine_studio_trace.py` (`simulate_convo_engine_family` and `list_registered_action_contracts`) to production Lua `ConvoProbe` + manifest/catalog discovery, deleting Python predicate/rendering duplication and hard-coded `KNOWN_ACTION_CONTRACTS`. Added `test_convo_engine_s9h3_convo_probe.py` and cleared S9H3 regression locks (`test_08`, `test_09`). Verified Core Python `178/178 OK (expected failures=3)` and Core Lua `33/33 PASS`.
- **S9H4 — compact Studio + compiler field descriptors: COMPLETE.** Added compiler-owned `FieldDescriptor` registry (`codebuilder/convo_engine_fields.py`, exposed via `convo_engine_authoring.py` and `SemanticLabAuthoringService.describe_convo_engine_fields()`) and `SurfaceRegistry` (`studio/surface_registry.py`), promoted ConvoEngine (`Conversations`), `Source / Impact`, and `Review` to primary Studio tabs while gating legacy panes behind `"Show Legacy Compatibility Tools"`, updated `ConvoEngineAuthoringPane` to render fields from compiler descriptors and display/preserve unknown fields, fixed `dataset_catalog.py` so missing sources report `exists=false, editable=false` and missing workflow datasets report `workflowReady=false`, disabled edits on missing sources in `DatasetLibraryPane` / `DialogueContentPane`, added `test_convo_engine_s9h4_studio.py`, and cleared `test_06` and `test_07`. Full Core Python suite verified: `182/182 OK (expected failures=1)`.
- **S9H5 — compact main CLI + compatibility quarantine: COMPLETE.** Added shared `codebuilder/convo_cli_ops.py` and unified `workspace` (`describe`) + `convo` (`operations`, `catalog`, `get`, `impact`, `validate`, `simulate`, `change preview|apply`, `build preview|apply`, `audit`) subcommands on main `entrypoints/cli.py` / `entrypoints/app.py`, delegated `convo_engine_cli.py` (`validate`, `create`, `edit`, `move`, `write`, `audit-s6m8`) onto `OperationRegistry`, quarantined legacy schema reading behind explicit opt-in (`allow_legacy_schema=False` default / `--allow-legacy`), deleted 342 lines of dead legacy PSDL record-bucket CRUD methods from `SemanticLabAuthoringService`, normalized `OperationRegistry.dispatch` `ok` envelopes, and added `test_convo_engine_s9h5_cli.py`. Verified Core Python `185/185 OK (expected failures=1)`.
- **S9H6 — BuildPlanner + isolated determinism/cache/lock: COMPLETE.** Added `codebuilder/build_planner.py` (`BuildPlanner`, `BuildPlan`), `output_repositories` redirection in `codebuilder/build.py`, thread-reentrant `workspace_generation_lock` in `codebuilder/convo_transaction.py`, routed `OperationRegistry` (`convo.build.preview` / `convo.build.apply`) and `convo_engine_s6m8_audit.py` determinism checks into isolated temporary staging directories, cleared `test_11`, and added `test_convo_engine_s9h6_build_planner.py`. Verified Core Python `188/188 OK (expected failures=0)`.
- **S9H7 — exhaustive acceptance + complexity audit: COMPLETE.** Verified Core Python `188/188 PASS`, unified CLI `convo audit --check-determinism` (`566` families, `0` legacy violations, `368` isolated determinism file hashes / `0` diffs), Core Lua Convo/Semantic/Conversation/Role (`36/36 PASS`), DynamicTrading (`89/89 PASS`), ProjectHoomans (`1020/1021`, only unrelated `pnc_population_director_smoke.lua:316`), and `pz-verify` Kahlua (`0` errors across `276` mod Lua files). Measured post-S9 metrics (`SemanticLabAuthoringService`: `2,433` lines; `entrypoints/cli.py`: `1,432` lines / `124` `add_argument` calls).

## Completion boundary — MET

Developer-side S9 is complete: Semantic Lab and the main CLI consume ConvoEngine as the single conversation authoring/simulation/build authority with owner-routed safe CRUD, production-Lua simulation/trace (`ConvoProbe`), manifest-driven `WorkspaceCatalog`/`ConvoCatalog` discovery, compatibility-gated Studio surfaces, one discoverable `OperationRegistry` CLI/service contract, concurrency-safe isolated deterministic audit (`BuildPlanner`), and all cross-repo verification suites passing cleanly. Only user-owned live Project Zomboid SP/MP playtesting remains.
