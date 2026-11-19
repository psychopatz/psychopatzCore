local CORE_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CORE_42_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. CORE_42_ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local modDataStore = {}
ModData = {
    getOrCreate = function(key)
        modDataStore[key] = modDataStore[key] or {}
        return modDataStore[key]
    end,
    transmit = function() end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

local serverFlag = true
local clientFlag = false
isServer = function() return serverFlag end
isClient = function() return clientFlag end

local worldHours = 100
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
    }
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Social = Actors.Social
local Authority = Actors.SocialAuthority
local PlayerIdentity = Actors.PlayerIdentity
local Projection = Actors.Projection
local Provider = Actors.Provider
local SocialPolicy = Actors.SocialPolicy
SocialPolicy.RegisterRegistry(require "PsychopatzCore/SocialPolicy/Registry")

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.RuntimeRole = RuntimeRole

-- =========================================================================
-- MATRIX 1: Core-only (PNC = nil, DTCommon = nil)
-- =========================================================================
equal(PNC, nil, "Matrix 1 requires PNC == nil")
equal(DTCommon, nil, "Matrix 1 requires DTCommon == nil")

local reg = Actors.NewRegistry()
Actors.DefaultRegistry = reg
Actors.RuntimeStore.Attach(reg)

local coreActor = assert(reg:Create({
    actorId = "actor:p7:core_only",
    identitySeed = "p7-core-only",
    world = { mode = "anchor", anchor = { x = 1000, y = 2000, z = 0 } },
    providerLease = { leaseID = "lease:p7:core", provider = "PsychopatzCore", owner = "PsychopatzCore", state = "abstract" },
}))
local initialRevision = coreActor.revision
equal(initialRevision, 1, "initial core actor revision is 1")

-- Pure client rejects every authoritative social mutation
serverFlag = false
clientFlag = true
equal(RuntimeRole.AllowsServerCode(), false, "pure client disallows server social authority")

local mutRes, mutReason = Authority.RecordAuthorizedEvent(coreActor.actorId, {
    targetKey = "player:acc:char_1",
    eventID = "ev:p7:client_attempt",
    type = "favor",
    approvalDelta = 10,
    authority = "server",
    authorized = true,
}, PsychopatzCore, coreActor.revision)
equal(mutRes, nil, "client RecordAuthorizedEvent rejected")
equal(mutReason, "server_authority_required", "client RecordAuthorizedEvent rejection reason")

local patchRes, patchReason = Authority.SetPersonality(coreActor.actorId, { greed = 0.9 }, PsychopatzCore, coreActor.revision)
equal(patchRes, nil, "client SetPersonality rejected")
equal(patchReason, "server_authority_required", "client SetPersonality reason")

local extRes, extReason = Authority.SetExtension(coreActor.actorId, "player:acc:char_1", "Ext", { flag = true }, PsychopatzCore, coreActor.revision)
equal(extRes, nil, "client SetExtension rejected")
equal(extReason, "server_authority_required", "client SetExtension reason")

local migRes, migReason = Authority.MigrateAliases(coreActor.actorId, "player:acc:char_1", { "player:legacy" }, PsychopatzCore, coreActor.revision)
equal(migRes, nil, "client MigrateAliases rejected")
equal(migReason, "server_authority_required", "client MigrateAliases reason")

local afterClientGet = assert(reg:Get(coreActor.actorId))
equal(afterClientGet.revision, initialRevision, "rejected client mutations do not advance actor revision")
equal(afterClientGet.social.revision, 0, "rejected client mutations do not advance social revision")

-- Server authorized event commit + replay idempotency + private-state projection omission
serverFlag = true
clientFlag = false
local committedCore = assert(Authority.RecordAuthorizedEvent(coreActor.actorId, {
    targetKey = "player:acc:char_1",
    eventID = "ev:p7:core:1",
    type = "favor",
    approvalDelta = 8,
    respectDelta = 4,
    familiarityDelta = 3,
    createdAt = worldHours,
    worldAgeHours = worldHours,
    authority = "server",
    authorized = true,
}, PsychopatzCore, afterClientGet.revision))

local revAfterFirst = committedCore.social.revision
truthy(revAfterFirst >= 1, "server authorized commit increments social revision")

local replayRes, replayReason = Authority.RecordAuthorizedEvent(committedCore.actorId, {
    targetKey = "player:acc:char_1",
    eventID = "ev:p7:core:1",
    type = "favor",
    approvalDelta = 8,
    createdAt = worldHours,
    authority = "server",
    authorized = true,
}, PsychopatzCore, committedCore.revision)
equal(replayRes, nil, "replayed eventID rejected")
equal(replayReason, "duplicate_event", "replayed eventID reason")

