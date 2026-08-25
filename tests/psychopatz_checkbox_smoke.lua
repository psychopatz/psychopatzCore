local CLIENT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = { UI = {} }
local UI = PsychopatzCore.UI

local TickBox = {}
TickBox.__index = TickBox
function TickBox:new(_, _, width, height, _, target, callback)
    return setmetatable({ width = width, height = height,
        target = target, callback = callback, selected = false }, self)
end
function TickBox:initialise() end
function TickBox:instantiate() end
function TickBox:addOption(label) self.label = label end
function TickBox:setSelected(_, value) self.selected = value == true end
function TickBox:isSelected() return self.selected end
function TickBox:setFont(font) self.font = font end
function TickBox:setX(value) self.x = value end
function TickBox:setY(value) self.y = value end

ISTickBox = TickBox
package.preload["ISUI/ISTickBox"] = function() return TickBox end

dofile(CLIENT .. "PsychopatzCore/UI/Components/PsychopatzCheckbox.lua")

local parent = {
    children = {},
    addChild = function(self, child) self.children[#self.children + 1] = child end,
}
local changes = {}
local checkbox = UI.CreateCheckbox(parent, {
    id = "debug_access",
    label = "Debug Access",
    value = false,
    onChange = function(_, value) changes[#changes + 1] = value end,
})

assert(checkbox:getChecked() == false, "checkbox starts selected")
assert(checkbox.label == "Debug Access", "checkbox label was not applied")
checkbox:setSelected(1, true)
assert(checkbox:getChecked() == true, "checkbox getter did not read state")
assert(checkbox:setChecked(false) == false, "checkbox setter did not clear state")
checkbox.callback(checkbox.target, checkbox, true)
assert(changes[1] == true, "checkbox change callback did not receive state")

print("psychopatz_checkbox_smoke: ok")
