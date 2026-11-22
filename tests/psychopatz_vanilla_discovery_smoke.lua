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

local mockClockHours = 80
local hooks = {
    LoadChunk = {},
    OnSpawnVehicleEnd = {},
    OnSeeNewRoom = {},
}

Events = {}
for k, list in pairs(hooks) do
    Events[k] = {
        Add = function(fn) list[#list + 1] = fn end,
    }
end

function getGameTime()
    return { getWorldAgeHours = function() return mockClockHours end }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Discovery = Core.VanillaDiscoveryAdapter
local Location = Core.WorldEventLocation
local WorldKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

ScopedEvents.Reset()
Observer.Reset()
Discovery.Reset()
WorldKnowledge.Reset()
Location.ClearProviders()

truthy(#hooks.LoadChunk >= 1, "LoadChunk discovery hook installed")
truthy(#hooks.OnSpawnVehicleEnd >= 1, "OnSpawnVehicleEnd discovery hook installed")
truthy(#hooks.OnSeeNewRoom >= 1, "OnSeeNewRoom discovery hook installed")

-- 1. Streaming a chunk with Ambulance Crash, Murder Scene, and Ranch ONLY records pending sites (NO omniscience!)
local chunkRecorded = Discovery.InspectChunk({
    vehicleStorySpawnData = {
        story = { getName = function() return "Ambulance Crash" end },
        spawnX = 8150,
        spawnY = 11520,
    },
    zones = {
        {
            type = "ZoneStory",
            pickedRzStory = { getName = function() return "Murder Scene" end },
            pickedXForZoneStory = 8160,
            pickedYForZoneStory = 11530,
        },
        {
            type = "Ranch",
            name = "cow",
            x = 8170,
            y = 11540,
        },
    },
}, { nowHours = mockClockHours })
eq(chunkRecorded, 3, "InspectChunk buffered 3 pending stories")
eq(ScopedEvents.GetStats().activeCount, 0, "NO omniscient facts or scoped events created before discovery")
eq(#WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 50 }), 0,
    "WorldKnowledge remains empty until observer discovers site")

-- 2. Observer far away promotes nothing
local farPromote = Discovery.DiscoverNearPoint(12000, 3000, 75, { nowHours = mockClockHours })
eq(#farPromote, 0, "far observer does not discover pending sites")

-- 3. Observer enters area -> promotes Ambulance Crash, Murder Scene, and Ranch to canonical facts & scoped events
local localPromote = Discovery.DiscoverNearPoint(8155, 11525, 75, { nowHours = mockClockHours })
eq(#localPromote, 3, "nearby observer discovers all 3 local sites")

local facts = WorldKnowledge.Ledger.Query(WorldKnowledge.LedgerState, { max = 50 })
local byKind = {}
for i = 1, #facts do
    byKind[facts[i].kind] = facts[i]
end
local amb = byKind["discovery.vehicle_story.ambulance_crash"]
truthy(amb ~= nil, "mandatory ambulance crash discovery published")
eq(amb.payload.vanillaSourceID, "RVSAmbulanceCrash", "exact RVSAmbulanceCrash identity preserved")

local murder = byKind["discovery.zone_story.murder_scene"]
truthy(murder ~= nil, "zone murder scene discovery published")
eq(murder.payload.vanillaSourceID, "RZSMurderScene", "exact RZSMurderScene identity preserved")

local ranch = byKind["discovery.ranch_livestock"]
truthy(ranch ~= nil, "ranch discovery published")
eq(ranch.payload.animalType, "cow", "ranch animalType preserved")

-- 4. Duplicate ambulance story at same area is fingerprint-deduped
local dupAmb = assert(Discovery.DiscoverVehicleStory("RVSAmbulanceCrash", 8155, 11525, { nowHours = mockClockHours + 1 }))
eq(dupAmb.status, "deduped", "repeat ambulance discovery in same area deduped")
eq(dupAmb.reason, "discovery_fingerprint_exists", "discovery dedupe reason")

-- 5. OnSpawnVehicleEnd captures spawned VanAmbulance even if vehicleStorySpawnData was already cleared
local ambFallback = Discovery.OnSpawnVehicleEnd({
    getScriptName = function() return "Base.VanAmbulance" end,
    getX = function() return 10520 end,
    getY = function() return 10620 end,
}, { observerPresent = true, nowHours = mockClockHours })
eq(ambFallback.observation.semanticType, "discovery.vehicle_story.ambulance_crash",
    "OnSpawnVehicleEnd identifies Base.VanAmbulance crash cleanly")

-- 6. Bandit road, police blockade, crash horde, survivalist camp stories
local banditRoad = assert(Discovery.DiscoverVehicleStory("Bandits on Road", 6120, 5220, { nowHours = mockClockHours }))
eq(banditRoad.observation.semanticType, "discovery.vehicle_story.bandit_road", "bandit road mapped")
local blockade = assert(Discovery.DiscoverVehicleStory("Police Blockade Shooting", 6420, 5220, { nowHours = mockClockHours }))
eq(blockade.observation.semanticType, "discovery.vehicle_story.police_blockade", "police blockade mapped")
local crashHorde = assert(Discovery.DiscoverVehicleStory("Crash Horde", 6720, 5220, { nowHours = mockClockHours }))
eq(crashHorde.observation.semanticType, "discovery.vehicle_story.crash_horde", "crash horde mapped")
local survCamp = assert(Discovery.DiscoverZoneStory("Survivalist Campsite", 7020, 5220, { nowHours = mockClockHours }))
eq(survCamp.observation.semanticType, "discovery.zone_story.survivalist_camp", "survivalist camp mapped")

-- 7. Observable building & dead-survivor scenes (no fabricated RB*/RDS* internal class!)
local gunSiege = assert(Discovery.InspectRoomObservation({
    roomName = "gunstore",
    barricadeCount = 3,
    weaponBagCount = 2,
    deadBodyCount = 2,
    x = 7520,
    y = 5520,
}, { nowHours = mockClockHours }))
eq(gunSiege.observation.semanticType, "discovery.building_scene.gunstore_siege", "observable gunstore siege")
eq(gunSiege.fact.payload.vanillaSourceID, "observable_room_scene", "never fabricates unexposed RB* class ID")

local safehouse = assert(Discovery.InspectRoomObservation({
    roomName = "livingroom",
    barricadeCount = 4,
    survivorBagCount = 1,
    x = 7820,
    y = 5520,
}, { nowHours = mockClockHours }))
eq(safehouse.observation.semanticType, "discovery.building_scene.safehouse", "observable safehouse")

local banditRaid = assert(Discovery.InspectRoomObservation({
    roomName = "hall",
    banditCount = 2,
    deadBodyCount = 2,
    x = 8420,
    y = 5520,
}, { nowHours = mockClockHours }))
eq(banditRaid.observation.semanticType, "discovery.dead_survivor.bandit_raid", "observable bandit raid")

local suicide = assert(Discovery.InspectRoomObservation({
    roomName = "bedroom",
    hasSuicideClues = true,
    deadBodyCount = 2,
    x = 8720,
    y = 5520,
}, { nowHours = mockClockHours }))
eq(suicide.observation.semanticType, "discovery.dead_survivor.suicide_pact", "observable suicide scene")

local rats = assert(Discovery.InspectRoomObservation({
    roomName = "kitchen",
    ratCount = 5,
    x = 9020,
    y = 5520,
}, { nowHours = mockClockHours }))
eq(rats.observation.semanticType, "discovery.dead_survivor.rat_infestation", "observable rat infestation")

print("psychopatz_vanilla_discovery_smoke: OK")
