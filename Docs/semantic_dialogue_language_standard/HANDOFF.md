---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S5"
phase_commit_message: "phase(S5): phase(S5): migrate Core static dialogue through PSDL"
phase_commit_vector: "project-hoomans=a0ee642394d5ab5303f911403558fb07e1aec24b;psychopatz-core=self;dynamic-trading=ba6d2ca3ea17430044dd8a1dbe640114167da4f5"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=7a3dae83842524f49a12c3310c3dfa9dea2833ae586097ca751cb8b17e7ef387;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "7a3dae83842524f49a12c3310c3dfa9dea2833ae586097ca751cb8b17e7ef387"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T14:03:23.169303Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S5 — first-party domain migration and deletion"
chunk: "migrate one coherent first-party semantic domain in each mandatory adopter through the Core PSDL mechanism"
retrieval_tier: "verify"
---





# Session Handoff

## What became true

- S0 is accepted across PsychopatzCore, ProjectHoomans and DynamicTrading.
- S1 is accepted: Core owns the actor-neutral canonical IR, typed participant/slot/reference contracts, public context paths, normalized bounded predicates and collection operations.
- S2 is accepted: Core owns the sole PSDL parser/compiler/normalizer for `psychopatz.semantic.dialogue-language.v1`, with deterministic multi-kind validation and existing runtime-plan projection.
- S3 is accepted: Core owns the participant-neutral semantic offer and typed text-binding contracts; PSDL response plans project into the existing ResponsePlan/BranchOffers authorities.
- S4 is accepted: Core PSDL behavior and beat records validate against the existing Interaction Director contracts and project into its behavior/beat registry shapes.
- Behaviors retain semantic strategy fields; beats retain entry/maintain/exit, candidate relevance, cooldown, maximum turns and groups; beats do not own wording.
- Shared Core predicate normalization is used by dialogue, offers, behaviors and beats. Simple dialogue remains valid without a beat.
- DynamicTrading and ProjectHoomans were inspected at the S4 boundary; neither adopter received a duplicate director or PSDL compiler.
- Core's remaining static suggestion authoring now lives in final PSDL shards `psdl/dialogue/core_check_in.json` and `psdl/dialogue/core_identity.json`, with ten-record parity against the superseded Core UI source.
- Hoomans and DTCommon generated projections were refreshed through the Core compiler; DTCommon now retains a synchronized provider-local generated manifest.
- Current cross-repository checks pass: Core 109-test harness, Hoomans ownership/smoke suites, DT trader smokes, and Kahlua scans for all changed generated/runtime Lua.

## Remaining

- Execute S5-S8 across all three repositories. Migrate coherent first-party domains through Core PSDL, prove behavioral parity and caller/reference zero, delete superseded first-party authoring, then complete authoring-service and exhaustive acceptance gates.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then
read current dirty source before relying on stale structural references.

Exact next action:

1. Re-inspect PsychopatzCore, ProjectHoomans and DynamicTrading worktrees and current PSDL/legacy authoring surfaces.
2. Select the next coherent domain with production callers in ProjectHoomans and/or DynamicTrading.
3. Author its final PSDL source through the Core compiler, regenerate downstream artifacts, run parity/caller-zero checks, and remove the superseded first-party source in the same accepted phase.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before S0 and again at every accepted phase boundary.
- `CODE_VERIFIED`: DynamicTrading trader packs, static suggestions, generated outputs and runtime callers remain mandatory migration inputs, not a duplicate Core mechanism.
- `TEST_VERIFIED`: S0 guard/audit tests pass; the three-repository guard has zero violations.
- `TEST_VERIFIED`: S1 Core/adopter contract fixtures and the full 100-test semantic harness pass; changed Lua files pass Kahlua verification.
- `TEST_VERIFIED`: S2 Core compiler fixtures and the full 105-test semantic harness pass.
- `TEST_VERIFIED`: S3 Core/Hoomans response/offer/binding fixtures pass; changed Core/Hoomans Lua files pass Kahlua verification.
- `TEST_VERIFIED`: S4 behavior/beat projection fixtures and the full 106-test Core semantic harness pass; Python compilation and diff checks pass.
- `STATIC_ONLY`: S5-S8 migration, authoring-service and final acceptance gates remain incomplete.

## Blockers / open decisions

- None.

## Acceptance

S4 is accepted only when PSDL behavior/beat records are validated by the
existing Core Interaction Director contract, project deterministically into its
registry shape, preserve shared predicates and beat references, and keep
wording outside beats. The next acceptance boundary is S5's first domain
migration with parity and superseded-source removal.

> Replace this file on the next handoff; do not append a diary.
