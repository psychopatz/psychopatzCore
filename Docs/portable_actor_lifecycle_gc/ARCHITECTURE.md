# Architecture — Portable Actor Lifecycle & Social Garbage Collection

## 1. Ownership

PsychopatzCore owns live actor identity, provider leases, player-character identity, tombstones, reference providers, GC, sparse generic relationships, the social memory bank, and the portable Social Policy compiler/runtime mechanism.

Project Hoomans keeps corpse/reanimation/death-marker gameplay and Hoomans-specific bonds, conduct, factions, quests, memorials, and physical NPC behavior.

DynamicTrading keeps stock, budgets, quotes, sessions, debts/contracts, and commercial-role policy.

Future mods register bounded reference providers instead of patching Core GC.

## 2. ActorRef lifecycle

Lifecycle operates on canonical ActorRefs, not only live ActorRegistry records.

Required refs include Core actor IDs and persistent player-character refs.

Public lifecycle states:

    LIVE
      -> RETIRED
      -> TOMBSTONE
      -> FORGOTTEN / PURGED

RETIRED and TOMBSTONE may share one compact stored form if separate persistence is unnecessary.

Core Registry Remove remains valid only for rollback/uncommitted creation or proven superseded migration state. Meaningful death/permanent departure uses lifecycle retirement.

## 3. Tombstone

A tombstone is intentionally tiny and bounded.

It may store canonical ref, kind, compact display identity, owner/source code, retiredAt, reason class, lifecycleRevision, grace metadata, and small flags needed for portable resolution.

It must not retain inventory, needs, tasks, full appearance, provider runtime, outgoing relationships, the retired actor's memory bank, full Knowledge, transcript history, or adopter commercial state.

Adopter corpse markers and memorials are separate domain objects and can pin the Core tombstone only while truly needed.

## 4. Directional relationships

Relationships remain directional: A -> B and B -> A are independent.

When A retires:

- A's outgoing generic social state is recyclable;
- B -> A may survive as a compact historical edge when meaningful;
- weak/unimportant B -> A edges are prunable;
- death does not automatically make every incoming edge permanent.

Historical retention may depend on anchor memory, durable bond/family/romance, unresolved grievance, debt/commitment, quest/faction/story pin, meaningful relationship magnitude, or recent significant evidence.

Historical edges should discard live-only cooldown/saturation fields when no longer useful.

## 5. Actor-level Social Memory Bank

Current relationship-local memory bounds can multiply by relationship count.

Target:

    actor.social
      relationships[target] -> compact current/historical summary
      memoryBank[]          -> bounded episodic evidence owned by this actor

Each memory stores relevant ActorRefs/roles, event class, retention class, salience/strength, provenance, timestamps, and consolidation metadata.

Initial design target:

- total persistent social memories per actor: 96;
- SHORT: 24;
- LONG: 56;
- ANCHOR: 16;
- SCENE: never persistent.

L0/L3 measurements may tune defaults, but the invariant is one bounded actor-level budget with a fixed hard ceiling.

Migration from per-edge memories must be versioned and deterministic, preserve anchors and baseline effects, consolidate duplicates, and remove per-edge persisted memory arrays after caller-zero. No permanent dual representation.

Active actors may build ephemeral memoryByTarget/memoryByClass/memoryByEvent indexes that are never persisted.

## 6. Reference strength

STRONG pins historical identity while its owning fact matters. Examples include anchor memory, unresolved murder/betrayal grievance, family/bond, active quest, memorial, or outstanding contract/debt that truly requires actor identity.

WEAK may resolve while a tombstone exists but does not keep it forever. Before purge, weak projections degrade to a bounded role/category rather than dangling.

LABEL_ONLY carries semantic meaning without actor identity, for example former_companion or old_trader.

No reference strength permits transcript persistence.

## 7. Reference providers

Core exposes one bounded provider registry.

Conceptually:

    RegisterReferenceProvider(providerID, provider)

    provider.CollectStrongRefs(context, emit)
    provider.CollectWeakRefs(context, emit)   optional
    provider.OnBeforePurge(ref, context)      optional bounded compaction

Providers must be deterministic, server-side, owner-scoped, bounded, and nonblocking.

No persistent reference count is authoritative.

## 8. Mark-and-sweep GC

