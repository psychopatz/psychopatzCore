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

local dailyCallbacks = {}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = {
        Add = function(fn)
            dailyCallbacks[#dailyCallbacks + 1] = fn
        end,
    },
}

local serverFlag = true
local clientFlag = false
isServer = function() return serverFlag end
isClient = function() return clientFlag end

local currentWorldHours = 100
getGameTime = function()
    return {
        getWorldAgeHours = function() return currentWorldHours end,
    }
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local GC = Actors.GC
local Social = Actors.Social
local RuntimeStore = Actors.RuntimeStore
local PlayerIdentity = Actors.PlayerIdentity
local SurvivorWorldRegistry =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local WorldKnowledge =
    require "PsychopatzCore/WorldKnowledge/PsychopatzActorWorldKnowledge"
local WorldFactLedger =
    require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFactLedger"

PlayerIdentity.Reset()

-- 0. Provider registration contract & fail-closed validation
local badProv, badProvErr = GC.RegisterReferenceProvider("", { owner = "Test", CollectStrongRefs = function() end })
falsy(badProv, "empty provider id rejected")
equal(badProvErr, "provider_id_invalid", "empty provider id error")

local badMax, badMaxErr = GC.RegisterReferenceProvider("test:overmax", {
    owner = "Test",
    maxRefs = GC.MAX_REFS_PER_PROVIDER + 1,
    CollectStrongRefs = function() end,
})
falsy(badMax, "overflow provider maxRefs rejected")
equal(badMaxErr, "provider_max_refs_invalid", "overflow maxRefs error")

-- 1. Strong root vs weak-only root, grace period, ExplainRetention / ExplainPurge
local reg = Actors.NewRegistry()
local strongTarget = assert(reg:Create({
    actorId = "actor:gc:pinned",
    identitySeed = "gc-pinned",
    identity = { displayName = "Pinned Victim" },
    extensions = {
        [Actors.Identity.EXTENSION] = { aliases = { "alias:pinned" } },
    },
}))
local weakTarget = assert(reg:Create({
    actorId = "actor:gc:weak",
    identitySeed = "gc-weak",
    identity = { displayName = "Weak Acquaintance" },
    extensions = {
        [Actors.Identity.EXTENSION] = { aliases = { "alias:weak" } },
    },
}))
local graceTarget = assert(reg:Create({
    actorId = "actor:gc:grace",
    identitySeed = "gc-grace",
    identity = { displayName = "Recent Deceased" },
}))

assert(reg:Retire(strongTarget.actorId, {
    authority = "server",
    retiredAt = 100,
    graceHours = 24,
    reason = "death",
}))
assert(reg:Retire(weakTarget.actorId, {
    authority = "server",
    retiredAt = 100,
    graceHours = 24,
    reason = "death",
}))
assert(reg:Retire(graceTarget.actorId, {
    authority = "server",
    retiredAt = 200,
    graceHours = 100,
    reason = "death",
}))
equal(reg:TombstoneCount(), 3, "three retired tombstones present")

local pinActive = true
local weakDegraded = false
assert(GC.RegisterReferenceProvider("test:custom_roots", {
    owner = "TestSuite",
    maxRefs = 16,
    CollectStrongRefs = function(_, emit)
        if pinActive then
            emit("alias:pinned", "active_quest_pin", { quest = "q_1" })
        end
    end,
    CollectWeakRefs = function(_, emit)
        if not weakDegraded then
            emit(weakTarget.actorId, "rumor_mention")
        end
    end,
    OnBeforePurge = function(ref)
        if ref == weakTarget.actorId then
            weakDegraded = true
        end
        return true, 1
    end,
}))

-- Client runtime cannot execute GC
serverFlag = false
clientFlag = true
local clientStep, clientStepErr = GC.Step(reg, { authority = "server", now = 150 })
equal(clientStep, nil, "client GC.Step rejected")
equal(clientStepErr, "server_authority_required", "client GC.Step error")
local clientRun, clientRunErr = GC.RunFull(reg, { authority = "server", now = 150 })
equal(clientRun, nil, "client GC.RunFull rejected")
equal(clientRunErr, "server_authority_required", "client GC.RunFull error")
serverFlag = true
clientFlag = false

