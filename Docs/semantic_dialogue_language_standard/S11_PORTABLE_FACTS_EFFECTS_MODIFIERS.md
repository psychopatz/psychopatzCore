# S11 Portable Facts, Effects, and Timed Modifiers

**Status:** APPROVED FOUNDATION DESIGN — required by S11A before broad stateful content migration.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**State/outcome architecture:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`
**Completeness/memory architecture:** `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`
**Compiler/runtime optimization:** `S11_COMPILER_RUNTIME_OPTIMIZATION.md`
**Participant/emergent-dialogue foundation:** `S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

## Purpose

ConvoEngine authoring needs to express state constraints and consequences compactly without creating separate mini-languages for relationship, mood, inventory, health, traits, quests, tasks, combat, or future adopter domains.

The compiler should understand a small generic structural vocabulary:

```text
EntityRef
Predicate / Query
Action
Effect
Modifier
Retention
MemoryResidue
```

Adopters define the domain schemas and authority adapters.

Core understands structure, validation, normalization, portability, graph analysis, and backend projection.

This is a no-split-system design.

## Governing rule

> Conditions ask authoritative state. Actions request authoritative mutation. Effects describe typed consequences owned by a registered domain. Modifiers are effects with lifecycle/stacking semantics. Memory records what happened. None of these may become a second source of gameplay truth.

## Existing ProjectHoomans seams to preserve

The current implementation already contains useful domain-specific mechanisms that should be normalized rather than replaced.

### Relationship

Current dialogue effect handlers include:

```text
pnc:relationship
pnc:memory
```

Relationship authority already supports approval/respect/familiarity changes, relationship memories, strength, decay-per-day, permanence, sharing/provenance, and recalculation through RelationshipService.

S11 should preserve RelationshipService as authority.

### Mood / morale

`PNC_MoraleModifierDefinitions.lua` already provides registered modifier definitions such as housing, sleep quality, food quality, recreation, social, safety, and employment, with weights and optional worsening over time.

This is a precursor to the generic modifier contract. S11 should normalize the compiler-facing contract around it rather than create a second mood system.

### Inventory / items

ProjectHoomans already owns authoritative inventory/query/consumption services and typed item descriptors.

ConvoEngine must consume semantic inventory query capabilities. It must not depend on raw inventory table layout.

## Canonical entity roles

Authoring may use a compact bounded role vocabulary:

```text
actor
target
speaker
addressee
player
npc
source
```

Canonical IR resolves each role to an `EntityRef`.

A role is contextual; the compiler must not assume that `actor` always means player or NPC.

Example:

```text
dialogue:
  speaker = npc
  addressee = player

social event:
  actor = npc_a
  target = npc_b
```

Effect/predicate validation must fail when a required role cannot be resolved.

## Authoring sugar versus canonical IR

Compact authoring syntax may be friendly and domain-shaped.

Canonical IR must normalize it into explicit generic structures before Portable Dialogue Plan generation.

Example source sugar:

```yaml
when:
  actor.has:
    item: Base.Bandage
    count: 1
```

Canonical meaning:

```text
Predicate
  provider = inventory
  subject = actor
  query = contains
  selector.item = Base.Bandage
  count >= 1
```

The convenience syntax must never survive as opaque backend-specific callbacks.

## Fact/query providers

State predicates must query registered semantic fact providers.

Examples:

```text
inventory.contains
inventory.count
inventory.has_tag
inventory.has_usable

relationship.approval
relationship.respect
relationship.familiarity
relationship.state

mood.morale
mood.stress
mood.panic

health.state
health.injury
needs.hunger
needs.thirst
task.state
quest.state
trait.has
combat.state
```

These are conceptual semantic facts. Exact provider IDs should follow the current capability/schema conventions.

Core must not read adopter persistence paths such as:

```text
record.inventory.items
record.social.relationships[targetKey]
```

inside portable predicates.

## Compact item constraints

The authoring layer should support readable inventory predicates that normalize to the inventory query provider.

Examples:

```yaml
when:
  actor.has:
    item: Base.Bandage
```

```yaml
when:
  target.has:
    item: Base.WaterBottle
    count:
      gte: 2
```

```yaml
when:
  actor.has:
    category: medical
    count:
      gte: 1
```

```yaml
when:
  actor.has:
    tag: weapon
```

Optional selector fields such as equipped/state/quality are allowed only when the registered inventory provider explicitly declares support.

