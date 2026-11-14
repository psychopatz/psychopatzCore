# Architecture — ConvoEngine

## Status and authority

**ConvoEngine** is the normative first-party conversation authoring/compiler system for **PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon**.

The previous name **PSDL** meant **Psychopatz Semantic Dialogue Language**. `PSDL` / `psdl` is now a migration-era internal alias only; new public documentation, APIs, source layout, and runtime layout use **ConvoEngine**. Do not perform an unsafe blind rename—remove the old alias through tested compiler/service migration and caller-zero evidence.

ConvoEngine itself is **Core-owned infrastructure**. Its language schema, canonical IR, compiler, generic validator, shared predicate/reference/binding contracts, package-routing logic and reusable authoring service belong physically in `psychopatzCore`. ProjectHoomans and DynamicTrading/DTCommon are adopters: they may own domain-specific PSDL records and adapters, but they must not fork or duplicate the language/compiler/runtime authority.

This goal does **not** replace accepted semantic runtime authorities. It standardizes how authors describe them.

```text
PSDL source
    ↓
PSDL normalization + validation
    ↓
Canonical Semantic Dialogue IR
    ↓
existing semantic/runtime authorities
    ├─ Core NLU / semantic candidates
    ├─ semantic context + evidence
    ├─ ResponsePlan / BranchOffers
    ├─ Interaction Director
    ├─ behavior / beat arbitration
    ├─ Scene Runtime / Social Conversation
    ├─ realization / translation
    └─ gameplay/domain authorities
```

No second parser, response engine, scene runtime, button engine, relationship authority, gameplay authority, or transcript store is introduced.

## Runtime namespace boundary

ConvoEngine-owned runtime belongs under:

```text
PsychopatzCore/ConvoEngine/...
PNC/ConvoEngine/...
DTCommon/ConvoEngine/...
```

Do not preserve conversation-owned runtime under nested paths such as:

```text
<Owner>/Semantics/Generated/Conversation/...
<Owner>/Semantics/Conversation/...
<Owner>/.../PSDL/...
```

The rename is ownership-scoped, not a global semantic refactor.
`PsychopatzCore/Semantics/` remains valid for generic semantic infrastructure
that is broader than conversation: parser/NLU, shared predicates, fuzzy/entity
matching, semantic IR, and comparable reusable mechanisms.

Before moving a hand-authored module currently under `Semantics/`, classify
its actual responsibility. Conversation orchestration/presentation belongs to
ConvoEngine; generic semantic interpretation/resolution stays in Semantics.

### Naming closure invariant

ConvoEngine ownership applies to generated/runtime text identity as well as Lua
module paths. Maintained ConvoEngine source/output uses `convo.*` template
identity, adopter ConvoEngine domains such as `pnc.convo.*`, and
`Conversation/Text/convo/...` translation paths.

`psdl.*`, `pnc.psdl.*`, and `Conversation/Text/psdl/` are not valid
steady-state ConvoEngine output. They may survive only inside explicitly
classified migration readers/test fixtures until their compatibility obligation
is removed.

Do not apply this rule to genuinely generic Semantic IR or NLU contracts merely
because their schema/symbol names contain `semantic`.

## Core principle

There is one authored semantic conversation graph.

Player buttons, NPC affordances, chained NPC messages, nested choices, semantic free-text input, translations, behavior strategies and beats are **projections or orchestration of the same semantic model**, not separately maintained dialogue systems.

## Actor-neutral reference model

PSDL must not encode player/NPC identity into ordinary reusable dialogue.

Canonical participant references are:

- `speaker` — entity producing the current semantic act;
- `addressee` — primary entity being addressed;
- `target` — optional semantic target, not necessarily a person;
- `initiator` — scene/interaction initiator where distinct from speaker;
- `observer` / `participants` — scene participation projections;
- `slot.<name>` — typed semantic captures/references;
- `reference.<name>` — grounded fact/event/entity references.

The same definition must be usable for player→NPC, NPC→player, NPC→NPC and multi-participant scenes unless it declares an explicit participant constraint.

Do not create new canonical authoring fields such as `npcName`, `targetNPCName`, `playerFirstName`, `npcGender`, or `playerRelationship`. Historical adapters may read them during migration, but new PSDL source uses actor-neutral references.

### Presentation sugar

Common presentation bindings are implicit and typed:

```text
{speaker.name}
{addressee.name}
{target.name}
{slot.person.name}
{slot.location.name}
```

`target` is an entity reference. It may resolve to a person, item, settlement, location, faction, building, vehicle, task, event or other registered semantic entity. `.name` is presentation, not identity.

Custom bindings remain available for derived values such as direction, distance, relationship terms or domain-specific projections.

## Canonical context

Predicates and realization bindings read a bounded public context, conceptually:

```text
conversation
├─ speaker
│  ├─ identity
│  ├─ traits
│  ├─ personality
│  ├─ roles/capabilities
│  ├─ situation
│  └─ knowledge
├─ addressee
│  ├─ identity
│  ├─ traits
│  ├─ personality
│  ├─ roles/capabilities
│  ├─ situation
│  └─ knowledge
├─ relationship
│  ├─ speakerToAddressee
│  └─ addresseeToSpeaker
├─ scene
│  ├─ participants
│  ├─ audience
│  ├─ topic/history
│  └─ active beat(s)
├─ world
├─ slot
├─ reference
└─ result        # bounded public action-result context, only after execution
```

Private/secret/undiscovered facts remain inaccessible. PSDL predicates never reach directly into Java objects, mutable domain stores or arbitrary Lua callbacks.

## Predicate language

One shared predicate language is used by dialogue, turns, variants, offers, behaviors and beats.

Required logical forms:

- `all`;
- `any`;
- `not`.

Required scalar operations preserve the existing semantic predicate contract:

- `exists`;
- `eq` / `neq`;
- `in` / `not_in`;
- `gt` / `gte`;
- `lt` / `lte`;
- `truthy` / `falsy`.

PSDL extends the common predicate contract with generic bounded collection operations:

- `contains`;
- `not_contains`;
- `contains_any`;
- `contains_all`.

These are generic collection operations, not trait-specific special cases. They support traits, capabilities, tags, roles, known IDs and other bounded projected collections.

## PSDL module kinds

PSDL uses one language family with small composable module kinds.

### `dialogue`

Defines semantic recognition/triggering, typed slots, contextual eligibility, initiating speech, replies, offers, transitions, typed effects/intents, and optional references to registered authoritative action contracts.

A dialogue answers: what can a participant mean, say, ask or offer in this semantic interaction?

### `behavior`

Defines a reusable response strategy such as warn, reassure, challenge, joke, retaliate, acknowledge, de-escalate or ask-follow-up.

A behavior references semantic content/realization and may be selected by one-shot policy or by a beat.

A behavior does not own mutable gameplay state.

### `beat`

Defines a temporary conversational situation with entry, maintain and exit predicates plus ranked behavior candidates, relevance, cooldown and turn bounds.

A beat answers: what conversational situation are we in, and which behaviors are appropriate while it remains active?

Beats do not own wording and are not nested mini-dialogue files. They compose through semantic entry/exit conditions and director arbitration.

### `realization`

Defines optional reusable semantic-to-language constructions/lexical components when simple inline dialogue variants are insufficient.

Realization remains bounded, locale-aware and downstream of semantic truth.

## Beats and dialogue

Beats are part of PSDL, but they are a separate module kind rather than a required wrapper around dialogue.

Simple content must remain simple:

```text
semantic trigger → response
```

Advanced emergent conversation may use:

```text
semantic stimulus
      ↓
beat arbitration
      ↓
behavior strategy
      ↓
dialogue / realization
      ↓
turns + offers
```

Many different insults/threats may enter `beat.social.argument`; the beat must not be hard-wired to one insult phrase or one dialogue file.

Beat groups remain useful for mutually exclusive or independently composable contextual dimensions. The language must not prevent future concurrent groups such as social/tactical/emotional/task, but the implementation must remain bounded.

## Compact family authoring

The persisted authoring unit is one coherent semantic family/module.

Ordinary dialogue families write shared identity and semantics once:

```text
root:
  kind
  namespace
  id
  slots?
  invoke?       # semantic meaning
  execute?      # optional registered authoritative action contract
  affordance?   # how the family is recommended/presented
  say?          # initiator spoken realization(s)
  reply?        # named semantic reply outcomes, each with independent say
  after?        # post-exchange continuation
  base?         # common record fields
```

Numeric keys under `say` are stable **realization keys**, not separate semantic
family identities. A family remains one semantic identity such as
`social.knowledge.ask_person`; callers never depend on wording key `1`, `2`, or
`3`. Single-line `say` remains valid and normalizes to the same canonical
realization model.

