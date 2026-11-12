---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S5"
phase_commit_message: "phase(S5): accept task and tool-reply migration"
phase_commit_vector: "project-hoomans=1c88d83c3a8ff7c6a1f0838d1b029e0a6528bbb5;psychopatz-core=self;dynamic-trading=3eb4d4a3f14440751610ec371bb2a4aee753a57a"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T18:37:59.639880Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S5 — first-party domain migration deletion"
chunk: "migrate one coherent first-party semantic domain in each mandatory adopter through Core PSDL mechanism"
retrieval_tier: "verify"
---



# Session Handoff

## What became true

- S0 remains accepted across PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon. The machine-readable authoring inventory and no-new-legacy guard cover all three repositories and pass with zero violations.
- S1-S4 remain accepted with Core ownership of the actor-neutral IR, shared predicates, PSDL compiler/normalizer, typed references/slots/bindings, semantic offers, and behavior/beat projection contracts.
- ProjectHoomans task/command/companion-action, social, navigation, and knowledge wording now use final PSDL sources routed through the Core compiler. DynamicTrading remains a mandatory adopter and receives only generated routing output for these Core-owned domains.
- The knowledge migration preserves 7 semantic families, 32 bounded style plans, 320 phrase pairs, and 640 EN/TL locale values. Superseded Core knowledge sources/generated outputs/translations and Hoomans Knowledge phrase-family/generated-index/split translations are removed.
- The world-event migration preserves 2 semantic families, 8 bounded style plans, and 80 phrase pairs/160 EN/TL locale values. `behavior.world_event_warn` is now a Core PSDL behavior with its existing Interaction Director contract intact; superseded world-event content/behavior sources/generated modules/translations are removed.
- ProjectHoomans' world-event adapter projects Core-generated plans into the existing phrase-family and SpeechRealization authorities. World-event lifecycle, arbitration, and gameplay remain adopter/runtime-owned; no second dialogue runtime or director was added.
- ProjectHoomans medical-event wording is now authored in six final PSDL shards named by semantic response surface: call, overview, repeat, teammate, treatment, and update. Together they preserve 32 semantic families/records, 320 phrase pairs, and 640 EN/TL locale values.
- The existing Hoomans medical response catalog remains the selector; its Core adapter projects PSDL plans into the established phrase-family/SpeechRealization authority. Medical predicates, follow-up offers, response plans, treatment logic, and health gameplay remain adopter-owned. Superseded Core medical content sources/generated modules and split Event translations are removed.

## Remaining
- The event-reaction shard is accepted. Continue S5 through the remaining combat-kill/banter and other maintained first-party domains, then close S6-S8 across all three repositories.

- Execute S5-S8 across all three repositories. Migrate the remaining event-reaction/combat and other maintained first-party domains through Core PSDL, prove parity and caller/reference zero, remove superseded first-party authoring, and complete taxonomy, authoring-service, and exhaustive acceptance gates.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then read current dirty source before relying on stale structural references.

1. Re-inspect PsychopatzCore, ProjectHoomans, and DynamicTrading worktrees and current PSDL/legacy authoring surfaces.
2. Select the next coherent production domain, beginning with remaining combat-kill/banter dialogue.
3. Author its final PSDL source through the Core compiler, regenerate downstream artifacts, run parity/caller-zero checks, and remove the superseded first-party source in the same accepted phase.
4. Continue through remaining ProjectHoomans surfaces and any remaining DynamicTrading/DTCommon surfaces before S6-S8 closure.

## Evidence
- `TEST_VERIFIED`: event-reaction parity covers 19 families, 190 phrase pairs, and 380 EN/TL locale values; Core 109-test harness, PSDL build, direct Lua family load, focused Hoomans event/social smokes, three-repository guard, caller/reference-zero, and changed-file Kahlua gates pass.

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before this boundary; adopter repositories were committed before Core.
- `CODE_VERIFIED`: Core remains the only PSDL mechanism owner. DynamicTrading trader packs/static suggestions, generated outputs, and runtime callers remain mandatory migration inputs, not duplicate Core mechanism.
- `TEST_VERIFIED`: S0 audit/guard covers 3 repositories and 11 maintained surfaces with zero violations.
- `TEST_VERIFIED`: knowledge parity covers 7 families, 32 plans, 320 phrase pairs, and 640 EN/TL locale values; Core 109-test harness, PSDL build, focused Hoomans knowledge/world-knowledge smokes, generated ownership tests, direct Lua family load, and changed-file Kahlua gates pass.
- `TEST_VERIFIED`: world-event parity covers 2 families, 8 plans, 80 phrase pairs, and 160 EN/TL locale values; behavior-contract parity, direct Lua family/behavior loads, Core 109-test harness, PSDL build, three-repository guard, and changed-file Kahlua gates pass.
- `TEST_VERIFIED`: medical-event parity covers 32 semantic families/records, 320 phrase pairs, and 640 EN/TL locale values across six semantic shards; Core 109-test harness, PSDL build, direct Lua family loads, three-repository guard, and changed-file Conversation Kahlua gates pass.
- `TEST_VERIFIED`: accepted adopter commit vector is ProjectHoomans `d9044265`, DynamicTrading `cb1397f9`, with Core committed last at the current handoff boundary.
- `BASELINE_EVIDENCE`: the broad Hoomans worker/authoring suite still stops at the pre-existing duplicate automatic-flow registration `semantic.generated.simple_command.camp.failed` during startup. Temporary-copy compiler tests also retain the existing fixture assumption that mandatory external adopter shards are present; neither is a world-event parity or caller-zero failure.
- `STATIC_ONLY`: S5 remaining migration and S6-S8 final acceptance remain incomplete.

## Blockers / open decisions

- None.

## Acceptance
The event-reaction chunk is accepted with seven adopter-owned PSDL dialogue shards, 19-family/190-pair/380-locale parity, existing social response and SpeechRealization authorities, caller/reference-zero evidence, and removal of superseded first-party sources. The next acceptance boundary is the remaining combat-kill/banter domain through the same Core-owned compiler.

The medical-event chunk is accepted with six adopter-owned PSDL dialogue
shards, 32-family/320-pair/640-locale parity, existing medical response and
SpeechRealization authorities,
caller/reference-zero evidence, and removal of superseded first-party sources.
The next acceptance boundary is the next coherent S5 event-reaction/combat
domain through the same Core-owned compiler.

> Replace this file on the next handoff; do not append a diary.
