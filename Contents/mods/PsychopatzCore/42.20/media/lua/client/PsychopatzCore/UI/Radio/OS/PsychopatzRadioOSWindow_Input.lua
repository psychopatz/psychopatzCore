-- Mouse, keyboard and joypad input for the Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local Window = PsychopatzCore.RadioOS.Window

function Window:onMouseMove(x, y)
    self._hoverControl = self:hitControl(x, y)
    return true
end

function Window:onMouseMoveOutside()
    self._hoverControl = nil
end

function Window:onMouseDown(x, y)
    local control = self:hitControl(x, y)
    if control then return self:pressControl(control) end
    return true
end

function Window:onMouseUp()
    self._pressedControl = nil
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
