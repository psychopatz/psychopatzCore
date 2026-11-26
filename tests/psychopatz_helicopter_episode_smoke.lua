local T = require "tests/support/test"
T.addPackagePaths()

local SHARED_ROOT = T.layerRoot("common_shared")
local VERSIONED_ROOT = T.layerRoot("runtime_shared")
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

local mockClockHours = 100
local mockModData = {}
local heliState = { active = false, x = 8050, y = 11550 }
local everyTenMinutesHandlers = {}

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
    EveryTenMinutes = {
        Add = function(fn) everyTenMinutesHandlers[#everyTenMinutesHandlers + 1] = fn end,
    },
}

function getWorld()
    return {
        helicopter = {
            isActive = function() return heliState.active end,
            x = heliState.x,
            y = heliState.y,
        },
    }
end

-- Update coordinates cleanly when testing movement
local function setHeli(active, x, y)
    heliState.active = active
    heliState.x = x or heliState.x
    heliState.y = y or heliState.y
end

function getGameTime()
    return {
        getWorldAgeHours = function() return mockClockHours end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Adapter = Core.WorldEventAdapter
local Location = Core.WorldEventLocation
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

ScopedEvents.Reset()
Observer.Reset()
WorldKnowledge.Reset()
Location.ClearProviders()

Location.RegisterProvider("heli_settlements", function(x, y)
    if x >= 8000 and x <= 8200 and y >= 11400 and y <= 11600 then
        return {
            settlementID = "settlement:rosewood",
            regionID = "region_south",
            label = "Rosewood",
            kind = "settlement",
        }
    end
    return nil
end, 10)

local regCount = 0
ScopedEvents.OnEventRegistered(function()
    regCount = regCount + 1
end, { id = "count_heli_writes" })

local function heliReader()
    return {
        isActive = function() return heliState.active end,
        x = heliState.x,
        y = heliState.y,
    }
end

-- 1. Inactive -> nothing written
local idleRes, idleStatus = Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() })
falsy(idleRes, "inactive helicopter creates no episode")
eq(idleStatus, "helicopter_inactive", "inactive status")

-- 2. Inactive -> active starts ONE regional episode + ONE canonical fact
setHeli(true, 8050, 11550)
mockClockHours = 101
local startRes = assert(Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() }))
eq(startRes.action, "started", "helicopter episode started")
eq(regCount, 1, "start performs 1 scoped event registration")
eq(ScopedEvents.GetStats().activeCount, 1, "single canonical helicopter event")

local ev = ScopedEvents.Get(startRes.eventID)
truthy(ev ~= nil, "helicopter scoped event active")
eq(ev.scope, "region", "helicopter uses regional scope when resolved")
eq(ev.scopeID, "region_south", "helicopter regional scopeID")
local fact = WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, startRes.factID)
truthy(fact ~= nil, "canonical helicopter fact published")
eq(fact.payload.sampleCount, 1, "initial sampleCount = 1")

-- 3. Active within same coarse 100x100 bucket -> ZERO persistent writes
for i = 1, 10 do
    setHeli(true, 8050 + i, 11550 - i)
    mockClockHours = 101 + i * 0.01
    local sameRes, sameStatus = Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() })
    falsy(sameRes, "same bucket skips write")
    eq(sameStatus, "same_coarse_region", "same coarse region status")
end
eq(regCount, 1, "10 small moves in same bucket caused 0 extra writes")

-- 4. Meaningful coarse moves across 8 buckets -> capped at MAX_EPISODE_SAMPLES = 5
for step = 1, 8 do
    setHeli(true, 8500 + step * 350, 11550)
    mockClockHours = 102 + step * 0.05
    local moveRes = Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() })
    truthy(moveRes and moveRes.action == "updated", "coarse move updates canonical episode")
end
local updatedFact = WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, startRes.factID)
eq(updatedFact.payload.sampleCount, Observer.MAX_EPISODE_SAMPLES,
    "helicopter sample count strictly capped at MAX_EPISODE_SAMPLES=5")
eq(ScopedEvents.GetStats().activeCount, 1, "still only ONE active helicopter event")

-- 5. Save & reload while active preserves episode identity without duplicating
assert(ScopedEvents.SaveToModData({ nowHours = mockClockHours }))
local savedWkg = WorldKnowledge.ToPayload()
ScopedEvents.Reset()
Observer.Reset()
WorldKnowledge.Reset()
assert(ScopedEvents.LoadFromModData({ nowHours = mockClockHours + 0.1 }))
assert(WorldKnowledge.FromPayload(savedWkg, { now = mockClockHours + 0.1 }))

local samePostReload, samePostStatus = Adapter.ObserveHelicopter(mockClockHours + 0.2, {
    helicopter = heliReader(),
})
falsy(samePostReload, "post-reload same area does NOT duplicate episode")
eq(samePostStatus, "same_coarse_region", "post-reload same area status")
eq(Observer.GetHelicopterState().episodeSeq, 1, "episodeSeq stays 1 across reload")

-- 6. Active -> inactive ends episode cleanly and moves to history
setHeli(false, heliState.x, heliState.y)
mockClockHours = 103
local endRes = assert(Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() }))
eq(endRes.action, "ended", "helicopter episode ended")
falsy(ScopedEvents.Get(startRes.eventID), "ended helicopter removed from active events")
eq(#ScopedEvents.GetHistory(10), 1, "ended helicopter archived in history")
local endedFact = WorldKnowledge.Ledger.Get(WorldKnowledge.LedgerState, startRes.factID)
eq(endedFact.payload.phase, "end", "canonical fact marked end")

-- 7. Next overflight increments episodeSeq cleanly
setHeli(true, 10620, 10020)
mockClockHours = 120
local nextRes = assert(Adapter.ObserveHelicopter(mockClockHours, { helicopter = heliReader() }))
eq(nextRes.action, "started", "second helicopter overflight starts new episode")
eq(Observer.GetHelicopterState().episodeSeq, 2, "second episode increments seq to 2")

print("psychopatz_helicopter_episode_smoke: OK")