Owner normally derives from the manifest/provider contract. The family may
override owner only when package routing genuinely differs.

The compact authoring form is therefore optimized for humans/agents, while the
canonical IR/runtime remains explicit and strongly validated.

## Semantic recommendation chaining

Reusable recommendation/button semantics belong to the **target family**.

A suggestible family defines `invoke` + `affordance` once. Other families
reference it through `after.recommend` or a bounded recommendation group.

This keeps:

- UI-only button label;
- stable keyed/style-aware spoken `say` realization;
- semantic invocation frame;
- participant consumer policy;
- constraints;
- recommendation grouping/priority

out of duplicated static suggestion catalogs.

The compiler projects target affordances into the existing Core semantic Offer
contract. Player UI and NPC policy remain consumers of the same meaning.

`affordance.label` is UI-only. The actual initiating line comes from the
selected family's `say` realization, then `invoke` dispatches semantic meaning.
Replies are independent named semantic outcomes under `reply`, each with their
own `say` realization and optional branch-specific `after`. Initiating wording
key `1` never implies reply wording key `1`.

Same-speaker continuation remains ResponsePlan `turns`. Post-response flow uses
bounded `after.recommend`, `after.goto`, end, or resume normalization.
Do not reintroduce a second node/choice runtime.

See `CHAINING_AND_AFFORDANCES.md` for the authoring contract.

## Turns, offers and transitions

The language has three distinct continuation concepts:

- **turn** — the same responder continues speaking;
- **offer** — a participant may make a semantic continuation;
- **transition** — conversation/flow state changes.

Do not use `next`, queued payloads, UI navigation or extra response keys interchangeably to mean all three.

ResponsePlan remains the runtime authority for bounded multi-turn delivery.

## Participant-neutral offers

An authored offer is a semantic affordance, not a player button.

The same offer can be consumed by:

- the existing player response UI;
- NPC semantic choice policy;
- another eligible participant adapter.

Presentation chooses whether it appears as a button. NPCs never simulate button clicks or reparse button text.

The historical player-only `visibility = "player"` shape is not the target canonical contract.

## Typed slots and references

PSDL slots are typed:

```text
entity.person
entity.item
entity.location
entity.faction
entity.settlement
entity.vehicle
fact
event
topic
```

The compiler/runtime may extend the registry without changing the language grammar.

Typed slots are used by semantic NLU/entity resolution and by authored offers. Fuzzy matching remains an external semantic resolver concern.

PSDL may declare semantic risk policy such as exact/safe/confirm, but authors do not encode edit-distance thresholds.

Mutating gameplay actions remain subject to existing exact/confirmation safety policy.

## Bindings and interpolation

Text interpolation is declarative.

Built-ins such as `{speaker.name}` and `{target.name}` require no manual binding boilerplate. Derived/custom values use explicit typed bindings.

The compiler must reject:

- undefined placeholders;
- inaccessible/private bindings;
- incompatible slot/binding types;
- required bindings with no resolvable source;
- locale variants with inconsistent placeholder contracts unless explicitly supported.

Bindings never authorize gameplay effects.

## Translation model

PSDL source owns locale content. Generated runtime translation files do not become authoring sources.

EN remains the required fallback locale. Additional locales are data-driven and must not require compiler/runtime language whitelists.

```json
"text": {
  "EN": ["Hello, {addressee.name}."],
  "TL": ["Kumusta, {addressee.name}."]
}
```

## Semantic effects, actions and authority

PSDL expresses typed semantic intents/events/effects and may reference a
registered authoritative gameplay action contract. It never embeds arbitrary
Lua mutation scripts or arbitrary function/module names.

Keep these concepts distinct:

```text
invoke
= semantic meaning

execute
= optional registered authoritative gameplay operation

result
= bounded typed public output from that operation
```

Good:

```text
intent = REQUEST
action = CAMP
execute = pnc.companion.camp
effect = relationship.event:PLAYER_COMFORTED_NPC
```

Forbidden:

```text
lua = "npc.relationship = npc.relationship + 10"
function = "PNC.CompanionCommands.Execute"
```

PsychopatzCore owns the generic action-contract/result mechanism. Adopters own
their domain adapters and actual mutation policy. Gameplay/domain authorities
remain responsible for validation and mutation.

