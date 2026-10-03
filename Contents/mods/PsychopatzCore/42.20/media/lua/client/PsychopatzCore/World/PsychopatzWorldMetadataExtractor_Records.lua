PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor
local Internal = Extractor.Internal or {}
Extractor.Internal = Internal

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function callGlobal(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function number(value)
    if value == nil then return nil end
    return tonumber(value)
end

local function nonEmptyString(value)
    if value == nil then return nil end
    local text = tostring(value)
    return text ~= "" and text or nil
end

local function normalizedName(value)
    local text = nonEmptyString(value)
    if not text then return nil end
    text = string.lower(text)
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text ~= "" and text or nil
end

local function safeFileName(value)
    local text = nonEmptyString(value) or "Unassigned"
    text = string.gsub(text, "[^%w%-%_ ]", "_")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text ~= "" and text or "Unassigned"
end

local function increment(bucket, key)
    bucket[key] = (bucket[key] or 0) + 1
end

local function addUnique(list, seen, value)
    if not value or seen[value] then return false end
    seen[value] = true
    list[#list + 1] = value
    return true
end

local function listSize(list)
    local size = number(call(list, "size"))
    if not size or size < 0 then return nil end
    return math.floor(size)
end

local function listItem(list, index)
    return call(list, "get", index)
end

local function boundsFor(object, widthMethod, heightMethod, x2Method, y2Method)
    local x = number(call(object, "getX"))
    local y = number(call(object, "getY"))
    local width = number(call(object, widthMethod))
    local height = number(call(object, heightMethod))
    local x2 = number(call(object, x2Method))
    local y2 = number(call(object, y2Method))
    if width == nil and x ~= nil and x2 ~= nil then width = x2 - x + 1 end
    if height == nil and y ~= nil and y2 ~= nil then height = y2 - y + 1 end
    if x == nil or y == nil or width == nil or height == nil then
        return nil
    end
    return { x = x, y = y, width = width, height = height }
end

local function sizeFor(bounds, extras)
    local result = {
        width = bounds and bounds.width or 0,
        height = bounds and bounds.height or 0,
    }
    result.area = result.width * result.height
    if type(extras) == "table" then
        for key, value in pairs(extras) do result[key] = value end
    end
    return result
end

local function overlaps(left, right)
    if not left or not right then return false end
    return left.x < right.x + right.width
        and right.x < left.x + left.width
        and left.y < right.y + right.height
        and right.y < left.y + left.height
end

local function engineID(object)
    local id = nonEmptyString(call(object, "getIDString"))
    if id then return id end
    return nonEmptyString(call(object, "getID"))
end

local function compareID(left, right)
    return tostring(left.id or "") < tostring(right.id or "")
end

local function zoneIsTechnical(zoneType)
    local value = string.lower(tostring(zoneType or ""))
    return value == "nav" or value == "foragingnav"
        or value == "spawnpoint"
end

local function zoneDetails(zone)
    local bounds = boundsFor(zone, "getWidth", "getHeight", nil, nil)
    local rawName = nonEmptyString(call(zone, "getName"))
    local originalName = nonEmptyString(call(zone, "getOriginalName"))
    local zoneType = nonEmptyString(call(zone, "getType"))
    local normalizedType = normalizedName(zoneType) or "unknown"
    local normalizedZoneName = normalizedName(originalName or rawName)
    local key = normalizedType .. "|" .. (normalizedZoneName or "")
    local placeName
    if zoneType == "Region" or (zoneType == "TownZone" and rawName) then
        placeName = rawName or originalName
    end
    return {
        id = "zone:" .. key,
        type = "zone",
        rawName = rawName,
        originalName = originalName,
        zoneType = zoneType,
        normalizedName = normalizedZoneName,
        bounds = bounds,
        placeName = placeName,
        isPlaceZone = zoneType == "Region"
            or (zoneType == "TownZone"
                and (rawName ~= nil or originalName ~= nil)),
    }
end

local function publicZone(zone)
    return {
        id = zone.id,
        type = zone.type,
        rawName = zone.rawName,
        originalName = zone.originalName,
        zoneType = zone.zoneType,
        normalizedName = zone.normalizedName,
        size = zone.size,
        features = zone.features,
    }
end

local function publicRoom(room)
    return {
        id = room.id,
        type = room.type,
        rawName = room.rawName,
        normalizedName = room.normalizedName,
        level = room.level,
        size = room.size,
        features = room.features,
    }
end

local function publicBuilding(building)
    return {
        id = building.id,
        type = building.type,
        size = building.size,
        zoneIDs = building.zoneIDs,
        features = building.features,
        rooms = building.rooms,
    }
end



Internal.call = call
Internal.callGlobal = callGlobal
Internal.number = number
Internal.nonEmptyString = nonEmptyString
Internal.normalizedName = normalizedName
Internal.safeFileName = safeFileName
Internal.increment = increment
Internal.addUnique = addUnique
Internal.listSize = listSize
Internal.listItem = listItem
Internal.boundsFor = boundsFor
Internal.sizeFor = sizeFor
Internal.overlaps = overlaps
Internal.engineID = engineID
Internal.compareID = compareID
Internal.zoneIsTechnical = zoneIsTechnical
Internal.zoneDetails = zoneDetails
Internal.publicZone = publicZone
Internal.publicRoom = publicRoom
Internal.publicBuilding = publicBuilding

return Internal

