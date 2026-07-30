require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"

PsychopatzConversationChoices = PsychopatzConversationPart:derive(
    "PsychopatzConversationChoices"
)

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text

local function fontHeight()
    return getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16
end

local function textWidth(value)
    return getTextManager
        and getTextManager():MeasureStringX(UIFont.Small, value)
        or #tostring(value or "") * 8
end

local function wrap(value, maximumWidth)
    local lines = {}
    local line = ""
    local word
    for word in string.gmatch(tostring(value or ""), "%S+") do
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

function PsychopatzConversationChoices:setChoices(choices)
    self.choices = choices or {}
    self.hoveredChoice = nil
    self.scrollOffset = 0
    self.layoutDirty = true
end

function PsychopatzConversationChoices:buildLayout()
    local y = (self.headerHeight or 24) + self.padding
    local available = math.max(60, self.width - self.padding * 2 - 50)
    local lineH = fontHeight()
    self.choiceLayout = {}
    local index
    for index = 1, #self.choices do
        local lines = wrap(Text.Resolve(self.choices[index].text or self.choices[index]),
            available)
        local height = math.max(42, #lines * lineH + 19)
        self.choiceLayout[index] = {
            y = y,
            height = height,
            lines = lines,
        }
        y = y + height + 5
    end
    self.contentHeight = y + self.padding
    self.maximumScroll = math.max(
        0,
        self.contentHeight - self.height + (self.headerHeight or 24) + 5
    )
    self.scrollOffset = math.max(0,
        math.min(self.maximumScroll, self.scrollOffset or 0))
    self.layoutDirty = false
end

function PsychopatzConversationChoices:choiceAt(x, y)
    if self.layoutDirty then self:buildLayout() end
    if x < self.padding or x > self.width - self.padding then return nil end
    if y <= (self.headerHeight or 24) then return nil end
    local contentY = y + (self.maximumScroll - (self.scrollOffset or 0))
    local index
    for index = 1, #self.choiceLayout do
        local layout = self.choiceLayout[index]
        if contentY >= layout.y and contentY <= layout.y + layout.height then
            return index
        end
    end
    return nil
end

function PsychopatzConversationChoices:prerender()
    PsychopatzConversationPart.prerender(self)
    if self.layoutDirty then self:buildLayout() end
end

function PsychopatzConversationChoices:render()
    if self.reveal <= 0 then return end
    local alpha = self:getContentOpacity()
    local accent = self:getAccentColor()
    local index
    local headerHeight = self.headerHeight or 24
    self:setStencilRect(
        2,
        headerHeight + 2,
        self.width - 5,
        self.height - headerHeight - 5
    )
    for index = 1, #self.choices do
        local choice = self.choices[index]
        local layout = self.choiceLayout[index]
        local y = layout.y - (self.maximumScroll - (self.scrollOffset or 0))
        local enabled = choice.enabled ~= false
            and self.owner
            and self.owner:isConversationInteractive()
        local hovered = index == self.hoveredChoice
        local left = self.padding
        local width = self.width - self.padding * 2
        if y + layout.height >= headerHeight and y <= self.height then
        self:drawRect(
            left + 3,
            y + 3,
            width,
            layout.height,
            alpha * 0.34,
            0,
            0,
            0
        )
        self:drawRect(
            left,
            y,
            width,
            layout.height,
            alpha * (hovered and 0.9 or 0.63),
            enabled and accent.r * (hovered and 0.30 or 0.15) or 0.10,
            enabled and accent.g * (hovered and 0.30 or 0.15) or 0.10,
            enabled and accent.b * (hovered and 0.30 or 0.15) or 0.10
        )
        self:drawRectBorder(
            left,
            y,
            width,
            layout.height,
            alpha * (enabled and (hovered and 0.95 or 0.52) or 0.22),
            enabled and accent.r or 0.40,
            enabled and accent.g or 0.40,
            enabled and accent.b or 0.40
        )
        self:drawRect(
            left,
            y,
            hovered and 5 or 2,
            layout.height,
            alpha * (enabled and 0.92 or 0.24),
            accent.r,
            accent.g,
            accent.b
        )
        local badgeSize = 24
        local badgeX = left + 9
        local badgeY = y + math.floor((layout.height - badgeSize) / 2)
        self:drawRect(badgeX, badgeY, badgeSize, badgeSize,
            alpha * (hovered and 0.72 or 0.30),
            accent.r * 0.30,
            accent.g * 0.30,
            accent.b * 0.30)
        self:drawRectBorder(badgeX, badgeY, badgeSize, badgeSize,
            alpha * (enabled and 0.75 or 0.25),
            accent.r, accent.g, accent.b)
        self:drawTextCentre(
            tostring(index),
            badgeX + badgeSize / 2,
            badgeY + 4,
            enabled and math.min(1, accent.r + 0.28) or 0.45,
            enabled and math.min(1, accent.g + 0.28) or 0.45,
            enabled and math.min(1, accent.b + 0.28) or 0.45,
            alpha,
            UIFont.Small
        )
        if hovered and enabled then
            self:drawText(
                ">",
                left + width - 18,
                y + math.floor((layout.height - fontHeight()) / 2),
                math.min(1, accent.r + 0.25),
                math.min(1, accent.g + 0.25),
                math.min(1, accent.b + 0.25),
                alpha,
                UIFont.Small
            )
        end
        local lineIndex
        for lineIndex = 1, #layout.lines do
            self:drawText(
                layout.lines[lineIndex],
                left + 42,
                y + 8 + (lineIndex - 1) * fontHeight(),
                enabled and 0.92 or 0.48,
                enabled and 0.96 or 0.48,
                enabled and 0.90 or 0.48,
                alpha,
                UIFont.Small
            )
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
        self:drawRect(self.width - 7, trackY, 2, trackH,
            alpha * 0.18, accent.r, accent.g, accent.b)
        self:drawRect(self.width - 8, thumbY, 4, thumbH,
            alpha * 0.88, accent.r, accent.g, accent.b)
    end
end

function PsychopatzConversationChoices:onMouseMove(dx, dy)
    if self.editMode then
        return PsychopatzConversationPart.onMouseMove(self, dx, dy)
    end
    local x = self:getMouseX()
    local y = self:getMouseY()
    self.hoveredChoice = self:choiceAt(x, y)
    return self.hoveredChoice ~= nil
end

function PsychopatzConversationChoices:onMouseDown(x, y)
    if self.editMode then
        return PsychopatzConversationPart.onMouseDown(self, x, y)
    end
    local index = self:choiceAt(x, y)
    local choice = index and self.choices[index] or nil
    if choice and choice.enabled ~= false
        and self.owner
        and self.owner:isConversationInteractive()
    then
        self.owner:onChoiceSelected(choice, index)
        return true
    end
    return false
end

function PsychopatzConversationChoices:onMouseWheel(del)
    if self.editMode then return false end
    if self.layoutDirty then self:buildLayout() end
    self.scrollOffset = math.max(0,
        math.min(self.maximumScroll or 0, (self.scrollOffset or 0) + del * 38))
    return true
end

function PsychopatzConversationChoices:onPartResize()
    self.layoutDirty = true
end

function PsychopatzConversationChoices:new(x, y, width, height, options)
    options = options or {}
    options.partID = "choices"
    options.minimumWidth = options.minimumWidth or 240
    options.minimumHeight = options.minimumHeight or 100
    options.title = options.title or {
        key = "UI_PsychopatzConversation_Choices",
        fallback = "RESPONSE CHANNEL",
    }
    local o = PsychopatzConversationPart.new(self, x, y, width, height, options)
    o.choices = {}
    o.padding = 10
    o.choiceLayout = {}
    o.scrollOffset = 0
    o.layoutDirty = true
    return o
end

return PsychopatzConversationChoices
