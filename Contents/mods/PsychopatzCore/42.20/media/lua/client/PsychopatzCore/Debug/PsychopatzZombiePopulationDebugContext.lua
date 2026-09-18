require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Context = Core.ZombiePopulationDebugContext or {}
local Translation = Core.Translation
local LABEL = Translation and Translation.GetKey
    and Translation.GetKey("UI_PsychopatzZombiePopulation_InspectMap",
        "[Debug] Inspect Zombie Population")
    or "[Debug] Inspect Zombie Population"

Core.ZombiePopulationDebugContext = Context

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    if not ok then return nil end
    return value
end

local function callGlobal(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if not ok then return nil end
    return value
end

local function display(value)
    if value == nil then return "<nil>" end
    return tostring(value)
end

local function coordinate(value)
    local number = tonumber(value)
    return number and math.floor(number) or value
end

local function chunkCoordinate(value, size)
    local number = tonumber(value)
    return number and math.floor(number / size) or nil
end

local function normalizeByte(value)
    local number = tonumber(value)
    if not number then return nil end
    number = math.floor(number)
    if number < 0 then number = number + 256 end
    return number
end

local function round(value)
    local number = tonumber(value)
    if not number then return nil end
    return math.floor(number + 0.5)
end

local function zoneIdentity(zone)
    return table.concat({
        display(call(zone, "getType")),
        display(call(zone, "getName")),
        display(call(zone, "getX")),
        display(call(zone, "getY")),
        display(call(zone, "getZ")),
        display(call(zone, "getWidth")),
        display(call(zone, "getHeight")),
    }, "|")
end

local function zoneSummary(metaGrid, x, y, z)
    local zones = call(metaGrid, "getZonesAt", x, y, z)
    local size = call(zones, "size")
    if type(size) ~= "number" then return "<unavailable>", nil end

    local names = {}
    local seen = {}
    local zombiesType
    for index = 0, size - 1 do
        local zone = call(zones, "get", index)
        if zone then
            local identity = zoneIdentity(zone)
            if not seen[identity] then
                seen[identity] = true
                names[#names + 1] = display(call(zone, "getName"))
                    .. ":" .. display(call(zone, "getType"))
            end
            if not zombiesType and call(zone, "getType") == "ZombiesType" then
                zombiesType = call(zone, "getName")
            end
        end
    end

    if #names == 0 then return "<none>", zombiesType end
    return table.concat(names, ","), zombiesType
end

local function staticPopulation(metaGrid, x, y)
    local metaChunk = call(metaGrid, "getChunkDataFromTile", x, y)
    if not metaChunk then
        local metaX = chunkCoordinate(x, 8)
        local metaY = chunkCoordinate(y, 8)
        metaChunk = call(metaGrid, "getChunkData", metaX, metaY)
    end
    if not metaChunk then
        return nil
    end

    local raw = normalizeByte(call(metaChunk, "getUnadjustedZombieIntensity"))
    local adjusted = call(metaChunk, "getZombieIntensity", false)
    local source = "metaChunk.getZombieIntensity(false)"
    if adjusted == nil and raw ~= nil then
        adjusted = 0.06 + (raw / 255.0) * 11.94
        source = "raw meta intensity fallback"
    end

    return {
        raw = raw,
        adjusted = tonumber(adjusted),
        estimated = round(adjusted),
        source = source,
    }
end

local function isChunkLoaded(metaGrid, physicalX, physicalY)
    if not metaGrid or physicalX == nil or physicalY == nil then
        return nil
    end
    return call(metaGrid, "isChunkLoaded", physicalX, physicalY)
end

local function countLoadedZombies(world, physicalX, physicalY)
    local cell = call(world, "getCell")
    local zombies = call(cell, "getZombieList")
    local size = call(zombies, "size")
    if type(size) ~= "number" then return nil end

    local count = 0
    for index = 0, size - 1 do
        local zombie = call(zombies, "get", index)
        local x = call(zombie, "getX")
        local y = call(zombie, "getY")
        if chunkCoordinate(x, 10) == physicalX
            and chunkCoordinate(y, 10) == physicalY
        then
            count = count + 1
        end
    end
    return count
end

local function inspectAt(player, x, y, z, source)
    if not Core.Debug or type(Core.Debug.CanUse) ~= "function"
        or Core.Debug.CanUse(player) ~= true
    then
        return false
    end

    x = coordinate(x)
    y = coordinate(y)
    z = coordinate(z)
    if x == nil or y == nil then return false end
    if z == nil then z = 0 end

    local world = callGlobal(getWorld)
    local metaGrid = call(world, "getMetaGrid")
    if not metaGrid then
        print(LABEL .. " | source=" .. display(source)
            .. " | coords=" .. display(x) .. "," .. display(y)
            .. "," .. display(z) .. " | metaGrid=<unavailable>")
        return true
    end

    local metaX = chunkCoordinate(x, 8)
    local metaY = chunkCoordinate(y, 8)
    local physicalX = chunkCoordinate(x, 10)
    local physicalY = chunkCoordinate(y, 10)
    local population = staticPopulation(metaGrid, x, y)
    local loaded = isChunkLoaded(metaGrid, physicalX, physicalY)
    local exactCount
    if loaded == true then
        exactCount = countLoadedZombies(world, physicalX, physicalY)
    end

    local zones, zombiesType = zoneSummary(metaGrid, x, y, z)
    local confidence = exactCount ~= nil and "exact-loaded-chunk" or "estimated"
    print(LABEL
        .. " | source=" .. display(source)
        .. " | coords=" .. display(x) .. "," .. display(y)
        .. "," .. display(z)
        .. " | metaChunk=" .. display(metaX) .. "," .. display(metaY)
        .. " | physicalChunk=" .. display(physicalX) .. "," .. display(physicalY)
        .. " | loaded=" .. display(loaded)
        .. " | exactCount=" .. display(exactCount)
        .. " | estimatedCount=" .. display(population and population.estimated)
        .. " | density=" .. display(population and population.adjusted)
        .. " | rawIntensity=" .. display(population and population.raw)
        .. " | confidence=" .. confidence
        .. " | sourceMetadata=" .. display(population and population.source)
        .. " | zombiesType=" .. display(zombiesType)
        .. " | zones=" .. display(zones))
    return true
end

function Context.InspectCoordinates(player, x, y, z, source)
    return inspectAt(player, x, y, z, source)
end

Context.MapLabel = LABEL

return Context
