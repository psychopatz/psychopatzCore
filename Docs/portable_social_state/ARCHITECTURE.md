# Architecture — Portable Social State

## 1. Ownership

| Concern | Canonical owner | Adopter responsibility |
| --- | --- | --- |
| stable actor identity/provider continuity | PsychopatzCore Actors | map domain NPC/trader/player identity to Core actor refs |
| generic personality/social state | PsychopatzCore PsychopatzSocial | supply domain/personality policy, never copy generic truth |
| sparse directed relationships | PsychopatzCore | emit authorized domain events and consume projections |
| compact bounded relationship/event memory | PsychopatzCore | define domain event meaning/policy through adapters/CodeBuilder |
| social policy IR/compiler mechanism | PsychopatzCore CodeBuilder | own adopter policy source packages |
| semantic evidence/conversation projection | Core reusable contracts + adopter providers | expose bounded facts; domain truth stays authoritative |
| Hoomans conduct/factions/physical NPC rules | ProjectHoomans | adapt rich Hoomans semantics into Core social contracts |
| merchant stock/budget/quotes/trade commit | DTCommon | remain economic authority |
| abstract trader provider/radio access | DTAbstract | reuse same Core actor/social state without body/Hoomans |
| physical trader representation | DTHoomans + Hoomans body provider | reuse same actorID/social state |
| intrinsic/market economic value | MarketSense | remain economic evidence/valuation authority |

There must be one canonical shared directed relationship for a Core actor pair. Adopter-specific extensions are allowed only for genuinely domain-specific state and must not duplicate generic dimensions or memory history.

## 2. Existing Core foundation

Current PsychopatzSocial already provides:

- schema-versioned actor social state;
- sparse relationships[targetKey];
- approval/respect/familiarity;
- per-relationship revision and actor social revision;
- server-authorized event recording;
- bounded relationship memories;
- recent-event deduplication;
- namespaced extension bags;
- player/NPC/actor target-key normalization.

The roadmap evolves this foundation rather than replacing it.

## 3. Target social-state model

    Core Actor
      |
      +-- personality / overrides
      |
      +-- sparse directed relationships
      |     target actor
      |       +-- generic dimensions
      |       +-- revision
      |       +-- compact bounded memories
      |       +-- namespaced adopter extensions
      |
      +-- bounded recent event identities
      +-- actor-level social revision

Memory describes significant evidence/history. Relationship summarizes durable social attitude. Knowledge belongs to the appropriate knowledge/fact authority. Current threat/hostility is an operational projection, not automatically a permanent relationship bit.

## 4. Retention classes

Portable semantic retention vocabulary:

- SCENE: transient; never persisted by Core social state;
- SHORT: short-lived/current-day or bounded recent significance;
- LONG: durable episodic evidence with decay/expiry policy;
- ANCHOR: rare high-salience effectively permanent memory under a very small hard cap.

Exact numeric budgets are measured/selected during implementation. They are configurable only within compiler/runtime hard bounds.

No per-tick decay. Effective strength/expiry is evaluated lazily on targeted query, activation, bounded maintenance, save/day transition or explicit reconciliation.

## 5. Consolidation

Repeated equivalent events must not linearly grow social memory.

Portable policy can declare a consolidation family/key derived from stable bounded inputs such as:

- semantic event class;
- source/subject;
- target;
- relation family;
- optional adopter scope.

Consolidated state may retain count, first/last time, bounded severity/effect aggregate and representative provenance.

Important high-salience events may remain distinct.

## 6. Event identity and provenance

Prefer existing stable event IDs and owner references. Do not add an unbounded global event database by default.

A memory/evidence projection may identify:

- direct target;
- direct witness;
- hearsay from actor X;
- domain/system evidence.

Provenance is compact semantic metadata, not copied prose.

Shared event identity should minimize duplicated event payload while allowing each actor to hold a distinct interpretation/strength/source mode.

## 7. CodeBuilder and Social Policy IR

The existing CodeBuilder toolchain is the compiler authority.

Canonical adopter policy conceptually declares:

    event trade.fair_deal
      memory:
        retention
        salience
        consolidation
        observer/hearsay policy
      relationship:
        generic effect classes/deltas or registered modifier refs
      evidence:
        semantic classes/relations
      extensions:
        adopter-owned bounded metadata contract

