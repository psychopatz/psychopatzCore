-- Mouse, keyboard and joypad input for the Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local Window = PsychopatzCore.RadioOS.Window

local function diagnostics()
    return PsychopatzCore.RadioOS.Diagnostics
end

local function numeric(value)
    return tonumber(value) or 0
end

local function setCapture(window, value)
    if window and window.setCapture then window:setCapture(value == true) end
end

local function isCaptured(window)
    if not window or type(window.isCapture) ~= "function" then return nil end
    local ok, value = pcall(window.isCapture, window)
    if not ok then return nil end
    return value == true
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
    local wasDragging = self._dragging
    local wasResizing = self._resizing
    local wasMoving = wasDragging or wasResizing
    self._pointerDown = false
    self._dragging = false
    self._resizing = false
    setCapture(self, false)
    if wasDragging and self.presentationMode == "immersive"
        and not self._layoutEditing and self.finishPresentationDrag
    then
        self:finishPresentationDrag()
    elseif wasMoving then
        self:saveGeometry(true)
    end
    local control = self._pointerControl
    self._pointerControl = nil
    if control and not wasMoving and not self._pointerCancelled then
        self:releaseControl(control)
    else
        self._pressedControl = nil
        self._pttHeld = false
    end
    self._pointerCancelled = false
end

function Window:recoverStalePointer(reason)
    if not self._dragging and not self._resizing
        and not self._pointerControl
    then
        self._pointerDown = false
        return false
    end
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.RecordPointer then
        activeDiagnostics.RecordPointer(self, "recovered", {
            reason = reason or "stale_pointer",
        })
    end
    self._pointerCancelled = true
    self:finishPointer()
    return true
end

function Window:onMouseMove(dx, dy)
    if self._dragging then
        -- A stale drag must never turn ordinary hover motion into window
        -- motion.  This also protects against an engine callback being
        -- skipped while the panel is outside a max-draw boundary.
        if self._pointerDown ~= true then
            self:recoverStalePointer("drag_without_pointer_down")
            return true
        end
        local captured = isCaptured(self)
        if captured == false then
            self:recoverStalePointer("capture_lost")
            return true
        end
        local deltaX = numeric(dx)
        local deltaY = numeric(dy)
        if self.presentationMode == "immersive"
            and not self._layoutEditing and self.trackPresentationDrag
        then
            self:trackPresentationDrag(deltaX, deltaY)
        else
            self:moveBy(deltaX, deltaY)
        end
        return true
    end
    if self._resizing then
        if self._pointerDown ~= true then
            self:recoverStalePointer("resize_without_pointer_down")
            return true
        end
        self:resizeBy(numeric(dx), numeric(dy))
        return true
    end
    local x, y = mousePosition(self, dx, dy)
    self._hoverControl = self:hitControl(x, y)
    self._hoverScreenAction = self.hitScreenAction
        and self:hitScreenAction(x, y) or nil
    self._hoverResize = self._layoutEditing and self:isResizeHandle(x, y)
    return true
end

function Window:onMouseMoveOutside(dx, dy)
    if self._dragging then
        if self._pointerDown ~= true then
            self:recoverStalePointer("outside_drag_without_pointer_down")
            return true
        end
        return self:onMouseMove(dx, dy)
    end
    if self._resizing then
        if self._pointerDown ~= true then
            self:recoverStalePointer("outside_resize_without_pointer_down")
            return true
        end
        self:resizeBy(numeric(dx), numeric(dy))
        return true
    end
    self._hoverControl = nil
    self._hoverScreenAction = nil
    self._hoverResize = false
    return true
end

function Window:onMouseDown(x, y)
    local activeDiagnostics = diagnostics()
    if self._pointerDown == true or self._dragging or self._resizing
        or self._pointerControl
    then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "ignored", {
                reason = "duplicate_down",
                localX = x, localY = y,
            })
        end
        return true
    end
    if self._closed then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "ignored", {
                reason = "closed", localX = x, localY = y,
            })
        end
        return true
    end
    if self.presentationState == "opening"
        or self.presentationState == "showing"
        or self.presentationState == "hiding"
    then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "ignored", {
                reason = "animation", state = self.presentationState,
                localX = x, localY = y,
            })
        end
        return true
    end
    local control = self:hitControl(x, y)
    if control then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "down", {
                branch = "control", control = control,
                localX = x, localY = y,
            })
        end
        self._pointerControl = control
        self._pointerDown = true
        self._pointerCancelled = false
        return self:pressControl(control)
    end

    local action = self.hitScreenAction and self:hitScreenAction(x, y)
    if action and self.activateScreenAction then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "down", {
                branch = "screen_action", action = action,
                localX = x, localY = y,
            })
        end
        -- Screen rows are intentional commands.  Consume the event in the
        -- window so a click can never fall through to the game world.
        self:activateScreenAction(action)
        return true
    end

    if self._layoutEditing and self:isResizeHandle(x, y) then
        if activeDiagnostics and activeDiagnostics.RecordPointer then
            activeDiagnostics.RecordPointer(self, "down", {
                branch = "resize", localX = x, localY = y,
            })
        end
        self._resizing = true
        self._pointerDown = true
        self._hoverResize = true
        setCapture(self, true)
        if self.bringToTop then self:bringToTop() end
        return true
    end

    if self:isDragRegion(x, y) then
        if self.presentationMode == "immersive"
            and self.presentationState == "docked"
            and self.applyDockPosition
        then
            -- Repair a legacy/full-body saved y before starting a gesture.
            -- The immersive surface always begins from its dock anchor.
            self:applyDockPosition()
        end
        self._pointerDown = true
        self._dragging = true
        self._dragDistanceY = 0
        if self.beginPresentationDrag
            and self.presentationMode == "immersive"
            and not self._layoutEditing
        then
            self:beginPresentationDrag(x, y)
        end
        setCapture(self, true)
        if self.bringToTop then self:bringToTop() end
    elseif activeDiagnostics and activeDiagnostics.RecordPointer then
        activeDiagnostics.RecordPointer(self, "ignored", {
            reason = "no_drag_region", localX = x, localY = y,
        })
    end
    return true
end

function Window:onMouseUp()
    self:finishPointer()
    return true
end

function Window:onMouseUpOutside()
    self._pointerCancelled = true
    self:finishPointer()
    return true
end

function Window:onKeyPress(key)
    if Keyboard then
        if key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_BACK then
            self:back()
            return true
elseif key == Keyboard.KEY_LEFT then
            self:triggerControl("left")
            return true
        elseif key == Keyboard.KEY_RIGHT then
            self:triggerControl("right")
            return true
        elseif key == Keyboard.KEY_UP then
            self:triggerControl("up")
            return true
        elseif key == Keyboard.KEY_DOWN then
            self:triggerControl("down")
            return true
        elseif key == Keyboard.KEY_RETURN or key == Keyboard.KEY_SPACE then
            self:triggerControl("ok")
            return true
        end
    end
    return false
end

function Window:onJoypadDown(button)
    if Joypad and button == Joypad.AButton then
        return self:triggerControl("ok")
    elseif Joypad and button == Joypad.BButton then
        self:back()
        return true
    elseif Joypad and button == Joypad.LBumper then
        return self:triggerControl("left")
    elseif Joypad and button == Joypad.RBumper then
        return self:triggerControl("right")
    end
    return false
end

return Window
