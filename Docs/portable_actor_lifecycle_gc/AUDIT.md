# L0 Audit — Portable Actor Lifecycle & Social Garbage Collection

**Status:** ACCEPTED (L0 gate closed; production code untouched during L0).  
**Checkpoints audited:**
- `PsychopatzCore`: `d2d6c62799574f52a57befc1263d39d8e3c51f03`
- `ProjectHoomans`: `67510b0dba22f78dd012093476accf900b7e1814`
- `DynamicTrading`: `c5a45962047068f6e597b36a0111bdd8d99abe13`

---

## 1. Cross-Repository Removal & Deletion Classification

| Repo | Call Site | Mechanism | Classification | Current Behavior & Gap |
|---|---|---|---|---|
| Core | `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzActorMigration.lua:315` (`Migration.Rollback`) | `registry:Remove(mapping.actorId)` | `rollback-hard-delete` | Undoes uncommitted/rolled-back candidate import; should migrate to explicit `HardDelete` with `"rollback"`. |
| DT | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderGeneration.lua:98-103` (`RemoveCanonicalGroup`) <- `DTHoomans_CaravanService.lua:635-642,821-826` | `Actors.DefaultRegistry:Remove(actorID)` + `RemoveGroup` | `rollback-hard-delete` | Cleans up failed caravan creation transactions before commit. |
| DT | `Contents/mods/DTAbstract/42.20/media/lua/server/DTAbstract/DTAbstract_PreSurvivorWorldImport.lua:181-183` (`Import.Rebind`) | `registry:ReleaseProvider` then `registry:Remove(oldActorID)` | `migration-redirect / superseded-actor` | Rebinds commercial record from `actor:dt:world:*` / `actor:abstract:*` to canonical SurvivorWorld actor; **Gap:** does not merge `oldActor.social` or `DTCommon.WorldKnowledge` before removal. |
| DT | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderRegistry.lua:103-115` (`TraderService.Remove`) called by `DTAbstract_Server.lua:322` (`RemoveTrader`) | `Provider.releaseTrader` + `TraderService.Remove(traderID)` | `debug/admin` + `commercial-role-removal` | Releases DT lease/journey and removes commercial record while preserving Core actor. (Server handler lacks `canUseDebug(player)` check.) |
| DT | `DTAbstract_TraderWorldProvider.lua:275` (`spawnTrader`), `DTHoomans_CaravanService.lua:731,819` (`finalize` / `processState`) | `TraderService.Remove` + lease/faction rollback | `rollback-hard-delete` | Cleans failed trader/caravan spawn. (`CaravanService:819` hardcodes `"dt_" .. faction.id` rather than `state.traderID`.) |
| DT | `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_ProviderRuntime.lua:88-101` (`releaseProviderProjection`) | `PNC.Registry.RemoveRecord(actorID)` (only if `dtProviderProjection == true`) | `rollback-hard-delete` (on `:265,294`) / `dematerialization` (on `:447,550`) | Tears down transient PNC physical projection while preserving Core actor and DT commercial record. |
| DT | True trader actor death / retirement | None wired | `lifecycle-retire` (**missing**) | **Gap:** DT does not subscribe to Core retirement or retire dead traders; `DTAbstract_TraderWorldProvider.lua:585-605` keeps `actor == nil` records indefinitely as `available = false`. |
| Hoomans | `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health/PNC_Health_Death.lua:150,158,172` (`retireDeadRecord`) & `PNC_BodyLifecycle_Reanimation.lua:103` | `Registry.RemoveRecord(record.id)` | `lifecycle-retire` | Deletes full PNC record after `ReleaseWorker`, `markDeadState`, `CorpseAwareness.ObserveDeath`, `UniqueNPCRegistry.MarkDead`, `Factions/Communities.OnNPCDeath`, and `createCorpse`. **Critical Gap:** 0 calls to Core `ActorRegistry` retire/remove/`CoreProvider.Release`; canonical Core actor leaks indefinitely. |
| Hoomans | `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/API/PNC_API/Lifecycle.lua:205` (`API.Despawn`) <- `PNC_CommunityDirector_Core.lua:206`, `PNC_MobileGroupDirector_Generation.lua:146`, `PNC_GroupGenerator_Rollback.lua:13,26` | `Registry.RemoveRecord(npcId)` | `rollback-hard-delete` | Rolls back failed/uncommitted generated NPCs; also leaves Core actor orphaned. |

---

## 2. Persisted Actor Reference Classification

