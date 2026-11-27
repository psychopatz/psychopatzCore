-- Verify PsychopatzCore SurvivorWorld Events (ModData snapshot/restore, query,
-- subscribe, TTL) and Hazards (threat providers + A* corridor roadblock routing).

package.path = "./Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. "./Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. package.path

local SurvivorWorld = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Events = SurvivorWorld.Events
local Hazards = SurvivorWorld.Hazards
local CorridorGraph = SurvivorWorld.CorridorGraph
local RoutePlanner = SurvivorWorld.RoutePlanner

Events.Reset()
Hazards.Reset()
CorridorGraph.Reset()

-- 1. Events Publish / Subscribe / QueryNear / Snapshot-Restore / TTL.
local seen = {}
Events.Subscribe("AIRDROP", function(ev, lifecycle)
    seen[#seen + 1] = ev.id .. ":" .. lifecycle
end)

local ev1 = assert(Events.Publish({
    id = "evt_airdrop_1",
    kind = "AIRDROP",
    ownerMod = "FutureEventsMod",
    x = 1200,
    y = 1400,
    radius = 60,
    ttlHours = 24,
    summary = "Supply crate dropped near West Point",
}, 10.0))
assert(ev1.id == "evt_airdrop_1", "published event id")
assert(#seen == 1 and seen[1] == "evt_airdrop_1:published", "subscriber notified")

local near = Events.QueryNear(1230, 1410, 50)
assert(#near == 1 and near[1].id == "evt_airdrop_1", "QueryNear found airdrop")

-- Simulate server restart: export -> reset -> restore.
local snap = Events.ExportSnapshot()
Events.Reset()
assert(#Events.List() == 0, "events cleared after reset")
local restored = Events.RestoreSnapshot(snap, 20.0)
assert(restored == 1, "active event restored after reload")
assert(Events.Get("evt_airdrop_1") ~= nil, "restored event readable")

-- Advance past TTL (10 + 24 = 34) and prune.
local pruned = Events.PruneExpired(35.0)
assert(pruned == 1 and #Events.List() == 0, "expired event pruned")

-- 2. Hazards threat provider + corridor roadblock steering A* around blocked edge.
Hazards.RegisterThreatProvider("roaming_horde_mod", function(x, y)
    if math.abs(x - 1000) <= 50 and math.abs(y - 1000) <= 50 then
        return { intensity = 95, kind = "horde" }
    end
    return 0
end)
local threat = Hazards.EvaluateThreatAt(1010, 1010, 10.0)
assert(threat.totalThreat == 95 and threat.providerThreat == 95, "threat provider evaluated")

-- Build a diamond corridor inside sector (0,0):
-- A(40,150) -> TOP(140,220) -> B(240,150) and A(40,150) -> BOT(140,80) -> B(240,150).
CorridorGraph.SetWorldSeed(777)
CorridorGraph.RegisterSettlementNode("A", 40, 150, 0)
CorridorGraph.RegisterSettlementNode("TOP", 140, 220, 0)
CorridorGraph.RegisterSettlementNode("BOT", 140, 80, 0)
CorridorGraph.RegisterSettlementNode("B", 240, 150, 0)

-- Block the TOP and direct center corridors via a future Events Mod roadblock!
Hazards.RegisterCorridorModifier("bridge_out_event", function(x, y)
    if y >= 145 then return "blocked" end
    return 1.0
end)

local route, reason = RoutePlanner.PlanRoute({ x = 40, y = 150 }, { x = 240, y = 150 })
assert(route ~= nil and reason == "corridor_planned", "corridor route planned around roadblock (got " .. tostring(reason) .. ")")
local hitsBefore = RoutePlanner._cacheHits or 0
local routeCached, reasonCached = RoutePlanner.PlanRoute({ x = 40, y = 150 }, { x = 240, y = 150 })
assert(routeCached ~= nil and reasonCached == "corridor_planned", "cached route still valid")
assert((RoutePlanner._cacheHits or 0) == hitsBefore + 1, "repeat route hit O(1) memoization cache")
local routedViaBottom = false
for i = 1, #route.points do
    local p = route.points[i]
    assert(p.y <= 155, "route must avoid blocked TOP corridor (got y=" .. tostring(p.y) .. ")")
    if p.y < 100 then routedViaBottom = true end
end
assert(routedViaBottom, "A* routed through BOT alternate corridor")

-- Temporary corridor penalty TTL pruning.
Hazards.AddTemporaryCorridorPenalty("temp_horde_1", 140, 80, 30, 6.0, 12.0)
local multBefore = Hazards.EvaluateCorridorCost(140, 80, 11.0)
assert(multBefore >= 5.9, "temporary penalty active before expiry")
Hazards.PruneTemporaryPenalties(13.0)
local multAfter = Hazards.EvaluateCorridorCost(140, 80, 13.0)
assert(multAfter == 1.0, "temporary penalty pruned after expiry")

Events.Reset()
Hazards.Reset()
CorridorGraph.Reset()
print("PASS: psychopatz_survivor_world_events_hazards_smoke")
