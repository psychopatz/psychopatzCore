---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S5"
phase_commit_message: "phase(S5): reconcile companion command handoff residual"
phase_commit_vector: "project-hoomans=e7e44b80f56239ef3d99c115c6eaa7b24ed52a69;psychopatz-core=self;dynamic-trading=fa9bff72293918dc07d8d6303a67c65585a74deb"
phase_residual_vector: "project-hoomans=0507c20b6ea69968903f49b87db31da35cbf86a3ad320128efe95d65f31aff9e;psychopatz-core=52d4a6298ab9af337454117d635dc77278ac9780e736676754f354bdc238cf00;dynamic-trading=557003e34c04c2b75f174403a669f1e9b024949adac44db8add7a3e859e53b63"
residual_worktree_fingerprint: "52d4a6298ab9af337454117d635dc77278ac9780e736676754f354bdc238cf00"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T16:21:16Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S5 — first-party domain migration deletion"
chunk: "migrate one coherent first-party semantic domain in each mandatory adopter through Core PSDL mechanism"
retrieval_tier: "verify"
---

# Session Handoff

## What became true

- S0 remains accepted across PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon. The refreshed machine-readable inventory and no-new-legacy guard pass with zero violations.
- S1-S4 remain accepted with Core ownership of the actor-neutral IR, shared predicates, PSDL compiler/normalizer, typed references/slots/bindings, semantic offers, and behavior/beat projection contracts.
- ProjectHoomans task/command/companion-action wording is now authored in four final PSDL shards: player commands, companion replies, lifecycle actions, and combat/horde reactions.
- The command migration preserves 76 semantic phrase families and 152 EN/TL locale entries. The existing Hoomans response catalog and companion speech authority consume Core-generated `Registry.PSDLPlan` variants; command execution, effects, horde acknowledgement, safety, and UI projection authorities remain adopter-owned.
- Superseded Core command/player, command/replies, command/lifecycle, and combat-horde sources plus generated Content modules are removed. No duplicate PSDL compiler, IR, predicate evaluator, binding engine, or runtime was added to either adopter.
- Direct command realization and horde acknowledgement smokes pass; Core's semantic harness remains green at 109 tests; ownership routing tests pass 8/8; the three-repository S0 audit/guard passes.

## Remaining

- Execute S5-S8 across all three repositories. Migrate the remaining maintained first-party domains through Core PSDL, prove parity and caller/reference zero, remove superseded first-party authoring, and complete taxonomy, authoring-service, and exhaustive acceptance gates.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then read current dirty source before relying on stale structural references.

1. Re-inspect PsychopatzCore, ProjectHoomans, and DynamicTrading worktrees and current PSDL/legacy authoring surfaces.
2. Select the next coherent production domain, beginning with social apology/hostility/reconciliation.
3. Author its final PSDL source through the Core compiler, regenerate downstream artifacts, run parity/caller-zero checks, and remove the superseded first-party source in the same accepted phase.
4. Continue through navigation/knowledge/world-event, remaining ProjectHoomans surfaces, and any remaining DynamicTrading/DTCommon surfaces before S6-S8 closure.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before this boundary; participant repositories were committed before Core.
- `CODE_VERIFIED`: DynamicTrading trader packs, static suggestions, generated outputs, and runtime callers remain mandatory migration inputs, not duplicate Core mechanism.
- `TEST_VERIFIED`: S0 guard/audit, Core 109-test semantic harness, Hoomans ownership routing, direct command realization, horde acknowledgement, and changed Conversation Kahlua gates pass.
- `TEST_VERIFIED`: command parity covers 76 semantic phrase families and 152 EN/TL entries; production searches found no references to superseded Core command/combat content module IDs.
- `BASELINE_EVIDENCE`: the broad `pnc_companion_commands_smoke` still fails at its known presentation-path camp-rejection handoff after direct semantic resolution succeeds; this remains separate from the PSDL parity and caller-zero gates.
- `STATIC_ONLY`: S5 remaining migration and S6-S8 final acceptance remain incomplete.

## Blockers / open decisions

- None.

## Acceptance

The task/command/companion-action chunk is accepted with four adopter-owned
PSDL shards, 76-family/152-locale parity, existing semantic response
authority, caller/reference zero, and removal of superseded first-party
sources. The next acceptance boundary is the next coherent S5 domain through
the same Core-owned compiler.

> Replace this file on the next handoff; do not append a diary.
