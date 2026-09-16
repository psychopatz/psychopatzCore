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

function PsychopatzConversationChat:setMessages(messages)
    self.messages = messages or {}
    self.scrollOffset = 0
    self.layoutDirty = true
end

function PsychopatzConversationChat:addMessage(message)
    self.messages[#self.messages + 1] = message
    self.scrollOffset = 0
    self.layoutDirty = true
end

function PsychopatzConversationChat:setTyping(speaker)
    local previous = self.typingSpeaker
    self.typingSpeaker = speaker
    self.layoutDirty = true
    self.typingRenderSignature = nil
    if traceEnabled() and previous ~= speaker then
        DebugTrace.Record({
            source = "PsychopatzCore",
            event = "conversation.typing_state",
            data = {
                previousSpeaker = previous,
                speaker = speaker,
                messageCount = #(self.messages or {}),
                reveal = self.reveal,
                contentAlpha = self:getContentOpacity(),
            },
        })
    end
end

function PsychopatzConversationChat:buildLayout()
    local available = math.max(80, self.width - 34)
    local bubbleWidth = math.floor(available * 0.78)
    local y = (self.headerHeight or 24) + 11
    local lineH = fontHeight()
    local layouts = {}
    local index
    for index = 1, #self.messages do
        local message = self.messages[index]
        local lines = wrap(Text.Resolve(message.payload or message), bubbleWidth - 24)
        local height = math.max(46, #lines * lineH + 31)
        layouts[#layouts + 1] = {
            message = message,
            lines = lines,
            y = y,
            height = height,
            width = bubbleWidth,
        }
        y = y + height + 8
    end
    if self.typingSpeaker then
        layouts[#layouts + 1] = {
            typing = true,
            speaker = self.typingSpeaker,
            lines = { Text.Resolve({
                key = "UI_PsychopatzConversation_Typing",
                fallback = "...",
            }) },
            y = y,
            height = 39,
            width = math.floor(bubbleWidth * 0.42),
        }
        y = y + 47
    end
    self.messageLayout = layouts
    self.contentHeight = y + 4
    self.maximumScroll = math.max(
        0,
        self.contentHeight - self.height + (self.headerHeight or 24) + 5
    )
    self.scrollOffset = math.max(0, math.min(self.maximumScroll, self.scrollOffset or 0))
    self.layoutDirty = false
    if traceEnabled() and self.typingSpeaker then
        local typingLayout = layouts[#layouts]
        DebugTrace.Record({
            source = "PsychopatzCore",
            event = "conversation.typing_layout",
            data = {
                speaker = self.typingSpeaker,
                y = typingLayout and typingLayout.y or nil,
                height = typingLayout and typingLayout.height or nil,
                width = typingLayout and typingLayout.width or nil,
                contentHeight = self.contentHeight,
                maximumScroll = self.maximumScroll,
                scrollOffset = self.scrollOffset,
                viewportHeight = self.height,
            },
        })
    end
end

function PsychopatzConversationChat:prerender()
    PsychopatzConversationPart.prerender(self)
    if self.layoutDirty then self:buildLayout() end
end

function PsychopatzConversationChat:render()
    local contentAlpha = self:getContentOpacity()
    local lineH = fontHeight()
    local index
    if self.reveal <= 0 then
        if self.typingSpeaker then
            traceTypingRender(self, nil, nil, nil, false, contentAlpha, "reveal")
        end
        return
    end
    local headerHeight = self.headerHeight or 24
    local typingLayout
    local typingX
    local typingY
    self:setStencilRect(
        2,
        headerHeight + 2,
        self.width - 5,
        self.height - headerHeight - 5
    )
    for index = 1, #(self.messageLayout or {}) do
        local layout = self.messageLayout[index]
        local speaker = layout.message and layout.message.speaker or layout.speaker
        local player = speaker == "player"
        local x = player and (self.width - layout.width - 14) or 14
        local y = layout.y - (self.maximumScroll - (self.scrollOffset or 0))
        local color = player
            and { r = 0.055, g = 0.235, b = 0.19 }
            or { r = 0.125, g = 0.145, b = 0.135 }
        local accent = player
            and { r = 0.25, g = 0.92, b = 0.70 }
            or self:getAccentColor()
        if y + layout.height >= headerHeight and y <= self.height then
            if not layout.typing then
                self:drawRect(x + 3, y + 4, layout.width, layout.height,
                    contentAlpha * 0.38, 0, 0, 0)
                self:drawRect(x, y, layout.width, layout.height, contentAlpha * 0.92,
                    color.r, color.g, color.b)
                self:drawRectBorder(
                    x,
                    y,
                    layout.width,
                    layout.height,
                    contentAlpha * 0.44,
                    accent.r,
                    accent.g,
                    accent.b
                )
                local tailX = player and x + layout.width - 8 or x - 5
                self:drawRect(tailX, y + layout.height - 10, 8, 6,
                    contentAlpha * 0.9, color.r, color.g, color.b)
                local railX = player and x + layout.width - 3 or x
                self:drawRect(railX, y, 3, layout.height, contentAlpha * 0.92,
                    accent.r, accent.g, accent.b)
            end
            if layout.typing then
                typingLayout = layout
                typingX = x
                typingY = y
            end
            local npcName = self.owner
                and self.owner.spec
                and self.owner.spec.context
                and self.owner.spec.context.npcName
                or Text.Resolve({
                    key = "UI_PsychopatzConversation_NPC",
                    fallback = "NPC",
                })
            if not player and layout.message
                and layout.message.speakerName
            then
                npcName = layout.message.speakerName
            end
            local playerName = self.owner
                and self.owner.spec
                and self.owner.spec.context
                and (
                    self.owner.spec.context.playerName
                    or self.owner.spec.context.playerFullName
                )
            local speakerLabel = player
                and (playerName or Text.Resolve({
                        key = "UI_PsychopatzConversation_You",
                        fallback = "YOU",
                    }))
                or tostring(npcName)
            self:drawText(
                string.upper(speakerLabel),
                x + 10,
                y + 4,
                accent.r,
                accent.g,
                accent.b,
                contentAlpha * 0.9,
                UIFont.Small
            )
            if layout.typing then
                self:drawText(
                    Typing.GetText(),
                    x + 10,
                    y + 20,
                    0.74,
                    0.91,
                    0.82,
                    contentAlpha,
                    UIFont.Small
                )
            else
                local lineIndex
                for lineIndex = 1, #layout.lines do
                    drawFormattedLine(
                        self,
                        layout.lines[lineIndex],
                        x + 10,
                        y + 20 + (lineIndex - 1) * lineH,
                        { r = 0.93, g = 0.95, b = 0.92 },
                        accent,
                        contentAlpha,
                        layout.lines[lineIndex].kind
                    )
                end
            end
        end
    end
    if self.typingSpeaker then
        local visible = typingLayout ~= nil
        traceTypingRender(
            self,
            typingLayout,
            typingX,
            typingY,
            visible,
            contentAlpha,
            visible and "visible" or "clipped"
        )
    end
    self:clearStencilRect()
    if self.maximumScroll > 0 then
        local trackY = headerHeight + 7
        local trackH = math.max(18, self.height - trackY - 8)
        local viewportH = math.max(1, self.height - headerHeight)
        local thumbH = math.max(18, trackH * (viewportH / self.contentHeight))
        local thumbY = trackY + (trackH - thumbH)
            * (1 - ((self.scrollOffset or 0) / self.maximumScroll))
        local accent = self:getAccentColor()
        self:drawRect(self.width - 7, trackY, 2, trackH,
            contentAlpha * 0.18, accent.r, accent.g, accent.b)
        self:drawRect(self.width - 8, thumbY, 4, thumbH,
            contentAlpha * 0.88, accent.r, accent.g, accent.b)
    end
end

function PsychopatzConversationChat:onMouseWheel(del)
    if self.editMode then return false end
    if self.layoutDirty then self:buildLayout() end
    self.scrollOffset = math.max(
        0,
        math.min(self.maximumScroll or 0, (self.scrollOffset or 0) + del * 38)
    )
    return true
end

function PsychopatzConversationChat:onPartResize()
    PsychopatzConversationPart.onPartResize(self)
    self.layoutDirty = true
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

return PsychopatzConversationChat
