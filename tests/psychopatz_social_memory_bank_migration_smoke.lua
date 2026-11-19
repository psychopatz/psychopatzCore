local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function falsy(value, label)
    if value then error(label or "expected falsy") end
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
    EveryDays = { Add = function() end },
}

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"
local Authority = require "PsychopatzCore/Actors/PsychopatzActorSocialAuthority"
local GC = require "PsychopatzCore/Actors/PsychopatzActorGC"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

-- 1. Legacy v2 per-relationship migration (5 contacts x 30 = 150 memories -> bounded memoryBank)
local legacyRels = {}
for c = 1, 5 do
    local ck = "player:mig:char" .. c
    local mems = {}
    for m = 1, 30 do
        mems[m] = {
            id = string.format("legacy:%d:%d", c, m),
            type = "help_" .. m,
            retentionClass = "LONG",
            salience = 100 + (m % 20),
            approvalEffect = 2,
            respectEffect = 1,
            createdAt = 10 + m,
        }
    end
    legacyRels[ck] = {
        targetKey = ck,
        approval = 60,
        respect = 30,
        familiarity = 40,
        baselineApproval = 0,
        baselineRespect = 0,
        revision = 10,
        memories = mems,
    }
end

local seedReg = Actors.NewRegistry()
local seedActor = assert(seedReg:Create({
    actorId = "actor:l3:legacy_migrated",
    identitySeed = "l3-leg",
}))
local compactLegacyActor = assert(Persistence.EncodeActor(seedActor))
compactLegacyActor.social = {
    schemaVersion = 2,
    revision = 5,
    personality = { sociability = 0.7 },
    personalityOverrides = {},
    recentEventIDs = {},
    relationships = legacyRels,
    aliases = {},
    extensions = {},
}

local legacyWrapper = {
    schema = Persistence.SCHEMA,
    schemaVersion = Persistence.SCHEMA_VERSION_V2,
    revision = 3,
    actors = { compactLegacyActor },
    aliasMap = {},
    tombstones = {},
}
local legacyJson = assert(Json.Encode(legacyWrapper, Persistence.REGISTRY_JSON_LIMITS))
local migReg = Actors.NewRegistry()
local loadOk, loadReason = migReg:Load(legacyJson)
truthy(loadOk, "legacy v2 registry loads cleanly: " .. tostring(loadReason))

local migratedActor = assert(migReg:Get("actor:l3:legacy_migrated"))
equal(migratedActor.social.schemaVersion, Social.SCHEMA_VERSION, "social upgraded to schemaVersion 3")
truthy(type(migratedActor.social.memoryBank) == "table", "memoryBank populated")
truthy(#migratedActor.social.memoryBank <= Social.MAX_LONG_MEMORIES,
    "150 legacy LONG memories collapsed to MAX_LONG_MEMORIES (56)")

local baselinePromotedTotal = 0
for c = 1, 5 do
    local ck = "player:mig:char" .. c
    equal(migratedActor.social.relationships[ck].memories, nil,
        "migrated relationship omits embedded memories")
    baselinePromotedTotal = baselinePromotedTotal
        + (tonumber(migratedActor.social.relationships[ck].baselineApproval) or 0)
end
truthy(baselinePromotedTotal > 0,
    "evicted legacy memories promoted deltas into target relationship baselines")

local validMig, validMigErr = Social.Validate(migratedActor.social)
truthy(validMig, "migrated state validates cleanly: " .. tostring(validMigErr))

-- Validation fail-closed checks
local badRelMem = Social.NewState()
badRelMem.relationships["npc:bad:1"] = {
    targetKey = "npc:bad:1",
    approval = 0,
    respect = 0,
    familiarity = 0,
    revision = 0,
    memories = { { id = "bad:1" } },
}
local okBad1, errBad1 = Social.Validate(badRelMem)
equal(okBad1, false)
equal(errBad1, "relationship_memories_forbidden", "Validate forbids rel.memories")

