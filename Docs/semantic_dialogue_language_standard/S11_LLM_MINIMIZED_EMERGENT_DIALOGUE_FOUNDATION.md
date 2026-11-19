# S11 LLM-Minimized Emergent Dialogue Foundation

**Status:** APPROVED FUTURE-FACING FOUNDATION — S11 must preserve and expose the required seams; the autonomous Dialogue Director itself is OUT OF SCOPE for S11.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Architecture:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`
**Completeness/memory:** `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`
**Portable facts/effects:** `S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`
**Optimization:** `S11_COMPILER_RUNTIME_OPTIMIZATION.md`
**Post-S12 authority note:** the S11 prohibition on implementing the Director was phase-scoped. The current post-S12 design authority is `CONVERSATION_DIRECTOR_ARCHITECTURE.md`; S11 remains rationale for participant/role/reference/LLM-minimization principles and must not be read as requiring a permanent "future only" state.

**Promoted core standard:** `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md` now makes the reusable-meaning/runtime-binding/composition boundary normative for all new and modernized dataset source. This S11 document remains the deeper design rationale; S12 performs the dataset conversion.

## Purpose

Project Hoomans ultimately needs emergent NPC dialogue that can select useful topics, beats, semantic acts, and participants from live world context while minimizing LLM usage.

S11 does **not** implement that autonomous director.

S11 must make sure the canonical semantic data model is capable of supporting it later without another dialogue rewrite.

The future architecture is:

```text
world/social context
  participants
  activities
  recent semantic events
  memories
  relationships
  mood/modifiers
  tasks/quests
  inventory/world facts
        ↓
future Dialogue Director
  deterministic candidate discovery
  bounded utility scoring
  dynamic role binding
        ↓
Conversation Archetype / Semantic Beat
        ↓
existing ConvoEngine
  state/outcome validation
  actions/effects/modifiers
  memory/closure
  realization
```

The future Dialogue Director is a **consumer** of ConvoEngine metadata. It must never become a second semantic authority.

## LLM minimization invariant

Semantic correctness must never depend on an LLM.

The canonical system must be able to determine, without an LLM:

- which semantic families/beats exist;
- which participants/roles are eligible;
- which state predicates are true;
- which topics/events/memories are relevant candidates;
- which actions/effects are legal;
- which branches/outcomes are possible;
- whether a dialogue can continue or must close;
- which semantic memory/effects are produced.

A future LLM may be optionally used for bounded tasks such as:

- natural-language realization/paraphrase;
- subtle ranking among already-valid candidate beats;
- stylistic variation;
- non-authoritative flavor.

An LLM must not invent gameplay effects, state transitions, capabilities, relationship mutations, inventory mutations, memory truth, role bindings that violate constraints, or unvalidated dialogue branches.

## Participant-set model

A conversation scene contains an arbitrary **bounded** collection of participant EntityRefs.

Conceptually:

```text
ParticipantSet<EntityRef>
```

Do not encode participant count into dialogue identity.

Do not author:

```text
argument_2_people
argument_3_people
argument_4_people
```

unless a scenario is genuinely count-specific.

A single semantic family should normally work across varying participant counts.

## Semantic roles are dynamic views

Participants and roles are different concepts.

A scene may contain:

```text
participants = [Mara, John, Patrick, Sarah]
```

while one beat binds:

```text
speaker      = Mara
addressee    = Patrick
subject      = John
witnesses    = [Sarah]
```

and the next beat may bind different roles.

Canonical source must describe **role requirements**, not numbered participant slots.

Avoid:

```text
actor1
actor2
actor3
speaker2
target4
```

Prefer semantic roles:

```text
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
```

Adopters may register additional typed role names where justified, but generic compiler semantics remain role/cardinality based.

## Role cardinality

Role definitions must support bounded cardinality.

Conceptually:

```text
ONE
OPTIONAL_ONE
ONE_OR_MORE
ZERO_OR_MORE
BOUNDED_MANY
```

Examples:

```text
instigator = ONE
opponent   = ONE
mediator   = OPTIONAL_ONE
supporters = ZERO_OR_MORE
witnesses  = ZERO_OR_MORE
```

Runtime binding resolves actual EntityRefs from the ParticipantSet.

The compiler validates:

- required roles;
- exclusion constraints;
- cardinality;
- role-target compatibility;
- whether a multi-entity role is legal for an action/effect/query.

## Role selectors

A RoleSpec may define:

```text
name
cardinality
candidate source
constraints
ranking hints
exclusions
optional binding policy
```

Example conceptual role:

```text
mediator:
  candidates = participants
  constraints:
    alive
    not hostile
    knows instigator
    knows opponent
  ranking:
    highest combined relationship
