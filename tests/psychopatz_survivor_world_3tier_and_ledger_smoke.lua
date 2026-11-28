local root = debug.getinfo(1, "S").source:match("^@?(.*)/tests/") or "."
package.path = root .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua;"
    .. package.path

local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local RoutePlanner = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local ScavengeLedger = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"
local Bootstrap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrap"
local TravelConditions = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTravelConditions"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

-- 1. ScavengeLedger: 7-day (168h) lazy regen, smart 64-entry eviction & snapshot round-trip.
ScavengeLedger.Reset()
local k1 = ScavengeLedger.PackClusterKey(1000, 1000)
local d1 = ScavengeLedger.RecordScavengeByKey(k1, 0.90, 10.0)
assert(d1 >= 0.89 and ScavengeLedger.IsExhaustedByKey(k1, 10.0), "cluster should be exhausted at t=10")

-- Halfway through 7 days (84h later): 0.90 - 0.50 = 0.40 (no longer exhausted)
local halfDep = ScavengeLedger.GetDepletionByKey(k1, 94.0)
assert(halfDep > 0.35 and halfDep < 0.45, "expected ~0.40 depletion at +84h, got " .. tostring(halfDep))
assert(not ScavengeLedger.IsExhaustedByKey(k1, 94.0), "should no longer be exhausted at +84h")

-- Full 7 days (168h later): self-prunes to 0 on read
local fullDep = ScavengeLedger.GetDepletionByKey(k1, 178.0)
assert(fullDep == 0, "expected 0 depletion at +168h, got " .. tostring(fullDep))
assert(ScavengeLedger.State.count == 0, "healed entry should self-delete on read")

-- Smart eviction at MAX_ENTRIES = 64: lowest depletion gets evicted, freshly stripped survives.
ScavengeLedger.Reset()
local weakKey = ScavengeLedger.PackClusterKey(0, 0)
ScavengeLedger.RecordScavengeByKey(weakKey, 0.15, 100.0)
for i = 1, 63 do
    ScavengeLedger.RecordScavengeByKey(ScavengeLedger.PackClusterKey(i * 40, 0), 0.95, 100.0)
end
assert(ScavengeLedger.State.count == 64, "expected 64 entries before overflow")
local freshKey = ScavengeLedger.PackClusterKey(999 * 40, 0)
ScavengeLedger.RecordScavengeByKey(freshKey, 0.95, 100.0)
assert(ScavengeLedger.State.count == 64, "count must remain capped at 64")
assert(ScavengeLedger.GetDepletionByKey(weakKey, 100.0) == 0, "weakest entry should be evicted")
assert(ScavengeLedger.GetDepletionByKey(freshKey, 100.0) >= 0.90, "freshly stripped entry must survive")

local snap = ScavengeLedger.ExportSnapshot(100.0)
ScavengeLedger.Reset()
assert(ScavengeLedger.RestoreSnapshot(snap, 100.0), "snapshot restore should succeed")
assert(ScavengeLedger.GetDepletionByKey(freshKey, 100.0) >= 0.90, "restored entry must match")

-- 2. 3-Tier Map-Agnostic CorridorGraph (Urban Nav + Building POIs + Wilderness Fallback).
local function makeZone(ztype, x, y, w, h)
    return {
        getType = function() return ztype end,
        getX = function() return x end,
        getY = function() return y end,
        getWidth = function() return w end,
        getHeight = function() return h end,
    }
end

local function makeBuilding(x, y, w, h)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getW = function() return w end,
        getH = function() return h end,
    }
end

-- Sector (0,0) = urban town with Nav roads + 2 distinct house clusters.
-- Sector (5,5) = pure wilderness (0 Nav, 0 buildings) -> Tier 3 wilderness clearings!
local navZones = {
    makeZone("Nav", 60, 120, 180, 10),
    makeZone("Nav", 150, 40, 10, 180),
}
local buildings = {
    makeBuilding(90, 90, 12, 12),   -- House cluster A
    makeBuilding(210, 170, 14, 14), -- House cluster B
}

_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getZonesIntersecting = function(_, minX, minY, _, w, h)
                    local hits = {}
                    for i = 1, #navZones do
                        local z = navZones[i]
                        if z:getX() >= minX and z:getX() < minX + w
                            and z:getY() >= minY and z:getY() < minY + h
                        then
                            hits[#hits + 1] = z
                        end
                    end
                    return {
                        size = function() return #hits end,
                        get = function(_, idx) return hits[idx + 1] end,
                    }
                end,
                getBuildingsIntersecting = function(_, minX, minY, w, h)
                    local hits = {}
                    for i = 1, #buildings do
                        local b = buildings[i]
                        if b:getX() >= minX and b:getX() < minX + w
                            and b:getY() >= minY and b:getY() < minY + h
                        then
                            hits[#hits + 1] = b
                        end
                    end
                    return {
                        size = function() return #hits end,
                        get = function(_, idx) return hits[idx + 1] end,
                    }
                end,
            }
        end,
    }
end

CorridorGraph.Reset()
RoutePlanner.ClearCache()
ScavengeLedger.Reset()
CorridorGraph.SetWorldSeed(777)

