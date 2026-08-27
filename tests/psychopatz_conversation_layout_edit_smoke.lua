local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
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
        visible = true,
    }, self)
end

function Panel:initialise() end
function Panel:createChildren() end
function Panel:instantiate()
    if self.createChildren then self:createChildren() end
end
function Panel:addChild(child)
    child.parent = self
    self.children[#self.children + 1] = child
end
function Panel:setAnchorLeft() end
function Panel:setAnchorRight() end
function Panel:setVisible(value) self.visible = value end
function Panel:setTitle(value) self.title = value end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
function Panel:getX() return self.x end
function Panel:getY() return self.y end
function Panel:getWidth() return self.width end
function Panel:getHeight() return self.height end
function Panel:setReveal() end
function Panel:setEditMode() end
function Panel:onPartResize() end
function Panel:addToUIManager() end

ISPanel = Panel

local Button = Panel:derive("TestButton")
function Button:new(x, y, width, height, title, target, onclick)
    local o = Panel.new(self, x, y, width, height)
    o.title = title
    o.target = target
    o.onclick = onclick
    return o
end
ISButton = Button

local Part = Panel:derive("TestConversationPart")
local function registerPart(name)
    _G[name] = Part
    return Part
end

PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(key, fallback)
                if key == "showEditorButton" then return true end
                if values[key] ~= nil then return values[key] end
                return fallback
            end,
            Set = function(key, value)
                values[key] = value
                return value
            end,
        },
        Text = {
            Resolve = function(payload) return payload.fallback end,
        },
        Theme = {
            Resolve = function() return { r = 0.1, g = 1, b = 0.4 } end,
        },
        Animator = {
            New = function() return {} end,
            SkipOpen = function() end,
        },
        Lifecycle = {},
    },
}

values = {
    layout_portrait_x = 0.30,
    layout_portrait_y = 0.31,
    layout_portrait_w = 0.32,
    layout_portrait_h = 0.33,
    layout_relationship_x = 0.34,
    layout_relationship_y = 0.35,
    layout_relationship_w = 0.36,
    layout_relationship_h = 0.37,
    layout_history_x = 0.38,
    layout_history_y = 0.39,
    layout_history_w = 0.40,
    layout_history_h = 0.41,
    layout_choices_x = 0.42,
    layout_choices_y = 0.43,
    layout_choices_w = 0.44,
    layout_choices_h = 0.45,
}

package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"] =
    function() return PsychopatzCore.Conversation.Settings end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"] =
    function() return PsychopatzCore.Conversation.Layout end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationAnimator"] =
    function() return PsychopatzCore.Conversation.Animator end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLifecycle"] =
    function() return PsychopatzCore.Conversation.Lifecycle end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSession"] =
    function() return {} end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"] =
    function() return PsychopatzCore.Conversation.Theme end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait"] =
    function() return registerPart("PsychopatzConversationPortrait") end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat"] =
    function() return registerPart("PsychopatzConversationChat") end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices"] =
    function() return registerPart("PsychopatzConversationChoices") end

getCore = function()
    return {
        getScreenWidth = function() return 1000 end,
        getScreenHeight = function() return 800 end,
    }
end

dofile(ROOT .. "UI/Conversation/PsychopatzConversationLayout.lua")
dofile(ROOT .. "UI/Conversation/PsychopatzConversationView.lua")

local Conversation = PsychopatzCore.Conversation
local Layout = Conversation.Layout
local view = PsychopatzConversationView:new({})
view:initialise()
view:instantiate()
Conversation.instance = view

assertEqual(view.layoutButton.x, 830, "save button stays at the right")
assertEqual(view.resetLayoutButton.x, 680,
    "reset button sits beside save")
assertEqual(view.resetLayoutButton.title, "RESET TO DEFAULT",
    "reset button title")
assertEqual(view.resetLayoutButton.visible, false,
    "reset button starts hidden")

view:toggleEditMode()
assertEqual(view.resetLayoutButton.visible, true,
    "reset button appears in edit mode")

view.resetLayoutButton.onclick(view, view.resetLayoutButton)
assertEqual(values.layout_portrait_x, Layout.defaults.portrait.x,
    "portrait x resets to factory default")
assertEqual(values.layout_relationship_w, Layout.defaults.relationship.w,
    "relationship width resets to factory default")
assertEqual(values.layout_choices_h, Layout.defaults.choices.h,
    "choices height resets to factory default")
assertEqual(view.portraitPart.x, math.floor(Layout.defaults.portrait.x * 1000),
    "portrait bounds apply immediately")
assertEqual(view.historyPart.y, math.floor(Layout.defaults.history.y * 800),
    "history bounds apply immediately")

view:toggleEditMode()
assertEqual(view.resetLayoutButton.visible, false,
    "reset button hides after editing")

print("psychopatz_conversation_layout_edit_smoke: ok")