Unsupported selector fields must fail compile-time validation rather than silently degrade.

## Relationship conditions

Author-friendly relationship predicates may be compact:

```yaml
when:
  relationship:
    subject: actor
    target: addressee
    approval:
      gte: 25
```

Canonical IR normalizes this into:

```text
provider = relationship
fact = approval
subject = actor
target = addressee
op = gte
value = 25
```

Do not expose relationship persistence layout to source content.

## Composition

Conditions compose through the existing canonical predicate AST.

Example:

```yaml
when:
  all:
    - actor.has:
        item: Base.Bandage
    - relationship:
        subject: actor
        target: addressee
        approval:
          gte: 25
```

The compiler expands both into portable predicates before canonical IR/Portable Plan.

## Pure predicates versus mutations

A `when` condition is always read-only.

This:

```yaml
when:
  actor.has:
    item: Base.Bandage
```

must never consume the item.

Mutation remains explicit through `execute` or a typed effect authority.

Example:

```yaml
execute:
  use: pnc.medical.bandage
```

The medical/inventory authority owns item removal, treatment, rollback, race handling, and authoritative result.

## Four author-facing building blocks

Stateful content should primarily compose:

```text
when
execute
effects
memory
```

### when

Pure semantic predicates/fact queries.

### execute

At most one primary authoritative action/capability request for a semantic outcome unless an existing transaction contract explicitly supports a composed atomic action.

### effects

Typed immediate consequences or modifier applications owned by registered domain authorities.

### memory

Semantic episode retention/projection policy as defined by the memory-continuity architecture.

This keeps content concise while preserving ownership.

## Immediate effects

An immediate effect is a typed domain consequence without an independent timed lifecycle.

Conceptual form:

```yaml
effects:
  - relationship:
      subject: npc
      target: player
      approval: 2
      respect: 1
```

The compiler must resolve this through a registered effect-domain schema/adapter.

It must not directly mutate arbitrary fields.

Existing ProjectHoomans `pnc:relationship` is the current reference mechanism.

## Generic modifier contract

Timed or stacking buffs/debuffs use one generic portable modifier shape:

```text
Modifier
  domain
  definitionID
  subject
  target?
  values
  retention
  stacking
  source?
  conditions?
```

Example relationship modifier:

```yaml
effects:
  - modifier:
      domain: relationship
      id: insulted_me
      subject: npc
      target: player
      values:
        approval: -10
        respect: -4
      duration: 7d
      stacking: refresh
```

Example mood modifier:

```yaml
effects:
  - modifier:
      domain: mood
      id: encouraged_by_friend
      subject: npc
      values:
        morale: 8
        stress: -4
      duration: 12h
      stacking: refresh
```

Core understands the generic modifier structure. ProjectHoomans defines allowed relationship/mood fields and applies them through its authorities.

## Domain schemas

Every effect/modifier domain must publish a compiler-visible schema.

A schema defines at least:

```text
domain ID
allowed value fields
field types/ranges
required entity roles
whether target is allowed/required
supported retention modes
supported stacking modes
authority capability/adapter
possible result outcomes
portable fact/query surface when relevant
```

Example:

```text
relationship:
  fields = approval, respect
  familiarity = explicit policy only
  target required
  authority = RelationshipService/effect adapter

mood:
  fields = morale, stress, panic, boredom...
  target optional/forbidden according to definition
  authority = morale/mood modifier service
```

Do not hard-code Hoomans domains into Core.

An addon may register a future domain such as reputation without changing the language.

## Relationship modifier policy

Distinguish baseline/direct standing changes from temporary social impressions.

Short/medium-lived dialogue consequences should normally use relationship memories/modifiers rather than repeatedly changing baseline values.

Conceptually:

```text
baseline standing
+ active relationship memories/modifiers
+ decay
= effective relationship
```

Use direct baseline mutation only when the domain event genuinely changes baseline standing.

The compiler/effect schema must make this distinction explicit enough to validate author intent.

## Mood modifier policy

Mood should converge toward:

```text
base/current mood state
+ active typed modifiers
= effective mood
```

The existing MoraleModifierDefinitions registry should become or feed the Hoomans domain-definition authority rather than being duplicated by a ConvoEngine-only mood table.

A modifier definition may provide:

```text
stable ID
affected dimensions
default duration/retention policy
stacking policy
decay/worsening semantics
source/category
presentation metadata
```

Active modifier instances stay compact.

