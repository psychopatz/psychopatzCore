# Progress — Compact Survivor World Runtime

## Parent status

**DEVELOPER COMPLETE — S0–S11 accepted; native SP/MP acceptance remains user-owned.**

One compact PsychopatzCore SurvivorWorld now owns generic survivor-world identity, persistence, traversal, projection and discovery. ProjectHoomans retains physical/gameplay extension state; DynamicTrading retains commercial state. S11 additionally removes migration-era fallback authority and misleading adopter storage/identity names while preserving one-way old-save import. Final developer validation is green against the established unrelated baselines. Release acceptance still requires the native N1–N6 matrix in `S10_CROSS_REPOSITORY_ACCEPTANCE.md`.

## Accepted foundation

Preserve:

- Core stable actor identity/world/journey/provider lease/runtime store/map host/projection;
- Core deterministic identity/appearance generation;
- Core ActorInventory SEED_ONLY / BASELINE_DELTA / FULL codecs;
- Core canonical faction/community/group/traversal/discovery/presentation authority;
- Hoomans physical body/AI/combat/needs/facilities and adopter-extension behavior;
- Hoomans individual separated/live-provider travel as the bounded actor-specific exception;
- DTCommon trader/economy/commercial lifecycle authority;
- DTAbstract/DTHoomans representation adapters without parallel generic world authority.

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

## S6B/S6C accepted evidence

ProjectHoomans generic world authority is now cut over to Core.

- faction/community/location/group generic fields persist only in Core SurvivorWorld;
- PNC registries are rebuilt runtime compatibility views;
- Hoomans-only policy/runtime fields persist in one bounded extension root;
- legacy generic roots are captured once, then retired;
- reload reconstructs PNC views from Core + extension state without resurrecting old roots;
- generic mutation hooks update Core, including audited scavenging and casualty bypasses;
- production persistence performs one SurvivorWorld save rather than three generic PNC writes;
- the temporary S6 Save redirect failed closed when Core authority was composed but cutover was unavailable; S11 later removed that facade in favor of explicit view `Commit` boundaries with no detached fallback.

Validation:

- Core S6B compatibility regressions pass;
- Core full suite remains **137/144**, same seven unrelated failures;
- Hoomans focused cutover/reload/mutation/save tests pass;
- Hoomans full suite remains **991/996**, same five unrelated semantic/harness failures;
- S6B production Lua: **11/11** luac + installed-PZ Kahlua;
- S6C production Lua: **4/4** luac + installed-PZ Kahlua;
- git diff checks pass.

Detailed evidence: `S6_HOOMANS_ADOPTION.md`.

Commits:

- Core `4933793`;
- ProjectHoomans `5d6e1e8e`, `ab19fe69`, `3f523dc8`.

## S7 accepted evidence

DTAbstract now adopts Core SurvivorWorld as its only survivor-world authority.

- standalone composition bootstraps Core with no ProjectHoomans dependency;
- DTCommon settlement identity comes from Core communities;
- commercial trader records bind existing canonical trader-group leaders;
- binding creates no extra actor or group;
- abstract movement uses Core GroupJourney, not actor-owned duplicate travel;
- DTHoomans handoff preserves the same actor/group and rebases group movement from the physical body's final position;
- the former DTHoomans settlement-directory authority is removed;
- recognized pre-S7 standalone abstract traders rebind once to canonical actors/groups while preserving merchant stock/budget;
- static Kentucky settlements are no longer auto-registered;
- untouched abstract actors require no body/AI/FULL inventory.

Validation:

- DynamicTrading full suite: **62/62**;
- changed DynamicTrading production Lua: **11/11** luac + installed-PZ Kahlua;
- Core SurvivorWorld-focused tests pass;
- Core full suite: **138/145**, same seven unrelated baseline failures;
- Core bootstrap Lua passes luac + installed-PZ Kahlua;
- duplicate-authority source audit passes.

Detailed evidence: `S7_DTABSTRACT_ADOPTION.md`.

Commits:

- PsychopatzCore `5045522`;
- DynamicTrading `bbd14454`.

## S8 accepted evidence

Core provider-neutral presentation/discovery authority is now shared by ProjectHoomans and DTAbstract.

Accepted behavior:

- canonical per-actor dots and actor/group/community/faction IDs;
- one Core group-route/progress/ETA source;
- deterministic Core overlap spreading;
- provider-neutral portrait payload -> client descriptor conversion;
- shared selection/highlight/tracking state;
- server-authoritative community/group/signal discovery;
- discover-all/reset debug actions, including per-entity reset;
- Hoomans physical bodies override only canonical actor position through a Core provider hook;
- Hoomans generic discovery snapshots/debug actions use Core while Hoomans radio/contact policy stays adopter-owned;
- Hoomans compatibility saves preserve Core-only signal discovery;
- DTAbstract no longer owns transient trader discovery truth;
- DTAbstract map/nearby/debug surfaces read Core actor/discovery state;
- portrait UI is lazy-loaded and refresh is demand-throttled rather than a new background world tick.

Validation:

- Core focused S8 tests pass;
- Core full suite: **141/148**;
- detached clean HEAD `cae306c`: **141/148** with the exact same seven unrelated failures;
- Hoomans focused S8 cutover/map/MP-loader tests pass;
- Hoomans full suite: **995/1000**, same five unrelated semantic/harness failures;
- DynamicTrading full suite: **62/62**;
- changed production Lua: Core **4/4**, Hoomans **10/10**, DTAbstract **3/3** luac;
- installed-PZ Kahlua: Core **4/4**, Hoomans **10/10**, DTAbstract **3/3**;
- S8 slices pass `git diff --check`;
- DynamicTrading's two unrelated `mod.info` edits remain outside the S8 commit.

Detailed evidence: `S8_SHARED_PRESENTATION_DISCOVERY.md`.

Commits:

- existing Core S8A foundation `cae306c`;
- PsychopatzCore `baaf075`;
- ProjectHoomans `5c9988e8`;
- DynamicTrading `dc13226b`.

## S9 accepted evidence

DynamicTrading no longer carries a second generic survivor-world authority.

Removed or retired from active runtime:

- the `DynamicTrading` actor projection source and `DTCommon_TraderProjectionServer.lua`;
- actor/world projection APIs from `DTCommon_TraderPresentation.lua`;
- the self-only DT map projection helper;
- built-in Kentucky settlement geography and `EnsureDefaults`;
- the projection-only trader-world change-listener bus;
- live `coreActorID/coreProvider*` aliases and old `BindCore*/SetCore*` service names.

Accepted ownership:

- Core SurvivorWorld owns actor/faction/community/group geography, group routes and generic presentation/discovery;
- DTCommon owns commercial actor binding, stock/budget, destination intent, visits/exchange/restock/cooldown and compact commercial lifecycle metadata;
- DTAbstract/DTHoomans own representation execution;
- provider `getPosition` exists only for bounded representation switching/handoff;
- retired pre-SurvivorWorld actor IDs are isolated in one-way `DTAbstract_PreSurvivorWorldImport.lua`;
- old DT save aliases are decoded by `DTCommon_PreSurvivorWorldImport.lua` and immediately canonicalized before active policy logic.

Validation:

- DynamicTrading full suite: **62/62**;
- changed S9 production Lua: **16/16** luac;
- installed-PZ Kahlua: **16/16**;
- DynamicTrading `git diff --check`: pass;
- Core focused SurvivorWorld presentation/transport/discovery/group-journey regressions: pass;
- Hoomans focused Core travel-directory/live-body/discovery/map regressions: pass;
- source audit: no DT actor projection feed, no built-in settlement geography, no permanent dual world authority;
- the two unrelated DynamicTrading `mod.info` edits remain outside the commit.

DynamicTrading commit: `86b712a5`.

Detailed evidence: `S9_DYNAMIC_TRADING_CLEANUP.md`.

## S10 accepted evidence

Developer acceptance is complete.

- Core full sweep: **141/148**, same seven unrelated baseline failures;
- Hoomans full suite: **995/1000**, same five unrelated semantic/harness failures;
- DynamicTrading full suite: **62/62**;
- Hoomans bridge harness: **78/78**;
- Hoomans MP developer matrix: **20/20**;
- actor footprint at 1000: **1,272.27 bytes/actor**, 1000 SEED_ONLY, 0 FULL;
- 25-member group: **1,494 bytes total**, one **687-byte** shared journey;
- Core-only, save/reload, hotplug, provider handoff, load-order and cross-adopter matrices pass;
- final source audit finds one Core generic-world authority and no permanent dual-write/read path;
- current authority surfaces pass luac/Kahlua: Core **15/15**, Hoomans **24/24**, DT **16/16**;
- all repositories pass `git diff --check`.

