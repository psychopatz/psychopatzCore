# NPC foundation field ownership matrix

Status: P0A audit artifact, 2026-10-18; P0B contract evidence appended below.
This is a source-backed extraction matrix, not an implementation approval. The
checked-out source heads were PsychopatzCore `8b8e0b7`, Project Hoomans
`3f313b0b` (production source unchanged from `d117d861`), and Dynamic Trading
`2b1975a2`. Dynamic Trading's and PsychopatzCore's media trees were excluded
from the codebase graph coverage, and the Hoomans materialization source had a
coverage freshness warning, so the media findings below were verified by direct
source reads.

## Ownership rule

PsychopatzCore is the future canonical owner of stable NPC identity,
deterministic generation inputs, resolved appearance data, personal inventory,
personal relationships, generic locations/journeys, and generic presentation.
Project Hoomans remains the physical-body, director, job, faction, and live
simulation provider. DTCommon remains the merchant policy owner: stock, funds,
pricing, access, fulfillment, and restock. A DT merchant's carried personal
inventory is never the same record as its merchant stock.

No row below authorizes a production migration. Each target field needs a
versioned import adapter and a no-loss preflight before it can become a Core
write path.

## Field matrix

| Canonical domain / field | Current producer and serialized key | Current authority and normalized shape | Core target / conflict rule | P0A evidence |
| --- | --- | --- | --- | --- |
| Stable actor ID | Hoomans `PNC_Types.NewRecord`; `PNC_Persistence.SerializeRecord.id`. DT separately uses `traderID`. | Server record ID string; Hoomans currently owns NPC IDs. | Core actor ID. Preserve exact ID; reject empty/duplicate mappings. Never derive a new ID from a rerolled name or seed. | Generated record and payload ID round-trip in `tests/pnc_npc_foundation_parity_baseline_smoke.lua`. |
| Identity seed | `PNC_Identity_Factory.GenerateResolvedIdentity`; `PNC_Identity_Profile.ApplyRecordIdentity`; persisted as `identity.seed` and `identitySeed`. | Positive normalized integer, bounded by `Identity.SEED_MAX`; seed is the deterministic generation input. | Core `identity.seed`. Existing persisted seed wins; a missing seed requires a staged deterministic assignment ledger, never an implicit live reroll. | Factory-generated seed and rehydrated seed match. |
| Display name / name parts | Factory resolves SurvivorFactory forename, surname, and display name; persistence writes `identity.displayName` and `identity.survivor.forename/surname`. | Bounded strings; explicit authored name wins over factory fallback. | Core identity name profile. Preserve the serialized values exactly; do not regenerate a name when an authored value exists. | Name, forename, and surname are generated and checked through the persistence path. |
| Voice profile | Factory resolves `voice`, `voicePrefix`, `voiceType`, and `voicePitch`; current persistence sanitizer writes only `identity.survivor.voice`. | `voice` is a string; the additional factory fields are numeric/string values but are currently not all serialized. | Core full voice profile. Import must fail or retain source when `voicePrefix`, `voiceType`, or `voicePitch` cannot be represented. | Confirmed gap: baseline checks the persisted legacy voice only; the extra factory fields are not claimed as parity. |
| Resolved face / body appearance | Factory captures skin texture, skin/hair colors, hair model, and beard model; persistence writes the corresponding sanitized survivor fields. | Compact scalar/color tables; no engine objects. | Core resolved appearance record. Persist the resolved values used for portrait/body projection; source values win over defaults. | Skin texture, hair model, and colors are checked after rehydration. |
| Authored appearance policy | `PNC_Identity_Appearance` schema 2 normalizes outfit/slot/voice modes. `PNC_Identity_Profile.RollAppearance` consumes `record.appearance`, but `PNC_Types.NormalizeDefinition` and `PNC_Persistence.SerializeRecord` do not currently carry that field. | Policy has `random`, `none`, and `item` modes, exact slots, worn slot, and item state. | Core appearance policy plus resolved projection. Import must preserve the policy before any resolved appearance is recomputed. | Confirmed gap: explicit authored policy is not serialized by the current Hoomans record path. |
| Seeded clothing / worn visuals | Archetype look -> `PNC_Identity_Profile.RollAppearance` -> `PNC_Inventory_Templates` creates `tmpl:look:*` items with `wornSlot` and item state. | Deterministic from seed/archetype when no explicit policy exists; inventory item slots are the durable representation. | Core personal inventory and appearance projection. Inventory item identity/state is authoritative; body visuals are a lease. | `Base.Shirt` and its worn projection survive generated-record rehydration. |
| Inventory baseline inputs | `PNC_Inventory_Templates.buildIdentityTemplate`; `PNC_Inventory_EquipmentGeneration`; `inventory.template` stores archetype, seed, generator version, equipment pool, weapon mode, and template ref. | Current generator version is `PNC.Const.GENERATOR_VERSION = 4`; NPC inventory schema is 2 with `SEED_ONLY`, `BASELINE_DELTA`, and `FULL`. | Core actor inventory template/baseline. A baseline is valid only when its generator and template reference are known; otherwise promote to full or quarantine. | Actual template creation and seed/delta persistence execute in the new smoke test's harness. |
| Personal item identity and portable state | Hoomans CoreBridge maps compact items to PsychopatzCore virtual records; Core serializer uses virtual schema 1 / record schema 1; Hoomans delta schema is 1. | Server-authoritative dense item records; bounded portable state, quantities, metadata, and container relationships; no engine objects. | Core personal inventory. Preserve item IDs, type IDs, quantities, container, worn/equip slot, `legacyTemplateKey`, and representable portable state. Unrepresentable state requires a full fallback, not silent dropping. | P0A checks item IDs, stack, container, equipped slot, and bounded `modData`. P0B characterization confirms `customName` and `modData` round-trip, but `legacyTemplateKey` is lost by current CoreBridge metadata. |
| Portable item metadata map | `PNC_Inventory_CoreStateCodec.metadata/applyMetadata` currently carries metadata indexes 1–16: `id`, `stack`, `container`, `bagContainer`, `maxWeight`, `weightReduction`, `wearableSlot`, `templateKey`, `preferredContainer`, `wornSlot`, `attachedSlot`, `equipSlot`, `interactionLocked`, `interactionLockReason`, `identityNPCId`, and `identityNPCName`. Core item flags/state carry `condition`, `uses`, `favorite`, `customName`, bounded `modData`, custom weight, food/fluid/ammo/clothing state. | Those listed fields are representable in the checked-out Core virtual record; Hoomans `legacyTemplateKey` is a separate source field and is not in the metadata tuple. | Add `legacyTemplateKey` to a versioned metadata schema or retain the full source item envelope as opaque/full. A candidate with that field is not eligible for seed/delta-only restoration until the mapping exists. | Hoomans `cce488a6` follows the actual `CoreBridge → CoreStateCodec → Core ItemRecord` path and retains the exact legacy item in the planner while returning `portable_metadata_unrepresentable`. |
| Equipped / worn / attached equipment | Hoomans keeps `record.equipment` summary plus inventory `equipped`, `worn`, and `attached`; persistence writes equipment summary and inventory payload. | The item ledger is the durable source; summary is derived/projection data. | Core item ledger owns personal equipment. Rebuild summary from the ledger and reject conflicting dual-authority values. | Equipped primary and worn slots are checked after inventory hydration. |
| Directed relationships | `PNC_RelationshipTypes` and relationship service use `npc:<id>` and `player:<account>:<characterUUID>` keys; `record.social` persists schema 3. | Server-authoritative normalized scores, memories, bounded journals, personality and conduct projections. | Core relationship state. Preserve exact target keys and memory IDs; username-only aliases are not valid substitutes. | Directed approval, respect, and memory ID survive rehydration. |
| NPC position / spawn / anchor | `PNC_Persistence.SerializeRecord` writes `position`, `spawn`, and `anchor`; deserializer restores all three. | Server-authoritative numeric coordinates; anchor is distinct from current position. | Core location state. If a journey is active, journey authority must define the next position; do not merge two writers. | Current position and anchor are checked. |
| Journey / travel | Hoomans travel model stores a normalized `travel` record and persistence restores it; presence materialization consumes the result. | Hoomans currently owns live movement and body pathing; travel schema/version is Hoomans-owned. | Core abstract journey plus Hoomans projection adapter. Preserve journey ID/owner/ref and resolve position conflicts by one declared authority. | Not covered by the first baseline; requires the P0B migration fixture. |
| Merchant identity linkage | DTCommon registry stores compact fields including `n`, `r`, `c`, `p`, `g`, `l`, `m`, and `a`; `p` is the physical NPC binding. | DTCommon owns merchant-to-NPC linkage and merchant policy; Hoomans owns physical faction/body membership. | DTCommon remains the only merchant linkage writer. Link to Core actor ID; never copy merchant stock into personal inventory. | Audited in source; not exercised by the NPC-only baseline. |
| Merchant stock / budget / pricing | DTCommon stock and storage persist a Core virtual-inventory envelope; TraderService owns budget, quote, transfer, stock, and revision changes. MarketSense remains the intrinsic valuation source. | Server-authoritative stock/budget/quote revisions and transaction validation. Current access also has an abstract radio path. | DTCommon only. Preserve stock and carried inventory as separate ledgers; later access work must remove distant physical-transfer authorization by radio. | Audited in source; DT trade is deliberately outside P0A. |
| Map visibility / presentation | Hoomans `PNC_MapPresentation` and client map layers use knownness, `knownBy`, role tag, icon, and portrait revision. | Knowledge-gated presentation; map is not an identity or inventory authority. | Core generic presentation and event/marker contracts; Hoomans keeps colony/faction-specific layers. | Audited in source; no live map claim. |
| Physical body / body lease | Hoomans `PNC_Presence_Materialize` creates and leases an IsoZombie; persistence stores only compact body hints. | Hoomans owns body lifecycle, health, combat, needs, jobs, and materialization. Body instance/online ID is not actor identity. | Remains Hoomans projection of a Core actor. Stale leases must be quarantined/cleaned, never duplicated into Core. | Not exercised; the harness intentionally does not start Project Zomboid. |

