---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
phase_commit: "self"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
participant_heads: "project-hoomans=a23890d67da3ddbd4173a5a00d69e75644fbedc1;dynamic-trading=f41df273b37057ebf99f689fb9e67bac6d47d07e"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S7 — ConvoEngine-native Semantic Lab UX"
chunk: "S7 — Semantic Lab exchange-family authoring & trace"
evidence: "TEST_VERIFIED"
retrieval_tier: "verify"
updated_at: "2026-11-14T18:22:30Z"
---

# ConvoEngine Session Handoff

## Current truth

The old public/project name **PSDL** meant **Psychopatz Semantic Dialogue
Language**.

The target name is now **ConvoEngine**.

Treat `PSDL` / `psdl` as migration-era internal identifiers only. Do not do
a blind repository-wide rename. Retire them through tested Core compiler/service
changes and caller-zero evidence.

The existing compiler/runtime migration is useful. Do not undo it.

## Mandatory repositories

```text
Core
/home/psychopatz/Zomboid/Workshop/psychopatzCore
HEAD 28647c99964b845087e8397622b7c374b4245372 (parent of this S6M7-S6M8 handoff)

Hoomans
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
HEAD a23890d67da3ddbd4173a5a00d69e75644fbedc1

DynamicTrading
/home/psychopatz/Zomboid/Workshop/DynamicTrading
HEAD f41df273b37057ebf99f689fb9e67bac6d47d07e
```

Reinspect Git state before edits. Preserve unrelated work.

## Small-model startup

Read only:

1. `PROGRESS.md`;
2. this file;
3. `CONVO_ENGINE.md`;
4. the one ROADMAP/spec section for the active chunk;
5. exact source/tests being changed.

Do not load the full documentation set unless the active chunk requires it.

## Core architecture

One coherent conversation family:

```text
family
├─ kind / namespace / id
├─ participants? / slots? / when?
├─ invoke
├─ execute?             # optional registered gameplay action
├─ affordance.label     # UI-only
├─ say                  # initiating actor speech
├─ reply
│  ├─ named_outcome
│  │  ├─ say
│  │  └─ after?
│  └─ ...
└─ after?
```

Numeric keys under `say` are stable wording realization handles only.

```json
"say": {
  "1": "Who are you?",
  "2": "What's your name?"
}
```

They are not semantic IDs.

A single realization may simply be:

```json
"say": "Who are you?"
```

Reply outcomes such as `known`, `unknown`, `accepted`, `rejected`,
`pending`, and `completed` carry semantic meaning.

Initiating `say.1` is never positionally paired with reply `say.1`.

## Button/speech rule

```text
affordance.label
= UI button description

say
= what the selecting actor actually says

invoke
= semantic meaning

reply.<outcome>.say
= responder speech
```

Player and NPC consume the same bound semantic affordance.

NPC choice uses semantic context/utility, not rendered text.

## CodeBuilder-only content workflow

Conversation content must be migrated/authored through the Core CodeBuilder
ConvoEngine authoring/migration path.

Allowed workflow:

```text
CodeBuilder preview/validate
→ CodeBuilder write canonical source
→ CodeBuilder build/regenerate
→ tests/audits
```

Do not manually manufacture dozens of JSON shards.

Do not manually edit or move generated runtime Lua/JSON.

Direct file edits are appropriate for the CodeBuilder implementation, tests,
and docs themselves.

## Source layout target

No extra language-name nesting:

```text
sources/conversation/
├─ manifest.json
├─ dialogue/
├─ behavior/
├─ beat/
└─ realization/
```

The current `psdl/` folder is migration input.

## Runtime namespace target

Current generated conversation path:

```text
<Owner>/Semantics/Generated/Conversation/PSDL/...
```

Final ConvoEngine-owned namespace:

```text
PsychopatzCore/ConvoEngine/...
PNC/ConvoEngine/...
DTCommon/ConvoEngine/...
```

Do not retain conversation-owned `Semantics`, `Generated`, `Conversation`,
or `PSDL` path wrappers.

This is scoped. Core `PsychopatzCore/Semantics/` also contains generic parser,
predicate, fuzzy/entity resolution, semantic IR, lexicon, and other reusable
semantic infrastructure. Those remain there unless S6M2A proves a module is
ConvoEngine-owned.

