-- Deterministic, bounded MetaGrid street & settlement corridor graph.
-- Shared by PsychopatzCore, DynamicTrading (DTAbstract), and Project Hoomans.
-- Uses only in-memory IsoMetaGrid "Nav" zones and registered settlement anchors
-- (zero chunk loading, LRU-bounded per-sector cache).

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Graph = {}

Graph.SCHEMA_VERSION = 1
Graph.SECTOR_SIZE = 300
Graph.MAX_SECTORS = 24
Graph.MAX_NODES_PER_SECTOR = 20
Graph.MAX_EDGE_DISTANCE = 180
Graph.MAX_NEIGHBORS = 4
Graph.MIN_NODE_SPACING = 24
Graph.ZONE_INSPECTION_CAP = 96

Graph.State = Graph.State or {
    worldSeed = 0,
    sectors = {},
    sectorOrder = {},
    anchors = {},
    revision = 0,
}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

function Graph.MixSeed(worldSeed, ...)
    local parts = { tostring(worldSeed or Graph.State.worldSeed or 0) }
    local count = select("#", ...)
    for i = 1, count do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    return Util.hash(table.concat(parts, "|"))
end

function Graph.SetWorldSeed(seed)
    local normalized = tonumber(seed) or Util.hash(tostring(seed or "default"))
    if Graph.State.worldSeed ~= normalized then
        Graph.State.worldSeed = normalized
        Graph.ClearCache()
    end
    return Graph.State.worldSeed
end

function Graph.ClearCache()
    Graph.State.sectors = {}
    Graph.State.sectorOrder = {}
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return true
end

function Graph.Reset()
    Graph.State.sectors = {}
    Graph.State.sectorOrder = {}
    Graph.State.anchors = {}
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return true
end

function Graph.SectorCoords(x, y)
    local size = Graph.SECTOR_SIZE
    return math.floor(finite(x, 0) / size), math.floor(finite(y, 0) / size)
end

local function sectorKey(sx, sy)
    return tostring(sx) .. ":" .. tostring(sy)
end