Mark tombstones reachable from strong roots:

- Core social strong refs;
- retained historical edge pins;
- registered quest/faction/bond/contract/corpse providers;
- other explicit bounded roots.

Sweep only when:

- tombstone is unmarked;
- grace/minimum age elapsed;
- no provider/body/transaction owns it;
- weak refs have been compacted/degraded safely.

Sweep removes orphaned aliases/index records too.

GC runs on startup/reload reconciliation, save/day boundaries, count thresholds, explicit maintenance, or budgeted scheduler slices after retirement.

Never scan the world on every Tick.

Long passes must be cursor/generation budgeted.

## 9. Retirement transaction

Authoritative death/permanent retirement order:

    validate authority + lifecycle revision
      -> process grounded domain/social consequences
      -> capture minimal tombstone identity
      -> release body/provider/task/live-only state
      -> remove outgoing private social/memory/knowledge state
      -> publish lifecycle revision
      -> keep incoming survivor history valid
      -> later GC compacts/purges when roots disappear

Do not retire before corpse/inventory/domain systems capture state they own.

## 10. Project Hoomans

PNC DeathMarkers remain Hoomans-owned corpse/player-facing lifecycle records, not the Core tombstone database.

On NPC death Hoomans:

- performs corpse/reanimation/social consequences;
- retires the canonical Core actor;
- may expose a temporary GC root while corpse/reanimation/UI identity is needed;
- preserves real bonds/quests/faction memorial refs through their own providers;
- does not make ordinary unowned deaths permanent cemetery records.

## 11. Player-character death

Player account identity and player-character identity are separate.

On authoritative character death:

- retire the character ref;
- NPC -> player historical edges/memories may remain when meaningful;
- no automatic transfer of personal relationship to a new character;
- optional account/faction reputation remains a separate domain authority;
- same living character reconnect keeps identity;
- new character gets a new character identity.

## 12. DynamicTrading

Commercial-role removal is not automatically actor death.

Rollback, debug trader deletion, provider dematerialization, superseded migration actor, and true death/permanent actor retirement must be classified separately.

Outstanding debt/contracts pin identity only when actual DT domain state requires it.

DT remains commercial authority.

## 13. Semantic projection

Semantic code never scans raw tombstones or all memories.

Core returns a bounded ActorIdentityProjection with:

    status = LIVE | RETIRED | FORGOTTEN
    compact display identity when available
    lifecycleRevision

Social context may include a compact relationship snapshot, top bounded relevant memories, lifecycle state, provenance, and social/relationship/lifecycle revisions.

Weak history degrades gracefully:

    Alice died
      -> my former companion died
      -> I lost someone

## 14. Interaction responsiveness

Clicking Interact never triggers GC or history reconstruction.

Hot path:

    resolve ActorRef
      -> GetHotRelationshipSnapshot
      -> resolve lifecycle revision/status
      -> open UI
      -> use cached/precompiled candidate index
      -> only surviving semantic candidates request bounded SocialQueryPlans

No world scan, GC sweep, CodeBuilder work, raw ModData traversal, or LLM is allowed on the click path.

Decision tokens carry lifecycleRevision plus social/relationship revisions and revalidate before commit.

## 15. CodeBuilder Social Policy

Extend the existing Social Policy IR, not another compiler.

Canonical policy may declare:

    references:
      target: STRONG
      subject: WEAK
      witness: LABEL_ONLY

Compiler validates known strengths, bounded fan-out, retention/reference compatibility, owner routing, deterministic lowering, and source maps.

## 16. Multiplayer

Only server authority can retire refs, create/update/purge tombstones, mutate social memory/relationship state, and advance lifecycle revisions.

Clients receive bounded presentation projections only.

## 17. Diagnostics

Required debug/harness surfaces:

- ExplainRetention(ref);
- ExplainPurge(ref);
- memory/edge counts by retention class;
- strong/weak root counts by provider;
- GC generation/cursor/budget;
- tombstone age/size;
- orphan detection;
- interaction social-query counts/latency.

Diagnostics are projections, not persistent logs.

## 18. Failure behavior

Fail closed on invalid authority, stale lifecycle revision, malformed/unbounded provider roots, unknown strong refs without migration, or purge that would break a strong root.

Failed GC leaves canonical state valid and retryable.
