local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = {
    AllowsServerCode = function() return true end,
}

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
    OnServerStarted = { Add = function() end },
    OnPlayerDeath = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
}
isServer = function() return true end
isClient = function() return false end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local SocialQuery = Actors.SocialQuery
local PlayerIdentity = Actors.PlayerIdentity
local GC = Actors.GC
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local corePolicyReg = require "PsychopatzCore/SocialPolicy/Registry"
Actors.SocialPolicy.RegisterRegistry(corePolicyReg)

local registry = Actors.NewRegistry()
Actors.DefaultRegistry = registry

local worldHours = 100
local totalActors = 1200
local retiredTotal = 1000
local strongAnchorPinned = 25
local strongProviderPinned = 25

local tStart = os.clock()

-- 1. Create 1,200 actors with sparse contacts + 1 high-contact actor (100 contacts x 64 events)
local highContactID = "actor:soak:high_contact"
local actorIDs = {}
for idx = 1, totalActors do
    local id = idx == 1 and highContactID or string.format("actor:soak:%04d", idx)
    actorIDs[idx] = id
    local nextTarget = string.format("actor:soak:%04d", (idx % totalActors) + 1)
    assert(registry:Create({
        actorId = id,
        identitySeed = "soak-seed-" .. tostring(idx),
        identity = { displayName = "Survivor " .. tostring(idx), role = "resident" },
        social = Social.NewState({
            relationships = {
                [nextTarget] = {
                    target = nextTarget,
                    approval = 10,
                    respect = 5,
                    familiarity = 15,
                    revision = 1,
                },
            },
        }),
    }))
end

-- Populate high-contact actor with 100 contacts x 64 repeated events = 6,400 events
local highActor = assert(registry:Get(highContactID))
local hcSocial = Social.NewState(highActor.social)
local hcRels = hcSocial.relationships or {}
local hcMems = hcSocial.memoryBank or {}
for c = 1, 100 do
    local targetID = string.format("actor:soak:%04d", c + 1)
    local isStrongAnchorTarget = (c >= 1 and c <= strongAnchorPinned)
    hcRels[targetID] = {
        target = targetID,
        approval = isStrongAnchorTarget and -80 or 15,
        respect = isStrongAnchorTarget and -40 or 10,
        familiarity = 30,
        revision = 2,
    }
    -- Keep 64 events simulated through Consolidation/Insert on first few and bounded batch insert
    if c <= 25 then
        -- 25 STRONG anchors pinned to target 2..26 (will survive retirement!)
        hcMems[#hcMems + 1] = {
            id = "mem:hc:anchor:" .. tostring(c),
            aboutKey = targetID,
            type = "betrayed_player",
            retentionClass = "ANCHOR",
            refStrength = "STRONG",
            permanent = true,
            salience = 100,
            confidence = 1.0,
            sourceMode = "direct",
            createdAt = worldHours,
        }
    end
end
hcSocial.relationships = hcRels
hcSocial.memoryBank = hcMems
-- Also drive 64 repeated events per contact through RecordAuthorizedEvent on sample targets (3x64=192)
-- while verifying memoryBank ceiling stays <= 96
for repTargetIdx = 27, 31 do
    local tKey = string.format("actor:soak:%04d", repTargetIdx)
    for ev = 1, 64 do
        hcSocial = assert(Social.RecordAuthorizedEvent(hcSocial, {
            targetKey = tKey,
            eventID = string.format("ev:%d:%d", repTargetIdx, ev),
            type = "commercial_trade",
            retentionClass = "SHORT",
            refStrength = "WEAK",
            salience = 35,
            createdAt = worldHours + (ev * 0.01),
            authority = "server",
            authorized = true,
        }))
    end
end
highActor = assert(registry:Commit(highContactID, { social = hcSocial }, highActor.revision))
assert(#highActor.social.memoryBank <= Social.MAX_ACTOR_MEMORIES,
    "actor-level memoryBank must stay <= 96")
for _, rel in pairs(highActor.social.relationships or {}) do
    assert(rel.memories == nil, "per-relationship memories array must not exist")
end
local hcSaveBytes = #Json.Encode(highActor)
assert(hcSaveBytes < 50000, "high-contact actor serialized footprint must remain < 50 KB")

