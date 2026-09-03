-- Adds a reusable title-bar control for windows that can detach from their
-- magnetic owner and behave like movable on-screen widgets.

require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzWindowToolbar"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Resolver = UI.ImageResolver
local Toolbar = UI.WindowToolbar

local WidgetWindow = UI.WidgetWindow or {}
UI.WidgetWindow = WidgetWindow

WidgetWindow.ATTACHED_ICON = "media/ui/MP/mp_ui_passwordOn.png"
WidgetWindow.DETACHED_ICON = "media/ui/MP/mp_ui_passwordOff.png"

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
    if Toolbar then Toolbar.Sync(window) end
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
    if Toolbar then Toolbar.Sync(window) end
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

    local button = Toolbar and Toolbar.Add(window, {
        id = definition.id or "psychopatz-widget-toggle",
        title = "",
        image = function(target)
            return iconFor(target)
        end,
        imageSize = definition.imageSize,
        order = definition.order or 100,
        target = window,
        onclick = function(target)
            return WidgetWindow.Toggle(target)
        end,
        variant = "quiet",
    })
    if not button then return nil end

    button:setTitle("")
    button:setDisplayBackground(true)
    UI.SetButtonTheme(button, {
        background = "transparent",
        hover = "surfaceHover",
        hoverAlpha = 0.7,
        border = "transparent",
        text = "transparent",
    })
    window.psychopatzWidgetButton = button
    WidgetWindow.Sync(window)
    return button
end

return WidgetWindow