### PsychopatzCore (`Contents/mods/PsychopatzCore/`)
- `Actors/PsychopatzActorRegistry.lua` (`PsychopatzCore.ActorRegistry` GlobalModData): `records[actorId]` (`STRONG` live actor; **missing** lifecycle state, tombstones, `lifecycleRevision`, and GC).
- `Actors/PsychopatzPlayerIdentity.lua` (`PsychopatzCore.PlayerIdentity` GlobalModData): `identities[uuid]` (`STRONG` issued character UUIDs; **missing** `lifecycleStatus`, `retiredAt`, `lifecycleRevision`, purge support, and `OnPlayerDeath` hook).
- `Actors/PsychopatzSocial.lua`: `actor.social.relationships[targetKey]` (`STRONG` when anchored/pinned/high-significance, otherwise `WEAK`/prunable); `social.aliases[alias]` (`migration-redirect` / `WEAK`); `relationship.memories[*]` (currently per-edge up to 64); `memory.sourceKey` (`WEAK` provenance ref).
- `Actors/PsychopatzActorKnowledge.lua`: `actor.knowledge.byPlayer[playerKey]` (`STRONG` bucket; `MAX_PLAYERS = 32` never evicts retired players, risking `"player_limit"`); `evidence[*].sourceEntityKey` (`WEAK`); `fact.value` / `evidence[*].payload` (`LABEL_ONLY`).
- `WorldKnowledge/PsychopatzActorWorldKnowledge.lua`: `byActor[actorID]` (`STRONG` bucket, `DEFAULT_MAX_ACTORS = 256` arbitrary eviction); `refs[*].sourceActorID` (`WEAK`); `runtime.cooldowns` (`transient/runtime`).
- `WorldKnowledge/PsychopatzWorldFact.lua`: `subject` / `object` / `cause` (`WEAK / historical` with inline snapshot `name`); `producer` / `payload` (`LABEL_ONLY`).
- `World/SurvivorWorld/Types/*` (`PsychopatzCore.SurvivorWorld` GlobalModData): Faction/Community/Group `leaderActorID` (`STRONG` while active), `memberActorIDs` (`WEAK` membership list, currently never scrubbed on death/purge), `discovery.players[playerKey]` (`STRONG` discovery bucket).
- `Actors/PsychopatzActorProjection.lua` & `Conversation/PsychopatzConversationHistory.lua`: `projection/cache` and daily-reset UI presentation (`transient/runtime` threads, persistent `migratedThreads`).

### ProjectHoomans (`Contents/mods/ProjectHoomans/`)
- **Confirmed non-existent subsystems:** No memorials/graves/cemetery, no prisoner/captive system, no dedicated squad subsystem, no separate persisted rumor/gossip table, and no persisted bed/facility NPC ownership (`PNC_FacilityReservations_Core.lua` and `PNC_FactionTollService_Core.lua` are `transient/runtime` only).
- `PNC_Core_Global` / `PNC_Record_<id>`: `record.id`, `coreActorID`, `ownerCharacterUUID`, `generation.playerCharacterUUID` (`STRONG` while alive; `ownerUsername` = `LABEL_ONLY`); `social.relationshipExtensions[targetKey].bond` (`STRONG` for durable bonds `"friend"|"lover"|"family"`); `social.conduct.evidence[*].{actorKey,subjectKey}` (`WEAK`); `followerAbandonment`/`colonistDeparture` (`WEAK`).
- `PNC_Core_Global.deathMarkers[id]` (`PNC_DeathMarkers.lua`): `id`, `corpseToken`, `colonyOwned`, `lifecycleOnly`, `infected` (`STRONG` temporary corpse/reanimation identity while active; `name` = `LABEL_ONLY`). Never expires while chunk is unloaded (`CorpseAudit.lua:194` removes only on loaded-missing corpse or reanimation).
- `PNC_HuskLedger`: `npcId` (`WEAK`, capped at 256 / 168h TTL).
- `PNC_SurvivorWorldExtensions_v1` & Factions/Communities/Abstract Groups/Uniques:
  - Factions `ownerPlayerKey`, `playerMemberKeys`, `leaderNPCID` (`STRONG`); `playerPacifications` (`WEAK`, TTL), `relationDetails[*].incidents[*].{actorKey,subjectKey}` (`WEAK`, bounded), `tags.formerOwnerKey` (`WEAK`). **Gap:** `PNC_FactionService_Lifecycle.lua:201-231` does not remove non-leader dead NPCs from `faction.memberIDs` / Core `memberActorIDs` on `OnNPCDeath`.
  - Communities `leaderNPCID` / `memberIDs` (`STRONG`, cleaned in `Communities.OnNPCDeath`).
  - Abstract `uniqueNPCsByID[defId]` (`STRONG` alive, `WEAK` once `status == "dead"`).
