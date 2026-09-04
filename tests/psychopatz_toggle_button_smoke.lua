local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = { UI = {} }
local UI = PsychopatzCore.UI
UI.SetButtonVariant = function(button, variant)
    button.variant = variant
end
UI.StyleButton = UI.SetButtonVariant
UI.CreateButton = function(parent, definition)
    local button = {
        target = definition.target or parent,
        onclick = definition.onclick,
        title = definition.title,
    }
    function button:setTitle(value) self.title = value end
    if parent and parent.addChild then parent:addChild(button) end
    return button
end

package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function() return UI end

dofile(CLIENT .. "PsychopatzCore/UI/Components/PsychopatzToggleButton.lua")

local parent = {
    children = {},
    addChild = function(self, child) self.children[#self.children + 1] = child end,
}
local changes = {}
local button = UI.CreateToggleButton(parent, {
    offTitle = "Debug Access: OFF",
    onTitle = "Debug Access: ON",
    offVariant = "quiet",
    onVariant = "success",
    autoToggle = true,
    onChange = function(_, _, value) changes[#changes + 1] = value end,
})

assert(button:getToggleState() == false, "toggle starts enabled")
assert(button.title == "Debug Access: OFF", "off title was not applied")
assert(button.variant == "quiet", "off variant was not applied")

button.onclick(button.target, button)
assert(button:getToggleState() == true, "toggle did not enable")
assert(button.title == "Debug Access: ON", "on title was not applied")
assert(button.variant == "success", "on variant was not applied")
assert(changes[1] == true, "onChange did not receive enabled state")

button.onclick(button.target, button)
assert(button:getToggleState() == false, "toggle did not disable")
assert(changes[2] == false, "onChange did not receive disabled state")

print("psychopatz_toggle_button_smoke: ok")
