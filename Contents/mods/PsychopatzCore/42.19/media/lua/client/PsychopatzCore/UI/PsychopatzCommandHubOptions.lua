-- Shared appearance and geometry options for all command-hub consumers.

require "PsychopatzCore/Settings/PsychopatzSettings"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Options = UI.CommandHubOptions or {}
UI.CommandHubOptions = Options
local Layout = UI.Layout

Options.DefaultOpacity = 0.92
Options.DefaultBranch = "right"
Options.ContentOpacityLift = 0.08

local Store = PsychopatzCore.Settings.Open("CommandHub", {
    fileName = "PsychopatzCore_CommandHub.txt",
    defaults = {
        opacity = 0.92,
        branch = "right",
        contentOpacityLift = 0.08,
    },
})

local function ensureLoaded()
    if Store.loaded then return end
    Store:Load()
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function Options.GetOpacity()
    ensureLoaded()
    return clamp(tonumber(Store:Get("opacity", Options.DefaultOpacity))
        or Options.DefaultOpacity, 0.1, 1)
end

function Options.GetOpacityPercent()
    return math.floor(Options.GetOpacity() * 100 + 0.5)
end

function Options.SetOpacity(value, persist)
    local opacity = clamp(tonumber(value) or Options.DefaultOpacity, 0.1, 1)
    Store:Set("opacity", opacity, persist ~= false)
    return opacity
end

function Options.SetOpacityPercent(value, persist)
    return Options.SetOpacity((tonumber(value) or Options.DefaultOpacity * 100)
        / 100, persist)
end

function Options.GetBranch()
    ensureLoaded()
    local branch = tostring(Store:Get("branch", Options.DefaultBranch)
        or Options.DefaultBranch):lower()
    return branch == "left" and "left" or "right"
end

function Options.SetBranch(value, persist)
    local branch = tostring(value or "right"):lower() == "left" and "left" or "right"
    Store:Set("branch", branch, persist ~= false)
    return branch
end

function Options.GetContentOpacityLift()
    ensureLoaded()
    return clamp(tonumber(Store:Get("contentOpacityLift",
        Options.ContentOpacityLift)) or Options.ContentOpacityLift, 0, 0.25)
end

function Options.SetContentOpacityLift(value, persist)
    local lift = clamp(tonumber(value) or 0.08, 0, 0.25)
    Store:Set("contentOpacityLift", lift, persist ~= false)
    return lift
end

function Options.ApplyOpacity(window, opacity)
    if not window then return end
    local value = clamp(tonumber(opacity) or Options.GetOpacity(), 0.1, 1)
    window.backgroundColor = window.backgroundColor or { r = 0, g = 0, b = 0, a = value }
    window.backgroundColor.a = value
    if window.borderColor then window.borderColor.a = math.min(1, value + 0.2) end
    window.commandHubOpacity = value
    return value
end

function Options.ApplySurfaceOpacity(window, opacity)
    if not window then return end
    local lift = tonumber(opacity)
    if lift == nil then lift = Options.GetContentOpacityLift() end
    local value = clamp(Options.GetOpacity() + lift, 0.1, 1)
    window.backgroundColor = window.backgroundColor or { r = 0, g = 0, b = 0, a = value }
    window.backgroundColor.a = math.min(1, value)
    window.commandHubSurfaceOpacity = window.backgroundColor.a
    return window.backgroundColor.a
end

Options.targets = Options.targets or {}

function Options.RegisterTarget(id, window)
    local key = tostring(id or "")
    if key == "" or not window then return false end
    Options.targets[key] = window
    Options.ApplyOpacity(window)
    return true
end

function Options.UnregisterTarget(id)
    local key = tostring(id or "")
    if Options.targets[key] == nil then return false end
    Options.targets[key] = nil
    return true
end

function Options.ApplyRegisteredOpacity(opacity)
    local value = tonumber(opacity) or Options.GetOpacity()
    for _, window in pairs(Options.targets) do
        if window then Options.ApplyOpacity(window, value) end
    end
    return value
