local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
local ROOT_42 = T.layerRoot("runtime_shared")
package.path = ROOT .. "?.lua;" .. ROOT_42 .. "?.lua;" .. package.path

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
    get = function(key)
        return modDataStore[key]
    end,
    transmit = function() end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
isServer = function() return true end
isClient = function() return false end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"
local Persistence = Actors.Persistence
local RuntimeStore = Actors.RuntimeStore
local corePolicyReg = require "PsychopatzCore/SocialPolicy/Registry"
Actors.SocialPolicy.RegisterRegistry(corePolicyReg)

local startClock = os.clock()
local reg = Actors.NewRegistry()
local zeroEdgeCount = 800
local socialActorCount = 80
local abstractTraderCount = 120
local totalExpected = zeroEdgeCount + socialActorCount + abstractTraderCount
local compactOmittedCount = 0

-- 1. Build 800 zero-edge actors and prove compact persistence omits payload.social
for i = 1, zeroEdgeCount do
    local id = "actor:scale:zero:" .. i
    local actor = assert(reg:Create({
        actorId = id,
        identitySeed = "zero-" .. i,
        providerLease = { leaseID = "lease:z:" .. i, provider = "PsychopatzCore", owner = "PsychopatzCore", state = "abstract" },
    }))
    local encoded = assert(Persistence.EncodeActor(actor))
    if encoded.social == nil then
        compactOmittedCount = compactOmittedCount + 1
    end
end
equal(compactOmittedCount, zeroEdgeCount, "all 800 zero-edge actors omit payload.social")

-- 2. Build 80 general social actors with sparse edges + 120 abstract traders
local targetPlayer = "player:sp_slot_1:char_scale"
for i = 1, socialActorCount do
    local s = Social.NewState({ personality = { sociability = 0.65, forgiveness = 0.55 } })
    s = assert(Social.RecordAuthorizedEvent(s, {
        targetKey = targetPlayer,
        eventID = "ev:scale:soc:" .. i,
        type = "social.assistance",
        policy = corePolicyReg.Resolve("social.assistance"),
        createdAt = 100 + i,
        worldAgeHours = 100 + i,
        authority = "server",
        authorized = true,
    }))
    assert(reg:Create({
        actorId = "actor:scale:soc:" .. i,
        identitySeed = "soc-" .. i,
        social = s,
    }))
end

for i = 1, abstractTraderCount do
    local s = Social.NewState({ personality = { greed = 0.4, sociability = 0.7 } })
    s = assert(Social.RecordAuthorizedEvent(s, {
        targetKey = targetPlayer,
        eventID = "ev:scale:dt:" .. i,
        type = "commercial_trade",
        retentionClass = Retention.LONG,
        consolidationFamily = "dt:trade:routine",
        maxConsolidatedApproval = 15,
        maxConsolidatedFamiliarity = 25,
        approvalDelta = 2,
        familiarityDelta = 2,
        salience = 105,
        createdAt = 200 + i,
        worldAgeHours = 200 + i,
        authority = "server",
        authorized = true,
    }))
    assert(reg:Create({
        actorId = "actor:scale:trader:" .. i,
        identitySeed = "tr-" .. i,
        providerLease = { leaseID = "lease:tr:" .. i, provider = "DTAbstract", owner = "dtcommon:trader_world", state = "abstract" },
        social = s,
    }))
end

equal(reg:Count(), totalExpected, "registry holds 1000 actors cleanly")

-- 3. Stress 500 repeated same-pair events across SCENE + 2 consolidation families
local stressState = Social.NewState({ personality = { greed = 0.2, sociability = 0.8 } })
for i = 1, 250 do
    stressState = assert(Social.RecordAuthorizedEvent(stressState, {
        targetKey = targetPlayer,
        eventID = "ev:stress:routine:" .. i,
        type = "commercial_trade",
        retentionClass = Retention.LONG,
        consolidationFamily = "dt:trade:routine",
        maxConsolidatedApproval = 15,
        maxConsolidatedFamiliarity = 25,
        approvalDelta = 1,
        familiarityDelta = 1,
        salience = 105,
        createdAt = 500 + i,
        worldAgeHours = 500 + i,
        authority = "server",
        authorized = true,
    }))
end
for i = 1, 150 do
    stressState = assert(Social.RecordAuthorizedEvent(stressState, {
        targetKey = targetPlayer,
        eventID = "ev:stress:scene:" .. i,
        type = "social.greeting",
        retentionClass = Retention.SCENE,
        approvalDelta = 0,
        familiarityDelta = 1,
        createdAt = 800 + i,
        worldAgeHours = 800 + i,
        authority = "server",
        authorized = true,
    }))
