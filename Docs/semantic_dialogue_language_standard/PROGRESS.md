# Progress — ConvoEngine

**Status:** IN PROGRESS — S0-S8R ConvoEngine accepted; S9H0 and S9H1 complete, S9H2 OperationRegistry + safe ConvoTransaction next.
**Estimated developer progress:** 94% for the expanded ConvoEngine + harness objective.
**Branch:** existing `main` in all three repositories.
**Active phase:** S9 — Semantic Harness ConvoEngine convergence.
**Immediate Next Chunk:** S9H2 — implement `OperationRegistry` (`workspace.describe`, `convo.*`) and `ConvoTransaction` (`ChangeSet` preview/apply, owner-routed writes, identity-edit move semantics, dangling-reference rejection, fingerprint guards), remove unsafe direct `Path.unlink()` from ConvoEngine pane, and begin decomposing `SemanticLabAuthoringService` onto `HarnessContext`.

## Accepted ConvoEngine baseline

S0-S8R runtime/compiler/content migration remains accepted and must not be redesigned without a concrete regression.

Verified 2026-11-14 baseline:

    canonical ConvoEngine families                 566
    active psdl.* / pnc.psdl.* output violations    0
    deterministic generated files                  404 / 0 diffs
    Core Python semantic-harness                   150/150 PASS
    Core Convo/Semantic/Conversation Lua            34/34 PASS
    DynamicTrading                                   89/89 PASS
    ProjectHoomans                                 1020/1021
    Kahlua ConvoEngine trees                          0 errors

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
- **S9H4 — compact Studio + compiler field descriptors: NEXT.**
- **S9H5 — compact main CLI + compatibility quarantine: NOT STARTED.**
- **S9H6 — BuildPlanner + isolated determinism/cache/lock: NOT STARTED.**
- **S9H7 — exhaustive acceptance + complexity audit: NOT STARTED.**

## Immediate Next Chunk — S9H4 compact Studio + compiler field descriptors

Add compiler-owned `FieldDescriptor` metadata + `SurfaceRegistry`, promote ConvoEngine to the primary Conversation Studio home (`Conversations`, `Source / Impact`, `Review`), fix `dataset_catalog.py` so missing Dataset Library sources report `exists=false, editable=false` and missing workflow datasets report `workflowReady=false`, hide zero-source legacy tabs behind explicit compatibility toggles, support structured editing + unknown field round-trip, and clear `test_06` and `test_07`.

## Completion boundary

The expanded developer-side objective is complete only when Semantic Lab and the main CLI consume ConvoEngine as the single conversation authoring/simulation authority: owner-routed safe CRUD, production-Lua simulation/trace, current source discovery, no misleading dead authoring tabs, one discoverable CLI/service contract, concurrency-safe deterministic audit, and the full S8R verification matrix still passing.
