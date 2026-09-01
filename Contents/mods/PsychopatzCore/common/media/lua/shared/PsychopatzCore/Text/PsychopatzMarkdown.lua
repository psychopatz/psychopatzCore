PsychopatzCore = PsychopatzCore or {}

-- Small, deterministic Markdown presentation layer for Core-owned UI.
--
-- This intentionally is not a full CommonMark implementation. It produces
-- safe styled runs for callers that already own their layout and rendering.
-- The original message must remain untouched so other systems can use the
-- canonical LLM text, while UI consumers can derive a presentation document.
PsychopatzCore.Markdown = PsychopatzCore.Markdown or {}

local Markdown = PsychopatzCore.Markdown
Markdown.VERSION = 1
Markdown.MAX_TEXT = 12000
Markdown.MAX_LINES = 128

local function trim(value)
    local output = tostring(value or "")
    output = string.gsub(output, "^%s+", "")
    return string.gsub(output, "%s+$", "")
end

local function isWordCharacter(value)
    return value ~= nil and value ~= ""
        and string.match(value, "[%w_]") ~= nil
end

local function appendRun(runs, value, style)
    value = tostring(value or "")
    if value == "" then return end
    style = style or "normal"
    local previous = runs[#runs]
    if previous and previous.style == style then
        previous.text = previous.text .. value
    else
        runs[#runs + 1] = { text = value, style = style }
    end
end

local function validDelimited(value, startAt, marker)
    local closeAt = string.find(value, marker, startAt, true)
    if not closeAt then return nil end
    local inner = string.sub(value, startAt, closeAt - 1)
    if string.find(inner, "\n", 1, true) then return nil end
    inner = trim(inner)
    if inner == "" then return nil end
    local after = string.sub(value, closeAt + #marker, closeAt + #marker)
    if isWordCharacter(after) then return nil end
    return inner, closeAt + #marker
end

local function parseInline(value)
    local runs = {}
    local position = 1
    local length = #value
    while position <= length do
        local character = string.sub(value, position, position)
        local nextCharacter = string.sub(value, position + 1, position + 1)
        if character == "\\" and nextCharacter ~= "" then
            appendRun(runs, nextCharacter, "normal")
            position = position + 2
        elseif character == "`" then
            local content, nextPosition = validDelimited(value, position + 1, "`")
            if content then
                appendRun(runs, content, "code")
                position = nextPosition
            else
                appendRun(runs, character, "normal")
                position = position + 1
            end
        elseif character == "!" and nextCharacter == "[" then
            local labelEnd = string.find(value, "]", position + 2, true)
            local openParen = labelEnd and string.sub(value, labelEnd + 1, labelEnd + 1)
            if labelEnd and openParen == "(" then
                local urlEnd = string.find(value, ")", labelEnd + 2, true)
                if urlEnd then
                    appendRun(runs, string.sub(value, position + 2, labelEnd - 1), "normal")
                    position = urlEnd + 1
                else
                    appendRun(runs, character, "normal")
                    position = position + 1
                end
            else
                appendRun(runs, character, "normal")
                position = position + 1
            end
        elseif character == "[" then
            local labelEnd = string.find(value, "]", position + 1, true)
            local openParen = labelEnd and string.sub(value, labelEnd + 1, labelEnd + 1)
            if labelEnd and openParen == "(" then
                local urlEnd = string.find(value, ")", labelEnd + 2, true)
                if urlEnd then
                    appendRun(runs, string.sub(value, position + 1, labelEnd - 1), "link")
                    position = urlEnd + 1
                else
                    appendRun(runs, character, "normal")
                    position = position + 1
                end
            else
                appendRun(runs, character, "normal")
                position = position + 1
            end
        elseif character == "*" or character == "_" then
            local marker = character
            if nextCharacter == marker then marker = marker .. marker end
            local canOpen = nextCharacter ~= "" and (
                not string.match(nextCharacter, "%s")
                or (marker == "*" and string.match(nextCharacter, "%s") ~= nil)
            )
            local before = string.sub(value, position - 1, position - 1)
            if marker == "_" and isWordCharacter(before) then canOpen = false end
            local content
            local nextPosition
            if canOpen then
                content, nextPosition = validDelimited(
                    value, position + #marker, marker
                )
            end
            if content then
                local style = (marker == "**" or marker == "__")
                    and "bold" or "italic"
                if marker == "*" and string.match(string.sub(value, position + 1, position + 1), "%s") then
                    style = "stage"
                end
                appendRun(runs, content, style)
                position = nextPosition
            else
                appendRun(runs, character, "normal")
                position = position + 1
            end
        else
            appendRun(runs, character, "normal")
            position = position + 1
        end
    end
    if #runs == 0 then appendRun(runs, " ", "normal") end
    return runs
end

local function parseLine(value)
    local kind = "body"
    local content = value
    local heading, headingText = string.match(content, "^%s*(#+)%s+(.+)$")
    if heading and #heading <= 6 then
        kind = "heading"
        content = headingText
    else
        local quoteText = string.match(content, "^%s*>%s?(.*)$")
        if quoteText then
            kind = "quote"
            content = "│ " .. quoteText
        else
            local listText = string.match(content, "^%s*[-+]%s+(.+)$")
            if not listText then
                local starText = string.match(content, "^%s*%*%s+(.+)$")
                if starText and not string.find(starText, "*", 1, true) then
                    listText = starText
                end
            end
            if listText then
                kind = "list"
                content = "• " .. listText
            end
        end
    end
    return { runs = parseInline(content), kind = kind }
end

function Markdown.Parse(value)
    local source = string.sub(tostring(value or ""), 1, Markdown.MAX_TEXT)
    source = string.gsub(source, "\r\n", "\n")
    source = string.gsub(source, "\r", "\n")
    local document = { version = Markdown.VERSION, lines = {} }
    local inCode = false
    local startAt = 1
    local sourceLength = #source
    while startAt <= sourceLength and #document.lines < Markdown.MAX_LINES do
        local newlineAt = string.find(source, "\n", startAt, true)
        local line
        if newlineAt then
            line = string.sub(source, startAt, newlineAt - 1)
            startAt = newlineAt + 1
        else
            line = string.sub(source, startAt)
            startAt = sourceLength + 1
        end
        if string.match(line, "^%s*```") then
            inCode = not inCode
        elseif inCode then
            document.lines[#document.lines + 1] = {
                runs = { { text = line ~= "" and line or " ", style = "code" } },
                kind = "code",
            }
        else
            document.lines[#document.lines + 1] = parseLine(line)
        end
    end
    if #document.lines == 0 then
        document.lines[1] = { runs = { { text = " ", style = "normal" } }, kind = "body" }
    end
    return document
end

function Markdown.LineText(line)
    local output = ""
    for index = 1, #((line and line.runs) or {}) do
        output = output .. tostring(line.runs[index].text or "")
    end
    return output
end

local function appendWrappedWord(line, word, style, maximumWidth, measure, output)
    local current = Markdown.LineText(line)
    local candidate = current == "" and word or (current .. " " .. word)
    if current ~= "" and measure(candidate) > maximumWidth then
        output[#output + 1] = line
        line = { runs = {}, kind = line.kind }
    elseif current ~= "" then
        appendRun(line.runs, " ", "normal")
    end
    appendRun(line.runs, word, style)
    return line
end

function Markdown.Wrap(value, maximumWidth, measure)
    local document = type(value) == "table" and value.lines and value or Markdown.Parse(value)
    maximumWidth = math.max(40, tonumber(maximumWidth) or 320)
    measure = measure or function(text) return #tostring(text or "") * 8 end
    local output = {}
    local sourceIndex
    for sourceIndex = 1, #document.lines do
        local sourceLine = document.lines[sourceIndex]
        local line = { runs = {}, kind = sourceLine.kind }
        local runIndex
        for runIndex = 1, #(sourceLine.runs or {}) do
            local run = sourceLine.runs[runIndex]
            local word
            for word in string.gmatch(tostring(run.text or ""), "%S+") do
                line = appendWrappedWord(
                    line, word, run.style, maximumWidth, measure, output
                )
            end
        end
        if #line.runs == 0 then appendRun(line.runs, " ", "normal") end
        output[#output + 1] = line
    end
    return output
end

function Markdown.ToText(value)
    local document = type(value) == "table" and value.lines and value or Markdown.Parse(value)
    local output = {}
    for index = 1, #document.lines do
        output[#output + 1] = Markdown.LineText(document.lines[index])
    end
    return table.concat(output, "\n")
end

function Markdown.ToSingleLine(value)
    local output = Markdown.ToText(value)
    output = string.gsub(output, "[\r\n]+", " ")
    output = string.gsub(output, "%s+", " ")
    return trim(output)
end

-- Conversation consumers historically look below Conversation. Keep this
-- alias so the parser is reusable without requiring UI-specific modules.
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.Conversation.Markdown = Markdown

return Markdown
