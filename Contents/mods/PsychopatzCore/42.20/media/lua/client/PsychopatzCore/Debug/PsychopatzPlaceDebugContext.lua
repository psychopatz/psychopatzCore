require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Context = Core.PlaceDebugContext or {}
local Translation = Core.Translation
local LABEL = Translation and Translation.GetKey
    and Translation.GetKey("UI_PsychopatzPlace_Inspect",
        "[Debug] Inspect Current Place")
    or "[Debug] Inspect Current Place"
local MAP_LABEL = Translation and Translation.GetKey
    and Translation.GetKey("UI_PsychopatzPlace_InspectMap",
        "[Debug] Inspect Map Place")
    or "[Debug] Inspect Map Place"

Core.PlaceDebugContext = Context

local function canUseDebug(player)
    local debugAccess = Core.Debug
    return debugAccess
        and type(debugAccess.CanUse) == "function"
        and debugAccess.CanUse(player) == true
end

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

local function property(object, key)
    if not object then return nil end
    local ok, value = pcall(function() return object[key] end)
    return ok and value or nil
end

local function display(value)
    if value == nil then return "<nil>" end
    return tostring(value)
end

local function coordinate(value)
    local number = tonumber(value)
    return number and math.floor(number) or value
end

local function describeZone(zone)
    if not zone then return nil end
    return display(call(zone, "getName"))
        .. ":" .. display(call(zone, "getType"))
end

local function zoneIdentity(zone)
    local id = property(zone, "id")
        or call(zone, "getIDString") or call(zone, "getID")
    if id ~= nil then return tostring(id) end
    return table.concat({
        display(call(zone, "getType")),
        display(call(zone, "getName")),
        display(call(zone, "getOriginalName")),
        display(call(zone, "getX")),
        display(call(zone, "getY")),
        display(call(zone, "getZ")),
        display(call(zone, "getWidth")),
        display(call(zone, "getHeight")),
    }, "|")
end

