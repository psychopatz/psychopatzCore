# ConvoEngine — Compact Agent Contract

## What it is

**ConvoEngine** is the PsychopatzCore-owned conversation authoring/compiler
system shared by PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon.

The old name **PSDL** meant **Psychopatz Semantic Dialogue Language**. Treat
`PSDL` / `psdl` as a migration-era internal name only. New documentation,
new APIs, new source layout, and new runtime layout should use **ConvoEngine**.

Do not perform a blind repository-wide rename. Migrate internal identifiers only
through tested Core compiler/service changes and remove the old alias after
caller-zero.

## Naming boundary

New ConvoEngine-owned public/runtime identifiers use **ConvoEngine**, not
`PSDL`, `SemanticDialogue`, or a conversation-owned `Semantics` package
wrapper.

Target examples:

```text
schema:
psychopatz.convo-engine.v1

runtime:
PsychopatzCore/ConvoEngine/...
PNC/ConvoEngine/...
DTCommon/ConvoEngine/...

conversation-owned symbols:
PsychopatzConvoEngine...
PNC_ConvoEngine...
DTCommon_ConvoEngine...
```

Do not blindly rename the word `semantic` everywhere. Semantic meaning remains
a real concept inside the engine (`intent`, semantic family, predicates,
semantic candidates), and generic Core semantic services remain named/located
under `PsychopatzCore/Semantics/` when they are broader than conversation.

Legacy source/schema/API names such as
`psychopatz.semantic.dialogue-language.v1`, `PSDL`, or
`*SemanticDialogue*` may be read temporarily by explicit migration adapters.
New writes use ConvoEngine names. Remove old aliases/readers after migrated
caller/source zero is proven.

### Steady-state text/template naming

ConvoEngine naming applies to text identity as well as filesystem/module names.

Maintained ConvoEngine source/output must use:

```text
template IDs:
  convo.<family>.<role>...

Hoomans text domains:
  pnc.convo.<domain>...

conversation text tree:
  Conversation/Text/convo/...
```

Maintained ConvoEngine source/generated/runtime/translation output must not emit:

```text
psdl.*
pnc.psdl.*
Conversation/Text/psdl/
```

A legacy-name reference is allowed only when it is explicitly classified as a
bounded migration reader/test fixture. It must not be used for new writes or
steady-state generated output.

Do **not** confuse this with generic semantic infrastructure. A genuinely shared
Core contract such as `psychopatz.semantic.dialogue-ir.v1` may remain semantic
when its ownership audit proves it is provider-neutral infrastructure broader
than ConvoEngine.

The exhaustive S8 audit must scan canonical source, generated Lua,
translations, manifests/registries and first-party runtime callers for active
legacy-name leakage.

## One authoring path

Conversation content is authored through **CodeBuilder / ConvoEngine authoring
services**, not by manually constructing runtime Lua or bulk-writing source JSON
by hand.

Allowed agent workflow:

```text
inspect canonical source
→ use CodeBuilder ConvoEngine authoring/migration API
→ validate
→ preview
→ write canonical source
→ run CodeBuilder build
→ regenerate runtime artifacts
→ run tests/audits
```

Agents may directly edit **CodeBuilder implementation/tests/docs** when changing
the compiler itself. They must not bypass the authoring/migration API for mass
conversation-content creation or sharding.

Generated runtime files are never authored manually.

## Compact source model

One file owns one coherent semantic exchange family.

```text
family
├─ kind / namespace / id
├─ participants? / slots? / when?
├─ invoke
├─ execute?              # registered gameplay action
├─ affordance.label      # UI-only button label
├─ say                   # initiating actor speech
├─ reply                 # named semantic outcomes
│  ├─ known / unknown / accepted / rejected / ...
│  │  ├─ say
│  │  └─ after?
│  └─ ...
└─ after?                # default continuation
```

Stable numeric keys under `say` are wording realization handles only:

```json
"say": {
  "1": "Who are you?",
  "2": "What's your name?"
}
```

They are not semantic IDs. A single realization may simply be:

```json
"say": "Who are you?"
```

## Button / speech / meaning

Keep these separate:

```text
affordance.label
= UI label
= "Ask about Bob"

say
= actual initiating speech
= "Have you seen Bob lately?"

invoke
= semantic meaning

reply.<outcome>.say
= responder speech
```

Player and NPC consume the same bound semantic affordance instance.

## Gameplay functions

Never author arbitrary Lua callbacks.

```text
invoke
→ optional execute registered action
→ bounded public result.*
→ named reply outcome
→ reply speech
```

Example:

```json
"execute": "pnc.companion.camp"
```

Core owns the generic action/result contract. Hoomans keeps the actual camp
gameplay/server authority.

Read-only candidate discovery is separate from mutation.

## Source layout

Do not add another language-name nesting layer.

