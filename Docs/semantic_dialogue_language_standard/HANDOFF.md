---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
phase_commit: "self"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
participant_heads: "project-hoomans=d188b3f4fbe0f77b228254ac94dc8cc3db2f2a15;dynamic-trading=800c3808f736b310ee2c6371e0c4bcebf37fb736"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S6M — ConvoEngine normalization"
chunk: "S6M5 — Affordance/label vs say, named reply outcomes, slots, and chaining normalization"
evidence: "TEST_VERIFIED"
retrieval_tier: "verify"
updated_at: "2026-11-14T09:30:00Z"
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
HEAD 4b7e45e7 (parent of this S6M4 commit)

Hoomans
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
HEAD d188b3f4fbe0f77b228254ac94dc8cc3db2f2a15

DynamicTrading
/home/psychopatz/Zomboid/Workshop/DynamicTrading
HEAD 800c3808f736b310ee2c6371e0c4bcebf37fb736
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

## Immediate Next Chunk — S6M5

Responsibility:

> Normalize dynamic slots (`$slot.*`), button `affordance.label` vs initiating `say`, named independent `reply` outcomes, shared player/NPC affordance reuse, and recommendation/chaining (`after.recommend` / `after.goto`) through CodeBuilder, keeping runtime callers/tests green.

## Following bounded chunks

- **S6M3-S6M5:** source migration/sharding/normalization through CodeBuilder (`say` keys, outcomes, styles, affordances, recommendations).
- **S6M6:** registered action/result contract + CAMP parity.
- **S6M7-S6M8:** metadata cleanup + regeneration/audit/regression closure.
- **S7:** final ConvoEngine Semantic Lab UX.
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