local function describeZoneMetadata(zone)
    local zoneType = call(zone, "getType")
    local width = call(zone, "getWidth")
    local height = call(zone, "getHeight")
    local area = call(zone, "getTotalArea")
    local numericWidth = tonumber(width)
    local numericHeight = tonumber(height)
    if area == nil and numericWidth and numericHeight then
        area = numericWidth * numericHeight
    end
    local parts = {
        "type=" .. display(zoneType),
        "name=" .. display(call(zone, "getName")),
        "original=" .. display(call(zone, "getOriginalName")),
        "level=" .. display(call(zone, "getZ")),
        "size=" .. display(width) .. "x" .. display(height),
        "area=" .. display(area),
    }
    local id = property(zone, "id")
        or call(zone, "getIDString") or call(zone, "getID")
    if id ~= nil then parts[#parts + 1] = "id=" .. display(id) end

    local geometry = property(zone, "geometryType")
    if geometry ~= nil then
        parts[#parts + 1] = "geometry=" .. display(geometry)
    end
    local preferred = property(zone, "isPreferredZoneForSquare")
    if preferred ~= nil then
        parts[#parts + 1] = "preferred=" .. display(preferred)
    end
    local construction = call(zone, "haveCons")
    if construction == nil then construction = property(zone, "haveConstruction") end
    if construction ~= nil then
        parts[#parts + 1] = "construction=" .. display(construction)
    end

    local zombieSpawnType = property(zone, "zombiesTypeToSpawn")
    if zombieSpawnType ~= nil then
        parts[#parts + 1] = "zombiesTypeToSpawn=" .. display(zombieSpawnType)
    end
    local specialZombies = property(zone, "spawnSpecialZombies")
    if specialZombies ~= nil then
        parts[#parts + 1] = "spawnSpecialZombies=" .. display(specialZombies)
    end
    if zoneType == "ZombiesType" then
        local density = call(zone, "getZombieDensity")
        if density ~= nil then
            parts[#parts + 1] = "zombieDensity=" .. display(density)
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function inspectZones(metaGrid, x, y, z, preferredZone)
    local zones
    local zoneParts = {}
    local metadataParts = {}
    local metadataSeen = {}
    local townName
    local index
    local count
    local zone
    local zoneType

    local function appendMetadata(zone)
        if not zone then return end
        local identity = zoneIdentity(zone)
        if metadataSeen[identity] then return end
        metadataSeen[identity] = true
        metadataParts[#metadataParts + 1] = describeZoneMetadata(zone)
    end

    if metaGrid and x ~= nil and y ~= nil and z ~= nil then
        zones = call(metaGrid, "getZonesAt", x, y, z)
    end

    if zones then
        count = call(zones, "size")
        if type(count) == "number" then
            for index = 0, count - 1 do
                zone = call(zones, "get", index)
                if zone then
                    zoneType = call(zone, "getType")
                    if not townName and zoneType == "TownZone" then
                        townName = call(zone, "getName")
                    end
                    zoneParts[#zoneParts + 1] = describeZone(zone)
                    appendMetadata(zone)
                end
            end
        end
    end

    if preferredZone then
        zoneType = call(preferredZone, "getType")
        if not townName and zoneType == "TownZone" then
            townName = call(preferredZone, "getName")
        end
        if #zoneParts == 0 then
            zoneParts[1] = describeZone(preferredZone)
        end
        appendMetadata(preferredZone)
    end

    local allZones
    if not zones and not preferredZone then
        allZones = "<unavailable>"
    elseif #zoneParts == 0 then
        allZones = "<none>"
    else
        allZones = table.concat(zoneParts, ",")
    end

    local allMetadata
    if not zones and not preferredZone then
        allMetadata = "<unavailable>"
    elseif #metadataParts == 0 then
        allMetadata = "<none>"
    else
        allMetadata = table.concat(metadataParts, ";")
    end

    return townName, allZones, allMetadata
end

local function inspectAt(player, x, y, z, source, square)
    local world
    local metaGrid
    local preferredZone
    local roomDef
    local townName
    local allZones
    local zoneMetadata
    local squareZoneType
    local squareZombiesType
    local squareLootZone

    if not canUseDebug(player) then
        return false
    end

    x = coordinate(x)
    y = coordinate(y)
    z = coordinate(z)

    if not square and source ~= "map"
        and x ~= nil and y ~= nil and z ~= nil
    then
        square = callGlobal(getSquare, x, y, z)
    end

    if x ~= nil and y ~= nil and z ~= nil then
        preferredZone = callGlobal(getZone, x, y, z)
    end

    world = callGlobal(getWorld)
    metaGrid = call(world, "getMetaGrid")
    townName, allZones, zoneMetadata = inspectZones(
        metaGrid, x, y, z, preferredZone)
    roomDef = call(square, "getRoomDef")
    if not roomDef and metaGrid
        and x ~= nil and y ~= nil and z ~= nil
    then
        roomDef = call(metaGrid, "getRoomAt", x, y, z)
    end
    squareZoneType = call(square, "getZoneType")
    squareZombiesType = call(square, "getSquareZombiesType")
        or call(square, "getZombiesType")
    squareLootZone = call(square, "getLootZone")

    print((source == "map" and MAP_LABEL or LABEL)
        .. (source and " | source=" .. display(source) or "")
        .. " | coords=" .. display(x) .. "," .. display(y)
        .. "," .. display(z)
        .. " | town=" .. display(townName)
        .. " | preferredZone=" .. display(describeZone(preferredZone))
        .. " | zones=" .. display(allZones)
        .. " | zoneMetadata=" .. display(zoneMetadata)
        .. " | squareZoneType=" .. display(squareZoneType)
        .. " | squareZombiesType=" .. display(squareZombiesType)
        .. " | squareLootZone=" .. display(squareLootZone)
        .. " | room=" .. display(call(roomDef, "getName")))
    return true
end

function Context.InspectCoordinates(player, x, y, z, source)
    return inspectAt(player, x, y, z, source)
end

function Context.Inspect(player)
    local square = call(player, "getCurrentSquare")
    local x = call(square, "getX") or call(player, "getX")
    local y = call(square, "getY") or call(player, "getY")
    local z = call(square, "getZ") or call(player, "getZ")
    return inspectAt(player, x, y, z, nil, square)
end

function Context.Add(context, player)
    if not canUseDebug(player) or not context then
        return nil
    end

    return context:addOption(LABEL, nil, function()
        return Context.Inspect(player)
    end)
end

Context.Label = LABEL
Context.MapLabel = MAP_LABEL

return Context
