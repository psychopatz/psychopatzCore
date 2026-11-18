# ConvoEngine Naming and Source Layout Standard

## Purpose

This document is normative for ConvoEngine source organization, semantic identity,
stable realization keys, reply outcomes, and generated module naming.

The goal is to keep dialogue easy to expand, inspect, translate, test and edit
without reopening unrelated content or forcing agents to read monolithic files.

## Ownership

PsychopatzCore owns the ConvoEngine compiler/normalizer, generic validation,
namespace/realization/reply rules, source modularity audit, generated naming helpers and
shared authoring service.

ProjectHoomans and DynamicTrading/DTCommon own adopter-specific ConvoEngine conversation records.
They must consume the Core rules and generator rather than duplicating them.

## Schema identity

Steady-state first-party source uses:

~~~text
psychopatz.convo-engine.v1
psychopatz.convo-engine.package.v1
~~~

Do not add new `psychopatz.psdl.*` source/package schemas or create a
ConvoEngine v2 during the pre-release dataset modernization. Compactness is a
source-form/compiler-stage property under ConvoEngine v1, not a separate schema
identity.

## Canonical CodeBuilder conversation roots

Do not add a language-name wrapper below the already-explicit
`sources/conversation/` root.

Core:

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ dialogue/
├─ behavior/
├─ beat/
└─ realization/
```

ProjectHoomans:

```text
tools/providers/pnc/codebuilder/sources/conversation/
├─ manifest.json
├─ dialogue/
├─ behavior/
├─ beat/
└─ realization/
```

DynamicTrading follows the same layout beneath its provider CodeBuilder root.

The existing `psdl/` directory is migration input. New final source should
not introduce `psdl/` or `convo_engine/` nesting because the parent
directory already identifies the conversation authoring domain.

## Primary source rule — one file, one semantic family

A source file owns one coherent semantic family/module.

Good:

```text
dialogue/social/argument/deescalate.json
dialogue/social/argument/retaliate.json
dialogue/social/scene/horde/prompt.json
dialogue/social/scene/horde/brave_reply.json
dialogue/task/fetch/lifecycle.json
dialogue/command/follow/replies.json
beat/social/argument.json
behavior/social/conflict/warn.json
```

Bad:

```text
dialogue/social.json
dialogue/social_content.json
dialogue/social_interaction_scene_horde_work.json
dialogue/social_interaction_scene_travel_news.json
dialogue/task_tool_replies.json
dialogue/core_semantic_responses.json
director/social.json
```

A file may contain many initiating/reply realization alternatives and many
localized phrase alternatives when they all belong to the same semantic family.

Do not enforce one-record-per-file. Do enforce one-family-per-file.

## Hierarchical organization

Do not place all adopter dialogue flat under `sources/conversation/dialogue/`.

Use stable semantic domain/subdomain directories:

```text
dialogue/
├─ social/
│  ├─ greeting/
│  ├─ argument/
│  ├─ reaction/
│  ├─ memory/
│  └─ scene/
│     ├─ horde/
│     ├─ post_combat/
│     ├─ excursion/
│     ├─ news/
│     └─ work/
├─ task/
│  ├─ fetch/
│  ├─ eat/
│  ├─ drink/
│  └─ refill/
├─ command/
│  ├─ follow/
│  ├─ stay/
│  ├─ camp/
│  └─ return_home/
├─ health/
├─ medical/
├─ navigation/
├─ combat/
└─ world/
```

Create a new directory only for stable semantic ownership, not arbitrary file
count or migration history.

## File naming

Use lowercase `snake_case.json` names describing the semantic family:

```text
deescalate.json
brave_reply.json
lifecycle.json
check_in.json
person_location.json
warning.json
```

Avoid migration/bucket names:

```text
social_content.json
core_semantic_responses.json
task_tool_replies.json
compatibility_content.json
Generated.json
Part03.json
FinalFixed.json
```

A broad name such as `replies.json` or `lifecycle.json` is acceptable only
inside a semantic directory that identifies the owner, for example:

```text
command/follow/replies.json
task/fetch/lifecycle.json
```

## Compact exchange-family source

Ordinary dialogue/content files own one coherent semantic exchange family.
Identity is written once at the root.

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "invoke": { ... },
  "affordance": { ... },

  "say": {
    "1": "...",
    "2": "..."
  },

  "reply": {
    "known": {
      "say": {
        "1": "...",
        "2": "..."
      }
    },
    "unknown": {
      "say": "..."
    }
  }
}
```

The canonical family identity remains:

```text
social.knowledge.ask_person
```

Do not append `.1`/`.2` merely because there are multiple phrasings.

For adopter-owned files, owner normally derives from the manifest/shard owner
or `defaultOwner`; explicit file owner is needed only when routing differs or
would otherwise be ambiguous.

Filesystem path improves discoverability but is not canonical identity.

