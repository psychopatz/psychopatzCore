require "PsychopatzCore/UI/Core/PsychopatzUITheme"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout or {}
UI.Layout = Layout

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Layout.Clamp(value, minimum, maximum)
    return clamp(value, minimum, maximum)
end

function Layout.ScreenSize()
    local core = getCore and getCore() or nil
    return core and core:getScreenWidth() or 1280, core and core:getScreenHeight() or 720
end

function Layout.Scale()
    local width, height = Layout.ScreenSize()
    local metrics = Theme.metrics
    local scale = math.min(width / metrics.baselineWidth, height / metrics.baselineHeight)
    return clamp(scale, metrics.minimumScale, metrics.maximumScale)
end

function Layout.Pixels(value, scale)
    return math.max(1, math.floor((tonumber(value) or 0) * (scale or Layout.Scale()) + 0.5))
end

function Layout.ResolveWindow(spec)
    spec = spec or {}
    local screenWidth, screenHeight = Layout.ScreenSize()
    local scale = Layout.Scale()
    local margin = Layout.Pixels(spec.screenMargin or Theme.metrics.screenMargin, scale)
    local availableWidth = math.max(320, screenWidth - margin * 2)
    local availableHeight = math.max(260, screenHeight - margin * 2)
    local minimumWidth = math.min(Layout.Pixels(spec.minWidth or 520, scale), availableWidth)
    local minimumHeight = math.min(Layout.Pixels(spec.minHeight or 360, scale), availableHeight)
    local maximumWidth = math.min(Layout.Pixels(spec.maxWidth or spec.width or 1100, scale), availableWidth)
    local maximumHeight = math.min(Layout.Pixels(spec.maxHeight or spec.height or 720, scale), availableHeight)
    local width = clamp(Layout.Pixels(spec.width or 900, scale), minimumWidth, maximumWidth)
    local height = clamp(Layout.Pixels(spec.height or 620, scale), minimumHeight, maximumHeight)
    return {
        x = math.max(margin, math.floor((screenWidth - width) / 2)),
        y = math.max(margin, math.floor((screenHeight - height) / 2)),
        width = width,
        height = height,
        scale = scale,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
    }
end

function Layout.KeepOnScreen(element, margin)
    if not element then return end
    local screenWidth, screenHeight = Layout.ScreenSize()
    margin = tonumber(margin) or Layout.Pixels(Theme.metrics.screenMargin)
    local width = math.min(element:getWidth(), math.max(320, screenWidth - margin * 2))
    local height = math.min(element:getHeight(), math.max(260, screenHeight - margin * 2))
    element:setWidth(width)
    element:setHeight(height)
    element:setX(clamp(element:getX(), margin, math.max(margin, screenWidth - width - margin)))
    element:setY(clamp(element:getY(), margin, math.max(margin, screenHeight - height - margin)))
end

function Layout.SetBounds(element, x, y, width, height)
    if not element then return end
    element:setX(math.floor(x))
    element:setY(math.floor(y))
    element:setWidth(math.max(1, math.floor(width)))
    element:setHeight(math.max(1, math.floor(height)))
end

function Layout.IsCompact(width, breakpoint)
    return (tonumber(width) or 0) < (tonumber(breakpoint) or Theme.metrics.compactBreakpoint)
end

function Layout.ContentRect(window, options)
    options = options or {}
    local scale = window.uiScale or Layout.Scale()
    local padding = Layout.Pixels(options.padding or Theme.metrics.padding, scale)
    local top = Layout.Pixels(options.top or 30, scale)
    local bottom = Layout.Pixels(options.bottom or Theme.metrics.padding, scale)
    return {
        x = padding,
        y = top,
        width = math.max(1, window:getWidth() - padding * 2),
        height = math.max(1, window:getHeight() - top - bottom),
    }
end

function Layout.MeasureButton(title, options)
    options = options or {}
    local scale = options.scale or Layout.Scale()
    local font = options.font or Theme.Font(scale)
    local padding = Layout.Pixels(options.padding or 20, scale)
    local minimum = Layout.Pixels(options.minWidth or 64, scale)
    return math.max(minimum, Theme.TextWidth(font, title) + padding)
end

function Layout.Flow(controls, rect, options)
    options = options or {}
    local scale = options.scale or Layout.Scale()
    local gap = Layout.Pixels(options.gap or Theme.metrics.spacing, scale)
    local rowGap = Layout.Pixels(options.rowGap or Theme.metrics.spacing, scale)
    local height = Layout.Pixels(options.height or Theme.metrics.controlHeight, scale)
    local x = rect.x
    local y = rect.y
    local row = 1
    local widestX = rect.x + rect.width
    for index, control in ipairs(controls or {}) do
        local desiredWidth = control.psychopatzPreferredWidth
            or Layout.MeasureButton(control.getTitle and control:getTitle() or control.title or control.text or "", {
                scale = scale,
                font = options.font,
                minWidth = options.minWidth,
                padding = options.horizontalPadding,
            })
        desiredWidth = math.min(desiredWidth, rect.width)
        if x > rect.x and x + desiredWidth > widestX then
            row = row + 1
            x = rect.x
            y = y + height + rowGap
        end
        Layout.SetBounds(control, x, y, desiredWidth, height)
        x = x + desiredWidth + gap
    end
    return {
        rows = row,
        height = row * height + (row - 1) * rowGap,
        bottom = y + height,
    }
end

function Layout.Split(rect, options)
    options = options or {}
    local scale = options.scale or Layout.Scale()
    local gap = Layout.Pixels(options.gap or Theme.metrics.spacing, scale)
    if Layout.IsCompact(rect.width, Layout.Pixels(options.breakpoint or Theme.metrics.compactBreakpoint, scale)) then
        local topRatio = tonumber(options.topRatio) or 0.42
        local topHeight = math.floor((rect.height - gap) * topRatio)
        return {
            compact = true,
            first = { x = rect.x, y = rect.y, width = rect.width, height = topHeight },
            second = { x = rect.x, y = rect.y + topHeight + gap, width = rect.width, height = rect.height - topHeight - gap },
        }
    end
    local firstRatio = tonumber(options.firstRatio) or 0.4
    local firstWidth = math.floor((rect.width - gap) * firstRatio)
    return {
        compact = false,
        first = { x = rect.x, y = rect.y, width = firstWidth, height = rect.height },
        second = { x = rect.x + firstWidth + gap, y = rect.y, width = rect.width - firstWidth - gap, height = rect.height },
    }
end

function Layout.Ellipsize(value, font, maximumWidth)
    local text = tostring(value or "")
    if Theme.TextWidth(font, text) <= maximumWidth then return text end
    while #text > 1 and Theme.TextWidth(font, text .. "...") > maximumWidth do
        text = string.sub(text, 1, #text - 1)
    end
    return text .. "..."
end

return Layout
