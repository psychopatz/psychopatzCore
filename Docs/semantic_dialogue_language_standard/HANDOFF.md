---
handoff_schema: 2
checkpoint_mode: "clean_checkpoint"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
parent_head: "02ffe3e0df1265e9599d84f465f4478715259c4d"
participant_heads: "project-hoomans=a21cfd5f806abe9075d97f9dd9c774a43127b412;dynamic-trading=d7c888de62d6f90dcf6746a24e5f50d7f7346e1d"
state: "CLEAN_CHECKPOINT"
parent_status: "DEVELOPER_COMPLETE"
phase: "S8R — final ConvoEngine naming and truthful closure"
chunk: "COMPLETE — S0-S8 + S8R developer-side closure verified across all three repositories"
evidence: "TEST_VERIFIED_S8R5; DEVELOPER_COMPLETE_LIVE_PZ_USER_OWNED"
retrieval_tier: "verify"
updated_at: "2026-11-14"
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

Developer-side ConvoEngine **S0-S8 + S8R** work is **complete**. All S6/S7
mechanisms remain intact, all active PSDL output identity has been replaced with
`convo.*` / `pnc.convo.*` / `Conversation/Text/convo/...`, the S6M8/S8R audit and
bare CLI discovery are hardened, and all goal-owned normative documents are
committed cleanly.

## S8R final acceptance — 2026-11-14

All S8R1-S8R5 developer gates are complete and freshly verified:

```text
Core Python semantic-harness                150/150 PASS
Core Convo/Semantic/Conversation Lua         34/34 PASS
Core refactor_binding_smoke                  PASS (17 changed Lua files)
DynamicTrading                               89/89 PASS
ProjectHoomans                             1020/1021 (focused convo/psdl Lua 27/27 PASS)
Kahlua ConvoEngine trees                         0 errors (Core 52, Hoomans common 219 + 42.20 181, DT 5)
bare three-repo S6M8 audit                   ok=true
familyFilesChecked                             566
convoPlans                                     566
legacyNameViolations                             0
determinism files/diffs                    404 / 0
compiled.fingerprint                       cbb4cb3ed7fc811f24daf61d5cdc28a1eaadeca80bf3bf479fd46a6ac31ac2ac
```

The single Hoomans failure remains
`pnc_population_director_smoke.lua:316`. Fresh Git/dependency evidence confirms
neither that test nor PopulationDirector runtime changed in the ConvoEngine
migration (`git log` at `79114089`), and `Population` Lua has `0`
`ConvoEngine`/`Conversation` references. Do not weaken or modify it.

Active legacy identity eliminated across all three repos:

```text
template IDs:            convo.<family>.<role>...  (psdl.* = 0)
Hoomans text domains:    pnc.convo.<domain>...     (pnc.psdl.* = 0)
conversation text tree:  Conversation/Text/convo/... (Conversation/Text/psdl/ = 0)
Manifest/shard kind:     "ConvoEngine"             ("PSDL" = 0)
obsolete pane alias:     deleted tools/semantic_harness/studio/psdl_authoring_pane.py
```

## Mandatory repositories and residual worktrees

```text
Core (main — clean working tree on commit)
/home/psychopatz/Zomboid/Workshop/psychopatzCore

Hoomans (main)
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
HEAD a21cfd5f806abe9075d97f9dd9c774a43127b412
Preserved unrelated worktree dirt: docs/Jobs/* (11 pre-existing modified markdown files)

DynamicTrading (main)
/home/psychopatz/Zomboid/Workshop/DynamicTrading
HEAD d7c888de62d6f90dcf6746a24e5f50d7f7346e1d
Preserved unrelated worktree dirt: .architecture-refactor/output/architecture-audit.md, tools/providers/dt/__pycache__/
```

## Small-model startup

Read only:

1. `PROGRESS.md`;
2. this file;
3. `CONVO_ENGINE.md`;
4. S8R in `ROADMAP.md` plus only the one deeper naming/audit spec needed for the active edit;
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

This is accepted S6M6 history, not the current chunk.

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

## What became true in S7

- Added `tools/semantic_harness/codebuilder/convo_engine_studio_trace.py` and exposed `list_convo_engine_families()`, `list_convo_engine_action_contracts()`, and `simulate_convo_engine_family()` on `SemanticLabAuthoringService`.
- Replaced record-bucket PSDL UI in Semantic Lab with `ConvoEngineAuthoringPane` (`tools/semantic_harness/studio/convo_engine_authoring_pane.py`, mounted at `"ConvoEngine"` tab in `ui/studio_surface_builder.py`, with `PSDLAuthoringPane` preserved as thin subclass alias in `psdl_authoring_pane.py`), supporting family filtering/CRUD, reply outcome editing, registered `execute` contract picker, `after.recommend` picker, player<->NPC / NPC<->NPC simulation preview with separated `button_label` / `spoken_action` / `response`, full `predicate -> affordance -> invoke -> speech -> execute -> result -> reply -> after` trace, and in-UI S6M8 audit.
- Verification: Core Python `tools/semantic_harness/tests` 146/146 OK (`test_convo_engine_studio_s7.py` + `test_convo_engine_s6m8_audit.py` PASS).

