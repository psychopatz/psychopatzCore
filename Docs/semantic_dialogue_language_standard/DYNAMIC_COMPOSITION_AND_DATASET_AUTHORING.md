# ConvoEngine Dynamic Composition & Dataset Authoring Standard

**Status:** NORMATIVE CORE AUTHORING STANDARD
**System:** ConvoEngine
**Authoring schema:** `psychopatz.convo-engine.v1`
**Package schema:** `psychopatz.convo-engine.package.v1`
**Release state:** pre-release; v1 evolves in place until first public release.

## Principle

> **Author reusable semantic meaning once. Bind live context at runtime. Compose only validated semantic pieces. Realize wording last.**

A ConvoEngine family describes reusable meaning, state/outcome policy, legal gameplay integration, and continuation. Runtime supplies current participants, roles, slots, topics, events, activities, memories, world facts, and realization choice.

Do not create a new semantic family merely because the person, place, item, event, mood, wording, participant count, or current world context is different.

## Four layers

### 1. Semantic family

Stable reusable meaning:

~~~text
social.knowledge.ask_person
social.warning.threat
social.apology
command.camp
task.status.ask
~~~

The family owns the semantic contract.

### 2. Runtime-bound semantic instance

The same family instantiated with live context:

~~~text
social.knowledge.ask_person
  person = Bob

social.warning.threat
  threat = horde:42

command.camp
  camp_site = room:bedroom_3
~~~

Runtime binding does not create a new source family.

### 3. Beat / archetype composition

Validated families or semantic beats may be composed into bounded context-sensitive sequences:

~~~text
returned_from_scavenge
→ ask_trip_result
→ report_injury
→ express_concern
→ offer_help
~~~

The sequence may vary with live context, but every semantic piece remains compiler-valid and authority-safe.

### 4. Realization

Wording is selected after meaning and bindings are known:

~~~text
"You look rough. What happened out there?"
~~~

Wording/style variation is not semantic identity.

## One-family authority rule

For one semantic interaction/action, one canonical family owns the complete conversational policy:

~~~text
invoke
statePolicy
inputPolicy
repeatPolicy
postconditions
closure
execute
reply outcomes
after / continuation
realization references
~~~

Do not split action content and state policy across separate project-owned families and stitch them together at runtime by action name or lookup convention.

Gameplay/domain truth remains adopter-owned behind typed ActionContract/capability adapters. The family owns conversational policy, not mutable gameplay truth.

## Runtime may dynamically construct

Runtime may bind or select only validated structures:

~~~text
participants
semantic roles
slot values
TopicRef
EventRef
ActivityRef
MemoryRef
DomainRef
eligible semantic family instances
bounded candidate sets
validated beat sequences
optional reactions
declared continuations
realization/style/phrase variants
typed action arguments
~~~

Runtime composition is encouraged when it removes duplicated context-specific content.

## Runtime must not invent

Runtime must not invent:

~~~text
new gameplay capabilities
new actions/effects
new state transitions
new predicate semantics
new reply outcome meanings
new persistence/memory authority
new inventory/world truth
unregistered callbacks
unvalidated semantic branches
~~~

An LLM is never required for semantic correctness. Optional LLM use may paraphrase or rank already-valid candidates only.

## Prefer parameterization over specialization

Prefer:

~~~text
ask_person(person=<EntityRef>)
warn_threat(threat=<EventRef>)
offer_item(item=<EntityRef>)
camp(site=<LocationRef>)
~~~

over:

~~~text
ask_bob
ask_alice
ask_kate
warn_horde_at_school
warn_horde_at_store
camp_in_bedroom
camp_by_fire
~~~

unless the specialized case has genuinely different semantic meaning, legal state transitions, or gameplay authority.

## Prefer roles over fixed participant identities

Reusable families describe role requirements:

~~~text
speaker
addressee
actor
target
subject
beneficiary
mediator
supporter
witness
audience
observer
source
~~~

Do not encode participant count or numbered actor identities into family IDs unless the scenario is genuinely count-specific.

## Prefer structured context over prose-derived context

Use typed semantic references and authoritative facts:

~~~text
TopicRef
EventRef
ActivityRef
MemoryRef
DomainRef
EntityRef
state facts
relationship facts
task/quest facts
inventory/world facts
~~~

Do not make future directors or runtime systems mine rendered dialogue text to learn what a family means.

## Prefer realization variation over semantic duplication