local badScene = Social.NewState()
badScene.memoryBank[1] = { id = "scene:1", retentionClass = "SCENE", aboutKey = "npc:a:1" }
local okBad2, errBad2 = Social.Validate(badScene)
equal(okBad2, false)
equal(errBad2, "memory_bank_scene_forbidden", "Validate forbids SCENE in memoryBank")

local badDup = Social.NewState()
badDup.memoryBank[1] = { id = "dup:1", retentionClass = "LONG", refStrength = "WEAK", aboutKey = "npc:a:1" }
badDup.memoryBank[2] = { id = "dup:1", retentionClass = "LONG", refStrength = "WEAK", aboutKey = "npc:a:2" }
local okBad3, errBad3 = Social.Validate(badDup)
equal(okBad3, false)
equal(errBad3, "memory_bank_duplicate_id", "Validate forbids duplicate memory ids")

local badStrength = Social.NewState()
badStrength.memoryBank[1] = { id = "rs:1", retentionClass = "LONG", refStrength = "INVALID", aboutKey = "npc:a:1" }
local okBad4, errBad4 = Social.Validate(badStrength)
equal(okBad4, false)
equal(errBad4, "memory_bank_ref_strength_invalid", "Validate forbids unknown refStrength")

local badOverflow = Social.NewState()
for i = 1, Social.MAX_ANCHOR_MEMORIES + 1 do
    badOverflow.memoryBank[i] = {
        id = "anc:" .. i,
        retentionClass = "ANCHOR",
        refStrength = "STRONG",
        aboutKey = "npc:a:1",
    }
end
local okBad5, errBad5 = Social.Validate(badOverflow)
equal(okBad5, false)
equal(errBad5, "memory_bank_bucket_limit_exceeded", "Validate enforces anchor bucket limit")

-- 2. 100-contact high-activity actor (100 contacts x 64 events = 6,400 events)
local highReg = Actors.NewRegistry()
local highActor = assert(highReg:Create({
    actorId = "actor:l3:high_contact",
    identitySeed = "l3-high",
}))
local state100 = Social.NewState()
for c = 1, 100 do
    local ck = string.format("npc:hc:%03d", c)
    for m = 1, 64 do
        local cls = (m <= 16) and Social.RETENTION_SHORT or Social.RETENTION_LONG
        local rs = Social.REF_WEAK
        if m == 64 and c <= 12 then
            cls = Social.RETENTION_ANCHOR
            rs = Social.REF_STRONG
        end
        state100 = assert(Social.RecordAuthorizedEvent(state100, {
            targetKey = ck,
            eventID = string.format("hc:%d:%d", c, m),
            type = "evt_" .. (m % 8),
            retentionClass = cls,
            refStrength = rs,
            salience = 90 + (m % 15) + ((cls == Social.RETENTION_ANCHOR) and 110 or 0),
            approvalDelta = 1,
            familiarityDelta = 1,
            createdAt = (c * 100) + m,
            authority = "server",
            authorized = true,
            consolidate = false,
        }))
    end
