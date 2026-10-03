local Portrait = PsychopatzConversationPortrait
local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings
local Input = {}

local function normalizeScreenVariant(value)
    if value == nil then return nil end
    value = string.lower(tostring(value))
    if value == "crt" or value == "screen" then return "crt" end
    if value == "subtle" or value == "default" or value == "clean" then
        return "subtle"
    end
    if value == "none" or value == "off" then return "none" end
    return nil
end

local function isCRTEnabled(part)
    local variant = normalizeScreenVariant(part and part.screenVariant)
    if variant == "crt" then return true end
    if variant == "none" then return false end
    return Settings and Settings.Get
        and Settings.Get("crtEnabled", false) == true
end

local function partCoordinate(part, panel, value, axis)
    local coordinate = tonumber(value) or 0
    local current = panel
    local getter
    local parent
    local offset
    while current and current ~= part do
        getter = axis == "x" and current.getX or current.getY
        offset = getter and getter(current) or current[axis]
        coordinate = coordinate + (tonumber(offset) or 0)
        parent = current.getParent and current:getParent() or current.parent
        current = parent
    end
    return coordinate
end

-- The 3D portrait consumes pointer input to rotate the face. During layout
-- editing, forward that input to its containing panel so dragging the face
-- moves/resizes the portrait window like every other conversation panel.
local function routeLayoutPointer(part, original, method, panel, x, y)
    if part and part.editMode then
        local result
        if method == "onMouseDown" then
            result = part[method](
                part,
                partCoordinate(part, panel, x, "x"),
                partCoordinate(part, panel, y, "y")
            )
            if result and panel.setCapture then
                panel:setCapture(true)
            end
            part.layoutPointerPanel = panel
            return result
        end
        result = part[method](part, x, y)
        if method == "onMouseUp" or method == "onMouseUpOutside" then
            if panel.setCapture then panel:setCapture(false) end
            if part.layoutPointerPanel == panel then
                part.layoutPointerPanel = nil
            end
        end
        return result
    end
    return original and original(panel, x, y) or false
end

local ResizeGrip = ISPanel:derive("PsychopatzConversationPortraitResizeGrip")

function ResizeGrip:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0, g = 0, b = 0, a = 0 }
end

function ResizeGrip:prerender()
    if not self.owner or not self.owner.editMode then return end
    self:drawRect(0, 0, self.width, self.height,
        0.92, 0.30, 0.82, 1.0)
end

function ResizeGrip:onMouseDown(x, y)
    if not self.owner or not self.owner.editMode then return false end
    local accepted = self.owner:onMouseDown(self.x + x, self.y + y)
    if accepted and self.setCapture then
        self:setCapture(true)
    end
    if accepted then self.owner.layoutPointerPanel = self end
    return accepted
end

function ResizeGrip:onMouseMove(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMove(dx, dy)
end

function ResizeGrip:onMouseMoveOutside(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMoveOutside(dx, dy)
end

function ResizeGrip:onMouseUp(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUp(self.x + x, self.y + y)
    if self.setCapture then self:setCapture(false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:onMouseUpOutside(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUpOutside(self.x + x, self.y + y)
    if self.setCapture then self:setCapture(false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:new(x, y, width, height, owner)
    local o = ISPanel.new(self, x, y, width, height)
    o.owner = owner
    return o
end

local function installLayoutPointerBridge(part, panel)
    if not panel or panel.layoutPointerBridgeInstalled then return end
    panel.layoutPointerBridgeInstalled = true
    local originalMouseDown = panel.onMouseDown
    local originalMouseMove = panel.onMouseMove
    local originalMouseMoveOutside = panel.onMouseMoveOutside
    local originalMouseUp = panel.onMouseUp
    local originalMouseUpOutside = panel.onMouseUpOutside
    panel.onMouseDown = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseDown, "onMouseDown", element, x, y
        )
    end
    panel.onMouseMove = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseMove, "onMouseMove", element, x, y
        )
    end
    panel.onMouseMoveOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseMoveOutside,
            "onMouseMoveOutside",
            element,
            x,
            y
        )
    end
    panel.onMouseUp = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseUp, "onMouseUp", element, x, y
        )
    end
    panel.onMouseUpOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseUpOutside,
            "onMouseUpOutside",
            element,
            x,
            y
        )
    end
end

Input.NormalizeScreenVariant = normalizeScreenVariant
Input.IsCRTEnabled = isCRTEnabled
Input.ResizeGrip = ResizeGrip
Input.InstallLayoutPointerBridge = installLayoutPointerBridge

return Input
