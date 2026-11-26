local T = require "tests/support/test"
T.addPackagePaths()

local CORE_COMMON = T.layerRoot("common_shared")
local CORE_42 = T.layerRoot("runtime_shared")
local HOOMANS_REPO = os.getenv("PZ_TEST_HOOMANS_REPOSITORY") or "../ProjectHoomans"
local DT_REPO = os.getenv("PZ_TEST_DT_REPOSITORY") or "../DynamicTrading"

local PNC_SHARED = HOOMANS_REPO .. "/Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local PNC_COMMON = HOOMANS_REPO .. "/Contents/mods/ProjectHoomans/common/media/lua/shared/"
local PNC_SERVER = HOOMANS_REPO .. "/Contents/mods/ProjectHoomans/42.20/media/lua/server/"
local DT_SHARED = DT_REPO .. "/Contents/mods/DTCommon/42.20/media/lua/shared/"
local DT_COMMON = DT_REPO .. "/Contents/mods/DTCommon/common/media/lua/shared/"
local DT_HOOMANS_SERVER = DT_REPO .. "/Contents/mods/DTHoomans/42.20/media/lua/server/"

package.path = CORE_COMMON .. "?.lua;"
    .. CORE_42 .. "?.lua;"
    .. PNC_COMMON .. "?.lua;"
    .. PNC_SHARED .. "?.lua;"
    .. PNC_SERVER .. "?.lua;"
    .. DT_COMMON .. "?.lua;"
    .. DT_SHARED .. "?.lua;"
    .. DT_HOOMANS_SERVER .. "?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function countOccurrences(haystack, needle)
    local count = 0
    local startIdx = 1
    while true do
        local pos = string.find(haystack, needle, startIdx, true)
        if not pos then break end
        count = count + 1
        startIdx = pos + #needle
    end
    return count
end

