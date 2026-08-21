local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
    .. "PsychopatzCore/UI/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local variant
PsychopatzCore = { UI = {
    CreateButton = function(_, definition)
        return {
            title = definition.title,
            setTitle = function(self, value) self.title = value end,
        }
    end,
    SetButtonVariant = function(button, value)
        variant = value
        button.variant = value
        return button
    end,
} }
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function() return PsychopatzCore.UI end

dofile(ROOT .. "Components/PsychopatzToggleButton.lua")
local toggle = PsychopatzCore.UI.CreateToggleButton(nil, {
    offTitle = "Assign", onTitle = "Remove",
    offVariant = "quiet", onVariant = "warning",
})
equal(toggle.title, "Assign", "toggle initial title")
equal(toggle:getToggleState(), false, "toggle initial state")
toggle:setToggleState(true)
equal(toggle.title, "Remove", "toggle active title")
equal(variant, "warning", "toggle active variant")
equal(toggle:toggle(), false, "toggle reverses state")
equal(toggle.title, "Assign", "toggle restored title")

local Window = {}
function Window:derive()
    local class = {}
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
PsychopatzCore.UI.Window = Window
PsychopatzCore.UI.Layout = {}
PsychopatzCore.UI.Theme = { colors = { text = {} } }
package.preload["PsychopatzCore/UI/PsychopatzWindow"] = function() return Window end

dofile(ROOT .. "PsychopatzNotificationWindow.lua")
PsychopatzCore.Notifications.instance = {}
local shown, reason = PsychopatzCore.Notifications.Show({
    id = "search:1", title = "Complete", details = { "Fridge: Beans" },
})
equal(shown, true, "notification queued")
equal(#PsychopatzCore.Notifications.Queue, 1, "notification queue size")
shown, reason = PsychopatzCore.Notifications.Show({ id = "search:1" })
equal(shown, false, "duplicate notification rejected")
equal(reason, "duplicate", "duplicate notification reason")

print("psychopatz_ui_components_smoke: ok")
