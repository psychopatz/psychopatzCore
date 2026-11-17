# S11 Compiler and Runtime Optimization Contract

**Status:** APPROVED FOUNDATION DESIGN — required by S11A before broad stateful content migration.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**State/outcome architecture:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`
**Completeness/memory architecture:** `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`
**Portable facts/effects/modifiers:** `S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`
**Participant/emergent-dialogue foundation:** `S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

## Purpose

S11 is adding stronger semantic policy, compiler completeness, memory continuity, fact/effect domains, and timed modifiers.

The system must not pay for that expressiveness by making the Project Zomboid runtime large, dynamic, or expensive.

The optimization rule is:

> Do expensive reasoning at compile time. Generate compact definitions, indexes, and dependency metadata. Keep runtime evaluation small, bounded, cacheable, and driven by authoritative state changes.

This document is normative.

## Small-model implementation rule

When choosing where logic belongs, use this order:

1. If the value can be determined from source/schema at build time, compile it.
2. If the value changes only when an authoritative fact changes, cache/project it and invalidate on that fact.
3. If the value must be checked at interaction time, evaluate only the compiled facts required by that family.
4. Never scan every semantic family, every memory, every modifier, or every inventory item every frame unless current profiling proves no bounded alternative exists.
5. Never duplicate authoritative gameplay state merely to make semantic evaluation faster.

## Compiler-heavy / runtime-light architecture

Target pipeline:

```text
rich compact authoring
→ canonical normalization
→ schema validation
→ dialogue completeness analysis
→ dependency analysis
→ static optimization
→ compact Portable Dialogue Plan
→ compact generated definitions/indexes
→ small runtime evaluator
→ existing adopter authorities
```

The runtime should primarily:

```text
resolve family
→ fetch only required facts
→ evaluate compact predicate/state program
→ select outcome
→ optionally execute ActionContract/domain authority
→ apply registered typed effects/modifiers
→ emit semantic memory residue
→ invalidate affected semantic dependencies
```

Do not rediscover source structure at runtime.

## Definition / instance separation

Static schema belongs in generated definitions.

Mutable save/runtime records contain only changing instance data.

### Definition examples

A generated semantic memory/modifier/family definition may own:

```text
stable semantic ID
domain
default duration/retention
default stacking/dedupe
allowed/required roles
static presentation
fact dependencies
effect dependencies
action capability
compiled predicate/state program
postconditions
memory-residue policy
```

### Instance examples

A runtime modifier/memory instance should normally contain only:

```text
definitionID
subjectRef
targetRef? if required
createdAt
lastAt? if needed
expiresAt? or untilRef?
domainRef? / sourceRef?
count/stack? only if required
small immutable slot payload? only if not recoverable from authority
```

Do not repeat static definition metadata in every ModData instance.

## Stable compiled IDs

Canonical source remains human-readable:

```text
relationship.insulted_me
needs.water.accepted
command.follow
```

Generated/runtime persistence may map these to compact stable IDs when it materially reduces save/runtime size.

Requirements:

- ID mapping must be deterministic or compiler-owned and stable across source reorder.
- Never use unstable array position as persisted identity.
- Collision detection is mandatory if hashing is used.
- Debug/Semantic Lab must be able to recover the human-readable semantic ID.
- Version migration must preserve previously persisted IDs or provide explicit migration.

## Dependency-driven state projection

Every compiled semantic family should declare the authoritative facts it can read.

Conceptual example:

```text
command.follow requires:
  addressee.companion.orderKind
  addressee.activity.busy
  addressee.health.state
```

The runtime must project only required facts for the selected/suggested families.

Do not build a giant complete semantic state snapshot for every turn when only a few facts are needed.

Generated dependency metadata should support:

```text
family → required facts
fact → consuming families
effect/action → invalidated facts
preset → expanded dependencies
ActionContract → consuming families
memory definition → context-reference consumers
modifier definition → affected facts
```