local projected = assert(Projection.ProjectActor(committedCore, worldHours, { position = { x = 1000, y = 2000, z = 0 } }))
equal(projected.actorID, coreActor.actorId, "client projection keeps canonical actorID")
equal(projected.social, nil, "client actor projection omits private social graph")
equal(projected.relationships, nil, "client actor projection omits raw relationships")
equal(projected.memories, nil, "client actor projection omits raw memories")

-- =========================================================================
-- MATRIX 2: Core + DTCommon + DTAbstract (PNC = nil)
-- =========================================================================
local DT_COMMON_SHARED = "../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/"
local DT_COMMON_COMMON = "../DynamicTrading/Contents/mods/DTCommon/common/media/lua/shared/"
local DT_HOOMANS_SERVER = "../DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/server/"
package.path = DT_COMMON_COMMON .. "?.lua;" .. DT_COMMON_SHARED .. "?.lua;" .. DT_HOOMANS_SERVER .. "?.lua;" .. package.path

local dtPolicyReg = require "DTCommon/SocialPolicy/Registry"
SocialPolicy.RegisterRegistry(dtPolicyReg)

local function dtFile(rel)
    return "../DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/" .. rel
end
dofile(dtFile("DTCommon/00_DTCommon_Init.lua"))
dofile(dtFile("DTCommon/DTCommon_Storage.lua"))
dofile(dtFile("DTCommon/DTCommon_TraderSupport.lua"))
dofile(dtFile("DTCommon/DTCommon_TraderStock.lua"))
dofile(dtFile("DTCommon/DTCommon_CoreActorPolicy.lua"))
dofile(dtFile("DTCommon/DTCommon_MarketPricing.lua"))
dofile(dtFile("DTCommon/DTCommon_TraderRegistry.lua"))

equal(PNC, nil, "Matrix 2 keeps PNC == nil")

local mpPlayerModData = { PNC_CharacterUUID = "char_mp_p7" }
PlayerIdentity.RegisterIssuedIdentity("char_mp_p7", "SurvivorP7", { source = "p7_matrix" })
local mpPlayer = {
    getUsername = function() return "SurvivorP7" end,
    getOnlineID = function() return 41 end,
    getModData = function() return mpPlayerModData end,
}
local canonicalPlayerKey = assert(PlayerIdentity.GetTargetKey(mpPlayer))

local sharedTraderActor = assert(reg:Create({
    actorId = "actor:p7:shared_trader",
    identitySeed = "p7-shared-trader",
    world = { mode = "anchor", anchor = { x = 1500, y = 2500, z = 0 } },
    providerLease = {
        leaseID = "lease:p7:shared_trader",
        provider = "DTAbstract",
        owner = "dtcommon:trader_world",
        state = "abstract",
    },
    social = Social.NewState({ personality = { greed = 0.25, sociability = 0.8, forgiveness = 0.7 } }),
}))

local traderID, traderRec = DTCommon.TraderService.Create({
    traderID = "trader:p7:shared",
    displayName = "Morgan P7",
    archetype = "General",
    stock = { ["Base.WaterBottle"] = 4 },
    budget = 250,
    actorID = sharedTraderActor.actorId,
    provider = "DTAbstract",
    providerState = "abstract",
    abstractAccessEnabled = true,
})
truthy(traderID == "trader:p7:shared" and traderRec, "DT trader created with canonical Core actorID")
traderRec.ca = traderRec.ca or {}
traderRec.ca.returnProviderID = "DTAbstract"

-- Pure client cannot emit trade social event
serverFlag = false
clientFlag = true
local dtClientRes, dtClientReason = DTCommon.CoreActorPolicy.RecordTradeEvent(traderRec, mpPlayer, {
    requestID = "p7-client-forged",
    totalValue = 120,
})
equal(dtClientRes, nil, "DT trade social mutation rejected on pure client")
equal(dtClientReason, "server_authority_required", "DT client rejection preserves server_authority_required")

-- Server records remote abstract radio trade while PNC == nil
serverFlag = true
clientFlag = false
local sAfterTrade1 = assert(DTCommon.CoreActorPolicy.RecordTradeEvent(traderRec, mpPlayer, {
    requestID = "p7-dt-1",
    totalValue = 220,
    createdAt = worldHours,
}))
local dtReplay, dtReplayReason = DTCommon.CoreActorPolicy.RecordTradeEvent(traderRec, mpPlayer, {
    requestID = "p7-dt-1",
    totalValue = 220,
    createdAt = worldHours,
})
equal(dtReplay, nil, "DT trade requestID replay rejected")
equal(dtReplayReason, "duplicate_event", "DT trade replay reason")

