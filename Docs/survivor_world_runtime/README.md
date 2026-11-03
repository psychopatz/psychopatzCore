# Compact Survivor World Runtime

## Parent objective

Create one compact, provider-agnostic Survivor World in PsychopatzCore so ProjectHoomans and DynamicTrading/DTAbstract simulate the **same persistent people, factions, communities, groups, journeys, discovery state, and map entities**.

The representation difference is intentional:

- **Abstract provider:** no live NPC body, no physical AI, no hydrated full inventory, no combat/needs/pathfinding runtime.
- **ProjectHoomans provider:** materializes the same canonical actors into rich physical Hoomans runtime when required.

The compact world must scale to large abstract populations without storing a full Hoomans record for every off-screen NPC.

## Why this goal exists

Native testing exposed a broader parity gap after trader-world unification:

- ProjectHoomans owns dynamic population/faction/community/group generation, WorldDiscovery, individual NPC travel-map entries, hover/highlight behavior, and discovery debug tools.
- DTAbstract still has a separate trader-centric map and DTCommon static settlement defaults.
- abstract-only mode therefore does not represent the same generated survivor world.

The fix is not to copy ProjectHoomans into DTAbstract and not to make DTAbstract require ProjectHoomans. Reusable world simulation moves into Core; physical mechanics remain Hoomans-owned.

## Compactness principle

A canonical abstract actor is **not** a full Hoomans NPC without a body.

Persist only durable information needed to answer:

- who the actor is;
- what they look like;
- faction/community/group/role;
- durable life/condition state;
- where they or their group are;
- where they are going;
- durable relationships/knowledge;
- current provider/representation.

Provider runtime state is disposable.

## Target shape

```text
PsychopatzCore Survivor World
  compact persistence
  actors + factions + communities + groups + journeys + discovery
                       |
              +--------+--------+
              |                 |
        Abstract provider   Hoomans provider
        no live body        live body
        cheap projection    physical AI/combat
        map/portrait        hydrated inventory
        radio/notify        NPC interaction
              |                 |
              +--------+--------+
                       |
                   DTCommon
              trader/economy roles
```

## Persistence strategy

Use **deterministic base + sparse durable delta**.

Existing foundations already help:

- Core identity/appearance are seed-driven.
- Core ActorInventory supports SEED_ONLY, BASELINE_DELTA, and FULL.
- Hoomans inventory persistence has the same compact modes.
- Core actor journey/provider/persistence/projection already exists.

This goal makes compact persistence the default.

## Completion boundary

Developer completion requires:

- one Core survivor-world registry/model;
- reusable PNC population/faction/community/group/discovery mechanisms migrated to Core;
- DTAbstract consumes the same world rather than static trader/town simulation;
- abstract actors do not hydrate bodies, AI, or full inventories;
- untouched actors use compact seed-first inventory/appearance;
- group traversal is stored once per group;
- Hoomans hydrates/dehydrates the same actors;
- shared per-NPC map dots/routes/hover/selection/highlight work in both modes;
- shared discover-all settlements/groups/signals/debug tools work in both modes;
- static DTAbstract world fallbacks are removed after migration;
- measured ModData budgets pass;
- cross-repository automated acceptance passes;
- only native SP/MP acceptance remains.

## Documents

- AUDIT.md
- ARCHITECTURE.md
- COMPACT_PERSISTENCE.md
- ROADMAP.md
- HARNESS_ACCEPTANCE.md
- AGENT_RUNBOOK.md
- PROGRESS.md

The executable /goal prompt remains conversational unless explicitly requested.