These indexes should be compiler outputs, not hand-maintained registries.

## Event-driven invalidation

After authoritative mutation, invalidate semantic projections by affected fact keys.

Examples:

```text
FOLLOW accepted
→ invalidate companion.orderKind

inventory transfer
→ invalidate relevant inventory.contains/count facts

relationship modifier applied/expired
→ invalidate relationship.approval/respect/effective state

mood modifier applied/expired
→ invalidate mood dimensions it contributes to
```

Do not rebuild all semantic affordances after every unrelated event.

A full rebuild remains acceptable for explicit debug/recovery paths and as a correctness fallback until dependency invalidation is proven.

## Compiled predicate/state programs

Authoring remains expressive.

Canonical generated runtime should avoid repeatedly traversing large source-shaped tables when a compact deterministic representation is possible.

The compiler may lower common predicates/state policies into a compact program/decision table such as:

```text
factID
operator
constant/reference
jump/next-rule
outcomeID
reasonID
admissionID
```

Requirements:

- semantics must remain equivalent to canonical predicate AST;
- Reference VM and PZ backend parity must prove equivalence;
- debug trace must map compact instructions back to source provenance;
- unsupported complex predicates may continue using the generic bounded evaluator;
- never optimize by changing domain semantics.

Optimization is an implementation detail beneath the Portable Dialogue Plan contract.

## Incremental compiler analysis

The Dialogue Completeness Analyzer and related schema analysis must support incremental recomputation where feasible.

Cache by normalized semantic/source fingerprint.

When one family changes, reanalyze:

```text
changed family
+ presets/macros it depends on
+ definitions/contracts it consumes
+ families transitively affected by changed shared definitions
```

Do not require a complete corpus analysis for every local source edit.

A full deterministic package analysis remains mandatory for acceptance/release.

Generated cache data is disposable optimization state, not semantic authority.

## Fact-provider cost model

Compiler-visible fact providers should declare a coarse cost class.

Minimum conceptual classes:

```text
CHEAP
BOUNDED
EXPENSIVE
```

Examples:

```text
relationship.approval       CHEAP
companion.orderKind         CHEAP
inventory.contains          BOUNDED
world.search_nearby_items   EXPENSIVE
pathfinding/reachability    EXPENSIVE
```

The compiler should warn or fail when expensive fact queries are used in high-frequency automatic suggestion/ranking paths without explicit caching/event ownership.

Expensive state queries should normally run on explicit interaction, authority update, or bounded cache refresh rather than per-frame polling.

Cost is advisory/validation metadata, not a second execution authority.

## Inventory optimization rule

Portable semantic code uses inventory fact/query providers such as:

```text
inventory.contains
inventory.count
inventory.has_tag
inventory.has_usable
```

ConvoEngine must not maintain its own inventory copy/index.

The authoritative inventory subsystem decides how to answer efficiently.

If an existing inventory service already has indexes/caches, reuse them.

If optimization is required, improve the authoritative inventory service rather than adding a semantic shadow inventory.

## Timed modifier expiry scheduling

Do not scan every modifier every frame.

Use bounded game-time scheduling such as:

- ordered next-expiry queue; or
- coarse time buckets (for example game-hour buckets); or
- existing event/tick scheduling infrastructure.

TIMED modifier expiry wakes only when relevant.

UNTIL modifiers should prefer authoritative domain events/state transitions over continuous polling.

PERMANENT modifiers require no expiry scheduling.

SESSION modifiers expire with their owning session/context boundary.

Exact structure should follow current ProjectHoomans scheduler/runtime conventions after source audit.

## Memory expiry and pruning

Same-day/timed semantic memories should be pruned opportunistically or on bounded game-time cadence.

Acceptable triggers include:

- memory lookup;
- conversation open;
- game-hour/day transition;
- bounded scheduled maintenance.

Do not scan every NPC's memory every frame.

Permanent memories and domain references remain untouched unless their owning policy explicitly retires them.

