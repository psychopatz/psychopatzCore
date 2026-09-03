-- Shared, small-footprint extension point for actions launched from the
-- vanilla ISRadioWindow. Mods register intent here; host integrations can
-- render independently ordered action stacks without replacing one another.

require "ISUI/ISButton"
require "ISUI/ISContextMenu"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioActions = PsychopatzCore.RadioActions or {}

local RadioActions = PsychopatzCore.RadioActions
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local Theme = PsychopatzCore.UI.Theme
local UI = PsychopatzCore.UI

RadioActions._byID = RadioActions._byID or {}
RadioActions._ordered = RadioActions._ordered or {}
RadioActions.PLACEMENT_SIGNAL = "psychopatz.radio.signal"
RadioActions.LEGACY_PLACEMENT_SIGNAL = "dynamic_trading.signal"

local function normalizePlacement(value)
    value = tostring(value or "")
    if value == RadioActions.LEGACY_PLACEMENT_SIGNAL then
        return RadioActions.PLACEMENT_SIGNAL
    end
    return value
end

local function log(message)
    print("[PsychopatzCore][RadioActions] " .. tostring(message))
end

local function getPlayer(window)
    local playerNum = tonumber(window and window.playerNum) or 0
    if getSpecificPlayer then
        return getSpecificPlayer(playerNum)
    end
    return nil
end

local function isUsableRadio(window)
    local data = window and window.deviceData
    if not data and window and window.device and window.device.getDeviceData then
        data = window.device:getDeviceData()
    end
    if not data or not RadioDeviceState then return false end
    return data.getIsPortable and data:getIsPortable()
        and data.getIsTwoWay and data:getIsTwoWay()
        and (not data.getIsTelevision or not data:getIsTelevision())
end

local function isOperational(window)
    local data = window and window.deviceData
    if not data and window and window.device and window.device.getDeviceData then
        data = window.device:getDeviceData()
    end
    if not data or not RadioDeviceState then return false end
    return RadioDeviceState.IsActive(data)
end

