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

local function notifyHighlight(choice, highlighted)
    if type(choice) ~= "table"
        or type(choice.onHighlightChanged) ~= "function"
    then
        return
    end
    choice.onHighlightChanged(choice, highlighted == true)
end

local Internal = {
    fontHeight = fontHeight,
}
PsychopatzConversationChoices.Internal = Internal

function PsychopatzConversationChoices:setHoveredChoice(index)
    if index == self.hoveredChoice then return false end
    local previous = self.hoveredChoice and self.choices
        and self.choices[self.hoveredChoice] or nil
    local current = index and self.choices and self.choices[index] or nil
    self.hoveredChoice = index
    notifyHighlight(previous, false)
    notifyHighlight(current, true)
    return true
end

function PsychopatzConversationChoices:setChoices(choices)
    self:setHoveredChoice(nil)
    self.choices = choices or {}
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
    local contentAlpha = self:getContentOpacity()
    local accent = self:getAccentColor()
    local headerHeight = self.headerHeight or 24
    self:setStencilRect(
        2,
        headerHeight + 2,
        self.width - 5,
        self.height - headerHeight - 5
    )
    Internal.renderChoices(self, contentAlpha, accent, headerHeight)
    self:clearStencilRect()
    Internal.renderScrollbar(self, contentAlpha, accent, headerHeight)
    self:updateChoiceTooltip()
end
-- A disabled entry can explain why it is disabled: the reason shows on hover
-- instead of the row silently doing nothing. Follows the shared list-tooltip
-- pattern (an ISToolTip owned by the drawing panel, repositioned on hover).
function PsychopatzConversationChoices:updateChoiceTooltip()
    local hovered = self.hoveredChoice and self.choices
        and self.choices[self.hoveredChoice] or nil
    local text
    if hovered and hovered.enabled == false
        and type(hovered.tooltip) == "string"
        and hovered.tooltip ~= ""
    then
        text = hovered.tooltip
    end
    if not text or not ISToolTip then
        if self.choiceTooltip and self.choiceTooltip.getIsVisible
            and self.choiceTooltip:getIsVisible()
        then
            self.choiceTooltip:setVisible(false)
            self.choiceTooltip:removeFromUIManager()
        end
        return
    end
    if not self.choiceTooltip then
        self.choiceTooltip = ISToolTip:new()
        self.choiceTooltip:setOwner(self)
        self.choiceTooltip:setVisible(false)
        self.choiceTooltip:setAlwaysOnTop(true)
        self.choiceTooltip.maxLineWidth = 1000
    end
    if not self.choiceTooltip:getIsVisible() then
        self.choiceTooltip:addToUIManager()
        self.choiceTooltip:setVisible(true)
    end
    self.choiceTooltip.description = text
    self.choiceTooltip:setX(self:getMouseX() + 23)
    self.choiceTooltip:setY(self:getMouseY() + 23)
end

function PsychopatzConversationChoices:onMouseMove(dx, dy)
    if self.editMode then
        return PsychopatzConversationPart.onMouseMove(self, dx, dy)
    end
    local x = self:getMouseX()
    local y = self:getMouseY()
    self:setHoveredChoice(self:choiceAt(x, y))
    return self.hoveredChoice ~= nil
end

function PsychopatzConversationChoices:onMouseMoveOutside(dx, dy)
    if self.editMode then
        return PsychopatzConversationPart.onMouseMoveOutside(self, dx, dy)
    end
    self:setHoveredChoice(nil)
    return false
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
    PsychopatzConversationPart.onPartResize(self)
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

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices_Renderer"

return PsychopatzConversationChoices
