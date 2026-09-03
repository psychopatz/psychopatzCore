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
Options.DefaultSurfaceOpacityLift = 0.08
Options.DefaultDetailOpacityLift = 0.04
Options.DefaultTitlebarControlScale = 1.0

local Store = PsychopatzCore.Settings.Open("CommandHub", {
    fileName = "PsychopatzCore_CommandHub.txt",
    defaults = {
        opacity = 0.92,
        branch = "right",
        surfaceOpacityLift = 0.08,
        detailOpacityLift = 0.04,
        titlebarControlScale = 1.0,
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

function Options.GetSurfaceOpacityLift()
    ensureLoaded()
    return clamp(tonumber(Store:Get("surfaceOpacityLift",
        Options.DefaultSurfaceOpacityLift)) or Options.DefaultSurfaceOpacityLift,
        0, 0.25)
end

function Options.SetSurfaceOpacityLift(value, persist)
    local lift = clamp(tonumber(value) or Options.DefaultSurfaceOpacityLift,
        0, 0.25)
    Store:Set("surfaceOpacityLift", lift, persist ~= false)
    return lift
end

function Options.GetDetailOpacityLift()
    ensureLoaded()
    return clamp(tonumber(Store:Get("detailOpacityLift",
        Options.DefaultDetailOpacityLift)) or Options.DefaultDetailOpacityLift,
        0, 0.25)
end

function Options.SetDetailOpacityLift(value, persist)
    local lift = clamp(tonumber(value) or Options.DefaultDetailOpacityLift,
        0, 0.25)
    Store:Set("detailOpacityLift", lift, persist ~= false)
    return lift
end

function Options.GetTitlebarControlScale()
    ensureLoaded()
    return clamp(tonumber(Store:Get("titlebarControlScale",
        Options.DefaultTitlebarControlScale))
        or Options.DefaultTitlebarControlScale, 0.5, 1.25)
end

function Options.SetTitlebarControlScale(value, persist)
    local scale = clamp(tonumber(value) or Options.DefaultTitlebarControlScale,
        0.5, 1.25)
    Store:Set("titlebarControlScale", scale, persist ~= false)
    return scale
end

-- Short aliases keep the option easy to consume from generic toolbar code
-- while the longer name remains the persisted/public settings contract.
Options.GetToolbarScale = Options.GetTitlebarControlScale
Options.SetToolbarScale = Options.SetTitlebarControlScale

function Options.GetOpacityLift(role)
    return tostring(role or "surface"):lower() == "detail"
        and Options.GetDetailOpacityLift() or Options.GetSurfaceOpacityLift()
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

function Options.ApplySurfaceOpacity(window, role)
    if not window then return end
    local lift = Options.GetOpacityLift(role)
    local value = clamp(Options.GetOpacity() + lift, 0.1, 1)
    window.backgroundColor = window.backgroundColor or { r = 0, g = 0, b = 0, a = value }
    window.backgroundColor.a = math.min(1, value)
    window.commandHubSurfaceOpacity = window.backgroundColor.a
    return window.backgroundColor.a
end

function Options.ApplyWindowOpacity(window, opacity)
    if not window then return end
    if window.psychopatzOpacityMode == "surface" then
        local base = clamp(tonumber(opacity) or Options.GetOpacity(), 0.1, 1)
        local value = clamp(base + Options.GetSurfaceOpacityLift(), 0.1, 1)
        window.backgroundColor = window.backgroundColor
            or { r = 0, g = 0, b = 0, a = value }
        window.backgroundColor.a = value
        window.commandHubOpacity = base
        window.commandHubSurfaceOpacity = value
        return value
    end
    return Options.ApplyOpacity(window, opacity)
end

Options.targets = Options.targets or {}

function Options.RegisterTarget(id, window)
    local key = tostring(id or "")
    if key == "" or not window then return false end
    Options.targets[key] = window
    Options.ApplyWindowOpacity(window)
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
        if window then Options.ApplyWindowOpacity(window, value) end
    end
    return value
end

function Options.ApplyRegisteredToolbarScale()
    local toolbar = UI.WindowToolbar
    if toolbar and toolbar.RefreshAll then
        return toolbar.RefreshAll()
    end
    local scale = Options.GetTitlebarControlScale()
    for _, window in pairs(Options.targets) do
        if window and toolbar and toolbar.Sync then toolbar.Sync(window) end
    end
    return scale
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

function Options.GetContentOpacity(role)
    local amount = Options.GetOpacityLift(role)
    return clamp(Options.GetOpacity() + amount, 0.1, 1)
end

function Options.GetContentOpacitySignature()
    return table.concat({
        tostring(Options.GetOpacity()),
        tostring(Options.GetSurfaceOpacityLift()),
        tostring(Options.GetDetailOpacityLift()),
    }, ":")
end

function Options.ResetGeometry(window)
    if not window then return false end
    local bounds = Options.GetBounds(window)
    Options.ApplyGeometry(window, bounds.x, bounds.y, bounds.width, bounds.height)
    Options.SetOpacityPercent(Options.DefaultOpacity * 100)
    Options.SetBranch(Options.DefaultBranch)
    Options.SetTitlebarControlScale(Options.DefaultTitlebarControlScale)
    Options.ApplyWindowOpacity(window, Options.DefaultOpacity)
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
    Store:Set("opacity", Options.DefaultOpacity, false)
    Store:Set("branch", Options.DefaultBranch, false)
    Store:Set("surfaceOpacityLift", Options.DefaultSurfaceOpacityLift, false)
    Store:Set("detailOpacityLift", Options.DefaultDetailOpacityLift, true)
    Store:Set("titlebarControlScale", Options.DefaultTitlebarControlScale, true)
    return true
end

return Options
