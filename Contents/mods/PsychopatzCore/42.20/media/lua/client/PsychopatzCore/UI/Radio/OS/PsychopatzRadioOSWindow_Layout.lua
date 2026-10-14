-- Measured LCD typography and responsive row geometry.
-- Keep layout math out of the renderer so every app and hit-test shares the
-- same clipped, resolution-aware metrics.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Window = OS.Window

local function safeMeasure(method, font, value)
    if not getTextManager then return nil end
    local manager = getTextManager()
    if not manager or type(manager[method]) ~= "function" then return nil end
    local ok, result = pcall(manager[method], manager, font, tostring(value or ""))
    return ok and tonumber(result) or nil
end

function Window:screenFont()
    local scale = tonumber(self.scale) or 1
    if scale < 1.25 and UIFont and UIFont.Tiny then
        return UIFont.Tiny
    end
    return (UIFont and UIFont.Small) or self._font
end

function Window:fitText(value, width, maxChars)
    value = tostring(value or "")
    local available = math.max(1, tonumber(width) or 1)
    local font = self:screenFont()
    local fallbackCharWidth = safeMeasure("MeasureStringX", font, "M")
        or 6
    fallbackCharWidth = math.max(1, tonumber(fallbackCharWidth) or 6)
    local measured = safeMeasure("MeasureStringX", font, value)
    if measured and measured > available then
        local suffix = "..."
        local low, high = 0, #value
        while low < high do
            local middle = math.ceil((low + high) / 2)
            local candidate = string.sub(value, 1, middle) .. suffix
            local candidateWidth = safeMeasure("MeasureStringX", font,
                candidate) or (#candidate * fallbackCharWidth)
            if candidateWidth <= available then
                low = middle
            else
                high = middle - 1
            end
        end
        return low > 0 and string.sub(value, 1, low) .. suffix or suffix
    end
    local fallbackChars = math.max(1, math.floor(tonumber(maxChars)
        or available / fallbackCharWidth))
    if not measured and #value > fallbackChars then
        return string.sub(value, 1, math.max(1, fallbackChars - 3)) .. "..."
    end
    return value
end

function Window:screenMetrics()
    local screen = self:screenRect()
    local scale = tonumber(self.scale) or 1
    local font = self:screenFont()
    local fontHeight = safeMeasure("MeasureStringY", font, "Ag")
        or (font == (UIFont and UIFont.Tiny) and 10 or 14)
    local padding = math.max(2, math.floor(3 * scale))
    local lineHeight = math.max(fontHeight + math.max(1, math.floor(scale)),
        math.floor(10 * scale))
    local lineCount = math.max(1, math.floor((screen.h - padding * 2)
        / math.max(1, lineHeight)))
    return {
        screen = screen,
        scale = scale,
        font = font,
        fontHeight = fontHeight,
        padding = padding,
        lineHeight = lineHeight,
        lineCount = lineCount,
        x = screen.x + padding,
        width = math.max(1, screen.w - padding * 2),
    }
end

function Window:headerLayout(subtitle, options)
    options = options or {}
    local metrics = self:screenMetrics()
    local screen = metrics.screen
    local lines = 1
    if subtitle and options.showSubtitle ~= false and metrics.lineCount >= 3 then
        lines = 2
    end
    return {
        contentY = screen.y + metrics.padding + lines * metrics.lineHeight,
        metrics = metrics,
        lines = lines,
    }
end

function Window:screenListLayout(itemCount, preferredRows, selectedIndex, header)
    local metrics = self:screenMetrics()
    header = header or self._headerLayout
    local startY = header and header.contentY
        or metrics.screen.y + metrics.padding
    local gap = math.max(1, math.floor(metrics.scale))
    local rowHeight = metrics.lineHeight + gap
    local available = metrics.screen.y + metrics.screen.h
        - metrics.padding - startY
    local maxRows = math.max(1, math.floor((available + gap) / rowHeight))
    local targetRows = preferredRows and math.min(
        math.max(1, tonumber(preferredRows) or 1), maxRows) or maxRows
    local visible = math.min(math.max(0, tonumber(itemCount) or 0), targetRows)
    local selected = math.max(1, tonumber(selectedIndex) or 1)
    local first = visible > 0
        and (math.floor((selected - 1) / visible) * visible + 1) or 1
    return {
        first = first,
        visible = visible,
        rowHeight = rowHeight,
        x = metrics.screen.x + metrics.padding,
        width = math.max(1, metrics.screen.w - metrics.padding * 2),
        y = startY,
        metrics = metrics,
    }
end

function Window:screenRowRect(layout, offset)
    if not layout then return nil end
    local row = tonumber(offset) or 0
    return {
        x = layout.x,
        y = layout.y + row * layout.rowHeight,
        w = layout.width,
        h = math.max(1, layout.rowHeight - math.max(1,
            math.floor(layout.metrics.scale))),
    }
end

return Window