local function touchSector(key)
    local order = Graph.State.sectorOrder
    for i = #order, 1, -1 do
        if order[i] == key then
            table.remove(order, i)
            break
        end
    end
    order[#order + 1] = key
    while #order > Graph.MAX_SECTORS do
        local evicted = table.remove(order, 1)
        if evicted then
            Graph.State.sectors[evicted] = nil
        end
    end
end

local function distSq(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return dx * dx + dy * dy
end

local function addNodeIfSpaced(nodes, candidate, minSpacingSq)
    for i = 1, #nodes do
        if distSq(nodes[i].x, nodes[i].y, candidate.x, candidate.y) < minSpacingSq then
            return false
        end
    end
    nodes[#nodes + 1] = candidate
    return true
end

local function extractMetaNavNodes(sx, sy, worldSeed)
    local nodes = {}
    local world = type(getWorld) == "function" and getWorld() or nil
    local metaGrid = world and type(world.getMetaGrid) == "function"
        and world:getMetaGrid() or nil
    if not metaGrid or type(metaGrid.getZonesIntersecting) ~= "function" then
        return nodes
    end
    local size = Graph.SECTOR_SIZE
    local minX = sx * size
    local minY = sy * size
    local ok, zones = pcall(
        metaGrid.getZonesIntersecting,
        metaGrid,
        minX,
        minY,
        0,
        size,
        size
    )
    if not ok or not zones or type(zones.size) ~= "function" then
        return nodes
    end
    local total = tonumber(zones:size()) or 0
    if total <= 0 then
        return nodes
    end
    local rawCandidates = {}
    local inspectCount = math.min(total, Graph.ZONE_INSPECTION_CAP)
    for i = 0, inspectCount - 1 do
        local zone = zones.get and zones:get(i) or nil
        if zone then
            local zType = zone.getType and tostring(zone:getType() or "") or ""
            if zType == "Nav" then
                local zx = finite(zone.getX and zone:getX(), nil)
                local zy = finite(zone.getY and zone:getY(), nil)
                local zw = finite(zone.getWidth and zone:getWidth(), 0)
                local zh = finite(zone.getHeight and zone:getHeight(), 0)
                if zx and zy and zw > 0 and zh > 0 then
                    local cx = zx + zw / 2
                    local cy = zy + zh / 2
                    -- Long road strips contribute endpoints + midpoint for smooth street lines.
                    if zw >= 48 or zh >= 48 then
                        if zw >= zh then
                            rawCandidates[#rawCandidates + 1] = { x = zx + 6, y = cy, z = 0 }
                            rawCandidates[#rawCandidates + 1] = { x = cx, y = cy, z = 0 }
                            rawCandidates[#rawCandidates + 1] = { x = zx + zw - 6, y = cy, z = 0 }
                        else
                            rawCandidates[#rawCandidates + 1] = { x = cx, y = zy + 6, z = 0 }
                            rawCandidates[#rawCandidates + 1] = { x = cx, y = cy, z = 0 }
                            rawCandidates[#rawCandidates + 1] = { x = cx, y = zy + zh - 6, z = 0 }
                        end
                    else
                        rawCandidates[#rawCandidates + 1] = { x = cx, y = cy, z = 0 }
                    end
                end
            end
        end
    end
    table.sort(rawCandidates, function(a, b)
        local ha = Graph.MixSeed(worldSeed, "nav", math.floor(a.x), math.floor(a.y))
        local hb = Graph.MixSeed(worldSeed, "nav", math.floor(b.x), math.floor(b.y))
        if ha == hb then
            if a.x == b.x then return a.y < b.y end
            return a.x < b.x
        end
        return ha < hb
    end)
    local minSpacingSq = Graph.MIN_NODE_SPACING * Graph.MIN_NODE_SPACING
    for i = 1, #rawCandidates do
        if #nodes >= Graph.MAX_NODES_PER_SECTOR then break end
        local pt = rawCandidates[i]
        local id = "nav_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
            .. tostring(math.floor(pt.x)) .. "_" .. tostring(math.floor(pt.y))
        addNodeIfSpaced(nodes, {
            id = id,
            x = pt.x,
            y = pt.y,
            z = pt.z or 0,
            kind = "nav",
            sectorKey = sectorKey(sx, sy),
        }, minSpacingSq)
    end
    return nodes
end

local function buildSectorEdges(nodes)
    local edges = {}
    local adj = {}
    local maxDistSq = Graph.MAX_EDGE_DISTANCE * Graph.MAX_EDGE_DISTANCE
    for i = 1, #nodes do
        adj[nodes[i].id] = {}
    end
    local seenPairs = {}
    for i = 1, #nodes do
        local a = nodes[i]
        local nearest = {}
        for j = 1, #nodes do
            if i ~= j then
                local b = nodes[j]
                local d2 = distSq(a.x, a.y, b.x, b.y)
                if d2 <= maxDistSq then
                    nearest[#nearest + 1] = { node = b, distSq = d2 }
                end
            end
        end
        table.sort(nearest, function(left, right)
            if left.distSq == right.distSq then
                return left.node.id < right.node.id
            end
            return left.distSq < right.distSq
        end)
        local limit = math.min(#nearest, Graph.MAX_NEIGHBORS)
        for k = 1, limit do
            local b = nearest[k].node
            local pairKey = a.id < b.id and (a.id .. "|" .. b.id) or (b.id .. "|" .. a.id)
            if not seenPairs[pairKey] then
                seenPairs[pairKey] = true
                local d = math.sqrt(nearest[k].distSq)
                edges[#edges + 1] = {
                    from = a.id,
                    to = b.id,
                    fromX = a.x,
                    fromY = a.y,
                    toX = b.x,
                    toY = b.y,
                    weight = d,
                }
                adj[a.id][#adj[a.id] + 1] = { id = b.id, weight = d }
                adj[b.id][#adj[b.id] + 1] = { id = a.id, weight = d }
            end
        end
    end
    return edges, adj
end

function Graph.RegisterSettlementNode(id, x, y, z, options)
    id = tostring(id or "")
    if id == "" then return nil, "anchor_id_required" end
    options = type(options) == "table" and options or {}
    local nx = finite(x, nil)
    local ny = finite(y, nil)
    local nz = finite(z, 0)
    if not nx or not ny then return nil, "anchor_position_required" end
    local sx, sy = Graph.SectorCoords(nx, ny)
    local key = sectorKey(sx, sy)
    local node = {
        id = "anchor:" .. id,
        anchorId = id,
        x = nx,
        y = ny,
        z = nz,
        kind = tostring(options.kind or "settlement"),
        sectorKey = key,
    }
    Graph.State.anchors[id] = node
    -- Invalidate cached sector so the new settlement node links into nearby roads.
    Graph.State.sectors[key] = nil
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return node
end

function Graph.UnregisterSettlementNode(id)
    id = tostring(id or "")
    local existing = Graph.State.anchors[id]
    if not existing then return false end
    Graph.State.anchors[id] = nil
    if existing.sectorKey then
        Graph.State.sectors[existing.sectorKey] = nil
    end
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return true
end

function Graph.EnsureSector(sx, sy, options)
    options = type(options) == "table" and options or {}
    local key = sectorKey(sx, sy)
    local existing = Graph.State.sectors[key]
    if existing and options.force ~= true then
        touchSector(key)
        return existing
    end
    local seed = tonumber(options.seed) or Graph.State.worldSeed or 0
    local nodes = extractMetaNavNodes(sx, sy, seed)
    for _, anchor in pairs(Graph.State.anchors) do
        if anchor.sectorKey == key then
            nodes[#nodes + 1] = {
                id = anchor.id,
                anchorId = anchor.anchorId,
                x = anchor.x,
                y = anchor.y,
                z = anchor.z,
                kind = anchor.kind,
                sectorKey = key,
            }
        end
    end
    local edges, adj = buildSectorEdges(nodes)
    local nodesByID = {}
    for i = 1, #nodes do
        nodesByID[nodes[i].id] = nodes[i]
    end
    local sector = {
        key = key,
        sx = sx,
        sy = sy,
        nodes = nodes,
        nodesByID = nodesByID,
        edges = edges,
        adj = adj,
    }
    Graph.State.sectors[key] = sector
    touchSector(key)
    return sector
end

function Graph.GetDebugSnapshot(bounds)
    bounds = type(bounds) == "table" and bounds or nil
    local nodes = {}
    local edges = {}
    local sectorCount = 0
    for _, sector in pairs(Graph.State.sectors) do
        sectorCount = sectorCount + 1
        for i = 1, #sector.nodes do
            local n = sector.nodes[i]
            if not bounds or (
                n.x >= (tonumber(bounds.minX) or -math.huge)
                and n.x <= (tonumber(bounds.maxX) or math.huge)
                and n.y >= (tonumber(bounds.minY) or -math.huge)
                and n.y <= (tonumber(bounds.maxY) or math.huge)
            ) then
                nodes[#nodes + 1] = n
            end
        end
        for i = 1, #sector.edges do
            edges[#edges + 1] = sector.edges[i]
        end
    end
    return {
        revision = Graph.State.revision,
        sectorCount = sectorCount,
        nodes = nodes,
        edges = edges,
    }
end

return Graph