- `PNC_PlayerCharacters`: `byUUID[uuid]` (`STRONG`, dead characters kept forever with `status = "dead"`); `supersededBy` / `uuidAliases` (`migration-redirect`); `conduct.evidence` & `startingCompanions.grants[traitID].npcID` (`WEAK`).
- `PNC_QuestInstances_V1`: `ownerCharacterUUID`, `giverNPCID`, `scopeKey` (`STRONG` while active/non-terminal; `WEAK` once terminal; **Gap:** no `OnNPCDeath` handler).
- `PNC_MedicalCare_V1`: `patientId`, `supplyRequesterId` (`STRONG` while active, `WEAK` terminal; **Gap:** no `OnNPCDeath` cleanup); `actorId` (`transient/runtime`).
- `PNC_FishingWorld_V1` / `PNC_LumberWorld_V1`: `workers[npcId]` / `jobs[npcId]` (`WEAK` stale worker refs; **Gap:** not released in `Health.Kill`).
- `PNC_NPCKnowledge`, `PNC.WorldKnowledge`, `PNC_ConversationHistory`, `PNC_InteractionLifecycle_V1`: `WEAK` historical/knowledge dossiers; `PNC_ColonyStorage_v1.activityJournal[*].ACTOR` (`LABEL_ONLY`); `PNC_WorkOrders_V1` / `PNC_PBrainZMemory` (`transient/runtime`); `PNC_PlayerOwnedNeeds_V1` (`projection/cache`, cleaned in `RemoveRecord`).

### DynamicTrading (`Contents/mods/DynamicTrading/`)
- **Confirmed non-existent subsystems:** No debts, contracts, loans, invoices, escrow, orders, bounties, persisted trade logs, or DT-owned faction tables exist. Quotes (`DTCommon_TraderStock.lua`) are `transient/runtime`. Trade aggregates live in Core social extension `"DynamicTrading"`.
- `ModData["DTCommon.Traders"]`:
  - `t[traderID].ca.actorID`, `t[traderID].l` (`STRONG` canonical commercial role / leader ID);
  - `t[traderID].p` (`STRONG` while materialized, `nil` when abstract, `projection` of physical binding);
  - `t[traderID].m[1..24]`, `t[traderID].g` (`WEAK` roster/faction refs);
  - `t[traderID].ca.providerLeaseID`, `ca.providerBodyID` (`projection/cache`);
  - `t[traderID].ca.coreActorID`, `ca.coreActorId`, `ca.coreProvider` (`migration-redirect / obsolete`, stripped on normalize);
  - `t[traderID].n`, `r`, `c` (`LABEL_ONLY`);
  - `data.worldKnowledge` (`WEAK / projection` Core `WorldKnowledge` payload, currently never pruned on trader/actor removal).
- `ModData["DTCommon.SettlementMarkets"]`: zero actor/trader/player refs.
- `ModData["DTCommon.MarketEvents"]`: zero actor/player refs (optional `scope = { kind = "faction", id }` -> `WEAK`).

---

## 3. Verified Implementation Bugs & Hot-Path Findings for L1-L8

1. **Core Social Memory Multiplier & Caller Inventory:**
   - Currently `PsychopatzSocialRetention.lua:10-13` defines `MAX_MEMORIES = 64` (`SHORT=16`, `LONG=42`, `ANCHOR=6`) **per relationship**.
   - Direct `relationship.memories` readers/writers exist in **only 3 Core files** (`PsychopatzSocial.lua`, `PsychopatzSocialRetention.lua`, `PsychopatzSocialProjections.lua`), **0 DynamicTrading files**, and **~24 ProjectHoomans files** (relationship math/services, `CorpseAwareness_Relationship`, `CombatAdapter_Awareness`, `PlayerKnowledgeCommands_Identity`, debug formatters).
2. **Core Semantic / Interaction Hot Paths:**
   - `GetHotRelationshipSnapshot` and `SocialQueryPlan` do not exist in Core yet (L8).
   - `PsychopatzActorConversationService.lua:49-50` deep-copies `actor.social.relationships` on every turn; L8 must avoid copying/scanning full social graphs on click/turn.
3. **Player-Character Lifecycle Bug in Hoomans:**
   - `PNC_PlayerCharacterLifecycle_Callbacks.lua:28-30` captures only 2 of 3 return values from `PlayerCharacters.MarkDead` (passing `"marked_dead"` instead of the dead character `uuid` to `Recruitment.ReleaseCharacterOwnership`).
4. **Hoomans Knowledge Snapshot Bug on Dead NPCs:**
   - `PNC_NPCKnowledgeService_PlayerSnapshots.lua:69` fails with `"npc_not_found"` once `Registry.RemoveRecord(npcID)` runs.
