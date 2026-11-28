-- Deterministic, bounded 3-tier map-agnostic corridor graph.
-- Shared by PsychopatzCore, DynamicTrading (DTAbstract), and Project Hoomans.
--
-- Tier 1: Registered Player & AI Settlement gravity hubs (800-tile spatial hash).
-- Tier 2: In-memory IsoMetaGrid "Nav" road strips + 40-tile building-cluster POIs.
-- Tier 3: Deterministic wilderness trail/clearing fallback for wilderness-only maps.
--
-- Zero chunk loading, integer-packed coordinate keys (zero string GC churn),
-- and LRU-bounded per-sector cache.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local ScavengeLedger = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"

local Graph = {}

Graph.SCHEMA_VERSION = 2
Graph.SECTOR_SIZE = 300
Graph.MAX_SECTORS = 32
Graph.MAX_NAV_NODES_PER_SECTOR = 16
Graph.MAX_POI_NODES_PER_SECTOR = 8
Graph.MAX_WILDERNESS_NODES_PER_SECTOR = 6
Graph.MAX_NODES_PER_SECTOR = 24
Graph.MAX_EDGE_DISTANCE = 190
Graph.MAX_NEIGHBORS = 4
Graph.MIN_NODE_SPACING = 24
Graph.POI_CLUSTER_SIZE = 40
Graph.SETTLEMENT_GRID_SIZE = 800
Graph.MIN_SETTLEMENT_SPACING = 800
Graph.ZONE_INSPECTION_CAP = 96
Graph.BUILDING_INSPECTION_CAP = 128
Graph.HEAT_CELL_SIZE = 150
Graph.HEAT_DECAY_HOURS = 48
Graph.MAX_HEAT_ENTRIES = 64

local COORD_OFFSET = 32768
local COORD_STRIDE = 65536