local function sortActions()
    table.sort(RadioActions._ordered, function(left, right)
        local leftOrder = tonumber(left.order) or 0
        local rightOrder = tonumber(right.order) or 0
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
end

local function callPredicate(action, name, player, window, default)
    local predicate = action and action[name]
    if type(predicate) ~= "function" then return default end
    local ok, result = pcall(predicate, player, window, action)
    if not ok then
        log("action '" .. tostring(action.id) .. "' " .. name .. " failed: " .. tostring(result))
        return false
    end
    return result ~= false
end

function RadioActions.Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string"
        or definition.id == "" or type(definition.onClick) ~= "function"
    then
        log("ignored invalid radio action registration")
        return false
    end

    local existing = RadioActions._byID[definition.id]
    if existing then
        for index = #RadioActions._ordered, 1, -1 do
            if RadioActions._ordered[index] == existing then
                table.remove(RadioActions._ordered, index)
                break
            end
        end
    end

    RadioActions._byID[definition.id] = definition
    RadioActions._ordered[#RadioActions._ordered + 1] = definition
    sortActions()
    return true
end

function RadioActions.Unregister(id)
    local definition = RadioActions._byID[id]
    if not definition then return false end
    RadioActions._byID[id] = nil
    for index = #RadioActions._ordered, 1, -1 do
        if RadioActions._ordered[index] == definition then
            table.remove(RadioActions._ordered, index)
            break
        end
    end
    return true
end

function RadioActions.List()
    local result = {}
    for index = 1, #RadioActions._ordered do
        result[index] = RadioActions._ordered[index]
    end
    return result
end

function RadioActions.HasHostRequest(field)
    field = tostring(field or "")
    if field == "" then return false end
    for _, action in ipairs(RadioActions._ordered) do
        if tostring(action.hostButton or "") == field then return true end
    end
    return false
end

function RadioActions.GetAvailable(window)
    local available = {}
    if not isUsableRadio(window) then return available end
    local player = getPlayer(window)
    for _, action in ipairs(RadioActions._ordered) do
        if callPredicate(action, "isAvailable", player, window, true) then
            available[#available + 1] = action
        end
    end
    return available
end

function RadioActions.GetAvailableForPlacement(window, placement)
    local result = {}
    placement = normalizePlacement(placement)
    for _, action in ipairs(RadioActions.GetAvailable(window)) do
        if normalizePlacement(action.placement) == placement then
            result[#result + 1] = action
        end
    end
    return result
end

local function invoke(action, window)
    if not action then return false end
    local player = getPlayer(window)
    if not callPredicate(action, "isEnabled", player, window, true) then
        return false
    end
    local ok, result = pcall(action.onClick, player, window, action)
    if not ok then
        log("action '" .. tostring(action.id) .. "' onClick failed: " .. tostring(result))
        return false
    end
    return result ~= false
end

local function styleActionButton(button)
    if not button then return end
    local definition = {
        background = "surface",
        backgroundAlpha = 0.96,
        hover = "surfaceHover",
        border = "accent",
        borderAlpha = 0.92,
        text = "text",
    }
    if UI.SetButtonTheme then
        UI.SetButtonTheme(button, definition)
    else
        button.backgroundColor = Theme.Color("surface", 0.96)
        button.backgroundColorMouseOver = Theme.Color("surfaceHover")
        button.borderColor = Theme.Color("accent", 0.92)
        button.textColor = Theme.Color("text")
    end
end

function RadioActions.BindButton(button, action, window, options)
    if not button or not action or not window then return false end
    options = type(options) == "table" and options or {}
    button.target = window
    button.onclick = function(target)
        return invoke(action, target or window)
    end
    if button.setTitle then
        button:setTitle(tostring(options.title or action.shortLabel
            or action.label or action.id))
    end
    button.enable = isOperational(window)
        and callPredicate(action, "isEnabled", getPlayer(window), window, true)
    button.psychopatzRadioActionID = action.id
    styleActionButton(button)
    return true
end

-- Some radio integrations already provide a correctly positioned service
-- button. An action can opt into that host instead of adding a second control
-- over the vanilla title bar. This also keeps older integrations working when
-- the shared action registry is present.
local function bindHostButton(window, action)
    local field = action and action.hostButton
    local button = type(field) == "string" and window and window[field] or nil
    if not button then return false end
    return RadioActions.BindButton(button, action, window)
end

local function openMenu(window, actions)
    if not ISContextMenu or not ISContextMenu.get then return false end
    local button = window.psychopatzRadioActionsButton
    local x = button and button.getAbsoluteX and button:getAbsoluteX() or getMouseX()
    local y = button and button.getAbsoluteY and button:getAbsoluteY() + button:getHeight() or getMouseY()
    local context = ISContextMenu.get(tonumber(window.playerNum) or 0, x, y)
    local player = getPlayer(window)
    for _, action in ipairs(actions) do
        local option = context:addOption(tostring(action.label or action.id), window, function(target)
            invoke(action, target)
        end)
        option.notAvailable = not isOperational(window)
            or not callPredicate(action, "isEnabled", player, window, true)
        if action.tooltip and option.toolTip then
            option.toolTip.description = tostring(action.tooltip)
        end
    end
    return true
end

function RadioActions.Attach(window)
    if not window or window.psychopatzRadioActionsButton then return end
    local button = ISButton:new(0, 0, 118, 20, "", window, function(target)
        local actions = RadioActions.GetAvailable(target)
        if #actions == 1 then
            invoke(actions[1], target)
        elseif #actions > 1 then
            openMenu(target, actions)
        end
    end)
    button:initialise()
    button:instantiate()
    styleActionButton(button)
    button:setVisible(false)
    window.psychopatzRadioActionsButton = button
    window:addChild(button)
end

function RadioActions.Refresh(window)
    RadioActions.Attach(window)
    local button = window and window.psychopatzRadioActionsButton
    if not button then return end

    local actions = RadioActions.GetAvailable(window)
    local standalone = {}
    for _, action in ipairs(actions) do
        local hasPlacement = tostring(action.placement or "") ~= ""
        if not bindHostButton(window, action)
            and not hasPlacement
            and action.hostRequired ~= true
        then
            standalone[#standalone + 1] = action
        end
    end
    if #standalone == 0 then
        button:setVisible(false)
        return
    end

    local isSingleAction = #standalone == 1
    local title = isSingleAction
        and tostring(standalone[1].shortLabel or standalone[1].label
            or standalone[1].id)
        or "Radio Services (" .. tostring(#standalone) .. ")"
    button:setTitle(title)
    button.enable = isOperational(window)
    button:setX(math.max(4, (tonumber(window.width) or button:getWidth()) - button:getWidth() - 6))
    local titleHeight = window.titleBarHeight and window:titleBarHeight() or 18
    button:setY(titleHeight + 4)
    button:setVisible(true)
    if window.bringChildToFront then window:bringChildToFront(button) end
end

return RadioActions