Detailed evidence and native N1–N6 handoff: `S10_CROSS_REPOSITORY_ACCEPTANCE.md`.

## S11 accepted evidence

Post-migration consolidation is complete.

- Core group planning now supports bounded caller-supplied existing actor IDs; duplicate/invalid supplied IDs fail closed.
- ProjectHoomans retired generic ModData keys are isolated in one frozen pre-SurvivorWorld import reader.
- `PNC_AbstractWorldStore` is removed; `PNC_HoomansWorldView` is explicitly a Core + Hoomans-extension runtime view and has no public Save authority.
- faction/community persistence modules are now world-view modules; public write boundaries are `Commit`, with no detached old-root fallback.
- `PNC_GroupGenerationPlan.lua` and `PNC_SettlementGenerationPlan.lua` are removed; automatic population generation consumes Core plans and passes planned faction/community/group/actor IDs into Hoomans materialization.
- `PNC_PopulationIdentity.lua` is replaced by Hoomans-only `PNC_PopulationHoomansPolicy.lua`.
- DynamicTrading old schema aliases live only in `DTCommon_PreSurvivorWorldImport.lua`; pre-SurvivorWorld standalone actor rebinding lives only in `DTAbstract_PreSurvivorWorldImport.lua`.
- DTHoomans caravan naming now uses Core generation profiles while Hoomans-specific tags use `PNC.PopulationHoomansPolicy`.
- Core full sweep: **141/148**, same seven unrelated failures.
- Hoomans full suite: **995/1000**, same five unrelated semantic/harness failures.
- DynamicTrading full suite: **62/62**; bridge harness **78/78**.
- changed production Lua parses: Core **1/1**, Hoomans **103/103**, DynamicTrading **6/6**.
- all repositories pass `git diff --check`.
- native feedback triggered a real Kahlua re-audit: `pz_verify.py --kahlua` passes **121/121** surviving S11 production/native-fixture files after removing one Core `next()` use, eight native-fixture `next()` uses, and one DT `os.time()` fallback.

Detailed evidence: `S11_POST_MIGRATION_CONSOLIDATION.md`.

## Native remediation — fresh-save trader creation and actor-map ownership

Native DTAbstract acceptance exposed that developer-side S8 coverage had not actually
made Core the renderer of canonical per-actor map dots, and that DynamicTrading's
debug spawn UX was still split between adopters. The user explicitly chose a fresh
save rather than migration of the old `actor:dtabstract:*` save records, so no
additional old-save repair path was added.

Remediation now preserves one authority per concern:

- PsychopatzCore owns the provider-neutral SurvivorWorld actor-dot renderer,
  hover, selection, tracking and selected/tracked route presentation;
- Core server composition now gates on `RuntimeRole.AllowsServerCode()` rather
  than dedicated-server identity, so single-player correctly registers the
  SurvivorWorld projection/discovery server handlers;
- ProjectHoomans only decorates Core actor dots with its visibility,
  tactical color and identity policy, while retaining its renderer only for
  genuinely Hoomans-only/non-Core entries;
- DTAbstract only decorates canonical trader actors with commercial labels and
  renders community/group/signal discovery; it has no second actor hit/hover/
  tracking renderer;
- DTAbstract debug Talk reports the final Core conversation-open result back to
  its manager, so server authorization is no longer misreported as successful
  UI opening;
- DTCommon owns the single DynamicTrading debug-spawn client/server contract and
  provider selection; the former DTHoomans-only spawn menu and DTAbstract-only
  spawn commands are removed;
- DTAbstract debug spawn first repositions/binds an unused canonical Core
  trader-group actor; when no unused canonical trader group remains, DTCommon
  asks Core to generate one bounded canonical caravan group at the requested
  position, then binds only the commercial trader role; DTAbstract still
  creates no body and owns no actor/group identity;
- DTHoomans consumes the same DTCommon debug command and materializes through
  its physical provider;
- the forced startup trader-world tick fills the bounded two-trader target on a
  fresh save immediately, publishes the Core actor projection, then returns to
  the normal one-spawn-per-cadence replacement policy.

Developer validation after remediation:

- Core full sweep: **144/151**, with the same seven unrelated baseline failures;
- ProjectHoomans full suite: **996/1001**, with the same five unrelated
  semantic/harness failures;
- DynamicTrading full suite: **68/68**;
- DTHoomans bridge harness: **78/78**;
- focused Core actor-map, shared DTCommon debug spawn, DTAbstract map/debug/Talk
  binding and startup-population regressions pass;
- changed production Lua: **18/18** installed-PZ Kahlua;
- all three repositories pass `git diff --check`;
- source audit finds no surviving provider-specific DT debug-spawn path and no
  adopter-owned canonical actor-map event/context.

A fresh-save native retest remains required. In DTAbstract, the expected native
result is two canonical trader bindings available immediately, real Core actor
coordinates/portraits for Talk, Core-owned NPC dots on the map, and zero visible
NPC bodies.

### Native follow-up — non-blocking DTAbstract debug spawn

The first fresh-save retest exposed a main-thread stall when invoking the shared
Spawn Trader debug action in single-player. The command previously performed
provider selection, canonical group generation/binding, persistence, projection
broadcast, and a client projection refresh synchronously inside the click's
client-command callback.

The follow-up keeps the same ownership boundaries but changes execution:

- DTCommon validates and queues the debug request immediately; provider selection
  and spawn execution run one request at a time from the server tick;
- the client receives an immediate queued acknowledgement, then a separate final
  success/failure notification;
- shared trader creation only marks the Core actor projection dirty; the
  trader-world runtime coalesces and publishes it on the next tick instead of
  broadcasting inside SpawnTrader;
- DTAbstract no longer sends a nested projection request from the spawn-result
  callback;
- DTCommon debug and DTAbstract nearby-discovery clients explicitly load the Core
  notification UI so abstract nearby/spawn feedback is visible;
- spawn logging now exposes debug_spawn_queued, debug_spawn_processing, and
  debug_spawn_completed phases for native diagnosis.

Validation for this follow-up: DynamicTrading **68/68**, focused queued-spawn /
projection-coalescing / nearby-discovery regressions pass, changed production Lua
**6/6** installed-PZ Kahlua, and git diff --check is clean.

A second native fresh-save retest is required. Spawn Trader should return control
immediately, show a queued notification, then show the final DTAbstract result;
the canonical abstract actor dot should appear from the coalesced Core projection
without any visible world NPC body.

### Native follow-up — bounded MarketSense-backed stock seeding

A second native retest still showed severe lag during trader creation. Audit isolated the remaining hotspot to DTCommon trader inventory seeding rather than SurvivorWorld actor generation: each Stock.New() previously iterated the full MarketSense known-item registry and performed availability plus price evaluation for every obtainable item. With the observed 4,412-item MarketSense catalog, one trader spawn could issue thousands of MarketSense calls.

DTCommon MarketCatalog now caches a bounded stock-seed universe during its existing one-time catalog build. TraderStock.New() samples at most 32 cached candidates and prices only until the bounded 8-slot stock is filled. Subsequent traders reuse the same catalog cache and do not rescan MarketSense. A dedicated 4,412-item regression verifies one catalog build, zero catalog rescans for the second trader, and at most eight price evaluations per seeded trader. DynamicTrading full suite is 69/69 and changed production Lua is 2/2 Kahlua.

## Current phase

**DEVELOPER COMPLETE — native SP/MP acceptance pending.**

## Immediate Next Chunk

The current native defect remediation is developer-complete. No additional
old-save migration work is required for this acceptance cycle.

The next action is a user-owned **fresh-save** Project Zomboid acceptance pass:
verify immediate trader generation, DTCommon shared debug spawn, Core-owned NPC
map dots, DTAbstract Talk/portrait opening, and absence of visible NPC bodies.
The broader N1–N6 matrix in `S10_CROSS_REPOSITORY_ACCEPTANCE.md` remains the
release gate.

## Repository safety

PsychopatzCore: existing main only.

ProjectHoomans: existing main only; preserve unrelated semantic/harness work.

DynamicTrading: existing main only; preserve unrelated user work.

No blind pull/reset/rebase/stash.

## Blockers

None identified.

## Completion reminder

Compact persistence is only the first mandatory phase. Final completion still requires shared factions, communities, groups, traversal, discovery, per-actor map dots, selection/highlight/debug parity, both adopter migrations, cleanup and cross-repository validation.