end
for i = 1, 100 do
    stressState = assert(Social.RecordAuthorizedEvent(stressState, {
        targetKey = targetPlayer,
        eventID = "ev:stress:high:" .. i,
        type = "trade.fair_high_value",
        retentionClass = Retention.LONG,
        consolidationFamily = "dt:trade:high_value",
        maxConsolidatedApproval = 25,
        maxConsolidatedRespect = 15,
        maxConsolidatedFamiliarity = 25,
        approvalDelta = 2,
        respectDelta = 1,
        familiarityDelta = 2,
        salience = 145,
        createdAt = 1000 + i,
        worldAgeHours = 1000 + i,
        authority = "server",
        authorized = true,
    }))
end

local stressRel = assert(Social.Get(stressState, targetPlayer))
truthy(#stressRel.memories <= Retention.MAX_MEMORIES and #stressRel.memories == 2,
    "500 repeated same-pair events collapse cleanly into 2 consolidated memory slots")
local stressProj = assert(Social.QueryCandidateProjection(stressState, targetPlayer, { worldAgeHours = 1100 }))
equal(stressProj.consolidatedEpisodeCount, 350, "consolidatedEpisodeCount tracks 250 + 100 persistent episodes")

-- 4. Bucket caps (SHORT <= 24, LONG <= 56, ANCHOR <= 16, total <= 96) + 365-day lazy decay
local bucketState = Social.NewState()
for i = 1, 30 do
    bucketState = assert(Social.RecordAuthorizedEvent(bucketState, {
        targetKey = targetPlayer,
        eventID = "ev:bucket:short:" .. i,
        type = "minor_sparring",
        retentionClass = Retention.SHORT,
        salience = 90 + (i % 10),
        decayPerDay = 1.0,
        approvalDelta = 1,
        createdAt = 100,
        worldAgeHours = 100,
        authority = "server",
        authorized = true,
    }))
end
for i = 1, 65 do
    bucketState = assert(Social.RecordAuthorizedEvent(bucketState, {
        targetKey = targetPlayer,
        eventID = "ev:bucket:long:" .. i,
        type = "long_note_" .. i,
        retentionClass = Retention.LONG,
        salience = 100 + (i % 20),
        decayPerDay = 0.05,
        approvalDelta = 1,
        createdAt = 100,
        worldAgeHours = 100,
        authority = "server",
        authorized = true,
    }))
end
for i = 1, 20 do
    bucketState = assert(Social.RecordAuthorizedEvent(bucketState, {
        targetKey = targetPlayer,
        eventID = "ev:bucket:anchor:" .. i,
        type = "anchor_milestone_" .. i,
        retentionClass = Retention.ANCHOR,
        salience = 190 + i * 2,
        approvalDelta = -3,
        respectDelta = -1,
        createdAt = 100,
        worldAgeHours = 100,
        authority = "server",
        authorized = true,
    }))
end

local bucketRel = assert(Social.Get(bucketState, targetPlayer))
local nAnchor, nShort, nLong = 0, 0, 0
for _, mem in ipairs(bucketRel.memories or {}) do
    local cls = Retention.EffectiveClass(mem)
    if cls == Retention.ANCHOR then
        nAnchor = nAnchor + 1
    elseif cls == Retention.SHORT then
        nShort = nShort + 1
    else
        nLong = nLong + 1
    end
