-- Deterministic street-corridor route planner over PsychopatzSurvivorWorldCorridorGraph.
-- Produces canonical PsychopatzSurvivorWorldGroupRoute polylines for both
-- DynamicTrading (DTAbstract) and Project Hoomans.

local Route = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupRoute"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local Hazards = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldHazards"

local Planner = {}

Planner.SNAP_RADIUS = 140
Planner.MAX_SECTORS_PER_ROUTE = 9
Planner.MAX_EXPANSIONS = 64
Planner.MAX_WAYPOINTS = 12
Planner.MIN_CORRIDOR_DISTANCE = 24
Planner.MAX_ROUTE_CACHE = 64
Planner.MAX_COLD_PLANS_PER_TICK = 4
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
                        adj[a.id][#adj[a.id] + 1] = { id = b.id, weight = w }
                        adj[b.id][#adj[b.id] + 1] = { id = a.id, weight = w }
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

local function runAStar(startNode, goalNode, nodesByID, adj)
    if startNode.id == goalNode.id then
        return { startNode }
    end
    local open = { startNode.id }
    local inOpen = { [startNode.id] = true }
    local closed = {}
    local cameFrom = {}
    local gScore = { [startNode.id] = 0 }
    local fScore = { [startNode.id] = dist(startNode.x, startNode.y, goalNode.x, goalNode.y) }
    local expansions = 0

    while #open > 0 and expansions < Planner.MAX_EXPANSIONS do
        local bestIdx = 1
        local bestID = open[1]
        local bestF = fScore[bestID] or math.huge
        for i = 2, #open do
            local cid = open[i]
            local cf = fScore[cid] or math.huge
            if cf < bestF or (cf == bestF and cid < bestID) then
                bestF = cf
                bestID = cid
                bestIdx = i
            end
        end
        table.remove(open, bestIdx)
        inOpen[bestID] = nil

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
        for i = 1, #neighbors do
            local edge = neighbors[i]
            local nid = edge.id
            local toNode = nodesByID[nid]
            if not closed[nid] and toNode then
                local mult, blocked = 1.0, false
                if fromNode and Hazards and type(Hazards.EvaluateCorridorCost) == "function" then
                    mult, blocked = Hazards.EvaluateCorridorCost(
                        (fromNode.x + toNode.x) * 0.5,
                        (fromNode.y + toNode.y) * 0.5
                    )
                end
                if not blocked then
                    local tentativeG = (gScore[bestID] or math.huge) + (edge.weight * mult)
                    if tentativeG < (gScore[nid] or math.huge) then
                        cameFrom[nid] = bestID
                        gScore[nid] = tentativeG
                        fScore[nid] = tentativeG + dist(toNode.x, toNode.y, goalNode.x, goalNode.y)
                        if not inOpen[nid] then
                            inOpen[nid] = true
                            open[#open + 1] = nid
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

    local hazRev = Hazards and Hazards.GetRevision and Hazards.GetRevision() or 1
    local worldSeed = CorridorGraph.GetWorldSeed and CorridorGraph.GetWorldSeed() or 0
    local cacheKey = tostring(startNode.id) .. "->" .. tostring(goalNode.id)
        .. "@" .. tostring(hazRev) .. "#" .. tostring(worldSeed)
    local cachedPath = Planner._routeCache[cacheKey]
    local nodePath
    if cachedPath ~= nil then
        Planner._cacheHits = (Planner._cacheHits or 0) + 1
        nodePath = cachedPath ~= false and cachedPath or nil
    else
        if not consumeColdPlanBudget(options) then
            return Route.Normalize(nil, startPt, endPt), "direct_budget_deferred"
        end
        nodePath = runAStar(startNode, goalNode, nodesByID, adj)
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

    local points = { startPt }
    for i = 1, #nodePath do
        local n = nodePath[i]
        points[#points + 1] = {
            x = n.x,
            y = n.y,
            z = n.z or 0,
            tag = n.kind == "settlement" and "settlement_node" or "street_node",
        }
    end
    points[#points + 1] = endPt
    return Route.Normalize(points, startPt, endPt), "corridor_planned"
end

return Planner