## Canonical ID naming

Canonical IDs are concise lowercase semantic identities.

Good:

```text
social.argument.deescalate
social.scene.horde.prompt
task.fetch.completed
command.camp
behavior.social.warn
beat.social.argument
realization.social.acknowledge
```

Meaningful semantic outcomes may be addressed by family + outcome where the
runtime contract requires it, for example conceptually
`command.camp/rejected`; wording realization numbers are not semantic IDs.

Avoid redundant implementation/history or wording-only identity fragments:

```text
semantic.interaction.argument.deescalate.guarded
semantic.question.wellbeing.default.neutral
semantic.tool_reply.order_camp.1
generated.*
legacy.*
codebuilder.*
runtime.*
```

The language is already semantic; routine dialogue IDs must not repeat
`semantic.`.

## Stable realization-key contract

Numeric keys remain intentionally supported under text realization roles:

```json
"say": {
  "1": "...",
  "2": "...",
  "4": "..."
}
```

A realization key means:

> a stable authored wording alternative for one semantic role.

It is not semantic family identity and is not a PartNN shard.

A family with one realization should normally stay compact:

```json
"say": "Who are you?"
```

When multiple alternatives exist, numeric keys provide editing/translation/
diagnostic stability. Gaps may remain after deletion; do not renumber surviving
keys merely to make them contiguous.

Semantic callers never reference wording keys.

## Family versus reply outcome versus realization versus style

These are different dimensions.

### Semantic family

What the interaction means:

```text
social.knowledge.ask_person
```

### Reply outcome

A meaningful responder state:

```text
known
unknown
refused
accepted
rejected
pending
completed
```

### Realization key

A stable wording alternative inside one initiating or reply `say` role:

```text
say.1
say.2
reply.known.say.1
reply.known.say.2
```

These keys do not become global semantic IDs.

### Style/context realization

Neutral, warm, terse, guarded, personality/relationship context, etc. normally
belongs inside one realization through variants + shared predicates.

Do not create four semantic families merely because one realization supports:

```text
neutral
warm
terse
guarded
```

unless those names genuinely represent independently referenced semantic
meaning.

### Phrase alternatives

Multiple localized phrasings inside one style/variant remain phrase arrays.
They do not require additional semantic IDs.

## Variant naming

Variant IDs describe style/context, not semantic family identity:

```text
neutral
warm
guarded
terse
aggressive
fearful
friendly
trusted
withdrawn
```

Use `known`, `unknown`, `accepted`, etc. as reply outcomes when they
represent response meaning rather than mere wording style.

Phrase list identity may be generated internally. Authors should not need
`neutral.01` through `neutral.10` unless an individual phrase truly has an
external stable identity.

## Participant/reference naming

Use actor-neutral references:

```text
speaker
addressee
target
initiator
observer
participants
slot.<semantic_name>
reference.<semantic_name>
```

Do not use `npc1`, `playerChar`, `targetNPC`, etc. in reusable source.

## Relationship naming

Directional relationship paths remain explicit:

```text
relationship.speakerToAddressee
relationship.addresseeToSpeaker
```

## Beat and behavior organization

Do not keep all social behaviors and beats in one `director/social.json`.

Prefer independently understandable files:

```text
behavior/
  social/
    conflict/
      warn.json
      challenge.json
      deescalate.json
      retaliate.json
    acknowledge/
      memory.json
      news.json

beat/
  social/
    argument.json
    reconciliation.json
    suspicious_first_contact.json
```

Beats reference reusable behavior IDs; wording remains dialogue/realization
content.

## Runtime module naming and namespace migration

CodeBuilder-generated Lua is downstream-only and must never be hand-edited.

Generated status is provenance, not a folder name. The current conversation
migration path:

```text
<Owner>/Semantics/Generated/Conversation/PSDL/...
```

must converge to the subsystem namespace itself:

```text
<Owner>/ConvoEngine/...
```

Examples:

```text
source:
sources/conversation/dialogue/social/argument/deescalate.json

runtime:
<Owner>/ConvoEngine/Dialogue/Social/Argument/Deescalate.lua
```

```text
source:
sources/conversation/dialogue/social/scene/horde/brave_reply.json

runtime:
<Owner>/ConvoEngine/Dialogue/Social/Scene/Horde/BraveReply.lua
```

Remove redundant conversation-owned runtime path segments `Semantics`,
`Generated`, `Conversation`, and `PSDL`.

This rule is scoped to ConvoEngine-owned runtime. Do **not** rename generic Core
semantic infrastructure merely because it currently lives under
`PsychopatzCore/Semantics/`. Parser/NLU, predicates, fuzzy/entity matching,
semantic IR, and other reusable non-conversation semantic mechanisms retain
their semantic namespace unless a separate evidence-backed refactor says
otherwise.

Generated provenance remains explicit in file headers, CodeBuilder manifests,
fingerprints, and source-lineage reports.