end
truthy(#bucketRel.memories <= Retention.MAX_ACTOR_MEMORIES, "total memories never exceed MAX_ACTOR_MEMORIES (96)")
truthy(#bucketState.memoryBank <= Retention.MAX_ACTOR_MEMORIES, "actor memoryBank never exceeds 96")
equal(bucketState.relationships[targetPlayer].memories, nil, "stored relationship omits embedded memories")
truthy(nAnchor <= Retention.MAX_ANCHOR_MEMORIES, "anchor memories never exceed MAX_ANCHOR_MEMORIES (16)")
truthy(nShort <= Retention.MAX_SHORT_MEMORIES, "short memories never exceed MAX_SHORT_MEMORIES (24)")
truthy(nLong <= Retention.MAX_LONG_MEMORIES, "long memories never exceed MAX_LONG_MEMORIES (56)")

local multiContact = Social.NewState()
for c = 1, 30 do
    local ck = "npc:scale:c" .. c
    for e = 1, 5 do
        multiContact = assert(Social.RecordAuthorizedEvent(multiContact, {
            targetKey = ck,
            eventID = string.format("ev:mc:%d:%d", c, e),
            type = "mc_event_" .. e,
            retentionClass = Retention.LONG,
            approvalDelta = 1,
            createdAt = 100 + e,
            authority = "server",
            authorized = true,
        }))
    end
end
truthy(#multiContact.memoryBank <= Retention.MAX_ACTOR_MEMORIES,
    "multi-contact memoryBank stays capped at MAX_ACTOR_MEMORIES (96) across 150 distinct events")

-- Advance 365 days lazily without any per-tick loop
local yearLaterHours = 100 + (365 * 24)
local yearProj = assert(Social.QueryCandidateProjection(bucketState, targetPlayer, { worldAgeHours = yearLaterHours }))
equal(yearProj.activeMemoryCount, nAnchor, "365-day lazy decay expires all SHORT/LONG while retaining ANCHOR")
local prunedRel = assert(Social.RecalculateRelationship(bucketState, targetPlayer, yearLaterHours))
equal(#prunedRel.memories, nAnchor, "RecalculateRelationship prunes expired SHORT/LONG cleanly")

-- 5. Compiled policy observer fanout cap <= 8 & hearsay attenuation check
for eventID, spec in pairs(corePolicyReg.events or {}) do
    if type(spec.maxObservers) == "number" then
        truthy(spec.maxObservers <= 8, "compiled policy observer cap bounded <= 8 for " .. eventID)
    end
end
local directState = Social.NewState()
directState = assert(Social.RecordAuthorizedEvent(directState, {
    targetKey = targetPlayer,
    eventID = "ev:prov:direct",
    type = "betrayal",
    retentionClass = Retention.LONG,
    approvalDelta = -20,
    createdAt = 100,
    sourceMode = "direct",
    authority = "server",
    authorized = true,
}))
local hearsayState = Social.NewState()
hearsayState = assert(Social.RecordAuthorizedEvent(hearsayState, {
    targetKey = targetPlayer,
    eventID = "ev:prov:hearsay",
    type = "betrayal",
    retentionClass = Retention.LONG,
    approvalDelta = -20,
    createdAt = 100,
    sourceMode = "hearsay",
    authority = "server",
    authorized = true,
}))
local directProj = assert(Social.QueryCandidateProjection(directState, targetPlayer, { worldAgeHours = 100 }))
local hearsayProj = assert(Social.QueryCandidateProjection(hearsayState, targetPlayer, { worldAgeHours = 100 }))
truthy(hearsayProj.grievanceScore < directProj.grievanceScore, "hearsay attenuates grievanceScore relative to direct witness")
equal(hearsayProj.hearsayEvidenceCount, 1, "hearsay provenance counted explicitly")

-- 6. RuntimeStore 30KB chunked save/load round-trip across all 1000 actors
RuntimeStore.Attach(reg)
local savedOk, savedErr = RuntimeStore.Save()
truthy(savedOk, savedErr)
local rootData = assert(ModData.get(RuntimeStore.STORAGE_KEY))
truthy(type(rootData.registryChunks) == "table" and #rootData.registryChunks >= 2,
    "1000-actor registry splits into multiple 30KB ModData chunks")
for idx, chunk in ipairs(rootData.registryChunks) do
    truthy(#chunk <= RuntimeStore.MAX_STRING_BYTES, "chunk " .. idx .. " obeys 30KB UTF byte margin")
end

local freshReg = Actors.NewRegistry()
RuntimeStore.Attach(freshReg)
local loadedOk, loadedErr = RuntimeStore.Load(false)
truthy(loadedOk, loadedErr)
equal(freshReg:Count(), totalExpected, "chunked Load restores all 1000 actors")
local sampleTrader = assert(freshReg:Get("actor:scale:trader:120"))
equal(sampleTrader.providerLease.provider, "DTAbstract", "reloaded abstract trader keeps DTAbstract lease")
local sampleProj = assert(Social.QueryCandidateProjection(sampleTrader.social, targetPlayer, { worldAgeHours = 320 }))
equal(sampleProj.exists, true, "reloaded abstract trader preserves social projection")

local elapsedSec = os.clock() - startClock
print(string.format(
    "PASS psychopatz_social_scale_stress_smoke actors=%d chunks=%d elapsed=%.3fs",
    totalExpected, #rootData.registryChunks, elapsedSec
))
