local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

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
function Panel:getParent() return self.parent end
function Panel:getX() return self.x end
function Panel:getY() return self.y end
function Panel:getWidth() return self.width end
function Panel:getHeight() return self.height end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
function Panel:setVisible(value) self.visible = value end
function Panel:setCapture(value) self.nativeCapture = value end
function Panel:setAnchorLeft() end
function Panel:setAnchorRight() end
function Panel:setAnchorTop() end
function Panel:setAnchorBottom() end
function Panel:drawRect() end

ISPanel = Panel

local Model = Panel:derive("TestPortraitModel")
function Model:new(x, y, width, height)
    local o = Panel.new(self, x, y, width, height)
    o.originalMouseDownCount = 0
    return o
end
function Model:onMouseDown()
    self.originalMouseDownCount = self.originalMouseDownCount + 1
    return true
end
function Model:onMouseMove() return true end
function Model:onMouseMoveOutside() return true end
function Model:onMouseUp() return true end
function Model:onMouseUpOutside() return true end

local PortraitPanel = Panel:derive("TestPortraitPanel")
function PortraitPanel:new(x, y, width, height)
    return Panel.new(self, x, y, width, height)
end
function PortraitPanel:instantiate()
    self.modelView = Model:new(0, 0, self.width, self.height)
    self:addChild(self.modelView)
end
function PortraitPanel:setTarget() end
function PortraitPanel:setPortraitBounds(x, y, width, height)
    self:setX(x)
    self:setY(y)
    self:setWidth(width)
    self:setHeight(height)
    self.modelView:setWidth(width)
    self.modelView:setHeight(height)
end

PsychopatzCore = {
    Conversation = {
        Text = { Resolve = function(_, fallback) return fallback end },
        Theme = {
            Resolve = function() return { r = 1, g = 1, b = 1 } end,
            Brighten = function(_, color) return color end,
        },
        Settings = { Get = function(_, fallback) return fallback end },
        Backgrounds = { Get = function() return nil end },
    },
}

package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISUI3DModel"] = function() return true end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"] =
    function()
        dofile(ROOT .. "UI/Conversation/Parts/PsychopatzConversationPart.lua")
        return PsychopatzConversationPart
    end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationOpacity"] =
    function()
        local opacity = {
            Get = function(_, role)
                return role == "detail" and 1 or 0.82
            end,
        }
        PsychopatzCore.Conversation.Opacity = opacity
        return opacity
    end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationOpacityControl"] =
    function()
        local control = Panel:derive("TestOpacityControl")
        function control:new(x, y, width, height, options)
            local object = Panel.new(self, x, y, width, height)
            object.owner = options and options.owner
            object.partID = options and options.partID
            return object
        end
        function control:refresh() end
        function control:bringToTop() end
        PsychopatzCore.Conversation.OpacityControl = control
        return control
    end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationText"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"] =
    function() return true end
package.preload["PsychopatzCore/UI/Components/PsychopatzPortraitPanel"] =
    function()
        PsychopatzPortraitPanel = PortraitPanel
        return PortraitPanel
    end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"] =
    function() return true end

getMouseX = function() return 100 end
getMouseY = function() return 100 end

dofile(ROOT .. "UI/Conversation/Parts/PsychopatzConversationPortrait.lua")

local part = PsychopatzConversationPortrait:new(10, 20, 200, 200, {
    owner = {
        spec = {},
        canUseDebug = function() return true end,
    },
})
part:initialise()
part:createChildren()
part.parent = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end,
}

local model = part.portrait.modelView
assertEqual(model.originalMouseDownCount, 0,
    "model starts without pointer input")
model:onMouseDown(10, 10)
assertEqual(model.originalMouseDownCount, 1,
    "model keeps its normal pointer handler outside edit mode")

part:setEditMode(true)
assertEqual(part.resizeGrip.visible, true,
    "portrait resize grip becomes visible in edit mode")
assertEqual(part.opacityControl.visible, true,
    "authorized opacity control becomes visible in edit mode")
assertEqual(part.opacityControl.x, 8,
    "opacity control is centered horizontally")
assertEqual(part.opacityControl.y, 65,
    "opacity control is centered vertically")
assertEqual(part.children[#part.children], part.resizeGrip,
    "portrait resize grip is the topmost child")

-- The nested model receives this click first.  Its edit-mode bridge must
-- translate model-local coordinates through the portrait into part space.
model:onMouseDown(185, 185)
assertEqual(model.originalMouseDownCount, 1,
    "edit-mode model click bypasses portrait rotation")
assertEqual(part.capture, true, "model click starts part capture")
assertEqual(part.resizing, true, "model click reaches the resize corner")
assertEqual(model.nativeCapture, true, "model keeps native capture for drag events")

model:onMouseUp(185, 185)
assertEqual(part.capture, false, "model mouse-up finishes part capture")
assertEqual(model.nativeCapture, false, "model native capture is released")

part:setWidth(240)
part:setHeight(220)
part:onPartResize()
assertEqual(part.resizeGrip.x, 226, "resize grip follows width")
assertEqual(part.resizeGrip.y, 206, "resize grip follows height")
assertEqual(part.opacityControl.x, 8,
    "opacity control remains centered after resize")
assertEqual(part.opacityControl.y, 75,
    "opacity control remains vertically centered after resize")

part.resizeGrip:onMouseDown(1, 1)
assertEqual(part.resizing, true, "topmost grip starts resizing")
part.resizeGrip:onMouseUp(1, 1)
assertEqual(part.capture, false, "topmost grip finishes resizing")

-- The live conversation promotes opacity controls to the root so nested model
-- and content renderers cannot paint over the editor affordance.
local root = Panel:new(0, 0, 800, 600)
root:addChild(part)
part:attachOpacityControl(root)
assertEqual(part.opacityControl.parent, root,
    "opacity control is hosted by the conversation root")
assertEqual(root.children[#root.children], part.opacityControl,
    "root-hosted opacity control is the topmost editor child")
assertEqual(part.opacityControl.x, 18,
    "root-hosted opacity control keeps horizontal centering")
assertEqual(part.opacityControl.y, 95,
    "root-hosted opacity control keeps vertical centering")

part:setEditMode(false)
assertEqual(part.resizeGrip.visible, false,
    "portrait resize grip hides outside edit mode")

print("psychopatz_conversation_portrait_edit_smoke: ok")