S6M2A must classify runtime modules/references by ownership before path edits.
S6M2B then changes Core routing/generator logic, migrates only proven
ConvoEngine-owned hand-authored runtime modules, regenerates all owners, updates
exact requires/tests, proves old-path caller zero, and removes old paths after
parity.

Generated provenance belongs in file headers, CodeBuilder manifests,
fingerprints, and lineage—not the folder name. Never manually move generated
files.

## Gameplay functions/results

ConvoEngine never embeds arbitrary Lua callbacks.

```text
invoke
→ optional execute registered action
→ bounded result.*
→ reply outcome
→ reply speech
```

Example:

```json
"execute": "pnc.companion.camp"
```

Core owns the generic action/result contract. Hoomans keeps the real camp
gameplay/server authority.

Read-only candidate discovery is separate from mutation.

This is S6M6, not the current chunk.

## What became true in S6M2B

- Updated CodeBuilder routing, naming, compiler, and registry emitters (`generation_ownership.py`, `catalog_naming.py`, `conversation_contract.py`, `conversation_compiler.py`, `psdl_compiler.py`, `conversation_registry.py`, `build.py`, `psdl_authoring_audit.py`) so all ConvoEngine-owned runtime output emits directly under `<Owner>/ConvoEngine/...` with semantic module names (zero `Catalog.lua` leaves), `CONVO_PLANS` / `ConvoPlan` / `appendConvoPlans`, and `build.py` prunes stale generated Lua before writing.
- Migrated proven ConvoEngine-owned runtime modules in Core (`PsychopatzCore/ConvoEngine/{DialogueFlow,DialogueRouter,DialogueState*,DialogueTurn,Foundation,FoundationRegistry,Offer,TextBinding}`), DynamicTrading (`DTCommon/ConvoEngine/...`), and ProjectHoomans (`PNC/ConvoEngine/...`) while keeping Core generic semantic infrastructure under `PsychopatzCore/Semantics/`.
- Regenerated 457 generated files across all three repositories via CodeBuilder, updated all Lua/Python callers and tests, and verified zero remaining Lua callers on removed `Semantics/Generated/Conversation`, `Conversation/PSDL`, `PSDLPlan`, and old `PsychopatzSemanticDialogue*` paths.
- Verification: Core Python `tools/semantic_harness/tests` 127/127 OK, `refactor_binding_smoke.py` PASS, all 12 Core Lua smoke tests PASS; DynamicTrading `tests/run_tests.py` PASS 89/89; ProjectHoomans `tests/run_tests.py` 1003/1020 PASS (17 pre-existing S1/S5 baseline failures recorded for S6M3-S8 closure, including `FlowGenerator_Registration` missing `projecthoomans:task_lifecycle` projection in `SocialContent_Core` from S5 `1c88d83c`); `test_generation_ownership.py` 7/8 PASS (1 pre-existing S5 fixture path `behaviors/social`).

## What became true in S6M3

- Extended CodeBuilder manifest loading, bucket migration (`SemanticLabAuthoringService.migrate_convo_engine_bucket` & `convo_engine_cli.py migrate-bucket`), assembly, and domain-level Lua module chunking (`moduleSourceShard` + byte-aware chunk splitting) so every bucket under `sources/conversation/` compiles from recursive `sourceRoots` / `externalSourceRoots`.
- Migrated all 106 `psdl/` buckets (1029 records) across PsychopatzCore, ProjectHoomans, and DynamicTrading via CodeBuilder into 688 coherent family shards under `sources/conversation/{behavior,beat,realization,dialogue}/...`, leaving zero `psdl/` directories in all three repositories.
- Regenerated 454 generated files cleanly via `build.py` (with `DTCommon` marked `optional: true` in Core `externalSourceRoots` so Hoomans-only compiler tests remain self-contained).
- Verified Core Python `tools/semantic_harness/tests` 129/129 OK, `refactor_binding_smoke.py` PASS, Core semantic Lua smokes 9/9 PASS, DynamicTrading `tests/run_tests.py` 89/89 PASS, ProjectHoomans `tests/run_tests.py` 1003/1020 PASS (exact pre-existing S1/S5 baseline).

## What became true in S6M4

