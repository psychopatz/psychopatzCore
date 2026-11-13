---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
phase_commit: "self"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
participant_heads: "project-hoomans=c10b3f94f7a83b77547fed55d4da676823c42b75;dynamic-trading=f4a68eb971910092409d8bff447f50a15ffe296a"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "S6M — ConvoEngine normalization"
chunk: "S6M1B — headless CodeBuilder create/edit/move/shard/write command/API"
evidence: "TEST_VERIFIED"
retrieval_tier: "verify"
updated_at: "2026-11-13T09:56:00Z"
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
HEAD 9d9f9406666fda1e9e1a53f835890d2710fec399

Hoomans
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
HEAD c10b3f94f7a83b77547fed55d4da676823c42b75

DynamicTrading
/home/psychopatz/Zomboid/Workshop/DynamicTrading
HEAD f4a68eb971910092409d8bff447f50a15ffe296a
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

## What became true in S6M1A

- Implemented `tools/semantic_harness/codebuilder/convo_engine_exchange.py` and wired it into `semantic_dialogue_ir.py`, `psdl_compiler.py`, `service.py`, and `__init__.py`.
- Added canonical schema `psychopatz.convo-engine.v1` with bounded read-only compatibility for `psychopatz.semantic.dialogue-language.v1` (rejected when `allow_legacy_schema=False` or when compact exchange-family fields use the legacy schema).
- Added compact exchange-family support (`kind / namespace / id`, direct single `say`, stable sparse numeric `say` keys, independent named `reply` outcomes, `invoke`, `affordance.label`, `after`, `slots.*.suggest/limit`).
- Normalized explicit runtime text roles (`button_label`, `spoken_action`, `response`) with fail-closed rejection of `button_label -> spoken_action` fallback and rejection of semantic references targeting wording realization keys.
- Exposed `preview_convo_engine_document`, `validate_convo_engine_document`, and `preview_convo_engine_sources` on `SemanticLabAuthoringService` and verified `tools/semantic_harness/tests/fixtures/convo_engine_ask_person.json`.
- Verification: `python3 -m unittest discover -s tools/semantic_harness/tests -p "test_*.py"` ran 120 tests, all passing.

## Immediate Next Chunk — S6M1B

Responsibility:

> Add a small headless CodeBuilder ConvoEngine create/edit/move/shard/write
> command/API and prove agents can perform validated content migration and
> write a validated fixture without raw filesystem JSON generation.

Do not:

- migrate production content yet;
- change runtime output paths yet;
- implement action/results yet;
- rewrite Semantic Lab;
- hand-edit generated Lua.

Pass gate:

- headless CLI + service methods create, edit, move/shard, validate, and write a canonical ConvoEngine fixture;
- focused tests pass.

## Following bounded chunks

- **S6M1B:** small headless CodeBuilder create/edit/move/shard/write API.
- **S6M2A:** classify ConvoEngine-owned runtime modules versus generic semantic infrastructure.
- **S6M2B:** migrate proven conversation runtime to `<Owner>/ConvoEngine/...` + semantic generated filenames through root-cause routing/regeneration.
- **S6M3-S6M5:** source migration/sharding through CodeBuilder.
- **S6M6:** registered action/result contract + CAMP parity.
- **S6M7-S6M8:** metadata cleanup + regeneration/audit.
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
