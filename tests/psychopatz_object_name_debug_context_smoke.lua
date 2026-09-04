local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local authorized = false
local printed = {}
local oldPrint = print

PsychopatzCore = {
    Debug = {
        CanUse = function() return authorized end,
    },
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end

ISContextMenu = {}
print = function(message)
    printed[#printed + 1] = tostring(message)
end

local Context = require "PsychopatzCore/Debug/PsychopatzObjectNameDebugContext"

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    return menu
end

local square = {
    getX = function() return 101 end,
    getY = function() return 202 end,
    getZ = function() return 0 end,
}
local object = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return nil end,
    getSpriteName = function() return "trash_01_22" end,
    getProperties = function()
        return {
            get = function(_, key)
                return key == "CustomName" and "Trash" or nil
            end,
        }
    end,
    getSquare = function() return square end,
}
local player = {}
local menu = newMenu()

assert(Context.Add(menu, { object }, player) == nil,
    "object-name option was visible without debug access")
assert(#menu.options == 0, "unauthorized object-name menu was not empty")

authorized = true
local option = Context.Add(menu, { object }, player)
assert(option and option.name == "[Debug] Grab Object Name",
    "object-name option label was incorrect")
option.callback()
assert(#printed == 1, "object-name option did not print a record")
assert(string.find(printed[1], "resolvedName=Trash", 1, true),
    "resolved tile name was missing")
assert(string.find(printed[1], "customName=Trash", 1, true),
    "custom tile name was missing")
assert(string.find(printed[1], "spriteName=trash_01_22", 1, true),
    "sprite name was missing")

authorized = false
option.callback()
assert(#printed == 1, "stale object-name option bypassed debug access")

print = oldPrint
print("psychopatz_object_name_debug_context_smoke: ok")