## What was verified before S8R reopening

- Completed fresh exhaustive three-repository acceptance after S7 commit `2d667ccf98f50560c488fa4bab466ac10bfce0b4`:
  - Core Python suite (`python3 -m unittest discover -s tools/semantic_harness/tests -p "test_*.py" -q`): `146/146` OK.
  - Three-repository S6M8 audit with two-pass determinism (`convo_engine_cli.py audit-s6m8 --check-determinism`): `"ok": true`, `owners: ["PsychopatzCore", "ProjectHoomans", "DTCommon"]`, `familyFilesChecked: 566`, `psdlDirectories: 0`, `catalogLuaLeaves: 0`, `legacyRuntimeDirectories: 0`, `compiled.fingerprint: e87edeeb6127568c6a665c311730780b1d2682cc4f2ba18f1c5cb5e4309870bf`, `patterns: 56`, `uiDefinitions: 21`, `convoPlans: 566`, `determinism.diffs: []` across `404` files, `violationCount: 0`.
  - Core ConvoEngine/Semantic/Conversation Lua suites: `29/29` PASS.
  - `DynamicTrading/tests/run_tests.py`: `89/89` PASS.
  - `ProjectHoomans/tests/run_tests.py`: `1020/1021` PASS (single unrelated failure at `pnc_population_director_smoke.lua:316` world-bootstrap check; zero ConvoEngine/Conversation/Semantic references in `Director/Population/` or `Population/`).
  - Kahlua2 static verification (`pz_verify.py --kahlua --severity ERROR`): `0` errors across `PsychopatzCore/ConvoEngine` (`52` files), `PNC/ConvoEngine` (`219` files), and `DTCommon/ConvoEngine` (`5` files).

## What became true in S8R

- **S8R1 (`convo_engine_psdl_inventory.py`, `S8R1_PSDL_CLASSIFICATION.json`):** inventoried and classified all `279` first-party `PSDL`/`psdl` references into `235` `active_convo_engine_identity_or_output`, `42` `bounded_migration_reader_or_test_fixture`, `1` `generic_semantic_infrastructure`, and `1` `obsolete_compatibility_alias`.
- **S8R2 (compiler/source/caller naming closure):** switched Core `psdl_compiler.py` (`labelKey`, `utteranceKey`, turn `templateID`, default realization path) and `conversation_compiler.py` (`"ConvoEngine"` manifest/shard kind) to `convo.*` / `"ConvoEngine"`; deleted zero-caller `tools/semantic_harness/studio/psdl_authoring_pane.py`; migrated all `38` Hoomans `pnc.psdl.*` families via `SemanticLabAuthoringService.migrate_legacy_text_identity`; updated `DialogueBlocks.lua`, 3 Hoomans composer/definition runtime callers, `DTHoomans_Conversation.lua` (`convo_referral_plan_unavailable`), DT `provider.json`, and tests; regenerated all owners cleanly via CodeBuilder `build.py` (moving `76` EN/TL translation files to `Conversation/Text/convo/`); drove active legacy-name leakage down to `0` violations across all three repositories.
- **S8R3 (`convo_engine_s6m8_audit.py`, `service.py`, `convo_engine_cli.py`, `test_convo_engine_s6m8_audit.py`):** integrated `scan_active_legacy_name_leakage` (`legacyNameViolations`) into `audit_convo_engine_workspace`, added `discover_convo_engine_repositories` + `require_all_owners=True` so bare `convo_engine_cli.py audit-s6m8 --check-determinism` discovers all three owners unambiguously or fails closed (`missing_mandatory_repository` / `CompileError`), and added negative-leakage, fail-closed discovery, and bare CLI regression tests.
- **S8R4 & S8R5:** reconciled and committed the full goal-owned normative ConvoEngine documentation set in `psychopatzCore`, committed `DynamicTrading` and `ProjectHoomans` changes first on `main`, and verified fresh three-repo regeneration, test suites, Kahlua2 static checks, `git diff --check`, and final repository state.

## Remaining user-owned live verification

- Native Project Zomboid live SP/MP in-game acceptance (UI rendering, conversation flow/timing, sound/emote/CAMP UX feel) remains user-owned.

## Safety

- no new branch;
- no reset/stash/discard of uncertain work;
- no broad staging;
- no push/PR/tag/release/publish without explicit authorization;
- accepted cross-repo phase commits: adopters first, Core last;
- do not call S8 complete until every gate is freshly proven.

Native Project Zomboid live/visual acceptance remains user-owned after
developer-side completion.
