---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S1"
phase_commit_message: "phase(S1): phase(S1): reconcile committed handoff residual vector"
phase_commit_vector: "project-hoomans=999b816f2e12335f5d367cdc1b8e460ea80eed0c;psychopatz-core=self;dynamic-trading=806d1842c536861f1ed5d5e856683626a5aca4d7"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T12:11:56.582043Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S2 — PSDL parser/compiler and language validation"
chunk: "implement the Core-owned PSDL parser/compiler on the accepted canonical IR and predicate contracts"
retrieval_tier: "verify"
---





# Session Handoff

## What became true

- S0 is accepted across PsychopatzCore, ProjectHoomans and DynamicTrading.
- Core now owns a machine-readable inventory at `Docs/semantic_dialogue_language_standard/S0_AUTHORING_INVENTORY.json`.
- The inventory records 11 maintained surfaces with source files, owner/classification, references, generated outputs, compatibility status, PSDL destination and migration/removal status.
- The Core-owned `psdl_authoring_audit.py` guard rejects changed first-party authoring under frozen superseded roots and accepts PSDL records, generated output and compatibility adapters outside those roots.
- S1 is accepted: Core owns the actor-neutral canonical IR, typed participant/slot/reference contracts, public context paths, normalized bounded predicates and collection operations.
- ProjectHoomans' generic predicate path is now a thin Core compatibility seam; its suggestion predicate module remains only an adopter façade.
- The same Core predicate contract passes NPC→player and player→NPC actor-swapped fixtures, generic target and typed slot/reference projections, collection operations and fail-closed private paths.

## Remaining

- Implement S2 in PsychopatzCore. ProjectHoomans and DynamicTrading must consume the public Core PSDL compiler/normalizer rather than add a parallel schema or compiler.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then
read current dirty source before relying on the inventory's structural
references.

Exact next action:

1. Inspect existing Core CodeBuilder conversation contracts and owner-routing/generation seams.
2. Add the Core-owned `psychopatz.semantic.dialogue-language.v1` parser/compiler and language validation with deterministic fixtures.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before S0 changes.
- `CODE_VERIFIED`: DynamicTrading trader pack/static suggestions, generated registry and trader conversation callers are included in the inventory.
- `TEST_VERIFIED`: focused S0 audit/guard tests pass (7 tests); current three-repository guard pass has zero violations.
- `TEST_VERIFIED`: the full Core semantic harness passes (100 tests), the S1 actor-swapped Lua smoke passes, and changed Lua files pass the Kahlua error scan.
- `STATIC_ONLY`: Core PSDL compiler and adopter migrations remain incomplete; continue automatically through S2-S8.

## Expensive discoveries worth preserving

- Core's existing CodeBuilder conversation roots are mixed migration input and must not be mistaken for a second adopter compiler.
- ProjectHoomans' old `PNC/Conversation/Definitions` tree is a maintained first-party source with 94 files; its generated 121-file semantic output and EN/TL catalogs are downstream boundaries.
- DynamicTrading's mandatory source is `tools/providers/dt/codebuilder/sources/conversation/`: one pack contains 11 concepts, 7 speech acts, 19 patterns and 3 action providers; static suggestions contain 8 offers in EN/TL.
- The old roots are frozen by path during migration; external compatibility remains allowed when it is outside those authoring roots.

## Blockers / open decisions

- None.

## Acceptance

S1 is accepted only when the committed handoff records the three-repository
phase vector, Core owns the reusable IR/predicate mechanism, the Hoomans
duplicate evaluator is removed, and the actor-swapped IR/predicate fixture
gate passes. The next acceptance boundary is S2's Core-owned compiler and
language-validation gate.

> Replace this file on the next handoff; do not append a diary.
