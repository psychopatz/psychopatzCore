-- Adds a reusable title-bar control for windows that can detach from their
-- magnetic owner and behave like movable on-screen widgets.

require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Resolver = UI.ImageResolver

local WidgetWindow = UI.WidgetWindow or {}
UI.WidgetWindow = WidgetWindow

WidgetWindow.ATTACHED_ICON = "media/ui/MP/mp_ui_star_outline.png"
WidgetWindow.DETACHED_ICON = "media/ui/MP/mp_ui_star.png"

local function getValue(target, methodName, fallback)
    if not target then return fallback end
    local method = target[methodName]
    if type(method) == "function" then
        local ok, value = pcall(method, target)
        if ok and value ~= nil then return value end
    end
    return target[string.lower(string.sub(methodName, 4))] or fallback
end

local function iconFor(window)
    return window.psychopatzWidgetDetached
        and WidgetWindow.DETACHED_ICON or WidgetWindow.ATTACHED_ICON
end

local function syncTooltip(window)
    local button = window.psychopatzWidgetButton
    if not button then return end
    if window.psychopatzWidgetDetached then
        local value = getText and getText("UI_PsychopatzCore_Widget_Attach")
            or nil
        button.tooltip = value and value ~= ""
            and value ~= "UI_PsychopatzCore_Widget_Attach"
            and value or "Attach to owner"
    else
        local value = getText and getText("UI_PsychopatzCore_Widget_Detach")
            or nil
        button.tooltip = value and value ~= ""
            and value ~= "UI_PsychopatzCore_Widget_Detach"
            and value or "Detach as widget"
    end
end

local function syncIcon(window)
    local button = window.psychopatzWidgetButton
    if not button or not button.setImage or not Resolver then return end
    local texture = Resolver.Resolve(iconFor(window))
    if texture then button:setImage(texture) end
    syncTooltip(window)
end

local function syncToolbar(window)
    local button = window.psychopatzWidgetButton
    if not button then return end

    local native = window.psychopatzTitlebarPinButton or window.pinButton
    local titleHeight = getValue(window, "titleBarHeight", 18)
    local nativeWidth = getValue(native, "getWidth", titleHeight - 2)
    local nativeHeight = getValue(native, "getHeight", titleHeight - 2)
    local size = math.max(1, math.floor(math.min(nativeWidth, nativeHeight)))
    local nativeX = getValue(native, "getX", getValue(window, "getWidth", 1) - size - 1)
    local nativeY = getValue(native, "getY", 1)

    button.anchorLeft = false
    button.anchorRight = true
    button.anchorTop = true
    button.anchorBottom = false
    button:setWidth(size)
    button:setHeight(size)
    button:setX(math.floor(nativeX - size - 1))
    button:setY(math.floor(nativeY))
    button:setVisible(true)
    button:bringToTop()
end

function WidgetWindow.IsDetached(window)
    return window ~= nil and window.psychopatzWidgetEnabled == true
        and window.psychopatzWidgetDetached == true
end

function WidgetWindow.SetDetached(window, detached)
    if not window or window.psychopatzWidgetEnabled ~= true then
        return false
    end
    local value = detached == true
    local changed = window.psychopatzWidgetDetached ~= value
    window.psychopatzWidgetDetached = value
    syncIcon(window)
    syncToolbar(window)
    if changed then
        if window.saveGeometry then window:saveGeometry(true) end
        if window.psychopatzWidgetOnChanged then
            window.psychopatzWidgetOnChanged(window, value)
        end
    end
    return value
end

function WidgetWindow.Toggle(window)
    if not window then return false end
    return WidgetWindow.SetDetached(window, not WidgetWindow.IsDetached(window))
end

function WidgetWindow.Sync(window)
    if not window or window.psychopatzWidgetEnabled ~= true then return false end
    syncIcon(window)
    syncToolbar(window)
    return true
end

function WidgetWindow.Install(window, definition)
    if not window then return nil end
    if window.psychopatzWidgetButton then
        WidgetWindow.Sync(window)
        return window.psychopatzWidgetButton
    end

    definition = definition or {}
    window.psychopatzWidgetEnabled = true
    window.psychopatzWidgetDetached = window.psychopatzWidgetDetached == true
    window.psychopatzWidgetOnChanged = definition.onDetachedChanged

    local button = UI.CreateButton(window, {
        id = definition.id or "psychopatz-widget-toggle",
        title = "",
        target = window,
        onclick = function(target)
            return WidgetWindow.Toggle(target)
        end,
        variant = "quiet",
    })
    if not button then return nil end

    button:setTitle("")
    button:setDisplayBackground(true)
    button.backgroundColor = Theme.Color("transparent")
    button.backgroundColorMouseOver = Theme.Color("surfaceHover", 0.7)
    button.borderColor = Theme.Color("transparent")
    button.textColor = Theme.Color("transparent")
    if button.forceImageSize then
        local titleHeight = getValue(window, "titleBarHeight", 18)
        local size = math.max(1, math.floor(titleHeight - 4))
        button:forceImageSize(size, size)
    end
    window.psychopatzWidgetButton = button
    WidgetWindow.Sync(window)
    return button
end

return WidgetWindow