Graph.State = Graph.State or {
    worldSeed = 0,
    sectors = {},
    sectorOrder = {},
    anchors = {},
    settlementGrid = {},
    trafficHeat = {},
    trafficHeatCount = 0,
    revision = 1,
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

function Graph.PackCoords(cx, cy)
    return (math.floor(finite(cx, 0)) + COORD_OFFSET) * COORD_STRIDE
        + (math.floor(finite(cy, 0)) + COORD_OFFSET)
end

function Graph.MixSeed(worldSeed, ...)
    local parts = { tostring(worldSeed or Graph.State.worldSeed or 0) }
    local count = select("#", ...)
    for i = 1, count do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    return Util.hash(table.concat(parts, "|"))
end

function Graph.GetWorldSeed()
    return tonumber(Graph.State.worldSeed) or 0
end

function Graph.GetTopologyRevision()
    return tonumber(Graph.State.revision) or 1
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
    Graph.State.settlementGrid = {}
    Graph.State.trafficHeat = {}
    Graph.State.trafficHeatCount = 0
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return true
end

function Graph.SectorCoords(x, y)
    local size = Graph.SECTOR_SIZE
    return math.floor(finite(x, 0) / size), math.floor(finite(y, 0) / size)
end

local function sectorKey(sx, sy)
    return Graph.PackCoords(sx, sy)
end

local function settlementGridCoords(x, y)
    local size = Graph.SETTLEMENT_GRID_SIZE
    return math.floor(finite(x, 0) / size), math.floor(finite(y, 0) / size)
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
        if evicted ~= nil then
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

local function getMetaGrid()
    local world = type(getWorld) == "function" and getWorld() or nil
    if not world or type(world.getMetaGrid) ~= "function" then
        return nil
    end
    return world:getMetaGrid()
end

local function extractBuildingPOIs(metaGrid, sx, sy, worldSeed, nodes, minSpacingSq)
    if not metaGrid or type(metaGrid.getBuildingsIntersecting) ~= "function" then
        return 0
    end
    local size = Graph.SECTOR_SIZE
    local minX = sx * size
    local minY = sy * size
    local ok, buildings = pcall(
        metaGrid.getBuildingsIntersecting,
        metaGrid,
        minX,
        minY,
        size,
        size
    )
    if not ok or not buildings then return 0 end

    local isJavaList = type(buildings.size) == "function" and type(buildings.get) == "function"
    local total = isJavaList and (tonumber(buildings:size()) or 0) or (type(buildings) == "table" and #buildings or 0)
    if total <= 0 then return 0 end

    -- Bucket buildings into 40-tile clusters using integer-packed keys.
    local clusters = {}
    local clusterKeys = {}
    local inspectCount = math.min(total, Graph.BUILDING_INSPECTION_CAP)
    for i = 0, inspectCount - 1 do
        local b = isJavaList and buildings:get(i) or buildings[i + 1]
        if b then
            local bx, by
            if type(b.getX) == "function" and type(b.getY) == "function" then
                bx = finite(b:getX(), nil)
                by = finite(b:getY(), nil)
                local bw = type(b.getW) == "function" and finite(b:getW(), 0) or 0
                local bh = type(b.getH) == "function" and finite(b:getH(), 0) or 0
                if bx and by then
                    bx = bx + bw * 0.5
                    by = by + bh * 0.5
                end
            elseif type(b) == "table" and b.x and b.y then
                bx = finite(b.x, nil)
                by = finite(b.y, nil)
            end
            if bx and by then
                local cKey = ScavengeLedger.PackClusterKey(bx, by)
                local bucket = clusters[cKey]
                if not bucket then
                    bucket = { sumX = bx, sumY = by, count = 1, key = cKey }
                    clusters[cKey] = bucket
                    clusterKeys[#clusterKeys + 1] = cKey
                else
                    bucket.sumX = bucket.sumX + bx
                    bucket.sumY = bucket.sumY + by
                    bucket.count = bucket.count + 1
                end
            end
        end
    end

    local candidates = {}
    for i = 1, #clusterKeys do
        local bucket = clusters[clusterKeys[i]]
        candidates[#candidates + 1] = {
            x = bucket.sumX / bucket.count,
            y = bucket.sumY / bucket.count,
            z = 0,
            poiKey = bucket.key,
            buildings = bucket.count,
        }
    end

    table.sort(candidates, function(a, b)
        local ha = Graph.MixSeed(worldSeed, "poi", a.poiKey)
        local hb = Graph.MixSeed(worldSeed, "poi", b.poiKey)
        if ha == hb then return a.poiKey < b.poiKey end
        return ha < hb
    end)

    local added = 0
    local sKey = sectorKey(sx, sy)
    for i = 1, #candidates do
        if added >= Graph.MAX_POI_NODES_PER_SECTOR or #nodes >= Graph.MAX_NODES_PER_SECTOR then
            break
        end
        local pt = candidates[i]
        local id = "poi_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
            .. tostring(math.floor(pt.x)) .. "_" .. tostring(math.floor(pt.y))
        if addNodeIfSpaced(nodes, {
            id = id,
            x = pt.x,
            y = pt.y,
            z = 0,
            kind = "poi",
            poiKey = pt.poiKey,
            buildings = pt.buildings,
            sectorKey = sKey,
        }, minSpacingSq) then
            added = added + 1
        end
    end
    return added
end

local function extractSectorNodes(sx, sy, worldSeed, options)
    local nodes = {}
    local metaGrid = getMetaGrid()
    if not metaGrid then
        return nodes
    end

    local size = Graph.SECTOR_SIZE
    local minX = sx * size
    local minY = sy * size
    local sKey = sectorKey(sx, sy)
    local minSpacingSq = Graph.MIN_NODE_SPACING * Graph.MIN_NODE_SPACING

    local navCandidates = {}
    local poiZoneCandidates = {}
    local wildZoneCandidates = {}

    if type(metaGrid.getZonesIntersecting) == "function" then
        local ok, zones = pcall(
            metaGrid.getZonesIntersecting,
            metaGrid,
            minX,
            minY,
            0,
            size,
            size
        )
        if ok and zones and type(zones.size) == "function" then
            local total = tonumber(zones:size()) or 0
            local inspectCount = math.min(total, Graph.ZONE_INSPECTION_CAP)
            for i = 0, inspectCount - 1 do
                local zone = zones.get and zones:get(i) or nil
                if zone then
                    local zType = zone.getType and tostring(zone:getType() or "") or ""
                    local zx = finite(zone.getX and zone:getX(), nil)
                    local zy = finite(zone.getY and zone:getY(), nil)
                    local zw = finite(zone.getWidth and zone:getWidth(), 0)
                    local zh = finite(zone.getHeight and zone:getHeight(), 0)
                    if zx and zy and zw > 0 and zh > 0 then
                        local cx = zx + zw * 0.5
                        local cy = zy + zh * 0.5
                        if zType == "Nav" then
                            if zw >= 48 or zh >= 48 then
                                if zw >= zh then
                                    navCandidates[#navCandidates + 1] = { x = zx + 6, y = cy, z = 0 }
                                    navCandidates[#navCandidates + 1] = { x = cx, y = cy, z = 0 }
                                    navCandidates[#navCandidates + 1] = { x = zx + zw - 6, y = cy, z = 0 }
                                else
                                    navCandidates[#navCandidates + 1] = { x = cx, y = zy + 6, z = 0 }
                                    navCandidates[#navCandidates + 1] = { x = cx, y = cy, z = 0 }
                                    navCandidates[#navCandidates + 1] = { x = cx, y = zy + zh - 6, z = 0 }
                                end
                            else
                                navCandidates[#navCandidates + 1] = { x = cx, y = cy, z = 0 }
                            end
                        elseif zType == "TownZone" or zType == "TrailerPark" then
                            poiZoneCandidates[#poiZoneCandidates + 1] = { x = cx, y = cy, z = 0 }
                        elseif zType == "Forest" or zType == "DeepForest"
                            or zType == "Farm" or zType == "Water"
                        then
                            wildZoneCandidates[#wildZoneCandidates + 1] = { x = cx, y = cy, z = 0 }
                        end
                    end
                end
            end
        end
    end

    -- Tier 2a: MetaGrid "Nav" road nodes.
    table.sort(navCandidates, function(a, b)
        local ha = Graph.MixSeed(worldSeed, "nav", math.floor(a.x), math.floor(a.y))
        local hb = Graph.MixSeed(worldSeed, "nav", math.floor(b.x), math.floor(b.y))
        if ha == hb then
            if a.x == b.x then return a.y < b.y end
            return a.x < b.x
        end
        return ha < hb
    end)
    local navCount = 0
    for i = 1, #navCandidates do
        if navCount >= Graph.MAX_NAV_NODES_PER_SECTOR then break end
        local pt = navCandidates[i]
        local id = "nav_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
            .. tostring(math.floor(pt.x)) .. "_" .. tostring(math.floor(pt.y))
        if addNodeIfSpaced(nodes, {
            id = id,
            x = pt.x,
            y = pt.y,
            z = pt.z or 0,
            kind = "nav",
            sectorKey = sKey,
        }, minSpacingSq) then
            navCount = navCount + 1
        end
    end

    -- Tier 2b: Building-cluster POI nodes (houses/commercial blocks).
    local poiCount = extractBuildingPOIs(metaGrid, sx, sy, worldSeed, nodes, minSpacingSq)
    if poiCount == 0 and #poiZoneCandidates > 0 then
        table.sort(poiZoneCandidates, function(a, b)
            local ha = Graph.MixSeed(worldSeed, "poizone", math.floor(a.x), math.floor(a.y))
            local hb = Graph.MixSeed(worldSeed, "poizone", math.floor(b.x), math.floor(b.y))
            if ha == hb then return a.x < b.x end
            return ha < hb
        end)
        for i = 1, #poiZoneCandidates do
            if poiCount >= Graph.MAX_POI_NODES_PER_SECTOR or #nodes >= Graph.MAX_NODES_PER_SECTOR then
                break
            end
            local pt = poiZoneCandidates[i]
            local id = "poi_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
                .. tostring(math.floor(pt.x)) .. "_" .. tostring(math.floor(pt.y))
            if addNodeIfSpaced(nodes, {
                id = id,
                x = pt.x,
                y = pt.y,
                z = 0,
                kind = "poi",
                poiKey = ScavengeLedger.PackClusterKey(pt.x, pt.y),
                sectorKey = sKey,
            }, minSpacingSq) then
                poiCount = poiCount + 1
            end
        end
    end

    -- Tier 3: Map-agnostic Wilderness Fallback when a sector has neither roads nor buildings.
    if navCount == 0 and poiCount == 0 and (not options or options.allowWildernessFallback ~= false) then
        local wildCount = 0
        if #wildZoneCandidates > 0 then
            table.sort(wildZoneCandidates, function(a, b)
                local ha = Graph.MixSeed(worldSeed, "wild", math.floor(a.x), math.floor(a.y))
                local hb = Graph.MixSeed(worldSeed, "wild", math.floor(b.x), math.floor(b.y))
                if ha == hb then return a.x < b.x end
                return ha < hb
            end)
            for i = 1, #wildZoneCandidates do
                if wildCount >= Graph.MAX_WILDERNESS_NODES_PER_SECTOR then break end
                local pt = wildZoneCandidates[i]
                local id = "wild_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
                    .. tostring(math.floor(pt.x)) .. "_" .. tostring(math.floor(pt.y))
                if addNodeIfSpaced(nodes, {
                    id = id,
                    x = pt.x,
                    y = pt.y,
                    z = 0,
                    kind = "wilderness",
                    poiKey = ScavengeLedger.PackClusterKey(pt.x, pt.y),
                    sectorKey = sKey,
                }, minSpacingSq) then
                    wildCount = wildCount + 1
                end
            end
        end
        -- Pure wilderness/custom maps with no zones in this sector still get deterministic
        -- 3x2 stratified jittered clearings for even coverage across the 300x300 sector.
        local targetWild = Graph.MAX_WILDERNESS_NODES_PER_SECTOR
        local cols, rows = 3, 2
        local cellW = math.floor(size / cols)
        local cellH = math.floor(size / rows)
        for slot = 0, (cols * rows) - 1 do
            if wildCount >= targetWild then break end
            local col = slot % cols
            local row = math.floor(slot / cols)
            local hx = Graph.MixSeed(worldSeed, "wx", slot * 17 + 3, sx, sy)
            local hy = Graph.MixSeed(worldSeed, "wy", sy, slot * 31 + 7, sx)
            local wx = minX + col * cellW + 18 + (hx % math.max(1, cellW - 36))
            local wy = minY + row * cellH + 18 + (hy % math.max(1, cellH - 36))
            local id = "wild_" .. tostring(sx) .. "_" .. tostring(sy) .. "_"
                .. tostring(math.floor(wx)) .. "_" .. tostring(math.floor(wy))
            if addNodeIfSpaced(nodes, {
                id = id,
                x = wx,
                y = wy,
                z = 0,
                kind = "wilderness",
                poiKey = ScavengeLedger.PackClusterKey(wx, wy),
                sectorKey = sKey,
            }, minSpacingSq) then
                wildCount = wildCount + 1
            end
        end
    end

    return nodes
end

local function classifyEdgeKind(a, b)
    if a.kind == "settlement" or b.kind == "settlement" then
        return "settlement"
    end
    if a.kind == "nav" and b.kind == "nav" then
        return "road"
    end
    if a.kind == "poi" or b.kind == "poi" then
        return "feeder"
    end
    return "wilderness"
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
                local eKind = classifyEdgeKind(a, b)
                edges[#edges + 1] = {
                    from = a.id,
                    to = b.id,
                    fromX = a.x,
                    fromY = a.y,
                    toX = b.x,
                    toY = b.y,
                    weight = d,
                    edgeKind = eKind,
                }
                adj[a.id][#adj[a.id] + 1] = { id = b.id, weight = d, edgeKind = eKind }
                adj[b.id][#adj[b.id] + 1] = { id = a.id, weight = d, edgeKind = eKind }
            end
        end
    end
    return edges, adj
end

local function removeAnchorFromGrid(existing)
    if not existing or existing.gridKey == nil then return end
    local bucket = Graph.State.settlementGrid[existing.gridKey]
    if bucket then
        bucket[existing.anchorId] = nil
    end
end

function Graph.RegisterSettlementNode(id, x, y, z, options)
    id = tostring(id or "")
    if id == "" then return nil, "anchor_id_required" end
    options = type(options) == "table" and options or {}
    local nx = finite(x, nil)
    local ny = finite(y, nil)
    local nz = finite(z, 0)
    if not nx or not ny then return nil, "anchor_position_required" end

    local existing = Graph.State.anchors[id]
    if existing then
        removeAnchorFromGrid(existing)
        if existing.sectorKey ~= nil then
            Graph.State.sectors[existing.sectorKey] = nil
        end
    end

    local sx, sy = Graph.SectorCoords(nx, ny)
    local sKey = sectorKey(sx, sy)
    local gx, gy = settlementGridCoords(nx, ny)
    local gKey = Graph.PackCoords(gx, gy)
    local node = {
        id = "anchor:" .. id,
        anchorId = id,
        x = nx,
        y = ny,
        z = nz,
        kind = tostring(options.kind or "settlement"),
        owner = tostring(options.owner or "ai"),
        label = options.label and tostring(options.label) or nil,
        sectorKey = sKey,
        gridKey = gKey,
    }
    Graph.State.anchors[id] = node
    local bucket = Graph.State.settlementGrid[gKey]
    if not bucket then
        bucket = {}
        Graph.State.settlementGrid[gKey] = bucket
    end
    bucket[id] = node

    -- Invalidate cached sector so the new settlement node links into nearby roads/POIs.
    Graph.State.sectors[sKey] = nil
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return node
end

function Graph.UnregisterSettlementNode(id)
    id = tostring(id or "")
    local existing = Graph.State.anchors[id]
    if not existing then return false end
    removeAnchorFromGrid(existing)
    Graph.State.anchors[id] = nil
    if existing.sectorKey ~= nil then
        Graph.State.sectors[existing.sectorKey] = nil
    end
    Graph.State.revision = (tonumber(Graph.State.revision) or 0) + 1
    return true
end

function Graph.FindNearbySettlements(x, y, radius, excludeId)
    local nx = finite(x, 0)
    local ny = finite(y, 0)
    local r = math.max(0, finite(radius, Graph.MIN_SETTLEMENT_SPACING))
    local rSq = r * r
    local gx, gy = settlementGridCoords(nx, ny)
    local span = math.max(1, math.ceil(r / Graph.SETTLEMENT_GRID_SIZE))
    local hits = {}
    for dx = -span, span do
        for dy = -span, span do
            local bucket = Graph.State.settlementGrid[Graph.PackCoords(gx + dx, gy + dy)]
            if bucket then
                for id, node in pairs(bucket) do
                    if id ~= excludeId then
                        local d2 = distSq(nx, ny, node.x, node.y)
                        if d2 <= rSq then
                            hits[#hits + 1] = node
                        end
                    end
                end
            end
        end
    end
    return hits
end

function Graph.HasSettlementWithin(x, y, minDistance, excludeId)
    local r = math.max(0, finite(minDistance, Graph.MIN_SETTLEMENT_SPACING))
    local rSq = r * r
    local nx = finite(x, 0)
    local ny = finite(y, 0)
    local gx, gy = settlementGridCoords(nx, ny)
    local span = math.max(1, math.ceil(r / Graph.SETTLEMENT_GRID_SIZE))
    for dx = -span, span do
        for dy = -span, span do
            local bucket = Graph.State.settlementGrid[Graph.PackCoords(gx + dx, gy + dy)]
            if bucket then
                for id, node in pairs(bucket) do
                    if id ~= excludeId and distSq(nx, ny, node.x, node.y) < rSq then
                        return true, node
                    end
                end
            end
        end
    end
    return false, nil
end

-- Updates live economy/demand metadata on a registered Tier-1 settlement hub
-- so Trader Caravans (DTAbstract/DTHoomans) can route to supply shortages and
-- Looters can evaluate raid targets without scanning full community tables.
function Graph.UpdateSettlementState(id, patch)
    local node = Graph.State.anchors[tostring(id or "")]
    if not node or type(patch) ~= "table" then return false end
    if patch.foodRatio ~= nil then node.foodRatio = math.max(0, math.min(1, finite(patch.foodRatio, 1))) end
    if patch.waterRatio ~= nil then node.waterRatio = math.max(0, math.min(1, finite(patch.waterRatio, 1))) end
    if patch.population ~= nil then node.population = math.max(0, math.floor(finite(patch.population, 0))) end
    if patch.demandLevel ~= nil then node.demandLevel = tostring(patch.demandLevel) end
    if patch.prosperity ~= nil then node.prosperity = math.max(0, finite(patch.prosperity, 0)) end
    return true
end

function Graph.FindSettlementsByDemand(x, y, maxRadius, onlyShortage)
    local hits = Graph.FindNearbySettlements(x, y, maxRadius or 2400)
    local out = {}
    for i = 1, #hits do
        local n = hits[i]
        local isShortage = n.demandLevel == "shortage" or n.demandLevel == "critical"
            or (tonumber(n.foodRatio) and tonumber(n.foodRatio) < 0.35)
        if not onlyShortage or isShortage then
            out[#out + 1] = n
        end
    end
    table.sort(out, function(a, b)
        local fa = tonumber(a.foodRatio) or 1
        local fb = tonumber(b.foodRatio) or 1
        if fa ~= fb then return fa < fb end
        return tostring(a.id) < tostring(b.id)
    end)
    return out
end

-- Lazy-decaying supply-line traffic heat (integer-packed 150-tile buckets, max 64).
-- Traders and Scavengers add heat as they travel; Looters query hot corridors to ambush.
local function effectiveHeat(entry, nowHours)
    if type(entry) ~= "table" then return 0 end
    local elapsed = math.max(0, finite(nowHours, 0) - finite(entry.t, 0))
    local h = finite(entry.h, 0) - (elapsed / Graph.HEAT_DECAY_HOURS)
    return h > 0.01 and math.min(10, h) or 0
end

function Graph.RecordTrafficHeat(x, y, amount, nowHours)
    local size = Graph.HEAT_CELL_SIZE
    local hx = math.floor(finite(x, 0) / size)
    local hy = math.floor(finite(y, 0) / size)
    local key = Graph.PackCoords(hx, hy)
    local now = finite(nowHours, 0)
    local heat = Graph.State.trafficHeat
    local existing = heat[key]
    local prev = existing and effectiveHeat(existing, now) or 0
    if not existing then
        if (Graph.State.trafficHeatCount or 0) >= Graph.MAX_HEAT_ENTRIES then
            local lowestKey, lowestVal = nil, math.huge
            local count = 0
            for k, e in pairs(heat) do
                local v = effectiveHeat(e, now)
                if v <= 0 then
                    heat[k] = nil
                else
                    count = count + 1
                    if v < lowestVal then
                        lowestVal = v
                        lowestKey = k
                    end
                end
            end
            if count >= Graph.MAX_HEAT_ENTRIES and lowestKey ~= nil then
                heat[lowestKey] = nil
                count = count - 1
            end
            Graph.State.trafficHeatCount = count
        end
        Graph.State.trafficHeatCount = (Graph.State.trafficHeatCount or 0) + 1
    end
    local nextH = math.min(10, prev + math.max(0.05, finite(amount, 0.35)))
    heat[key] = { h = nextH, t = now, x = (hx + 0.5) * size, y = (hy + 0.5) * size }
    return nextH
end

function Graph.GetTrafficHeat(x, y, nowHours)
    local size = Graph.HEAT_CELL_SIZE
    local key = Graph.PackCoords(math.floor(finite(x, 0) / size), math.floor(finite(y, 0) / size))
    local entry = Graph.State.trafficHeat[key]
    if not entry then return 0 end
    local val = effectiveHeat(entry, nowHours)
    if val <= 0 then
        Graph.State.trafficHeat[key] = nil
        Graph.State.trafficHeatCount = math.max(0, (Graph.State.trafficHeatCount or 1) - 1)
        return 0
    end
    return val
end

function Graph.FindHottestCorridorPoint(x, y, maxRadius, nowHours)
    local nx, ny = finite(x, 0), finite(y, 0)
    local rSq = math.max(100, finite(maxRadius, 1200))
    rSq = rSq * rSq
    local best, bestScore = nil, 0
    for k, entry in pairs(Graph.State.trafficHeat) do
        local val = effectiveHeat(entry, nowHours)
        if val <= 0 then
            Graph.State.trafficHeat[k] = nil
            Graph.State.trafficHeatCount = math.max(0, (Graph.State.trafficHeatCount or 1) - 1)
        else
            local d2 = distSq(nx, ny, entry.x, entry.y)
            if d2 <= rSq then
                local score = val / (1 + math.sqrt(d2) / 400)
                if score > bestScore then
                    bestScore = score
                    best = { x = entry.x, y = entry.y, z = 0, heat = val, score = score }
                end
            end
        end
    end
    return best
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
    local nodes = extractSectorNodes(sx, sy, seed, options)
    for _, anchor in pairs(Graph.State.anchors) do
        if anchor.sectorKey == key then
            nodes[#nodes + 1] = {
                id = anchor.id,
                anchorId = anchor.anchorId,
                x = anchor.x,
                y = anchor.y,
                z = anchor.z,
                kind = anchor.kind,
                owner = anchor.owner,
                label = anchor.label,
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
