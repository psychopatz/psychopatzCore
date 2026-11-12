---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S0"
phase_commit_message: "phase(S0): reconcile committed handoff residual vector"
phase_commit_vector: "project-hoomans=f3fd184c7784a450b1e67249a966c2db9b1f3b14;psychopatz-core=self;dynamic-trading=806d1842c536861f1ed5d5e856683626a5aca4d7"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T11:50:19.827771Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S1 — canonical IR, reference model and predicate v2"
chunk: "implement Core-owned actor-neutral Canonical Semantic Dialogue IR and shared predicate extensions"
retrieval_tier: "verify"
---



# Session Handoff

## What became true

- S0 is accepted across PsychopatzCore, ProjectHoomans and DynamicTrading.
- Core now owns a machine-readable inventory at `Docs/semantic_dialogue_language_standard/S0_AUTHORING_INVENTORY.json`.
- The inventory records 11 maintained surfaces with source files, owner/classification, references, generated outputs, compatibility status, PSDL destination and migration/removal status.
- The Core-owned `psdl_authoring_audit.py` guard rejects changed first-party authoring under frozen superseded roots and accepts PSDL records, generated output and compatibility adapters outside those roots.

## Remaining

- Implement S1 in PsychopatzCore. ProjectHoomans and DynamicTrading must consume the public Core contracts rather than add a parallel IR or predicate evaluator.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then
read current dirty source before relying on the inventory's structural
references.

Exact next action:

1. Inspect existing Core predicate/context/reference contracts and their callers.
2. Add the actor-neutral IR/reference model and bounded collection predicate operations in Core, with focused actor-swap fixtures.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before S0 changes.
- `CODE_VERIFIED`: DynamicTrading trader pack/static suggestions, generated registry and trader conversation callers are included in the inventory.
- `TEST_VERIFIED`: focused S0 audit/guard tests pass (7 tests); current three-repository guard pass has zero violations.
- `STATIC_ONLY`: Core PSDL compiler/IR and adopter migrations remain incomplete; continue automatically through S1-S8.

## Expensive discoveries worth preserving

- Core's existing CodeBuilder conversation roots are mixed migration input and must not be mistaken for a second adopter compiler.
- ProjectHoomans' old `PNC/Conversation/Definitions` tree is a maintained first-party source with 94 files; its generated 121-file semantic output and EN/TL catalogs are downstream boundaries.
- DynamicTrading's mandatory source is `tools/providers/dt/codebuilder/sources/conversation/`: one pack contains 11 concepts, 7 speech acts, 19 patterns and 3 action providers; static suggestions contain 8 offers in EN/TL.
- The old roots are frozen by path during migration; external compatibility remains allowed when it is outside those authoring roots.

## Blockers / open decisions

- None.

## Acceptance

S0 is accepted only when the committed handoff records the three-repository
phase vector, the inventory is reproducible, and the guard passes current
worktrees plus focused allow/reject fixtures. The next acceptance boundary is
S1's Core actor-swap IR/predicate fixture gate.

> Replace this file on the next handoff; do not append a diary.