- Normalized all remaining `psychopatz.semantic.dialogue-language.v1` numeric `.01/.1/.2` wording shards and style-sibling families (`.neutral/.warm/.terse/.guarded/.friendly`) + redundant `semantic.` prefixes into canonical `psychopatz.convo-engine.v1` family modules via CodeBuilder (`convo_engine_normalization.py`, `conversation_compiler.py`, `conversation_rendering.py`, `Foundation.lua`), leaving **0** `psychopatz.semantic.dialogue-language.v1` source files across all three repositories.
- Regenerated all Core, ProjectHoomans, and DynamicTrading ConvoEngine outputs via CodeBuilder, added `ConvoPlanFamily.install` fallback across `SpeechRealization.lua` / `Interaction/Presentation.lua` / `PNC_SemanticTacticalSpatialLanguage.lua`, fixed `ToolReplies.lua` & `PlayerEmote.lua`, updated Hoomans `ResponseCatalog/` / `Dialogue/` / `client/` callers, Core observatory/pilot fixtures, and test expectations atomically.
- Verification: Core Python `tools/semantic_harness/tests` 131/131 OK, `refactor_binding_smoke.py` PASS, Core semantic Lua tests 18/18 PASS; DynamicTrading `tests/run_tests.py` PASS 89/89; ProjectHoomans `tests/run_tests.py` 1012/1020 PASS (down from 17 pre-existing failures to 8 pre-existing S1/S5/SocialFlavorClient baseline failures); Kahlua2 static check 0 issues across all modified Lua files.

## What became true in S6M5

- Extended Core compiler, registry, and CodeBuilder normalization services (`convo_engine_exchange.py`, `conversation_registry.py`, `conversation_compiler.py`, `psdl_compiler.py`, `convo_engine_normalization.py`, `service.py`) to project `exchangeFamily.slots`, index `reply.<outcome>` (`Registry.CONVO_REPLY_INDEX` & `Registry.ConvoOutcome`), project `affordance` + `say` records into `Registry.UI`, preserve `textRows` without fallback duplicates, and provide validated `fold_suggestion_pair`, `fold_outcome_family`, and `shard_offers_to_families` transformations.
- Added Core `PsychopatzCore/ConvoEngine/Affordance.lua` and extended `Foundation.lua` and Hoomans `PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily.lua` to enforce strict `button_label` vs `spoken_action` vs `response` separation (no label→speech fallback), single-slot candidate expansion and `{slot.*.*}` binding, shared `"player"` / `"npc"` / `"participant"` affordance scoring, independent `reply.<outcome>` selection (plus `<id>.<outcome>` & `<id>.<outcome>.<subvariant>` installs), and cycle/hop-bounded `after.recommend` / `after.goto` / `end` / `resume`.
- Normalized Core (`question.knowledge`, `question.identity` known branch, sharded `core_check_in` + `core_identity`), Hoomans (`static_suggestion_text` 12 label+utterance families, `companion_check_in`, `health_content`, `companion_commands_lifecycle` 5 commands, `quest_content` 4 stages, `task_lifecycle` 7 tasks + `gift`), and DynamicTrading (`trade_conversation_suggestions` -> 8 offer families + `suggestions_recognition`) via CodeBuilder and regenerated 466 artifacts via `build.py`.
- Verification: Core Python `tools/semantic_harness/tests` 135/135 OK, `refactor_binding_smoke.py` PASS, Core semantic + S6M5 Lua tests 18/18 PASS; DynamicTrading `tests/run_tests.py` PASS 89/89; ProjectHoomans `tests/run_tests.py` 1012/1020 PASS (exact 8 pre-existing failures, 0 regressions); 0 Kahlua2 errors on edited Lua modules.

## What became true in S6M6

