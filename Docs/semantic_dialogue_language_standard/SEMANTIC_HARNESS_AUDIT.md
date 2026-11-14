# Semantic Harness ConvoEngine Convergence Audit

**Audit date:** 2026-11-14
**Repositories:** psychopatzCore, ProjectHoomans, DynamicTrading
**Status:** implementation supports ConvoEngine, but Semantic Lab/CLI are not yet fully converged on the final authority model.

## Executive finding

The manifest/compiler/build path is genuinely ConvoEngine-native and the S8R runtime migration is accepted. The remaining problem is the harness surface around it: several Studio and service APIs still model the retired record-bucket/dataset architecture, while the ConvoEngine Studio simulator reimplements part of production semantic policy in Python instead of asking the production Lua modules.

Therefore the next work is not another ConvoEngine runtime redesign. It is a bounded **Semantic Harness convergence** phase that removes duplicate/superseded authoring surfaces and makes the harness consume the same compiler/runtime authorities that the game uses.

## Verified good foundations

- Canonical ConvoEngine family discovery sees 566 current family files across Core, ProjectHoomans, and DTCommon.
- `SemanticLabAuthoringService` already exposes canonical create/edit/move/shard/normalize/write/validate operations.
- `conversation_discovery_record()` and `conversation_affected_closure()` already provide compiler-owned routing/impact evidence.
- `write_conversation_output()` is the shared generation authority.
- The production Lua worker architecture is intentionally thin: Python sends commands while Lua owns semantic policy.
- Core runtime already exposes the production mechanisms the Studio needs: `PsychopatzSemanticPredicate`, `TextBinding`, `ConvoEngine.Affordance`, `ConvoEngine.ActionContract`, and generated Foundation/Registry data.
- `ActionContract.List()` / `Get()` exist; `Affordance` exposes `RenderRoleText`, `Score`, `ExpandSlots`, `Collect`, `SelectNpcAffordance`, `SelectReply`, `ResolveAfter`, `ApplyActionResult`, and `ExecuteExchange`.

## Finding H1 — legacy PSDL record-bucket service API remains

`SemanticLabAuthoringService` still contains `list_psdl_sources`, `load_psdl_source`, record-level create/edit/duplicate/delete/reorder/write methods and compatibility helpers. Their non-definition callers are tests only. The current ConvoEngine pane does not use them.

**Impact:** API/token clutter and a second mental model for agents. Small models can choose the wrong authoring seam.

**Plan:** migrate the remaining tests to ConvoEngine family APIs, isolate only the genuinely required legacy-schema reader in an explicit migration module, then delete the dead record-bucket CRUD surface after caller-zero.

## Finding H2 — Studio simulation is a second semantic interpreter

`convo_engine_studio_trace.py` implements its own predicate evaluator and text renderer. Its predicate set is smaller than production: it lacks `falsy`, `not_in`, `contains`, `not_contains`, `contains_any`, and `contains_all`. Placeholder rendering also bypasses production `TextBinding` public/private path and resolver behavior.

It also hard-codes `pnc.companion.camp` in `KNOWN_ACTION_CONTRACTS`, even though runtime contracts are registered by `ActionContract.Register` and can be listed from Lua.

**Impact:** Studio can report a simulation result that differs from the real runtime as the language grows.

**Plan:** keep Python compilation/structural preview, but move behavioral simulation to new read-only worker commands backed by production Lua Predicate/TextBinding/Affordance/ActionContract. Python should display the returned trace, not reinterpret it.

## Finding H3 — dynamic affordance behavior is not actually simulated

The current Studio trace does not exercise production candidate providers, slot expansion, utility scoring, relationship/trait preference, consumer filtering, deterministic NPC selection, recency/cooldowns, or bounded `after` recommendation resolution. It mostly picks the first viable authored realization/reply.

**Plan:** expose production read-only operations for family detail, affordance collection, NPC selection, reply selection, after resolution, role-text rendering, and action-contract catalog. Use the exact same context projection as the worker/game path.

## Finding H4 — family discovery and service repository ownership diverge

`convo_engine_studio_trace._convo_roots()` walks folders directly and assumes sibling `ProjectHoomans` / `DynamicTrading` checkouts. This duplicates manifest/compiler repository discovery and differs from the hardened S8R audit discovery.

The service constructor also currently initializes `package_repositories[ProjectHoomans]` to `self.repository` even when a separate `hoomans_repository` argument is supplied. The main Semantic Harness CLI/GUI has no separate `--hoomans-repository` option and documents `--repository` as Project Hoomans, while ConvoEngine audit code independently discovers participants. These are three different repository-resolution models.

**Plan:** centralize participant discovery in one service-level repository map, honor explicit owner repositories, and derive family/source rows from the compiled manifest/discovery index. Main GUI/CLI, ConvoEngine CLI, audit, Dataset Library, and Studio panes must consume the same map. No Studio-specific filesystem discovery.

## Finding H5 — unsafe ConvoEngine CRUD in the pane

`ConvoEngineAuthoringPane` currently:

- defaults a new-family write path into Core even when the selected owner is ProjectHoomans or DTCommon;
- deletes canonical source with direct `Path.unlink()`;
- can change namespace/id in the form and write to the old path instead of using the move/rename contract;
- does not pass an expected source fingerprint on write;
- leaves regeneration as a separate manual instruction after write/delete.

Cross-reference validation also checks reference shape and wording-key prohibition but does not prove every `after.goto` / `after.recommend` target exists. Direct deletion can therefore leave dangling semantic references.

**Plan:** add one service-owned transactional family change API: preview impact -> validate global references -> fingerprint guard -> owner-routed create/edit/move/delete -> CodeBuilder regenerate -> return changed artifacts. The GUI never unlinks or chooses package roots itself.

## Finding H6 — dead legacy Studio surfaces are still presented as canonical

Against the real three-repository workspace:

    ConvoEngine families: 566
    Dialogue Content rows: 0
    Dataset Library sources: 4, all exists=false
    Workflow datasets: 3, all reported workflowReady=true despite exists=false

The missing dataset IDs are the old `semantic_flows`, `common_dialogue`, `grounded_personal`, plus `wordnet_concepts`. `DatasetLibraryPane` still labels them canonical/editable. The main Studio exposes an empty `Dialogue Content` tab, while the real ConvoEngine authoring pane is hidden under Developer Tools.

**Impact:** the GUI actively steers users and small agents toward obsolete paths.

**Plan:** promote ConvoEngine to the primary Dialogue Content authoring surface. Hide/remove zero-source legacy tabs and fail closed on missing dataset sources (`editable=false`, `workflowReady=false`). Keep only dataset/lexicon surfaces backed by real current sources. Update Source Explorer to list ConvoEngine families and their compiler-owned discovery/affected-closure data.

## Finding H7 — main Semantic Harness CLI does not expose ConvoEngine authoring

The main `entrypoints/cli.py` authoring operations expose datasets/blocks/workflows, while ConvoEngine has a separate `convo_engine_cli.py`.

**Plan:** add a `convo`/`convo-engine` command surface to the main CLI that delegates to the same `SemanticLabAuthoringService` APIs for list/show/validate/preview/simulate/create/edit/move/delete/regenerate/audit. Keep the specialized CLI as a thin compatibility entrypoint if needed, not a second implementation.

## Finding H8 — structured ConvoEngine editor coverage is partial

The pane can edit all advanced fields as raw JSON, but first-class controls are missing for locale maps, multiple stable `say` realizations, style variants, reply variants, slot candidate providers, utility/prefer, recommend groups, goto/end/resume, execute bindings/results, and behavior/beat-specific fields.

**Plan:** after authority convergence, add structured controls derived from the compiler schema/projections. Raw JSON remains an advanced escape hatch, not the primary way to author final architecture features.

## Finding H9 — deterministic audit/build is not concurrency-safe

A concurrent Core test run plus `audit-s6m8 --check-determinism` can race while both rewrite/prune live generated output. Sequential runs pass.

**Plan:** prefer deterministic renders into temporary output roots and compare hashes without mutating live `media/`. If a live regeneration is unavoidable, use one workspace generation lock. Never place staging directories inside Project Zomboid `media/`.

## Finding H10 — conceptual surface is larger than the implementation needs

Fresh harness-owned measurements (excluding the bundled virtualenv and caches):

    Python files                                  277
    Python LOC                                 71,593
    CodeBuilder LOC                            25,340
    Studio + UI LOC                           ~20,863
    SemanticLabAuthoringService                  2,729 lines
      methods                                       97
      public methods                                66
    main CLI                                     1,425 lines
      add_argument calls                           123

The counts are not defects by themselves. The problem is that callers must
choose among many overlapping methods, flags, panes and legacy source models.

**Plan:** use `SEMANTIC_HARNESS_COMPACT_ARCHITECTURE.md` as the normative S9
target. Compactness means authority compression: one WorkspaceCatalog, one
ConvoCatalog, a small OperationRegistry/transaction surface, production Lua
ConvoProbe, BuildPlanner, and thin GUI/CLI clients. Soft size thresholds are
review triggers only; do not split files without an ownership reason.

## Acceptance direction

The harness convergence phase is accepted only when:

- Studio family browsing comes from compiler/manifest authority, not folder guesses;
- ConvoEngine family CRUD is service-owned, owner-routed, fingerprint-guarded, reference-safe, and regenerates atomically;
- runtime simulation/trace calls production Lua Predicate/TextBinding/Affordance/ActionContract rather than Python copies;
- player and NPC previews expose the same candidate/utility/selection decisions as runtime;
- action contract discovery is runtime/declarative rather than hard-coded CAMP metadata;
- dead Dataset Library/Dialogue Content/workflow surfaces are removed or made fail-closed and non-editable;
- ConvoEngine is the obvious primary conversation authoring surface in Studio and CLI;
- Source Explorer includes all ConvoEngine families and impact routing;
- deterministic audit can run without racing a live generated tree;
- focused parity tests plus the full existing S8R test matrix remain green.

Native Project Zomboid live SP/MP acceptance remains user-owned; this phase is developer-side harness convergence only.