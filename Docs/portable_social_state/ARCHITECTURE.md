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

## 15. Frozen P1 Portable Contracts & Limits

### 15.1 Target Key & Identity Contract

`PsychopatzSocial.NormalizeTargetKey(value)` and `PsychopatzSocial.ParseTargetKey(value)` recognize:

- `actor:<id>` (`kind = "actor"`)
- `npc:<id>` (`kind = "npc"`)
- `player:<accountIdentity>:<characterUUID>` (`kind = "player"`, canonical persistent identity)
- `player:<id>` (`kind = "player"`, legacy/session key resolved via `state.aliases`)
- `steam:<id>` (`kind = "steam"`)

All keys reject empty strings, whitespace-only values, and control characters. `state.aliases[aliasKey] = canonicalKey` redirects reads, mutations, authorized events, extensions, and candidate projections transparently.

### 15.2 Directed Relationship & Baseline Contract

Each sparse entry `state.relationships[targetKey]` owns:

- `targetKey` (`string`)
- `approval` (`number`, clamped `[-100, 100]`, default `0`)
- `respect` (`number`, clamped `[-100, 100]`, default `0`)
- `familiarity` (`number`, clamped `[0, 100]`, default `0`)
- `baselineApproval` (`number`, clamped `[-100, 100]`, optional/default `0`)
- `baselineRespect` (`number`, clamped `[-100, 100]`, optional/default `0`)
- `state` (`"unknown"|"neutral"|"friend"|"rival"|"enemy"`, optional/resolved from scores + hysteresis)
- `previousState` (`"unknown"|"neutral"|"friend"|"rival"|"enemy"`, optional)
- `revision` (`integer >= 0`)
- `lastEventAt` (`number|nil`)
- `lastEvaluatedAt` (`number|nil`)
- `memories` (`Memory[]`, bounded `<= MAX_MEMORIES = 64`)
- `cooldowns` (`map<string, number>`, bounded `<= MAX_COOLDOWNS = 32`)
- `saturation` (`map<string, { approval: number, respect: number }>`, bounded `<= MAX_SATURATION = 32`)
- `extensions` (`map<string, table>`, bounded `<= MAX_EXTENSIONS_PER_SCOPE = 16` namespaces)

**Convergence invariant (Baselines + Memories):** When a memory is inserted with `approvalEffect`/`respectEffect`, its active contribution tracks against `baselineApproval`/`baselineRespect`. Non-persisted (`SCENE`) deltas, direct `MutateRelationship` score changes, and capacity-evicted non-expired memory residues promote into `baselineApproval`/`baselineRespect` so cross-mod recalculation (`RecalculateRelationship`) never erases deltas applied by another adopter (such as `DynamicTrading` trades alongside `ProjectHoomans` social events).

### 15.3 Memory, Retention, Lazy Decay, Consolidation & Provenance Contract

- **Hard limits:** `MAX_MEMORIES = 64`, `MAX_SHORT_MEMORIES = 16`, `MAX_LONG_MEMORIES = 42`, `MAX_ANCHOR_MEMORIES = 6`, `MAX_RECENT_EVENTS = 128`, `MAX_COOLDOWNS = 32`, `MAX_SATURATION = 32`, `MAX_EXTENSIONS_PER_SCOPE = 16`.
- **Retention classes (`retentionClass`):**
  - `SCENE`: transient; never stored in `relationship.memories`.
  - `SHORT`: short-horizon episodic; default `decayPerDay = 1.0`, cap `16`.
  - `LONG`: multi-day episodic; default `decayPerDay = 0.05`, cap `42`.
  - `ANCHOR`: permanent identity-defining (`permanent = true`, `decayPerDay = 0`), requires `salience >= 180` or explicit anchor policy, cap `6`. On anchor saturation, deterministic comparison by `(salience, effectMagnitude, count, createdAt, eventSequence, id)` either demotes the weakest existing anchor to `LONG` or demotes the incoming entry.
