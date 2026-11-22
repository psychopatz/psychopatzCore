local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local VERSIONED_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = VERSIONED_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "eq") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(val, label)
    if not val then error(label or "expected truthy") end
end

local function falsy(val, label)
    if val then error((label or "expected falsy") .. " got=" .. tostring(val)) end
end

local mockPowerOn = true
local mockWorldDays = 5
local mockWaterShutDay = 14
local mockModData = {}
local hookCallbacks = { OnElectricityChanged = {}, OnGameStart = {}, EveryHours = {} }

ModData = {
    getOrCreate = function(key)
        mockModData[key] = mockModData[key] or {}
        return mockModData[key]
    end,
    get = function(key)
        return mockModData[key]
    end,
}

Events = {
    OnElectricityChanged = {
        Add = function(fn) hookCallbacks.OnElectricityChanged[#hookCallbacks.OnElectricityChanged + 1] = fn end,
    },
    OnGameStart = {
        Add = function(fn) hookCallbacks.OnGameStart[#hookCallbacks.OnGameStart + 1] = fn end,
    },
    EveryHours = {
        Add = function(fn) hookCallbacks.EveryHours[#hookCallbacks.EveryHours + 1] = fn end,
    },
}

function getWorld()
    return {
        isHydroPowerOn = function() return mockPowerOn end,
    }
end

function getSandboxOptions()
    return {
        doesPowerGridExist = function() return mockPowerOn end,
        getWaterShutModifier = function() return mockWaterShutDay end,
    }
end

function getGameTime()
    return {
        getWorldAgeDaysSinceBegin = function() return mockWorldDays end,
        getWorldAgeHours = function() return mockWorldDays * 24 end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Adapter = Core.WorldEventAdapter
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

truthy(Adapter ~= nil, "Core.WorldEventAdapter loaded")
truthy(#hookCallbacks.OnElectricityChanged >= 1, "OnElectricityChanged hook installed")
truthy(#hookCallbacks.EveryHours >= 1, "EveryHours hook installed")

ScopedEvents.Reset()
Observer.Reset()
WorldKnowledge.Reset()

-- 1. Missing authority fails closed
local failRes, failDiag = Adapter.ObserveUtilities(10, {
    world = false,
    sandbox = false,
    gameTime = false,
    force = true,
})
eq(#failRes, 0, "unavailable authority produces 0 events")
eq(failDiag.electricity, "electricity_authority_unknown", "power fails closed")
eq(failDiag.water, "water_authority_unknown", "water fails closed")

-- 2. Power and water initially ON -> 0 cutoff events
mockPowerOn = true
mockWorldDays = 5
local initRes = Adapter.ObserveUtilities(5 * 24)
eq(#initRes, 0, "utilities ON emit 0 cutoff events")
eq(Observer.GetUtilityState("electricity").on, true, "electricity watermark recorded ON")
eq(Observer.GetUtilityState("water").on, true, "water watermark recorded ON")

-- 3. Power cutoff via OnElectricityChanged -> exactly one global event + fact
mockPowerOn = false
mockWorldDays = 10
hookCallbacks.OnElectricityChanged[1]()
local elecEv = ScopedEvents.Get("core:utility:electricity_cutoff")
truthy(elecEv ~= nil, "electricity cutoff registered in ScopedWorldEvents")
eq(elecEv.scope, "global", "electricity cutoff is global")
local elecFact = WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:utility.electricity_cutoff:global")
truthy(elecFact ~= nil, "electricity cutoff fact published to WorldKnowledge")

-- Repeat calls do NOT duplicate
local repeatRes = Adapter.ObserveUtilities(10 * 24 + 1)
eq(#repeatRes, 0, "repeated utility check does NOT duplicate electricity cutoff")

-- 4. Water shutoff via day >= waterShutDay -> exactly one global event + fact
mockWorldDays = 14
hookCallbacks.EveryHours[1]()
local waterEv = ScopedEvents.Get("core:utility:water_cutoff")
truthy(waterEv ~= nil, "water cutoff registered in ScopedWorldEvents")
eq(waterEv.scope, "global", "water cutoff is global")
local waterFact = WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, "fact:core:utility.water_cutoff:global")
truthy(waterFact ~= nil, "water cutoff fact published to WorldKnowledge")

-- 5. Save/reload preserves utility watermarks -> zero duplicates after reload
assert(ScopedEvents.SaveToModData({ nowHours = 14 * 24 }))
ScopedEvents.Reset()
Observer.Reset()
assert(ScopedEvents.LoadFromModData({ nowHours = 15 * 24 }))
local postReloadRes = Adapter.ObserveUtilities(15 * 24)
eq(#postReloadRes, 0, "post-reload utility check does not duplicate cutoffs")
truthy(ScopedEvents.Get("core:utility:electricity_cutoff") ~= nil, "electricity cutoff survives reload")
truthy(ScopedEvents.Get("core:utility:water_cutoff") ~= nil, "water cutoff survives reload")

-- 6. Power restoration closes active electricity cutoff event cleanly
mockPowerOn = true
mockWorldDays = 16
local restoreRes = Adapter.ObserveUtilities(16 * 24)
eq(#restoreRes, 1, "restoration emitted 1 close transition")
falsy(ScopedEvents.Get("core:utility:electricity_cutoff"), "restored electricity removes cutoff from active registry")
eq(Observer.GetUtilityState("electricity").cutoffEmitted, false, "cutoffEmitted cleared on restore")

print("psychopatz_vanilla_utilities_smoke: OK")
