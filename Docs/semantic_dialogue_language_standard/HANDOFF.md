---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S3"
phase_commit_message: "phase(S3): phase(S3): reconcile committed handoff residual vector"
phase_commit_vector: "project-hoomans=a365fdf0106b882c9d502a29de9c2e93d578fc89;psychopatz-core=self;dynamic-trading=806d1842c536861f1ed5d5e856683626a5aca4d7"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T12:34:46.277521Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S4 — behaviors and beats under PSDL"
chunk: "express behaviors and beats through PSDL while retaining the existing Interaction Director"
retrieval_tier: "verify"
---




# Session Handoff

## What became true

- S0 is accepted across PsychopatzCore, ProjectHoomans and DynamicTrading.
- Core owns the machine-readable three-repository authoring inventory and zero-new-legacy guard at `Docs/semantic_dialogue_language_standard/S0_AUTHORING_INVENTORY.json`.
- S1 is accepted: Core owns the actor-neutral canonical IR, typed participant/slot/reference contracts, public context paths, normalized bounded predicates and collection operations.
- ProjectHoomans' generic predicate path is a thin Core compatibility seam; its suggestion predicate module remains only an adopter façade.
- S2 is accepted: Core owns the sole PSDL parser/compiler/normalizer for `psychopatz.semantic.dialogue-language.v1`, with deterministic multi-kind validation and existing runtime-plan projection.
- S3 is accepted: Core owns the participant-neutral semantic offer and typed text-binding contracts; PSDL response plans project into the existing ResponsePlan/BranchOffers authorities.
- Hoomans' BranchOffers path is a Core compatibility façade, and its adopter smoke proves a two-turn plan preserves NPC/player/participant consumers and semantic frames without text reparsing.
- Core text bindings resolve actor-neutral paths and registered typed resolvers while rejecting private paths.

## Remaining

- Implement S4 through Core and adopter fixtures. Behaviors and beats must remain modular PSDL records under the existing Interaction Director; beats do not own wording and simple dialogue does not require a beat.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then
read current dirty source before relying on stale structural references.

Exact next action:

1. Inspect existing Core/ProjectHoomans/DynamicTrading behavior and beat records, Interaction Director contracts and generated outputs.
2. Compile representative PSDL behavior/beat records into the existing director-compatible shapes, preserving shared predicates and beat→behavior references.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before S0 and again at every accepted phase boundary.
- `CODE_VERIFIED`: DynamicTrading trader pack/static suggestions and generated/runtime callers remain mandatory migration inputs, not a duplicate Core mechanism.
- `TEST_VERIFIED`: S0 guard/audit tests pass (7 tests), the three-repository guard has zero violations, and the full Core semantic harness passes (105 tests).
- `TEST_VERIFIED`: Core and Hoomans S3 response/offer/binding smoke fixtures pass; changed Core/Hoomans Lua files pass the Kahlua error scan.
- `STATIC_ONLY`: S4 behavior/beat adoption and S5-S8 migrations remain incomplete; continue automatically through S4-S8.

## Blockers / open decisions

- None.

## Acceptance

S3 is accepted only when the committed handoff records the three-repository
phase vector, Core owns the reusable semantic offer and text-binding seams,
ResponsePlan/BranchOffers projection passes for player and NPC consumers, and
dynamic actor-neutral text bindings remain separate from semantic frames. The
next acceptance boundary is S4's existing Interaction Director behavior/beat
gate.

> Replace this file on the next handoff; do not append a diary.
