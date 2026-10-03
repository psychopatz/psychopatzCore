local Core = PsychopatzCore
local Keybinds = require "PsychopatzCore/Input/PsychopatzKeybinds"
local Translation = Core.Translation

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local function getOpenDebugWindow()
    local window = PsychopatzDebugWindow.instance
    if not window then return nil end

    if window.getIsVisible and not window:getIsVisible() then
        if PsychopatzDebugWindow.instance == window then
            PsychopatzDebugWindow.instance = nil
        end
        return nil
    end

    return window
end

local function openDebugWindow()
    local existing = getOpenDebugWindow()
    if existing then
        existing:setVisible(true)
        existing:bringToTop()
        return existing
    end

    local player = getPlayer()
    if not Core.IsOwner(player) then return end

    local width, height = 250, 100
    local window = PsychopatzDebugWindow:new(
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2),
        width, height, {
            persistenceNamespace = "Debug",
            persistenceKey = "AdminControl",
            resizable = false,
            bottomResize = false,
            responsiveSpec = {
                width = width, height = height,
                minWidth = width, minHeight = height,
                maxWidth = width, maxHeight = height,
            },
        }
    )
    window:initialise()
    PsychopatzDebugWindow.instance = window
    window:addToUIManager()
    if not window.psychopatzGeometryRestored then
        window:setX(math.floor((getCore():getScreenWidth()
            - window:getWidth()) / 2))
        window:setY(math.floor((getCore():getScreenHeight()
            - window:getHeight()) / 2))
    end
    if window.itemEntry then window.itemEntry:selectAll() end
    return window
end

local function onDebugTap()
    local player = getPlayer()
    if not Core.IsOwner(player) then return end

    local existing = getOpenDebugWindow()
    if existing then
        existing:onExecute()
    end
end

local function onDebugLongPress()
    local player = getPlayer()
    if not Core.IsOwner(player) then return end

    if not getOpenDebugWindow() then
        openDebugWindow()
    end
end

Keybinds.RegisterTapLongPress({
    id = "PsychopatzCore.DebugControlsNumpad0",
    label = tr(
        "UI_PsychopatzCore_DebugControlsKey",
        "Open Psychopatz Debug Controls (Numpad 0)"),
    tooltip = tr(
        "UI_PsychopatzCore_DebugControlsTooltip",
        "Hold Numpad 0 for 600 ms to open the controls; press and release it while open to execute the current command set."),
    exposeInOptions = false,
    defaultKey = Keyboard and Keyboard.KEY_NUMPAD0 or 82,
    longPressMs = 600,
    isEnabled = function()
        return Core.IsOwner(getPlayer and getPlayer() or nil)
    end,
    onTap = onDebugTap,
    onLongPress = onDebugLongPress,
})

local nightVisionLight = nil
local updateTick = 0
_G.PsychopatzNightVisionActive = _G.PsychopatzNightVisionActive or false

local function updateNightVision()
    local player = getPlayer()
    if not player then return end

    if _G.PsychopatzNightVisionActive then
        updateTick = updateTick + 1
        if not nightVisionLight or updateTick % 300 == 0 then
            if nightVisionLight then getCell():removeLamppost(nightVisionLight) end
            nightVisionLight = IsoLightSource.new(
                math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()),
                1.0, 1.0, 1.0, 20
            )
            getCell():addLamppost(nightVisionLight)
        else
            nightVisionLight:setX(math.floor(player:getX()))
            nightVisionLight:setY(math.floor(player:getY()))
            nightVisionLight:setZ(math.floor(player:getZ()))
        end
    elseif nightVisionLight then
        getCell():removeLamppost(nightVisionLight)
        nightVisionLight = nil
    end
end

Events.OnTick.Add(updateNightVision)

return Core
