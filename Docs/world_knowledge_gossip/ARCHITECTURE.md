# Architecture — Grounded World Knowledge & Gossip

## Ownership

PsychopatzCore owns reusable mechanism only:
- WorldFact primitive, stable IDs and schema/versioning;
- bounded fact ledger/index/retention;
- actor knowledge references and provenance/confidence vocabulary;
- generic dissemination/query/ranking contracts;
- portable conversation-context projection contract;
- diagnostics needed to explain why an actor knows a fact.

ProjectHoomans owns Hoomans/PZ policy and producers:
- faction/member/community/settlement incidents;
- NPC death/corpse/health facts where the authoritative Hoomans owner can prove them;
- zombie-pressure normalization from existing cached threat data;
- adapters to authoritative Project Zomboid helicopter/power/water/season state;
- Hoomans-specific dissemination policy and localized semantic realization where appropriate.

DynamicTrading owns trading facts and commerce:
- trader/caravan/route/market observations;
- stock, budget, quote, session and transaction authority remains DTCommon;
- radio Talk never authorizes remote inventory transfer merely because a fact is discussable.

## Data model

A generic fact is primitive-only and serialization-safe. Exact field names are to be source-audited before freezing, but the contract must support:

~~~text
WorldFact
  id
  kind
  subject?       stable entity/faction/location reference
  object?        optional second reference
  cause?         typed cause, not free-form prose
  location?      coarse stable region/sector/community reference
  happenedAt
  severity?
  retention      ephemeral | historical | derived
  dissemination policy/reference
  revision/schema
~~~

An actor knowledge entry references a fact instead of copying it:

~~~text
ActorFactKnowledge
  factID
  learnedAt
  sourceKind     experienced | witnessed | told | radio | faction | public | inferred
  sourceActorID?
  confidence?
  flags?
~~~

Do not copy full fact payloads into every actor. Do not persist localized EN/TL sentences.

## Event/state lifetimes

Ephemeral facts: zombie pressure, active helicopter, transient gunfire/weather-like context. Runtime or short TTL unless an actor forms a meaningful memory.

Historical facts: deaths, faction destruction, major diplomacy changes, settlement collapse, major rescue. Persist in a bounded ledger with retention/compaction policy.

Derived current state: power, water, season, current faction status/population. Query the authoritative owner when current truth is needed; do not duplicate that state in multiple ModData stores merely for dialogue.

## Zombie pressure

Hoomans already states that population-wide zombie enumeration belongs to PNC_WorldCensus. PNC_SpatialIndex and PNC_Perception_Frame provide bounded cached nearby threat data; follower/combat horde awareness already consumes those caches and maps counts into coarse bands.

The new system MUST reuse an existing cached/bounded observation. It MUST NOT add an independent getZombieList scan or per-NPC world census.

Normalize meaningful transitions rather than persisting raw counts, e.g. CLEAR/LIGHT/MODERATE/HEAVY/HORDE. Repeated observations in the same band do not create repeated historical facts.

## Knowledge and dissemination

Facts never become universally known merely because they exist.

A producer supplies or references dissemination policy. Examples:
- eyewitness/experienced: actor present/perception-qualified;
- faction: appropriate faction members can learn an incident;
- nearby: geographically relevant actors/factions may learn later;
- public/environmental: observable world state can be known when conditions allow;
- told/radio: learned through an explicit social/radio exchange.

V1 keeps canonical facts truthful. Do not implement fabricated/false rumor mutation. Uncertainty comes from provenance/confidence and presentation: "I saw..." versus "I heard...".

Propagation is event-driven/opportunistic, not a global gossip tick. Valid triggers include real conversations, social idle interactions, faction contact and authenticated radio contact. Select a small bounded number of shareable novel facts, dedupe by fact ID, apply pair/fact cooldowns, and never iterate every actor against every fact each tick.

## Conversation projection

Preserve the existing shared conversation path.

~~~text
authoritative owners
  -> WorldFact adapters
  -> Core WorldKnowledge/actor knowledge
  -> bounded relevance query
  -> existing conversation context
       -> offline semantic response
       -> optional PBrainZ
~~~

Hoomans currently consumes npcGossip.statements and the semantic resolver already caps rendered gossip lines. Migrate that input to a real grounded provider rather than creating a second gossip engine.

PBrainZ may rephrase only facts already authorized for that actor/player/context. It must never query the global fact ledger directly to discover private truth.

## Ranking

Rank only already-authorized actor-known candidates. Bounded relevance may consider recency, importance, geographic/social relevance and novelty. Ranking cannot make an unknown/private fact visible.

## Persistence budget

Initial implementation must establish measured budgets rather than silently grow ModData. Directional targets:
- one bounded global historical fact ledger, expected order of hundreds rather than unbounded history;
- bounded per-actor fact references, expected order of dozens;
- runtime-only ranking caches, zombie-pressure state, pair cooldowns and dissemination queues;
- compact primitive IDs/timestamps/enums rather than prose/transcripts.

Exact limits are accepted only after tests measure save footprint and realistic actor/fact counts.

## Diagnostics invariant

Every rendered gossip statement must be explainable:
fact ID/type -> authoritative producer -> subject/cause/location -> how actor learned it -> confidence/source -> why candidate ranked -> localization/realization selected.

If diagnostics cannot answer "why does this actor know this?", acceptance fails.
