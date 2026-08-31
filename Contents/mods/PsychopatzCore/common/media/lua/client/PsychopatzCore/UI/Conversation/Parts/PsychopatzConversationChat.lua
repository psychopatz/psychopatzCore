require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTyping"

PsychopatzConversationChat = PsychopatzConversationPart:derive(
    "PsychopatzConversationChat"
)

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local Typing = Conversation.Typing

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
    local lines = {}
    local line = ""
    local word
    value = tostring(value or "")
    for word in string.gmatch(value, "%S+") do
        local candidate = line == "" and word or (line .. " " .. word)
        if line ~= "" and textWidth(candidate) > maximumWidth then
            lines[#lines + 1] = line
            line = word
        else
            line = candidate
        end
    end
    lines[#lines + 1] = line ~= "" and line or " "
    return lines
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
    self.typingSpeaker = speaker
    self.layoutDirty = true
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
end

function PsychopatzConversationChat:prerender()
    PsychopatzConversationPart.prerender(self)
    if self.layoutDirty then self:buildLayout() end
end

function PsychopatzConversationChat:render()
    local alpha = self:getContentOpacity()
    local lineH = fontHeight()
    local index
    if self.reveal <= 0 then return end
    local headerHeight = self.headerHeight or 24
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
            self:drawRect(x + 3, y + 4, layout.width, layout.height,
                alpha * 0.38, 0, 0, 0)
            self:drawRect(x, y, layout.width, layout.height, alpha * 0.92,
                color.r, color.g, color.b)
            self:drawRectBorder(
                x,
                y,
                layout.width,
                layout.height,
                alpha * 0.44,
                accent.r,
                accent.g,
                accent.b
            )
            local railX = player and x + layout.width - 3 or x
            self:drawRect(railX, y, 3, layout.height, alpha * 0.92,
                accent.r, accent.g, accent.b)
            local tailX = player and x + layout.width - 8 or x - 5
            self:drawRect(tailX, y + layout.height - 10, 8, 6,
                alpha * 0.9, color.r, color.g, color.b)
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
                alpha * 0.9,
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
                    alpha,
                    UIFont.Small
                )
            else
            local lineIndex
            for lineIndex = 1, #layout.lines do
                self:drawText(
                    layout.lines[lineIndex],
                    x + 10,
                    y + 20 + (lineIndex - 1) * lineH,
                    0.93,
                    0.95,
                    0.92,
                    alpha,
                    UIFont.Small
                )
            end
            end
        end
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
            alpha * 0.18, accent.r, accent.g, accent.b)
        self:drawRect(self.width - 8, thumbY, 4, thumbH,
            alpha * 0.88, accent.r, accent.g, accent.b)
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