## Retention and duration

Memory and modifiers should share one generic game-time retention vocabulary without becoming the same record type.

Minimum retention modes:

```text
SESSION
TIMED
UNTIL
PERMANENT
```

Compact duration literals are authoring sugar:

```text
30m
6h
1d
7d
2w
```

The compiler converts them to canonical game-time units before runtime.

Do not parse human duration strings at runtime.

## Stacking / dedupe

Use a bounded generic stacking vocabulary:

```text
replace
refresh
extend
stack
accumulate
ignore
```

Optional parameters may include:

```text
maxStacks
maxValue
dedupeKey
```

The compiler must reject repeated/timed modifiers that have ambiguous stacking behavior when the domain requires an explicit policy.

## Memory versus modifier

Do not conflate semantic memory and active modifier state.

A semantic memory answers:

```text
what happened?
```

A modifier answers:

```text
what influence is active now because of it?
```

One outcome may create both.

Example:

```text
episode:
  player_insulted_me
  retention = 30d

modifier:
  insulted_me
  approval = -10
  retention = 7d
```

The penalty may expire while the event remains recallable.

They may share time utilities, stable IDs, source references, and dedupe policies, but not authority/storage semantics.

## Inventory mutations

Inventory predicates only query.

Inventory mutation must use typed authoritative actions such as transfer/consume/remove/equip through the adopter capability/ActionContract path.

Example:

```yaml
when:
  actor.has:
    item: Base.Bandage

execute:
  use: pnc.medical.bandage
```

If the action contract declares an item precondition, compiler completeness analysis may compare it with source predicates and report obvious contradictions or missing ownership.

Do not require every action precondition to be duplicated in `when`; the authoritative action remains final.

## Reusable predicate/effect presets

Common content should use reusable source-level presets/macros to reduce repetition.

Examples:

```yaml
when:
  use: social.friendly_and_safe
```

```yaml
effects:
  - use: social.helped_me
```

Presets must expand before canonical IR into explicit predicates/effects.

Opaque Lua callbacks are forbidden because they make completeness analysis and backend parity blind.

Preset recursion/cycles must fail validation.

## Example compact semantic family

Conceptual authoring:

```yaml
id: medical.offer_bandage

when:
  all:
    - actor.has:
        item: Base.Bandage
    - relationship:
        subject: actor
        target: addressee
        approval:
          gte: 20

execute:
  use: pnc.medical.bandage

effects:
  - use: social.helped_me

memory:
  retention: social.week

after:
  end: resolved
```

The compiler expands this into explicit canonical predicates, action capability, effect definitions, retention policy, closure/memory residue, and backend-portable data.

## Runtime optimization boundary

Static domain/definition metadata belongs in generated definitions. Active memory/modifier instances persist only mutable values/references required by the definition. Stable compiled IDs may be used for compact runtime/save representation, but source semantic IDs remain authoritative and debuggable.

Compiled families declare required fact providers and affected fact keys. Runtime projection/invalidation follows `S11_COMPILER_RUNTIME_OPTIMIZATION.md`; ConvoEngine must not create a shadow inventory/relationship/mood cache to optimize queries.

Timed modifier expiry uses bounded game-time scheduling rather than per-frame scanning. Repeated modifiers/memories should use definition-driven dedupe/aggregation when separate instances add no semantic value.

## Compact runtime representation

Keep source semantic IDs human-readable.

Generated/runtime persistence may map stable semantic IDs to compact stable IDs when it materially reduces ModData size.

Do not use unstable array positions.

Persist active modifier instances sparsely:

```text
definitionID
subject/target reference
createdAt
expiresAt? / untilRef?
sourceRef?
stack/count? only when needed
small override payload? only when definition does not supply it
```

Static fields such as default duration, presentation, allowed values, and default stacking belong in generated definitions, not every instance.

## Compiler validation

Add stable diagnostics for at least:

```text
CE_UNKNOWN_FACT_PROVIDER
CE_UNKNOWN_EFFECT_DOMAIN
CE_UNSUPPORTED_EFFECT_FIELD
CE_INVALID_ENTITY_ROLE
CE_UNRESOLVED_EFFECT_TARGET
CE_INVALID_ITEM_SELECTOR
CE_UNSUPPORTED_ITEM_SELECTOR
CE_INVALID_DURATION
CE_INVALID_STACK_POLICY
CE_MODIFIER_STACK_POLICY_REQUIRED
CE_MODIFIER_FIELD_OUT_OF_RANGE
CE_EFFECT_AUTHORITY_MISSING
CE_PREDICATE_PROVIDER_MISSING
CE_CONDITION_ACTION_CONTRADICTION
CE_PRESET_RECURSION
CE_OPAQUE_PRESET_NOT_PORTABLE
CE_DOMAIN_SCHEMA_BACKEND_DIVERGENCE
```

