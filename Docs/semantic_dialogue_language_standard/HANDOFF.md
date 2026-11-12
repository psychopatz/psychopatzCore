---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "S5"
phase_commit_message: "phase(S5): finalize knowledge translation routing"
phase_commit_vector: "project-hoomans=f365e5b8b424ad043a675c6da430151a33fb6f9c;psychopatz-core=self;dynamic-trading=4b84faad9aeece88f2674fa6cfaf3429fa507f15"
phase_residual_vector: "project-hoomans=a01a7eb210e939424c3c16adf8194c3b3157f2635716037693b0e99c35286961;psychopatz-core=056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108;dynamic-trading=2dd8d943662ee7381ab631614ca5e1765276051c909b40d0c07b3483dfc246e5"
residual_worktree_fingerprint: "056633bafff892c20a41afd30a857c15eab98132ebb467b2f3b447cae9353108"
codebase_memory_indexed_commit: "5075fb7f7334c33b4cfd0991dcf5dd9b4a9c3b88"
updated_at: "2026-11-12T17:22:04Z"
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
- ProjectHoomans social apology/reconciliation wording is now authored in final `psdl/dialogue/social_apology.json` with four semantic families and sixteen bounded style plans. The existing social response catalog projects those plans into the established phrase-family/SpeechRealization authority.
- The social migration preserves 160 EN/TL phrase pairs (320 locale values), removes superseded Core/Hoomans Apology sources and generated outputs, and keeps the Core-owned reconcile/acknowledge-repair behavior IDs as runtime contracts through the PSDL `responseTemplateID` validation seam.
- ProjectHoomans navigation wording is now authored in final `psdl/dialogue/navigation.json` with five semantic families and twenty bounded style plans. The existing navigation response catalog projects those plans into the established phrase-family/SpeechRealization authority.
- The navigation migration preserves 200 EN/TL phrase pairs (400 locale values), removes the superseded Core navigation source, Hoomans manual navigation phrase-family source, generated Content modules, and split Navigation translations, and leaves navigation branch/gameplay authority unchanged.
- PsychopatzCore knowledge, identity, activity, and gossip wording is now authored in four final PSDL shards with seven semantic families and 32 bounded style plans. The existing Hoomans question response catalog projects the Core-generated plans into its phrase-family/SpeechRealization authority with actor-neutral `speaker.name`, `target.name`, and `addressee.name` bindings.
- The knowledge migration preserves 320 phrase pairs and 640 EN/TL locale values, removes superseded Core knowledge content/source/translation surfaces and Hoomans Knowledge phrase-family/generated-index/split-translation surfaces, and leaves knowledge/context selection and gameplay authority in the adopter.

## Remaining

- Execute S5-S8 across all three repositories. Migrate the remaining world-event/event and other maintained first-party domains through Core PSDL, prove parity and caller/reference zero, remove superseded first-party authoring, and complete taxonomy, authoring-service, and exhaustive acceptance gates.

## Resume

Use Codebase Memory at the recorded retrieval tier for each repository, then read current dirty source before relying on stale structural references.

1. Re-inspect PsychopatzCore, ProjectHoomans, and DynamicTrading worktrees and current PSDL/legacy authoring surfaces.
2. Select the next coherent production domain, beginning with world-event/event dialogue.
3. Author its final PSDL source through the Core compiler, regenerate downstream artifacts, run parity/caller-zero checks, and remove the superseded first-party source in the same accepted phase.
4. Continue through remaining ProjectHoomans surfaces and any remaining DynamicTrading/DTCommon surfaces before S6-S8 closure.

## Evidence

- `CODE_VERIFIED`: all three repositories were independently inspected at current `main` HEAD/worktree state before this boundary; participant repositories were committed before Core.
- `CODE_VERIFIED`: DynamicTrading trader packs, static suggestions, generated outputs, and runtime callers remain mandatory migration inputs, not duplicate Core mechanism.
- `TEST_VERIFIED`: S0 guard/audit, Core 109-test semantic harness, Hoomans ownership routing, direct command realization, horde acknowledgement, social apology source/plan parity, direct Lua style-family load, and changed Conversation Kahlua gates pass.
- `TEST_VERIFIED`: command parity covers 76 semantic phrase families and 152 EN/TL entries; production searches found no references to superseded Core command/combat content module IDs.
- `TEST_VERIFIED`: social apology parity covers 4 families, 16 style plans, and 320 EN/TL locale values; production searches find no superseded `social_apology` source, generated SocialApology module, or Apology translation file.
- `TEST_VERIFIED`: navigation parity covers 5 families, 20 style plans, and 400 EN/TL locale values; focused navigation/response-catalog smokes, generated ownership tests, direct Lua family load, Core 109-test harness, three-repository audit/guard, and changed-file Kahlua gates pass.
- `TEST_VERIFIED`: knowledge parity covers 7 semantic families, 32 bounded style plans, 320 phrase pairs, and 640 EN/TL locale values; Core 109-test harness, PSDL build, focused knowledge/world-knowledge smokes, generated ownership tests, direct Lua family load, three-repository audit/guard, and changed-file Conversation Kahlua gates pass. The broader worker trio retains its known startup transport baseline and is not counted as a migration failure.
- `BASELINE_EVIDENCE`: the broad `pnc_companion_commands_smoke` still fails at its known presentation-path camp-rejection handoff after direct semantic resolution succeeds; this remains separate from the PSDL parity and caller-zero gates.
- `BASELINE_EVIDENCE`: the Lua worker social suite advances beyond the former apology-template validation but still hits the pre-existing duplicate automatic-flow registration `semantic.generated.simple_command.camp.failed`.
- `STATIC_ONLY`: S5 remaining migration and S6-S8 final acceptance remain incomplete.

## Blockers / open decisions

- None.

## Acceptance

The knowledge chunk is accepted with four Core-owned PSDL shards, 7-family/
32-plan/640-locale parity, existing semantic response authority,
caller/reference-zero evidence, and removal of superseded first-party sources.
The next acceptance boundary is the next coherent S5 domain through the same
Core-owned compiler.

> Replace this file on the next handoff; do not append a diary.
