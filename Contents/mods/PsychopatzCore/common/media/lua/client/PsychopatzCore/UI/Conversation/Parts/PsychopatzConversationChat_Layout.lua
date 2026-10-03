local Chat = PsychopatzConversationChat
local Internal = Chat.Internal
local Text = Internal.Text
local DebugTrace = Internal.DebugTrace
local traceEnabled = Internal.traceEnabled
local fontHeight = Internal.fontHeight
local wrap = Internal.wrap

function Chat:setMessages(messages)
    self.messages = messages or {}
    self.scrollOffset = 0
    self.layoutDirty = true
end

function Chat:addMessage(message)
    self.messages[#self.messages + 1] = message
    self.scrollOffset = 0
    self.layoutDirty = true
end

function Chat:setTyping(speaker)
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

function Chat:buildLayout()
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
    self.scrollOffset = math.max(
        0,
        math.min(self.maximumScroll, self.scrollOffset or 0)
    )
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

function Chat:prerender()
    PsychopatzConversationPart.prerender(self)
    if self.layoutDirty then self:buildLayout() end
end

function Chat:onMouseWheel(del)
    if self.editMode then return false end
    if self.layoutDirty then self:buildLayout() end
    self.scrollOffset = math.max(
        0,
        math.min(self.maximumScroll or 0, (self.scrollOffset or 0) + del * 38)
    )
    return true
end

function Chat:onPartResize()
    PsychopatzConversationPart.onPartResize(self)
    self.layoutDirty = true
end

return Internal