local urbanSec = CorridorGraph.EnsureSector(0, 0)
local hasNav, hasPOI = false, false
for i = 1, #urbanSec.nodes do
    if urbanSec.nodes[i].kind == "nav" then hasNav = true end
    if urbanSec.nodes[i].kind == "poi" then hasPOI = true end
end
assert(hasNav and hasPOI, "urban sector should contain both Nav road and building POI nodes")

local wildSec = CorridorGraph.EnsureSector(5, 5)
local wildCount = 0
for i = 1, #wildSec.nodes do
    if wildSec.nodes[i].kind == "wilderness" then wildCount = wildCount + 1 end
end
assert(wildCount >= 4, "pure wilderness sector should generate deterministic trail/clearing nodes")

-- 3. House-to-house branching via SelectNextScavengePOI: exhausting House A branches to House B!
local firstPOI = RoutePlanner.SelectNextScavengePOI(95, 95, {
    minDistance = 0,
    maxDistance = 300,
    sectorRadius = 0,
    worldAgeHours = 50.0,
})
assert(firstPOI and firstPOI.kind == "poi", "expected House A POI selected")
ScavengeLedger.RecordScavengeByKey(firstPOI.poiKey, 0.95, 50.0)
local secondPOI = RoutePlanner.SelectNextScavengePOI(95, 95, {
    minDistance = 0,
    maxDistance = 300,
    sectorRadius = 0,
    worldAgeHours = 50.0,
})
assert(secondPOI and secondPOI.id ~= firstPOI.id, "exhausted POI must be skipped so scavenger branches out")

-- 4. Pit-stop waypoint tagging on planned corridor route.
local pitRoute, pitReason = RoutePlanner.PlanRoute(
    { x = 65, y = 125, z = 0 },
    { x = 215, y = 175, z = 0 },
    { archetype = "SCAVENGER", includePitStops = true, maxPitStops = 2, worldAgeHours = 50.0 }
)
assert(pitReason == "corridor_planned", "expected corridor_planned, got " .. tostring(pitReason))
assert(pitRoute.totalWaitHours >= 0, "route should normalize waitHours cleanly")

-- 5. Tier-1 Player & AI Settlement 800-tile spatial hash check.
CorridorGraph.RegisterSettlementNode("player_base_1", 1000, 1000, 0, { owner = "player" })
assert(CorridorGraph.HasSettlementWithin(1400, 1000, 800), "400 tiles should be within 800-tile spacing")
assert(not CorridorGraph.HasSettlementWithin(2000, 1000, 800), "1000 tiles should be outside 800-tile spacing")

-- 6. Bootstrap starter settlements respect 800-tile minimum spacing.
local plan, err = Bootstrap.BuildPlan({
    worldSeed = 12345,
    anchor = { x = 10000, y = 10000, z = 0 },
})
assert(plan, err)
assert(#plan.communities >= 5, "expected at least 5 starter communities, got " .. tostring(#plan.communities))
for i = 1, #plan.communities do
    for j = i + 1, #plan.communities do
        local a = plan.communities[i].location and (plan.communities[i].location.position or plan.communities[i].location)
        local b = plan.communities[j].location and (plan.communities[j].location.position or plan.communities[j].location)
        local dx, dy = a.x - b.x, a.y - b.y
        local d = math.sqrt(dx * dx + dy * dy)
        assert(d >= 799, "starter settlements must be >= 800 tiles apart, got " .. tostring(d))
    end
end

-- 7. Archetype-aware night camping & shelterAnchor preservation during waiting.
local traderNight = TravelConditions.EvaluateForArchetype("TRADER", { timeOfDay = 22.0, rainIntensity = 0 })
assert(traderNight.shouldCampNight == true and traderNight.shouldSeekShelter == true,
    "traders must camp on clear nights")
assert(math.abs(traderNight.recommendedWaitHours - 7.5) < 0.01,
    "expected 7.5h until dawn from 22:00, got " .. tostring(traderNight.recommendedWaitHours))

local looterNight = TravelConditions.EvaluateForArchetype("LOOTER", { timeOfDay = 22.0, rainIntensity = 0 })
assert(looterNight.shouldCampNight == false and looterNight.shouldSeekShelter == false,
    "looters must stay nocturnal on clear nights")

local campJourney = assert(GroupJourney.New("g_camp_test", {
    origin = { x = 100, y = 100, z = 0 },
    destination = { x = 400, y = 100, z = 0 },
    speed = 50,
    directRoute = true,
}, 10.0))
GroupJourney.SetShelterWait(campJourney, 4.0, { x = 145, y = 135, z = 0, kind = "building" }, "night_camp")
local midWait = assert(GroupJourney.Advance(campJourney, 12.0))
assert(midWait.state == "waiting", "should remain waiting at +2h")
assert(midWait.x == 145 and midWait.y == 135,
    "shelterAnchor position must be preserved while waiting, got " .. tostring(midWait.x) .. "," .. tostring(midWait.y))
local afterDawn = assert(GroupJourney.Advance(midWait, 15.0))
assert(afterDawn.state == "en_route" and afterDawn.shelterAnchor == nil,
    "shelterAnchor must clear when wait ends and journey resumes")

print("PASS psychopatz_survivor_world_3tier_and_ledger_smoke")