local modDataStore = {}
ModData = {
    getOrCreate = function(key)
        modDataStore[key] = modDataStore[key] or {}
        return modDataStore[key]
    end,
    get = function(key) return modDataStore[key] end,
    transmit = function() end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
isServer = function() return true end
isClient = function() return false end

local worldHours = 200
getGameTime = function()
    return {
        getYear = function() return 1993 end,
        getMonth = function() return 7 end,
        getDay = function() return 15 end,
        getWorldAgeHours = function() return worldHours end,
    }
end
getTimeInMillis = function() return math.floor(worldHours * 3600000) end
ZombRand = function(maxVal)
    return math.max(0, math.floor((tonumber(maxVal) or 1) / 2))
end

-- Core dependencies
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local PlayerIdentity = Actors.PlayerIdentity
local SocialPolicy = Actors.SocialPolicy
local Provider = Actors.Provider

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.RuntimeRole = RuntimeRole
SocialPolicy.RegisterRegistry(require "PsychopatzCore/SocialPolicy/Registry")

-- ProjectHoomans dependencies
PNC = {
    Translation = {
        GetKey = function(_, fallback) return fallback or "" end,
        TrFormat = function(_, fallback) return fallback or "" end,
    },
}
dofile(PNC_SHARED .. "PNC/Core/Base/PNC_Core.lua")
dofile(PNC_SHARED .. "PNC/Core/Base/PNC_Constants.lua")
dofile(PNC_SHARED .. "PNC/Core/Identity/PNC_PlayerCharacterConstants.lua")
dofile(PNC_SHARED .. "PNC/Core/Identity/PNC_Identity.lua")
PNC.Identity.ApplyRecordIdentity = function(record, definition)
    record.identitySeed = tonumber(definition.identitySeed) or record.identitySeed or 42
    record.identity = definition.identity or record.identity or { seed = record.identitySeed, survivor = {} }
    record.name = definition.displayName or definition.name or record.id
    record.archetypeID = definition.archetypeID or "General"
    record.isFemale = definition.isFemale == true
end
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_EntityRef.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialProfileConstants.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialProfileTypes.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialTraits.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialProfileMath.lua")
dofile(PNC_SHARED .. "PNC/Core/Conduct/PNC_ConductConstants.lua")
dofile(PNC_SHARED .. "PNC/Core/Conduct/PNC_ConductTypes.lua")
dofile(PNC_SHARED .. "PNC/Core/Conduct/PNC_ConductMath.lua")
dofile(PNC_SHARED .. "PNC/Core/Conduct/PNC_ConductDefinitions.lua")
dofile(PNC_SHARED .. "PNC/Core/Identity/PNC_PlayerCharacterTypes.lua")
dofile(PNC_SHARED .. "PNC/Core/Travel/PNC_Travel.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipStates.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipMath.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipGraph.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipPresentation.lua")
dofile(PNC_SHARED .. "PNC/Core/Base/PNC_Types.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_Relationships.lua")
dofile(PNC_SHARED .. "PNC/Core/Persistence/PNC_Persistence.lua")

SocialPolicy.RegisterRegistry(require "PNC/SocialPolicy/Registry")
dofile(PNC_SHARED .. "PNC/ConvoEngine/Interaction/Relations.lua")
dofile(PNC_SHARED .. "PNC/ConvoEngine/Interaction/Evidence.lua")
dofile(PNC_SHARED .. "PNC/Conversation/Memory/PNC_ConversationMemory.lua")

local hoomansRecords = {}
PNC.Registry = {
    Data = hoomansRecords,
    Get = function(id) return hoomansRecords[tostring(id)] end,
    AddRecord = function(rec)
        hoomansRecords[tostring(rec.id)] = rec
        return true
    end,
    RemoveRecord = function(id)
        hoomansRecords[tostring(id)] = nil
        return true
    end,
    GetLiveZombie = function() return nil end,
    MarkDirty = function() end,
}

local Lifecycle = dofile(PNC_SHARED .. "PNC/ConvoEngine/Interaction/Lifecycle.lua")
local lifecycleStore = Lifecycle.New({ worldHour = worldHours })
PNC.Semantics = { InteractionLifecycle = Lifecycle }
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InteractionLifecyclePersistence = {
    RegisterSharedEvent = function(event) return Lifecycle.RegisterSharedEvent(lifecycleStore, event) end,
    Apply = function(envelope, options) return Lifecycle.Apply(lifecycleStore, envelope, options) end,
    RecordNPCSpeech = function(spec) return Lifecycle.RecordNPCSpeech(lifecycleStore, spec) end,
}

dofile(PNC_SERVER .. "PNC/Player/PNC_PlayerCharacterDebug.lua")
dofile(PNC_SERVER .. "PNC/Player/PNC_PlayerCharacterService.lua")
PNC.PlayerCharacters.Load()
dofile(PNC_SERVER .. "PNC/Social/PNC_ConductService.lua")
dofile(PNC_SERVER .. "PNC/Social/PNC_RelationshipService.lua")
dofile(PNC_SERVER .. "PNC/Social/PNC_SocialEventService.lua")

-- DynamicTrading dependencies
SocialPolicy.RegisterRegistry(require "DTCommon/SocialPolicy/Registry")
dofile(DT_SHARED .. "DTCommon/00_DTCommon_Init.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_Storage.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_TraderSupport.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_TraderStock.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_CoreActorPolicy.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_MarketPricing.lua")
dofile(DT_SHARED .. "DTCommon/DTCommon_TraderRegistry.lua")
dofile(DT_HOOMANS_SERVER .. "DTHoomans/DTHoomans_ProviderRuntime.lua")

-- 1. Setup canonical Core registry, player identity, and DTAbstract trader -> DTHoomans materialization
local reg = Actors.NewRegistry()
Actors.DefaultRegistry = reg

local playerModData = { PNC_CharacterUUID = "char_p10_proof" }
PlayerIdentity.RegisterIssuedIdentity("char_p10_proof", "SurvivorP10", { source = "p10_proof" })
local player = {
    getUsername = function() return "SurvivorP10" end,
    getOnlineID = function() return 17 end,
    getModData = function() return playerModData end,
}
local playerKey = assert(PlayerIdentity.GetTargetKey(player))
PNC.PlayerCharacters.EnsureIdentity(player, { worldAgeHours = worldHours })

local actorID = "actor_p10_combined_npc"
local coreActor = assert(reg:Create({
    actorId = actorID,
    identitySeed = "p10-combined-seed",
    world = { mode = "anchor", anchor = { x = 1200, y = 2400, z = 0 } },
    providerLease = {
        leaseID = "lease:p10:combined",
        provider = "DTAbstract",
        owner = "dtcommon:trader_world",
        state = "abstract",
    },
    social = Social.NewState({ personality = { greed = 0.25, sociability = 0.85, forgiveness = 0.7 } }),
}))

local traderID, traderRec = DTCommon.TraderService.Create({
    traderID = "trader:p10:combined",
    displayName = "Morgan P10",
    archetype = "General",
    stock = { ["Base.WaterBottle"] = 4 },
    budget = 250,
    actorID = actorID,
    provider = "DTAbstract",
    providerState = "abstract",
    abstractAccessEnabled = true,
})
truthy(traderID and traderRec, "DT trader created")
traderRec.ca.returnProviderID = "DTAbstract"

-- DTAbstract trade while abstract
local afterTradeSocial = assert(DTCommon.CoreActorPolicy.RecordTradeEvent(traderRec, player, {
    requestID = "p10-dt-trade-1",
    totalValue = 250,
    createdAt = worldHours,
}))

-- Transition DTAbstract -> DTHoomans and instantiate Hoomans NPC record backed by Core actor
local beforeSwitch = assert(reg:Get(actorID))
local switched = assert(Provider.Switch(beforeSwitch, {
    provider = "DTHoomans",
    owner = "dthoomans:runtime",
    handoffFrom = "dtcommon:trader_world",
    now = worldHours,
}))
local materialized = assert(Provider.Materialize(switched, {
    provider = "DTHoomans",
    owner = "dthoomans:runtime",
    bodyID = "zombie:p10:1",
    now = worldHours,
}))
assert(reg:Commit(actorID, { providerLease = materialized.providerLease }, beforeSwitch.revision))

local hoomansRecord = assert(PNC.Types.NewRecord({
    id = actorID,
    coreActorID = actorID,
    displayName = "Morgan P10",
    identitySeed = 731,
    archetypeID = "General",
    tacticalClass = "neutral",
    x = 1200,
    y = 2400,
    z = 0,
    equipment = { worn = {}, attached = {} },
}))
hoomansRecords[actorID] = hoomansRecord
PNC.Persistence.CoreSocial.SyncFromCore(hoomansRecord, PsychopatzCore)

-- Apply Hoomans baseline, SocialEvent (which updates Conduct + RelationshipService), durable bond, interaction, morale
worldHours = worldHours + 2
assert(PNC.Relationships.SetInitialBaseline(actorID, playerKey, { approval = 5, respect = 3 }, worldHours))

local emitResult = assert(PNC.SocialEvents.Emit({
    id = "social:p10:hoomans_treat",
    type = "treated_wound",
    actorKey = playerKey,
    targetKey = PNC.EntityRef.ForNPC(actorID),
    occurredAt = worldHours,
    sourceSystem = "wounds",
    context = {},
}))
truthy(emitResult and emitResult.ok, emitResult and emitResult.reason or "SocialEvents.Emit failed")
truthy((tonumber(emitResult.memoriesCreated) or 0) >= 1, "SocialEvents.Emit persisted relationship memory")

assert(PNC.Conduct.AddEvidence(PNC.EntityRef.ForNPC(actorID), {
    id = "conduct:p10:npc_helper",
    eventID = "social:p10:npc_helper",
    eventType = "treated_wound",
    actorKey = PNC.EntityRef.ForNPC(actorID),
    subjectKey = playerKey,
    createdAt = worldHours,
    lastEvaluatedAt = worldHours,
    effects = { generosity = 6 },
    strength = 1,
}))
assert(PNC.Relationships.SetDurableBond(actorID, playerKey, { class = "friend" }, worldHours, "relationship_milestone"))
assert(PNC.Relationships.RecordInteraction(actorID, playerKey, {
    eventID = "p10:conv:1",
    interactionType = "conversation",
    worldAgeHours = worldHours,
    applied = true,
}))
hoomansRecord.social.morale = 14
hoomansRecord.social.moraleBaseline = 3
assert(PNC.Persistence.CoreSocial.SyncToCore(hoomansRecord, PsychopatzCore))

-- 2. Serialize BOTH Core registry and Hoomans NPC record to JSON and verify single persistence
local coreSavedActor = assert(reg:Get(actorID))
local coreJson = assert(Actors.Persistence.SerializeRegistry({ coreSavedActor }, reg.revision))
local pncPayload = assert(PNC.Persistence.SerializeRecord(hoomansRecord))
local pncJson = assert(Json.Encode(pncPayload))

equal(pncPayload.social.authority, "core", "PNC payload social uses core authority envelope")
equal(pncPayload.social.relationships, nil, "PNC payload omits generic relationships")
equal(pncPayload.social.recentEventIDs, nil, "PNC payload omits generic recentEventIDs")
equal(pncPayload.social.personality, nil, "PNC payload omits generic personality")
equal(pncPayload.social.revision, nil, "PNC payload omits generic social revision")

-- Generic memory records appear in Core JSON ONLY, never in PNC JSON relationships/memories
local hoomansMemID = "memory:social:p10:hoomans_treat:" .. actorID .. ":target"
equal(countOccurrences(coreJson, "dt:trade:p10-dt-trade-1") >= 1, true, "DT memory persisted in Core JSON")
equal(countOccurrences(pncJson, "dt:trade:p10-dt-trade-1"), 0, "DT memory NOT persisted in PNC JSON")
equal(countOccurrences(coreJson, hoomansMemID) >= 1, true, "Hoomans memory persisted in Core JSON")
equal(countOccurrences(pncJson, "\"memories\":"), 0, "PNC JSON has no persisted memories array")
truthy(pncPayload.social.relationshipExtensions[playerKey].interactionJournal ~= nil,
    "PNC interactionJournal retained as Hoomans-owned extension")

-- Generic relationship storage keys appear in Core JSON only, 0 times in PNC JSON
for _, genericKey in ipairs({
    "\"baselineApproval\"",
    "\"baselineRespect\"",
    "\"approvalEffect\"",
    "\"respectEffect\"",
    "\"retentionClass\"",
    "\"consolidationKey\"",
    "\"knowledgeSource\"",
    "\"recentEventIDs\"",
}) do
    truthy(countOccurrences(coreJson, genericKey) >= 1, genericKey .. " persisted in Core JSON")
    equal(countOccurrences(pncJson, genericKey), 0, genericKey .. " NOT persisted in PNC JSON")
end

-- PNC-specific extensions survive in PNC JSON
equal(pncPayload.social.morale, 14, "PNC morale preserved")
equal(pncPayload.social.moraleBaseline, 3, "PNC moraleBaseline preserved")
truthy(pncPayload.social.conduct and #pncPayload.social.conduct.evidence >= 1, "PNC conduct evidence preserved")
equal(pncPayload.social.conduct.scores, nil, "derived conduct scores omitted from save")
equal(pncPayload.social.relationshipExtensions[playerKey].bond.class, "friend", "PNC bond preserved")
truthy(#pncPayload.social.relationshipExtensions[playerKey].interactionJournal >= 1,
    "PNC interactionJournal preserved")

-- 3. Reload into fresh Core + Hoomans registries (and verify stripped Core extension still reconstructs via PNC envelope)
local decodedCore = Json.Decode(coreJson, Actors.Persistence.REGISTRY_JSON_LIMITS)
decodedCore.actors[1].social.extensions.ProjectHoomans = nil
for _, rel in pairs(decodedCore.actors[1].social.relationships or {}) do
    if rel.extensions then rel.extensions.ProjectHoomans = nil end
end
local strippedCoreJson = assert(Json.Encode(decodedCore, Actors.Persistence.REGISTRY_JSON_LIMITS))

local freshReg = Actors.NewRegistry()
truthy(freshReg:Load(strippedCoreJson), "Fresh Core registry loads stripped Core save")
Actors.DefaultRegistry = freshReg

hoomansRecords[actorID] = nil
local reloadedHoomans = assert(PNC.Persistence.DeserializeRecord(pncPayload, actorID))
hoomansRecords[actorID] = reloadedHoomans

local reloadedRel = assert(PNC.Relationships.Get(actorID, playerKey))
equal(reloadedRel.baselineApproval, 5, "Reloaded baselineApproval matches Core")
equal(reloadedRel.bond.class, "friend", "Reloaded bond reconstructed from PNC extension")
truthy(#reloadedRel.interactionJournal >= 1, "Reloaded interactionJournal reconstructed from PNC extension")
truthy(#reloadedRel.memories >= 2, "Reloaded memories include both DT and Hoomans entries")
equal(reloadedHoomans.social.morale, 14, "Reloaded morale preserved")

local conductAfterReload = assert(PNC.Conduct.GetForEntity(playerKey))
truthy(conductAfterReload and #conductAfterReload.evidence >= 1, "Player conduct remains intact")

-- Presentation, semantic evidence, and DTAbstract dematerialization continuity
local pres = PNC.RelationshipPresentation.Summarize(reloadedRel, true)
equal(pres.exists, true, "Presentation summary works after reload")
equal(pres.approval, reloadedRel.approval, "Presentation approval matches Core")

local evidenceRows = PNC.Relationships.QuerySemanticEvidence(actorID, playerKey, actorID, worldHours + 1, {})
truthy(#evidenceRows >= 2, "Semantic evidence sees both DT and Hoomans Core memories after reload")

PNC.Persistence.CoreProvider = {
    Dematerialize = function(actor, _, options)
        local demat, dReason = Provider.Dematerialize(actor, {
            provider = options and options.provider or "DTHoomans",
            owner = options and options.owner or "dthoomans:runtime",
            now = options and options.now or worldHours,
        })
        if not demat then return nil, dReason end
        return { actor = demat }
    end,
}
local dematActor, dematErr = DTHoomans.ProviderRuntime.DematerializeTrader(traderID, {
    returnProviderID = "DTAbstract",
    now = worldHours + 1,
})
truthy(dematActor, dematErr)
local postDematRel = assert(Social.Get(assert(freshReg:Get(actorID)).social, playerKey))
truthy(#postDematRel.memories >= 2, "DTAbstract dematerialization preserves both DT and Hoomans social history")
truthy(postDematRel.extensions.DynamicTrading and postDematRel.extensions.DynamicTrading.totalTrades == 1,
    "DynamicTrading extension preserved across dematerialization")

equal(PNC.Persistence.CoreSocial.MigrateLegacyRecordToCore, nil,
    "retired legacy social migrator absent")

print("PASS psychopatz_social_single_persistence_authority_smoke")