```

The future director/runtime may resolve this deterministically using authoritative facts.

Do not encode fixed NPC identities in reusable semantic definitions.

## Quantified role operations

Portable semantic structure should be able to express bounded operations over role sets.

Conceptual operations:

```text
one(role)
any(role)
all(role)
each(role)
count(role)
```

Examples:

```text
any(participants) has medical item
all(required_guards) are armed
each(witnesses) receives witness memory
count(hostile_participants) >= 2
```

These must lower into bounded canonical IR/Portable Plan operations.

Do not create ad-hoc Lua loops hidden from compiler analysis.

## Conversation archetypes

Most reusable dialogue should be structured as **conversation archetypes**, not full participant-specific scripts.

Examples:

```text
request
argument
gossip
greeting
warning
mediation
apology
recruitment
trade negotiation
group planning
task briefing
event reaction
```

An archetype declares:

- required/optional roles;
- semantic beat graph;
- allowed semantic acts;
- continuation/closure rules;
- reaction budget;
- required facts;
- topic/event/memory hooks;
- effects/memory policies.

The same archetype can bind different participants and domain subjects.

## Semantic acts / beats

Dialogue content should increasingly describe reusable semantic acts rather than duplicated full prose branches.

Examples:

```text
greet
ask
answer
request
accept
refuse
clarify
accuse
deny
admit
support
oppose
mediate
warn
threaten
apologize
thank
challenge
leave
```

A SemanticBeat conceptually contains:

```text
act
speaker role
target/addressee role(s)
subject/topic/event/domain reference
guard
state/outcome policy
effects
memory residue
continuation
realization reference
```

The beat describes meaning.

Realization supplies wording.

## Topic references

Topics should be structured semantic references rather than raw text strings.

Conceptually:

```text
TopicRef
  topicID
  subjectRef?
  eventRef?
  domainRef?
  salience metadata?
```

This allows the future director to distinguish:

```text
generic food small talk
```

from:

```text
the current settlement food shortage
```

without using text similarity as authority.

S11 does not need to build full future topic scoring, but its source/IR must not erase these structured references.

## Semantic event references

Important gameplay occurrences should be referable as structured semantic events.

Conceptually:

```text
SemanticEventRef
  eventID
  type
  actors
  targets?
  witnesses?
  location?
  domainRef?
  occurredAt
  salience/severity metadata?
```

Do not require the future dialogue system to mine raw logs or prose to discover what happened.

Event producers remain adopter/domain owned.

ConvoEngine consumes bounded projections/references.

## Activity references

Current NPC activity should be exposed as bounded semantic facts/references, for example:

```text
activity.kind
activity.targetRef
activity.startedAt
activity.interruptibility
activity.domainRef
```

This allows a future director to prefer context-relevant beats such as:

```text
cooking → food topic
guarding → security topic
returned_from_scavenge → trip/result topic
building → construction/help topic
```

without ConvoEngine taking ownership of the activity system.

## Memory references

Same-day/durable semantic memory should expose structured references suitable for future candidate discovery.

A future director should be able to ask for concepts such as:

```text
recent unresolved obligations
recent salient events
recent relationship-changing episodes
recent topics with cooldown/repeat status
```

without reading transcript prose.

Memory remains history; current domain authority remains truth.

## Discoverable family metadata

Every canonical semantic family/archetype intended for future autonomous discovery should expose machine-readable metadata sufficient for candidate generation.

At minimum where relevant:

```text
semantic family ID
semantic act / archetype
topic tags / TopicRef types
required roles + cardinality
optional roles
required fact providers
eligible input/context classes
event/activity/memory hooks
repeat/cooldown policy
expected cost class
possible effects/memory residue
continuation/closure class
realization references
source provenance
```

A future director must not parse dialogue prose to learn what a family means.

## Candidate discovery versus authority

Future candidate discovery may produce:

```text
CandidateBeat
  family/beat ID
  possible role bindings
  topic/event/memory/activity references
  relevance features
```

Candidate discovery does not grant permission to execute.

The selected candidate still passes through canonical ConvoEngine state/outcome admission, ActionContract/domain authority, completeness-safe continuation, and effect/memory ownership.

## Future utility scoring

The future director may use deterministic bounded scoring such as:

```text
score =
  topic relevance
+ recent event salience
+ unresolved obligation relevance
+ activity relevance
+ relationship interest
+ personality preference
+ participant role suitability
+ freshness
- repetition penalty
- cooldown
- interruption cost
- social risk
- expensive-query cost
```

This scoring is explicitly **out of S11 implementation scope**.

S11 only needs to preserve the typed metadata/facts necessary to support such scoring later.

Do not add speculative scoring code in S11.

## Bounded group turn scheduling

Emergent group dialogue must remain bounded.

A future/group conversation archetype should be able to declare concepts such as:

```text
maxTurns
maxOptionalReactions
required responder roles
eligible next-speaker roles
reaction cooldown
priority
```

Do not allow every nearby participant to speak merely because they match a broad role.

One utterance normally has one speaker.

Addressee/audience/witness roles may contain multiple participants.

Group/choral speech should be an explicit specialized semantic act if ever required.

## Sparse relationship evaluation

Do not construct the full N×N relationship matrix merely because a scene has N participants.

Fetch only relationship edges required by the selected candidate/beat.

Examples:

```text
mediator → instigator
mediator → opponent
each witness → speaker
```

Dependency-driven projection from S11_COMPILER_RUNTIME_OPTIMIZATION.md must remain sparse over role bindings.

## Group effects

Effects may target one or many bound roles, subject to domain schema/cardinality rules.

Example conceptual event:

```text
speaker = Mara
target = John
witnesses = [Patrick, Sarah]
```

Possible consequences:

```text
John → Mara approval -10
Patrick → Mara respect +3
Sarah → Mara respect -2
witness memory for Patrick/Sarah
target memory for John
actor memory for Mara
```

All consequences derive from one semantic event/beat.

Do not duplicate the dialogue definition for each participant count.

## Perspective-aware memory

One semantic episode may be referenced by many participant memories with role-specific perspective.

Example:

```text
eventID = accusation:42

