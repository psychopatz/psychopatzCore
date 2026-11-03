# Progress — Compact Survivor World Runtime

## Parent status

**ACTIVE — new cross-repository survivor-world migration.**

The completed DynamicTrading UnifiedTraderWorldRuntime remains accepted commercial foundation. This job addresses the broader world-simulation parity and ModData footprint gap found during native testing.

## Accepted foundation

Preserve:

- Core stable actor identity/world/journey/provider lease/runtime store/map host/projection;
- Core deterministic identity/appearance generation;
- Core ActorInventory compact codec modes;
- Hoomans physical body/AI/combat/needs/facilities behavior;
- current Hoomans faction/community/mobile-group/population behavior as parity source;
- Hoomans WorldDiscovery and individual actor map UX as parity source;
- DTCommon trader/economy authority;
- DynamicTrading provider-neutral trader work from 23e3bad3.

## Verified gaps

1. Core ActorRegistry:Create stores personalInventory as FULL by default.
2. generated appearance is deterministic but resolved appearance is persisted.
3. reusable faction/community/population/group/discovery logic remains under PNC.
4. DTAbstract lacks Hoomans WorldDiscovery/debug tooling.
5. DTAbstract uses a separate trader marker model rather than per-NPC travel presentation.
6. DTCommon settlement directory still has static Kentucky defaults used by abstract mode.
7. group-shared travel is not yet a Core survivor-world contract.
8. naive promotion of full Hoomans records would unnecessarily bloat ModData.

## Current phase

**S0 — Baseline, ownership matrix, and footprint budget.**

## Immediate Next Chunk

### S0A — serialized footprint and field ownership audit

Before production migration:

1. build a read-only footprint harness for Core actor registry and PNC world persistence;
2. measure bytes for 10/100/500/1000 untouched actors;
3. measure SEED_ONLY vs BASELINE_DELTA vs FULL;
4. measure generated/authored appearance sections;
5. measure 1/5/10/25-member group traversal duplication;
6. classify PNC faction/community/population/group/discovery fields by final owner/persistence class;
7. enumerate DT static world/map/discovery duplicates;
8. record explicit byte budgets in PROGRESS and HARNESS_ACCEPTANCE before S1.

Then continue automatically through S1–S10.

## Repository safety

PsychopatzCore: existing main only; currently ahead of origin/main.

ProjectHoomans: existing main only; preserve unrelated semantic/harness work.

DynamicTrading: existing main only; preserve the two unrelated unstaged mod.info edits.

No blind pull/reset/rebase/stash.

## Blockers

None identified.

## Completion reminder

A compact actor alone is insufficient.

Final parity also requires the same factions, communities, groups, traversal, discovery entities, per-actor map dots, selection/highlight and debug tools in both representation modes.