Compiler passes must include:

1. parse/normalize;
2. symbol and owner resolution;
3. schema/type validation;
4. bound/static fan-out validation;
5. authority validation;
6. deterministic ID/lowering;
7. generated runtime plan/table;
8. source/debug map;
9. affected fixture discovery;
10. deterministic output check.

Canonical source must never contain direct PNC/DT/PZ engine calls. Dynamic behavior uses registered typed predicates/effects/adapters with explicit owner contracts.

## 8. Project Hoomans adoption

Hoomans currently owns richer social/event/relationship systems. Implementation must audit overlap against Core.

Rules:

- migrate/reuse generic shared dimensions/history in Core where portable;
- retain Hoomans-only conduct/faction/romance/physical-world rules behind adapters when genuinely product-specific;
- do not keep two writable generic relationship histories;
- Hoomans SocialEvent commits may emit one authorized Core social event plus domain-owned consequences;
- Hoomans semantic evidence and Conversation Director consume bounded Core/adopter projections rather than raw state dumps.

## 9. DynamicTrading / DTAbstract adoption

DynamicTrading already maps traders to Core actor IDs and already consumes Core social relationship values for pricing.

Target behavior:

    authoritative trade outcome
          |
          v
    DTCommon trade-domain event adapter
          |
          v
    Core authorized social event
          |
          +-- directed relationship update
          +-- bounded/consolidated memory
          +-- revision
          |
          v
    later trade/conversation query
          |
          +-- DTCommon pricing/credit/negotiation policy
          +-- ConvoEngine trader dialogue/evidence
          +-- DTAbstract remote trader interaction

The social system can influence willingness, relationship modifier, negotiation patience, credit eligibility inputs, dialogue, requests and remembered grievances. It never owns market price, stock, funds or trade commit.

DTAbstract must use exactly the same actorID/social state as the physical representation. Materialization/dematerialization cannot reset trader memory.

## 10. Player handling

NPC/trader -> player relationship is ordinary directed Core actor social state using stable persistent player identity mapping.

Human player feelings are not inferred. Player -> NPC/player state is recorded only where an explicit gameplay/domain contract owns it.

Reconnect/online-ID changes must not create a new social identity.

## 11. Multiplayer

Server authority owns social mutation.

Clients may submit domain actions but never authoritative social deltas or memories.

Replication returns bounded projections necessary for UI/conversation, not private full NPC/trader social stores.

Revision mismatch causes refresh/revalidation.

DTAbstract remote access does not weaken authority: radio/session authorization and trade authorization remain DTCommon/DTAbstract concerns; social state is merely context.

## 12. Future emergent-autonomy compatibility

This Core social state is a foundation for a future non-LLM emergent stack:

    World Signals
       -> Event / Opportunity Director
       -> Advertisement / Affordance providers
       -> NPC Autonomy Resolver
       -> Task / Action authority
       -> authoritative events
       -> Portable Social State
       -> future decision context

The social subsystem supplies bounded memory/relationship/knowledge/threat features. It does not choose the final action or own world pacing.

A remembered grievance may increase the viability of AVOID, CONFRONT, REPORT or RETALIATE, but Core social state does not command one response.

## 13. Performance

Required invariants:

- sparse actor-pair edges only;
- no population-squared allocation;
- bounded memories per meaningful relationship;
- bounded recent-event dedup;
- no per-memory/per-actor tick aging;
- no transcript persistence;
- no full social graph replication;
- targeted candidate-oriented queries;
- ephemeral indexes/caches rebuildable from compact canonical state;
- abstract traders/NPCs retain compact state without live-body overhead.

## 14. Migration rule

Do not preserve permanent compatibility shims merely to keep superseded duplicate social authorities alive.

Migration must be measured, explicit and owner-scoped:

- read old authoritative state;
- normalize into the accepted Core contract;
- verify adopter behavior;
- switch writers;
- remove obsolete duplicate writer/path once caller-zero is proven.

Generated/CodeBuilder policy is changed at canonical source, never by hand-editing generated output.
