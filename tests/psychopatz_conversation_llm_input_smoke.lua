local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

package.path = table.concat({
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua",
    "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua",
    package.path,
}, ";")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function assertTrue(value, label)
    if not value then error(label or "assertTrue", 2) end
end

local Panel = {}
Panel.__index = Panel

function Panel:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

function Panel:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        children = {},
    }, self)
end

function Panel:createChildren() end
function Panel:addChild(child)
    self.children[#self.children + 1] = child
    child.parent = self
end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
function Panel:setVisible(value) self.visible = value end
function Panel:setTitle(value) self.title = value end
function Panel:setEnable(value) self.enabled = value end
function Panel:setEditable(value) self.editable = value end
function Panel:getText() return self.text or "" end
function Panel:setText(value) self.text = value end
function Panel:getWidth() return self.width end
function Panel:getHeight() return self.height end

ISPanel = Panel

local ConversationPart = Panel:derive("PsychopatzConversationPart")
function ConversationPart:getBackgroundOpacity() return 0.9 end
function ConversationPart:getContentOpacity() return 0.8 end
function ConversationPart:onPartResize() end
PsychopatzConversationPart = ConversationPart

PsychopatzCore = {
    Conversation = {
        Text = { Resolve = function(_, value) return value end },
        Opacity = { GetSignature = function() return "test" end },
    },
    UI = {},
}

local Theme = {
    colors = {
        surface = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        border = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        surfaceRaised = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        borderStrong = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
        text = { r = 1, g = 1, b = 1, a = 1 },
        textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
        accent = { r = 0.2, g = 0.8, b = 0.8, a = 1 },
        accentDark = { r = 0.1, g = 0.3, b = 0.3, a = 1 },
    },
    GetRevision = function() return 1 end,
}

local UI = PsychopatzCore.UI
local function makeControl(definition)
    local control = {
        id = definition and definition.id,
        text = definition and definition.text or "",
        backgroundColor = { a = 1 },
        borderColor = { a = 1 },
        textColor = { a = 1 },
    }
    setmetatable(control, { __index = Panel })
    control.onClick = definition and definition.onclick
    control:setTitle(definition and definition.title or "")
    return control
end

package.preload["ISUI/ISButton"] = function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] = function()
    UI.Theme = Theme
    return Theme
end
package.preload["PsychopatzCore/UI/Components/PsychopatzImageResolver"] =
    function()
        UI.ImageResolver = { Resolve = function(_, image) return image end }
        return UI.ImageResolver
    end
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function()
        function UI.CreateButton(parent, definition)
            local button = makeControl(definition)
            if parent then parent:addChild(button) end
            return button
        end
        function UI.SetButtonVariant(button, variant)
            button.variant = variant
            return button
        end
        function UI.RefreshTheme() return true end
        return UI
    end
package.preload["PsychopatzCore/UI/Components/PsychopatzTextEntry"] =
    function()
        function UI.CreateTextEntry(parent, definition)
            local entry = makeControl(definition)
            entry.text = "hello"
            entry.maxTextLength = definition.maxTextLength
            function entry:setMultipleLine(value) self.multiline = value end
            function entry:setMaxLines(value) self.maxLines = value end
            function entry:setMaxTextLength(value) self.maxTextLength = value end
            if parent then parent:addChild(entry) end
            return entry
        end
        return UI
    end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] =
    function() return ConversationPart end

Keyboard = {
    KEY_LSHIFT = 1,
    KEY_RSHIFT = 2,
    isKeyDown = function() return false end,
}

dofile(ROOT .. "UI/Conversation/Parts/PsychopatzConversationLLMInput.lua")

local submitted = 0
local closed = 0
local part = PsychopatzConversationLLMInput:new(0, 0, 320, 120, {
    modeButtons = {
        { mode = "chat", title = "CHAT", width = 50 },
    },
    toggleButton = {
        id = "stream",
        title = "STREAM",
        alternateTitle = "STOP",
        width = 50,
    },
    submit = function() submitted = submitted + 1; return true end,
    onClose = function() closed = closed + 1 end,
})
part.onPartResize = function() end
part.updateModeButtonStyles = function() end
part.updateToggleButton = function() end
part.refreshOpacity = function() end
part:createChildren()

assertEqual(#part.modeButtons, 1, "mode button created")
assertTrue(part.toggleButton ~= nil, "toggle button created")
assertTrue(part.entry ~= nil, "text entry created")
assertTrue(part.sendButton ~= nil, "send button created")
assertTrue(part.closeButton ~= nil, "close button created")
assertEqual(part.children[1].id, "chat", "mode button id preserved")
assertEqual(part.children[2].id, "stream", "toggle button id preserved")
assertEqual(part.children[3].maxTextLength, 4000,
    "text entry max length preserved")

part:onSubmit()
assertEqual(submitted, 1, "public submit callback preserved")
part:onClosePressed()
assertEqual(closed, 1, "public close callback preserved")

print("psychopatz_conversation_llm_input_smoke: ok")