Target canonical CodeBuilder source:

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ dialogue/
├─ behavior/
├─ beat/
└─ realization/
```

Adopter provider roots follow the same layout beneath their own
`sources/conversation/`.

Do not create new `psdl/`, `convo_engine/`, `generated/`, `legacy/`, or
PartNN authoring folders.

## Runtime layout

Generated status is provenance, not a directory.

Target runtime namespace:

```text
PsychopatzCore/ConvoEngine/
PNC/ConvoEngine/
DTCommon/ConvoEngine/
```

Example Core layout:

```text
PsychopatzCore/ConvoEngine/
├─ Registry.lua
├─ Manifest.lua
├─ Dialogue/
├─ Behavior/
├─ Beat/
├─ Realization/
├─ Patterns/
├─ UI/
└─ ...
```

Do not emit:

```text
.../Semantics/Generated/Conversation/...
.../Semantics/Conversation/...
.../Conversation/PSDL/...
```

The name `ConvoEngine` already supplies the conversation/runtime meaning, so
both `Semantics` and `Conversation` are redundant path taxonomy for this
subsystem.

This does **not** rename all generic semantic infrastructure. Core-wide NLU,
predicate, fuzzy/entity matching, semantic IR, and other reusable semantic
mechanisms may remain under `PsychopatzCore/Semantics/` when they are broader
than ConvoEngine. Conversation-owned runtime/adapters move under ConvoEngine.

Generated files still contain a generated-file header and are tracked by the
CodeBuilder manifest/fingerprint/lineage system.

The path flattening must happen in Core owner-routing/generator code, followed
by one atomic regeneration and caller/test update. Never move generated files
manually.

## Small-model execution rules

This job must remain safe for Luna-class agents.

An agent should read only:

1. `PROGRESS.md`;
2. `HANDOFF.md`;
3. this compact contract;
4. the one deep specification relevant to its active chunk;
5. exact source/tests it is changing.

Do not require a small agent to ingest every ConvoEngine document before each
edit.

Each chunk must have:

- one root-cause responsibility;
- explicit files/mechanisms to change;
- explicit forbidden shortcuts;
- focused tests;
- a clear pass/fail gate.

Do not combine mass source sharding, runtime path migration, compiler grammar,
action-result implementation, and Semantic Lab UI into one unbounded patch.

## Required implementation order

1. Core ConvoEngine compiler/service contract.
2. Headless CodeBuilder authoring/migration command/API capable of creating,
   editing, moving/sharding, validating, and writing final exchange families.
3. Classify runtime modules as ConvoEngine-owned versus generic semantic infrastructure.
4. Migrate ConvoEngine-owned runtime routing from `Semantics/Generated/Conversation/...` (and conversation-specific `Semantics/...` modules where proven) to `<Owner>/ConvoEngine/...`; keep genuinely generic semantic infrastructure under Core `Semantics/`.
5. Remove extra runtime `Conversation` / `PSDL` path segments.
6. Semantic generated-module naming.
7. Migrate source through the CodeBuilder migration path.
8. Regenerate all three repositories.
9. Update exact first-party requires/tests atomically.
10. Verify no old ConvoEngine-owned `Semantics/...` path callers remain.
11. Continue reply/action-result/Semantic Lab acceptance.

The above runtime/compiler/content migration order and **S8R** final
naming/audit/document closure are complete:

1. classified all remaining legacy PSDL names (`S8R1_PSDL_CLASSIFICATION.json`);
2. removed active `psdl.*` / `pnc.psdl.*` /
   `Conversation/Text/psdl/` output identity through Core/CodeBuilder root
   causes (`convo.*` / `pnc.convo.*` / `Conversation/Text/convo/`);
3. hardened `convo_engine_s6m8_audit.py` and `convo_engine_cli.py` repository
   discovery / fail-closed checks;
4. regenerated/retested all three repositories;
5. committed the S8R normative documentation checkpoint.

Do not reopen source sharding, compact family syntax, action contracts, or
runtime ownership without a concrete regression.

**S9 harness convergence and S9R post-S9 closure are complete and accepted.**
S9 established the accepted Semantic Lab model, removed the major duplicate
legacy-authoring/runtime-simulation authorities, moved Studio/CLI onto shared
`OperationRegistry` / `ConvoTransaction` / production-Lua `ConvoProbe` /
`BuildPlanner` ports under `HarnessContext`, and kept legacy datasets/schemas
compatibility-gated. See `PROGRESS.md` and `SEMANTIC_HARNESS_AUDIT.md` for
verified acceptance evidence.

## Hard rules

- No hand-written generated Lua.
- No manual bulk content-file creation when CodeBuilder migration/authoring can
  own the operation.
- No broad alias registry for old generated paths.
- No semantic meaning derived by reparsing rendered strings.
- No arbitrary Lua execution from conversation source.
- No push/publish without explicit authorization.
- Preserve unrelated work in all three repositories.