end

function Options.GetBounds(window)
    if not window then return nil end
    local spec = window.responsiveSpec or {
        width = 320, height = 390, minWidth = 260, minHeight = 230,
        maxWidth = 520, maxHeight = 820,
    }
    return Layout.ResolveWindow(spec)
end

function Options.ClampGeometry(window, x, y, width, height)
    local bounds = Options.GetBounds(window)
    local screenWidth, screenHeight = Layout.ScreenSize()
    local minimumWidth = tonumber(bounds.minWidth) or 1
    local maximumWidth = tonumber(bounds.maxWidth) or screenWidth
    local minimumHeight = tonumber(bounds.minHeight) or 1
    local maximumHeight = tonumber(bounds.maxHeight) or screenHeight
    local resolvedWidth = math.max(minimumWidth, math.min(maximumWidth,
        math.floor(tonumber(width) or bounds.width)))
    local resolvedHeight = math.max(minimumHeight, math.min(maximumHeight,
        math.floor(tonumber(height) or bounds.height)))
    local resolvedX = math.max(0, math.min(screenWidth - resolvedWidth,
        math.floor(tonumber(x) or bounds.x)))
    local resolvedY = math.max(0, math.min(screenHeight - resolvedHeight,
        math.floor(tonumber(y) or bounds.y)))
    return resolvedX, resolvedY, resolvedWidth, resolvedHeight
end

function Options.ApplyGeometry(window, values, y, width, height)
    if not window then return false end
    local x
    if type(values) == "table" then
        x, y, width, height = values.x, values.y, values.width, values.height
    else
        x = values
    end
    local resolvedX, resolvedY, resolvedWidth, resolvedHeight =
        Options.ClampGeometry(window, x, y, width, height)
    window:setX(resolvedX)
    window:setY(resolvedY)
    window:setWidth(resolvedWidth)
    window:setHeight(resolvedHeight)
    if window.requestResponsiveLayout then window:requestResponsiveLayout(true) end
    if window.fitToContent then window:fitToContent(false) end
    if window.saveGeometry then window:saveGeometry(true) end
    return true
end

function Options.GetContentOpacity(lift)
    local amount = tonumber(lift)
    if amount == nil then amount = Options.GetContentOpacityLift() end
    return clamp(Options.GetOpacity() + amount, 0.1, 1)
end

function Options.ResetGeometry(window)
    if not window then return false end
    local bounds = Options.GetBounds(window)
    Options.ApplyGeometry(window, bounds.x, bounds.y, bounds.width, bounds.height)
    Options.SetOpacityPercent(Options.DefaultOpacity * 100)
    Options.SetBranch(Options.DefaultBranch)
    Options.ApplyOpacity(window, Options.DefaultOpacity)
    return true
end

-- Deprecated table-form geometry helper retained below only for source-level
-- compatibility with older consumers.
function Options.ApplyGeometryTable(window, values)
    return Options.ApplyGeometry(window, values)
end

function Options.PlaceAttached(window, owner, gap)
    if not window or not owner then return false end
    if window.psychopatzWidgetDetached == true then return false end
    local spacing = tonumber(gap) or 4
    local ownerX = owner:getX()
    local ownerY = owner:getY()
    local ownerWidth = owner:getWidth()
    local width = window:getWidth()
    local x = Options.GetBranch() == "left"
        and ownerX - width - spacing
        or ownerX + ownerWidth + spacing
    window:setX(x)
    window:setY(ownerY)
    if window.requestResponsiveLayout then window:requestResponsiveLayout(true) end
    if window.saveGeometry then window:saveGeometry(false) end
    return true
end

function Options.Reset()
    Store:Set("opacity", 0.92, false)
    Store:Set("branch", "right", false)
    Store:Set("contentOpacityLift", 0.08, true)
    return true
end

return Options