local priceCtxDT = DTCommon.MarketPricing.BuildContext(traderRec, mpPlayer)
truthy(priceCtxDT.relationshipRevision >= 1, "DT Pricing.BuildContext reflects server-recorded Core social revision")
truthy(priceCtxDT.totalTrades == 1, "DT Pricing.BuildContext sees exact trade count without PNC")

-- =========================================================================
-- MATRIX 3: Core + Project Hoomans reconnect & alias convergence
-- =========================================================================
local savedDT = DTCommon
DTCommon = nil

local PNC_SHARED = "../ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local PNC_COMMON = "../ProjectHoomans/Contents/mods/ProjectHoomans/common/media/lua/shared/"
package.path = PNC_COMMON .. "?.lua;" .. PNC_SHARED .. "?.lua;" .. package.path

SocialPolicy.RegisterRegistry(require "PNC/SocialPolicy/Registry")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_EntityRef.lua")
dofile(PNC_SHARED .. "PNC/Core/Relationships/PNC_RelationshipMath.lua")
dofile(PNC_SHARED .. "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")

local reconnectActor = assert(reg:Create({
    actorId = "actor:p7:hoomans_reconnect",
    identitySeed = "p7-reconnect",
    social = Social.NewState({
        relationships = {
            ["player:online:41"] = {
                approval = 14,
                respect = 6,
                familiarity = 9,
                revision = 2,
                memories = {
                    {
                        id = "mem:p7:legacy",
                        type = "treated_wound",
                        retentionClass = Social.RETENTION_LONG,
                        salience = 150,
                        createdAt = 50,
                        approvalEffect = 5,
                        respectEffect = 2,
                    },
                },
            },
        },
    }),
}))

-- Player reconnects with new onlineID = 88 while retaining issued char_mp_p7 UUID
local reconnectedPlayer = {
    getUsername = function() return "SurvivorP7" end,
    getOnlineID = function() return 88 end,
    getModData = function() return mpPlayerModData end,
}
local reconnectKey = assert(PlayerIdentity.GetTargetKey(reconnectedPlayer))
equal(reconnectKey, canonicalPlayerKey, "reconnect resolves same canonical UUID target key despite onlineID change")

