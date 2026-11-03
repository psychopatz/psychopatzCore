# Progress — Compact Survivor World Runtime

## Parent status

**ACTIVE — S0–S3 accepted; S4 Core Survivor World model is active.**

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

## S3 accepted evidence

Core inventory hardening:

- SEED_ONLY now requires exact current item/equipment equality with deterministic baseline;
- decoded BASELINE_DELTA payloads retain baseline and delta state across later mutations;
- decoded ledgers recalculate item ordinals to avoid post-hydration ID collisions;
- SetEquipmentState and explicit root-container clearing support lossless capture;
- CreateBaselineFromPayload rebuilds a fresh bounded baseline for repeated physical captures;
- ToSmallestPayload chooses SEED_ONLY when exact, otherwise BASELINE_DELTA, then FULL.

ProjectHoomans integration:

- new PNC ActorInventory bridge hydrates Core compact personal inventory into Hoomans logical inventory only at the physical-provider boundary;
- runtime-only hydration provenance prevents Hoomans-derived profile metadata from creating false durable deltas;
- unchanged hydrate/capture returns SEED_ONLY;
- durable Hoomans item changes return BASELINE_DELTA with exact item IDs;
- repeated capture does not accumulate historical delta bloat;
- CoreProvider materialization hydrates logical inventory before body creation;
- body-backed loose inventory is projected/captured when a real body inventory exists;
- dematerialization returns the compact captured payload;
- missing registered records fall back to safe rehydration rather than inventing unrelated inventory.

DynamicTrading integration:

- normal DTHoomans dematerialization commits returned personalInventory with providerLease;
- missing-body recovery captures the surviving logical Hoomans inventory and commits it before returning abstract;
- provider hot-swap and runtime tests use the public ActorInventory API rather than FULL-payload internals.

Validation:

- Core inventory/actor/provider/runtime focused matrix passes;
- Hoomans bridge, seed/delta, Core provider, end-to-end and equipment regressions pass;
- DynamicTrading full suite: **59/59**;
- changed S3 production Lua passes installed-PZ Kahlua verification;
- git diff checks pass.

## S4A accepted evidence

Core now has one standalone, bounded SurvivorWorld schema and persistence envelope for factions, communities, abstract locations, mobile groups, population metadata and player-scoped discovery.

The read-only PNC importer:

- accepts plain serialization-safe tables;
- preserves legacy entity IDs;
- maps generic faction/community/location/group/population/discovery state;
- excludes Hoomans body/AI/facility/job/combat/behavior policy;
- rejects over-capacity source data;
- does not require PNC or DynamicTrading.

Bounds:

- 256 factions;
- 512 communities;
- 4096 abstract locations;
- 1024 groups;
- 4096 sectors;
- 256 discovery players;
- 128 group members;
- 4096 discovery entries/player;
- 32 MiB world envelope.

Validation:

- four SurvivorWorld focused tests pass;
- full Core Lua sweep remains **134/141**, with exactly the same seven unrelated failures verified on clean HEAD;
- changed production Lua passes luac;
- installed-PZ Kahlua compiler: **14/14**;
- git diff check passes.

Detailed evidence: `S4_SCHEMA_EXTRACTION.md`.

## S4B accepted evidence

Core now owns deterministic provider-neutral generation contracts for world/sector seeds, generation IDs, weighted choices, entity IDs, default faction/community names, community/group planning and bounded adopter policy extensions.

The generic seed/name behavior is locked to the current PNC serialization-safe algorithms. Canonical plans are byte-identical for the same seed/request before and after registering an adopter policy. Body/equipment/facility/job/combat/behavior policy is not part of the canonical plan.

Validation:

- S4B generation smoke passes;
- exact PNC-compatible seed/name fixtures pass;
- adopter policy isolation/capacity passes;
- full Core Lua sweep remains **135/142**, with only the same seven unrelated baseline failures;
- installed-PZ Kahlua compiler: **6/6** changed S4B files;
- git diff check passes.

Detailed evidence: `S4_GENERATION_CONTRACTS.md`.

## S5A accepted evidence

Core SurvivorWorld mobile groups now own one bounded shared GroupJourney. Normal members project from that journey; an intentionally separated actor may use its existing ActorWorld journey as a per-actor override.

Measured serialized group footprint with the same shared route:

- 1 member: **1,110 bytes**;
- 5 members: **1,174 bytes**;
- 10 members: **1,254 bytes**;
- 25 members: **1,494 bytes**;
- shared journey: **687 bytes** at every member count.

Only **384 bytes** are added from 1 to 25 members, proving route/journey storage is O(1) while member IDs are O(N).

Validation:

- six SurvivorWorld focused tests pass;
- save/reload, route waits, rebase, arrival, planned-departure timing and actor-override projection pass;
- full Core Lua sweep: **136/143**, with the same seven unrelated clean-HEAD failures;
- changed production Lua: **8/8** luac;
- installed-PZ Kahlua compiler: **8/8**;
- git diff check passes.

Detailed evidence: `S5_GROUP_SHARED_TRAVERSAL.md`.

## S5B accepted evidence

ProjectHoomans now adopts Core GroupJourney for abstract mobile-group travel.

- legacy PNC TRAVELING groups migrate lazily to Core GroupJourney;
- AbstractTraversal advances and decides arrival from Core journey state, not stateEndsAt;
- stateEndsAt remains compatibility summary only;
- group journey survives PNC normalization/reload with stable journey identity/progress;
- director debug snapshots carry the Core journey;
- mobile-group map presentation consumes Core route/progress when present and keeps the old straight-line interpolation only for legacy snapshots;
- normal members project from the group journey while intentionally separated actors retain ActorWorld journey overrides;
- individual PNC TravelRepository remains actor-specific/live-provider travel only.

Validation:

- six S5B-focused Hoomans tests pass;
- Hoomans full suite: **986/991** at S5B, with only the same five unrelated semantic/harness failures;
- changed S5B production Lua: **5/5** luac and installed-PZ Kahlua;
- git diff check passes.

ProjectHoomans commit: `191ee26e`.

## S6A accepted evidence

Core now provides a lazy server-authority SurvivorWorld RuntimeStore at `PsychopatzCore.SurvivorWorld`.

- no GlobalModData root is allocated merely by loading Core;
- Hoomans explicitly activates the capability;
- Core persists one bounded serialized SurvivorWorld root;
- pre-OnInit mutations remain dirty and survive first save;
- clean saves do not rewrite unchanged data.

ProjectHoomans adds a one-way migration authority:

- builds a read-only snapshot of legacy faction/community/abstract/discovery stores;
- previews PNC → Core conversion without mutation;
- does not auto-import or continuously dual-write;
- explicit import persists only the Core SurvivorWorld root;
- accidental import over a non-empty Core world is rejected.

Validation:

- seven Core SurvivorWorld tests pass;
- Core full suite: **137/144**, with the same seven unrelated clean-HEAD failures;
- Hoomans full suite: **987/992**, with only the same five unrelated semantic/harness failures;
- S6A changed production Lua passes installed-PZ Kahlua;
- composition-order and MP server-file gates pass.

Commits:

- Core `d1e4a7b`;
- ProjectHoomans `d42e4e50`.

## Current phase

**S6 — ProjectHoomans adopter-world authority migration.**

## Immediate Next Chunk

### S6B — canonical generic world cutover

1. classify faction/community/location/group fields into Core-generic versus Hoomans extension state at the actual mutation/persistence boundaries;
2. cut generic faction/community/location/group persistence over to the Core RuntimeStore without permanent dual writes;
3. keep PNC registries only as compatibility/runtime extension views where Hoomans-specific policy requires them;
4. migrate supported legacy PNC saves once, then stop writing generic world fields to legacy ModData;
5. ensure all generic mutation paths update Core first and project the resulting canonical record back into Hoomans views;
6. preserve facilities/jobs/combat/behavior/encounter policy in Hoomans-owned extension state;
7. validate save/reload, generation, mobile travel, faction/community lifecycle and full Hoomans regression;
8. then continue S6C cleanup/removal of duplicate active authority and proceed to S7.

## Repository safety

PsychopatzCore: existing main only.

ProjectHoomans: existing main only; preserve unrelated semantic/harness work.

DynamicTrading: existing main only; preserve the two unrelated unstaged mod.info edits.

No blind pull/reset/rebase/stash.

## Blockers

None identified.

## Completion reminder

Compact persistence is only the first mandatory phase. Final completion still requires shared factions, communities, groups, traversal, discovery, per-actor map dots, selection/highlight/debug parity, both adopter migrations, cleanup and cross-repository validation.
