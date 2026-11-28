local root = debug.getinfo(1, "S").source:match("^@?(.*)/tests/") or "."
package.path = root .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. package.path

local SurvivorWorld = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local WorldEvents = SurvivorWorld.Events
local Materializer = SurvivorWorld.EventMaterializer
local CorridorGraph = SurvivorWorld.CorridorGraph
local Diplomacy = SurvivorWorld.Diplomacy

-- Mock PZ cell & player for materializer verification.
local spawnedLog = {}
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return { x = x, y = y, z = z }
        end,
    }
end
local player = { getX = function() return 1000 end, getY = function() return 1000 end }

-- 1. Modular EventMaterializer: blueprints, tag matching, priority, custom radius & cleanup.
WorldEvents.Reset()
Materializer.Reset()
Materializer.RegisterDefaultBlueprints()
Materializer.ItemSpawner = function(_, itemType)
    spawnedLog[#spawnedLog + 1] = itemType
    return true
end

-- Built-in CAMP_REMAINS blueprint materializes automatically on player approach.
WorldEvents.Publish({
    id = "camp_1",
    kind = "CAMP_REMAINS",
    x = 1010,
    y = 1010,
    z = 0,
    ttlHours = 12,
}, 10.0)
local matCount = Materializer.PumpNearPlayers({ player }, 55, 10.5, 4)
assert(matCount == 1, "expected CAMP_REMAINS blueprint to materialize")
assert(#spawnedLog >= 1, "expected blueprint to spawn camp clue items")

-- Custom third-party mod registers tag-matched descriptor with priority & cleanup hook.
local customMaterialized = false
local customCleaned = false
Materializer.Register("future_mod:roadblock", {
    ownerMod = "FutureWorldEventsMod",
    tag = "custom_roadblock",
    priority = 90,
    radius = 80,
    canMaterialize = function(ev) return ev.severity >= 2 end,
    materialize = function()
        customMaterialized = true
        return true, { spawned = "barricade" }
    end,
    cleanup = function()
        customCleaned = true
    end,
})

WorldEvents.Publish({
    id = "rb_1",
    kind = "MILITARY_CHECKPOINT",
    ownerMod = "FutureWorldEventsMod",
    x = 1065,
    y = 1000,
    z = 0,
    severity = 3,
    tags = { custom_roadblock = true },
    ttlHours = 6,
}, 10.0)
-- Default pump radius is 55, but handler's custom radius is 80 so 65 tiles triggers!
local mat2 = Materializer.PumpNearPlayers({ player }, 55, 11.0, 4)
assert(mat2 == 1 and customMaterialized == true, "custom tag-matched handler should materialize at 65 tiles")

-- Expiring the event automatically dispatches the registered cleanup hook!
WorldEvents.PruneExpired(20.0)
assert(customCleaned == true, "cleanup hook must fire when materialized event expires")

assert(Materializer.UnregisterByOwner("FutureWorldEventsMod") == 1, "UnregisterByOwner should remove mod handlers")

-- 2. Core CorridorGraph lazy-decaying trafficHeat & settlement demand signals.
CorridorGraph.Reset()
CorridorGraph.RecordTrafficHeat(2000, 2000, 2.5, 10.0)
assert(CorridorGraph.GetTrafficHeat(2000, 2000, 10.0) >= 2.4, "heat should be recorded")
local hot = CorridorGraph.FindHottestCorridorPoint(2200, 2000, 600, 10.0)
assert(hot and hot.heat >= 2.4, "Looter should find hottest active supply corridor")
-- After 48h * 3 = 144h, heat decays to 0 cleanly.
assert(CorridorGraph.GetTrafficHeat(2000, 2000, 200.0) == 0, "heat must lazily decay to 0")

CorridorGraph.RegisterSettlementNode("s_needy", 3000, 3000, 0, { owner = "ai" })
CorridorGraph.UpdateSettlementState("s_needy", { foodRatio = 0.15, waterRatio = 0.40, demandLevel = "shortage" })
local needy = CorridorGraph.FindSettlementsByDemand(3100, 3000, 800, true)
assert(#needy == 1 and needy[1].anchorId == "s_needy", "Caravans should find shortage settlements")

-- 3. Core Diplomacy: relational & desperation-driven hostility (not hardcoded to LOOTER).
local wellFedRefugee = { groupType = "REFUGEE", factionId = "f_ref", resources = { food = 40, water = 40 } }
local starvingRefugee = { groupType = "REFUGEE", factionId = "f_ref2", resources = { food = 2, water = 2 }, needs = { morale = 0.15 } }
local trader = { groupType = "TRADER", factionId = "f_trd", resources = { food = 50, water = 50 } }
local looter = { groupType = "LOOTER", factionId = "f_loot" }
local settlement = { type = "SETTLEMENT", factionId = "f_set" }

local s1, h1 = Diplomacy.EvaluateEncounterStance(wellFedRefugee, trader, 0)
assert(s1 == "NEUTRAL" and h1 == false, "well-fed neutral refugee should be peaceful")

local s2, h2, r2 = Diplomacy.EvaluateEncounterStance(starvingRefugee, trader, 0)
assert(s2 == "DESPERATE_HOSTILE" and h2 == true and r2 == "desperation_flip",
    "starving refugee should flip into desperate hostility")

local s3, h3, r3 = Diplomacy.EvaluateEncounterStance(wellFedRefugee, trader, -50)
assert(s3 == "HOSTILE" and h3 == true and r3 == "faction_hostility",
    "hostile-relation refugee must be hostile regardless of archetype label")

local s4, h4, r4 = Diplomacy.EvaluateEncounterStance(looter, settlement, 0)
assert(s4 == "RAID_HOSTILE" and h4 == true and r4 == "looter_predation",
    "looter encountering settlement must trigger RAID_HOSTILE")

print("PASS psychopatz_survivor_world_emergent_materializer_smoke")
