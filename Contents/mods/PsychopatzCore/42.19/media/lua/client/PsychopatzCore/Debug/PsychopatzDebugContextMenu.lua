require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Debug = Core.Debug
local Hub = Core.DebugHub

if Core._debugContextMenuInstalled then
    return Core.DebugContextMenu
end
Core._debugContextMenuInstalled = true

local ContextMenu = {}
Core.DebugContextMenu = ContextMenu

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

local function resolvePlayer(playerNum)
    if getSpecificPlayer then
        return getSpecificPlayer(tonumber(playerNum) or 0)
    end
    return getPlayer and getPlayer() or nil
end

local function openDebugHub(player)
    if not Debug or type(Debug.CanUse) ~= "function"
        or Debug.CanUse(player) ~= true
    then
        return false
    end
    if not Hub or type(Hub.Open) ~= "function" then
        return false
    end
    Hub.Open()
    return true
end

function ContextMenu.OnFillWorldObjectContextMenu(playerNum, context, _, test)
    if test or not context then
        return
    end

    local player = resolvePlayer(playerNum)
    if not Debug or type(Debug.CanUse) ~= "function"
        or Debug.CanUse(player) ~= true
    then
        return
    end

    context:addOption(
        tr("ContextMenu_Psychopatz_DebugAccess",
            "[Debug] Access Psychopatz Mod Controls"),
        nil,
        function()
            openDebugHub(player)
        end
    )
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(
        ContextMenu.OnFillWorldObjectContextMenu)
end

return ContextMenu