- Implemented the Core registered Semantic Action Contract / `execute` + bounded public `result.*` compiler/IR/runtime mechanism (`semantic_dialogue_ir.py`, `convo_engine_exchange.py`, `psdl_compiler.py`, `PsychopatzSemanticIR.lua`, `TextBinding.lua`, `ActionContract.lua`, `Affordance.lua`) rejecting arbitrary Lua/callbacks, enforcing `discoveryOnly` isolation, validating typed inputs and capability gates, correlating sync and async (`request_response`) completions with duplicate/stale suppression, and projecting fail-closed public `result.*` fields & bindings.
- Registered Hoomans `pnc.companion.camp` action contract & `pnc.camp.location_phrase` presentation resolver in `PNC/ConvoEngine/CampActionContract.lua` (required from `PNC/ConvoEngine/Foundation.lua`) routing exclusively through Hoomans' existing authoritative `PNC.Client.RequestSemanticTask` / `TaskRequestService.Submit` path and client-observed `camp_site` hint rules.
- Updated `command_camp.json` through `SemanticLabAuthoringService.write_convo_engine_source` and regenerated all 466 generated artifacts cleanly via `build.py`.
- Verification: Core Python `tools/semantic_harness/tests` 140/140 OK, `refactor_binding_smoke.py` PASS (5 changed Lua files), Core S6M5 + S6M6 Lua smokes PASS; DynamicTrading `tests/run_tests.py` PASS 89/89; ProjectHoomans `tests/run_tests.py` 1013/1021 PASS (`pnc_convo_engine_camp_action_smoke.lua` PASS, 10/10 camp/task filter pass, exact 8 pre-existing baseline failures, 0 regressions); 0 Kahlua2 errors across all 6 edited/created Lua files.

## What became true in S6M7-S6M8

- Enforced stale migration metadata stripping (`sourceSurface`, `migration`, `sourceCatalog`, `originalOwner`, `metadata.sourcePath`, `metadata.sourceProfile`) in `convo_engine_authoring.py` / `SemanticLabAuthoringService.write_convo_engine_source` and fixed cross-file `compile_convo_engine_sources` + `beat`-to-sibling-`behavior` validation in `psdl_compiler.py` / `service.py`.
- Cleaned stale migration metadata across all 436 Core/Hoomans and 2 DynamicTrading canonical ConvoEngine source files via `SemanticLabAuthoringService.write_convo_engine_source`, restored `opening.001..003` `metadata.textRows` in `social_settlement_admission.json`, and regenerated 466 runtime/translation files via `build.py`.
- Closed all 7 Hoomans ConvoEngine/semantic/translation/emote/gift/context regressions (Core `UI_PsychopatzConversation_Goodbye` in `EN/TL/Conversation/UI.json` + camelCase `{slot.*}` regex in `PsychopatzConversationText.lua`; Hoomans `DialogueBlocks.lua` compact `say`, `PNC_CompanionCommandInteractionQueue.lua` explicit player actor + synchronous pump, `PNC_CompanionCommandInteraction.lua` unique per-exchange correlation ID, `PNC_TranslationBootstrap.lua` + `_Segments.lua` `^semantic.` / `^UI_DT_Conversation_` / `DebugDiscoveryRawLabel`, `Gifts_Receive_Presentation.lua` nil-guards, `pnc_conversation_smoke.lua`, `pnc_semantic_context_smoke.lua`, `pnc_semantic_cognition_client_smoke.lua`).
- Added automated `convo_engine_s6m8_audit.py`, CLI `audit-s6m8`, service `run_convo_engine_s6m8_audit()`, and `test_convo_engine_s6m8_audit.py`.
- Verification: Core Python 144/144 OK, Core ConvoEngine S6M5/S6M6 Lua smokes PASS, `audit-s6m8` 0 violations across 566 family files & 0 diffs across 404 generated files in two-pass determinism check, Kahlua2 0 errors across 288 scanned Lua files, DynamicTrading 89/89 PASS, ProjectHoomans 1020/1021 PASS (only unrelated world-bootstrap `pnc_population_director_smoke.lua:316` fails).

## Immediate Next Chunk — S7

Responsibility:

> Upgrade Semantic Lab (`tools/semantic_harness/studio/`) to ConvoEngine-native authoring & live simulation/trace UX backed by `SemanticLabAuthoringService`, covering hierarchical family browsing, kind/namespace/family-id/slots/say/reply/`execute` authoring, player↔NPC & NPC↔NPC preview, and `affordance → speech → execute → result → reply` traces.

## Following bounded chunks

- **S8:** exhaustive three-repo acceptance.

## Safety

- no new branch;
- no reset/stash/discard of uncertain work;
- no broad staging;
- no push/PR/tag/release/publish without explicit authorization;
- accepted cross-repo phase commits: adopters first, Core last;
- do not call S8 complete until every gate is freshly proven.

Native Project Zomboid live/visual acceptance remains user-owned after
developer-side completion.
