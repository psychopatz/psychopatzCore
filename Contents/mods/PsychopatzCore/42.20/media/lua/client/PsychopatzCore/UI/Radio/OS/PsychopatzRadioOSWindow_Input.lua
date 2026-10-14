-- Mouse, keyboard and joypad input for the Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local Window = PsychopatzCore.RadioOS.Window

local function numeric(value)
    return tonumber(value) or 0
end

local function setCapture(window, value)
    if window and window.setCapture then window:setCapture(value == true) end
end

local function mousePosition(window, fallbackX, fallbackY)
    if getMouseX and getMouseY and window.getAbsoluteX
        and window.getAbsoluteY
    then
        return getMouseX() - window:getAbsoluteX(),
            getMouseY() - window:getAbsoluteY()
    end
    return fallbackX, fallbackY
end

function Window:isResizeHandle(x, y)
    local width = numeric(self.getWidth and self:getWidth() or self.width)
    local height = numeric(self.getHeight and self:getHeight() or self.height)
    local size = tonumber(self.resizeHandleSize) or 16
    return x >= width - size and y >= height - size
end

function Window:isDragRegion(x, y)
    local width = numeric(self.getWidth and self:getWidth() or self.width)
    local height = numeric(self.getHeight and self:getHeight() or self.height)
    if x < 0 or y < 0 or x > width or y > height then return false end
    if self:isInside(self:screenRect(), x, y) then return false end
    if self:hitControl(x, y) then return false end
    return true
end

function Window:finishPointer()
    local wasMoving = self._dragging or self._resizing
    self._dragging = false
    self._resizing = false
    setCapture(self, false)
    if wasMoving then self:saveGeometry(true) end
    self._pressedControl = nil
end

function Window:onMouseMove(dx, dy)
    if self._dragging then
        self:moveBy(numeric(dx), numeric(dy))
        return true
    end
    if self._resizing then
        self:resizeBy(numeric(dx), numeric(dy))
        return true
    end
    local x, y = mousePosition(self, dx, dy)
    self._hoverControl = self:hitControl(x, y)
    self._hoverScreenAction = self.hitScreenAction
        and self:hitScreenAction(x, y) or nil
    self._hoverResize = self:isResizeHandle(x, y)
    return true
end

function Window:onMouseMoveOutside(dx, dy)
    if self._dragging then
        self:moveBy(numeric(dx), numeric(dy))
        return true
    end
    if self._resizing then
        self:resizeBy(numeric(dx), numeric(dy))
        return true
    end
    self._hoverControl = nil
    self._hoverScreenAction = nil
    self._hoverResize = false
    return true
end

function Window:onMouseDown(x, y)
    if self._closed then return true end
    local control = self:hitControl(x, y)
    if control then return self:pressControl(control) end

    local action = self.hitScreenAction and self:hitScreenAction(x, y)
    if action and self.activateScreenAction then
        -- Screen rows are intentional commands.  Consume the event in the
        -- window so a click can never fall through to the game world.
        self:activateScreenAction(action)
        return true
    end

    if self:isResizeHandle(x, y) then
        self._resizing = true
        self._hoverResize = true
        setCapture(self, true)
        if self.bringToTop then self:bringToTop() end
        return true
    end

    if self:isDragRegion(x, y) then
        self._dragging = true
        setCapture(self, true)
        if self.bringToTop then self:bringToTop() end
    end
    return true
end

function Window:onMouseUp()
    self:finishPointer()
    return true
end

function Window:onMouseUpOutside()
    self:finishPointer()
    return true
end

function Window:onKeyPress(key)
    if Keyboard then
        if key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_BACK then
            self:back()
            return true
        elseif key == Keyboard.KEY_LEFT then
            self:pressControl("left")
            return true
        elseif key == Keyboard.KEY_RIGHT then
            self:pressControl("right")
            return true
        elseif key == Keyboard.KEY_UP then
            self:moveSelection(-1)
            return true
        elseif key == Keyboard.KEY_DOWN then
            self:moveSelection(1)
            return true
        elseif key == Keyboard.KEY_RETURN or key == Keyboard.KEY_SPACE then
            self:pressControl("center")
            return true
        end
    end
    return false
end

function Window:onJoypadDown(button)
    if Joypad and button == Joypad.AButton then
        return self:pressControl("center")
    elseif Joypad and button == Joypad.BButton then
        self:back()
        return true
    elseif Joypad and button == Joypad.LBumper then
        return self:pressControl("left")
    elseif Joypad and button == Joypad.RBumper then
        return self:pressControl("right")
    end
    return false
end

return Window
