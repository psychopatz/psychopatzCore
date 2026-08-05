-- Native Build 42 radio host for placed actions. The registry owns action
-- definitions; this adapter owns only the Signal-module layout.

require "RadioCom/ISRadioWindow"
require "PsychopatzCore/UI/Radio/PsychopatzRadioActions"

local Actions = PsychopatzCore.RadioActions
local SignalHost = {}

PsychopatzCore.RadioSignalHost = SignalHost

local BUTTON_HEIGHT = 22
local HORIZONTAL_PADDING = 10
local TOP_GAP = 4
local ROW_GAP = 4

local function findSignal(window)
    for _, module in ipairs(window and window.modules or {}) do
        local element = module.element
        local panel = element and element.subpanel
        if panel and panel.sineWaveDisplay then
            return element, panel
        end
    end
    return nil, nil
end

-- Build 42 reserves a distance row for every high-tier radio and renders the
-- placeholder "distance: ~ meters" even when no distance was measured.  It is
-- not useful state, and becomes especially conspicuous beside hosted actions.
-- Keep the native row only while an actual received-signal distance exists.
local function hasMeasuredDistance(panel)
    local deviceData = panel and panel.deviceData
    local distance
    if not deviceData or panel.incomingSignal ~= true
        or not deviceData.getLastRecordedDistance
    then
        return false
    end
    distance = tonumber(deviceData:getLastRecordedDistance())
    return distance ~= nil and distance >= 0
end

local function naturalSignalHeight(panel)
    local height = tonumber(panel and panel.cacheHeight)
        or tonumber(panel and panel.height) or 0
    if panel and panel.drawDistance == true then
        height = height + (tonumber(panel.fontheight) or 0) + 2
    end
    return height
end

local function addChild(parent, child)
    if child.parent == parent then return end
    if child.parent and child.parent.removeChild then
        child.parent:removeChild(child)
    end
    parent:addChild(child)
end

local function ensureButton(window, panel, action)
    window.psychopatzSignalActionButtons =
        window.psychopatzSignalActionButtons or {}
    local id = tostring(action.id)
    local button = window.psychopatzSignalActionButtons[id]
    if not button then
        button = ISButton:new(0, 0, 100, BUTTON_HEIGHT, "", window,
            function() return false end)
        button:initialise()
        button:instantiate()
        button:setVisible(false)
        button.psychopatzSignalActionID = id
        window.psychopatzSignalActionButtons[id] = button
    end
    addChild(panel, button)
    Actions.BindButton(button, action, window, {
        title = action.signalLabel or action.label or id,
    })
    return button
end

function SignalHost.Refresh(window)
    local element, panel = findSignal(window)
    if not element or not panel then return false end

    local actions = Actions.GetAvailableForPlacement(
        window,
        Actions.PLACEMENT_SIGNAL
    )
    local active = {}
    panel.drawDistance = hasMeasuredDistance(panel)
    local baseHeight = naturalSignalHeight(panel)
    local y = baseHeight + (#actions > 0 and TOP_GAP or 0)
    local width = math.max(80,
        (tonumber(panel.width) or 100) - HORIZONTAL_PADDING * 2)

    for _, action in ipairs(actions) do
        local id = tostring(action.id)
        local button = ensureButton(window, panel, action)
        active[id] = true
        button:setX(HORIZONTAL_PADDING)
        button:setY(y)
        button:setWidth(width)
        button:setHeight(BUTTON_HEIGHT)
        button:setVisible(true)
        y = y + BUTTON_HEIGHT + ROW_GAP
    end

    for id, button in pairs(
        window.psychopatzSignalActionButtons or {}
    ) do
        if not active[id] then button:setVisible(false) end
    end

    if #actions > 0 then y = y - ROW_GAP + TOP_GAP end
    panel.psychopatzSignalActionsBottom = y
    panel:setHeight(math.max(baseHeight, y))
    if element.calculateHeights then element:calculateHeights() end
    return true
end

if ISRadioWindow
    and ISRadioWindow.psychopatzRadioSignalHostPatched ~= true
then
    local originalCreateChildren = ISRadioWindow.createChildren
    local originalPrerender = ISRadioWindow.prerender

    function ISRadioWindow:createChildren()
        originalCreateChildren(self)
        Actions.Attach(self)
        SignalHost.Refresh(self)
    end

    function ISRadioWindow:prerender()
        -- Size the native Signal module first; vanilla then flows every module
        -- and derives the radio-window height from that single source.
        SignalHost.Refresh(self)
        originalPrerender(self)
        -- Vanilla recomputes drawDistance during prerender. Enforce the
        -- measured-distance gate again after that recomputation so its
        -- placeholder cannot reappear for an idle signal panel.
        SignalHost.Refresh(self)
        Actions.Refresh(self)
    end

    ISRadioWindow.psychopatzRadioSignalHostPatched = true
end

return SignalHost
