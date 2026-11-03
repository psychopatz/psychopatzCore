# S0 Field Ownership and Persistence Matrix

Snapshot: 2026-11-03.

This matrix is source-backed by the current Core actor schema, PNC record serializer, PNC abstract-world types/store, faction/community/discovery stores, and DynamicTrading settlement/map code.

| Domain / field family | Current owner | Final owner | Persistence class | Migration direction |
| --- | --- | --- | --- | --- |
| actorID / revision / schema | Core | Core | canonical durable | keep; compact codec |
| identitySeed / generatorVersion | Core | Core | canonical durable | keep |
| generated display name / generated survivor identity | Core | Core | deterministic base unless overridden | reconstruct from seed/version; persist durable authored override only |
| generated appearance resolved table | Core | Core | runtime cache / deterministic base | stop serializing by default |
| authored appearance policy | Core/Hoomans | Core | canonical durable | persist exact authored policy/delta |
| portrait summary/cache | Hoomans/runtime | Core presentation | runtime cache | derive from compact appearance |
| personal inventory baseline | Core | Core | deterministic base | SEED_ONLY |
| personal inventory durable changes | Core/Hoomans physical sync | Core | canonical durable delta | BASELINE_DELTA when representable |
| exact unsupported/imported inventory | Core | Core | canonical durable | FULL only when required |
| merchant stock/budget | DTCommon | DTCommon | DT domain durable | never merge into actor inventory |
| default social state | Core | Core | deterministic/default | omit from compact encoding when default |
| non-default relationships/memories | Core | Core | bounded durable delta | persist sparse/bounded |
| default persona | Core | Core | deterministic/default | omit when reconstructable |
| knowledge facts | Core | Core | bounded durable delta | persist only non-default bounded facts |
| actor world stationary default | Core | Core | compact world | omit default fields; persist meaningful location/override |
| actor individual journey | Core | Core | compact world exception | persist only when actor travels independently |
| provider lease | Core | Core | canonical durable | persist compact lease state |
| body reference / body lease runtime objects | Hoomans | Hoomans provider runtime | runtime only | never canonical ModData |
| AI blackboard / behavior runtime | Hoomans | Hoomans provider runtime | runtime only | discard on dematerialize |
| path/perception/animation/combat target | Hoomans | Hoomans provider runtime | runtime only | discard |
| transient needs micro-state | Hoomans | Hoomans provider runtime | runtime only unless explicitly promoted | do not migrate wholesale |
| faction ID / seed / archetype / name contract | PNC Factions | Core Survivor World | canonical durable/shared | migrate registry |
| faction gameplay policy/tactical consequences | PNC | Hoomans adopter policy | adopter extension | keep out of generic Core schema |
| community ID / site / faction / generic population | PNC Communities | Core Survivor World | compact world/shared | migrate |
| Hoomans facilities/jobs/community gameplay | PNC | Hoomans | adopter durable/runtime | keep adopter-owned |
| mobile group ID / member IDs / leader / mission | PNC AbstractWorld/Factions | Core Survivor World | compact world/shared | migrate |
| group location/destination/journey | PNC AbstractWorld/mobile group | Core Survivor World | compact world/shared | one copy per group |
| per-member copy of same travel | PNC NPC record travel when present | none | redundant | remove after group migration |
| population sectors/generation provenance | PNC PopulationDirector | Core Survivor World mechanism | compact world/shared | migrate generic mechanism |
| Hoomans body/equipment composition policy | PNC | Hoomans | provider policy | retain |
| WorldDiscovery entity IDs/phases/signals | PNC | Core Survivor World | compact world/player-scoped | migrate |
| Hoomans WorldDiscovery debug buttons | PNC client | Core generic debug | runtime UI | migrate generic actions |
| per-NPC travel map presentation | PNC TravelDirectory/map layer | Core presentation | client projection/runtime | migrate generic model |
| physical-only map/body details | PNC | Hoomans | adopter presentation | retain |
| DT static Kentucky settlement defaults | DTCommon | migration/bootstrap only | obsolete active authority | remove after Core communities are authoritative |
| DTAbstract trader-only map markers | DTAbstract | Core shared actor map | obsolete duplicate | remove after shared map migration |
| DT trader commercial lifecycle | DTCommon | DTCommon | DT domain | preserve accepted UnifiedTraderWorldRuntime |

## S0 measured baseline

From `tools/survivor_world_runtime/footprint_baseline.lua` using the production Core JSON encoder:

- current FULL-inventory actors at 1000 actors: **3041.12 bytes/actor**;
- same runtime actor schema with SEED_ONLY inventory: **2664.12 bytes/actor**;
- one durable inventory delta using the current BASELINE_DELTA shape: **3211.12 bytes/actor**;
- generated appearance section: approximately **456 bytes/actor**;
- current SEED_ONLY inventory section: approximately **739 bytes/actor**;
- identity section: approximately **423 bytes/actor**;
- provider lease: approximately **271 bytes/actor**;
- world state: approximately **238 bytes/actor**.

PNC normalized abstract group storage grows modestly with members because member IDs are shared under one group: 811 bytes for 1 member and 1195 bytes for 25 members in the benchmark fixture.

A representative route duplicated onto every actor grows to 11,337 bytes for 25 members versus 869 bytes for one shared group route envelope: **10,468 avoidable bytes** in that fixture.

## S0 migration hazard

A legacy/current FULL ActorInventory payload cannot be blindly decoded and re-emitted as SEED_ONLY. The baseline harness reproduced `equipment_reference_invalid` because FULL payload reconstruction does not by itself prove deterministic baseline provenance.

S1 must implement an explicit safe compaction/migration path. It may compact only when reconstructed baseline + payload comparison proves semantic equivalence; otherwise it retains BASELINE_DELTA/FULL rather than losing state.
