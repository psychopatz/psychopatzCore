# Conversation Director Architecture

**Status:** NORMATIVE DESIGN FREEZE — implementation follows layout normalization
**Date:** 2026-11-19
**Owner:** PsychopatzCore mechanism; adopter facts/content remain adopter-owned
**Physical-layout contract:** `CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md`
**Dynamic-authoring contract:** `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`

## Purpose

The existing scene behaviors/beats are the prototype metadata for a future
Conversation Director.

The Director must make conversations more emergent without becoming another
dialogue system.

Core rule:

> The Director discovers, ranks, binds, and sequences already-valid ConvoEngine
> semantics. It never authors or duplicates semantic meaning.

## 1. Authority boundary

ConvoEngine owns canonical semantic families, behaviors, beats, realization
references, role contracts, predicates, continuation/closure and action/result
contracts.

Adopters own gameplay/world truth and typed domain capabilities.

The Director owns only:

- ephemeral scene context;
- candidate discovery;
- deterministic utility scoring;
- role binding among eligible participants;
- bounded beat/family sequencing;
- diversity/cooldown selection policy;
- continuation/termination scheduling.

The Director does not own:

- new semantic actions/effects;
- relationship/inventory/mood truth;
- reply meaning;
- translation text;
- persistent shadow state;
- a second condition language;
- a second family registry;
- a second behavior/beat authoring tree.

## 2. Scene model

A scene is runtime context, not a second authored semantic graph.

Conceptual structure:

~~~text
SceneContext
  sceneID
  trigger/stimulus
  ParticipantSet<EntityRef>
  current speaker/addressee bindings
  TopicRef/EventRef/ActivityRef/MemoryRef candidates
  projected authoritative facts
  recent selected semantic IDs
  cooldown/diversity history
  bounded turn/beat budget
~~~

SceneContext is short-lived.

Durable consequences continue to flow into existing gameplay authorities and
ConversationMemory/event systems.

Do not persist a complete Director shadow world.

## 3. Candidate model

The Director consumes canonical ConvoEngine records through one compiled
candidate index.

Conceptually:

~~~text
DirectorCandidate
  canonicalID
  kind                 behavior | beat | dialogue/archetype
  stimuli[]
  domains[]
  topic/activity/event hooks[]
  requiredFacts[]
  roleSpec summary
  baseRelevance
  cooldown/diversity metadata
  continuation class
~~~

This is derived compiler metadata, not authored separately.

The index contains IDs and compact selection data only. Full semantic policy
remains in the canonical ConvoEngine plan.

## 4. Director pipeline

~~~text
runtime event / conversation continuation
        ↓
build or update SceneContext
        ↓
candidate index lookup
  stimulus/domain/topic/activity/event
        ↓
cheap eligibility filter
  required facts / role cardinality / cooldown
        ↓
bind candidate roles to ParticipantSet
        ↓
canonical ConvoEngine validation
  predicates / state / action admission / closure
        ↓
deterministic utility scoring
        ↓
bounded top-K choice
        ↓
execute existing ConvoEngine/Interaction/Response pipeline
        ↓
record existing history/memory/effects
        ↓
continue scene or close
~~~

The Director never bypasses canonical validation merely because a candidate
scored highly.

## 5. Utility scoring

Scoring is deterministic and inspectable.

Generic terms may include:

- base relevance;
- stimulus match;
- topic/event/activity relevance;
- continuity bonus;
- role fit;
- freshness;
- relationship/mood relevance from authoritative projected facts;
- repeat/cooldown penalty;
- recent-semantic diversity penalty;
- scene-budget penalty;
- explicit authored priority when already part of canonical metadata.

Do not embed domain-specific world truth directly in the generic scorer.

Domain-specific relevance enters through registered fact/reference providers or
bounded scoring features.

Every score component must be traceable in Semantic Lab/debug tooling.

## 6. Optimization model

The Director must not scan all families every frame.

Use compiler-generated sparse indexes such as:

~~~text
byStimulus
byDomain
byTopic
byActivity
byEventType
byRequiredFact
byKind
~~~

Candidate discovery should intersect small sets before expensive validation.

Runtime rules:

- event-driven evaluation, not per-frame global scans;
- bounded top-K candidate set;
- bounded participant/role combinations;
- stable deterministic tie-breaking;
- required-fact projection only for surviving candidates;
- cache only derived candidate/index results with explicit invalidation;
- no shadow relationship/inventory/mood cache without authoritative invalidation;
- detailed score traces generated on demand, not continuously.

## 7. Role binding

Role binding is generic and participant-count agnostic.

The Director binds existing RoleSpec/cardinality to SceneContext participants.

It may use deterministic role heuristics, but cannot invent invalid role
relationships.

Binding sequence:

1. eliminate participants that fail role kind/cardinality constraints;
2. apply explicit canonical exclusion/relationship constraints;
3. rank remaining bindings using generic relevance features;
4. pass the selected binding through canonical validation;
5. reject/try next bounded candidate when validation fails.

Do not author `actor1`/`actor2`/`speaker2` scene variants.

## 8. Behavior and beat relationship

Behaviors are candidate semantic reactions/actions.

Beats are bounded sequencing/archetype structures.

A scene may select:

~~~text
behavior → dialogue/realization → close
~~~

or:

~~~text
beat → behavior/family candidates → continuation → close
~~~

Simple dialogue does not require a beat.

The Director must not require every semantic family to be wrapped in a scene or
beat.

Current `behavior/scene/*` content remains canonical semantic behavior source.
The old generated `Behaviors/Director/*` files are projections to retire, not a
new authoring namespace to expand.

## 9. Extension model

Adding a new Director-eligible behavior should normally require only:

1. add/edit canonical ConvoEngine behavior source;
2. add translation source if text is introduced;
3. declare existing typed stimulus/reference/role/relevance metadata;
4. run CodeBuilder;
5. tests.

It should not require:

- editing a Director switch statement;
- adding a hand-maintained registration list;
- creating a second Director JSON/Lua copy;
- editing an index by hand.

The compiler derives index membership automatically.

## 10. LLM boundary

Zero LLM calls are required for:

- candidate discovery;
- role legality;
- semantic validity;
- action/effect authority;
- closure;
- memory truth;
- utility scoring.

Optional future LLM use is limited to:

- paraphrasing an already-valid realization;
- non-authoritative flavor;
- optional tie-breaking/ranking among an already-valid bounded candidate set.

LLM output cannot create a new action, effect, state transition, capability,
fact, or semantic branch.

## 11. Debuggability

Semantic Lab/Director debug must expose:

- scene participants;
- trigger/context references;
- candidates considered;
- filter/rejection reasons;
- role bindings considered;
- score components;
- selected candidate;
- canonical validation result;
- continuation/closure decision.

Normal gameplay does not pay for full trace generation.

## 12. Implementation boundary

Do not implement the autonomous Director until the physical layout/localization
normalization is accepted.

Reason:

- the Director should consume one canonical behavior/beat artifact;
- it must not institutionalize `Behaviors/Director` / `Beats/Director` duplicate
  files;
- it should resolve realization keys through the normalized translation
  pipeline rather than embedded locale corpora.

The first Director implementation phase begins only after the S13 layout gate
proves those boundaries.

## 13. Acceptance invariant for the future implementation

A Director implementation is acceptable when:

> one canonical ConvoEngine source produces one semantic runtime artifact;
> compiler-derived indexes discover candidates without semantic duplication;
> ephemeral SceneContext binds live participants and authoritative references;
> deterministic bounded utility scoring selects only canonically valid
> candidates; behaviors/beats remain reusable and participant-agnostic; adding a
> new candidate normally requires source+translation+generation rather than
> Director code edits; runtime evaluation is event-driven and sparse; and no LLM
> or second semantic/gameplay authority is required for correctness.
