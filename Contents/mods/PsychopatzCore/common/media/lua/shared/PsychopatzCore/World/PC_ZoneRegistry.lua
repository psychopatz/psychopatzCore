PsychopatzCore = PsychopatzCore or {}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = PsychopatzCore.Zones or {}

Zones.SCHEMA_VERSION = 1
Zones.BUCKET_SIZE = Zones.BUCKET_SIZE or 10

local function hasEntries(source)
    for _, _ in pairs(type(source) == "table" and source or {}) do
        return true
    end
    return false
end
Zones._byID = Zones._byID or {}
Zones._buckets = Zones._buckets or {}
Zones._memberships = Zones._memberships or {}

local function bucketKey(x, y)
    local size = Zones.BUCKET_SIZE
    return tostring(math.floor(x / size)) .. ":" .. tostring(math.floor(y / size))
end

local function removeIndex(id)
    local memberships = Zones._memberships[id]
    for index = 1, #(memberships or {}) do
        local key = memberships[index]
        local bucket = Zones._buckets[key]
        if bucket then
            bucket[id] = nil
            if not hasEntries(bucket) then Zones._buckets[key] = nil end
        end
    end
    Zones._memberships[id] = nil
end

local function addIndex(zone)
    local bounds = zone.cachedBounds
    if not bounds then return end
    local memberships = {}
    local minX = math.floor(bounds.minX / Zones.BUCKET_SIZE)
    local maxX = math.floor(bounds.maxX / Zones.BUCKET_SIZE)
    local minY = math.floor(bounds.minY / Zones.BUCKET_SIZE)
    local maxY = math.floor(bounds.maxY / Zones.BUCKET_SIZE)
    for cellX = minX, maxX do
        for cellY = minY, maxY do
            local key = tostring(cellX) .. ":" .. tostring(cellY)
            local bucket = Zones._buckets[key]
            if not bucket then bucket = {}; Zones._buckets[key] = bucket end
            bucket[zone.id] = true
            memberships[#memberships + 1] = key
        end
    end
    Zones._memberships[zone.id] = memberships
end

local function normalizeRecord(source, existing)
    if type(source) ~= "table" or type(source.id) ~= "string" or source.id == "" then
        return nil, "INVALID_ZONE"
    end
    local ok, reason, geometry = GridRegion.validate(source.geometry)
    if not ok then return nil, reason end
    return {
        schemaVersion = Zones.SCHEMA_VERSION,
        id = source.id,
        ownerType = tostring(source.ownerType or ""),
        ownerId = tostring(source.ownerId or ""),
        type = tostring(source.type or "generic"),
        subtype = source.subtype and tostring(source.subtype) or nil,
        geometry = geometry,
        cachedTileCount = GridRegion.countTiles(geometry),
        cachedBounds = GridRegion.bounds(geometry),
        revision = existing and ((tonumber(existing.revision) or 0) + 1)
            or math.max(0, math.floor(tonumber(source.revision) or 0)),
    }
end

function Zones.register(source)
    local existing = type(source) == "table" and Zones._byID[source.id] or nil
    local zone, reason = normalizeRecord(source, existing)
    if not zone then return false, reason end
    if existing then removeIndex(zone.id) end
    Zones._byID[zone.id] = zone
    addIndex(zone)
    return true, zone
end

function Zones.updateGeometry(id, geometry, expectedRevision)
    local current = Zones._byID[tostring(id or "")]
    if not current then return false, "ZONE_NOT_FOUND" end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= current.revision then
        return false, "REVISION_CONFLICT"
    end
    local source = {}
    for key, value in pairs(current) do source[key] = value end
    source.geometry = geometry
    return Zones.register(source)
end

function Zones.get(id) return Zones._byID[tostring(id or "")] end

function Zones.remove(id)
    id = tostring(id or "")
    if not Zones._byID[id] then return false, "ZONE_NOT_FOUND" end
    removeIndex(id)
    Zones._byID[id] = nil
    return true
end

function Zones.queryPoint(x, y, z, zoneType)
    local output = {}
    local bucket = Zones._buckets[bucketKey(x, y)]
    for id, _ in pairs(bucket or {}) do
        local zone = Zones._byID[id]
        local bounds = zone and zone.cachedBounds
        if zone and (not zoneType or zone.type == zoneType) and bounds
            and x >= bounds.minX and x <= bounds.maxX
            and y >= bounds.minY and y <= bounds.maxY
            and z >= bounds.minZ and z <= bounds.maxZ
            and GridRegion.containsPoint(zone.geometry, x, y, z)
        then
            output[#output + 1] = zone
        end
    end
    return output
end

function Zones.export()
    local output = { schemaVersion = Zones.SCHEMA_VERSION, byID = {} }
    for id, zone in pairs(Zones._byID) do
        output.byID[id] = {
            schemaVersion = zone.schemaVersion, id = zone.id,
            ownerType = zone.ownerType, ownerId = zone.ownerId,
            type = zone.type, subtype = zone.subtype,
            geometry = GridRegion.normalize(zone.geometry), revision = zone.revision,
        }
    end
    return output
end

function Zones.import(payload)
    Zones._byID, Zones._buckets, Zones._memberships = {}, {}, {}
    local accepted = 0
    for _, zone in pairs(type(payload) == "table" and payload.byID or {}) do
        local ok = Zones.register(zone)
        if ok then accepted = accepted + 1 end
    end
    return true, accepted
end

function Zones.debugStats()
    local zones, buckets, memberships = 0, 0, 0
    for _, _ in pairs(Zones._byID) do zones = zones + 1 end
    for _, bucket in pairs(Zones._buckets) do
        buckets = buckets + 1
        for _, _ in pairs(bucket) do memberships = memberships + 1 end
    end
    return { zones = zones, buckets = buckets, memberships = memberships }
end

PsychopatzCore.Zones = Zones
PC_Zones = Zones
return Zones
