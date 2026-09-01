local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
    .. "PsychopatzCore/UI/"

PsychopatzCore = { UI = {} }
local UI = PsychopatzCore.UI

package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISScrollingListBox"] = function() return true end
package.preload[
    "PsychopatzCore/UI/Core/PsychopatzUILayout"] = function() return true end
package.preload[
    "PsychopatzCore/UI/Components/PsychopatzVirtualizedList"] = function()
        return {}
    end

dofile(ROOT .. "Components/PsychopatzUIControls.lua")

local expectedTarget = {}
local expectedButton = {}
local receivedTarget
local receivedButton
local receivedArgument

local callback = UI.ButtonCallback(function(button, target, argument)
    receivedButton = button
    receivedTarget = target
    receivedArgument = argument
end)

callback(expectedTarget, expectedButton, "argument")

if receivedTarget ~= expectedTarget then
    error("button callback target was not preserved")
end
if receivedButton ~= expectedButton then
    error("button callback did not receive the actual button")
end
if receivedArgument ~= "argument" then
    error("button callback varargs were not preserved")
end

print("psychopatz_command_hub_callback_smoke: ok")
