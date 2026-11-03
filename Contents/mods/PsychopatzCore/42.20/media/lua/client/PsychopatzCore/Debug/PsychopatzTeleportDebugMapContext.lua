require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/World/PsychopatzTeleport"

local MapHost = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Teleport = Core.Teleport
local Translation = Core.Translation
local MapContext = Core.TeleportDebugMapContext or {}
Core.TeleportDebugMapContext = MapContext

local function tr(key, fallback)
    if Translation and Translation.GetKey then
        return Translation.GetKey(key, fallback)
    end
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then return fallback end
    return value
end

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
    if not player or not Teleport or not Teleport.CanUse(player)
        or not map or not map.mapAPI
    then
        return nil
    end

    local worldX = call(map.mapAPI, "uiToWorldX", x, y)
    local worldY = call(map.mapAPI, "uiToWorldY", x, y)
    if worldX == nil or worldY == nil then return nil end

    return {
        player = player,
        worldX = worldX,
        worldY = worldY,
        z = call(player, "getZ") or 0,
    }
end

local function addTeleportOption(context, state)
    if not context or not state then return false end
    local label = tr(
        "ContextMenu_Psychopatz_TeleportHere",
        "[Debug] Teleport Here"
    ) .. " (" .. math.floor(state.worldX)
        .. ", " .. math.floor(state.worldY) .. ")"

    context:addOption(label, nil, function()
        pcall(Teleport.ToCoordinates,
            state.player, state.worldX, state.worldY, state.z)
    end)
    return true
end

MapHost.Contexts.Register("PsychopatzCore:teleport_debug", {
    order = 20,
    available = function(map, x, y)
        return resolveState(map, x, y) ~= nil
    end,
    augment = function(map, context, x, y)
        local ok, added = pcall(
            addTeleportOption, context, resolveState(map, x, y))
        return ok and added == true
    end,
})

MapContext.Installed = true

return MapContext
