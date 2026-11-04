# S11 Post-Migration Consolidation

Snapshot: 2026-11-04.

## Result

**DEVELOPER ACCEPTED — native Project Zomboid SP/MP acceptance remains user-owned.**

S11 is a post-S10 hardening slice. It does not add a second runtime or reopen the accepted SurvivorWorld architecture. It removes migration-era fallback authority and misleading names that remained after the functional cutover.

## Core generation contract

PsychopatzCore remains the generic generation authority.

- PsychopatzSurvivorWorldGenerationPlanner.BuildGroupPlan now accepts a bounded caller-supplied memberActorIDs list for groups formed from already-existing actors.
- Supplied actor IDs are validated, deduplicated and bounded by the Core group-member limit.
- ProjectHoomans automatic settlement/group generation now consumes Core community/group plans instead of PNC-only generation-plan modules.
- Core-generated faction/community/group/actor IDs are passed through the Hoomans creation/materialization seams.
- Hoomans still owns physical presence, equipment, facilities, combat/AI policy and other adopter-only behavior.

The removed PNC-only plan modules are PNC_GroupGenerationPlan.lua and PNC_SettlementGenerationPlan.lua.

## ProjectHoomans consolidation

### One-way import only

The four retired generic PNC ModData keys are now known only by PNC/Director/PNC_SurvivorWorldImportSource.lua.

That module is a frozen, bounded pre-SurvivorWorld decoder/retirement boundary for factions, communities, abstract world and discovery. Normal faction/community/director/discovery modules no longer advertise those retired ModData keys.

### Runtime views, not storage authorities

Migration-era storage naming was removed:

- PNC_AbstractWorldStore -> PNC_HoomansWorldView;
- faction registry persistence module -> faction world-view module;
- community persistence module -> community world-view module.

PNC.HoomansWorldView has no public Save authority.

Faction/community gameplay views expose Commit, which delegates to the active Core + Hoomans-extension persistence boundary and fails closed if the cutover is unavailable. No detached/partial runtime can resurrect the old generic roots.

After cutover, view reloads rebuild from Core SurvivorWorld + Hoomans extensions. The frozen old roots are read only before the one-way cutover and are retired only after durable Core/extension writes succeed.

### Hoomans policy naming

PNC_PopulationIdentity.lua was replaced by PNC_PopulationHoomansPolicy.lua.

The replacement contains only adopter policy: faction tags and initial physical-presence preference. Generic faction naming/identity comes from Core generation contracts.

### Native acceptance fixtures

The faction/community/abstract-world/discovery native restart fixtures now verify:

- Core SurvivorWorld contains canonical generic state;
- PNC_SurvivorWorldExtensions_v1 contains Hoomans-only extension state;
- retired generic PNC roots remain empty.

They no longer require duplicate old-root persistence.

## DynamicTrading consolidation

DynamicTrading migration-era inputs are isolated behind explicit one-way import modules:

- DTCommon_PreSurvivorWorldImport.lua owns retired coreActorID/coreActorId/coreProvider decoding;
- DTAbstract_PreSurvivorWorldImport.lua owns recognized pre-SurvivorWorld standalone actor rebinding.

DTCommon_CoreActorPolicy consumes canonical fields during normal runtime; old alias names are not part of its active schema logic.

DTHoomans caravan integration no longer references the removed PNC.PopulationIdentity object:

- generic caravan faction naming comes from Core SurvivorWorld generation profiles;
- Hoomans-only mobile/population tags come from PNC.PopulationHoomansPolicy;
- the standalone bridge harness remains 78/78.

The two pre-existing user-owned DynamicTrading mod.info edits remain untouched by this consolidation.

## Source-audit result

ProjectHoomans active production/tests contain no references to:

- PNC.AbstractWorldStore / PNC_AbstractWorldStore;
- PNC_FactionService_RegistryPersistence;
- PNC_CommunityService_Persistence;
- PNC.Factions.Save / PNC.Communities.Save;
- PNC_GroupGenerationPlan / PNC_SettlementGenerationPlan;
- PNC.PopulationIdentity / PNC_PopulationIdentity.

The retired PNC root literals occur only in PNC_SurvivorWorldImportSource.lua.

DynamicTrading active production/tests contain no references to the retired trader-world migration module/name or the removed Hoomans world/policy names. Retired DT schema aliases occur only in DTCommon_PreSurvivorWorldImport.lua.

## Validation

PsychopatzCore:

- full Lua sweep: **141/148**;
- the same seven unrelated baseline failures remain;
- SurvivorWorld generation smoke passes, including caller-supplied existing-member groups;
- changed production Lua: **1/1 luac**.

ProjectHoomans:

- full suite: **995/1000**;
- the same five unrelated semantic/harness baseline failures remain;
- focused cutover, save-authority, population, composition and MP-loader regressions pass;
- changed production Lua: **103/103 luac**.

DynamicTrading:

- full suite: **62/62**;
- standalone Hoomans bridge harness: **78/78**;
- focused pre-SurvivorWorld import/policy regressions pass;
- changed production Lua: **6/6 luac**.

All three repositories pass git diff --check.

Native testing subsequently exposed a Kahlua-incompatible `next()` call in the Core generation profile normalizer and `next()` uses in eight native acceptance fixtures. The production call and native fixtures were replaced with Kahlua-safe iteration/`ModDataStore.IsEmpty` checks. A complete post-fix `pz_verify.py --kahlua` sweep over every surviving S11 production Lua file plus the eight affected native fixtures passed **121/121 with 0 errors**. The same audit also found and fixed one sandboxed `os.time()` fallback in `DTCommon_CoreActorPolicy.lua`.

The same native run exposed two transport/logging defects. `PsychopatzMoneyBundlerServer.lua` logged every command in the shared `PsychopatzCore` command module before checking whether it was a money command, so normal `ActorProjectionRequest` traffic appeared as MoneyBundler spam. The handler now logs only `BundleMoney`/`UnbundleMoney`. `PsychopatzSurvivorWorldClient.lua` also duplicated ActorProjectionClient's startup projection request; its startup hook now owns discovery bootstrap only. Focused money-bundler and SurvivorWorld transport smokes cover both regressions.

## Completion boundary

S11 strengthens the already accepted developer architecture. No additional developer implementation is required by the SurvivorWorld roadmap at this point.

The remaining release gate is still the user-owned native N1–N6 matrix in S10_CROSS_REPOSITORY_ACCEPTANCE.md.
