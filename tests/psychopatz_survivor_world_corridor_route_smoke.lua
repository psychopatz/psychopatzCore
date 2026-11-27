local root = debug.getinfo(1, "S").source:match("^@?(.*)/tests/") or "."
package.path = root .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua;"
    .. package.path

local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local RoutePlanner = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

-- 1. Graceful fallback when MetaGrid is unavailable.
CorridorGraph.Reset()
local directRoute, directReason = RoutePlanner.PlanRoute(
    { x = 100, y = 100, z = 0 },
    { x = 250, y = 100, z = 0 }
)
assert(directReason == "direct_no_corridors", "expected direct_no_corridors, got " .. tostring(directReason))
assert(#directRoute.points == 2, "direct fallback should have 2 points")

-- 2. Mock IsoMetaGrid with L-shaped Nav road strips across sector (0,0).
local function makeZone(ztype, x, y, w, h)
    return {
        getType = function() return ztype end,
        getX = function() return x end,
        getY = function() return y end,
        getWidth = function() return w end,
        getHeight = function() return h end,
    }
end

local navZones = {
    makeZone("Nav", 100, 100, 120, 10), -- horizontal street y=105, x=100..220
    makeZone("Nav", 210, 100, 10, 120), -- vertical street x=215, y=100..220
    makeZone("Vegitation", 140, 140, 50, 50), -- ignored non-Nav zone
}

_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getZonesIntersecting = function(_, minX, minY, _, w, h)
                    local hits = {}
                    for i = 1, #navZones do
                        local z = navZones[i]
                        local zx, zy = z:getX(), z:getY()
                        if zx >= minX - 20 and zx <= minX + w + 20
                            and zy >= minY - 20 and zy <= minY + h + 20
                        then
                            hits[#hits + 1] = z
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
CorridorGraph.SetWorldSeed(424242)
local secA = CorridorGraph.EnsureSector(0, 0)
assert(#secA.nodes >= 3, "expected Nav street nodes extracted from MetaGrid")
assert(#secA.edges >= 2, "expected street corridor edges")

-- Determinism check: resetting with same world seed produces identical node IDs.
local idsA = {}
for i = 1, #secA.nodes do idsA[i] = secA.nodes[i].id end
CorridorGraph.ClearCache()
local secB = CorridorGraph.EnsureSector(0, 0)
assert(#secB.nodes == #idsA, "deterministic node count")
for i = 1, #idsA do
    assert(secB.nodes[i].id == idsA[i], "deterministic node ordering at " .. tostring(i))
end

-- 3. Dynamic settlement registration links into street graph.
local sNode = CorridorGraph.RegisterSettlementNode("settlement_alpha", 225, 225, 0)
assert(sNode and sNode.kind == "settlement", "settlement node registered")

-- 4. GroupJourney.New automatically plans a street-following polyline.
local journey, jErr = GroupJourney.New("group_traders_1", {
    origin = { x = 95, y = 105, z = 0 },
    destination = { x = 225, y = 225, z = 0 },
    speed = 50,
    seed = 424242,
}, 10.0)
assert(journey, jErr)
assert(#journey.route.points >= 4, "expected multi-waypoint street route, got " .. tostring(#journey.route.points))

local hasStreetOrSettlement = false
for i = 1, #journey.route.points do
    local tag = journey.route.points[i].tag
    if tag == "street_node" or tag == "settlement_node" then
        hasStreetOrSettlement = true
    end
end
assert(hasStreetOrSettlement, "route should include street/settlement waypoint tags")

-- 5. Debug snapshot bounded and populated.
local snap = CorridorGraph.GetDebugSnapshot()
assert(snap.sectorCount == 1 and #snap.nodes >= 4 and #snap.edges >= 3, "debug snapshot populated")

print("PASS psychopatz_survivor_world_corridor_route_smoke")
