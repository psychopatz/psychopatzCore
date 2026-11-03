# Architecture — Compact Survivor World Runtime

## 1. Ownership

### PsychopatzCore

Core owns reusable survivor-world mechanisms:

- compact actor identity/durable state;
- deterministic appearance contract;
- affiliation references;
- generic faction records;
- communities/settlements;
- mobile groups;
- generic population sectors/generation contracts;
- abstract world location/journey;
- group journey/projection;
- provider leases/transitions;
- discovery entities/signals;
- shared map presentation, selection, highlight, tracking;
- generic world debug tools;
- compact persistence and size telemetry.

### ProjectHoomans

Hoomans owns physical gameplay/runtime:

- live bodies;
- combat/needs;
- physical perception/pathfinding;
- animations;
- local AI;
- facilities/jobs;
- Hoomans gameplay policy;
- caravan composition/equipment policy;
- physical inventory/body sync;
- physical interaction UI.

### DynamicTrading

DTCommon owns economics:

- trader role mapping;
- stock/budget;
- prices/quotes/trades;
- settlement market/exchange;
- trader commercial policy.

### DTAbstract

DTAbstract is a lightweight representation/interaction adapter. It does not own a second faction/community/population/map world.

## 2. Compact canonical records

### Actor

Persist only compact durable fields:

```text
actorID
identity seed + durable identity
appearance seed/profile/version + sparse authored/durable delta
factionID
communityID
groupID
role/rank/tags
durable condition flags
provider lease
optional personal world override
bounded social/knowledge deltas
revision/schema
```

### Faction

Stored once:

```text
factionID
seed/archetype
name/generation contract
generic disposition/diplomacy
community refs
bounded deltas
```

### Community

Stored once:

```text
communityID
seed/profile
factionID
site/anchor/location
generic population summary
discovery/public metadata
bounded deltas
```

### Mobile group

Stored once:

```text
groupID
factionID
memberIDs
leaderID
role/mission
shared journey
shared current/destination location
provider-neutral lifecycle
revision
```

## 3. Persistence classes

Every field must be one of:

**Canonical durable** — stable IDs, reconstruction contracts, affiliations, durable role/condition, provider lease, durable relationships/knowledge.

**Compact world** — group membership, shared journey, abstract location, mission, settlement/faction/discovery state.

**Provider runtime** — body, AI, pathing, combat/perception/animation, transient needs/tasks/UI. Never canonical unless explicitly promoted through a durable-delta policy.

## 4. Seed + delta rule

Canonical state is:

```text
deterministic base(seed + generatorVersion + archetype)
+ sparse durable deltas
```

Do not serialize reconstructable resolved state merely for convenience.

Generator-version changes must never silently mutate existing canonical identity/appearance.

## 5. Appearance/portraits

Generated appearance persists seed/profile/version plus durable overrides.

Resolved generated appearance is reconstructed/cached at runtime where safe.

Authored/custom appearance that cannot be regenerated remains persistable.

Portraits must work without a live body.

## 6. Inventory

Abstract actors must not require hydrated FULL inventory.

Default:

- untouched deterministic actor -> SEED_ONLY;
- durable mutations -> BASELINE_DELTA;
- FULL only for unsupported/non-deterministic/imported exact state.

Materialization hydrates lazily. Dematerialization compacts to the smallest safe mode.

Merchant stock remains separate from actor personal inventory.

## 7. Hydration/dehydration

Materialize:

Core compact actor/group
→ Hoomans provider
→ reconstruct identity/appearance
→ hydrate personal inventory if needed
→ create body/AI/needs/runtime
→ bind one body lease.

Dematerialize:

physical actor
→ capture durable changes
→ compact inventory
→ persist approved appearance/condition/social changes
→ rebase shared/individual journey
→ discard runtime state
→ release body lease.

## 8. Traversal

Group travel is shared state.

All member actor positions can be projected from one group journey for map, discovery, dialogue and interaction eligibility.

Individual journey exists only when an actor intentionally separates.

## 9. Map/discovery parity

Core owns one provider-neutral presentation model:

- per-actor dot;
- overlap spreading;
- route/target;
- name/role;
- portrait;
- hover;
- selection;
- highlight/tracking;
- group/faction/community context;
- discovery visibility.

Physical providers may add detail but not a second actor-map authority.

## 10. Debug parity

Core generic debug tools work in abstract-only and Hoomans modes:

- discover all settlements;
- discover all mobile groups;
- discover all signals;
- raw overlays;
- actor/group/faction/community inspectors;
- footprint diagnostics;
- provider/materialization diagnostics.

## 11. ModData budget

Serialized size is a correctness requirement.

Telemetry must report bytes for actor, faction, community, group/journey, discovery, inventory mode and adopter extensions.

Mandatory qualitative gates:

- untouched abstract actors have no FULL inventory;
- no AI/body/runtime tables in canonical persistence;
- group journey is not duplicated per member;
- generated/default fields can be omitted/reconstructed;
- size growth is compact and approximately linear.

S0 establishes evidence-backed byte budgets before schema migration.

## 12. Migration

Use staged versioned migration:

1. read old data;
2. validate;
3. project to compact schema in memory;
4. verify IDs/appearance/inventory/world parity;
5. write only the new schema after acceptance;
6. no indefinite dual writes;
7. unknown versions quarantine/report instead of silent reset.

Temporary migration adapters are removed after migration except intentional bounded version decoders for supported saves.
