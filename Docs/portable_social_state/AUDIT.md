# Initial Audit — Portable Social State

**Scope:** P0 source-verified cross-repo baseline and authority audit (`P0A` / `H0` / `DT0`). No production schemas were modified in P0.

## Core evidence

Current PsychopatzCore source already has the portable social nucleus in `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzSocial.lua` (L1-459) and `PsychopatzActorSocialAuthority.lua` (L1-153):

- `SCHEMA_VERSION = 1`;
- sparse relationship map keyed by normalized actor/player/steam target (`npc:`, `actor:`, `player:`, `steam:`);
- generic `approval` (`[-100, 100]`), `respect` (`[-100, 100]`), and `familiarity` (`[0, 100]`) dimensions;
- relationship `revision` and actor social `revision`;
- per-relationship memories (`MAX_MEMORIES = 64` FIFO eviction in `RecordAuthorizedEvent`);
- recent event dedup with `MAX_RECENT_EVENTS = 128` FIFO eviction;
- server-authorized `RecordAuthorizedEvent` contract (`event.authorized == true and event.authority == "server"`);
- namespaced extension bags (`state.extensions`, `relationship.extensions`);
- persistence/registry integration through Core Actors (`PsychopatzActorPersistence.lua` v2 compact encoding omitting default `actor.social`, `PsychopatzActorRuntimeStore.lua` 30,000-byte chunked `GlobalModData["PsychopatzCore.ActorRegistry"]`, `PsychopatzActorProjection.lua` excluding private `actor.social` from client broadcasts, `PsychopatzPlayerIdentity.lua` persistent MP/SP keys and `GetLegacyKeys`, `PsychopatzActorProvider.lua` leases across `PsychopatzCore`, `ProjectHoomans`, `DTAbstract`, `DTHoomans`).

Baseline Core test gap identified: `tools/semantic_harness/testing/acceptance.py:L46-51` (`CORE_LUA_PATTERNS`) only globs `*convo*.lua`, `*semantic*.lua`, `*runtime_role*.lua`, `*conversation*.lua`, omitting `*social*.lua`, `*actor*.lua`, `*player_identity*.lua`, `*hotplug*.lua`.

### Baseline serialized footprint & query cost (`PsychopatzActorPersistence.EncodeActor` + `Social.Get`)

Measured directly with Lua against `PsychopatzCore`:

- `empty` (0 rels, 0 mems): `1005` compact JSON bytes (`social` omitted, `0` social bytes), `1k_get_ms = 0.339 ms`
- `sparse1_1mem` (1 rel, 1 mem): `1560` compact JSON bytes (`504` social bytes), `1k_get_ms = 3.898 ms`
- `sparse5_10mems` (5 rels, 10 mems/rel = 50 mems): `12238` compact JSON bytes (`11162` social bytes), `1k_get_ms = 21.195 ms`
- `dense1_64mems` (1 rel, 64 unconsolidated mems): `14539` compact JSON bytes (`13470` social bytes), `1k_get_ms = 120.677 ms` (driven by full `Util.clone` on every `Social.Get` and lack of repeated-event consolidation)

This is the mechanism to evolve. A second Core social authority is not justified.

## Project Hoomans evidence

Project Hoomans currently contains richer production social systems including:

- `RelationshipService` (`server/PNC/Social/PNC_RelationshipService.lua` + 11 submodules, `shared/PNC/Core/Relationships/*`): `approval`, `respect`, `familiarity`, `baselineApproval`, `baselineRespect`, `state`/`previousState`, `memories` (`MEMORY_LIMIT = 20`), `cooldowns`, `saturation`, `bond`, `interactionJournal`, `morale`, `eventSequence`, `relationshipRevision`.
- `SocialEvent` service/hooks/transaction path (`server/PNC/Social/PNC_SocialEventService.lua`, `shared/PNC/Core/Relationships/PNC_SocialEventDefinitions.lua`): 25 event types with two-phase `Conduct` + `RelationshipService` commits and post-process faction/knowledge bridges.
- `ConductService` (`shared/PNC/Core/Conduct/*`, `server/PNC/Social/PNC_ConductService.lua`): 7-dimension objective conduct ledger stored in `social.extensions.ProjectHoomans.conduct` and `PlayerCharacters.Registry`.
- `KnowledgeSocialEventAdapter` & `NPCKnowledgeService` (`GlobalModData["PNC_NPCKnowledge"]`, `PNC_Persistence_CoreKnowledge.lua`).
- `ConversationMemory` (`record.memory` / `raw.m`): compact integer ring buffers (`s` TODAY max 8, `t` topic bitmasks max 4 players, `l` durable max 6).
- Unified Semantic Evidence (`SESSION`, `TODAY`, `DURABLE`, max 16 rows) and accepted Semantic Social Conversation Director consumers.