### Text/template namespace

Filesystem/module naming is not sufficient by itself. Maintained ConvoEngine
text identity must also converge on ConvoEngine naming.

Steady state:

```text
generated template IDs:
  convo.<family>.<role>...

ProjectHoomans textDomain:
  pnc.convo.<domain>...

conversation text tree:
  Conversation/Text/convo/...
```

Do not emit or newly author:

```text
psdl.*
pnc.psdl.*
Conversation/Text/psdl/
```

During S12, remaining first-party PSDL names are migration findings only. After
source/caller zero, they are not allowed in maintained ConvoEngine source,
package descriptors, generated output or first-party runtime callers. Generic
provider-neutral Semantic IR contracts are a separate ownership class and are
not renamed merely because they contain the word `semantic`.

Translation/text-path migration follows the same root-cause rule as Lua:
change canonical source/compiler routing and exact first-party callers, then
regenerate. Never rename generated translation output by hand.

Do **not** generate steady-state leaves such as:

```text
.../CombatBanterWeaponKillBrave/Catalog.lua
.../SocialInteractionArgument/Catalog.lua
```

The literal leaf `Catalog.lua` is too vague and hides the semantic module.

The ConvoEngine generator must reuse/extend Core collision-safe naming helpers
in `catalog_naming.py`; do not create a second naming algorithm.

Path migration must be root-cause-first: update Core owner-prefix/generator
routing, regenerate all three owner outputs, update exact first-party
requires/tests atomically, prove old-path caller zero, then remove old generated
trees. Never manually move generated files.

If a coherent generated module exceeds a runtime budget, first review the
source semantic boundary. Do not create meaningless `Part02` or `Catalog02`
files. Any unavoidable generated chunking must remain deterministic,
source-lineage-aware and semantically identifiable.

## Migration metadata cleanup

Steady-state ConvoEngine source should derive routine metadata rather than repeat migration
history.

Normally derive:

- source lineage from actual compiler source path;
- owner from document/provider ownership;
- semantic family from namespace + local ID;
- canonical response/template identity from family + semantic role/outcome + realization key only where a stable external seam truly needs it;
- category from semantic namespace when no external runtime contract requires
  an explicit value.

Legacy `sourceSurface`, duplicated `contentOwner`, and redundant
`responseTemplateID` metadata must be removed once their actual consumers are
migrated to derived compiler projections.

Do not remove metadata blindly. Prove caller/runtime parity first.

## Modularity audit rules

The Core audit must validate semantic structure, not only file bytes.

Required checks:

- one semantic family/module per source file;
- namespace/path agreement;
- valid stable `say` realization-key identity;
- named semantic reply outcomes;
- no routine redundant `semantic.` prefix;
- style/context duplication that should be nested under a realization;
- stale deleted-source `sourceSurface` metadata;
- derivable/redundant `responseTemplateID`;
- broad bucket filenames spanning unrelated families;
- generated `Catalog.lua` leaves;
- source/generated lineage parity.

Size is a secondary review signal.

A larger coherent single-family file may be valid. A small file mixing unrelated
families is not.

## Affordance and chaining placement

Reusable recommendation/button semantics live with the target semantic family.

A suggestible family may add root:

```text
invoke
affordance
```

Callers chain with:

```text
after.recommend
after.goto
after.end
after.resume
```

Do not create a separate static-suggestion source merely to hold UI labels,
initiating speech, reply speech, semantic frames, or recommendation grouping
already owned by the target family. UI label belongs in `affordance.label`;
initiating speech belongs in family `say`; responder speech belongs in named
`reply.<outcome>.say`.

Optional gameplay work belongs in a registered typed `execute` contract, not
in arbitrary callback fields. See `CHAINING_AND_AFFORDANCES.md` and
`ACTIONS_AND_RESULTS.md`.

## Translation keys

Translation keys are derived from canonical family + text role + stable
realization key (when present) + local style/turn/offer identity.

Locale does not belong in canonical semantic IDs.

## Migration naming rule

Move a migrated family directly to its final namespace/path/ID.

Do not create:

```text
*.v2
*.psdl
*.new
*.migrated
Legacy/
Compat/
Old/
PartNN/
```

as steady-state first-party authoring.

When renaming current first-party IDs, inventory callers first, update
references/tests/generated mappings atomically, prove old-ID caller zero, then
remove the old identity. Do not add a broad permanent alias registry.

Explicit external compatibility seams may keep narrowly-scoped adapters when
required.

## Discoverability rule

A coding agent changing one semantic family should normally need:

1. that family's ConvoEngine source file;
2. shared language/runtime contract;
3. focused tests.

It should not need to open a giant social/task catalog or unrelated families.

A developer browsing generated Lua should be able to infer semantic purpose
from the path and filename without opening a generic `Catalog.lua`.
