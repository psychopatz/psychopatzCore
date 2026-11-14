# Progress — ConvoEngine

**Status:** IN PROGRESS — S0-S8R ConvoEngine accepted; S9H0 regression-lock complete, S9H1 WorkspaceCatalog + ConvoCatalog next.
**Estimated developer progress:** 93% for the expanded ConvoEngine + harness objective.
**Branch:** existing `main` in all three repositories.
**Active phase:** S9 — Semantic Harness ConvoEngine convergence.
**Immediate Next Chunk:** S9H1 — implement `WorkspaceCatalog` (`WorkspaceSnapshot`, manifest-driven provider/conversation-source normalization, explicit owner repository routing) and `ConvoCatalog` (lightweight compiler-owned `FamilySummary` index, search/filter, source/generated routing, refs, bounded closure), and migrate Studio/Source Explorer/audit/CLI/CodeBuilder lookup.

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

- **S9H0 — regression-lock + architecture freeze: COMPLETE.** `test_convo_engine_s9_regressions.py` pins all 13 reproduced defects/invariants (16 tests, 12 expected failures before S9H1-S9H6 fixes; full Core Python suite 166/166 OK).
- **S9H1 — WorkspaceCatalog + ConvoCatalog: NEXT.**
- **S9H2 — OperationRegistry + safe ConvoTransaction: NOT STARTED.**
- **S9H3 — production Lua ConvoProbe: NOT STARTED.**
- **S9H4 — compact Studio + compiler field descriptors: NOT STARTED.**
- **S9H5 — compact main CLI + compatibility quarantine: NOT STARTED.**
- **S9H6 — BuildPlanner + isolated determinism/cache/lock: NOT STARTED.**
- **S9H7 — exhaustive acceptance + complexity audit: NOT STARTED.**

## Immediate Next Chunk — S9H1 WorkspaceCatalog + ConvoCatalog

Build `WorkspaceCatalog` and `ConvoCatalog` as the single shared discovery authority across GUI, CLI, audit, Source Explorer, and CodeBuilder, fixing explicit Hoomans/DT owner repository routing and migrating Studio/Source Explorer off folder guesses.

## Completion boundary

The expanded developer-side objective is complete only when Semantic Lab and the main CLI consume ConvoEngine as the single conversation authoring/simulation authority: owner-routed safe CRUD, production-Lua simulation/trace, current source discovery, no misleading dead authoring tabs, one discoverable CLI/service contract, concurrency-safe deterministic audit, and the full S8R verification matrix still passing.