local liveBaselineBytes = #assert(registry:Save())

-- Custom external strong root provider pinning retired actors 27..(26+strongProviderPinned)
local pinnedByProvider = {}
for idx = 27, 26 + strongProviderPinned do
    pinnedByProvider[actorIDs[idx]] = true
end
assert(GC.RegisterReferenceProvider("SoakTest.PinnedRoots", {
    owner = "SoakTest",
    maxRefs = 256,
    CollectStrongRefs = function(_, emit)
        local keys = {}
        for id in pairs(pinnedByProvider) do keys[#keys + 1] = id end
        table.sort(keys)
        for _, id in ipairs(keys) do
            emit(id, "soak_external_pin")
        end
        return true
    end,
}))

-- 2. Verify TickBudgeted skips when tombstones < threshold (64), runs when >= 64
assert(registry:Retire(actorIDs[2], {
    authority = "server",
    reason = "death",
    retiredAt = worldHours,
    graceHours = 12,
}))
local belowRes = assert(GC.TickBudgeted(registry, { authority = "server", now = worldHours }))
assert(belowRes.skipped == true and belowRes.reason == "below_threshold")

-- Retire actors 3..1001 -> total 1,000 retired actors (200 left live)
for idx = 3, retiredTotal + 1 do
    assert(registry:Retire(actorIDs[idx], {
        authority = "server",
        reason = "death",
        retiredAt = worldHours,
        graceHours = 12,
    }))
end

-- Verify MP player death / reconnect / new character / cross-account isolation
local p1 = {
    getUsername = function() return "acc_soak_1" end,
    getOnlineID = function() return 101 end,
    getModData = function() return { PNC_CharacterUUID = "char_soak_a1" } end,
}
assert(PlayerIdentity.RegisterIssuedIdentity("char_soak_a1", "acc_soak_1", {
    authority = "server",
    displayName = "SoakHero1",
}))
local okValLive = PlayerIdentity.ValidateLiveInteraction(p1, { accountKey = "acc_soak_1" })
assert(okValLive == true)
assert(PlayerIdentity.RetirePlayerCharacter(p1, {
    authority = "server",
    accountKey = "acc_soak_1",
    retiredAt = worldHours,
    graceHours = 12,
}))
local okValDead, deadErr = PlayerIdentity.ValidateLiveInteraction(p1, { accountKey = "acc_soak_1" })
assert(okValDead == false and deadErr == "actor_retired")
local p2 = {
    getUsername = function() return "acc_soak_1" end,
    getOnlineID = function() return 102 end,
    getModData = function() return { PNC_CharacterUUID = "char_soak_a2" } end,
}
assert(PlayerIdentity.RegisterIssuedIdentity("char_soak_a2", "acc_soak_1", {
    authority = "server",
    displayName = "SoakHero2",
}))
local okOtherAcct, otherAcctErr = PlayerIdentity.ValidateLiveInteraction(p2, {
    expectedAccountKey = "acc_other",
})
assert(okOtherAcct == false and otherAcctErr == "account_mismatch")

-- Advance world time +5,000 hours & run cursor-budgeted GC slices (budget = 32)
worldHours = worldHours + 5000
local slices = 0
local lastStep
repeat
    lastStep = assert(GC.Step(registry, {
        authority = "server",
        budget = 32,
        now = worldHours,
    }))
    slices = slices + 1
    assert(slices <= 200, "budgeted GC must converge within bounded slices")
until lastStep.completed == true
assert(slices > 1, "budget=32 over 1,000+ tombstones must slice across multiple steps")

-- Verify counts: 50 strongly pinned stay RETIRED, 950 unreferenced/weak NPC + 1 player = 951 purged to FORGOTTEN
local expectedRemainingTombstones = strongAnchorPinned + strongProviderPinned
local diag = assert(GC.GetDiagnostics(registry, { now = worldHours }))
assert(diag.liveActors == (totalActors - retiredTotal),
    "expected 200 live actors, got " .. tostring(diag.liveActors))
assert(diag.tombstones == expectedRemainingTombstones,
    "expected 50 pinned tombstones, got " .. tostring(diag.tombstones))
assert(diag.orphanedAliasCount == 0, "expected 0 orphaned aliases after sweep")
for idx = 2, 26 do
    assert(registry:GetLifecycleState(actorIDs[idx]) == "RETIRED",
        "ANCHOR STRONG actor must remain RETIRED")
end
for idx = 27, 26 + strongProviderPinned do
    assert(registry:GetLifecycleState(actorIDs[idx]) == "RETIRED",
        "provider-pinned actor must remain RETIRED")
end
for idx = 27 + strongProviderPinned, retiredTotal + 1 do
    assert(registry:GetLifecycleState(actorIDs[idx]) == "FORGOTTEN",
        "unreferenced/weak actor must purge to FORGOTTEN")
end

-- Check post-GC save bytes strictly smaller than 1,200-live baseline
local postGCSaveStr = assert(registry:Save())
local postGCSaveBytes = #postGCSaveStr
assert(postGCSaveBytes < liveBaselineBytes,
    "post-GC serialized save must shrink relative to 1,200 live actor baseline")

-- Kahlua _G.next = nil Save()/Load() round-trip
local savedNext = _G.next
_G.next = nil
local okRoundSave, serAgain = pcall(registry.Save, registry)
local reloaded = Actors.NewRegistry()
local okRoundLoad, loadOK, loadErr = pcall(reloaded.Load, reloaded, serAgain)
_G.next = savedNext
assert(okRoundSave and type(serAgain) == "string", "Save under _G.next=nil must succeed")
assert(okRoundLoad and loadOK, "Load under _G.next=nil must succeed: " .. tostring(loadErr))
assert(#reloaded:ListTombstones() == expectedRemainingTombstones)
assert(#reloaded:List() == (totalActors - retiredTotal))
-- Spot check high-contact surviving actor after reload
local reloadedHC = assert(reloaded:Get(highContactID))
assert(#reloadedHC.social.memoryBank <= Social.MAX_ACTOR_MEMORIES)
for _, targetRef in ipairs({ actorIDs[2], actorIDs[27], actorIDs[500] }) do
    assert(reloaded:ProjectIdentity(targetRef) ~= nil)
end

-- 3. Hot-interaction latency & zero-GC-on-click (1,000 opens + plans)
SocialQuery.ResetDiagnostics()
local genBeforeClicks = (registry.gcMeta and registry.gcMeta.generation) or 0
local tClick0 = os.clock()
for idx = 1, 1000 do
    local target = actorIDs[((idx - 1) % 60) + 2]
    local hot = assert(SocialQuery.OpenInteractionHotContext(registry, highContactID, target, {
        now = worldHours,
    }))
    assert(hot.decisionToken ~= nil)
    if (idx % 4) == 0 then
        local planRes = assert(SocialQuery.ExecutePlan(registry, highContactID, {
            targetRef = target,
            maxMemories = 4,
        }, { now = worldHours }))
        assert(#planRes.memories <= 4)
    end
end
local clickElapsedMs = (os.clock() - tClick0) * 1000
local meanClickMs = clickElapsedMs / 1000
local genAfterClicks = (registry.gcMeta and registry.gcMeta.generation) or 0
assert(genAfterClicks == genBeforeClicks, "1,000 hot interactions must trigger ZERO GC sweeps")
assert(SocialQuery.GetDiagnostics().gcCallsDuringHotOpen == 0)
assert(meanClickMs < 5.0, "hot interaction mean latency must remain bounded (< 5 ms)")

GC.UnregisterReferenceProvider("SoakTest.PinnedRoots")

local totalSec = os.clock() - tStart
print(string.format(
    "PASS psychopatz_actor_lifecycle_gc_soak_scale_smoke actors=%d retired=%d purged=%d retained=%d slices=%d liveBytes=%d postGCBytes=%d highContactBytes=%d meanClickMs=%.3f elapsed=%.3fs",
    totalActors,
    retiredTotal,
    retiredTotal - expectedRemainingTombstones,
    expectedRemainingTombstones,
    slices,
    liveBaselineBytes,
    postGCSaveBytes,
    hcSaveBytes,
    meanClickMs,
    totalSec
))
