-- Primitive snapshot boundary for the client preview framework.
-- Java objects, functions, and metatables must never cross this boundary.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = PsychopatzCore.Preview
local Snapshot = Preview.Snapshot or {}
Preview.Snapshot = Snapshot

Snapshot.VERSION = 1
Snapshot.MAX_DEPTH = 5
Snapshot.MAX_OBJECTS = 4096
Snapshot.MAX_ZONES = 256

local function primitive(value, depth, seen)
    local valueType = type(value)
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" then return nil end
    depth = tonumber(depth) or 0
    if depth >= Snapshot.MAX_DEPTH then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local output = {}
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number"
            or keyType == "boolean"
        then
            local copied = primitive(child, depth + 1, seen)
            if copied ~= nil then output[key] = copied end
        end
    end
    seen[value] = nil
    return output
end

Snapshot.CopyPrimitive = primitive

local function text(value, fallback)
    value = tostring(value or "")
    if value == "" then return fallback end
    return value
end

local function coordinate(value)
    value = tonumber(value)
    if value == nil or value ~= value then return nil end
    return value
end

local function objectID(object, index)
    if type(object) ~= "table" then return nil end
    local value = object.id or object.objectKey or object.targetID
    if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    return "object:" .. tostring(math.floor(coordinate(object.x) or 0))
        .. ":" .. tostring(math.floor(coordinate(object.y) or 0))
        .. ":" .. tostring(math.floor(coordinate(object.z) or 0))
        .. ":" .. tostring(index or 0)
end

local function normalizeCoordinates(record, key)
    if type(record) ~= "table" then return false end
    local x, y, z = coordinate(record.x), coordinate(record.y),
        coordinate(record.z)
    if x ~= nil and y ~= nil and z ~= nil then
        record.x, record.y, record.z = x, y, z
        return true
    end
    if key ~= "zones" then return false end
    local bounds = record.roomBounds or record.bounds
    if type(bounds) ~= "table" then return false end
    local minX, minY = coordinate(bounds.minX), coordinate(bounds.minY)
    local maxX, maxY = coordinate(bounds.maxX), coordinate(bounds.maxY)
    z = z or coordinate(bounds.z)
    if minX == nil or minY == nil or maxX == nil or maxY == nil
        or z == nil
    then return false end
    record.x = (minX + maxX) / 2
    record.y = (minY + maxY) / 2
    record.z = z
    return true
end

local function normalizeRecords(source, key, limit)
    local output = {}
    local values = type(source[key]) == "table" and source[key] or {}
    local maximum = math.min(limit, #values)
    for index = 1, maximum do
        local record = values[index]
        if normalizeCoordinates(record, key) then
            if key == "objects" then record.id = objectID(record, index) end
            output[#output + 1] = record
        end
    end
    return output
end

function Snapshot.Normalize(value, providerID)
    local source = primitive(value) or {}
    local output = {
        version = tonumber(source.version) or Snapshot.VERSION,
        status = text(source.status, "UNAVAILABLE"),
        providerID = text(source.providerID, providerID or "unknown"),
        source = text(source.source, nil),
        origin = type(source.origin) == "table" and source.origin or nil,
        radius = tonumber(source.radius),
        maxObjects = tonumber(source.maxObjects),
        objects = {},
        zones = {},
        campPreview = source.campPreview,
        diagnostics = type(source.diagnostics) == "table"
            and source.diagnostics or {},
        providers = type(source.providers) == "table" and source.providers
            or {},
        observedAt = tonumber(source.observedAt),
    }
    if output.status ~= "READY" and output.status ~= "UNAVAILABLE" then
        output.status = "UNAVAILABLE"
    end
    output.objects = normalizeRecords(source, "objects", Snapshot.MAX_OBJECTS)
    output.zones = normalizeRecords(source, "zones", Snapshot.MAX_ZONES)
    return output
end

function Snapshot.IsReady(value)
    return type(value) == "table" and value.status == "READY"
end

return Snapshot
