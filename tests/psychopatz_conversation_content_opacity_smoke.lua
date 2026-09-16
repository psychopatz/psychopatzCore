local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

local Part = {}
Part.__index = Part
local panelOpacity = 0
local contentOpacity = 1
local traceEntries = {}
local DebugTrace = {
    IsEnabled = function() return true end,
    Record = function(definition)
        traceEntries[#traceEntries + 1] = definition
    end,
}

function Part:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

function Part:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        reveal = 1,
        headerHeight = 24,
        padding = 8,
        maximumScroll = 1,
        scrollOffset = 0,
        draws = {},
    }, self)
end

function Part:getBackgroundOpacity() return panelOpacity end
function Part:getContentOpacity() return contentOpacity end
function Part:getAccentColor()
    return { r = 0.9, g = 0.7, b = 0.1 }
end
function Part:setStencilRect() end
function Part:clearStencilRect() end
function Part:drawRect(x, y, width, height, alpha, red, green, blue)
    self.draws[#self.draws + 1] = {
        kind = "rect",
        x = x,
        y = y,
        width = width,
        height = height,
        alpha = alpha,
        red = red,
        green = green,
        blue = blue,
    }
end
function Part:drawRectBorder(_, _, _, _, alpha)
    self.draws[#self.draws + 1] = { kind = "border", alpha = alpha }
end
function Part:drawText(_, _, _, _, _, _, alpha)
    self.draws[#self.draws + 1] = { kind = "text", alpha = alpha }
end
function Part:drawTextCentre(_, _, _, _, _, _, alpha)
    self.draws[#self.draws + 1] = { kind = "text", alpha = alpha }
end

PsychopatzConversationPart = Part
UIFont = { Small = {} }
PsychopatzCore = {
    DebugTrace = DebugTrace,
    Conversation = {
        Text = {
            Resolve = function(value, fallback)
                if type(value) == "table" then
                    return value.payload or value.fallback or fallback or ""
                end
                return tostring(value or fallback or "")
            end,
        },
        Typing = { GetText = function() return "..." end },
    },
    Markdown = {
        Wrap = function(value) return { tostring(value or "") } end,
    },
}

package.preload[
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
] = function() return Part end
package.preload[
    "PsychopatzCore/UI/Conversation/PsychopatzConversationTyping"
] = function() return PsychopatzCore.Conversation.Typing end
package.preload["PsychopatzCore/Text/PsychopatzMarkdown"] =
    function() return PsychopatzCore.Markdown end

dofile(ROOT .. "UI/Conversation/Parts/PsychopatzConversationChat.lua")
dofile(ROOT .. "UI/Conversation/Parts/PsychopatzConversationChoices.lua")

local function assertAllVisible(draws, label)
    if #draws == 0 then error(label .. ": no draw calls", 2) end
    for index, draw in ipairs(draws) do
        if draw.alpha <= 0 then
            error(label .. ": draw " .. tostring(index)
                .. " was assigned zero content alpha", 2)
        end
    end
end

local function assertAllHidden(draws, label)
    if #draws == 0 then error(label .. ": no draw calls", 2) end
    for index, draw in ipairs(draws) do
        if draw.alpha > 0 then
            error(label .. ": draw " .. tostring(index)
                .. " remained visible at zero content alpha", 2)
        end
    end
end

local chat = PsychopatzConversationChat:new(0, 0, 320, 180)
chat.messages = {}
chat:setTyping("npc")
chat:buildLayout()
local generatedTyping = chat.messageLayout[#chat.messageLayout]
if not generatedTyping or generatedTyping.typing ~= true then
    error("typing lifecycle: setTyping did not create a typing layout", 2)
end
if generatedTyping.y < chat.headerHeight + 2
    or generatedTyping.y + generatedTyping.height > chat.height - 3
then
    error("typing lifecycle: generated row is outside the chat viewport", 2)
end
chat.draws = {}
chat:render()
if #chat.draws == 0 then error("typing lifecycle: no generated draw calls", 2) end
for index, draw in ipairs(chat.draws) do
    if draw.kind ~= "text" or draw.alpha <= 0 then
        error("typing lifecycle: generated draw " .. tostring(index)
            .. " was not visible content", 2)
    end
end
local traceEvents = {}
for _, entry in ipairs(traceEntries) do
    traceEvents[entry.event] = true
end
if not traceEvents["conversation.typing_state"]
    or not traceEvents["conversation.typing_layout"]
    or not traceEvents["conversation.typing_render"]
then
    error("typing lifecycle: runtime trace missed a lifecycle boundary", 2)
end
chat:setTyping(nil)
chat.messageLayout = {
    {
        message = { speaker = "npc", speakerName = "NPC" },
        lines = { "Hello" },
        y = 32,
        height = 46,
        width = 220,
    },
}
chat.contentHeight = 300
chat:render()
assertAllVisible(chat.draws, "conversation rows")
local railIndex
local tailIndex
for index, draw in ipairs(chat.draws) do
    if draw.kind == "rect" and draw.width == 3 then
        railIndex = index
    elseif draw.kind == "rect" and draw.width == 8 and draw.height == 6 then
        tailIndex = index
    end
end
if not railIndex or not tailIndex or tailIndex >= railIndex then
    error("conversation row: tail must be drawn before its green rail", 2)
end

chat.maximumScroll = 0
chat.messageLayout = {
    {
        typing = true,
        speaker = "npc",
        lines = { "..." },
        y = 32,
        height = 39,
        width = 100,
    },
}
chat.draws = {}
chat:render()
if #chat.draws == 0 then error("typing row: no draw calls", 2) end
for index, draw in ipairs(chat.draws) do
    if draw.kind ~= "text" then
        error("typing row: draw " .. tostring(index)
            .. " retained non-text chrome", 2)
    end
    if draw.alpha <= 0 then
        error("typing row: draw " .. tostring(index)
            .. " was assigned zero content alpha", 2)
    end
end

chat.messageLayout = {
    {
        message = { speaker = "npc", speakerName = "NPC" },
        lines = { "Hello" },
        y = 32,
        height = 46,
        width = 220,
    },
}
chat.maximumScroll = 1
contentOpacity = 0
chat.draws = {}
chat:render()
assertAllHidden(chat.draws, "conversation rows")

contentOpacity = 1
local choices = PsychopatzConversationChoices:new(0, 0, 320, 180)
choices.owner = { isConversationInteractive = function() return true end }
choices.choices = { { text = "Choose this" } }
choices.choiceLayout = { { y = 32, height = 42, lines = { "Choose this" } } }
choices.contentHeight = 300
choices:render()
assertAllVisible(choices.draws, "response controls")
contentOpacity = 0
choices.draws = {}
choices:render()
assertAllHidden(choices.draws, "response controls")

print("psychopatz_conversation_content_opacity_smoke: ok")