-- ExplainRetention before sweep at now=150 (past 124 grace for pinned/weak; inside 300 grace for graceTarget)
local retPinned = assert(GC.ExplainRetention(reg, strongTarget.actorId, { now = 150 }))
equal(retPinned.retained, true, "pinned actor retained")
equal(#retPinned.strongRoots, 1, "ExplainRetention lists exact strong root")
equal(retPinned.strongRoots[1].providerID, "test:custom_roots", "strong root provider ID")
equal(retPinned.wouldPurgeNow, false, "pinned actor would not purge")

local retGrace = assert(GC.ExplainRetention(reg, graceTarget.actorId, { now = 150 }))
equal(retGrace.retained, true, "grace actor retained")
equal(retGrace.graceRemainingHours, 150, "grace remaining hours calculated")
local purGraceBefore = assert(GC.ExplainPurge(reg, graceTarget.actorId, { now = 150 }))
equal(purGraceBefore.purged, false, "grace actor not purged")
equal(purGraceBefore.blockingReasons[1], "grace_period_active", "ExplainPurge explains grace block")

-- Run full GC at now=150: weakTarget purges (weakDegraded flips), strongTarget stays, graceTarget stays
local gen1 = assert(GC.RunFull(reg, { authority = "server", now = 150 }))
equal(gen1.ok, true, "gen1 completed")
equal(gen1.purgedCount, 1, "gen1 purged only weakTarget")
equal(gen1.purgedRefs[1], weakTarget.actorId, "weakTarget purged")
equal(weakDegraded, true, "OnBeforePurge compacted weak ref before purge")
equal(reg:TombstoneCount(), 2, "two tombstones remain after gen1")
equal(reg:ProjectIdentity("alias:weak").status, "FORGOTTEN", "purged weak alias resolves FORGOTTEN")

local expPurge = assert(GC.ExplainPurge(reg, weakTarget.actorId, { now = 150 }))
equal(expPurge.purged, true, "ExplainPurge reports completed purge")
equal(expPurge.generation, gen1.generation, "ExplainPurge reports exact generation")

-- Unpin strong root -> next GC generation purges strongTarget cleanly (no persistent refcount!)
pinActive = false
local gen2 = assert(GC.RunFull(reg, { authority = "server", now = 160 }))
equal(gen2.ok, true, "gen2 completed")
equal(gen2.purgedCount, 1, "gen2 purged unpinned target")
equal(gen2.purgedRefs[1], strongTarget.actorId, "strongTarget purged after root release")
equal(reg:ProjectIdentity("alias:pinned").status, "FORGOTTEN", "purged alias removed cleanly")
equal(reg:TombstoneCount(), 1, "only graceTarget remains")

-- Active ownership blocks purge even past grace
local ownedActive = true
assert(GC.RegisterReferenceProvider("test:active_owner", {
    owner = "TestSuite",
    CollectStrongRefs = function() end,
    IsOwnedActive = function(ref)
        if ref == graceTarget.actorId and ownedActive then
            return true, "corpse_reanimating"
        end
        return false
    end,
}))
local gen3 = assert(GC.RunFull(reg, { authority = "server", now = 400 }))
equal(gen3.purgedCount, 0, "active ownership blocks purge past grace")
equal(gen3.activeOwnershipBlocked, 1, "activeOwnershipBlocked counted")
equal(reg:TombstoneCount(), 1, "graceTarget still exists while owned active")

ownedActive = false
assert(GC.UnregisterReferenceProvider("test:custom_roots"))
assert(GC.UnregisterReferenceProvider("test:active_owner"))

-- 2. Fail-closed provider error modes (exception, false, malformed ref, overflow) delete ZERO tombstones
local failModes = { "exception", "false_return", "malformed_ref", "overflow" }
for _, mode in ipairs(failModes) do
    assert(GC.RegisterReferenceProvider("test:fail_" .. mode, {
        owner = "BrokenMod",
        maxRefs = 2,
        CollectStrongRefs = function(_, emit)
            if mode == "exception" then
                error("boom")
            elseif mode == "false_return" then
                return false, "provider_down"
            elseif mode == "malformed_ref" then
                emit("bad\nref", "broken")
            elseif mode == "overflow" then
                emit("a", "r1")
                emit("b", "r2")
                emit("c", "r3")
            end
        end,
    }))
    local aborted = assert(GC.RunFull(reg, { authority = "server", now = 400 }))
    equal(aborted.ok, false, "fail mode " .. mode .. " returns ok=false")
    equal(aborted.aborted, true, "fail mode " .. mode .. " aborts sweep")
    equal(aborted.purgedCount, 0, "fail mode " .. mode .. " purges ZERO tombstones")
    equal(reg:TombstoneCount(), 1, "fail mode " .. mode .. " leaves canonical tombstone intact")
    assert(GC.UnregisterReferenceProvider("test:fail_" .. mode))
end

-- Partial OnBeforePurge failure skips ONLY the failing ref and leaves state retryable
local extraTarget = assert(reg:Create({ actorId = "actor:gc:extra", identitySeed = "gc-extra" }))
assert(reg:Retire(extraTarget.actorId, { authority = "server", retiredAt = 100, graceHours = 10 }))
local blockPrePurge = true
assert(GC.RegisterReferenceProvider("test:pre_purge_fail", {
    owner = "TestSuite",
    CollectStrongRefs = function() end,
    OnBeforePurge = function(ref)
        if ref == graceTarget.actorId and blockPrePurge then
            return false, "io_busy"
        end
        return true, 0
    end,
}))
local partialRes = assert(GC.RunFull(reg, { authority = "server", now = 400 }))
equal(partialRes.ok, true, "partial OnBeforePurge finishes pass cleanly")
equal(partialRes.purgedCount, 1, "healthy ref purged")
equal(partialRes.purgedRefs[1], extraTarget.actorId, "extraTarget purged")
equal(#partialRes.purgeFailedRefs, 1, "failing ref reported")
equal(reg:Has(graceTarget.actorId), false, "still no live record")
truthy(reg:GetTombstone(graceTarget.actorId), "failing ref tombstone preserved for retry")

blockPrePurge = false
local retryRes = assert(GC.RunFull(reg, { authority = "server", now = 401 }))
equal(retryRes.purgedCount, 1, "retry purges previously blocked tombstone")
equal(reg:TombstoneCount(), 0, "zero tombstones after retry")
assert(GC.UnregisterReferenceProvider("test:pre_purge_fail"))

-- 3. Budgeted cursor stepping (budget = 5 across 40 tombstones) matches RunFull
local batchRegFull = Actors.NewRegistry()
local batchRegSliced = Actors.NewRegistry()
for i = 1, 40 do
    local id = string.format("actor:gc:batch:%02d", i)
    assert(batchRegFull:Create({ actorId = id, identitySeed = "b-" .. i }))
    assert(batchRegSliced:Create({ actorId = id, identitySeed = "b-" .. i }))
    assert(batchRegFull:Retire(id, { authority = "server", retiredAt = 10, graceHours = 20 }))
    assert(batchRegSliced:Retire(id, { authority = "server", retiredAt = 10, graceHours = 20 }))
end
-- Pin #17 strongly in both registries via a temporary provider
assert(GC.RegisterReferenceProvider("test:batch_pin", {
    owner = "TestSuite",
    CollectStrongRefs = function(_, emit)
        emit("actor:gc:batch:17", "kept_for_test")
    end,
}))
local fullBatchRes = assert(GC.RunFull(batchRegFull, { authority = "server", now = 100 }))
equal(fullBatchRes.purgedCount, 39, "RunFull purges 39/40 batch tombstones")

local slices = 0
local finalSlice = nil
repeat
    slices = slices + 1
    finalSlice = assert(GC.Step(batchRegSliced, { authority = "server", budget = 5, now = 100 }))
until finalSlice.completed or slices > 50
truthy(slices >= 8, "budget=5 across 40 tombstones spans >= 8 incremental slices (got " .. slices .. ")")
equal(finalSlice.purgedCount, 39, "sliced GC purges same 39/40 batch tombstones")
equal(batchRegSliced:TombstoneCount(), batchRegFull:TombstoneCount(), "sliced and full tombstone counts match")
truthy(batchRegSliced:GetTombstone("actor:gc:batch:17"), "pinned #17 retained in sliced pass")
assert(GC.UnregisterReferenceProvider("test:batch_pin"))

-- 4. Built-in PsychopatzCore.Social, SurvivorWorld, WorldKnowledge providers
local socReg = Actors.NewRegistry()
local deadAnchor = assert(socReg:Create({ actorId = "actor:soc:dead_anchor", identitySeed = "da" }))
local deadWeak = assert(socReg:Create({ actorId = "actor:soc:dead_weak", identitySeed = "dw" }))
local deadWitness = assert(socReg:Create({ actorId = "actor:soc:dead_witness", identitySeed = "dwit" }))
local deadLeader = assert(socReg:Create({ actorId = "actor:soc:dead_leader", identitySeed = "dl" }))

local survivorSocial = Social.NewState({
    relationships = {
        ["npc:actor:soc:dead_anchor"] = {
            approval = -60,
            respect = -30,
            familiarity = 50,
            memories = {
                {
                    id = "mem:anchor:betray",
                    type = "betrayal",
                    retentionClass = "ANCHOR",
                    salience = 230,
                    createdAt = 50,
                    sourceKey = "actor:soc:dead_witness",
                },
            },
        },
        ["actor:soc:dead_weak"] = {
            approval = 5,
            respect = 0,
            familiarity = 5,
            memories = {
                {
                    id = "mem:weak:hello",
                    type = "greeting",
                    retentionClass = "SHORT",
                    createdAt = 50,
                },
            },
        },
    },
    aliases = {
        ["legacy:dead_weak"] = "actor:soc:dead_weak",
    },
})
local survivor = assert(socReg:Create({
    actorId = "actor:soc:survivor",
    identitySeed = "surv",
    social = survivorSocial,
}))

assert(socReg:Retire(deadAnchor.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(socReg:Retire(deadWeak.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(socReg:Retire(deadWitness.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(socReg:Retire(deadLeader.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))

local sw = assert(SurvivorWorldRegistry.new({ worldSeed = 777 }))
assert(sw:UpsertFaction({
    id = "faction:gc",
    name = "GC Faction",
    leaderActorID = deadLeader.actorId,
    memberActorIDs = { deadLeader.actorId, deadWeak.actorId, survivor.actorId },
}))

local ledger = WorldFactLedger.New()
local wkState = WorldKnowledge.NewState()
assert(WorldFactLedger.Add(ledger, { factID = "fact:1", kind = "rumor", producer = "test", occurredAt = 50 }))
WorldKnowledge.Acquire(wkState, ledger, deadWeak.actorId, "fact:1", {
    authorized = true,
    provenance = "told",
    sourceActorID = deadWitness.actorId,
    learnedAt = 50,
})
WorldKnowledge.Acquire(wkState, ledger, survivor.actorId, "fact:1", {
    authorized = true,
    provenance = "told",
    sourceActorID = deadWitness.actorId,
    learnedAt = 50,
})

local socGen = assert(GC.RunFull(socReg, {
    authority = "server",
    now = 200,
    survivorWorld = sw,
    worldKnowledge = wkState,
}))
equal(socGen.purgedCount, 2, "deadWeak and deadWitness purged; deadAnchor and deadLeader retained")
truthy(socReg:GetTombstone(deadAnchor.actorId), "social ANCHOR memory pins deadAnchor via npc: prefix")
truthy(socReg:GetTombstone(deadLeader.actorId), "SurvivorWorld active faction leader pins deadLeader")
equal(socReg:GetTombstone(deadWeak.actorId), nil, "weak social edge did NOT retain deadWeak")
equal(socReg:GetTombstone(deadWitness.actorId), nil, "weak memory sourceKey did NOT retain deadWitness")

local updatedSurvivor = assert(socReg:Get(survivor.actorId))
equal(updatedSurvivor.social.relationships["actor:soc:dead_weak"], nil,
    "OnBeforePurge compacted weak dead relationship")
equal(updatedSurvivor.social.aliases["legacy:dead_weak"], nil,
    "OnBeforePurge removed orphaned social alias")
local anchorRel = assert(updatedSurvivor.social.relationships["npc:actor:soc:dead_anchor"])
equal(anchorRel.memories[1].sourceKey, nil, "weak sourceKey degraded on purge")
equal(anchorRel.memories[1].sourceDegraded, true, "sourceDegraded marker recorded")

local swFaction = assert(sw:GetFaction("faction:gc"))
equal(#swFaction.memberActorIDs, 2, "SurvivorWorld memberActorIDs scrubbed purged weak member")
equal(wkState.byActor[deadWeak.actorId], nil, "WorldKnowledge dead actor bucket removed on purge")
equal(wkState.byActor[survivor.actorId].refs["fact:1"].sourceDegraded, true,
    "WorldKnowledge weak sourceActorID degraded cleanly")

local diag = assert(GC.GetDiagnostics(socReg, {
    now = 250,
    survivorWorld = sw,
    worldKnowledge = wkState,
}))
equal(diag.liveActors, 1, "diagnostics reports liveActors")
equal(diag.tombstones, 2, "diagnostics reports remaining tombstones")
equal(diag.oldestTombstoneAgeHours, 200, "diagnostics reports tombstone age")
truthy(diag.tombstoneBytesEstimate > 0, "diagnostics reports tombstone byte estimate")

-- 5. RuntimeStore startup reconciliation, EveryDays hook, and Kahlua _G.next = nil safety
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorld = PsychopatzCore.SurvivorWorld or {}
local prevSW = PsychopatzCore.SurvivorWorld.DefaultRegistry
PsychopatzCore.SurvivorWorld.DefaultRegistry = sw
currentWorldHours = 200
RuntimeStore.Attach(socReg)
local originalNext = _G.next
_G.next = nil
local okSave = pcall(function()
    assert(RuntimeStore.Save())
end)
_G.next = originalNext
truthy(okSave, "RuntimeStore.Save succeeds under _G.next = nil")

local reloadReg = Actors.NewRegistry()
RuntimeStore.Attach(reloadReg)
equal(reloadReg:TombstoneCount(), 2, "RuntimeStore reload reconciles and keeps pinned tombstones")
equal(reloadReg.gcMeta.generation >= 1, true, "gcMeta generation persisted across save/load")

-- Daily maintenance hook triggers budgeted GC when world age passes grace
local dailyDead = assert(reloadReg:Create({ actorId = "actor:gc:daily", identitySeed = "daily" }))
assert(reloadReg:Retire(dailyDead.actorId, { authority = "server", retiredAt = 200, graceHours = 24 }))
equal(reloadReg:TombstoneCount(), 3, "daily tombstone added")
currentWorldHours = 300
for _, fn in ipairs(dailyCallbacks) do fn() end
equal(reloadReg:TombstoneCount(), 2, "EveryDays hook swept expired unreferenced tombstone")
PsychopatzCore.SurvivorWorld.DefaultRegistry = prevSW

print("PASS psychopatz_actor_gc_mark_sweep_smoke")