If two records differ only in wording, tone, style, locale, or phrase choice, they should normally be realizations/variants of one semantic family.

Semantic references stop at the meaningful family/outcome level. Realization keys remain presentation identities.

## Prefer beats/archetypes over monolithic scripts

When a conversation can be assembled from reusable semantic acts, model it as bounded beats/archetypes rather than duplicating large participant-specific scripts.

Examples:

~~~text
greeting
request
argument
gossip
warning
mediation
apology
recruitment
trade negotiation
group planning
task briefing
event reaction
~~~

The future Dialogue Director consumes this metadata. It is not a second semantic authority.

## Dataset modernization classification

Every maintained family considered during dataset modernization must be classified before rewrite:

~~~text
STATIC_LITERAL
  genuinely fixed semantic content

SLOT_PARAMETERIZABLE
  duplicated context should become typed slots/bindings

CONTEXT_VARIANT
  same meaning; state/context changes eligibility, outcome, or realization

BEAT_COMPONENT
  reusable semantic act suitable for dynamic composition

ARCHETYPE_MEMBER
  belongs to a reusable conversation pattern/beat graph

REDUNDANT_SPECIALIZATION
  semantic duplicate caused by hard-coded entity/context/participant variation

DOMAIN_ACTION
  state-aware family invoking authoritative gameplay action

REALIZATION_ONLY
  semantic duplicate caused only by wording/style/localization

LEGACY_SPLIT_AUTHORITY
  one interaction's policy/content/action is split across multiple canonical families
~~~

Classification is not merely documentation. It determines the modernization recipe.

## Per-family modernization checklist

For every family being rewritten:

1. Identify the stable semantic meaning.
2. Confirm one canonical family owns that meaning.
3. Replace hard-coded participants/entities/context with roles, slots, or typed references where appropriate.
4. Move wording-only differences into realizations/variants.
5. Encode eligibility as canonical predicates/state policy rather than UI/runtime special cases.
6. Keep mutable truth in adopter authorities.
7. Route mutations through registered ActionContract/capability adapters.
8. Make repeat/closure/post-state behavior explicit for mutating/stateful interactions.
9. Expose discoverable act/topic/event/activity/memory metadata where relevant.
10. Prefer bounded beat/archetype composition over duplicated scripts.
11. Ensure semantic correctness requires zero LLM calls.
12. Run completeness, family verification, affected analysis, generation reconcile, and relevant runtime/provider tests.
13. Delete superseded project-owned source/runtime paths after parity and caller-zero; do not leave compatibility wrappers.

## ConvoEngine v1 rule

Because ConvoEngine has not had a public release, first-party development uses one final pre-release schema target:

~~~text
psychopatz.convo-engine.v1
psychopatz.convo-engine.package.v1
~~~

Do not create `psychopatz.convo-engine.v2` during this modernization.

The current `psychopatz.psdl.v2` / `psychopatz.psdl.package.v2` identifiers are pre-release implementation residue. Migrate first-party sources/compiler/package descriptors to ConvoEngine v1 and remove the old aliases/read paths after source/caller zero.

Compact authoring sugar, profiles, package defaults, sidecars, typed slots, roles, bindings, policies, beats, behaviors and realizations all remain available under ConvoEngine v1. Compact source versus normalized IR is a compiler-stage distinction, not a reason for two authoring schema names.

After the first public release, future incompatible schema evolution must use an explicit compatibility/versioning decision. This pre-release migration does not establish a permanent "mutate v1 forever" policy.

## Authoring workflow

Use the ConvoEngine/CodeBuilder authoring service:

~~~text
inspect family + classification
→ edit/migrate canonical source through CodeBuilder
→ validate/preview
→ write source
→ affected analysis
→ family verification
→ generation/reconcile
→ provider/runtime tests
→ completeness/health
~~~

Generated Lua, registries, manifests, indexes and translations remain downstream artifacts and are never hand-edited.

## Acceptance invariant

A modernized dataset is ready when:

> semantic families describe reusable meaning rather than hard-coded situations; live context is supplied through bounded roles/slots/references; runtime may compose validated families/beats but cannot invent authority; one family owns each semantic interaction's conversational policy; gameplay truth remains adopter-owned; wording is separated into realization; all maintained first-party sources use ConvoEngine v1; duplicate/split/wording-only families are retired after parity; and the dataset is discoverable enough for a future deterministic Dialogue Director without requiring an LLM for correctness.
