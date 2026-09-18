require "PsychopatzCore/00_PsychopatzCore_Init"

local PlaceContext = require "PsychopatzCore/Debug/PsychopatzPlaceDebugContext"
local ZombiePopulationContext = require
    "PsychopatzCore/Debug/PsychopatzZombiePopulationDebugContext"

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

local function canUseDebug(player)
    local debugAccess = Core.Debug
    return player
        and debugAccess
        and type(debugAccess.CanUse) == "function"
        and debugAccess.CanUse(player) == true
end

local function resolvePlayer(map)
    local playerNum = tonumber(map and map.playerNum) or 0
    if getSpecificPlayer then
        return getSpecificPlayer(playerNum), playerNum
    end
    return getPlayer and getPlayer() or nil, playerNum
end

local function addInspectOption(state)
    if not state or not state.context then
        return false
    end

    state.context:addOption(
        PlaceContext.MapLabel or "[Debug] Inspect Map Place",
        nil,
        function()
            return PlaceContext.InspectCoordinates(
                state.player,
                state.worldX,
                state.worldY,
                state.z,
                "map"
            )
        end
    )
    return true
end

local function addZombiePopulationOption(state)
    if not state or not state.context then
        return false
    end

    state.context:addOption(
        ZombiePopulationContext.MapLabel
            or "[Debug] Inspect Zombie Population",
        nil,
        function()
            return ZombiePopulationContext.InspectCoordinates(
                state.player,
                state.worldX,
                state.worldY,
                state.z,
                "map"
            )
        end
    )
    return true
end

local loadedMap = pcall(require, "ISUI/Maps/ISWorldMap")
local loadedContextMenu = pcall(require, "ISUI/ISContextMenu")

if not loadedMap or not loadedContextMenu
    or not ISWorldMap
    or type(ISWorldMap.onRightMouseUp) ~= "function"
    or not ISContextMenu
    or type(ISContextMenu.get) ~= "function"
then
    return MapContext
end

if ISWorldMap._psychopatzPlaceDebugMapInstalled then
    return MapContext
end
ISWorldMap._psychopatzPlaceDebugMapInstalled = true

local originalRightMouseUp = ISWorldMap.onRightMouseUp
local activeState
local originalContextGet = ISContextMenu.get

-- The vanilla map handler creates the context menu internally. Capture that
-- menu while it runs so this option can coexist with vanilla and other mod
-- map providers without copying the base-game handler.
ISContextMenu.get = function(playerNum, x, y, ...)
    local context = originalContextGet(playerNum, x, y, ...)
    if activeState then
        activeState.context = context
    end
    return context
end

function ISWorldMap:onRightMouseUp(x, y)
    local player, playerNum = resolvePlayer(self)
    local state
    local worldX
    local worldY
    local z
    local previousState = activeState

    if canUseDebug(player) and self.mapAPI then
        worldX = call(self.mapAPI, "uiToWorldX", x, y)
        worldY = call(self.mapAPI, "uiToWorldY", x, y)
        z = call(player, "getZ")
        if z == nil then z = 0 end
        if worldX ~= nil and worldY ~= nil then
            state = {
                player = player,
                playerNum = playerNum,
                worldX = worldX,
                worldY = worldY,
                z = z,
            }
            activeState = state
        end
    end

    local ok, result = pcall(originalRightMouseUp, self, x, y)
    activeState = previousState
    if not ok then
        error(result)
    end

    if state and state.context then
        addInspectOption(state)
        addZombiePopulationOption(state)
    elseif state and result ~= true then
        -- Core debug access can be enabled without the engine's global debug
        -- flag. In that case vanilla returns before creating a context menu.
        state.context = ISContextMenu.get(
            state.playerNum,
            x + (call(self, "getAbsoluteX") or 0),
            y + (call(self, "getAbsoluteY") or 0)
        )
        addInspectOption(state)
        addZombiePopulationOption(state)
        result = true
    end

    return result
end

MapContext.Installed = true

return MapContext