Read-only candidate discovery and text binding remain separate from execution:
slot/context/binding resolvers may inspect bounded public state, while
`execute` happens only after a semantic action has actually been selected and
passed authority/safety gates.

Raw implementation return tables never enter PSDL directly. Action adapters
project only contract-declared public fields under bounded `result.*`, with
normalized outcomes such as pending/accepted/rejected/failed/completed.

Asynchronous actions remain first-class: runtime correlation/request IDs and
network callbacks are implementation details, not authoring fields.

See `ACTIONS_AND_RESULTS.md` for the normative execution/result contract.

## Canonical compilation boundary

```text
PSDL source
    ↓
syntax sugar expansion
    ↓
typed reference/slot normalization
    ↓
predicate normalization
    ↓
Canonical Semantic Dialogue IR
    ↓
validation
    ↓
generated runtime artifacts
```

There must not be separate simple/advanced/legacy dialogue runtimes as authoring authorities.

Existing runtime structures may remain internally where they are already accepted; the compiler maps canonical IR onto them.

## Source and generated ownership

### Mandatory three-mod boundary

- **PsychopatzCore** owns the PSDL language/schema, Canonical Semantic Dialogue IR, compiler/normalizer, generic validation, generic predicates/references/slots/bindings, registered Semantic Action Contract/result mechanism, shared authoring APIs, generic package routing, and reusable runtime contracts.
- **ProjectHoomans** owns Hoomans-specific semantic dialogue recipes, NPC/social gameplay adapters, and product-specific constraints/content.
- **DynamicTrading / DTCommon** owns trader/market-specific semantic dialogue recipes, trading adapters, and product-specific constraints/content.

All three repositories are mandatory migration/adoption scope. The goal is not complete if DynamicTrading remains on a separate first-party conversation authoring path.

Adopters own product/domain semantic recipes and gameplay-specific constraints unless explicitly migrated to Core as generic infrastructure. If a capability is reusable by more than one adopter, prefer moving the mechanism/contract to Core rather than duplicating it.

`owner` controls package routing. Physical source path is provenance/organization, not canonical identity. Core's compiler may emit/generated-route artifacts into the owning adopter package; that does not transfer compiler ownership to the adopter.

Generated Lua/JSON/translations/manifests/indexes are downstream-only.

## Zero-new-legacy rule

From this goal onward:

- do not add new first-party dialogue through old node/choice/outcome authoring;
- do not add new first-party static suggestion definitions as a separate semantic authority;
- do not add new first-party response-pool/flow files merely because an old domain used them;
- do not introduce `Legacy/`, `Compat/`, `Old/`, `V1/`, `Part02` or equivalent migration-copy source trees;
- do not create broad alias registries to keep first-party old IDs alive;
- do not duplicate a migrated definition in both old and PSDL source.

Existing old source is migration input only. Convert one owning domain, prove parity/callers, then delete the superseded source. Transitional readers/adapters may exist in compiler/runtime code only when bounded and explicitly scheduled for removal; they are not new authoring surfaces.

External-mod compatibility remains an explicit adapter boundary and does not justify first-party legacy authoring.

## Performance and persistence

PSDL must preserve accepted performance invariants:

- no per-NPC dialogue polling;
- no per-frame semantic scans;
- bounded predicate/slot/reference counts;
- bounded turns/offers/participants;
- no routine LLM requirement;
- no persisted transcript;
- no persisted generated button list;
- no persisted rendered response plan;
- no giant per-NPC dialogue catalog.

## Observability

Semantic Lab / Observatory should be able to explain:

```text
source module
→ normalized PSDL IR
→ resolved participants/references/slots
→ predicate trace
→ semantic candidate/frame
→ active beat
→ behavior candidates
→ selected behavior
→ response/turn/variant
→ offers
→ player button or NPC affordance projection
→ realization/translation
→ optional registered action dispatch
→ bounded authoritative `result.*`
→ reply outcome/realization
→ authoritative effect result
```

The tool displays the production chain; it does not implement a duplicate evaluator.

## Non-goals

- no free-form arbitrary scripting language;
- no arbitrary Lua/module/function callback authoring;
- no replacement for Core semantic NLU;
- no author-visible fuzzy algorithm tuning;
- no second relationship/knowledge/gameplay authority;
- no mandatory beat for simple dialogue;
- no cinematic transcript scripting engine;
- no automatic persistence of conversations;
- no new compatibility/legacy content tree.
