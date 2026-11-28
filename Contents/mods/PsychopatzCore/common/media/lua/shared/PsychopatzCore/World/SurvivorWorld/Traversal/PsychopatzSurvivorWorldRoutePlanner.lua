-- Deterministic 3-tier corridor route planner over PsychopatzSurvivorWorldCorridorGraph.
-- Produces canonical PsychopatzSurvivorWorldGroupRoute polylines for both
-- DynamicTrading (DTAbstract) and Project Hoomans.
-- Uses a flat-array binary min-heap for O(log N) A* pops, archetype edge weighting,
-- revision-stamped O(1) route caching, and lazy-regen ScavengeLedger pit-stop tagging.

local Route = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupRoute"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local Hazards = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldHazards"
local ScavengeLedger = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"

local Planner = {}

Planner.SNAP_RADIUS = 160
Planner.MAX_SECTORS_PER_ROUTE = 9
Planner.MAX_EXPANSIONS = 96
Planner.MAX_WAYPOINTS = 12
Planner.MIN_CORRIDOR_DISTANCE = 24
Planner.MAX_ROUTE_CACHE = 64
Planner.MAX_COLD_PLANS_PER_TICK = 4
Planner.DEFAULT_PIT_STOP_WAIT_HOURS = 0.45
Planner._routeCache = Planner._routeCache or {}
Planner._routeCacheOrder = Planner._routeCacheOrder or {}
Planner._cacheHits = Planner._cacheHits or 0
Planner._coldPlanWindowMs = Planner._coldPlanWindowMs or 0
Planner._coldPlansInWindow = Planner._coldPlansInWindow or 0

function Planner.ClearCache()
    Planner._routeCache = {}
    Planner._routeCacheOrder = {}
    Planner._cacheHits = 0
    Planner._coldPlanWindowMs = 0
    Planner._coldPlansInWindow = 0
end