## Dedupe, aggregation, and save-size control

Definitions should declare compact duplicate behavior when repeated episodes/modifiers can occur.

Generic behaviors:

```text
ignore
refresh
replace
accumulate
multi
```

For modifiers, existing stacking vocabulary remains:

```text
replace
refresh
extend
stack
accumulate
ignore
```

Prefer one compact instance with:

```text
count
firstAt
lastAt
```

when individual repeated records are not semantically required.

Examples:

- repeated identity introduction: dedupe/ignore or idempotent;
- repeated insult memory: refresh or accumulate according to definition;
- same obligation: dedupe by domainRef;
- repeated question: accumulate count if dialogue needs "you asked me this N times".

Do not preserve duplicate full episodes merely to count them.

## Presets/macros are compile-time only

Authoring presets such as:

```text
social.friendly_and_safe
social.helped_me
retention.social_week
```

must expand before canonical IR/Portable Plan completion.

Runtime must not perform preset inheritance or macro expansion.

Compiler diagnostics and completeness analysis must see the expanded predicate/effect graph.

Preset recursion/cycles are compile errors.

## Compact generated indexes

Generation should emit only indexes justified by actual runtime/compiler consumers.

Useful examples:

```text
semanticID → compactID
compactID → debug semanticID
family → requiredFacts
fact → families
actionContract → families
modifierDomain/definition → affectedFacts
memoryDefinition → context tags/resolvers
source provenance → generated family
```

Do not emit duplicate indexes that can be derived cheaply from another generated artifact unless profiling shows a material benefit.

All generated indexes require deterministic/no-op generation acceptance.

## On-demand decision traces

Normal production runtime should not allocate large debug traces.

The evaluator should return minimal result data by default.

When Semantic Lab/debug/harness explicitly requests trace mode, include bounded diagnostics such as:

```text
family
required facts read
matched predicate/state rule
outcome
reason
admission
action/effect result
invalidated facts
memory/modifier residue
source provenance
```

Trace mode must not change behavior.

## Performance budgets

S11A must establish measured baselines before setting hard thresholds.

Measure at least:

```text
compile one family
incremental recompile after one-family edit
full package compile
analyze one family
full completeness analysis
Portable Plan generation
one semantic-turn state evaluation
suggestion frontier generation
same-day memory lookup
modifier apply/refresh
modifier expiry maintenance
generated definition/index size
serialized memory/modifier bytes per NPC in representative scenarios
```

For each budget:

1. record current baseline;
2. define an evidence-based target/regression threshold;
3. add a performance fixture/test where stable/reproducible;
4. fail or warn according to severity;
5. never weaken semantic correctness merely to hit a number.

Do not invent arbitrary timing thresholds without measuring the current machine/test harness.

## Performance acceptance scenarios

At minimum profile:

### Idle/suggestion path

Multiple nearby NPCs with ordinary conversation affordance generation.

Prove expensive world/inventory scans are not performed once per semantic family per frame.

### Inventory-gated dialogue

Many item-gated families.

Prove required inventory facts are shared/cached by authoritative query service where appropriate rather than causing independent full scans.

### Timed modifiers

NPC with many active relationship/mood modifiers.

Prove ordinary frames do not scan every modifier and that expiry processing is bounded.

### Same-day memories

NPC/player pair with many semantic episodes.

Prove lookup/pruning remains bounded and dedupe prevents linear duplicate growth for aggregatable definitions.

### Compiler incremental edit

Edit one semantic family.

Prove incremental analysis touches the bounded dependency closure rather than unnecessarily rebuilding all unrelated families.

## Compiler optimization diagnostics

Add stable diagnostics/warnings where useful, for example:

```text
CO_EXPENSIVE_FACT_IN_HOT_PATH
CO_REDUNDANT_FACT_READ
CO_GLOBAL_REBUILD_REQUIRED
CO_UNSTABLE_PERSISTED_ID
CO_DUPLICATE_GENERATED_INDEX
CO_UNBOUNDED_INSTANCE_GROWTH
CO_MODIFIER_FULL_SCAN
CO_MEMORY_FULL_SCAN
CO_RUNTIME_PRESET_EXPANSION
CO_INCREMENTAL_CACHE_MISS_FANOUT
CO_SAVE_PAYLOAD_DUPLICATES_STATIC_DATA
```

These diagnostics are optimization evidence, not substitutes for semantic correctness diagnostics.

## Small-model implementation sequence

**Ordering note:** O1 baseline/ownership work is part of S11A0; O2-O9 execute only after the canonical data model/source→IR→Portable Plan/backend structure and analyzer/adapters/lifecycle reach their ROADMAP-defined prerequisites. `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md` is authoritative if this local O-sequence appears to conflict with S11A order.

A smaller model must follow O1-O9 in order once their S11A prerequisites are satisfied:

### O1 — baseline and ownership map

- measure current compile/runtime/save-size baselines;
- identify existing cache/index/scheduler/inventory/memory/modifier services;
- record what can be reused;
- do not optimize code yet.

### O2 — stable definitions and dependency metadata

- add stable semantic/definition ID strategy;
- add family required-fact metadata;
- add fact→consumer and mutation→invalidated-fact metadata;
- keep current behavior unchanged;
- add deterministic generation tests.

### O3 — dependency-driven projection/invalidation

- project only required facts;
- invalidate only affected fact/family caches after authoritative changes;
- retain safe full-rebuild fallback until parity is proven;
- test stale-projection regressions.

### O4 — compile-time lowering

- lower eligible predicate/state rules into compact runtime representation;
- keep generic evaluator fallback;
- prove Reference VM/PZ equivalence;
- preserve debug source provenance.

### O5 — incremental analysis

- fingerprint normalized families/shared definitions;
- cache completeness/dependency analysis;
- recompute only affected closure on local edits;
- retain full analysis command for acceptance.

### O6 — modifier/memory runtime scheduling

- use existing scheduler conventions for timed expiry;
- remove per-frame full scans;
- add dedupe/aggregation for repeated episodes/modifiers;
- verify game-time semantics.

### O7 — compact persistence

- separate generated definition data from mutable instance data;
- remove duplicated static fields from persisted instances;
- add schema version/migration if persisted shape changes;
- measure representative ModData size before/after.

### O8 — on-demand diagnostics

- normal runtime returns minimal data;
- trace mode supplies detailed compiler/runtime decision evidence;
- Semantic Lab consumes generated dependency/completeness/index data.

### O9 — performance budgets and acceptance

- set thresholds from measured baselines;
- add stable regression tests;
- run full semantic correctness + performance gates;
- do not trade correctness for speed.

## Things the smaller model must NOT do

Do not:

- create a semantic shadow inventory;
- create a second relationship/mood/modifier store;
- cache mutable domain truth without invalidation ownership;
- scan all semantic families each frame;
- scan every memory/modifier each frame;
- parse authoring duration strings/presets at runtime;
- persist static definition metadata per instance;
- use source-order indexes as persisted IDs;
- remove generic evaluator fallback before optimized parity is proven;
- make Semantic Lab the owner of optimization indexes;
- hand-edit generated indexes;
- weaken compiler completeness or state/outcome correctness for performance;
- add speculative complex data structures before profiling demonstrates need.

## Completion invariant

The optimization foundation is accepted only when:

> Rich semantic authoring is normalized and analyzed at compile time; generated definitions and indexes are deterministic and compact; runtime fetches only required authoritative facts, evaluates bounded compiled policy, invalidates by authoritative fact changes, schedules timed expiry without per-frame global scans, deduplicates aggregatable memories/modifiers, persists only mutable instance data, supports on-demand diagnostics, and meets measured performance/save-size regression budgets without creating shadow state or weakening semantic correctness.
