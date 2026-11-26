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

local mockClockHours = 50
local mockSeason = "Summer"
local hooks = {}

Events = {}
for _, name in ipairs({
    "OnAmbientSound",
    "OnWorldSound",
    "OnWeatherPeriodStart",
    "OnWeatherPeriodStage",
    "OnWeatherPeriodComplete",
    "OnWeatherPeriodStop",
    "OnThunderEvent",
    "OnDeviceText",
    "OnNewFire",
}) do
    hooks[name] = {}
    Events[name] = {
        Add = function(fn)
            hooks[name][#hooks[name] + 1] = fn
        end,
    }
end

function getGameTime()
    return { getWorldAgeHours = function() return mockClockHours end }
end

function getClimateManager()
    return { getSeasonName = function() return mockSeason end }
end

function instanceof(obj, cls)
    return type(obj) == "table" and obj._class == cls
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

for name, list in pairs(hooks) do
    truthy(#list >= 1, "Core hook registered for " .. name)
end

-- 1. All 5 gunfire variants normalize to ambient.gunfire with exact vanillaSourceID
local gunVariants = {
    { "MetaAssaultRifle1", "rifle", 8150, 11520 },
    { "MetaPistol1", "pistol", 8450, 11520 },
    { "MetaPistol2", "pistol", 8750, 11520 },
    { "MetaPistol3", "pistol", 9050, 11520 },
    { "MetaShotgun1", "shotgun", 9350, 11520 },
}
for _, item in ipairs(gunVariants) do
    local res = assert(Adapter.OnAmbientSound(item[1], item[3], item[4], { nowHours = mockClockHours }))
    eq(res.observation.semanticType, "ambient.gunfire", item[1] .. " normalized to ambient.gunfire")
    eq(res.fact.payload.weaponClass, item[2], item[1] .. " preserves weaponClass")
    eq(res.fact.payload.vanillaSourceID, item[1], item[1] .. " preserves vanillaSourceID")
    eq(res.scopedEvent.scope, "local_area", item[1] .. " scoped to local_area")
end

-- 2. Scream normalizes to ambient.scream
local screamRes = assert(Adapter.OnAmbientSound("MetaScream", 10100, 10200, { nowHours = mockClockHours }))
eq(screamRes.observation.semanticType, "ambient.scream", "MetaScream normalized")
eq(screamRes.fact.payload.vanillaSourceID, "MetaScream", "MetaScream source preserved")

-- 3. House alarms: SP Alarm world sound + MP burglar2 share same deduped semantic category
local nonAlarm, nonAlarmReason = Adapter.OnWorldSound(8150, 11520, 0, 50, 50, { _class = "IsoZombie" })
falsy(nonAlarm, "non-Alarm world sound rejected in O(1) fast guard")
eq(nonAlarmReason, "ignored_non_alarm", "non-Alarm reject reason")

local alarmSP = assert(Adapter.OnWorldSound(8150, 11520, 0, 600, 600, { _class = "Alarm" }, { nowHours = mockClockHours }))
eq(alarmSP.observation.semanticType, "world.house_alarm", "SP Alarm mapped to world.house_alarm")
-- Repeated tick of SP Alarm in same area is cooldown-deduped
local alarmSPDup = assert(Adapter.OnWorldSound(8150, 11520, 0, 600, 600, { _class = "Alarm" }, { nowHours = mockClockHours + 0.01 }))
eq(alarmSPDup.status, "deduped", "per-tick Alarm world sound deduped")
-- Second alarm in another area via burglar2
local alarmMP = assert(Adapter.OnAmbientSound("burglar2", 10550, 10650, { nowHours = mockClockHours }))
eq(alarmMP.observation.semanticType, "world.house_alarm", "burglar2 mapped to world.house_alarm")

-- 4. Low-value wildlife & thunder: 1000 calls produce 0 ScopedWorldEvents & 0 WorldKnowledge facts
local beforeActive = ScopedEvents.GetStats().activeCount
local beforeFacts = #WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 200 })
local ephemeralCount = 0
Observer.OnEphemeral(function() ephemeralCount = ephemeralCount + 1 end, { id = "v5_ephem_count" })

for i = 1, 250 do
    Adapter.OnAmbientSound("MetaDogBark", 8150 + i, 11520, { nowHours = mockClockHours + i * 0.001 })
    Adapter.OnAmbientSound("MetaOwl", 8150 + i, 11520, { nowHours = mockClockHours + i * 0.001 })
    Adapter.OnAmbientSound("MetaWolfHowl", 8150 + i, 11520, { nowHours = mockClockHours + i * 0.001 })
    Adapter.OnThunderEvent(8150 + i, 11520, true, false, true, { nowHours = mockClockHours + i * 0.001 })
end
eq(ephemeralCount, 1000, "all 1000 ephemeral sounds triggered transient listener")
eq(ScopedEvents.GetStats().activeCount, beforeActive, "0 ScopedWorldEvents added by wildlife/thunder")
eq(#WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 200 }), beforeFacts,
    "0 WorldKnowledge facts added by wildlife/thunder")

-- 5. WeatherPeriod: mild rain is ephemeral, blizzard is regional severe_storm episode & closes cleanly
local mildRain = assert(Adapter.OnWeatherPeriodEvent("start", {
    isBlizzard = function() return false end,
    isTropicalStorm = function() return false end,
    isThunderStorm = function() return false end,
    getCurrentStrength = function() return 0.35 end,
}, { nowHours = mockClockHours, regionID = "region_south" }))
eq(mildRain.status, "ephemeral", "mild rain stays ephemeral")

local blizzardStart = assert(Adapter.OnWeatherPeriodEvent("start", {
    isBlizzard = function() return true end,
    isTropicalStorm = function() return false end,
    isThunderStorm = function() return false end,
    getCurrentStrength = function() return 0.90 end,
}, { nowHours = mockClockHours, regionID = "region_south" }))
eq(blizzardStart.observation.semanticType, "weather.severe_storm", "blizzard creates severe_storm")
eq(blizzardStart.observation.scope, "region", "severe_storm is regional, never global")
truthy(ScopedEvents.Get(blizzardStart.eventID) ~= nil, "severe_storm active in ScopedWorldEvents")

local blizzardEnd = assert(Adapter.OnWeatherPeriodEvent("end", {
    isBlizzard = function() return true end,
    getCurrentStrength = function() return 0.10 end,
}, { nowHours = mockClockHours + 6, regionID = "region_south" }))
eq(blizzardEnd.status, "ended", "blizzard ended cleanly")
falsy(ScopedEvents.Get(blizzardStart.eventID), "ended severe_storm removed from active events")

-- 6. Radio broadcast (structured guid only) + Fire hazard + Season transition
local ignoredChatter, chatterErr = Adapter.OnDeviceText("", "", -1, -1, 0, "random line", nil)
falsy(ignoredChatter, "empty guid broadcast ignored without parsing text")
eq(chatterErr, "broadcast_metadata_absent", "broadcast missing metadata reason")

local radioRes = assert(Adapter.OnDeviceText("AEBS-001", "WTHR,CHOPPER", -1, -1, 0, "text", nil, {
    nowHours = mockClockHours,
    channelID = "AEBS",
}))
eq(radioRes.observation.semanticType, "media.broadcast", "structured radio broadcast recorded")
eq(radioRes.observation.provenance, "radio", "radio provenance preserved")

local fireRes = assert(Adapter.OnNewFire({
    getSquare = function() return { getX = function() return 10200 end, getY = function() return 10300 end, getZ = function() return 0 end } end,
}, { nowHours = mockClockHours }))
eq(fireRes.observation.semanticType, "world.fire_hazard", "fire hazard recorded")

-- Season: first observation records baseline, second transition emits event
local initSeason, initSeasonMsg = Adapter.ObserveSeason(mockClockHours)
falsy(initSeason, "initial season baseline recorded cleanly")
eq(initSeasonMsg, "initial_season_recorded", "initial season message")
mockSeason = "Autumn"
local transSeason = assert(Adapter.ObserveSeason(mockClockHours + 24))
eq(transSeason.observation.semanticType, "weather.season_transition", "season transition recorded")
eq(transSeason.fact.payload.previousSeason, "Summer", "previous season recorded")

print("psychopatz_vanilla_live_meta_events_smoke: OK")