Diagnostics should include semantic family, source provenance, normalized field/provider/domain, and repair hint.

## Completeness-analyzer integration

The Dialogue Completeness Analyzer must include fact/effect/modifier semantics in its graph/report.

It should be able to reason about:

- state predicate reachability;
- missing/unsupported fact providers;
- action preconditions versus explicit source constraints;
- effect result branches;
- timed modifier lifecycle ownership;
- duplicate modifier application versus stacking policy;
- modifier-created memory residue where declared;
- terminal branches that claim effects but have no authority;
- fixture coverage for important condition combinations.

## Fixture scaffolding

The compiler may derive fixture skeletons for simple predicates.

Example:

```text
actor.has(Base.Bandage)
relationship.approval >= 20
```

may produce a scenario-patch request showing the facts required for a witness.

For provider state that cannot be safely synthesized generically, emit an explicit fixture-authoring requirement rather than inventing state.

## Portable backend parity

For the same canonical fact query/modifier/effect definition, Reference VM and PZ/Lua backend must agree on:

```text
provider/domain resolution
normalized predicate/effect shape
duration normalization
stacking policy
admission/result classification
diagnostic outcome
```

The Reference VM may simulate an adopter effect only through its declared schema/adapter contract. It must not encode Hoomans gameplay rules into Core.

## S11A integration order

**Ordering note:** authoritative phase order is `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md` / ROADMAP S11A. This subsystem must be structurally frozen in S11A1-A3 before the canonical Completeness Analyzer is built in S11A4. Do not use production legacy dialogue migration as compiler scaffolding.

Before broad content migration:

1. define generic EntityRef / fact-query / effect / modifier / retention IR;
2. add adopter-visible domain schema registration;
3. add compact authoring sugar normalization;
4. normalize item/relationship/mood reference cases;
5. integrate with the canonical predicate and ActionContract boundaries;
6. integrate modifier lifecycle metadata with retention/time utilities;
7. add compiler diagnostics and backend parity;
8. integrate with Dialogue Completeness Analyzer;
9. expose definitions and traces through CodeBuilder/Semantic Lab;
10. add declarative fixture coverage;
11. migrate existing relationship effect handlers and morale definitions through adapters without duplicating authority;
12. then use the contract during Identity/Companion/Needs/Greeting and later S11 domain migration.

## Acceptance examples

At minimum prove:

### Inventory-gated action

```text
actor has bandage
→ medical option actionable
→ authoritative action consumes/uses it

actor lacks bandage
→ same semantic family classified unavailable/blocked
→ zero mutation
```

### Relationship-gated branch

```text
approval >= threshold
→ branch reachable

approval below threshold
→ branch excluded or state-specific alternate
```

### Timed relationship modifier

```text
insult event
→ relationship modifier applied
→ refresh/stack behavior deterministic
→ expires/decays according to game time
→ baseline authority preserved
```

### Timed mood modifier

```text
encouragement
→ morale modifier applied
→ same definition refreshes according to policy
→ expiry restores effective contribution without deleting unrelated mood state
```

### Memory/modifier separation

```text
insult episode retained 30d
relationship penalty retained 7d
after day 7:
  episode recall still possible
  penalty no longer contributes
```

## Completion invariant

The portable facts/effects/modifier foundation is accepted only when the compiler/runtime optimization contract is also respected. In particular, static definition data is not duplicated per instance, fact dependencies are compiler-visible, timed lifecycle processing is bounded, and performance/save-size budgets are measured.

The portable facts/effects/modifier foundation is accepted only when:

> Stateful content can express compact actor/target conditions, inventory requirements, relationship/mood checks, typed authoritative effects, and RimWorld-like timed modifiers through one compiler-normalized portable vocabulary; adopter schemas own domain meaning and mutation; predicates remain read-only; action/effect authority remains explicit; duration/stacking are generic; memory and modifiers remain distinct; compiler completeness can analyze the result; and no domain-specific mini-DSL or parallel state authority is required.
