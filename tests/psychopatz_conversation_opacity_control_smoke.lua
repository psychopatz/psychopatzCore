local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

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
        x = x, y = y, width = width, height = height, children = {},
    }, self)
end

function Panel:initialise() end
function Panel:instantiate() end
function Panel:addChild(child) child.parent = self end
function Panel:setVisible(value) self.visible = value end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
function Panel:getAbsoluteX() return self.x end
function Panel:bringToTop() end
function Panel:drawRect() end
function Panel:drawRectBorder() end
function Panel:drawText() end
function Panel:drawTextCentre() end
function Panel:drawTextRight() end
function Panel:render() end

ISPanel = Panel

local values = {
    conversationOpacityBase = 0.50,
    historySurfaceOpacityLift = 0,
    historyDetailOpacityLift = 0.18,
    portraitSurfaceOpacityLift = 0.10,
    portraitDetailOpacityLift = 0.18,
}

PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(key, fallback)
                return values[key] == nil and fallback or values[key]
            end,
            Set = function(key, value)
                values[key] = value
                return value
            end,
        },
        Text = {
            Resolve = function(payload) return payload.fallback end,
        },
    },
}

package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationOpacity"] =
    function()
        dofile(ROOT .. "UI/Conversation/PsychopatzConversationOpacity.lua")
        return PsychopatzCore.Conversation.Opacity
    end

dofile(ROOT .. "UI/Conversation/PsychopatzConversationOpacityControl.lua")

local Control = PsychopatzCore.Conversation.OpacityControl
local owner = {
    getAccentColor = function()
        return { r = 0.2, g = 0.8, b = 0.6 }
    end,
}
local control = Control:new(0, 0, 220, 70, {
    owner = owner,
    partID = "history",
})
control:initialise()
control:refresh(true)

getMouseX = function() return 150 end
control:onMouseDown(150, 20)
control:onMouseUp(178, 20)
assert(values.historySurfaceOpacityLift == 0.25,
    "surface slider writes only its module lift")

control:refresh(true)
getMouseX = function() return 178 end
control:onMouseDown(178, 47)
control:onMouseUp(178, 47)
assert(values.historyDetailOpacityLift == 0.50,
    "content slider writes only its module lift")

control:refresh(true)
getMouseX = function() return 66 end
control:onMouseDown(66, 20)
control:onMouseUp(66, 20)
control:refresh(true)
assert(values.historySurfaceOpacityLift == -0.50,
    "surface slider can reach a fully transparent panel")
assert(values.historyDetailOpacityLift == 0.50,
    "content slider remains independent from the panel layer")
assert(PsychopatzCore.Conversation.Opacity.Get("history", "surface") == 0,
    "surface effective opacity reaches zero")
assert(PsychopatzCore.Conversation.Opacity.Get("history", "detail") == 1,
    "content remains fully visible when the panel is transparent")

control:onMouseDown(66, 47)
control:onMouseUp(66, 47)
control:onMouseDown(66, 47)
control:onMouseUp(66, 47)
assert(values.historyDetailOpacityLift == -0.50,
    "content slider can still reach a fully transparent content layer")
assert(PsychopatzCore.Conversation.Opacity.Get("history", "detail") == 0,
    "content effective opacity reaches zero independently")

local other = Control:new(0, 0, 220, 70, {
    owner = owner,
    partID = "portrait",
})
other:initialise()
other:refresh(true)
assert(other.rows[1].value ~= control.rows[1].value,
    "each part keeps an independent slider value")

print("psychopatz_conversation_opacity_control_smoke: ok")