5. **DT Dead-Code Binding Check:**
   - `DTHoomans_SettlementTrader.lua:243-247` checks `Service.SetCoreActorID`, which does not exist (`DTCommon_TraderService.lua:650` defines `Service.BindActor`).

---

## 4. L0 Serialized Footprint Baseline (Measured at Core `HEAD d2d6c62`)

Measured using `PsychopatzCore` `Actors.NewRegistry()` + `Persistence.SerializeRegistry` / `SerializeActor` (`Json.Encode`) with `MAX_STRING_BYTES = 30000` chunking:

| Scenario | Actors | Contacts/Actor | Memories/Contact | Total Persisted Memories | Serialized Bytes | Avg Bytes/Actor | 30KB Chunks |
|---|---|---|---|---|---|---|---|
| Zero-social baseline | 0 | 0 | 0 | 0 | 83 B | 0.0 B | 1 |
| Zero-social baseline | 10 | 0 | 0 | 0 | 12,353 B | 1,235.3 B | 1 |
| Zero-social baseline | 100 | 0 | 0 | 0 | 122,912 B | 1,229.1 B | 5 |
| Zero-social baseline | 1000 | 0 | 0 | 0 | 1,230,185 B | 1,230.2 B | 42 |
| Sparse `5x4` baseline | 10 | 5 | 4 | 200 | 74,643 B | 7,464.3 B | 3 |
| Sparse `5x4` baseline | 100 | 5 | 4 | 2,000 | 751,552 B | 7,515.5 B | 26 |
| Sparse `5x4` baseline | 1000 | 5 | 4 | 20,000 | 7,584,695 B | 7,584.7 B | 253 |
| High-contact (1 actor, same hr) | 1 | 1 | 64 | 64 | 17,671 B (social: 16,713 B) | 17,671 B | 1 |
| High-contact (1 actor, same hr) | 1 | 10 | 64 | 640 | 162,208 B (social: 161,250 B) | 162,208 B | 6 |
| High-contact (1 actor, same hr) | 1 | 25 | 64 | 1,600 | 402,993 B (social: 402,035 B) | 402,993 B | 14 |
| High-contact (1 actor, same hr) | 1 | 50 | 64 | 3,200 | 804,193 B (social: 803,235 B) | 804,193 B | 27 |
| High-contact (1 actor, same hr) | 1 | 100 | 64 | 6,400 | 1,606,721 B (social: 1,605,763 B) | 1,606,721 B | 54 |
| Multi-day high-contact (48/edge) | 1 | 100 | 48 | 4,800 | 1,210,590 B (social: 1,209,591 B) | 1,210,590 B | 41 |
| Sample compact tombstone | 1 (tombstone) | 0 | 0 | 0 | 159 B | 159 B | — |

**Key quantitative proof:**
- Current `MAX_MEMORIES = 64` per relationship multiplies linearly with relationship count (`16,713 B` for 1 contact -> `1,605,763 B` social payload for 100 contacts, i.e. **~16 KB per saturated edge**, **1.61 MB for a single actor**).
- Replacing a full dead live actor (`1,230 B` base, `7,585 B` sparse, up to `1.61 MB` high-contact) with a compact tombstone (`~159 B`, eventually purged to `0 B`) and enforcing one actor-level 96-memory budget yields an immediate **8×–48× footprint reduction per retired actor** and caps a 100-contact survivor's memory bank below ~40 KB regardless of contact count.

---

## 5. CodeBuilder Social Policy Extension Seams

- **Compiler & schema:** `tools/semantic_harness/codebuilder/social_policy_compiler.py` (`psychopatz.social-policy.package.v1` / `psychopatz.social-policy.v1`).
  - `_normalize_event` validates `memory`, `relationship`, `evidence`, `extensions`, and enforces `_scan_portability` (forbidding `IsoPlayer`, `ModData`, `PNC.`, `DTCommon.`, etc.).
  - `build_social_domain_schema` exports `DomainSchema(domain="social")` into ConvoEngine.
  - `render_social_policy_lua_artifacts` compiles deterministic `<Owner>/SocialPolicy/Events/<Domain>.lua` + `Registry.lua`, consumed by `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzSocialPolicy.lua`.
- **Recipe check baseline:** `python3 tools/semantic_harness/codebuilder/reconcile.py --recipe tools/semantic_harness/codebuilder/generation_recipe.json --check` passes clean at L0 (`desired=467`, `missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`, `preserved=18`).
- **Baseline scale smoke:** `lua tests/psychopatz_social_scale_stress_smoke.lua` passes at L0 (`actors=1000 chunks=48 elapsed=7.154s`).
