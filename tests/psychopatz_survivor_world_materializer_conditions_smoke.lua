-- Verify PsychopatzCore SurvivorWorld EventMaterializer (one-shot idempotency
-- for any mod's world events) and TravelConditions (day/night/rain/storm).

package.path = "./Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. "./Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. package.path

local SurvivorWorld = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Events = SurvivorWorld.Events
local Materializer = SurvivorWorld.EventMaterializer
local Conditions = SurvivorWorld.TravelConditions

Events.Reset()
Materializer.Reset()

-- 1. TravelConditions: clear noon vs night vs tropical storm.
local cDay = Conditions.Evaluate({ timeOfDay = 12, rainIntensity = 0, fogIntensity = 0, isStorm = false })
assert(cDay.speedMultiplier == 1.0 and cDay.shouldSeekShelter == false, "clear day speed == 1.0")

local cNight = Conditions.Evaluate({ timeOfDay = 23, rainIntensity = 0, fogIntensity = 0, isStorm = false })
assert(cNight.speedMultiplier < 0.85 and cNight.isNight == true, "night slows travel")

local cStorm = Conditions.Evaluate({ timeOfDay = 23, rainIntensity = 0.9, fogIntensity = 0.5, isStorm = true })
assert(cStorm.speedMultiplier <= 0.60 and cStorm.shouldSeekShelter == true, "storm slows travel & advises shelter")

-- 2. EventMaterializer: one-shot materialization when player approaches loaded square.
local prevGetCell = _G.getCell
local fakeSquare = { kind = "loaded_square" }
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y)
            if x == 1200 and y == 1400 then return fakeSquare end
            return nil
        end,
    }
end

local handlerCalls = 0
Materializer.RegisterHandler("FUTURE_AIRDROP", function(ev, sq)
    assert(ev.id == "evt_drop_1", "event passed to handler")
    assert(sq == fakeSquare, "loaded square passed to handler")
    handlerCalls = handlerCalls + 1
    return true, "spawned"
end)

Events.Publish({
    id = "evt_drop_1",
    kind = "FUTURE_AIRDROP",
    ownerMod = "EventsMod",
    x = 1200,
    y = 1400,
    ttlHours = 24,
}, 10.0)

local farPlayer = { getX = function() return 5000 end, getY = function() return 5000 end }
local nearPlayer = { getX = function() return 1210 end, getY = function() return 1405 end }

-- Far player does not trigger materialization.
assert(Materializer.PumpNearPlayers({ farPlayer }, 55, 11.0, 2) == 0, "far player skipped")
assert(handlerCalls == 0, "handler not called for far player")

-- Near player triggers materialization exactly once.
assert(Materializer.PumpNearPlayers({ nearPlayer }, 55, 11.0, 2) == 1, "near player materialized 1 event")
assert(handlerCalls == 1, "handler called once")

-- Second pump is a no-op (idempotent one-shot!).
assert(Materializer.PumpNearPlayers({ nearPlayer }, 55, 12.0, 2) == 0, "second pump does not duplicate")
assert(handlerCalls == 1, "handler still called only once")

local updatedEv = Events.Get("evt_drop_1")
assert(updatedEv and updatedEv.payload and updatedEv.payload.materialized == true, "event marked materialized")

_G.getCell = prevGetCell
Events.Reset()
Materializer.Reset()
print("PASS: psychopatz_survivor_world_materializer_conditions_smoke")
