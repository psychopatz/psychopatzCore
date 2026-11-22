local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local VERSIONED_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = VERSIONED_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local T = {}
function T.equal(actual, expected, label)
    if actual ~= expected then
        error((label or "eq") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end
function T.truthy(val, label)
    if not val then error(label or "expected truthy") end
end
function T.finish(name)
    print(tostring(name or "test") .. ": OK")
end

local mockHours = 200.0
local modData = {}
local hooks = {
    OnGameStart = {},
    OnInitGlobalModData = {},
    OnSave = {},
    OnElectricityChanged = {},
    EveryHours = {},
    EveryTenMinutes = {},
    OnAmbientSound = {},
    OnWorldSound = {},
    OnThunderEvent = {},
    OnNewFire = {},
    LoadChunk = {},
    OnSpawnVehicleEnd = {},
    OnSeeNewRoom = {},
}

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return mockHours / 24 end,
        getWorldAgeHours = function() return mockHours end,
    }
end
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
    get = function(key) return modData[key] end,
    transmit = function() return true end,
}
Events = {}
for k, v in pairs(hooks) do
    Events[k] = {
        Add = function(fn) v[#v + 1] = fn end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local PZAdapter = Core.WorldEventAdapter
local Discovery = Core.VanillaDiscoveryAdapter
local Location = Core.WorldEventLocation
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

ScopedEvents.Reset({ nowHours = mockHours })
Observer.Reset()
Discovery.Reset()
WKG.Reset({ now = mockHours })
Location.ClearProviders()
Location.RegisterProvider("soak_regions", function(x, y)
    local cellX = math.floor(x / 300)
    local cellY = math.floor(y / 300)
    return {
        regionID = "region_" .. tostring(cellX) .. "_" .. tostring(cellY),
        settlementID = "settlement_" .. tostring(cellX) .. "_" .. tostring(cellY),
        localAreaID = "area_" .. tostring(math.floor(x / 100)) .. "_" .. tostring(math.floor(y / 100)),
        label = "Sector " .. tostring(cellX) .. ":" .. tostring(cellY),
        kind = "region",
    }
end, 10)

-- 1. 2,000+ ephemeral wildlife/thunder invocations produce 0 persistent ledger/scoped writes.
for i = 1, 800 do
    PZAdapter.OnAmbientSound("MetaDogBark", 3000 + (i % 50), 3000 + (i % 50), { hours = mockHours + i * 0.001 })
    PZAdapter.OnAmbientSound("MetaOwl", 4000 + (i % 40), 4000 + (i % 40), { hours = mockHours + i * 0.001 })
    PZAdapter.OnThunderEvent(3500 + i, 3500, false, false, false, { hours = mockHours + i * 0.001 })
end
T.equal(ScopedEvents.GetStats().activeCount, 0, "2400 ephemeral ambience/thunder calls produce 0 active ScopedEvents")
T.equal(#WKG.Ledger.Query(WKG.LedgerState, {}), 0, "2400 ephemeral ambience/thunder calls produce 0 WorldKnowledge ledger facts")

-- 2. Helicopter 120 updates across 4 coarse regions keep <= 5 locationHistory samples & single episode.
for step = 0, 119 do
    local x = 3100 + math.floor(step / 30) * 650
    local y = 3100 + math.floor(step / 30) * 650
    PZAdapter.ObserveHelicopter(mockHours + step * 0.02, {
        helicopter = {
            isActive = function() return true end,
            x = x,
            y = y,
        },
    })
end
local heliActive = ScopedEvents.QueryActive({ eventType = "world_helicopter_overflight" }, mockHours + 2.4)
T.equal(#heliActive, 1, "120 helicopter ticks maintain 1 canonical episode")
local sampleCount = Observer.GetHelicopterState().sampleCount or 1
T.truthy(sampleCount >= 1 and sampleCount <= 5, "helicopter sample cap enforced (" .. tostring(sampleCount) .. " <= 5)")
PZAdapter.ObserveHelicopter(mockHours + 2.5, {
    helicopter = {
        isActive = function() return false end,
        x = 3100,
        y = 3100,
    },
})

-- 3. 250 gunfire/scream/alarm events across coarse buckets + 160 world-story discoveries obey strict caps.
for i = 1, 250 do
    local x = 1000 + (i % 45) * 400
    local y = 1000 + math.floor(i / 45) * 400
    local name = (i % 3 == 0) and "MetaShotgun1" or ((i % 3 == 1) and "MetaScream" or "burglar2")
    PZAdapter.OnAmbientSound(name, x, y, { hours = mockHours + 3 + i * 0.05 })
end

for i = 1, 160 do
    local x = 2000 + i * 250
    local y = 2000 + i * 250
    for _, fn in ipairs(hooks.LoadChunk) do
        fn({
            vehicleStorySpawnData = {
                story = { getName = function() return (i % 2 == 0) and "Ambulance Crash" or "Bandits on Road" end },
                spawnX = x,
                spawnY = y,
            },
        })
    end
end
T.truthy(#(Discovery._pendingOrder or {}) <= 64, "pending discovery buffer capped at <= 64 (" .. tostring(#(Discovery._pendingOrder or {})) .. ")")

for i = 1, 80 do
    local x = 2000 + i * 250
    local y = 2000 + i * 250
    Discovery.DiscoverNearPoint(x, y, 50, { nowHours = mockHours + 16 })
end

local scStats = ScopedEvents.GetStats()
local obStats = Observer.GetStats()
local factCount = #WKG.Ledger.Query(WKG.LedgerState, {})

T.truthy(scStats.activeCount <= 32, "ScopedEvents activeCount bounded <= 32 (" .. tostring(scStats.activeCount) .. ")")
T.truthy(scStats.historyCount <= 64, "ScopedEvents historyCount bounded <= 64 (" .. tostring(scStats.historyCount) .. ")")
T.truthy(factCount <= 256, "WorldKnowledge ledger count bounded <= 256 (" .. tostring(factCount) .. ")")
T.truthy(obStats.cooldownCount <= 128, "Observer cooldown cache bounded <= 128 (" .. tostring(obStats.cooldownCount) .. ")")
T.truthy(obStats.discoveryCount <= 256, "Observer discovery cache bounded <= 256 (" .. tostring(obStats.discoveryCount) .. ")")

-- 4. Save / Reload persistence preserves caps, deduplicates utility cutoffs, and prunes expired entries.
PZAdapter.ObserveUtilities(mockHours + 17, { powerOn = true, waterOn = true })
PZAdapter.ObserveUtilities(mockHours + 18, { powerOn = false, waterOn = false })
local okSave = ScopedEvents.SaveToModData({ nowHours = mockHours + 18 })
local persistedRoot = modData[ScopedEvents.MODDATA_KEY]
T.truthy(okSave and type(persistedRoot) == "table" and #(persistedRoot.activeEvents or {}) <= 32,
    "serialized ModData activeEvents payload bounded <= 32")

local reloadAt = mockHours + 200
mockHours = reloadAt
ScopedEvents.Reset({ nowHours = 0 })
ScopedEvents.LoadFromModData({ nowHours = reloadAt })
local postExpiryStats = ScopedEvents.GetStats()
T.truthy(postExpiryStats.activeCount <= 2, "expired non-utility local events pruned on reload leaving only durable utilities")

-- Utility state remains exactly-once across repeated reload checks.
PZAdapter.ObserveUtilities(reloadAt + 1, { powerOn = false, waterOn = false })
T.equal(#ScopedEvents.QueryActive({ eventType = "utility_electricity_cutoff" }, reloadAt + 1), 1,
    "electricity cutoff remains exactly-once across reload")
T.equal(#ScopedEvents.QueryActive({ eventType = "utility_water_cutoff" }, reloadAt + 1), 1,
    "water cutoff remains exactly-once across reload")

T.finish("psychopatz_v8_world_event_scale_soak_smoke")
