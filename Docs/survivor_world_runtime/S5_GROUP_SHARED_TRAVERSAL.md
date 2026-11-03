# S5A Group-Shared Traversal

Snapshot: 2026-11-03.

## Accepted ownership

A mobile SurvivorWorld group now owns one canonical `GroupJourney`.

Normal group members do not persist route geometry or journey progress. Their position is projected from the group journey. An intentionally separated actor may retain its existing Core `ActorWorld.journey`; member projection selects that actor journey as an explicit override without copying it to other members.

Ownership stays split between shared group travel, actor-specific exceptions, and provider runtime.

## Compact route contract

The serialized group route contains bounded route points only. Derived segment geometry is not persisted.

- maximum route points: **64**;
- oversized route input is rejected at SurvivorWorld persistence/mutation boundaries;
- route points are shared once by the group;
- group membership stores actor IDs only.

The journey supports planned/en-route/waiting/paused/arrived/cancelled/blocked states, route-point waits, deterministic projection, save/reload, rebase without changing journey identity, and arrival transition.

A planned-journey regression proves that projections before departure never contribute elapsed travel after departure.

## Projection contract

`SurvivorWorldTraversal.ProjectMemberPosition()` resolves in this order:

1. actor-owned journey when an intentional actor override exists;
2. shared group journey for normal members;
3. static group location when the group has no journey.

No route table is copied into each member actor.

## Serialized footprint

Measured with the production Core JSON encoder using one four-point journey:

| Members | Serialized group bytes | Shared journey bytes |
| ---: | ---: | ---: |
| 1 | 1,110 | 687 |
| 5 | 1,174 | 687 |
| 10 | 1,254 | 687 |
| 25 | 1,494 | 687 |

From 1 to 25 members the group grows only **384 bytes**, while the journey remains exactly **687 bytes**. This satisfies the O(1)-journey gate; only member IDs grow O(N).

The original S0 duplicated-route counterfactual measured about **10.5 KiB** of avoidable route storage at 25 members. S5A removes that duplication from the Core group contract.

## Validation

Passing:

- `psychopatz_survivor_world_group_journey_smoke.lua`;
- all six SurvivorWorld focused tests;
- full Core Lua sweep: **136/143** pass;
- the same seven unrelated Core failures remain and were previously reproduced on clean HEAD;
- `luac -p`: **8/8** changed production Lua;
- installed-PZ Kahlua compiler: **8/8** changed production Lua;
- `git diff --check`: pass.

## Next

S5B migrates ProjectHoomans mobile-group travel/projection onto the Core group journey contract while leaving live body/pathing policy in Hoomans.