Critical convergence hazards verified in `PNC_EntityRef.lua` (L43-87), `PNC_Persistence_CoreSocial.lua` (L53-65, L169-171, L194-346), and `PNC_RelationshipMath.lua` (L61-114):
- `PNC.EntityRef.Parse` rejects `actor:*`, colon-containing `npc:*` IDs, and 2-segment `player:*` keys, causing `Types.NormalizeMemory` / `Types.NormalizeRelationship` in `FromCoreSocial` to silently discard foreign (e.g. `DynamicTrading`) memories/edges.
- `PNC_RelationshipMath.RecalculateRelationship` recomputes `approval`/`respect` from `baseline + sum(Hoomans memories)`, erasing direct deltas applied by other mods unless Core owns the unified baseline + memory/consolidation math.

## DynamicTrading / DTAbstract evidence

Current DynamicTrading source already demonstrates portability value:

- trader definitions carry canonical actor IDs (`record.ca.actorID`, `DTCommon_TraderGeneration.lua`, `DTCommon_CoreTraderCandidateFactory.lua`);
- `DTAbstract` is an abstract provider path in the same DynamicTrading repository (`DTAbstract_TraderWorldProvider.lua`, `DTAbstract_RadioOS.lua`, `DTAbstract_NearbyDiscovery.lua`, `DTAbstract_CoreProvider.lua`);
- `DTCommon_CoreActorPolicy` (`L300-442`) resolves the Core actor, reads Core social relationship `approval`/`respect`/`familiarity` for `relationshipModifier` (`PriceContext`), and calls `SocialAuthority.RecordAuthorizedEvent` + `SetExtension("DynamicTrading", ...)` from `DTCommon_TraderService.ExecuteTradeBasket` (`L1021-1028`);
- merchant stock (`record.i`), budget (`record.b`), stock version (`record.v`), quotes, and trade commit remain `DTCommon`-owned.

Continuity bugs identified for P5:
- `DTHoomans_SettlementTrader.lua:L251-269` (`EnsureTraderForFaction`) and `DTCommon_TraderRegistry.lua:L144-164` (`BindFaction`) do not bind `record.ca.actorID`, leaving resident settlement traders with `ca.actorID == nil`.
- `DTAbstract_PreSurvivorWorldImport.lua:L136-167` updates `policy.actorID` without updating `record.l`, `record.g`, `record.m`.
- `DTHoomans_ProviderRuntime.lua:L388-406` (`DematerializeTrader`) omits Core social sync/preservation when committing `providerLease` and `personalInventory`.
- `DTCommon_CoreActorPolicy.lua:L402-417` applies hardcoded flat `+1 approval, +0 respect, +1 familiarity` without CodeBuilder Social Policy compilation or consolidation.
- `DTCommon_TraderConversation.lua:L537-725, L911-922` omits `relationship` in `contextFor` and uses static `responseFor` strings for free-text semantic turns.

## CodeBuilder evidence

PsychopatzCore owns the current ConvoEngine schema/compiler/package-routing toolchain (`tools/semantic_harness/codebuilder/generation_recipe.json`, `reconcile.py`, `generation_ownership.py`, `targets/pz_packages.json`, `semantic_contract.py`).

Source-verified decision: Social Policy should be a **distinct typed CodeBuilder IR domain** (`psychopatz.social-policy.v1`, package schema `psychopatz.social-policy.package.v1`, surface `social_policy_lua` in `generation_recipe.json`) rather than forcing non-conversational gameplay rules into `convo-engine.v1` (which hard-gates `kind` to `dialogue|behavior|beat|realization`). The Social Policy compiler exports a `DomainSchema` into `DomainSchemaRegistry` (`semantic_contract.py:L630-678`) so `convo-engine.v1` dialogue records remain statically validated against compiled social policy.

