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

function Layout.NormalizeAnchor(anchor)
    anchor = string.lower(tostring(anchor or "center"))
    anchor = string.gsub(anchor, "[%s%-]+", "_")
    if anchor == "centre" or anchor == "middle" then return "center" end
    if anchor == "upper_left" then return "top_left" end
    if anchor == "upper_right" then return "top_right" end
    if anchor == "lower_left" then return "bottom_left" end
    if anchor == "lower_right" then return "bottom_right" end
    return anchor
end

function Layout.ResolveAnchor(anchor, width, height, options)
    options = options or {}
    local defaultWidth, defaultHeight = Layout.ScreenSize()
    local screenWidth = tonumber(options.screenWidth) or defaultWidth
    local screenHeight = tonumber(options.screenHeight) or defaultHeight
    local margin = tonumber(options.margin) or Layout.Pixels(Theme.metrics.screenMargin)
    local offsetX = tonumber(options.offsetX) or 0
    local offsetY = tonumber(options.offsetY) or 0
    local centerX = math.floor((screenWidth - width) / 2)
    local centerY = math.floor((screenHeight - height) / 2)
    local left = margin
    local right = screenWidth - width - margin
    local top = margin
    local bottom = screenHeight - height - margin
    anchor = Layout.NormalizeAnchor(anchor)

    local x = centerX
    local y = centerY
    if anchor == "top" then
        y = top
    elseif anchor == "bottom" then
        y = bottom
    elseif anchor == "left" or anchor == "center_left" then
        x = left
    elseif anchor == "right" or anchor == "center_right" then
        x = right
    elseif anchor == "top_left" or anchor == "left_top" then
        x, y = left, top
    elseif anchor == "top_right" or anchor == "right_top" then
        x, y = right, top
    elseif anchor == "bottom_left" or anchor == "left_bottom" then
        x, y = left, bottom
    elseif anchor == "bottom_right" or anchor == "right_bottom" then
        x, y = right, bottom
    end
    return math.floor(x + offsetX), math.floor(y + offsetY)
end

function Layout.PlaceAtAnchor(element, anchor, options)
    if not element then return nil end
    options = options or {}
    local x, y = Layout.ResolveAnchor(anchor, element:getWidth(), element:getHeight(), options)
    element:setX(x)
    element:setY(y)
    if options.keepOnScreen ~= false then Layout.KeepOnScreen(element, options.margin) end
    return { x = element:getX(), y = element:getY() }
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
    local x, y = Layout.ResolveAnchor(spec.anchor, width, height, {
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        margin = margin,
        offsetX = spec.offsetX,
        offsetY = spec.offsetY,
    })
    return {
        x = clamp(x, margin, math.max(margin, screenWidth - width - margin)),
        y = clamp(y, margin, math.max(margin, screenHeight - height - margin)),
        width = width,
        height = height,
        scale = scale,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        margin = margin,
        minWidth = minimumWidth,
        minHeight = minimumHeight,
        maxWidth = maximumWidth,
        maxHeight = maximumHeight,
    }
end

function Layout.ResolveSavedWindow(state, spec)
    if type(state) ~= "table" then return nil end
    local bounds = Layout.ResolveWindow(spec)
    local width = clamp(tonumber(state.w or state.width) or bounds.width, bounds.minWidth, bounds.maxWidth)
    local height = clamp(tonumber(state.h or state.height) or bounds.height, bounds.minHeight, bounds.maxHeight)
    local x = clamp(tonumber(state.x) or bounds.x, bounds.margin,
        math.max(bounds.margin, bounds.screenWidth - width - bounds.margin))
    local y = clamp(tonumber(state.y) or bounds.y, bounds.margin,
        math.max(bounds.margin, bounds.screenHeight - height - bounds.margin))
    return {
        x = math.floor(x),
        y = math.floor(y),
        width = math.floor(width),
        height = math.floor(height),
        scale = bounds.scale,
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

-- Native PZ scrolling controls create their scrollbars during instantiate().
-- The scrollbar does not reliably follow later setWidth/setHeight calls, and
-- ISScrollingListBox uses its stale x-position as a stencil boundary. Keep the
-- projection synchronized centrally so responsive windows cannot clip every
-- row or leave a tiny scrollbar behind after a resize.
function Layout.SyncNativeScrollbars(element)
    if not element then return end
    local vertical = element.vscroll
    if vertical then
        local width = vertical.getWidth and vertical:getWidth()
            or vertical.width or 13
        vertical:setX(math.max(0, element:getWidth() - width))
        vertical:setY(0)
        vertical:setHeight(element:getHeight())
    end
    local horizontal = element.hscroll
    if horizontal then
        local height = horizontal.getHeight and horizontal:getHeight()
            or horizontal.height or 13
        horizontal:setX(0)
        horizontal:setY(math.max(0, element:getHeight() - height))
        horizontal:setWidth(element:getWidth())
    end
    -- setWidth/setHeight do not refresh the native thumb position.  Without
    -- this pass, a list populated before its responsive bounds are applied
    -- can keep the scrollbar's initial 1px geometry until the next resize.
    if element.updateScrollbars and element.javaObject then
        element:updateScrollbars()
    end
end

function Layout.SetBounds(element, x, y, width, height)
    if not element then return end
    element:setX(math.floor(x))
    element:setY(math.floor(y))
    element:setWidth(math.max(1, math.floor(width)))
    element:setHeight(math.max(1, math.floor(height)))
    Layout.SyncNativeScrollbars(element)
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

local function utf8Prefix(value, byteCount)
    byteCount = math.min(math.max(0, byteCount or 0), #value)
    if byteCount == #value then return value end

    -- Lua 5.1/Kahlua has no guaranteed utf8 library. Keep the cut at a
    -- codepoint boundary so localized labels never render a partial byte
    -- sequence when they are shortened.
    local index = byteCount
    while index > 0 do
        local byte = string.byte(value, index)
        if byte < 0x80 then return string.sub(value, 1, byteCount) end
        if byte >= 0xC0 then
            local expected = byte < 0xE0 and 2
                or byte < 0xF0 and 3 or byte < 0xF8 and 4 or 1
            if index + expected - 1 <= byteCount then
                return string.sub(value, 1, byteCount)
            end
            return string.sub(value, 1, index - 1)
        end
        index = index - 1
    end
    return ""
end

function Layout.Ellipsize(value, font, maximumWidth)
    local text = tostring(value or "")
    local width = tonumber(maximumWidth) or 0
    if width <= 0 then return "" end
    if Theme.TextWidth(font, text) <= width then return text end

    local suffix = "..."
    if Theme.TextWidth(font, suffix) > width then return "" end

    -- Width checks are monotonic for a prefix, so binary search avoids a
    -- measure call for every character in long item names and descriptions.
    local low = 0
    local high = #text
    while low < high do
        local middle = math.floor((low + high + 1) / 2)
        local prefix = utf8Prefix(text, middle)
        if Theme.TextWidth(font, prefix .. suffix) <= width then
            low = middle
        else
            high = middle - 1
        end
    end
    return utf8Prefix(text, low) .. suffix
end

return Layout
