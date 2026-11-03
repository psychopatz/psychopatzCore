# Progress — Compact Survivor World Runtime

## Parent status

**ACTIVE — S0/S1/S2 accepted; S3 lazy inventory hydration is active.**

The completed DynamicTrading UnifiedTraderWorldRuntime remains accepted commercial foundation. This job owns the broader compact survivor-world parity migration.

## Accepted foundation

Preserve:

- Core stable actor identity/world/journey/provider lease/runtime store/map host/projection;
- Core deterministic identity/appearance generation;
- Core ActorInventory SEED_ONLY / BASELINE_DELTA / FULL codecs;
- Hoomans physical body/AI/combat/needs/facilities behavior;
- current Hoomans faction/community/mobile-group/population behavior as parity source;
- Hoomans WorldDiscovery and individual actor map UX as parity source;
- DTCommon trader/economy authority;
- DynamicTrading provider-neutral trader work from 23e3bad3.

## S0 accepted evidence

Baseline harness:

`tools/survivor_world_runtime/footprint_baseline.lua`

Generated evidence:

- `S0_BASELINE.json`
- `S0_BASELINE.md`
- `S0_FIELD_OWNERSHIP.md`

Measured current Core actor footprint:

- FULL inventory at 1000 actors: **3041.12 bytes/actor**;
- same actor schema with SEED_ONLY inventory: **2664.12 bytes/actor**;
- generated appearance: about **456 bytes/actor**;
- SEED_ONLY inventory section: about **739 bytes/actor**;
- identity: about **423 bytes/actor**;
- provider lease: about **271 bytes/actor**;
- world: about **238 bytes/actor**.

Shared-route evidence:

- representative 25-member shared route envelope: **869 bytes**;
- same route duplicated per actor: **11,337 bytes**;
- avoidable duplicate storage: **10,468 bytes**.

S0 also reproduced a migration hazard: decoding a legacy FULL inventory and simply re-emitting SEED_ONLY can fail `equipment_reference_invalid`. S1 must compact legacy payloads only after deterministic baseline equivalence is proven.

## Evidence-backed budgets

### B1 — untouched compact actor

At 1000 untouched generated actors, average serialized Core registry growth must be:

**<= 1,900 bytes/actor**

before S1/S2 are accepted together.

S1 alone may land above this while appearance remains uncompressed, but must materially improve the 2664-byte SEED_ONLY counterfactual.

### B2 — inventory

- untouched generated actor: never FULL;
- new untouched actor: SEED_ONLY;
- durable mutations: BASELINE_DELTA when safely representable;
- FULL only when exact state cannot safely compact;
- migration may retain FULL rather than lose data.

### B3 — generated appearance

After S2, generated appearance canonical serialized contribution target:

**<= 180 bytes/actor**

for the generated-default contract.

Authored/custom appearance is exempt from this per-actor target when exact preservation requires more bytes.

### B4 — group traversal

One shared journey per group. Route/journey serialized bytes must grow approximately O(1) with member count; only the member ID list may grow O(N).

### B5 — provider runtime

Body/AI/path/perception/animation/combat/runtime tables contribute **0 canonical serialized bytes**.

## S1 accepted evidence

Implemented:

- ActorRegistry:Create defaults personal inventory to SEED_ONLY;
- default seed inventory no longer persists repeated starter definitions;
- compact actor registry schema v2 omits default social/persona/knowledge/provider/owner/extension scaffolding;
- rich runtime actor shape is reconstructed on load;
- schema-v1 registries remain readable;
- unchanged legacy FULL inventory is compacted only after exact baseline equivalence proof;
- changed/unsupported FULL inventory is retained;
- actor registry has explicit bounds: 4096 actors / 16 MiB;
- registry decode uses a dedicated bounded JSON envelope rather than weakening the generic JSON codec.

Measured S1 footprint:

- 10 actors: **1656.50 bytes/actor**;
- 100 actors: **1652.40 bytes/actor**;
- 500 actors: **1655.42 bytes/actor**;
- 1000 actors: **1655.79 bytes/actor**;
- 1000/1000 untouched actors SEED_ONLY;
- 0 FULL untouched actors.

Large-registry regression:

- 700 actors;
- 1,146,215-byte serialized registry;
- save/reload passes above the generic 1 MiB JSON limit through the actor-registry-specific bound.

Focused actor/provider/projection/runtime regression matrix passes.

## S2 accepted evidence

Implemented:

- generated appearance algorithm is explicitly versioned (v1);
- generated-default appearance compacts only after exact regeneration equality proof;
- compact generated appearance payload is **59 bytes**;
- authored appearance is retained as exact full state;
- a durable modification to a generated appearance falls back to full state rather than being regenerated away;
- unsupported generator versions fail explicitly;
- S1 compact actor schema v1 remains readable;
- runtime actors still expose full resolved appearance to portraits/providers.

Measured post-S2 footprint:

- 10 actors: **1276.70 bytes/actor**;
- 100 actors: **1270.92 bytes/actor**;
- 500 actors: **1272.11 bytes/actor**;
- 1000 actors: **1272.27 bytes/actor**;
- 1000/1000 untouched actors SEED_ONLY;
- 0 FULL untouched actors.

This beats the locked <=1900 bytes/actor target by a wide margin and reduces untouched actor storage by about 58% from the original ~3041 bytes/actor baseline.

Portrait/presentation/provider/projection regressions pass. A 900-actor **1,132,286-byte** registry still round-trips through the explicit actor-registry bound.

## Current phase

**S3 — Lazy inventory hydration and durable delta capture.**

## Immediate Next Chunk

### S3A — production Hoomans hydration/dehydration boundary

1. audit the existing Core actor inventory ↔ PNC/Hoomans provider bridge;
2. make compact Core payloads hydrate lazily only when physical gameplay requires an inventory;
3. preserve exact item/equipment identity through materialization;
4. on dematerialization, capture durable changes and choose the smallest safe Core mode;
5. unchanged physical round-trip must return to SEED_ONLY;
6. representable durable changes should return BASELINE_DELTA;
7. unsupported exact state must remain FULL rather than lose data;
8. add cross-repository provider regressions and footprint checks;
9. then continue automatically into S4 Core Survivor World model.

## Repository safety

PsychopatzCore: existing main only.

ProjectHoomans: existing main only; preserve unrelated semantic/harness work.

DynamicTrading: existing main only; preserve the two unrelated unstaged mod.info edits.

No blind pull/reset/rebase/stash.

## Blockers

None identified.

## Completion reminder

Compact persistence is only the first mandatory phase. Final completion still requires shared factions, communities, groups, traversal, discovery, per-actor map dots, selection/highlight/debug parity, both adopter migrations, cleanup and cross-repository validation.