## Version and input policy

The current checked-out sources explicitly support only the following versions:

- Hoomans NPC persistence: `PNC.Const.PERSISTENCE_VERSION = 16`.
- Hoomans appearance policy: schema `2`.
- Hoomans NPC inventory: schema `2`; modes `SEED_ONLY`, `BASELINE_DELTA`, and
  `FULL`.
- Hoomans CoreBridge envelope: schema `1`; Hoomans Core delta: schema `1`.
- PsychopatzCore virtual inventory and dense item records: schema `1` each.
- Hoomans directed social state: schema `3`.

No older Hoomans save version was verified as a supported import input in this
audit. Hoomans' normal persistence loader performs an exact-version reset for
unsupported records. An extraction adapter must inspect and copy the source
payload before that reset path, retain the original unchanged, and fail closed
when its version or required fields are unknown.

## Deferred serialized-root mapping

The read-only P0B planner explicitly projects serialized roots outside the
bounded foundation adapter into `candidate.source.opaque`. The current raw
roots include `recordRevision`, `repairVersions`, `uniqueDefinitionId`,
`uniqueDefinitionVersion`, `inventoryTemplateRef`, `startingItems`,
`skillBaseLevels`, `tacticalClass`, `ownerUsername`, `m`, `orderSpec`,
`patrolPoints`, `patrolIndex`, `hostility`, `health`, `stamina`, `weaponMode`,
`attackType`, `equipmentSpawnMode`, `equipmentPoolID`, `equipment`,
`allowedJobs`, `jobPriorities`, `semanticCognition`, `semanticActionPlan`,
`followerAbandonment`, `colonistDeparture`, `affiliation`, `progression`,
`recipeKnowledge`, `corpse`, `mapPresentation`, `vanillaTraits`,
`vanillaTraitsAuthored`, `dynamicTraits`, `dynamicTraitsAuthored`, `npcTraits`,
`conditionStats`, `npcJournal`, and `bodyHint` when present. Each receives a
`canonical_mapping_deferred` decision and remains source data; this is not a
Core ownership or write approval. Hoomans `cce488a6` tests exact preservation
of `semanticCognition` and an unknown `futureRoot` through the candidate codec.

## Executable baseline

Run from the Project Hoomans repository:

```text
python3 tests/run_tests.py pnc_npc_foundation_parity_baseline_smoke --jobs 1 --verbose
```

The baseline passed on 2026-10-18 in the existing isolated Lua harness. It
uses the actual Hoomans identity factory/profile, appearance resolver, record
generator, inventory template/persistence/CoreBridge, relationship normalizer,
and record serializer/deserializer. SurvivorFactory and native equipment
construction are deterministic test doubles; this is not live SP/MP or
Project Zomboid acceptance. The P0B characterization
`pnc_npc_foundation_p0b_gap_characterization_smoke.lua` passes as well. It
confirms the authored appearance policy and complete voice profile remain
unserialized, and identifies `legacyTemplateKey` as the current portable
metadata loss. It also confirms that `customName` and bounded `modData` are
not losses in this path. No canonical parity claim is made until every
representability decision has an import owner.