## Reconciled Cross-Repo Ownership Map

| Field / Path / System | Classification | Authoritative Owner / Target |
| --- | --- | --- |
| `actor.social` (`schemaVersion`, `revision`, `personality`, `personalityOverrides`, `recentEventIDs`, `aliases`, `extensions`) & `relationships[targetKey]` (`targetKey`, `approval`, `respect`, `familiarity`, `baselineApproval`, `baselineRespect`, `state`, `previousState`, `revision`, `lastEventAt`, `lastEvaluatedAt`, `memories`, `cooldowns`, `saturation`, `extensions`) | **Core-generic authority** | `PsychopatzCore/Actors/PsychopatzSocial.lua` & `PsychopatzActorSocialAuthority.lua` |
| `PlayerIdentity` (`GetTargetKey`, `GetLegacyKeys`, provenance), `ActorProvider` leases, `ActorPersistence`, `ActorRuntimeStore` | **Core-generic authority** | `PsychopatzCore/Actors/*` |
| `CodeBuilder` toolchain (`generation_recipe.json`, `reconcile.py`, `generation_ownership.py`, `targets/pz_packages.json`, `DomainSchemaRegistry`) | **Core-generic authority** | `PsychopatzCore/tools/semantic_harness/codebuilder/*` |
| `PNC_EntityRef.lua` strict key filter, `PNC_RelationshipMath.RecalculateRelationship` non-Core overwrite, `PNC_Persistence_CoreSocial.lua` extension-buried generic fields | **Duplicate-to-migrate** | Converge into Core `PsychopatzSocial` + thin Hoomans adapter |
| `PNC_SocialEventDefinitions.lua` portable retention/salience/relationship metadata; `DTCommon_CoreActorPolicy.lua` hardcoded flat `+1/+0/+1` deltas | **Duplicate-to-migrate** | Migrate to adopter-owned canonical CodeBuilder Social Policy packages (`psychopatz.social-policy.v1`) |
| `ConductService`, `NPCKnowledgeService`, `bond`, `morale`/`moraleBaseline`, `interactionJournal`, Faction diplomacy (`PNC_FactionTypes/Relations`), `ConversationMemory` (`raw.m`), physical NPC lifecycle/hooks | **Hoomans-specific authority** | `ProjectHoomans` (stored in `extensions.ProjectHoomans` or dedicated Hoomans stores) |
| `DTCommon.Traders` (`i`, `b`, `v`, `s`, `a`, `c`, `r`, `ca.actorID`, `ca.priceBias`, `ca.restock`, visits), `SettlementMarkets`, `MarketEvents`, `ExecuteTradeBasket`, `rel.extensions.DynamicTrading`, `DTCommon/ConvoEngine/*`, `MarketSense` | **DynamicTrading-specific authority** | `DynamicTrading` (`DTCommon`, `DTAbstract`, `DTHoomans`) / `MarketSense` |
| `PsychopatzActorProjection`, `PNC_RelationshipPresentation`, `Evidence` / `EvidenceAdapters` (`SESSION`/`TODAY`/`DURABLE`), `SocialDirector`, `DTCommon_CoreActorPolicy.PriceContext`, `record.ca.provider*`, `ViewCache`, `dtProviderProjection` | **Derived projection/cache** | Computed on read or bounded client snapshot; never authoritative truth |
| `CORE_LUA_PATTERNS` exclusion of `*social*`/`*actor*`/`*player_identity*`/`*hotplug*` in `acceptance.py:L46-51`; `DTCommon` pre-SurvivorWorld import shims (`actor:dt:world:*`, `actor:abstract:*`) | **Legacy-to-fix / retire** | Update `acceptance.py` in P2; preserve/reconcile shims where needed |

## Current workspace risk

Production worktrees are clean as of P0 (`9a20333a231fd4e2f95ab6b497565c98e7c93ce4` in `psychopatzCore`, `68aae0667b68d6001ae2a135d300c16b9a42188e` in `ProjectHoomans`, `36a8767e731ea0d1c566eb9d617e4a81eac8c047` in `DynamicTrading`), with only the untracked job documentation directories present before phase commits. Always inspect current `git status` before each phase edit and preserve any unrelated dirty work.
