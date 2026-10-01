require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/World/PsychopatzTeleport"

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
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function canUseDebug(player)
    return Teleport.CanUse(player)
end

local function resolvePlayer(map)
    local playerNum = tonumber(map and map.playerNum) or 0
    if getSpecificPlayer then
        return getSpecificPlayer(playerNum), playerNum
    end
    return getPlayer and getPlayer() or nil, playerNum
end

local function addTeleportOptionUnsafe(state)
    if not state or not state.context then return false end

    -- Coordinates are echoed in the label so a tester can see the resolved
    -- destination before committing to it.
    local label = tr("ContextMenu_Psychopatz_TeleportHere",
        "[Debug] Teleport Here") .. " ("
        .. math.floor(state.worldX) .. ", "
        .. math.floor(state.worldY) .. ")"

    state.context:addOption(label, nil, function()
        -- The world map is a top-down view, so ground level is the intended
        -- destination; the player's own level is only the second candidate and
        -- ResolveDestination falls back from there. Never touches the base
        -- game option, which keeps using ISWorldMap:onTeleport.
        pcall(Teleport.ToCoordinates,
            state.player,
            state.worldX,
            state.worldY,
            state.z)
    end)
    return true
end

--- Fault containment: a defect in this option must never break the base-game
-- map context menu, which is built by the handler this module wraps.
local function addTeleportOption(state)
    local ok, added = pcall(addTeleportOptionUnsafe, state)
    if not ok then return false end
    return added == true
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

if ISWorldMap._psychopatzTeleportDebugMapInstalled then
    return MapContext
end
ISWorldMap._psychopatzTeleportDebugMapInstalled = true

local originalRightMouseUp = ISWorldMap.onRightMouseUp
local activeState
local originalContextGet = ISContextMenu.get

-- The vanilla handler builds its context menu internally. Capture that menu
-- while it runs so this option is appended next to the base-game entries
-- instead of replacing the handler or the vanilla teleport option.
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
        addTeleportOption(state)
    elseif state and result ~= true then
        -- The core debug gate can be open while the engine's global debug flag
        -- is off, in which case vanilla returns before creating a menu.
        state.context = ISContextMenu.get(
            state.playerNum,
            x + (call(self, "getAbsoluteX") or 0),
            y + (call(self, "getAbsoluteY") or 0)
        )
        addTeleportOption(state)
        result = true
    end

    return result
end

MapContext.Installed = true

return MapContext
