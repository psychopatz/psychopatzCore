-- Fixed Core window variant.
--
-- This is the attached-panel counterpart to PsychopatzWindow.  It keeps the
-- shared frame, theme, responsive layout, persistence, and resize behavior,
-- while removing the native pin/collapse controls and collapse behavior.

require "PsychopatzCore/UI/PsychopatzWindow"

local UI = PsychopatzCore.UI

PsychopatzFixedWindow = PsychopatzWindow:derive("PsychopatzFixedWindow")
UI.FixedWindow = PsychopatzFixedWindow

function PsychopatzFixedWindow:new(x, y, width, height, options)
    local fixedOptions = {}
    for key, value in pairs(options or {}) do fixedOptions[key] = value end
    fixedOptions.collapsible = false
    fixedOptions.pin = true
    local object = PsychopatzWindow.new(self, x, y, width, height,
        fixedOptions)
    setmetatable(object, self)
    self.__index = self
    return object
end

return PsychopatzFixedWindow
