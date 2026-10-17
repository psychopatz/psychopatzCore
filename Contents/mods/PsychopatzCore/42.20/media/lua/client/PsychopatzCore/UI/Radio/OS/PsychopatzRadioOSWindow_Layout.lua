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

function Window:textWidth(value)
    value = tostring(value or "")
    local font = self:screenFont()
    local measured = safeMeasure("MeasureStringX", font, value)
    if measured then return math.max(1, measured) end
    return math.max(1, #value * 6)
end

function Window:ellipsizeText(value, width)
    value = tostring(value or "")
    width = math.max(1, tonumber(width) or 1)
    if self:textWidth(value) <= width then return value end
    local suffix = "..."
    if self:textWidth(suffix) > width then
        for length = #value, 1, -1 do
            local candidate = string.sub(value, 1, length)
            if self:textWidth(candidate) <= width then return candidate end
        end
        return ""
    end
    for length = #value, 0, -1 do
        local candidate = string.sub(value, 1, length) .. suffix
        if self:textWidth(candidate) <= width then return candidate end
    end
    return suffix
end

function Window:wrapText(value, width, maxLines)
    value = tostring(value or "")
    width = math.max(1, tonumber(width) or 1)
    maxLines = math.max(1, math.floor(tonumber(maxLines) or 1))
    if value == "" then return { "" } end

    local lines = {}
    local current = ""
    local truncated = false
    local function appendLine(line)
        if line == "" then return end
        lines[#lines + 1] = line
    end
    local function fitWord(word)
        if self:textWidth(word) <= width then return { word } end
        local chunks = {}
        local chunk = ""
        for index = 1, #word do
            local candidate = chunk .. string.sub(word, index, index)
            if chunk ~= "" and self:textWidth(candidate) > width then
                chunks[#chunks + 1] = chunk
                chunk = string.sub(word, index, index)
            else
                chunk = candidate
            end
        end
        if chunk ~= "" then chunks[#chunks + 1] = chunk end
        return chunks
    end

    for word in string.gmatch(value, "%S+") do
        local chunks = fitWord(word)
        for _, chunk in ipairs(chunks) do
            local candidate = current == "" and chunk
                or current .. " " .. chunk
            if current ~= "" and self:textWidth(candidate) > width then
                appendLine(current)
                current = chunk
            else
                current = candidate
            end
            if #lines >= maxLines then
                truncated = true
                break
            end
        end
        if truncated then break end
    end
    if not truncated then appendLine(current) end
    if #lines == 0 then lines[1] = "" end
    if #lines > maxLines then
        while #lines > maxLines do table.remove(lines) end
        truncated = true
    end
    if truncated then
        lines[maxLines] = self:ellipsizeText(lines[maxLines], width)
    end
    return lines
end

function Window:fitText(value, width, maxChars)
    local lines = self:wrapText(value, width, 1)
    local result = lines[1] or ""
    if maxChars and #result > tonumber(maxChars) then
        result = string.sub(result, 1, math.max(1, tonumber(maxChars) - 3))
            .. "..."
    end
    return result
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
        local subtitleLines = self:wrapText(subtitle, metrics.width,
            metrics.lineCount >= 4 and 2 or 1)
        lines = 1 + math.max(1, #subtitleLines)
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