end
highActor = assert(Authority.CommitSocial(
    highActor.actorId,
    state100,
    { Actors = { DefaultRegistry = highReg } },
    highActor.revision
))
truthy(#highActor.social.memoryBank <= Social.MAX_ACTOR_MEMORIES,
    "100-contact actor memoryBank bounded <= 96 (actual=" .. tostring(#highActor.social.memoryBank) .. ")")

local saved100 = assert(highReg:Save())
local bytes100 = #saved100
print(string.format("[L3 footprint] 100-contact 6400-event actor save = %d bytes (L0 baseline was 1606721 bytes)", bytes100))
truthy(bytes100 < 50000,
    "100-contact actor save strictly < 50KB (actual=" .. tostring(bytes100) .. "B)")

-- 3. FIFO-bounded ephemeral memory index cache (zero persisted keys)
for idx = 1, Social.MAX_MEMORY_INDEX_CACHE + 8 do
    local sTemp = Social.NewState()
    sTemp = assert(Social.RecordAuthorizedEvent(sTemp, {
        targetKey = "npc:idx:" .. idx,
        eventID = "ev:idx:" .. idx,
        type = (idx % 2 == 0) and "trade_done" or "gift_given",
        retentionClass = Social.RETENTION_LONG,
        approvalDelta = 2,
        createdAt = idx,
        authority = "server",
        authorized = true,
    }))
    local byT = Social.GetMemoriesForTarget(sTemp, "npc:idx:" .. idx)
    local byC = Social.GetMemoriesByClass(sTemp, Social.RETENTION_LONG)
    local byE = Social.GetMemoriesByEvent(sTemp, (idx % 2 == 0) and "trade_done" or "gift_given")
    equal(#byT, 1, "index query byTarget returns 1")
    equal(#byC, 1, "index query byClass returns 1")
    equal(#byE, 1, "index query byEvent returns 1")
end
local idxStats = Social.GetMemoryIndexStats()
equal(idxStats.cachedStates, Social.MAX_MEMORY_INDEX_CACHE,
    "FIFO cache capped at MAX_MEMORY_INDEX_CACHE (32)")
equal(idxStats.persistedKeysAdded, false, "zero persisted index keys added to social state")
equal(string.find(saved100, "\"byTarget\""), nil, "serialized JSON omits index keys")

-- 4. Summary, hot snapshot, RemoveMemory, CompactHistoricalEdge, PruneDefaultEdges
local apiState = Social.NewState()
apiState = assert(Social.RecordAuthorizedEvent(apiState, {
    targetKey = "npc:api:friend",
    eventID = "ev:api:1",
    type = "saved_life",
    retentionClass = Social.RETENTION_ANCHOR,
    refStrength = Social.REF_STRONG,
    salience = 220,
    approvalDelta = 40,
    respectDelta = 20,
    familiarityDelta = 25,
    cooldownHours = 12,
    createdAt = 100,
    worldAgeHours = 100,
    authority = "server",
    authorized = true,
}))
apiState = assert(Social.RecordAuthorizedEvent(apiState, {
    targetKey = "npc:api:acquaintance",
    eventID = "ev:api:2",
    type = "greeting",
    retentionClass = Social.RETENTION_SHORT,
    refStrength = Social.REF_WEAK,
    approvalDelta = 0,
    respectDelta = 0,
    familiarityDelta = 2,
    createdAt = 100,
    authority = "server",
    authorized = true,
}))
local stats = assert(Social.GetActorMemoryStats(apiState))
equal(stats.total, 2, "stats total")
equal(stats.byClass.ANCHOR, 1, "stats anchor count")
equal(stats.byClass.SHORT, 1, "stats short count")
equal(stats.byRefStrength.STRONG, 1, "stats STRONG count")
equal(stats.byRefStrength.WEAK, 1, "stats WEAK count")

local sumOnly = assert(Social.GetRelationshipSummary(apiState, "npc:api:friend"))
equal(sumOnly.memories, nil, "GetRelationshipSummary omits memories")
local hotSnap = assert(Social.GetHotRelationshipSnapshot(apiState, "npc:api:friend"))
equal(hotSnap.exists, true)
equal(hotSnap.memoryCount, 1)
equal(hotSnap.strongMemoryCount, 1)
equal(hotSnap.recentMemories[1].id, "ev:api:1")

local cliRem, cliRemErr = Social.RemoveMemory(apiState, "ev:api:2", "client")
equal(cliRem, nil)
equal(cliRemErr, "server_authority_required", "client RemoveMemory rejected")
truthy(Social.RemoveMemory(apiState, "ev:api:2", "server"), "server RemoveMemory removes SHORT entry")
equal(Social.PruneDefaultEdges(apiState), 1, "PruneDefaultEdges drops default zero-delta acquaintance edge")
equal(apiState.relationships["npc:api:acquaintance"], nil, "acquaintance edge pruned")
truthy(apiState.relationships["npc:api:friend"] ~= nil, "significant friend edge preserved")

local compactedRel = assert(Social.CompactHistoricalEdge(apiState, "npc:api:friend", {
    lifecycleStatus = "TOMBSTONE",
    lifecycleRevision = 4,
    displayLabel = "Doc Hale",
    kind = "npc",
    reasonClass = "combat_death",
    retiredAt = 150,
}))
equal(compactedRel.historical, true, "CompactHistoricalEdge marks edge historical")
equal(compactedRel.targetLifecycleStatus, "TOMBSTONE", "lifecycleStatus set")
equal(compactedRel.targetLifecycleRevision, 4, "lifecycleRevision set")
equal(compactedRel.historicalLabel, "Doc Hale", "historicalLabel bounded")
equal(apiState.relationships["npc:api:friend"].cooldowns, nil, "runtime cooldowns stripped on historical edge")
equal(apiState.relationships["npc:api:friend"].saturation, nil, "runtime saturation stripped on historical edge")

-- 5. GC integration: refStrength distinguishes STRONG ANCHOR vs WEAK ANCHOR vs WEAK SHORT + roleRefs
local gcReg = Actors.NewRegistry()
local deadStrong = assert(gcReg:Create({ actorId = "actor:l3:dead_strong", identitySeed = "ds" }))
local deadWeakAnchor = assert(gcReg:Create({ actorId = "actor:l3:dead_weak_anchor", identitySeed = "dwa" }))
local deadWeakShort = assert(gcReg:Create({ actorId = "actor:l3:dead_weak_short", identitySeed = "dws" }))
local deadSubjectStrong = assert(gcReg:Create({ actorId = "actor:l3:dead_subj_strong", identitySeed = "dss" }))
local deadRoleWeak = assert(gcReg:Create({ actorId = "actor:l3:dead_role_weak", identitySeed = "drw" }))

local keeper = assert(gcReg:Create({ actorId = "actor:l3:keeper", identitySeed = "kp" }))
local ks = Social.NewState()
ks = assert(Social.RecordAuthorizedEvent(ks, {
    targetKey = "actor:l3:dead_strong",
    eventID = "ev:gc:strong",
    type = "betrayal",
    retentionClass = Social.RETENTION_ANCHOR,
    refStrength = Social.REF_STRONG,
    salience = 230,
    approvalDelta = -60,
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
ks = assert(Social.RecordAuthorizedEvent(ks, {
    targetKey = "actor:l3:dead_weak_anchor",
    eventID = "ev:gc:weak_anchor",
    type = "solemn_memorial",
    retentionClass = Social.RETENTION_ANCHOR,
    refStrength = Social.REF_WEAK,
    salience = 210,
    approvalDelta = 10,
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
ks = assert(Social.RecordAuthorizedEvent(ks, {
    targetKey = "actor:l3:dead_weak_short",
    eventID = "ev:gc:weak_short",
    type = "small_talk",
    retentionClass = Social.RETENTION_SHORT,
    refStrength = Social.REF_WEAK,
    approvalDelta = 2,
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
ks = assert(Social.RecordAuthorizedEvent(ks, {
    targetKey = "actor:l3:dead_strong",
    eventID = "ev:gc:roles",
    type = "witnessed_crime",
    retentionClass = Social.RETENTION_ANCHOR,
    refStrength = Social.REF_STRONG,
    subjectKey = "actor:l3:dead_subj_strong",
    roleRefs = {
        witness = { ref = "actor:l3:dead_role_weak", refStrength = "WEAK", label = "Witness Lee" },
    },
    salience = 225,
    approvalDelta = -20,
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
keeper = assert(Authority.CommitSocial(
    keeper.actorId,
    ks,
    { Actors = { DefaultRegistry = gcReg } },
    keeper.revision
))

assert(gcReg:Retire(deadStrong.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(gcReg:Retire(deadWeakAnchor.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(gcReg:Retire(deadWeakShort.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(gcReg:Retire(deadSubjectStrong.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(gcReg:Retire(deadRoleWeak.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))

local gcRes = assert(GC.RunFull(gcReg, { authority = "server", now = 200 }))
equal(gcRes.purgedCount, 3, "deadWeakAnchor, deadWeakShort, deadRoleWeak purged; strong targets retained")
truthy(gcReg:GetTombstone(deadStrong.actorId), "STRONG ANCHOR retains deadStrong tombstone")
truthy(gcReg:GetTombstone(deadSubjectStrong.actorId), "STRONG subjectKey retains deadSubjectStrong tombstone")
equal(gcReg:GetTombstone(deadWeakAnchor.actorId), nil, "WEAK ANCHOR does NOT pin deadWeakAnchor forever")
equal(gcReg:GetTombstone(deadWeakShort.actorId), nil, "WEAK SHORT does NOT pin deadWeakShort")
equal(gcReg:GetTombstone(deadRoleWeak.actorId), nil, "WEAK roleRef does NOT pin deadRoleWeak")

local keeperAfter = assert(gcReg:Get(keeper.actorId))
equal(keeperAfter.social.relationships["actor:l3:dead_weak_short"], nil,
    "OnBeforePurge removes weak dead edge")
local foundWeakAnchorMem, foundWeakShortMem, foundRolesMem = nil, false, nil
for _, mem in ipairs(keeperAfter.social.memoryBank) do
    if mem.id == "ev:gc:weak_anchor" then foundWeakAnchorMem = mem end
    if mem.id == "ev:gc:weak_short" then foundWeakShortMem = true end
    if mem.id == "ev:gc:roles" then foundRolesMem = mem end
end
truthy(foundWeakAnchorMem, "degraded ANCHOR narrative consequence preserved in memoryBank")
equal(foundWeakAnchorMem.aboutKey, nil, "weak anchor aboutKey degraded to nil")
equal(foundWeakAnchorMem.aboutDegraded, true, "aboutDegraded flag recorded")
equal(foundWeakAnchorMem.refStrength, Social.REF_LABEL_ONLY, "refStrength downgraded to LABEL_ONLY")
equal(foundWeakShortMem, false, "trivial SHORT weak memory removed from memoryBank on purge")
truthy(foundRolesMem and foundRolesMem.roleRefs.witness.ref == nil
    and foundRolesMem.roleRefs.witness.label == "Witness Lee",
    "WEAK roleRef degraded to label-only on purge")

-- Authority RemoveMemory + _G.next=nil Save/Load roundtrip parity
local authTest = assert(gcReg:Create({ actorId = "actor:l3:auth_mem", identitySeed = "am" }))
local committed = assert(Authority.RecordAuthorizedEvent(authTest.actorId, {
    targetKey = "player:acc:uuid1",
    eventID = "ev:auth:rm1",
    type = "chat",
    retentionClass = Social.RETENTION_LONG,
    refStrength = Social.REF_WEAK,
    approvalDelta = 5,
    createdAt = 10,
    authority = "server",
    authorized = true,
}, { Actors = { DefaultRegistry = gcReg } }, authTest.revision))
local hotBefore = assert(Authority.GetHotRelationshipSnapshot(
    authTest.actorId, "player:acc:uuid1", {}, { Actors = { DefaultRegistry = gcReg } }))
equal(hotBefore.memoryCount, 1)
assert(Authority.RemoveMemory(authTest.actorId, "ev:auth:rm1",
    { Actors = { DefaultRegistry = gcReg } }, committed.revision))
local hotAfter = assert(Authority.GetHotRelationshipSnapshot(
    authTest.actorId, "player:acc:uuid1", {}, { Actors = { DefaultRegistry = gcReg } }))
equal(hotAfter.memoryCount, 0, "Authority.RemoveMemory removed memory")

local realNext = _G.next
_G.next = nil
local okSave, savedRoundtrip = pcall(function()
    return gcReg:Save()
end)
_G.next = realNext
truthy(okSave and type(savedRoundtrip) == "string",
    "Registry:Save works cleanly under _G.next = nil: " .. tostring(savedRoundtrip))

local reloaded = Actors.NewRegistry()
local rOk, rErr = reloaded:Load(savedRoundtrip)
truthy(rOk, "reloaded L3 registry: " .. tostring(rErr))
local rk = assert(reloaded:Get(keeper.actorId))
equal(rk.social.schemaVersion, 3, "reloaded keeper keeps schemaVersion 3")
truthy(#rk.social.memoryBank >= 2, "reloaded memoryBank preserves surviving & degraded consequences")

print("psychopatz_social_memory_bank_migration_smoke: PASS")