local migratedActor = assert(Authority.MigrateAliases(
    reconnectActor.actorId,
    reconnectKey,
    { "player:online:41", "player:user:SurvivorP7", "player:online:88" },
    PsychopatzCore,
    reconnectActor.revision
))
local mergedRel = assert(Social.Get(migratedActor.social, reconnectKey))
equal(mergedRel.approval, 14, "legacy onlineID relationship approval preserved across reconnect")
equal(migratedActor.social.relationships["player:online:41"], nil, "legacy onlineID raw slot removed after convergence")
equal(migratedActor.social.aliases["player:online:41"], reconnectKey, "legacy onlineID aliased to canonical target key")
equal(Social.Get(migratedActor.social, "player:online:41").targetKey, reconnectKey, "Social.Get transparently resolves alias to canonical relationship")
equal(#mergedRel.memories, 1, "legacy memory migrated once without duplication")

-- =========================================================================
-- MATRIX 4: Combined Core + ProjectHoomans + DTCommon + DTAbstract + DTHoomans
-- =========================================================================
DTCommon = savedDT
dofile("../DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_ProviderRuntime.lua")

local hoomansRecords = {}
PNC.Registry = {
    Get = function(id) return hoomansRecords[id] end,
    AddRecord = function(rec)
        hoomansRecords[rec.id or rec.coreActorID] = rec
        return true
    end,
    GetLiveZombie = function() return nil end,
    MarkDirty = function() end,
}
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

-- Transition trader: DTAbstract -> DTHoomans (materialized)
worldHours = worldHours + 2
local preMatActor = assert(reg:Get(sharedTraderActor.actorId))
local revBeforeMat = preMatActor.social.revision
local switchedToHoomans = assert(Provider.Switch(preMatActor, {
    provider = "DTHoomans",
    owner = "dthoomans:runtime",
    handoffFrom = "dtcommon:trader_world",
    now = worldHours,
}))
local materializedActor = assert(Provider.Materialize(switchedToHoomans, {
    provider = "DTHoomans",
    owner = "dthoomans:runtime",
    bodyID = "zombie:p7:trader",
    now = worldHours,
}))
local committedMat = assert(reg:Commit(sharedTraderActor.actorId, {
    providerLease = materializedActor.providerLease,
}, preMatActor.revision))
equal(committedMat.actorId, "actor:p7:shared_trader", "canonical actorId preserved across materialization")

-- Materialize Hoomans view of actor social and add a Hoomans event
hoomansRecords[committedMat.actorId] = {
    id = committedMat.actorId,
    coreActorID = committedMat.actorId,
    social = PNC.Persistence.CoreSocial.FromCoreSocial(committedMat.social),
}
local hRel = hoomansRecords[committedMat.actorId].social.relationships[canonicalPlayerKey]
truthy(hRel ~= nil, "materialized Hoomans record sees DTAbstract trade relationship")
hRel.approval = hRel.approval + 6
hRel.respect = hRel.respect + 4
hRel.memories[#hRel.memories + 1] = {
    id = "hoomans:p7:escort",
    eventID = "hoomans:p7:escort",
    type = "treated_wound",
    retentionClass = Social.RETENTION_LONG,
    salience = 160,
    createdAt = worldHours,
    approvalEffect = 6,
    respectEffect = 4,
    strength = 1.0,
}
hRel.revision = (tonumber(hRel.revision) or 0) + 1
hoomansRecords[committedMat.actorId].social.recentEventIDs = hoomansRecords[committedMat.actorId].social.recentEventIDs or {}
hoomansRecords[committedMat.actorId].social.recentEventIDs[#hoomansRecords[committedMat.actorId].social.recentEventIDs + 1] = "hoomans:p7:escort"

-- Dematerialize back to DTAbstract via DTHoomans.ProviderRuntime (triggers PNC.Persistence.CoreSocial.SyncToCore)
worldHours = worldHours + 2
local dematResult, dematErr = DTHoomans.ProviderRuntime.DematerializeTrader(traderID, {
    returnProviderID = "DTAbstract",
    now = worldHours,
})
truthy(dematResult, dematErr)

local afterDematActor = assert(reg:Get(sharedTraderActor.actorId))
equal(afterDematActor.actorId, "actor:p7:shared_trader", "canonical actorId preserved across dematerialization")
equal(afterDematActor.providerLease.provider, "DTAbstract", "providerLease returned cleanly to DTAbstract")
truthy(afterDematActor.social.revision > revBeforeMat, "social.revision strictly advanced after Hoomans->DTAbstract dematerialization")

-- Record another abstract radio trade after dematerialization
worldHours = worldHours + 1
local afterPostDematSocial = assert(DTCommon.CoreActorPolicy.RecordTradeEvent(traderRec, mpPlayer, {
    requestID = "p7-dt-2",
    totalValue = 180,
    createdAt = worldHours,
}))
local finalActor = assert(reg:Get(sharedTraderActor.actorId))
truthy(finalActor.social.revision > afterDematActor.social.revision, "post-dematerialization trade increments social.revision monotonically")

local finalRel = assert(Social.Get(afterPostDematSocial, canonicalPlayerKey))
truthy(finalRel.extensions and finalRel.extensions.DynamicTrading
    and finalRel.extensions.DynamicTrading.totalTrades == 2,
    "DynamicTrading totalTrades preserved accurately across DTAbstract -> DTHoomans -> DTAbstract")

local foundDT, foundHoomans = false, false
for _, mem in ipairs(finalRel.memories or {}) do
    if mem.type == "trade.fair_high_value" or mem.id == "dt:trade:p7-dt-1" or mem.lastEventID == "dt:trade:p7-dt-2" then
        foundDT = true
    end
    if mem.id == "hoomans:p7:escort" then
        foundHoomans = true
    end
end
truthy(foundDT and foundHoomans, "both DT and Hoomans memories coexist on the same Core relationship after full round-trip")

-- Save and reload registry preserves everything identically
local savedBlob = assert(reg:Save())
local reloadedReg = Actors.NewRegistry()
local loadOk, loadReason = reloadedReg:Load(savedBlob)
truthy(loadOk, loadReason)
local reloadedActor = assert(reloadedReg:Get(sharedTraderActor.actorId))
equal(reloadedActor.social.revision, finalActor.social.revision, "reloaded social revision matches saved state")
local reloadedRel = assert(Social.Get(reloadedActor.social, canonicalPlayerKey))
equal(reloadedRel.extensions.DynamicTrading.totalTrades, 2, "reloaded DynamicTrading extension preserved")
equal(reloadedRel.approval, finalRel.approval, "reloaded combined approval preserved")

PNC = nil
DTCommon = nil
DTHoomans = nil

print("PASS psychopatz_social_mp_continuity_matrix_smoke")
