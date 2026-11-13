---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
phase_commit: "self"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
participant_heads: "project-hoomans=a92c83a78606bc99136d193baca90a55d693ff84;dynamic-trading=87435bacae563750f87cb7c7a2ba5b4b62bc081c"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S6M — ConvoEngine normalization"
chunk: "S6M3 — CodeBuilder source sharding and canonical normalization"
evidence: "TEST_VERIFIED"
retrieval_tier: "verify"
updated_at: "2026-11-13T18:43:00Z"
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
HEAD f695be0 (parent of this S6M2B commit)

Hoomans
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
HEAD a92c83a78606bc99136d193baca90a55d693ff84

DynamicTrading
/home/psychopatz/Zomboid/Workshop/DynamicTrading
HEAD 87435bacae563750f87cb7c7a2ba5b4b62bc081c
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

## Immediate Next Chunk — S6M3

Responsibility:

> Shard and migrate canonical ConvoEngine source content through the CodeBuilder
> authoring/migration API/CLI (`one file = one coherent semantic family`) under
> `sources/conversation/{dialogue,behavior,beat,realization}/...`, eliminating bulk
> `psdl/*` migration buckets without manual JSON manufacturing.

Pass gate:

- Source shards live cleanly under `sources/conversation/` without giant multi-family buckets;
- CodeBuilder preview/validation/build/regeneration passes cleanly with tests.

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