local function consumeColdPlanBudget(options)
    if options and options.bypassBudget == true then return true end
    local nowMs = nil
    if type(getTimestampMs) == "function" then
        nowMs = tonumber(getTimestampMs())
    end
    -- In headless unit tests without getTimestampMs, keep budget unrestricted.
    if not nowMs then return true end
    if (nowMs - (tonumber(Planner._coldPlanWindowMs) or 0)) >= 50 then
        Planner._coldPlanWindowMs = nowMs
        Planner._coldPlansInWindow = 0
    end
    if Planner._coldPlansInWindow >= Planner.MAX_COLD_PLANS_PER_TICK then
        return false
    end
    Planner._coldPlansInWindow = Planner._coldPlansInWindow + 1
    return true
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function dist(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return math.sqrt(dx * dx + dy * dy)
end

local function distSq(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return dx * dx + dy * dy
end

local function normalizeArchetype(options)
    local raw = options and (options.archetype or options.groupType or options.role) or "DEFAULT"
    return string.upper(tostring(raw))
end

local function edgeArchetypeMultiplier(archetype, edgeKind, toNode, nowHours)
    local mult = 1.0
    if archetype == "TRADER" or archetype == "CARAVAN" then
        if edgeKind == "settlement" then mult = 0.78
        elseif edgeKind == "road" then mult = 0.85
        elseif edgeKind == "feeder" then mult = 1.15
        elseif edgeKind == "wilderness" then mult = 1.35 end
    elseif archetype == "SCAVENGER" or archetype == "LOOTER" then
        if edgeKind == "feeder" or (toNode and toNode.kind == "poi") then
            local dep = (toNode and toNode.poiKey and ScavengeLedger)
                and ScavengeLedger.GetDepletionByKey(toNode.poiKey, nowHours) or 0
            if dep >= ScavengeLedger.EXHAUSTED_THRESHOLD then
                mult = 1.85
            else
                mult = 0.82 + (dep * 0.40)
            end
        elseif edgeKind == "settlement" then
            mult = 0.95
        end
    elseif archetype == "REFUGEE" then
        if edgeKind == "wilderness" then mult = 0.85
        elseif edgeKind == "settlement" then mult = 0.85
        elseif edgeKind == "road" then mult = 1.08 end
    end
    return mult
end

-- Flat-array binary min-heap for O(log N) A* open-set pops (zero wrapper tables).
local function heapPush(ids, fs, id, f)
    local idx = #ids + 1
    ids[idx] = id
    fs[idx] = f
    while idx > 1 do
        local parent = math.floor(idx / 2)
        if fs[idx] < fs[parent] or (fs[idx] == fs[parent] and ids[idx] < ids[parent]) then
            ids[idx], ids[parent] = ids[parent], ids[idx]
            fs[idx], fs[parent] = fs[parent], fs[idx]
            idx = parent
        else
            break
        end
    end
end

local function heapPop(ids, fs)
    local n = #ids
    if n == 0 then return nil, nil end
    local topID, topF = ids[1], fs[1]
    ids[1] = ids[n]
    fs[1] = fs[n]
    ids[n] = nil
    fs[n] = nil
    n = n - 1
    local idx = 1
    while true do
        local left = idx * 2
        if left > n then break end
        local right = left + 1
        local smallest = left
        if right <= n and (fs[right] < fs[left]
            or (fs[right] == fs[left] and ids[right] < ids[left]))
        then
            smallest = right
        end
        if fs[smallest] < fs[idx]
            or (fs[smallest] == fs[idx] and ids[smallest] < ids[idx])
        then
            ids[idx], ids[smallest] = ids[smallest], ids[idx]
            fs[idx], fs[smallest] = fs[smallest], fs[idx]
            idx = smallest
        else
            break
        end
    end
    return topID, topF
end

local function collectCombinedGraph(origin, destination, options)
    local sx1, sy1 = CorridorGraph.SectorCoords(origin.x, origin.y)
    local sx2, sy2 = CorridorGraph.SectorCoords(destination.x, destination.y)
    local minSX = math.min(sx1, sx2)
    local maxSX = math.max(sx1, sx2)
    local minSY = math.min(sy1, sy2)
    local maxSY = math.max(sy1, sy2)

    local sectors = {}
    local sectorCount = 0
    for sx = minSX, maxSX do
        for sy = minSY, maxSY do
            if sectorCount >= Planner.MAX_SECTORS_PER_ROUTE then break end
            sectors[#sectors + 1] = CorridorGraph.EnsureSector(sx, sy, options)
            sectorCount = sectorCount + 1
        end
        if sectorCount >= Planner.MAX_SECTORS_PER_ROUTE then break end
    end

    local nodes = {}
    local nodesByID = {}
    local adj = {}
    for i = 1, #sectors do
        local sec = sectors[i]
        for j = 1, #sec.nodes do
            local n = sec.nodes[j]
            if not nodesByID[n.id] then
                nodesByID[n.id] = n
                nodes[#nodes + 1] = n
                adj[n.id] = {}
            end
        end
    end
    for i = 1, #sectors do
        local sec = sectors[i]
        for id, list in pairs(sec.adj) do
            local target = adj[id]
            if target then
                for k = 1, #list do
                    target[#target + 1] = list[k]
                end
            end
        end
    end

    -- Bridge nodes across adjacent sector boundaries so routes cross sectors cleanly.
    if #sectors > 1 and #nodes > 1 then
        local bridgeMaxSq = CorridorGraph.MAX_EDGE_DISTANCE * CorridorGraph.MAX_EDGE_DISTANCE
        for i = 1, #nodes do
            local a = nodes[i]
            for j = i + 1, #nodes do
                local b = nodes[j]
                if a.sectorKey ~= b.sectorKey then
                    local d2 = distSq(a.x, a.y, b.x, b.y)
                    if d2 <= bridgeMaxSq then
                        local w = math.sqrt(d2)
                        local eKind = (a.kind == "nav" and b.kind == "nav") and "road"
                            or ((a.kind == "settlement" or b.kind == "settlement") and "settlement"
                            or ((a.kind == "poi" or b.kind == "poi") and "feeder" or "wilderness"))
                        adj[a.id][#adj[a.id] + 1] = { id = b.id, weight = w, edgeKind = eKind }
                        adj[b.id][#adj[b.id] + 1] = { id = a.id, weight = w, edgeKind = eKind }
                    end
                end
            end
        end
    end

    return nodes, nodesByID, adj
end

local function findNearestNode(nodes, x, y, maxRadius)
    local best = nil
    local bestDistSq = maxRadius * maxRadius
    for i = 1, #nodes do
        local n = nodes[i]
        local d2 = distSq(x, y, n.x, n.y)
        if d2 < bestDistSq or (d2 == bestDistSq and best and n.id < best.id) then
            bestDistSq = d2
            best = n
        end
    end
    return best
end

local function runAStar(startNode, goalNode, nodesByID, adj, archetype, nowHours)
    if startNode.id == goalNode.id then
        return { startNode }
    end
    local heapIds = {}
    local heapF = {}
    local closed = {}
    local cameFrom = {}
    local gScore = { [startNode.id] = 0 }
    local startH = dist(startNode.x, startNode.y, goalNode.x, goalNode.y)
    heapPush(heapIds, heapF, startNode.id, startH)
    local expansions = 0

    while #heapIds > 0 and expansions < Planner.MAX_EXPANSIONS do
        local bestID = heapPop(heapIds, heapF)
        if not bestID then break end
        if not closed[bestID] then
            if bestID == goalNode.id then
                local rev = {}
                local cur = bestID
                while cur do
                    rev[#rev + 1] = nodesByID[cur]
                    cur = cameFrom[cur]
                end
                local path = {}
                for i = #rev, 1, -1 do
                    path[#path + 1] = rev[i]
                end
                return path
            end

            closed[bestID] = true
            expansions = expansions + 1
            local fromNode = nodesByID[bestID]
            local neighbors = adj[bestID] or {}
            local curG = gScore[bestID] or math.huge
            for i = 1, #neighbors do
                local edge = neighbors[i]
                local nid = edge.id
                local toNode = nodesByID[nid]
                if not closed[nid] and toNode then
                    local hazMult, blocked = 1.0, false
                    if fromNode and Hazards and type(Hazards.EvaluateCorridorCost) == "function" then
                        hazMult, blocked = Hazards.EvaluateCorridorCost(
                            (fromNode.x + toNode.x) * 0.5,
                            (fromNode.y + toNode.y) * 0.5
                        )
                    end
                    if not blocked then
                        if archetype == "REFUGEE" and hazMult > 1.0 then
                            hazMult = 1.0 + (hazMult - 1.0) * 1.35
                        end
                        local archMult = edgeArchetypeMultiplier(
                            archetype, edge.edgeKind, toNode, nowHours
                        )
                        local tentativeG = curG + (edge.weight * hazMult * archMult)
                        if tentativeG < (gScore[nid] or math.huge) then
                            cameFrom[nid] = bestID
                            gScore[nid] = tentativeG
                            local fVal = tentativeG + dist(toNode.x, toNode.y, goalNode.x, goalNode.y)
                            heapPush(heapIds, heapF, nid, fVal)
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function decimateWaypoints(path, maxCount)
    if #path <= maxCount then return path end
    local out = { path[1] }
    local step = (#path - 1) / (maxCount - 1)
    for i = 1, maxCount - 2 do
        local idx = math.floor(1 + i * step + 0.5)
        idx = math.max(2, math.min(#path - 1, idx))
        if path[idx] ~= out[#out] then
            out[#out + 1] = path[idx]
        end
    end
    out[#out + 1] = path[#path]
    return out
end

local function nodeTag(n, isPitStop)
    if isPitStop then
        return n.kind == "wilderness" and "pit_stop_wilderness" or "pit_stop_poi"
    end
    if n.kind == "settlement" then return "settlement_node" end
    if n.kind == "poi" then return "poi_node" end
    if n.kind == "wilderness" then return "wilderness_node" end
    return "street_node"
end

-- Selects the best un-exhausted building-cluster POI or wilderness clearing near (x, y)
-- so scavengers/looters/travelers naturally branch out house-to-house instead of looping.
function Planner.SelectNextScavengePOI(x, y, options)
    options = type(options) == "table" and options or {}
    local nx = finite(x, 0)
    local ny = finite(y, 0)
    local nowHours = options.worldAgeHours
    local sx, sy = CorridorGraph.SectorCoords(nx, ny)
    local sectorRadius = math.max(0, math.min(2, math.floor(tonumber(options.sectorRadius) or 1)))
    local minDist = math.max(0, finite(options.minDistance, 20))
    local maxDist = math.max(minDist + 40, finite(options.maxDistance, 450))
    local minDistSq = minDist * minDist
    local maxDistSq = maxDist * maxDist
    local excludeKey = tonumber(options.excludePoiKey)

    local best = nil
    local bestScore = math.huge
    for dx = -sectorRadius, sectorRadius do
        for dy = -sectorRadius, sectorRadius do
            local sec = CorridorGraph.EnsureSector(sx + dx, sy + dy, options)
            if sec and sec.nodes then
                for i = 1, #sec.nodes do
                    local n = sec.nodes[i]
                    if (n.kind == "poi" or n.kind == "wilderness")
                        and (excludeKey == nil or n.poiKey ~= excludeKey)
                    then
                        local d2 = distSq(nx, ny, n.x, n.y)
                        if d2 >= minDistSq and d2 <= maxDistSq then
                            local dep = (n.poiKey and ScavengeLedger)
                                and ScavengeLedger.GetDepletionByKey(n.poiKey, nowHours) or 0
                            if dep < ScavengeLedger.EXHAUSTED_THRESHOLD then
                                -- Prefer closer, fresher building POIs over distant or partially looted ones.
                                local d = math.sqrt(d2)
                                local kindPenalty = n.kind == "wilderness" and 45 or 0
                                local score = d + (dep * 220) + kindPenalty
                                if score < bestScore or (score == bestScore and best and n.id < best.id) then
                                    bestScore = score
                                    best = n
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

function Planner.PlanRoute(origin, destination, options)
    options = type(options) == "table" and options or {}
    local startPt = {
        x = finite(origin and origin.x, 0),
        y = finite(origin and origin.y, 0),
        z = finite(origin and origin.z, 0),
    }
    local endPt = {
        x = finite(destination and destination.x, startPt.x),
        y = finite(destination and destination.y, startPt.y),
        z = finite(destination and destination.z, startPt.z),
    }
    if dist(startPt.x, startPt.y, endPt.x, endPt.y) < Planner.MIN_CORRIDOR_DISTANCE then
        return Route.Normalize(nil, startPt, endPt), "direct_short"
    end

    local nodes, nodesByID, adj = collectCombinedGraph(startPt, endPt, options)
    if #nodes == 0 then
        return Route.Normalize(nil, startPt, endPt), "direct_no_corridors"
    end

    local snapRadius = tonumber(options.snapRadius) or Planner.SNAP_RADIUS
    local startNode = findNearestNode(nodes, startPt.x, startPt.y, snapRadius)
    local goalNode = findNearestNode(nodes, endPt.x, endPt.y, snapRadius)
    if not startNode or not goalNode then
        return Route.Normalize(nil, startPt, endPt), "direct_outside_snap"
    end

    local archetype = normalizeArchetype(options)
    local nowHours = options.worldAgeHours
    local topoRev = CorridorGraph.GetTopologyRevision and CorridorGraph.GetTopologyRevision() or 1
    local hazRev = Hazards and Hazards.GetRevision and Hazards.GetRevision() or 1
    local scavRev = ScavengeLedger and ScavengeLedger.GetRevision and ScavengeLedger.GetRevision() or 1
    local worldSeed = CorridorGraph.GetWorldSeed and CorridorGraph.GetWorldSeed() or 0
    local cacheKey = tostring(startNode.id) .. "->" .. tostring(goalNode.id)
        .. "|" .. archetype
        .. "@" .. tostring(topoRev) .. ":" .. tostring(hazRev) .. ":" .. tostring(scavRev)
        .. "#" .. tostring(worldSeed)

    local cachedPath = Planner._routeCache[cacheKey]
    local nodePath
    if cachedPath ~= nil then
        Planner._cacheHits = (Planner._cacheHits or 0) + 1
        nodePath = cachedPath ~= false and cachedPath or nil
    else
        if not consumeColdPlanBudget(options) then
            return Route.Normalize(nil, startPt, endPt), "direct_budget_deferred"
        end
        nodePath = runAStar(startNode, goalNode, nodesByID, adj, archetype, nowHours)
        Planner._routeCache[cacheKey] = nodePath or false
        Planner._routeCacheOrder[#Planner._routeCacheOrder + 1] = cacheKey
        while #Planner._routeCacheOrder > Planner.MAX_ROUTE_CACHE do
            local oldest = table.remove(Planner._routeCacheOrder, 1)
            if oldest then Planner._routeCache[oldest] = nil end
        end
    end
    if not nodePath or #nodePath == 0 then
        return Route.Normalize(nil, startPt, endPt), "direct_unconnected"
    end

    local maxWaypoints = math.max(
        2,
        math.min(Route.MAX_POINTS - 2, tonumber(options.maxWaypoints) or Planner.MAX_WAYPOINTS)
    )
    nodePath = decimateWaypoints(nodePath, maxWaypoints)

    local maxPitStops = tonumber(options.maxPitStops)
        or (options.includePitStops == true and 2 or 0)
    local pitStopWait = finite(options.pitStopWaitHours, Planner.DEFAULT_PIT_STOP_WAIT_HOURS)
    local assignedPitStops = 0

    local points = { startPt }
    for i = 1, #nodePath do
        local n = nodePath[i]
        local isPitStop = false
        if assignedPitStops < maxPitStops
            and (n.kind == "poi" or n.kind == "wilderness")
            and not (n.poiKey and ScavengeLedger.IsExhaustedByKey(n.poiKey, nowHours))
        then
            isPitStop = true
            assignedPitStops = assignedPitStops + 1
        end
        points[#points + 1] = {
            x = n.x,
            y = n.y,
            z = n.z or 0,
            tag = nodeTag(n, isPitStop),
            waitHours = isPitStop and pitStopWait or 0,
        }
    end
    points[#points + 1] = endPt
    return Route.Normalize(points, startPt, endPt), "corridor_planned"
end

return Planner
