# Progress — Portable Social State

**Status:** IN PROGRESS — P0 accepted; advancing to P1.
**Current phase:** P1 — Portable contract and migration design.
**Developer completion:** 1/10 phases accepted (P0).
**Primary:** /home/psychopatz/Zomboid/Workshop/psychopatzCore
**Participants:** ProjectHoomans, DynamicTrading.

## Verified P0 findings

- Core `PsychopatzSocial` (`SCHEMA_VERSION = 1`, `MAX_MEMORIES = 64`, `MAX_RECENT_EVENTS = 128`) and `PsychopatzActorSocialAuthority` are verified; compact v2 persistence omits `payload.social` when default (`1005` bytes empty vs `14539` bytes at 64 unconsolidated memories, `1k_get_ms = 120.677 ms` due to full clone).
- Baseline Core test discovery gap: `tools/semantic_harness/testing/acceptance.py` `CORE_LUA_PATTERNS` omits `*social*.lua`, `*actor*.lua`, `*player_identity*.lua`, `*hotplug*.lua`.
- ProjectHoomans convergence hazards verified: `PNC_EntityRef.lua` rejects `actor:*`, colon `npc:*` IDs, and 2-segment `player:*` keys; `PNC_RelationshipMath.RecalculateRelationship` can erase foreign (e.g. `DynamicTrading`) deltas; `PNC_Persistence_CoreSocial.lua` tucks generic relationship fields (`baselineApproval`, `baselineRespect`, `state`, `previousState`, `cooldowns`, `saturation`, `lastEvaluatedAt`) into `rel.extensions.ProjectHoomans`.
- DynamicTrading continuity gaps verified: `DTHoomans_SettlementTrader.lua` and `DTCommon_TraderRegistry.BindFaction` omit `record.ca.actorID`; `DTAbstract_PreSurvivorWorldImport` updates `policy.actorID` without `record.l`/`g`/`m`; `DTHoomans_ProviderRuntime.DematerializeTrader` omits Core social sync; `DTCommon_CoreActorPolicy` uses hardcoded flat `+1/+0/+1` deltas; `DTCommon_TraderConversation` omits `relationship` in `contextFor` and uses static `responseFor`.
- CodeBuilder architecture decision: Social Policy will be a distinct typed CodeBuilder IR domain (`psychopatz.social-policy.v1` / `psychopatz.social-policy.package.v1`, surface `social_policy_lua`) rather than forcing non-conversation gameplay rules into `convo-engine.v1`, bridging to ConvoEngine via `DomainSchemaRegistry`.
- Cross-repo ownership map documented in `Docs/portable_social_state/AUDIT.md` and participant audit/progress docs with zero production schema edits in P0.

## Immediate Next Chunk

**P1 — Freeze portable contracts and migration design in `Docs/portable_social_state/ARCHITECTURE.md`**, then proceed directly into **P2** (`PsychopatzSocial` bounded retention, salience, lazy decay, consolidation, provenance, candidate/autonomy query projections).
