require "PsychopatzCore/00_PsychopatzCore_Init"

local PlaceContext =
    require "PsychopatzCore/Debug/PsychopatzPlaceDebugContext"
local ZombiePopulationContext = require
    "PsychopatzCore/Debug/PsychopatzZombiePopulationDebugContext"
local MapHost = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local MapContext = Core.PlaceDebugMapContext or {}
Core.PlaceDebugMapContext = MapContext

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function resolveState(map, x, y)
    local playerNum = tonumber(map and map.playerNum) or 0
    local player = getSpecificPlayer and getSpecificPlayer(playerNum)
        or (getPlayer and getPlayer() or nil)
    local debugAccess = Core.Debug
    if not player or not debugAccess
        or type(debugAccess.CanUse) ~= "function"
        or debugAccess.CanUse(player) ~= true
        or not map or not map.mapAPI
    then
        return nil
    end

    local worldX = call(map.mapAPI, "uiToWorldX", x, y)
    local worldY = call(map.mapAPI, "uiToWorldY", x, y)
    if worldX == nil or worldY == nil then return nil end

    return {
        player = player,
        playerNum = playerNum,
        worldX = worldX,
        worldY = worldY,
        z = call(player, "getZ") or 0,
    }
end

local function addOptions(context, state)
    if not context or not state then return false end
    context:addOption(
        PlaceContext.MapLabel or "[Debug] Inspect Map Place",
        nil,
        function()
            return PlaceContext.InspectCoordinates(
                state.player, state.worldX, state.worldY,
                state.z, "map")
        end
    )
    context:addOption(
        ZombiePopulationContext.MapLabel
            or "[Debug] Inspect Zombie Population",
        nil,
        function()
            return ZombiePopulationContext.InspectCoordinates(
                state.player, state.worldX, state.worldY,
                state.z, "map")
        end
    )
    return true
end

MapHost.Contexts.Register("PsychopatzCore:place_debug", {
    order = 30,
    available = function(map, x, y)
        return resolveState(map, x, y) ~= nil
    end,
    augment = function(map, context, x, y)
        return addOptions(context, resolveState(map, x, y))
    end,
})

MapContext.Installed = true

return MapContext
