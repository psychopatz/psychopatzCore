require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTyping"
require "PsychopatzCore/Text/PsychopatzMarkdown"

PsychopatzConversationChat = PsychopatzConversationPart:derive(
    "PsychopatzConversationChat"
)

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local Typing = Conversation.Typing
local Markdown = PsychopatzCore.Markdown
local DebugTrace = PsychopatzCore.DebugTrace

local function traceEnabled()
    return DebugTrace and DebugTrace.IsEnabled
        and DebugTrace.IsEnabled() == true
end

local function traceTypingRender(part, layout, x, y, visible, contentAlpha, reason)
    if not traceEnabled() then return end
    local headerHeight = part.headerHeight or 24
    local clipTop = headerHeight + 2
    local clipBottom = part.height - 3
    local signature = table.concat({
        tostring(visible == true),
        tostring(math.floor((tonumber(contentAlpha) or 0) * 1000 + 0.5)),
        tostring(math.floor((tonumber(part.reveal) or 0) * 1000 + 0.5)),
        tostring(math.floor(tonumber(y) or -1)),
        tostring(layout and layout.height or -1),
        tostring(reason or "layout"),
    }, ":")
    if part.typingRenderSignature == signature then return end
    part.typingRenderSignature = signature
    DebugTrace.Record({
        source = "PsychopatzCore",
        event = "conversation.typing_render",
        data = {
            speaker = part.typingSpeaker,
            visible = visible == true,
            contentAlpha = contentAlpha,
            reveal = part.reveal,
            x = x,
            y = y,
            height = layout and layout.height or nil,
            width = layout and layout.width or nil,
            clipTop = clipTop,
            clipBottom = clipBottom,
            reason = reason,
        },
    })
end

local function fontHeight()
    if getTextManager then
        return getTextManager():getFontHeight(UIFont.Small)
    end
    return 16
end

local function textWidth(value)
    if getTextManager then
        return getTextManager():MeasureStringX(UIFont.Small, value)
    end
    return #tostring(value or "") * 8
end

local function wrap(value, maximumWidth)
    return Markdown.Wrap(value, maximumWidth, textWidth)
end

local function drawFormattedLine(panel, line, x, y, baseColor, accent, alpha, kind)
    if type(line) ~= "table" then
        panel:drawText(tostring(line or ""), x, y,
            baseColor.r, baseColor.g, baseColor.b, alpha, UIFont.Small)
        return
    end
    local cursor = x
    local index
    for index = 1, #(line.runs or {}) do
        local run = line.runs[index]
        local style = run.style or "normal"
        local color = baseColor
        if style == "stage" then
            color = { r = 0.68, g = 0.76, b = 0.71 }
        elseif style == "italic" then
            -- PZ has no portable italic UIFont; keep emphasis visibly
            -- distinct while retaining the standard font for compatibility.
            color = { r = 0.86, g = 0.91, b = 0.88 }
        elseif style == "link" then
            color = { r = 0.30, g = 0.82, b = 0.96 }
        elseif style == "code" then
            color = { r = 0.92, g = 0.78, b = 0.48 }
        elseif kind == "heading" then
            color = accent
        end
        panel:drawText(run.text, cursor, y,
            color.r, color.g, color.b, alpha, UIFont.Small)
        if style == "bold" or kind == "heading" then
            -- PZ's standard UIFont.Small has no portable bold variant. A
            -- one-pixel duplicate gives a stable, inexpensive bold face.
            panel:drawText(run.text, cursor + 1, y,
                color.r, color.g, color.b, alpha, UIFont.Small)
        end
        cursor = cursor + textWidth(run.text)
    end
end

local Internal = {
    Text = Text,
    Typing = Typing,
    DebugTrace = DebugTrace,
    traceEnabled = traceEnabled,
    traceTypingRender = traceTypingRender,
    fontHeight = fontHeight,
    wrap = wrap,
    drawFormattedLine = drawFormattedLine,
}
PsychopatzConversationChat.Internal = Internal

function PsychopatzConversationChat:render()
    Internal.render(self)
end

function PsychopatzConversationChat:new(x, y, width, height, options)
    options = options or {}
    options.partID = "history"
    options.minimumWidth = options.minimumWidth or 260
    options.minimumHeight = options.minimumHeight or 160
    options.title = options.title or {
        key = "UI_PsychopatzConversation_History",
        fallback = "CONVERSATION LOG",
    }
    local o = PsychopatzConversationPart.new(self, x, y, width, height, options)
    o.messages = {}
    o.messageLayout = {}
    o.scrollOffset = 0
    o.layoutDirty = true
    return o
end

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat_Layout"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat_Renderer"

return PsychopatzConversationChat