- **Lazy decay:** `CalculateMemoryStrength(memory, worldAgeHours)` evaluates `math.max(0, strength - decayPerDay * math.max(0, (worldAgeHours - createdAt) / 24))` on query, recalculation, or event insertion; zero per-tick loops.
- **Consolidation:** Repeated equivalent `SHORT`/`LONG` events sharing `consolidationKey` coalesce in place: incrementing `count`, preserving `firstCreatedAt`, updating `createdAt` / `lastEventID` / `eventSequence`, refreshing `strength` / `salience`, and accumulating `approvalEffect` / `respectEffect` / `familiarityEffect` within policy caps (`maxConsolidatedApproval`, `maxConsolidatedRespect`, `maxConsolidatedFamiliarity`).
- **Provenance:** Each memory carries compact semantic provenance: `sourceMode` (`"direct"|"witnessed"|"hearsay"|"system"`), `knowledgeSource`, optional `sourceKey`, `confidence` (`[0, 1]`), and `shareable` (`boolean`).

### 15.4 Candidate-Oriented Projection & Action-Neutral Decision Feature Seam

- Social.QueryCandidateProjection(state, target, options) and the authority wrapper return a bounded read-only projection without mutating state.
- Portable Social State may expose a second bounded action-neutral decision-feature projection. It may derive trust, grievance pressure, assistance history, familiarity, caution-relevant evidence, provenance confidence, direct or witnessed or hearsay evidence, relationship and social revisions, and personality inputs.
- The social subsystem must not know concrete autonomy candidate IDs or own candidate-specific utility formulas. TALK, TRADE, HELP, AVOID, CONFRONT, REPORT, RETALIATE, future work or task actions and advertisement-specific scoring belong to the future Autonomy Resolver or domain consumer.
- The current P8 EvaluateAutonomyCandidates implementation is a migration target, not the canonical long-term API. P11 must retire or move it after caller-zero proof. No permanent compatibility shim is required for a pre-release internal seam.

### 15.5 Compact Default-Omission Persistence Invariant

`Social.NewState()` with no arguments MUST remain minimal and deterministic so `PsychopatzActorPersistence.lua` continues omitting `payload.social` for actors with zero social edges, default personality, no recent events, and no extensions.

### 15.6 CodeBuilder Social Policy IR Contract

- Authoring schema: `psychopatz.social-policy.v1`
- Package schema: `psychopatz.social-policy.package.v1`
- Compiled runtime plan schema: `psychopatz.social-policy.runtime-plan.v1`
- Generation recipe surface: `social_policy_lua` (`generator = "social_policy"`), routed per owner via `targets/pz_packages.json` (`PsychopatzCore/SocialPolicy`, `PNC/SocialPolicy`, `DTCommon/SocialPolicy`).
- Compiler static validation fails closed on: unknown retention class, `ANCHOR` without `salience >= 180` or `anchorMax <= 6`, `observerPolicy.maxObservers > 8`, `hearsayPolicy.maxHops > 2`, out-of-range deltas/caps, or any PZ Java / ModData / PNC / DT implementation reference in canonical IR.
- Compiles deterministically to `<Owner>/SocialPolicy/Registry.lua` (plus domain modules), includes source map metadata, and registers `DomainSchema(domain = "social", ...)` into `DomainSchemaRegistry` for static validation of `convo-engine.v1` dialogue modifiers.

### 15.7 Single Persistence Authority Contract

For any actor represented in PsychopatzCore, generic portable social state is persisted exactly once in Core actor.social.

Adopters may keep only genuinely product-specific extension state in their own persistence. A Project Hoomans runtime record may present a combined convenience view derived from Core generic social state plus PNC-owned morale, conduct, bond and journal state, but that combined generic view is ephemeral and must not be serialized as a second relationship or memory history.

Supported older saves may use an explicit versioned migration that imports legacy adopter generic social state into Core once. The migration must not become permanent dual-write or dual-read authority.

### 15.8 Native Player Identity Safety Contract

Persistent player identity is server-authoritative, survives reconnect and save reload, rejects cross-account conflicts, and must be generated and issued using Project Zomboid-safe primitives.

Portable identity code must not depend on sandboxed os.* APIs. Identity issuance must remain collision-safe under repeated creation and harness-verifiable without relying on transient online player indices as the persistent key.