actor perspective:
  I accused John.

target perspective:
  Mara accused me.

witness perspective:
  I saw Mara accuse John.
```

The authoritative episode identity is shared.

Do not duplicate the world event itself per witness.

## Realization boundary

Semantic acts/beats should reference realization pools/templates.

Do not bake all wording into the semantic graph.

Example:

```text
act = support
speaker = supporter
target = accused
strength = strong
tone = angry
```

Realization may select a suitable authored variant.

This is a major LLM-reduction mechanism.

A future LLM may optionally paraphrase a validated realization, but authored/template realization must remain sufficient for correct gameplay behavior.

## Generated structure, not generated authority

The runtime may dynamically compose **validated structures**:

- role bindings;
- semantic beat sequences;
- optional reactions;
- topic/event references;
- realization variants.

It must not dynamically invent unregistered actions/effects/state transitions.

The safe boundary is:

```text
authored/compiled:
  valid acts
  valid role contracts
  valid conditions
  valid actions/effects
  valid continuations
  valid realization pools

runtime:
  select and compose valid pieces
```

## Compiler validation

Add/future-proof diagnostics for at least:

```text
CE_ROLE_UNBOUND
CE_ROLE_CARDINALITY_MISMATCH
CE_EMPTY_REQUIRED_ROLE
CE_PARTICIPANT_OUTSIDE_SCENE
CE_AMBIGUOUS_GROUP_EFFECT
CE_INVALID_ROLE_SELECTOR
CE_ROLE_SELECTOR_UNBOUNDED
CE_GROUP_REACTION_UNBOUNDED
CE_PARTICIPANT_COUNT_SPECIALIZATION_REDUNDANT
CE_FAMILY_NOT_DISCOVERABLE
CE_TOPIC_REFERENCE_UNTYPED
CE_EVENT_REFERENCE_UNTYPED
CE_ACTIVITY_REFERENCE_UNTYPED
CE_LLM_REQUIRED_FOR_SEMANTIC_AUTHORITY
```

Exact codes may follow established compiler naming conventions.

## S11 scope boundary

**Ordering note:** participant/role/archetype/reference structure belongs in the S11A1 canonical data-model freeze and must be carried through S11A2-A3 before the analyzer is finalized. The authoritative sequence is `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`; do not migrate production dialogue merely to exercise this foundation.

S11 **must implement/future-proof**:

1. ParticipantSet / EntityRef compatibility in canonical IR/Portable Plan.
2. Dynamic semantic role representation and cardinality metadata.
3. Fact/effect/query targeting through bound roles or bounded role sets.
4. Structured TopicRef/EventRef/ActivityRef/MemoryRef-compatible metadata where current systems expose them.
5. Discoverable semantic family/beat metadata.
6. Compiler completeness over optional/multi-role branches.
7. Dependency analysis over only the bound role/fact pairs required.
8. Bounded reaction/continuation metadata where group flows exist.
9. Realization references separate from semantic meaning.
10. Tests proving ordinary two-person behavior remains a special case of the generic participant/role model.

S11 **must NOT implement yet**:

- autonomous beat/topic selection;
- global social utility scoring;
- personality-driven conversation planning;
- LLM candidate generation;
- LLM-authored gameplay semantics;
- broad autonomous NPC chatter director;
- unrestricted procedural conversation graph generation.

Those belong to a later Dialogue Director goal.

## Small-model rule

If implementing S11 and a choice appears between:

```text
add a participant-count-specific dialogue variant
```

and:

```text
generalize the role/archetype/beat binding
```

prefer the generic role binding unless the scenario is genuinely count-specific.

If implementing a future-facing field would require speculative director behavior, preserve the typed metadata seam but do not implement the director.

## Completion invariant

The emergent-dialogue foundation is accepted when:

> Canonical dialogue semantics are participant-count agnostic by default; scenes can expose bounded ParticipantSets; semantic roles bind dynamically with cardinality; predicates/actions/effects/memory can target one or many bound roles through portable schemas; semantic families expose discoverable act/topic/event/activity/memory metadata; realization is separate from meaning; compiler completeness understands optional/group role paths; runtime remains bounded and sparse; ordinary two-person dialogue remains a simple specialization; and no LLM is required for semantic correctness or gameplay authority.
