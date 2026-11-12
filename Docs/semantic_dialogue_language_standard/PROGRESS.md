# Progress — Psychopatz Semantic Dialogue Language Standard

**Status:** IN PROGRESS — S0-S2 ACCEPTED; continuing automatically through S3-S8.
**Branch:** existing `main` in each participant repository.
**Active phase:** S3 — turns, bindings, slots and participant-neutral offers.
**Developer completion boundary:** S8.

## Current verified architecture

Repository audit before implementation found that the required runtime capabilities already exist in separate accepted systems:

- shared bounded predicate evaluation;
- actor traits/personality/identity/relationship projections;
- identity gender projection;
- directed relationship approval/respect/familiarity/state;
- bounded fuzzy semantic recovery with mutation-safety policy;
- item/world/entity matching paths;
- ResponsePlan multi-turn response delivery;
- BranchOffers and generated semantic affordances;
- per-speaker/addressee flow keys;
- Interaction Director beat/behavior arbitration;
- multi-participant InteractionScene runtime;
- autonomous NPC semantic-choice conversation controller;
- dynamic name/address/reference resolution;
- owner-routed CodeBuilder generation and inline locale work currently in progress.

The problem is authoring fragmentation, not absence of those runtime capabilities.

## S0 acceptance now verified

- `S0_AUTHORING_INVENTORY.json` inventories 11 maintained surfaces across all three repositories, including Core mechanism ownership, ProjectHoomans definitions/generated/runtime adapters, and DynamicTrading trader pack/static suggestions/generated/runtime compatibility.
- Each surface records source files, owner/classification, production/test/documentation references, generated outputs, external compatibility status, final PSDL destination and migration/removal status.
- `psdl_authoring_audit.py --check` passes against the current Core, ProjectHoomans and DynamicTrading worktrees.
- The focused guard rejects changed first-party authoring under each frozen old root while accepting Core-compiled PSDL records, generated outputs and compatibility adapters outside those roots.

## S1 acceptance now verified

- Core owns the actor-neutral canonical IR contract with `speaker`, `addressee`, `target`, bounded participants, typed slots/references, public context paths and stable schema validation.
- Core owns the single normalized predicate contract across dialogue/runtime validation, including scalar/logical operations and bounded `contains`, `not_contains`, `contains_any`, and `contains_all` operations.
- ProjectHoomans' former generic predicate evaluator is now a thin compatibility seam to the Core evaluator; its suggestion predicate façade remains an adopter alias rather than a second implementation.
- Controlled Lua fixtures pass for NPC→player and player→NPC actor swaps, generic target references, typed slot/reference projections, collection predicates and fail-closed private paths.
- Core semantic harness tests pass: 100 tests; the focused S1 contract suite is included. Changed Lua runtime and harness files pass the Kahlua error scan.
- DynamicTrading was re-inspected in the same phase; its trader pack/static suggestions remain migration input and do not gain a parallel predicate/IR implementation.

## S2 acceptance now verified

- Core now owns `psdl_compiler.py`, the only PSDL parser/normalizer/compiler entry point; it accepts single records and bounded catalogs for `dialogue`, `behavior`, `beat`, and `realization`.
- The compiler routes every record through the Core canonical IR and shared predicate normalizer, validates owner/package identity, typed slots/references, public bindings, locale fallback and placeholder parity, bounded turns/offers/transitions, beat behavior references, and legacy/ambiguous source rejection.
- Runtime planning emits existing ResponsePlan/semantic-affordance-shaped data with package-routed module identities; it does not create a second dialogue runtime.
- `SemanticLabAuthoringService.preview_psdl_document` and `preview_psdl_sources` expose the same Core compiler without writing generated output.
- The S2 fixture compiles a translated multi-kind catalog deterministically and rejects malformed translations, inaccessible bindings, unknown fields, legacy identities, beat wording and dangling behavior references.
- Full Core semantic harness passes: 105 tests.

## Normative decisions now frozen

- PSDL is the target first-party authoring standard across PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon.
- PsychopatzCore is the physical owner of the PSDL language/schema, canonical IR, compiler/normalizer, generic validation, shared predicates/references/slots/bindings and reusable authoring service.
- ProjectHoomans and DynamicTrading are mandatory adopters, not optional future scope, and may not duplicate Core's PSDL mechanism.
- Canonical source is actor-neutral: `speaker`, `addressee`, `target`, typed slots/references.
- New reusable authoring does not use player/NPC-specific name variables.
- Offers are semantic affordances; player buttons and NPC choices are projections.
- Turns, offers and transitions are distinct concepts.
- Behaviors and beats are first-class PSDL module kinds.
- Beats orchestrate behaviors and never become mandatory wrappers around simple dialogue.
- One shared predicate language applies across modules.
- Inline locale maps use EN as required fallback; languages are data-driven.
- Existing old authoring is migration input only.
- No new first-party `Legacy/Compat/Old/V1/PartNN` source copies or broad alias registries.
- Migrated domains delete their superseded first-party source after parity/caller-zero proof.
- Generated Lua/JSON/translations remain downstream-only.

## Workspace/concurrency warning

All three repositories may contain concurrent work. At the latest documentation checkpoint, PsychopatzCore contains the Core-owned PSDL documentation and CodeBuilder README changes; ProjectHoomans contains successor annotations; DynamicTrading already has unrelated dirty/untracked work that predates this scope clarification.

Do not infer that earlier work was discarded or that HEAD is permanently authoritative. S0 must re-inspect **all three repositories** and current Git history/worktrees before editing, preserve any concurrent work, and treat exact current source as truth.

## Next Chunk

Execute **S3** in PsychopatzCore and adopter fixtures: map compact/simple and
multi-turn PSDL responses to the accepted ResponsePlan and BranchOffers
authorities, prove typed binding/slot behavior and participant-neutral offer
consumption without UI-text reparsing.

## Evidence status

- `CODE_VERIFIED`: runtime capabilities listed above were inspected in current source before this roadmap was written.
- `TEST_VERIFIED`: S2 Core compiler fixtures and the full 105-test semantic harness pass.
- `TEST_VERIFIED`: S0 guard and focused audit tests pass; the current three-repository guard pass is recorded in the inventory.
- `TEST_VERIFIED`: S1 Core/adopter contract fixtures and the full 100-test semantic harness pass; changed Lua files pass Kahlua verification.
- `STATIC_ONLY`: S3–S8 implementation gates remain open.

## Stop conditions

Do not stop after producing only schemas or examples.

Stop only when:

- S0–S8 developer objective is complete;
- a genuine ownership/auth/tooling blocker prevents safe progress;
- or all developer work is complete and only explicit user-owned native acceptance remains.

No push or Workshop publication.
